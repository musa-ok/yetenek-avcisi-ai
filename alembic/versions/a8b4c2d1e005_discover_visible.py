"""players_multivideo.discover_visible for Keşfet vitrini

Revision ID: a8b4c2d1e005
Revises: f7a3b2c1d904
Create Date: 2026-05-29

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "a8b4c2d1e005"
down_revision: Union[str, None] = "f7a3b2c1d904"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("players_multivideo", schema=None) as batch_op:
        batch_op.add_column(
            sa.Column(
                "discover_visible",
                sa.Boolean(),
                nullable=False,
                server_default=sa.false(),
            )
        )
        batch_op.create_index(
            "ix_players_multivideo_discover_visible",
            ["discover_visible"],
            unique=False,
        )

    bind = op.get_bind()
    if bind is not None:
        from sqlalchemy.orm import Session

        from services.discover_visibility import backfill_all_discover_visibility

        session = Session(bind=bind)
        try:
            backfill_all_discover_visibility(session)
        finally:
            session.close()


def downgrade() -> None:
    with op.batch_alter_table("players_multivideo", schema=None) as batch_op:
        batch_op.drop_index("ix_players_multivideo_discover_visible")
        batch_op.drop_column("discover_visible")
