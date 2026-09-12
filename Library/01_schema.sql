-- Database Schema (STAR)
-- Staging table: mirrors the raw CSV column order.
CREATE TABLE stg_covid_raw (
    entity TEXT,
    code VARCHAR(10),
    report_date DATE,
    cumulative_deaths BIGINT,
    cumulative_cases BIGINT
);

-- Country dimension this describes WHO/WHERE
CREATE TABLE dim_country (
    country_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_name VARCHAR(150) NOT NULL UNIQUE,
    country_code VARCHAR(10),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Date dimension. this describes WHEN
CREATE TABLE dim_date (
    date_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    week INTEGER NOT NULL,
    day INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL
);

-- COVID-19 fact table.
CREATE TABLE fact_covid (
    covid_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_id INTEGER NOT NULL,
    date_id INTEGER NOT NULL,
    total_cases BIGINT,
    total_deaths BIGINT,
    daily_cases BIGINT,
    daily_deaths BIGINT,
    mortality_rate NUMERIC(8,4),
    data_quality_status VARCHAR(30),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_fact_country
        FOREIGN KEY (country_id)
        REFERENCES dim_country(country_id),

    CONSTRAINT fk_fact_date
        FOREIGN KEY (date_id)
        REFERENCES dim_date(date_id),

    CONSTRAINT uq_fact_country_date
        UNIQUE (country_id, date_id),

    CONSTRAINT chk_data_quality_status
        CHECK (
            data_quality_status IN
            ('VALID', 'NO_CASES', 'INVALID_SOURCE_DATA')
            OR data_quality_status IS NULL
        )
);
-- Automatically indexed:
-- dim_country(country_name)
-- dim_date(full_date)
-- fact_covid(country_id, date_id)

-- Explicitly required:
CREATE INDEX idx_fact_covid_date
ON fact_covid(date_id);
