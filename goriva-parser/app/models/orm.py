from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class FuelType(Base):
    __tablename__ = "fuel_type"

    pk: Mapped[int] = mapped_column(Integer, primary_key=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    long_name: Mapped[str | None] = mapped_column(String(200))

    price_snapshots: Mapped[list["PriceSnapshot"]] = relationship(back_populates="fuel_type")


class Franchise(Base):
    __tablename__ = "franchise"

    pk: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(200), unique=True, nullable=False)
    marker_url: Mapped[str | None] = mapped_column(String(500))
    marker_hover_url: Mapped[str | None] = mapped_column(String(500))

    stations: Mapped[list["Station"]] = relationship(back_populates="franchise")


class Station(Base):
    __tablename__ = "station"

    pk: Mapped[int] = mapped_column(Integer, primary_key=True)
    franchise_id: Mapped[int | None] = mapped_column(ForeignKey("franchise.pk"))
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    address: Mapped[str | None] = mapped_column(String(500))
    lat: Mapped[float | None] = mapped_column(Float)
    lng: Mapped[float | None] = mapped_column(Float)
    zip_code: Mapped[str | None] = mapped_column(String(20))
    open_hours: Mapped[str | None] = mapped_column(Text)

    franchise: Mapped["Franchise | None"] = relationship(back_populates="stations")
    price_snapshots: Mapped[list["PriceSnapshot"]] = relationship(back_populates="station")


class PriceSnapshot(Base):
    __tablename__ = "price_snapshot"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    station_id: Mapped[int] = mapped_column(ForeignKey("station.pk"), nullable=False)
    fuel_type_id: Mapped[int] = mapped_column(ForeignKey("fuel_type.pk"), nullable=False)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    fetched_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    station: Mapped["Station"] = relationship(back_populates="price_snapshots")
    fuel_type: Mapped["FuelType"] = relationship(back_populates="price_snapshots")


class FetchLog(Base):
    __tablename__ = "fetch_log"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    started_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime)
    stations_fetched: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(50), nullable=False, default="running")
