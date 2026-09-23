/*=============================================================================
  SP_RUN_ALL_STAGE_LOADS - Orchestrator
  Loops through all active ETL_CONFIG rows and calls SP_LOAD_STAGE for each
=============================================================================*/

CREATE OR REPLACE PROCEDURE IP_DATAENGINEERING.METADATA.SP_RUN_ALL_STAGE_LOADS()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
BEGIN
    LET v_table_name VARCHAR;
    LET v_result     VARCHAR DEFAULT '';
    LET v_call_result VARCHAR;

    LET config_cursor CURSOR FOR
        SELECT STAGE_TABLE_NAME
          FROM IP_DATAENGINEERING.METADATA.ETL_CONFIG
         WHERE IS_ACTIVE = TRUE
         ORDER BY CONFIG_ID;

    FOR config_rec IN config_cursor DO
        v_table_name := config_rec.STAGE_TABLE_NAME;
        CALL IP_DATAENGINEERING.METADATA.SP_LOAD_STAGE(:v_table_name) INTO :v_call_result;
        v_result := :v_result || :v_table_name || ' => ' || :v_call_result || ' | ';
    END FOR;

    RETURN :v_result;
END;
$$;
