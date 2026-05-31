"""Uvicorn giriş noktası — uygulama app_factory üzerinden oluşturulur."""
import uvicorn

from app_factory import app

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(__import__("os").getenv("PORT", "8000")),
        reload=__import__("os").getenv("ENVIRONMENT", "development") == "development",
    )
