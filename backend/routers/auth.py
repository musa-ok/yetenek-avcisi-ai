"""
YENİ AUTH SİSTEMİ - FastAPI + PostgreSQL
Sade, temiz ve hatasız auth endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import models, schemas
from database import get_db
from deps import get_current_user
from auth import get_password_hash, verify_password
from services.token_service import issue_token_response, refresh_tokens_pair, revoke_refresh_token, revoke_all_user_refresh_tokens
from services.referral_helpers import ensure_user_referral_code, resolve_referrer_id, build_referral_links
from email_service import send_otp_email
import random
import uuid
import logging

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Authentication"])  # Prefix main.py'de tanımlı


def _user_payload(user: models.User) -> dict:
    return {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role,
        "is_verified": user.is_verified,
        "phone_number": user.phone_number,
        "birth_date": user.birth_date.isoformat() if user.birth_date else None,
        "profile_image_url": user.profile_image_url,
        "referral_code": user.referral_code,
    }


def _auth_response(db: Session, user: models.User) -> dict:
    ensure_user_referral_code(db, user)
    tokens = issue_token_response(db, user)
    return {**tokens, "user": _user_payload(user)}


def generate_otp() -> str:
    """6 haneli OTP kodu üret"""
    return str(random.randint(100000, 999999))


def store_otp_db(user: models.User, code: str, db: Session) -> None:
    """OTP'yi veritabanına kaydet - sunucu yeniden başlasa bile kaybolmaz"""
    user.otp_code = code.strip()
    user.otp_expires_at = datetime.utcnow() + timedelta(minutes=10)
    db.commit()


def verify_otp_db(user: models.User, code: str, db: Session) -> tuple[bool, str]:
    """Veritabanındaki OTP'yi doğrula"""
    code = code.strip()
    
    if not user.otp_code:
        return False, "OTP kodu bulunamadı. Lütfen tekrar kayıt olun."
    
    if not user.otp_expires_at or datetime.utcnow() > user.otp_expires_at:
        user.otp_code = None
        user.otp_expires_at = None
        db.commit()
        return False, "Kodun süresi dolmuş. Lütfen tekrar kayıt olun."
    
    if user.otp_code != code:
        return False, "Geçersiz kod. Lütfen e-postanızı kontrol edin."
    
    # Başarılı - kodu temizle
    user.otp_code = None
    user.otp_expires_at = None
    db.commit()
    return True, ""


