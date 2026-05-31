"""Ürün UX: profil v2, scout notu, shortlist, bildirim, karşılaştırma."""
import json
import os
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session

import models
import models_multivideo
import models_product
import schemas_product as sp
from database import get_db
from deps import get_current_user, get_optional_user, require_scout
from services import player_helpers as ph
from services.notifications import create_notification
from services.player_discovery import discover_players_as_dicts

router = APIRouter(tags=["Product"])


def _note_to_dict(note: models_product.ScoutNote, viewer_id: Optional[int], scout_name: str):
    return {
        "id": note.id,
        "scout_id": note.scout_id,
        "scout_name": scout_name,
        "player_id": note.player_id,
        "player_source": note.player_source,
        "body": note.body,
        "visibility": note.visibility,
        "created_at": note.created_at.isoformat() if note.created_at else None,
        "updated_at": note.updated_at.isoformat() if note.updated_at else None,
        "is_mine": viewer_id is not None and note.scout_id == viewer_id,
    }


def _profile_block(p: models_multivideo.PlayerMultiVideo, owner: Optional[models.User]):
    birth = owner.birth_date.isoformat() if owner and owner.birth_date else None
    return {
        "profile_image_url": p.profile_image_url or (owner.profile_image_url if owner else None),
        "birth_date": birth,
        "city": p.city or (owner.city if owner else None),
        "club_name": p.club_name,
        "club_history": p.club_history,
        "preferred_foot": p.preferred_foot,
        "height_cm": p.height_cm,
        "weight_kg": p.weight_kg,
    }


def _skills_block(p: models_multivideo.PlayerMultiVideo):
    skills = p.skill_scores or {}
    ovr = p.overall_rating or 50
    return {
        "pac": skills.get("pace", ovr),
        "sho": skills.get("finishing", ovr),
        "pas": skills.get("passing", ovr),
        "dri": skills.get("dribbling", ovr),
        "def": skills.get("defending", ovr),
        "phy": skills.get("strength", ovr),
    }


@router.get("/me/multivideo-profile")
def get_my_multivideo_profile(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Giriş yapan kullanıcının en güncel multivideo oyuncu profili (analiz şart değil)."""
    player = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.user_id == current_user.id)
        .order_by(models_multivideo.PlayerMultiVideo.id.desc())
        .first()
    )
    if not player:
        return {"player_id": None}
    return {
        "player_id": player.id,
        "position": player.position,
        **_profile_block(player, current_user),
    }


    return current_user


@router.patch("/me/multivideo-profile")
def upsert_my_multivideo_profile(
    body: sp.PlayerProfileV2Update,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Futbolcu Scoutiq alanlarini kaydet — kayit yoksa olusturur (analiz kotasi harcamaz)."""
    player = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.user_id == current_user.id)
        .order_by(models_multivideo.PlayerMultiVideo.id.desc())
        .first()
    )
    if not player:
        from position_skills_config import get_position_code

        player = models_multivideo.PlayerMultiVideo(
            user_id=current_user.id,
            name=current_user.full_name or current_user.email.split("@")[0],
            age=current_user.calculate_age() if hasattr(current_user, "calculate_age") else (current_user.age or 18),
            position="Orta Saha",
            position_code=get_position_code("Orta Saha"),
            overall_rating=0,
            skill_scores={},
            ai_strengths=[],
            ai_improvements=[],
        )
        db.add(player)
        db.flush()

    data = body.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(player, k, v)
    db.commit()
    db.refresh(player)
    return {
        "player_id": player.id,
        "position": player.position,
        **_profile_block(player, current_user),
    }


@router.patch("/players/multivideo/{player_id}/profile")
def update_multivideo_profile(
    player_id: int,
    body: sp.PlayerProfileV2Update,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    player = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.id == player_id)
        .first()
    )
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadi.")
    if player.user_id != current_user.id and (current_user.role or "").lower() != "admin":
        raise HTTPException(status_code=403, detail="Sadece kendi profilinizi duzenleyebilirsiniz.")

    data = body.model_dump(exclude_unset=True)
    for k, v in data.items():
        setattr(player, k, v)
    db.commit()
    db.refresh(player)
    payload = ph.multivideo_to_public_dict(player, db)
    payload["community_rating"] = ph.build_community_rating_summary_mv(db, player_id)
    return payload


@router.get("/players/discover")
def discover_players(
    position: Optional[str] = Query(None),
    min_age: Optional[int] = Query(None, ge=10, le=50),
    max_age: Optional[int] = Query(None, ge=10, le=50),
    min_ovr: Optional[int] = Query(None, ge=1, le=99),
    max_ovr: Optional[int] = Query(None, ge=1, le=99),
    city: Optional[str] = Query(None),
    rising_7d: bool = Query(False),
    db: Session = Depends(get_db),
):
    return discover_players_as_dicts(
        db,
        position=position,
        min_age=min_age,
        max_age=max_age,
        min_ovr=min_ovr,
        max_ovr=max_ovr,
        city=city,
        rising_7d=rising_7d,
    )


