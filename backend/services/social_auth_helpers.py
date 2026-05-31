"""Sosyal giriş isim / e-posta yardımcıları."""
import re

APPLE_PRIVATE_SUFFIX = "@private.yetenekavcisi.app"


def is_apple_private_email(email: str) -> bool:
    e = (email or "").lower()
    return "privaterelay.appleid.com" in e or e.endswith(APPLE_PRIVATE_SUFFIX)


def looks_like_opaque_token(value: str) -> bool:
    v = (value or "").strip()
    if not v:
        return True
    if re.match(r"^[0-9a-f]{8}-[0-9a-f]{4}-", v, re.I):
        return True
    if re.match(r"^[0-9]{3,}\.[0-9a-zA-Z.-]+\.[0-9a-zA-Z.-]+$", v):
        return True
    if re.match(r"^[0-9a-f]{16,}$", v, re.I):
        return True
    return False


def sanitize_display_name(full_name: str, email: str, fallback: str = "Kullanıcı") -> str:
    name = (full_name or "").strip()
    if name and not looks_like_opaque_token(name) and name.lower() != (email or "").split("@")[0].lower():
        return name
    if email and not is_apple_private_email(email):
        local = email.split("@")[0]
        if not looks_like_opaque_token(local):
            cleaned = re.sub(r"[._-]+", " ", local).strip()
            if len(cleaned) >= 2:
                return cleaned.title()
    return fallback


def apple_storage_email(email: str, provider_id: str) -> str:
    e = (email or "").strip().lower()
    if e:
        return e
    pid = (provider_id or "").strip()
    if not pid:
        raise ValueError("Apple provider_id gerekli")
    return f"apple_{pid}{APPLE_PRIVATE_SUFFIX}"


def find_social_user(db, provider: str, email: str, provider_id: str):
    import models

    if provider == "apple" and provider_id:
        user = (
            db.query(models.User)
            .filter(models.User.provider == "apple", models.User.provider_id == provider_id)
            .first()
        )
        if user:
            return user
    if email:
        return db.query(models.User).filter(models.User.email == email).first()
    return None
