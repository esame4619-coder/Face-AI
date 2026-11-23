import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import worker_pool


def test_worker_config_requires_valid_http_worker(monkeypatch):
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "worker-a", "url": "https://worker-a.example", "daily_jobs": 12},
        {"name": "bad-scheme", "url": "ftp://worker.example"},
        {"name": "missing-url"},
    ]))
    workers = worker_pool._workers()
    assert len(workers) == 1
    assert workers[0]["name"] == "worker-a"
    assert workers[0]["daily_jobs"] == 12


def test_worker_config_empty_means_no_remote_workers(monkeypatch):
    monkeypatch.delenv("WORKERS_JSON", raising=False)
    assert worker_pool._workers() == []


def test_worker_usage_is_counted_per_utc_day_and_worker(tmp_path, monkeypatch):
    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "usage.sqlite3"))
    assert worker_pool._used_today("worker-a") == 0
    assert worker_pool._try_reserve_job("worker-a", 2) is True
    assert worker_pool._try_reserve_job("worker-a", 2) is True
    assert worker_pool._try_reserve_job("worker-a", 2) is False
    assert worker_pool._try_reserve_job("worker-b", 2) is True
    assert worker_pool._used_today("worker-a") == 2
    assert worker_pool._used_today("worker-b") == 1
