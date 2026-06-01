"""Multivideo AI analizi — slot bazlı (v1) + arka plan görevi."""
from __future__ import annotations

import os
import shutil
import urllib.request
import uuid as _uuid

from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

import models_multivideo
import vision
from database import SessionLocal
from services import slot_scoring
from services.sprint_timing import apply_sprint_timing_to_slot
from services.multivideo_slots import (
    apply_slot_analysis_result,
    ordered_analysis_items,
)


def _download_item_to_tmp(player_id: int, idx: int, url: str) -> str | None:
    tmp = f"/tmp/fin_{player_id}_{idx}_{_uuid.uuid4()}.mp4"
    try:
        if url.startswith("/static/"):
            candidates = [
                os.path.join(os.path.dirname(__file__), "..", url.lstrip("/")),
                os.path.join(os.getcwd(), url.lstrip("/")),
            ]
            for c in candidates:
                if os.path.exists(c):
                    shutil.copy(c, tmp)
                    return tmp
        elif url.startswith("http"):
            urllib.request.urlretrieve(url, tmp)
            return tmp
        elif os.path.exists(url):
            shutil.copy(url, tmp)
            return tmp
    except Exception as dl_err:
        print(f"[FINALIZE] Video {idx} indirilemedi: {dl_err}")
    return None


def run_multivideo_finalize(player_id: int) -> dict:
    db = SessionLocal()
    temp_paths: list[str] = []
    try:
        player = (
            db.query(models_multivideo.PlayerMultiVideo)
            .filter(models_multivideo.PlayerMultiVideo.id == player_id)
            .first()
        )
        if not player:
            return {"ok": False, "error": "Oyuncu bulunamadı."}

        player.analysis_status = "processing"
        player.analysis_error = None
        db.commit()

        if not player.is_complete:
            player.analysis_status = "failed"
            player.analysis_error = "Tüm videolar yüklenmedi."
            db.commit()
            return {"ok": False, "error": player.analysis_error}

        items = ordered_analysis_items(player)
        slot_results: list[dict] = []

        for idx, item in enumerate(items, 1):
            url = item.get("url")
            if not url:
                continue
            local = _download_item_to_tmp(player_id, idx, url)
            if not local:
                continue
            temp_paths.append(local)

            label = item.get("label") or item.get("skill") or ""
            result = vision.analyze_slot_video(
                local,
                player.position or "",
                label,
                slot=item.get("slot"),
                phase=item.get("phase"),
            )

            phase = item.get("phase")
            if phase == "flat":
                result = apply_sprint_timing_to_slot(
                    result, local, distance_m=20.0, age=player.age
                )
            elif phase == "uphill":
                result = apply_sprint_timing_to_slot(
                    result, local, distance_m=10.0, age=player.age
                )

            if not result.get("compatible", True):
                err_msg = vision._normalize_mismatch_message(
                    result.get("message") or result.get("observation") or ""
                )
                prev_ovr = player.previous_overall_rating
                player.analysis_status = "failed"
                player.analysis_error = err_msg
                player.ai_summary_report = None
                player.ai_strengths = []
                player.ai_improvements = []
                player.skill_scores = {}
                if prev_ovr and prev_ovr > 35:
                    player.overall_rating = prev_ovr
                else:
                    player.overall_rating = 0
                db.commit()
                return {
                    "ok": False,
                    "error": err_msg,
                    "mismatch": True,
                    "retryable": True,
                    "player": player.to_dict(),
                }

            score = int(result.get("score") or 40)
            obs = result.get("observation") or ""
            timing_sec = result.get("timing_sec")
            try:
                timing_sec = float(timing_sec) if timing_sec is not None else None
            except (TypeError, ValueError):
                timing_sec = None
            apply_slot_analysis_result(
                player,
                slot=int(item.get("slot") or 0),
                phase=item.get("phase"),
                is_kosu=bool(item.get("is_kosu")),
                score=score,
                analysis_text=obs,
                timing_sec=timing_sec,
                timing_source=result.get("timing_source"),
                timing_estimated=result.get("timing_estimated"),
            )
            slot_results.append({**result, **item})

        if not slot_results:
            player.analysis_status = "failed"
            player.analysis_error = "Videolar hazırlanamadı. Lütfen tekrar deneyin."
            db.commit()
            return {"ok": False, "error": player.analysis_error, "retryable": True}

        skill_scores = slot_scoring.aggregate_slot_results(slot_results)
        breakdown = skill_scores.get("slot_breakdown") or []
        new_ovr = slot_scoring.compute_ovr(player.position or "", skill_scores)
        skill_scores = slot_scoring.ensure_fifa_six_in_skill_scores(
            skill_scores, new_ovr
        )

        if player.overall_rating and player.overall_rating > 35:
            player.previous_overall_rating = player.overall_rating
        player.overall_rating = max(1, min(100, new_ovr))
        player.skill_scores = skill_scores
        player.ai_summary_report = slot_scoring.build_scout_report(
            player.name or "",
            player.position or "",
            player.overall_rating,
            breakdown,
        )
        strengths, improvements = slot_scoring.strengths_and_improvements(breakdown)
        player.ai_strengths = strengths
        player.ai_improvements = improvements
        player.analysis_status = "completed"
        player.analysis_error = None

        flag_modified(player, "skill_scores")
        flag_modified(player, "ai_strengths")
        flag_modified(player, "ai_improvements")
        db.commit()

        if player.user_id:
            from services.notifications import notify_player_owner_analysis_done

            notify_player_owner_analysis_done(
                db, player.user_id, player.name, player.id
            )

        return {"ok": True, "player": player.to_dict()}
    except Exception as exc:
        db.rollback()
        try:
            player = (
                db.query(models_multivideo.PlayerMultiVideo)
                .filter(models_multivideo.PlayerMultiVideo.id == player_id)
                .first()
            )
            if player:
                player.analysis_status = "failed"
                player.analysis_error = f"Analiz hatası: {exc}"
                db.commit()
        except Exception:
            pass
        return {"ok": False, "error": str(exc), "retryable": True}
    finally:
        for tmp in temp_paths:
            try:
                os.remove(tmp)
            except Exception:
                pass
        db.close()
