from pydantic import BaseModel

class PlayerCreate(BaseModel):
    name: str
    age: int
    position: str
    strong_foot: str
    video_url: str # Video linki buraya gelecek

class PlayerResponse(PlayerCreate):
    id: int
    speed_score: float
    passing_score: float
    ai_summary: str

    class Config:
        from_attributes = True