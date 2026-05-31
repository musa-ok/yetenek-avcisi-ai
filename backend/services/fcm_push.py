"""Firebase Cloud Messaging — opsiyonel; FIREBASE_CREDENTIALS_* + FCM_ENABLED gerekir."""
import json
import logging
import os
from typing import Any, Optional

logger = logging.getLogger(__name__)

_firebase_ready = False


def _fcm_enabled() -> bool:
    return os.getenv("FCM_ENABLED", "false").strip().lower() in {"1", "true", "yes"}


def _ensure_firebase() -> bool:
    global _firebase_ready
    if _firebase_ready:
        return True
    if not _fcm_enabled():
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials
    except ImportError:
        logger.warning("firebase-admin yuklu degil; push atlaniyor.")
        return False

    if firebase_admin._apps:
        _firebase_ready = True
        return True

    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "").strip()
    cred_json = os.getenv("FIREBASE_CREDENTIALS_JSON", "").strip()

    try:
        if cred_json:
            cred = credentials.Certificate(json.loads(cred_json))
        elif cred_path and os.path.isfile(cred_path):
            cred = credentials.Certificate(cred_path)
        else:
            logger.debug("FCM: FIREBASE_CREDENTIALS_PATH veya FIREBASE_CREDENTIALS_JSON yok.")
            return False
        firebase_admin.initialize_app(cred)
        _firebase_ready = True
        return True
    except Exception as exc:
        logger.exception("FCM init hatasi: %s", exc)
        return False


def send_push(
    device_token: str,
    *,
    title: str,
    body: Optional[str] = None,
    data: Optional[dict[str, Any]] = None,
) -> bool:
    """Tek cihaza push gonder. Basarisizsa False."""
    token = (device_token or "").strip()
    if not token:
        return False
    if not _ensure_firebase():
        return False

    try:
        from firebase_admin import messaging

        payload_data = {str(k): str(v) for k, v in (data or {}).items()}
        message = messaging.Message(
            notification=messaging.Notification(
                title=title[:200],
                body=(body or "")[:500],
            ),
            data=payload_data,
            token=token,
            android=messaging.AndroidConfig(priority="high"),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound="default", badge=1),
                ),
            ),
        )
        messaging.send(message)
        logger.info("FCM push gonderildi: %s", title[:60])
        return True
    except Exception as exc:
        logger.warning("FCM push basarisiz: %s", exc)
        return False
