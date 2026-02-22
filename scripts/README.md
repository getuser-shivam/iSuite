# iSuite Build Scripts

This directory contains PowerShell scripts for building and running the iSuite Flutter application on Windows.

## Scripts

### setup_flutter.ps1
Automatically downloads and sets up Flutter SDK in the `tools` directory.

**Usage:**
```powershell
.\scripts\setup_flutter.ps1
```

**Features:**
- Downloads Flutter SDK 3.24.5 stable
- Extracts to `tools/flutter` directory
- Runs `flutter doctor` to verify installation
- Provides instructions for adding Flutter to PATH

### run_windows.ps1
Builds and runs the iSuite application on Windows.

**Usage:**
```powershell
# Basic run
.\scripts\run_windows.ps1

# Setup Flutter first, then run
.\scripts\run_windows.ps1 -Setup

# Clean build before running
.\scripts\run_windows.ps1 -Clean

# Run in release mode
.\scripts\run_windows.ps1 -Release

# Combine options
.\scripts\run_windows.ps1 -Setup -Clean -Release
```

**Parameters:**
- `-Setup`: Run Flutter setup before building
- `-Clean`: Clean build files before building
- `-Release`: Build and run in release mode (default is debug)

## Quick Start

1. **First time setup:**
   ```cmd
   run_windows.bat -Setup
   ```

2. **Regular development:**
   ```cmd
   run_windows.bat
   ```

3. **Clean build:**
   ```cmd
   run_windows.bat -Clean
   ```

## Directory Structure

```
iSuite/
├── scripts/
│   ├── setup_flutter.ps1    # Flutter setup script
│   ├── run_windows.ps1      # Windows build/run script
│   └── README.md            # This file
├── tools/
│   └── flutter/             # Flutter SDK (auto-installed)
├── lib/                     # Flutter source code
├── windows/                 # Windows-specific configuration
└── run_windows.bat          # Main entry point (batch file)
```

## Troubleshooting

### Flutter not found
- Run with `-Setup` flag to automatically install Flutter
- Or manually install Flutter from https://flutter.dev/docs/get-started/install/windows

### Build errors
- Use `-Clean` flag to clean build files
- Check `flutter doctor` output for missing dependencies

### Permission issues
- Run PowerShell as Administrator
- Ensure execution policy allows script execution:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Internet connection (for Flutter download)
- Visual Studio with Windows development tools (for Windows builds)
