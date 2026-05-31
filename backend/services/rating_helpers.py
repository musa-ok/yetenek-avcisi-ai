"""Community rating: outlier-aware averages, counts, scout listesi."""
from __future__ import annotations

import statistics
from datetime import datetime
from typing import Any, Optional, Sequence, Type

from sqlalchemy.orm import Session

import models


METRIC_FIELDS = ("pac", "sho", "pas", "dri", "def_", "phy")
METRIC_API_KEYS = ("PAC", "SHO", "PAS", "DRI", "DEF", "PHY")


def _iso(dt: Optional[datetime]) -> Optional[str]:
    if dt is None:
        return None
    return dt.isoformat() if hasattr(dt, "isoformat") else str(dt)


def weighted_metric_average(values: Sequence[int]) -> Optional[int]:
    """Aşırı uç puanları medyana yakın ağırlıkla yumuşatır."""
    if not values:
        return None
    if len(values) == 1:
        return int(values[0])
    med = float(statistics.median(values))
    weighted_sum = 0.0
    weight_sum = 0.0
    for v in values:
        dist = abs(v - med)
        w = max(0.2, 1.0 - (dist / 30.0))
        weighted_sum += v * w
        weight_sum += w
    return round(weighted_sum / weight_sum) if weight_sum else None


def _summarize_ratings(
    rows: list,
    *,
    current_user_id: Optional[int] = None,
) -> dict[str, Any]:
    if not rows:
        empty = {k: None for k in METRIC_API_KEYS}
        empty["OVR"] = None
        empty["rating_count"] = 0
        empty["current_user_has_rated"] = False
        return empty

    metrics: dict[str, list[int]] = {f: [] for f in METRIC_FIELDS}
    scout_list: list[dict[str, Any]] = []
    current_user_has_rated = False

    for rating_row, user_row in rows:
        r = rating_row
        u = user_row
        for f in METRIC_FIELDS:
            metrics[f].append(getattr(r, f))
        avg = round(
            (r.pac + r.sho + r.pas + r.dri + r.def_ + r.phy) / 6
        )
        is_mine = current_user_id is not None and r.reviewer_id == current_user_id
        if is_mine:
            current_user_has_rated = True
        scout_list.append(
            {
                "reviewer_id": r.reviewer_id,
                "scout_name": u.full_name or u.email or f"Scout #{u.id}",
                "score": avg,
                "pac": r.pac,
                "sho": r.sho,
                "pas": r.pas,
                "dri": r.dri,
                "def": r.def_,
                "phy": r.phy,
                "created_at": _iso(r.created_at),
                "updated_at": _iso(r.updated_at),
                "is_mine": is_mine,
            }
        )

    pac = weighted_metric_average(metrics["pac"])
    sho = weighted_metric_average(metrics["sho"])
    pas = weighted_metric_average(metrics["pas"])
    dri = weighted_metric_average(metrics["dri"])
    deff = weighted_metric_average(metrics["def_"])
    phy = weighted_metric_average(metrics["phy"])
    parts = [pac, sho, pas, dri, deff, phy]
    ovr = round(sum(parts) / 6) if all(p is not None for p in parts) else None

    return {
        "PAC": pac,
        "SHO": sho,
        "PAS": pas,
        "DRI": dri,
        "DEF": deff,
        "PHY": phy,
        "OVR": ovr,
        "rating_count": len(rows),
        "current_user_has_rated": current_user_has_rated,
        "scout_ratings_detail": scout_list,
    }


def build_community_rating_summary(
    db: Session,
    player_id: int,
    *,
    current_user_id: Optional[int] = None,
) -> dict[str, Any]:
    rows = (
        db.query(models.Rating, models.User)
        .join(models.User, models.User.id == models.Rating.reviewer_id)
        .filter(models.Rating.player_id == player_id)
        .order_by(models.Rating.updated_at.desc(), models.Rating.created_at.desc())
        .all()
    )
    summary = _summarize_ratings(rows, current_user_id=current_user_id)
    summary.pop("scout_ratings_detail", None)
    return summary


