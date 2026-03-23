from fastapi import APIRouter

from app.api.v1 import fetch_log, franchises, fuels, prices, regulated_prices, stations

router = APIRouter()

router.include_router(stations.router)
router.include_router(prices.router)
router.include_router(fuels.router)
router.include_router(franchises.router)
router.include_router(fetch_log.router)
router.include_router(regulated_prices.router)
