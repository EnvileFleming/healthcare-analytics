# End-to-End Healthcare Analytics

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Analytics-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Power BI](https://img.shields.io/badge/Power%20BI-Reporting-F2C811?logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![SQL](https://img.shields.io/badge/SQL-ETL%20%26%20Analytics-4479A1?logo=mysql&logoColor=white)](https://en.wikipedia.org/wiki/SQL)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An end-to-end healthcare analytics project that transforms raw global COVID-19 time-series data into a validated PostgreSQL warehouse and Power BI-ready reporting views.

The project demonstrates the complete analytics workflow: staging, dimensional modeling, SQL ETL, data-quality validation, business analysis, advanced time-series analysis, and semantic-layer design.

## Project at a glance

| Area | Implementation |
|---|---|
| Source | Global COVID-19 time-series CSV |
| Database | PostgreSQL |
| Warehouse model | Star schema |
| Fact grain | One country/entity observation per reporting date |
| ETL | SQL-based staging and transformation |
| Analytics | CTEs, window functions, rankings, rolling averages, growth analysis, segmentation |
| Reporting layer | Reusable PostgreSQL views for Power BI |
| Data volume | Designed to process 180K+ source records |
| Current status | SQL pipeline and documentation complete; PBIX/dashboard assets are not yet committed |

## Why this project exists

Public-health datasets are useful for analysis, but they often contain cumulative measures, reporting revisions, missing codes, and aggregate entities such as World, regions, and income groups.

This project addresses those challenges by:

- Converting raw records into a reusable dimensional warehouse
- Deriving daily cases and deaths from cumulative totals
- Separating data-quality checks from transformation logic
- Preserving questionable source records for traceability
- Preventing aggregate entities from being treated as individual countries
- Preparing consistent datasets for BI reporting

## Solution architecture

~~~mermaid
flowchart TB
    A[Raw COVID-19 CSV] --> B[stg_covid_raw]
    B --> C[SQL ETL]
    C --> D[dim_country]
    C --> E[dim_date]
    C --> F[fact_covid]
    F --> G[Data-quality validation]
    F --> H[Analytical views]
    H --> I[Power BI-ready datasets]
~~~

## Data warehouse design

The warehouse uses a star schema. The central fact table stores COVID-19 measurements, while the dimensions provide the geographic and time context required for analysis.

~~~mermaid
erDiagram
    DIM_COUNTRY ||--o{ FACT_COVID : describes
    DIM_DATE ||--o{ FACT_COVID : dates

    DIM_COUNTRY {
        integer country_id PK
        varchar country_name
        varchar country_code
        timestamp created_at
    }

    DIM_DATE {
        integer date_id PK
        date full_date UK
        integer year
        integer quarter
        integer month
        varchar month_name
        integer week
        integer day
        varchar day_name
    }

    FACT_COVID {
        bigint covid_id PK
        integer country_id FK
        integer date_id FK
        bigint total_cases
        bigint total_deaths
        bigint daily_cases
        bigint daily_deaths
        numeric mortality_rate
        varchar data_quality_status
        timestamp created_at
    }
~~~

### Table responsibilities

- DIM_COUNTRY: country/entity name and source code
- DIM_DATE: reusable calendar attributes for time-based analysis
- FACT_COVID: cumulative totals, derived daily metrics, mortality rate, and data-quality status

This model keeps descriptive attributes separate from measurable events, making joins, aggregations, and Power BI relationships easier to understand.

## ETL workflow

1. Create the staging, dimension, and fact tables with [01_schema.sql](Library/01_schema.sql).
2. Import the source CSV into the staging table, stg_covid_raw.
3. Validate the import with [02_load_staging.sql](Library/02_load_staging.sql).
4. Populate DIM_COUNTRY and DIM_DATE.
5. Load cumulative measurements into FACT_COVID.
6. Derive daily cases and deaths with LAG().
7. Apply data-quality classifications.
8. Calculate mortality rate only for records classified as valid.
9. Run reporting, business, and advanced analytical queries.
10. Create Power BI-ready views with [08_analytical_views.sql](Library/08_analytical_views.sql).

### Deriving daily metrics

The source contains cumulative totals. Daily values are calculated by comparing each observation with the previous observation for the same country/entity:

~~~sql
total_cases - LAG(total_cases) OVER (
    PARTITION BY country_id
    ORDER BY date_id
)
~~~

This keeps the calculation inside PostgreSQL and avoids a self-join for previous-period comparisons.

## Data-quality approach

The project does not silently overwrite questionable source values. Instead, it validates the warehouse and preserves anomalies for review.

Checks include:

| Check | Purpose |
|---|---|
| Duplicate country-date records | Prevent inflated metrics |
| Missing country codes | Identify aggregate or incomplete entities |
| Negative cumulative values | Detect invalid totals |
| Deaths greater than cases | Detect logically inconsistent records |
| Missing dimension relationships | Verify warehouse integrity |
| Null cumulative metrics | Identify incomplete ETL results |
| Negative daily cases/deaths | Detect downward revisions in cumulative source data |

The ETL assigns one of three statuses:

- VALID
- NO_CASES
- INVALID_SOURCE_DATA

Historical negative daily values can occur when the original source revises a previously reported cumulative total. Those records remain available for traceability, while invalid mortality calculations are excluded from valid-rate analysis.

## Analytical questions

The SQL layer supports questions such as:

- What are the latest global cases, deaths, and mortality rate?
- Which countries have the highest latest cumulative cases or deaths?
- Which countries recorded the largest single-day increases?
- What is the latest reporting date and country coverage?
- Which countries have the highest valid mortality rates?
- What are the 7-day rolling case and death averages?
- When did each country reach its peak daily cases or deaths?
- Which countries show three consecutive days of increasing cases?
- How much does each country contribute to the latest World case total?
- How can countries be segmented into case-volume quartiles?

## Advanced SQL demonstrated

- CTEs for multi-step transformations
- LAG() for previous-day comparisons and derived metrics
- ROW_NUMBER() for latest-record and peak-value selection
- RANK() for country comparisons
- NTILE(4) for case-volume segmentation
- Windowed AVG() for 7-day rolling averages
- Windowed SUM() for running totals
- NULLIF() and conditional logic for safe ratio calculations
- Country filtering using standard three-character source codes

## Global reporting rule

The source contains countries alongside regional and global aggregates. Summing every entity would double-count observations.

For global reporting, the business and analytical layers use the dedicated World record. Country-level analysis separately filters to entities with standard three-character country codes.

This distinction is important when interpreting global totals, country rankings, and country share of global cases.

## Reporting views

The project creates two groups of reusable views:

### General-purpose views

Created in [05_views.sql](Library/05_views.sql):

- vw_country_daily_metrics
- vw_global_daily_summary
- vw_country_summary
- vw_monthly_summary
- vw_country_rankings

### Power BI semantic-layer views

Created in [08_analytical_views.sql](Library/08_analytical_views.sql):

- vw_analytics_country_performance: latest valid country-level snapshot
- vw_analytics_global_trends: World time series with rolling averages
- vw_analytics_country_trends: country-level time series with rolling averages
- vw_analytics_country_rankings: latest country rankings and global case share

Power BI can connect to these views instead of rebuilding the joins and analytical calculations inside every visual.

## Repository structure

~~~text
healthcare-analytics/
├── README.md
├── LICENSE
├── data/
│   └── readme.md
└── Library/
    ├── 01_schema.sql
    ├── 02_load_staging.sql
    ├── 03_etl.sql
    ├── 04_data_quality.sql
    ├── 05_views.sql
    ├── 06_business_queries.sql
    ├── 07_advanced_analytics.sql
    └── 08_analytical_views.sql
~~~

## SQL file guide

| File | Purpose |
|---|---|
| [01_schema.sql](Library/01_schema.sql) | Creates the staging table, dimensions, fact table, constraints, and indexes |
| [02_load_staging.sql](Library/02_load_staging.sql) | Validates record count, date range, sample rows, and distinct entities after import |
| [03_etl.sql](Library/03_etl.sql) | Loads dimensions and facts, derives daily metrics, classifies records, and calculates mortality |
| [04_data_quality.sql](Library/04_data_quality.sql) | Runs warehouse integrity and source-data validation checks |
| [05_views.sql](Library/05_views.sql) | Creates reusable reporting views |
| [06_business_queries.sql](Library/06_business_queries.sql) | Answers executive and country-level analytical questions |
| [07_advanced_analytics.sql](Library/07_advanced_analytics.sql) | Demonstrates rolling averages, growth, rankings, peak detection, segmentation, and trend analysis |
| [08_analytical_views.sql](Library/08_analytical_views.sql) | Creates the Power BI semantic layer |

## Reproduce the project

The raw CSV is not committed to this repository. This keeps the repository lightweight and separates source data from project code.

1. Create a PostgreSQL database.
2. Run [01_schema.sql](Library/01_schema.sql).
3. Obtain the source CSV described in [data/readme.md](data/readme.md).
4. Import the CSV into stg_covid_raw using DataGrip or PostgreSQL COPY.
5. Run the scripts in this order:

~~~text
02_load_staging.sql
03_etl.sql
04_data_quality.sql
05_views.sql
06_business_queries.sql
07_advanced_analytics.sql
08_analytical_views.sql
~~~

6. Connect Power BI to the analytical views when building the report.

## Technical decisions

### Why PostgreSQL?

The project keeps staging, transformation, validation, and analytical logic in one reproducible SQL environment.

### Why a star schema?

A fact table plus country and date dimensions creates a clear analytical model that supports filtering, aggregation, and BI relationships.

### Why use LAG()?

The source provides cumulative totals. LAG() provides the previous observation needed to derive daily changes without a self-join.

### Why preserve negative daily values?

A negative daily value may reflect a source revision rather than a database error. Preserving it makes the source history auditable.

### Why use World for global totals?

The source includes overlapping country, regional, and global records. Using World directly avoids double-counting.

## Skills demonstrated

- PostgreSQL and advanced SQL
- SQL ETL and staging architecture
- Star-schema and dimensional modeling
- Data-quality validation
- CTEs and window functions
- Time-series and trend analysis
- Power BI semantic-layer preparation
- Technical documentation and reproducible workflows

## Project status

- [x] Raw-data structure documented
- [x] PostgreSQL schema defined
- [x] Staging validation script
- [x] SQL ETL pipeline
- [x] Data-quality checks
- [x] Reusable reporting views
- [x] Business-analysis queries
- [x] Advanced SQL analytics
- [x] Power BI analytical views
- [ ] Power BI PBIX file
- [ ] Dashboard screenshots
- [ ] Final visual findings and recommendations

## Next improvement opportunities

- Add the finished PBIX file or export selected dashboard pages as images
- Add a data dictionary with business definitions and metric rules
- Add recorded validation results, such as row counts and anomaly counts
- Review the older general-purpose global summary view before using it for executive totals
- Add a small findings section once the dashboard is complete
