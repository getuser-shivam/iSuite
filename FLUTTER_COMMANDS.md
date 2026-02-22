# Flutter Commands Reference for iSuite

## Essential Flutter Commands

### Environment Commands
```bash
# Check Flutter environment
flutter doctor -v

# Check Flutter version
flutter --version

# Upgrade Flutter
flutter upgrade

# Clean Flutter cache
flutter clean

# Repair pub cache
flutter pub cache repair
```

### Project Commands
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Analyze code
flutter analyze

# Run tests
flutter test

# Format code
flutter format .
```

### Build Commands
```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Run in profile mode
flutter run --profile

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build app bundle (release)
flutter build appbundle --release

# Build for web
flutter build web

# Build for iOS
flutter build ios
```

### Device Commands
```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# List all available devices
flutter devices -v
```

### Development Commands
```bash
# Run with hot reload disabled
flutter run --no-hot-reload

# Run with specific flavor
flutter run --flavor <flavor_name>

# Start with tracing
flutter run --trace-startup

# Run with verbose logging
flutter run -v
```

## iSuite Specific Commands

### Parameterization System Testing
```bash
# Test central config initialization
flutter test test/central_config_test.dart

# Test component factory
flutter test test/component_factory_test.dart

# Test parameterized components
flutter test test/parameterized_components_test.dart
```

### Build Validation
```bash
# Test build configuration
flutter build apk --debug --dry-run

# Validate assets
flutter build apk --debug --analyze-size

# Check for missing assets
flutter build apk --debug --verbose
```

### Performance Analysis
```bash
# Profile performance
flutter run --profile

# Generate performance report
flutter run --profile --trace-startup

# Memory profiling
flutter run --profile --debug-info
```

## Troubleshooting Commands

### Common Issues
```bash
# Clean and rebuild
flutter clean && flutter pub get && flutter run

# Reset Flutter environment
flutter channel stable && flutter upgrade && flutter clean

# Fix dependency issues
flutter pub deps
flutter pub upgrade --major-versions

# Clear all caches
flutter clean && flutter pub cache repair
```

### Android Specific
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Check Android setup
flutter doctor -v | grep Android

# Clean Android build
cd android && ./gradlew clean && cd .. && flutter clean
```

### iOS Specific (macOS only)
```bash
# Check iOS setup
flutter doctor -v | grep iOS

# Clean iOS build
cd ios && xcodebuild clean && cd .. && flutter clean

# Update CocoaPods
cd ios && pod update && cd ..
```

## Development Workflow Commands

### Before Starting Development
```bash
# 1. Check environment
flutter doctor

# 2. Get dependencies
flutter pub get

# 3. Analyze code
flutter analyze

# 4. Run tests
flutter test
```

### During Development
```bash
# 1. Run with hot reload
flutter run

# 2. Analyze changes
flutter analyze

# 3. Run specific tests
flutter test test/specific_test.dart

# 4. Format code
flutter format lib/
```

### Before Release
```bash
# 1. Full analysis
flutter analyze --fatal-infos

# 2. Run all tests
flutter test --coverage

# 3. Build release
flutter build apk --release

# 4. Validate build
flutter build apk --release --analyze-size
```

## Advanced Commands

### Debugging
```bash
# Run with debugger
flutter run --debug

# Print widget tree
flutter run --debug
# Press 'w' in terminal for widget inspector

# Network debugging
flutter run --debug
# Use Flutter DevTools for network inspection
```

### Testing
```bash
# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/provider_test.dart

# Run tests with specific tags
flutter test --tags integration

# Generate test coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Performance
```bash
# Performance profiling
flutter run --profile

# Baseline performance
flutter run --profile --trace-startup

# Memory profiling
flutter run --profile --debug-info

# Frame rendering analysis
flutter run --profile --trace-startup --profile-memory
```

## IDE Integration Commands

### VS Code
```bash
# Install Flutter extension
code --install-extension Dart-Code.flutter

# Run from VS Code terminal
flutter run

# Debug from VS Code
flutter run --debug
```

### Android Studio
```bash
# Open project in Android Studio
idea .

# Run from Android Studio
# Use the run button in Android Studio

# Debug from Android Studio
# Use the debug button in Android Studio
```

## Continuous Integration Commands

### GitHub Actions
```bash
# Local CI testing
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

### Pre-commit Hooks
```bash
# Format code
flutter format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Build validation
flutter build apk --debug --dry-run
```

## Quick Reference Cheat Sheet

```bash
# Quick environment check
flutter doctor

# Quick dependency update
flutter pub get

# Quick code analysis
flutter analyze

# Quick test run
flutter test

# Quick app start
flutter run

# Quick build
flutter build apk --release

# Quick clean
flutter clean
```

---

**Note**: These commands are essential for iSuite development. Keep this reference handy for common Flutter operations and troubleshooting.
