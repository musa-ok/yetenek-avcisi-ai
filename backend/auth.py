"""Şifre hash ve JWT yardımcıları (access token token_service üzerinden)."""
import os
from datetime import datetime, timedelta
from typing import Optional

from passlib.context import CryptContext
from jose import JWTError

from config import ACCESS_TOKEN_EXPIRE_MINUTES, get_secret_key
from services import token_service

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

ALGORITHM = os.getenv("ALGORITHM", "HS256")


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Geriye uyumluluk — sub=user_id veya email içeren data dict."""
    sub = data.get("sub")
    email = data.get("email", "")
    role = data.get("role", "")
    try:
        user_id = int(sub)
    except (TypeError, ValueError):
        user_id = 0
    return token_service.create_access_token(
        user_id=user_id,
        email=email,
        role=role,
    )


def decode_access_token(token: str):
    payload = token_service.decode_access_token(token)
    if not payload:
        return None
    return payload
