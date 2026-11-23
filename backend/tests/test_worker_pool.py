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


def test_pool_status_coverage_requires_quota_ready_worker(monkeypatch, tmp_path):
    import asyncio

    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "quota-status.sqlite3"))
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "worker-a", "url": "https://worker-a.example", "daily_jobs": 1}
    ]))
    monkeypatch.setenv("MIN_ACTIVE_WORKERS", "1")
    monkeypatch.setattr(worker_pool, "_used_today", lambda _name: 1)

    class Response:
        is_success = True
        def json(self): return {"status": "online"}

    class Client:
        async def __aenter__(self): return self
        async def __aexit__(self, *args): return False
        async def get(self, url, **kwargs): return Response()

    monkeypatch.setattr(worker_pool.httpx, "AsyncClient", lambda **kwargs: Client())
    result = asyncio.run(worker_pool.pool_status())

    assert result["healthy_active"] == 1
    assert result["ready_active"] == 0
    assert result["coverage_gap"] is True
    assert result["workers"][0]["available_by_quota"] is False


def test_dispatch_keeps_inflight_request_until_worker_responds(monkeypatch, tmp_path):
    import asyncio
    import worker_pool

    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "inflight.sqlite3"))
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "worker-a", "url": "https://worker-a.example", "daily_jobs": 5}
    ]))
    worker = worker_pool._workers()[0]
    monkeypatch.setattr(
        worker_pool, "scheduled_workers",
        lambda _workers: ([worker], [], [], [])
    )

    class Response:
        is_success = True
        status_code = 200
        content = b"completed-after-window"
        def json(self): return {"status": "online"}

    class Client:
        async def __aenter__(self): return self
        async def __aexit__(self, *args): return False
        async def get(self, url, **kwargs): return Response()
        async def post(self, url, **kwargs):
            await asyncio.sleep(0.03)  # Simulate the rotation boundary passing.
            return Response()

    monkeypatch.setattr(worker_pool.httpx, "AsyncClient", lambda **kwargs: Client())
    result, worker_name = asyncio.run(
        worker_pool.dispatch_faceswap(b"source", b"target")
    )

    assert result == b"completed-after-window"
    assert worker_name == "worker-a"


def test_dispatch_skips_unhealthy_worker_and_hands_over(monkeypatch, tmp_path):
    import asyncio

    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "handover.sqlite3"))
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "worker-a", "url": "https://worker-a.example", "daily_jobs": 5},
        {"name": "worker-b", "url": "https://worker-b.example", "daily_jobs": 5},
    ]))
    worker_pool._cursor = 0

    class Response:
        def __init__(self, online=True, content=b""):
            self.is_success = True
            self.status_code = 200
            self.content = content
            self._online = online
        def json(self): return {"status": "online" if self._online else "offline"}

    class Client:
        async def __aenter__(self): return self
        async def __aexit__(self, *args): return False
        async def get(self, url, **kwargs):
            return Response(online="worker-b" in url)
        async def post(self, url, **kwargs):
            return Response(content=b"handover-success")

    monkeypatch.setattr(worker_pool.httpx, "AsyncClient", lambda **kwargs: Client())
    result, name = asyncio.run(worker_pool.dispatch_faceswap(b"s", b"t"))

    assert result == b"handover-success"
    assert name == "worker-b"
    assert worker_pool._used_today("worker-a") == 0
    assert worker_pool._used_today("worker-b") == 1


def test_daily_quota_reservation_is_atomic_under_concurrency(tmp_path, monkeypatch):
    from concurrent.futures import ThreadPoolExecutor

    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "concurrent-quota.sqlite3"))
    limit = 7
    with ThreadPoolExecutor(max_workers=20) as executor:
        results = list(executor.map(
            lambda _index: worker_pool._try_reserve_job("shared-worker", limit),
            range(30),
        ))

    assert sum(results) == limit
    assert worker_pool._used_today("shared-worker") == limit
