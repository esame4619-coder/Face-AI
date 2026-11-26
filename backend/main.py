import asyncio
import logging
import os
import secrets
import tempfile
import subprocess
from pathlib import Path
from io import BytesIO

from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from PIL import Image, ImageEnhance, ImageFilter, ImageOps

from engine import face_swap_engine
from enhance_engine import is_available as ai_enhance_available, enhance as ai_enhance
from worker_pool import dispatch_faceswap, dispatch_video_faceswap, dispatch_video_face_detection, pool_status


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

logger = logging.getLogger("mohtarif.faceswap")


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
        "ai_enhance_available": ai_enhance_available(),
    }


@app.get("/pool/status")
async def worker_pool_status(_auth: None = Depends(verify_api_key)):
    try:
        return await pool_status()
    except Exception as error:
        raise HTTPException(503, "Could not read worker pool status")


async def validate_image(file: UploadFile):
    # Do not trust the multipart Content-Type header: some Android gallery
    # providers send valid photos as application/octet-stream. Validate the
    # actual file bytes with Pillow below instead.
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
    """Use EDSR x2 super-resolution when installed; otherwise safe Pillow enhancement."""
    data = await validate_image(image)
    if ai_enhance_available():
        try:
            result = await asyncio.to_thread(ai_enhance, data)
            return Response(
                content=result,
                media_type="image/png",
                headers={
                    "Content-Disposition": "attachment; filename=enhanced-ai.png",
                    "X-Enhancement-Engine": "EDSR-x2",
                },
            )
        except Exception:
            logger.exception("EDSR AI enhancement failed; falling back to Pillow")
    try:
        with Image.open(BytesIO(data)) as opened:
            processed = ImageOps.exif_transpose(opened).convert("RGB")
        width, height = processed.size
        if width < 1 or height < 1 or width * height > MAX_IMAGE_PIXELS:
            raise HTTPException(413, "Image dimensions are too large")
        processed = ImageEnhance.Contrast(processed).enhance(1.08)
        processed = ImageEnhance.Color(processed).enhance(1.06)
        processed = ImageEnhance.Sharpness(processed).enhance(1.25)
        processed = processed.filter(ImageFilter.UnsharpMask(radius=1.4, percent=115, threshold=3))
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
            headers={
                "Content-Disposition": "attachment; filename=enhanced.png",
                "X-Enhancement-Engine": "Pillow-fallback",
            },
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
    except Exception:
        # Keep the detailed traceback in the server log; never expose internals to the app client.
        logger.exception("Face swap processing failed")
        raise HTTPException(503, "Face swap is temporarily unavailable")


MAX_VIDEO_SIZE = 100 * 1024 * 1024
MAX_VIDEO_DURATION = 60.0


def inspect_video(data: bytes) -> float:
    """Validate an MP4/MOV container and enforce the 1–60 second duration."""
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
            raise HTTPException(400, "الفيديو لازم يكون MP4 أو MOV ومدته من ثانية إلى 60 ثانية.") from None



@app.post("/api/video-faces")
async def detect_video_faces(
    target_video: UploadFile = File(...),
    _auth: None = Depends(verify_api_key),
):
    """Return selectable face thumbnails from the sampled frame with most detected faces.

    Detection is a preparation step for one video-swap job, so it intentionally
    does not consume a second worker quota slot.
    """
    if target_video.content_type not in {"video/mp4", "application/mp4", "video/quicktime"}:
        raise HTTPException(400, "صيغة الفيديو المدعومة هي MP4 أو MOV.")
    video_data = await target_video.read(MAX_VIDEO_SIZE + 1)
    if not video_data:
        raise HTTPException(400, "ملف الفيديو فارغ.")
    if len(video_data) > MAX_VIDEO_SIZE:
        raise HTTPException(413, "الحد الأقصى لحجم الفيديو 100 ميجابايت.")
    inspect_video(video_data)
    try:
        if os.getenv("WORKERS_JSON", "").strip():
            result, worker_name = await dispatch_video_face_detection(video_data)
        else:
            result = await asyncio.to_thread(face_swap_engine.detect_video_faces, video_data)
            worker_name = "local"
        result["worker"] = worker_name
        return result
    except HTTPException:
        raise
    except Exception:
        logger.exception("Video face detection failed")
        raise HTTPException(503, "تعذر اكتشاف الوجوه في الفيديو. تأكد من جاهزية محرك FaceFusion.")

@app.post("/api/faceswap-video")
async def face_swap_video(
    source: UploadFile = File(...),
    target_video: UploadFile = File(...),
    reference_frame_number: int = Form(default=0, ge=0),
    reference_face_position: int = Form(default=0, ge=0),
    _auth: None = Depends(verify_api_key),
):
    """Swap a source face into the selected person in an MP4 video."""
    if source.content_type and not source.content_type.startswith("image/"):
        raise HTTPException(400, "ملف الوجه الأصلي لازم يكون صورة.")
    if target_video.content_type not in {"video/mp4", "application/mp4", "video/quicktime"}:
        raise HTTPException(400, "صيغة الفيديو المدعومة هي MP4 أو MOV.")

    source_data = await validate_image(source)
    video_data = await target_video.read(MAX_VIDEO_SIZE + 1)
    if not video_data:
        raise HTTPException(400, "ملف الفيديو فارغ.")
    if len(video_data) > MAX_VIDEO_SIZE:
        raise HTTPException(413, "الحد الأقصى لحجم الفيديو 100 ميجابايت.")
    inspect_video(video_data)

    try:
        if os.getenv("WORKERS_JSON", "").strip():
            result, worker_name = await dispatch_video_faceswap(source_data, video_data, reference_frame_number, reference_face_position)
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
                    reference_frame_number,
                    reference_face_position,
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
        logger.exception("Video face swap processing failed")
        raise HTTPException(503, "تعذرت معالجة الفيديو حاليًا. تأكد من جاهزية محرك FaceFusion والسيرفر.")


