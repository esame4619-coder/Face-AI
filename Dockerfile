# Hugging Face Spaces Docker image (CPU-only, free hardware compatible)
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=7860

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ffmpeg libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 libgomp1 \
    ca-certificates build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch 3.9.2 \
    https://github.com/facefusion/facefusion.git /opt/facefusion

WORKDIR /opt/facefusion
RUN python install.py default --skip-conda \
    && python -m pip install --no-cache-dir -r requirements.txt onnxruntime==1.31.0 opencv-python-headless==5.0.0.93

WORKDIR /app
COPY backend/requirements.txt .
RUN pip install -r requirements.txt
COPY backend/ .

ENV FACEFUSION_PATH=/opt/facefusion/facefusion.py
ENV PYTHON_PATH=python
EXPOSE 7860
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-7860}"]
