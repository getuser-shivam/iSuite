# iSuite Architecture Overview

## Table of Contents

- [Introduction](#introduction)
- [Architecture Principles](#architecture-principles)
- [Project Structure](#project-structure)
- [Design Patterns](#design-patterns)
- [Data Flow](#data-flow)
- [State Management](#state-management)
- [Database Architecture](#database-architecture)
- [Security Architecture](#security-architecture)
- [Performance Considerations](#performance-considerations)
- [Scalability Design](#scalability-design)

---

## Introduction

iSuite is built using Clean Architecture principles to ensure maintainability, testability, and scalability. This document outlines the architectural decisions, patterns, and guidelines used throughout the application.

### Architecture Goals

- **Separation of Concerns**: Clear boundaries between layers
- **Testability**: Easy unit and integration testing
- **Maintainability**: Code that's easy to understand and modify
- **Scalability**: Architecture that grows with the application
- **Performance**: Optimized for mobile and desktop platforms

---

## Architecture Principles

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│           Presentation              │  ← UI Layer
│  (Screens, Widgets, Providers)      │
├─────────────────────────────────────┤
│             Domain                  │  ← Business Logic
│  (Entities, Use Cases, Repositories)│
├─────────────────────────────────────┤
│              Data                   │  ← Data Layer
│   (Models, Repositories, Services)   │
└─────────────────────────────────────┘
```

### Dependency Rule

**Dependencies point inward**:
- Presentation depends on Domain
- Data depends on Domain
- Domain has no dependencies

### SOLID Principles

1. **Single Responsibility**: Each class has one reason to change
2. **Open/Closed**: Open for extension, closed for modification
3. **Liskov Substitution**: Subtypes must be substitutable
4. **Interface Segregation**: Clients shouldn't depend on unused interfaces
5. **Dependency Inversion**: Depend on abstractions, not concretions

---

## Project Structure

### Directory Organization

```
lib/
├── core/                          # Core utilities
│   ├── app_theme.dart            # Theme configuration
│   ├── app_router.dart           # Navigation routing
│   ├── constants.dart            # App constants
│   ├── database_helper.dart      # Database management
│   ├── supabase_client.dart     # Supabase integration
│   └── notification_service.dart # Notification handling
├── data/                          # Data layer implementation
│   ├── models/                   # Data models
│   │   ├── task_model.dart
│   │   ├── user_model.dart
│   │   └── note_model.dart
│   ├── repositories/             # Repository implementations
│   │   ├── task_repository_impl.dart
│   │   ├── user_repository_impl.dart
│   │   └── note_repository_impl.dart
│   └── services/                 # External services
│       ├── api_service.dart
│       └── storage_service.dart
├── domain/                        # Business logic layer
│   ├── entities/                 # Business entities
│   │   ├── task.dart
│   │   ├── user.dart
│   │   └── note.dart
│   ├── repositories/             # Repository interfaces
│   │   ├── task_repository.dart
│   │   ├── user_repository.dart
│   │   └── note_repository.dart
│   └── usecases/                 # Business use cases
│       ├── create_task_usecase.dart
│       ├── get_tasks_usecase.dart
│       └── update_task_usecase.dart
└── presentation/                  # UI layer
    ├── providers/                # State management
    │   ├── task_provider.dart
    │   ├── user_provider.dart
    │   └── theme_provider.dart
    ├── screens/                  # UI screens
    │   ├── home_screen.dart
    │   ├── tasks_screen.dart
    │   └── settings_screen.dart
    └── widgets/                  # Reusable widgets
        ├── task_card.dart
        ├── custom_button.dart
        └── loading_widget.dart
```

### Layer Responsibilities

#### Core Layer
- **App Theme**: Centralized theme management
- **App Router**: Navigation configuration
- **Constants**: Application-wide constants
- **Database Helper**: SQLite database management
- **Services**: Cross-cutting concerns (notifications, API)

#### Data Layer
- **Models**: Data transfer objects and entities
- **Repositories**: Data access implementations
- **Services**: External API and storage integrations

#### Domain Layer
- **Entities**: Core business objects
- **Repository Interfaces**: Data access contracts
- **Use Cases**: Business logic operations

#### Presentation Layer
- **Providers**: State management with Provider pattern
- **Screens**: UI screens and pages
- **Widgets**: Reusable UI components

---

## Design Patterns

### Repository Pattern

```dart
// Domain Layer - Interface
abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<Task?> getTaskById(String id);
  Future<void> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
}

// Data Layer - Implementation
class TaskRepositoryImpl implements TaskRepository {
  final DatabaseHelper _databaseHelper;
  
  TaskRepositoryImpl(this._databaseHelper);
  
  @override
  Future<List<Task>> getTasks() async {
    final data = await _databaseHelper.getTasks();
    return data.map((e) => Task.fromMap(e)).toList();
  }
  
  // ... other implementations
}
```

### Provider Pattern for State Management

```dart
class TaskProvider extends ChangeNotifier {
  final TaskRepository _taskRepository;
  List<Task> _tasks = [];
  bool _isLoading = false;
  
  TaskProvider(this._taskRepository);
  
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _tasks = await _taskRepository.getTasks();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Use Case Pattern

```dart
class CreateTaskUseCase {
  final TaskRepository _repository;
  
  CreateTaskUseCase(this._repository);
  
  Future<void> execute(Task task) async {
    // Business validation
    if (task.title.isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }
    
    // Additional business logic
    task.createdAt = DateTime.now();
    task.isCompleted = false;
    
    await _repository.createTask(task);
  }
}
```

### Factory Pattern for Dependency Injection

```dart
class ServiceFactory {
  static TaskRepository createTaskRepository() {
    return TaskRepositoryImpl(DatabaseHelper());
  }
  
  static TaskProvider createTaskProvider() {
    return TaskProvider(createTaskRepository());
  }
}
```

---

## Data Flow

### Typical Data Flow Example

```
User Action (Button Click)
    ↓
UI Widget (Presentation)
    ↓
Provider (State Management)
    ↓
Use Case (Business Logic)
    ↓
Repository (Data Access)
    ↓
Data Source (Database/API)
```

### Detailed Flow for Creating a Task

1. **User Interaction**
   ```dart
   ElevatedButton(
     onPressed: () => provider.createTask(title, description),
     child: Text('Create Task'),
   )
   ```

2. **Provider Method**
   ```dart
   Future<void> createTask(String title, String description) async {
     final task = Task(title: title, description: description);
     await _createTaskUseCase.execute(task);
     await loadTasks(); // Refresh list
   }
   ```

3. **Use Case Execution**
   ```dart
   Future<void> execute(Task task) async {
     // Business validation
     validateTask(task);
     
     // Call repository
     await _repository.createTask(task);
   }
   ```

4. **Repository Implementation**
   ```dart
   Future<void> createTask(Task task) async {
     final data = task.toMap();
     await _databaseHelper.insert('tasks', data);
   }
   ```

5. **Database Operation**
   ```dart
   Future<void> insert(String table, Map<String, dynamic> data) async {
     final db = await database;
     await db.insert(table, data);
   }
   ```

---

## State Management

### Provider Architecture

```dart
// Main app setup
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        // ... other providers
      ],
      child: const iSuiteApp(),
    ),
  );
}
```

### Provider Hierarchy

```
App (MultiProvider)
├── ThemeProvider
├── UserProvider
├── TaskProvider
├── CalendarProvider
├── NoteProvider
├── FileProvider
├── AnalyticsProvider
├── BackupProvider
├── SearchProvider
├── ReminderProvider
├── TaskSuggestionProvider
├── TaskAutomationProvider
├── NetworkProvider
├── FileSharingProvider
└── CloudSyncProvider
```

### State Management Patterns

1. **Simple State**: Using `ChangeNotifier` for basic state
2. **Complex State**: Using `Bloc` with `Provider` for complex logic
3. **Global State**: Shared providers across the app
4. **Local State**: `StatefulWidget` for component-specific state

---

## Database Architecture

### SQLite Schema Design

```sql
-- Users table
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Tasks table
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  priority INTEGER DEFAULT 0,
  is_completed INTEGER DEFAULT 0,
  due_date INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Notes table
CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  category TEXT,
  is_pinned INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Calendar events table
CREATE TABLE calendar_events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  start_time INTEGER NOT NULL,
  end_time INTEGER NOT NULL,
  location TEXT,
  is_all_day INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id)
);
```

### Database Helper Architecture

```dart
class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = 'isuite.db';
  static const int _databaseVersion = 1;
  
  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Create all tables
    await _createUserTable(db);
    await _createTaskTable(db);
    await _createNoteTable(db);
    await _createCalendarTable(db);
  }
}
```

### Repository Pattern for Data Access

```dart
abstract class BaseRepository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> create(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
}

class TaskRepositoryImpl implements BaseRepository<Task> {
  final DatabaseHelper _databaseHelper;
  
  TaskRepositoryImpl(this._databaseHelper);
  
  @override
  Future<List<Task>> getAll() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('tasks', orderBy: 'created_at DESC');
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  @override
  Future<void> create(Task task) async {
    final db = await _databaseHelper.database;
    await db.insert('tasks', task.toMap());
  }
  
  // ... other methods
}
```

---

## Security Architecture

### Authentication Flow

```
Login Screen
    ↓
User Provider
    ↓
Authentication Service
    ↓
Supabase Auth
    ↓
JWT Token Storage
    ↓
Authenticated State
```

### Data Security Measures

1. **Local Storage Encryption**
   ```dart
   // Using flutter_secure_storage for sensitive data
   final storage = FlutterSecureStorage();
   await storage.write(key: 'auth_token', value: token);
   ```

2. **API Security**
   ```dart
   // HTTPS with certificate pinning
   final dio = Dio();
   dio.options.baseUrl = 'https://api.isuite.app';
   dio.interceptors.add(AuthInterceptor());
   ```

3. **Input Validation**
   ```dart
   class ValidationService {
     static bool isValidEmail(String email) {
       return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
     }
     
     static String? validatePassword(String? value) {
       if (value == null || value.length < 8) {
         return 'Password must be at least 8 characters';
       }
       return null;
     }
   }
   ```

### Permission Management

```dart
class PermissionService {
  static Future<bool> requestNotifications() async {
     final status = await Permission.notification.request();
     return status.isGranted;
  }
  
  static Future<bool> requestStorage() async {
     final status = await Permission.storage.request();
     return status.isGranted;
  }
}
```

---

## Performance Considerations

### Memory Management

1. **Lazy Loading**
   ```dart
   class LazyList<T> {
     final List<T> Function() _loader;
     List<T>? _items;
     
     LazyList(this._loader);
     
     List<T> get items {
       _items ??= _loader();
       return _items!;
     }
   }
   ```

2. **Image Caching**
   ```dart
   class CachedImage extends StatelessWidget {
     final String url;
     
     const CachedImage({Key? key, required this.url}) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       return Image.network(
         url,
         cacheWidth: 300,
         cacheHeight: 300,
         loadingBuilder: (context, child, loadingProgress) {
           return loadingProgress == null ? child : CircularProgressIndicator();
         },
       );
     }
   }
   ```

3. **Database Optimization**
   ```dart
   // Using transactions for bulk operations
   Future<void> createMultipleTasks(List<Task> tasks) async {
     final db = await database;
     final batch = db.batch();
     
     for (final task in tasks) {
       batch.insert('tasks', task.toMap());
     }
     
     await batch.commit();
   }
   ```

### Performance Monitoring

```dart
class PerformanceMonitor {
  static void trackScreenTime(String screenName) {
     final startTime = DateTime.now();
     
     return () {
       final endTime = DateTime.now();
       final duration = endTime.difference(startTime);
       
       // Log performance metrics
       debugPrint('$screenName took ${duration.inMilliseconds}ms');
     };
  }
}
```

---

## Scalability Design

### Modular Architecture

The application is designed to scale through:

1. **Feature Modules**: Each feature is a self-contained module
2. **Plugin Architecture**: Easy to add new features
3. **Service Layer**: Abstracted services for easy replacement
4. **Configuration-Driven**: Feature flags and configuration

### Future Scalability Considerations

1. **Microservices Ready**: Repository pattern allows easy migration
2. **Cloud Integration**: Supabase integration for cloud features
3. **Multi-tenant Support**: User-based data isolation
4. **API Versioning**: Structured API design for versioning

### Extension Points

```dart
// Plugin interface for extensions
abstract class iSuitePlugin {
  String get name;
  String get version;
  Future<void> initialize();
  Widget? get mainScreen;
  List<Provider> get providers;
}

// Example plugin implementation
class CalendarPlugin implements iSuitePlugin {
  @override
  String get name => 'Calendar';
  
  @override
  String get version => '1.0.0';
  
  @override
  Future<void> initialize() async {
    // Initialize calendar service
  }
  
  @override
  Widget get mainScreen => CalendarScreen();
  
  @override
  List<Provider> get providers => [
    ChangeNotifierProvider(create: (_) => CalendarProvider()),
  ];
}
```

---

## Conclusion

This architecture provides a solid foundation for the iSuite application, ensuring:

- **Maintainability**: Clear separation of concerns
- **Testability**: Easy unit and integration testing
- **Scalability**: Architecture that grows with features
- **Performance**: Optimized for mobile platforms
- **Security**: Built-in security measures

The architecture follows industry best practices and Flutter/Dart conventions, making it easy for developers to understand and contribute to the project.

---

**Note**: This architecture document is continuously updated as the application evolves. Check the repository for the latest version.
