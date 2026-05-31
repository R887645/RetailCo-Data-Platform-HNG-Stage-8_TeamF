"""
RetailCo ERP Extractor:CP2
=============================
Pulls all 9 entities from the ERP REST API into Lake Postgres (raw schema).

What this file does (read top to bottom):
  1. ENTITY CONFIGS  — defines each table: endpoint, columns, primary key
  2. HTTP SESSION    — creates a requests session with headers
  3. get_with_backoff() — retries on 429 (rate limit) and 500 (server error)
  4. paginate()      — follows cursor pages until has_more = False
  5. DB HELPERS      — get/set watermark, upsert rows
  6. extract_entity() — main function: watermark → paginate → upsert → update watermark
  7. extract_all()   — runs all entities (called by Airflow)
"""

from __future__ import annotations

import json
import logging
import os
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Generator, Optional

import psycopg2
import psycopg2.extras
import requests
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s: %(message)s",
)
logger = logging.getLogger("erp_extractor")

BASE_URL  = os.environ["ERP_BASE_URL"].rstrip("/")
API_KEY   = os.environ["ERP_API_KEY"]
LAKE_CONN = os.environ["LAKE_CONN"]

MAX_RETRIES  = 5
BACKOFF_BASE = 2
PAGE_SIZE    = 100


@dataclass
class EntityConfig:
    name: str
    endpoint: str
    pk: str
    supports_updated_after: bool
    columns: list[str]


ENTITIES: list[EntityConfig] = [

    EntityConfig(
        name="stores",
        endpoint="/api/v1/stores",
        pk="id",
        supports_updated_after=True,
        columns=[
            "id", "team_id", "name", "city", "state", "address",
            "phone", "manager_name", "opened_date",
            "created_at", "updated_at"
        ],
    ),

    EntityConfig(
        name="employees",
        endpoint="/api/v1/employees",
        pk="id",
        supports_updated_after=True,
        columns=[
            "id", "team_id", "store_id", "first_name", "last_name",
            "email", "role", "hired_date", "is_deleted",
            "created_at", "updated_at"
        ],
    ),

    EntityConfig(
        name="payment_methods",
        endpoint="/api/v1/payment-methods",
        pk="id",
        supports_updated_after=True,
        columns=[
            "id", "team_id", "name", "provider", "is_digital",
            "created_at", "updated_at"
        ],
    ),

    EntityConfig(
        name="customers",
        endpoint="/api/v1/customers",
        pk="id",
        supports_updated_after=True,
        columns=[
            "id", "team_id", "first_name", "last_name", "email",
            "phone", "segment", "tier", "address", "city", "state",
            "effective_from", "registered_at", "is_deleted",
            "created_at", "updated_at"
        ],
    ),

    EntityConfig(
        name="products",
        endpoint="/api/v1/products",
        pk="id",
        supports_updated_after=True,
        columns=[
            "id", "team_id", "sku", "name", "category", "sub_category",
            "brand", "supplier", "cost_price", "selling_price",
            "effective_from", "is_deleted",
            "created_at", "updated_at"
        ],
    ),

    EntityConfig(
        name="orders",
        endpoint="/api/v1/orders",
        pk="id",
        supports_updated_after=True,
        columns=[
            "id", "team_id", "customer_id", "store_id", "employee_id",
            "status", "discount_code", "discount_amount", "total_amount",
            "ordered_at", "paid_at", "shipped_at", "delivered_at",
            "cancelled_at", "created_at", "updated_at"
        ],
    ),

    EntityConfig(
        name="order_items",
        endpoint="/api/v1/order-items",
        pk="id",
        supports_updated_after=True,
        columns=[
            "id", "team_id", "order_id", "product_id",
            "quantity", "unit_price", "discount_pct", "line_total",
            "created_at", "updated_at"
        ],
    ),

    EntityConfig(
        name="payments",
        endpoint="/api/v1/payments",
        pk="id",
        supports_updated_after=True,
        columns=[
            "id", "team_id", "order_id", "customer_id",
            "payment_method_id", "amount_paid", "currency",
            "status", "payment_type", "reference", "paid_at",
            "created_at", "updated_at"
        ],
    ),

    EntityConfig(
        name="inventory_movements",
        endpoint="/api/v1/inventory-movements",
        pk="id",
        supports_updated_after=True,
        columns=[
            "id", "team_id", "product_id", "store_id",
            "movement_type", "quantity", "reference_id",
            "reference_type", "notes", "moved_at",
            "created_at", "updated_at"
        ],
    ),
]


def make_session() -> requests.Session:
    session = requests.Session()
    session.headers.update({
        "X-API-Key": API_KEY,
        "Accept": "application/json",
    })
    return session

SESSION = make_session()


def get_with_backoff(url: str, params: dict | None = None) -> dict:
    for attempt in range(MAX_RETRIES):
        try:
            response = SESSION.get(url, params=params, timeout=30)

            if response.status_code == 200:
                return response.json()

            elif response.status_code == 429:
                retry_after = int(
                    response.headers.get("Retry-After", BACKOFF_BASE ** attempt)
                )
                logger.warning("Rate limited (429). Waiting %ss before attempt %s/%s",
                    retry_after, attempt + 1, MAX_RETRIES)
                time.sleep(retry_after)

            elif response.status_code in (500, 502, 503, 504):
                wait = BACKOFF_BASE ** attempt
                logger.warning("Server error %s. Waiting %ss before attempt %s/%s",
                    response.status_code, wait, attempt + 1, MAX_RETRIES)
                time.sleep(wait)

            elif response.status_code == 401:
                raise PermissionError(f"Invalid API key. Response: {response.text}")

            else:
                response.raise_for_status()

        except requests.exceptions.Timeout:
            wait = BACKOFF_BASE ** attempt
            logger.warning("Request timed out. Waiting %ss (attempt %s/%s)",
                wait, attempt + 1, MAX_RETRIES)
            time.sleep(wait)

        except requests.exceptions.ConnectionError as exc:
            wait = BACKOFF_BASE ** attempt
            logger.warning("Connection error: %s. Waiting %ss (attempt %s/%s)",
                exc, wait, attempt + 1, MAX_RETRIES)
            time.sleep(wait)

    raise RuntimeError(f"Failed to GET {url} after {MAX_RETRIES} attempts")


