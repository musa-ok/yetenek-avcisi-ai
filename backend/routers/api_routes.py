"""Tüm REST endpoint'leri — main.py'den taşındı (router)."""
import os
import uuid
import shutil
import mimetypes
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Request, Response, status, BackgroundTasks
from fastapi.responses import FileResponse
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import func
from sqlalchemy.orm.attributes import flag_modified

import auth
import models
import models_multivideo
import schemas
import otp_service
import email_service
import vision
from database import get_db
from deps import (
    ROLE_ADMIN,
    ROLE_PENDING_SCOUT,
    ROLE_SCOUT,
    create_user_token,
    get_current_user,
    get_optional_user,
    require_scout,
    require_setup_enabled,
)
from services import player_helpers as ph
from services import rating_helpers as rating_h
from services.analysis_worker import run_multivideo_finalize
from services.smart_summary import build_smart_summary
from storage import StorageService

router = APIRouter()
storage_service = StorageService()

player_to_dict = ph.player_to_dict
build_community_rating_summary = ph.build_community_rating_summary
build_community_rating_summary_mv = ph.build_community_rating_summary_mv
calculate_overall_from_position = ph.calculate_overall_from_position
multivideo_to_public_dict = ph.multivideo_to_public_dict
scout_ratings_for_multivideo = ph.scout_ratings_for_multivideo
scout_ratings_for_legacy = ph.scout_ratings_for_legacy
resolve_player_detail = ph.resolve_player_detail

@router.get(
    "/",
    tags=["Health Check"],
    summary="API Health Check",
    description="API'nin çalıştığını doğrulamak için basit health check endpoint'i",
)
def read_root():
    return {"mesaj": "Yetenek Avcısı API Başarıyla Çalışıyor! ⚽🚀"}


# ESKİ /register ENDPOINTİ - YENİ /auth/register KULLANILIYOR (routers/auth.py)
# @router.post("/register", tags=["Authentication"])
# def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
#     ...


# ESKİ /auth/send-otp - YENİ /auth/resend-otp KULLANILIYOR (routers/auth.py - DB tabanlı)
# @router.post("/auth/send-otp", tags=["Authentication"])
# def send_otp(payload: dict, db: Session = Depends(get_db)):
#     ...eski in-memory otp_service tabanlı endpoint - kapatıldı...


# ESKİ /auth/verify-otp - YENİ routers/auth.py KULLANILIYOR (otp_store ile)
# @router.post("/auth/verify-otp", tags=["Authentication"])
# def verify_otp(payload: dict, db: Session = Depends(get_db)):
#     ...eski otp_service tabanlı endpoint - ÇAKIŞIYORDU, kapatıldı...


# ESKİ /login ENDPOINTİ - YENİ /auth/login KULLANILIYOR (routers/auth.py)
# @router.post("/login", response_model=schemas.LoginResponse)
# def login_user(payload: schemas.LoginRequest, db: Session = Depends(get_db)):
#     ...


@router.post("/token", response_model=schemas.Token)
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
    
    return {"access_token": create_user_token(db_user), "token_type": "bearer"}


# ===================== SOSYAL MEDYA AUTH =====================
# ESKİ /auth/social ve /auth/social/register → YENİ routers/auth.py KULLANILIYOR
# ESKİ /auth/send-otp → YENİ /auth/resend-otp KULLANILIYOR (routers/auth.py - DB tabanlı)


# ESKİ /auth/verify-otp ENDPOINTİ - YENİ /auth/verify-otp KULLANILIYOR (routers/auth.py)
# @router.post("/auth/verify-otp")
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
#         "access_token": create_user_token(db_user),
#         "token_type": "bearer",
#         "user": db_user,
#     }


@router.post("/auth/forgot-password", tags=["Authentication"])
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


@router.post("/auth/reset-password", tags=["Authentication"])
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


@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user


