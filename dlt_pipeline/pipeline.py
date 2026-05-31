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


# -------------------------------------------------------------------
# CONNECTIONS
# -------------------------------------------------------------------

LAKE_CONN      = os.environ["LAKE_CONN"]
WAREHOUSE_CONN = os.environ["WAREHOUSE_CONN"]


# -------------------------------------------------------------------
# SOURCE TABLE CONFIGURATION
# -------------------------------------------------------------------

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


# -------------------------------------------------------------------
# DLT SOURCE
# -------------------------------------------------------------------

@dlt.source(name="lake")
def lake_source():

    """
        Builds one dlt resource per lake table.
        Each resource loads incrementally using source_updated_at as the cursor.
        dlt tracks the last value automatically so only new or updated rows
        are moved on each run.
    """
    def build_resource(
        table_name: str,
        cursor_field: str,
        primary_key: str
    ):

        @dlt.resource(
            name=table_name,
            primary_key=primary_key,
            write_disposition="merge"
        )
        def resource(
            updated_at=dlt.sources.incremental(
                cursor_field,
                initial_value="1970-01-01T00:00:00+00:00"
            )
        ) -> Iterator[dict]:

            logger.info(
                f"Loading raw.{table_name} "
                f"after {updated_at.last_value}"
            )

            with psycopg2.connect(LAKE_CONN) as conn:
                with conn.cursor(
                    cursor_factory=psycopg2.extras.RealDictCursor
                ) as cur:

                    cur.execute(
                        f"""
                        SELECT
                            id,
                            raw_data,
                            source_created_at,
                            source_updated_at,
                            extracted_at
                        FROM raw.{table_name}
                        WHERE {cursor_field} > %s
                        ORDER BY {cursor_field}
                        """,
                        (updated_at.last_value,)
                    )

                    while True:
                        rows = cur.fetchmany(500)

                        if not rows:
                            break

                        logger.info(
                            f"{table_name}: fetched {len(rows)} rows"
                        )

                        for row in rows:

                            yield {
                                "id": row["id"],
                                "raw_data": row["raw_data"],
                                "source_created_at": row["source_created_at"],
                                "source_updated_at": row["source_updated_at"],
                                "extracted_at": row["extracted_at"]
                            }

        return resource

    return [
        build_resource(
            table_name,
            config["cursor_field"],
            config["primary_key"]
        )
        for table_name, config in TABLE_CONFIGS.items()
    ]

# -------------------------------------------------------------------
# PIPELINE
# -------------------------------------------------------------------

def build_pipeline():

    return dlt.pipeline(
        pipeline_name="retailco_lake_to_warehouse",
        destination=dlt.destinations.postgres(
            credentials=WAREHOUSE_CONN
        ),
        dataset_name="raw",
        dev_mode=False
    )

# -------------------------------------------------------------------
# RUNNER
# -------------------------------------------------------------------
def run_pipeline():

    """ Runs the full lake to warehouse load. Called by the Airflow DAG after extraction succeeds. """

    logger.info("Starting Lake → Warehouse load")

    pipeline = build_pipeline()

    source = lake_source()

    load_info = pipeline.run(source)

    logger.info("Pipeline completed successfully")

    logger.info(load_info)

    for package in load_info.load_packages:
        failed_jobs = package.jobs.get("failed_jobs", [])

        if failed_jobs:
            raise RuntimeError(
                f"Pipeline failed with jobs: {failed_jobs}"
            )

if __name__ == "__main__":
    run_pipeline()
