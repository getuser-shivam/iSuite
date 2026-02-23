@echo off
title iSuite Master App Launcher
echo ========================================
echo    iSuite Master App - Enhanced
echo ========================================
echo.
echo Starting Python GUI application...
echo.

REM Check if Python is installed
py --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ and add to PATH
    pause
    exit /b 1
)

REM Check if master app exists
if not exist "master_app_enhanced.py" (
    echo ERROR: master_app_enhanced.py not found
    echo Please ensure the file exists in the current directory
    pause
    exit /b 1
)

REM Run the enhanced master app
echo Launching iSuite Master App...
py master_app_enhanced.py

if %errorlevel% neq 0 (
    echo.
    echo Application exited with error code: %errorlevel%
    pause
) else (
    echo.
    echo Application closed successfully
)

echo.
pause
