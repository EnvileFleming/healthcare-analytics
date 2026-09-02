-- this segment Verify that the raw CSV data was successfully loaded into the staging table before we begin the ETL process.

-- CSV was imported manually through DataGrip which goes to stg_covid_raw table. This script is to validate the import.
SELECT COUNT(*) AS total_records
FROM stg_covid_raw;

-- Preview imported records
SELECT *
FROM stg_covid_raw
LIMIT 10;

-- Validate date range
SELECT
    MIN(report_date) AS earliest_date,
    MAX(report_date) AS latest_date
FROM stg_covid_raw;

-- Check number of distinct entities
SELECT COUNT(DISTINCT entity) AS total_entities
FROM stg_covid_raw;
