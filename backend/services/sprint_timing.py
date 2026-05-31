"""Koşu süresi: OpenCV ölçümü + yaş normu + slot puanına birleştirme."""
from __future__ import annotations

from typing import Any

from services.sprint_cv import measure_sprint_seconds


def pace_score_from_sprint_time(
    seconds: float,
    distance_m: float = 20.0,
    age: int | None = None,
) -> int | None:
    """
    Mesafe ve süreye göre 1–100 pace alt skoru.
    Yaş için hafif tolerans (genç kategoriler).
    """
    if seconds <= 0 or distance_m <= 0:
        return None

    # m/s → referans eşikler (yaklaşık akademi testi)
    speed = distance_m / seconds
    age_factor = 1.0
    if age is not None:
        if age <= 14:
            age_factor = 0.92
        elif age <= 17:
            age_factor = 0.96

    if distance_m <= 12:
        elite, good, mid = 5.5 * age_factor, 4.2 * age_factor, 3.2 * age_factor
    else:
        elite, good, mid = 7.0 * age_factor, 5.5 * age_factor, 4.0 * age_factor

    if speed >= elite:
        return 94
    if speed >= good:
        return 82
    if speed >= mid:
        return 68
    if speed >= mid * 0.85:
        return 55
    return 42


def apply_sprint_timing_to_slot(
    result: dict[str, Any],
    video_path: str,
    *,
    distance_m: float,
    age: int | None = None,
) -> dict[str, Any]:
    """
    Önce OpenCV süre; başarısızsa Gemini timing_sec yedek.
    Koşu slot puanı: ölçülen süre ağırlıklı.
    """
    cv = measure_sprint_seconds(video_path, distance_m=distance_m)
    ai_score = int(result.get("score") or 50)

    sec = cv.get("seconds")
    conf = float(cv.get("confidence") or 0.0)

    if sec is not None and conf >= 0.4:
        pace_from_time = pace_score_from_sprint_time(float(sec), distance_m=distance_m, age=age)
        if pace_from_time is not None:
            result["timing_sec"] = sec
            result["timing_estimated"] = False
            result["timing_source"] = "opencv"
            result["timing_confidence"] = conf
            result["timing_method"] = cv.get("method")
            result["score"] = round(ai_score * 0.32 + pace_from_time * 0.68)
            obs = (result.get("observation") or "").strip()
            result["observation"] = (
                f"{obs} [Süre: {sec}s — video analizi, {distance_m:.0f}m]"
            ).strip()
            return result

    # Gemini yedek
    t = result.get("timing_sec")
    if t is not None:
        try:
            t = float(t)
            pace_from_time = pace_score_from_sprint_time(t, distance_m=distance_m, age=age)
            if pace_from_time is not None:
                result["timing_estimated"] = True
                result["timing_source"] = "gemini_estimate"
                result["timing_confidence"] = 0.35
                result["score"] = round(ai_score * 0.55 + pace_from_time * 0.45)
                return result
        except (TypeError, ValueError):
            pass

    result["timing_source"] = result.get("timing_source") or "none"
    if cv.get("message"):
        obs = (result.get("observation") or "").strip()
        hint = cv["message"]
        if "raw_seconds" in cv:
            hint += f" (ham: {cv['raw_seconds']}s)"
        result["observation"] = f"{obs} [Süre ölçülemedi: {hint}]".strip()
    return result


def merge_timing_into_slot_result(
    result: dict[str, Any],
    *,
    distance_m: float = 20.0,
    age: int | None = None,
    video_path: str | None = None,
) -> dict[str, Any]:
    """Geriye dönük: video_path verilirse tam pipeline."""
    if video_path:
        return apply_sprint_timing_to_slot(
            result, video_path, distance_m=distance_m, age=age
        )
    t = result.get("timing_sec")
    if t is None:
        return result
    try:
        t = float(t)
    except (TypeError, ValueError):
        return result
    pace_from_time = pace_score_from_sprint_time(t, distance_m=distance_m, age=age)
    if pace_from_time is None:
        return result
    ai_score = int(result.get("score") or 50)
    result["score"] = round(ai_score * 0.55 + pace_from_time * 0.45)
    result["timing_estimated"] = bool(result.get("timing_estimated", True))
    result["timing_source"] = result.get("timing_source") or "gemini_estimate"
    return result
