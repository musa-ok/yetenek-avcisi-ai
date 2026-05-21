import os
from dotenv import load_dotenv
load_dotenv()
from typing import Callable
from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.responses import JSONResponse, StreamingResponse, FileResponse
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
import models
import models_multivideo
import database
from database import engine, SessionLocal
import schemas
import auth
import otp_service
import email_service
import uvicorn
import os
import json
import uuid
import shutil
import re
import pandas as pd
import google.generativeai as genai
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, func
from starlette.middleware.base import BaseHTTPMiddleware
import logging
import mimetypes
import tempfile
from pathlib import Path
from storage import StorageService
import vision

storage_service = StorageService()

models.Base.metadata.create_all(bind=engine)
models_multivideo.Base.metadata.create_all(bind=engine)

# YENİ AUTH ROUTER
from routers import auth as auth_router

app = FastAPI(
    title="Yetenek Avcısı API",
    description="Futbolcu yetenek analiz ve scout platformu için REST API",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    contact={
        "name": "Yetenek Avcısı Team",
        "email": "info@yetenekavcisi.com",
    },
    license_info={
        "name": "MIT License",
        "url": "https://opensource.org/licenses/MIT",
    }
)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")
ROLE_SCOUT = "Scout"
ROLE_PLAYER = "Futbolcu"
ROLE_ADMIN = "admin"
ROLE_PENDING_SCOUT = "pending_scout"

if not os.path.exists("static"):
    os.makedirs("static")
app.mount("/static", StaticFiles(directory="static"), name="static")

# Add CORS middleware for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# YENİ AUTH ROUTER EKLE (prefix=/auth)
app.include_router(auth_router.router, prefix="/auth")

# Add middleware - All temporarily disabled
# app.add_middleware(ErrorHandlingMiddleware)
# app.add_middleware(SecurityHeadersMiddleware)
# app.add_middleware(LoggingMiddleware)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _normalize_role(role: str) -> str:
    cleaned = (role or "").strip().lower()
    if cleaned in {"futbolcu", "player"}:
        return ROLE_PLAYER
    return ROLE_SCOUT


def _create_user_token(user: models.User) -> str:
    return auth.create_access_token(
        {"sub": str(user.id), "email": user.email, "role": user.role}
    )


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    payload = auth.decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Gecersiz token.")

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


def require_roles(*allowed_roles: str) -> Callable:
    normalized_roles = {(r or "").strip().lower() for r in allowed_roles}

    def _dependency(current_user: models.User = Depends(get_current_user)):
        user_role = (current_user.role or "").strip().lower()
        if user_role not in normalized_roles:
            allowed_display = ", ".join(sorted(allowed_roles))
            raise HTTPException(
                status_code=403,
                detail=f"Bu islem icin gerekli rol: {allowed_display}",
            )
        return current_user

    return _dependency


require_scout = require_roles(ROLE_SCOUT)


def _player_to_dict(player: models.Player, db: Session = None):
    owner = player.owner
    return {
        "id": player.id,
        "user_id": player.user_id,
        "name": player.name,
        "age": player.age,
        "position": player.position,
        "overall_rating": player.overall_rating,
        "phone_number": owner.phone_number if owner else None,
        "ai_scout_report": player.ai_scout_report,
        "video_url": player.video_url,
        "source": "legacy",
        "scout_ratings": _scout_ratings_for_legacy(db, player.id) if db else [],
    }

def _build_community_rating_summary_mv(db: Session, player_id: int):
    averages = (
        db.query(
            func.avg(models.MultiVideoRating.pac).label("pac"),
            func.avg(models.MultiVideoRating.sho).label("sho"),
            func.avg(models.MultiVideoRating.pas).label("pas"),
            func.avg(models.MultiVideoRating.dri).label("dri"),
            func.avg(models.MultiVideoRating.def_).label("def_"),
            func.avg(models.MultiVideoRating.phy).label("phy"),
        )
        .filter(models.MultiVideoRating.player_id == player_id)
        .first()
    )

    if not averages or averages.pac is None:
        return {"PAC": None, "SHO": None, "PAS": None, "DRI": None, "DEF": None, "PHY": None, "OVR": None}

    pac = round(averages.pac)
    sho = round(averages.sho)
    pas = round(averages.pas)
    dri = round(averages.dri)
    deff = round(averages.def_)
    phy = round(averages.phy)
    return {
        "PAC": pac,
        "SHO": sho,
        "PAS": pas,
        "DRI": dri,
        "DEF": deff,
        "PHY": phy,
        "OVR": round((pac + sho + pas + dri + deff + phy) / 6),
    }


def _build_community_rating_summary(db: Session, player_id: int):
    averages = (
        db.query(
            func.avg(models.Rating.pac).label("pac"),
            func.avg(models.Rating.sho).label("sho"),
            func.avg(models.Rating.pas).label("pas"),
            func.avg(models.Rating.dri).label("dri"),
            func.avg(models.Rating.def_).label("def_"),
            func.avg(models.Rating.phy).label("phy"),
        )
        .filter(models.Rating.player_id == player_id)
        .first()
    )

    if not averages or averages.pac is None:
        return {"PAC": None, "SHO": None, "PAS": None, "DRI": None, "DEF": None, "PHY": None, "OVR": None}

    pac = round(averages.pac)
    sho = round(averages.sho)
    pas = round(averages.pas)
    dri = round(averages.dri)
    deff = round(averages.def_)
    phy = round(averages.phy)
    return {
        "PAC": pac,
        "SHO": sho,
        "PAS": pas,
        "DRI": dri,
        "DEF": deff,
        "PHY": phy,
        "OVR": round((pac + sho + pas + dri + deff + phy) / 6),
    }


