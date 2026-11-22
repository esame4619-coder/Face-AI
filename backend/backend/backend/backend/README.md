# Al Mohtarif AI Backend

Private AI processing server for Al Mohtarif AI Android application.

## Technologies
- Python 3.11
- FastAPI
- Uvicorn
- Pillow

## API Endpoints

- GET / : Server information
- GET /health : Server health status
- POST /api/faceswap : Face swap processing endpoint

## Run locally

Install dependencies:

pip install -r requirements.txt

Start server:

uvicorn main:app --host 0.0.0.0 --port 8000

API documentation:

http://localhost:8000/docs
