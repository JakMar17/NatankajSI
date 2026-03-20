import asyncio
import logging
from datetime import UTC, datetime, timedelta

from apscheduler import AsyncScheduler
from apscheduler.triggers.interval import IntervalTrigger

from app.config import settings
from app.database import async_session
from app.fetcher.ingest import run_full_fetch
from app.models.orm import FetchLog
from sqlalchemy import func, select

logger = logging.getLogger(__name__)

_scheduler: AsyncScheduler | None = None


async def _do_fetch() -> None:
    async with async_session() as session:
        await run_full_fetch(session)


async def _is_stale() -> bool:
    """Return True if there's no recent successful fetch within the interval."""
    async with async_session() as session:
        result = await session.execute(
            select(func.max(FetchLog.completed_at)).where(FetchLog.status == "success")
        )
        last = result.scalar_one_or_none()

    if last is None:
        return True
    if last.tzinfo is None:
        last = last.replace(tzinfo=UTC)
    threshold = datetime.now(UTC) - timedelta(hours=settings.fetch_interval_hours)
    return last < threshold


async def start_scheduler() -> None:
    global _scheduler
    _scheduler = AsyncScheduler()
    await _scheduler.__aenter__()

    await _scheduler.add_schedule(
        _do_fetch,
        IntervalTrigger(hours=settings.fetch_interval_hours),
        id="hourly_fetch",
    )
    await _scheduler.add_schedule(
        _refresh_reference_data,
        IntervalTrigger(hours=24),
        id="daily_reference",
    )

    if await _is_stale():
        logger.info("Data is stale — triggering immediate fetch in background")
        asyncio.create_task(_do_fetch())

    logger.info("Scheduler started (interval=%dh)", settings.fetch_interval_hours)


async def _refresh_reference_data() -> None:
    from app.fetcher.ingest import ingest_fuel_types, ingest_franchises
    async with async_session() as session:
        await ingest_fuel_types(session)
        await ingest_franchises(session)


async def stop_scheduler() -> None:
    global _scheduler
    if _scheduler:
        await _scheduler.__aexit__(None, None, None)
        _scheduler = None
