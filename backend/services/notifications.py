"""In-app bildirim kayıtları (+ ileride FCM push)."""
import json
from typing import Any, Optional

from sqlalchemy.orm import Session

import models
import models_product


def create_notification(
    db: Session,
    *,
    user_id: int,
    kind: str,
    title: str,
    body: Optional[str] = None,
    payload: Optional[dict[str, Any]] = None,
) -> models_product.AppNotification:
    row = models_product.AppNotification(
        user_id=user_id,
        kind=kind,
        title=title,
        body=body,
        payload_json=json.dumps(payload) if payload else None,
    )
    db.add(row)
    db.commit()
    db.refresh(row)

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user and user.fcm_device_token:
        from services.fcm_push import send_push

        send_push(
            user.fcm_device_token,
            title=title,
            body=body,
            data={**(payload or {}), "kind": kind, "notification_id": str(row.id)},
        )
    return row


def notify_player_owner_analysis_done(db: Session, player_user_id: int, player_name: str, player_id: int):
    create_notification(
        db,
        user_id=player_user_id,
        kind="analysis_done",
        title="Analiz tamamlandi",
        body=f"{player_name} icin AI analizi hazir.",
        payload={"player_id": player_id, "source": "multivideo"},
    )


def notify_scout_approved(db: Session, scout_user_id: int):
    create_notification(
        db,
        user_id=scout_user_id,
        kind="scout_approved",
        title="Scout hesabin onaylandi",
        body="Artik oyunculari puanlayabilir ve not ekleyebilirsin.",
    )


def notify_new_rating_on_player(db: Session, player_user_id: int, player_id: int, scout_name: str):
    if player_user_id:
        create_notification(
            db,
            user_id=player_user_id,
            kind="rating",
            title="Yeni scout puani",
            body=f"{scout_name} oyuncu kartina puan verdi.",
            payload={"player_id": player_id, "source": "multivideo"},
        )
