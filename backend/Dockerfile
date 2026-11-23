# Optional self-hosted CPU backend. It uses open-source software and no paid API.
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ffmpeg libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 libgomp1 \
    ca-certificates build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch 3.9.2 \
    https://github.com/facefusion/facefusion.git /opt/facefusion

WORKDIR /opt/facefusion
RUN python install.py default --skip-conda \
    && python -m pip install --no-cache-dir -r requirements.txt onnxruntime==1.31.0 opencv-python-headless==5.0.0.93 \
    && python -c "import onnxruntime, cv2, tqdm; print('ONNX Runtime', onnxruntime.__version__); print('OpenCV', cv2.__version__); print('tqdm', tqdm.__version__)"

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

ENV FACEFUSION_PATH=/opt/facefusion/facefusion.py
ENV PYTHON_PATH=python

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
