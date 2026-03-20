from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.models.orm import Franchise
from app.models.schemas import FranchiseSchema

router = APIRouter(prefix="/franchises", tags=["franchises"])


@router.get("", response_model=list[FranchiseSchema])
async def list_franchises(session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(Franchise).order_by(Franchise.name))
    return result.scalars().all()
