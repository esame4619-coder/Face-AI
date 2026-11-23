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


def test_dispatch_fails_over_to_next_healthy_worker(monkeypatch, tmp_path):
    import asyncio

    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "usage.sqlite3"))
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "worker-a", "url": "https://worker-a.example", "daily_jobs": 5},
        {"name": "worker-b", "url": "https://worker-b.example", "daily_jobs": 5},
    ]))
    worker_pool._cursor = 0
    attempted = []

    class FakeResponse:
        def __init__(self, status_code, content=b"", payload=None):
            self.status_code = status_code
            self.content = content
            self.is_success = 200 <= status_code < 300
            self._payload = payload or {}

        def json(self):
            return self._payload

    class FakeClient:
        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            return False

        async def get(self, url, **kwargs):
            return FakeResponse(200, payload={"status": "online"})

        async def post(self, url, **kwargs):
            attempted.append(url)
            if "worker-a" in url:
                return FakeResponse(503)
            return FakeResponse(200, content=b"processed-image")

    monkeypatch.setattr(worker_pool.httpx, "AsyncClient", lambda **kwargs: FakeClient())

    result, worker_name = asyncio.run(
        worker_pool.dispatch_faceswap(b"source", b"target")
    )

    assert result == b"processed-image"
    assert worker_name == "worker-b"
    assert attempted == [
        "https://worker-a.example/api/faceswap",
        "https://worker-b.example/api/faceswap",
    ]
    assert worker_pool._used_today("worker-a") == 1
    assert worker_pool._used_today("worker-b") == 1


def test_private_docker_worker_urls_require_explicit_opt_in(monkeypatch):
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "internal", "url": "http://worker-one:8000"},
        {"name": "public-http", "url": "http://example.com"},
    ]))
    monkeypatch.delenv("ALLOW_INSECURE_WORKER_URLS", raising=False)
    assert worker_pool._workers() == []

    monkeypatch.setenv("ALLOW_INSECURE_WORKER_URLS", "true")
    workers = worker_pool._workers()
    assert [worker["name"] for worker in workers] == ["internal"]


def test_pool_status_reports_health_coverage_and_transition(monkeypatch, tmp_path):
    import asyncio

    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "status.sqlite3"))
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "worker-a", "url": "https://worker-a.example"}
    ]))
    monkeypatch.setenv("MIN_ACTIVE_WORKERS", "2")
    monkeypatch.setattr(worker_pool, "_used_today", lambda _name: 0)

    class Response:
        is_success = True
        def json(self): return {"status": "online"}

    class Client:
        async def __aenter__(self): return self
        async def __aexit__(self, *args): return False
        async def get(self, url, **kwargs): return Response()

    monkeypatch.setattr(worker_pool.httpx, "AsyncClient", lambda **kwargs: Client())
    result = asyncio.run(worker_pool.pool_status())

    assert result["configured"] == 1
    assert result["active_scheduled"] == 1
    assert result["healthy_active"] == 1
    assert result["minimum_active_required"] == 2
    assert result["coverage_gap"] is True
    assert result["workers"][0]["health_state"] == "healthy"
    assert result["workers"][0]["accepting_new_jobs"] is True
    assert result["next_transition"] is None
