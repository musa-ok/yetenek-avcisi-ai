from typing import Any, Literal, Optional

from pydantic import BaseModel, Field


class PlayerProfileV2Update(BaseModel):
    profile_image_url: Optional[str] = None
    city: Optional[str] = None
    club_name: Optional[str] = None
    club_history: Optional[str] = None
    preferred_foot: Optional[str] = None
    height_cm: Optional[int] = Field(None, ge=100, le=230)
    weight_kg: Optional[int] = Field(None, ge=40, le=150)


class ScoutNoteCreate(BaseModel):
    body: str = Field(..., min_length=1, max_length=8000)
    visibility: Literal["private", "public"] = "private"
    player_source: str = Field(default="multivideo")


class ScoutNoteUpdate(BaseModel):
    body: Optional[str] = Field(None, min_length=1, max_length=8000)
    visibility: Optional[Literal["private", "public"]] = None


class ScoutNoteResponse(BaseModel):
    id: int
    scout_id: int
    scout_name: Optional[str] = None
    player_id: int
    player_source: str
    body: str
    visibility: str
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    is_mine: bool = False

    class Config:
        from_attributes = True


class ShortlistCreate(BaseModel):
    title: str = Field(default="Favorilerim", max_length=120)


class ShortlistItemAdd(BaseModel):
    player_id: int
    player_source: str = "multivideo"


class ShortlistItemResponse(BaseModel):
    player_id: int
    player_source: str
    player: Optional[dict[str, Any]] = None


class ShortlistResponse(BaseModel):
    id: int
    title: str
    share_token: str
    share_url: Optional[str] = None
    items: list[ShortlistItemResponse] = []
    item_count: int = 0


class NotificationResponse(BaseModel):
    id: int
    kind: str
    title: str
    body: Optional[str] = None
    payload: Optional[dict[str, Any]] = None
    read: bool = False
    created_at: Optional[str] = None


class FcmTokenRegister(BaseModel):
    """Boş token = cihaz kaydını sil (bildirimler kapalı)."""
    device_token: str = Field(default="")


class ComparePlayerSide(BaseModel):
    id: int
    name: str
    position: str
    age: int
    overall_rating: int
    community_rating: dict[str, Optional[int]]
    profile: dict[str, Any]
    skills: dict[str, Optional[int]]


class PlayerCompareResponse(BaseModel):
    player_a: ComparePlayerSide
    player_b: ComparePlayerSide
