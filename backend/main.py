import asyncio
import os
import secrets
import tempfile
import subprocess
from pathlib import Path
from io import BytesIO

from fastapi import FastAPI, UploadFile, File, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from PIL import Image, ImageEnhance, ImageFilter, ImageOps

from engine import face_swap_engine
from worker_pool import dispatch_faceswap, dispatch_video_faceswap, pool_status


app = FastAPI(
    title="Al Mohtarif AI Engine",
    description="Private AI Processing Server",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

MAX_FILE_SIZE = 15 * 1024 * 1024
MAX_IMAGE_PIXELS = 25_000_000


async def verify_api_key(authorization: str | None = Header(default=None)):
    expected = os.getenv('API_KEY', '').strip()
    if expected:
        supplied = authorization or ''
        if not secrets.compare_digest(supplied, f'Bearer {expected}'):
            raise HTTPException(status_code=401, detail='مفتاح الوصول غير صحيح أو غير موجود.')


@app.get("/")
async def home():
    return {
        "app": "المحترف في AI",
        "status": "running"
    }


@app.get("/health")
async def health():
    return {
        "status": "online",
        "engine": "FaceFusion",
        "engine_available": face_swap_engine.is_available(),
        "worker_pool_configured": bool(os.getenv("WORKERS_JSON", "").strip()),
    }


@app.get("/pool/status")
async def worker_pool_status(_auth: None = Depends(verify_api_key)):
    try:
        return await pool_status()
    except Exception as error:
        raise HTTPException(503, "Could not read worker pool status")


async def validate_image(file: UploadFile):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(400, "Invalid image format")

    data = await file.read(MAX_FILE_SIZE + 1)

    if len(data) > MAX_FILE_SIZE:
        raise HTTPException(413, "Image is too large")

    try:
        with Image.open(BytesIO(data)) as image:
            width, height = image.size
            if width < 1 or height < 1 or width * height > MAX_IMAGE_PIXELS:
                raise HTTPException(413, "Image dimensions are too large")
            image.verify()
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(400, "Cannot read image")

    return data


@app.post("/api/enhance")
async def enhance_image(image: UploadFile = File(...), _auth: None = Depends(verify_api_key)):
    """Basic local enhancement: orientation correction, gentle contrast/color,
    sharpening and 2x Lanczos enlargement. This is not an AI super-resolution model.
    """
    data = await validate_image(image)
    try:
        with Image.open(BytesIO(data)) as opened:
            processed = ImageOps.exif_transpose(opened).convert("RGB")

        width, height = processed.size
        if width < 1 or height < 1 or width * height > 25_000_000:
            raise HTTPException(413, "Image dimensions are too large")

        processed = ImageEnhance.Contrast(processed).enhance(1.08)
        processed = ImageEnhance.Color(processed).enhance(1.06)
        processed = ImageEnhance.Sharpness(processed).enhance(1.25)
        processed = processed.filter(
            ImageFilter.UnsharpMask(radius=1.4, percent=115, threshold=3)
        )

        scale = min(2.0, 4096 / max(width, height))
        if scale > 1:
            processed = processed.resize(
                (max(1, int(width * scale)), max(1, int(height * scale))),
                Image.Resampling.LANCZOS,
            )

        output = BytesIO()
        processed.save(output, format="PNG", optimize=True)
        return Response(
            content=output.getvalue(),
            media_type="image/png",
            headers={"Content-Disposition": "attachment; filename=enhanced.png"},
        )
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(400, "Could not enhance this image")


@app.post("/api/faceswap")
async def face_swap(
    source: UploadFile = File(...),
    target: UploadFile = File(...),
    _auth: None = Depends(verify_api_key)
):
    source_data = await validate_image(source)
    target_data = await validate_image(target)

    try:
        if os.getenv("WORKERS_JSON", "").strip():
            result, worker_name = await dispatch_faceswap(source_data, target_data)
        else:
            if not face_swap_engine.is_available():
                raise HTTPException(503, "FaceFusion engine is not installed and no remote workers are configured")
            with tempfile.TemporaryDirectory() as temp_dir:
                output_path = Path(temp_dir) / "faceswap.png"
                await asyncio.to_thread(
                    face_swap_engine.swap_faces,
                    source_data,
                    target_data,
                    str(output_path)
                )
                if not output_path.exists():
                    raise RuntimeError("Output image was not generated")
                result = output_path.read_bytes()
            worker_name = "local"

        return Response(
            content=result,
            media_type="image/png",
            headers={
                "Content-Disposition": "attachment; filename=faceswap.png",
                "X-Worker-Name": worker_name,
            }
        )

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(503, "Face swap is temporarily unavailable")


MAX_VIDEO_SIZE = 200 * 1024 * 1024
MAX_VIDEO_DURATION = 120.0


def inspect_video(data: bytes) -> float:
    """Validate MP4 container and enforce the agreed 1–120 second duration."""
    with tempfile.NamedTemporaryFile(suffix=".mp4") as temp:
        temp.write(data)
        temp.flush()
        try:
            probe = subprocess.run(
                ["ffprobe", "-v", "error", "-show_entries", "format=duration,format_name",
                 "-of", "default=noprint_wrappers=1", temp.name],
                capture_output=True, text=True, timeout=20, check=True,
            )
            values = dict(
                line.split("=", 1) for line in probe.stdout.splitlines() if "=" in line
            )
            duration = float(values.get("duration", "0"))
            formats = values.get("format_name", "")
            if "mp4" not in formats and "mov" not in formats:
                raise ValueError("not an MP4 container")
            if duration < 1.0 or duration > MAX_VIDEO_DURATION:
                raise ValueError("duration outside allowed range")
            return duration
        except (subprocess.SubprocessError, ValueError, OSError):
            raise HTTPException(400, "الفيديو لازم يكون MP4 ومدته من ثانية إلى 120 ثانية.") from None


@app.post("/api/faceswap-video")
async def face_swap_video(
    source: UploadFile = File(...),
    target_video: UploadFile = File(...),
    _auth: None = Depends(verify_api_key),
):
    """Swap a source face into an MP4 video using the installed FaceFusion engine."""
    if source.content_type and not source.content_type.startswith("image/"):
        raise HTTPException(400, "ملف الوجه الأصلي لازم يكون صورة.")
    if target_video.content_type not in {"video/mp4", "application/mp4", "video/quicktime"}:
        raise HTTPException(400, "صيغة الفيديو المدعومة هي MP4 فقط.")

    source_data = await validate_image(source)
    video_data = await target_video.read(MAX_VIDEO_SIZE + 1)
    if not video_data:
        raise HTTPException(400, "ملف الفيديو فارغ.")
    if len(video_data) > MAX_VIDEO_SIZE:
        raise HTTPException(413, "الحد الأقصى لحجم الفيديو 200 ميجابايت.")
    inspect_video(video_data)

    try:
        if os.getenv("WORKERS_JSON", "").strip():
            result, worker_name = await dispatch_video_faceswap(source_data, video_data)
        else:
            if not face_swap_engine.is_available():
                raise HTTPException(503, "محرك FaceFusion غير مثبت ولا توجد سيرفرات معالجة مرتبطة.")
            with tempfile.TemporaryDirectory() as temp_dir:
                output_path = Path(temp_dir) / "faceswap_video.mp4"
                await asyncio.to_thread(
                    face_swap_engine.swap_video,
                    source_data,
                    video_data,
                    str(output_path),
                )
                if not output_path.is_file():
                    raise RuntimeError("Video output was not generated")
                result = output_path.read_bytes()
            worker_name = "local"

        return Response(
            content=result,
            media_type="video/mp4",
            headers={
                "Content-Disposition": 'attachment; filename="faceswap.mp4"',
                "X-Worker-Name": worker_name,
            },
        )
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(503, "تعذرت معالجة الفيديو حاليًا. تأكد من جاهزية محرك FaceFusion والسيرفر.")
