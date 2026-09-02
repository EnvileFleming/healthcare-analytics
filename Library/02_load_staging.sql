-- Staging Layer

-- The raw CSV is imported into stg_covid_raw.
-- Expected source column order:
-- Entity, Code, Day, Cumulative confirmed deaths,
-- Cumulative confirmed cases

-- In DataGrip, use Import Data from File and map:
-- Entity -> entity
-- Code -> code
-- Day -> report_date
-- Cumulative confirmed deaths -> cumulative_deaths
-- Cumulative confirmed cases -> cumulative_cases

-- Validate the staging load.
SELECT COUNT(*) AS staging_records
FROM stg_covid_raw;

SELECT *
FROM stg_covid_raw
LIMIT 10;

SELECT
    MIN(report_date) AS earliest_date,
    MAX(report_date) AS latest_date
FROM stg_covid_raw;
