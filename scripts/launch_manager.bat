@echo off
REM iSuite Master Build & Run Manager Launcher (Windows)
REM This batch file launches the Python GUI application for managing Flutter builds

echo 🚀 Starting iSuite Master Build & Run Manager...

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python is not installed or not in PATH.
    echo    Please install Python 3 first.
    pause
    exit /b 1
)

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ This doesn't appear to be a Flutter project directory.
    echo    Please run this script from the iSuite project root.
    pause
    exit /b 1
)

REM Check if the manager script exists
if not exist "scripts\isuite_manager.py" (
    echo ❌ isuite_manager.py not found in scripts directory.
    pause
    exit /b 1
)

REM Install required Python packages if needed
echo 📦 Checking Python dependencies...
python -c "import tkinter, sqlite3, requests" >nul 2>&1
if %errorlevel% neq 0 (
    echo 📦 Installing required Python packages...
    pip install requests
)

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

REM Launch the manager
echo 🎯 Launching iSuite Manager...
python scripts\isuite_manager.py

REM Check if the manager exited successfully
if %errorlevel% equ 0 (
    echo ✅ iSuite Manager closed successfully.
) else (
    echo ❌ iSuite Manager encountered an error.
    echo    Check logs\isuite_manager.log for details.
)

echo 👋 Done!
pause
