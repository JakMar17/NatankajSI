from collections import defaultdict
from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.helpers import load_mol_map
from app.database import get_session
from app.models.orm import Franchise, FuelType, PriceSnapshot, Station
from app.models.schemas import PriceEntry, PricesResponse, StationPrices

router = APIRouter(prefix="/prices", tags=["prices"])


@router.get("", response_model=PricesResponse)
async def get_prices(
    timestamp: datetime | None = Query(None, description="Return latest snapshot at or before this timestamp"),
    session: AsyncSession = Depends(get_session),
):
    # Resolve target fetched_at
    ts_query = select(func.max(PriceSnapshot.fetched_at))
    if timestamp is not None:
        ts_query = ts_query.where(PriceSnapshot.fetched_at <= timestamp)
    target_ts = (await session.execute(ts_query)).scalar_one_or_none()

    if target_ts is None:
        return PricesResponse(fetched_at=timestamp or datetime.utcnow(), stations=[])

    rows = (await session.execute(
        select(
            PriceSnapshot.price,
            Station.pk,
            Station.name,
            Station.address,
            Station.lat,
            Station.lng,
            Station.zip_code,
            Station.open_hours,
            Station.franchise_id,
            Franchise.name.label("franchise_name"),
            FuelType.code.label("fuel_code"),
            FuelType.name.label("fuel_name"),
        )
        .join(Station, PriceSnapshot.station_id == Station.pk)
        .outerjoin(Franchise, Station.franchise_id == Franchise.pk)
        .join(FuelType, PriceSnapshot.fuel_type_id == FuelType.pk)
        .where(PriceSnapshot.fetched_at == target_ts)
        .order_by(Station.name, FuelType.code)
    )).all()

    # Group by station
    station_map: dict[int, StationPrices] = {}
    prices_map: dict[int, list[PriceEntry]] = defaultdict(list)

    for row in rows:
        if row.pk not in station_map:
            station_map[row.pk] = StationPrices(
                pk=row.pk,
                name=row.name,
                address=row.address,
                lat=row.lat,
                lng=row.lng,
                zip_code=row.zip_code,
                open_hours=row.open_hours,
                franchise_id=row.franchise_id,
                franchise_name=row.franchise_name,
                prices=[],
            )
        prices_map[row.pk].append(PriceEntry(fuel_code=row.fuel_code, fuel_name=row.fuel_name, price=row.price))

    mol_map = await load_mol_map(session, list(station_map.keys()))

    for pk, station in station_map.items():
        station.prices = prices_map[pk]
        station.mol = mol_map.get(pk)

    return PricesResponse(fetched_at=target_ts, stations=list(station_map.values()))
