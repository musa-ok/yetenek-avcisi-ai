#!/usr/bin/env python3
"""
Database'i yeni özelliklerle günceller (SQLite uyumlu)
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from backend.database import SessionLocal
from sqlalchemy import text

def update_database():
    """Database'i yeni özelliklerle günceller"""
    
    db = SessionLocal()
    
    try:
        print("🔄 Database güncelleniyor...")
        
        # Tablo yapısını kontrol et
        result = db.execute(text("PRAGMA table_info(players)"))
        columns = [row[1] for row in result.fetchall()]
        
        print(f"Mevcut kolonlar: {columns}")
        
        # Eksik kolonları ekle
        new_columns = {
            "dribbling_tight_spaces": "INTEGER",
            "heading": "INTEGER", 
            "composure": "INTEGER",
            "gk_distribution": "INTEGER",
            "gk_command_area": "INTEGER",
            "gk_1v1": "INTEGER"
        }
        
        for column_name, column_type in new_columns.items():
            if column_name not in columns:
                try:
                    sql = f"ALTER TABLE players ADD COLUMN {column_name} {column_type}"
                    db.execute(text(sql))
                    db.commit()
                    print(f"✅ Kolon eklendi: {column_name}")
                except Exception as e:
                    print(f"❌ Kolon eklenemedi {column_name}: {e}")
            else:
                print(f"⚠️ Kolon zaten mevcut: {column_name}")
        
        print("🎉 Database güncellemesi tamamlandı!")
        
    except Exception as e:
        print(f"❌ Hata: {str(e)}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    update_database()
