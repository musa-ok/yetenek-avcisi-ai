from sqlalchemy import Column, Integer, String, Text, ForeignKey, Boolean, UniqueConstraint, DateTime, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base  # Bir önceki adımdaki veritabanı bağlantımız


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, index=True)
    phone_number = Column(String, nullable=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)  # Güvenlik: Şifreler kırılamaz şekilde tutulacak
    role = Column(String)  # 'Scout' veya 'Futbolcu'
    
    # Doğum tarihi ve yaş (yaş her yıl otomatik hesaplanır)
    birth_date = Column(DateTime(timezone=True), nullable=True)
    age = Column(Integer, nullable=True)
    
    # Profil fotoğrafı URL
    profile_image_url = Column(String, nullable=True)
    
    # Scout onay sistemi
    scout_document_url = Column(String, nullable=True)  # TFF lisansı / PFSA belgesi yolu

    # Sosyal medya giriş bilgileri
    provider = Column(String, nullable=True)  # 'apple', 'google', 'facebook'
    provider_id = Column(String, nullable=True)
    
    # Doğrulama ve profil durumları
    is_verified = Column(Boolean, default=False)  # OTP doğrulaması tamamlandı mı?
    is_profile_complete = Column(Boolean, default=False)  # Profil bilgileri tamamlandı mı?

    # OTP - Veritabanında saklanır (sunucu yeniden başlasa bile kaybolmaz)
    otp_code = Column(String, nullable=True)
    otp_expires_at = Column(DateTime, nullable=True)
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 🚨 YENİ EKLENEN KOTA KOLONLARI 🚨
    daily_analyses_count = Column(Integer, default=0)
    last_analysis_date = Column(DateTime(timezone=True), nullable=True)

    player_profile = relationship("Player", back_populates="owner", uselist=False)
    ratings_given = relationship("Rating", back_populates="reviewer")
    multivideo_profiles = relationship("PlayerMultiVideo", back_populates="owner")
    
    def calculate_age(self):
        """Doğum tarihinden yaşı hesaplar"""
        if self.birth_date is None:
            return self.age or 18
        from datetime import datetime
        today = datetime.now(self.birth_date.tzinfo) if self.birth_date.tzinfo else datetime.now()
        age = today.year - self.birth_date.year
        if (today.month, today.day) < (self.birth_date.month, self.birth_date.day):
            age -= 1
        return age


class Player(Base):
    __tablename__ = "players"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Genel Bilgiler
    name = Column(String, index=True)
    age = Column(Integer)
    position = Column(String, index=True)  # ST, CM, CB, GK
    overall_rating = Column(Integer, default=50)

    # Forvet Özellikleri
    pace = Column(Integer, nullable=True)
    finishing = Column(Integer, nullable=True)
    dribbling = Column(Integer, nullable=True)
    positioning = Column(Integer, nullable=True)
    dribbling_tight_spaces = Column(Integer, nullable=True)
    heading = Column(Integer, nullable=True)
    composure = Column(Integer, nullable=True)

    # Orta Saha Özellikleri
    vision = Column(Integer, nullable=True)
    passing = Column(Integer, nullable=True)
    ball_control = Column(Integer, nullable=True)
    stamina = Column(Integer, nullable=True)

    # Defans Özellikleri
    tackling = Column(Integer, nullable=True)
    marking = Column(Integer, nullable=True)
    strength = Column(Integer, nullable=True)
    jumping = Column(Integer, nullable=True)

    # Kaleci Özellikleri
    gk_reflexes = Column(Integer, nullable=True)
    gk_diving = Column(Integer, nullable=True)
    gk_handling = Column(Integer, nullable=True)
    gk_positioning = Column(Integer, nullable=True)
    gk_kicking = Column(Integer, nullable=True)
    gk_distribution = Column(Integer, nullable=True)
    gk_command_area = Column(Integer, nullable=True)
    gk_1v1 = Column(Integer, nullable=True)

    # Yapay Zeka (RAG) Analiz Raporu
    ai_scout_report = Column(Text, nullable=True)

    owner = relationship("User", back_populates="player_profile")
    community_ratings = relationship("Rating", back_populates="player")


class Rating(Base):
    __tablename__ = "ratings"
    __table_args__ = (
        UniqueConstraint("reviewer_id", "player_id", name="uq_rating_reviewer_player"),
    )

    id = Column(Integer, primary_key=True, index=True)
    reviewer_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    player_id = Column(Integer, ForeignKey("players.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # FIFA benzeri 6 ana metrik (1-99)
    pac = Column(Integer, nullable=False)
    sho = Column(Integer, nullable=False)
    pas = Column(Integer, nullable=False)
    dri = Column(Integer, nullable=False)
    def_ = Column("def", Integer, nullable=False)
    phy = Column(Integer, nullable=False)

    reviewer = relationship("User", back_populates="ratings_given")
    player = relationship("Player", back_populates="community_ratings")


# Eski referanslar bozulmasın diye alias bırakıyoruz.
PlayerRating = Rating


# ==========================================
# ÇOKLU VIDEO SİSTEMİ (MULTI-UPLOAD)
# ==========================================

from sqlalchemy import JSON, Float

# PlayerMultiVideo moved to models_multivideo.py to avoid conflicts


class MultiVideoRating(Base):
    """Scout'ların PlayerMultiVideo oyuncularına verdiği FIFA-tarzı puanlar."""
    __tablename__ = "multivideo_ratings"
    __table_args__ = (
        UniqueConstraint(
            "reviewer_id", "player_id", name="uq_mv_rating_reviewer_player"
        ),
    )

    id = Column(Integer, primary_key=True, index=True)
    reviewer_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    player_id = Column(
        Integer,
        ForeignKey("players_multivideo.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    pac = Column(Integer, nullable=False)
    sho = Column(Integer, nullable=False)
    pas = Column(Integer, nullable=False)
    dri = Column(Integer, nullable=False)
    def_ = Column("def", Integer, nullable=False)
    phy = Column(Integer, nullable=False)

    reviewer = relationship("User")
    player = relationship("PlayerMultiVideo", backref="community_ratings_mv")