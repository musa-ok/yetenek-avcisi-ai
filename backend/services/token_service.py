"""JWT access + refresh token çifti ve revoke listesi (DB)."""
from __future__ import annotations

import hashlib
import secrets
import uuid
from datetime import datetime, timedelta
from typing import Any, Optional

from jose import JWTError, jwt
from sqlalchemy.orm import Session

import models
from config import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    ALGORITHM,
    REFRESH_TOKEN_EXPIRE_DAYS,
    get_secret_key,
)


def _hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def create_access_token(
    *,
    user_id: int,
    email: str,
    role: str,
    jti: Optional[str] = None,
) -> str:
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload: dict[str, Any] = {
        "sub": str(user_id),
        "email": email,
        "role": role,
        "type": "access",
        "exp": expire,
    }
    if jti:
        payload["jti"] = jti
    return jwt.encode(payload, get_secret_key(), algorithm=ALGORITHM)


def decode_access_token(token: str) -> Optional[dict[str, Any]]:
    try:
        payload = jwt.decode(token, get_secret_key(), algorithms=[ALGORITHM])
        if payload.get("type") != "access":
            return None
        jti = payload.get("jti")
        if jti:
            # Revoke edilmiş access jti kontrolü token_service üzerinden yapılır
            pass
        return payload
    except JWTError:
        return None


def is_access_jti_revoked(db: Session, jti: str) -> bool:
    row = (
        db.query(models.RevokedToken)
        .filter(
            models.RevokedToken.jti == jti,
            models.RevokedToken.token_type == "access",
        )
        .first()
    )
    return row is not None


def revoke_access_jti(db: Session, jti: str, user_id: int) -> None:
    if not jti or is_access_jti_revoked(db, jti):
        return
    db.add(
        models.RevokedToken(
            jti=jti,
            user_id=user_id,
            token_type="access",
        )
    )
    db.commit()


def _store_refresh(db: Session, user_id: int, raw: str) -> models.RefreshToken:
    jti = str(uuid.uuid4())
    expires = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    row = models.RefreshToken(
        user_id=user_id,
        jti=jti,
        token_hash=_hash_token(raw),
        expires_at=expires,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def create_refresh_token(db: Session, user_id: int) -> str:
    raw = secrets.token_urlsafe(48)
    _store_refresh(db, user_id, raw)
    return raw


def revoke_refresh_token(db: Session, raw: str) -> None:
    h = _hash_token(raw)
    row = (
        db.query(models.RefreshToken)
        .filter(models.RefreshToken.token_hash == h)
        .first()
    )
    if row and row.revoked_at is None:
        row.revoked_at = datetime.utcnow()
        db.commit()


def revoke_all_user_refresh_tokens(db: Session, user_id: int) -> None:
    now = datetime.utcnow()
    rows = (
        db.query(models.RefreshToken)
        .filter(
            models.RefreshToken.user_id == user_id,
            models.RefreshToken.revoked_at.is_(None),
        )
        .all()
    )
    for r in rows:
        r.revoked_at = now
    db.commit()


def refresh_tokens_pair(db: Session, raw_refresh: str) -> dict[str, Any]:
    """Refresh rotation: eski token iptal, yeni çift üret."""
    h = _hash_token(raw_refresh.strip())
    row = (
        db.query(models.RefreshToken)
        .filter(models.RefreshToken.token_hash == h)
        .first()
    )
    if not row or row.revoked_at is not None:
        raise ValueError("invalid_refresh")
    if row.expires_at < datetime.utcnow():
        row.revoked_at = datetime.utcnow()
        db.commit()
        raise ValueError("expired_refresh")

    user = db.query(models.User).filter(models.User.id == row.user_id).first()
    if not user or not user.is_active:
        raise ValueError("invalid_user")

    row.revoked_at = datetime.utcnow()
    db.commit()

    access_jti = str(uuid.uuid4())
    access = create_access_token(
        user_id=user.id,
        email=user.email,
        role=user.role or "",
        jti=access_jti,
    )
    refresh = create_refresh_token(db, user.id)
    return {
        "access_token": access,
        "refresh_token": refresh,
        "token_type": "bearer",
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    }


def issue_token_response(db: Session, user: models.User) -> dict[str, Any]:
    access_jti = str(uuid.uuid4())
    access = create_access_token(
        user_id=user.id,
        email=user.email,
        role=user.role or "",
        jti=access_jti,
    )
    refresh = create_refresh_token(db, user.id)
    return {
        "access_token": access,
        "refresh_token": refresh,
        "token_type": "bearer",
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    }
