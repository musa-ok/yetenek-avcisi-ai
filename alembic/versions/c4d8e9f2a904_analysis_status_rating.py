"""analysis_status on multivideo players

Revision ID: c4d8e9f2a904
Revises: b2c4e8f1a903
Create Date: 2026-05-30

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "c4d8e9f2a904"
down_revision: Union[str, None] = "b2c4e8f1a903"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("players_multivideo", schema=None) as batch_op:
        batch_op.add_column(sa.Column("analysis_status", sa.String(length=20), nullable=True))
        batch_op.add_column(sa.Column("analysis_error", sa.Text(), nullable=True))
        batch_op.create_index(
            batch_op.f("ix_players_multivideo_analysis_status"),
            ["analysis_status"],
            unique=False,
        )


def downgrade() -> None:
    with op.batch_alter_table("players_multivideo", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_players_multivideo_analysis_status"))
        batch_op.drop_column("analysis_error")
        batch_op.drop_column("analysis_status")
