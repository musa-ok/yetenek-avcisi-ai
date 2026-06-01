"""Slot sonuçlarını attribute skorlarına ve OVR'ye dönüştürür."""
from __future__ import annotations

from typing import Any

from position_skills_config import KOSU_FLAT_LABEL, KOSU_UPHILL_LABEL, get_attributes_for_position

# FIFA benzeri alanlar
ATTR_KEYS = [
    "pace",
    "finishing",
    "passing",
    "dribbling",
    "defending",
    "strength",
    "technical_ability",
    "physical_attributes",
    "tactical_awareness",
    "mental_attributes",
]

# Mevki → OVR ağırlıkları (toplam ~1.0)
POSITION_OVR_WEIGHTS: dict[str, dict[str, float]] = {
    "Kaleci": {
        "technical_ability": 0.25,
        "tactical_awareness": 0.2,
        "mental_attributes": 0.2,
        "physical_attributes": 0.2,
        "defending": 0.15,
    },
    "Stoper": {
        "defending": 0.35,
        "strength": 0.25,
        "pace": 0.15,
        "tactical_awareness": 0.15,
        "passing": 0.1,
    },
    "Defans": {
        "defending": 0.35,
        "strength": 0.25,
        "pace": 0.15,
        "tactical_awareness": 0.15,
        "passing": 0.1,
    },
    "Bek": {
        "pace": 0.25,
        "defending": 0.25,
        "passing": 0.2,
        "dribbling": 0.15,
        "strength": 0.15,
    },
    "CDM/CM": {
        "passing": 0.3,
        "tactical_awareness": 0.25,
        "defending": 0.2,
        "physical_attributes": 0.15,
        "pace": 0.1,
    },
    "Orta Saha": {
        "passing": 0.3,
        "tactical_awareness": 0.25,
        "defending": 0.2,
        "physical_attributes": 0.15,
        "pace": 0.1,
    },
    "On Numara": {
        "passing": 0.25,
        "dribbling": 0.25,
        "finishing": 0.2,
        "technical_ability": 0.15,
        "pace": 0.15,
    },
    "Kanat": {
        "pace": 0.3,
        "dribbling": 0.25,
        "passing": 0.2,
        "finishing": 0.15,
        "physical_attributes": 0.1,
    },
    "Forvet": {
        "finishing": 0.35,
        "dribbling": 0.25,
        "pace": 0.2,
        "strength": 0.1,
        "passing": 0.1,
    },
}

# Skill adı / etiket → attribute
_LABEL_TO_ATTR: list[tuple[str, str]] = [
    (KOSU_FLAT_LABEL.lower(), "pace"),
    (KOSU_UPHILL_LABEL.lower(), "physical_attributes"),
    ("20 metre", "pace"),
    ("10 metre", "physical_attributes"),
    ("hız", "pace"),
    ("bitiricilik", "finishing"),
    ("uzaktan", "finishing"),
    ("şut", "finishing"),
    ("pas", "passing"),
    ("pas aralığı", "passing"),
    ("orta", "passing"),
    ("dripling", "dribbling"),
    ("dar alanda", "dribbling"),
    ("1'e 1", "dribbling"),
    ("markaj", "defending"),
    ("defansif", "defending"),
    ("top kapma", "defending"),
    ("hava top", "defending"),
    ("fiziksel", "strength"),
    ("refleks", "technical_ability"),
    ("top tutma", "technical_ability"),
    ("kaleci", "technical_ability"),
    ("oyun görüşü", "tactical_awareness"),
    ("yaratıcılık", "tactical_awareness"),
    ("soğukkanlılık", "mental_attributes"),
    ("pozisyon", "tactical_awareness"),
]


