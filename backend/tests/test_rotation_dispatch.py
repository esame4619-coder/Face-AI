import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import worker_pool


def test_dispatch_never_sends_jobs_to_sleeping_worker(monkeypatch, tmp_path):
    import asyncio
    from datetime import datetime, timezone

    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "rotation.sqlite3"))
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "sleeping", "url": "https://sleeping.example", "daily_jobs": 5,
         "rotation": {"enabled": True, "active_from": "10:00", "active_until": "11:00",
                      "timezone": "UTC"}},
        {"name": "active", "url": "https://active.example", "daily_jobs": 5}
    ]))
    monkeypatch.setattr(worker_pool, "scheduled_workers",
                        lambda workers: ([workers[1]], [], [workers[0]], []))
    calls = []

    class Response:
        status_code = 200
        is_success = True
        content = b"result"
        def json(self):
            return {"status": "online"}

    class Client:
        async def __aenter__(self): return self
        async def __aexit__(self, *args): return False
        async def get(self, url, **kwargs):
            calls.append(("health", url))
            return Response()
        async def post(self, url, **kwargs):
            calls.append(("post", url))
            return Response()

    monkeypatch.setattr(worker_pool.httpx, "AsyncClient", lambda **kwargs: Client())
    result, selected = asyncio.run(worker_pool.dispatch_faceswap(b"s", b"t"))
    assert result == b"result"
    assert selected == "active"
    assert all("sleeping.example" not in url for _, url in calls)
    assert any(kind == "post" and "active.example" in url for kind, url in calls)


def test_dispatch_probes_warming_worker_but_does_not_assign_it(monkeypatch, tmp_path):
    import asyncio

    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "warmup.sqlite3"))
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "active", "url": "https://active.example"},
        {"name": "warming", "url": "https://warming.example"}
    ]))
    monkeypatch.setattr(worker_pool, "scheduled_workers",
                        lambda workers: ([workers[0]], [workers[1]], [], []))
    calls = []

    class Response:
        status_code = 200
        is_success = True
        content = b"done"
        def json(self): return {"status": "online"}

    class Client:
        async def __aenter__(self): return self
        async def __aexit__(self, *args): return False
        async def get(self, url, **kwargs):
            calls.append(("health", url))
            return Response()
        async def post(self, url, **kwargs):
            calls.append(("post", url))
            return Response()

    monkeypatch.setattr(worker_pool.httpx, "AsyncClient", lambda **kwargs: Client())
    result, selected = asyncio.run(worker_pool.dispatch_faceswap(b"s", b"t"))
    assert result == b"done"
    assert selected == "active"
    assert ("health", "https://warming.example/health") in calls
    assert not any(kind == "post" and "warming.example" in url for kind, url in calls)



def test_dispatch_rejects_request_when_no_worker_is_active(monkeypatch, tmp_path):
    import asyncio
    import pytest

    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "no-active.sqlite3"))
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "sleeping", "url": "https://sleeping.example"}
    ]))
    monkeypatch.setattr(worker_pool, "scheduled_workers",
                        lambda workers: ([], [], workers, []))

    class Client:
        async def __aenter__(self): return self
        async def __aexit__(self, *args): return False
        async def get(self, url, **kwargs):
            raise AssertionError("sleeping worker must not be probed or receive work")
        async def post(self, url, **kwargs):
            raise AssertionError("no work may be dispatched")

    monkeypatch.setattr(worker_pool.httpx, "AsyncClient", lambda **kwargs: Client())
    with pytest.raises(RuntimeError, match="No workers are inside an active rotation window"):
        asyncio.run(worker_pool.dispatch_faceswap(b"s", b"t"))


def test_failed_warmup_probe_does_not_block_current_active_worker(monkeypatch, tmp_path):
    import asyncio

    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "warmup-failure.sqlite3"))
    monkeypatch.setenv("WORKERS_JSON", json.dumps([
        {"name": "active", "url": "https://active.example"},
        {"name": "warming", "url": "https://warming.example"}
    ]))
    monkeypatch.setattr(worker_pool, "scheduled_workers",
                        lambda workers: ([workers[0]], [workers[1]], [], []))
    posted = []

    class Response:
        status_code = 200
        is_success = True
        content = b"active-result"
        def json(self): return {"status": "online"}

    class Client:
        async def __aenter__(self): return self
        async def __aexit__(self, *args): return False
        async def get(self, url, **kwargs):
            if "warming.example" in url:
                raise TimeoutError("warmup probe timed out")
            return Response()
        async def post(self, url, **kwargs):
            posted.append(url)
            return Response()

    monkeypatch.setattr(worker_pool.httpx, "AsyncClient", lambda **kwargs: Client())
    result, selected = asyncio.run(worker_pool.dispatch_faceswap(b"s", b"t"))
    assert result == b"active-result"
    assert selected == "active"
    assert posted == ["https://active.example/api/faceswap"]
