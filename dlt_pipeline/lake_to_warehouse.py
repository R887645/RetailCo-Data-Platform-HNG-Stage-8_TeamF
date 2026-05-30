"""
RetailCo dlt Pipeline — CP3
============================
Reads from Lake Postgres (raw schema)
Writes to Warehouse Postgres (raw schema)

What dlt handles automatically:
  - Incremental loading (only moves rows where updated_at > last run)
  - Type coercion between source and destination
  - Schema evolution (new columns added automatically)
  - Idempotent loads via merge on primary key
"""

from __future__ import annotations
import logging
import os
import dlt
from dlt.sources import DltResource
from typing import Iterator
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

LAKE_CONN      = os.environ["LAKE_CONN"]
WAREHOUSE_CONN = os.environ["WAREHOUSE_CONN"]

# ── Table configs — one entry per Lake table ──────────────────────────────────
# cursor_field: column dlt uses to track what's new
# primary_key:  column used for upsert (no duplicates)

TABLE_CONFIGS = {
    "stores":              {"cursor_field": "updated_at", "primary_key": "id"},
    "employees":           {"cursor_field": "updated_at", "primary_key": "id"},
    "payment_methods":     {"cursor_field": "updated_at", "primary_key": "id"},
    "customers":           {"cursor_field": "updated_at", "primary_key": "id"},
    "products":            {"cursor_field": "updated_at", "primary_key": "id"},
    "orders":              {"cursor_field": "updated_at", "primary_key": "id"},
    "order_items":         {"cursor_field": "updated_at", "primary_key": "id"},
    "payments":            {"cursor_field": "updated_at", "primary_key": "id"},
    "inventory_movements": {"cursor_field": "updated_at", "primary_key": "id"},
}


# ── Source: reads from Lake ───────────────────────────────────────────────────

@dlt.source(name="lake")
def lake_source():
    """
    One dlt resource per table in the Lake.
    Each resource uses incremental loading on updated_at.
    dlt remembers the last value and only fetches newer rows next run.
    """
    import psycopg2
    import psycopg2.extras

    resources = []

    for table_name, config in TABLE_CONFIGS.items():
        cursor_field = config["cursor_field"]
        primary_key  = config["primary_key"]

        def make_resource(t=table_name, cf=cursor_field, pk=primary_key):

            @dlt.resource(
                name=t,
                primary_key=pk,
                write_disposition="merge",
            )
            def table_resource(
                updated_at=dlt.sources.incremental(
                    cf,
                    initial_value="1970-01-01T00:00:00+00:00"
                )
            ) -> Iterator[dict]:
                """
                Yields rows from lake raw.<table> where updated_at > last run.
                dlt tracks the last value automatically.
                """
                conn = psycopg2.connect(LAKE_CONN)
                try:
                    with conn.cursor(
                        cursor_factory=psycopg2.extras.RealDictCursor
                    ) as cur:
                        sql = f"""
                            SELECT *
                            FROM raw.{t}
                            WHERE {cf} > %s
                            ORDER BY {cf} ASC
                        """
                        cur.execute(sql, (updated_at.last_value,))

                        # Fetch in batches of 500 to avoid memory issues
                        while True:
                            rows = cur.fetchmany(500)
                            if not rows:
                                break
                            for row in rows:
                                yield dict(row)
                finally:
                    conn.close()

            return table_resource

        resources.append(make_resource())

    return resources


# ── Pipeline definition ───────────────────────────────────────────────────────

def build_pipeline() -> dlt.Pipeline:
    return dlt.pipeline(
        pipeline_name="retailco_lake_to_warehouse",
        destination=dlt.destinations.postgres(WAREHOUSE_CONN),
        dataset_name="raw",
        dev_mode=False,
    )


# ── Main function called by Airflow ───────────────────────────────────────────

def run_pipeline() -> None:
    """
    Runs the full lake to warehouse load.
    Called by the Airflow DAG after CP2 extract succeeds.
    """
    pipeline  = build_pipeline()
    source    = lake_source()

    logger.info("Starting dlt pipeline: lake → warehouse")
    load_info = pipeline.run(source)
    logger.info("dlt pipeline completed: %s", load_info)

    # Fail loudly if any jobs failed
    for package in load_info.load_packages:
        for job in package.jobs.get("failed_jobs", []):
            raise RuntimeError(f"dlt job failed: {job}")


# ── Local test ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    run_pipeline()