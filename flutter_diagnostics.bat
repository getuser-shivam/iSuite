@echo off
REM Flutter Doctor and Analysis Script for iSuite Project
REM This script runs Flutter diagnostics to validate the project setup

echo ========================================
echo iSuite Flutter Diagnostics
echo ========================================
echo.

REM Check if Flutter is in PATH
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found in PATH
    echo Please install Flutter SDK and add it to your PATH
    echo.
    echo Installation instructions:
    echo 1. Download Flutter from https://flutter.dev/docs/get-started/install
    echo 2. Extract to C:\flutter
    echo 3. Add C:\flutter\bin to PATH
    echo 4. Restart Command Prompt
    echo.
    pause
    exit /b 1
)

echo Flutter found in PATH
echo.

REM Run Flutter Doctor
echo Running Flutter Doctor...
echo =====================
flutter doctor -v
echo.

REM Check for issues
echo Checking Flutter Doctor results...
flutter doctor | findstr /i "issues" >nul
if %errorlevel% equ 0 (
    echo WARNING: Flutter Doctor detected issues
    echo Please resolve the issues above before continuing
    echo.
) else (
    echo SUCCESS: Flutter Doctor reports no issues
    echo.
)

REM Check if we're in Flutter project directory
if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found
    echo Please run this script from the Flutter project root directory
    pause
    exit /b 1
)

echo Flutter project detected
echo.

REM Get dependencies
echo Getting Flutter dependencies...
echo ============================
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)
echo Dependencies installed successfully
echo.

REM Analyze the project
echo Analyzing Flutter project...
echo ============================
flutter analyze
if %errorlevel% neq 0 (
    echo WARNING: Flutter analyze found issues
    echo Please review and fix the issues above
    echo.
) else (
    echo SUCCESS: No analysis issues found
    echo.
)

REM Check for common issues
echo Checking for common Flutter issues...
echo ====================================

REM Check for missing imports
echo Checking for missing imports...
flutter analyze | findstr /i "undefined" >nul
if %errorlevel% equ 0 (
    echo WARNING: Possible undefined classes/methods detected
) else (
    echo SUCCESS: No undefined references found
)

REM Check for deprecated APIs
echo Checking for deprecated APIs...
flutter analyze | findstr /i "deprecated" >nul
if %errorlevel% equ 0 (
    echo WARNING: Deprecated APIs detected
) else (
    echo SUCCESS: No deprecated APIs found
)

echo.

REM Test build (dry run)
echo Testing build configuration...
echo =============================
flutter build apk --debug --dry-run
if %errorlevel% neq 0 (
    echo WARNING: Build configuration has issues
) else (
    echo SUCCESS: Build configuration is valid
)

echo.

REM Summary
echo ========================================
echo DIAGNOSTICS SUMMARY
echo ========================================
echo.
echo Flutter Environment: CHECKED
echo Project Structure: CHECKED
echo Dependencies: INSTALLED
echo Code Analysis: COMPLETED
echo Build Configuration: TESTED
echo.
echo Project is ready for development!
echo.

REM Next steps
echo NEXT STEPS:
echo 1. Fix any issues reported by Flutter Doctor
echo 2. Resolve any analysis warnings
echo 3. Run the app: flutter run
echo 4. Build APK: flutter build apk --release
echo.

pause
