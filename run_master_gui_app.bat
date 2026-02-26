@echo off
REM iSuite Master GUI App Launcher
REM This script launches the Python GUI application for building and running the iSuite Flutter project

echo ============================================
echo     iSuite Master Build & Run GUI App
echo ============================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Python is not installed or not in PATH.
    echo Please install Python 3.7+ from https://python.org
    echo.
    pause
    exit /b 1
)

echo Python found. Starting iSuite Master GUI App...
echo.

REM Change to the script directory (project root)
cd /d "%~dp0"

REM Run the GUI application
python master_gui_app.py

REM If the app exits with an error, show a message
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo The application exited with error code %ERRORLEVEL%
    echo Check the console output above for details.
    echo.
)

echo.
echo Application closed.
pause
