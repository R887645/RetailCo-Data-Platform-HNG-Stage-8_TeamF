import time
import logging
import requests
from dotenv import load_dotenv
from pathlib import Path
import os

load_dotenv(dotenv_path=Path(__file__).resolve().parent.parent / ".env", override=True)

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

class ERPClient:
    def __init__(self):
        self.base_url = os.getenv("ERP_BASE_URL")
        self.api_key = os.getenv("ERP_API_KEY")

    def get(self, endpoint, params=None, attempt=1):
        headers = {"X-API-Key": self.api_key}
        try:
            response = requests.get(
                f"{self.base_url}{endpoint}",
                headers=headers,
                params=params,
                timeout=30
            )
            if response.status_code == 429:
                if attempt <= 5:
                    wait = int(response.headers.get("Retry-After", 10))
                    logger.warning(f"Rate limited. Waiting {wait}s (attempt {attempt})...")
                    time.sleep(wait)
                    return self.get(endpoint, params, attempt + 1)
                raise Exception(f"Rate limit exceeded after 5 retries: {endpoint}")

            if response.status_code >= 500:
                if attempt <= 5:
                    wait = 2 ** attempt
                    logger.warning(f"Server error {response.status_code}. Retrying in {wait}s (attempt {attempt})...")
                    time.sleep(wait)
                    return self.get(endpoint, params, attempt + 1)
                raise Exception(f"Failed after 5 attempts: {endpoint}")

            response.raise_for_status()
            return response.json()

        except requests.exceptions.RequestException as e:
            if attempt <= 5:
                wait = 2 ** attempt
                logger.warning(f"Request failed: {e}. Retrying in {wait}s (attempt {attempt})...")
                time.sleep(wait)
                return self.get(endpoint, params, attempt + 1)
            raise