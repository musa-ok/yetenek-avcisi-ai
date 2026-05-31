"""Upload endpoint'leri için sıkı rate limit."""
from __future__ import annotations

import time

from fastapi import HTTPException, Request, Response
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint

from rate_limiter import rate_limiter

_UPLOAD_FRAGMENTS = (
    "/upload-video",
    "/upload-document",
    "/me/upload-photo",
    "/upload-slot-",
    "/upload-slot/",
    "/kosu",
)

_MAX = 10
_WINDOW = 300  # 5 dk


def _is_upload_path(path: str) -> bool:
    p = path.lower()
    if "/players/multivideo/" in p and ("upload" in p or "/kosu" in p):
        return True
    return any(f in p for f in _UPLOAD_FRAGMENTS)


class UploadRateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        if request.method not in ("POST", "PUT", "PATCH") or not _is_upload_path(
            request.url.path
        ):
            return await call_next(request)

        client = request.client.host if request.client else "unknown"
        auth = request.headers.get("authorization", "")
        key = f"upload:{auth[-24:] if auth else client}:{request.url.path}"

        if not rate_limiter.is_allowed(key, _MAX, _WINDOW):
            reset = rate_limiter.get_reset_time(key, _WINDOW) or int(time.time()) + _WINDOW
            raise HTTPException(
                status_code=429,
                detail="Çok fazla yükleme denemesi. Lütfen birkaç dakika sonra tekrar deneyin.",
                headers={"Retry-After": str(max(1, reset - int(time.time())))},
            )

        response = await call_next(request)
        remaining = rate_limiter.get_remaining_requests(key, _MAX, _WINDOW)
        response.headers["X-RateLimit-Limit"] = str(_MAX)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        return response
