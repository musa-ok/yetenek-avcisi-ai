"""In-app bildirim kayıtları (+ FCM push)."""
import json
from typing import Any, Optional

from sqlalchemy.orm import Session

import models
import models_product

# MVP push: telefona yalnızca bu kind'lar; diğerleri uygulama içi listede kalır.
PUSH_NOTIFICATION_KINDS = frozenset(
    {
        "analysis_done",
        "analysis_failed",
        "rating",
        "rating_updated",
        "scout_note",
        "scout_approved",
        "scout_rejected",
        "admin_pending_scout",
    }
)


def should_send_push(kind: str) -> bool:
    return kind in PUSH_NOTIFICATION_KINDS


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
    if user and user.fcm_device_token and should_send_push(kind):
        from services.fcm_push import send_push

        send_push(
            user.fcm_device_token,
            title=title,
            body=body,
            data={**(payload or {}), "kind": kind, "notification_id": str(row.id)},
        )
    return row


def notify_player_owner_analysis_done(
    db: Session, player_user_id: int, player_name: str, player_id: int
):
    create_notification(
        db,
        user_id=player_user_id,
        kind="analysis_done",
        title="Analiz tamamlandı",
        body=f"{player_name} için AI analizi hazır.",
        payload={"player_id": player_id, "source": "multivideo"},
    )


def notify_analysis_failed(
    db: Session,
    player_user_id: int,
    player_id: int,
    player_name: str,
    error_message: str,
):
    detail = (error_message or "Analiz tamamlanamadı.").strip()[:200]
    create_notification(
        db,
        user_id=player_user_id,
        kind="analysis_failed",
        title="Analiz başarısız",
        body=f"{player_name}: {detail}",
        payload={"player_id": player_id, "source": "multivideo"},
    )


def notify_ovr_changed(
    db: Session,
    player_user_id: int,
    player_id: int,
    player_name: str,
    old_ovr: int,
    new_ovr: int,
):
    if old_ovr == new_ovr:
        return
    create_notification(
        db,
        user_id=player_user_id,
        kind="ovr_changed",
        title="OVR güncellendi",
        body=f"{player_name}: {old_ovr} → {new_ovr}",
        payload={
            "player_id": player_id,
            "source": "multivideo",
            "old_ovr": old_ovr,
            "new_ovr": new_ovr,
        },
    )


def notify_videos_ready_for_finalize(
    db: Session, player_user_id: int, player_id: int, player_name: str
):
    create_notification(
        db,
        user_id=player_user_id,
        kind="videos_ready",
        title="Videolar tamam",
        body=f"{player_name} için tüm testler yüklendi. Analizi başlatabilirsin.",
        payload={"player_id": player_id, "source": "multivideo"},
    )


def notify_quota_exhausted(db: Session, user_id: int):
    create_notification(
        db,
        user_id=user_id,
        kind="quota_exhausted",
        title="Günlük analiz limiti",
        body="Bugünkü 3 analiz hakkını kullandın. Yarın yenilenir.",
        payload={},
    )


def notify_quota_last_used(db: Session, user_id: int):
    create_notification(
        db,
        user_id=user_id,
        kind="quota_warning",
        title="Son analiz hakkın",
        body="Bugün için son analiz hakkını kullandın (3/3).",
        payload={},
    )


def notify_scout_approved(db: Session, scout_user_id: int):
    create_notification(
        db,
        user_id=scout_user_id,
        kind="scout_approved",
        title="Scout hesabın onaylandı",
        body="Artık oyuncuları puanlayabilir ve not ekleyebilirsin.",
    )


def notify_scout_rejected(
    db: Session, scout_user_id: int, user_name: Optional[str] = None
):
    name = (user_name or "Aday").strip()
    create_notification(
        db,
        user_id=scout_user_id,
        kind="scout_rejected",
        title="Scout başvurun reddedildi",
        body=f"Sayın {name}, başvurunuz bu aşamada onaylanamadı. Detaylar e-postanıza gönderildi.",
    )


def notify_scout_document_received(db: Session, scout_user_id: int):
    create_notification(
        db,
        user_id=scout_user_id,
        kind="scout_document_received",
        title="Belgen alındı",
        body="Scout başvurun inceleniyor. Onay veya red sonucu bildirilecek.",
    )


def notify_admin_pending_scout(
    db: Session, admin_user_id: int, scout_name: str, scout_email: str
):
    create_notification(
        db,
        user_id=admin_user_id,
        kind="admin_pending_scout",
        title="Yeni scout başvurusu",
        body=f"{scout_name} ({scout_email}) belge yükledi, inceleme bekliyor.",
        payload={"scout_email": scout_email},
    )


def notify_new_rating_on_player(
    db: Session,
    player_user_id: int,
    player_id: int,
    scout_name: str,
    *,
    player_source: str = "multivideo",
):
    create_notification(
        db,
        user_id=player_user_id,
        kind="rating",
        title="Yeni scout puanı",
        body=f"{scout_name} oyuncu kartına puan verdi.",
        payload={"player_id": player_id, "source": player_source},
    )


def notify_rating_updated_on_player(
    db: Session,
    player_user_id: int,
    player_id: int,
    scout_name: str,
    *,
    player_source: str = "multivideo",
):
    create_notification(
        db,
        user_id=player_user_id,
        kind="rating_updated",
        title="Scout puanı güncellendi",
        body=f"{scout_name} oyuncu kartındaki puanını güncelledi.",
        payload={"player_id": player_id, "source": player_source},
    )


def notify_scout_note_on_player(
    db: Session,
    player_user_id: int,
    player_id: int,
    player_source: str,
    scout_name: str,
):
    create_notification(
        db,
        user_id=player_user_id,
        kind="scout_note",
        title="Yeni scout notu",
        body=f"{scout_name} oyuncu kartına not ekledi.",
        payload={"player_id": player_id, "source": player_source},
    )


def notify_shortlist_player_analysis(
    db: Session, scout_user_id: int, player_id: int, player_name: str
):
    create_notification(
        db,
        user_id=scout_user_id,
        kind="shortlist_analysis",
        title="Listendeki oyuncu güncellendi",
        body=f"{player_name} için yeni AI analizi tamamlandı.",
        payload={"player_id": player_id, "source": "multivideo"},
    )


def notify_added_to_shortlist(
    db: Session,
    player_user_id: int,
    player_id: int,
    player_source: str,
    scout_name: str,
    shortlist_title: str,
):
    create_notification(
        db,
        user_id=player_user_id,
        kind="shortlist_added",
        title="Favorilere eklendin",
        body=f"{scout_name} seni \"{shortlist_title}\" listesine ekledi.",
        payload={"player_id": player_id, "source": player_source},
    )


def notify_security_password_changed(db: Session, user_id: int):
    create_notification(
        db,
        user_id=user_id,
        kind="security_password_changed",
        title="Şifre değiştirildi",
        body="Hesap şifren güncellendi. Bu işlemi siz yapmadıysanız destekle iletişime geçin.",
        payload={},
    )


def notify_security_new_login(db: Session, user_id: int):
    create_notification(
        db,
        user_id=user_id,
        kind="security_new_login",
        title="Yeni cihazdan giriş",
        body="Hesabına tanımadığımız bir cihazdan giriş yapıldı.",
        payload={},
    )
