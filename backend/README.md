# المحترف في AI — Backend

هذا خادم اختياري ذاتي الاستضافة لمعالجة الصور باستخدام FaceFusion محليًا.
لا توجد مفاتيح API أو خدمات مدفوعة. يحتاج جهاز التشغيل إلى موارد CPU/RAM مناسبة؛
وقد يكون التنفيذ بطيئًا على CPU مقارنةً بـ GPU.

## تشغيل API بدون محرك FaceFusion

من هذا المجلد:

```bash
python -m pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

افحص الحالة من `/health`. سيظهر `engine_available: false` إلى أن تثبّت FaceFusion.

## صورة Docker مع FaceFusion CPU

```bash
docker build -t mohtarif-ai-backend .
docker run --rm -p 8000:8000 mohtarif-ai-backend
```

بناء صورة Docker قد يستغرق وقتًا ومساحة كبيرة بسبب نماذج واعتماديات FaceFusion.
هذا الملف لا ينشئ استضافة مجانية دائمة؛ الخادم يعمل على جهازك أنت ما دام الجهاز
والخدمة قيد التشغيل.

## Endpoints

- `GET /` معلومات الخادم
- `GET /health` حالة API وتوفر المحرك
- `POST /api/faceswap` حقلا رفع صور: `source` و`target`
- `POST /api/enhance` حقل رفع صورة: `image`؛ تحسين أساسي محلي بالتباين والألوان والحدة مع تكبير Lanczos حتى 2x. هذه المعالجة ليست نموذج Super-Resolution بالذكاء الاصطناعي.

استخدم صورًا تملكها أو لديك إذن صريح من أصحابها.
