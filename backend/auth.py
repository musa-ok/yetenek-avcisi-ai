from datetime import datetime, timedelta
from passlib.context import CryptContext
from jose import jwt, JWTError
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from database import get_db
from models import User
from otp_service import store_otp, verify_otp, send_email_otp

# Güvenlik Anahtarımız (Gerçek projelerde bu .env dosyasında saklanır)
SECRET_KEY = "yetenek_avcisi_gizli_anahtar_cok_gizli"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7 # Token 1 hafta geçerli olsun

# Şifreleri güvenli ve bağımlılık sorunsuz bir algoritma ile sakla
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None

router = APIRouter(tags=["Authentication"])

class RegisterRequest(BaseModel):
    full_name: str
    email: str
    password: str
    role: str
    phone_number: str
    birth_date: Optional[str] = None
    age: Optional[int] = None

class VerifyOtpRequest(BaseModel):
    email: str
    code: str

@router.post("/register")
async def register_user(req: RegisterRequest, db: Session = Depends(get_db)):
    email_lower = req.email.lower().strip()
    existing_user = db.query(User).filter(User.email == email_lower).first()
    
    if existing_user:
        if existing_user.is_verified:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Bu e-posta adresi zaten kayıtlı."
            )
        else:
            # 🛡️ HAYALET HESAP ÇÖZÜMÜ: Eğer doğrulanmamış yarım kayıt varsa, eskiyi sil.
            db.delete(existing_user)
            db.commit()

    # Yeni kullanıcı oluştur
    hashed_pwd = get_password_hash(req.password)
    new_user = User(
        full_name=req.full_name,
        email=email_lower,
        hashed_password=hashed_pwd,
        role=req.role,
        phone_number=req.phone_number,
        birth_date=req.birth_date,
        age=req.age,
        is_verified=False
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # OTP Üret ve Gönder
    otp_code = store_otp(email_lower)
    success = send_email_otp(email_lower, otp_code)
    
    if not success:
        db.delete(new_user)
        db.commit()
        raise HTTPException(status_code=500, detail="Doğrulama maili gönderilemedi.")

    return {"message": "Kayıt başarılı, doğrulama kodu gönderildi.", "email": email_lower}

@router.post("/verify-otp")
async def verify_user_otp(req: VerifyOtpRequest, db: Session = Depends(get_db)):
    email_lower = req.email.lower().strip()
    user = db.query(User).filter(User.email == email_lower).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
        
    if user.is_verified:
        raise HTTPException(status_code=400, detail="Kullanıcı zaten doğrulanmış.")

    # 🛡️ OTP GEÇERSİZ/SÜRE DOLDU ÇÖZÜMÜ
    is_valid, error_msg = verify_otp(email_lower, req.code.strip())
    
    if not is_valid:
        raise HTTPException(status_code=400, detail=error_msg or "Geçersiz veya süresi dolmuş kod.")

    # Doğrulama Başarılı!
    user.is_verified = True
    db.commit()

    # Token üretip adamı direkt içeri alıyoruz
    access_token = create_access_token(data={"sub": user.email, "role": user.role})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "full_name": user.full_name,
            "email": user.email,
            "role": user.role,
            "is_verified": user.is_verified
        }
    }