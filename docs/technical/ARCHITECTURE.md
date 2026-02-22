# iSuite Architecture Documentation

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Layer Architecture](#layer-architecture)
- [Design Patterns](#design-patterns)
- [Data Flow](#data-flow)
- [State Management](#state-management)
- [Navigation](#navigation)
- [Database Design](#database-design)
- [Security Architecture](#security-architecture)

---

## Architecture Overview

### High-Level Architecture

iSuite follows **Clean Architecture** principles with clear separation of concerns, making the application scalable, testable, and maintainable.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer (UI)                │
├─────────────────────────────────────────────────────────────────┤
│                    Domain Layer (Business Logic)         │
├─────────────────────────────────────────────────────────────────┤
│                      Data Layer (Data Access)            │
└─────────────────────────────────────────────────────────────────┘
```

### Core Principles

1. **Separation of Concerns**: Each layer has specific responsibilities
2. **Dependency Inversion**: High-level modules depend on abstractions
3. **Single Responsibility**: Each class has one reason to change
4. **Open/Closed Principle**: Classes are open for extension, closed for modification
5. **Interface Segregation**: Clients depend on interfaces, not implementations

---

## Layer Architecture

### Presentation Layer

**Responsibility**: UI components, user interactions, and state presentation

#### Components

```
presentation/
├── screens/              # Screen implementations
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── tasks_screen.dart
│   ├── settings_screen.dart
│   └── profile_screen.dart
├── providers/            # State management
│   ├── theme_provider.dart
│   ├── user_provider.dart
│   └── task_provider.dart
└── widgets/              # Reusable UI components
    ├── task_card.dart
    ├── task_list_item.dart
    ├── add_task_dialog.dart
    └── task_filter_chip.dart
```

#### Key Characteristics

- **Widget-Based**: Built with Flutter widgets and custom components
- **State Management**: Uses Provider pattern for reactive updates
- **Navigation**: Go Router for declarative routing
- **Responsive Design**: Adapts to different screen sizes
- **Theme System**: Material Design 3 with light/dark themes

### Domain Layer

**Responsibility**: Business logic, entities, and use cases

#### Components

```
domain/
├── models/              # Business entities
│   └── task.dart
└── use cases/           # Application business logic (future)
```

#### Key Characteristics

- **Pure Dart**: No framework dependencies
- **Business Rules**: Domain-specific validation and logic
- **Entities**: Core business objects with behavior
- **Interfaces**: Abstract contracts for repositories

### Data Layer

**Responsibility**: Data persistence, retrieval, and external service integration

#### Components

```
data/
├── database_helper.dart     # Database management
└── repositories/           # Data access implementations
    └── task_repository.dart
```

#### Key Characteristics

- **Database Abstraction**: SQLite with helper class
- **Repository Pattern**: Clean data access interface
- **Error Handling**: Comprehensive error management
- **Data Mapping**: Entity-to-database conversion

---

## Design Patterns

### Provider Pattern

**Purpose**: State management and dependency injection

```dart
// Provider setup in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TaskProvider()),
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
  ],
  child: MyApp(),
)
```

**Benefits**:
- Reactive UI updates
- Dependency injection
- Testable state management
- Performance optimization

### Repository Pattern

**Purpose**: Data access abstraction

```dart
// Abstract repository
abstract class TaskRepository {
  Future<List<Task>> getAllTasks({String? userId});
  Future<Task?> getTaskById(String id);
  Future<String> createTask(Task task);
  Future<int> updateTask(Task task);
  Future<int> deleteTask(String id);
}

// Concrete implementation
class TaskRepositoryImpl implements TaskRepository {
  final DatabaseHelper _database;
  
  TaskRepositoryImpl(this._database);
  
  @override
  Future<List<Task>> getAllTasks({String? userId}) async {
    // Implementation using DatabaseHelper
  }
}
```

**Benefits**:
- Testable data access
- Swappable implementations
- Centralized data logic
- Error handling consistency

### Factory Pattern

**Purpose**: Object creation with type safety

```dart
// Task factory methods
factory Task.fromJson(Map<String, dynamic> json) {
  return Task(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    // ... other fields
  );
}

Map<String, dynamic> toJson() {
  return {
    'id': id,
    'title': title,
    // ... other fields
  };
}
```

### Observer Pattern

**Purpose**: State change notifications

```dart
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  
  void updateTask(Task updatedTask) {
    _tasks = _tasks.map((task) => 
      task.id == updatedTask.id ? updatedTask : task
    ).toList();
    notifyListeners();
  }
}
```

---

## Data Flow

### Task Creation Flow

```
User Input (UI)
       ↓
TaskProvider.createTask()
       ↓
Validation (Domain)
       ↓
TaskRepository.createTask()
       ↓
DatabaseHelper.insert()
       ↓
SQLite Database
       ↓
Task ID (Return)
       ↓
UI Update (Provider)
```

### Task Retrieval Flow

```
UI Request
       ↓
TaskProvider.loadTasks()
       ↓
TaskRepository.getAllTasks()
       ↓
DatabaseHelper.query()
       ↓
SQLite Database
       ↓
Task List (Return)
       ↓
UI Update (Provider)
```

### Error Handling Flow

```
Database Error
       ↓
Repository Catch Exception
       ↓
Provider Error State
       ↓
UI Error Display
```

---

## State Management

### Provider Architecture

#### State Providers

1. **TaskProvider**: Task-related state and operations
2. **UserProvider**: Authentication and profile state
3. **ThemeProvider**: Theme and appearance preferences

#### State Updates

```dart
// Reactive state updates
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  
  List<Task> get tasks => _tasks;
  
  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners(); // Triggers UI rebuild
  }
}
```

#### State Persistence

```dart
// Save state to local storage
class UserProvider extends ChangeNotifier {
  Future<void> _saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
  }
}
```

---

## Navigation

### Go Router Configuration

```dart
class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
      GoRoute(path: '/tasks', builder: (context, state) => TasksScreen()),
      // ... other routes
    ],
  );
}
```

### Navigation Patterns

- **Declarative Routes**: Configuration-based routing
- **Deep Linking**: Support for app links
- **Route Guards**: Authentication and authorization
- **Navigation History**: Browser back button support

---

## Database Design

### Schema Design

#### Tables

```sql
-- Users Table
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar TEXT,
  created_at INTEGER NOT NULL,
  last_login_at INTEGER,
  preferences TEXT, -- JSON string
  is_email_verified INTEGER NOT NULL DEFAULT 0,
  is_premium INTEGER NOT NULL DEFAULT 0
);

