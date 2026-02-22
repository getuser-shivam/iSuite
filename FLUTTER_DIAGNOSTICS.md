# Flutter Diagnostics and Setup Guide

## Quick Start

### Windows Users
Double-click `flutter_diagnostics.bat` to run comprehensive Flutter diagnostics

### Linux/macOS Users
Run `./flutter_diagnostics.sh` to run comprehensive Flutter diagnostics

## What the Diagnostics Script Does

### 🔍 **Environment Validation**
- Checks if Flutter SDK is installed and in PATH
- Runs `flutter doctor -v` for detailed environment analysis
- Identifies missing dependencies and configuration issues

### 📦 **Project Validation**
- Verifies Flutter project structure (pubspec.yaml check)
- Runs `flutter pub get` to install dependencies
- Checks for dependency conflicts and missing packages

### 🔬 **Code Analysis**
- Runs `flutter analyze` for static code analysis
- Identifies undefined classes, methods, and variables
- Detects deprecated APIs and usage patterns
- Reports potential bugs and performance issues

### 🏗️ **Build Validation**
- Tests build configuration with `flutter build apk --dry-run`
- Validates Android/iOS build setup
- Checks for missing assets and configuration files

## Manual Flutter Commands

If you prefer to run commands manually:

### Environment Check
```bash
flutter doctor -v
```

### Dependencies
```bash
flutter pub get
```

### Code Analysis
```bash
flutter analyze
```

### Build Test
```bash
flutter build apk --debug --dry-run
```

### Run App
```bash
flutter run
```

### Build Release APK
```bash
flutter build apk --release
```

## Common Issues and Solutions

### Flutter Not Found in PATH
**Windows:**
1. Download Flutter from https://flutter.dev/docs/get-started/install
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to PATH
4. Restart Command Prompt

**Linux/macOS:**
1. Download Flutter and extract to `~/flutter` or `/opt/flutter`
2. Add `export PATH="$PATH:/path/to/flutter/bin"` to `~/.bashrc` or `~/.zshrc`
3. Restart terminal

### Android License Issues
```bash
flutter doctor --android-licenses
```

### Missing Android SDK
Install Android Studio and Android SDK, then run:
```bash
flutter doctor
```

### iOS Setup Issues (macOS only)
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### Dependency Conflicts
```bash
flutter clean
flutter pub get
```

## Project-Specific Considerations

### iSuite Parameterization System
The iSuite project uses a centralized configuration system. Ensure:

1. **CentralConfig** is properly initialized in `main.dart`
2. All providers implement `ParameterizedComponent`
3. Dependencies are correctly registered in `ComponentFactory`

### Required Dependencies
Check `pubspec.yaml` for these key dependencies:
- `provider` for state management
- `shared_preferences` for configuration persistence
- Any custom packages for file management

### Build Configuration
The project includes:
- Enhanced parameterization system
- Centralized configuration management
- Multi-provider setup
- Custom theme management

## Advanced Diagnostics

### Performance Analysis
```bash
flutter run --profile
```

### Memory Analysis
```bash
flutter run --profile --trace-startup
```

### Widget Inspector
```bash
flutter run --debug
# Then press 'w' in terminal to open widget inspector
```

### Network Analysis
```bash
flutter run --debug
# Use Flutter DevTools for network profiling
```

## Continuous Integration

### GitHub Actions Example
```yaml
name: Flutter CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
      with:
        channel: 'stable'
    - run: flutter doctor
    - run: flutter pub get
    - run: flutter analyze
    - run: flutter test
```

## Troubleshooting

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

### Reset Flutter
```bash
flutter channel stable
flutter upgrade
flutter clean
flutter pub get
```

### Clear Cache
```bash
flutter pub cache repair
```

## Development Workflow

### Before Development
1. Run `flutter doctor` to ensure environment is ready
2. Run `flutter pub get` to install dependencies
3. Run `flutter analyze` to check for issues

### During Development
1. Use `flutter analyze` frequently to catch issues early
2. Use `flutter run` for testing
3. Use `flutter test` for unit tests

### Before Release
1. Run full diagnostic script
2. Fix all analysis issues
3. Test on multiple devices/simulators
4. Build release APK for final testing

---

**Note**: The diagnostic scripts provide comprehensive validation of your Flutter environment and iSuite project setup. Run them regularly to ensure optimal development experience.
