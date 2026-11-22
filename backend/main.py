from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from io import BytesIO

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
        "engine": "not_configured",
        "message": "AI server is ready"
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

    raise HTTPException(
        status_code=503,
        detail="Face swap engine is not installed yet"
    )
