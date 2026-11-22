import os
import subprocess
import tempfile
from pathlib import Path


class FaceSwapEngine:

    def __init__(self):
        self.facefusion_path = os.getenv(
            "FACEFUSION_PATH",
            "/opt/facefusion/facefusion.py"
        )

        self.python_path = os.getenv(
            "PYTHON_PATH",
            "python"
        )

    def is_available(self):
        return Path(self.facefusion_path).is_file()

    def swap_faces(self, source_image, target_image, output_path):

        if not self.is_available():
            raise RuntimeError(
                "FaceFusion is not installed on the server"
            )

        with tempfile.TemporaryDirectory() as temp_dir:

            source_path = Path(temp_dir) / "source.jpg"
            target_path = Path(temp_dir) / "target.jpg"

            source_path.write_bytes(source_image)
            target_path.write_bytes(target_image)

            command = [
                self.python_path,
                self.facefusion_path,
                "headless-run",
                "--source-path", str(source_path),
                "--target-path", str(target_path),
                "--output-path", str(output_path),
                "--processors", "face_swapper"
            ]

            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=300
            )

            if result.returncode != 0:
                raise RuntimeError(
                    result.stderr or "FaceFusion processing failed"
                )

            if not Path(output_path).is_file():
                raise RuntimeError(
                    "FaceFusion did not generate an output image"
                )

        return output_path


face_swap_engine = FaceSwapEngine()
