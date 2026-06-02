"""
RetailCo Master Pipeline DAG — Checkpoint 5
Orchestrates the full pipeline in order:
Extract → dlt Load → dbt Snapshot → dbt Staging → dbt Marts → dbt Test
"""

import os
import sys
import logging
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../extractor"))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../dlt_pipeline"))

from extract import extract_entity
from watermark import setup_watermark_table
from loader import setup_raw_tables
from api_client import ERPClient
from pipeline import run_pipeline

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

DBT_PROJECT_DIR = os.path.join(
    os.path.dirname(__file__), "../../dbt_project"
)

default_args = {
    "owner": "retailco",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "retry_exponential_backoff": True,
    "on_failure_callback": None,
}

def run_setup():
    logger.info("Preparing extraction environment")

    setup_watermark_table()
    setup_raw_tables()

    logger.info("Setup completed")

def run_extract(entity):
    try:
        logger.info(f"Starting extraction: {entity}")

        client = ERPClient()
        extract_entity(client, entity)

        logger.info(f"Completed extraction: {entity}")

    except Exception as e:
        logger.exception(f"Failed extracting {entity}: {e}")
        raise

def run_dlt():
    try:
        logger.info("Starting dlt load")
        run_pipeline()
        logger.info("dlt load completed")

    except Exception as e:
        logger.exception(f"dlt load failed: {e}")
        raise

with DAG(
    dag_id="retailco_master_pipeline",
    default_args=default_args,
    start_date=datetime(2025, 1, 1),
    schedule="@daily",
    catchup=True,
    max_active_runs=1,
    tags=["retailco", "master"],
) as dag:

    # ── Setup ─────────────────────────────────────────────────────
    setup_task = PythonOperator(
        task_id="setup_tables",
        python_callable=run_setup,
    )

    # ── Extract ───────────────────────────────────────────────────
    extract_tasks = []
    for entity in ENTITIES:
        task = PythonOperator(
            task_id=f"extract_{entity}",
            python_callable=run_extract,
            op_kwargs={"entity": entity},
        )
        extract_tasks.append(task)

    setup_task >> extract_tasks[0]
    for i in range(len(extract_tasks) - 1):
        extract_tasks[i] >> extract_tasks[i + 1]

    # ── dlt Load ──────────────────────────────────────────────────
    dlt_load_task = PythonOperator(
        task_id="dlt_load",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} &&
        dbt snapshot --profiles-dir .
        """,
        execution_timeout=timedelta(minutes=20)
    )

    # ── dbt Snapshot ──────────────────────────────────────────────
    dbt_snapshot_task = BashOperator(
        task_id="dbt_snapshot",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} &&
        dbt snapshot --profiles-dir .
        """,
        execution_timeout=timedelta(minutes=20)
    )

    # ── dbt Staging ───────────────────────────────────────────────
    dbt_staging_task = BashOperator(
        task_id="dbt_staging",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} &&
        dbt run --select staging --profiles-dir .
        """,
        execution_timeout=timedelta(minutes=20)
    )
    # ── dbt Marts ─────────────────────────────────────────────────
    dbt_marts_task = BashOperator(
        task_id="dbt_marts",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} &&
        dbt run --select marts --profiles-dir .
        """,
        execution_timeout=timedelta(minutes=20)
    )

    # ── dbt Test ──────────────────────────────────────────────────
    dbt_test_task = BashOperator(
        task_id="dbt_test",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} &&
        dbt test --profiles-dir .
        """,
        execution_timeout=timedelta(minutes=20)
    )

    # ── Task Dependencies ─────────────────────────────────────────
    extract_tasks[-1] >> dlt_load_task
    dlt_load_task >> dbt_snapshot_task
    dbt_snapshot_task >> dbt_staging_task
    dbt_staging_task >> dbt_marts_task
    dbt_marts_task >> dbt_test_task
