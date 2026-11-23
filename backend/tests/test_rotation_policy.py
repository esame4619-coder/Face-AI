from datetime import datetime, timezone
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from rotation_policy import rotation_state, scheduled_workers


def test_rotation_active_and_warmup_windows():
    config = {"enabled": True, "active_from": "08:00", "active_until": "12:00",
              "timezone": "UTC", "warmup_minutes": 15}
    assert rotation_state(config, datetime(2026, 11, 23, 8, 0, tzinfo=timezone.utc)) == "active"
    assert rotation_state(config, datetime(2026, 11, 23, 7, 50, tzinfo=timezone.utc)) == "warming"
    assert rotation_state(config, datetime(2026, 11, 23, 7, 30, tzinfo=timezone.utc)) == "sleeping"
    assert rotation_state(config, datetime(2026, 11, 23, 12, 0, tzinfo=timezone.utc)) == "sleeping"


def test_rotation_crosses_midnight():
    config = {"enabled": True, "active_from": "22:00", "active_until": "06:00",
              "timezone": "UTC", "warmup_minutes": 20}
    assert rotation_state(config, datetime(2026, 11, 24, 2, 0, tzinfo=timezone.utc)) == "active"
    assert rotation_state(config, datetime(2026, 11, 23, 21, 45, tzinfo=timezone.utc)) == "warming"
    assert rotation_state(config, datetime(2026, 11, 24, 6, 0, tzinfo=timezone.utc)) == "sleeping"


def test_disabled_rotation_keeps_legacy_worker_active():
    assert rotation_state({}, datetime(2026, 11, 23, 2, 0, tzinfo=timezone.utc)) == "active"


def test_invalid_rotation_is_not_scheduled():
    config = {"enabled": True, "active_from": "bad", "active_until": "06:00"}
    assert rotation_state(config, datetime(2026, 11, 23, 2, 0, tzinfo=timezone.utc)) == "invalid"


def test_worker_groups_separate_active_warming_and_sleeping():
    workers = [
        {"name": "active", "rotation": {}},
        {"name": "warm", "rotation": {"enabled": True, "active_from": "08:00",
         "active_until": "12:00", "timezone": "UTC", "warmup_minutes": 15}},
        {"name": "sleep", "rotation": {"enabled": True, "active_from": "10:00",
         "active_until": "12:00", "timezone": "UTC"}},
    ]
    active, warming, sleeping, invalid = scheduled_workers(
        workers, datetime(2026, 11, 23, 7, 50, tzinfo=timezone.utc))
    assert [w["name"] for w in active] == ["active"]
    assert [w["name"] for w in warming] == ["warm"]
    assert [w["name"] for w in sleeping] == ["sleep"]
    assert invalid == []
