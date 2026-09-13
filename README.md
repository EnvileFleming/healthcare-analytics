# End-to-End Healthcare Analytics

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Analytics-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Power BI](https://img.shields.io/badge/Power%20BI-Reporting-F2C811?logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![SQL](https://img.shields.io/badge/SQL-ETL%20%26%20Analytics-4479A1?logo=mysql&logoColor=white)](https://en.wikipedia.org/wiki/SQL)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

<p align="center">
  <img src="assets/healthcare-analytics-banner.png" alt="Healthcare Analytics project banner" width="100%">
</p>

An end-to-end healthcare analytics project that transforms raw global COVID-19 time-series data into a validated PostgreSQL warehouse and Power BI-ready reporting views.

The project covers staging, dimensional modeling, SQL ETL, data-quality validation, business analysis, advanced time-series analysis, and semantic-layer preparation.

## Project highlights

- Built a PostgreSQL staging and warehouse workflow for 180K+ source records.
- Designed a star schema with a COVID-19 fact table and country/date dimensions.
- Derived daily cases and deaths from cumulative source data using LAG().
- Added validation checks for duplicates, missing values, invalid totals, relationships, and source revisions.
- Created reusable reporting and Power BI analytical views.
- Used CTEs, window functions, rankings, rolling averages, growth analysis, peak detection, and segmentation.

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

## Star-schema design

The central fact table stores measurements by country/entity and reporting date. The dimensions provide geographic and calendar context for analysis.

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

## Technology stack

| Area | Technology |
|---|---|
| Database | PostgreSQL |
| Query language | SQL |
| Data modeling | Star schema |
| ETL | PostgreSQL SQL |
| Database IDE | DataGrip |
| Visualization | Power BI |
| Version control | Git and GitHub |

## Workflow

1. Define the staging, dimension, and fact tables.
2. Import the source CSV into stg_covid_raw.
3. Validate the staging data.
4. Populate dimensions and load fact records.
5. Derive daily metrics and mortality rates.
6. Run data-quality checks and analytical queries.
7. Create reporting views for Power BI.

For global reporting, the analytical layer uses the dedicated World record to avoid double-counting countries, regions, and other aggregate entities.

## Repository structure

~~~text
healthcare-analytics/
├── README.md
├── TECHNICAL_NOTES.md
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
| [01_schema.sql](Library/01_schema.sql) | Creates staging, dimensions, facts, constraints, and indexes |
| [02_load_staging.sql](Library/02_load_staging.sql) | Validates the imported record count, date range, sample rows, and entities |
| [03_etl.sql](Library/03_etl.sql) | Loads the warehouse, derives daily metrics, classifies records, and calculates mortality |
| [04_data_quality.sql](Library/04_data_quality.sql) | Runs warehouse-integrity and source-data checks |
| [05_views.sql](Library/05_views.sql) | Creates general-purpose reporting views |
| [06_business_queries.sql](Library/06_business_queries.sql) | Answers executive and country-level analytical questions |
| [07_advanced_analytics.sql](Library/07_advanced_analytics.sql) | Demonstrates advanced time-series and ranking analysis |
| [08_analytical_views.sql](Library/08_analytical_views.sql) | Creates Power BI-ready semantic-layer views |

## Reproduce the project

The raw CSV is not committed to the repository. See [data/readme.md](data/readme.md) for the expected source structure and loading notes.

1. Create a PostgreSQL database.
2. Run [01_schema.sql](Library/01_schema.sql).
3. Obtain the source CSV and import it into stg_covid_raw.
4. Run the remaining scripts in order:

~~~text
02_load_staging.sql
03_etl.sql
04_data_quality.sql
05_views.sql
06_business_queries.sql
07_advanced_analytics.sql
08_analytical_views.sql
~~~

5. Connect Power BI to the analytical views when building the report.

## Project status

- [x] PostgreSQL schema
- [x] Staging validation
- [x] SQL ETL pipeline
- [x] Data-quality checks
- [x] Reporting views
- [x] Business queries
- [x] Advanced SQL analytics
- [x] Power BI analytical views
- [ ] Power BI PBIX file
- [ ] Dashboard screenshots
- [ ] Final visual findings and recommendations

## Technical documentation

For the detailed data-model decisions, validation logic, SQL patterns, analytical-view definitions, assumptions, and future improvements, see [TECHNICAL_NOTES.md](TECHNICAL_NOTES.md).