def _calculate_overall_from_position(player: models.Player) -> int:
    values = []
    if player.position == "Forvet":
        values = [player.pace, player.finishing, player.dribbling, player.positioning]
    elif player.position == "Orta Saha":
        values = [player.vision, player.passing, player.ball_control, player.stamina]
    elif player.position == "Defans":
        values = [player.tackling, player.marking, player.strength, player.jumping]
    elif player.position == "Kaleci":
        values = [player.gk_reflexes, player.gk_diving, player.gk_handling, player.gk_positioning, player.gk_kicking]
    values = [v for v in values if v is not None]
    if not values:
        return 50
    return round(sum(values) / len(values))


@app.get(
    "/",
    tags=["Health Check"],
    summary="API Health Check",
    description="API'nin çalıştığını doğrulamak için basit health check endpoint'i",
)
def read_root():
    return {"mesaj": "Yetenek Avcısı API Başarıyla Çalışıyor! ⚽🚀"}


# ESKİ /register ENDPOINTİ - YENİ /auth/register KULLANILIYOR (routers/auth.py)
# @app.post("/register", tags=["Authentication"])
# def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
#     ...


# ESKİ /auth/send-otp - YENİ /auth/resend-otp KULLANILIYOR (routers/auth.py - DB tabanlı)
# @app.post("/auth/send-otp", tags=["Authentication"])
# def send_otp(payload: dict, db: Session = Depends(get_db)):
#     ...eski in-memory otp_service tabanlı endpoint - kapatıldı...


# ESKİ /auth/verify-otp - YENİ routers/auth.py KULLANILIYOR (otp_store ile)
# @app.post("/auth/verify-otp", tags=["Authentication"])
# def verify_otp(payload: dict, db: Session = Depends(get_db)):
#     ...eski otp_service tabanlı endpoint - ÇAKIŞIYORDU, kapatıldı...


# ESKİ /login ENDPOINTİ - YENİ /auth/login KULLANILIYOR (routers/auth.py)
# @app.post("/login", response_model=schemas.LoginResponse)
# def login_user(payload: schemas.LoginRequest, db: Session = Depends(get_db)):
#     ...


@app.post("/token", response_model=schemas.Token)
def token_login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == form_data.username.strip().lower()).first()
    try:
        password_ok = db_user and auth.verify_password(form_data.password, db_user.hashed_password)
    except Exception:
        password_ok = False
    if not password_ok:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Gecersiz kullanici adi veya sifre.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # SECURITY: Check if user is verified
    if not db_user.is_verified:
        raise HTTPException(status_code=403, detail="Lutfen once e-posta adresinizi dogrulayin.")
    
    return {"access_token": _create_user_token(db_user), "token_type": "bearer"}


# ===================== SOSYAL MEDYA AUTH =====================
# ESKİ /auth/social ve /auth/social/register → YENİ routers/auth.py KULLANILIYOR
# ESKİ /auth/send-otp → YENİ /auth/resend-otp KULLANILIYOR (routers/auth.py - DB tabanlı)


# ESKİ /auth/verify-otp ENDPOINTİ - YENİ /auth/verify-otp KULLANILIYOR (routers/auth.py)
# @app.post("/auth/verify-otp")
# def verify_otp(payload: dict, db: Session = Depends(get_db)):
#     email = payload.get("email", "").strip().lower()
#     code = payload.get("code", "").strip()
#     if not email or not code:
#         raise HTTPException(status_code=400, detail="Email ve kod gereklidir.")
    
#     success, error_message = otp_service.verify_otp(email, code)
#     if not success:
#         raise HTTPException(status_code=400, detail=error_message)
    
#     db_user = db.query(models.User).filter(models.User.email == email).first()
#     if not db_user:
#         raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
    
#     # Mark user as verified
#     db_user.is_verified = True
#     db.commit()
#     db.refresh(db_user)
    
#     # Return access token so user is automatically logged in
#     return {
#         "message": "Doğrulama başarılı",
#         "verified": True,
#         "access_token": _create_user_token(db_user),
#         "token_type": "bearer",
#         "user": db_user,
#     }


@app.post("/auth/forgot-password", tags=["Authentication"])
def forgot_password(payload: dict, db: Session = Depends(get_db)):
    """Şifre sıfırlama kodu gönderir."""
    email = (payload.get("email") or "").strip().lower()
    if not email:
        raise HTTPException(status_code=400, detail="E-posta adresi gereklidir.")

    db_user = db.query(models.User).filter(models.User.email == email).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.")

    code = otp_service.store_otp(email, expires_in_minutes=10)
    sent = otp_service.send_password_reset_email(email, code)
    if not sent:
        raise HTTPException(status_code=500, detail="E-posta gönderilemedi.")

    return {"message": "Şifre sıfırlama kodu e-posta adresinize gönderildi."}