def attribute_for_label(skill_label: str) -> str:
    low = (skill_label or "").lower()
    for needle, attr in _LABEL_TO_ATTR:
        if needle in low:
            return attr
    attrs = get_attributes_for_position(skill_label.split("—")[0].strip())
    if attrs:
        mapping = {
            "pace": "pace",
            "finishing": "finishing",
            "passing": "passing",
            "dribbling": "dribbling",
            "crossing": "passing",
            "heading": "defending",
            "marking": "defending",
            "tackling": "defending",
            "strength": "strength",
            "reflexes": "technical_ability",
            "handling": "technical_ability",
            "positioning": "tactical_awareness",
            "distribution": "passing",
            "creativity": "tactical_awareness",
            "shooting": "finishing",
            "acceleration": "pace",
            "work_rate": "physical_attributes",
            "stamina": "physical_attributes",
            "defensive_awareness": "defending",
        }
        return mapping.get(attrs[0], "technical_ability")
    return "technical_ability"


def aggregate_slot_results(slot_results: list[dict[str, Any]]) -> dict[str, Any]:
    """Slot listesinden skill_scores + slot_breakdown üretir."""
    by_attr: dict[str, list[int]] = {k: [] for k in ATTR_KEYS}
    breakdown: list[dict[str, Any]] = []

    for row in slot_results:
        score = int(row.get("score") or 40)
        score = max(1, min(100, score))
        label = row.get("label") or row.get("skill") or ""
        attr = row.get("attribute") or attribute_for_label(label)
        if attr not in by_attr:
            by_attr[attr] = []
        by_attr[attr].append(score)
        breakdown.append(
            {
                "slot": row.get("slot"),
                "skill": row.get("skill"),
                "label": label,
                "score": score,
                "attribute": attr,
                "confidence": row.get("confidence"),
                "observation": row.get("observation"),
                "timing_sec": row.get("timing_sec"),
                "timing_estimated": row.get("timing_estimated", False),
                "timing_source": row.get("timing_source"),
                "timing_confidence": row.get("timing_confidence"),
                "phase": row.get("phase"),
            }
        )

    skill_scores: dict[str, Any] = {}
    for attr, scores in by_attr.items():
        if scores:
            skill_scores[attr] = round(sum(scores) / len(scores))

    skill_scores["slot_breakdown"] = breakdown
    skill_scores["analysis_version"] = "slot_v1"
    return skill_scores


def merge_breakdown_lists(
    existing: list[dict[str, Any]] | None,
    new_rows: list[dict[str, Any]] | None,
    *,
    session_position: str | None = None,
) -> list[dict[str, Any]]:
    """Önceki analiz testleri + yeni oturum; aynı FIFA alanı birden fazla kez ölçüldüyse sonra ortalanır."""
    merged: list[dict[str, Any]] = []
    for row in existing or []:
        if isinstance(row, dict):
            merged.append(dict(row))
    for row in new_rows or []:
        if not isinstance(row, dict):
            continue
        copy = dict(row)
        if session_position and not copy.get("session_position"):
            copy["session_position"] = session_position
        merged.append(copy)
    return merged


def skill_scores_from_breakdown(breakdown: list[dict[str, Any]]) -> dict[str, Any]:
    """Birleşik slot_breakdown → attribute ortalamaları + tam test listesi."""
    by_attr: dict[str, list[int]] = {k: [] for k in ATTR_KEYS}
    clean: list[dict[str, Any]] = []

    for row in breakdown:
        if not isinstance(row, dict):
            continue
        score = row.get("score")
        if score is None:
            continue
        s = max(1, min(100, int(score)))
        label = str(row.get("label") or row.get("skill") or "")
        attr = row.get("attribute") or attribute_for_label(label)
        if attr not in by_attr:
            by_attr[attr] = []
        by_attr[attr].append(s)
        clean.append(dict(row))

    skill_scores: dict[str, Any] = {
        "slot_breakdown": clean,
        "analysis_version": "slot_v1",
    }
    for attr, scores in by_attr.items():
        if scores:
            skill_scores[attr] = round(sum(scores) / len(scores))
    return skill_scores


def compute_unified_ovr(skill_scores: dict[str, Any], position: str | None = None) -> int:
    """Birleşik kart OVR — ölçülen FIFA altı ortalaması veya mevki ağırlığı."""
    ss = ensure_fifa_six_in_skill_scores(dict(skill_scores), 50)
    if position and position in POSITION_OVR_WEIGHTS:
        return compute_ovr(position, ss)
    vals = [ss.get(k) for k in _FIFA_ATTRS if ss.get(k) is not None]
    if not vals:
        return 50
    return max(1, min(100, round(sum(vals) / len(vals))))


