import psycopg2
import json
import os
import logging
from dotenv import load_dotenv
from pathlib import Path

load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env", override=True)

logger = logging.getLogger(__name__)

ENTITIES = [
    "stores",
    "employees",
    "payment_methods",
    "customers",
    "products",
    "orders",
    "order_items",
    "payments",
    "inventory_movements",
]

def get_connection():
    return psycopg2.connect(
        host=os.getenv("LAKE_DB_HOST", "127.0.0.1"),
        port=int(os.getenv("LAKE_DB_PORT", 5435)),
        dbname=os.getenv("LAKE_DB_NAME", "retailco_lake"),
        user=os.getenv("LAKE_DB_USER", "postgres"),
        password=os.getenv("LAKE_DB_PASSWORD", "postgres")
    )

def setup_raw_tables():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("CREATE SCHEMA IF NOT EXISTS raw;")
    for entity in ENTITIES:
        cur.execute(f"""
            CREATE TABLE IF NOT EXISTS raw.{entity} (
                id varchar PRIMARY KEY,
                raw_data jsonb,
                source_created_at timestamp,
                source_updated_at timestamp,
                extracted_at timestamp DEFAULT now()
            );
        """)
    conn.commit()
    cur.close()
    conn.close()
    logger.info("All raw tables ready.")

def load_records(entity_name, records):
    if not records:
        logger.info(f"No new records found for {entity_name}.")
        return

    conn = get_connection()
    cur = conn.cursor()

    for record in records:
        cur.execute(f"""
            INSERT INTO raw.{entity_name} (id, raw_data, source_created_at, source_updated_at)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE
            SET raw_data = EXCLUDED.raw_data,
                source_updated_at = EXCLUDED.source_updated_at,
                extracted_at = now()
        """, (
            record.get("id"),
            json.dumps(record),
            record.get("createdAt"),
            record.get("updatedAt")
        ))

    conn.commit()
    logger.info(f"Loaded {len(records)} records into raw.{entity_name}.")
    cur.close()
    conn.close()