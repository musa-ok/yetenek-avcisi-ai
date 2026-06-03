"""Keşfet vitrini: kullanıcı + mevki başına yalnızca en güncel tamamlanmış analiz."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy.orm import Session

import models_multivideo as mv


def normalize_position(position: Optional[str]) -> str:
    return (position or "").strip().casefold()


def is_discover_eligible(player: mv.PlayerMultiVideo) -> bool:
    """Keşfet listesine girebilecek tamamlanmış analiz."""
    if (player.analysis_status or "").lower() != "completed":
        return False
    if not (player.ai_summary_report or "").strip():
        return False
    return int(player.overall_rating or 0) > 35


def _recency_key(player: mv.PlayerMultiVideo) -> tuple[float, int]:
    ts = player.updated_at or player.created_at
    if ts is None:
        return (0.0, player.id or 0)
    if ts.tzinfo is not None:
        return (ts.timestamp(), player.id or 0)
    return (ts.timestamp(), player.id or 0)


def pick_discover_winner(
    players: list[mv.PlayerMultiVideo], position: str
) -> Optional[mv.PlayerMultiVideo]:
    """Aynı kullanıcı + mevki için Keşfet'te gösterilecek kayıt (en güncel tamamlanan)."""
    pos = normalize_position(position)
    eligible = [
        p
        for p in players
        if normalize_position(p.position) == pos and is_discover_eligible(p)
    ]
    if not eligible:
        return None
    return max(eligible, key=_recency_key)


def prior_session_overall_rating(
    rows: list[mv.PlayerMultiVideo],
    *,
    user_id: int,
    position: str,
    exclude_player_id: int,
) -> Optional[int]:
    """Aynı kullanıcı + mevki: hariç tutulan kayıt dışındaki en güncel tamamlanmış oturum OVR."""
    pos = normalize_position(position)
    candidates = [
        p
        for p in rows
        if p.user_id == user_id
        and normalize_position(p.position) == pos
        and p.id != exclude_player_id
        and is_discover_eligible(p)
    ]
    if not candidates:
        return None
    best = max(candidates, key=_recency_key)
    ovr = int(best.overall_rating or 0)
    return ovr if ovr > 35 else None


def prior_session_overall_rating_for_user(
    db: Session,
    *,
    user_id: int,
    position: str,
    exclude_player_id: int,
) -> Optional[int]:
    rows = (
        db.query(mv.PlayerMultiVideo)
        .filter(mv.PlayerMultiVideo.user_id == user_id)
        .all()
    )
    return prior_session_overall_rating(
        rows,
        user_id=user_id,
        position=position,
        exclude_player_id=exclude_player_id,
    )


def resolve_previous_overall_before_finalize(
    player: mv.PlayerMultiVideo,
    *,
    prior_session_ovr: Optional[int],
) -> Optional[int]:
    """
    Finalize öncesi karşılaştırma OVR:
    - Aynı satırda zaten OVR varsa (yeniden analiz) o değer
    - Yeni oturumda önceki tamamlanmış oturumun OVR'ı
    """
    current = int(player.overall_rating or 0)
    if current > 35:
        return current
    if prior_session_ovr is not None and prior_session_ovr > 35:
        return prior_session_ovr
    return None


def _as_utc_aware(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def is_rising_7d(player: mv.PlayerMultiVideo) -> bool:
    """Son 7 günde güncellenmiş ve önceki referans OVR'a göre artış."""
    prev = player.previous_overall_rating
    cur = int(player.overall_rating or 0)
    if prev is None or cur <= prev:
        return False
    ts = _as_utc_aware(player.updated_at)
    if ts is None:
        return False
    since = datetime.now(timezone.utc) - timedelta(days=7)
    return ts >= since


def _ensure_previous_from_prior_session(
    rows: list[mv.PlayerMultiVideo],
    winner: mv.PlayerMultiVideo,
) -> None:
    """Vitrin kazananında önceki oturum OVR referansı yoksa doldur (mevcut veri)."""
    if not is_discover_eligible(winner):
        return
    cur = int(winner.overall_rating or 0)
    if winner.previous_overall_rating is not None:
        return
    prior = prior_session_overall_rating(
        rows,
        user_id=winner.user_id,
        position=winner.position or "",
        exclude_player_id=winner.id,
    )
    if prior is not None and cur > prior:
        winner.previous_overall_rating = prior


def refresh_discover_visibility(
    db: Session,
    *,
    user_id: int,
    position: str,
    winner_player_id: Optional[int] = None,
) -> None:
    """
    Verilen mevki için kullanıcının tüm kayıtlarını günceller:
    yalnızca kazanan tamamlanmış analiz discover_visible=True.
    """
    rows = (
        db.query(mv.PlayerMultiVideo)
        .filter(mv.PlayerMultiVideo.user_id == user_id)
        .all()
    )
    winner = None
    if winner_player_id is not None:
        winner = next((r for r in rows if r.id == winner_player_id), None)
    if winner is None or not is_discover_eligible(winner):
        winner = pick_discover_winner(rows, position)

    pos = normalize_position(position)
    for row in rows:
        if normalize_position(row.position) != pos:
            continue
        row.discover_visible = bool(
            winner is not None and row.id == winner.id and is_discover_eligible(row)
        )
    if winner is not None:
        _ensure_previous_from_prior_session(rows, winner)
    db.commit()


def backfill_all_discover_visibility(db: Session) -> None:
    """Mevcut veri: her (user_id, mevki) için en güncel tamamlanmış analizi işaretle."""
    rows = db.query(mv.PlayerMultiVideo).all()
    by_user: dict[int, list[mv.PlayerMultiVideo]] = {}
    for row in rows:
        by_user.setdefault(row.user_id, []).append(row)

    for user_rows in by_user.values():
        positions = {normalize_position(r.position) for r in user_rows}
        for pos in positions:
            if not pos:
                continue
            winner = pick_discover_winner(user_rows, pos)
            for row in user_rows:
                if normalize_position(row.position) != pos:
                    continue
                row.discover_visible = bool(
                    winner is not None
                    and row.id == winner.id
                    and is_discover_eligible(row)
                )
            if winner is not None:
                _ensure_previous_from_prior_session(user_rows, winner)
    db.commit()
