"""
RetailCo : Full Pipeline DAG (CP5)
====================================
The single end-to-end orchestration DAG.

Task execution order:
  extract_stores ──┐
  extract_employees──┤
  extract_customers──┤
  extract_products ──┤──→ load_lake_to_warehouse
  extract_orders   ──┤        ↓
  extract_order_items┤    dbt_snapshot
  extract_payments ──┤        ↓
  extract_payment_methods┤ dbt_staging
  extract_inventory──┘        ↓
                          dbt_marts
                              ↓
                          dbt_test

Rules:
  - All extract tasks run in PARALLEL
  - load runs only after ALL extracts succeed
  - dbt tasks run in strict sequence
  - Any failure blocks all downstream tasks
  - Every task retries twice with exponential backoff
  - catchup=True enables backfill
"""

import os
import sys
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup

# Make our project modules importable inside Airflow container
sys.path.insert(0, "/opt/airflow/extractor")
sys.path.insert(0, "/opt/airflow/dlt_pipeline")

# ── Paths ──────────────────────────────────────────────────────────────────────
DBT_PROJECT_DIR  = "/opt/airflow/dbt_project"
DBT_PROFILES_DIR = "/opt/airflow/dbt_project"

# ── Default args : applied to every task ──────────────────────────────────────
default_args = {
    "owner":                     "team-f",
    "depends_on_past":           False,
    "email_on_failure":          False,
    "retries":                   2,
    "retry_delay":               timedelta(minutes=5),
    "retry_exponential_backoff": True,
    "max_retry_delay":           timedelta(minutes=30),
}

# ── Entity list ────────────────────────────────────────────────────────────────
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


# ── Python callables ───────────────────────────────────────────────────────────

def run_extract(entity_name: str, **context) -> dict:
    """Extract one entity from ERP API into Lake."""
    from erp_extractor import extract_entity
    result = extract_entity(entity_name, full_refresh=False)
    print(f"Extracted {entity_name}: {result['rows']} rows")
    return result


def run_dlt_load(**context) -> None:
    """Move new/updated rows from Lake to Warehouse via dlt."""
    from lake_to_warehouse import run_pipeline
    run_pipeline()


# ── DAG definition ─────────────────────────────────────────────────────────────
with DAG(
    dag_id="retailco_pipeline",
    description="RetailCo full pipeline: Extract → Load → Transform → Test",
    start_date=datetime(2024, 1, 1),
    schedule_interval="0 2 * * *",   # every day at 02:00 WAT
    catchup=True,                     # enables backfill
    default_args=default_args,
    max_active_runs=1,                # no overlapping runs
    tags=["retailco", "production", "cp5"],
) as dag:

    # ── STEP 1: Extract all 9 entities in parallel ─────────────────────────────
    with TaskGroup(
        group_id="extract",
        tooltip="Extract all 9 ERP entities into Lake"
    ) as extract_group:

        extract_tasks = {}
        for entity in ENTITIES:
            task = PythonOperator(
                task_id=f"extract_{entity}",
                python_callable=run_extract,
                op_kwargs={"entity_name": entity},
                doc_md=f"Extract {entity} from ERP API into raw.{entity} in Lake",
            )
            extract_tasks[entity] = task

    # ── STEP 2: Load Lake → Warehouse via dlt ──────────────────────────────────
    load_task = PythonOperator(
        task_id="load_lake_to_warehouse",
        python_callable=run_dlt_load,
        doc_md="Move new/updated rows from Lake to Warehouse using dlt incremental load",
    )

    # ── STEP 3: dbt snapshot (SCD2 for dim_customer + dim_product) ────────────
    dbt_snapshot = BashOperator(
        task_id="dbt_snapshot",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt snapshot "
            f"--profiles-dir {DBT_PROFILES_DIR} "
            f"--no-version-check"
        ),
        doc_md="Run dbt snapshots to capture SCD2 history for customers and products",
    )

    # ── STEP 4: dbt staging models ─────────────────────────────────────────────
    dbt_staging = BashOperator(
        task_id="dbt_staging",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt run --select staging "
            f"--profiles-dir {DBT_PROFILES_DIR} "
            f"--no-version-check"
        ),
        doc_md="Build staging views: cast types, rename columns, filter soft deletes",
    )

    # ── STEP 5: dbt marts (dimensions + facts) ─────────────────────────────────
    dbt_marts = BashOperator(
        task_id="dbt_marts",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt run --select marts "
            f"--profiles-dir {DBT_PROFILES_DIR} "
            f"--no-version-check"
        ),
        doc_md="Build all 6 dimensions and 4 fact tables (Kimball model)",
    )

    # ── STEP 6: dbt tests ──────────────────────────────────────────────────────
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"dbt test "
            f"--profiles-dir {DBT_PROFILES_DIR} "
            f"--no-version-check"
        ),
        doc_md="Run all dbt tests: not_null, unique, relationships, custom tests",
    )

    # ── Task dependencies (THE ORDER THAT MATTERS) ─────────────────────────────
    # All 9 extract tasks → load → snapshot → staging → marts → test
    extract_group >> load_task >> dbt_snapshot >> dbt_staging >> dbt_marts >> dbt_test