import asyncio
from io import BytesIO
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi import HTTPException
from fastapi.testclient import TestClient
from PIL import Image
from starlette.datastructures import Headers, UploadFile
import pytest

import main
from worker_pool import _try_reserve_job, _used_today


client = TestClient(main.app)


def make_png():
    buffer = BytesIO()
    Image.new("RGB", (32, 24), (120, 80, 40)).save(buffer, format="PNG")
    return buffer.getvalue()


def test_health_reports_engine_state(monkeypatch):
    monkeypatch.setattr(main.face_swap_engine, "is_available", lambda: False)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "online"
    assert response.json()["engine_available"] is False


def test_enhance_returns_png():
    response = client.post(
        "/api/enhance",
        files={"image": ("input.png", make_png(), "image/png")},
    )
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("image/png")
    result = Image.open(BytesIO(response.content))
    assert result.format == "PNG"
    assert result.size == (64, 48)


def test_enhance_rejects_non_image():
    response = client.post(
        "/api/enhance",
        files={"image": ("input.txt", b"not an image", "text/plain")},
    )
    assert response.status_code == 400


def test_faceswap_returns_service_unavailable_without_engine(monkeypatch):
    monkeypatch.setattr(main.face_swap_engine, "is_available", lambda: False)
    png = make_png()
    response = client.post(
        "/api/faceswap",
        files={
            "source": ("source.png", png, "image/png"),
            "target": ("target.png", png, "image/png"),
        },
    )
    assert response.status_code == 503
    assert "FaceFusion" in response.json()["detail"]



def test_validate_image_rejects_excessive_dimensions(monkeypatch):
    class OversizedImage:
        size = (5001, 5000)

        def __enter__(self):
            return self

        def __exit__(self, *_args):
            return False

        def verify(self):
            return None

    monkeypatch.setattr(main.Image, "open", lambda *_args, **_kwargs: OversizedImage())
    upload = UploadFile(
        filename="large.png",
        file=BytesIO(b"image-data"),
        headers=Headers({"content-type": "image/png"}),
    )

    with pytest.raises(HTTPException) as error:
        asyncio.run(main.validate_image(upload))

    assert error.value.status_code == 413
    assert "dimensions" in error.value.detail


def test_validate_image_rejects_file_over_limit(monkeypatch):
    monkeypatch.setattr(main, "MAX_FILE_SIZE", 8)
    upload = UploadFile(
        filename="large.png",
        file=BytesIO(b"0123456789"),
        headers=Headers({"content-type": "image/png"}),
    )
    with pytest.raises(HTTPException) as error:
        asyncio.run(main.validate_image(upload))
    assert error.value.status_code == 413


def test_pool_status_requires_api_key_when_configured(monkeypatch):
    monkeypatch.setenv("API_KEY", "private-test-key")
    response = client.get("/pool/status")
    assert response.status_code == 401


def test_pool_status_accepts_correct_api_key_when_configured(monkeypatch):
    async def fake_pool_status():
        return {"workers": []}
    monkeypatch.setenv("API_KEY", "private-test-key")
    monkeypatch.setattr(main, "pool_status", fake_pool_status)
    response = client.get(
        "/pool/status",
        headers={"Authorization": "Bearer private-test-key"},
    )
    assert response.status_code == 200
    assert response.json() == {"workers": []}


def test_worker_quota_reservation_is_persisted(tmp_path, monkeypatch):
    monkeypatch.setenv("POOL_DB_PATH", str(tmp_path / "usage.sqlite3"))
    assert _try_reserve_job("worker-a", 1) is True
    assert _used_today("worker-a") == 1
    assert _try_reserve_job("worker-a", 1) is False
    assert _used_today("worker-a") == 1
