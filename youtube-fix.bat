@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0_payload\core.ps1" -PayloadId "run"
if errorlevel 1 (
  echo.
  echo [ERROR] Ne udalos zapustit. Zapustite ot imeni administratora.
  pause
)
