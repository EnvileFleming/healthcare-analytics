-- Reusable PostgreSQL reporting views

-- Country Daily Metrics
CREATE OR REPLACE VIEW vw_country_daily_metrics AS
SELECT
    c.country_name,
    c.country_code,
    d.full_date,
    d.year,
    d.month,
    d.month_name,
    d.quarter,
    f.total_cases,
    f.total_deaths,
    f.daily_cases,
    f.daily_deaths,
    CASE
        WHEN f.data_quality_status = 'VALID'
            THEN f.mortality_rate
        ELSE NULL
    END AS mortality_rate,
    f.data_quality_status
FROM fact_covid AS f
JOIN dim_country AS c
    ON c.country_id = f.country_id
JOIN dim_date AS d
    ON d.date_id = f.date_id;

-- Global Daily Summary
-- Uses the dedicated World record to avoid double-counting
-- countries, regions, and other aggregate entities.
CREATE OR REPLACE VIEW vw_global_daily_summary AS
SELECT
    d.full_date,
    d.year,
    d.month,
    f.daily_cases AS global_daily_cases,
    f.daily_deaths AS global_daily_deaths,
    f.total_cases AS cumulative_cases,
    f.total_deaths AS cumulative_deaths
FROM fact_covid AS f
JOIN dim_country AS c
    ON c.country_id = f.country_id
JOIN dim_date AS d
    ON d.date_id = f.date_id
WHERE c.country_name = 'World';

-- Country Summary
-- Returns the latest cumulative totals and the highest
-- daily values recorded for each standard country.
CREATE OR REPLACE VIEW vw_country_summary AS
WITH country_metrics AS (
    SELECT
        c.country_id,
        c.country_name,
        c.country_code,
        d.full_date,
        f.total_cases,
        f.total_deaths,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_id
            ORDER BY d.full_date DESC, f.covid_id DESC
        ) AS latest_row,
        MAX(f.daily_cases) OVER (
            PARTITION BY c.country_id
        ) AS highest_daily_cases,
        MAX(f.daily_deaths) OVER (
            PARTITION BY c.country_id
        ) AS highest_daily_deaths
    FROM fact_covid AS f
    JOIN dim_country AS c
        ON c.country_id = f.country_id
    JOIN dim_date AS d
        ON d.date_id = f.date_id
    WHERE LENGTH(c.country_code) = 3
)
SELECT
    country_name,
    country_code,
    full_date AS latest_date,
    total_cases,
    total_deaths,
    highest_daily_cases,
    highest_daily_deaths
FROM country_metrics
WHERE latest_row = 1;

-- Monthly Global Summary
-- Uses World directly instead of summing all entities.
CREATE OR REPLACE VIEW vw_monthly_summary AS
SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.daily_cases) AS monthly_cases,
    SUM(f.daily_deaths) AS monthly_deaths
FROM fact_covid AS f
JOIN dim_country AS c
    ON c.country_id = f.country_id
JOIN dim_date AS d
    ON d.date_id = f.date_id
WHERE c.country_name = 'World'
GROUP BY
    d.year,
    d.month,
    d.month_name;

-- Latest Country Rankings
CREATE OR REPLACE VIEW vw_country_rankings AS
WITH latest_country_data AS (
    SELECT
        c.country_id,
        c.country_name,
        c.country_code,
        d.full_date,
        f.total_cases,
        f.total_deaths,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_id
            ORDER BY d.full_date DESC, f.covid_id DESC
        ) AS latest_row
    FROM fact_covid AS f
    JOIN dim_country AS c
        ON c.country_id = f.country_id
    JOIN dim_date AS d
        ON d.date_id = f.date_id
    WHERE LENGTH(c.country_code) = 3
),
latest_countries AS (
    SELECT
        country_name,
        country_code,
        full_date,
        total_cases,
        total_deaths
    FROM latest_country_data
    WHERE latest_row = 1
)
SELECT
    country_name,
    country_code,
    full_date AS latest_date,
    total_cases,
    total_deaths,
    RANK() OVER (
        ORDER BY total_cases DESC
    ) AS cases_rank,
    RANK() OVER (
        ORDER BY total_deaths DESC
    ) AS deaths_rank
FROM latest_countries;
