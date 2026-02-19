# iSuite

A comprehensive cross-platform suite of tools and utilities built with Flutter, designed to enhance productivity and streamline workflows across mobile (Android/iOS) and desktop (Windows) devices.

## Overview

iSuite is a modern Flutter-based application that provides a collection of integrated tools for various productivity tasks. This project leverages Flutter's cross-platform capabilities to deliver a seamless user experience with powerful features and intuitive interfaces on all devices.

## Technology Stack

- **Frontend**: Flutter (Cross-platform for Android, iOS, Windows)
- **Database**: SQLite (local) with MySQL option (server-side)
- **State Management**: Provider pattern for reactive updates
- **Architecture**: Clean Architecture with MVVM pattern
- **Navigation**: Go Router for declarative routing
- **UI Framework**: Material Design 3 with adaptive theming

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
- **Task Management**: Complete task management system with CRUD operations
- **Calendar System**: Full calendar feature with event management
- **Notes Management**: Comprehensive notes with rich text editing
- **File Management**: Complete file storage and organization system
- **Analytics Dashboard**: Comprehensive analytics and reporting system

### 🚧 In Progress
- **Analytics Dashboard**: Advanced analytics and reporting system

### 📋 Next Steps
- **Cloud Sync**: Multi-device synchronization
- **Analytics**: Advanced usage tracking and insights
- **Team Collaboration**: Shared workspaces and real-time collaboration

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

## Documentation

### 📚 Comprehensive Documentation

#### User Documentation
- **[User Guide](docs/USER_GUIDE.md)** - Complete user manual with step-by-step instructions
- **[Feature Overview](docs/USER_GUIDE.md#features-overview)** - Detailed feature descriptions
- **[Getting Started](docs/USER_GUIDE.md#getting-started)** - Installation and setup guide
- **[Troubleshooting](docs/USER_GUIDE.md#troubleshooting)** - Common issues and solutions

#### Developer Documentation
- **[Developer Guide](docs/DEVELOPER.md)** - Development setup and contribution guidelines
- **[Architecture Overview](docs/ARCHITECTURE.md)** - System architecture and design patterns
- **[API Documentation](docs/API.md)** - Complete API reference for all components
- **[Database Schema](docs/DATABASE_SCHEMA.md)** - Database design and schema documentation

#### Technical Documentation
- **[Project Structure](docs/DEVELOPER.md#project-structure)** - Code organization and file layout
- **[Coding Standards](docs/DEVELOPER.md#coding-standards)** - Development conventions and best practices
- **[Testing Guidelines](docs/DEVELOPER.md#testing-guidelines)** - Testing strategies and examples
- **[Building & Deployment](docs/DEVELOPER.md#building--deployment)** - Build and deployment instructions

### 📖 Quick Reference

| Topic | Document | Description |
|-------|----------|-------------|
| **Getting Started** | [User Guide](docs/USER_GUIDE.md#getting-started) | Installation and first-time setup |
| **Task Management** | [User Guide](docs/USER_GUIDE.md#task-management) | Complete task management system |
| **Calendar Features** | [User Guide](docs/USER_GUIDE.md#calendar-management) | Full calendar with event management |
| **Notes Management** | [User Guide](docs/USER_GUIDE.md#notes-management) | Comprehensive notes with rich text editing |
| **Development Setup** | [Developer Guide](docs/DEVELOPER.md#development-setup) | Environment setup and tools |
| **API Reference** | [API Documentation](docs/API.md) | Complete API documentation |
| **Database Design** | [Database Schema](docs/DATABASE_SCHEMA.md) | Database structure and relationships |
| **Architecture** | [Architecture Overview](docs/ARCHITECTURE.md) | System design and patterns |
| **Notes Feature** | [Notes Feature](docs/NOTES_FEATURE.md) | Complete notes documentation |

### 🔍 Finding Information

#### For Users
- **New to iSuite?** Start with the [User Guide](docs/USER_GUIDE.md)
- **Need help with features?** Check the [Troubleshooting](docs/USER_GUIDE.md#troubleshooting) section
- **Want to learn advanced features?** Browse the [Features Overview](docs/USER_GUIDE.md#features-overview)

#### For Developers
- **Setting up development?** Follow the [Development Setup](docs/DEVELOPER.md#development-setup) guide
- **Understanding the codebase?** Read the [Architecture Overview](docs/ARCHITECTURE.md)
- **Contributing to the project?** See the [Contributing Guidelines](docs/DEVELOPER.md#contributing-guidelines)
- **API integration?** Check the [API Documentation](docs/API.md)

### 📞 Support

#### Getting Help
- **Documentation Issues**: Report documentation problems via GitHub Issues
- **Feature Requests**: Submit feature requests on GitHub Discussions
- **Bug Reports**: File bug reports with detailed information
- **Community Support**: Join our [Discord Community](https://discord.gg/isuite)

#### Contact Information
- **Email**: docs@isuite.app
- **GitHub**: [iSuite Repository](https://github.com/getuser-shivam/iSuite)
- **Website**: [iSuite.app](https://isuite.app)

---

## Contributing

We welcome contributions! Please follow these steps:

1. **Read the Documentation**
   - [Developer Guide](docs/DEVELOPER.md) for setup and guidelines
   - [Architecture Overview](docs/ARCHITECTURE.md) for understanding the codebase
   - [API Documentation](docs/API.md) for API reference

2. **Set Up Development Environment**
   ```bash
   git clone https://github.com/getuser-shivam/iSuite.git
   cd iSuite
   flutter pub get
   ```

3. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make Changes**
   - Follow [Coding Standards](docs/DEVELOPER.md#coding-standards)
   - Add tests for new functionality
   - Update documentation

5. **Test Your Changes**
   ```bash
   flutter test
   flutter analyze
   ```

6. **Submit Pull Request**
   - Use descriptive title and description
   - Reference related issues
   - Include screenshots for UI changes

### Contribution Guidelines

- **Code Quality**: Follow established patterns and conventions
- **Total Files**: 100+ files including source code, documentation, and tests
- **Lines of Code**: 25,000+ lines of well-structured code
- **Documentation Coverage**: Complete API reference and user guides
- **Cross-Platform Ready**: Works on Android, iOS, and Windows
- **Performance Optimized**: Efficient database queries and state management
- **Developer Friendly**: Comprehensive setup guides and contribution guidelines, see the [Developer Guide](docs/DEVELOPER.md#contributing-guidelines).

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)

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
