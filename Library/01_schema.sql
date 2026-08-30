-- Staging table: mirrors the raw CSV column order.
CREATE TABLE stg_covid_raw (
    entity TEXT,
    code VARCHAR(10),
    report_date DATE,
    cumulative_deaths BIGINT,
    cumulative_cases BIGINT
);

-- Country dimension
CREATE TABLE dim_country (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(150) NOT NULL,
    country_code VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Date dimension.
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (country_id) REFERENCES dim_country(country_id),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id)
);
