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

    def swap_video(self, source_image: bytes, target_video: bytes, output_path: str, reference_frame_number: int = 0, reference_face_position: int = 0):
        """Run FaceFusion on a video target; FaceFusion processes its frames."""
        if not self.is_available():
            raise RuntimeError("FaceFusion is not installed.")
        output = Path(output_path)
        output.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="mohtarif-video-") as temp_dir:
            source_path = Path(temp_dir) / "source.png"
            target_path = Path(temp_dir) / "target.mp4"
            processed_path = Path(temp_dir) / "processed.mp4"
            source_path.write_bytes(source_image)
            target_path.write_bytes(target_video)
            command = [
                self.python_path, str(self.facefusion_path), "headless-run",
                "--source-paths", str(source_path),
                "--target-path", str(target_path),
                "--output-path", str(processed_path),
                "--processors", "face_swapper",
                "--face-selector-mode", "reference",
                "--face-selector-order", "large-small",
                "--reference-frame-number", str(max(0, reference_frame_number)),
                "--reference-face-position", str(max(0, reference_face_position)),
                "--reference-face-distance", "0.3",
                "--face-tracker-score", "0.2",
            ]
            completed = subprocess.run(
                command, capture_output=True, text=True, timeout=3600,
                cwd=str(self.facefusion_path.parent), check=False,
            )
            if completed.returncode != 0:
                detail = (completed.stderr or completed.stdout or "").strip()
                raise RuntimeError(detail[-4000:] or "FaceFusion video processing failed")
            if not processed_path.is_file() or processed_path.stat().st_size == 0:
                raise RuntimeError("FaceFusion finished without creating an MP4 video")

            # Keep the original soundtrack, even when FaceFusion outputs a silent video.
            mux = subprocess.run(
                ["ffmpeg", "-y", "-i", str(processed_path), "-i", str(target_path),
                 "-map", "0:v:0", "-map", "1:a:0?", "-c:v", "copy",
                 "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart",
                 str(output)],
                capture_output=True, text=True, timeout=600, check=False,
            )
            if mux.returncode != 0 or not output.is_file() or output.stat().st_size == 0:
                detail = (mux.stderr or mux.stdout or "").strip()
                raise RuntimeError(detail[-3000:] or "Could not preserve original video audio")
        return output


    def detect_video_faces(self, target_video: bytes) -> dict:
        """Find faces in sampled video frames using FaceFusion's own detector."""
        if not self.is_available():
            raise RuntimeError("FaceFusion is not installed.")
        import json
        import base64

        with tempfile.TemporaryDirectory(prefix="mohtarif-detect-") as temp_dir:
            video_path = Path(temp_dir) / "target.mp4"
            result_path = Path(temp_dir) / "faces.json"
            video_path.write_bytes(target_video)
            helper = r"""
import sys, json, base64, cv2
from pathlib import Path
sys.path.insert(0, str(Path(sys.argv[1]).parent))
from facefusion.program import create_program
from facefusion.args import apply_args
from facefusion import state_manager, face_detector
facefusion_path = Path(sys.argv[1])
video_path = sys.argv[2]
args_list = [
    "headless-run", "--source-paths", video_path, "--target-path", video_path,
    "--output-path", str(Path(video_path).with_name("unused.png")),
    "--processors", "face_swapper", "--face-selector-order", "large-small",
    "--face-detector-model", "yolo_face",
    "--face-detector-size", "640x640", "--face-detector-score", "0.5"
]
parser = create_program()
args = vars(parser.parse_args(args_list))
apply_args(args, state_manager.init_item)
if not face_detector.pre_check():
    raise RuntimeError("FaceFusion face detector models are unavailable")
cap = cv2.VideoCapture(video_path)
fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
if total < 1:
    raise RuntimeError("Cannot read video frames")
sample_indices = sorted(set([0, total // 4, total // 2, (3 * total) // 4, total - 1]))
best = None
for frame_index in sample_indices:
    cap.set(cv2.CAP_PROP_POS_FRAMES, frame_index)
    ok, frame = cap.read()
    if not ok or frame is None:
        continue
    boxes, scores, landmarks = face_detector.detect_faces(frame)
    order = sorted(range(len(boxes)), key=lambda i: float(max(0, boxes[i][2]-boxes[i][0]) * max(0, boxes[i][3]-boxes[i][1])), reverse=True)
    faces = []
    height, width = frame.shape[:2]
    for idx in order:
        x1, y1, x2, y2 = [int(v) for v in boxes[idx]]
        pad_x, pad_y = int((x2-x1)*0.22), int((y2-y1)*0.22)
        x1, y1 = max(0, x1-pad_x), max(0, y1-pad_y)
        x2, y2 = min(width, x2+pad_x), min(height, y2+pad_y)
        crop = frame[y1:y2, x1:x2]
        if crop.size:
            ok, encoded = cv2.imencode(".jpg", crop, [int(cv2.IMWRITE_JPEG_QUALITY), 88])
            if ok:
                faces.append({"image": base64.b64encode(encoded.tobytes()).decode("ascii"), "score": float(scores[idx])})
    if faces and (best is None or len(faces) > len(best["faces"])):
        best = {"reference_frame_number": int(frame_index), "reference_time_seconds": round(frame_index / fps, 3), "faces": faces}
cap.release()
print(json.dumps(best or {"reference_frame_number": 0, "reference_time_seconds": 0, "faces": []}))
"""
            completed = subprocess.run(
                [self.python_path, "-c", helper, str(self.facefusion_path), str(video_path)],
                capture_output=True, text=True, timeout=600,
                cwd=str(self.facefusion_path.parent), check=False,
            )
            if completed.returncode != 0:
                detail = (completed.stderr or completed.stdout or "").strip()
                raise RuntimeError(detail[-3000:] or "Face detection failed")
            try:
                result = json.loads(completed.stdout.strip().splitlines()[-1])
            except Exception as exc:
                raise RuntimeError("FaceFusion returned invalid face detection data") from exc
            if not result.get("faces"):
                raise RuntimeError("لم يتم العثور على وجوه واضحة في الفيديو.")
            return result



face_swap_engine = FaceSwapEngine()
