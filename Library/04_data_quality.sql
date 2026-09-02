-- 04_data_quality.sql

-- 1. Duplicate country-date record // Each country should have only one observation per date // Duplicates could cause inflated KPIs and aggregations
SELECT
    country_id,
    date_id,
    COUNT(*) AS duplicate_count
FROM fact_covid
GROUP BY country_id, date_id
HAVING COUNT(*) > 1;

-- 2. Missing country codes // Identify entities without a country code or incomplete source data rather than actual countries
SELECT *
FROM dim_country
WHERE country_code IS NULL;

-- 3. Negative cumulative values // Cumulative case and death totals should not be negative
SELECT *
FROM fact_covid
WHERE total_cases < 0
   OR total_deaths < 0;

-- 4. Deaths greater than cases // Identify logically inconsistent source records where cumulative deaths exceed cumulative confirmed cases
SELECT *
FROM fact_covid
WHERE total_deaths > total_cases;

-- 5. Missing date relationships // Ensure every fact record has a matching date dimension
SELECT f.*
FROM fact_covid f
LEFT JOIN dim_date d ON f.date_id = d.date_id
WHERE d.date_id IS NULL;

-- 6. Missing country relationships // Ensure every fact record has a matching country/entity
SELECT f.*
FROM fact_covid f
LEFT JOIN dim_country c ON f.country_id = c.country_id
WHERE c.country_id IS NULL;

-- 7. Null cumulative metrics // Identify fact records where core analytical measures were not successfully populated during the ETL process
SELECT *
FROM fact_covid
WHERE total_cases IS NULL
   OR total_deaths IS NULL;

-- 8. Negative daily cases // Negative daily values can occur when cumulative totals are revised downward by the original data source.
SELECT *
FROM fact_covid
WHERE daily_cases < 0;

-- 9. Negative daily deaths // Detect downward revisions in cumulative death totals.

SELECT *
FROM fact_covid
WHERE daily_deaths < 0;

-- 10. Data quality summary // Produce a single validation summary showing the scale of the main data-quality issues found in the warehouse
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
