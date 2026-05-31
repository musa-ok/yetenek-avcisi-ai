"""Koşu slotu: 20m düz + 10m yokuş ayrı URL alanları

Revision ID: d5e1f0a3b812
Revises: c4d8e9f2a904
Create Date: 2026-05-30

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "d5e1f0a3b812"
down_revision: Union[str, None] = "c4d8e9f2a904"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("players_multivideo", schema=None) as batch_op:
        batch_op.add_column(sa.Column("kosu_slot", sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column("kosu_skill_name", sa.String(), nullable=True))
        batch_op.add_column(sa.Column("kosu_video_flat_url", sa.String(), nullable=True))
        batch_op.add_column(sa.Column("kosu_video_uphill_url", sa.String(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("players_multivideo", schema=None) as batch_op:
        batch_op.drop_column("kosu_video_uphill_url")
        batch_op.drop_column("kosu_video_flat_url")
        batch_op.drop_column("kosu_skill_name")
        batch_op.drop_column("kosu_slot")
