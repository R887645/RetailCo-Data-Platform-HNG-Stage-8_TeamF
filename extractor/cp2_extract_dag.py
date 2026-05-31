"""
CP2; Airflow DAG: ERP Extraction
"""
import sys
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator

sys.path.insert(0, "/opt/airflow/extractor")

default_args = {
    "owner": "team-f",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "retry_exponential_backoff": True,
}

ENTITY_NAMES = [
    "stores", "employees", "payment_methods", "customers",
    "products", "orders", "order_items", "payments", "inventory_movements",
]

def run_extract(entity_name: str, **context) -> dict:
    from erp_extractor import extract_entity
    return extract_entity(entity_name, full_refresh=False)

with DAG(
    dag_id="cp2_erp_extraction",
    description="Daily ERP extraction into Lake",
    start_date=datetime(2024, 1, 1),
    schedule_interval="0 2 * * *",
    catchup=True,
    default_args=default_args,
    max_active_runs=1,
    tags=["retailco", "cp2"],
) as dag:
    for entity in ENTITY_NAMES:
        PythonOperator(
            task_id=f"extract_{entity}",
            python_callable=run_extract,
            op_kwargs={"entity_name": entity},
        )

    # ── CP3: dlt load task (runs AFTER all extract tasks finish) ──────────────────

def run_dlt_load(**context):
    """Runs after all 9 extract tasks succeed."""
    import sys
    sys.path.insert(0, "/opt/airflow/dlt_pipeline")
    from lake_to_warehouse import run_pipeline
    run_pipeline()

load_task = PythonOperator(
    task_id="load_lake_to_warehouse",
    python_callable=run_dlt_load,
)

# Make ALL extract tasks run before the load task
for entity in ENTITY_NAMES:
    dag.get_task(f"extract_{entity}") >> load_task