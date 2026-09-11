# Technical Notes

This document contains the implementation details behind the [Healthcare Analytics](README.md) project. The main README is intentionally concise; this file keeps the deeper SQL and modeling context available for reviewers.

## 1. Data model

### Grain

The intended fact-table grain is one COVID-19 observation for one country/entity on one reporting date.

### Staging table

stg_covid_raw mirrors the expected source CSV:

| Source column | Staging column | Type |
|---|---|---|
| Entity | entity | TEXT |
| Code | code | VARCHAR(10) |
| Day | report_date | DATE |
| Cumulative confirmed deaths | cumulative_deaths | BIGINT |
| Cumulative confirmed cases | cumulative_cases | BIGINT |

### Dimension tables

- dim_country stores country/entity names and source codes.
- dim_date stores reusable calendar attributes, including year, quarter, month, week, day, and day name.

### Fact table

fact_covid stores:

- Cumulative cases and deaths
- Derived daily cases and deaths
- Mortality rate
- Data-quality status
- Foreign keys to the country and date dimensions

## 2. ETL logic

The SQL pipeline in 03_etl.sql performs the following:

1. Inserts unique entities into dim_country.
2. Inserts unique reporting dates and calendar attributes into dim_date.
3. Joins staging records to dimension keys.
4. Loads cumulative measures into fact_covid.
5. Derives daily cases and deaths with LAG().
6. Assigns a data-quality status.
7. Calculates mortality rate for valid records.
8. Creates a reusable valid-metrics view.

Daily cases are derived from cumulative totals:

~~~sql
total_cases - LAG(total_cases) OVER (
    PARTITION BY country_id
    ORDER BY date_id
)
~~~

The same pattern is used for daily deaths.

## 3. Data-quality rules

04_data_quality.sql checks:

| Rule | Reason |
|---|---|
| Duplicate country/date combinations | Prevent inflated aggregations |
| Missing country codes | Identify aggregate or incomplete entities |
| Negative cumulative values | Detect invalid source totals |
| Deaths greater than cases | Detect logically inconsistent records |
| Missing dimension relationships | Verify referential completeness |
| Null cumulative metrics | Identify incomplete fact records |
| Negative daily cases/deaths | Identify downward source revisions |

The ETL status logic is:

- VALID: cases are present, greater than zero, and not lower than deaths
- NO_CASES: total cases equal zero
- INVALID_SOURCE_DATA: cases are null or lower than deaths

Negative daily values are checked separately because they can result from revisions to cumulative source totals. They are not automatically deleted or replaced.

## 4. Analytical SQL patterns

The project demonstrates the following techniques:

| Technique | Use in the project |
|---|---|
| CTEs | Break multi-step analysis into readable stages |
| LAG() | Compare current and previous observations |
| ROW_NUMBER() | Select the latest record or identify peak days |
| RANK() | Rank countries by cases, deaths, or mortality |
| NTILE(4) | Segment countries into case-volume quartiles |
| AVG() OVER() | Calculate 7-day rolling averages |
| SUM() OVER() | Calculate running totals |
| NULLIF() | Prevent division-by-zero errors |
| FILTER | Produce compact data-quality summaries |

Examples of supported analysis include latest-country rankings, day-over-day growth, peak infection/death days, three-day increasing trends, country case share, and cases-per-death ratios.

## 5. Aggregate-entity handling

The source contains individual countries as well as entities such as World, regions, and income groups.

Country-level analysis uses standard three-character country codes to exclude most aggregate entities.

Global reporting uses the World record directly. This is safer than summing all fact rows because country and aggregate records overlap.

The World-based logic is used in:

- Executive KPI queries
- Global running-total analysis
- Country case-share analysis
- vw_analytics_global_trends

## 6. View layer

### General-purpose views

05_views.sql creates:

- vw_country_daily_metrics
- vw_global_daily_summary
- vw_country_summary
- vw_monthly_summary
- vw_country_rankings

These views support exploration and reusable SQL reporting.

### Power BI analytical views

08_analytical_views.sql creates:

- vw_analytics_country_performance: one latest valid snapshot per country
- vw_analytics_global_trends: World time series with 7-day rolling averages
- vw_analytics_country_trends: country-level time series with rolling averages
- vw_analytics_country_rankings: latest rankings and share of global cases

The analytical views centralize joins and metric logic before the data reaches Power BI.

## 7. Important assumptions and limitations

- The raw CSV is not committed to the repository and must be obtained separately.
- The expected source-column mapping is documented in data/readme.md.
- Source records may contain historical reporting revisions.
- A country code is used as a practical filter for country-level reporting; source-code quality should still be reviewed.
- Mortality rate is calculated only when the ETL status is VALID.
- The general-purpose vw_global_daily_summary view aggregates fact rows by date. For executive global totals, use the World-based analytical view to avoid mixing countries and aggregate entities.
- The PBIX file, dashboard screenshots, and final findings are not yet committed.

## 8. Future improvements

- Add a unique country/date constraint if the source grain is confirmed.
- Make the ETL idempotent so scripts can be safely rerun.
- Add explicit staging-to-fact row-count reconciliation.
- Add a dedicated data-quality results table for historical auditability.
- Add a source URL, dataset version, and refresh date to the data documentation.
- Add the finished Power BI report and a short findings section.
- Add a data dictionary with business definitions, units, and null-handling rules.
