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


def test_video_face_detection_returns_local_face_choices(monkeypatch):
    monkeypatch.delenv("WORKERS_JSON", raising=False)
    monkeypatch.delenv("API_KEY", raising=False)
    monkeypatch.setattr(main, "inspect_video", lambda _data: 4.2)

    def fake_detect(data):
        assert data == b"valid-video"
        return {
            "reference_frame_number": 42,
            "reference_time_seconds": 1.68,
            "faces": [{"image": "ZmFrZQ==", "score": 0.98}],
        }

    monkeypatch.setattr(main.face_swap_engine, "detect_video_faces", fake_detect)
    response = client.post(
        "/api/video-faces",
        files={"target_video": ("clip.mp4", b"valid-video", "video/mp4")},
    )
    assert response.status_code == 200
    assert response.json()["reference_frame_number"] == 42
    assert response.json()["reference_time_seconds"] == 1.68
    assert response.json()["faces"][0]["score"] == 0.98
    assert response.json()["worker"] == "local"


def test_video_face_detection_rejects_wrong_content_type():
    response = client.post(
        "/api/video-faces",
        files={"target_video": ("clip.avi", b"video", "video/x-msvideo")},
    )
    assert response.status_code == 400


def test_video_face_detection_rejects_empty_video():
    response = client.post(
        "/api/video-faces",
        files={"target_video": ("clip.mp4", b"", "video/mp4")},
    )
    assert response.status_code == 400


def test_video_face_detection_enforces_upload_limit(monkeypatch):
    monkeypatch.setattr(main, "MAX_VIDEO_SIZE", 4)
    response = client.post(
        "/api/video-faces",
        files={"target_video": ("clip.mp4", b"12345", "video/mp4")},
    )
    assert response.status_code == 413


def test_video_face_detection_requires_api_key_when_configured(monkeypatch):
    monkeypatch.setenv("API_KEY", "video-secret")
    response = client.post(
        "/api/video-faces",
        files={"target_video": ("clip.mp4", b"video", "video/mp4")},
    )
    assert response.status_code == 401


def test_video_swap_forwards_selected_reference_to_worker(monkeypatch):
    monkeypatch.setenv("WORKERS_JSON", '[{"name":"worker-a","url":"https://worker.example"}]')
    monkeypatch.delenv("API_KEY", raising=False)
    monkeypatch.setattr(main, "inspect_video", lambda _data: 4.2)
    captured = {}

    async def fake_dispatch(source, video, frame_number, face_position):
        captured.update(
            source=source,
            video=video,
            frame_number=frame_number,
            face_position=face_position,
        )
        return b"processed-mp4", "worker-a"

    monkeypatch.setattr(main, "dispatch_video_faceswap", fake_dispatch)
    response = client.post(
        "/api/faceswap-video",
        data={"reference_frame_number": "42", "reference_face_position": "2"},
        files={
            "source": ("face.png", make_png(), "image/png"),
            "target_video": ("clip.mp4", b"valid-video", "video/mp4"),
        },
    )
    assert response.status_code == 200
    assert response.content == b"processed-mp4"
    assert response.headers["x-worker-name"] == "worker-a"
    assert captured["frame_number"] == 42
    assert captured["face_position"] == 2
    assert captured["video"] == b"valid-video"


def test_video_swap_rejects_negative_reference_values():
    response = client.post(
        "/api/faceswap-video",
        data={"reference_frame_number": "-1", "reference_face_position": "0"},
        files={
            "source": ("face.png", make_png(), "image/png"),
            "target_video": ("clip.mp4", b"valid-video", "video/mp4"),
        },
    )
    assert response.status_code == 422

def test_inspect_video_accepts_mp4_under_duration_limit(monkeypatch):
    monkeypatch.setattr(
        main.subprocess,
        "run",
        lambda *_args, **_kwargs: type(
            "ProbeResult", (), {"stdout": "duration=30.0\nformat_name=mov,mp4,m4a", "returncode": 0}
        )(),
    )
    assert main.inspect_video(b"video") == 30.0


def test_inspect_video_rejects_duration_over_limit(monkeypatch):
    monkeypatch.setattr(
        main.subprocess,
        "run",
        lambda *_args, **_kwargs: type(
            "ProbeResult", (), {"stdout": "duration=61.0\nformat_name=mov,mp4", "returncode": 0}
        )(),
    )
    with pytest.raises(HTTPException) as error:
        main.inspect_video(b"video")
    assert error.value.status_code == 400


def test_inspect_video_rejects_non_mp4_container(monkeypatch):
    monkeypatch.setattr(
        main.subprocess,
        "run",
        lambda *_args, **_kwargs: type(
            "ProbeResult", (), {"stdout": "duration=10.0\nformat_name=avi", "returncode": 0}
        )(),
    )
    with pytest.raises(HTTPException) as error:
        main.inspect_video(b"video")
    assert error.value.status_code == 400


def test_video_engine_uses_reference_selector_and_restores_audio(tmp_path, monkeypatch):
    engine = main.face_swap_engine
    facefusion_file = tmp_path / "facefusion.py"
    facefusion_file.write_text("# fake FaceFusion entrypoint")
    monkeypatch.setattr(engine, "facefusion_path", facefusion_file)
    monkeypatch.setattr(engine, "is_available", lambda: True)
    calls = []

    def fake_run(command, **_kwargs):
        calls.append(command)
        if command[0] == "python":
            processed = Path(command[command.index("--output-path") + 1])
            processed.write_bytes(b"silent-video")
        else:
            Path(command[-1]).write_bytes(b"video-with-audio")
        return type("ProcessResult", (), {"returncode": 0, "stderr": "", "stdout": ""})()

    monkeypatch.setattr(main.subprocess, "run", fake_run)
    output = tmp_path / "result.mp4"
    result = engine.swap_video(
        b"source-image",
        b"target-video",
        str(output),
        reference_frame_number=27,
        reference_face_position=1,
    )
    assert result == output
    assert output.read_bytes() == b"video-with-audio"
    command = calls[0]
    assert command[command.index("--face-selector-mode") + 1] == "reference"
    assert command[command.index("--face-selector-order") + 1] == "large-small"
    assert command[command.index("--reference-frame-number") + 1] == "27"
    assert command[command.index("--reference-face-position") + 1] == "1"
    assert calls[1][0] == "ffmpeg"
    assert "-map" in calls[1] and "1:a:0?" in calls[1]


def test_inspect_video_accepts_mov_container(monkeypatch):
    monkeypatch.setattr(
        main.subprocess,
        "run",
        lambda *_args, **_kwargs: type(
            "ProbeResult", (), {"stdout": "duration=12.0\\nformat_name=mov", "returncode": 0}
        )(),
    )
    assert main.inspect_video(b"video") == 12.0
