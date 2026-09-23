/*=============================================================================
  RAW Layer - Synthetic Data Load
  JPMC IP team infrastructure data (servers, DCs, network, apps, incidents)
=============================================================================*/

USE SCHEMA IP_DATAENGINEERING.RAW;

----------------------------------------------------------------------
-- DATA_CENTERS (8 rows)
----------------------------------------------------------------------
INSERT INTO DATA_CENTERS VALUES
('DC001', 'JPMC-NYC-PRIMARY',   '383 Madison Ave, New York, NY',      'US-EAST',    'TIER-4', 5000, 4200, 'ACTIVE',  'dc-ops-nyc@jpmc.com'),
('DC002', 'JPMC-NYC-SECONDARY', '270 Park Ave, New York, NY',         'US-EAST',    'TIER-3', 3000, 2100, 'ACTIVE',  'dc-ops-nyc@jpmc.com'),
('DC003', 'JPMC-DEL-PRIMARY',   '500 Stanton Christiana, Newark, DE', 'US-EAST',    'TIER-4', 4000, 3500, 'ACTIVE',  'dc-ops-del@jpmc.com'),
('DC004', 'JPMC-TX-PRIMARY',    '2200 Ross Ave, Dallas, TX',          'US-CENTRAL', 'TIER-3', 3500, 2800, 'ACTIVE',  'dc-ops-tx@jpmc.com'),
('DC005', 'JPMC-TX-DR',         '14221 Dallas Pkwy, Dallas, TX',      'US-CENTRAL', 'TIER-3', 2000, 800,  'STANDBY', 'dc-ops-tx@jpmc.com'),
('DC006', 'JPMC-LON-PRIMARY',   '25 Bank St, Canary Wharf, London',   'EU-WEST',    'TIER-4', 3000, 2600, 'ACTIVE',  'dc-ops-lon@jpmc.co.uk'),
('DC007', 'JPMC-SG-PRIMARY',    '168 Robinson Rd, Singapore',         'APAC',       'TIER-3', 2000, 1500, 'ACTIVE',  'dc-ops-sg@jpmc.com'),
('DC008', 'JPMC-MUM-PRIMARY',   'BKC Complex, Mumbai, India',         'APAC',       'TIER-3', 1500, 1100, 'ACTIVE',  'dc-ops-mum@jpmc.com');

----------------------------------------------------------------------
-- SERVERS (50 rows)
----------------------------------------------------------------------
INSERT INTO SERVERS
SELECT
    'SRV-' || LPAD(SEQ4()::VARCHAR, 4, '0'),
    'JPMC-SRV-' || CASE MOD(SEQ4(), 4) WHEN 0 THEN 'PROD' WHEN 1 THEN 'UAT' WHEN 2 THEN 'DEV' ELSE 'QA' END || '-' || LPAD(SEQ4()::VARCHAR, 3, '0'),
    'DC' || LPAD((MOD(SEQ4(), 8) + 1)::VARCHAR, 3, '0'),
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'PHYSICAL' WHEN 1 THEN 'VIRTUAL' WHEN 2 THEN 'VIRTUAL' WHEN 3 THEN 'CONTAINER' ELSE 'CLOUD-VM' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'RHEL' WHEN 1 THEN 'WINDOWS-SERVER' WHEN 2 THEN 'UBUNTU' ELSE 'CENTOS' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN '8.6' WHEN 1 THEN '2019' WHEN 2 THEN '22.04' ELSE '7.9' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 32 WHEN 1 THEN 16 WHEN 2 THEN 8 ELSE 64 END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 128 WHEN 1 THEN 64 WHEN 2 THEN 32 ELSE 256 END,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 2 WHEN 1 THEN 4 ELSE 8 END,
    '10.' || MOD(SEQ4(), 255) || '.' || MOD(SEQ4()*7, 255) || '.' || MOD(SEQ4()*13+1, 254),
    CASE MOD(SEQ4(), 10) WHEN 9 THEN 'DECOMMISSIONED' WHEN 8 THEN 'MAINTENANCE' ELSE 'RUNNING' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'PRODUCTION' WHEN 1 THEN 'UAT' WHEN 2 THEN 'DEVELOPMENT' ELSE 'QA' END,
    CASE MOD(SEQ4(), 6) WHEN 0 THEN 'TRADE-PLATFORM' WHEN 1 THEN 'RISK-ENGINE' WHEN 2 THEN 'DATA-ANALYTICS' WHEN 3 THEN 'CORE-BANKING' WHEN 4 THEN 'PAYMENTS' ELSE 'COMPLIANCE' END,
    DATEADD(DAY, -MOD(SEQ4()*37, 1800), CURRENT_DATE())
