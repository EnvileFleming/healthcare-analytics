# End-to-End Healthcare Analytics Platform

**PostgreSQL | SQL | Data Warehousing | ETL | Data Quality | Power BI**

An end-to-end analytics project that transforms raw global COVID-19 data into a structured dimensional warehouse, validates source-data quality, performs advanced SQL analysis, and prepares reporting-ready datasets for Power BI.

## Project Highlights

* Built an end-to-end **SQL ETL pipeline in PostgreSQL** to transform and validate **180K+ healthcare records**.
* Designed a **star-schema data warehouse** with fact and dimension tables for country and time-series analysis.
* Developed **25+ analytical queries** using CTEs, window functions, rankings, rolling averages, trend detection, and segmentation.
* Implemented a dedicated **data-quality validation layer** to identify source anomalies without silently modifying the original data.
* Created reusable **analytical views** that act as a semantic layer between PostgreSQL and Power BI.
* Applied source-aware global reporting logic to prevent double-counting countries, regions, and aggregate entities.

---

## Business Problem

Large public-health datasets contain thousands of historical observations, cumulative metrics, source revisions, regional aggregates, and inconsistent records.

The goal of this project was to build an analytics workflow that could:

* Transform raw COVID-19 records into an analysis-ready data model
* Support country-level and global trend analysis
* Calculate reusable public-health KPIs
* Detect and document data-quality issues
* Perform advanced time-series analysis in SQL
* Provide clean datasets for Power BI reporting

Rather than connecting Power BI directly to the raw dataset, the project uses PostgreSQL as the main transformation and analytical layer.

---

## Architecture

```text
Raw COVID-19 CSV Dataset
        |
        v
PostgreSQL Staging Layer
        |
        v
SQL ETL and Transformation
        |
        v
Dimensional Data Warehouse
        |
        v
Data Quality Validation
        |
        v
Business SQL Analysis
        |
        v
Advanced SQL Analytics
        |
        v
Analytical Semantic Layer
        |
        v
Power BI Dashboard
```

### Technology Stack

| Area            | Technology                           |
| --------------- | ------------------------------------ |
| Database        | PostgreSQL                           |
| Query Language  | SQL                                  |
| Database IDE    | DataGrip                             |
| Data Modeling   | Star Schema                          |
| ETL             | PostgreSQL SQL                       |
| Analytics       | PostgreSQL Window Functions and CTEs |
| Visualization   | Power BI                             |
| Version Control | Git                                  |
| Repository      | GitHub                               |

---

# Data Warehouse Design

The analytical warehouse follows a **star-schema design** with one central fact table and two dimensions.

```text
             dim_country
                  |
                  |
             fact_covid
                  |
                  |
               dim_date
```

## `fact_covid`

Stores country-date COVID-19 measurements.

Key metrics include:

* Cumulative confirmed cases
* Cumulative confirmed deaths
* Daily cases
* Daily deaths
* Mortality rate
* Data-quality status

Foreign keys:

* `country_id`
* `date_id`

## `dim_country`

Stores descriptive geographic attributes:

* Country name
* Country code

## `dim_date`

Provides reusable time attributes:

* Full date
* Year
* Quarter
* Month
* Month name
* Week
* Day
* Day name

Separating descriptive attributes from numerical measurements makes the model easier to query, maintain, and use in Power BI.

---

# ETL Pipeline

Raw source data is first loaded into the PostgreSQL staging layer before being transformed into the dimensional model.

The ETL process performs the following steps:

1. Load raw CSV records into `stg_covid_raw`
2. Populate unique country records into `dim_country`
3. Generate the reusable `dim_date` dimension
4. Join staging records with dimension keys
5. Load cumulative metrics into `fact_covid`
6. Derive daily cases using `LAG()`
7. Derive daily deaths using `LAG()`
8. Assign data-quality classifications
9. Calculate mortality rates for valid observations
10. Validate the completed warehouse

### Example: Deriving Daily Metrics

The source dataset contains cumulative totals. Daily values are derived by comparing each observation with the previous observation for the same country.

```sql
LAG(total_cases) OVER (
    PARTITION BY country_id
    ORDER BY date_id
)
```

