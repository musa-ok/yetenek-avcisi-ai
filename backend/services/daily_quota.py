"""Günlük analiz kotası — sadece finalize başlatılınca düşer."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy.orm import Session

import models


def reserve_daily_analysis_quota(
    db: Session,
    user: models.User,
    *,
    player_analysis_status: str | None,
) -> None:
    """
    Oyuncu kaydı açılınca değil; analiz (finalize) başlatılınca 1 hak düşer.
    Aynı oyuncuda yeniden finalize (failed sonrası) tekrar hak düşürmez.
    """
    status = (player_analysis_status or "").strip().lower()
    if status in ("pending", "processing", "completed"):
        return

    now_utc = datetime.now(timezone.utc)
    if not user.last_analysis_date or user.last_analysis_date.date() != now_utc.date():
        user.daily_analyses_count = 0
        user.last_analysis_date = now_utc

    if (user.daily_analyses_count or 0) >= 3:
        from services.notifications import notify_quota_exhausted

        notify_quota_exhausted(db, user.id)
        raise HTTPException(
            status_code=403,
            detail="Günlük 3 yetenek analizi limitinizi doldurdunuz. Lütfen yarın tekrar deneyin.",
        )

    user.daily_analyses_count = (user.daily_analyses_count or 0) + 1
    db.commit()
    if (user.daily_analyses_count or 0) >= 3:
        from services.notifications import notify_quota_last_used

        notify_quota_last_used(db, user.id)