FROM TABLE(GENERATOR(ROWCOUNT => 50));

----------------------------------------------------------------------
-- NETWORK_DEVICES (40 rows)
----------------------------------------------------------------------
INSERT INTO NETWORK_DEVICES
SELECT
    'NET-' || LPAD(SEQ4()::VARCHAR, 4, '0'),
    'JPMC-' || CASE MOD(SEQ4(), 4) WHEN 0 THEN 'RTR' WHEN 1 THEN 'SW' WHEN 2 THEN 'FW' ELSE 'LB' END || '-' || LPAD(SEQ4()::VARCHAR, 3, '0'),
    'DC' || LPAD((MOD(SEQ4(), 8) + 1)::VARCHAR, 3, '0'),
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'ROUTER' WHEN 1 THEN 'SWITCH' WHEN 2 THEN 'FIREWALL' ELSE 'LOAD-BALANCER' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'CISCO' WHEN 1 THEN 'JUNIPER' WHEN 2 THEN 'PALO-ALTO' ELSE 'F5' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'ASR-9000' WHEN 1 THEN 'QFX-5200' WHEN 2 THEN 'PA-5260' ELSE 'BIG-IP-I5800' END,
    'v' || (MOD(SEQ4(), 5) + 7) || '.' || MOD(SEQ4(), 10) || '.' || MOD(SEQ4()*3, 20),
    '10.' || (MOD(SEQ4(), 10)+100) || '.' || MOD(SEQ4()*3, 255) || '.' || MOD(SEQ4()*11+1, 254),
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 48 WHEN 1 THEN 96 WHEN 2 THEN 24 ELSE 16 END,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 10 WHEN 1 THEN 40 ELSE 100 END,
    CASE MOD(SEQ4(), 12) WHEN 11 THEN 'OFFLINE' WHEN 10 THEN 'DEGRADED' ELSE 'ONLINE' END,
    DATEADD(DAY, -MOD(SEQ4()*41, 2000), CURRENT_DATE()),
    DATEADD(DAY, -MOD(SEQ4()*7, 90), CURRENT_DATE())
FROM TABLE(GENERATOR(ROWCOUNT => 40));

----------------------------------------------------------------------
-- APPLICATIONS (30 rows)
----------------------------------------------------------------------
INSERT INTO APPLICATIONS
SELECT
    'APP-' || LPAD(SEQ4()::VARCHAR, 4, '0'),
    CASE MOD(SEQ4(), 10) WHEN 0 THEN 'JPMC-TRADE-ENGINE' WHEN 1 THEN 'JPMC-RISK-CALC' WHEN 2 THEN 'JPMC-PAYMENTS-GW' WHEN 3 THEN 'JPMC-CLIENT-PORTAL' WHEN 4 THEN 'JPMC-FRAUD-DETECT' WHEN 5 THEN 'JPMC-AML-MONITOR' WHEN 6 THEN 'JPMC-DATA-LAKE' WHEN 7 THEN 'JPMC-AUTH-SERVICE' WHEN 8 THEN 'JPMC-REPORT-ENGINE' ELSE 'JPMC-API-GATEWAY' END || '-' || LPAD(SEQ4()::VARCHAR, 2, '0'),
    CASE MOD(SEQ4(), 10) WHEN 0 THEN 'Real-time trade execution and order management' WHEN 1 THEN 'Market risk calculation engine for portfolio analysis' WHEN 2 THEN 'Payment processing gateway for wire and ACH transfers' WHEN 3 THEN 'Client-facing investment management portal' WHEN 4 THEN 'Real-time fraud detection and alerting system' WHEN 5 THEN 'Anti-money laundering transaction monitoring' WHEN 6 THEN 'Centralized data lake for analytics and reporting' WHEN 7 THEN 'Authentication and authorization microservice' WHEN 8 THEN 'Regulatory and management reporting engine' ELSE 'Enterprise API gateway for service mesh' END,
    'SRV-' || LPAD((MOD(SEQ4(), 50))::VARCHAR, 4, '0'),
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'WEB-APP' WHEN 1 THEN 'MICROSERVICE' WHEN 2 THEN 'BATCH-JOB' WHEN 3 THEN 'API' ELSE 'DATABASE' END,
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'JAVA/SPRING-BOOT' WHEN 1 THEN 'PYTHON/FLASK' WHEN 2 THEN 'SCALA/SPARK' WHEN 3 THEN 'NODE.JS/EXPRESS' ELSE 'ORACLE/PLSQL' END,
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'INVESTMENT-BANKING' WHEN 1 THEN 'RISK-MANAGEMENT' WHEN 2 THEN 'CORPORATE-TREASURY' WHEN 3 THEN 'RETAIL-BANKING' ELSE 'COMPLIANCE' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'CRITICAL' WHEN 1 THEN 'HIGH' WHEN 2 THEN 'MEDIUM' ELSE 'LOW' END,
    CASE MOD(SEQ4(), 8) WHEN 7 THEN 'RETIRED' WHEN 6 THEN 'MAINTENANCE' ELSE 'ACTIVE' END,
    DATEADD(DAY, -MOD(SEQ4()*29, 2500), CURRENT_DATE()),
    CASE MOD(SEQ4(), 6) WHEN 0 THEN 'Raj Patel' WHEN 1 THEN 'Sarah Chen' WHEN 2 THEN 'Michael Torres' WHEN 3 THEN 'Priya Sharma' WHEN 4 THEN 'James Wilson' ELSE 'Aisha Khan' END
