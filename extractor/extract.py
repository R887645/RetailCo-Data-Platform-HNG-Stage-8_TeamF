import logging
from api_client import ERPClient
from paginator import paginate
from watermark import setup_watermark_table, get_watermark, set_watermark
from loader import load_records, setup_raw_tables

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
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

def extract_entity(client, entity):
    logger.info(f"Extracting {entity}...")
    watermark = get_watermark(entity)
    params = {}
    if watermark:
        params["updated_after"] = watermark
        logger.info(f"Using watermark: {watermark}")

    records = paginate(client, f"/{entity}/", params=params)

    if not records:
        logger.info(f"No new records found for {entity}.")
        return

    load_records(entity, records)

    latest_updated_at = max(
        (record["updatedAt"] for record in records if record.get("updatedAt")),
        default=None
    )
    if latest_updated_at:
        set_watermark(entity, latest_updated_at)

    logger.info(f"Done: {entity}")

def main():
    setup_watermark_table()
    setup_raw_tables()
    client = ERPClient()
    for entity in ENTITIES:
        extract_entity(client, entity)
    logger.info("All entities extracted successfully.")

if __name__ == "__main__":
    main()