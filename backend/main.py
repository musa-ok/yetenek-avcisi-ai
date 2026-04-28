from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from typing import List
import models, schemas, database

models.Base.metadata.create_all(bind=database.engine)
app = FastAPI(title="Yetenek Avcısı MVP")

@app.post("/players/", response_model=schemas.PlayerResponse)
def create_player(player: schemas.PlayerCreate, db: Session = Depends(database.get_db)):
    db_player = models.Player(**player.dict())
    db.add(db_player)
    db.commit()
    db.refresh(db_player)
    return db_player

@app.get("/players/", response_model=List[schemas.PlayerResponse])
def get_players(db: Session = Depends(database.get_db)):
    return db.query(models.Player).all()


from pydantic import BaseModel


# Scout'un arama yaparken göndereceği metin
class ScoutQuery(BaseModel):
    query_text: str


@app.post("/search_players/")
def search_players_by_ai(query: ScoutQuery, db: Session = Depends(database.get_db)):
    # BURA MVP SİMÜLASYONUDUR.
    # Gerçekte buradaki metin bir LLM API'sine (Gemini/OpenAI) gidip
    # bize JSON formatında SQL filtreleri olarak geri dönecek.

    search_term = query.query_text.lower()
    all_players = db.query(models.Player).all()

    matched_players = []
    for player in all_players:
        # Oyuncunun tüm özelliklerini yapay zekanın okuyabileceği bir "Context" (Bağlam) metnine çeviriyoruz.
        player_context = f"{player.age} yaşında {player.strong_foot} ayaklı {player.position}. Özet: {player.ai_summary}".lower()

        # Scout'un aradığı kelimeler bu bağlam metni içinde geçiyorsa eşleşme sayıyoruz.
        # (İleride bu satırı LangChain ve Vektör Veritabanı ile değiştireceğiz)
        if any(word in search_term.split() for word in player_context.split()):
            matched_players.append(player)

    return {
        "mesaj": f"'{query.query_text}' araması için yapay zeka analizli sonuçlar getirildi.",
        "sonuclar": matched_players
    }