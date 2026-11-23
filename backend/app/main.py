import asyncio
import tempfile
from io import BytesIO
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from PIL import Image

from .engine import face_swap_engine

app = FastAPI(
    title="Al Mohtarif AI Engine",
    description="AI processing API for the Al Mohtarif AI app",
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

MAX_IMAGE_BYTES = 15 * 1024 * 1024


@app.get("/")
async def home():
    return {"app": "المحترف في AI", "status": "running"}


@app.get("/health")
async def health():
    available = face_swap_engine.is_available()
    return {
        "status": "online",
        "engine": "FaceFusion",
        "engine_available": available,
    }


async def read_valid_image(file: UploadFile) -> bytes:
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=415, detail="Invalid image format")
    data = await file.read(MAX_IMAGE_BYTES + 1)
    if not data:
        raise HTTPException(status_code=400, detail="Empty image")
    if len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="Image exceeds 15 MB")
    try:
        with Image.open(BytesIO(data)) as image:
            image.verify()
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Unreadable image") from exc
    return data


@app.post("/api/faceswap")
async def face_swap(
    source: UploadFile = File(...),
    target: UploadFile = File(...),
):
    source_data, target_data = await asyncio.gather(
        read_valid_image(source), read_valid_image(target)
    )
    if not face_swap_engine.is_available():
        raise HTTPException(
            status_code=503,
            detail="FaceFusion engine is not installed on this worker",
        )

    try:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "faceswap.png"
            await asyncio.to_thread(
                face_swap_engine.swap_faces,
                source_data,
                target_data,
                str(output_path),
            )
            if not output_path.is_file():
                raise RuntimeError("No output image was generated")
            result = output_path.read_bytes()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Face swap failed: {exc}") from exc

    return Response(
        content=result,
        media_type="image/png",
        headers={"Content-Disposition": 'attachment; filename="faceswap.png"'},
    )
