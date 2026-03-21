import logging
import math
import re
from datetime import UTC, datetime

import httpx
from sqlalchemy import delete, select
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.orm import (
    Franchise,
    MolCardType,
    MolGastroCategory,
    MolServiceType,
    MolStation,
    MolStationCard,
    MolStationGastro,
    MolStationService,
    Station,
)

logger = logging.getLogger(__name__)

MOL_API_URL = "https://iskalnik.mol.si/api.php"
MOL_FRANCHISE_NAME = "MOL & INA d.o.o."


async def _fetch_mol_stations() -> list[dict]:
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            MOL_API_URL,
            json={"api": "stations", "mode": "country", "lang": "sl", "input": "SI"},
            headers={"content-type": "application/json"},
        )
        resp.raise_for_status()
        return resp.json()


def _strip_prefix(name: str) -> str:
    name = re.sub(
        r"^(BS MOL|MOL BS)\s*(TRUCK|PAY&GO|BENCINSKI SERVIS)?\s*",
        "",
        name,
        flags=re.IGNORECASE,
    )
    return re.sub(r"[^a-z0-9]", "", name.lower())


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6_371_000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


async def _load_db_stations(session: AsyncSession) -> list[tuple[int, str, float | None, float | None]]:
    result = await session.execute(
        select(Station.pk, Station.name, Station.lat, Station.lng)
        .join(Franchise, Station.franchise_id == Franchise.pk)
        .where(Franchise.name == MOL_FRANCHISE_NAME)
    )
    return result.all()


def _build_name_index(
    db_stations: list[tuple],
) -> dict[str, list[tuple[int, float | None, float | None]]]:
    index: dict[str, list] = {}
    for pk, name, lat, lng in db_stations:
        key = _strip_prefix(name)
        index.setdefault(key, []).append((pk, lat, lng))
    return index


def _match_station(
    api_station: dict,
    name_index: dict[str, list[tuple]],
    all_db: list[tuple],
) -> int | None:
    api_lat = api_station["gpsPosition"]["latitude"]
    api_lng = api_station["gpsPosition"]["longitude"]

    # Name match
    key = _strip_prefix(api_station["name"])
    candidates = name_index.get(key, [])
    if len(candidates) == 1:
        return candidates[0][0]
    if len(candidates) > 1:
        # Disambiguate by geo
        return min(candidates, key=lambda c: _haversine(c[1] or 0, c[2] or 0, api_lat, api_lng))[0]

    # Geo fallback across all MOL stations
    with_coords = [(pk, lat, lng) for pk, _, lat, lng in all_db if lat and lng]
    if not with_coords:
        return None
    best = min(with_coords, key=lambda c: _haversine(c[1], c[2], api_lat, api_lng))
    if _haversine(best[1], best[2], api_lat, api_lng) < 500:
        return best[0]
    return None


async def _upsert_reference_types(
    session: AsyncSession, api_stations: list[dict]
) -> tuple[dict[str, int], dict[str, int], dict[str, int]]:
    services: dict[str, str] = {}
    cards: dict[str, str] = {}
    gastro: dict[str, str] = {}

    for s in api_stations:
        for v in s["services"]["values"]:
            services[v["id"]] = v["name"]
        for v in s["cards"]["values"]:
            cards[v["id"]] = v["name"]
        for v in s.get("gastroCategory", {}).get("values", []):
            gastro[v["id"]] = v["name"]

    for code, name in services.items():
        await session.execute(
            sqlite_insert(MolServiceType)
            .values(code=code, name=name)
            .on_conflict_do_update(index_elements=["code"], set_={"name": name})
        )
    for code, name in cards.items():
        await session.execute(
            sqlite_insert(MolCardType)
            .values(code=code, name=name)
            .on_conflict_do_update(index_elements=["code"], set_={"name": name})
        )
    for code, name in gastro.items():
        await session.execute(
            sqlite_insert(MolGastroCategory)
            .values(code=code, name=name)
            .on_conflict_do_update(index_elements=["code"], set_={"name": name})
        )
    await session.commit()

    svc_map = {r.code: r.id for r in (await session.execute(select(MolServiceType.code, MolServiceType.id))).all()}
    card_map = {r.code: r.id for r in (await session.execute(select(MolCardType.code, MolCardType.id))).all()}
    gastro_map = {r.code: r.id for r in (await session.execute(select(MolGastroCategory.code, MolGastroCategory.id))).all()}

    return svc_map, card_map, gastro_map


