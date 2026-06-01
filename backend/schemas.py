from pydantic import BaseModel, EmailStr, Field, field_serializer
from typing import Optional, Any


# --- GÜVENLİK VE KULLANICI ŞEMALARI ---
class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    phone_number: Optional[str] = None
    password: str
    role: str
    birth_date: Optional[str] = None  # ISO format: "2000-05-15"
    age: Optional[int] = None
    referral_code: Optional[str] = None


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: Optional[str] = None


class UserResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    role: str
    phone_number: Optional[str] = None
    birth_date: Optional[Any] = None
    age: Optional[int] = None
    profile_image_url: Optional[str] = None
    scout_document_url: Optional[str] = None
    is_verified: Optional[bool] = True

    @field_serializer('birth_date')
    def serialize_birth_date(self, v: Any) -> Optional[str]:
        if v is None:
            return None
        if isinstance(v, str):
            return v
        return v.isoformat()

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone_number: Optional[str] = None
    profile_image_url: Optional[str] = None
    birth_date: Optional[str] = None


class Token(BaseModel):
    access_token: str
    token_type: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


# --- OYUNCU ŞEMALARI ---
class PlayerBase(BaseModel):
    name: Optional[str] = None  # Backend'den current_user'dan alınacak
    age: Optional[int] = None   # Backend'den current_user'dan alınacak
    position: str

    # Tüm özellikler opsiyoneldir, mevkiye göre sadece gerekenler dolacak
    finishing: Optional[int] = None
    pace: Optional[int] = None
    dribbling: Optional[int] = None
    positioning: Optional[int] = None
    vision: Optional[int] = None
    passing: Optional[int] = None
    ball_control: Optional[int] = None
    stamina: Optional[int] = None
    tackling: Optional[int] = None
    marking: Optional[int] = None
    strength: Optional[int] = None
    jumping: Optional[int] = None
    gk_reflexes: Optional[int] = None
    gk_diving: Optional[int] = None
    gk_handling: Optional[int] = None
    gk_positioning: Optional[int] = None
    gk_kicking: Optional[int] = None


class PlayerCreate(PlayerBase):
    """Frontend sadece position ve yetenekleri gönderir.
    name ve age backend'den current_user'dan otomatik alınır."""
    pass


class PlayerResponse(PlayerBase):
    id: int
    overall_rating: int
    user_id: Optional[int] = None
    ai_scout_report: Optional[str] = None

    class Config:
        from_attributes = True


class PlayerRatingCreate(BaseModel):
    pac: int = Field(..., ge=1, le=99)
    sho: int = Field(..., ge=1, le=99)
    pas: int = Field(..., ge=1, le=99)
    dri: int = Field(..., ge=1, le=99)
    def_: int = Field(..., alias="def", ge=1, le=99)
    phy: int = Field(..., ge=1, le=99)

    class Config:
        populate_by_name = True


class CommunityRatingSummary(BaseModel):
    PAC: Optional[int] = None
    SHO: Optional[int] = None
    PAS: Optional[int] = None
    DRI: Optional[int] = None
    DEF: Optional[int] = None
    PHY: Optional[int] = None
    OVR: Optional[int] = None
    rating_count: int = 0
    current_user_has_rated: bool = False


LoginResponse.model_rebuild()