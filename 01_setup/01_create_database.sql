/*=============================================================================
  IP_DATAENGINEERING - Setup Script
  Creates the database, schemas, and warehouse
=============================================================================*/

USE ROLE SYSADMIN;

-- Database
CREATE DATABASE IF NOT EXISTS IP_DATAENGINEERING;

-- Schemas
CREATE SCHEMA IF NOT EXISTS IP_DATAENGINEERING.RAW;
CREATE SCHEMA IF NOT EXISTS IP_DATAENGINEERING.STAGE;
CREATE SCHEMA IF NOT EXISTS IP_DATAENGINEERING.METADATA;

-- Warehouse
CREATE WAREHOUSE IF NOT EXISTS IP_DE_WH
  WITH WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

USE DATABASE IP_DATAENGINEERING;
USE WAREHOUSE IP_DE_WH;
