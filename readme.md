# Data

This folder documents the raw dataset used by the **Healthcare Analytics Platform**.

The project uses a global COVID-19 time-series dataset containing cumulative confirmed cases and deaths by entity and reporting date. The raw CSV is loaded into PostgreSQL through the staging table before the ETL pipeline transforms it into the analytical warehouse.

## Expected Raw Dataset Structure

The source CSV should contain the following columns:

| Source Column | Staging Column | PostgreSQL Type |
|---|---|---|
| `Entity` | `entity` | `TEXT` |
| `Code` | `code` | `VARCHAR(10)` |
| `Day` | `report_date` | `DATE` |
| `Cumulative confirmed deaths` | `cumulative_deaths` | `BIGINT` |
| `Cumulative confirmed cases` | `cumulative_cases` | `BIGINT` |

The staging table is defined in [`../sql/01_schema.sql`](../sql/01_schema.sql):

```sql
CREATE TABLE stg_covid_raw (
    entity TEXT,
    code VARCHAR(10),
    report_date DATE,
    cumulative_deaths BIGINT,
    cumulative_cases BIGINT
);
```

## Data Loading Workflow

The raw CSV is imported into PostgreSQL using DataGrip.

```text
Raw COVID-19 CSV
        |
        v
stg_covid_raw
        |
        v
SQL ETL
        |
        v
dim_country
dim_date
fact_covid
```

After the import, the staging layer is validated before the ETL process begins.

Example validation:

```sql
SELECT COUNT(*) AS total_records
FROM stg_covid_raw;
```

## Source Data Considerations

The dataset contains more than individual countries. It can also include aggregate entities such as:

- `World`
- Regional aggregates
- Income groups
- Other non-country groupings

Because these records overlap with country-level observations, global totals should not be calculated by summing every entity.

For global reporting, the project uses the dedicated `World` record. Country-level analysis is filtered separately using standard country codes.

## Data Quality Notes

The source data contains historical reporting revisions and anomalous records.

Examples handled by the project include:

- Missing country codes
- Negative daily cases or deaths caused by cumulative revisions
- Records where cumulative deaths exceed cumulative cases
- Missing or invalid values used in mortality calculations

These records are preserved for traceability and handled through the validation logic in:

```text
sql/04_data_quality.sql
```

The ETL process also assigns a `data_quality_status` so invalid source records are not used in mortality-rate analysis.

## Repository Policy

The raw CSV is intentionally not required to be committed directly to this repository.

This keeps the repository lightweight and separates source data from project code. To reproduce the project:

1. Obtain the source COVID-19 CSV.
2. Create the PostgreSQL schema using `sql/01_schema.sql`.
3. Import the CSV into `stg_covid_raw`.
4. Validate the staging data.
5. Run the ETL and analytical SQL files in sequence.

## SQL Execution Order

```text
01_schema.sql
02_load_staging.sql
03_etl.sql
04_data_quality.sql
05_views.sql
06_business_queries.sql
07_advanced_analytics.sql
08_analytical_views.sql
```

## Purpose of This Folder

This folder exists to document:

- The expected source-data structure
- How raw data maps into PostgreSQL
- Important source-data limitations
- How to reproduce the ingestion process

The analytical outputs are generated from PostgreSQL and consumed by Power BI through the reporting views created in `08_analytical_views.sql`.
