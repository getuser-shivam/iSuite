#!/bin/bash

# iSuite Master App Launcher - Shell Script
# This script launches the Python GUI master app for build and run management

echo "========================================"
echo "iSuite Master App Launcher"
echo "========================================"
echo

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo "ERROR: Python is not installed or not in PATH"
        echo "Please install Python 3.7+ and add it to PATH"
        exit 1
    else
        PYTHON_CMD="python"
    fi
else
    PYTHON_CMD="python3"
fi

echo "Using Python: $($PYTHON_CMD --version)"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "WARNING: pubspec.yaml not found in current directory"
    echo "Make sure you're running this from the Flutter project root"
    echo
fi

# Check if the master app exists
if [ ! -f "isuite_master_app.py" ]; then
    echo "ERROR: isuite_master_app.py not found"
    echo "Make sure the master app file is in the current directory"
    exit 1
fi

# Create logs directory if it doesn't exist
mkdir -p logs

echo "Starting iSuite Master App..."
echo

# Run the master app
$PYTHON_CMD isuite_master_app.py

# Check if the app ran successfully
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Master app exited with error code $?"
    echo "Check the logs directory for detailed error information"
    exit 1
fi

echo
echo "iSuite Master App closed successfully"
