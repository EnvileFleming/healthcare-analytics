-- Reusable Reporting Views

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
        WHEN f.total_cases > 0
             AND f.total_cases >= f.total_deaths
        THEN ROUND((f.total_deaths::numeric / f.total_cases) * 100,4)
        ELSE NULL
    END AS mortality_rate
FROM fact_covid f
JOIN dim_country c
ON f.country_id = c.country_id
JOIN dim_date d
ON f.date_id = d.date_id;

-- Global Daily Summary
CREATE OR REPLACE VIEW vw_global_daily_summary AS
SELECT
    d.full_date,
    d.year,
    d.month,
    SUM(f.daily_cases) AS global_daily_cases,
    SUM(f.daily_deaths) AS global_daily_deaths,
    SUM(f.total_cases) AS cumulative_cases,
    SUM(f.total_deaths) AS cumulative_deaths
FROM fact_covid f
JOIN dim_date d
ON f.date_id = d.date_id
GROUP BY
    d.full_date,
    d.year,
    d.month
ORDER BY d.full_date;

-- Country Summary
CREATE OR REPLACE VIEW vw_country_summary AS
SELECT
    c.country_name,
    c.country_code,
    MAX(f.total_cases) AS total_cases,
    MAX(f.total_deaths) AS total_deaths,
    MAX(f.daily_cases) AS highest_daily_cases,
    MAX(f.daily_deaths) AS highest_daily_deaths
FROM fact_covid f
JOIN dim_country c
ON f.country_id = c.country_id
GROUP BY
    c.country_name,
    c.country_code;

-- Monthly Summary
CREATE OR REPLACE VIEW vw_monthly_summary AS
SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.daily_cases) AS monthly_cases,
    SUM(f.daily_deaths) AS monthly_deaths
FROM fact_covid f
JOIN dim_date d
ON f.date_id = d.date_id
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;

-- Top Countries
CREATE OR REPLACE VIEW vw_country_rankings AS
SELECT
    c.country_name,
    MAX(f.total_cases) AS total_cases,
    MAX(f.total_deaths) AS total_deaths,
    RANK() OVER(
        ORDER BY MAX(f.total_cases) DESC
    ) AS cases_rank,
    RANK() OVER(
        ORDER BY MAX(f.total_deaths) DESC
    ) AS deaths_rank
FROM fact_covid f
JOIN dim_country c
ON f.country_id = c.country_id
GROUP BY c.country_name;

-- VALIDATE THE CREATED VIEWS
SELECT * FROM vw_country_daily_metrics LIMIT 10;
SELECT * FROM vw_global_daily_summary LIMIT 10;
SELECT * FROM vw_country_summary LIMIT 10;
SELECT * FROM vw_monthly_summary LIMIT 10;
SELECT * FROM vw_country_rankings LIMIT 10;
