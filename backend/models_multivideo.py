"""
Multi-Video Player Model
Her oyuncu için 3 ayrı yetenek videosu ve puanları
"""

from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, JSON, Float, UniqueConstraint
from datetime import datetime, timezone
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import models

class PlayerMultiVideo(Base):
    """
    Çoklu video sistemi için oyuncu modeli
    Her mevki için 3 ayrı yetenek videosu
    """
    __tablename__ = "players_multivideo"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Temel Bilgiler
    name = Column(String, index=True)
    age = Column(Integer)
    position = Column(String, index=True)  # Kaleci, Stoper, Bek, CDM/CM, On Numara, Kanat, Forvet
    position_code = Column(String(10))  # GK, CB, FB, CM, CAM, WING, ST
    overall_rating = Column(Integer, default=50)
    
    # Video 1: Slot 1
    video_1_url = Column(String, nullable=True)
    video_1_skill = Column(String, nullable=True)  # Yetenek adı (örn: "Uzaktan Şut")
    video_1_slot = Column(Integer, default=1)
    video_1_rating = Column(Integer, nullable=True)  # 0-100 puan
    video_1_ai_analysis = Column(Text, nullable=True)  # AI analiz metni
    
    # Video 2: Slot 2  
    video_2_url = Column(String, nullable=True)
    video_2_skill = Column(String, nullable=True)
    video_2_slot = Column(Integer, default=2)
    video_2_rating = Column(Integer, nullable=True)
    video_2_ai_analysis = Column(Text, nullable=True)
    
    # Video 3: Slot 3
    video_3_url = Column(String, nullable=True)
    video_3_skill = Column(String, nullable=True)
    video_3_slot = Column(Integer, default=3)
    video_3_rating = Column(Integer, nullable=True)
    video_3_ai_analysis = Column(Text, nullable=True)
    
    # Detaylı Özellik Puanları (JSON formatında esneklik)
    skill_scores = Column(JSON, nullable=True, default=dict)
    # Örnek: {"long_shot": 85, "close_control": 78, "finishing": 92}
    
    # AI Raporları
    ai_summary_report = Column(Text, nullable=True)  # Genel AI değerlendirmesi
    ai_strengths = Column(JSON, nullable=True, default=list)  # Güçlü yönler listesi
    ai_improvements = Column(JSON, nullable=True, default=list)  # Geliştirilecek alanlar
    
    # İlişkiler
    owner = relationship("User", back_populates="multivideo_profiles")
    
    @property
    def completion_percentage(self):
        """Yükleme tamamlanma yüzdesi (3 videodan kaç tanesi var)"""
        uploaded = sum([
            1 if self.video_1_url else 0,
            1 if self.video_2_url else 0,
            1 if self.video_3_url else 0
        ])
        return (uploaded / 3) * 100
    
    @property
    def average_rating(self):
        """Yüklenen videoların ortalama puanı"""
        ratings = []
        if self.video_1_rating is not None:
            ratings.append(self.video_1_rating)
        if self.video_2_rating is not None:
            ratings.append(self.video_2_rating)
        if self.video_3_rating is not None:
            ratings.append(self.video_3_rating)
        
        if not ratings:
            return 0
        return sum(ratings) / len(ratings)
    
    @property
    def is_complete(self):
        """Tüm 3 video yüklenmiş mi?"""
        return all([
            self.video_1_url is not None,
            self.video_2_url is not None,
            self.video_3_url is not None
        ])
    
    def get_video_info(self, slot: int):
        """Slot numarasına göre video bilgisi döndürür"""
        if slot == 1:
            return {
                "url": self.video_1_url,
                "skill": self.video_1_skill,
                "rating": self.video_1_rating,
                "analysis": self.video_1_ai_analysis,
                "slot": 1,
                "is_uploaded": self.video_1_url is not None and len(self.video_1_url) > 0
            }
        elif slot == 2:
            return {
                "url": self.video_2_url,
                "skill": self.video_2_skill,
                "rating": self.video_2_rating,
                "analysis": self.video_2_ai_analysis,
                "slot": 2,
                "is_uploaded": self.video_2_url is not None and len(self.video_2_url) > 0
            }
        elif slot == 3:
            return {
                "url": self.video_3_url,
                "skill": self.video_3_skill,
                "rating": self.video_3_rating,
                "analysis": self.video_3_ai_analysis,
                "slot": 3,
                "is_uploaded": self.video_3_url is not None and len(self.video_3_url) > 0
            }
        return None
    
    def to_dict(self):
        """API yanıtı için dict formatında döndürür"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "name": self.name,
            "age": self.age,
            "position": self.position,
            "position_code": self.position_code,
            "overall_rating": self.overall_rating,
            "average_rating": self.average_rating,
            "completion_percentage": self.completion_percentage,
            "is_complete": self.is_complete,
            
            # Videolar (URL'si null olanlar dahil edilmez)
            "videos": [
                v for v in [
                    self.get_video_info(1),
                    self.get_video_info(2),
                    self.get_video_info(3)
                ] if v and v.get("url")
            ],
            
            # Detaylı puanlar
            "skill_scores": self.skill_scores or {},
            
            # AI Raporları
            "ai_summary_report": self.ai_summary_report,
            "ai_strengths": self.ai_strengths or [],
            "ai_improvements": self.ai_improvements or [],
            
            # AI Detaylı Skorlar (skill_scores JSON'undan açılım)
            "pace": (self.skill_scores or {}).get("pace"),
            "finishing": (self.skill_scores or {}).get("finishing"),
            "passing": (self.skill_scores or {}).get("passing"),
            "dribbling": (self.skill_scores or {}).get("dribbling"),
            "defending": (self.skill_scores or {}).get("defending"),
            "strength": (self.skill_scores or {}).get("strength"),
            "technical_ability": (self.skill_scores or {}).get("technical_ability"),
            "physical_attributes": (self.skill_scores or {}).get("physical_attributes"),
            "tactical_awareness": (self.skill_scores or {}).get("tactical_awareness"),
            "mental_attributes": (self.skill_scores or {}).get("mental_attributes"),
            
            # Tarihler
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

# User modeline ilişki ekle (database.py'de yapılacak)
# multivideo_profiles = relationship("PlayerMultiVideo", back_populates="owner")
