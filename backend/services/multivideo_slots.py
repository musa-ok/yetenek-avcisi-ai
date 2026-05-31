"""Multivideo slot ↔ DB (Hız slotları 2'şer video: düz + yokuş)."""
from __future__ import annotations

from typing import Any

from sqlalchemy.orm.attributes import flag_modified

import models_multivideo
from position_skills_config import (
    KOSU_FLAT_LABEL,
    KOSU_UPHILL_LABEL,
    get_skills_for_position,
    is_kosu_slot_for,
    video_column_index_for_slot,
)


def _kosu_map(player: models_multivideo.PlayerMultiVideo) -> dict[str, Any]:
    data = player.kosu_videos_by_slot
    if isinstance(data, dict) and data:
        return dict(data)
    # Eski tek kolon → JSON
    if player.kosu_slot and (
        player.kosu_video_flat_url or player.kosu_video_uphill_url
    ):
        return {
            str(player.kosu_slot): {
                "skill_name": player.kosu_skill_name,
                "flat_url": player.kosu_video_flat_url,
                "uphill_url": player.kosu_video_uphill_url,
            }
        }
    return {}


def _kosu_entry(player: models_multivideo.PlayerMultiVideo, slot: int) -> dict[str, Any]:
    return dict(_kosu_map(player).get(str(slot), {}))


def kosu_slot_upload_complete(player: models_multivideo.PlayerMultiVideo, slot: int) -> bool:
    e = _kosu_entry(player, slot)
    return bool(e.get("flat_url") and e.get("uphill_url"))


def set_kosu_video(
    player: models_multivideo.PlayerMultiVideo,
    slot: int,
    *,
    phase: str,
    url: str,
    skill_name: str,
) -> None:
    data = _kosu_map(player)
    key = str(slot)
    entry = dict(data.get(key, {}))
    entry["skill_name"] = skill_name
    if phase == "flat":
        entry["flat_url"] = url
    else:
        entry["uphill_url"] = url
    data[key] = entry
    player.kosu_videos_by_slot = data
    flag_modified(player, "kosu_videos_by_slot")


def url_for_logical_slot(player: models_multivideo.PlayerMultiVideo, slot: int) -> str | None:
    if is_kosu_slot_for(player.position or "", slot):
        return None
    col = video_column_index_for_slot(player.position or "", slot)
    if col == 1:
        return player.video_1_url
    if col == 2:
        return player.video_2_url
    if col == 3:
        return player.video_3_url
    return None


def set_url_for_logical_slot(
    player: models_multivideo.PlayerMultiVideo,
    slot: int,
    url: str,
    skill_name: str,
) -> None:
    col = video_column_index_for_slot(player.position or "", slot)
    if col is None:
        raise ValueError(f"Slot {slot} çift video (koşu) slotu; tek video endpoint kullanılamaz.")
    if col == 1:
        player.video_1_url = url
        player.video_1_skill = skill_name
    elif col == 2:
        player.video_2_url = url
        player.video_2_skill = skill_name
    else:
        player.video_3_url = url
        player.video_3_skill = skill_name


def slot_is_uploaded(player: models_multivideo.PlayerMultiVideo, slot: int) -> bool:
    if is_kosu_slot_for(player.position or "", slot):
        return kosu_slot_upload_complete(player, slot)
    u = url_for_logical_slot(player, slot)
    return bool(u and len(u) > 0)


def count_uploaded(player: models_multivideo.PlayerMultiVideo) -> int:
    n = 0
    for s in get_skills_for_position(player.position or ""):
        if s.get("is_kosu_slot"):
            e = _kosu_entry(player, s["slot"])
            if e.get("flat_url"):
                n += 1
            if e.get("uphill_url"):
                n += 1
        elif slot_is_uploaded(player, s["slot"]):
            n += 1
    return n


def player_is_complete(player: models_multivideo.PlayerMultiVideo) -> bool:
    for s in get_skills_for_position(player.position or ""):
        if not slot_is_uploaded(player, s["slot"]):
            return False
    return True


def completion_percentage(player: models_multivideo.PlayerMultiVideo) -> float:
    from position_skills_config import get_required_upload_count

    required = get_required_upload_count(player.position or "")
    if required <= 0:
        return 0.0
    return (count_uploaded(player) / required) * 100.0