def paginate(endpoint: str, updated_after: Optional[str] = None) -> Generator[dict, None, None]:
    url    = f"{BASE_URL}{endpoint}"
    params = {"limit": PAGE_SIZE}

    if updated_after:
        params["updated_after"] = updated_after

    page_count   = 0
    record_count = 0

    while True:
        data        = get_with_backoff(url, params)
        records     = data.get("data", data if isinstance(data, list) else [])
        has_more    = data.get("has_more", False)
        next_cursor = data.get("next_cursor")

        for record in records:
            yield record
            record_count += 1

        page_count += 1

        if not has_more or not next_cursor:
            break

        params["cursor"] = next_cursor

    logger.info("Pagination done for %s: %s pages, %s records",
        endpoint, page_count, record_count)


def get_db_connection():
    return psycopg2.connect(LAKE_CONN)


def get_watermark(cur, entity: str) -> Optional[str]:
    cur.execute(
        "SELECT last_updated_at FROM raw.watermarks WHERE entity = %s",
        (entity,)
    )
    row = cur.fetchone()
    if row and row[0]:
        return row[0].isoformat()
    return None


def set_watermark(cur, entity: str, ts: Optional[datetime]) -> None:
    cur.execute(
        """
        INSERT INTO raw.watermarks (entity, last_updated_at, last_run_at)
        VALUES (%s, %s, NOW())
        ON CONFLICT (entity)
        DO UPDATE SET
            last_updated_at = EXCLUDED.last_updated_at,
            last_run_at     = NOW()
        """,
        (entity, ts)
    )


def upsert_records(cur, entity: EntityConfig, records: list[dict]) -> int:
    if not records:
        return 0

    cols         = entity.columns + ["_extracted_at"]

    def make_row(record: dict) -> tuple:
        values = []
        for col in entity.columns:
            val = record.get(col)
            if isinstance(val, (dict, list)):
                val = json.dumps(val)
            values.append(val)
        values.append(datetime.now(timezone.utc))
        return tuple(values)

    rows         = [make_row(r) for r in records]
    col_list     = ", ".join(cols)
    placeholders = ", ".join(["%s"] * len(cols))
    update_set   = ", ".join(
        f"{c} = EXCLUDED.{c}" for c in cols if c != entity.pk
    )

    sql = f"""
        INSERT INTO raw.{entity.name} ({col_list})
        VALUES ({placeholders})
        ON CONFLICT ({entity.pk}) DO UPDATE SET {update_set}
    """

    psycopg2.extras.execute_batch(cur, sql, rows, page_size=500)
    return len(rows)


def extract_entity(entity_name: str, full_refresh: bool = False) -> dict:
    entity = next(e for e in ENTITIES if e.name == entity_name)
    conn   = get_db_connection()

    try:
        with conn:
            with conn.cursor() as cur:
                watermark = None
                if not full_refresh:
                    watermark = get_watermark(cur, entity.name)

                if watermark:
                    logger.info("INCREMENTAL extract for %s since %s", entity.name, watermark)
                else:
                    logger.info("FULL extract for %s", entity.name)

                updated_after  = watermark if entity.supports_updated_after else None
                buffer         = []
                max_updated_at = None
                total_upserted = 0

                for record in paginate(entity.endpoint, updated_after=updated_after):
                    buffer.append(record)

                    raw_ts = record.get("updated_at")
                    if raw_ts:
                        try:
                            ts = datetime.fromisoformat(str(raw_ts).replace("Z", "+00:00"))
                            if max_updated_at is None or ts > max_updated_at:
                                max_updated_at = ts
                        except (ValueError, AttributeError):
                            pass

                    if len(buffer) >= 500:
                        total_upserted += upsert_records(cur, entity, buffer)
                        buffer = []

                if buffer:
                    total_upserted += upsert_records(cur, entity, buffer)

                if max_updated_at:
                    set_watermark(cur, entity.name, max_updated_at)
                elif not watermark:
                    set_watermark(cur, entity.name, datetime.now(timezone.utc))

        result = {"entity": entity.name, "rows": total_upserted, "watermark": str(max_updated_at)}
        logger.info("✓ Finished %s: %s rows", entity.name, total_upserted)
        return result

    finally:
        conn.close()


def extract_all(full_refresh: bool = False) -> list[dict]:
    results = []
    for entity in ENTITIES:
        logger.info("Starting extract: %s", entity.name)
        result = extract_entity(entity.name, full_refresh=full_refresh)
        results.append(result)
    return results


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        result = extract_entity(sys.argv[1])
        print(f"\nResult: {result}")
    else:
        results = extract_all()
        print("\nSummary:")
        for r in results:
            print(f"  {r['entity']:25s} → {r['rows']:,} rows")
