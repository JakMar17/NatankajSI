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
    mol_station: Mapped["MolStation | None"] = relationship(back_populates="station")


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


# ── MOL reference tables ──────────────────────────────────────────────────────

class MolServiceType(Base):
    __tablename__ = "mol_service_type"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)

    station_services: Mapped[list["MolStationService"]] = relationship(back_populates="service_type")


class MolCardType(Base):
    __tablename__ = "mol_card_type"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)

    station_cards: Mapped[list["MolStationCard"]] = relationship(back_populates="card_type")


class MolGastroCategory(Base):
    __tablename__ = "mol_gastro_category"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)

    station_gastros: Mapped[list["MolStationGastro"]] = relationship(back_populates="gastro_category")


# ── MOL station ───────────────────────────────────────────────────────────────

class MolStation(Base):
    __tablename__ = "mol_station"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    station_id: Mapped[int] = mapped_column(ForeignKey("station.pk"), unique=True, nullable=False)
    mol_code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    company: Mapped[str | None] = mapped_column(String(200))
    brand: Mapped[str | None] = mapped_column(String(100))
    name: Mapped[str | None] = mapped_column(String(200))
    street_address: Mapped[str | None] = mapped_column(String(500))
    city: Mapped[str | None] = mapped_column(String(200))
    postcode: Mapped[str | None] = mapped_column(String(20))
    lat: Mapped[float | None] = mapped_column(Float)
    lng: Mapped[float | None] = mapped_column(Float)
    status: Mapped[str | None] = mapped_column(String(20))
    shop_size: Mapped[int | None] = mapped_column(Integer)
    num_of_pos: Mapped[int | None] = mapped_column(Integer)
    last_synced_at: Mapped[datetime | None] = mapped_column(DateTime)

    station: Mapped["Station"] = relationship(back_populates="mol_station")
    services: Mapped[list["MolStationService"]] = relationship(
        back_populates="mol_station", cascade="all, delete-orphan"
    )
    cards: Mapped[list["MolStationCard"]] = relationship(
        back_populates="mol_station", cascade="all, delete-orphan"
    )
    gastro: Mapped[list["MolStationGastro"]] = relationship(
        back_populates="mol_station", cascade="all, delete-orphan"
    )


# ── MOL junction tables ───────────────────────────────────────────────────────

class MolStationService(Base):
    __tablename__ = "mol_station_service"

    mol_station_id: Mapped[int] = mapped_column(ForeignKey("mol_station.id"), primary_key=True)
    service_type_id: Mapped[int] = mapped_column(ForeignKey("mol_service_type.id"), primary_key=True)
    value: Mapped[str | None] = mapped_column(String(200))

    mol_station: Mapped["MolStation"] = relationship(back_populates="services")
    service_type: Mapped["MolServiceType"] = relationship(back_populates="station_services")


class MolStationCard(Base):
    __tablename__ = "mol_station_card"

    mol_station_id: Mapped[int] = mapped_column(ForeignKey("mol_station.id"), primary_key=True)
    card_type_id: Mapped[int] = mapped_column(ForeignKey("mol_card_type.id"), primary_key=True)

    mol_station: Mapped["MolStation"] = relationship(back_populates="cards")
    card_type: Mapped["MolCardType"] = relationship(back_populates="station_cards")


class MolStationGastro(Base):
    __tablename__ = "mol_station_gastro"

    mol_station_id: Mapped[int] = mapped_column(ForeignKey("mol_station.id"), primary_key=True)
    gastro_category_id: Mapped[int] = mapped_column(ForeignKey("mol_gastro_category.id"), primary_key=True)

    mol_station: Mapped["MolStation"] = relationship(back_populates="gastro")
    gastro_category: Mapped["MolGastroCategory"] = relationship(back_populates="station_gastros")
