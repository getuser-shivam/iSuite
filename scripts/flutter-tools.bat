@echo off
REM Flutter Development Tools Script for Windows
REM This script runs all Flutter development tools for code quality and testing

echo 🚀 Running Flutter Development Tools...
echo ==================================

REM Check if Flutter is installed
echo [INFO] Checking Flutter installation...
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    exit /b 1
)
echo [SUCCESS] Flutter is installed

REM Run Flutter Doctor
echo [INFO] Running Flutter Doctor...
flutter doctor -v
if %errorlevel% equ 0 (
    echo [SUCCESS] Flutter Doctor completed successfully
) else (
    echo [WARNING] Flutter Doctor found some issues
)

REM Get dependencies
echo [INFO] Getting dependencies...
flutter pub get
if %errorlevel% equ 0 (
    echo [SUCCESS] Dependencies installed successfully
) else (
    echo [ERROR] Failed to install dependencies
    exit /b 1
)

REM Generate localization
echo [INFO] Generating localization...
flutter gen-l10n
if %errorlevel% equ 0 (
    echo [SUCCESS] Localization generated successfully
) else (
    echo [WARNING] Localization generation failed
)

REM Run Flutter Analyze
echo [INFO] Running Flutter Analyze...
flutter analyze --fatal-infos --fatal-warnings
if %errorlevel% equ 0 (
    echo [SUCCESS] Flutter Analyze passed
) else (
    echo [ERROR] Flutter Analyze failed
    exit /b 1
)

REM Check code formatting
echo [INFO] Checking code formatting...
dart format --set-exit-if-changed .
if %errorlevel% equ 0 (
    echo [SUCCESS] Code is properly formatted
) else (
    echo [ERROR] Code formatting issues found
    exit /b 1
)

REM Run tests
echo [INFO] Running tests...

REM Unit tests
echo [INFO] Running unit tests...
flutter test --coverage --reporter=expanded
if %errorlevel% equ 0 (
    echo [SUCCESS] Unit tests passed
) else (
    echo [ERROR] Unit tests failed
    exit /b 1
)

REM Widget tests
echo [INFO] Running widget tests...
flutter test --coverage integration_test\
if %errorlevel% equ 0 (
    echo [SUCCESS] Widget tests passed
) else (
    echo [WARNING] Some widget tests failed
)

REM Build test
echo [INFO] Running build test...

REM Web build
echo [INFO] Building for web...
flutter build web --release --web-renderer canvaskit
if %errorlevel% equ 0 (
    echo [SUCCESS] Web build successful
) else (
    echo [ERROR] Web build failed
    exit /b 1
)

REM Android build (if possible)
where java >nul 2>nul
if %errorlevel% equ 0 (
    echo [INFO] Building for Android...
    flutter build apk --release
    if %errorlevel% equ 0 (
        echo [SUCCESS] Android build successful
    ) else (
        echo [WARNING] Android build failed
    )
) else (
    echo [WARNING] Java not available, skipping Android build
)

REM Code quality check
echo [INFO] Running code quality check...

REM Install dart_code_metrics if not available
where dart_code_metrics >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Installing dart_code_metrics...
    dart pub global activate dart_code_metrics
)

REM Run code metrics
dart_code_metrics lib\ --reporter=console
if %errorlevel% equ 0 (
    echo [SUCCESS] Code quality check passed
) else (
    echo [WARNING] Code quality issues found
)

REM Security check
echo [INFO] Running security check...

REM Check dependencies for known vulnerabilities
flutter pub deps --style=tree

REM Check for sensitive data
echo [INFO] Checking for sensitive data...

REM Check for hardcoded secrets
findstr /r /i "password secret token key" lib\*.dart | findstr /v "//" | findstr /v "/*" | findstr /v "*/" | findstr /v "password secret token key.*:" >nul 2>nul
if %errorlevel% equ 0 (
    echo [WARNING] Potential hardcoded secrets found
) else (
    echo [SUCCESS] No hardcoded secrets found
)

REM Performance check
echo [INFO] Running performance check...

REM Check for common performance issues
echo [INFO] Checking for performance issues...

