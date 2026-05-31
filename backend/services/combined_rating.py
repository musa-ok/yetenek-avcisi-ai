"""Scout topluluk puanı + AI OVR birleşimi (6. adım)."""
from __future__ import annotations

from typing import Any


def build_combined_rating(ai_ovr: int, community: dict[str, Any]) -> dict[str, Any]:
    """
    Scout sayısına göre ağırlıklı birleşik OVR.

    - scout_count == 0 → yalnızca AI
    - scout_count 1–2 → %70 AI + %30 topluluk
    - scout_count ≥ 3 → %45 AI + %55 topluluk
    """
    ai = max(0, min(100, int(ai_ovr or 0)))
    count = int(community.get("rating_count") or 0)
    raw_comm = community.get("OVR")
    comm: int | None = int(raw_comm) if raw_comm is not None else None

    if count <= 0 or comm is None:
        display = ai if ai > 0 else None
        return {
            "display_ovr": display,
            "combined_ovr": display,
            "ai_ovr": ai if ai > 0 else None,
            "community_ovr": None,
            "scout_count": 0,
            "weights": {"ai": 1.0, "community": 0.0},
            "label": "ai_only",
        }

    comm = max(1, min(100, comm))
    if count >= 3:
        w_ai, w_comm = 0.45, 0.55
        label = "balanced"
    else:
        w_ai, w_comm = 0.70, 0.30
        label = "ai_heavy"

    if ai > 0:
        combined = round(ai * w_ai + comm * w_comm)
    else:
        combined = comm
    combined = max(1, min(100, combined))

    return {
        "display_ovr": combined,
        "combined_ovr": combined,
        "ai_ovr": ai if ai > 0 else None,
        "community_ovr": comm,
        "scout_count": count,
        "weights": {"ai": w_ai, "community": w_comm},
        "label": label,
    }


def apply_combined_to_player_payload(
    payload: dict[str, Any],
    *,
    ai_ovr: int,
    community: dict[str, Any],
) -> dict[str, Any]:
    """DTO'ya birleşik skor alanlarını ekler; overall_rating = görünür skor."""
    combined = build_combined_rating(ai_ovr, community)
    display = combined.get("display_ovr")
    if display is None:
        display = ai_ovr or 0

    payload["overall_rating"] = display
    payload["ai_ovr"] = combined.get("ai_ovr") if combined.get("ai_ovr") is not None else (ai_ovr or 0)
    payload["combined_ovr"] = combined.get("combined_ovr")
    payload["community_ovr"] = combined.get("community_ovr")
    payload["combined_rating"] = combined
    payload["rating_sources"] = combined
    payload["community_rating"] = community
    return payload
