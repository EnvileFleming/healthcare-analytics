-- SQL ETL Pipeline

-- Load country dimension.
INSERT INTO dim_country
(
    country_name,
    country_code
)
SELECT DISTINCT
    entity,
    code
FROM stg_covid_raw
ORDER BY entity;

SELECT DISTINCT COUNT(*) AS total_countries
FROM dim_country
WHERE country_code IS NULL;

-- Load date dimension; This create reusable date attributes like year, quarter, month, week, and day.
INSERT INTO dim_date
(
    full_date, year, quarter, month,
    month_name, week, day, day_name
)
SELECT DISTINCT
    report_date,
    EXTRACT(YEAR FROM report_date)::INTEGER,
    EXTRACT(QUARTER FROM report_date)::INTEGER,
    EXTRACT(MONTH FROM report_date)::INTEGER,
    TO_CHAR(report_date,'Month'),
    EXTRACT(WEEK FROM report_date)::INTEGER,
    EXTRACT(DAY FROM report_date)::INTEGER,
    TO_CHAR(report_date,'Day')
FROM stg_covid_raw
ORDER BY report_date;

-- Load fact table.
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
FROM stg_covid_raw s
JOIN dim_country c
    ON s.entity = c.country_name
JOIN dim_date d
    ON s.report_date = d.full_date;

-- Derive daily cases from cumulative totals.
WITH daily_cases AS
(   SELECT
    covid_id,
    total_cases -
    LAG(total_cases)
    OVER(
        PARTITION BY country_id
        ORDER BY date_id
    ) AS new_cases
FROM fact_covid
)
UPDATE fact_covid f
SET daily_cases = COALESCE(d.new_cases,0)
FROM daily_cases d
WHERE f.covid_id = d.covid_id;

-- Derive daily deaths from cumulative totals.
WITH daily_deaths AS 
(   SELECT
    covid_id,
    total_deaths -
    LAG(total_deaths)
    OVER(
        PARTITION BY country_id
        ORDER BY date_id
    ) AS new_deaths
FROM fact_covid
)
UPDATE fact_covid f
SET daily_deaths = COALESCE(d.new_deaths,0)
FROM daily_deaths d
WHERE f.covid_id = d.covid_id;

-- Apply data quality rules to each fact record.
-- IS DISTINCT FROM updates only rows where the status
-- needs to be assigned or changed.
UPDATE fact_covid
SET data_quality_status =
    CASE
        WHEN total_cases IS NULL THEN 'INVALID_SOURCE_DATA'
        WHEN total_cases = 0 THEN 'NO_CASES'
        WHEN total_cases < total_deaths THEN 'INVALID_SOURCE_DATA'
        ELSE 'VALID'
    END
WHERE data_quality_status IS DISTINCT FROM
    CASE
        WHEN total_cases IS NULL THEN 'INVALID_SOURCE_DATA'
        WHEN total_cases = 0 THEN 'NO_CASES'
        WHEN total_cases < total_deaths THEN 'INVALID_SOURCE_DATA'
        ELSE 'VALID'
    END;

-- Calculate mortality rate only for valid records.

UPDATE fact_covid
SET mortality_rate = ROUND(
    (total_deaths::numeric / total_cases) * 100,
    4
)
WHERE data_quality_status = 'VALID';

-- Count records where mortality rate was not calculated
-- because the source data failed validation.

SELECT COUNT(*) AS invalid_mortality_rate_records
FROM fact_covid
WHERE mortality_rate IS NULL
  AND (
        total_cases IS NULL
        OR total_cases = 0
        OR total_deaths > total_cases
      );

-- Create a reusable view containing only records
-- with valid mortality calculations.

CREATE OR REPLACE VIEW vw_valid_covid_metrics AS
SELECT
    country_id,
    date_id,
    total_cases,
    total_deaths,
    mortality_rate
FROM fact_covid
WHERE data_quality_status = 'VALID';
