@echo off
REM iSuite Comprehensive Master App Launcher
REM This batch file runs the comprehensive master app for build and run operations

echo ========================================
echo iSuite Comprehensive Master App v4.0
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH.
    echo.
    echo Please install Python from: https://www.python.org/downloads/
    echo Or ensure Python is added to your system PATH.
    echo.
    echo Alternative: Run the app directly with full Python path:
    echo "C:\Python\python.exe" isuite_master_app_comprehensive.py
    pause
    exit /b 1
)

echo Python found. Starting iSuite Comprehensive Master App...
echo.

REM Change to the script directory
cd /d "%~dp0"

REM Run the comprehensive master app
python isuite_master_app_comprehensive.py

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to start the application.
    echo Error code: %errorlevel%
    echo.
    echo Please check the console output above for details.
    pause
)
