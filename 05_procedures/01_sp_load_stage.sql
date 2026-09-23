/*=============================================================================
  SP_LOAD_STAGE - Generic Metadata-Driven Stage Loader
  Reads config from ETL_CONFIG, creates ID table, MERGE by SCD type
=============================================================================*/

CREATE OR REPLACE PROCEDURE IP_DATAENGINEERING.METADATA.SP_LOAD_STAGE(P_STAGE_TABLE_NAME VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
    LET v_source_sql       VARCHAR;
    LET v_pk_columns       VARCHAR;
    LET v_scd_type         NUMBER;
    LET v_id_table_fq      VARCHAR;
    LET v_stage_table_fq   VARCHAR;
    LET v_id_table_name    VARCHAR;
    LET v_col_list         VARCHAR DEFAULT '';
    LET v_update_set       VARCHAR DEFAULT '';
    LET v_on_clause        VARCHAR DEFAULT '';
    LET v_change_detect    VARCHAR DEFAULT '';
    LET v_col_name         VARCHAR;
    LET v_result           VARCHAR DEFAULT '';
    LET v_src_vals         VARCHAR DEFAULT '';
    LET v_is_pk            NUMBER;

    -- Pre-compute names
    v_id_table_name  := P_STAGE_TABLE_NAME || '_ID';
    v_id_table_fq    := 'IP_DATAENGINEERING.STAGE.' || :v_id_table_name;
    v_stage_table_fq := 'IP_DATAENGINEERING.STAGE.' || P_STAGE_TABLE_NAME;

    -- STEP 1: Read config from METADATA.ETL_CONFIG
    SELECT SOURCE_SQL, PRIMARY_KEY_COLUMNS, SCD_TYPE
      INTO :v_source_sql, :v_pk_columns, :v_scd_type
      FROM IP_DATAENGINEERING.METADATA.ETL_CONFIG
     WHERE STAGE_TABLE_NAME = :P_STAGE_TABLE_NAME
       AND IS_ACTIVE = TRUE;

    -- STEP 2: Create ID table by running the source SQL
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TABLE ' || :v_id_table_fq || ' AS ' || :v_source_sql;
    v_result := 'ID table created. ';

    -- Parse PK columns into temp table (workaround: SPLIT_TO_TABLE doesn't accept bind vars in cursors)
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TEMPORARY TABLE IP_DATAENGINEERING.STAGE._TMP_PK_COLS AS SELECT TRIM(VALUE) AS PK_COL FROM TABLE(SPLIT_TO_TABLE(''' || :v_pk_columns || ''', ''|''))';

    -- Build ON clause from PK columns
    LET pk_cursor CURSOR FOR
        SELECT PK_COL FROM IP_DATAENGINEERING.STAGE._TMP_PK_COLS;
    FOR pk_rec IN pk_cursor DO
        IF (v_on_clause != '') THEN
            v_on_clause := :v_on_clause || ' AND ';
        END IF;
        v_on_clause := :v_on_clause || 'TGT.' || pk_rec.PK_COL || ' = SRC.' || pk_rec.PK_COL;
    END FOR;

    -- Build column metadata into temp table (avoids bind var issues with INFORMATION_SCHEMA cursors)
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TEMPORARY TABLE IP_DATAENGINEERING.STAGE._TMP_COL_META AS
        SELECT C.COLUMN_NAME, C.ORDINAL_POSITION, CASE WHEN P.PK_COL IS NOT NULL THEN 1 ELSE 0 END AS IS_PK
        FROM IP_DATAENGINEERING.INFORMATION_SCHEMA.COLUMNS C
        LEFT JOIN IP_DATAENGINEERING.STAGE._TMP_PK_COLS P ON C.COLUMN_NAME = P.PK_COL
        WHERE C.TABLE_SCHEMA = ''STAGE'' AND C.TABLE_NAME = ''' || :v_id_table_name || '''
        ORDER BY C.ORDINAL_POSITION';

    -- Build column lists, update sets, and change detection expressions
    LET col_cursor2 CURSOR FOR
        SELECT COLUMN_NAME, IS_PK FROM IP_DATAENGINEERING.STAGE._TMP_COL_META ORDER BY ORDINAL_POSITION;

    FOR col_rec IN col_cursor2 DO
        v_col_name := col_rec.COLUMN_NAME;
        v_is_pk    := col_rec.IS_PK;

        IF (v_col_list != '') THEN
            v_col_list := :v_col_list || ', ';
            v_src_vals := :v_src_vals || ', ';
        END IF;
        v_col_list := :v_col_list || :v_col_name;
        v_src_vals := :v_src_vals || 'SRC.' || :v_col_name;

        -- Non-PK columns: build UPDATE SET and change detection
        IF (v_is_pk = 0) THEN
            IF (v_update_set != '') THEN
                v_update_set    := :v_update_set || ', ';
                v_change_detect := :v_change_detect || ' OR ';
            END IF;
            v_update_set    := :v_update_set || 'TGT.' || :v_col_name || ' = SRC.' || :v_col_name;
            v_change_detect := :v_change_detect ||
                'NVL(CAST(TGT.' || :v_col_name || ' AS VARCHAR), ''~~NULL~~'') != NVL(CAST(SRC.' || :v_col_name || ' AS VARCHAR), ''~~NULL~~'')';
        END IF;
    END FOR;

    -- STEP 3: MERGE based on SCD type
    IF (v_scd_type = 1) THEN
        -----------------------------------------------------------
        -- SCD TYPE 1: Simple UPSERT (overwrite changed rows)
        -----------------------------------------------------------
        LET v_ins_cols VARCHAR;
        LET v_ins_vals VARCHAR;
        v_ins_cols := :v_col_list || ', DW_INSERT_DTS, DW_UPDATE_DTS';
        v_ins_vals := :v_src_vals || ', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()';

        LET v_sql VARCHAR;
        v_sql := 'MERGE INTO ' || :v_stage_table_fq || ' TGT USING ' || :v_id_table_fq || ' SRC ON (' || :v_on_clause || ') WHEN MATCHED AND (' || :v_change_detect || ') THEN UPDATE SET ' || :v_update_set || ', TGT.DW_UPDATE_DTS = CURRENT_TIMESTAMP() WHEN NOT MATCHED THEN INSERT (' || :v_ins_cols || ') VALUES (' || :v_ins_vals || ')';
        EXECUTE IMMEDIATE :v_sql;
        v_result := :v_result || 'SCD Type 1 MERGE completed.';

    ELSEIF (v_scd_type = 2) THEN
        -----------------------------------------------------------
        -- SCD TYPE 2: Expire old version + Insert new version
        -----------------------------------------------------------

        -- Step A: Expire changed rows (set active flag to N, end date to now)
        LET v_sql2 VARCHAR;
        v_sql2 := 'UPDATE ' || :v_stage_table_fq || ' TGT SET TGT.DW_ACTIVE_FLAG = ''N'', TGT.DW_END_DTS = CURRENT_TIMESTAMP(), TGT.DW_UPDATE_DTS = CURRENT_TIMESTAMP() FROM ' || :v_id_table_fq || ' SRC WHERE ' || :v_on_clause || ' AND TGT.DW_ACTIVE_FLAG = ''Y'' AND (' || :v_change_detect || ')';
        EXECUTE IMMEDIATE :v_sql2;

        -- Step B: Insert new active rows for changed + new records
        LET v_ins_cols2 VARCHAR;
        LET v_ins_vals2 VARCHAR;
        v_ins_cols2 := :v_col_list || ', DW_INSERT_DTS, DW_UPDATE_DTS, DW_ACTIVE_FLAG, DW_START_DTS, DW_END_DTS';
        v_ins_vals2 := :v_src_vals || ', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), ''Y'', CURRENT_TIMESTAMP(), ''9999-12-31 00:00:00''::TIMESTAMP_NTZ';

        LET v_sql3 VARCHAR;
        v_sql3 := 'INSERT INTO ' || :v_stage_table_fq || ' (' || :v_ins_cols2 || ') SELECT ' || :v_ins_vals2 || ' FROM ' || :v_id_table_fq || ' SRC WHERE NOT EXISTS (SELECT 1 FROM ' || :v_stage_table_fq || ' TGT WHERE ' || :v_on_clause || ' AND TGT.DW_ACTIVE_FLAG = ''Y'')';
        EXECUTE IMMEDIATE :v_sql3;
        v_result := :v_result || 'SCD Type 2 completed.';
    ELSE
        v_result := 'ERROR: Unsupported SCD_TYPE=' || :v_scd_type;
    END IF;

    -- STEP 4: Cleanup intermediate tables
    EXECUTE IMMEDIATE 'DROP TABLE IF EXISTS ' || :v_id_table_fq;
    EXECUTE IMMEDIATE 'DROP TABLE IF EXISTS IP_DATAENGINEERING.STAGE._TMP_PK_COLS';
    EXECUTE IMMEDIATE 'DROP TABLE IF EXISTS IP_DATAENGINEERING.STAGE._TMP_COL_META';
    v_result := :v_result || ' ID table dropped.';

    RETURN :v_result;
END;
$$;