@router.post("/me/upload-photo")
async def upload_profile_photo(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    import cloudinary
    import cloudinary.uploader
    import os
    cloudinary.config(
        cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
        api_key=os.getenv("CLOUDINARY_API_KEY"),
        api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    )
    contents = await file.read()
    result = cloudinary.uploader.upload(contents, folder="profile_photos", resource_type="image")
    url = result.get("secure_url")
    current_user.profile_image_url = url
    db.commit()
    db.refresh(current_user)
    return {"profile_image_url": url}


@router.put("/me", response_model=schemas.UserResponse)
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


@router.get("/players")
def get_players(
    position: Optional[str] = None,
    min_age: Optional[int] = None,
    max_age: Optional[int] = None,
    min_ovr: Optional[int] = None,
    max_ovr: Optional[int] = None,
    city: Optional[str] = None,
    rising_7d: bool = False,
    db: Session = Depends(get_db),
):
    from services.player_discovery import discover_players_as_dicts

    return discover_players_as_dicts(
        db,
        position=position,
        min_age=min_age,
        max_age=max_age,
        min_ovr=min_ovr,
        max_ovr=max_ovr,
        city=city,
        rising_7d=rising_7d,
    )


@router.post("/players", response_model=schemas.PlayerResponse)
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
    new_player.overall_rating = calculate_overall_from_position(new_player)
    db.add(new_player)
    db.commit()
    db.refresh(new_player)
    return new_player


@router.post("/upload-video/")
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
        
        new_player.overall_rating = calculate_overall_from_position(new_player)

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


@router.post("/players/multivideo/{player_id}/rate")
def rate_multivideo_player(
    player_id: int,
    rating: schemas.PlayerRatingCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_scout),
):
    player = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.id == player_id)
        .first()
    )
    if not player:
        raise HTTPException(status_code=404, detail="Multi-video oyuncu bulunamadı.")

    rating_h.assert_can_rate_player(current_user, player_user_id=player.user_id)

    reviewer_id = current_user.id
    _, created = rating_h.upsert_rating_row(
        db,
        models.MultiVideoRating,
        reviewer_id=reviewer_id,
        player_id=player_id,
        rating=rating,
    )

    if player.user_id and created:
        from services.notifications import notify_new_rating_on_player

        notify_new_rating_on_player(
            db,
            player.user_id,
            player_id,
            current_user.full_name or current_user.email or "Scout",
        )

    summary = rating_h.build_community_rating_summary_mv(
        db, player_id, current_user_id=reviewer_id
    )
    return {
        "mesaj": "Puan güncellendi." if not created else "Multi-video community rating kaydedildi.",
        "player_id": player_id,
        "reviewer_id": reviewer_id,
        "created": created,
        "community_rating": summary,
        "scout_ratings": rating_h.scout_ratings_for_multivideo(
            db, player_id, current_user_id=reviewer_id
        ),
    }


@router.post("/players/{player_id}/rate")
def rate_player(
    player_id: int,
    rating: schemas.PlayerRatingCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_scout),
):
    player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")

    rating_h.assert_can_rate_player(current_user, player_user_id=player.user_id)

    reviewer_id = current_user.id
    _, created = rating_h.upsert_rating_row(
        db,
        models.Rating,
        reviewer_id=reviewer_id,
        player_id=player_id,
        rating=rating,
    )

    if player.user_id and created:
        from services.notifications import notify_new_rating_on_player

        notify_new_rating_on_player(
            db,
            player.user_id,
            player_id,
            current_user.full_name or current_user.email or "Scout",
        )

    return {
        "mesaj": "Puan güncellendi." if not created else "Community rating kaydedildi.",
        "player_id": player_id,
        "reviewer_id": reviewer_id,
        "created": created,
        "community_rating": rating_h.build_community_rating_summary(
            db, player_id, current_user_id=reviewer_id
        ),
    }


@router.get("/players/detail/{player_id}")
def get_player_detail(player_id: int, db: Session = Depends(get_db)):
    mv_player = db.query(models_multivideo.PlayerMultiVideo).filter(models_multivideo.PlayerMultiVideo.id == player_id).first()
    if mv_player:
        payload = multivideo_to_public_dict(mv_player, db)
        payload["community_rating"] = build_community_rating_summary_mv(db, player_id)
        return payload

    player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")
    payload = player_to_dict(player)
    payload["community_rating"] = build_community_rating_summary(db, player.id)
    return payload


@router.get("/analysis-steps/{position}")
def get_analysis_steps(position: str):
    from step_analyzer import step_analyzer
    try:
        return step_analyzer.get_step_preview(position)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Analiz adımları alınamadı: {str(e)}")


