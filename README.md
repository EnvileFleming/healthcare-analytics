# End-to-End Healthcare Analytics Platform

An end-to-end healthcare analytics project that transforms global COVID-19 data into analysis-ready insights using **PostgreSQL, SQL, ETL, dimensional data modeling, data quality validation, advanced analytics, and Power BI**.

## Project Overview

This project demonstrates a complete analytics workflow, from raw CSV ingestion and database transformation to advanced SQL analysis and interactive dashboard development.

The pipeline loads **180K+ healthcare records** into PostgreSQL, transforms the raw data into a dimensional data warehouse, performs data quality validation, derives analytical metrics, and creates reusable views for Power BI reporting.

## Tech Stack

* **PostgreSQL**
* **SQL**
* **Power BI**
* **DataGrip**
* **Git**
* **GitHub**

## Project Architecture

```text
Raw COVID-19 CSV Dataset
        ↓
PostgreSQL Staging Layer
        ↓
SQL ETL & Transformation
        ↓
Dimensional Data Warehouse
        ↓
Data Quality Validation
        ↓
Business SQL Analysis
        ↓
Advanced SQL Analytics
        ↓
Analytical Views
        ↓
Power BI Dashboard
```

## Data Model

The PostgreSQL data warehouse follows a **star schema** designed for analytical reporting.

### Fact Table

`fact_covid`

Stores COVID-19 measurements at the country-date level, including:

* Total confirmed cases
* Total confirmed deaths
* Daily cases
* Daily deaths
* Mortality rate
* Country key
* Date key

### Dimension Tables

#### `dim_country`

Stores geographic information used for country-level analysis:

* Country name
* Country code

#### `dim_date`

Provides a dedicated date dimension containing:

* Full date
* Year
* Quarter
* Month
* Month name
* Week
* Day
* Day name

## ETL Pipeline

Raw COVID-19 data is first loaded into a PostgreSQL staging table before being transformed into the analytical warehouse.

The SQL ETL process includes:

* Loading raw CSV data into the staging layer
* Standardizing data types
* Populating country and date dimensions
* Loading cumulative cases and deaths into the fact table
* Deriving daily cases using `LAG()`
* Deriving daily deaths using `LAG()`
* Calculating mortality metrics
* Validating relationships between fact and dimension tables

This approach separates the raw data from the analytical model and creates a reproducible transformation workflow.

## Data Quality Validation

A dedicated SQL data-quality layer was implemented to identify source inconsistencies before reporting.

Validation checks include:

* Duplicate country-date records
* Missing country codes
* Missing case and death values
* Negative cumulative values
* Negative daily cases
* Negative daily deaths
* Cumulative deaths exceeding cumulative cases
* Missing dimension relationships
* Invalid mortality calculations

Historical reporting anomalies were identified during validation, including negative daily values caused by revisions to previously reported cumulative totals.

Rather than silently replacing these source-derived values, anomalous records were identified during validation to preserve data integrity and lineage.

## Business Analysis

The project uses SQL to investigate business and public-health questions such as:

* Which countries recorded the highest cumulative cases?
* Which countries recorded the highest deaths?
* What are the latest global COVID-19 KPIs?
* Which countries experienced the largest single-day increases?
* Which countries have the highest valid mortality rates?
* How did cases and deaths change over time?
* Which countries contributed the largest share of cases?
* When did each country experience its peak daily case count?
* Which records contain potential data-quality issues?
* Which countries demonstrated sustained increases in daily cases?

## Advanced SQL

The analytical layer demonstrates SQL techniques including:

* Common Table Expressions (**CTEs**)
* `JOIN`
* `GROUP BY`
* `CASE`
* `NULLIF`
* `LAG`
* `ROW_NUMBER`
* `RANK`
* `DENSE_RANK`
* `NTILE`
* Window functions
* Conditional aggregation
* Running totals
* Rolling averages
* Day-over-day analysis
* Ranking and segmentation
* Peak detection
* Time-series analysis

## Analytical Views

Reusable PostgreSQL views provide a reporting layer between the dimensional warehouse and Power BI.

### `vw_analytics_country_performance`

Provides the latest valid metrics for individual countries, including:

* Total cases
* Total deaths
* Mortality rate
* Latest reporting date

### `vw_analytics_global_trends`

Provides global time-series metrics for trend analysis.

### `vw_analytics_country_trends`

Provides country-level historical metrics including:

* Daily cases and deaths
* Cumulative cases and deaths
* Mortality rate
* Time dimensions
* Rolling averages

### `vw_analytics_country_rankings`

Supports comparative country analysis including:

* Case rankings
* Death rankings
* Share of total cases

## Power BI Dashboard

The PostgreSQL analytical views serve as the reporting layer for the Power BI dashboard.

The dashboard is designed around the following analytical areas:

### Executive Overview

* Total Cases
* Total Deaths
* Mortality Rate
* Countries Tracked
* Global case trends
* Global death trends

### Global Trends

* Daily cases
* Daily deaths
* Cumulative trends
* Time-series analysis

### Country Analysis

* Country-level KPIs
* Daily case trends
* Daily death trends
* Rolling averages
* Mortality analysis

### Country Rankings

* Top countries by cases
* Top countries by deaths
* Case contribution
* Country ranking analysis

## Repository Structure

```text
healthcare-analytics-platform/
│
├── README.md
│
├── data/
│   └── README.md
│
├── sql/
│   ├── 01_schema.sql
│   ├── 02_load_staging.sql
│   ├── 03_etl.sql
│   ├── 04_data_quality.sql
│   ├── 05_views.sql
│   ├── 06_business_queries.sql
│   ├── 07_advanced_analytics.sql
│   └── 08_analytical_views.sql
│
├── powerbi/
│   └── healthcare_analytics.pbix
│
├── images/
│   ├── data_model.png
│   └── dashboard.png
│
└── .gitignore
```

## Skills Demonstrated

**Data Analytics**

* KPI development
* Trend analysis
* Time-series analysis
* Data validation
* Analytical problem solving

**SQL**

* Advanced SQL
* CTEs
* Window functions
* Joins
* Aggregations
* Analytical views

**Data Engineering**

* ETL
* Data transformation
* Data quality validation
* Staging architecture

**Data Warehousing**

* PostgreSQL
* Star schema
* Fact and dimension modeling
* Dimensional modeling

**Business Intelligence**

* Power BI
* Dashboard development
* KPI reporting
* Data visualization

**Development & Documentation**

* DataGrip
* Git
* GitHub
* SQL documentation
* Reproducible analytics workflows

## Key Project Highlights

* Designed an end-to-end **SQL ETL pipeline** using **PostgreSQL** to transform, validate, and load **180K+ healthcare records** into a star-schema data warehouse.
* Developed advanced SQL analyses using **CTEs, window functions, joins, views, and aggregations** to generate KPIs, validate data, and answer **25+ analytical questions**.
* Created reusable analytical views to connect the PostgreSQL warehouse with **Power BI** for KPI reporting, trend analysis, and country-level insights.

## Project Status

* [x] Raw data ingestion
* [x] PostgreSQL staging layer
* [x] SQL ETL pipeline
* [x] Dimensional data warehouse
* [x] Data quality validation
* [x] Business SQL analysis
* [x] Advanced SQL analytics
* [x] Analytical views
* [ ] Power BI dashboard completion
* [ ] Dashboard screenshots
* [ ] Final documentation
