@echo off
echo iSuite Flutter Windows Runner
echo ==============================
cd /d "%~dp0"

REM Check if PowerShell script exists
if not exist "scripts\run_windows.ps1" (
    echo.
    echo ERROR: PowerShell script not found at scripts\run_windows.ps1
    echo Please ensure the scripts directory exists and contains run_windows.ps1
    pause
    exit /b 1
)

REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "scripts\run_windows.ps1" %*

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to run iSuite
    pause
    exit /b %errorlevel%
)

pause
