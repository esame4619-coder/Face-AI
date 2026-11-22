import asyncio
import tempfile
from pathlib import Path
from io import BytesIO

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from PIL import Image

from engine import face_swap_engine


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
        "engine_available": face_swap_engine.is_available()
    }


async def validate_image(file: UploadFile):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(400, "Invalid image format")

    data = await file.read(MAX_FILE_SIZE + 1)

    if len(data) > MAX_FILE_SIZE:
        raise HTTPException(413, "Image is too large")

    try:
        image = Image.open(BytesIO(data))
        image.verify()
    except Exception:
        raise HTTPException(400, "Cannot read image")

    return data


@app.post("/api/faceswap")
async def face_swap(
    source: UploadFile = File(...),
    target: UploadFile = File(...)
):
    source_data = await validate_image(source)
    target_data = await validate_image(target)

    if not face_swap_engine.is_available():
        raise HTTPException(
            503,
            "FaceFusion engine is not installed"
        )

    try:
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

        return Response(
            content=result,
            media_type="image/png",
            headers={
                "Content-Disposition":
                "attachment; filename=faceswap.png"
            }
        )

    except Exception as error:
        raise HTTPException(
            500,
            f"Face swap failed: {str(error)}"
        )
