-- Standard country codes use three characters. Filtering with
-- LENGTH(country_code) = 3 helps exclude World, regions,
-- income groups, and other aggregate entities in the dataset.


-- 7-DAY ROLLING AVERAGE OF DAILY CASES
-- Uses AVG() as a window function to smooth daily case fluctuations.
-- PARTITION BY keeps the calculation separate for each country, while the previous 6 rows plus the current row create a 7-day average.
SELECT
    country_name,
    full_date,
    daily_cases,
    ROUND(
        AVG(daily_cases) OVER (
            PARTITION BY country_name
            ORDER BY full_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_7_day_cases
FROM vw_country_daily_metrics
WHERE LENGTH(country_code) = 3
ORDER BY country_name, full_date;

-- COMPARE DAILY CASES WITH THE PREVIOUS REPORTING DAY
-- Uses LAG() to retrieve the previous day's case count for each country.
-- This allows the current and previous values to be compared without a self-join.

SELECT
    country_name,
    full_date,
    daily_cases,
    LAG(daily_cases) OVER (
        PARTITION BY country_name
        ORDER BY full_date
    ) AS previous_day_cases,
    daily_cases
    - LAG(daily_cases) OVER (
        PARTITION BY country_name
        ORDER BY full_date
    ) AS case_change

FROM vw_country_daily_metrics
WHERE LENGTH(country_code) = 3
ORDER BY country_name, full_date;

-- DAY-OVER-DAY CASE GROWTH RATE
-- Uses a CTE and LAG() to calculate the percentage change in daily cases.
-- NULLIF() prevents division-by-zero errors when the previous value is zero.

WITH daily_comparison AS (
    SELECT
        country_name,
        full_date,
        daily_cases,

        LAG(daily_cases) OVER (
            PARTITION BY country_name
            ORDER BY full_date
        ) AS previous_day_cases

    FROM vw_country_daily_metrics
    WHERE LENGTH(country_code) = 3
)

SELECT
    country_name,
    full_date,
    daily_cases,
    previous_day_cases,
    ROUND(
        (
            (daily_cases - previous_day_cases)::numeric
            / NULLIF(previous_day_cases, 0)
        ) * 100,
        2
    ) AS growth_rate

FROM daily_comparison
WHERE previous_day_cases > 0
ORDER BY country_name, full_date;

-- RANK COUNTRIES BY LATEST CUMULATIVE CASES
-- ROW_NUMBER() is used to keep only the latest record for each country.
-- RANK() then orders countries based on their latest cumulative case totals.

WITH latest_country_data AS (
    SELECT
        country_name,
        full_date,
        total_cases,
        ROW_NUMBER() OVER (
            PARTITION BY country_name
            ORDER BY full_date DESC
        ) AS rn
    FROM vw_country_daily_metrics
    WHERE LENGTH(country_code) = 3
),

country_totals AS (
    SELECT
        country_name,
        full_date,
        total_cases
    FROM latest_country_data
    WHERE rn = 1
)

SELECT
    country_name,
    full_date,
    total_cases,
    RANK() OVER (
        ORDER BY total_cases DESC
    ) AS rank_by_total_cases
FROM country_totals
ORDER BY rank_by_total_cases;

-- EACH COUNTRY'S SHARE OF GLOBAL CASES
-- Compares each country's latest case total with the latest World total.
-- The World record is used directly to avoid double-counting regional and other aggregate entities contained in the source dataset.

WITH latest_country_data AS (
    SELECT
        country_name,
        total_cases,
        ROW_NUMBER() OVER (
            PARTITION BY country_name
            ORDER BY full_date DESC
        ) AS rn
    FROM vw_country_daily_metrics
    WHERE LENGTH(country_code) = 3
),
country_totals AS (
    SELECT
        country_name,
        total_cases
    FROM latest_country_data
    WHERE rn = 1
),
world_total AS (
    SELECT
        total_cases AS global_cases
    FROM vw_country_daily_metrics
    WHERE country_name = 'World'
    ORDER BY full_date DESC
    LIMIT 1
)
  
SELECT
    c.country_name,
    c.total_cases,

    ROUND(
        (c.total_cases::numeric
            / NULLIF(w.global_cases, 0)
        ) * 100, 2
    ) AS global_case_share
FROM country_totals c
CROSS JOIN world_total w
ORDER BY global_case_share DESC;

-- PEAK INFECTION DAY FOR EACH COUNTRY
-- ROW_NUMBER() ranks daily case records within each country.
-- Keeping the first ranked row identifies the highest single-day case count.

WITH ranked_cases AS (
    SELECT
        country_name,
        full_date,
        daily_cases,
        ROW_NUMBER() OVER (
            PARTITION BY country_name
            ORDER BY daily_cases DESC, full_date
        ) AS rn
    FROM vw_country_daily_metrics
    WHERE LENGTH(country_code) = 3
)

SELECT
    country_name,
    full_date AS peak_case_date,
    daily_cases AS peak_daily_cases
FROM ranked_cases
WHERE rn = 1
ORDER BY peak_daily_cases DESC;

-- PEAK DEATH DAY FOR EACH COUNTRY 
-- This identifies the date when each country recorded its highest number of daily deaths.
-- The logic is the same as the peak case analysis. Records are ranked inside each country, and the top daily death record is selected using ROW_NUMBER().

WITH ranked_deaths AS (
    SELECT
        country_name,
        full_date,
        daily_deaths,

        ROW_NUMBER() OVER (
            PARTITION BY country_name
            ORDER BY daily_deaths DESC, full_date
        ) AS rn

    FROM vw_country_daily_metrics
    WHERE LENGTH(country_code) = 3
)

SELECT
    country_name,
    full_date AS peak_death_date,
    daily_deaths AS peak_daily_deaths

FROM ranked_deaths
WHERE rn = 1
ORDER BY peak_daily_deaths DESC;

-- SEGMENT COUNTRIES INTO CASE QUARTILES
-- NTILE(4) divides countries into four groups based on their latest
-- cumulative case totals, making high and low case groups easier to compare.

WITH latest_country_data AS (
    SELECT
        country_name,
        total_cases,
        ROW_NUMBER() OVER (
            PARTITION BY country_name
            ORDER BY full_date DESC
        ) AS rn
    FROM vw_country_daily_metrics
    WHERE LENGTH(country_code) = 3
),

latest_totals AS (
    SELECT
        country_name,
        total_cases
    FROM latest_country_data
    WHERE rn = 1
)

SELECT
    country_name,
    total_cases,
    NTILE(4) OVER (
        ORDER BY total_cases DESC
    ) AS case_segment

FROM latest_totals
ORDER BY case_segment, total_cases DESC;

-- IDENTIFY THREE-DAY INCREASING CASE TRENDS
-- LAG() retrieves the previous two daily case values for each country.
-- The query keeps periods where cases increased for three consecutive days.

WITH case_comparison AS (
    SELECT
        country_name,
        full_date,
        daily_cases,
        LAG(daily_cases, 1) OVER (
            PARTITION BY country_name
            ORDER BY full_date
        ) AS previous_day,
        LAG(daily_cases, 2) OVER (
            PARTITION BY country_name
            ORDER BY full_date
        ) AS two_days_previous
    FROM vw_country_daily_metrics
    WHERE LENGTH(country_code) = 3
)

SELECT
    country_name,
    full_date,
    two_days_previous,
    previous_day,
    daily_cases
FROM case_comparison
WHERE daily_cases > previous_day
  AND previous_day > two_days_previous
ORDER BY country_name, full_date;

-- GLOBAL RUNNING TOTAL OF CASES
-- SUM() OVER() calculates an accumulated total of daily cases over time.
-- Only the World entity is used to prevent double-counting aggregate records.

SELECT
    full_date,
    daily_cases,
    total_cases AS source_cumulative_cases,
    SUM(daily_cases) OVER (
        ORDER BY full_date
    ) AS calculated_running_total_cases
FROM vw_country_daily_metrics
WHERE country_name = 'World'
ORDER BY full_date;

-- Rank Countries by Latest Mortality Rate
-- ROW_NUMBER() keeps the latest valid observation for each country.
-- RANK() then compares countries based on their latest mortality rate.

WITH latest_mortality AS (
    SELECT
        c.country_name,
        d.full_date,
        f.total_cases,
        f.total_deaths,
        f.mortality_rate,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_name
            ORDER BY d.full_date DESC) AS rn
    FROM fact_covid f
    JOIN dim_country c
        ON f.country_id = c.country_id
    JOIN dim_date d
        ON f.date_id = d.date_id
    WHERE LENGTH(c.country_code) = 3
      AND f.data_quality_status = 'VALID'
),

latest_records AS (
    SELECT
        country_name,
        full_date,
        total_cases,
        total_deaths,
        mortality_rate
    FROM latest_mortality
    WHERE rn = 1
)

SELECT
    country_name,
    full_date,
    total_cases,
    total_deaths,
    mortality_rate,
    RANK() OVER (
        ORDER BY mortality_rate DESC
    ) AS mortality_rank
FROM latest_records
ORDER BY mortality_rank;

-- Rank Countries by Latest Cumulative Deaths
-- Keeps one latest record per country before ranking cumulative deaths.
-- This prevents multiple historical records from affecting the ranking.

WITH latest_country_deaths AS (
    SELECT
        c.country_name,
        d.full_date,
        f.total_deaths,
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

latest_records AS (
    SELECT
        country_name,
        full_date,
        total_deaths
    FROM latest_country_deaths
    WHERE rn = 1
)

SELECT
    country_name,
    full_date,
    total_deaths,

    RANK() OVER (
        ORDER BY total_deaths DESC
    ) AS death_rank

FROM latest_records
ORDER BY death_rank;

-- Cases per Death by Latest Country Record
-- Calculates the ratio between cumulative cases and deaths using each
-- country's latest valid record. NULLIF() safely handles zero deaths.

WITH latest_country_ratio AS (
    SELECT
        c.country_name,
        d.full_date,
        f.total_cases,
        f.total_deaths,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_name
            ORDER BY d.full_date DESC) AS rn
    FROM fact_covid f
    JOIN dim_country c
        ON f.country_id = c.country_id
    JOIN dim_date d
        ON f.date_id = d.date_id
    WHERE LENGTH(c.country_code) = 3
      AND f.data_quality_status = 'VALID'
)

SELECT
    country_name,
    full_date,
    total_cases,
    total_deaths,
    ROUND(total_cases::numeric
        / NULLIF(total_deaths, 0), 2) AS cases_per_death
FROM latest_country_ratio
WHERE rn = 1
  AND total_deaths > 0
ORDER BY cases_per_death DESC;