def build_community_rating_summary_mv(
    db: Session,
    player_id: int,
    *,
    current_user_id: Optional[int] = None,
) -> dict[str, Any]:
    rows = (
        db.query(models.MultiVideoRating, models.User)
        .join(models.User, models.User.id == models.MultiVideoRating.reviewer_id)
        .filter(models.MultiVideoRating.player_id == player_id)
        .order_by(
            models.MultiVideoRating.updated_at.desc(),
            models.MultiVideoRating.created_at.desc(),
        )
        .all()
    )
    summary = _summarize_ratings(rows, current_user_id=current_user_id)
    summary.pop("scout_ratings_detail", None)
    return summary


def scout_ratings_for_legacy(
    db: Session,
    player_id: int,
    *,
    current_user_id: Optional[int] = None,
) -> list[dict[str, Any]]:
    rows = (
        db.query(models.Rating, models.User)
        .join(models.User, models.User.id == models.Rating.reviewer_id)
        .filter(models.Rating.player_id == player_id)
        .order_by(models.Rating.updated_at.desc(), models.Rating.created_at.desc())
        .all()
    )
    return _summarize_ratings(rows, current_user_id=current_user_id).get(
        "scout_ratings_detail", []
    )


def scout_ratings_for_multivideo(
    db: Session,
    player_id: int,
    *,
    current_user_id: Optional[int] = None,
) -> list[dict[str, Any]]:
    rows = (
        db.query(models.MultiVideoRating, models.User)
        .join(models.User, models.User.id == models.MultiVideoRating.reviewer_id)
        .filter(models.MultiVideoRating.player_id == player_id)
        .order_by(
            models.MultiVideoRating.updated_at.desc(),
            models.MultiVideoRating.created_at.desc(),
        )
        .all()
    )
    return _summarize_ratings(rows, current_user_id=current_user_id).get(
        "scout_ratings_detail", []
    )


def assert_can_rate_player(
    current_user: models.User,
    *,
    player_user_id: Optional[int],
) -> None:
    from fastapi import HTTPException

    role = (current_user.role or "").strip().lower()
    if role == "futbolcu":
        raise HTTPException(
            status_code=403,
            detail="Sadece onaylı Scout hesapları puan verebilir.",
        )
    if role == "pending_scout":
        raise HTTPException(
            status_code=403,
            detail="Scout hesabınız henüz onaylanmadı. Puan vermek için admin onayını bekleyin.",
        )
    if role not in ("scout", "admin"):
        raise HTTPException(
            status_code=403,
            detail="Sadece onaylı Scout hesapları puan verebilir.",
        )
    if player_user_id is not None and player_user_id == current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Kendi profilinize puan veremezsiniz.",
        )


def upsert_rating_row(
    db: Session,
    model_cls: Type,
    *,
    reviewer_id: int,
    player_id: int,
    rating,
) -> tuple[Any, bool]:
    """Kayıt varsa günceller (updated_at), yoksa oluşturur. (row, created) döner."""
    existing = (
        db.query(model_cls)
        .filter(
            model_cls.player_id == player_id,
            model_cls.reviewer_id == reviewer_id,
        )
        .first()
    )
    if existing:
        existing.pac = rating.pac
        existing.sho = rating.sho
        existing.pas = rating.pas
        existing.dri = rating.dri
        existing.def_ = rating.def_
        existing.phy = rating.phy
        db.commit()
        db.refresh(existing)
        return existing, False

    row = model_cls(
        reviewer_id=reviewer_id,
        player_id=player_id,
        pac=rating.pac,
        sho=rating.sho,
        pas=rating.pas,
        dri=rating.dri,
        def_=rating.def_,
        phy=rating.phy,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row, True
