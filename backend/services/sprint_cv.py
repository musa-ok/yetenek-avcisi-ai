"""Koşu videosundan OpenCV ile süre tahmini (hareket + sanal kapı geçişi)."""
from __future__ import annotations

from typing import Any

# Mesafe (m) → [min_s, max_s] fiziksel sınırlar (m/s ~2–11)
_DURATION_BOUNDS: dict[float, tuple[float, float]] = {
    20.0: (1.8, 9.5),
    10.0: (1.0, 5.5),
}

GATE_START = 0.18
GATE_END = 0.82


def _bounds_for_distance(distance_m: float) -> tuple[float, float]:
    if distance_m in _DURATION_BOUNDS:
        return _DURATION_BOUNDS[distance_m]
    scale = distance_m / 10.0
    lo, hi = _DURATION_BOUNDS[10.0]
    return (lo * scale**0.5, hi * scale**0.5)


def _smooth(values: list[float], window: int = 5) -> list[float]:
    if not values:
        return []
    out = []
    for i in range(len(values)):
        lo = max(0, i - window)
        hi = min(len(values), i + window + 1)
        out.append(sum(values[lo:hi]) / (hi - lo))
    return out


def _extract_motion_series(video_path: str) -> dict[str, Any] | None:
    try:
        import cv2  # type: ignore
        import numpy as np  # type: ignore
    except ImportError:
        return None

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        return None

    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    if fps < 5:
        fps = 30.0
    frame_skip = max(1, int(round(fps / 15)))
    frame_w = 320

    motion: list[float] = []
    cx_norm: list[float] = []
    frame_count = 0
    bg_accum: list[Any] = []
    max_frames = 500

    while frame_count < max_frames:
        ret, frame = cap.read()
        if not ret:
            break
        if frame_count % frame_skip != 0:
            frame_count += 1
            continue

        small = cv2.resize(frame, (frame_w, 180))
        gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(gray, (5, 5), 0)

        if len(bg_accum) < 8:
            bg_accum.append(gray.astype(np.float32))
            motion.append(0.0)
            cx_norm.append(-1.0)
            frame_count += 1
            continue

        bg = np.median(np.stack(bg_accum[:8], axis=0), axis=0).astype(np.uint8)
        diff = cv2.absdiff(gray, bg)
        _, thresh = cv2.threshold(diff, 28, 255, cv2.THRESH_BINARY)
        thresh = cv2.dilate(thresh, np.ones((5, 5), np.uint8), iterations=2)

        contours, _ = cv2.findContours(
            thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )
        area_max = 0.0
        cx_val = -1.0
        for c in contours:
            a = cv2.contourArea(c)
            if a > area_max and a > 400:
                area_max = a
                m = cv2.moments(c)
                if m["m00"] > 0:
                    cx_val = (m["m10"] / m["m00"]) / frame_w

        motion.append(area_max)
        cx_norm.append(cx_val)
        frame_count += 1

    cap.release()
    if len(motion) < 12:
        return None

    return {
        "motion": motion,
        "cx_norm": cx_norm,
        "sample_dt": frame_skip / fps,
        "fps": fps,
        "n": len(motion),
    }


def _duration_motion_blob(series: dict[str, Any]) -> dict[str, Any] | None:
    motion = series["motion"]
    smooth = _smooth(motion)
    peak = max(smooth)
    if peak < 800:
        return None

    thresh_m = peak * 0.22
    active = [i for i, v in enumerate(smooth) if v >= thresh_m]
    if len(active) < 4:
        return None

    best_start, best_end, cur_start = active[0], active[0], active[0]
    for i in range(1, len(active)):
        if active[i] == active[i - 1] + 1:
            if active[i] - cur_start > best_end - best_start:
                best_start, best_end = cur_start, active[i]
        else:
            cur_start = active[i]
            if active[i] - cur_start > best_end - best_start:
                best_start, best_end = cur_start, active[i]
    if active[-1] - cur_start > best_end - best_start:
        best_start, best_end = cur_start, active[-1]

    dt = series["sample_dt"]
    duration = (best_end - best_start) * dt
    cx = series["cx_norm"]
    cx_active = [cx[i] for i in range(best_start, best_end + 1) if cx[i] >= 0]
    h_span = (max(cx_active) - min(cx_active)) if len(cx_active) >= 3 else 0.0

    return {
        "seconds": duration,
        "confidence": 0.5,
        "method": "motion_blob",
        "start_idx": best_start,
        "end_idx": best_end,
        "horizontal_span": h_span,
        "peak": peak,
    }


