#!/usr/bin/env python3
"""FastAPI veritabanından kullanıcı silme betiği"""
import sys
import os

# Backend dizinine git
os.chdir(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
import models

def delete_user_by_email(email: str):
    """Veritabanından kullanıcıyı tamamen siler (hard delete)"""
    db = SessionLocal()
    try:
        # Kullanıcıyı bul
        user = db.query(models.User).filter(models.User.email == email.lower()).first()
        
        if user:
            print(f"[BULUNDU] ID: {user.id}, Email: {user.email}, Verified: {user.is_verified}")
            db.delete(user)  # Hard delete - tamamen sil
            db.commit()
            print(f"[✅ SİLİNDİ] {email} veritabanından tamamen temizlendi")
            return True
        else:
            print(f"[⚠️ YOK] {email} zaten veritabanında yok")
            return False
            
    except Exception as e:
        db.rollback()
        print(f"[❌ HATA] {e}")
        return False
    finally:
        db.close()

if __name__ == "__main__":
    email = sys.argv[1] if len(sys.argv) > 1 else "mok410681@gmail.com"
    print(f"\n{'='*50}")
    print(f"Kullanıcı Silme: {email}")
    print(f"{'='*50}\n")
    delete_user_by_email(email)
