import os
import json
import time
import hashlib
from typing import Any, Dict, List, Optional

import requests
import mysql.connector
from dotenv import load_dotenv


def stable_hash(record: Dict[str, Any]) -> str:
    """
    Stable dedupe key: station+pollutant+timestamp+values.
    """
    keys = [
        "country", "state", "city", "station",
        "pollutant_id", "last_update",
        "pollutant_avg", "pollutant_min", "pollutant_max",
    ]
    payload = {k: record.get(k) for k in keys}
    s = json.dumps(payload, sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def api_base() -> str:
    rid = os.environ["DATA_GOV_IN_RESOURCE_ID"].strip()
    return f"https://api.data.gov.in/resource/{rid}"


def fetch_page(
    base_url: str,
    api_key: str,
    offset: int,
    limit: int = 1000,
    filters: Optional[Dict[str, str]] = None,
) -> List[Dict[str, Any]]:
    params: Dict[str, Any] = {
        "api-key": api_key,
        "format": "json",
        "offset": offset,
        "limit": limit,
    }
    if filters:
        for k, v in filters.items():
            params[f"filters[{k}]"] = v

    r = requests.get(base_url, params=params, timeout=30)
    r.raise_for_status()
    return r.json().get("records", []) or []


def fetch_all(
    base_url: str,
    api_key: str,
    limit: int = 1000,
    filters: Optional[Dict[str, str]] = None,
    polite_sleep: float = 0.2,
    max_pages: Optional[int] = None,
) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    offset = 0
    page = 0

    while True:
        page_rows = fetch_page(base_url, api_key, offset=offset, limit=limit, filters=filters)
        if not page_rows:
            break

        rows.extend(page_rows)
        offset += limit
        page += 1

        if max_pages is not None and page >= max_pages:
            break

        time.sleep(polite_sleep)

    return rows


def insert_raw(records: List[Dict[str, Any]]) -> int:
    """
    Insert with INSERT IGNORE to dedupe.
    """
    conn = mysql.connector.connect(
        host=os.environ["MYSQL_HOST"],
        port=int(os.environ.get("MYSQL_PORT", "3306")),
        user=os.environ["MYSQL_USER"],
        password=os.environ["MYSQL_PASSWORD"],
        database=os.environ["MYSQL_DB"],
    )
    try:
        cur = conn.cursor()
        sql = """
            insert ignore into raw_air_quality_observations (record, record_hash)
            values (%s, %s)
        """
        data = [(json.dumps(r, ensure_ascii=False), stable_hash(r)) for r in records]
        cur.executemany(sql, data)
        conn.commit()
        return cur.rowcount  # rows actually inserted (best-effort)
    finally:
        conn.close()


def main():
    load_dotenv()

    api_key = os.environ.get("DATA_GOV_IN_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("Missing DATA_GOV_IN_API_KEY in .env")

    base_url = api_base()

    # Optional dev filter (uncomment to start smaller)
    # filters = {"city": "Delhi"}
    filters = None

    records = fetch_all(base_url, api_key, limit=1000, filters=filters)
    if not records:
        print("No records returned from API.")
        return

    inserted = insert_raw(records)
    print(f"Fetched: {len(records)} | Inserted (dedup): ~{inserted}")


if __name__ == "__main__":
    main()