@app.post("/auth/reset-password", tags=["Authentication"])
def reset_password(payload: dict, db: Session = Depends(get_db)):
    """OTP koduyla şifreyi sıfırlar."""
    email = (payload.get("email") or "").strip().lower()
    code = (payload.get("code") or "").strip()
    new_password = (payload.get("new_password") or "").strip()

    if not email or not code or not new_password:
        raise HTTPException(status_code=400, detail="E-posta, kod ve yeni şifre gereklidir.")

    if len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Şifre en az 6 karakter olmalıdır.")

    success, error_message = otp_service.verify_otp(email, code)
    if not success:
        raise HTTPException(status_code=400, detail=error_message)

    db_user = db.query(models.User).filter(models.User.email == email).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

    db_user.hashed_password = auth.get_password_hash(new_password)
    db.commit()

    return {"message": "Şifreniz başarıyla güncellendi."}


@app.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user


@app.put("/me", response_model=schemas.UserResponse)
def update_me(
    user_update: schemas.UserUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if user_update.full_name is not None:
        current_user.full_name = user_update.full_name.strip()
    if user_update.phone_number is not None:
        current_user.phone_number = user_update.phone_number.strip()
    if user_update.email is not None:
        new_email = user_update.email.strip().lower()
        if new_email != current_user.email:
            existing = db.query(models.User).filter(
                models.User.email == new_email,
                models.User.id != current_user.id
            ).first()
            if existing:
                raise HTTPException(status_code=400, detail="Bu email zaten kullanımda.")
            current_user.email = new_email
    if user_update.profile_image_url is not None:
        current_user.profile_image_url = user_update.profile_image_url.strip()
    if user_update.birth_date is not None:
        try:
            from datetime import date
            current_user.birth_date = date.fromisoformat(user_update.birth_date[:10])
        except Exception:
            pass
    
    db.commit()
    db.refresh(current_user)
    return current_user


def _scout_ratings_for_legacy(db: Session, player_id: int):
    rows = (
        db.query(models.Rating, models.User)
        .join(models.User, models.User.id == models.Rating.reviewer_id)
        .filter(models.Rating.player_id == player_id)
        .all()
    )
    out = []
    for r, u in rows:
        avg = round((r.pac + r.sho + r.pas + r.dri + r.def_ + r.phy) / 6)
        out.append({"scout_name": u.full_name or u.email or f"Scout #{u.id}", "score": avg})
    return out


def _scout_ratings_for_multivideo(db: Session, player_id: int):
    rows = (
        db.query(models.MultiVideoRating, models.User)
        .join(models.User, models.User.id == models.MultiVideoRating.reviewer_id)
        .filter(models.MultiVideoRating.player_id == player_id)
        .all()
    )
    out = []
    for r, u in rows:
        avg = round((r.pac + r.sho + r.pas + r.dri + r.def_ + r.phy) / 6)
        out.append({"scout_name": u.full_name or u.email or f"Scout #{u.id}", "score": avg})
    return out

def _multivideo_to_public_dict(p: "models_multivideo.PlayerMultiVideo", db: Session = None):
    owner = getattr(p, "owner", None)
    scout_ratings = _scout_ratings_for_multivideo(db, p.id) if db else []
    
    raw_urls = [p.video_1_url, p.video_2_url, p.video_3_url]
    raw_skills = [p.video_1_skill, p.video_2_skill, p.video_3_skill]
    raw_ratings = [p.video_1_rating, p.video_2_rating, p.video_3_rating]
    raw_analyses = [p.video_1_ai_analysis, p.video_2_ai_analysis, p.video_3_ai_analysis]

    videos_list = [
        {
            "url": raw_urls[i],
            "skill": raw_skills[i],
            "rating": raw_ratings[i],
            "analysis": raw_analyses[i],
            "slot": i + 1,
        }
        for i in range(3)
        if raw_urls[i]
    ]
    main_video_url = raw_urls[0] if raw_urls[0] else (raw_urls[1] if raw_urls[1] else raw_urls[2])

    skills = p.skill_scores or {}
    
    return {
        "id": p.id,
        "user_id": p.user_id,
        "name": p.name,
        "age": p.age,
        "position": p.position,
        "overall_rating": p.overall_rating or 0,
        "phone_number": owner.phone_number if owner else None,
        "ai_scout_report": p.ai_summary_report,
        "source": "multivideo",
        "scout_ratings": scout_ratings,
        "video_url": main_video_url,
        "videos": videos_list, 

        "pac": skills.get("pace", p.overall_rating),
        "sho": skills.get("finishing", p.overall_rating),
        "pas": skills.get("passing", p.overall_rating),
        "dri": skills.get("dribbling", p.overall_rating),
        "def_": skills.get("defending", p.overall_rating),
        "phy": skills.get("strength", p.overall_rating),

        "pace": skills.get("pace", p.overall_rating),
        "finishing": skills.get("finishing", p.overall_rating),
        "passing": skills.get("passing", p.overall_rating),
        "dribbling": skills.get("dribbling", p.overall_rating),
        "defending": skills.get("defending", p.overall_rating),
        "strength": skills.get("strength", p.overall_rating),
    }


@app.get("/players")
def get_players(db: Session = Depends(get_db)):
    # 🚨 DÜZELTME: SADECE PUANI 35'TEN BÜYÜK OLAN (GEÇERLİ) OYUNCULARI GETİR 🚨
    mv_players = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.ai_summary_report.isnot(None))
        .filter(models_multivideo.PlayerMultiVideo.overall_rating > 35) # Uyumsuz (0 puan) olanları eler
        .all()
    )
    return [_multivideo_to_public_dict(p, db) for p in mv_players]