def get_slot_video_info(player: models_multivideo.PlayerMultiVideo, slot: int) -> dict[str, Any]:
    pos = player.position or ""
    if is_kosu_slot_for(pos, slot):
        e = _kosu_entry(player, slot)
        flat = e.get("flat_url")
        uphill = e.get("uphill_url")
        done = kosu_slot_upload_complete(player, slot)
        return {
            "slot": slot,
            "skill": e.get("skill_name") or "Koşu",
            "is_kosu_slot": True,
            "kosu_flat_url": flat,
            "kosu_uphill_url": uphill,
            "kosu_flat_uploaded": bool(flat),
            "kosu_uphill_uploaded": bool(uphill),
            "flat_rating": e.get("flat_rating"),
            "uphill_rating": e.get("uphill_rating"),
            "flat_timing_sec": e.get("flat_timing_sec"),
            "uphill_timing_sec": e.get("uphill_timing_sec"),
            "flat_timing_source": e.get("flat_timing_source"),
            "uphill_timing_source": e.get("uphill_timing_source"),
            "url": flat,
            "is_uploaded": done,
        }
    col = video_column_index_for_slot(pos, slot)
    url = skill = rating = analysis = None
    if col == 1:
        url, skill = player.video_1_url, player.video_1_skill
        rating, analysis = player.video_1_rating, player.video_1_ai_analysis
    elif col == 2:
        url, skill = player.video_2_url, player.video_2_skill
        rating, analysis = player.video_2_rating, player.video_2_ai_analysis
    elif col == 3:
        url, skill = player.video_3_url, player.video_3_skill
        rating, analysis = player.video_3_rating, player.video_3_ai_analysis
    return {
        "slot": slot,
        "skill": skill,
        "rating": rating,
        "analysis": analysis,
        "url": url,
        "is_kosu_slot": False,
        "is_uploaded": bool(url and len(url) > 0),
    }


def ordered_video_paths_and_skills(
    player: models_multivideo.PlayerMultiVideo,
) -> tuple[list[str], list[str]]:
    items = ordered_analysis_items(player)
    return [i["url"] for i in items], [i["label"] for i in items]


def ordered_analysis_items(
    player: models_multivideo.PlayerMultiVideo,
) -> list[dict[str, Any]]:
    """Finalize için sıralı analiz birimleri (URL + metadata)."""
    items: list[dict[str, Any]] = []
    for s in get_skills_for_position(player.position or ""):
        slot = int(s["slot"])
        name = s.get("name") or ""
        if s.get("is_kosu_slot"):
            e = _kosu_entry(player, slot)
            if e.get("flat_url"):
                items.append(
                    {
                        "url": e["flat_url"],
                        "label": f"{name} — {KOSU_FLAT_LABEL}",
                        "skill": name,
                        "slot": slot,
                        "phase": "flat",
                        "is_kosu": True,
                    }
                )
            if e.get("uphill_url"):
                items.append(
                    {
                        "url": e["uphill_url"],
                        "label": f"{name} — {KOSU_UPHILL_LABEL}",
                        "skill": name,
                        "slot": slot,
                        "phase": "uphill",
                        "is_kosu": True,
                    }
                )
        else:
            u = url_for_logical_slot(player, slot)
            if u:
                items.append(
                    {
                        "url": u,
                        "label": name,
                        "skill": name,
                        "slot": slot,
                        "phase": None,
                        "is_kosu": False,
                    }
                )
    return items


def apply_slot_analysis_result(
    player: models_multivideo.PlayerMultiVideo,
    *,
    slot: int,
    phase: str | None,
    is_kosu: bool,
    score: int,
    analysis_text: str,
    timing_sec: float | None = None,
    timing_source: str | None = None,
    timing_estimated: bool | None = None,
) -> None:
    """Slot analiz puanını DB alanlarına yazar."""
    if is_kosu:
        data = _kosu_map(player)
        key = str(slot)
        entry = dict(data.get(key, {}))
        if phase == "flat":
            entry["flat_rating"] = score
            entry["flat_analysis"] = analysis_text
            if timing_sec is not None:
                entry["flat_timing_sec"] = timing_sec
            if timing_source:
                entry["flat_timing_source"] = timing_source
            if timing_estimated is not None:
                entry["flat_timing_estimated"] = timing_estimated
        elif phase == "uphill":
            entry["uphill_rating"] = score
            entry["uphill_analysis"] = analysis_text
            if timing_sec is not None:
                entry["uphill_timing_sec"] = timing_sec
            if timing_source:
                entry["uphill_timing_source"] = timing_source
            if timing_estimated is not None:
                entry["uphill_timing_estimated"] = timing_estimated
        data[key] = entry
        player.kosu_videos_by_slot = data
        flag_modified(player, "kosu_videos_by_slot")
        return

    col = video_column_index_for_slot(player.position or "", slot)
    if col == 1:
        player.video_1_rating = score
        player.video_1_ai_analysis = analysis_text
    elif col == 2:
        player.video_2_rating = score
        player.video_2_ai_analysis = analysis_text
    elif col == 3:
        player.video_3_rating = score
        player.video_3_ai_analysis = analysis_text
