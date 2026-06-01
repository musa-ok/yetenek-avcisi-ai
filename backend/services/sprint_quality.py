"""Koşu videosu kalite değerlendirmesi ve kullanıcıya iyileştirme ipuçları."""
from __future__ import annotations

from typing import Any

from services.sprint_cv import measure_sprint_seconds

# Sanal kapı çizgileri (kadraj genişliğinin oranı — koniler kadrajda olmalı)
GATE_START_RATIO = 0.18
GATE_END_RATIO = 0.82


def _user_rejection_reason(measured: dict[str, Any], distance_m: float) -> str:
    """Kullanıcıya gösterilecek red metni — süre/mesafe gibi teknik ölçüm yok."""
    msg = (measured.get("message") or "").lower()
    if "açılamadı" in msg or "çok kısa" in msg:
        return "Video okunamadı veya çok kısa. Lütfen yeniden çekin."
    if "belirgin koşu" in msg or "çizgi" in msg or "koni" in msg:
        return (
            "Başlangıç ve bitiş çizgisi (veya koni) net görünmüyor "
            "ya da koşu kadrajda seçilemiyor."
        )
    if "aralık" in msg or "beklenen" in msg:
        if distance_m >= 15:
            return (
                "20 metrelik koşunun tamamı tek videoda görünmüyor "
                "veya çekim kesilmiş olabilir."
            )
        return (
            "10 metrelik yokuş koşusu kadrajda net değil "
            "veya çekim kesilmiş olabilir."
        )
    return (
        "Hız testi videosu ölçülemiyor. Telefonu sabitleyin, yan çekim yapın "
        "ve başlangıç/bitiş çizgilerini kadraja alın."
    )


def assess_kosu_upload(
    video_path: str,
    *,
    distance_m: float,
    strict_block: bool = True,
) -> dict[str, Any]:
    """
    Yükleme öncesi önizleme. Düşük kalitede yükleme reddedilir (strict_block=True).
    """
    measured = measure_sprint_seconds(video_path, distance_m=distance_m)
    conf = float(measured.get("confidence") or 0.0)
    seconds = measured.get("seconds")
    method = measured.get("method") or "opencv_motion"
    msg = measured.get("message") or ""

    tips: list[str] = []
    quality = "good"

    if method == "unavailable":
        return {
            "quality": "unknown",
            "confidence": 0.0,
            "timing_preview_sec": None,
            "timing_estimated": True,
            "tips": ["Sunucuda video analizi modülü eksik; süre finalize'da ölçülecek."],
            "block_upload": False,
            "message": msg,
            "retake_recommended": False,
        }

    if seconds is None or conf < 0.38:
        quality = "poor"
        tips.extend([
            "Telefonu sabitle (tripod veya yere sabit).",
            "Yan çekim: başlangıç ve bitiş konileri/çizgisi kadrajda görünsün.",
            "Koşu başlamadan 1 sn önce ve bitişten 1 sn sonra kadrajı kesmeyin.",
            "20m testte tüm mesafe tek karede mümkün olduğunca görünsün.",
        ])
        if "hareket" in msg.lower() or "belirgin" in msg.lower():
            tips.append("Oyuncu küçük görünüyor — kamerayı 5–8 m yana alın, zoom kullanmayın.")
        if "aralık" in msg.lower():
            tips.append(
                "Muhtemelen tüm koşu mesafesi kadrajda değil veya video erken kesilmiş."
            )
    elif conf < 0.58:
        quality = "warn"
        tips.extend([
            "Video kabul edilebilir; daha iyi ölçüm için konileri netleştirin.",
            "Gün ışığı ve sabit kamera güveni artırır.",
        ])
    else:
        tips.append("Çekim koşulları ölçüm için uygun görünüyor.")

    out_of_range = "aralık" in msg.lower() or "beklenen" in msg.lower()
    block = strict_block and quality == "poor" and (seconds is None or out_of_range)
    user_message = _user_rejection_reason(measured, distance_m) if block else None

    return {
        "quality": quality,
        "confidence": conf,
        "timing_preview_sec": seconds,
        "timing_estimated": seconds is not None and method == "opencv_motion",
        "timing_method": measured.get("timing_method") or method,
        "tips": tips,
        "block_upload": block,
        "message": msg if block else "OK",
        "user_message": user_message,
        "retake_recommended": quality in ("poor", "warn"),
        "frames_analyzed": measured.get("frames_analyzed"),
        "horizontal_span_px": measured.get("horizontal_span_px"),
    }
