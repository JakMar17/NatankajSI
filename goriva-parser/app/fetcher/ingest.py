import logging
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.fetcher.client import fetch_all_pages, fetch_flat
from app.models.orm import FetchLog, FuelType, Franchise, Station, PriceSnapshot

logger = logging.getLogger(__name__)


async def ingest_fuel_types(session: AsyncSession) -> dict[str, int]:
    """Fetch and upsert fuel types. Returns {code: pk} mapping."""
    raw = await fetch_flat("/api/v1/fuel/")
    for item in raw:
        stmt = (
            sqlite_insert(FuelType)
            .values(
                pk=item["pk"],
                code=item["code"],
                name=item.get("name", item["code"]),
                long_name=item.get("long_name"),
            )
            .on_conflict_do_update(
                index_elements=["pk"],
                set_={"name": item.get("name", item["code"]), "long_name": item.get("long_name")},
            )
        )
        await session.execute(stmt)
    await session.commit()

    result = await session.execute(select(FuelType.code, FuelType.pk))
    return {row.code: row.pk for row in result}


async def ingest_franchises(session: AsyncSession) -> dict[str, int]:
    """Fetch and upsert franchises. Returns {name: pk} mapping."""
    raw = await fetch_flat("/api/v1/franchise/")
    for item in raw:
        stmt = (
            sqlite_insert(Franchise)
            .values(
                pk=item["pk"],
                name=item["name"],
                marker_url=item.get("marker"),
                marker_hover_url=item.get("marker_hover"),
            )
            .on_conflict_do_update(
                index_elements=["pk"],
                set_={
                    "name": item["name"],
                    "marker_url": item.get("marker"),
                    "marker_hover_url": item.get("marker_hover"),
                },
            )
        )
        await session.execute(stmt)
    await session.commit()

    result = await session.execute(select(Franchise.name, Franchise.pk))
    return {row.name: row.pk for row in result}


async def ingest_stations_and_prices(
    session: AsyncSession,
    stations_raw: list[dict],
    fuel_code_to_pk: dict[str, int],
    fetched_at: datetime,
) -> int:
    """Upsert stations and insert price snapshots. Returns count of stations."""
    price_rows = []

    for item in stations_raw:
        franchise_id = item.get("franchise")

        stmt = (
            sqlite_insert(Station)
            .values(
                pk=item["pk"],
                franchise_id=franchise_id,
                name=item["name"],
                address=item.get("address"),
                lat=item.get("lat"),
                lng=item.get("lng"),
                zip_code=item.get("zip_code"),
                open_hours=item.get("open_hours"),
            )
            .on_conflict_do_update(
                index_elements=["pk"],
                set_={
                    "franchise_id": franchise_id,
                    "name": item["name"],
                    "address": item.get("address"),
                    "lat": item.get("lat"),
                    "lng": item.get("lng"),
                    "zip_code": item.get("zip_code"),
                    "open_hours": item.get("open_hours"),
                },
            )
        )
        await session.execute(stmt)

        prices: dict = item.get("prices", {})
        for code, price in prices.items():
            if price is None:
                continue
            fuel_pk = fuel_code_to_pk.get(code)
            if fuel_pk is None:
                logger.warning("Unknown fuel code %s, skipping", code)
                continue
            price_rows.append(
                {
                    "station_id": item["pk"],
                    "fuel_type_id": fuel_pk,
                    "price": float(price),
                    "fetched_at": fetched_at,
                }
            )

    await session.commit()

    if price_rows:
        await session.execute(sqlite_insert(PriceSnapshot), price_rows)
        await session.commit()

    return len(stations_raw)


async def run_full_fetch(session: AsyncSession) -> None:
    """Orchestrate full data fetch: reference data + all station pages + prices."""
    started_at = datetime.now(UTC)
    log = FetchLog(started_at=started_at, status="running")
    session.add(log)
    await session.commit()
    await session.refresh(log)

    try:
        # Reference data
        fuel_map = await ingest_fuel_types(session)
        await ingest_franchises(session)

        # Station pages
        stations_raw = await fetch_all_pages("/api/v1/search/")
        fetched_at = datetime.now(UTC)

        count = await ingest_stations_and_prices(session, stations_raw, fuel_map, fetched_at)

        log.completed_at = datetime.now(UTC)
        log.stations_fetched = count
        log.status = "success"
        logger.info("Fetch complete: %d stations", count)
    except Exception:
        log.status = "error"
        log.completed_at = datetime.now(UTC)
        logger.exception("Fetch failed")
        raise
    finally:
        await session.commit()
