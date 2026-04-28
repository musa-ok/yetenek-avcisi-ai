from sqlalchemy import Column, Integer, String, Float
from database import Base

class Player(Base):
    __tablename__ = "players"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    age = Column(Integer)
    position = Column(String)
    strong_foot = Column(String)
    video_url = Column(String, default="Henüz yüklenmedi") # Scout'un izleyeceği link
    speed_score = Column(Float, default=0.0)
    passing_score = Column(Float, default=0.0)
    ai_summary = Column(String, default="Analiz bekleniyor...")