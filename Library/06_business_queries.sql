-- Executive KPIs
-- What are the latest global COVID statistics?
SELECT
    SUM(total_cases) AS total_cases,
    SUM(total_deaths) AS total_deaths
FROM fact_covid f
JOIN dim_date d
ON f.date_id = d.date_id
WHERE d.full_date = (
    SELECT MAX(full_date)
    FROM dim_date
);

-- Which countries have the highest cumulative cases?
SELECT
    c.country_name,
    MAX(f.total_cases) AS total_cases
FROM fact_covid f
JOIN dim_country c
ON f.country_id = c.country_id
WHERE country_code IS NOT NULL
GROUP BY c.country_name
ORDER BY total_cases DESC
LIMIT 10;

-- Which countries have the highest cumulative deaths
SELECT
    c.country_name,
    MAX(f.total_deaths) AS total_deaths
FROM fact_covid f
JOIN dim_country c
ON f.country_id = c.country_id

GROUP BY c.country_name
ORDER BY total_deaths DESC
LIMIT 10;

-- What is the latest reporting date?
SELECT MAX(full_date)
FROM dim_date;

-- How many countries are monitored
SELECT COUNT(*)
FROM dim_country;

-- Country Analysis
-- Which country had the highest single-day increase in cases?
SELECT
    c.country_name,
    d.full_date,
    f.daily_cases
FROM fact_covid f
JOIN dim_country c
ON f.country_id = c.country_id
JOIN dim_date d
ON f.date_id = d.date_id
ORDER BY f.daily_cases DESC
LIMIT 10
OFFSET 20;

-- Which country had the highest single-day increase in deaths?
SELECT
    c.country_name,
    d.full_date,
    f.daily_deaths
FROM fact_covid f
JOIN dim_country c
ON f.country_id = c.country_id
JOIN dim_date d
ON f.date_id = d.date_id
ORDER BY daily_deaths DESC
LIMIT 10;

-- Countries with the highest mortality rate
SELECT
    c.country_name,
    MAX(
        ROUND(
            total_deaths::numeric
            / NULLIF(total_cases,0)
            *100,2)
    ) AS mortality_rate
FROM fact_covid f
JOIN dim_country c
ON f.country_id=c.country_id
WHERE total_cases>=total_deaths
GROUP BY c.country_name
ORDER BY mortality_rate DESC
LIMIT 10;

-- Time Analysis
-- Monthly new cases
SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.daily_cases) AS monthly_cases
FROM fact_covid f
JOIN dim_date d
ON f.date_id=d.date_id
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;

-- Monthly new deaths
SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.daily_deaths) AS monthly_deaths
FROM fact_covid f
JOIN dim_date d
ON f.date_id=d.date_id
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;

-- Running total of global cases
SELECT
    full_date,
    SUM(vw_global_daily_summary.global_daily_cases) AS daily_cases,
    SUM(SUM(vw_global_daily_summary.global_daily_cases))
    OVER(ORDER BY full_date) AS running_cases
FROM vw_global_daily_summary
GROUP BY full_date
ORDER BY full_date;

-- 7-Day Moving Average
SELECT
    country_name,
    full_date,
    daily_cases,
    ROUND(
        AVG(daily_cases)
        OVER(
            PARTITION BY country_name
            ORDER BY full_date
            ROWS BETWEEN 6 PRECEDING
            AND CURRENT ROW), 2) AS moving_average
FROM vw_country_daily_metrics;

-- Rank countries by total cases
SELECT
    country_name,
    total_cases,
    DENSE_RANK() OVER(ORDER BY total_cases DESC) AS rank
FROM vw_country_daily_metrics
ORDER BY rank;

-- Data Quality Checks
-- Countries with invalid source records
SELECT
    c.country_name,
    COUNT(*) AS invalid_rows
FROM fact_covid f
JOIN dim_country c
ON f.country_id=c.country_id
WHERE total_deaths>total_cases
GROUP BY c.country_name
ORDER BY invalid_rows DESC;

-- Countries with negative daily cases
SELECT
    c.country_name,
    COUNT(*) AS revisions
FROM fact_covid f
JOIN dim_country c
ON f.country_id=c.country_id
WHERE daily_cases<0
GROUP BY c.country_name
ORDER BY revisions DESC;