@app.post("/players", response_model=schemas.PlayerResponse)
def create_player(
    player: schemas.PlayerCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    existing = db.query(models.Player).filter(models.Player.user_id == current_user.id).first()
    if existing:
        return existing
    user_name = current_user.full_name.strip()
    user_age = current_user.age or 18
    new_player = models.Player(
        user_id=current_user.id, name=user_name, age=user_age, position=player.position.strip(),
        finishing=player.finishing, pace=player.pace, dribbling=player.dribbling,
        positioning=player.positioning, vision=player.vision, passing=player.passing,
        ball_control=player.ball_control, stamina=player.stamina, tackling=player.tackling,
        marking=player.marking, strength=player.strength, jumping=player.jumping,
        gk_reflexes=player.gk_reflexes, gk_diving=player.gk_diving, gk_handling=player.gk_handling,
        gk_positioning=player.gk_positioning, gk_kicking=player.gk_kicking,
    )
    new_player.overall_rating = _calculate_overall_from_position(new_player)
    db.add(new_player)
    db.commit()
    db.refresh(new_player)
    return new_player


@app.post("/upload-video/")
async def upload_and_analyze_video(
    user_id: int = Form(...), name: str = Form(...), age: int = Form(...),
    position: str = Form(...), file: UploadFile = File(...), db: Session = Depends(get_db),
):
    try:
        video_url = await storage_service.upload_video(file)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Video upload failed: {str(e)}")

    import uuid
    temp_file_path = f"temp_{uuid.uuid4()}_{file.filename}"
    try:
        await file.seek(0)
        file_content = await file.read()
        with open(temp_file_path, "wb") as temp_file:
            temp_file.write(file_content)

        try:
            ai_data = vision.analyze_player_video_advanced(temp_file_path, position)
        except Exception:
            ai_data = {"ai_scout_report": "AI analizi su anda kullanilamiyor. Daha sonra tekrar deneyin."}

        new_player = models.Player(
            user_id=user_id, name=name, age=age, position=position,
            ai_scout_report=ai_data.get("ai_scout_report", "Rapor oluşturulamadı."),
        )
        
        for field in [
            "pace", "finishing", "dribbling", "positioning", "vision", "passing", "ball_control", 
            "stamina", "tackling", "marking", "strength", "jumping", "gk_reflexes", "gk_diving", 
            "gk_handling", "gk_positioning", "gk_kicking",
        ]:
            if field in ai_data:
                setattr(new_player, field, ai_data[field])
        
        new_player.overall_rating = _calculate_overall_from_position(new_player)

        db.add(new_player)
        db.commit()
        db.refresh(new_player)

        return {
            "mesaj": "Video analizi tamamlandı ve oyuncu veritabanına kaydedildi! 🏆",
            "oyuncu_id": new_player.id, "genel_reyting": new_player.overall_rating,
            "scout_raporu": new_player.ai_scout_report, "video_url": video_url,
        }

    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)