@router.post("/upload-video-step-by-step/")
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
        new_player.overall_rating = calculate_overall_from_position(new_player)
        db.add(new_player)
        db.commit()
        db.refresh(new_player)

        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

        return {"message": "Adım adım analiz tamamlandı!", "player": player_to_dict(new_player), "analysis_summary": {"analysis_type": ai_data.get("analysis_type", "step_by_step"), "total_steps": ai_data.get("total_steps", 0), "average_score": ai_data.get("average_score", 0), "detailed_ratings": {k: v for k, v in ai_data.items() if k != "ai_scout_report"}}}

    except Exception as e:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
        raise HTTPException(status_code=500, detail=f"Analiz sırasında hata: {str(e)}")


@router.get("/position-skills/{position}")
def get_position_skills(position: str):
    from position_skills_config import get_skills_for_position, get_position_code
    skills = get_skills_for_position(position)
    if not skills:
        raise HTTPException(status_code=404, detail=f"Mevki bulunamadı: {position}")
    return {"position": position, "position_code": get_position_code(position), "total_skills": len(skills), "skills": skills}


@router.post("/players/multivideo/create")
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
    from position_skills_config import get_required_video_count
    n = get_required_video_count(position)
    return {
        "message": f"Oyuncu kaydı oluşturuldu ({age} yaş). Şimdi {n} video yükleyin.",
        "player": player.to_dict(),
    }


