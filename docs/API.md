# iSuite API Documentation

## Overview

This document provides comprehensive API documentation for the iSuite application's data layer, providers, and core utilities.

## Table of Contents

- [Database Helper API](#database-helper-api)
- [Task Repository API](#task-repository-api)
- [User Provider API](#user-provider-api)
- [Task Provider API](#task-provider-api)
- [Theme Provider API](#theme-provider-api)
- [Utilities API](#utilities-api)

---

## Database Helper API

### Class: `DatabaseHelper`

Singleton class that manages SQLite database operations for the iSuite application.

#### Methods

##### `Future<Database> get database`
Returns the initialized database instance.

**Returns:** `Future<Database>` - The database instance

**Example:**
```dart
final db = await DatabaseHelper.instance.database;
```

##### `Future<int> insert(String table, Map<String, dynamic> data)`
Inserts a new record into the specified table.

**Parameters:**
- `table` (String): Table name
- `data` (Map<String, dynamic>): Data to insert

**Returns:** `Future<int>` - The ID of the inserted record

**Example:**
```dart
final taskId = await DatabaseHelper.instance.insert('tasks', taskData);
```

##### `Future<List<Map<String, dynamic>>> query(String table, {...})`
Queries records from the specified table.

**Parameters:**
- `table` (String): Table name
- `distinct` (bool?): Whether to return distinct rows
- `columns` (List<String>?): Specific columns to return
- `where` (String?): WHERE clause
- `whereArgs` (List<dynamic>?): Arguments for WHERE clause
- `groupBy` (String?): GROUP BY clause
- `having` (String?): HAVING clause
- `orderBy` (String?): ORDER BY clause
- `limit` (int?): LIMIT clause
- `offset` (int?): OFFSET clause

**Returns:** `Future<List<Map<String, dynamic>>>` - Query results

**Example:**
```dart
final tasks = await DatabaseHelper.instance.query(
  'tasks',
  where: 'status = ?',
  whereArgs: ['completed'],
  orderBy: 'createdAt DESC',
);
```

##### `Future<int> update(String table, Map<String, dynamic> values, {...})`
Updates records in the specified table.

**Parameters:**
- `table` (String): Table name
- `values` (Map<String, dynamic>): Data to update
- `where` (String?): WHERE clause
- `whereArgs` (List<dynamic>?): Arguments for WHERE clause

**Returns:** `Future<int>` - Number of affected rows

**Example:**
```dart
final count = await DatabaseHelper.instance.update(
  'tasks',
  {'status': 'completed'},
  where: 'id = ?',
  whereArgs: [taskId],
);
```

##### `Future<int> delete(String table, {...})`
Deletes records from the specified table.

**Parameters:**
- `table` (String): Table name
- `where` (String?): WHERE clause
- `whereArgs` (List<dynamic>?): Arguments for WHERE clause

**Returns:** `Future<int>` - Number of deleted rows

**Example:**
```dart
final count = await DatabaseHelper.instance.delete(
  'tasks',
  where: 'id = ?',
  whereArgs: [taskId],
);
```

---

## Task Repository API

### Class: `TaskRepository`

Repository class that provides high-level task operations using the DatabaseHelper.

#### Methods

##### `Future<List<Task>> getAllTasks({String? userId})`
Retrieves all tasks for a user.

**Parameters:**
- `userId` (String?): User ID filter

**Returns:** `Future<List<Task>>` - List of tasks

**Example:**
```dart
final tasks = await TaskRepository.getAllTasks(userId: 'user123');
```

##### `Future<List<Task>> getTasksByStatus(TaskStatus status, {String? userId})`
Retrieves tasks filtered by status.

**Parameters:**
- `status` (TaskStatus): Status filter
- `userId` (String?): User ID filter

**Returns:** `Future<List<Task>>` - Filtered task list

**Example:**
```dart
final completedTasks = await TaskRepository.getTasksByStatus(TaskStatus.completed);
```

##### `Future<List<Task>> getTasksByCategory(TaskCategory category, {String? userId})`
Retrieves tasks filtered by category.

**Parameters:**
- `category` (TaskCategory): Category filter
- `userId` (String?): User ID filter

**Returns:** `Future<List<Task>>` - Filtered task list

**Example:**
```dart
final workTasks = await TaskRepository.getTasksByCategory(TaskCategory.work);
```

##### `Future<List<Task>> getTasksDueToday({String? userId})`
Retrieves tasks due today.

**Parameters:**
- `userId` (String?): User ID filter

**Returns:** `Future<List<Task>>` - Tasks due today

**Example:**
```dart
final todayTasks = await TaskRepository.getTasksDueToday();
```

##### `Future<List<Task>> getOverdueTasks({String? userId})`
Retrieves overdue tasks.

**Parameters:**
- `userId` (String?): User ID filter

**Returns:** `Future<List<Task>>` - Overdue tasks

**Example:**
```dart
final overdueTasks = await TaskRepository.getOverdueTasks();
```

##### `Future<List<Task>> searchTasks(String query, {String? userId})`
Searches tasks by query string.

**Parameters:**
- `query` (String): Search query
- `userId` (String?): User ID filter

**Returns:** `Future<List<Task>>` - Search results

**Example:**
```dart
final results = await TaskRepository.searchTasks('important project');
```

##### `Future<Task?> getTaskById(String id)`
Retrieves a specific task by ID.

**Parameters:**
- `id` (String): Task ID

**Returns:** `Future<Task?>` - Task object or null

**Example:**
```dart
final task = await TaskRepository.getTaskById('task123');
```

##### `Future<String> createTask(Task task)`
Creates a new task.

**Parameters:**
- `task` (Task): Task object to create

**Returns:** `Future<String>` - Created task ID

**Example:**
```dart
final taskId = await TaskRepository.createTask(newTask);
```

##### `Future<int> updateTask(Task task)`
Updates an existing task.

**Parameters:**
- `task` (Task): Task object with updated data

**Returns:** `Future<int>` - Number of affected rows

**Example:**
```dart
final count = await TaskRepository.updateTask(updatedTask);
```

##### `Future<int> deleteTask(String id)`
Deletes a task by ID.

**Parameters:**
- `id` (String): Task ID to delete

**Returns:** `Future<int>` - Number of deleted rows

**Example:**
```dart
final count = await TaskRepository.deleteTask('task123');
```

---

## User Provider API

### Class: `UserProvider`

State management provider for user authentication and profile data.

#### Properties

##### `User? user`
Current authenticated user object.

**Type:** `User?`

**Example:**
```dart
final user = Provider.of<UserProvider>(context).user;
```

##### `bool isLoading`
Loading state indicator.

**Type:** `bool`

**Example:**
```dart
final isLoading = Provider.of<UserProvider>(context).isLoading;
```

##### `bool isAuthenticated`
Whether user is authenticated.

**Type:** `bool`

**Example:**
```dart
final isLoggedIn = Provider.of<UserProvider>(context).isAuthenticated;
```

#### Methods

##### `Future<void> login(String email, String password, {bool rememberMe = true})`
Authenticates user with email and password.

**Parameters:**
- `email` (String): User email
- `password` (String): User password
- `rememberMe` (bool): Whether to remember login

**Example:**
```dart
await userProvider.login('user@example.com', 'password123');
```

##### `Future<void> register(String name, String email, String password, {String? confirmPassword})`
Registers a new user account.

**Parameters:**
- `name` (String): User display name
- `email` (String): User email
- `password` (String): User password
- `confirmPassword` (String?): Password confirmation

**Example:**
```dart
await userProvider.register('John Doe', 'john@example.com', 'password123');
```

##### `Future<void> logout({bool clearAll = false})`
Logs out the current user.

**Parameters:**
- `clearAll` (bool): Whether to clear all stored data

**Example:**
```dart
await userProvider.logout();
```

##### `Future<void> updateProfile({String? name, String? email, String? avatar})`
Updates user profile information.

**Parameters:**
- `name` (String?): Updated name
- `email` (String?): Updated email
- `avatar` (String?): Updated avatar URL

**Example:**
```dart
await userProvider.updateProfile(name: 'John Smith');
```

---

## Task Provider API

### Class: `TaskProvider`

State management provider for task operations and filtering.

#### Properties

##### `List<Task> tasks`
All tasks list.

**Type:** `List<Task>`

##### `List<Task> filteredTasks`
Currently filtered tasks based on active filters.

**Type:** `List<Task>`

##### `TaskStatus selectedStatus`
Current status filter.

**Type:** `TaskStatus`

##### `TaskCategory selectedCategory`
Current category filter.

**Type:** `TaskCategory`

##### `TaskPriority selectedPriority`
Current priority filter.

**Type:** `TaskPriority`

##### `String searchQuery`
Current search query.

**Type:** `String`

##### `bool isLoading`
Loading state indicator.

**Type:** `bool`

#### Computed Properties

##### `int totalTasks`
Total number of tasks.

##### `int completedTasks`
Number of completed tasks.

##### `int pendingTasks`
Number of pending tasks.

##### `int overdueTasks`
Number of overdue tasks.

##### `double completionRate`
Task completion percentage (0.0 to 1.0).

#### Methods

##### `Future<void> createTask({...})`
Creates a new task.

**Parameters:**
- `title` (String): Task title
- `description` (String?): Task description
- `priority` (TaskPriority): Task priority
- `category` (TaskCategory): Task category
- `dueDate` (DateTime?): Due date
- `tags` (List<String>): Task tags
- `estimatedMinutes` (int?): Estimated time in minutes

**Example:**
```dart
await taskProvider.createTask(
  title: 'Complete project',
  description: 'Finish the Flutter app',
  priority: TaskPriority.high,
  category: TaskCategory.work,
  dueDate: DateTime.now().add(Duration(days: 1)),
);
```

##### `Future<void> updateTask(Task task)`
Updates an existing task.

**Parameters:**
- `task` (Task): Task object with updated data

**Example:**
```dart
await taskProvider.updateTask(updatedTask);
```

##### `Future<void> deleteTask(String taskId)`
Deletes a task.

**Parameters:**
- `taskId` (String): ID of task to delete

**Example:**
```dart
await taskProvider.deleteTask('task123');
```

##### `Future<void> toggleTaskCompletion(Task task)`
Toggles task completion status.

**Parameters:**
- `task` (Task): Task to toggle

**Example:**
```dart
await taskProvider.toggleTaskCompletion(task);
```

##### `void setStatusFilter(TaskStatus status)`
Sets status filter.

**Parameters:**
- `status` (TaskStatus): Status filter

**Example:**
```dart
taskProvider.setStatusFilter(TaskStatus.completed);
```

##### `void setCategoryFilter(TaskCategory category)`
Sets category filter.

**Parameters:**
- `category` (TaskCategory): Category filter

**Example:**
```dart
taskProvider.setCategoryFilter(TaskCategory.personal);
```

##### `void setSearchQuery(String query)`
Sets search query.

**Parameters:**
- `query` (String): Search query

**Example:**
```dart
taskProvider.setSearchQuery('important');
```

##### `void clearFilters()`
Clears all active filters.

**Example:**
```dart
taskProvider.clearFilters();
```

---

## Theme Provider API

### Class: `ThemeProvider`

State management provider for application theme settings.

#### Properties

##### `ThemeMode themeMode`
Current theme mode.

**Type:** `ThemeMode`

#### Methods

##### `Future<void> setThemeMode(ThemeMode themeMode)`
Sets the application theme mode.

**Parameters:**
- `themeMode` (ThemeMode): Theme mode to set

**Example:**
```dart
await themeProvider.setThemeMode(ThemeMode.dark);
```

##### `void toggleTheme()`
Toggles between theme modes.

**Example:**
```dart
themeProvider.toggleTheme();
```

---

## Utilities API

### Class: `AppUtils`

Utility class providing common helper methods.

#### Date/Time Methods

##### `static String formatDate(DateTime date, {String format = 'MM/dd/yyyy'})`
Formats a DateTime object to string.

**Parameters:**
- `date` (DateTime): Date to format
- `format` (String): Date format pattern

**Returns:** `String` - Formatted date string

##### `static String getRelativeTime(DateTime dateTime)`
Returns relative time string (e.g., "2 hours ago").

**Parameters:**
- `dateTime` (DateTime): Date to convert

**Returns:** `String` - Relative time string

#### Validation Methods

##### `static String? validateEmail(String? value)`
Validates email format.

**Parameters:**
- `value` (String?): Email to validate

**Returns:** `String?` - Error message or null if valid

##### `static String? validatePassword(String? value)`
Validates password strength.

**Parameters:**
- `value` (String?): Password to validate

**Returns:** `String?` - Error message or null if valid

#### UI Methods

##### `static void showSnackBar(BuildContext context, String message, {Color? backgroundColor})`
Shows a snackbar message.

**Parameters:**
- `context` (BuildContext): Build context
- `message` (String): Message to display
- `backgroundColor` (Color?): Optional background color

**Example:**
```dart
AppUtils.showSnackBar(context, 'Task completed successfully');
```

---

## Error Handling

All API methods include comprehensive error handling:

- Database operations throw exceptions on failure
- Provider methods set error states for UI display
- Validation methods return descriptive error messages
- All async methods handle connection timeouts

## Best Practices

1. **Always check for null values** when accessing optional parameters
2. **Handle exceptions** when calling async methods
3. **Use proper error messages** for user feedback
4. **Dispose resources** properly to avoid memory leaks
5. **Use proper typing** for all method parameters and returns

## Performance Considerations

- Database queries use proper indexing
- Provider updates are batched when possible
- Large datasets use pagination
- UI updates are optimized to minimize rebuilds
