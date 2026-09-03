-- Business and public-health analysis built from the
-- COVID-19 dimensional data warehouse.

-- EXECUTIVE KPIs
-- What are the latest global COVID statistics?
-- The dataset contains countries, regions, and global aggregates. We use the "World" record directly instead of summing all entities to avoid double-counting.

SELECT
    d.full_date AS reporting_date,
    f.total_cases,
    f.total_deaths,
    f.mortality_rate
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE c.country_name = 'World'
ORDER BY d.full_date DESC
LIMIT 1;

-- Which countries have the highest cumulative cases?
-- MAX() gets the highest cumulative value recorded for each country across the full reporting period.
-- country_code IS NOT NULL helps exclude aggregate entities such as World, continents, and income groups.

SELECT
    c.country_name,
    MAX(f.total_cases) AS total_cases
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
WHERE c.country_code IS NOT NULL
GROUP BY c.country_name
ORDER BY total_cases DESC
LIMIT 10;

-- Which countries have the highest cumulative deaths?
-- The same country-level filtering is used so aggregate entities do not appear in the ranking.

SELECT
    c.country_name,
    MAX(f.total_deaths) AS total_deaths
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
WHERE c.country_code IS NOT NULL
GROUP BY c.country_name
ORDER BY total_deaths DESC
LIMIT 10;

-- What is the latest reporting date?
-- This checks how recent the available warehouse data is.

SELECT
    MAX(full_date) AS latest_reporting_date
FROM dim_date;

-- How many countries are monitored?
-- Only entities with a country code are counted to avoid
-- including World and regional aggregate records.

SELECT
    COUNT(*) AS countries_monitored
FROM dim_country
WHERE country_code IS NOT NULL;

-- COUNTRY ANALYSIS
-- Which countries recorded the highest single-day increase in confirmed cases?
-- daily_cases was calculated during ETL by subtracting the previous cumulative total using the LAG() function.

SELECT
    c.country_name,
    d.full_date,
    f.daily_cases
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE c.country_code IS NOT NULL
ORDER BY f.daily_cases DESC
LIMIT 10;

-- Which countries recorded the highest single-day increase in deaths?
-- This identifies the largest daily increases in deaths across all monitored countries and reporting dates.

SELECT
    c.country_name,
    d.full_date,
    f.daily_deaths
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE c.country_code IS NOT NULL
ORDER BY f.daily_deaths DESC
LIMIT 10;

-- Which countries currently have the highest mortality rates?
-- ROW_NUMBER() identifies the latest VALID record for each country. This is better than taking MAX(mortality_rate),
-- because MAX() could return an unusually high value from an earlier point in the pandemic.

WITH latest_country_metrics AS (
    SELECT
        c.country_name,
        d.full_date,
        f.total_cases,
        f.total_deaths,
        f.mortality_rate,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_name
            ORDER BY d.full_date DESC
        ) AS row_num
    FROM fact_covid f
    JOIN dim_country c
        ON f.country_id = c.country_id
    JOIN dim_date d
        ON f.date_id = d.date_id
    WHERE c.country_code IS NOT NULL
      AND f.data_quality_status = 'VALID'
)
SELECT
    country_name,
    full_date,
    total_cases,
    total_deaths,
    mortality_rate
FROM latest_country_metrics
WHERE row_num = 1
ORDER BY mortality_rate DESC
LIMIT 10;

-- GLOBAL TIME ANALYSIS
-- How many new cases were reported globally each month?
-- Only the World entity is used because summing countries, regions, and World together would double-count cases.

SELECT
    d.year,
    d.month,
    TRIM(d.month_name) AS month_name,
    SUM(f.daily_cases) AS monthly_cases
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE c.country_name = 'World'
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;

-- How many new deaths were reported globally each month?
-- Daily deaths are aggregated by year and month to show how the global death trend changed over time.

SELECT
    d.year,
    d.month,
    TRIM(d.month_name) AS month_name,
    SUM(f.daily_deaths) AS monthly_deaths
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE c.country_name = 'World'
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;

-- How did global cumulative cases change over time?
-- Because the source already provides cumulative totals, we can retrieve the World total directly for each date rather than calculating another running total.

SELECT
    d.full_date,
    f.total_cases AS cumulative_cases
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE c.country_name = 'World'
ORDER BY d.full_date;

--  How did global cumulative deaths change over time?
-- This provides a clean time series that can also be used directly in Power BI for global trend visualization.

SELECT
    d.full_date,
    f.total_deaths AS cumulative_deaths
FROM fact_covid f
JOIN dim_country c
    ON f.country_id = c.country_id
JOIN dim_date d
    ON f.date_id = d.date_id
WHERE c.country_name = 'World'
ORDER BY d.full_date;

-- COUNTRY COMPARISON
-- Which countries have the highest total cases in the latest available data?
-- ROW_NUMBER() keeps only the latest record per country so every country appears once in the final comparison.

WITH latest_country_data AS (
    SELECT
        c.country_name,
        d.full_date,
        f.total_cases,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_name
            ORDER BY d.full_date DESC
        ) AS row_num
    FROM fact_covid f
    JOIN dim_country c
        ON f.country_id = c.country_id
    JOIN dim_date d
        ON f.date_id = d.date_id
    WHERE c.country_code IS NOT NULL
)
SELECT
    country_name,
    full_date,
    total_cases
FROM latest_country_data
WHERE row_num = 1
ORDER BY total_cases DESC
LIMIT 10;

-- Which countries have the highest total deaths in the latest available data?
-- This uses the same latest-record logic so the comparison represents the most recent available country totals.

WITH latest_country_data AS (
    SELECT
        c.country_name,
        d.full_date,
        f.total_deaths,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_name
            ORDER BY d.full_date DESC
        ) AS row_num
    FROM fact_covid f
    JOIN dim_country c
        ON f.country_id = c.country_id
    JOIN dim_date d
        ON f.date_id = d.date_id
    WHERE c.country_code IS NOT NULL
)
SELECT
    country_name,
    full_date,
    total_deaths
FROM latest_country_data
WHERE row_num = 1
ORDER BY total_deaths DESC
LIMIT 10;

-- Which countries have the largest number of cumulative cases per recorded death?
-- NULLIF prevents division-by-zero errors. // This query provides an additional comparison metric and demonstrates safe ratio calculations in SQL.

WITH latest_country_data AS (
    SELECT
        c.country_name,
        f.total_cases,
        f.total_deaths,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_name
            ORDER BY d.full_date DESC
        ) AS row_num
    FROM fact_covid f
    JOIN dim_country c
        ON f.country_id = c.country_id
    JOIN dim_date d
        ON f.date_id = d.date_id
    WHERE c.country_code IS NOT NULL
      AND f.data_quality_status = 'VALID'
)

SELECT
    country_name,
    total_cases,
    total_deaths,
    ROUND(
        total_cases::numeric
        / NULLIF(total_deaths, 0), 2) AS cases_per_death
FROM latest_country_data
WHERE row_num = 1
  AND total_deaths > 0
ORDER BY cases_per_death DESC
LIMIT 10;
