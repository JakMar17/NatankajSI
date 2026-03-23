import logging
from datetime import date

import httpx
from bs4 import BeautifulSoup
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.orm import RegulatedPrice

logger = logging.getLogger(__name__)

_URL = (
    "https://www.energetika-portal.si/podrocja/energetika/"
    "cene-naftnih-derivatov/regulirane-cene-naftnih-derivatov/"
)


def _parse_price(raw: str) -> float | None:
    text = raw.strip().replace("\xa0", "").replace("—", "").replace("–", "").replace("-", "")
    if not text:
        return None
    try:
        return float(text.replace(",", "."))
    except ValueError:
        return None


def _parse_date(raw: str) -> date | None:
    text = raw.strip()
    try:
        day, month, year = text.split(".")
        return date(int(year), int(month), int(day))
    except (ValueError, AttributeError):
        return None


async def _fetch_rows() -> list[tuple[date, float | None, float | None]]:
    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.get(_URL)
        resp.raise_for_status()

    soup = BeautifulSoup(resp.text, "html.parser")
    table = soup.find("table")
    if table is None:
        raise ValueError("Price table not found on the page")

    rows: list[tuple[date, float | None, float | None]] = []
    for tr in table.find("tbody").find_all("tr"):
        cells = [td.get_text() for td in tr.find_all("td")]
        if len(cells) < 3:
            continue
        valid_from = _parse_date(cells[0])
        if valid_from is None:
            continue
        petrol = _parse_price(cells[1])
        diesel = _parse_price(cells[2])
        rows.append((valid_from, petrol, diesel))

    return rows


async def sync_regulated_prices(session: AsyncSession) -> tuple[int, int]:
    """Fetch historic regulated prices and upsert into DB.

    Returns (inserted, updated) counts.
    """
    rows = await _fetch_rows()
    if not rows:
        logger.warning("No regulated price rows parsed from page")
        return 0, 0

    existing: dict[date, RegulatedPrice] = {}
    result = await session.execute(select(RegulatedPrice))
    for rp in result.scalars().all():
        existing[rp.valid_from] = rp

    inserted = updated = 0
    for valid_from, petrol, diesel in rows:
        if valid_from in existing:
            rp = existing[valid_from]
            if rp.petrol_price != petrol or rp.diesel_price != diesel:
                rp.petrol_price = petrol
                rp.diesel_price = diesel
                updated += 1
        else:
            session.add(RegulatedPrice(valid_from=valid_from, petrol_price=petrol, diesel_price=diesel))
            inserted += 1

    await session.commit()
    logger.info("Regulated prices sync: %d inserted, %d updated", inserted, updated)
    return inserted, updated