MAX_AUDIO_SIZE = 30 * 1024 * 1024
MAX_AUDIO_DURATION = 600.0


def inspect_audio(data: bytes) -> float:
    """Validate a decodable audio file and enforce a ten-minute duration."""
    with tempfile.NamedTemporaryFile(suffix=".audio") as temp:
        temp.write(data)
        temp.flush()
        try:
            probe = subprocess.run(
                ["ffprobe", "-v", "error", "-select_streams", "a:0",
                 "-show_entries", "stream=codec_type:format=duration",
                 "-of", "default=noprint_wrappers=1", temp.name],
                capture_output=True, text=True, timeout=20, check=True,
            )
            values = dict(line.split("=", 1) for line in probe.stdout.splitlines() if "=" in line)
            duration = float(values.get("duration", "0"))
            if values.get("codec_type") != "audio" or not 0 < duration <= MAX_AUDIO_DURATION:
                raise ValueError("invalid audio stream or duration")
            return duration
        except (subprocess.SubprocessError, ValueError, OSError):
            raise HTTPException(400, "ملف صوتي غير صالح أو مدته أكبر من 10 دقائق.") from None


@app.post("/api/change-voice")
async def change_voice(
    audio: UploadFile = File(...),
    voice_type: str = Form(...),
    accent: str = Form(default="محايد"),
    _auth: None = Depends(verify_api_key),
):
    """Apply offline pitch and EQ effects with FFmpeg; this does not change spoken language or clone identity."""
    if voice_type not in {"رجل", "امرأة", "طفل"}:
        raise HTTPException(400, "نوع الصوت غير مدعوم.")
    accent_filters = {
        "محايد": "anull",
        "مصري": "equalizer=f=180:t=q:w=1:g=1.5,equalizer=f=2500:t=q:w=1:g=1.0",
        "خليجي": "equalizer=f=300:t=q:w=1:g=1.0,equalizer=f=4500:t=q:w=1:g=1.2",
        "فصحى": "equalizer=f=220:t=q:w=1:g=0.8,equalizer=f=3200:t=q:w=1:g=1.4",
        "إنجليزي أمريكي": "equalizer=f=150:t=q:w=1:g=1.0,equalizer=f=2800:t=q:w=1:g=1.0",
        "إنجليزي بريطاني": "equalizer=f=180:t=q:w=1:g=0.8,equalizer=f=3600:t=q:w=1:g=1.0",
    }
    if accent not in accent_filters:
        raise HTTPException(400, "طابع المعالجة الصوتية غير مدعوم.")
    data = await audio.read(MAX_AUDIO_SIZE + 1)
    if not data:
        raise HTTPException(400, "ملف الصوت فارغ.")
    if len(data) > MAX_AUDIO_SIZE:
        raise HTTPException(413, "الحد الأقصى لحجم الصوت 30 ميجابايت.")
    inspect_audio(data)
    # A moderate resampling shift preserves duration via atempo. This is a
    # lightweight offline effect; it does not synthesize a new speaker identity.
    pitch = {"رجل": 0.88, "امرأة": 1.12, "طفل": 1.24}[voice_type]
    with tempfile.TemporaryDirectory(prefix="mohtarif-voice-") as temp_dir:
        input_path = Path(temp_dir) / "input.audio"
        output_path = Path(temp_dir) / "changed-voice.mp3"
        input_path.write_bytes(data)
        sample_rate = 48000
        filter_chain = (
            f"asetrate={int(sample_rate * pitch)},aresample={sample_rate},"
            f"atempo={1.0 / pitch:.6f},highpass=f=80,lowpass=f=12000,{accent_filters[accent]}"
        )
        try:
            completed = await asyncio.to_thread(
                subprocess.run,
                ["ffmpeg", "-y", "-v", "error", "-i", str(input_path),
                 "-vn", "-af", filter_chain, "-codec:a", "libmp3lame",
                 "-b:a", "192k", str(output_path)],
                capture_output=True, text=True, timeout=300, check=False,
            )
            if completed.returncode != 0 or not output_path.is_file() or output_path.stat().st_size == 0:
                logger.error("FFmpeg voice effect failed: %s", (completed.stderr or "")[-2000:])
                raise RuntimeError("FFmpeg voice effect failed")
            return Response(
                content=output_path.read_bytes(), media_type="audio/mpeg",
                headers={"Content-Disposition": 'attachment; filename="changed-voice.mp3"'},
            )
        except HTTPException:
            raise
        except Exception:
            logger.exception("Voice effect processing failed")
            raise HTTPException(503, "تعذر تحويل الصوت. تأكد من جاهزية خادم FFmpeg.") from None
