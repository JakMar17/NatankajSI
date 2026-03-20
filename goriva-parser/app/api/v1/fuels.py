from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.models.orm import FuelType
from app.models.schemas import FuelTypeSchema

router = APIRouter(prefix="/fuels", tags=["fuels"])


@router.get("", response_model=list[FuelTypeSchema])
async def list_fuels(session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(FuelType).order_by(FuelType.pk))
    return result.scalars().all()
