import os
from database import SessionLocal, engine
import models
import models_multivideo
import auth

# 🚨 SİHİRLİ DOKUNUŞ: Tablolar yoksa (veya boş DB bulduysa) zorla yaratır!
models.Base.metadata.create_all(bind=engine)
models_multivideo.Base.metadata.create_all(bind=engine)

def seed_users():
    db = SessionLocal()
    try:
        # 1. SCOUT KULLANICISI (Admin)
        admin = db.query(models.User).filter(models.User.email == "admin@test.com").first()
        if not admin:
            new_admin = models.User(
                full_name="Yetenek Avcısı Scout",
                email="admin@test.com",
                hashed_password=auth.get_password_hash("admin123"),
                role="Scout",
                is_verified=True,          # OTP sormasın diye
                is_profile_complete=True,  # Direkt içeri alsın diye
                is_active=True
            )
            db.add(new_admin)
            print("✅ BAŞARILI: Scout oluşturuldu! (Email: admin@test.com | Şifre: admin123)")
        else:
            print("✅ ZATEN VAR: Scout zaten mevcut. (Email: admin@test.com)")

        # 2. FUTBOLCU KULLANICISI (Video yükleme testleri için)
        oyuncu = db.query(models.User).filter(models.User.email == "oyuncu5@test.com").first()
        if not oyuncu:
            new_oyuncu = models.User(
                full_name="Test Futbolcu",
                email="oyuncu5@test.com",
                hashed_password=auth.get_password_hash("oyuncu1234"),
                role="Futbolcu",
                is_verified=True,          # OTP sormasın diye
                is_profile_complete=True,  # Direkt içeri alsın diye
                is_active=True,
                age=19                     # Veritabanı kurallarına uysun diye
            )
            db.add(new_oyuncu)
            print("✅ BAŞARILI: Futbolcu oluşturuldu! (Email: oyuncu@test.com | Şifre: oyuncu123)")
        else:
            print("✅ ZATEN VAR: Futbolcu zaten mevcut. (Email: oyuncu@test.com)")

        db.commit()

    except Exception as e:
        print(f"❌ BEKLENMEYEN HATA: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("🔑 TEST KULLANICILARI OLUŞTURULUYOR...")
    print("==================================================")
    seed_users()