@router.get("/players/compare")
def compare_players(
    a: int = Query(..., description="Oyuncu A id"),
    b: int = Query(..., description="Oyuncu B id"),
    db: Session = Depends(get_db),
):
    def _side(pid: int) -> dict:
        p = (
            db.query(models_multivideo.PlayerMultiVideo)
            .filter(models_multivideo.PlayerMultiVideo.id == pid)
            .first()
        )
        if not p:
            raise HTTPException(status_code=404, detail=f"Oyuncu {pid} bulunamadi.")
        owner = db.query(models.User).filter(models.User.id == p.user_id).first()
        comm = ph.build_community_rating_summary_mv(db, pid)
        skills = _skills_block(p)
        if comm.get("PAC"):
            skills = {
                "pac": comm["PAC"],
                "sho": comm["SHO"],
                "pas": comm["PAS"],
                "dri": comm["DRI"],
                "def": comm["DEF"],
                "phy": comm["PHY"],
            }
        return {
            "id": p.id,
            "name": p.name,
            "position": p.position,
            "age": p.age,
            "overall_rating": p.overall_rating or 0,
            "community_rating": comm,
            "profile": _profile_block(p, owner),
            "skills": skills,
        }

    return {"player_a": _side(a), "player_b": _side(b)}


# --- Scout notes ---
@router.get("/players/{player_id}/notes")
def list_player_notes(
    player_id: int,
    player_source: str = Query("multivideo"),
    db: Session = Depends(get_db),
    current_user: Optional[models.User] = Depends(get_optional_user),
):
    viewer_id = current_user.id if current_user else None
    q = db.query(models_product.ScoutNote, models.User).join(
        models.User, models.User.id == models_product.ScoutNote.scout_id
    ).filter(
        models_product.ScoutNote.player_id == player_id,
        models_product.ScoutNote.player_source == player_source,
    )
    if viewer_id is None:
        q = q.filter(models_product.ScoutNote.visibility == "public")
    else:
        q = q.filter(
            (models_product.ScoutNote.visibility == "public")
            | (models_product.ScoutNote.scout_id == viewer_id)
        )
    rows = q.order_by(models_product.ScoutNote.created_at.desc()).all()
    return [
        _note_to_dict(n, viewer_id, u.full_name or u.email or f"Scout #{u.id}")
        for n, u in rows
    ]


@router.post("/players/{player_id}/notes", status_code=201)
def create_player_note(
    player_id: int,
    body: sp.ScoutNoteCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_scout),
):
    note = models_product.ScoutNote(
        scout_id=current_user.id,
        player_id=player_id,
        player_source=body.player_source,
        body=body.body.strip(),
        visibility=body.visibility,
    )
    db.add(note)
    db.commit()
    db.refresh(note)
    return _note_to_dict(
        note,
        current_user.id,
        current_user.full_name or current_user.email or "Scout",
    )


@router.patch("/notes/{note_id}")
def update_player_note(
    note_id: int,
    body: sp.ScoutNoteUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_scout),
):
    note = db.query(models_product.ScoutNote).filter(models_product.ScoutNote.id == note_id).first()
    if not note:
        raise HTTPException(status_code=404, detail="Not bulunamadi.")
    if note.scout_id != current_user.id:
        raise HTTPException(status_code=403, detail="Sadece kendi notunuzu duzenleyebilirsiniz.")
    if body.body is not None:
        note.body = body.body.strip()
    if body.visibility is not None:
        note.visibility = body.visibility
    db.commit()
    db.refresh(note)
    return _note_to_dict(
        note,
        current_user.id,
        current_user.full_name or current_user.email or "Scout",
    )


@router.delete("/notes/{note_id}", status_code=204)
def delete_player_note(
    note_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_scout),
):
    note = db.query(models_product.ScoutNote).filter(models_product.ScoutNote.id == note_id).first()
    if not note:
        raise HTTPException(status_code=404, detail="Not bulunamadi.")
    if note.scout_id != current_user.id:
        raise HTTPException(status_code=403, detail="Sadece kendi notunuzu silebilirsiniz.")
    db.delete(note)
    db.commit()


# --- Shortlists ---
def _shortlist_payload(sl: models_product.Shortlist, db: Session, request: Optional[Request] = None):
    items_out = []
    for it in sl.items:
        detail = ph.resolve_player_detail(db, it.player_id)
        items_out.append(
            {
                "player_id": it.player_id,
                "player_source": it.player_source,
                "player": detail,
            }
        )
    share_url = None
    if request:
        base = str(request.base_url).rstrip("/")
        share_url = f"{base}/shortlists/share/{sl.share_token}"
    return {
        "id": sl.id,
        "title": sl.title,
        "share_token": sl.share_token,
        "share_url": share_url,
        "item_count": len(sl.items),
        "items": items_out,
    }


