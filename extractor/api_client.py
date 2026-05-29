import requests
import time

class ERPClient:
    def __init__(self, api_key, base_url):
        self.api_key = api_key
        self.base_url = base_url

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
                wait = int(response.headers.get("Retry-After", 10))
                time.sleep(wait)
                return self.get(endpoint, params, attempt)
            if response.status_code >= 500:
                if attempt <= 5:
                    time.sleep(2 ** attempt)
                    return self.get(endpoint, params, attempt + 1)
                raise Exception(f"Failed after 5 attempts: {endpoint}")
            response.raise_for_status()
            return response.json()
        except requests.exceptions.Timeout:
            if attempt <= 5:
                time.sleep(2 ** attempt)
                return self.get(endpoint, params, attempt + 1)
            raise
