import psycopg2
import os
import logging
from dotenv import load_dotenv
from pathlib import Path

load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env", override=True)

logger = logging.getLogger(__name__)

def get_connection():
    return psycopg2.connect(
        host=os.getenv("LAKE_DB_HOST", "127.0.0.1"),
        port=int(os.getenv("LAKE_DB_PORT", 5435)),
        dbname=os.getenv("LAKE_DB_NAME", "retailco_lake"),
        user=os.getenv("LAKE_DB_USER", "postgres"),
        password=os.getenv("LAKE_DB_PASSWORD", "postgres")
    )

def setup_watermark_table():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        CREATE SCHEMA IF NOT EXISTS raw;
        CREATE TABLE IF NOT EXISTS raw.watermarks (
            entity_name varchar PRIMARY KEY,
            last_updated_at timestamp
        );
    """)
    conn.commit()
    cur.close()
    conn.close()
    logger.info("Watermark table ready.")

def get_watermark(entity_name):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT last_updated_at FROM raw.watermarks WHERE entity_name = %s",
        (entity_name,)
    )
    row = cur.fetchone()
    cur.close()
    conn.close()
    return row[0].isoformat() if row and row[0] else None

def set_watermark(entity_name, timestamp):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO raw.watermarks (entity_name, last_updated_at)
        VALUES (%s, %s)
        ON CONFLICT (entity_name) DO UPDATE
        SET last_updated_at = EXCLUDED.last_updated_at
    """, (entity_name, timestamp))
    conn.commit()
    cur.close()
    conn.close()
    logger.info(f"Watermark set for {entity_name}: {timestamp}")