@router.post("/players/multivideo/create-from-auth")
def create_multivideo_player_from_auth(position: str = Form(...), db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    from position_skills_config import get_position_code
    from datetime import datetime, timezone
    position_code = get_position_code(position)
    name = current_user.full_name or current_user.email.split('@')[0]
    age = current_user.age or 18
    
    # 🚨 HER ZAMAN YENI PLAYER OLUŞTUR - Eski varsa dokunma, yeni kayıt aç
    # Kullanıcı "İstatistiklerim" sayfasından eski analizlere bakabilir
    player = models_multivideo.PlayerMultiVideo(
        user_id=current_user.id, 
        name=name, 
        age=age, 
        position=position, 
        position_code=position_code, 
        overall_rating=0, 
        skill_scores={}, 
        ai_strengths=[], 
        ai_improvements=[]
    )
    db.add(player)
    db.commit()
    db.refresh(player)
    from position_skills_config import get_required_video_count
    n = get_required_video_count(position)
    return {
        "message": f"{name} için kayıt oluşturuldu. Şimdi {n} video yükleyin.",
        "player": player.to_dict(),
    }

# ── UPLOAD SLOT: uyumluluk kontrolü + video kaydet ───────────────────────────
@router.post("/players/multivideo/{player_id}/upload-slot-{slot}")
async def upload_video_to_slot(
    player_id: int,
    slot: int,
    skill_name: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    import os
    import tempfile
    import uuid as _uuid

    import vision
    from position_skills_config import is_kosu_slot_for
    from services.multivideo_slots import set_url_for_logical_slot

    if slot not in (1, 2, 3):
        raise HTTPException(status_code=400, detail="Slot 1, 2 veya 3 olmalıdır.")
    player = db.query(models_multivideo.PlayerMultiVideo).filter(models_multivideo.PlayerMultiVideo.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")

    if is_kosu_slot_for(player.position or "", slot):
        raise HTTPException(
            status_code=400,
            detail="Bu slot Hız testi. Önce 20 metre düz, sonra 10 metre yokuş yukarı yükleyin.",
        )

    temp_path = None
    try:
        file_content = await file.read()
        suffix = os.path.splitext(file.filename or "")[1] or ".mp4"
        temp_path = os.path.join(
            tempfile.gettempdir(), f"slot_{player_id}_{slot}_{_uuid.uuid4()}{suffix}"
        )
        with open(temp_path, "wb") as tmp:
            tmp.write(file_content)

        check = vision.validate_slot_video(
            temp_path, player.position or "", skill_name
        )
        if not check.get("compatible", True):
            raise HTTPException(
                status_code=400,
                detail=check.get("message", "Uyumsuz video"),
            )

        ext = suffix or ".mp4"
        video_url = storage_service.upload_video_bytes(
            file_content, f"{player_id}_slot{slot}_{_uuid.uuid4()}{ext}"
        )
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Video yükleme hatası: {exc}")
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError:
                pass

    try:
        set_url_for_logical_slot(player, slot, video_url, skill_name)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    db.commit()
    db.refresh(player)
    return {
        "message": f"Slot {slot} yüklendi: {skill_name}",
        "completion": player.completion_percentage,
        "player": player.to_dict(),
    }


@router.post("/players/multivideo/{player_id}/upload-slot-{slot}/kosu")
async def upload_kosu_slot_video(
    player_id: int,
    slot: int,
    phase: str = Form(...),
    skill_name: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Koşu/hız slotu: phase=flat (20m düz) veya phase=uphill (10m yokuş)."""
    import os
    import tempfile
    import uuid as _uuid

    import vision
    from position_skills_config import (
        KOSU_FLAT_LABEL,
        KOSU_UPHILL_LABEL,
        is_kosu_slot_for,
    )
    from services.multivideo_slots import _kosu_entry, set_kosu_video

    phase_norm = (phase or "").strip().lower()
    if phase_norm not in ("flat", "uphill"):
        raise HTTPException(status_code=400, detail="phase=flat veya phase=uphill olmalı.")

    if slot not in (1, 2, 3):
        raise HTTPException(status_code=400, detail="Slot 1, 2 veya 3 olmalıdır.")

    player = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.id == player_id)
        .first()
    )
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")

    if not is_kosu_slot_for(player.position or "", slot):
        raise HTTPException(status_code=400, detail="Bu slot çift video (Hız) testi değil.")

    if phase_norm == "uphill" and not _kosu_entry(player, slot).get("flat_url"):
        raise HTTPException(
            status_code=400,
            detail="Önce 20 metre düz koşu videosunu yükleyin.",
        )

    test_label = KOSU_FLAT_LABEL if phase_norm == "flat" else KOSU_UPHILL_LABEL
    dist = 20.0 if phase_norm == "flat" else 10.0
    quality: dict = {}
    temp_path = None
    try:
        file_content = await file.read()
        suffix = os.path.splitext(file.filename or "")[1] or ".mp4"
        temp_path = os.path.join(
            tempfile.gettempdir(),
            f"kosu_{player_id}_{slot}_{phase_norm}_{_uuid.uuid4()}{suffix}",
        )
        with open(temp_path, "wb") as tmp:
            tmp.write(file_content)

        check = vision.validate_slot_video(
            temp_path, player.position or "", test_label
        )
        if not check.get("compatible", True):
            raise HTTPException(
                status_code=400,
                detail=check.get("message", "Uyumsuz video"),
            )

        from services.sprint_quality import assess_kosu_upload

        quality = assess_kosu_upload(temp_path, distance_m=dist, strict_block=True)
        if quality.get("block_upload"):
            reason = quality.get("user_message") or (
                (quality.get("tips") or ["Çekimi iyileştirip tekrar deneyin."])[0]
            )
            raise HTTPException(
                status_code=400,
                detail=f"Video kabul edilmedi. {reason}",
            )

        video_url = storage_service.upload_video_bytes(
            file_content,
            f"{player_id}_kosu_{phase_norm}_{_uuid.uuid4()}{suffix or '.mp4'}",
        )
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Video yükleme hatası: {exc}") from exc
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError:
                pass

    set_kosu_video(
        player,
        slot,
        phase=phase_norm,
        url=video_url,
        skill_name=skill_name,
    )

    db.commit()
    db.refresh(player)
    step = "20m düz koşu" if phase_norm == "flat" else "10m yokuş koşu"
    return {
        "message": f"{step} yüklendi.",
        "completion": player.completion_percentage,
        "player": player.to_dict(),
        "kosu_quality": quality,
    }


@router.get("/players/multivideo")
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


@router.get("/players/multivideo/{player_id}")
def get_multivideo_player_detail(player_id: int, db: Session = Depends(get_db)):
    player = db.query(models_multivideo.PlayerMultiVideo).filter(models_multivideo.PlayerMultiVideo.id == player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı")
    return player.to_dict()


# ── FINALIZE: 3 videoyu AI ile analiz et (async kuyruk) ──────────
@router.post("/players/multivideo/{player_id}/finalize")
def finalize_multivideo_player(
    player_id: int,
    background_tasks: BackgroundTasks,
    sync: bool = False,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    from services.daily_quota import reserve_daily_analysis_quota

    player = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.id == player_id)
        .first()
    )
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")
    if player.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Bu analizi başlatma yetkiniz yok.")
    if not player.is_complete:
        raise HTTPException(
            status_code=400,
            detail=f"Tüm videolar henüz yüklenmemiş. Tamamlanma: %{player.completion_percentage:.0f}",
        )
    if player.analysis_status == "processing":
        return {
            "message": "Analiz zaten devam ediyor.",
            "analysis_status": "processing",
            "player_id": player_id,
        }

    reserve_daily_analysis_quota(
        db, current_user, player_analysis_status=player.analysis_status
    )

    if sync:
        result = run_multivideo_finalize(player_id)
        if not result.get("ok"):
            return {
                "message": result.get("error", "Analiz başarısız."),
                "analysis_status": "failed",
                "retryable": result.get("retryable", False),
                "partial": result.get("partial", False),
                "player": result.get("player"),
            }
        return {
            "message": "Analiz tamamlandı! ✅",
            "analysis_status": "completed",
            "player": result.get("player"),
        }

    player.analysis_status = "pending"
    player.analysis_error = None
    db.commit()
    background_tasks.add_task(run_multivideo_finalize, player_id)
    return {
        "message": "Analiz kuyruğa alındı. Birkaç dakika içinde tamamlanacak.",
        "analysis_status": "processing",
        "player_id": player_id,
    }


@router.get("/players/multivideo/{player_id}/smart-summary")
def get_smart_summary(player_id: int, db: Session = Depends(get_db)):
    return build_smart_summary(db, player_id, source="multivideo")


@router.get("/players/multivideo/{player_id}/analysis-status")
def get_analysis_status(player_id: int, db: Session = Depends(get_db)):
    player = (
        db.query(models_multivideo.PlayerMultiVideo)
        .filter(models_multivideo.PlayerMultiVideo.id == player_id)
        .first()
    )
    if not player:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")
    return {
        "player_id": player_id,
        "analysis_status": player.analysis_status,
        "analysis_error": player.analysis_error,
        "overall_rating": player.overall_rating,
        "is_complete": player.is_complete,
    }


@router.get("/players/{player_id}")
def get_player_by_id(
    player_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[models.User] = Depends(get_optional_user),
):
    """Flutter /players/{id} istekleri için alias — get_player_detail ile aynı mantık."""
    uid = current_user.id if current_user else None
    payload = resolve_player_detail(db, player_id, current_user_id=uid)
    if not payload:
        raise HTTPException(status_code=404, detail="Oyuncu bulunamadı.")
    return payload

# Video dosyasını iOS ile uyumlu şekilde sunan endpoint
@router.get("/video/{filename}")
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


@router.post("/upload-document", tags=["Scout Approval"])
def upload_scout_document(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Scout belgesi yükle (TFF lisansı, PFSA sertifikası vb.)"""
    if current_user.role not in (ROLE_PENDING_SCOUT, ROLE_SCOUT):
        raise HTTPException(status_code=403, detail="Sadece scout kullanıcıları belge yükleyebilir.")

    file_bytes = file.file.read()
    from services.file_validation import validate_scout_document

    ext = validate_scout_document(
        filename=file.filename or "",
        content_type=file.content_type,
        data=file_bytes,
    )
    filename = f"{uuid.uuid4()}.{ext}"

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


@router.get("/admin/pending-scouts", tags=["Admin"])
def list_pending_scouts(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Bekleyen scout listesi (sadece admin)."""
    if (current_user.role or "").lower() != ROLE_ADMIN:
        raise HTTPException(status_code=403, detail="Sadece adminler erişebilir.")

    from sqlalchemy.orm import aliased

    Referrer = aliased(models.User)
    rows = (
        db.query(models.User, Referrer)
        .outerjoin(Referrer, models.User.referred_by_user_id == Referrer.id)
        .filter(
            models.User.role == ROLE_PENDING_SCOUT,
            models.User.scout_document_url.isnot(None),
        )
        .order_by(models.User.created_at.desc())
        .all()
    )
    result = []
    for u, referrer in rows:
        referrer_name = None
        referrer_email = None
        referrer_code = None
        if referrer is not None:
            referrer_name = (referrer.full_name or "").strip() or None
            referrer_email = referrer.email
            referrer_code = referrer.referral_code
        result.append(
            {
                "id": u.id,
                "full_name": u.full_name,
                "email": u.email,
                "phone_number": u.phone_number,
                "scout_document_url": u.scout_document_url,
                "created_at": u.created_at.isoformat() if u.created_at else None,
                "referred_by_user_id": u.referred_by_user_id,
                "referrer_name": referrer_name,
                "referrer_email": referrer_email,
                "referrer_code": referrer_code,
            }
        )
    return result


@router.put("/admin/approve-scout/{user_id}", tags=["Admin"])
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

    from services.notifications import notify_scout_approved

    notify_scout_approved(db, target.id)

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


@router.put("/admin/reject-scout/{user_id}", tags=["Admin"])
def reject_scout(
    user_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Bekleyen scout başvurusunu reddet (sadece admin). Kullanıcı kaydı silinir."""
    if (current_user.role or "").lower() != ROLE_ADMIN:
        raise HTTPException(status_code=403, detail="Sadece adminler erişebilir.")

    target = db.query(models.User).filter(models.User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")
    if target.role != ROLE_PENDING_SCOUT:
        raise HTTPException(
            status_code=400,
            detail="Yalnızca onay bekleyen scout başvuruları reddedilebilir.",
        )

    name = target.full_name or target.email
    user_email = target.email

    from services.notifications import notify_scout_rejected

    notify_scout_rejected(db, target.id, name)

    db.delete(target)
    db.commit()

    email_sent = False
    if user_email:
        email_sent = email_service.send_rejection_email(
            user_email=user_email,
            user_name=name or user_email,
        )

    return {
        "message": f"{name} başvurusu reddedildi."
        + (" Red bildirim e-postası gönderildi." if email_sent else " E-posta gönderilemedi.")
        + " Push bildirimi gönderildi (cihazda kayıtlıysa).",
        "user_id": user_id,
        "email_sent": email_sent,
    }


# ── SETUP: Admin kullanıcı oluştur (bir kez çalıştır) ─────────────────────────
@router.post("/setup/create-admin")
def create_admin(
    db: Session = Depends(get_db),
    _: None = Depends(require_setup_enabled),
):
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


@router.post("/setup/create-test-users")
def create_test_users(
    db: Session = Depends(get_db),
    _: None = Depends(require_setup_enabled),
):
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


@router.post("/setup/clean-duplicate-players")
def clean_duplicate_players(
    db: Session = Depends(get_db),
    _: None = Depends(require_setup_enabled),
):
    deleted = 0
    for model in [models.Player, models_multivideo.PlayerMultiVideo]:
        all_players = db.query(model).order_by(model.user_id, model.id).all()
        seen = {}
        for p in all_players:
            if p.user_id in seen:
                db.delete(p)
                deleted += 1
            else:
                seen[p.user_id] = p.id
    db.commit()
    return {"message": f"{deleted} duplicate temizlendi"}


@router.post("/admin/reset-analysis-quota", tags=["Admin"])
def reset_analysis_quota(
    payload: dict,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Belirtilen kullanıcıların günlük analiz limitini sıfırla (sadece admin)."""
    if (current_user.role or "").lower() != ROLE_ADMIN:
        raise HTTPException(status_code=403, detail="Sadece adminler erişebilir.")
    
    emails = payload.get("emails", [])
    if not emails:
        raise HTTPException(status_code=400, detail="E-posta adresleri gereklidir.")
    
    results = []
    for email in emails:
        user = db.query(models.User).filter(models.User.email == email.strip().lower()).first()
        if user:
            user.daily_analyses_count = 0
            user.last_analysis_date = None
            db.commit()
            results.append({"email": email, "status": "reset", "daily_count": 0})
        else:
            results.append({"email": email, "status": "not_found"})
    
    return {"message": "Analiz limitleri sıfırlandı", "results": results}


@router.get("/privacy-policy", tags=["Legal"])
def privacy_policy_metadata():
    """Mobil privacy ekranı ile uyumlu politika özeti."""
    return {
        "version": "2025-05-30",
        "app": "Scoutiq",
        "kvkk_contact": "info@yetenekavcisi.com",
        "rights": [
            "hesap_silme",
            "veri_export",
            "bilgi_talep",
        ],
        "endpoints": {
            "delete_account": "DELETE /users/me",
            "export_data": "GET /users/me/export",
        },
    }


@router.get("/users/me/export", tags=["User"])
def export_my_data(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """KVKK veri taşınabilirliği — JSON export."""
    from services.user_export import export_user_data

    return export_user_data(db, current_user)


@router.delete("/users/me", tags=["User"])
def delete_my_account(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Kendi hesabını kalıcı olarak sil (GDPR/Apple 5.1.1(v) uyumluluk)."""
    from services.token_service import revoke_all_user_refresh_tokens

    user_id = current_user.id
    email = current_user.email

    import traceback

    try:
        revoke_all_user_refresh_tokens(db, user_id)
        print(f"[DELETE ACCOUNT] Starting deletion for user {user_id} ({email})")
        
        # 1. Önce kullanıcının verdiği tüm rating'leri sil (FK constraint)
        print(f"[DELETE ACCOUNT] Step 1: Deleting MultiVideoRating...")
        mv_ratings = db.query(models.MultiVideoRating).filter(
            models.MultiVideoRating.reviewer_id == user_id
        ).all()
        print(f"[DELETE ACCOUNT] Found {len(mv_ratings)} MultiVideoRating records")
        for r in mv_ratings:
            db.delete(r)
        db.commit()
        print(f"[DELETE ACCOUNT] MultiVideoRating deleted")
        
        # 2. Legacy ratings sil
        print(f"[DELETE ACCOUNT] Step 2: Deleting legacy Rating...")
        legacy_ratings = db.query(models.Rating).filter(
            models.Rating.reviewer_id == user_id
        ).all()
        print(f"[DELETE ACCOUNT] Found {len(legacy_ratings)} legacy Rating records")
        for r in legacy_ratings:
            db.delete(r)
        db.commit()
        print(f"[DELETE ACCOUNT] Legacy Rating deleted")
        
        # 3. Kullanıcının tüm multi-video player kayıtlarını sil
        print(f"[DELETE ACCOUNT] Step 3: Deleting PlayerMultiVideo...")
        mv_players = db.query(models_multivideo.PlayerMultiVideo).filter(
            models_multivideo.PlayerMultiVideo.user_id == user_id
        ).all()
        print(f"[DELETE ACCOUNT] Found {len(mv_players)} PlayerMultiVideo records")
        for p in mv_players:
            db.delete(p)
        db.commit()
        print(f"[DELETE ACCOUNT] PlayerMultiVideo deleted")
        
        # 4. Kullanıcının tüm legacy player kayıtlarını sil
        print(f"[DELETE ACCOUNT] Step 4: Deleting legacy Player...")
        legacy_players = db.query(models.Player).filter(
            models.Player.user_id == user_id
        ).all()
        print(f"[DELETE ACCOUNT] Found {len(legacy_players)} legacy Player records")
        for p in legacy_players:
            db.delete(p)
        db.commit()
        print(f"[DELETE ACCOUNT] Legacy Player deleted")
        
        # 5. Son olarak kullanıcıyı sil
        print(f"[DELETE ACCOUNT] Step 5: Deleting user {user_id}...")
        db.delete(current_user)
        db.commit()
        print(f"[DELETE ACCOUNT] ✅ User {user_id} successfully deleted")
        
        return {"message": "Hesabınız ve tüm verileriniz kalıcı olarak silindi"}
        
    except Exception as e:
        db.rollback()
        error_detail = f"{str(e)}\n{traceback.format_exc()}"
        print(f"[DELETE ACCOUNT] ❌ ERROR: {error_detail}")
        raise HTTPException(status_code=500, detail=f"Hesap silinirken hata: {str(e)}")