-- Tasks Table
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  priority INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'todo',
  category TEXT NOT NULL DEFAULT 'work',
  due_date INTEGER,
  user_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  completed_at INTEGER,
  tags TEXT, -- JSON array
  is_recurring INTEGER NOT NULL DEFAULT 0,
  recurrence_pattern TEXT,
  estimated_minutes INTEGER,
  actual_minutes INTEGER,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Settings Table
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  user_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### Indexes

```sql
-- Performance indexes
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_category ON tasks(category);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);
```

### Data Integrity

#### Foreign Keys
- **Cascading Deletes**: User deletion removes related tasks
- **Referential Integrity**: Valid user references required
- **Constraint Enforcement**: Database-level validation

#### Data Types

```dart
// Enum mappings for type safety
enum TaskPriority {
  low('Low', 1, Colors.grey),
  medium('Medium', 2, Colors.orange),
  high('High', 3, Colors.red),
  urgent('Urgent', 4, Colors.purple);
}

enum TaskStatus {
  todo('To Do', Colors.blue),
  inProgress('In Progress', Colors.orange),
  completed('Completed', Colors.green),
  cancelled('Cancelled', Colors.grey);
}
```

---

## Security Architecture

### Authentication Flow

```
Login Attempt
       ↓
UserProvider.login()
       ↓
Input Validation
       ↓
Password Hashing (bcrypt)
       ↓
Database Query
       ↓
User Authentication
       ↓
JWT Token Generation
       ↓
Secure Storage
```

