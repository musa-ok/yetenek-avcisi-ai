"""
YENİ AUTH SİSTEMİ - FastAPI + PostgreSQL
Sade, temiz ve hatasız auth endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import models, schemas
from database import get_db
from auth import get_password_hash, verify_password, create_access_token
from email_service import send_otp_email
import random
import uuid

router = APIRouter(tags=["Authentication"])  # Prefix main.py'de tanımlı


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
    
    new_user = models.User(
        full_name=user_data.full_name.strip(),
        email=email,
        phone_number=user_data.phone_number,
        hashed_password=get_password_hash(user_data.password),
        role="pending_scout" if (user_data.role or "").strip().lower() in ("scout", "pending_scout") else "Futbolcu",
        birth_date=birth_date,
        age=user_data.age,
        is_verified=False,
        is_active=True
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
    send_otp_email(email, code)

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
    
    # 4. JWT Token oluştur ve DÖN
    token = create_access_token({"sub": str(user.id), "email": user.email})
    
    return {
        "message": "Doğrulama başarılı.",
        "verified": True,
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role,
            "is_verified": user.is_verified
        }
    }


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
    
    token = create_access_token({"sub": str(user.id), "email": user.email})
    
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role,
            "is_verified": user.is_verified
        }
    }


@router.post("/social")
def social_login(payload: dict, db: Session = Depends(get_db)):
    """
    SOSYAL GİRİŞ - Google & Apple
    - Mevcut kullanıcı varsa giriş yap
    - Yoksa yeni kullanıcı oluştur (is_verified=True)
    """
    provider = payload.get("provider", "").lower()
    email = payload.get("email", "").strip().lower()
    full_name = payload.get("full_name", "").strip()
    provider_id = payload.get("provider_id", "")
    
    if not email or not provider or not provider_id:
        raise HTTPException(
            status_code=400,
            detail="Provider, email ve provider_id gereklidir."
        )
    
    # Sadece google ve apple destekleniyor
    if provider not in ["google", "apple"]:
        raise HTTPException(
            status_code=400,
            detail="Desteklenmeyen provider. Sadece 'google' ve 'apple'."
        )
    
    # Mevcut kullanıcıyı kontrol et
    user = db.query(models.User).filter(models.User.email == email).first()
    
    if user:
        # ✅ Mevcut kullanıcı - sosyal login = otomatik doğrulanmış
        if not user.is_verified:
            user.is_verified = True
            db.commit()
            db.refresh(user)
        token = create_access_token({"sub": str(user.id), "email": user.email})
        return {
            "status": "complete",
            "access_token": token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "email": user.email,
                "full_name": user.full_name,
                "role": user.role,
                "is_verified": True
            }
        }
    else:
        # 🆕 Yeni kullanıcı - profil tamamlama gerekli
        return {
            "status": "incomplete",
            "email": email,
            "full_name": full_name,
            "provider": provider,
            "provider_id": provider_id
        }


@router.post("/social/register")
def social_register(payload: dict, db: Session = Depends(get_db)):
    """
    SOSYAL KAYIT - Profil tamamlama sonrası
    - Mevcut kullanıcı varsa güncelle
    - Yoksa yeni oluştur
    - Her durumda is_verified=True (sosyal login = doğrulanmış)
    """
    email = payload.get("email", "").strip().lower()
    full_name = payload.get("full_name", "").strip()
    phone_number = payload.get("phone_number", "").strip()
    role = payload.get("role", "Futbolcu").strip()
    provider = payload.get("provider", "").strip().lower()
    provider_id = payload.get("provider_id", "")
    
    if not email:
        raise HTTPException(status_code=400, detail="E-posta gereklidir.")
    
    user = db.query(models.User).filter(models.User.email == email).first()
    
    if user:
        user.full_name = full_name or user.full_name
        user.phone_number = phone_number or user.phone_number
        user.role = role
        user.provider = provider
        user.provider_id = provider_id
        user.is_verified = True
        user.is_profile_complete = True
    else:
        user = models.User(
            full_name=full_name,
            email=email,
            phone_number=phone_number,
            hashed_password="",
            role=role,
            provider=provider,
            provider_id=provider_id,
            is_verified=True,
            is_profile_complete=True,
            is_active=True,
        )
        db.add(user)
    
    db.commit()
    db.refresh(user)
    
    token = create_access_token({"sub": str(user.id), "email": user.email})
    return {
        "status": "complete",
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role,
            "is_verified": True
        }
    }
