@echo off
REM Flutter Development Environment Setup Script
REM This script sets up Flutter environment for iSuite development

echo ========================================
echo Flutter Environment Setup
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo Flutter not found. Installing Flutter...
    
    REM Create Flutter directory
    if not exist "C:\" mkdir "C:\flutter" 2>nul
    
    echo Please download Flutter from: https://flutter.dev/docs/get-started/install/windows
    echo Extract to C:\flutter and add C:\flutter\bin to PATH
    echo Then run this script again.
    pause
    exit /b 1
)

echo Flutter found. Checking version...
flutter --version
echo.

REM Run Flutter Doctor
echo Running Flutter Doctor...
flutter doctor
echo.

REM Check Android SDK
echo Checking Android SDK...
flutter doctor --android-licenses
echo.

REM Install dependencies
echo Installing project dependencies...
flutter pub get
echo.

REM Run analysis
echo Running code analysis...
flutter analyze
echo.

REM Setup complete
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Run flutter run to start the app
echo 2. Use flutter_diagnostics.bat for regular checks
echo 3. Check FLUTTER_DIAGNOSTICS.md for troubleshooting
echo.

pause
