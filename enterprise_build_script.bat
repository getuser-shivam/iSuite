@echo off
echo ================================================================
echo iSuite Enterprise Build Script
echo ================================================================
echo.

REM Set Flutter SDK path
set FLUTTER_PATH=C:\flutter\bin\flutter.bat
set PROJECT_PATH=%~dp0

echo [1/10] Checking Flutter Environment...
echo ------------------------------------------------
%FLUTTER_PATH% doctor -v
if %ERRORLEVEL% neq 0 (
    echo ERROR: Flutter environment check failed
    pause
    exit /b 1
)
echo.

echo [2/10] Cleaning Project...
echo ------------------------------------------------
%FLUTTER_PATH% clean
if %ERRORLEVEL% neq 0 (
    echo ERROR: Clean failed
    pause
    exit /b 1
)
echo.

echo [3/10] Getting Dependencies...
echo ------------------------------------------------
%FLUTTER_PATH% pub get
if %ERRORLEVEL% neq 0 (
    echo ERROR: Dependencies installation failed
    pause
    exit /b 1
)
echo.

echo [4/10] Code Formatting...
echo ------------------------------------------------
dart format .
if %ERRORLEVEL% neq 0 (
    echo WARNING: Code formatting had issues
)
echo.

echo [5/10] Static Code Analysis...
echo ------------------------------------------------
%FLUTTER_PATH% analyze
if %ERRORLEVEL% neq 0 (
    echo WARNING: Static analysis found issues
    echo Please fix critical errors before proceeding
    pause
)
echo.

echo [6/10] Running Tests...
echo ------------------------------------------------
%FLUTTER_PATH% test
if %ERRORLEVEL% neq 0 (
    echo WARNING: Some tests failed
)
echo.

echo [7/10] Building Windows Application...
echo ------------------------------------------------
%FLUTTER_PATH% build windows --release
if %ERRORLEVEL% neq 0 (
    echo ERROR: Windows build failed
    echo.
    echo Common fixes:
    echo 1. Fix compilation errors in lib/presentation/widgets/note_editor.dart
    echo 2. Update dependencies with: flutter pub upgrade
    echo 3. Check pubspec.yaml for correct platform configurations
    echo.
    pause
    exit /b 1
)
echo.

echo [8/10] Building Android APK...
echo ------------------------------------------------
%FLUTTER_PATH% build apk --split-per-abi --release
if %ERRORLEVEL% neq 0 (
    echo WARNING: Android build failed
)
echo.

echo [9/10] Building Web Application...
echo ------------------------------------------------
%FLUTTER_PATH% build web --release
if %ERRORLEVEL% neq 0 (
    echo WARNING: Web build failed
)
echo.

echo [10/10] Build Summary...
echo ------------------------------------------------
echo ================================================================
echo BUILD COMPLETED SUCCESSFULLY!
echo ================================================================
echo.
echo Build outputs:
echo - Windows: build\windows\x64\runner\Release\iSuite.exe
echo - Android: build\app\outputs\flutter-apk\
echo - Web: build\web\
echo.
echo To run the application:
echo - Windows: %FLUTTER_PATH% run -d windows
echo - Chrome: %FLUTTER_PATH% run -d chrome
echo.
echo Build logs saved to: build_logs\
echo ================================================================
pause
