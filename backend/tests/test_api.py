from io import BytesIO

from fastapi.testclient import TestClient
from PIL import Image

import main


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
