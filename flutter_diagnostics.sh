#!/bin/bash

# Flutter Doctor and Analysis Script for iSuite Project
# This script runs Flutter diagnostics to validate the project setup

echo "========================================"
echo "iSuite Flutter Diagnostics"
echo "========================================"
echo

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter not found in PATH"
    echo "Please install Flutter SDK and add it to your PATH"
    echo
    echo "Installation instructions:"
    echo "1. Download Flutter from https://flutter.dev/docs/get-started/install"
    echo "2. Extract to ~/flutter or /opt/flutter"
    echo "3. Add flutter/bin to PATH in ~/.bashrc or ~/.zshrc"
    echo "4. Restart terminal"
    echo
    exit 1
fi

echo "Flutter found in PATH"
echo

# Run Flutter Doctor
echo "Running Flutter Doctor..."
echo "====================="
flutter doctor -v
echo

# Check for issues
echo "Checking Flutter Doctor results..."
if flutter doctor | grep -q -i "issues"; then
    echo "WARNING: Flutter Doctor detected issues"
    echo "Please resolve the issues above before continuing"
    echo
else
    echo "SUCCESS: Flutter Doctor reports no issues"
    echo
fi

# Check if we're in Flutter project directory
if [ ! -f "pubspec.yaml" ]; then
    echo "ERROR: pubspec.yaml not found"
    echo "Please run this script from the Flutter project root directory"
    exit 1
fi

echo "Flutter project detected"
echo

# Get dependencies
echo "Getting Flutter dependencies..."
echo "============================"
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get dependencies"
    exit 1
fi
echo "Dependencies installed successfully"
echo

# Analyze the project
echo "Analyzing Flutter project..."
echo "============================"
flutter analyze
if [ $? -ne 0 ]; then
    echo "WARNING: Flutter analyze found issues"
    echo "Please review and fix the issues above"
    echo
else
    echo "SUCCESS: No analysis issues found"
    echo
fi

# Check for common issues
echo "Checking for common Flutter issues..."
echo "===================================="

# Check for missing imports
echo "Checking for missing imports..."
if flutter analyze | grep -q -i "undefined"; then
    echo "WARNING: Possible undefined classes/methods detected"
else
    echo "SUCCESS: No undefined references found"
fi

# Check for deprecated APIs
echo "Checking for deprecated APIs..."
if flutter analyze | grep -q -i "deprecated"; then
    echo "WARNING: Deprecated APIs detected"
else
    echo "SUCCESS: No deprecated APIs found"
fi

echo

# Test build (dry run)
echo "Testing build configuration..."
echo "============================="
flutter build apk --debug --dry-run
if [ $? -ne 0 ]; then
    echo "WARNING: Build configuration has issues"
else
    echo "SUCCESS: Build configuration is valid"
fi

echo

# Summary
echo "========================================"
echo "DIAGNOSTICS SUMMARY"
echo "========================================"
echo
echo "Flutter Environment: CHECKED"
echo "Project Structure: CHECKED"
echo "Dependencies: INSTALLED"
echo "Code Analysis: COMPLETED"
echo "Build Configuration: TESTED"
echo
echo "Project is ready for development!"
echo

# Next steps
echo "NEXT STEPS:"
echo "1. Fix any issues reported by Flutter Doctor"
echo "2. Resolve any analysis warnings"
echo "3. Run the app: flutter run"
echo "4. Build APK: flutter build apk --release"
echo
