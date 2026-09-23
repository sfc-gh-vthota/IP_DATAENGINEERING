/*=============================================================================
  DEMO RUNNER SCRIPT
  Run these commands in order during a customer demo.
  Copy/paste each section into Snowsight or your SQL client.
=============================================================================*/

-- ==========================================================================
-- PART A: SET CONTEXT
-- ==========================================================================
USE DATABASE IP_DATAENGINEERING;
USE WAREHOUSE IP_DE_WH;

-- ==========================================================================
-- PART B: EXPLORE RAW LAYER
-- ==========================================================================
-- Show all objects
SELECT TABLE_SCHEMA, TABLE_NAME, ROW_COUNT
FROM IP_DATAENGINEERING.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('RAW', 'STAGE', 'METADATA')
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- Sample raw data
SELECT * FROM RAW.DATA_CENTERS;
SELECT * FROM RAW.SERVERS LIMIT 10;

-- ==========================================================================
-- PART C: SHOW METADATA CONTROL PLANE
-- ==========================================================================
SELECT STAGE_TABLE_NAME, PRIMARY_KEY_COLUMNS, SCD_TYPE, IS_ACTIVE
FROM METADATA.ETL_CONFIG;

-- Show the source SQL for one config
SELECT SOURCE_SQL FROM METADATA.ETL_CONFIG
WHERE STAGE_TABLE_NAME = 'STG_SERVER_SUMMARY';

-- ==========================================================================
-- PART D: FULL LOAD (FROM EMPTY)
-- ==========================================================================
-- Reset stage tables
TRUNCATE TABLE STAGE.STG_SERVER_SUMMARY;
TRUNCATE TABLE STAGE.STG_INFRA_ASSETS;
TRUNCATE TABLE STAGE.STG_INCIDENT_DETAIL;

-- Run all loads
CALL METADATA.SP_RUN_ALL_STAGE_LOADS();

-- Verify counts
SELECT 'STG_SERVER_SUMMARY' AS TBL, COUNT(*) AS CNT FROM STAGE.STG_SERVER_SUMMARY
UNION ALL SELECT 'STG_INFRA_ASSETS', COUNT(*) FROM STAGE.STG_INFRA_ASSETS
UNION ALL SELECT 'STG_INCIDENT_DETAIL', COUNT(*) FROM STAGE.STG_INCIDENT_DETAIL;

-- ==========================================================================
-- PART E: SCD TYPE 1 DEMO (Overwrite)
-- ==========================================================================
-- Before: check current state
SELECT SERVER_ID, SERVER_NAME, OS_NAME, OS_VERSION, RAM_GB,
       DW_INSERT_DTS, DW_UPDATE_DTS
FROM STAGE.STG_SERVER_SUMMARY
WHERE SERVER_ID = 'SRV-0010';

-- Simulate source change
UPDATE RAW.SERVERS SET OS_VERSION = '24.04', RAM_GB = 128
WHERE SERVER_ID = 'SRV-0010';

-- Reload
CALL METADATA.SP_LOAD_STAGE('STG_SERVER_SUMMARY');

-- After: verify overwrite (single row, DW_UPDATE_DTS changed)
SELECT SERVER_ID, SERVER_NAME, OS_NAME, OS_VERSION, RAM_GB,
       DW_INSERT_DTS, DW_UPDATE_DTS,
       CASE WHEN DW_UPDATE_DTS > DW_INSERT_DTS THEN '** UPDATED **' ELSE 'ORIGINAL' END AS STATUS
FROM STAGE.STG_SERVER_SUMMARY
WHERE SERVER_ID = 'SRV-0010';

-- ==========================================================================
-- PART F: SCD TYPE 2 DEMO (History Tracking)
-- ==========================================================================
-- Before: check current state
SELECT DEVICE_ID, DEVICE_NAME, FIRMWARE_VER, DEVICE_STATUS,
       DW_ACTIVE_FLAG, DW_START_DTS, DW_END_DTS
FROM STAGE.STG_INFRA_ASSETS
WHERE DEVICE_ID = 'NET-0015';

-- Simulate source change
UPDATE RAW.NETWORK_DEVICES
SET FIRMWARE_VER = 'v20.0.0', DEVICE_STATUS = 'MAINTENANCE'
WHERE DEVICE_ID = 'NET-0015';

-- Reload
CALL METADATA.SP_LOAD_STAGE('STG_INFRA_ASSETS');

-- After: verify history (old row expired, new active row)
SELECT DEVICE_ID, DEVICE_NAME, FIRMWARE_VER, DEVICE_STATUS,
       DW_ACTIVE_FLAG, DW_START_DTS, DW_END_DTS
FROM STAGE.STG_INFRA_ASSETS
WHERE DEVICE_ID = 'NET-0015'
ORDER BY DW_START_DTS;

-- ==========================================================================
-- PART G: IDEMPOTENCY CHECK
-- ==========================================================================
SELECT MAX(DW_UPDATE_DTS) AS BEFORE_TS FROM STAGE.STG_SERVER_SUMMARY;

CALL METADATA.SP_LOAD_STAGE('STG_SERVER_SUMMARY');

SELECT MAX(DW_UPDATE_DTS) AS AFTER_TS FROM STAGE.STG_SERVER_SUMMARY;
-- ^ These should be identical — no spurious updates
