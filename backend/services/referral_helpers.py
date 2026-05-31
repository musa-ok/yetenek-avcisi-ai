"""Scout davet kodu üretimi ve çözümleme."""
from __future__ import annotations

import secrets
import string

from sqlalchemy.orm import Session

import models
from config import DEEP_LINK_SCHEME, REFERRAL_BASE_URL


def _random_code(length: int = 8) -> str:
    alphabet = string.ascii_uppercase + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def ensure_user_referral_code(db: Session, user: models.User) -> str:
    if user.referral_code:
        return user.referral_code
    for _ in range(10):
        code = _random_code()
        exists = (
            db.query(models.User)
            .filter(models.User.referral_code == code)
            .first()
        )
        if not exists:
            user.referral_code = code
            db.commit()
            return code
    code = _random_code(12)
    user.referral_code = code
    db.commit()
    return code


def resolve_referrer_id(db: Session, referral_code: str | None) -> int | None:
    if not referral_code or not str(referral_code).strip():
        return None
    code = str(referral_code).strip().upper()
    ref = db.query(models.User).filter(models.User.referral_code == code).first()
    return ref.id if ref else None


def build_referral_links(code: str) -> dict[str, str]:
    https_link = f"{REFERRAL_BASE_URL}/{code}"
    deep_link = f"{DEEP_LINK_SCHEME}://invite/{code}"
    return {
        "https_link": https_link,
        "deep_link": deep_link,
        "share_text": f"Scoutiq'e katıl — davet kodum: {code}\n{https_link}",
    }
