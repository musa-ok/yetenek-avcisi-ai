"""Ürün özellikleri: scout notu, shortlist, bildirim."""
import secrets

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from database import Base


def _share_token() -> str:
    return secrets.token_urlsafe(12)


class ScoutNote(Base):
    __tablename__ = "scout_notes"

    id = Column(Integer, primary_key=True, index=True)
    scout_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    player_id = Column(Integer, nullable=False, index=True)
    player_source = Column(String(20), nullable=False, default="multivideo")  # multivideo | legacy
    body = Column(Text, nullable=False)
    visibility = Column(String(20), nullable=False, default="private")  # private | public
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    scout = relationship("User", foreign_keys=[scout_id])


class Shortlist(Base):
    __tablename__ = "shortlists"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(120), nullable=False, default="Favorilerim")
    share_token = Column(String(32), unique=True, nullable=False, default=_share_token, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    owner = relationship("User", foreign_keys=[owner_id])
    items = relationship("ShortlistItem", back_populates="shortlist", cascade="all, delete-orphan")


class ShortlistItem(Base):
    __tablename__ = "shortlist_items"
    __table_args__ = (
        UniqueConstraint("shortlist_id", "player_id", "player_source", name="uq_shortlist_player"),
    )

    id = Column(Integer, primary_key=True, index=True)
    shortlist_id = Column(Integer, ForeignKey("shortlists.id", ondelete="CASCADE"), nullable=False, index=True)
    player_id = Column(Integer, nullable=False, index=True)
    player_source = Column(String(20), nullable=False, default="multivideo")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    shortlist = relationship("Shortlist", back_populates="items")


class AppNotification(Base):
    __tablename__ = "app_notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    kind = Column(String(40), nullable=False)  # rating | analysis_done | scout_approved | shortlist
    title = Column(String(200), nullable=False)
    body = Column(Text, nullable=True)
    payload_json = Column(Text, nullable=True)
    read_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", foreign_keys=[user_id])
