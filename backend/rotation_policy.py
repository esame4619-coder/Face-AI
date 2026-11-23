"""UTC-safe daily worker rotation policy."""
from datetime import datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


def _clock(value: str) -> time:
    try:
        hour, minute = value.split(":", 1)
        return time(int(hour), int(minute))
    except (ValueError, AttributeError):
        raise ValueError("rotation times must use HH:MM") from None


def rotation_state(config: dict, now: datetime | None = None) -> str:
    """Return active, warming, sleeping, or invalid for a recurring local window."""
    if not config or not config.get("enabled", False):
        return "active"
    try:
        zone = ZoneInfo(str(config.get("timezone", "UTC")))
        start = _clock(config["active_from"])
        end = _clock(config["active_until"])
        warmup = max(0, min(180, int(config.get("warmup_minutes", 10))))
    except (KeyError, ValueError, TypeError, ZoneInfoNotFoundError):
        return "invalid"
    current = now or datetime.now(timezone.utc)
    if current.tzinfo is None:
        current = current.replace(tzinfo=timezone.utc)
    local = current.astimezone(zone)
    start_dt = datetime.combine(local.date(), start, tzinfo=zone)
    end_dt = datetime.combine(local.date(), end, tzinfo=zone)
    if end <= start:
        end_dt += timedelta(days=1)
        previous_start = start_dt - timedelta(days=1)
        previous_end = end_dt - timedelta(days=1)
        if previous_start <= local < previous_end:
            return "active"
    if start_dt <= local < end_dt:
        return "active"
    if timedelta(0) <= start_dt - local <= timedelta(minutes=warmup):
        return "warming"
    return "sleeping"


def scheduled_workers(workers: list[dict], now: datetime | None = None):
    active, warming, sleeping, invalid = [], [], [], []
    for worker in workers:
        state = rotation_state(worker.get("rotation", {}), now)
        if state == "active":
            active.append(worker)
        elif state == "warming":
            warming.append(worker)
        elif state == "sleeping":
            sleeping.append(worker)
        else:
            invalid.append(worker["name"])
    return active, warming, sleeping, invalid


def next_rotation_transition(workers: list[dict], now: datetime | None = None):
    """Find the next minute when any configured worker changes schedule state."""
    current = now or datetime.now(timezone.utc)
    if current.tzinfo is None:
        current = current.replace(tzinfo=timezone.utc)
    current = current.astimezone(timezone.utc).replace(second=0, microsecond=0)
    initial = [rotation_state(w.get("rotation", {}), current) for w in workers]
    if all(not w.get("rotation", {}).get("enabled", False) for w in workers):
        return None
    for minute in range(1, 24 * 60 + 1):
        candidate = current + timedelta(minutes=minute)
        states = [rotation_state(w.get("rotation", {}), candidate) for w in workers]
        if states != initial:
            return candidate.isoformat()
    return None