@router.post("/register")
def register(user_data: schemas.UserCreate, db: Session = Depends(get_db)):
    """
    KUSURSUZ KAYIT SİSTEMİ:
    - Doğrulanmış kullanıcı varsa → Hata
    - Doğrulanmamış kullanıcı varsa → SİL ve yeniden oluştur
    - Yeni kayıt → is_verified=False, OTP gönder
    - Token DÖNMEZ
    """
    email = user_data.email.strip().lower()
    
    # 1. Mevcut kullanıcıyı kontrol et
    existing = db.query(models.User).filter(models.User.email == email).first()
    
    if existing:
        if existing.is_verified:
            # ✅ Doğrulanmış kullanıcı var → Giriş yapmalı
            raise HTTPException(
                status_code=400,
                detail="Bu e-posta zaten kayıtlı."
            )
        else:
            # 🗑️ YARIM KALMIŞ kayıt var → TAMAMEN SİL
            db.delete(existing)
            db.commit()
    
    # 2. YEPYENİ kullanıcı oluştur (veya silindikten sonra)
    birth_date = None
    if user_data.birth_date:
        try:
            birth_date = datetime.fromisoformat(user_data.birth_date.replace('Z', '+00:00'))
        except:
            pass
    
    referrer_id = resolve_referrer_id(db, getattr(user_data, "referral_code", None))

    new_user = models.User(
        full_name=user_data.full_name.strip(),
        email=email,
        phone_number=user_data.phone_number,
        hashed_password=get_password_hash(user_data.password),
        role="pending_scout" if (user_data.role or "").strip().lower() in ("scout", "pending_scout") else "Futbolcu",
        birth_date=birth_date,
        age=user_data.age,
        is_verified=False,
        is_active=True,
        referred_by_user_id=referrer_id,
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # 3. YEPYENİ OTP üret ve veritabanına kaydet
    code = generate_otp()
    store_otp_db(new_user, code, db)
    send_otp_email(email, code)
    
    # 4. SADECE mesaj dön (TOKEN YOK!)
    return {
        "message": "Kayıt başarılı, kod gönderildi.",
        "email": email,
        "requires_verification": True
    }


@router.post("/resend-otp")
def resend_otp(payload: dict, db: Session = Depends(get_db)):
    """
    OTP YENİDEN GÖNDER:
    - Mevcut kullanıcıyı bul
    - Yeni OTP üret, DB'ye yaz, e-posta gönder
    """
    email = payload.get("email", "").strip().lower()
    if not email:
        raise HTTPException(status_code=400, detail="E-posta gereklidir.")

    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

    if user.is_verified:
        raise HTTPException(status_code=400, detail="Bu hesap zaten doğrulanmış.")

    code = generate_otp()
    store_otp_db(user, code, db)
    sent = send_otp_email(email, code)
    logger.info(f"[RESEND-OTP] Email gönderim sonucu ({email}): {sent}")

    return {"message": "Yeni doğrulama kodu gönderildi.", "email": email}


@router.post("/verify-otp")
def verify_otp(payload: dict, db: Session = Depends(get_db)):
    """
    OTP DOĞRULAMA:
    - Kod doğruysa is_verified=True yap
    - Veritabanını kaydet
    - JWT Token dön
    """
    email = payload.get("email", "").strip().lower()
    code = payload.get("code", "").strip()
    
    if not email or not code:
        raise HTTPException(status_code=400, detail="E-posta ve kod gereklidir.")
    
    # 1. Kullanıcıyı bul
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
    
    # 2. Kodu veritabanından doğrula
    ok, err = verify_otp_db(user, code, db)
    if not ok:
        raise HTTPException(status_code=400, detail=err)
    
    # 3. Doğrulanmış olarak işaretle
    user.is_verified = True
    db.commit()
    db.refresh(user)
    
    resp = _auth_response(db, user)
    resp["message"] = "Doğrulama başarılı."
    resp["verified"] = True
    return resp


@router.post("/login")
def login(credentials: schemas.LoginRequest, db: Session = Depends(get_db)):
    """
    GİRİŞ:
    - E-posta ve şifre doğruysa giriş yap
    - Doğrulanmamış kullanıcı giriş yapamaz
    """
    email = credentials.email.strip().lower()
    
    user = db.query(models.User).filter(models.User.email == email).first()
    
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")
    
    if not user.is_verified:
        raise HTTPException(status_code=403, detail="Lütfen önce e-posta adresinizi doğrulayın.")
    
    return _auth_response(db, user)


@router.post("/refresh")
def refresh_token(body: schemas.RefreshTokenRequest, db: Session = Depends(get_db)):
    try:
        return refresh_tokens_pair(db, body.refresh_token)
    except ValueError:
        raise HTTPException(status_code=401, detail="Geçersiz veya süresi dolmuş oturum.")


@router.post("/logout")
def logout(
    body: schemas.LogoutRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if body.refresh_token:
        revoke_refresh_token(db, body.refresh_token)
    else:
        revoke_all_user_refresh_tokens(db, current_user.id)
    return {"message": "Çıkış yapıldı."}


@router.get("/me/referral")
def my_referral_link(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    code = ensure_user_referral_code(db, current_user)
    links = build_referral_links(code)
    return {"referral_code": code, **links}


@router.post("/social")
def social_login(payload: dict, db: Session = Depends(get_db)):
    """
    SOSYAL GİRİŞ - Google & Apple
    - Mevcut kullanıcı varsa giriş yap (e-posta veya Apple provider_id)
    - Yoksa profil tamamlama gerekli
    """
    from services.social_auth_helpers import (
        apple_storage_email,
        find_social_user,
        sanitize_display_name,
    )

    provider = payload.get("provider", "").lower()
    email = payload.get("email", "").strip().lower()
    full_name = payload.get("full_name", "").strip()
    provider_id = payload.get("provider_id", "")

    if not provider or not provider_id:
        raise HTTPException(
            status_code=400,
            detail="Provider ve provider_id gereklidir.",
        )

    if provider not in ["google", "apple"]:
        raise HTTPException(
            status_code=400,
            detail="Desteklenmeyen provider. Sadece 'google' ve 'apple'.",
        )

    if provider == "google" and not email:
        raise HTTPException(status_code=400, detail="Google girişi için e-posta gereklidir.")

    try:
        storage_email = apple_storage_email(email, provider_id) if provider == "apple" else email
    except ValueError:
        raise HTTPException(status_code=400, detail="Apple provider_id gerekli.")

    user = find_social_user(db, provider, storage_email, provider_id)

    if user:
        if not user.is_verified:
            user.is_verified = True
        if provider_id and not user.provider_id:
            user.provider_id = provider_id
        if provider and not user.provider:
            user.provider = provider
        db.commit()
        db.refresh(user)
        resp = _auth_response(db, user)
        resp["status"] = "complete"
        resp["user"]["full_name"] = sanitize_display_name(
            user.full_name or "", user.email
        )
        return resp

    safe_name = sanitize_display_name(full_name, storage_email, fallback="")
    return {
        "status": "incomplete",
        "email": storage_email,
        "full_name": safe_name,
        "provider": provider,
        "provider_id": provider_id,
    }


@router.post("/social/register")
def social_register(payload: dict, db: Session = Depends(get_db)):
    """SOSYAL KAYIT - Profil tamamlama sonrası."""
    from services.social_auth_helpers import find_social_user, sanitize_display_name

    email = payload.get("email", "").strip().lower()
    full_name = payload.get("full_name", "").strip()
    phone_number = payload.get("phone_number", "").strip()
    role = payload.get("role", "Futbolcu").strip()
    provider = payload.get("provider", "").strip().lower()
    provider_id = payload.get("provider_id", "")
    birth_date_raw = payload.get("birth_date")

    if not email:
        raise HTTPException(status_code=400, detail="E-posta gereklidir.")

    if provider == "apple":
        try:
            from services.social_auth_helpers import apple_storage_email

            email = apple_storage_email(email, provider_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Apple provider_id gerekli.")

    display_name = sanitize_display_name(full_name, email, fallback="")
    if len(display_name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Lütfen geçerli bir ad soyad girin (en az 2 karakter).",
        )

    user = find_social_user(db, provider, email, provider_id)
    if not user:
        user = db.query(models.User).filter(models.User.email == email).first()

    birth_date = None
    if birth_date_raw:
        try:
            birth_date = datetime.fromisoformat(str(birth_date_raw).replace("Z", "+00:00"))
        except ValueError:
            raise HTTPException(status_code=400, detail="Geçersiz doğum tarihi.")

    if user:
        user.full_name = display_name
        user.phone_number = phone_number or user.phone_number
        user.role = role
        user.provider = provider or user.provider
        user.provider_id = provider_id or user.provider_id
        user.is_verified = True
        user.is_profile_complete = True
        if birth_date:
            user.birth_date = birth_date
    else:
        user = models.User(
            full_name=display_name,
            email=email,
            phone_number=phone_number,
            hashed_password="",
            role=role,
            provider=provider,
            provider_id=provider_id,
            is_verified=True,
            is_profile_complete=True,
            is_active=True,
            birth_date=birth_date,
        )
        db.add(user)

    db.commit()
    db.refresh(user)

    resp = _auth_response(db, user)
    resp["status"] = "complete"
    return resp


@router.post("/admin/force-verify")
def admin_force_verify(payload: dict, db: Session = Depends(get_db)):
    """
    ADMIN: Kullanıcıyı zorla doğrula (OTP bypass)
    Sadece ADMIN_SECRET key ile kullanılabilir
    """
    secret = payload.get("secret", "")
    email = payload.get("email", "").strip().lower()
    role = payload.get("role", "").strip()

    import os
    admin_secret = os.getenv("ADMIN_SECRET", "YetenekAdmin2025!")
    if secret != admin_secret:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim.")

    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

    user.is_verified = True
    user.is_profile_complete = True
    if role:
        user.role = role
    db.commit()
    db.refresh(user)

    resp = _auth_response(db, user)
    resp["message"] = f"{email} doğrulandı."
    return resp


@router.post("/admin/delete-user")
def admin_delete_user(payload: dict, db: Session = Depends(get_db)):
    """ADMIN: Kullanıcıyı sil"""
    import os
    secret = payload.get("secret", "")
    email = payload.get("email", "").strip().lower()
    admin_secret = os.getenv("ADMIN_SECRET", "YetenekAdmin2025!")
    if secret != admin_secret:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim.")
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
    db.delete(user)
    db.commit()
    return {"message": f"{email} silindi."}