@router.get("/shortlists/mine")
def my_shortlists(
    request: Request,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_scout),
):
    rows = (
        db.query(models_product.Shortlist)
        .filter(models_product.Shortlist.owner_id == current_user.id)
        .order_by(models_product.Shortlist.updated_at.desc())
        .all()
    )
    if not rows:
        default = models_product.Shortlist(owner_id=current_user.id, title="Favorilerim")
        db.add(default)
        db.commit()
        db.refresh(default)
        rows = [default]
    return [_shortlist_payload(s, db, request) for s in rows]


@router.post("/shortlists", status_code=201)
def create_shortlist(
    body: sp.ShortlistCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_scout),
):
    sl = models_product.Shortlist(owner_id=current_user.id, title=body.title.strip() or "Favorilerim")
    db.add(sl)
    db.commit()
    db.refresh(sl)
    return _shortlist_payload(sl, db, request)


@router.post("/shortlists/{shortlist_id}/items", status_code=201)
def add_shortlist_item(
    shortlist_id: int,
    body: sp.ShortlistItemAdd,
    request: Request,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_scout),
):
    sl = db.query(models_product.Shortlist).filter(models_product.Shortlist.id == shortlist_id).first()
    if not sl or sl.owner_id != current_user.id:
        raise HTTPException(status_code=404, detail="Liste bulunamadi.")
    existing = (
        db.query(models_product.ShortlistItem)
        .filter(
            models_product.ShortlistItem.shortlist_id == shortlist_id,
            models_product.ShortlistItem.player_id == body.player_id,
            models_product.ShortlistItem.player_source == body.player_source,
        )
        .first()
    )
    if not existing:
        db.add(
            models_product.ShortlistItem(
                shortlist_id=shortlist_id,
                player_id=body.player_id,
                player_source=body.player_source,
            )
        )
        db.commit()
    db.refresh(sl)
    return _shortlist_payload(sl, db, request)


@router.delete("/shortlists/{shortlist_id}/items/{player_id}", status_code=204)
def remove_shortlist_item(
    shortlist_id: int,
    player_id: int,
    player_source: str = Query("multivideo"),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_scout),
):
    sl = db.query(models_product.Shortlist).filter(models_product.Shortlist.id == shortlist_id).first()
    if not sl or sl.owner_id != current_user.id:
        raise HTTPException(status_code=404, detail="Liste bulunamadi.")
    item = (
        db.query(models_product.ShortlistItem)
        .filter(
            models_product.ShortlistItem.shortlist_id == shortlist_id,
            models_product.ShortlistItem.player_id == player_id,
            models_product.ShortlistItem.player_source == player_source,
        )
        .first()
    )
    if item:
        db.delete(item)
        db.commit()


@router.get("/shortlists/share/{token}")
def get_shared_shortlist(token: str, request: Request, db: Session = Depends(get_db)):
    sl = (
        db.query(models_product.Shortlist)
        .filter(models_product.Shortlist.share_token == token)
        .first()
    )
    if not sl:
        raise HTTPException(status_code=404, detail="Paylasim linki gecersiz.")
    return _shortlist_payload(sl, db, request)


# --- Notifications ---
@router.get("/notifications")
def list_notifications(
    unread_only: bool = Query(False),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    q = db.query(models_product.AppNotification).filter(
        models_product.AppNotification.user_id == current_user.id
    )
    if unread_only:
        q = q.filter(models_product.AppNotification.read_at.is_(None))
    rows = q.order_by(models_product.AppNotification.created_at.desc()).limit(limit).all()
    out = []
    for n in rows:
        payload = None
        if n.payload_json:
            try:
                payload = json.loads(n.payload_json)
            except json.JSONDecodeError:
                payload = None
        out.append(
            {
                "id": n.id,
                "kind": n.kind,
                "title": n.title,
                "body": n.body,
                "payload": payload,
                "read": n.read_at is not None,
                "created_at": n.created_at.isoformat() if n.created_at else None,
            }
        )
    return out


@router.patch("/notifications/{notification_id}/read")
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    n = (
        db.query(models_product.AppNotification)
        .filter(
            models_product.AppNotification.id == notification_id,
            models_product.AppNotification.user_id == current_user.id,
        )
        .first()
    )
    if not n:
        raise HTTPException(status_code=404, detail="Bildirim bulunamadi.")
    from datetime import datetime, timezone

    n.read_at = datetime.now(timezone.utc)
    db.commit()
    return {"ok": True}


@router.post("/notifications/register-device")
def register_fcm_token(
    body: sp.FcmTokenRegister,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    token = (body.device_token or "").strip()
    current_user.fcm_device_token = token if len(token) >= 10 else None
    db.commit()
    from config import FCM_ENABLED

    if current_user.fcm_device_token:
        msg = (
            "FCM token kaydedildi."
            if FCM_ENABLED
            else "FCM token kaydedildi (sunucuda FCM_ENABLED=false, push kapali)."
        )
    else:
        msg = "FCM token kaldirildi."

    return {"ok": True, "fcm_enabled": FCM_ENABLED, "message": msg}
