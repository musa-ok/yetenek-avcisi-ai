"""Ortam ayarları ve production doğrulama."""
from __future__ import annotations

import os
import sys

# development | staging | production
ENVIRONMENT = os.getenv("ENVIRONMENT", "development").strip().lower()

AUTO_CREATE_TABLES = os.getenv(
    "AUTO_CREATE_TABLES",
    "true" if ENVIRONMENT in ("development", "staging") else "false",
).lower() in {"1", "true", "yes"}

ALLOW_SETUP_ENDPOINTS = ENVIRONMENT not in ("production", "staging")

SECRET_KEY = os.getenv("SECRET_KEY", "").strip()
ALGORITHM = os.getenv("ALGORITHM", "HS256").strip()
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./scout_app.db").strip()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip()

FCM_ENABLED = os.getenv("FCM_ENABLED", "false").strip().lower() in {"1", "true", "yes"}
SENTRY_DSN = os.getenv("SENTRY_DSN", "").strip()

REFERRAL_BASE_URL = os.getenv(
    "REFERRAL_BASE_URL",
    "https://scoutiq.app/invite",
).rstrip("/")
DEEP_LINK_SCHEME = os.getenv("DEEP_LINK_SCHEME", "yetenekavcisi")


def validate_settings() -> None:
    """Production/staging'de zorunlu secret'ları doğrula."""
    if ENVIRONMENT == "development":
        return
    if ENVIRONMENT not in ("production", "staging"):
        return

    missing: list[str] = []
    if not SECRET_KEY or SECRET_KEY == "yetenek_avcisi_gizli_anahtar_cok_gizli":
        missing.append("SECRET_KEY (güçlü, benzersiz)")
    if not DATABASE_URL or DATABASE_URL.startswith("sqlite"):
        missing.append("DATABASE_URL (PostgreSQL)")
    if not GEMINI_API_KEY:
        missing.append("GEMINI_API_KEY")

    if missing:
        msg = "Production ortamında eksik/zayıf ayar: " + ", ".join(missing)
        print(f"[CONFIG] FATAL: {msg}", file=sys.stderr)
        raise RuntimeError(msg)


def get_secret_key() -> str:
    if SECRET_KEY:
        return SECRET_KEY
    if ENVIRONMENT == "development":
        return "dev-only-insecure-secret-change-in-prod"
    raise RuntimeError("SECRET_KEY tanımlı değil")