This allows daily changes to be calculated without using a self-join.

---

# Data Quality Strategy

Data quality was treated as a separate analytical stage rather than silently correcting questionable source values.

Validation checks include:

* Duplicate country-date records
* Missing country codes
* Missing cumulative metrics
* Negative cumulative values
* Negative daily cases
* Negative daily deaths
* Death totals greater than case totals
* Missing fact-to-dimension relationships
* Invalid mortality calculations

Some historical records contain negative daily values because previously reported cumulative totals were later revised by the data source.

Instead of automatically replacing or deleting those records, the project preserves them and identifies them during validation.

### Data Quality Classification

Records are classified before mortality calculations are used:

```text
VALID
NO_CASES
INVALID_SOURCE_DATA
```

This keeps questionable source records traceable while preventing invalid mortality metrics from being treated as normal analytical results.

---

# Business Analysis

The project answers practical analytical questions including:

* What are the latest global COVID-19 statistics?
* Which countries have the highest cumulative case totals?
* Which countries have the highest cumulative death totals?
* Which countries experienced the largest single-day increases?
* Which countries have the highest valid mortality rates?
* How have global cases changed over time?
* How have global deaths changed over time?
* Which countries contribute the largest share of global cases?
* When did each country experience its peak infection day?
* When did each country experience its peak death day?
* Which countries show sustained increases in daily cases?
* Which records contain potential source-data problems?

---

# Advanced SQL Analytics

The project goes beyond basic filtering and aggregation by using advanced PostgreSQL analytical techniques.

## 7-Day Rolling Average

```sql
AVG(daily_cases) OVER (
    PARTITION BY country_name
    ORDER BY full_date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```

Used to smooth short-term daily fluctuations while keeping individual daily observations available.

## Previous-Period Comparison

`LAG()` is used to compare current observations with previous reporting periods.

Applications include:

* Previous-day case comparison
* Day-over-day growth
* Multi-day trend detection

## Country Ranking

`ROW_NUMBER()` identifies the latest country observation before ranking.

`RANK()` is then used to compare countries by:

* Cumulative cases
* Cumulative deaths
* Mortality rate

This avoids treating multiple historical records from the same country as independent ranking observations.

## Country Segmentation

`NTILE(4)` divides countries into four groups based on their latest cumulative case totals.

This demonstrates analytical segmentation directly in SQL.

## Peak Detection

`ROW_NUMBER()` is also used to identify:

* Peak infection day per country
* Peak death day per country

## Running Totals

`SUM() OVER()` demonstrates cumulative analysis without collapsing the time-series dataset.

---

# Handling Aggregate Entities

One important challenge in the source dataset is that it contains more than individual countries.

Examples include:

```text
World
Regional aggregates
Income groups
Other aggregate entities
```

Simply summing all rows would therefore produce incorrect global totals through double-counting.

For global reporting, the analytical layer uses the source's dedicated:

```text
World
```

record instead of summing countries and aggregate entities together.

Country-level reporting is separately filtered using standard country codes.

This logic is applied consistently to global trends, rankings, and case-share calculations.

---

# Analytical Semantic Layer

Instead of rebuilding joins and analytical calculations directly inside Power BI, PostgreSQL exposes reusable reporting-ready views.

## `vw_analytics_country_performance`

Provides one latest observation per country for:

* KPI reporting
* Country comparisons
* Maps
* Summary tables

## `vw_analytics_global_trends`

Provides global time-series metrics using the `World` entity.

Includes:

* Daily cases
* Daily deaths
* Cumulative cases
* Cumulative deaths
* Mortality rate
* 7-day rolling case average
* 7-day rolling death average

## `vw_analytics_country_trends`

Provides historical country-level metrics for:

* Time-series charts
* Country filtering
* Drill-through analysis
* Rolling averages
* Mortality analysis

## `vw_analytics_country_rankings`

Provides one latest observation per country with reusable:

* Case ranking
* Death ranking
* Mortality ranking
* Global case share

This semantic layer reduces duplicated analytical logic between PostgreSQL and Power BI.

---

# Power BI Dashboard

Power BI connects to the PostgreSQL analytical views instead of the raw source table.

