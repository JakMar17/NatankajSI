from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.models.orm import FetchLog
from app.models.schemas import FetchLogSchema

router = APIRouter(prefix="/fetch-log", tags=["fetch-log"])


@router.get("", response_model=list[FetchLogSchema])
async def list_fetch_logs(
    limit: int = 20, session: AsyncSession = Depends(get_session)
):
    result = await session.execute(
        select(FetchLog).order_by(FetchLog.started_at.desc()).limit(limit)
    )
    return result.scalars().all()
