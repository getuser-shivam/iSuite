# iSuite

A comprehensive cross-platform suite of tools and utilities built with Flutter, designed to enhance productivity and streamline workflows across mobile (Android/iOS) and desktop (Windows) devices.

## Overview

iSuite is a modern Flutter-based application that provides a collection of integrated tools for various productivity tasks. This project leverages Flutter's cross-platform capabilities to deliver a seamless user experience with powerful features and intuitive interfaces on all devices.

## Technology Stack

- **Frontend**: Flutter (Cross-platform for Android, iOS, Windows)
- **Database**: MySQL (when server-side data persistence is required)
- **Backend**: Node.js/Express (for API services)
- **State Management**: Provider/Bloc
- **Architecture**: Clean Architecture with MVVM pattern

## Features

- **Cross-Platform**: Single codebase for Android, iOS, and Windows
- **Modular Architecture**: Built with extensibility and maintainability in mind
- **Responsive Design**: Adaptive UI for different screen sizes
- **Offline Support**: Local data storage with online synchronization
- **Real-time Updates**: Live data synchronization across devices
- **Performance Optimized**: Efficient resource management
- **Secure Authentication**: User authentication and authorization
- **Cloud Integration**: Optional cloud storage and backup

## Getting Started

### Prerequisites

- Flutter SDK (version 3.0 or higher)
- Dart SDK (version 2.17 or higher)
- Android Studio / VS Code with Flutter extensions
- Git for version control
- MySQL Server (optional, for database features)
- Node.js (version 16 or higher) - for backend services

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/getuser-shivam/iSuite.git
   cd iSuite
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Set up MySQL database (optional):
   ```sql
   CREATE DATABASE isuite_db;
   ```

4. Configure environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

5. Run the application:
   ```bash
   flutter run
   ```

## Project Structure

```
iSuite/
├── lib/                 # Flutter source code
│   ├── core/           # Core utilities and constants
│   ├── data/           # Data layer (repositories, models)
│   ├── domain/         # Business logic (entities, use cases)
│   ├── presentation/   # UI layer (screens, widgets)
│   └── main.dart       # App entry point
├── assets/             # Static assets (images, fonts)
├── test/               # Flutter test files
├── backend/            # Node.js backend (optional)
├── database/           # Database schemas and migrations
├── docs/               # Documentation
├── pubspec.yaml        # Flutter dependencies
├── .env.example        # Environment variables template
└── README.md           # This file
```

## Current Status

### ✅ Completed Features
- **Project Structure**: Complete Flutter project with clean architecture
- **UI Framework**: Material Design 3 with responsive layouts
- **Navigation**: Go Router implementation with proper routing
- **State Management**: Provider pattern for theme and user management
- **Database**: SQLite integration with comprehensive schema
- **Authentication**: User login/logout system with profile management
- **Theme System**: Light/dark/system theme switching
- **Core Screens**: Splash, Home, Settings, and Profile screens
- **Code Quality**: Comprehensive linting rules and analysis options

### 🚧 In Progress
- Task management system
- Calendar integration
- Notes functionality
- File storage system
- Cloud synchronization

### 📋 Next Steps
- Add unit and widget tests
- Implement domain layer business logic
- Add font assets and app icons
- Set up CI/CD pipeline
- Deploy to app stores

## Usage

### Running on Different Platforms

#### Mobile (Android/iOS)
```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios
```

#### Desktop (Windows)
```bash
# Windows
flutter run -d windows

# Enable Windows support (first time only)
flutter config --enable-windows-desktop
flutter create --platforms=windows .
```

### Available Commands

- `flutter pub get` - Install dependencies
- `flutter run` - Run the app in debug mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build windows` - Build Windows executable
- `flutter test` - Run Flutter tests
- `flutter analyze` - Analyze code for issues

## Development

### Code Style

We follow Flutter/Dart coding conventions and use `flutter analyze` to ensure code quality. Please ensure your code adheres to the established style guidelines.

### Testing

Run the test suite:
```bash
flutter test
```

### Database Setup (Optional)

For features requiring local SQLite storage:

1. Database is automatically initialized on first app launch
2. Tables are created for users, tasks, notes, and settings
3. Data is stored locally on device
4. For MySQL integration, configure connection in `.env` file

### Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Build for different platforms
flutter build apk          # Android
flutter build ios          # iOS (macOS only)
flutter build windows      # Windows
flutter build web          # Web
```

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- **Author**: Shivam
- **GitHub**: [@getuser-shivam](https://github.com/getuser-shivam)
- **Repository**: [iSuite](https://github.com/getuser-shivam/iSuite)

## Acknowledgments

- Thanks to the Flutter team for the amazing cross-platform framework
- Thanks to all contributors who have helped make this project better
- Special thanks to the open-source community for inspiration and tools

---

**Note**: This project is currently under active development. Features and documentation are being added regularly. Built with ❤️ using Flutter for cross-platform excellence.
