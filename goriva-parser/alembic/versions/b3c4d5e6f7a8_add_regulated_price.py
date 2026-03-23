"""add_regulated_price

Revision ID: b3c4d5e6f7a8
Revises: a2b3c4d5e6f7
Create Date: 2026-03-23 00:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "b3c4d5e6f7a8"
down_revision: Union[str, Sequence[str], None] = "a2b3c4d5e6f7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "regulated_price",
        sa.Column("pk", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("valid_from", sa.Date(), nullable=False),
        sa.Column("petrol_price", sa.Float(), nullable=True),
        sa.Column("diesel_price", sa.Float(), nullable=True),
        sa.PrimaryKeyConstraint("pk"),
        sa.UniqueConstraint("valid_from"),
    )
    op.create_index("ix_regulated_price_valid_from", "regulated_price", ["valid_from"])


def downgrade() -> None:
    op.drop_index("ix_regulated_price_valid_from", table_name="regulated_price")
    op.drop_table("regulated_price")