FROM TABLE(GENERATOR(ROWCOUNT => 30));

----------------------------------------------------------------------
-- INCIDENTS (100 rows)
----------------------------------------------------------------------
INSERT INTO INCIDENTS
SELECT
    'INC-' || LPAD(SEQ4()::VARCHAR, 5, '0'),
    CASE MOD(SEQ4(), 10) WHEN 0 THEN 'High CPU utilization on production server' WHEN 1 THEN 'Memory leak detected in application service' WHEN 2 THEN 'Network latency spike affecting trade execution' WHEN 3 THEN 'Disk space critical threshold breached' WHEN 4 THEN 'SSL certificate expiration warning' WHEN 5 THEN 'Database connection pool exhausted' WHEN 6 THEN 'Firewall rule blocking legitimate traffic' WHEN 7 THEN 'Load balancer health check failures' WHEN 8 THEN 'Backup job failure for critical database' ELSE 'Unauthorized access attempt detected' END,
    'SRV-' || LPAD(MOD(SEQ4(), 50)::VARCHAR, 4, '0'),
    'APP-' || LPAD(MOD(SEQ4(), 30)::VARCHAR, 4, '0'),
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'P1' WHEN 1 THEN 'P2' WHEN 2 THEN 'P3' ELSE 'P4' END,
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'OPEN' WHEN 1 THEN 'IN-PROGRESS' WHEN 2 THEN 'RESOLVED' WHEN 3 THEN 'RESOLVED' ELSE 'CLOSED' END,
    DATEADD(MINUTE, -MOD(SEQ4()*1439, 525600), CURRENT_TIMESTAMP()),
    CASE WHEN MOD(SEQ4(), 5) IN (2,3,4) THEN DATEADD(HOUR, MOD(SEQ4()*3+1, 72), DATEADD(MINUTE, -MOD(SEQ4()*1439, 525600), CURRENT_TIMESTAMP())) ELSE NULL END,
    CASE MOD(SEQ4(), 8) WHEN 0 THEN 'Hardware failure - replaced component' WHEN 1 THEN 'Software bug - patched in latest release' WHEN 2 THEN 'Configuration drift - restored from baseline' WHEN 3 THEN 'Capacity exceeded - scaled resources' WHEN 4 THEN 'Security policy update required' WHEN 5 THEN 'Third-party service outage' WHEN 6 THEN 'DNS resolution failure' ELSE 'Scheduled maintenance window overlap' END,
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'INFRA-OPS' WHEN 1 THEN 'NETWORK-OPS' WHEN 2 THEN 'APP-SUPPORT' WHEN 3 THEN 'DBA-TEAM' ELSE 'SECURITY-OPS' END,
    CASE WHEN MOD(SEQ4(), 5) IN (2,3,4) THEN ROUND(MOD(SEQ4()*3+1, 72) + UNIFORM(0.1, 5.0, RANDOM()), 2) ELSE NULL END
FROM TABLE(GENERATOR(ROWCOUNT => 100));
