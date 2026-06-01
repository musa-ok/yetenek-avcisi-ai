"""Bildirim tetikleyicileri için yardımcılar."""
from __future__ import annotations

import hashlib
from typing import Optional

from fastapi import Request
from sqlalchemy.orm import Session

import models
import models_multivideo
import models_product


def resolve_player_owner_user_id(
    db: Session, player_id: int, player_source: str
) -> Optional[int]:
    source = (player_source or "multivideo").strip().lower()
    if source == "legacy":
        row = db.query(models.Player).filter(models.Player.id == player_id).first()
        return row.user_id if row else None
    row = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.id == player_id)
        .first()
    )
    return row.user_id if row else None


def resolve_player_display_name(
    db: Session, player_id: int, player_source: str
) -> str:
    source = (player_source or "multivideo").strip().lower()
    if source == "legacy":
        row = db.query(models.Player).filter(models.Player.id == player_id).first()
        return (row.name if row else None) or "Oyuncu"
    row = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.id == player_id)
        .first()
    )
    return (row.name if row else None) or "Oyuncu"


def admin_user_ids(db: Session) -> list[int]:
    admins = (
        db.query(models.User.id)
        .filter(models.User.is_active.is_(True))
        .filter(models.User.role.ilike("admin"))
        .all()
    )
    return [a[0] for a in admins]


def login_fingerprint(request: Optional[Request]) -> Optional[str]:
    if request is None:
        return None
    ua = (request.headers.get("user-agent") or "").strip()
    ip = (
        request.headers.get("x-forwarded-for", "").split(",")[0].strip()
        or (request.client.host if request.client else "")
    )
    raw = f"{ua}|{ip}"
    if not raw.strip("|"):
        return None
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:64]


def record_login_and_notify_if_new_device(
    db: Session, user: models.User, request: Optional[Request]
) -> None:
    fp = login_fingerprint(request)
    if not fp:
        return
    prev = getattr(user, "last_login_fingerprint", None)
    if prev and prev != fp:
        from services.notifications import notify_security_new_login

        notify_security_new_login(db, user.id)
    user.last_login_fingerprint = fp
    db.commit()


def maybe_notify_videos_ready(
    db: Session,
    player: models_multivideo.PlayerMultiVideo,
    *,
    was_complete: bool,
) -> None:
    if was_complete or not player.is_complete or not player.user_id:
        return
    status = (player.analysis_status or "").strip().lower()
    if status in ("processing", "completed"):
        return
    from services.notifications import notify_videos_ready_for_finalize

    notify_videos_ready_for_finalize(
        db,
        player.user_id,
        player.id,
        player.name or "Oyuncun",
    )


def notify_shortlist_watchers_analysis(
    db: Session,
    *,
    player_id: int,
    player_name: str,
    player_user_id: Optional[int],
) -> None:
    rows = (
        db.query(models_product.ShortlistItem, models_product.Shortlist)
        .join(
            models_product.Shortlist,
            models_product.Shortlist.id == models_product.ShortlistItem.shortlist_id,
        )
        .filter(
            models_product.ShortlistItem.player_id == player_id,
            models_product.ShortlistItem.player_source == "multivideo",
        )
        .all()
    )
    from services.notifications import notify_shortlist_player_analysis

    seen: set[int] = set()
    for _item, sl in rows:
        owner_id = sl.owner_id
        if owner_id in seen:
            continue
        if player_user_id and owner_id == player_user_id:
            continue
        seen.add(owner_id)
        notify_shortlist_player_analysis(
            db,
            owner_id,
            player_id,
            player_name,
        )
