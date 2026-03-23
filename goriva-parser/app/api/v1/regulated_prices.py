from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.models.orm import RegulatedPrice
from app.models.schemas import RegulatedPriceSchema

router = APIRouter(prefix="/regulated-prices", tags=["regulated-prices"])


@router.get("/latest", response_model=RegulatedPriceSchema)
async def get_latest_regulated_price(session: AsyncSession = Depends(get_session)):
    result = await session.execute(
        select(RegulatedPrice).order_by(RegulatedPrice.valid_from.desc()).limit(1)
    )
    row = result.scalar_one_or_none()
    if row is None:
        raise HTTPException(status_code=404, detail="No regulated prices available")
    return row


@router.get("", response_model=list[RegulatedPriceSchema])
async def list_regulated_prices(
    from_date: date | None = Query(default=None),
    to_date: date | None = Query(default=None),
    session: AsyncSession = Depends(get_session),
):
    stmt = select(RegulatedPrice).order_by(RegulatedPrice.valid_from.desc())
    if from_date:
        stmt = stmt.where(RegulatedPrice.valid_from >= from_date)
    if to_date:
        stmt = stmt.where(RegulatedPrice.valid_from <= to_date)
    result = await session.execute(stmt)
    return result.scalars().all()
