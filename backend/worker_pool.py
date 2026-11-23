"""Central scheduler for a configurable pool of independently hosted workers.

Workers are opt-in and explicitly configured with WORKERS_JSON. The scheduler
never creates accounts, bypasses provider limits, or assumes free capacity.
"""
import asyncio
import json
import os
import sqlite3
from pathlib import Path
from datetime import datetime, timezone
from typing import Any

import httpx

_MAX_FAILOVER = 3
_REQUEST_TIMEOUT = 900.0
_selection_lock = asyncio.Lock()
_dispatch_slots = asyncio.Semaphore(4)
_cursor = 0


def _workers() -> list[dict[str, Any]]:
    raw = os.getenv("WORKERS_JSON", "").strip()
    if not raw:
        return []
    try:
        items = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RuntimeError("WORKERS_JSON must contain a valid JSON array") from exc
    if not isinstance(items, list):
        raise RuntimeError("WORKERS_JSON must be a JSON array")
    result = []
    for item in items:
        if not isinstance(item, dict) or not item.get("url") or not item.get("name"):
            continue
        url = str(item["url"]).strip().rstrip("/")
        if not url.startswith("https://") and not url.startswith("http://127.0.0.1"):
            continue
        result.append({
            "name": str(item["name"]),
            "url": url,
            "api_key": str(item.get("api_key", "")),
            "daily_jobs": max(0, int(item.get("daily_jobs", 0))),
        })
    return result


def _db_path() -> str:
    path = Path(os.getenv("POOL_DB_PATH", "/data/worker_pool.sqlite3"))
    path.parent.mkdir(parents=True, exist_ok=True)
    return str(path)


def _used_today(name: str) -> int:
    today = datetime.now(timezone.utc).date().isoformat()
    with sqlite3.connect(_db_path(), timeout=10) as db:
        db.execute("""CREATE TABLE IF NOT EXISTS worker_usage (
            worker TEXT NOT NULL, day TEXT NOT NULL, jobs INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY(worker, day)
        )""")
        row = db.execute(
            "SELECT jobs FROM worker_usage WHERE worker=? AND day=?",
            (name, today),
        ).fetchone()
        return int(row[0]) if row else 0


def _try_reserve_job(name: str, daily_limit: int) -> bool:
    today = datetime.now(timezone.utc).date().isoformat()
    with sqlite3.connect(_db_path(), timeout=10, isolation_level="IMMEDIATE") as db:
        db.execute("""CREATE TABLE IF NOT EXISTS worker_usage (
            worker TEXT NOT NULL, day TEXT NOT NULL, jobs INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY(worker, day)
        )""")
        row = db.execute(
            "SELECT jobs FROM worker_usage WHERE worker=? AND day=?",
            (name, today),
        ).fetchone()
        used = int(row[0]) if row else 0
        if daily_limit and used >= daily_limit:
            return False
        db.execute(
            """INSERT INTO worker_usage(worker, day, jobs) VALUES(?, ?, 1)
            ON CONFLICT(worker, day) DO UPDATE SET jobs=jobs+1""",
            (name, today),
        )
        return True


async def pool_status() -> dict[str, Any]:
    workers = _workers()
    status = []
    async with httpx.AsyncClient(timeout=8.0) as client:
        for worker in workers:
            headers = {"Authorization": f"Bearer {worker['api_key']}"} if worker["api_key"] else {}
            try:
                response = await client.get(worker["url"] + "/health", headers=headers)
                online = response.is_success and response.json().get("status") == "online"
            except Exception:
                online = False
            used = await asyncio.to_thread(_used_today, worker["name"])
            limit = worker["daily_jobs"]
            status.append({
                "name": worker["name"],
                "online": online,
                "jobs_used_today": used,
                "daily_jobs_limit": limit if limit else None,
                "available_by_quota": (not limit or used < limit),
            })
    return {"configured": len(workers), "workers": status}


async def dispatch_faceswap(source: bytes, target: bytes) -> tuple[bytes, str]:
    global _cursor
    workers = _workers()
    if not workers:
        raise RuntimeError("No remote workers are configured")
    async with _dispatch_slots:
        async with httpx.AsyncClient(timeout=_REQUEST_TIMEOUT) as client:
            async with _selection_lock:
                start = _cursor % len(workers)
                _cursor = (_cursor + 1) % len(workers)
            ordered = workers[start:] + workers[:start]
            attempted = 0
            errors = []
            for worker in ordered:
                if attempted >= min(_MAX_FAILOVER, len(ordered)):
                    break
                attempted += 1
                headers = {"Authorization": f"Bearer {worker['api_key']}"} if worker["api_key"] else {}
                try:
                    health = await client.get(worker["url"] + "/health", headers=headers, timeout=8.0)
                    if not health.is_success or health.json().get("status") != "online":
                        errors.append(f"{worker['name']}: unhealthy")
                        continue
                    reserved = await asyncio.to_thread(
                        _try_reserve_job, worker["name"], worker["daily_jobs"]
                    )
                    if not reserved:
                        errors.append(f"{worker['name']}: daily quota reached")
                        continue
                    response = await client.post(
                        worker["url"] + "/api/faceswap",
                        files={
                            "source": ("source.png", source, "image/png"),
                            "target": ("target.png", target, "image/png"),
                        },
                        headers=headers,
                    )
                    if response.is_success and response.content:
                        return response.content, worker["name"]
                    errors.append(f"{worker['name']}: HTTP {response.status_code}")
                except Exception as exc:
                    errors.append(f"{worker['name']}: {type(exc).__name__}")
            detail = "; ".join(errors[-3:]) or "All configured workers reached their daily quota"
            raise RuntimeError("No worker could process this request. " + detail)
