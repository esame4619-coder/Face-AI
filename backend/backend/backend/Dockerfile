FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install FaceFusion 3.9.2
RUN git clone --depth 1 --branch 3.9.2 \
    https://github.com/facefusion/facefusion.git \
    /opt/facefusion

WORKDIR /opt/facefusion

# Install CPU runtime
RUN python install.py --onnxruntime default

# Install application backend
WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV FACEFUSION_PATH=/opt/facefusion/facefusion.py
ENV PYTHON_PATH=python

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
