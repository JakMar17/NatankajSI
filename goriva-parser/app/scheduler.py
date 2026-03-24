import asyncio
import logging
from datetime import UTC, datetime, timedelta
from time import perf_counter

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
    logger.info("Job started: hourly_fetch")
    started_at = perf_counter()
    try:
        async with async_session() as session:
            await run_full_fetch(session)
    except Exception:
        logger.exception("Job failed: hourly_fetch")
        raise
    finally:
        elapsed = perf_counter() - started_at
        logger.info("Job finished: hourly_fetch (%.2fs)", elapsed)


async def _do_mol_sync() -> None:
    from app.fetcher.mol_ingest import sync_mol_stations

    logger.info("Job started: daily_mol_sync")
    started_at = perf_counter()
    try:
        async with async_session() as session:
            await sync_mol_stations(session)
    except Exception:
        logger.exception("Job failed: daily_mol_sync")
        raise
    finally:
        elapsed = perf_counter() - started_at
        logger.info("Job finished: daily_mol_sync (%.2fs)", elapsed)


async def _do_regulated_prices_sync() -> None:
    from app.fetcher.regulated_prices_ingest import sync_regulated_prices

    logger.info("Job started: daily_regulated_prices")
    started_at = perf_counter()
    try:
        async with async_session() as session:
            await sync_regulated_prices(session)
    except Exception:
        logger.exception("Job failed: daily_regulated_prices")
        raise
    finally:
        elapsed = perf_counter() - started_at
        logger.info("Job finished: daily_regulated_prices (%.2fs)", elapsed)


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
    logger.info("Starting scheduler initialization")
    _scheduler = AsyncScheduler()
    await _scheduler.__aenter__()

    now = datetime.now(UTC)

    await _scheduler.add_schedule(
        _do_fetch,
        IntervalTrigger(
            hours=settings.fetch_interval_hours,
            start_time=now + timedelta(hours=settings.fetch_interval_hours),
        ),
        id="hourly_fetch",
    )
    await _scheduler.add_schedule(
        _refresh_reference_data,
        IntervalTrigger(hours=24, start_time=now + timedelta(hours=24)),
        id="daily_reference",
    )
    await _scheduler.add_schedule(
        _do_mol_sync,
        IntervalTrigger(hours=24, start_time=now + timedelta(hours=24)),
        id="daily_mol_sync",
    )
    await _scheduler.add_schedule(
        _do_regulated_prices_sync,
        IntervalTrigger(hours=24, start_time=now + timedelta(hours=24)),
        id="daily_regulated_prices",
    )

    logger.info(
        "Registered schedules: hourly_fetch, daily_reference, daily_mol_sync, daily_regulated_prices"
    )

    # APScheduler 4 requires explicit start; schedules won't run otherwise.
    await _scheduler.start_in_background()
    logger.info("Scheduler background loop started")

    if await _is_stale():
        logger.info("Data is stale — triggering immediate fetch in background")
        asyncio.create_task(_do_fetch())

    asyncio.create_task(_do_mol_sync())
    asyncio.create_task(_do_regulated_prices_sync())
    logger.info(
        "Scheduler started (interval=%dh, daily jobs + startup sync enabled)",
        settings.fetch_interval_hours,
    )


async def _refresh_reference_data() -> None:
    from app.fetcher.ingest import ingest_fuel_types, ingest_franchises

    logger.info("Job started: daily_reference")
    started_at = perf_counter()
    try:
        async with async_session() as session:
            await ingest_fuel_types(session)
            await ingest_franchises(session)
    except Exception:
        logger.exception("Job failed: daily_reference")
        raise
    finally:
        elapsed = perf_counter() - started_at
        logger.info("Job finished: daily_reference (%.2fs)", elapsed)


async def stop_scheduler() -> None:
    global _scheduler
    if _scheduler:
        logger.info("Stopping scheduler")
        await _scheduler.__aexit__(None, None, None)
        _scheduler = None
        logger.info("Scheduler stopped")
