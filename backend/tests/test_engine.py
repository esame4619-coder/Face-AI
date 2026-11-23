from pathlib import Path
import sys
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import engine


def test_face_swap_builds_expected_facefusion_command(tmp_path, monkeypatch):
    script = tmp_path / "facefusion.py"
    script.write_text("# test stub", encoding="utf-8")
    output = tmp_path / "result.png"
    processor = engine.FaceSwapEngine()
    processor.facefusion_path = script
    processor.python_path = "python-test"
    captured = {}

    def fake_run(command, **kwargs):
        captured["command"] = command
        captured["kwargs"] = kwargs
        Path(command[command.index("--output-path") + 1]).write_bytes(b"png-result")
        return SimpleNamespace(returncode=0, stdout="", stderr="")

    monkeypatch.setattr(engine.subprocess, "run", fake_run)
    result = processor.swap_faces(b"source-bytes", b"target-bytes", str(output))

    assert result == output
    assert output.read_bytes() == b"png-result"
    command = captured["command"]
    assert command[:3] == ["python-test", str(script), "headless-run"]
    assert "--source-paths" in command
    assert "--target-path" in command
    assert "--output-path" in command
    assert "--processors" in command
    assert command[command.index("--processors") + 1] == "face_swapper"
    assert captured["kwargs"]["timeout"] == 900
    assert captured["kwargs"]["check"] is False


def test_face_swap_surfaces_facefusion_error(tmp_path, monkeypatch):
    script = tmp_path / "facefusion.py"
    script.write_text("# test stub", encoding="utf-8")
    processor = engine.FaceSwapEngine()
    processor.facefusion_path = script

    monkeypatch.setattr(
        engine.subprocess,
        "run",
        lambda *args, **kwargs: SimpleNamespace(
            returncode=1, stdout="", stderr="FaceFusion test failure"
        ),
    )

    try:
        processor.swap_faces(b"source", b"target", str(tmp_path / "result.png"))
        assert False, "Expected FaceFusion failure to be raised"
    except RuntimeError as error:
        assert "FaceFusion test failure" in str(error)
