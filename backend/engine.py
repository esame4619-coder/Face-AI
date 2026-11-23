import os
import subprocess
import tempfile
from pathlib import Path


class FaceSwapEngine:
    """Runs the locally installed FaceFusion CLI; no paid API is used."""

    def __init__(self):
        self.facefusion_path = Path(
            os.getenv("FACEFUSION_PATH", "/opt/facefusion/facefusion.py")
        )
        self.python_path = os.getenv("PYTHON_PATH", "python")

    def is_available(self):
        return self.facefusion_path.is_file()

    def swap_faces(self, source_image: bytes, target_image: bytes, output_path: str):
        if not self.is_available():
            raise RuntimeError(
                "FaceFusion is not installed. Configure FACEFUSION_PATH on your own machine."
            )

        output = Path(output_path)
        output.parent.mkdir(parents=True, exist_ok=True)

        with tempfile.TemporaryDirectory(prefix="mohtarif-faceswap-") as temp_dir:
            source_path = Path(temp_dir) / "source.png"
            target_path = Path(temp_dir) / "target.png"
            source_path.write_bytes(source_image)
            target_path.write_bytes(target_image)

            command = [
                self.python_path,
                str(self.facefusion_path),
                "headless-run",
                "--source-paths", str(source_path),
                "--target-path", str(target_path),
                "--output-path", str(output),
                "--processors", "face_swapper",
            ]
            completed = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=900,
                cwd=str(self.facefusion_path.parent),
                check=False,
            )
            if completed.returncode != 0:
                detail = (completed.stderr or completed.stdout or "").strip()
                raise RuntimeError(detail[-4000:] or "FaceFusion processing failed")

            if not output.is_file() or output.stat().st_size == 0:
                raise RuntimeError("FaceFusion finished without creating an output image")

        return output


face_swap_engine = FaceSwapEngine()
