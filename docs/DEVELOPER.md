# iSuite Developer Guide

## Table of Contents

- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Building & Deployment](#building--deployment)
- [Contributing Guidelines](#contributing-guidelines)
- [Troubleshooting](#troubleshooting)

---

## Development Setup

### Prerequisites

#### Required Software

1. **Flutter SDK** (version 3.0 or higher)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (version 2.17 or higher)
   ```bash
   dart --version
   ```

3. **IDE** (Choose one)
   - **Android Studio** with Flutter plugin
   - **VS Code** with Flutter extension
   - **IntelliJ IDEA** with Flutter plugin

4. **Git** for version control
   ```bash
   git --version
   ```

#### Optional Tools

- **SQLite Browser** for database inspection
- **Postman** or **Insomnia** for API testing
- **Device Emulator** (Android Studio Emulator or iOS Simulator)

### Environment Setup

#### 1. Clone Repository

```bash
git clone https://github.com/getuser-shivam/iSuite.git
cd iSuite
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Configure Development Environment

```bash
# Enable desktop support (Windows)
flutter config --enable-windows-desktop
flutter create --platforms=windows .

# Enable web support (optional)
flutter config --enable-web
```

#### 4. Verify Setup

```bash
flutter doctor
```

Resolve any issues reported by `flutter doctor` before proceeding.

---

## Project Structure

```
iSuite/
├── lib/                          # Main source code
│   ├── core/                   # Core utilities and configurations
│   │   ├── app_theme.dart      # Theme definitions
│   │   ├── app_router.dart     # Navigation configuration
│   │   ├── constants.dart      # App-wide constants
│   │   ├── utils.dart         # Utility functions
│   │   └── extensions.dart    # Extension methods
│   ├── data/                   # Data layer
│   │   ├── database_helper.dart # SQLite database management
│   │   └── repositories/     # Data access layer
│   │       └── task_repository.dart
│   ├── domain/                 # Business logic layer
│   │   └── models/           # Domain models
│   │       └── task.dart
│   └── presentation/           # UI layer
│       ├── providers/          # State management
│       │   ├── theme_provider.dart
│       │   ├── user_provider.dart
│       │   └── task_provider.dart
│       ├── screens/            # Screen implementations
│       │   ├── splash_screen.dart
│       │   ├── home_screen.dart
│       │   ├── tasks_screen.dart
│       │   ├── settings_screen.dart
│       │   └── profile_screen.dart
│       └── widgets/           # Reusable UI components
│           ├── task_card.dart
│           ├── task_list_item.dart
│           ├── add_task_dialog.dart
│           └── task_filter_chip.dart
├── assets/                     # Static assets
│   ├── images/                # Image files
│   └── fonts/                 # Font files
├── test/                       # Test files
├── docs/                       # Documentation
├── database/                   # Database schemas
├── backend/                    # Backend services (optional)
├── pubspec.yaml               # Dependencies and metadata
└── analysis_options.yaml        # Linting rules
```

---

## Architecture Overview

### Clean Architecture

iSuite follows Clean Architecture principles with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer (UI)                │
├─────────────────────────────────────────────────────────────────┤
│                    Domain Layer (Business Logic)         │
├─────────────────────────────────────────────────────────────────┤
│                      Data Layer (Data Access)            │
└─────────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

#### Presentation Layer
- **Screens**: UI screens and navigation
- **Widgets**: Reusable UI components
- **Providers**: State management using Provider pattern
- **Routes**: Navigation configuration

#### Domain Layer
- **Models**: Business entities and rules
- **Use Cases**: Application business logic
- **Repositories**: Abstract data access interfaces

#### Data Layer
- **Database Helper**: SQLite operations
- **Repositories**: Concrete data implementations
- **Models**: Data transfer objects

### Design Patterns

#### Provider Pattern
State management using Flutter's Provider package:
```dart
ChangeNotifierProvider(create: (_) => TaskProvider())
```

#### Repository Pattern
Data access abstraction:
```dart
abstract class TaskRepository {
  Future<List<Task>> getAllTasks();
  Future<Task?> getTaskById(String id);
  Future<String> createTask(Task task);
  Future<int> updateTask(Task task);
  Future<int> deleteTask(String id);
}
```

#### Dependency Injection
Service locator pattern for dependency management:
```dart
final taskRepository = Provider.of<TaskRepository>(context);
```

---

## Coding Standards

### Dart/Flutter Conventions

#### Naming Conventions

- **Classes**: PascalCase (e.g., `TaskProvider`)
- **Variables**: camelCase (e.g., `taskList`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `API_BASE_URL`)
- **Private members**: Prefix with underscore (e.g., `_isLoading`)

#### File Organization

- One class per file when possible
- Group related functionality in directories
- Use barrel exports for clean imports

#### Code Style

```dart
// Good example
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  
  Future<void> loadTasks() async {
    try {
      _tasks = await _repository.getAllTasks();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
```

### Documentation

#### Public APIs
Document all public methods and classes:
```dart
/// Creates a new task with the specified parameters.
/// 
/// [title] The task title (required)
/// [description] Optional task description
/// [priority] Task priority level
/// 
/// Returns a [Future<String>] containing the created task ID.
/// 
/// Throws [DatabaseException] if the operation fails.
Future<String> createTask({
  required String title,
  String? description,
  TaskPriority priority = TaskPriority.medium,
}) async {
  // Implementation
}
```

#### Comments
- Use `///` for public API documentation
- Use `//` for implementation notes
- Avoid obvious comments that restate the code

---

## Testing Guidelines

### Test Structure

```
test/
├── unit/                    # Unit tests
│   ├── providers/
│   ├── repositories/
│   └── utils/
├── widget/                  # Widget tests
└── integration/             # Integration tests
```

### Writing Tests

#### Unit Tests

```dart
// test/unit/providers/task_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:isuite/providers/task_provider.dart';

void main() {
  group('TaskProvider Tests', () {
    late TaskProvider taskProvider;
    late MockTaskRepository mockRepository;

    setUp(() {
      mockRepository = MockTaskRepository();
      taskProvider = TaskProvider();
    });

    test('should create task successfully', () async {
      // Arrange
      final task = Task(
        id: '1',
        title: 'Test Task',
        priority: TaskPriority.high,
        createdAt: DateTime.now(),
      );

      // Act
      await taskProvider.createTask(
        title: task.title,
        priority: task.priority,
      );

      // Assert
      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks.first.title, task.title);
    });
  });
}
```

#### Widget Tests

```dart
// test/widgets/task_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:isuite/widgets/task_card.dart';

void main() {
  testWidgets('TaskCard displays task information correctly', (tester) async {
    final task = Task(
      id: '1',
      title: 'Test Task',
      priority: TaskPriority.high,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            onTap: () {},
            onToggle: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Task'), findsOneWidget);
    expect(find.byIcon(Icons.flag), findsOneWidget);
  });
}
```

### Test Coverage

Run tests with coverage:
```bash
flutter test --coverage
```

Generate coverage report:
```bash
genhtml coverage/lcov.info -o coverage/coverage.html
```

---

## Building & Deployment

### Development Build

```bash
# Debug build
flutter build debug

# Profile build
flutter build profile

# Release build
flutter build release
```

### Platform-Specific Builds

#### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

#### iOS

```bash
# Build iOS app
flutter build ios --release

# Build for iOS Simulator
flutter build ios --simulator
```

#### Windows

```bash
# Build Windows executable
flutter build windows --release
```

#### Web

```bash
# Build web app
flutter build web --release
```

### Deployment

#### Android

1. **Generate Signed APK/App Bundle**
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

2. **Upload to Google Play Console**
   - Create new release
   - Upload APK/AAB
   - Fill store listing information
   - Submit for review

#### iOS

1. **Build iOS App**
   ```bash
   flutter build ios --release
   ```

2. **Prepare for App Store**
   - Create App Store Connect record
   - Upload build with Xcode
   - Submit for review

#### Windows

1. **Build Windows Installer**
   ```bash
   flutter build windows --release
   ```

2. **Create Installer Package**
   - Use MSIX packaging or Inno Setup
   - Code sign the installer
   - Distribute through website or Microsoft Store

---

## Contributing Guidelines

### Contribution Workflow

1. **Fork Repository**
   ```bash
   git clone https://github.com/getuser-shivam/iSuite.git
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow coding standards
   - Add tests for new functionality
   - Update documentation

4. **Test Changes**
   ```bash
   flutter test
   flutter analyze
   ```

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

6. **Push Branch**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create Pull Request**
   - Use descriptive title
   - Reference related issues
   - Include screenshots for UI changes

### Code Review Process

#### Review Checklist

- [ ] Code follows project conventions
- [ ] Tests pass for new functionality
- [ ] Documentation is updated
- [ ] No breaking changes without version bump
- [ ] Performance impact is considered
- [ ] Security implications are reviewed

#### Review Guidelines

- **Be Constructive**: Focus on improving, not criticizing
- **Be Specific**: Reference exact lines or sections
- **Explain Reasoning**: Help author understand your perspective
- **Offer Solutions**: Suggest concrete improvements

### Commit Message Format

Use conventional commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions
- `chore`: Maintenance changes

Examples:
```
feat(tasks): add task filtering by priority
fix(auth): resolve login validation issue
docs(readme): update installation instructions
```

---

## Troubleshooting

### Common Development Issues

#### Build Errors

**Issue**: "Could not resolve dependencies"
**Solution**:
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

**Issue**: "Target android-x86 not found"
**Solution**:
```bash
flutter doctor
# Install missing Android SDK components
```

#### Runtime Errors

**Issue**: "NoSuchMethodError"
**Solution**:
- Check for null values before method calls
- Verify proper widget binding
- Use proper type checking

**Issue**: "RenderFlex overflow"
**Solution**:
- Use `Expanded` or `Flexible` widgets
- Implement responsive design
- Consider using `SingleChildScrollView`

#### Performance Issues

**Issue**: App is slow or laggy
**Solution**:
- Use `const` constructors for widgets
- Implement lazy loading for large lists
- Optimize image assets
- Use `ListView.builder` instead of `Column`

### Debugging Tools

#### Flutter Inspector

```bash
flutter run --debug
# Open Flutter Inspector in your IDE
```

#### Logging

```dart
import 'package:logging/logging.dart';

final _logger = Logger('iSuite');

void debugPrint(String message) {
  _logger.info(message);
}
```

#### Performance Profiling

```bash
flutter run --profile
flutter run --trace-startup --profile
```

### Environment-Specific Issues

#### Windows

**Issue**: "Unable to locate Visual Studio"
**Solution**:
- Ensure Visual Studio 2019 or later
- Install Visual Studio with "Desktop development with C++" workload
- Add Flutter to PATH

#### macOS

**Issue**: "CocoaPods not found"
**Solution**:
```bash
sudo gem install cocoapods
pod setup
```

#### Linux

**Issue**: "Flutter not found in PATH"
**Solution**:
```bash
export PATH="$PATH:/path/to/flutter/bin:$PATH"
echo 'export PATH="$PATH:/path/to/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## Resources

### Documentation

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Material Design 3](https://m3.material.io)
- [Provider Package](https://pub.dev/packages/provider)

### Tools & Extensions

- [Flutter Inspector](https://flutter.dev/docs/development/tools/flutter-inspector)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [Flutter Outline](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
- [Flutter Widget Snippets](https://marketplace.visualstudio.com/items?itemName=FlutterWidgetSnippets)

### Community

- [Flutter Community](https://github.com/flutter/flutter)
- [Dart Community](https://github.com/dart-lang/sdk)
- [Stack Overflow Flutter Tag](https://stackoverflow.com/questions/tagged/flutter)

---

*Last updated: February 2026*
*Version: 1.0.0*
