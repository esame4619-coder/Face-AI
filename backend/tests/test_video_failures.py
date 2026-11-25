"""Failure-path coverage for the video API."""
from fastapi.testclient import TestClient
from fastapi import HTTPException
import main


client = TestClient(main.app)


def test_video_face_detection_returns_service_unavailable_when_no_faces(monkeypatch):
    monkeypatch.delenv("WORKERS_JSON", raising=False)
    monkeypatch.delenv("API_KEY", raising=False)
    monkeypatch.setattr(main, "inspect_video", lambda _data: 3.0)

    def no_faces(_data):
        raise RuntimeError("لم يتم العثور على وجوه واضحة في الفيديو.")

    monkeypatch.setattr(main.face_swap_engine, "detect_video_faces", no_faces)
    response = client.post(
        "/api/video-faces",
        files={"target_video": ("clip.mp4", b"valid-video", "video/mp4")},
    )
    assert response.status_code == 503
    assert "تعذر اكتشاف الوجوه" in response.json()["detail"]


def test_inspect_video_maps_ffprobe_failure_to_bad_request(monkeypatch):
    def failed_probe(*_args, **_kwargs):
        raise main.subprocess.CalledProcessError(1, ["ffprobe"], stderr="invalid data")

    monkeypatch.setattr(main.subprocess, "run", failed_probe)
    try:
        main.inspect_video(b"not-a-real-video")
    except HTTPException as error:
        assert error.status_code == 400
        assert "MP4" in error.detail
    else:
        raise AssertionError("Expected invalid video to be rejected")
