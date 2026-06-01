"""Scout raporu metni temizleme."""
from __future__ import annotations

_DISCLAIMER = (
    "Not: Koşu süreleri mümkünse video hareket analizi (OpenCV) ile ölçülür; "
    "ölçülemezse AI tahmini kullanılır. Teknik form puanı AI değerlendirmesidir."
)


def strip_analysis_disclaimer(text: str | None) -> str:
    """Rapor sonundaki teknik notu kaldırır (eski kayıtlar için)."""
    if not text:
        return ""
    s = text.strip()
    idx = s.find(_DISCLAIMER)
    if idx >= 0:
        s = s[:idx].rstrip()
    # Satır satır sonda kalan Not: satırları
    lines = s.splitlines()
    while lines and lines[-1].strip().startswith("Not: Koşu süreleri"):
        lines.pop()
    return "\n".join(lines).strip()