The planned dashboard contains three reporting areas.

## Executive Overview

* Global Cases
* Global Deaths
* Global Mortality Rate
* Countries Monitored
* Global daily case trend
* Global daily death trend
* Top countries by cases
* Top countries by deaths

## Country Analysis

* Country selector
* Country-level KPIs
* Daily case trends
* Daily death trends
* 7-day rolling averages
* Mortality analysis

## Rankings and Comparison

* Case rankings
* Death rankings
* Mortality rankings
* Global case contribution
* Country comparison table

---

# Repository Structure

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

---

# SQL File Guide

### `01_schema.sql`

Creates the staging table, dimensions, fact table, constraints, and indexes.

### `02_load_staging.sql`

Validates the raw dataset after CSV ingestion into PostgreSQL.

### `03_etl.sql`

Transforms staging data and populates the dimensional warehouse.

### `04_data_quality.sql`

Validates warehouse integrity and identifies source-data anomalies.

### `05_views.sql`

Creates reusable general-purpose SQL reporting views.

### `06_business_queries.sql`

Answers business and public-health analytical questions.

### `07_advanced_analytics.sql`

Demonstrates advanced PostgreSQL techniques including CTEs, window functions, ranking, rolling averages, segmentation, and trend detection.

### `08_analytical_views.sql`

Creates Power BI-ready datasets that form the analytical semantic layer.

---

# Technical Decisions

### Why PostgreSQL for ETL?

The transformation requirements could be handled directly with SQL, allowing the project to keep database ingestion, transformation, validation, and analytical logic within one reproducible environment.

### Why use a star schema?

The star schema separates numerical measurements from descriptive country and date attributes, making analytical queries and BI reporting easier to understand and maintain.

### Why calculate daily metrics with `LAG()`?

The source provides cumulative case and death totals. `LAG()` allows the previous cumulative value to be accessed efficiently within each country's time series.

### Why preserve negative daily values?

Negative daily values may represent historical source revisions. Removing or replacing them would hide part of the source-data history, so they are identified through validation rather than silently changed.

### Why use the `World` entity for global reporting?

The dataset contains overlapping country, regional, and global records. Using `World` directly prevents double-counting when calculating global KPIs and trends.

### Why create analytical views before Power BI?

The views centralize reporting logic in PostgreSQL and provide Power BI with consistent, reusable datasets instead of duplicating transformations across visuals and DAX measures.

---

# Skills Demonstrated

### SQL and Analytics

* PostgreSQL
* Advanced SQL
* CTEs
* Window functions
* `LAG()`
* `ROW_NUMBER()`
* `RANK()`
* `NTILE()`
* Joins
* Aggregations
* Rolling averages
* Running totals
* Trend analysis
* Ranking and segmentation

### Data Engineering

* SQL ETL
* Staging architecture
* Data transformation
* Data validation
* Data-quality classification

### Data Warehousing

* Star schema
* Fact and dimension modeling
* Dimensional modeling
* Primary and foreign keys
* Indexing
* Analytical views

### Business Intelligence

* Power BI
* KPI design
* Time-series reporting
* Dashboard development
* Semantic reporting layer

### Development

* DataGrip
* Git
* GitHub
* SQL documentation
* Reproducible analytical workflows

---

# Key Takeaways

This project demonstrates my ability to take a raw dataset through the full analytics lifecycle:

```text
Raw Data
   |
   v
Data Modeling
   |
   v
SQL ETL
   |
   v
Data Validation
   |
   v
Business Analysis
   |
   v
Advanced Analytics
   |
   v
Reporting Layer
   |
   v
Power BI
```

The project focuses not only on writing SQL queries, but also on making defensible analytical decisions around data modeling, source-data quality, metric calculation, aggregate handling, and BI-ready data preparation.

---

# Project Status

* [x] Raw data ingestion
* [x] PostgreSQL staging layer
* [x] SQL ETL pipeline
* [x] Dimensional data warehouse
* [x] Data quality validation
* [x] Business SQL analysis
* [x] Advanced SQL analytics
* [x] Analytical semantic layer
* [ ] Power BI dashboard completion
* [ ] Dashboard screenshots
* [ ] Final project documentation
