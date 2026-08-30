-- 1. Duplicate country-date records.
SELECT
    country_id,
    date_id,
    COUNT(*) AS duplicate_count
FROM fact_covid
GROUP BY country_id, date_id
HAVING COUNT(*) > 1;

-- 2. Missing country codes.
SELECT *
FROM dim_country
WHERE country_code IS NULL;

-- 3. Negative cumulative values.
SELECT *
FROM fact_covid
WHERE total_cases < 0
   OR total_deaths < 0;

-- 4. Deaths greater than cases.
SELECT *
FROM fact_covid
WHERE total_deaths > total_cases;

-- 5. Missing date relationships.
SELECT f.*
FROM fact_covid f
LEFT JOIN dim_date d ON f.date_id = d.date_id
WHERE d.date_id IS NULL;

-- 6. Missing country relationships.
SELECT f.*
FROM fact_covid f
LEFT JOIN dim_country c ON f.country_id = c.country_id
WHERE c.country_id IS NULL;

-- 7. Null cumulative metrics.
SELECT *
FROM fact_covid
WHERE total_cases IS NULL
   OR total_deaths IS NULL;

-- 8. Negative daily cases.
SELECT *
FROM fact_covid
WHERE daily_cases < 0;

-- 9. Negative daily deaths.
SELECT *
FROM fact_covid
WHERE daily_deaths < 0;

-- 10. Data quality summary.
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE total_cases IS NULL) AS null_cases,
    COUNT(*) FILTER (WHERE total_deaths IS NULL) AS null_deaths,
    COUNT(*) FILTER (WHERE total_cases < total_deaths)
        AS invalid_source_records,
    COUNT(*) FILTER (WHERE daily_cases < 0)
        AS negative_daily_cases,
    COUNT(*) FILTER (WHERE daily_deaths < 0)
        AS negative_daily_deaths
FROM fact_covid;
