-- Power BI / Analytical Semantic Layer
-- Creates reusable reporting-ready views between the dimensional warehouse and Power BI.

-- Country Performance
-- Keeps one latest record per country for KPI analysis,
-- maps, tables, and country-level comparisons.

CREATE OR REPLACE VIEW vw_analytics_country_performance AS

WITH country_latest AS (
    SELECT
        c.country_name,
        c.country_code,
        d.full_date,
        f.total_cases,
        f.total_deaths,
        f.mortality_rate,
        f.data_quality_status,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_name
            ORDER BY d.full_date DESC) AS rn
    FROM fact_covid f
    JOIN dim_country c
        ON f.country_id = c.country_id
    JOIN dim_date d
        ON f.date_id = d.date_id
    WHERE LENGTH(c.country_code) = 3
)

SELECT
    country_name,
    country_code,
    full_date AS latest_date,
    total_cases,
    total_deaths,
    CASE
        WHEN data_quality_status = 'VALID'
        THEN mortality_rate
        ELSE NULL
    END AS mortality_rate,
    data_quality_status
FROM country_latest
WHERE rn = 1;

-- Global Trends
-- Uses the World entity directly instead of summing all countries and aggregate entities, which prevents double-counting.
-- Rolling averages smooth short-term daily fluctuations.

CREATE OR REPLACE VIEW vw_analytics_global_trends AS
  
SELECT
    d.full_date,
    f.daily_cases,
    f.daily_deaths,
    f.total_cases AS cumulative_cases,
    f.total_deaths AS cumulative_deaths,
    CASE
        WHEN f.data_quality_status = 'VALID'
        THEN f.mortality_rate
        ELSE NULL
    END AS mortality_rate,
    ROUND(
        AVG(f.daily_cases) OVER (
            ORDER BY d.full_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_7_day_cases,
    ROUND(
        AVG(f.daily_deaths) OVER (
            ORDER BY d.full_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_7_day_deaths
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE c.country_name = 'World';

-- Country Trends
-- Provides daily country-level metrics for Power BI
-- time-series charts, slicers, and drill-through analysis.
-- The 7-day averages make case and death trends easier to interpret.

CREATE OR REPLACE VIEW vw_analytics_country_trends AS

SELECT
    c.country_name,
    c.country_code,
    d.full_date,
    d.year,
    d.quarter,
    d.month,
    TRIM(d.month_name) AS month_name,
    f.total_cases,
    f.total_deaths,
    f.daily_cases,
    f.daily_deaths,
    CASE
        WHEN f.data_quality_status = 'VALID'
        THEN f.mortality_rate
        ELSE NULL
    END AS mortality_rate,
    f.data_quality_status,
    ROUND(
        AVG(f.daily_cases) OVER (
            PARTITION BY c.country_name
            ORDER BY d.full_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_7_day_cases,
    ROUND(
        AVG(f.daily_deaths) OVER (
            PARTITION BY c.country_name
            ORDER BY d.full_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_7_day_deaths
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE LENGTH(c.country_code) = 3;

-- Country Rankings
-- Keeps only the latest record for each country before ranking.
-- This avoids using MAX(), which represents the highest historical
-- value and is not always the same as the latest value.
--
-- Country case share is calculated against the latest World total
-- instead of summing country totals.

CREATE OR REPLACE VIEW vw_analytics_country_rankings AS

WITH latest_country_data AS (
    SELECT
        c.country_name,
        c.country_code,
        d.full_date,
        f.total_cases,
        f.total_deaths,
        f.mortality_rate,
        f.data_quality_status,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_name
            ORDER BY d.full_date DESC
        ) AS rn
    FROM fact_covid f
    JOIN dim_country c
        ON f.country_id = c.country_id
    JOIN dim_date d
        ON f.date_id = d.date_id
    WHERE LENGTH(c.country_code) = 3
),

latest_countries AS (
    SELECT
        country_name,
        country_code,
        full_date,
        total_cases,
        total_deaths,
        mortality_rate,
        data_quality_status
    FROM latest_country_data
    WHERE rn = 1
),

world_total AS (
    SELECT
        f.total_cases AS global_cases
    FROM fact_covid f
    JOIN dim_country c
        ON f.country_id = c.country_id
    JOIN dim_date d
        ON f.date_id = d.date_id
    WHERE c.country_name = 'World'
    ORDER BY d.full_date DESC
    LIMIT 1
)

SELECT
    lc.country_name,
    lc.country_code,
    lc.full_date AS latest_date,
    lc.total_cases,
    lc.total_deaths,
    CASE
        WHEN lc.data_quality_status = 'VALID'
        THEN lc.mortality_rate
        ELSE NULL
    END AS mortality_rate,
    RANK() OVER (
        ORDER BY lc.total_cases DESC) AS cases_rank,
    RANK() OVER (
        ORDER BY lc.total_deaths DESC) AS deaths_rank,
    CASE
        WHEN lc.data_quality_status = 'VALID'
        THEN RANK() OVER (
            ORDER BY lc.mortality_rate DESC NULLS LAST)
        ELSE NULL
    END AS mortality_rank,
    ROUND(
        (lc.total_cases::numeric
            / NULLIF(w.global_cases, 0)) * 100, 2) AS global_case_share
FROM latest_countries lc
CROSS JOIN world_total w;

-- Test Analytical Views

SELECT *
FROM vw_analytics_country_performance
LIMIT 10;

SELECT *
FROM vw_analytics_global_trends
LIMIT 10;

SELECT *
FROM vw_analytics_country_trends
LIMIT 10;

SELECT *
FROM vw_analytics_country_rankings
LIMIT 10;
