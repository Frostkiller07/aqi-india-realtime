import pandas as pd
import mysql.connector
from pathlib import Path

EXPORT_DIR = Path("bi_exports")
EXPORT_DIR.mkdir(exist_ok=True)

conn = mysql.connector.connect(
    host="127.0.0.1",
    user="aqi_user",
    password="aqi_pass",
    database="aqi"
)

tables = [
    "fct_air_quality",
    "fct_city_latest",
    "fct_city_daily",
    "dim_pollutant"
]

for table in tables:
    df = pd.read_sql(f"SELECT * FROM {table}", conn)
    out = EXPORT_DIR / f"{table}.csv"
    df.to_csv(out, index=False)
    print(f"Exported {table} -> {out}")


conn.close()
