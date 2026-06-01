"""RAG-benzeri özet: AI raporu + community rating + scout notları."""
from __future__ import annotations

import re
from typing import Any, Optional

from sqlalchemy.orm import Session

import models
import models_multivideo
import models_product
from services import rating_helpers as rh
from services.combined_rating import build_combined_rating
from services.report_text import strip_analysis_disclaimer


def _extract_short_summary(text: str, max_len: int = 320) -> str:
    """Scout raporundan kısa özet (tam raporu kopyalamaz)."""
    t = re.sub(r"\s+", " ", (text or "").strip())
    if not t:
        return ""
    if len(t) <= max_len:
        return t

    chunk = t[: max_len + 120]
    cut = max_len
    for sep in (". ", "! ", "? ", "; "):
        idx = chunk.rfind(sep, 0, max_len)
        if idx >= 100:
            cut = idx + 1
            break
    out = t[:cut].strip()
    if len(t) > cut and not out.endswith("…"):
        out = out.rstrip(".!?") + "…"
    return out


def _slot_breakdown_from_player(p: models_multivideo.PlayerMultiVideo) -> list[dict[str, Any]]:
    ss = p.skill_scores if isinstance(p.skill_scores, dict) else {}
    raw = ss.get("slot_breakdown")
    return raw if isinstance(raw, list) else []


def _condensed_ai_lines(
    name: str,
    position: str,
    ovr: int,
    breakdown: list[dict[str, Any]],
) -> list[str]:
    """Tam scout raporu yerine kısa satırlar (test adı + puan)."""
    lines: list[str] = []
    if breakdown:
        lines.append(
            f"{name} ({position}) — OVR {ovr}. "
            f"{len(breakdown)} test değerlendirildi."
        )
        for row in breakdown:
            lbl = row.get("label") or row.get("skill") or "Test"
            sc = row.get("score")
            lines.append(f"• {lbl}: {sc}/100")
        return lines

    intro = _extract_short_summary(
        f"{name} ({position}) için AI değerlendirmesi tamamlandı. Genel OVR: {ovr}.",
        max_len=200,
    )
    return [intro] if intro else []


def build_smart_summary(
    db: Session,
    player_id: int,
    *,
    source: str = "multivideo",
) -> dict[str, Any]:
    notes: list[str] = []
    report = ""
    name = ""
    position = ""
    ovr = 0
    community: dict[str, Any] = {}
    breakdown: list[dict[str, Any]] = []

    if source == "multivideo":
        p = (
            db.query(models_multivideo.PlayerMultiVideo)
            .filter(models_multivideo.PlayerMultiVideo.id == player_id)
            .first()
        )
        if not p:
            return {"summary": "Oyuncu bulunamadı.", "sections": []}
        name = p.name or ""
        position = p.position or ""
        report = strip_analysis_disclaimer(p.ai_summary_report)
        breakdown = _slot_breakdown_from_player(p)
        community = rh.build_community_rating_summary_mv(db, player_id)
        combined = build_combined_rating(p.overall_rating or 0, community)
        ovr = combined.get("display_ovr") or p.overall_rating or 0
        note_rows = (
            db.query(models_product.ScoutNote)
            .filter(
                models_product.ScoutNote.player_id == player_id,
                models_product.ScoutNote.player_source == "multivideo",
                models_product.ScoutNote.visibility == "public",
            )
            .order_by(models_product.ScoutNote.created_at.desc())
            .limit(8)
            .all()
        )
        for n in note_rows:
            if n.body:
                notes.append(n.body.strip())
    else:
        p = db.query(models.Player).filter(models.Player.id == player_id).first()
        if not p:
            return {"summary": "Oyuncu bulunamadı.", "sections": []}
        name = p.name or ""
        position = p.position or ""
        report = strip_analysis_disclaimer(p.ai_scout_report)
        community = rh.build_community_rating_summary(db, player_id)
        combined = build_combined_rating(p.overall_rating or 0, community)
        ovr = combined.get("display_ovr") or p.overall_rating or 0

    rc = community.get("rating_count") or 0
    covr = community.get("OVR")
    combined_ovr = combined.get("combined_ovr") if rc else None

    parts: list[str] = []
    condensed = _condensed_ai_lines(name, position, ovr, breakdown)
    if condensed:
        parts.append(condensed[0])
        if len(condensed) > 1:
            parts.append(" ".join(condensed[1:3]))
    elif report:
        short_report = _extract_short_summary(report, max_len=180)
        if short_report:
            parts.append(short_report)
    if rc:
        birlesik = f", birleşik OVR {combined_ovr}" if combined_ovr is not None else ""
        parts.append(
            f"Topluluk: {rc} scout değerlendirmesi, ortalama OVR {covr}{birlesik}."
        )
    if notes:
        snippet = " | ".join(notes[:2])
        if len(snippet) > 180:
            snippet = snippet[:177] + "…"
        parts.append(f"Scout notları: {snippet}")

    headline = f"{name} ({position}, OVR {ovr})".strip()
    summary_text = " ".join(parts).strip() or "Henüz yeterli veri yok."

    sections: list[dict[str, str]] = []
    if condensed:
        ai_body = "\n".join(condensed)
        sections.append({"title": "AI Özet", "body": ai_body})
    elif report:
        sections.append(
            {"title": "AI Özet", "body": _extract_short_summary(report, max_len=400)}
        )
    sections.append(
        {
            "title": "Topluluk",
            "body": (
                f"{rc} scout · topluluk OVR {covr}"
                + (f" · birleşik {combined_ovr}" if combined_ovr is not None else "")
                if rc
                else "Henüz scout puanı yok."
            ),
        }
    )
    if notes:
        sections.append(
            {"title": "Scout Notları", "body": "\n".join(notes[:5])}
        )

    return {
        "headline": headline,
        "summary": summary_text,
        "community_rating": community,
        "public_note_count": len(notes),
        "sections": sections,
    }
