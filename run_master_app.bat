@echo off
REM iSuite Master App Launcher - Windows Batch Script
REM This script launches the Python GUI master app for build and run management

echo ========================================
echo iSuite Master App Launcher
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ and add it to PATH
    pause
    exit /b 1
)

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo WARNING: pubspec.yaml not found in current directory
    echo Make sure you're running this from the Flutter project root
    echo.
)

REM Check if the master app exists
if not exist "isuite_master_app.py" (
    echo ERROR: isuite_master_app.py not found
    echo Make sure the master app file is in the current directory
    pause
    exit /b 1
)

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

echo Starting iSuite Master App...
echo.

REM Run the master app
python isuite_master_app.py

REM Check if the app ran successfully
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Master app exited with error code %errorlevel%
    echo Check the logs directory for detailed error information
    pause
    exit /b 1
)

echo.
echo iSuite Master App closed successfully
pause
