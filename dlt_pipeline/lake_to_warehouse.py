"""
RetailCo dlt Pipeline — Checkpoint 3
Reads from Lake PostgreSQL (raw schema)
Writes to Warehouse PostgreSQL (raw schema)
"""

from __future__ import annotations

import logging
import os
from typing import Iterator

import dlt
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
from pathlib import Path

load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env", override=True)

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)


# ── Connection strings ────────────────────────────────────────────────────────

LAKE_CONN      = os.environ["LAKE_CONN"]
WAREHOUSE_CONN = os.environ["WAREHOUSE_CONN"]


# ── Table configuration ───────────────────────────────────────────────────────

TABLE_CONFIGS = {
    "stores":              {"cursor_field": "source_updated_at", "primary_key": "id"},
    "employees":           {"cursor_field": "source_updated_at", "primary_key": "id"},
    "payment_methods":     {"cursor_field": "source_updated_at", "primary_key": "id"},
    "customers":           {"cursor_field": "source_updated_at", "primary_key": "id"},
    "products":            {"cursor_field": "source_updated_at", "primary_key": "id"},
    "orders":              {"cursor_field": "source_updated_at", "primary_key": "id"},
    "order_items":         {"cursor_field": "source_updated_at", "primary_key": "id"},
    "payments":            {"cursor_field": "source_updated_at", "primary_key": "id"},
    "inventory_movements": {"cursor_field": "source_updated_at", "primary_key": "id"},
}


# ── Source ────────────────────────────────────────────────────────────────────

@dlt.source(name="lake")
def lake_source() -> list:
    """
    Builds one dlt resource per lake table.
    Each resource loads incrementally using source_updated_at as the cursor.
    dlt tracks the last value automatically so only new or updated rows
    are moved on each run.
    """

    def make_resource(table: str, cursor_field: str, primary_key: str):

        @dlt.resource(
            name=table,
            primary_key=primary_key,
            write_disposition="merge",
        )
        def resource(
            updated_at=dlt.sources.incremental(
                cursor_field,
                initial_value="1970-01-01T00:00:00+00:00"
            )
        ) -> Iterator[dict]:

            conn = psycopg2.connect(LAKE_CONN)
            try:
                with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                    cur.execute(
                        f"""
                        SELECT *
                        FROM   raw.{table}
                        WHERE  {cursor_field} > %s
                        ORDER  BY {cursor_field} ASC
                        """,
                        (updated_at.last_value,)
                    )
                    while True:
                        rows = cur.fetchmany(500)
                        if not rows:
                            break
                        for row in rows:
                            yield dict(row)
            finally:
                conn.close()

        return resource

    return [
        make_resource(table, cfg["cursor_field"], cfg["primary_key"])
        for table, cfg in TABLE_CONFIGS.items()
    ]


# ── Pipeline ──────────────────────────────────────────────────────────────────

def build_pipeline() -> dlt.Pipeline:
    return dlt.pipeline(
        pipeline_name="retailco_lake_to_warehouse",
        destination=dlt.destinations.postgres(WAREHOUSE_CONN),
        dataset_name="raw",
        dev_mode=False,
    )


# ── Entry point ───────────────────────────────────────────────────────────────

def run_pipeline() -> None:
    """
    Runs the full lake to warehouse load.
    Called by the Airflow DAG after extraction succeeds.
    """
    pipeline  = build_pipeline()
    source    = lake_source()

    logger.info("Starting dlt pipeline: lake → warehouse")
    load_info = pipeline.run(source)
    logger.info("dlt pipeline complete: %s", load_info)

    for package in load_info.load_packages:
        for job in package.jobs.get("failed_jobs", []):
            raise RuntimeError(f"dlt job failed: {job}")


if __name__ == "__main__":
    run_pipeline()
