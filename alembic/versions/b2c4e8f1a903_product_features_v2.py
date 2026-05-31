"""product features v2: profile fields, scout notes, shortlist, notifications

Revision ID: b2c4e8f1a903
Revises: 9ae55be29a83
Create Date: 2026-05-29

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b2c4e8f1a903"
down_revision: Union[str, None] = "9ae55be29a83"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("fcm_device_token", sa.String(), nullable=True))
    op.add_column("users", sa.Column("city", sa.String(), nullable=True))

    op.add_column("players_multivideo", sa.Column("previous_overall_rating", sa.Integer(), nullable=True))
    op.add_column("players_multivideo", sa.Column("profile_image_url", sa.String(), nullable=True))
    op.add_column("players_multivideo", sa.Column("city", sa.String(), nullable=True))
    op.add_column("players_multivideo", sa.Column("club_name", sa.String(), nullable=True))
    op.add_column("players_multivideo", sa.Column("club_history", sa.Text(), nullable=True))
    op.add_column("players_multivideo", sa.Column("preferred_foot", sa.String(length=20), nullable=True))
    op.add_column("players_multivideo", sa.Column("height_cm", sa.Integer(), nullable=True))
    op.add_column("players_multivideo", sa.Column("weight_kg", sa.Integer(), nullable=True))

    op.create_table(
        "scout_notes",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("scout_id", sa.Integer(), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("player_source", sa.String(length=20), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("visibility", sa.String(length=20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["scout_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_scout_notes_id"), "scout_notes", ["id"], unique=False)
    op.create_index(op.f("ix_scout_notes_scout_id"), "scout_notes", ["scout_id"], unique=False)
    op.create_index(op.f("ix_scout_notes_player_id"), "scout_notes", ["player_id"], unique=False)

    op.create_table(
        "shortlists",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("owner_id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("share_token", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["owner_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("share_token"),
    )
    op.create_index(op.f("ix_shortlists_id"), "shortlists", ["id"], unique=False)
    op.create_index(op.f("ix_shortlists_owner_id"), "shortlists", ["owner_id"], unique=False)
    op.create_index(op.f("ix_shortlists_share_token"), "shortlists", ["share_token"], unique=True)

    op.create_table(
        "shortlist_items",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("shortlist_id", sa.Integer(), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=False),
        sa.Column("player_source", sa.String(length=20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["shortlist_id"], ["shortlists.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("shortlist_id", "player_id", "player_source", name="uq_shortlist_player"),
    )
    op.create_index(op.f("ix_shortlist_items_id"), "shortlist_items", ["id"], unique=False)
    op.create_index(op.f("ix_shortlist_items_shortlist_id"), "shortlist_items", ["shortlist_id"], unique=False)
    op.create_index(op.f("ix_shortlist_items_player_id"), "shortlist_items", ["player_id"], unique=False)

    op.create_table(
        "app_notifications",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("kind", sa.String(length=40), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("body", sa.Text(), nullable=True),
        sa.Column("payload_json", sa.Text(), nullable=True),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_app_notifications_id"), "app_notifications", ["id"], unique=False)
    op.create_index(op.f("ix_app_notifications_user_id"), "app_notifications", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_table("app_notifications")
    op.drop_table("shortlist_items")
    op.drop_table("shortlists")
    op.drop_table("scout_notes")

    op.drop_column("players_multivideo", "weight_kg")
    op.drop_column("players_multivideo", "height_cm")
    op.drop_column("players_multivideo", "preferred_foot")
    op.drop_column("players_multivideo", "club_history")
    op.drop_column("players_multivideo", "club_name")
    op.drop_column("players_multivideo", "city")
    op.drop_column("players_multivideo", "profile_image_url")
    op.drop_column("players_multivideo", "previous_overall_rating")

    op.drop_column("users", "city")
    op.drop_column("users", "fcm_device_token")
