#!/usr/bin/env python3
"""
Çoklu video sistemi için database migration
"""

import sys
sys.path.insert(0, '/Users/musaok/Projects/yetenek-avcisi')

from backend.database import engine, Base
from backend import models

def migrate():
    print("🔄 Çoklu video tablosu oluşturuluyor...")
    
    # Tüm tabloları oluştur (eksik olanları)
    Base.metadata.create_all(bind=engine)
    
    print("✅ Migration tamamlandı!")
    print("\n📋 Yeni tablolar:")
    print("  - players_multivideo (3 video URL + yetenek puanları)")

if __name__ == "__main__":
    migrate()
