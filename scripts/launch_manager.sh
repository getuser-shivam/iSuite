#!/bin/bash

# iSuite Master Build & Run Manager Launcher
# This script launches the Python GUI application for managing Flutter builds

echo "🚀 Starting iSuite Master Build & Run Manager..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ This doesn't appear to be a Flutter project directory."
    echo "   Please run this script from the iSuite project root."
    exit 1
fi

# Check if the manager script exists
if [ ! -f "scripts/isuite_manager.py" ]; then
    echo "❌ isuite_manager.py not found in scripts directory."
    exit 1
fi

# Install required Python packages if needed
echo "📦 Checking Python dependencies..."
python3 -c "import tkinter, sqlite3, requests" 2>/dev/null || {
    echo "📦 Installing required Python packages..."
    pip3 install requests
}

# Create logs directory if it doesn't exist
mkdir -p logs

# Launch the manager
echo "🎯 Launching iSuite Manager..."
python3 scripts/isuite_manager.py

# Check if the manager exited successfully
if [ $? -eq 0 ]; then
    echo "✅ iSuite Manager closed successfully."
else
    echo "❌ iSuite Manager encountered an error."
    echo "   Check logs/isuite_manager.log for details."
fi

echo "👋 Done!"
