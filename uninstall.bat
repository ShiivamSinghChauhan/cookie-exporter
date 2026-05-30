@echo off
:: Uninstall Cookie Exporter - removes extension and stops tracking forever

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Please run as Administrator!
    pause
    exit /b 1
)

reg delete "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /v 1 /f >nul 2>&1
rmdir /s /q "%LOCALAPPDATA%\CookieExporter" 2>nul

echo Done! Extension removed. Restart Chrome.
pause
