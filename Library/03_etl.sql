-- SQL ETL Pipeline
-- PostgreSQL rerunnable load for the dimensional warehouse

BEGIN;

-- Load or update the country/entity dimension.
-- The source should ideally contain one code per entity.
INSERT INTO dim_country (
    country_name,
    country_code
)
SELECT DISTINCT ON (BTRIM(entity))
    BTRIM(entity),
    NULLIF(BTRIM(code), '')
FROM stg_covid_raw
WHERE NULLIF(BTRIM(entity), '') IS NOT NULL
ORDER BY
    BTRIM(entity),
    (NULLIF(BTRIM(code), '') IS NULL),
    NULLIF(BTRIM(code), '')
ON CONFLICT (country_name)
DO UPDATE SET
    country_code = COALESCE(
        dim_country.country_code,
        EXCLUDED.country_code
    );

-- Check entities without a source code.
SELECT
    COUNT(*) AS entities_without_country_code
FROM dim_country
WHERE country_code IS NULL;

-- Load or update the date dimension.
INSERT INTO dim_date (
    full_date,
    year,
    quarter,
    month,
    month_name,
    week,
    day,
    day_name
)
SELECT DISTINCT
    report_date,
    EXTRACT(YEAR FROM report_date)::INTEGER,
    EXTRACT(QUARTER FROM report_date)::INTEGER,
    EXTRACT(MONTH FROM report_date)::INTEGER,
    TRIM(TO_CHAR(report_date, 'Month')),
    EXTRACT(WEEK FROM report_date)::INTEGER,
    EXTRACT(DAY FROM report_date)::INTEGER,
    TRIM(TO_CHAR(report_date, 'Day'))
FROM stg_covid_raw
WHERE report_date IS NOT NULL
ON CONFLICT (full_date) DO NOTHING;

-- Load or update the fact table.
-- This expects one source row per entity and reporting date.
INSERT INTO fact_covid (
    country_id,
    date_id,
    total_cases,
    total_deaths
)
SELECT
    c.country_id,
    d.date_id,
    s.cumulative_cases,
    s.cumulative_deaths
FROM stg_covid_raw AS s
JOIN dim_country AS c
    ON c.country_name = BTRIM(s.entity)
JOIN dim_date AS d
    ON d.full_date = s.report_date
ON CONFLICT (country_id, date_id)
DO UPDATE SET
    total_cases = EXCLUDED.total_cases,
    total_deaths = EXCLUDED.total_deaths;

-- Derive daily cases and deaths from cumulative totals.
-- The first observation for each entity remains NULL because
-- there is no previous reporting date to compare against.
WITH calculated_metrics AS (
    SELECT
        covid_id,
        total_cases
            - LAG(total_cases) OVER (
                PARTITION BY country_id
                ORDER BY date_id
            ) AS calculated_daily_cases,
        total_deaths
            - LAG(total_deaths) OVER (
                PARTITION BY country_id
                ORDER BY date_id
            ) AS calculated_daily_deaths
    FROM fact_covid
)
UPDATE fact_covid AS f
SET
    daily_cases = cm.calculated_daily_cases,
    daily_deaths = cm.calculated_daily_deaths
FROM calculated_metrics AS cm
WHERE f.covid_id = cm.covid_id;

-- Classify each fact record for downstream analysis.
UPDATE fact_covid
SET data_quality_status =
    CASE
        WHEN total_cases IS NULL
          OR total_deaths IS NULL
            THEN 'INVALID_SOURCE_DATA'

        WHEN total_cases = 0
            THEN 'NO_CASES'

        WHEN total_deaths > total_cases
            THEN 'INVALID_SOURCE_DATA'

        ELSE 'VALID'
    END;

-- Calculate mortality rate only for valid records.
UPDATE fact_covid
SET mortality_rate =
    CASE
        WHEN data_quality_status = 'VALID'
            THEN ROUND(
                (
                    total_deaths::NUMERIC
                    / NULLIF(total_cases, 0)
                ) * 100,
                4
            )
        ELSE NULL
    END;

-- Review records excluded from mortality analysis.
SELECT
    COUNT(*) AS invalid_mortality_rate_records
FROM fact_covid
WHERE mortality_rate IS NULL
  AND data_quality_status <> 'NO_CASES';

-- Reusable view containing only valid mortality metrics.
CREATE OR REPLACE VIEW vw_valid_covid_metrics AS
SELECT
    country_id,
    date_id,
    total_cases,
    total_deaths,
    mortality_rate
FROM fact_covid
WHERE data_quality_status = 'VALID';

COMMIT;
