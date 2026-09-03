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
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(150) NOT NULL,
    country_code VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Date dimension. this describes WHEN
CREATE TABLE dim_date (
    date_id SERIAL PRIMARY KEY,
    full_date DATE UNIQUE,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    week INTEGER,
    day INTEGER,
    day_name VARCHAR(20)
);

-- COVID-19 fact table.
CREATE TABLE fact_covid (
    covid_id BIGSERIAL PRIMARY KEY,
    country_id INTEGER NOT NULL,
    date_id INTEGER NOT NULL,
    total_cases BIGINT,
    total_deaths BIGINT,
    daily_cases BIGINT,
    daily_deaths BIGINT,
    mortality_rate NUMERIC(8,4),
    data_quality_status VARCHAR(30),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_country
        FOREIGN KEY (country_id)
        REFERENCES dim_country(country_id),
    CONSTRAINT fk_date
        FOREIGN KEY (date_id)
        REFERENCES dim_date(date_id)
);

-- Indexes for fact table
-- Indexes are there to make data retrieval and JOIN operations faster, especially once fact_covid contains a large number of rows.

CREATE INDEX idx_fact_country
ON fact_covid(country_id);

CREATE INDEX idx_fact_date
ON fact_covid(date_id);

CREATE INDEX idx_country_name
ON dim_country(country_name);

CREATE INDEX idx_date
ON dim_date(full_date);
