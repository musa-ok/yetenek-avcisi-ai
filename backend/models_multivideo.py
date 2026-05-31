"""
Multi-Video Player Model
Her oyuncu için 3 ayrı yetenek videosu ve puanları
"""

from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import models
from position_skills_config import (
    get_kosu_slot_numbers,
    get_required_upload_count,
    position_has_kosu_slot,
)
from services import multivideo_slots as mvs


class PlayerMultiVideo(Base):
    """
    Çoklu video sistemi için oyuncu modeli
    Her mevki için 3 ayrı yetenek videosu
    """
    __tablename__ = "players_multivideo"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Temel Bilgiler
    name = Column(String, index=True)
    age = Column(Integer)
    position = Column(String, index=True)
    position_code = Column(String(10))
    overall_rating = Column(Integer, default=50)
    previous_overall_rating = Column(Integer, nullable=True)

    # Profil v2
    profile_image_url = Column(String, nullable=True)
    city = Column(String, nullable=True, index=True)
    club_name = Column(String, nullable=True)
    club_history = Column(Text, nullable=True)
    preferred_foot = Column(String(20), nullable=True)
    height_cm = Column(Integer, nullable=True)
    weight_kg = Column(Integer, nullable=True)
    
    # Video 1–3: koşu olmayan slotlar sırayla (bkz. multivideo_slots)
    video_1_url = Column(String, nullable=True)
    video_1_skill = Column(String, nullable=True)
    video_1_slot = Column(Integer, default=1)
    video_1_rating = Column(Integer, nullable=True)
    video_1_ai_analysis = Column(Text, nullable=True)
    
    video_2_url = Column(String, nullable=True)
    video_2_skill = Column(String, nullable=True)
    video_2_slot = Column(Integer, default=2)
    video_2_rating = Column(Integer, nullable=True)
    video_2_ai_analysis = Column(Text, nullable=True)
    
    video_3_url = Column(String, nullable=True)
    video_3_skill = Column(String, nullable=True)
    video_3_slot = Column(Integer, default=3)
    video_3_rating = Column(Integer, nullable=True)
    video_3_ai_analysis = Column(Text, nullable=True)

    # Hız slotları: {"1": {"flat_url", "uphill_url", "skill_name"}, ...}
    kosu_videos_by_slot = Column(JSON, nullable=True, default=dict)
    # Eski tek-slot kolonları (okuma uyumluluğu)
    kosu_slot = Column(Integer, nullable=True)
    kosu_skill_name = Column(String, nullable=True)
    kosu_video_flat_url = Column(String, nullable=True)
    kosu_video_uphill_url = Column(String, nullable=True)
    
    skill_scores = Column(JSON, nullable=True, default=dict)
    ai_summary_report = Column(Text, nullable=True)
    ai_strengths = Column(JSON, nullable=True, default=list)
    ai_improvements = Column(JSON, nullable=True, default=list)

    analysis_status = Column(String(20), nullable=True, index=True)
    analysis_error = Column(Text, nullable=True)
    
    owner = relationship("User", back_populates="multivideo_profiles")
    
    @property
    def completion_percentage(self):
        return mvs.completion_percentage(self)
    
    @property
    def average_rating(self):
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
        return mvs.player_is_complete(self)
    
    def get_video_info(self, slot: int):
        return mvs.get_slot_video_info(self, slot)
    
    def to_dict(self):
        video_entries = [self.get_video_info(s) for s in (1, 2, 3)]
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
            "required_video_count": get_required_upload_count(self.position or ""),
            "kosu_slots": get_kosu_slot_numbers(self.position or ""),
            "kosu_videos_by_slot": mvs._kosu_map(self),
            "uses_sprint_protocol": position_has_kosu_slot(self.position or ""),
            "videos": video_entries,
            "skill_scores": self.skill_scores or {},
            "slot_breakdown": (self.skill_scores or {}).get("slot_breakdown") or [],
            "analysis_version": (self.skill_scores or {}).get("analysis_version"),
            "ai_summary_report": self.ai_summary_report,
            "ai_strengths": self.ai_strengths or [],
            "ai_improvements": self.ai_improvements or [],
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
            "analysis_status": self.analysis_status,
            "analysis_error": self.analysis_error,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
