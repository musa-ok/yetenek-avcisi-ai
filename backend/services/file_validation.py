"""Yükleme dosyası: boyut, MIME ve magic-byte doğrulama."""
from __future__ import annotations

from fastapi import HTTPException

SCOUT_DOC_MAX_BYTES = 10 * 1024 * 1024  # 10 MB
VIDEO_MAX_BYTES = 200 * 1024 * 1024  # 200 MB

_MAGIC = {
    "jpeg": [bytes([0xFF, 0xD8, 0xFF])],
    "png": [bytes([0x89, 0x50, 0x4E, 0x47])],
    "pdf": [bytes([0x25, 0x50, 0x44, 0x46])],
    "webp": [bytes([0x52, 0x49, 0x46, 0x46])],
}


def _starts_with(data: bytes, sig: bytes) -> bool:
    return len(data) >= len(sig) and data[: len(sig)] == sig


def detect_kind(data: bytes) -> str | None:
    if not data:
        return None
    for kind, sigs in _MAGIC.items():
        for sig in sigs:
            if _starts_with(data, sig):
                return kind
    return None


def validate_scout_document(
    *,
    filename: str,
    content_type: str | None,
    data: bytes,
) -> str:
    """Scout belgesi — whitelist + magic bytes. Dönüş: uzantı."""
    if len(data) > SCOUT_DOC_MAX_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"Belge en fazla {SCOUT_DOC_MAX_BYTES // (1024*1024)} MB olabilir.",
        )
    ext = (filename or "").rsplit(".", 1)[-1].lower() if "." in (filename or "") else ""
    allowed_ext = {"jpg", "jpeg", "png", "webp", "pdf"}
    allowed_mime = {
        "image/jpeg",
        "image/png",
        "image/jpg",
        "image/webp",
        "application/pdf",
    }
    if ext not in allowed_ext and (content_type or "") not in allowed_mime:
        raise HTTPException(
            status_code=400,
            detail="Sadece JPG, PNG, WEBP veya PDF yükleyebilirsiniz.",
        )

    kind = detect_kind(data)
    if kind is None:
        raise HTTPException(
            status_code=400,
            detail="Dosya içeriği tanınamadı. Geçerli bir görsel veya PDF yükleyin.",
        )
    if ext == "pdf" and kind != "pdf":
        raise HTTPException(status_code=400, detail="PDF dosyası bozuk veya sahte uzantılı.")
    if ext in ("jpg", "jpeg", "png", "webp") and kind not in ("jpeg", "png", "webp"):
        raise HTTPException(status_code=400, detail="Görsel dosyası doğrulanamadı.")

    return ext or kind
