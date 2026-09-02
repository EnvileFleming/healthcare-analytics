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

-- Implemented data quality rules to flag invalid records and excluded them from mortality rate calculations // ONLY VALID records to be updated
-- add a new column to the fact_covid table to store data quality status
ALTER TABLE fact_covid
ADD COLUMN data_quality_status VARCHAR(30);

-- validate data quality and update the new column based on the rules
UPDATE fact_covid
SET data_quality_status =
CASE
    WHEN total_cases = 0 THEN 'NO_CASES'
    WHEN total_cases < total_deaths THEN 'INVALID_SOURCE_DATA'
    ELSE 'VALID'
END;

-- update the mortality_rate column only for valid records
UPDATE fact_covid
SET mortality_rate = ROUND(
    (total_deaths::numeric / total_cases) * 100, 4)
WHERE data_quality_status = 'VALID';

-- Count invalid mortality rate records
SELECT COUNT(*) AS invalid_mortality_rate_records
FROM fact_covid
WHERE mortality_rate IS NULL
AND (total_cases IS NULL OR total_cases = 0 OR total_deaths > total_cases);

-- Calculate mortality rate while excluding invalid source records.
CREATE VIEW vw_valid_covid_metrics AS
SELECT
    country_id,
    date_id,
    total_cases,
    total_deaths,
    ROUND((total_deaths::numeric / total_cases) * 100, 4) AS mortality_rate
FROM fact_covid
WHERE total_cases > 0
  AND total_cases >= total_deaths;
