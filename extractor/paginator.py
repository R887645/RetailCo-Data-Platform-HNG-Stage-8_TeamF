import logging

logger = logging.getLogger(__name__)

def paginate(client, endpoint, params=None):
    params = params or {}
    all_records = []

    while True:
        response = client.get(endpoint, params=params)

        records = response.get("data", [])
        all_records.extend(records)

        logger.info(
            f"Fetched {len(records)} records from {endpoint}. "
            f"Total so far: {len(all_records)}"
        )

        meta = response.get("meta", {})

        if not meta.get("has_more"):
            break

        next_cursor = meta.get("cursor")

        if next_cursor:
            params = {**params, "cursor": next_cursor}

    return all_records