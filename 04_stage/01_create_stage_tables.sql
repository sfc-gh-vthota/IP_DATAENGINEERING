/*=============================================================================
  STAGE Layer - Target Tables
  Business columns + DW metadata columns for SCD tracking
=============================================================================*/

USE SCHEMA IP_DATAENGINEERING.STAGE;

----------------------------------------------------------------------
-- STG_SERVER_SUMMARY (SCD Type 1 - Overwrite)
----------------------------------------------------------------------
CREATE OR REPLACE TABLE STG_SERVER_SUMMARY (
    SERVER_ID           VARCHAR(20),
    SERVER_NAME         VARCHAR(100),
    SERVER_TYPE         VARCHAR(20),
    OS_NAME             VARCHAR(50),
    OS_VERSION          VARCHAR(20),
    CPU_CORES           NUMBER,
    RAM_GB              NUMBER,
    STORAGE_TB          NUMBER,
    IP_ADDRESS          VARCHAR(15),
    SERVER_STATUS       VARCHAR(20),
    ENVIRONMENT         VARCHAR(20),
    OWNER_TEAM          VARCHAR(50),
    PROVISIONED_DATE    DATE,
    DC_NAME             VARCHAR(100),
    DC_LOCATION         VARCHAR(200),
    DC_REGION           VARCHAR(50),
    DC_TIER             VARCHAR(10),
    DW_INSERT_DTS       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_UPDATE_DTS       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

----------------------------------------------------------------------
-- STG_DC_DEVICE_SUMMARY (SCD Type 2 - Composite PK: DC_ID + DEVICE_TYPE)
----------------------------------------------------------------------
CREATE OR REPLACE TABLE STG_DC_DEVICE_SUMMARY (
    DC_ID               VARCHAR(10),
    DEVICE_TYPE         VARCHAR(30),
    DC_NAME             VARCHAR(100),
    DC_REGION           VARCHAR(50),
    DC_TIER             VARCHAR(10),
    DEVICE_COUNT        NUMBER,
    TOTAL_THROUGHPUT_GBPS NUMBER,
    ONLINE_COUNT        NUMBER,
    OFFLINE_COUNT       NUMBER,
    AVG_PORT_COUNT      NUMBER,
    DW_INSERT_DTS       TIMESTAMP_NTZ,
    DW_UPDATE_DTS       TIMESTAMP_NTZ,
    DW_ACTIVE_FLAG      VARCHAR(1),
    DW_START_DTS        TIMESTAMP_NTZ,
    DW_END_DTS          TIMESTAMP_NTZ
);

----------------------------------------------------------------------
-- STG_INFRA_ASSETS (SCD Type 2 - History Tracking)
----------------------------------------------------------------------
CREATE OR REPLACE TABLE STG_INFRA_ASSETS (
    DEVICE_ID           VARCHAR(20),
    DEVICE_NAME         VARCHAR(100),
    DEVICE_TYPE         VARCHAR(30),
    MANUFACTURER        VARCHAR(50),
    MODEL               VARCHAR(50),
    FIRMWARE_VER        VARCHAR(20),
    IP_ADDRESS          VARCHAR(15),
    PORT_COUNT          NUMBER,
    THROUGHPUT_GBPS     NUMBER,
    DEVICE_STATUS       VARCHAR(20),
    INSTALL_DATE        DATE,
    LAST_PATCHED        DATE,
    DC_NAME             VARCHAR(100),
    DC_REGION           VARCHAR(50),
    DC_TIER             VARCHAR(10),
    DW_INSERT_DTS       TIMESTAMP_NTZ,
    DW_UPDATE_DTS       TIMESTAMP_NTZ,
    DW_ACTIVE_FLAG      VARCHAR(1),
    DW_START_DTS        TIMESTAMP_NTZ,
    DW_END_DTS          TIMESTAMP_NTZ
);

----------------------------------------------------------------------
-- STG_INCIDENT_DETAIL (SCD Type 1 - Overwrite)
----------------------------------------------------------------------
CREATE OR REPLACE TABLE STG_INCIDENT_DETAIL (
    INCIDENT_ID             VARCHAR(20),
    INCIDENT_TITLE          VARCHAR(300),
    SEVERITY                VARCHAR(10),
    INCIDENT_STATUS         VARCHAR(20),
    CREATED_DATE            TIMESTAMP_NTZ,
    RESOLVED_DATE           TIMESTAMP_NTZ,
    ROOT_CAUSE              VARCHAR(500),
    ASSIGNED_TEAM           VARCHAR(50),
    RESOLUTION_TIME_HOURS   NUMBER(10,2),
    SERVER_NAME             VARCHAR(100),
    SERVER_ENVIRONMENT      VARCHAR(20),
    SERVER_OWNER_TEAM       VARCHAR(50),
    APP_NAME                VARCHAR(100),
    BUSINESS_UNIT           VARCHAR(50),
    APP_CRITICALITY         VARCHAR(20),
    DW_INSERT_DTS           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_UPDATE_DTS           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

----------------------------------------------------------------------
-- STG_APP_SERVER_MAP (SCD Type 1 - Composite PK: APP_ID + SERVER_ID)
----------------------------------------------------------------------
CREATE OR REPLACE TABLE STG_APP_SERVER_MAP (
    APP_ID              VARCHAR(20),
    SERVER_ID           VARCHAR(20),
    APP_NAME            VARCHAR(100),
    APP_TYPE            VARCHAR(30),
    CRITICALITY         VARCHAR(20),
    BUSINESS_UNIT       VARCHAR(50),
    SERVER_NAME         VARCHAR(100),
    SERVER_TYPE         VARCHAR(20),
    ENVIRONMENT         VARCHAR(20),
    SERVER_STATUS       VARCHAR(20),
    DC_NAME             VARCHAR(100),
    DC_REGION           VARCHAR(50),
    DW_INSERT_DTS       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_UPDATE_DTS       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
