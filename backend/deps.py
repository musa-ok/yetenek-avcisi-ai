"""FastAPI dependency injection — auth, roller, DB."""
from typing import Callable, Optional

from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

import auth
import models
from database import get_db

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")
oauth2_scheme_optional = OAuth2PasswordBearer(tokenUrl="/token", auto_error=False)

ROLE_SCOUT = "Scout"
ROLE_PLAYER = "Futbolcu"
ROLE_ADMIN = "admin"
ROLE_PENDING_SCOUT = "pending_scout"


def create_user_token(user: models.User) -> str:
    from services.token_service import create_access_token

    return create_access_token(
        user_id=user.id,
        email=user.email,
        role=user.role or "",
    )


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    payload = auth.decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Gecersiz token.")

    jti = payload.get("jti")
    if jti:
        from services.token_service import is_access_jti_revoked

        if is_access_jti_revoked(db, jti):
            raise HTTPException(status_code=401, detail="Token iptal edildi.")

    sub = payload.get("sub")
    if sub is None:
        raise HTTPException(status_code=401, detail="Token bilgisi eksik.")

    try:
        user_id = int(sub)
    except (TypeError, ValueError):
        raise HTTPException(status_code=401, detail="Token bilgisi gecersiz.")

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="Kullanici bulunamadi.")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Pasif kullanici.")
    return user


def get_optional_user(
    token: Optional[str] = Depends(oauth2_scheme_optional),
    db: Session = Depends(get_db),
) -> Optional[models.User]:
    if not token:
        return None
    payload = auth.decode_access_token(token)
    if not payload:
        return None
    jti = payload.get("jti")
    if jti:
        from services.token_service import is_access_jti_revoked

        if is_access_jti_revoked(db, jti):
            return None
    sub = payload.get("sub")
    if sub is None:
        return None
    try:
        user_id = int(sub)
    except (TypeError, ValueError):
        return None
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user or not user.is_active:
        return None
    return user


def require_roles(*allowed_roles: str) -> Callable:
    normalized_roles = {(r or "").strip().lower() for r in allowed_roles}

    def _dependency(current_user: models.User = Depends(get_current_user)):
        user_role = (current_user.role or "").strip().lower()
        if user_role == ROLE_PENDING_SCOUT.lower():
            raise HTTPException(
                status_code=403,
                detail="Scout hesabınız henüz onaylanmadı. Bu işlem için admin onayı gerekir.",
            )
        if user_role == ROLE_PLAYER.lower():
            raise HTTPException(
                status_code=403,
                detail="Sadece onaylı Scout hesapları bu işlemi yapabilir.",
            )
        if user_role not in normalized_roles:
            allowed_display = ", ".join(sorted(allowed_roles))
            raise HTTPException(
                status_code=403,
                detail=f"Bu islem icin gerekli rol: {allowed_display}",
            )
        return current_user

    return _dependency


require_scout = require_roles(ROLE_SCOUT)
require_admin = require_roles(ROLE_ADMIN)


def require_setup_enabled():
    from config import ALLOW_SETUP_ENDPOINTS

    if not ALLOW_SETUP_ENDPOINTS:
        raise HTTPException(status_code=404, detail="Not found")
