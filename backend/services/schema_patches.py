"""SQLite geliştirme: eksik kolonları ekle (create_all ALTER yapmaz)."""
from __future__ import annotations

from sqlalchemy import inspect, text

from database import engine

_USER_COLUMNS = {
    "referral_code": "VARCHAR(16)",
    "referred_by_user_id": "INTEGER",
    "last_login_fingerprint": "VARCHAR(64)",
}


def ensure_users_columns() -> None:
    if engine.dialect.name != "sqlite":
        return
    insp = inspect(engine)
    if "users" not in insp.get_table_names():
        return
    existing = {c["name"] for c in insp.get_columns("users")}
    with engine.begin() as conn:
        for name, col_type in _USER_COLUMNS.items():
            if name not in existing:
                conn.execute(text(f"ALTER TABLE users ADD COLUMN {name} {col_type}"))


_MULTIVIDEO_COLUMNS = {
    "discover_visible": "BOOLEAN DEFAULT 0",
    "analysis_status": "VARCHAR(20)",
    "analysis_error": "TEXT",
    "kosu_slot": "INTEGER",
    "kosu_skill_name": "VARCHAR",
    "kosu_video_flat_url": "VARCHAR",
    "kosu_video_uphill_url": "VARCHAR",
    "kosu_videos_by_slot": "JSON",
}


def ensure_schema_patches() -> None:
    ensure_users_columns()
    ensure_players_multivideo_columns()


def ensure_players_multivideo_columns() -> None:
    if engine.dialect.name != "sqlite":
        return
    insp = inspect(engine)
    if "players_multivideo" not in insp.get_table_names():
        return
    existing = {c["name"] for c in insp.get_columns("players_multivideo")}
    added_discover = False
    with engine.begin() as conn:
        for name, col_type in _MULTIVIDEO_COLUMNS.items():
            if name not in existing:
                conn.execute(
                    text(f"ALTER TABLE players_multivideo ADD COLUMN {name} {col_type}")
                )
                if name == "discover_visible":
                    added_discover = True
    if added_discover:
        from database import SessionLocal
        from services.discover_visibility import backfill_all_discover_visibility

        db = SessionLocal()
        try:
            backfill_all_discover_visibility(db)
        finally:
            db.close()
