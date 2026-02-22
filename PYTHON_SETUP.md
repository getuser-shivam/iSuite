# iSuite Master App - Setup and Installation Guide

## Python Installation Required

The master app requires Python to be installed on your system. Since Python is not currently detected on your system, please follow these steps:

## Windows Python Installation

### Option 1: Microsoft Store (Recommended for Windows)
1. Press `Win + S` and search for "Python"
2. Click "Python 3.x" from the Microsoft Store
3. Click "Install" or "Get"
4. Wait for installation to complete

### Option 2: Official Python Website
1. Visit https://www.python.org/downloads/
2. Download the latest Python 3.x version
3. Run the installer
4. **IMPORTANT**: Check "Add Python to PATH" during installation
5. Complete the installation

### Option 3: Package Manager (Chocolatey)
If you have Chocolatey installed:
```bash
choco install python
```

## Verification

After installation, open Command Prompt and verify:
```bash
python --version
```

You should see something like:
```
Python 3.11.4
```

## Running the Master App

Once Python is installed:

### Method 1: Batch File (Recommended)
Double-click `run_master_app.bat` in the iSuite directory

### Method 2: Direct Python
Open Command Prompt in the iSuite directory and run:
```bash
python isuite_master_app.py
```

### Method 3: Shell Script (Linux/macOS)
```bash
./run_master_app.sh
```

## Troubleshooting

### "Python not found" Error
- Ensure Python is installed and added to PATH
- Restart Command Prompt after installation
- Try using `py` instead of `python` on Windows

### Permission Issues
- Run Command Prompt as Administrator
- Check antivirus software isn't blocking Python

### GUI Issues
- Ensure you have a graphical desktop environment
- Try running with `python -u isuite_master_app.py` for unbuffered output

## Features Available After Setup

Once Python is installed, you'll have access to:

✅ **Build Management**: Flutter build operations with logging
✅ **Error Analysis**: Automatic error categorization and suggestions  
✅ **Device Management**: Connected device detection and selection
✅ **Continuous Improvement**: Smart suggestions based on build history
✅ **Real-time Logging**: Comprehensive console output with timestamps
✅ **Project Validation**: Flutter project validation and health checks

## Next Steps

1. Install Python using one of the methods above
2. Restart your command prompt/terminal
3. Run the master app using `run_master_app.bat`
4. Select your Flutter project and start building!

The master app will automatically create log files and remember your last project for convenience.
