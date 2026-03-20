from datetime import datetime

from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class _Base(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True,
    )


class FuelTypeSchema(_Base):
    pk: int
    code: str
    name: str
    long_name: str | None


class FranchiseSchema(_Base):
    pk: int
    name: str
    marker_url: str | None
    marker_hover_url: str | None


class StationSchema(_Base):
    pk: int
    franchise_id: int | None
    name: str
    address: str | None
    lat: float | None
    lng: float | None
    zip_code: str | None
    open_hours: str | None


class PriceSnapshotSchema(_Base):
    id: int
    station_id: int
    fuel_type_id: int
    fuel_code: str
    price: float
    fetched_at: datetime


class LatestPriceEntry(_Base):
    fuel_code: str
    fuel_name: str
    price: float
    fetched_at: datetime


class StationWithPrices(StationSchema):
    franchise_name: str | None
    latest_prices: list[LatestPriceEntry]


class PriceEntry(_Base):
    fuel_code: str
    fuel_name: str
    price: float


class StationPrices(_Base):
    pk: int
    name: str
    address: str | None
    lat: float | None
    lng: float | None
    zip_code: str | None
    open_hours: str | None
    franchise_id: int | None
    franchise_name: str | None
    prices: list[PriceEntry]


class PricesResponse(_Base):
    fetched_at: datetime
    stations: list[StationPrices]


class FetchLogSchema(_Base):
    id: int
    started_at: datetime
    completed_at: datetime | None
    stations_fetched: int | None
    status: str