### Data Protection

#### Encryption

```dart
// Sensitive data encryption
import 'package:crypto/crypto.dart';

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final hash = sha256.convert(bytes);
  return hash.toString();
}
```

#### Secure Storage

```dart
// SharedPreferences for non-sensitive data
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
}
```

### Permission Management

```dart
// Runtime permission requests
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
```

---

## Performance Considerations

### Database Optimization

- **Connection Pooling**: Reuse database connections
- **Query Optimization**: Use efficient queries with proper indexing
- **Batch Operations**: Group multiple operations in transactions
- **Lazy Loading**: Load data on demand

### UI Performance

- **Widget Reuse**: Use const constructors where possible
- **Image Optimization**: Use appropriate image formats and caching
- **List Optimization**: Use ListView.builder for large lists
- **State Management**: Minimize unnecessary rebuilds

### Memory Management

- **Resource Disposal**: Properly dispose controllers and subscriptions
- **Image Caching**: Implement image memory management
- **Garbage Collection**: Monitor and optimize memory usage
- **Background Processing**: Use isolates for heavy computations

---

## Testing Architecture

### Test Organization

```
test/
├── unit/                    # Unit tests
│   ├── providers/
│   ├── repositories/
│   ├── models/
│   └── utils/
├── widget/                  # Widget tests
├── integration/             # Integration tests
└── helper/                 # Test utilities
```

### Test Patterns

#### Unit Testing

```dart
// Repository testing with mocks
class TaskRepositoryTest {
  late MockDatabaseHelper mockDatabase;
  late TaskRepository repository;

  setUp(() {
    mockDatabase = MockDatabaseHelper();
    repository = TaskRepositoryImpl(mockDatabase);
  });

  test('should retrieve all tasks', () async {
    when(mockDatabase.query(any, any, any, any, any, any, any))
        .thenAnswer((_) async => [
          {'id': '1', 'title': 'Task 1'},
          {'id': '2', 'title': 'Task 2'},
        ]);

    final tasks = await repository.getAllTasks();
    expect(tasks.length, 2);
  });
}
```

#### Widget Testing

```dart
// Widget testing with golden tests
testWidgets('TaskCard matches golden', (tester) async {
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

  await expect(find.byType(TaskCard), matchesGoldenFile('goldens/task_card.png'));
});
```

---

## Scalability Considerations

### Horizontal Scaling

- **Microservices Ready**: Repository pattern supports service separation
- **API Integration**: Abstracted data layer supports remote APIs
- **Caching Strategy**: Local caching for offline functionality
- **Load Balancing**: Database connection management

### Vertical Scaling

- **Database Sharding**: User-based data partitioning
- **Feature Flags**: Gradual feature rollout capability
- **Performance Monitoring**: Built-in metrics and analytics
- **Resource Optimization**: Memory and CPU usage monitoring

---

## Technology Stack

### Core Technologies

- **Flutter**: UI framework and cross-platform development
- **Dart**: Programming language and core libraries
- **SQLite**: Local database and persistence
- **Provider**: State management and dependency injection
- **Go Router**: Declarative navigation
- **Material Design 3**: UI component library

### Development Tools

- **Flutter CLI**: Command-line tools and build system
- **Dart DevTools**: Development and debugging tools
- **Flutter Inspector**: UI inspection and debugging
- **Code Analysis**: Static analysis and linting

---

## Future Enhancements

### Planned Improvements

1. **BLoC Integration**: Advanced state management option
2. **Cloud Sync**: Multi-device synchronization
3. **Offline Support**: Enhanced offline capabilities
4. **Analytics Integration**: Usage tracking and insights
5. **Plugin Architecture**: Modular feature development

### Migration Strategy

- **Version Compatibility**: Support for older app versions
- **Data Migration**: Smooth database schema updates
- **Configuration Migration**: Settings and preference updates
- **Rollback Capability**: Quick reversion if needed

---

*Last updated: February 2026*
*Version: 1.0.0*
