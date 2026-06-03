"""Keşfet vitrini: mevki başına en güncel analiz."""
from datetime import datetime, timedelta, timezone

import pytest

from services.discover_visibility import (
    is_discover_eligible,
    is_rising_7d,
    normalize_position,
    pick_discover_winner,
    prior_session_overall_rating,
    refresh_discover_visibility,
    resolve_previous_overall_before_finalize,
)


class _FakePlayer:
    def __init__(
        self,
        id: int,
        user_id: int,
        position: str,
        *,
        status: str = "completed",
        report: str = "Rapor",
        ovr: int = 80,
        previous_ovr: int | None = None,
        updated_at=None,
        discover_visible: bool = False,
    ):
        self.id = id
        self.user_id = user_id
        self.position = position
        self.analysis_status = status
        self.ai_summary_report = report
        self.overall_rating = ovr
        self.previous_overall_rating = previous_ovr
        self.updated_at = updated_at
        self.created_at = updated_at
        self.discover_visible = discover_visible


def test_normalize_position_casefold():
    assert normalize_position("Forvet") == normalize_position("forvet")


def test_pick_discover_winner_latest_by_updated_at():
    t1 = datetime(2025, 1, 1, tzinfo=timezone.utc)
    t2 = datetime(2025, 6, 1, tzinfo=timezone.utc)
    rows = [
        _FakePlayer(1, 10, "Forvet", updated_at=t1),
        _FakePlayer(2, 10, "Forvet", updated_at=t2),
    ]
    winner = pick_discover_winner(rows, "Forvet")
    assert winner is not None
    assert winner.id == 2


def test_pick_discover_winner_different_positions():
    rows = [
        _FakePlayer(1, 10, "Forvet", ovr=70),
        _FakePlayer(2, 10, "Defans", ovr=75),
    ]
    assert pick_discover_winner(rows, "Forvet").id == 1
    assert pick_discover_winner(rows, "Defans").id == 2


class _FakeQuery:
    def __init__(self, rows):
        self._rows = rows

    def filter(self, *args, **kwargs):
        return self

    def all(self):
        return self._rows


class _FakeDb:
    def __init__(self, rows):
        self._rows = rows
        self.committed = False

    def query(self, model):
        return _FakeQuery(self._rows)

    def commit(self):
        self.committed = True


def test_prior_session_overall_rating_excludes_current_row():
    t1 = datetime(2025, 1, 1, tzinfo=timezone.utc)
    t2 = datetime(2025, 6, 1, tzinfo=timezone.utc)
    rows = [
        _FakePlayer(1, 10, "Forvet", ovr=68, updated_at=t1),
        _FakePlayer(2, 10, "Forvet", ovr=0, updated_at=t2),
    ]
    prior = prior_session_overall_rating(
        rows, user_id=10, position="Forvet", exclude_player_id=2
    )
    assert prior == 68


def test_resolve_previous_uses_row_ovr_on_reanalysis():
    row = _FakePlayer(1, 10, "Forvet", ovr=72)
    assert (
        resolve_previous_overall_before_finalize(row, prior_session_ovr=65) == 72
    )


def test_resolve_previous_uses_prior_session_on_new_row():
    row = _FakePlayer(2, 10, "Forvet", ovr=0)
    assert (
        resolve_previous_overall_before_finalize(row, prior_session_ovr=68) == 68
    )


def test_is_rising_7d_requires_recent_update_and_ovr_gain():
    recent = datetime.now(timezone.utc) - timedelta(days=2)
    old = datetime.now(timezone.utc) - timedelta(days=10)
    rising = _FakePlayer(
        1, 10, "Forvet", ovr=74, previous_ovr=68, updated_at=recent
    )
    stale = _FakePlayer(
        2, 10, "Forvet", ovr=74, previous_ovr=68, updated_at=old
    )
    assert is_rising_7d(rising) is True
    assert is_rising_7d(stale) is False


def test_refresh_discover_visibility_hides_older_same_position():
    t1 = datetime(2025, 1, 1, tzinfo=timezone.utc)
    t2 = datetime(2025, 6, 1, tzinfo=timezone.utc)
    old = _FakePlayer(1, 10, "Forvet", updated_at=t1, discover_visible=True)
    new = _FakePlayer(2, 10, "Forvet", updated_at=t2)
    db = _FakeDb([old, new])
    refresh_discover_visibility(db, user_id=10, position="Forvet", winner_player_id=2)
    assert old.discover_visible is False
    assert new.discover_visible is True
    assert db.committed


def test_refresh_sets_previous_from_displaced_session():
    t1 = datetime(2025, 1, 1, tzinfo=timezone.utc)
    t2 = datetime(2025, 6, 1, tzinfo=timezone.utc)
    old = _FakePlayer(1, 10, "Forvet", ovr=68, updated_at=t1, discover_visible=True)
    new = _FakePlayer(2, 10, "Forvet", ovr=75, updated_at=t2)
    db = _FakeDb([old, new])
    refresh_discover_visibility(db, user_id=10, position="Forvet", winner_player_id=2)
    assert new.previous_overall_rating == 68
