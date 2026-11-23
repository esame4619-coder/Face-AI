"""Central scheduler for a configurable pool of independently hosted workers.

Workers are opt-in and explicitly configured with WORKERS_JSON. The scheduler
never creates accounts, bypasses provider limits, or assumes free capacity.
"""
import asyncio
import json
import os
import re
import sqlite3
from pathlib import Path
from datetime import datetime, timezone
from typing import Any
from urllib.parse import urlparse

import httpx
from rotation_policy import scheduled_workers, next_rotation_transition

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
        parsed = urlparse(url)
        secure_url = parsed.scheme == "https" and bool(parsed.hostname)
        loopback_url = parsed.scheme == "http" and parsed.hostname in {"127.0.0.1", "localhost"}
        internal_http = (
            os.getenv("ALLOW_INSECURE_WORKER_URLS", "").lower() == "true"
            and parsed.scheme == "http"
            and bool(parsed.hostname)
            and re.fullmatch(r"[a-zA-Z0-9-]+", parsed.hostname) is not None
        )
        if not (secure_url or loopback_url or internal_http):
            continue
        result.append({
            "name": str(item["name"]),
            "url": url,
            "api_key": str(item.get("api_key", "")),
            "daily_jobs": max(0, int(item.get("daily_jobs", 0))),
            "rotation": item.get("rotation", {}) if isinstance(item.get("rotation", {}), dict) else {},
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
    now = datetime.now(timezone.utc)
    active, warming, sleeping, invalid = scheduled_workers(workers, now)
    states = {w["name"]: "active" for w in active}
    states.update({w["name"]: "warming" for w in warming})
    states.update({w["name"]: "sleeping" for w in sleeping})
    states.update({name: "invalid" for name in invalid})
    probe_limit = asyncio.Semaphore(max(1, min(10, int(os.getenv("POOL_STATUS_CONCURRENCY", "10")))))

    async def inspect_worker(client: httpx.AsyncClient, worker: dict[str, Any]) -> dict[str, Any]:
        headers = {"Authorization": f"Bearer {worker['api_key']}"} if worker["api_key"] else {}
        async with probe_limit:
            try:
                response = await client.get(
                    worker["url"] + "/health", headers=headers, timeout=8.0
                )
                online = response.is_success and response.json().get("status") == "online"
            except Exception:
                online = False
        used = await asyncio.to_thread(_used_today, worker["name"])
        limit = worker["daily_jobs"]
        quota_ok = not limit or used < limit
        state = states.get(worker["name"], "invalid")
        accepting = state == "active" and online and quota_ok
        return {
            "name": worker["name"],
            "online": online,
            "health_state": "healthy" if online else "unreachable",
            "jobs_used_today": used,
            "daily_jobs_limit": limit if limit else None,
            "available_by_quota": quota_ok,
            "rotation_state": state,
            "accepting_new_jobs": accepting,
        }

    async with httpx.AsyncClient(timeout=8.0) as client:
        status = await asyncio.gather(
            *(inspect_worker(client, worker) for worker in workers)
        )
    healthy_active = sum(
        1 for item in status
        if item["rotation_state"] == "active" and item["online"]
    )
    ready_active = sum(1 for item in status if item["accepting_new_jobs"])
    try:
        minimum_active = max(1, int(os.getenv("MIN_ACTIVE_WORKERS", "1")))
    except ValueError:
        minimum_active = 1
    coverage_gap = len(active) < minimum_active or ready_active < minimum_active
    return {
        "configured": len(workers),
        "active_scheduled": len(active),
        "healthy_active": healthy_active,
        "ready_active": ready_active,
        "minimum_active_required": minimum_active,
        "warming": len(warming),
        "sleeping": len(sleeping),
        "invalid_rotation": len(invalid),
        "coverage_gap": coverage_gap,
        "next_transition": next_rotation_transition(workers, now),
        "workers": status,
    }


async def dispatch_faceswap(source: bytes, target: bytes) -> tuple[bytes, str]:
    global _cursor
    workers = _workers()
    if not workers:
        raise RuntimeError("No remote workers are configured")
    active, warming, sleeping, invalid = scheduled_workers(workers)
    async with _dispatch_slots:
        async with httpx.AsyncClient(timeout=_REQUEST_TIMEOUT) as client:
            # Probe upcoming workers during warm-up; they receive no jobs until active.
            for candidate in warming:
                candidate_headers = {"Authorization": f"Bearer {candidate['api_key']}"} if candidate["api_key"] else {}
                try:
                    await client.get(candidate["url"] + "/health", headers=candidate_headers, timeout=8.0)
                except Exception:
                    pass
            if not active:
                raise RuntimeError("No workers are inside an active rotation window")
            async with _selection_lock:
                start = _cursor % len(active)
                _cursor = (_cursor + 1) % len(active)
            ordered = active[start:] + active[:start]
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
