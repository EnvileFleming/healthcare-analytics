-- SQL ETL Pipeline

-- Load country dimension.
INSERT INTO dim_country (country_name, country_code)
SELECT DISTINCT entity, code
FROM stg_covid_raw
ORDER BY entity;

-- Load date dimension.
INSERT INTO dim_date (
    full_date, year, quarter, month,
    month_name, week, day, day_name
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
WITH daily AS (
    SELECT
        f.covid_id,
        f.total_cases -
        LAG(f.total_cases) OVER (
            PARTITION BY f.country_id
            ORDER BY d.full_date
        ) AS new_cases
    FROM fact_covid f
    JOIN dim_date d ON f.date_id = d.date_id
)
UPDATE fact_covid f
SET daily_cases = COALESCE(d.new_cases, 0)
FROM daily d
WHERE f.covid_id = d.covid_id;

-- Derive daily deaths from cumulative totals.
WITH daily AS (
    SELECT
        f.covid_id,
        f.total_deaths -
        LAG(f.total_deaths) OVER (
            PARTITION BY f.country_id
            ORDER BY d.full_date
        ) AS new_deaths
    FROM fact_covid f
    JOIN dim_date d ON f.date_id = d.date_id
)
UPDATE fact_covid f
SET daily_deaths = COALESCE(d.new_deaths, 0)
FROM daily d
WHERE f.covid_id = d.covid_id;

-- Calculate mortality rate while excluding invalid source records.
UPDATE fact_covid
SET mortality_rate =
    CASE
        WHEN total_cases IS NULL
          OR total_cases = 0
          OR total_cases < total_deaths
        THEN NULL
        ELSE ROUND(
            (total_deaths::NUMERIC / total_cases) * 100,
            4
        )
    END;
