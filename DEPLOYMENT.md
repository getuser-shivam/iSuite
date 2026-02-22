# iSuite Deployment Guide

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Build Configuration](#build-configuration)
- [Platform-Specific Deployment](#platform-specific-deployment)
- [Testing Before Deployment](#testing-before-deployment)
- [Release Checklist](#release-checklist)
- [Troubleshooting](#troubleshooting)

---

## Overview

This guide provides comprehensive instructions for deploying the iSuite application across different platforms. iSuite is a cross-platform Flutter application that supports Android, iOS, Windows, and web deployment.

### Supported Platforms

- **Android**: Android 5.0 (API level 21) and above
- **iOS**: iOS 11.0 and above
- **Windows**: Windows 10 and above
- **Web**: Modern browsers with ES6 support

---

## Prerequisites

### Development Environment

1. **Flutter SDK**: Version 3.16.0 or higher
2. **Dart SDK**: Version 3.2.0 or higher
3. **Platform-specific tools**:
   - Android: Android Studio, Android SDK
   - iOS: Xcode 14.0 or higher
   - Windows: Visual Studio 2022 with C++ development tools
   - Web: Chrome browser for testing

### Required Software

```bash
# Install Flutter
flutter doctor

# Install dependencies
flutter pub get

# Run tests
flutter test
```

---

## Environment Setup

### 1. Clone and Setup Repository

```bash
git clone <repository-url>
cd isuite
flutter pub get
```

### 2. Environment Configuration

Create environment-specific configuration files:

#### `.env.development`
```env
FLUTTER_ENV=development
API_BASE_URL=http://localhost:8080
DEBUG_MODE=true
ENABLE_ANALYTICS=false
```

#### `.env.production`
```env
FLUTTER_ENV=production
API_BASE_URL=https://api.isuite.app
DEBUG_MODE=false
ENABLE_ANALYTICS=true
```

### 3. Platform-Specific Setup

#### Android Setup
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Set up signing keys
mkdir -p android/app/src/main/kotlin/com/example/isuite
# Copy keystore files to android/app/
```

#### iOS Setup
```bash
# Navigate to iOS directory
cd ios

# Install CocoaPods
pod install

# Open Xcode project
open Runner.xcworkspace
```

#### Windows Setup
```bash
# Ensure Windows desktop support is enabled
flutter config --enable-windows-desktop

# Run Windows desktop configuration
flutter pub run flutter_tools:windows_desktop
```

---

## Build Configuration

### 1. Update Version Information

Update `pubspec.yaml` with current version:

```yaml
version: 1.0.0+1  # version+build_number
```

### 2. Build Commands

#### Development Build
```bash
# Debug build
flutter build apk --debug
flutter build windows --debug
flutter build web --debug
```

#### Production Build
```bash
# Release build
flutter build apk --release
flutter build appbundle --release
flutter build windows --release
flutter build web --release
```

### 3. Build Configuration Files

#### `build.yaml`
```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
          include_if_null: false
```

#### `analysis_options.yaml`
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  
linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: true
    prefer_single_quotes: true
```

---

## Platform-Specific Deployment

### Android Deployment

#### 1. Generate Signed APK

```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build signed APK
flutter build apk --release --keystore ~/upload-keystore.jks --storePassword <password> --keyPassword <password> --key-alias upload

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release --keystore ~/upload-keystore.jks --storePassword <password> --keyPassword <password> --key-alias upload
```

#### 2. Android Manifest Configuration

Update `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <application
        android:label="iSuite"
        android:icon="@mipmap/ic_launcher"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

#### 3. Play Store Upload

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new application
3. Upload App Bundle (`build/app/outputs/bundle/release/app-release.aab`)
4. Complete store listing and screenshots
5. Submit for review

### iOS Deployment

#### 1. Build iOS App

```bash
# Build for iOS
flutter build ios --release --no-codesign

# Or use Xcode for signing
open ios/Runner.xcworkspace
```

#### 2. Xcode Configuration

1. Open `Runner.xcworkspace` in Xcode
2. Select `Runner` project
3. Update bundle identifier: `com.yourcompany.isuite`
4. Configure signing certificates and provisioning profiles
5. Update app icons and launch screens
6. Build and archive: `Product > Archive`

#### 3. App Store Upload

1. Use Xcode Organizer to upload to App Store Connect
2. Complete app metadata in [App Store Connect](https://appstoreconnect.apple.com)
3. Submit for review

### Windows Deployment

#### 1. Build Windows App

```bash
# Build Windows executable
flutter build windows --release

# Output location: build/windows/runner/Release/
```

#### 2. Windows Installer

Create installer using [MSIX](https://docs.microsoft.com/en-us/windows/msix/):

```xml
<!-- Package.appxmanifest -->
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10">
  <Identity Name="iSuite" Publisher="CN=YourCompany" Version="1.0.0.0" />
  <Properties>
    <DisplayName>iSuite</DisplayName>
    <PublisherDisplayName>Your Company</PublisherDisplayName>
    <Logo>Assets\StoreLogo.png</Logo>
  </Properties>
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Universal" MinVersion="10.0.17763.0" MaxVersionTested="10.0.19041.0" />
  </Dependencies>
  <Applications>
    <Application Id="App" Executable="$targetnametoken$.exe" EntryPoint="$targetnametoken$.App" />
  </Applications>
</Package>
```

#### 3. Microsoft Store Upload

1. Go to [Microsoft Partner Center](https://partner.microsoft.com/dashboard)
2. Create new app submission
3. Upload MSIX package
4. Complete store listing
5. Submit for certification

### Web Deployment

#### 1. Build Web App

```bash
# Build for web
flutter build web --release --web-renderer canvaskit

# Output location: build/web/
```

#### 2. Web Server Configuration

##### Nginx Configuration
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/build/web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /assets {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

##### Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase
firebase init hosting

# Deploy
firebase deploy --only hosting
```

---

## Testing Before Deployment

### 1. Unit Tests

```bash
# Run all unit tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### 2. Integration Tests

```bash
# Run integration tests
flutter test integration_test/

# Run on specific device
flutter test -d <device-id>
```

### 3. Widget Tests

```bash
# Run widget tests
flutter test test/widget/
```

### 4. Performance Testing

```bash
# Profile app performance
flutter run --profile

# Build with performance profiling
flutter build apk --profile
```

### 5. Platform Testing Checklist

#### Android Testing
- [ ] Test on multiple Android versions (API 21, 28, 31, 33)
- [ ] Test on different screen sizes
- [ ] Test permissions flow
- [ ] Test network connectivity scenarios
- [ ] Test file operations

#### iOS Testing
- [ ] Test on multiple iOS versions (iOS 15, 16, 17)
- [ ] Test on iPhone and iPad
- [ ] Test app store review guidelines compliance
- [ ] Test background app refresh
- [ ] Test push notifications

#### Windows Testing
- [ ] Test on Windows 10 and 11
- [ ] Test different screen resolutions
- [ ] Test file system permissions
- [ ] Test Windows-specific features

#### Web Testing
- [ ] Test on Chrome, Firefox, Safari, Edge
- [ ] Test responsive design
- [ ] Test PWA functionality
- [ ] Test offline capabilities

---

## Release Checklist

### Pre-Release Checklist

- [ ] All tests passing
- [ ] Code review completed
- [ ] Documentation updated
- [ ] Version number updated
- [ ] Changelog updated
- [ ] Assets and icons updated
- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Accessibility compliance verified

### Release Process

1. **Create release branch**
   ```bash
   git checkout -b release/v1.0.0
   ```

2. **Update version and changelog**
   ```bash
   # Update pubspec.yaml
   # Update CHANGELOG.md
   git commit -m "chore: bump version to 1.0.0"
   ```

3. **Create tag**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   ```

4. **Build and test**
   ```bash
   flutter test
   flutter build apk --release
   flutter build appbundle --release
   ```

5. **Deploy to stores**
   - Upload to Google Play Store
   - Upload to Apple App Store
   - Upload to Microsoft Store (if applicable)
   - Deploy web version

6. **Merge and push**
   ```bash
   git checkout main
   git merge release/v1.0.0
   git push origin main --tags
   ```

### Post-Release Checklist

- [ ] Monitor crash reports
- [ ] Monitor user feedback
- [ ] Monitor performance metrics
- [ ] Update documentation website
- [ ] Announce release to users
- [ ] Plan next release cycle

---

## Troubleshooting

### Common Issues

#### Build Errors

**Issue**: "Could not resolve dependencies"
```bash
# Solution
flutter clean
flutter pub cache repair
flutter pub get
```

**Issue**: "Gradle build failed"
```bash
# Solution
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk --release
```

#### Signing Issues

**Issue**: "Signing key not found"
```bash
# Solution
# Check keystore path in gradle.properties
# Ensure keystore file exists and is accessible
```

#### Platform-Specific Issues

**Android**: "INSTALL_FAILED_INSUFFICIENT_STORAGE"
```bash
# Solution
adb shell pm uninstall com.example.isuite
flutter install
```

**iOS**: "Code signing error"
```bash
# Solution
# Check provisioning profiles in Xcode
# Ensure bundle identifier matches certificates
```

**Windows**: "MSIX packaging failed"
```bash
# Solution
# Check Windows SDK version
# Ensure Visual Studio C++ tools are installed
```

### Performance Issues

#### Slow Build Times
```bash
# Enable build cache
flutter config --enable-web
flutter build apk --release --build-number=1
```

#### Large APK Size
```bash
# Enable app splitting
flutter build apk --split-per-abi --release
```

### Debugging Tips

#### Enable Logging
```dart
import 'package:flutter/foundation.dart' as developer;

void main() {
  developer.log('App started', name: 'iSuite');
  runApp(MyApp());
}
```

#### Profile Mode Debugging
```bash
flutter run --profile --trace-startup
```

---

## Continuous Integration/Deployment

### GitHub Actions Workflow

```yaml
name: Build and Deploy

on:
  push:
    tags:
      - 'v*'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter test
      - run: flutter analyze

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-web:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id
```

---

## Conclusion

This deployment guide covers all aspects of deploying the iSuite application across multiple platforms. Following these guidelines ensures a smooth and successful deployment process.

For additional support or questions, refer to:
- [Flutter Documentation](https://flutter.dev/docs)
- [Platform-Specific Documentation](https://flutter.dev/docs/deployment)
- [iSuite Project Repository](https://github.com/your-org/isuite)

---

**Note**: Always test deployments in a staging environment before deploying to production.
