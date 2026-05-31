"""Koşu videoları slot başına JSON

Revision ID: e6f2a1b4c903
Revises: d5e1f0a3b812
Create Date: 2026-05-30

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "e6f2a1b4c903"
down_revision: Union[str, None] = "d5e1f0a3b812"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("players_multivideo", schema=None) as batch_op:
        batch_op.add_column(sa.Column("kosu_videos_by_slot", sa.JSON(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("players_multivideo", schema=None) as batch_op:
        batch_op.drop_column("kosu_videos_by_slot")
