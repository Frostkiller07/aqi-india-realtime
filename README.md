# 🇮🇳 AQI India – End-to-End Data Engineering & Analytics Pipeline

An end-to-end **local data engineering project** that ingests real-time air quality data for Indian cities, transforms it using **dbt**, validates data quality, and delivers **Tableau-ready analytics**.

Built to demonstrate **production-style data workflows**, not just dashboards.

---

## 🔍 What This Project Shows

- API ingestion & deduplication
- Relational data modeling (facts & dimensions)
- Data quality testing with dbt
- BI-ready data exports
- Interactive Tableau dashboards
- Reproducible, one-click pipeline execution

---

## 🧱 Tech Stack

| Layer | Tools |
|-----|------|
| Ingestion | Python |
| Database | MySQL (local) |
| Transformations | dbt (MySQL adapter) |
| Data Quality | dbt tests |
| Analytics | Tableau Public |
| Orchestration | Windows `.cmd` pipeline |

---

## 🧩 Architecture

data.gov.in API
↓
Python ingestion (MySQL)
↓
dbt staging + marts
↓
dbt tests
↓
CSV exports (BI layer)
↓
Tableau dashboards

---

## 📁 Project Structure

aqi-india-realtime/
│
├── src/
│ ├── ingest/
│ │ └── ingest_aqi.py # API → MySQL ingestion
│ └── bi/
│ └── export_for_tableau.py # BI CSV exports
│
├── dbt/
│ └── aqi_dbt/
│ ├── models/ # staging + marts
│ ├── tests/ # dbt tests
│ ├── target/ # dbt artifacts (ignored)
│ ├── dbt_project.yml
│ └── profiles.yml
│
├── bi_exports/ # Tableau-ready CSVs (generated)
├── logs/ # Pipeline logs (generated)
│
├── sql/
│ └── 00_mysql_setup.sql # Initial DB setup
│
├── .env # Secrets (ignored)
├── .env.example # Sample env file
├── .gitignore
├── requirements.txt
├── run_pipeline_and_export.cmd # Full pipeline + export
└── README.md


---

## Environment Variables

Create a `.env` file in the project root:

```env
# data.gov.in
DATA_GOV_IN_API_KEY=your_api_key
DATA_GOV_IN_RESOURCE_ID=resource_id

# MySQL
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DB=aqi
MYSQL_USER=aqi_user
MYSQL_PASSWORD=aqi_password
```

.env is never committed.
Use .env.example as a reference.


 
## How to Run the Pipeline (Windows)
1️. Create virtual environment
python -m venv .venv

2️. Install dependencies
.venv\Scripts\activate
pip install -r requirements.txt

3️. Run full pipeline
run_pipeline_and_export.cmd


This will:

Ingest AQI data from API

Deduplicate and store in MySQL

Run dbt models (staging + marts)

Run dbt tests

Export BI CSVs to bi_exports/


## Data Models (dbt)
Core marts:

- **fct_city_latest** – latest AQI snapshot per city  
- **fct_city_daily** – daily AQI trends by city & pollutant  
- **dim_pollutant** – pollutant metadata  
- **fct_air_quality** – normalized AQI facts  

All models are tested for **nulls, accepted values, and consistency**.
Schema consistency

## Tableau Dashboards
Included Visuals
Section  Description
KPI 1 Average AQI by City
KPI 2 Maximum AQI by City
KPI 3 AQI Severity Distribution
Map   City-level AQI map
Trend Daily AQI trend by pollutant
Ranking  Top 10 cities by AQI
Filters

State

City

Pollutant


## 📊 Tableau Dashboards

- **Dashboard 1 – AQI Snapshot (KPIs & Map)**
  - Current AQI levels by city
  - Severity distribution across India
  - Interactive filters for State and Pollutant  
  🔗 https://public.tableau.com/views/aqi-india-realtime/Dashboard1

- **Dashboard 2 – AQI Trends & Pollutant Analysis**
  - Daily AQI trends by pollutant
  - City and state-level drill-down
  - Identifies key pollution drivers over time  
  🔗 https://public.tableau.com/views/aqi-india-realtime-dashboard2/Dashboard2


## Design Decisions

CSV exports used instead of live DB connection
(Tableau Public compatibility)

Single-click pipeline for reproducibility

## Ignored Files (.gitignore)

.env (secrets)

.venv/

logs/

bi_exports/

dbt/target/

Python cache files

Generated data and logs are reproducible, not versioned.

## Author

Name: Jeet Ajay Damani
