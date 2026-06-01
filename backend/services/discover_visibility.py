"""Keşfet vitrini: kullanıcı + mevki başına yalnızca en güncel tamamlanmış analiz."""
from __future__ import annotations

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
    db.commit()
