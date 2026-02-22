# iSuite Developer Guide

## Table of Contents

- [Development Setup](#development-setup)
- [Project Architecture](#project-architecture)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Building & Deployment](#building--deployment)
- [Contributing Guidelines](#contributing-guidelines)
- [Troubleshooting](#troubleshooting)

---

## Development Setup

### Prerequisites

- **Flutter SDK**: Version 3.0 or higher
- **Dart SDK**: Version 2.17 or higher  
- **IDE**: Android Studio or VS Code with Flutter extensions
- **Git**: For version control
- **Node.js**: Version 16 or higher (for backend services)

### Environment Setup

1. **Install Flutter SDK**
   ```bash
   # Download Flutter SDK from https://flutter.dev/docs/get-started/install
   # Add Flutter to your PATH
   export PATH="$PATH:/path/to/flutter/bin"
   ```

2. **Verify Installation**
   ```bash
   flutter doctor
   ```

3. **Clone Repository**
   ```bash
   git clone https://github.com/getuser-shivam/iSuite.git
   cd iSuite
   ```

4. **Install Dependencies**
   ```bash
   flutter pub get
   ```

5. **Set Up Development Environment**
   ```bash
   # For VS Code
   code . --install-extension Dart-Code.flutter
   
   # For Android Studio
   # Install Flutter plugin from Marketplace
   ```

### Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Follow coding standards
   - Add tests for new functionality
   - Update documentation

3. **Run Tests**
   ```bash
   flutter test
   flutter analyze
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

---

## Project Architecture

### Clean Architecture Overview

iSuite follows Clean Architecture principles with clear separation of concerns:

```
lib/
├── core/                  # Core utilities and constants
│   ├── app_theme.dart     # Theme configuration
│   ├── app_router.dart    # Navigation routing
│   ├── constants.dart     # App constants
│   └── database_helper.dart # Database management
├── data/                  # Data layer
│   ├── models/           # Data models
│   ├── repositories/     # Repository implementations
│   └── services/         # External services
├── domain/               # Business logic layer
│   ├── entities/         # Business entities
│   ├── repositories/     # Repository interfaces
│   └── usecases/         # Business use cases
└── presentation/         # UI layer
    ├── providers/        # State management
    ├── screens/          # UI screens
    └── widgets/          # Reusable widgets
```

### Key Architectural Patterns

- **State Management**: Provider pattern with BLoC for complex state
- **Navigation**: Go Router for declarative routing
- **Database**: SQLite with Repository pattern
- **Dependency Injection**: GetIt for service location
- **Testing**: Unit, widget, and integration tests

### Data Flow

1. **UI Layer** (Presentation) triggers actions
2. **Provider** manages state and calls use cases
3. **Use Cases** contain business logic
4. **Repository** abstracts data sources
5. **Data Layer** handles local/remote data

---

## Coding Standards

### Dart/Flutter Conventions

1. **File Naming**: Use snake_case for files
   ```dart
   // ✅ Good
   task_screen.dart
   user_provider.dart
   
   // ❌ Bad
   TaskScreen.dart
   userProvider.dart
   ```

2. **Class Naming**: Use PascalCase for classes
   ```dart
   // ✅ Good
   class TaskScreen {}
   class UserProvider {}
   
   // ❌ Bad
   class taskScreen {}
   class user_provider {}
   ```

3. **Variable Naming**: Use camelCase for variables
   ```dart
   // ✅ Good
   final userName = 'John';
   final taskList = [];
   
   // ❌ Bad
   final user_name = 'John';
   final TaskList = [];
   ```

4. **Constants**: Use UPPER_CASE for constants
   ```dart
   // ✅ Good
   static const String API_URL = 'https://api.example.com';
   static const int MAX_RETRY_COUNT = 3;
   
   // ❌ Bad
   static const String apiUrl = 'https://api.example.com';
   static const int maxRetryCount = 3;
   ```

### Code Organization

1. **Import Order**
   ```dart
   // Flutter imports
   import 'package:flutter/material.dart';
   
   // Package imports
   import 'package:provider/provider.dart';
   
   // Project imports
   import '../core/constants.dart';
   import '../data/models/task.dart';
   ```

2. **Widget Structure**
   ```dart
   class TaskWidget extends StatelessWidget {
   // Properties first
   final Task task;
   final VoidCallback onTap;
   
   // Constructor
   const TaskWidget({
     Key? key,
     required this.task,
     required this.onTap,
   }) : super(key: key);
   
   // Build method
   @override
   Widget build(BuildContext context) {
     return Container(/* ... */);
   }
   }
   ```

### Documentation Standards

1. **Class Documentation**
   ```dart
   /// Manages task-related operations and state.
   /// 
   /// This provider handles CRUD operations for tasks,
   /// filtering, and search functionality.
   class TaskProvider extends ChangeNotifier {
     // ...
   }
   ```

2. **Method Documentation**
   ```dart
   /// Creates a new task with the provided details.
   /// 
   /// [title] The task title (required)
   /// [description] Optional task description
   /// [priority] Task priority level (default: normal)
   /// 
   /// Returns [Future<bool>] indicating success/failure
   Future<bool> createTask({
     required String title,
     String? description,
     TaskPriority priority = TaskPriority.normal,
   }) async {
     // ...
   }
   ```

---

## Testing Guidelines

### Testing Strategy

1. **Unit Tests**: Test business logic and utilities
2. **Widget Tests**: Test UI components in isolation
3. **Integration Tests**: Test complete user flows

### Test Structure

```
test/
├── unit/                  # Unit tests
│   ├── providers/        # Provider tests
│   ├── repositories/     # Repository tests
│   └── utils/           # Utility tests
├── widget/               # Widget tests
│   ├── screens/         # Screen widget tests
│   └── components/      # Component tests
└── integration/          # Integration tests
    └── app_test.dart    # Full app tests
```

### Writing Tests

1. **Unit Test Example**
   ```dart
   // test/unit/providers/task_provider_test.dart
   void main() {
     group('TaskProvider', () {
       late TaskProvider taskProvider;
       
       setUp(() {
         taskProvider = TaskProvider();
       });
       
       test('should create task successfully', () async {
         // Arrange
         const title = 'Test Task';
         
         // Act
         await taskProvider.createTask(title: title);
         
         // Assert
         expect(taskProvider.tasks.length, 1);
         expect(taskProvider.tasks.first.title, title);
       });
     });
   }
   ```

2. **Widget Test Example**
   ```dart
   // test/widget/screens/task_screen_test.dart
   void main() {
     testWidgets('TaskScreen displays tasks', (tester) async {
       // Arrange
       await tester.pumpWidget(
         MaterialApp(
           home: ChangeNotifierProvider(
             create: (_) => TaskProvider(),
             child: const TaskScreen(),
           ),
         ),
       );
       
       // Assert
       expect(find.text('Tasks'), findsOneWidget);
     });
   }
   ```

### Test Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/providers/task_provider_test.dart

# Run tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

---

## Building & Deployment

### Build Commands

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release

# Windows
flutter build windows --release

# Web
flutter build web --release
```

### Release Configuration

1. **Android Setup**
   ```bash
   # Generate signing key
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   
   # Configure signing in android/app/build.gradle
   # Set up play store console
   ```

2. **iOS Setup**
   ```bash
   # Configure Xcode project
   # Set up App Store Connect
   # Configure provisioning profiles
   ```

3. **Windows Setup**
   ```bash
   # Configure windows/runner/CMakeLists.txt
   # Set up code signing certificate
   ```

### Deployment Checklist

- [ ] All tests pass
- [ ] Code analysis completes without errors
- [ ] Version number updated
- [ ] Release notes prepared
- [ ] Assets optimized
- [ ] Dependencies audited
- [ ] Performance tested
- [ ] Security scan completed

---

## Contributing Guidelines

### Pull Request Process

1. **Fork Repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/your-username/iSuite.git
   cd iSuite
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make Changes**
   - Follow coding standards
   - Add tests for new functionality
   - Update documentation
   - Keep commits small and focused

4. **Test Changes**
   ```bash
   flutter test
   flutter analyze
   flutter format .
   ```

5. **Submit Pull Request**
   - Use descriptive title
   - Fill out PR template
   - Link related issues
   - Include screenshots for UI changes

### Code Review Guidelines

1. **Review Checklist**
   - [ ] Code follows project standards
   - [ ] Tests are included and passing
   - [ ] Documentation is updated
   - [ ] No breaking changes
   - [ ] Performance considerations addressed

2. **Review Process**
   - Assign reviewers based on expertise
   - Request changes constructively
   - Approve only when all checks pass
   - Merge with squash or rebase

### Commit Message Standards

Use [Conventional Commits](https://conventionalcommits.org/) format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Build process or auxiliary tool changes

Examples:
```
feat(tasks): add task priority levels
fix(auth): resolve login validation issue
docs(readme): update installation instructions
```

---

## Troubleshooting

### Common Issues

1. **Flutter Doctor Issues**
   ```bash
   # Missing Android licenses
   flutter doctor --android-licenses
   
   # CocoaPods not installed (macOS)
   sudo gem install cocoapods
   cd ios && pod install
   ```

2. **Build Issues**
   ```bash
   # Clean and rebuild
   flutter clean
   flutter pub get
   flutter run
   
   # Clear Flutter cache
   flutter pub cache repair
   ```

3. **Dependency Conflicts**
   ```bash
   # Update dependencies
   flutter pub upgrade
   
   # Check for outdated packages
   flutter pub outdated
   ```

4. **Performance Issues**
   ```bash
   # Run Flutter performance analysis
   flutter run --profile
   flutter run --trace-startup --profile
   ```

### Debugging Tools

1. **Flutter Inspector**
   - Widget tree visualization
   - Property inspection
   - Layout debugging

2. **Console Logging**
   ```dart
   debugPrint('Debug message');
   print('Console message');
   ```

3. **Breakpoint Debugging**
   - Set breakpoints in IDE
   - Step through code
   - Inspect variables

### Getting Help

- **GitHub Issues**: Report bugs and request features
- **Discord Community**: Join discussions and get help
- **Documentation**: Check existing docs first
- **Stack Overflow**: Search for Flutter-related questions

---

## Resources

### Official Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Provider Package](https://pub.dev/packages/provider)
- [Go Router](https://pub.dev/packages/go_router)

### Community Resources
- [Flutter Community](https://github.com/fluttercommunity)
- [Awesome Flutter](https://github.com/Solido/awesome-flutter)
- [Flutter Examples](https://github.com/flutter/samples)

### Development Tools
- [Flutter DevTools](https://flutter.dev/tools/devtools)
- [Dart Code Metrics](https://dartcodemetrics.dev/)
- [Very Good CLI](https://pub.dev/packages/very_good_cli)

---

**Note**: This guide is continuously updated. Check for the latest version in the repository.
