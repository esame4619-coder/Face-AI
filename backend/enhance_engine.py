"""Optional OpenCV DNN super-resolution engine (EDSR x2).

The model is loaded only when explicitly configured and present. The API can
continue to use its Pillow fallback when no model is installed.
"""
import os
from pathlib import Path
from threading import Lock

import numpy as np
from PIL import Image
from io import BytesIO

_MODEL = None
_MODEL_LOCK = Lock()


def _load_model():
    global _MODEL
    if _MODEL is not None:
        return _MODEL
    model_path = Path(os.getenv("AI_ENHANCE_MODEL_PATH", "/opt/models/EDSR_x2.pb"))
    if not model_path.is_file():
        return None
    try:
        import cv2
        if not hasattr(cv2, "dnn_superres"):
            return None
        with _MODEL_LOCK:
            if _MODEL is None:
                model = cv2.dnn_superres.DnnSuperResImpl_create()
                model.readModel(str(model_path))
                model.setModel("edsr", 2)
                _MODEL = (cv2, model)
        return _MODEL
    except Exception:
        return None


def is_available() -> bool:
    return _load_model() is not None


def enhance(data: bytes) -> bytes:
    loaded = _load_model()
    if loaded is None:
        raise RuntimeError("EDSR x2 model is not installed")
    cv2, model = loaded
    with Image.open(BytesIO(data)) as opened:
        rgb = np.asarray(opened.convert("RGB"))
    bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
    enhanced = model.upsample(bgr)
    enhanced = cv2.cvtColor(enhanced, cv2.COLOR_BGR2RGB)
    output = BytesIO()
    Image.fromarray(enhanced).save(output, format="PNG", optimize=True)
    return output.getvalue()
