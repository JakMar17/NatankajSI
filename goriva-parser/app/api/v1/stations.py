from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_session
from app.models.orm import Franchise, FuelType, PriceSnapshot, Station
from app.models.schemas import (
    LatestPriceEntry,
    PriceSnapshotSchema,
    StationSchema,
    StationWithPrices,
)

router = APIRouter(prefix="/stations", tags=["stations"])


async def _get_latest_prices_for_station(
    session: AsyncSession, station_id: int
) -> list[LatestPriceEntry]:
    sub = (
        select(
            PriceSnapshot.fuel_type_id,
            func.max(PriceSnapshot.fetched_at).label("max_fetched"),
        )
        .where(PriceSnapshot.station_id == station_id)
        .group_by(PriceSnapshot.fuel_type_id)
        .subquery()
    )
    stmt = (
        select(PriceSnapshot, FuelType.code, FuelType.name.label("fuel_name"))
        .join(
            sub,
            (PriceSnapshot.fuel_type_id == sub.c.fuel_type_id)
            & (PriceSnapshot.fetched_at == sub.c.max_fetched),
        )
        .join(FuelType, PriceSnapshot.fuel_type_id == FuelType.pk)
        .where(PriceSnapshot.station_id == station_id)
        .order_by(FuelType.code)
    )
    result = await session.execute(stmt)
    return [
        LatestPriceEntry(
            fuel_code=row.code,
            fuel_name=row.fuel_name,
            price=row.PriceSnapshot.price,
            fetched_at=row.PriceSnapshot.fetched_at,
        )
        for row in result.all()
    ]


@router.get("", response_model=list[StationWithPrices])
async def list_stations(session: AsyncSession = Depends(get_session)):
    result = await session.execute(
        select(Station).options(selectinload(Station.franchise)).order_by(Station.name)
    )
    stations = result.scalars().all()

    out = []
    for s in stations:
        prices = await _get_latest_prices_for_station(session, s.pk)
        out.append(
            StationWithPrices(
                pk=s.pk,
                franchise_id=s.franchise_id,
                name=s.name,
                address=s.address,
                lat=s.lat,
                lng=s.lng,
                zip_code=s.zip_code,
                open_hours=s.open_hours,
                franchise_name=s.franchise.name if s.franchise else None,
                latest_prices=prices,
            )
        )
    return out


@router.get("/{pk}", response_model=StationWithPrices)
async def get_station(pk: int, session: AsyncSession = Depends(get_session)):
    result = await session.execute(
        select(Station).options(selectinload(Station.franchise)).where(Station.pk == pk)
    )
    station = result.scalar_one_or_none()
    if station is None:
        raise HTTPException(status_code=404, detail="Station not found")

    prices = await _get_latest_prices_for_station(session, pk)
    return StationWithPrices(
        pk=station.pk,
        franchise_id=station.franchise_id,
        name=station.name,
        address=station.address,
        lat=station.lat,
        lng=station.lng,
        zip_code=station.zip_code,
        open_hours=station.open_hours,
        franchise_name=station.franchise.name if station.franchise else None,
        latest_prices=prices,
    )


@router.get("/{pk}/prices", response_model=list[PriceSnapshotSchema])
async def station_price_history(
    pk: int,
    from_dt: datetime | None = Query(None, alias="from"),
    to_dt: datetime | None = Query(None, alias="to"),
    fuel: str | None = Query(None, description="Fuel type code"),
    session: AsyncSession = Depends(get_session),
):
    stmt = (
        select(PriceSnapshot, FuelType.code.label("fuel_code"))
        .join(FuelType, PriceSnapshot.fuel_type_id == FuelType.pk)
        .where(PriceSnapshot.station_id == pk)
    )
    if from_dt:
        stmt = stmt.where(PriceSnapshot.fetched_at >= from_dt)
    if to_dt:
        stmt = stmt.where(PriceSnapshot.fetched_at <= to_dt)
    if fuel:
        stmt = stmt.where(FuelType.code == fuel)
    stmt = stmt.order_by(PriceSnapshot.fetched_at.desc(), FuelType.code)

    result = await session.execute(stmt)
    rows = result.all()
    return [
        PriceSnapshotSchema(
            id=row.PriceSnapshot.id,
            station_id=row.PriceSnapshot.station_id,
            fuel_type_id=row.PriceSnapshot.fuel_type_id,
            fuel_code=row.fuel_code,
            price=row.PriceSnapshot.price,
            fetched_at=row.PriceSnapshot.fetched_at,
        )
        for row in rows
    ]
