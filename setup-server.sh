#!/bin/bash
# Run this on your VPS: curl -s https://yourserver.com/setup.sh | bash
set -e

apt update && apt install -y python3 python3-pip
pip3 install fastapi uvicorn python-multipart aiofiles

mkdir -p /opt/cookie-exporter/cookie_data
cat > /opt/cookie-exporter/main.py << 'EOF'
import json, pickle, os
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import FileResponse

app = FastAPI()

UPLOAD_KEY = os.getenv("UPLOAD_KEY", "YOUR_UPLOAD_KEY")
ADMIN_KEY = os.getenv("ADMIN_KEY", "YOUR_ADMIN_KEY")
DATA_DIR = "cookie_data"
os.makedirs(DATA_DIR, exist_ok=True)

@app.post("/api/cookies")
async def upload_cookies(request: Request):
    if request.headers.get("x-api-key") != UPLOAD_KEY:
        raise HTTPException(403, "Forbidden")
    data = await request.json()
    domain = data.get("domain", "unknown")
    with open(os.path.join(DATA_DIR, f"{domain}.json"), "w") as f:
        json.dump(data, f)
    return {"status": "ok", "domain": domain}

@app.get("/api/cookies")
async def download_cookies(request: Request):
    if request.headers.get("x-admin-key") != ADMIN_KEY:
        raise HTTPException(403, "Forbidden")
    all_cookies = {}
    for fname in os.listdir(DATA_DIR):
        if fname.endswith(".json"):
            with open(os.path.join(DATA_DIR, fname)) as f:
                all_cookies[fname.replace(".json", "")] = json.load(f)
    pkl_path = os.path.join(DATA_DIR, "cookies.pkl")
    with open(pkl_path, "wb") as f:
        pickle.dump(all_cookies, f)
    return FileResponse(pkl_path, filename="cookies.pkl", media_type="application/octet-stream")

@app.get("/api/cookies/json")
async def download_cookies_json(request: Request):
    if request.headers.get("x-admin-key") != ADMIN_KEY:
        raise HTTPException(403, "Forbidden")
    all_cookies = {}
    for fname in os.listdir(DATA_DIR):
        if fname.endswith(".json"):
            with open(os.path.join(DATA_DIR, fname)) as f:
                all_cookies[fname.replace(".json", "")] = json.load(f)
    return all_cookies
EOF

cat > /etc/systemd/system/cookie-exporter.service << EOF
[Unit]
Description=Cookie Exporter Server
After=network.target

[Service]
WorkingDirectory=/opt/cookie-exporter
Environment="UPLOAD_KEY=YOUR_UPLOAD_KEY"
Environment="ADMIN_KEY=YOUR_ADMIN_KEY"
ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cookie-exporter
systemctl start cookie-exporter

echo "✅ Server running on port 8000"
echo "Upload key: YOUR_UPLOAD_KEY"
echo "Admin key: YOUR_ADMIN_KEY"
echo "Replace these keys in the script before deploying!"