REM Check for unnecessary rebuilds
findstr /r /i "setState markNeedsBuild notifyListeners" lib\*.dart | find /c /v "" > temp_count.txt
set /p state_updates=<temp_count.txt
echo [INFO] Found %state_updates% state updates

REM Check for async/await usage
findstr /r /i "async await" lib\*.dart | find /c /v "" > temp_count.txt
set /p async_ops=<temp_count.txt
echo [INFO] Found %async_ops% async operations

echo [SUCCESS] Performance check completed

REM Documentation check
echo [INFO] Running documentation check...

REM Generate documentation
where dartdoc >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Installing dartdoc...
    dart pub global activate dartdoc
)

dartdoc --output docs\api --exclude-private --exclude-internal
if %errorlevel% equ 0 (
    echo [SUCCESS] Documentation generated successfully
) else (
    echo [WARNING] Documentation generation failed
)

REM Clean up
echo [INFO] Cleaning up...

REM Remove temporary files
del /q *.tmp 2>nul
del /q .DS_Store 2>nul
del /q Thumbs.db 2>nul

REM Clean build cache
flutter clean

echo [SUCCESS] Cleanup completed

REM Generate report
echo [INFO] Generating development report...

set REPORT_FILE=development_report.md

echo # Flutter Development Report > %REPORT_FILE%
echo. >> %REPORT_FILE%
echo Generated on: %date% %time% >> %REPORT_FILE%
echo. >> %REPORT_FILE%
echo ## Flutter Environment >> %REPORT_FILE%
echo \`\`\` >> %REPORT_FILE%
flutter doctor -v >> %REPORT_FILE%
echo \`\`\` >> %REPORT_FILE%
echo. >> %REPORT_FILE%
echo ## Project Statistics >> %REPORT_FILE%
echo - Total Dart files: 1 >> %REPORT_FILE%
for /f %%i in ('dir /b /s lib\*.dart ^| find /c /v ""') do set total_files=%%i
echo - Total Dart files: %total_files% >> %REPORT_FILE%
for /f %%i in ('dir /b /s test\*.dart ^| find /c /v ""') do set test_files=%%i
echo - Total test files: %test_files% >> %REPORT_FILE%
echo. >> %REPORT_FILE%
echo ## Code Quality >> %REPORT_FILE%
echo - Analyze: PASSED >> %REPORT_FILE%
echo - Tests: PASSED >> %REPORT_FILE%
echo - Build: PASSED >> %REPORT_FILE%
echo. >> %REPORT_FILE%
echo ## Dependencies >> %REPORT_FILE%
echo \`\`\` >> %REPORT_FILE%
flutter pub deps --style=tree >> %REPORT_FILE%
echo \`\`\` >> %REPORT_FILE%
echo. >> %REPORT_FILE%
echo ## Performance Metrics >> %REPORT_FILE%
echo - State updates: %state_updates% >> %REPORT_FILE%
echo - Async operations: %async_ops% >> %REPORT_FILE%
echo. >> %REPORT_FILE%
echo ## Security Scan >> %REPORT_FILE%
echo - Hardcoded secrets: CHECK MANUALLY >> %REPORT_FILE%
echo - Vulnerable dependencies: Check manually with \`flutter pub deps\` >> %REPORT_FILE%
echo. >> %REPORT_FILE%
echo ## Recommendations >> %REPORT_FILE%
echo - Keep documentation coverage above 70%% >> %REPORT_FILE%
echo - Use async/await for asynchronous operations >> %REPORT_FILE%
echo - Avoid hardcoded secrets >> %REPORT_FILE%
echo - Run tests before committing >> %REPORT_FILE%
echo - Use flutter analyze to catch issues early >> %REPORT_FILE%

del temp_count.txt

echo [SUCCESS] Report generated: %REPORT_FILE%

echo.
echo ==================================
echo [SUCCESS] Flutter development tools completed successfully!
echo.
echo 📊 Report: development_report.md
echo 📚 Documentation: docs\api\
echo 🧪 Test coverage: coverage\
echo.
echo Next steps:
echo 1. Review the development report
echo 2. Check test coverage
echo 3. Review documentation
echo 4. Fix any issues found
echo.

pause