def _duration_gate_crossing(series: dict[str, Any]) -> dict[str, Any] | None:
    """
    Sanal kapılar: kadrajın %18 ve %82'si (baş/bitiş konileri buraya hizalanmalı).
    Oyuncu siluetinin yatay geçişi → foto-finish benzeri süre.
    """
    cx = series["cx_norm"]
    n = len(cx)
    filled = []
    last = 0.5
    for v in cx:
        if v >= 0:
            last = v
        filled.append(last)
    smooth = _smooth(filled, 3)

    valid = [v for v in smooth if v >= 0]
    if len(valid) < 8:
        return None

    span = max(smooth) - min(smooth)
    if span < 0.22:
        return None

    moving_right = smooth[-1] > smooth[0]
    start_idx = None
    end_idx = None

    for i in range(1, n):
        prev, cur = smooth[i - 1], smooth[i]
        if moving_right:
            if start_idx is None and prev < GATE_START <= cur:
                start_idx = i
            if prev < GATE_END <= cur:
                end_idx = i
        else:
            if start_idx is None and prev > GATE_START >= cur:
                start_idx = i
            if prev > GATE_END >= cur:
                end_idx = i

    if start_idx is None or end_idx is None or end_idx <= start_idx:
        return None

    dt = series["sample_dt"]
    duration = (end_idx - start_idx) * dt
    if duration <= 0.2:
        return None

    conf = 0.62
    if span >= 0.35:
        conf += 0.15
    if (end_idx - start_idx) >= 6:
        conf += 0.1

    return {
        "seconds": duration,
        "confidence": min(0.93, conf),
        "method": "gate_crossing",
        "start_idx": start_idx,
        "end_idx": end_idx,
        "horizontal_span": span,
    }


def measure_sprint_seconds(
    video_path: str,
    distance_m: float = 20.0,
) -> dict[str, Any]:
    base_fail = {
        "seconds": None,
        "confidence": 0.0,
        "method": "opencv_motion",
        "timing_method": "failed",
        "message": "Süre ölçülemedi.",
        "frames_analyzed": 0,
    }

    series = _extract_motion_series(video_path)
    if series is None:
        try:
            import cv2  # noqa: F401
        except ImportError:
            return {
                **base_fail,
                "method": "unavailable",
                "message": "OpenCV kurulu değil (opencv-python-headless).",
            }
        return {**base_fail, "message": "Video açılamadı veya çok kısa."}

    gate = _duration_gate_crossing(series)
    blob = _duration_motion_blob(series)
    pick = gate if gate else blob
    if gate and blob:
        pick = gate if gate["confidence"] >= blob["confidence"] else blob

    if not pick:
        return {
            **base_fail,
            "message": (
                "Belirgin koşu veya baş/bitiş çizgisi bulunamadı. "
                "Yan çekim + iki koni/çizgi kullanın."
            ),
            "frames_analyzed": series["n"],
        }

    duration = pick["seconds"]
    lo_b, hi_b = _bounds_for_distance(distance_m)
    in_range = lo_b <= duration <= hi_b

    confidence = pick["confidence"]
    if in_range:
        confidence = min(0.95, confidence + 0.12)
    else:
        confidence = min(confidence, 0.42)
        if duration < lo_b * 0.7 or duration > hi_b * 1.35:
            return {
                **base_fail,
                "message": (
                    f"Ölçülen süre ({duration:.2f}s) {distance_m:.0f}m için "
                    f"beklenen aralık dışında ({lo_b:.1f}–{hi_b:.1f}s)."
                ),
                "frames_analyzed": series["n"],
                "raw_seconds": round(duration, 3),
                "timing_method": pick["method"],
            }

    h_span_px = pick.get("horizontal_span", 0)
    if isinstance(h_span_px, float) and h_span_px <= 1.0:
        h_span_px = round(h_span_px * 320, 1)

    return {
        "seconds": round(duration, 2),
        "confidence": round(confidence, 2),
        "method": "opencv_motion",
        "timing_method": pick["method"],
        "message": "OK",
        "frames_analyzed": series["n"],
        "distance_m": distance_m,
        "horizontal_span_px": h_span_px,
    }
