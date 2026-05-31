"""FastAPI uygulama fabrikası — middleware, router kayıtları, DB init."""
import os

from dotenv import load_dotenv

load_dotenv()

from config import AUTO_CREATE_TABLES, SENTRY_DSN, validate_settings

validate_settings()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

import models
import models_multivideo
import models_product
from database import engine
from services.schema_patches import ensure_schema_patches
from routers.api_routes import router as api_router
from routers.auth import router as auth_v2_router
from routers.product_features import router as product_router
from upload_rate_limit_middleware import UploadRateLimitMiddleware

if SENTRY_DSN:
    try:
        import sentry_sdk
        from sentry_sdk.integrations.fastapi import FastApiIntegration

        sentry_sdk.init(dsn=SENTRY_DSN, integrations=[FastApiIntegration()], traces_sample_rate=0.1)
    except ImportError:
        print("[SENTRY] sentry-sdk yüklü değil, atlanıyor.")


def create_app() -> FastAPI:
    if AUTO_CREATE_TABLES:
        models.Base.metadata.create_all(bind=engine)
        models_multivideo.Base.metadata.create_all(bind=engine)
        models_product.Base.metadata.create_all(bind=engine)
        ensure_schema_patches()

    app = FastAPI(
        title="Yetenek Avcısı API",
        description="Futbolcu yetenek analiz ve scout platformu için REST API",
        version="2.1.0",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        contact={
            "name": "Yetenek Avcısı Team",
            "email": "info@yetenekavcisi.com",
        },
        license_info={
            "name": "MIT License",
            "url": "https://opensource.org/licenses/MIT",
        },
    )

    if not os.path.exists("static"):
        os.makedirs("static")
    app.mount("/static", StaticFiles(directory="static"), name="static")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=os.getenv("CORS_ORIGINS", "*").split(","),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_middleware(UploadRateLimitMiddleware)

    # v1 + geriye uyumlu kök prefix
    app.include_router(auth_v2_router, prefix="/auth")
    app.include_router(auth_v2_router, prefix="/api/v1/auth")
    app.include_router(api_router)
    app.include_router(api_router, prefix="/api/v1")
    app.include_router(product_router)
    app.include_router(product_router, prefix="/api/v1")

    return app


app = create_app()
