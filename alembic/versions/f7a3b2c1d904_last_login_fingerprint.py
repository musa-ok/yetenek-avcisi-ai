"""users.last_login_fingerprint for new-device login alerts

Revision ID: f7a3b2c1d904
Revises: e6f2a1b4c903
Create Date: 2026-05-29

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "f7a3b2c1d904"
down_revision: Union[str, None] = "e6f2a1b4c903"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("users", schema=None) as batch_op:
        batch_op.add_column(sa.Column("last_login_fingerprint", sa.String(length=64), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("users", schema=None) as batch_op:
        batch_op.drop_column("last_login_fingerprint")
