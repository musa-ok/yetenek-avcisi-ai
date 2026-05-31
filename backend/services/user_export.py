"""KVKK veri taşınabilirliği — kullanıcı verisi JSON export."""
from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy.orm import Session

import models
import models_multivideo
import models_product


def _iso(dt) -> str | None:
    if dt is None:
        return None
    return dt.isoformat() if hasattr(dt, "isoformat") else str(dt)


def export_user_data(db: Session, user: models.User) -> dict[str, Any]:
    mv_players = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.user_id == user.id)
        .all()
    )
    legacy_players = (
        db.query(models.Player).filter(models.Player.user_id == user.id).all()
    )
    ratings_mv = (
        db.query(models.MultiVideoRating)
        .filter(models.MultiVideoRating.reviewer_id == user.id)
        .all()
    )
    ratings_legacy = (
        db.query(models.Rating).filter(models.Rating.reviewer_id == user.id).all()
    )
    notes = (
        db.query(models_product.ScoutNote)
        .filter(models_product.ScoutNote.scout_id == user.id)
        .all()
    )

    return {
        "exported_at": datetime.utcnow().isoformat() + "Z",
        "format_version": "kvkk_export_v1",
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role,
            "phone_number": user.phone_number,
            "city": user.city,
            "birth_date": _iso(user.birth_date),
            "age": user.age,
            "referral_code": user.referral_code,
            "referred_by_user_id": user.referred_by_user_id,
            "created_at": _iso(user.created_at),
            "is_verified": user.is_verified,
        },
        "multivideo_profiles": [
            {
                "id": p.id,
                "name": p.name,
                "position": p.position,
                "overall_rating": p.overall_rating,
                "city": p.city,
                "created_at": _iso(p.created_at),
            }
            for p in mv_players
        ],
        "legacy_players": [
            {
                "id": p.id,
                "name": p.name,
                "position": p.position,
                "overall_rating": p.overall_rating,
            }
            for p in legacy_players
        ],
        "scout_ratings_given": [
            {
                "player_id": r.player_id,
                "pac": r.pac,
                "sho": r.sho,
                "pas": r.pas,
                "dri": r.dri,
                "def": r.def_,
                "phy": r.phy,
                "created_at": _iso(r.created_at),
            }
            for r in ratings_mv
        ]
        + [
            {
                "player_id": r.player_id,
                "pac": r.pac,
                "created_at": _iso(r.created_at),
            }
            for r in ratings_legacy
        ],
        "scout_notes_authored": [
            {"player_id": n.player_id, "body": n.body, "created_at": _iso(n.created_at)}
            for n in notes
        ],
        "privacy_notice": "Bu dosya KVKK kapsamında talep edilen kişisel veri özetidir.",
    }