@app.post("/players/multivideo/{player_id}/rate")
def rate_multivideo_player(player_id: int, rating: schemas.PlayerRatingCreate, db: Session = Depends(get_db), current_user: models.User = Depends(require_scout)):
    player = db.query(models_multivideo.PlayerMultiVideo).filter(models_multivideo.PlayerMultiVideo.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Multi-video oyuncu bulunamadı.")

    reviewer_id = current_user.id
    existing = db.query(models.MultiVideoRating).filter(models.MultiVideoRating.player_id == player_id, models.MultiVideoRating.reviewer_id == reviewer_id).first()
    if existing:
        raise HTTPException(status_code=409, detail="Bu oyuncuya zaten puan verdiniz. Bir scout bir oyuncuya yalnızca bir kez puan verebilir.")
    db.add(models.MultiVideoRating(reviewer_id=reviewer_id, player_id=player_id, pac=rating.pac, sho=rating.sho, pas=rating.pas, dri=rating.dri, def_=rating.def_, phy=rating.phy))
    db.commit()

    averages = db.query(func.avg(models.MultiVideoRating.pac).label("pac"), func.avg(models.MultiVideoRating.sho).label("sho"), func.avg(models.MultiVideoRating.pas).label("pas"), func.avg(models.MultiVideoRating.dri).label("dri"), func.avg(models.MultiVideoRating.def_).label("def_"), func.avg(models.MultiVideoRating.phy).label("phy")).filter(models.MultiVideoRating.player_id == player_id).first()
    summary = None
    if averages and averages.pac is not None:
        pac = round(averages.pac); sho = round(averages.sho); pas = round(averages.pas); dri = round(averages.dri); deff = round(averages.def_); phy = round(averages.phy)
        summary = {"PAC": pac, "SHO": sho, "PAS": pas, "DRI": dri, "DEF": deff, "PHY": phy, "OVR": round((pac + sho + pas + dri + deff + phy) / 6)}
    return {"mesaj": "Multi-video community rating kaydedildi.", "player_id": player_id, "reviewer_id": reviewer_id, "community_rating": summary, "scout_ratings": _scout_ratings_for_multivideo(db, player_id)}


@app.post("/players/{player_id}/rate")
def rate_player(player_id: int, rating: schemas.PlayerRatingCreate, db: Session = Depends(get_db), current_user: models.User = Depends(require_scout)):
    player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")

    reviewer_id = current_user.id
    existing = db.query(models.Rating).filter(models.Rating.player_id == player_id, models.Rating.reviewer_id == reviewer_id).first()
    if existing:
        raise HTTPException(status_code=409, detail="Bu oyuncuya zaten puan verdiniz. Bir scout bir oyuncuya yalnızca bir kez puan verebilir.")
    db.add(models.Rating(reviewer_id=reviewer_id, player_id=player_id, pac=rating.pac, sho=rating.sho, pas=rating.pas, dri=rating.dri, def_=rating.def_, phy=rating.phy))
    db.commit()
    return {"mesaj": "Community rating kaydedildi.", "player_id": player_id, "reviewer_id": reviewer_id, "community_rating": _build_community_rating_summary(db, player_id)}


@app.get("/players/detail/{player_id}")
def get_player_detail(player_id: int, db: Session = Depends(get_db)):
    mv_player = db.query(models_multivideo.PlayerMultiVideo).filter(models_multivideo.PlayerMultiVideo.id == player_id).first()
    if mv_player:
        payload = _multivideo_to_public_dict(mv_player, db)
        payload["community_rating"] = _build_community_rating_summary_mv(db, player_id)
        return payload

    player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")
    payload = _player_to_dict(player)
    payload["community_rating"] = _build_community_rating_summary(db, player.id)
    return payload


@app.get("/analysis-steps/{position}")
def get_analysis_steps(position: str):
    from step_analyzer import step_analyzer
    try:
        return step_analyzer.get_step_preview(position)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Analiz adımları alınamadı: {str(e)}")


@app.post("/upload-video-step-by-step/")
async def upload_and_analyze_step_by_step(user_id: int = Form(...), name: str = Form(...), age: int = Form(...), position: str = Form(...), file: UploadFile = File(...), db: Session = Depends(get_db)):
    from step_analyzer import step_analyzer
    try:
        video_url = await storage_service.upload_video(file)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Video upload failed: {str(e)}")

    import uuid as _uuid
    temp_file_path = f"temp_{_uuid.uuid4()}.mp4"
    try:
        await file.seek(0)
        file_content = await file.read()
        with open(temp_file_path, "wb") as temp_file:
            temp_file.write(file_content)

        def progress_callback(current_step, total_steps, step_name):
            print(f"İlerleme: {current_step}/{total_steps} - {step_name}")

        try:
            ai_data = step_analyzer.analyze_step_by_step(temp_file_path, position, progress_callback)
        except Exception as e:
            try:
                ai_data = vision.analyze_player_video_advanced(temp_file_path, position)
                ai_data["analysis_type"] = "fallback"
            except Exception:
                ai_data = {"ai_scout_report": "AI analizi şu anda kullanılamıyor. Daha sonra tekrar deneyin.", "analysis_type": "error"}

        new_player = models.Player(
            user_id=user_id, name=name, age=age, position=position, ai_scout_report=ai_data.get("ai_scout_report", "Rapor oluşturulamadı."),
            pace=ai_data.get("pace"), finishing=ai_data.get("finishing"), dribbling_tight_spaces=ai_data.get("dribbling_tight_spaces"),
            heading=ai_data.get("heading"), positioning=ai_data.get("positioning"), composure=ai_data.get("composure"),
            gk_reflexes=ai_data.get("gk_reflexes"), gk_diving=ai_data.get("gk_diving"), gk_handling=ai_data.get("gk_handling"),
            gk_positioning=ai_data.get("gk_positioning"), gk_distribution=ai_data.get("gk_distribution"), gk_command_area=ai_data.get("gk_command_area"),
            gk_1v1=ai_data.get("gk_1v1"), video_url=video_url,
        )
        new_player.overall_rating = _calculate_overall_from_position(new_player)
        db.add(new_player)
        db.commit()
        db.refresh(new_player)

        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

        return {"message": "Adım adım analiz tamamlandı!", "player": _player_to_dict(new_player), "analysis_summary": {"analysis_type": ai_data.get("analysis_type", "step_by_step"), "total_steps": ai_data.get("total_steps", 0), "average_score": ai_data.get("average_score", 0), "detailed_ratings": {k: v for k, v in ai_data.items() if k != "ai_scout_report"}}}

    except Exception as e:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
        raise HTTPException(status_code=500, detail=f"Analiz sırasında hata: {str(e)}")


@app.get("/position-skills/{position}")
def get_position_skills(position: str):
    from position_skills_config import get_skills_for_position, get_position_code
    skills = get_skills_for_position(position)
    if not skills:
        raise HTTPException(status_code=404, detail=f"Mevki bulunamadı: {position}")
    return {"position": position, "position_code": get_position_code(position), "total_skills": len(skills), "skills": skills}


@app.post("/players/multivideo/create")
def create_multivideo_player(user_id: int, name: str, birth_date: str, position: str, db: Session = Depends(get_db)):
    from position_skills_config import get_position_code
    from datetime import datetime
    position_code = get_position_code(position)
    try:
        parsed_birth_date = datetime.fromisoformat(birth_date.replace('Z', '+00:00'))
    except ValueError:
        parsed_birth_date = datetime.strptime(birth_date, "%Y-%m-%d")
    today = datetime.now()
    age = today.year - parsed_birth_date.year
    if (today.month, today.day) < (parsed_birth_date.month, parsed_birth_date.day):
        age -= 1
    
    player = models_multivideo.PlayerMultiVideo(user_id=user_id, name=name, birth_date=parsed_birth_date, age=age, position=position, position_code=position_code, overall_rating=0, skill_scores={}, ai_strengths=[], ai_improvements=[])
    db.add(player)
    db.commit()
    db.refresh(player)
    return {"message": f"Oyuncu kaydı oluşturuldu ({age} yaş). Şimdi 3 video yükleyin.", "player": player.to_dict()}


@app.post("/players/multivideo/create-from-auth")
def create_multivideo_player_from_auth(position: str = Form(...), db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    from position_skills_config import get_position_code
    from datetime import datetime, timezone
    now_utc = datetime.now(timezone.utc)
    if not current_user.last_analysis_date or current_user.last_analysis_date.date() != now_utc.date():
        current_user.daily_analyses_count = 0
        current_user.last_analysis_date = now_utc
    
    if current_user.daily_analyses_count >= 3:
        raise HTTPException(status_code=403, detail="Günlük 3 yetenek analizi limitinizi doldurdunuz. Lütfen yarın tekrar deneyin.")
    
    current_user.daily_analyses_count += 1
    db.commit()

    position_code = get_position_code(position)
    name = current_user.full_name or current_user.email.split('@')[0]
    age = current_user.age or 18
    player = models_multivideo.PlayerMultiVideo(user_id=current_user.id, name=name, age=age, position=position, position_code=position_code, overall_rating=0, skill_scores={}, ai_strengths=[], ai_improvements=[])
    db.add(player)
    db.commit()
    db.refresh(player)
    return {"message": f"{name} için kayıt oluşturuldu. Şimdi 3 video yükleyin.", "player": player.to_dict()}

# ── UPLOAD SLOT: AI YOK — sadece video yükle ve URL'yi kaydet ───────────────
@app.post("/players/multivideo/{player_id}/upload-slot-{slot}")
async def upload_video_to_slot(
    player_id: int,
    slot: int,
    skill_name: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    if slot not in (1, 2, 3):
        raise HTTPException(status_code=400, detail="Slot 1, 2 veya 3 olmalıdır.")
    player = db.query(models_multivideo.PlayerMultiVideo).filter(models_multivideo.PlayerMultiVideo.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")

    try:
        video_url = await storage_service.upload_video(file)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Video yükleme hatası: {exc}")

    if slot == 1:
        player.video_1_url = video_url
        player.video_1_skill = skill_name
    elif slot == 2:
        player.video_2_url = video_url
        player.video_2_skill = skill_name
    else:
        player.video_3_url = video_url
        player.video_3_skill = skill_name

    db.commit()
    db.refresh(player)
    return {
        "message": f"Slot {slot} yüklendi: {skill_name}",
        "completion": player.completion_percentage,
        "player": player.to_dict(),
    }


@app.get("/players/multivideo")
def list_multivideo_players(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    players = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.ai_summary_report.isnot(None))
        .filter(models_multivideo.PlayerMultiVideo.overall_rating > 35)
        .offset(skip)
        .limit(limit)
        .all()
    )
    return {"total": len(players), "players": [p.to_dict() for p in players]}


@app.get("/players/multivideo/{player_id}")
def get_multivideo_player_detail(player_id: int, db: Session = Depends(get_db)):
    player = db.query(models_multivideo.PlayerMultiVideo).filter(models_multivideo.PlayerMultiVideo.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı")
    return player.to_dict()


# ── FINALIZE: 3 videoyu AI ile analiz et, mismatch → 0 PUAN BAS, 200 DÖN ──────────
@app.post("/players/multivideo/{player_id}/finalize")
def finalize_multivideo_player(player_id: int, db: Session = Depends(get_db)):
    import shutil, urllib.request, uuid as _uuid
    from sqlalchemy.orm.attributes import flag_modified

    player = db.query(models_multivideo.PlayerMultiVideo).filter(models_multivideo.PlayerMultiVideo.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")
    if not player.is_complete:
        raise HTTPException(
            status_code=400,
            detail=f"Tüm videolar henüz yüklenmemiş. Tamamlanma: %{player.completion_percentage:.0f}",
        )

    # ── 1. Videoları geçici dosyalara kopyala / indir ─────────────────────────
    video_urls = [u for u in [player.video_1_url, player.video_2_url, player.video_3_url] if u]
    temp_paths: list = []
    try:
        for i, video_url in enumerate(video_urls, 1):
            tmp = f"/tmp/fin_{player_id}_{i}_{_uuid.uuid4()}.mp4"
            try:
                if video_url.startswith('/static/'):
                    candidates = [
                        os.path.join(os.path.dirname(__file__), video_url.lstrip('/')),
                        os.path.join(os.getcwd(), video_url.lstrip('/')),
                    ]
                    for c in candidates:
                        if os.path.exists(c):
                            shutil.copy(c, tmp)
                            temp_paths.append(tmp)
                            break
                elif video_url.startswith('http'):
                    urllib.request.urlretrieve(video_url, tmp)
                    temp_paths.append(tmp)
                elif os.path.exists(video_url):
                    shutil.copy(video_url, tmp)
                    temp_paths.append(tmp)
            except Exception as dl_err:
                print(f"[FINALIZE] Video {i} indirilemedi: {dl_err}")

        if not temp_paths:
            raise HTTPException(status_code=500, detail="Videolar hazırlanamadı, lütfen tekrar deneyin.")

        # ── 2. AI analizi (3 video birden) ────────────────────────────────────
        skill_names = [player.video_1_skill, player.video_2_skill, player.video_3_skill]
        ai = vision.analyze_multiple_videos(
            video_paths=temp_paths,
            position=player.position,
            skill_names=skill_names,
        )

    finally:
        for tmp in temp_paths:
            try:
                os.remove(tmp)
            except Exception:
                pass

    # ── 3. Mismatch kontrolü: 400 VERME, SİLME, SADECE 0 BAS ─────────────────────────
    report_lower = ai.get('ai_scout_report', '').lower()
    mismatch_words = ('uyumsuz', 'mismatch', 'eşleşmiyor', '⚠️ hata', 'yanlış')
    is_mismatch = any(w in report_lower for w in mismatch_words)
    is_low = ai.get('overall_rating', 0) <= 35

    if is_mismatch or is_low:
        error_report = ai.get('ai_scout_report', '⚠️ HATA: Uyumsuz video.')
        db.delete(player)
        db.commit()
        return {"message": "Analiz başarısız: Uyumsuz veya geçersiz video.", "error": error_report, "deleted": True}

    # ── 4. Sonuçları kaydet (NORMAL SENARYO) ───────────────────────────────────
    skill_fields = [
        'pace', 'finishing', 'passing', 'dribbling', 'defending', 'strength',
        'technical_ability', 'physical_attributes', 'tactical_awareness', 'mental_attributes',
    ]
    player.skill_scores = {f: ai.get(f, 40) for f in skill_fields}
    player.overall_rating = ai.get('overall_rating', 50)
    player.ai_summary_report = ai.get('ai_scout_report', 'Analiz tamamlandı.')
    player.ai_strengths = ai.get('ai_strengths', [])
    player.ai_improvements = ai.get('ai_improvements', [])

    flag_modified(player, 'skill_scores')
    flag_modified(player, 'ai_strengths')
    flag_modified(player, 'ai_improvements')

    db.commit()
    return {"message": "Analiz tamamlandı! ✅", "player": player.to_dict()}


@app.get("/players/{player_id}")
def get_player_by_id(player_id: int, db: Session = Depends(get_db)):
    """Flutter /players/{id} istekleri için alias — get_player_detail ile aynı mantık."""
    mv_player = db.query(models_multivideo.PlayerMultiVideo).filter(
        models_multivideo.PlayerMultiVideo.id == player_id
    ).first()
    if mv_player:
        payload = _multivideo_to_public_dict(mv_player, db)
        payload["community_rating"] = _build_community_rating_summary_mv(db, player_id)
        return payload

    player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")
    payload = _player_to_dict(player, db)
    payload["community_rating"] = _build_community_rating_summary(db, player.id)
    return payload

# Video dosyasını iOS ile uyumlu şekilde sunan endpoint
@app.get("/video/{filename}")
async def serve_video(filename: str, request: Request):
    video_path = os.path.join("static/videos", filename)
    
    if not os.path.exists(video_path):
        raise HTTPException(status_code=404, detail="Video bulunamadı")
    
    # Dosya boyutunu al
    file_size = os.path.getsize(video_path)
    
    # Range header'ı kontrol et
    range_header = request.headers.get("range")
    headers = {
        "Accept-Ranges": "bytes",
        "Content-Type": "video/mp4",
    }
    
    if range_header:
        # Range request (iOS video player bunu kullanır)
        start, end = range_header.replace("bytes=", "").split("-")
        start = int(start) if start else 0
        end = int(end) if end else file_size - 1
        
        # Content-Length ve Content-Range header'larını ayarla
        content_length = end - start + 1
        headers.update({
            "Content-Range": f"bytes {start}-{end}/{file_size}",
            "Content-Length": str(content_length),
        })
        
        # Dosyanın ilgili kısmını oku
        with open(video_path, "rb") as f:
            f.seek(start)
            data = f.read(content_length)
        
        return Response(
            content=data,
            status_code=206,  # Partial Content
            headers=headers
        )
    else:
        # Tam dosya
        headers["Content-Length"] = str(file_size)
        return FileResponse(
            video_path,
            headers=headers
        )


# ===================== SCOUT ONAY SİSTEMİ =====================

SCOUT_DOCS_DIR = "static/scout_docs"
os.makedirs(SCOUT_DOCS_DIR, exist_ok=True)

# Cloudinary config
try:
    import cloudinary
    import cloudinary.uploader
    _cld_url = os.getenv("CLOUDINARY_URL", "")
    if _cld_url:
        cloudinary.config(cloudinary_url=_cld_url)
        _use_cloudinary = True
        print("[STORAGE] Cloudinary aktif")
    else:
        _use_cloudinary = False
        print("[STORAGE] Cloudinary URL yok, local storage kullanılıyor")
except ImportError:
    _use_cloudinary = False
    print("[STORAGE] cloudinary paketi yok, local storage kullanılıyor")


@app.post("/upload-document", tags=["Scout Approval"])
def upload_scout_document(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Scout belgesi yükle (TFF lisansı, PFSA sertifikası vb.)"""
    if current_user.role not in (ROLE_PENDING_SCOUT, ROLE_SCOUT):
        raise HTTPException(status_code=403, detail="Sadece scout kullanıcıları belge yükleyebilir.")

    allowed_types = {
        "image/jpeg", "image/png", "image/jpg", "image/webp", "application/pdf"
    }
    allowed_extensions = {"jpg", "jpeg", "png", "webp", "pdf", "heic", "heif"}
    ext_from_name = (file.filename or "").rsplit(".", 1)[-1].lower() if "." in (file.filename or "") else ""
    if file.content_type not in allowed_types and ext_from_name not in allowed_extensions:
        raise HTTPException(status_code=400, detail="Sadece JPG, PNG, WEBP veya PDF dosyası yükleyebilirsiniz.")

    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "bin"
    filename = f"{uuid.uuid4()}.{ext}"

    file_bytes = file.file.read()

    if _use_cloudinary:
        import cloudinary.uploader, io
        resource_type = "raw" if ext == "pdf" else "image"
        result = cloudinary.uploader.upload(
            io.BytesIO(file_bytes),
            public_id=f"scout_docs/{filename}",
            resource_type=resource_type,
        )
        doc_url = result["secure_url"]
    else:
        dest = os.path.join(SCOUT_DOCS_DIR, filename)
        with open(dest, "wb") as f:
            f.write(file_bytes)
        doc_url = f"/static/scout_docs/{filename}"
    db.query(models.User).filter(models.User.id == current_user.id).update(
        {"scout_document_url": doc_url},
        synchronize_session=False,
    )
    db.commit()

    # Send admin notification about new pending scout
    email_service.send_pending_notification_to_admin(
        user_name=current_user.full_name or current_user.email,
        user_email=current_user.email
    )

    return {"message": "Belge yüklendi, inceleme bekliyor. Onaylandığında mail alacaksınız.", "document_url": doc_url}


@app.get("/admin/pending-scouts", tags=["Admin"])
def list_pending_scouts(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Bekleyen scout listesi (sadece admin)."""
    if (current_user.role or "").lower() != ROLE_ADMIN:
        raise HTTPException(status_code=403, detail="Sadece adminler erişebilir.")

    scouts = (
        db.query(models.User)
        .filter(
            models.User.role == ROLE_PENDING_SCOUT,
            models.User.scout_document_url.isnot(None),
        )
        .all()
    )
    return [
        {
            "id": u.id,
            "full_name": u.full_name,
            "email": u.email,
            "phone_number": u.phone_number,
            "scout_document_url": u.scout_document_url,
            "created_at": u.created_at.isoformat() if u.created_at else None,
        }
        for u in scouts
    ]


@app.put("/admin/approve-scout/{user_id}", tags=["Admin"])
def approve_scout(
    user_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Belirtilen kullanıcıyı scout olarak onayla (sadece admin)."""
    if (current_user.role or "").lower() != ROLE_ADMIN:
        raise HTTPException(status_code=403, detail="Sadece adminler erişebilir.")

    target = db.query(models.User).filter(models.User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
    if target.role != ROLE_PENDING_SCOUT:
        raise HTTPException(status_code=400, detail="Bu kullanıcı zaten onaylı veya farklı bir roldedir.")

    target.role = ROLE_SCOUT
    db.commit()

    # Send approval email to the scout
    email_sent = email_service.send_approval_email(
        user_email=target.email,
        user_name=target.full_name or target.email
    )

    return {
        "message": f"{target.full_name} başarıyla scout olarak onaylandı." + 
                  (" Onay maili gönderildi." if email_sent else " Mail gönderilemedi."),
        "user_id": user_id,
        "email_sent": email_sent
    }


# ── SETUP: Admin kullanıcı oluştur (bir kez çalıştır) ─────────────────────────
@app.post("/setup/create-admin")
def create_admin(db: Session = Depends(get_db)):
    from auth import get_password_hash
    existing = db.query(models.User).filter(models.User.email == "info.yetenekavcisi@gmail.com").first()
    if existing:
        existing.role = "admin"
        existing.is_verified = True
        db.commit()
        return {"message": "Mevcut kullanici admin yapildi", "email": existing.email}
    admin = models.User(
        email="info.yetenekavcisi@gmail.com",
        hashed_password=get_password_hash("Admin123!"),
        role="admin",
        full_name="Admin",
        is_verified=True,
    )
    db.add(admin)
    db.commit()
    return {"message": "Admin olusturuldu", "email": "info.yetenekavcisi@gmail.com"}


@app.post("/setup/create-test-users")
def create_test_users(db: Session = Depends(get_db)):
    from auth import get_password_hash, create_access_token
    results = []

    users_to_create = [
        {"email": "info@yetenekavcisi.com", "full_name": "Admin", "role": "Scout", "phone": "5000000001"},
        {"email": "test@yetenekavcisi.com", "full_name": "Tester", "role": "Futbolcu", "phone": "5000000002"},
    ]

    for u in users_to_create:
        user = db.query(models.User).filter(models.User.email == u["email"]).first()
        if user:
            user.is_verified = True
            user.is_profile_complete = True
            user.role = u["role"]
            user.hashed_password = get_password_hash("Admin123!")
            db.commit()
            db.refresh(user)
            results.append({"email": u["email"], "status": "updated", "role": user.role})
        else:
            new_user = models.User(
                email=u["email"],
                full_name=u["full_name"],
                hashed_password=get_password_hash("Admin123!"),
                role=u["role"],
                phone_number=u["phone"],
                is_verified=True,
                is_profile_complete=True,
                is_active=True,
            )
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            results.append({"email": u["email"], "status": "created", "role": new_user.role})

    return {"message": "Test kullanicilari hazir", "users": results}


@app.post("/setup/clean-duplicate-players")
def clean_duplicate_players(db: Session = Depends(get_db)):
    from sqlalchemy import func
    duplicates = (
        db.query(models.Player.user_id, func.min(models.Player.id).label("keep_id"))
        .group_by(models.Player.user_id)
        .having(func.count(models.Player.id) > 1)
        .all()
    )
    deleted = 0
    for dup in duplicates:
        db.query(models.Player).filter(
            models.Player.user_id == dup.user_id,
            models.Player.id != dup.keep_id
        ).delete()
        deleted += 1
    db.commit()
    return {"message": f"{deleted} duplicate temizlendi"}