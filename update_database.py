#!/usr/bin/env python3
"""
Database'i yeni özelliklerle günceller
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from backend.database import SessionLocal, engine
from backend import models
from sqlalchemy import text

def update_database():
    """Database'i yeni özelliklerle günceller"""
    
    db = SessionLocal()
    
    try:
        print("🔄 Database güncelleniyor...")
        
        # Yeni kolonları ekle
        new_columns = [
            # Forvet özellikleri
            "ALTER TABLE players ADD COLUMN IF NOT EXISTS dribbling_tight_spaces INTEGER",
            "ALTER TABLE players ADD COLUMN IF NOT EXISTS heading INTEGER", 
            "ALTER TABLE players ADD COLUMN IF NOT EXISTS composure INTEGER",
            
            # Kaleci özellikleri
            "ALTER TABLE players ADD COLUMN IF NOT EXISTS gk_distribution INTEGER",
            "ALTER TABLE players ADD COLUMN IF NOT EXISTS gk_command_area INTEGER",
            "ALTER TABLE players ADD COLUMN IF NOT EXISTS gk_1v1 INTEGER",
        ]
        
        for column_sql in new_columns:
            try:
                db.execute(text(column_sql))
                print(f"✅ Kolon eklendi: {column_sql}")
            except Exception as e:
                print(f"⚠️ Kolon zaten mevcut veya hata: {e}")
        
        db.commit()
        print("🎉 Database güncellemesi tamamlandı!")
        
    except Exception as e:
        print(f"❌ Hata: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    update_database()