_FIFA_ATTRS = ("pace", "finishing", "passing", "dribbling", "defending", "strength")


def ensure_fifa_six_in_skill_scores(
    skill_scores: dict[str, Any], ovr: int
) -> dict[str, Any]:
    """
    Kart / istatistik için 6 ana metrik — yalnızca slot_breakdown veya
    mevcut skill_scores'tan gelen değerler korunur; ölçülmeyenler boş kalır.
    """
    ss = dict(skill_scores or {})
    breakdown = ss.get("slot_breakdown") or []

    by_attr: dict[str, list[int]] = {k: [] for k in _FIFA_ATTRS}
    extra_physical: list[int] = []
    for row in breakdown:
        if not isinstance(row, dict):
            continue
        score = row.get("score")
        if score is None:
            continue
        s = max(1, min(100, int(score)))
        attr = row.get("attribute") or ""
        if attr in by_attr:
            by_attr[attr].append(s)
        elif attr == "physical_attributes":
            extra_physical.append(s)

    measured: set[str] = set()
    for attr, scores in by_attr.items():
        if scores:
            ss[attr] = round(sum(scores) / len(scores))
            measured.add(attr)

    if extra_physical:
        ss["strength"] = round(sum(extra_physical) / len(extra_physical))
        measured.add("strength")

    # Eski kayıtlardaki ortalama-doldurma (89,89,…) değerlerini kaldır
    for k in _FIFA_ATTRS:
        if k not in measured:
            ss.pop(k, None)

    return ss


def compute_ovr(position: str, skill_scores: dict[str, Any]) -> int:
    weights = POSITION_OVR_WEIGHTS.get(position) or {
        "pace": 0.15,
        "finishing": 0.15,
        "passing": 0.15,
        "dribbling": 0.15,
        "defending": 0.15,
        "strength": 0.15,
        "technical_ability": 0.1,
    }
    total_w = 0.0
    total = 0.0
    for attr, w in weights.items():
        v = skill_scores.get(attr)
        if v is not None:
            total += float(v) * w
            total_w += w
    if total_w <= 0:
        vals = [skill_scores.get(k) for k in ATTR_KEYS if skill_scores.get(k) is not None]
        return round(sum(vals) / len(vals)) if vals else 50
    return max(1, min(100, round(total / total_w)))


def strengths_and_improvements(
    breakdown: list[dict[str, Any]], top_n: int = 3
) -> tuple[list[str], list[str]]:
    sorted_rows = sorted(breakdown, key=lambda x: x.get("score") or 0, reverse=True)
    strengths = [
        f"{r.get('label', r.get('skill', 'Test'))}: {r.get('score')}/100 — {r.get('observation', '')[:120]}"
        for r in sorted_rows[:top_n]
        if (r.get("score") or 0) >= 65
    ]
    weak = sorted(breakdown, key=lambda x: x.get("score") or 0)
    improvements = [
        f"{r.get('label', r.get('skill', 'Test'))}: {r.get('score')}/100 — gelişim: {r.get('observation', '')[:100]}"
        for r in weak[:top_n]
        if (r.get("score") or 0) < 75
    ]
    if not strengths:
        strengths = ["Genel performans değerlendirildi."]
    if not improvements:
        improvements = ["Tüm testlerde dengeli profil; detay için tam rapora bakın."]
    return strengths, improvements


def build_scout_report(
    name: str,
    position: str,
    ovr: int,
    breakdown: list[dict[str, Any]],
) -> str:
    lines = [
        f"{name} ({position}) için slot bazlı AI değerlendirmesi tamamlandı. Genel OVR: {ovr}.",
        "",
        "Test bazlı özet:",
    ]
    for r in breakdown:
        lbl = r.get("label") or r.get("skill") or "Test"
        sc = r.get("score")
        obs = (r.get("observation") or "").strip()
        lines.append(f"• {lbl}: {sc}/100. {obs}")
    return "\n".join(lines).strip()
