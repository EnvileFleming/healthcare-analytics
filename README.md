# End-to-End Healthcare Analytics Platform

An end-to-end healthcare analytics project that transforms global COVID-19 data into business-ready insights using **Python, PostgreSQL, advanced SQL, dimensional data modeling, data quality validation, and Power BI**.

## Project Overview

This project demonstrates a complete analytics workflow, from raw data ingestion and transformation to SQL analysis and interactive dashboard development.

The pipeline processes **180K+ healthcare records**, loads them into a PostgreSQL dimensional data warehouse, validates data quality, performs advanced analytical queries, and prepares business-ready datasets for Power BI reporting.

## Tech Stack

- **Python**
- **Pandas**
- **PostgreSQL**
- **SQL**
- **Power BI**
- **Git**
- **GitHub**

## Project Architecture

```text
Raw COVID-19 Dataset
        ↓
Python / Pandas
        ↓
PostgreSQL Staging Layer
        ↓
ETL & Data Transformation
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

The PostgreSQL warehouse follows a **star schema** designed for analytical reporting.

### Fact Table

`fact_covid`

Contains:

- Total confirmed cases
- Total confirmed deaths
- Daily cases
- Daily deaths
- Mortality rate
- Country key
- Date key

### Dimension Tables

`dim_country`

Contains country information such as:

- Country name
- Country code

`dim_date`

Contains:

- Date
- Year
- Quarter
- Month
- Month name
- Week
- Day
- Day name

## ETL Pipeline

The ETL workflow extracts raw COVID-19 data, performs data cleaning and validation, and loads the transformed records into PostgreSQL.

Key ETL processes include:

- Standardizing column names and data types
- Validating missing and duplicate records
- Loading data into a staging table
- Populating country and date dimensions
- Loading the COVID-19 fact table
- Calculating daily cases and deaths using SQL window functions
- Creating analytical metrics for reporting

## Data Quality Validation

The project includes a dedicated data quality layer to identify source inconsistencies before analytical reporting.

Validation rules include:

- Duplicate country-date records
- Missing country codes
- Missing case or death values
- Negative cumulative values
- Negative daily cases
- Negative daily deaths
- Cumulative deaths exceeding cumulative cases
- Referential integrity between fact and dimension tables

During validation, historical reporting anomalies were identified, including negative daily case adjustments caused by revisions to previously reported cumulative totals.

Rather than modifying the source-derived values, these anomalies were retained and identified during validation to preserve data lineage.

## Business Analysis

The project answers **25+ analytical business and public-health questions**, including:

- Which countries recorded the highest cumulative cases?
- Which countries recorded the highest deaths?
- What are the latest global COVID-19 KPIs?
- Which countries experienced the largest single-day increases?
- Which countries have the highest valid mortality rates?
- How did cases and deaths change monthly and quarterly?
- Which countries contributed the largest share of global cases?
- When did each country experience its peak daily case count?
- Which countries showed sustained increases in new cases?

## Advanced SQL

Advanced SQL techniques demonstrated include:

- Common Table Expressions (**CTEs**)
- `JOIN`
- `GROUP BY`
- Conditional aggregation
- `CASE`
- `NULLIF`
- `LAG`
- `ROW_NUMBER`
- `RANK`
- `DENSE_RANK`
- `NTILE`
- Window functions
- Running totals
- Rolling averages
- Day-over-day growth
- Time-series analysis
- Country ranking and segmentation
- Peak detection

## Analytical Views

Reusable PostgreSQL views were created to provide a clean semantic layer between the data warehouse and Power BI.

Key views include:

- `vw_analytics_country_performance`
- `vw_analytics_global_trends`
- `vw_analytics_country_trends`
- `vw_analytics_country_rankings`

These views simplify Power BI reporting and reduce repeated transformation logic.

## Power BI Dashboard

The Power BI reporting layer is designed around four analytical areas.

### Executive Overview

- Total Cases
- Total Deaths
- Mortality Rate
- Countries Tracked
- Global case trends
- Global death trends

### Global Trends

- Daily cases
- Daily deaths
- Cumulative trends
- Time-series filtering

### Country Analysis

- Country-level KPIs
- Daily case trends
- Daily death trends
- 7-day rolling averages
- Mortality analysis

### Country Rankings

- Top countries by cases
- Top countries by deaths
- Global case contribution
- Country ranking analysis

## Repository Structure

```text
healthcare-analytics-platform/
│
├── README.md
│
├── data/
│   └── README.md
│
├── python/
│   └── etl_pipeline.py
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

**Data Analytics:** Exploratory Data Analysis, KPI Development, Time-Series Analysis, Trend Analysis

**Data Engineering:** ETL, Data Cleaning, Data Transformation, Data Validation, Data Quality

**Database:** PostgreSQL, Dimensional Modeling, Star Schema, Data Warehousing

**SQL:** Advanced SQL, CTEs, Window Functions, Analytical Views, Aggregations

**Business Intelligence:** Power BI, Dashboard Development, Data Visualization, Reporting

**Development:** Python, Pandas, Git, GitHub

## Resume Highlights

- Designed an end-to-end **ETL pipeline** using **Python (Pandas)** and **PostgreSQL** to clean, transform, and load **180K+ healthcare records** into a star-schema data warehouse.
- Developed advanced **SQL** solutions using **CTEs, window functions, joins, views, and aggregations** to generate KPIs, validate data, and answer **25+ business questions**.
- Built an interactive **Power BI** dashboard featuring KPI reporting, trend analysis, and country-level insights, supported by **Git/GitHub** documentation and reproducible analytics workflows.

## Project Status

- [x] Data ingestion
- [x] ETL pipeline
- [x] PostgreSQL staging layer
- [x] Dimensional data warehouse
- [x] Data quality validation
- [x] Business SQL analysis
- [x] Advanced SQL analytics
- [x] Analytical views
- [ ] Power BI dashboard completion
- [ ] Dashboard screenshots
- [ ] Final project documentation
