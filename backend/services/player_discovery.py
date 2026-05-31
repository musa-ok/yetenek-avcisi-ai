"""Keşfet: filtreli oyuncu listesi."""
from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

import models_multivideo
from services.player_helpers import multivideo_to_public_dict


def query_discoverable_players(
    db: Session,
    *,
    position: Optional[str] = None,
    min_age: Optional[int] = None,
    max_age: Optional[int] = None,
    min_ovr: Optional[int] = None,
    max_ovr: Optional[int] = None,
    city: Optional[str] = None,
    rising_7d: bool = False,
):
    q = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.ai_summary_report.isnot(None))
        .filter(models_multivideo.PlayerMultiVideo.overall_rating > 35)
    )
    if position and position.strip().lower() not in ("tum", "tüm", "all", ""):
        q = q.filter(models_multivideo.PlayerMultiVideo.position == position.strip())
    if min_age is not None:
        q = q.filter(models_multivideo.PlayerMultiVideo.age >= min_age)
    if max_age is not None:
        q = q.filter(models_multivideo.PlayerMultiVideo.age <= max_age)
    if min_ovr is not None:
        q = q.filter(models_multivideo.PlayerMultiVideo.overall_rating >= min_ovr)
    if max_ovr is not None:
        q = q.filter(models_multivideo.PlayerMultiVideo.overall_rating <= max_ovr)
    if city and city.strip():
        needle = f"%{city.strip()}%"
        q = q.filter(models_multivideo.PlayerMultiVideo.city.ilike(needle))
    if rising_7d:
        since = datetime.now(timezone.utc) - timedelta(days=7)
        q = q.filter(
            and_(
                models_multivideo.PlayerMultiVideo.updated_at.isnot(None),
                models_multivideo.PlayerMultiVideo.updated_at >= since,
                models_multivideo.PlayerMultiVideo.previous_overall_rating.isnot(None),
                models_multivideo.PlayerMultiVideo.overall_rating
                > models_multivideo.PlayerMultiVideo.previous_overall_rating,
            )
        )
    return q.all()


def discover_players_as_dicts(db: Session, **filters):
    players = query_discoverable_players(db, **filters)
    out = []
    for p in players:
        d = multivideo_to_public_dict(p, db)
        prev = p.previous_overall_rating
        cur = d.get("overall_rating") or p.overall_rating or 0
        d["rising_7d"] = bool(
            prev is not None and cur > prev and p.updated_at
        )
        d["ovr_delta"] = (cur - prev) if prev is not None else None
        out.append(d)

    min_ovr = filters.get("min_ovr")
    max_ovr = filters.get("max_ovr")
    if min_ovr is not None:
        out = [x for x in out if (x.get("overall_rating") or 0) >= min_ovr]
    if max_ovr is not None:
        out = [x for x in out if (x.get("overall_rating") or 0) <= max_ovr]

    out.sort(key=lambda x: x.get("overall_rating") or 0, reverse=True)
    return out
