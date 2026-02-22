#!/bin/bash

# Flutter Development Environment Setup Script
# This script sets up Flutter environment for iSuite development

echo "========================================"
echo "Flutter Environment Setup"
echo "========================================"
echo

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found. Installing Flutter..."
    
    # Create Flutter directory
    mkdir -p ~/flutter
    
    echo "Please download Flutter from: https://flutter.dev/docs/get-started/install/linux"
    echo "Extract to ~/flutter and add ~/flutter/bin to PATH"
    echo "Then run this script again."
    exit 1
fi

echo "Flutter found. Checking version..."
flutter --version
echo

# Run Flutter Doctor
echo "Running Flutter Doctor..."
flutter doctor
echo

# Check Android SDK
echo "Checking Android SDK..."
flutter doctor --android-licenses
echo

# Install dependencies
echo "Installing project dependencies..."
flutter pub get
echo

# Run analysis
echo "Running code analysis..."
flutter analyze
echo

# Setup complete
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo
echo "Next steps:"
echo "1. Run flutter run to start the app"
echo "2. Use flutter_diagnostics.sh for regular checks"
echo "3. Check FLUTTER_DIAGNOSTICS.md for troubleshooting"
echo
