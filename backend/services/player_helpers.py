"""Oyuncu listeleme, rating ortalamaları ve DTO dönüşümleri."""
from typing import Optional

from sqlalchemy.orm import Session

import models
import models_multivideo
from services import rating_helpers as rh
from services.combined_rating import apply_combined_to_player_payload
from services.report_text import strip_analysis_disclaimer

# Geriye uyumluluk
scout_ratings_for_legacy = rh.scout_ratings_for_legacy
scout_ratings_for_multivideo = rh.scout_ratings_for_multivideo
build_community_rating_summary = rh.build_community_rating_summary
build_community_rating_summary_mv = rh.build_community_rating_summary_mv


def player_to_dict(player: models.Player, db: Optional[Session] = None, current_user_id: Optional[int] = None):
    owner = player.owner
    payload = {
        "id": player.id,
        "user_id": player.user_id,
        "name": player.name,
        "age": player.age,
        "position": player.position,
        "overall_rating": player.overall_rating,
        "phone_number": owner.phone_number if owner else None,
        "ai_scout_report": strip_analysis_disclaimer(player.ai_scout_report),
        "video_url": getattr(player, "video_url", None),
        "source": "legacy",
        "scout_ratings": scout_ratings_for_legacy(db, player.id, current_user_id=current_user_id) if db else [],
    }
    if db:
        community = rh.build_community_rating_summary(db, player.id, current_user_id=current_user_id)
        apply_combined_to_player_payload(
            payload,
            ai_ovr=player.overall_rating or 0,
            community=community,
        )
    return payload


def build_community_rating_summary_legacy(db: Session, player_id: int, current_user_id: Optional[int] = None):
    return rh.build_community_rating_summary(db, player_id, current_user_id=current_user_id)


def build_community_rating_summary_mv_helper(db: Session, player_id: int, current_user_id: Optional[int] = None):
    return rh.build_community_rating_summary_mv(db, player_id, current_user_id=current_user_id)


# Eski isimler — api_routes import uyumu
build_community_rating_summary_mv = build_community_rating_summary_mv_helper


def calculate_overall_from_position(player: models.Player) -> int:
    values = []
    if player.position == "Forvet":
        values = [player.pace, player.finishing, player.dribbling, player.positioning]
    elif player.position == "Orta Saha":
        values = [player.vision, player.passing, player.ball_control, player.stamina]
    elif player.position == "Defans":
        values = [player.tackling, player.marking, player.strength, player.jumping]
    elif player.position == "Kaleci":
        values = [
            player.gk_reflexes,
            player.gk_diving,
            player.gk_handling,
            player.gk_positioning,
            player.gk_kicking,
        ]
    values = [v for v in values if v is not None]
    if not values:
        return 50
    return round(sum(values) / len(values))


def multivideo_to_public_dict(
    p: models_multivideo.PlayerMultiVideo,
    db: Optional[Session] = None,
    current_user_id: Optional[int] = None,
):
    owner = getattr(p, "owner", None)
    scout_ratings = (
        scout_ratings_for_multivideo(db, p.id, current_user_id=current_user_id)
        if db
        else []
    )

    raw_urls = [p.video_1_url, p.video_2_url, p.video_3_url]
    raw_skills = [p.video_1_skill, p.video_2_skill, p.video_3_skill]
    raw_ratings = [p.video_1_rating, p.video_2_rating, p.video_3_rating]
    raw_analyses = [p.video_1_ai_analysis, p.video_2_ai_analysis, p.video_3_ai_analysis]

    videos_list = [
        {
            "url": raw_urls[i],
            "skill": raw_skills[i],
            "rating": raw_ratings[i],
            "analysis": raw_analyses[i],
            "slot": i + 1,
        }
        for i in range(3)
        if raw_urls[i]
    ]
    main_video_url = raw_urls[0] or raw_urls[1] or raw_urls[2]
    skills = p.skill_scores or {}

    birth_date = None
    if owner and owner.birth_date:
        birth_date = (
            owner.birth_date.isoformat()
            if hasattr(owner.birth_date, "isoformat")
            else str(owner.birth_date)
        )

    ai_ovr = p.overall_rating or 0
    community = (
        rh.build_community_rating_summary_mv(db, p.id, current_user_id=current_user_id)
        if db
        else {}
    )

    payload = {
        "id": p.id,
        "user_id": p.user_id,
        "name": p.name,
        "age": p.age,
        "position": p.position,
        "overall_rating": ai_ovr,
        "phone_number": owner.phone_number if owner else None,
        "profile_image_url": p.profile_image_url or (owner.profile_image_url if owner else None),
        "birth_date": birth_date,
        "city": p.city or (owner.city if owner else None),
        "club_name": p.club_name,
        "club_history": p.club_history,
        "preferred_foot": p.preferred_foot,
        "height_cm": p.height_cm,
        "weight_kg": p.weight_kg,
        "previous_overall_rating": p.previous_overall_rating,
        "ai_scout_report": strip_analysis_disclaimer(p.ai_summary_report),
        "source": "multivideo",
        "scout_ratings": scout_ratings,
        "video_url": main_video_url,
        "videos": videos_list,
        "pac": skills.get("pace", p.overall_rating),
        "sho": skills.get("finishing", p.overall_rating),
        "pas": skills.get("passing", p.overall_rating),
        "dri": skills.get("dribbling", p.overall_rating),
        "def_": skills.get("defending", p.overall_rating),
        "phy": skills.get("strength", p.overall_rating),
        "pace": skills.get("pace", p.overall_rating),
        "finishing": skills.get("finishing", p.overall_rating),
        "passing": skills.get("passing", p.overall_rating),
        "dribbling": skills.get("dribbling", p.overall_rating),
        "defending": skills.get("defending", p.overall_rating),
        "strength": skills.get("strength", p.overall_rating),
        "slot_breakdown": skills.get("slot_breakdown") or [],
        "analysis_version": skills.get("analysis_version"),
        "skill_scores": skills,
        "analysis_status": p.analysis_status,
        "analysis_error": p.analysis_error,
        "created_at": (
            p.created_at.isoformat()
            if p.created_at and hasattr(p.created_at, "isoformat")
            else None
        ),
        "updated_at": (
            p.updated_at.isoformat()
            if p.updated_at and hasattr(p.updated_at, "isoformat")
            else None
        ),
    }
    apply_combined_to_player_payload(payload, ai_ovr=ai_ovr, community=community)
    return payload


def resolve_player_detail(
    db: Session, player_id: int, current_user_id: Optional[int] = None
) -> dict:
    """Legacy veya multivideo oyuncu detayı + community_rating."""
    mv_player = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.id == player_id)
        .first()
    )
    if mv_player:
        return multivideo_to_public_dict(mv_player, db, current_user_id=current_user_id)

    player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if not player:
        return None

    return player_to_dict(player, db, current_user_id=current_user_id)
