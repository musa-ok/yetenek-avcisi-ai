from database import SessionLocal
import models
import auth


def seed():
    db = SessionLocal()
    try:
        # ==========================================
        # 1. SCOUT (GÖZLEMCİ) HESABI OLUŞTURMA
        # ==========================================
        scout_email = "scout@avci.com"
        db_scout = db.query(models.User).filter(models.User.email == scout_email).first()

        if not db_scout:
            print("🔍 Scout kullanıcısı oluşturuluyor...")
            new_scout = models.User(
                full_name="Musa Scout",
                email=scout_email,
                hashed_password=auth.get_password_hash("sifre123"),
                role="Scout",
                phone_number="+905551112233"
            )
            db.add(new_scout)
            db.commit()
            print("✅ Scout hesabı oluşturuldu! Giriş: scout@avci.com / Şifre: sifre123")
        else:
            db_scout.role = "Scout"
            db_scout.hashed_password = auth.get_password_hash("sifre123")
            db.commit()
            print("⚡ Scout hesabı güncellendi (scout@avci.com).")

        # ==========================================
        # 2. FUTBOLCU HESABI OLUŞTURMA
        # ==========================================
        futbolcu_email = "arda@yildiz.com"
        db_futbolcu = db.query(models.User).filter(models.User.email == futbolcu_email).first()

        if not db_futbolcu:
            print("⚽ Futbolcu kullanıcısı oluşturuluyor: Arda Yıldız...")
            new_futbolcu = models.User(
                full_name="Arda Yıldız",
                email=futbolcu_email,
                hashed_password=auth.get_password_hash("sifre123"),
                role="Futbolcu",
                phone_number="+905554443322"
            )
            db.add(new_futbolcu)
            db.commit()
            db.refresh(new_futbolcu)
            db_futbolcu = new_futbolcu
            print("✅ Futbolcu hesabı oluşturuldu! Giriş: arda@yildiz.com / Şifre: sifre123")
        else:
            db_futbolcu.role = "Futbolcu"
            db_futbolcu.hashed_password = auth.get_password_hash("sifre123")
            db.commit()
            print("⚡ Futbolcu hesabı güncellendi (arda@yildiz.com).")

        # ==========================================
        # 3. FUTBOLCU İÇİN ÖRNEK ANALİZ/OYUNCU KAYDI EKLENMESİ
        # ==========================================
        db_player = db.query(models.Player).filter(models.Player.user_id == db_futbolcu.id).first()

        if not db_player:
            print("📊 Futbolcu için örnek oyuncu analizi oluşturuluyor...")
            new_player = models.Player(
                user_id=db_futbolcu.id,
                name="Arda Yıldız",
                age=19,
                position="Forvet",
                overall_rating=85,
                pace=90,
                finishing=88,
                dribbling=84,
                positioning=82,
                ai_scout_report="Arda, dar alanda yüksek top tekniği ve bitiricilik yeteneği ile öne çıkıyor. Patlayıcı gücü sayesinde defans arkasına sarkma konusunda çok etkili. Modern bir 9 numara potansiyeline sahip."
            )
            db.add(new_player)
            db.commit()
            print("✅ Örnek analiz verileri başarıyla eklendi! ⚽🔥")
        else:
            print("⚡ Örnek oyuncu kaydı zaten mevcut.")

    except Exception as e:
        print(f"❌ Hata oluştu: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()