async def sync_mol_stations(session: AsyncSession) -> int:
    """Fetch MOL API, match to station table, upsert all mol_* tables. Returns count synced."""
    api_stations = await _fetch_mol_stations()
    db_stations = await _load_db_stations(session)
    name_index = _build_name_index(db_stations)
    svc_map, card_map, gastro_map = await _upsert_reference_types(session, api_stations)

    now = datetime.now(UTC)
    synced = 0

    for api_s in api_stations:
        station_pk = _match_station(api_s, name_index, db_stations)
        if station_pk is None:
            logger.debug("No DB match for MOL station %r", api_s["name"])
            continue

        # Upsert mol_station scalar fields
        await session.execute(
            sqlite_insert(MolStation)
            .values(
                station_id=station_pk,
                mol_code=api_s["code"],
                company=api_s.get("company") or None,
                brand=api_s.get("brand") or None,
                name=api_s.get("name") or None,
                street_address=api_s.get("address") or None,
                city=api_s.get("city") or None,
                postcode=api_s.get("postcode") or None,
                lat=api_s["gpsPosition"]["latitude"],
                lng=api_s["gpsPosition"]["longitude"],
                status=api_s.get("stationStatus"),
                shop_size=api_s.get("shopSize"),
                num_of_pos=api_s.get("numOfPos"),
                last_synced_at=now,
            )
            .on_conflict_do_update(
                index_elements=["station_id"],
                set_={
                    "mol_code": api_s["code"],
                    "company": api_s.get("company") or None,
                    "brand": api_s.get("brand") or None,
                    "name": api_s.get("name") or None,
                    "street_address": api_s.get("address") or None,
                    "city": api_s.get("city") or None,
                    "postcode": api_s.get("postcode") or None,
                    "lat": api_s["gpsPosition"]["latitude"],
                    "lng": api_s["gpsPosition"]["longitude"],
                    "status": api_s.get("stationStatus"),
                    "shop_size": api_s.get("shopSize"),
                    "num_of_pos": api_s.get("numOfPos"),
                    "last_synced_at": now,
                },
            )
        )
        await session.commit()

        mol_station = (
            await session.execute(select(MolStation).where(MolStation.station_id == station_pk))
        ).scalar_one()

        # Replace junction rows
        await session.execute(delete(MolStationService).where(MolStationService.mol_station_id == mol_station.id))
        await session.execute(delete(MolStationCard).where(MolStationCard.mol_station_id == mol_station.id))
        await session.execute(delete(MolStationGastro).where(MolStationGastro.mol_station_id == mol_station.id))

        # Services — merge stationAdditionalProperties (EV charger count, skip activeCarWash duplicate)
        props = {p["key"]: p["value"] for p in api_s.get("stationAdditionalProperties", [])}
        for svc in api_s["services"]["values"]:
            svc_id = svc_map.get(svc["id"])
            if svc_id is None:
                continue
            value = props.get("numberOfEvChargers") if svc["id"] == "ELECTRONIC_VEHICLE_CHARGER" else None
            await session.execute(
                sqlite_insert(MolStationService).values(
                    mol_station_id=mol_station.id,
                    service_type_id=svc_id,
                    value=value,
                )
            )

        # Cards
        for card in api_s["cards"]["values"]:
            card_id = card_map.get(card["id"])
            if card_id:
                await session.execute(
                    sqlite_insert(MolStationCard).values(
                        mol_station_id=mol_station.id,
                        card_type_id=card_id,
                    )
                )

        # Gastro
        for g in api_s.get("gastroCategory", {}).get("values", []):
            g_id = gastro_map.get(g["id"])
            if g_id:
                await session.execute(
                    sqlite_insert(MolStationGastro).values(
                        mol_station_id=mol_station.id,
                        gastro_category_id=g_id,
                    )
                )

        await session.commit()
        synced += 1

    logger.info("MOL sync complete: %d/%d stations synced", synced, len(api_stations))
    return synced
