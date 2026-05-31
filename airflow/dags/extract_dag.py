import logging
import sys
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../extractor"))

from extract import extract_entity
from watermark import setup_watermark_table
from loader import setup_raw_tables
from api_client import ERPClient

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

default_args = {
    "owner": "retailco",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "retry_exponential_backoff": True,
}

def run_setup():
    setup_watermark_table()
    setup_raw_tables()

def run_extract(entity):
    """
    Extract a single ERP entity and load it into the raw lake.
    """
    try:
        client = ERPClient()
        extract_entity(client, entity)

    except Exception as e:
        logger.exception(f"Failed extracting {entity}: {e}")
        raise

with DAG(
    dag_id="retailco_extract",
    default_args=default_args,
    start_date=datetime(2025, 1, 1),
    schedule="@daily",
    catchup=True,
    tags=["retailco", "extract"],
) as dag:

    setup_task = PythonOperator(
        task_id="setup_tables",
        python_callable=run_setup,
    )

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