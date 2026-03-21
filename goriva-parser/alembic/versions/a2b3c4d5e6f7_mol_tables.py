"""mol_tables

Revision ID: a2b3c4d5e6f7
Revises: 56ac57a55b24
Create Date: 2026-03-21 00:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "a2b3c4d5e6f7"
down_revision: Union[str, Sequence[str], None] = "56ac57a55b24"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "mol_service_type",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("code", sa.String(length=100), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code"),
    )
    op.create_table(
        "mol_card_type",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("code", sa.String(length=100), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code"),
    )
    op.create_table(
        "mol_gastro_category",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("code", sa.String(length=100), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code"),
    )
    op.create_table(
        "mol_station",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("station_id", sa.Integer(), nullable=False),
        sa.Column("mol_code", sa.String(length=50), nullable=False),
        sa.Column("company", sa.String(length=200), nullable=True),
        sa.Column("brand", sa.String(length=100), nullable=True),
        sa.Column("name", sa.String(length=200), nullable=True),
        sa.Column("street_address", sa.String(length=500), nullable=True),
        sa.Column("city", sa.String(length=200), nullable=True),
        sa.Column("postcode", sa.String(length=20), nullable=True),
        sa.Column("lat", sa.Float(), nullable=True),
        sa.Column("lng", sa.Float(), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=True),
        sa.Column("shop_size", sa.Integer(), nullable=True),
        sa.Column("num_of_pos", sa.Integer(), nullable=True),
        sa.Column("last_synced_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["station_id"], ["station.pk"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("mol_code"),
        sa.UniqueConstraint("station_id"),
    )
    op.create_table(
        "mol_station_service",
        sa.Column("mol_station_id", sa.Integer(), nullable=False),
        sa.Column("service_type_id", sa.Integer(), nullable=False),
        sa.Column("value", sa.String(length=200), nullable=True),
        sa.ForeignKeyConstraint(["mol_station_id"], ["mol_station.id"]),
        sa.ForeignKeyConstraint(["service_type_id"], ["mol_service_type.id"]),
        sa.PrimaryKeyConstraint("mol_station_id", "service_type_id"),
    )
    op.create_table(
        "mol_station_card",
        sa.Column("mol_station_id", sa.Integer(), nullable=False),
        sa.Column("card_type_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["mol_station_id"], ["mol_station.id"]),
        sa.ForeignKeyConstraint(["card_type_id"], ["mol_card_type.id"]),
        sa.PrimaryKeyConstraint("mol_station_id", "card_type_id"),
    )
    op.create_table(
        "mol_station_gastro",
        sa.Column("mol_station_id", sa.Integer(), nullable=False),
        sa.Column("gastro_category_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["mol_station_id"], ["mol_station.id"]),
        sa.ForeignKeyConstraint(["gastro_category_id"], ["mol_gastro_category.id"]),
        sa.PrimaryKeyConstraint("mol_station_id", "gastro_category_id"),
    )


def downgrade() -> None:
    op.drop_table("mol_station_gastro")
    op.drop_table("mol_station_card")
    op.drop_table("mol_station_service")
    op.drop_table("mol_station")
    op.drop_table("mol_gastro_category")
    op.drop_table("mol_card_type")
    op.drop_table("mol_service_type")
