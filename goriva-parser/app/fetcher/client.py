import httpx

from app.config import settings

BASE_URL = settings.goriva_base_url


async def fetch_all_pages(path: str) -> list[dict]:
    url = f"{BASE_URL}{path}"
    results = []
    async with httpx.AsyncClient(timeout=30.0) as client:
        while url:
            resp = await client.get(url, headers={"Accept": "application/json"})
            resp.raise_for_status()
            data = resp.json()
            results.extend(data["results"])
            url = data.get("next")
    return results


async def fetch_flat(path: str) -> list[dict]:
    url = f"{BASE_URL}{path}"
    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.get(url, headers={"Accept": "application/json"})
        resp.raise_for_status()
        data = resp.json()
    if isinstance(data, list):
        return data
    return data.get("results", data)
