# Reminders Feature Documentation

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Data Models](#data-models)
- [User Interface](#user-interface)
- [Implementation Details](#implementation-details)
- [API Reference](#api-reference)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)

---

## Overview

The Reminders feature in iSuite provides a comprehensive notification and alert system that helps users stay on top of their tasks, events, and important dates. It integrates seamlessly with the task management and calendar systems to provide timely reminders through multiple notification channels.

### Key Capabilities

- **Multiple Reminder Types**: Task reminders, event reminders, custom reminders
- **Flexible Scheduling**: One-time, recurring, and location-based reminders
- **Rich Notifications**: Sound, vibration, LED, and custom notification styles
- **Smart Snoozing**: Intelligent snooze options with adaptive timing
- **Cross-Platform**: Works on Android, iOS, and Windows
- **Backup & Sync**: Cloud synchronization across devices

---

## Features

### Core Reminder Features

#### 1. Reminder Types
- **Task Reminders**: Automatically created with task due dates
- **Event Reminders**: Calendar event notifications
- **Custom Reminders**: Standalone reminders for personal use
- **Location Reminders**: GPS-based location triggers (mobile only)
- **Recurring Reminders**: Daily, weekly, monthly, or custom patterns

#### 2. Notification Methods
- **Push Notifications**: Native device notifications
- **Email Reminders**: Email notifications for important events
- **SMS Reminders**: Text message alerts (premium feature)
- **In-App Notifications**: Banner and modal notifications within app

#### 3. Scheduling Options
- **Absolute Time**: Specific date and time
- **Relative Time**: Minutes/hours before event
- **Recurring Patterns**: Complex recurrence rules
- **Smart Scheduling**: AI-powered optimal timing
- **Timezone Awareness**: Automatic timezone adjustments

#### 4. Notification Customization
- **Sound Selection**: Custom notification sounds
- **Vibration Patterns**: Custom vibration sequences
- **LED Colors**: Device LED notification colors
- **Notification Priority**: High/normal/low priority levels
- **Do Not Disturb**: Respect device DND settings

### Advanced Features

#### 1. Smart Reminders
- **Context-Aware**: Based on user behavior and patterns
- **Priority-Based**: Higher priority for important tasks
- **Adaptive Timing**: Learns optimal reminder times
- **Batch Notifications**: Group similar reminders

#### 2. Reminder Analytics
- **Response Tracking**: Monitor reminder effectiveness
- **Dismissal Patterns**: Analyze user behavior
- **Optimization Suggestions**: AI-powered improvements
- **Performance Metrics**: Delivery success rates

#### 3. Integration Features
- **Task Integration**: Automatic task reminder creation
- **Calendar Sync**: Import calendar event reminders
- **Third-Party Apps**: Integration with external apps
- **API Access**: Programmatic reminder management

---

## Architecture

### Component Architecture

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  ┌─────────────┐ ┌─────────────────┐│
│  │ReminderScreen│ │ReminderWidget   ││
│  │ReminderList │ │NotificationView ││
│  └─────────────┘ └─────────────────┘│
├─────────────────────────────────────┤
│         Provider Layer              │
│  ┌─────────────────────────────────┐│
│  │     ReminderProvider            ││
│  │  - State Management             ││
│  │  - Notification Handling        ││
│  │  - Scheduling Logic            ││
│  └─────────────────────────────────┘│
├─────────────────────────────────────┤
│         Domain Layer                │
│  ┌─────────────┐ ┌─────────────────┐│
│  │Reminder     │ │ReminderUseCase  ││
│  │Entity       │ │- CreateReminder ││
│  │             │ │- UpdateReminder ││
│  │             │ │- DeleteReminder ││
│  └─────────────┘ └─────────────────┘│
├─────────────────────────────────────┤
│          Data Layer                 │
│  ┌─────────────┐ ┌─────────────────┐│
│  │ReminderRepo │ │NotificationSvc ││
│  │Implementation│ │- Local Notifications││
│  │             │ │- Push Notifications││
│  └─────────────┘ └─────────────────┘│
└─────────────────────────────────────┘
```

### Data Flow

```
User Action (Create Reminder)
    ↓
ReminderScreen (UI)
    ↓
ReminderProvider (State)
    ↓
CreateReminderUseCase (Business Logic)
    ↓
ReminderRepository (Data Access)
    ↓
Database + NotificationService (Storage + Notification)
    ↓
System Notification Manager (OS)
    ↓
User Receives Notification
```

### Key Components

#### 1. ReminderProvider
```dart
class ReminderProvider extends ChangeNotifier {
  final ReminderRepository _repository;
  final NotificationService _notificationService;
  
  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _error;
  
  // State management
  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Core operations
  Future<void> loadReminders();
  Future<void> createReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String reminderId);
  Future<void> snoozeReminder(String reminderId, Duration duration);
  
  // Notification handling
  Future<void> scheduleNotification(Reminder reminder);
  Future<void> cancelNotification(String reminderId);
  Future<void> handleNotificationResponse(NotificationResponse response);
}
```

#### 2. NotificationService
```dart
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  Future<void> initialize();
  Future<void> scheduleReminder(Reminder reminder);
  Future<void> cancelReminder(String reminderId);
  Future<void> updateReminder(Reminder reminder);
  
  // Platform-specific implementations
  Future<void> _initializeAndroid();
  Future<void> _initializeIOS();
  Future<void> _initializeWindows();
  
  // Notification customization
  Future<void> showCustomNotification({
    required String title,
    required String body,
    required String payload,
    NotificationDetails? details,
  });
}
```

---

## Data Models

### Reminder Entity

```dart
class Reminder {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final ReminderType type;
  final String? targetId; // Task or Event ID
  final DateTime triggerTime;
  final RecurrencePattern? recurrencePattern;
  final NotificationMethod notificationMethod;
  final bool isActive;
  final bool isCompleted;
  final ReminderPriority priority;
  final String? sound;
  final VibrationPattern? vibrationPattern;
  final String? ledColor;
  final int snoozeCount;
  final DateTime? nextTriggerTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? triggeredAt;
  final DateTime? completedAt;

  const Reminder({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    this.targetId,
    required this.triggerTime,
    this.recurrencePattern,
    this.notificationMethod = NotificationMethod.push,
    this.isActive = true,
    this.isCompleted = false,
    this.priority = ReminderPriority.normal,
    this.sound,
    this.vibrationPattern,
    this.ledColor,
    this.snoozeCount = 0,
    this.nextTriggerTime,
    required this.createdAt,
    required this.updatedAt,
    this.triggeredAt,
    this.completedAt,
  });

  // Serialization
  Map<String, dynamic> toMap() { /* ... */ }
  factory Reminder.fromMap(Map<String, dynamic> map) { /* ... */ }
  
  // Business logic
  bool get isOverdue => DateTime.now().isAfter(triggerTime) && !isCompleted;
  bool get isDueToday => DateTime.now().isSameDayAs(triggerTime);
  Reminder copyWith({/* parameters */}) { /* ... */ }
}
```

### Recurrence Pattern

```dart
class RecurrencePattern {
  final RecurrenceFrequency frequency;
  final int interval;
  final List<int> daysOfWeek; // For weekly patterns
  final int dayOfMonth; // For monthly patterns
  final int monthOfYear; // For yearly patterns
  final DateTime? endDate;
  final int? count; // Number of occurrences
  final Set<DateTime>? exceptions; // Exception dates

  const RecurrencePattern({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.dayOfMonth,
    this.monthOfYear,
    this.endDate,
    this.count,
    this.exceptions,
  });

  DateTime? getNextOccurrence(DateTime from);
  List<DateTime> getOccurrences(DateTime start, DateTime end);
  Map<String, dynamic> toMap();
  factory RecurrencePattern.fromMap(Map<String, dynamic> map);
}

enum RecurrenceFrequency {
  daily, weekly, monthly, yearly, custom
}
```

### Notification Settings

```dart
class NotificationSettings {
  final bool enabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool ledEnabled;
  final String defaultSound;
  final VibrationPattern defaultVibration;
  final String defaultLedColor;
  final Duration defaultSnoozeDuration;
  final bool doNotDisturbRespect;
  final TimeRange quietHours;
  final List<NotificationMethod> enabledMethods;

  const NotificationSettings({
    this.enabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.ledEnabled = true,
    this.defaultSound = 'default',
    this.defaultVibration = VibrationPattern.standard,
    this.defaultLedColor = '#2196F3',
    this.defaultSnoozeDuration = const Duration(minutes: 5),
    this.doNotDisturbRespect = true,
    this.quietHours = const TimeRange(start: Time(22, 0), end: Time(8, 0)),
    this.enabledMethods = const [NotificationMethod.push],
  });
}
```

---

## User Interface

### Reminder Screen Components

#### 1. Reminder List Screen
```dart
class RemindersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminders'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (provider.reminders.isEmpty) {
            return EmptyRemindersView();
          }
          
          return RefreshIndicator(
            onRefresh: provider.loadReminders,
            child: ListView.builder(
              itemCount: provider.reminders.length,
              itemBuilder: (context, index) {
                final reminder = provider.reminders[index];
                return ReminderCard(reminder: reminder);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateReminderDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

#### 2. Reminder Card Widget
```dart
class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  
  const ReminderCard({Key? key, required this.reminder}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          _getReminderIcon(reminder.type),
          color: _getReminderColor(reminder.priority),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatReminderTime(reminder.triggerTime)),
            if (reminder.description != null)
              Text(reminder.description!),
            if (reminder.recurrencePattern != null)
              Text(_formatRecurrence(reminder.recurrencePattern!)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!reminder.isCompleted)
              IconButton(
                icon: Icon(Icons.snooze),
                onPressed: () => _snoozeReminder(context, reminder),
              ),
            Switch(
              value: reminder.isActive,
              onChanged: (value) => _toggleReminder(context, reminder, value),
            ),
          ],
        ),
        onTap: () => _editReminder(context, reminder),
      ),
    );
  }
}
```

#### 3. Create/Edit Reminder Dialog
```dart
class ReminderDialog extends StatefulWidget {
  final Reminder? reminder;
  
  const ReminderDialog({Key? key, this.reminder}) : super(key: key);
  
  @override
  _ReminderDialogState createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _triggerTime;
  ReminderType _type = ReminderType.custom;
  ReminderPriority _priority = ReminderPriority.normal;
  RecurrencePattern? _recurrencePattern;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder?.title);
    _descriptionController = TextEditingController(text: widget.reminder?.description);
    _triggerTime = widget.reminder?.triggerTime;
    _type = widget.reminder?.type ?? ReminderType.custom;
    _priority = widget.reminder?.priority ?? ReminderPriority.normal;
    _recurrencePattern = widget.reminder?.recurrencePattern;
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.reminder == null ? 'Create Reminder' : 'Edit Reminder'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Trigger Time'),
                subtitle: Text(_triggerTime != null 
                    ? _formatDateTime(_triggerTime!) 
                    : 'Select time'),
                trailing: Icon(Icons.access_time),
                onTap: _selectDateTime,
              ),
              DropdownButtonFormField<ReminderType>(
                value: _type,
                decoration: InputDecoration(labelText: 'Type'),
                items: ReminderType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.name));
                }).toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              DropdownButtonFormField<ReminderPriority>(
                value: _priority,
                decoration: InputDecoration(labelText: 'Priority'),
                items: ReminderPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _priority = value!),
              ),
              ListTile(
                title: Text('Recurrence'),
                subtitle: Text(_recurrencePattern != null 
                    ? _formatRecurrence(_recurrencePattern!) 
                    : 'None'),
                trailing: Icon(Icons.repeat),
                onTap: _selectRecurrence,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveReminder,
          child: Text('Save'),
        ),
      ],
    );
  }
}
```

---

## Implementation Details

### Notification Scheduling

#### Android Implementation
```dart
class AndroidNotificationHelper {
  static const String channelId = 'reminder_channel';
  static const String channelName = 'Reminders';
  static const String channelDescription = 'Task and event reminders';
  
  static AndroidNotificationDetails _createAndroidDetails(Reminder reminder) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: _getImportance(reminder.priority),
      priority: _getPriority(reminder.priority),
      sound: reminder.sound != null ? RawResourceAndroidNotificationSound(reminder.sound!) : null,
      vibrationPattern: reminder.vibrationPattern?.pattern,
      ledColor: _getLedColor(reminder.ledColor),
      ledOnMs: 1000,
      ledOffMs: 500,
      enableLights: reminder.ledColor != null,
      enableVibration: reminder.vibrationPattern != null,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ongoing: false,
      autoCancel: true,
      fullScreenIntent: reminder.priority == ReminderPriority.urgent,
      actions: [
        AndroidNotificationAction('snooze', 'Snooze'),
        AndroidNotificationAction('complete', 'Complete'),
      ],
    );
  }
  
  static AndroidImportance _getImportance(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.urgent:
        return AndroidImportance.high;
      case ReminderPriority.high:
        return AndroidImportance.defaultImportance;
      case ReminderPriority.normal:
        return AndroidImportance.low;
      case ReminderPriority.low:
        return AndroidImportance.min;
    }
  }
}
```

#### iOS Implementation
```dart
class IOSNotificationHelper {
  static DarwinNotificationDetails _createIOSDetails(Reminder reminder) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: reminder.sound != null,
      sound: reminder.sound,
      badgeNumber: 1,
      interruptionLevel: _getInterruptionLevel(reminder.priority),
      threadIdentifier: reminder.id,
      categoryIdentifier: 'REMINDER_CATEGORY',
    );
  }
  
  static InterruptionLevel _getInterruptionLevel(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.urgent:
        return InterruptionLevel.timeSensitive;
      case ReminderPriority.high:
        return InterruptionLevel.active;
      case ReminderPriority.normal:
        return InterruptionLevel.passive;
      case ReminderPriority.low:
        return InterruptionLevel.none;
    }
  }
}
```

### Background Processing

#### Alarm Manager Setup
```dart
class ReminderScheduler {
  static const MethodChannel _channel = MethodChannel('reminder_scheduler');
  
  static Future<void> scheduleReminder(Reminder reminder) async {
    try {
      await _channel.invokeMethod('scheduleReminder', {
        'reminderId': reminder.id,
        'triggerTime': reminder.triggerTime.millisecondsSinceEpoch,
        'title': reminder.title,
        'description': reminder.description,
        'priority': reminder.priority.index,
        'recurrencePattern': reminder.recurrencePattern?.toMap(),
      });
    } catch (e) {
      debugPrint('Failed to schedule reminder: $e');
    }
  }
  
  static Future<void> cancelReminder(String reminderId) async {
    try {
      await _channel.invokeMethod('cancelReminder', {'reminderId': reminderId});
    } catch (e) {
      debugPrint('Failed to cancel reminder: $e');
    }
  }
}
```

#### Background Service
```dart
class ReminderBackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'reminder_service',
        initialNotificationTitle: 'iSuite Reminders',
        initialNotificationContent: 'Managing your reminders',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }
  
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }
  
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    
    service.on('checkReminders').listen((event) {
      _checkPendingReminders();
    });
    
    Timer.periodic(Duration(minutes: 1), (timer) {
      _checkPendingReminders();
    });
  }
  
  static Future<void> _checkPendingReminders() async {
    final provider = ReminderProvider();
    await provider.loadReminders();
    
    final now = DateTime.now();
    for (final reminder in provider.reminders) {
      if (reminder.isActive && 
          !reminder.isCompleted && 
          reminder.triggerTime.isBefore(now)) {
        await _triggerReminder(reminder);
      }
    }
  }
}
```

---

## API Reference

### ReminderProvider API

#### Methods

##### `Future<void> loadReminders()`
Loads all reminders for the current user.

**Returns:** `Future<void>`

**Example:**
```dart
final provider = ReminderProvider();
await provider.loadReminders();
```

##### `Future<void> createReminder(Reminder reminder)`
Creates a new reminder and schedules the notification.

**Parameters:**
- `reminder`: The reminder to create

**Returns:** `Future<void>`

**Example:**
```dart
final reminder = Reminder(
  id: uuid.v4(),
  userId: currentUser.id,
  title: 'Meeting with team',
  triggerTime: DateTime.now().add(Duration(hours: 1)),
  type: ReminderType.custom,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await provider.createReminder(reminder);
```

##### `Future<void> updateReminder(Reminder reminder)`
Updates an existing reminder and reschedules if necessary.

**Parameters:**
- `reminder`: The updated reminder

**Returns:** `Future<void>`

##### `Future<void> deleteReminder(String reminderId)`
Deletes a reminder and cancels its notification.

**Parameters:**
- `reminderId`: ID of the reminder to delete

**Returns:** `Future<void>`

##### `Future<void> snoozeReminder(String reminderId, Duration duration)`
Snoozes a reminder for the specified duration.

**Parameters:**
- `reminderId`: ID of the reminder to snooze
- `duration`: How long to snooze

**Returns:** `Future<void>`

**Example:**
```dart
await provider.snoozeReminder('reminder-123', Duration(minutes: 10));
```

### NotificationService API

#### Methods

##### `Future<void> initialize()`
Initializes the notification service with platform-specific settings.

**Returns:** `Future<void>`

##### `Future<void> scheduleReminder(Reminder reminder)`
Schedules a platform notification for the reminder.

**Parameters:**
- `reminder`: The reminder to schedule

**Returns:** `Future<void>`

##### `Future<void> cancelReminder(String reminderId)`
Cancels a scheduled notification.

**Parameters:**
- `reminderId`: ID of the reminder to cancel

**Returns:** `Future<void>`

---

## Usage Examples

### Basic Reminder Creation

```dart
// Create a simple one-time reminder
final reminder = Reminder(
  id: uuid.v4(),
  userId: 'user-123',
  title: 'Take medication',
  description: 'Remember to take your daily vitamins',
  triggerTime: DateTime.now().add(Duration(hours: 8)),
  type: ReminderType.custom,
  priority: ReminderPriority.high,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await reminderProvider.createReminder(reminder);
```

### Recurring Reminder

```dart
// Create a recurring daily reminder
final recurrencePattern = RecurrencePattern(
  frequency: RecurrenceFrequency.daily,
  interval: 1,
  endDate: DateTime.now().add(Duration(days: 30)),
);

final reminder = Reminder(
  id: uuid.v4(),
  userId: 'user-123',
  title: 'Daily standup meeting',
  triggerTime: DateTime.now().add(Duration(days: 1)),
  recurrencePattern: recurrencePattern,
  type: ReminderType.custom,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await reminderProvider.createReminder(reminder);
```

### Task-Linked Reminder

```dart
// Create a reminder linked to a task
final taskReminder = Reminder(
  id: uuid.v4(),
  userId: 'user-123',
  title: 'Complete project proposal',
  type: ReminderType.task,
  targetId: 'task-456',
  triggerTime: DateTime.now().add(Duration(days: 2)),
  priority: ReminderPriority.urgent,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await reminderProvider.createReminder(taskReminder);
```

### Custom Notification Settings

```dart
// Create reminder with custom notification settings
final customReminder = Reminder(
  id: uuid.v4(),
  userId: 'user-123',
  title: 'Important deadline',
  triggerTime: DateTime.now().add(Duration(hours: 1)),
  type: ReminderType.custom,
  priority: ReminderPriority.urgent,
  sound: 'urgent_alarm.mp3',
  vibrationPattern: VibrationPattern.urgent,
  ledColor: '#FF0000',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await reminderProvider.createReminder(customReminder);
```

---

## Troubleshooting

### Common Issues

#### 1. Notifications Not Showing

**Symptoms:** Reminders are created but no notifications appear.

**Possible Causes:**
- Notification permissions not granted
- Do Not Disturb mode enabled
- App notifications disabled in system settings
- Background service not running

**Solutions:**
```dart
// Check and request permissions
final status = await Permission.notification.request();
if (!status.isGranted) {
  // Show permission dialog
  await openAppSettings();
}

// Check DND settings
final isDND = await _checkDoNotDisturb();
if (isDND) {
  // Show warning about DND mode
}
```

#### 2. Reminders Not Triggering

**Symptoms:** Scheduled reminders don't fire at the correct time.

**Possible Causes:**
- Device in deep sleep mode
- Battery optimization killing app
- Time zone changes
- System time changes

**Solutions:**
```dart
// Request battery optimization exemption
if (await Permission.ignoreBatteryOptimizations.isDenied) {
  await Permission.ignoreBatteryOptimizations.request();
}

// Handle time zone changes
void _onTimeZoneChanged() {
  _rescheduleAllReminders();
}
```

#### 3. Duplicate Notifications

**Symptoms:** Multiple notifications for the same reminder.

**Possible Causes:**
- Multiple app instances
- Notification not properly cancelled
- Recurrence pattern issues

**Solutions:**
```dart
// Ensure single instance
await _cancelExistingNotification(reminder.id);
await _scheduleNewNotification(reminder);
```

### Debug Tools

#### Notification Debug Mode
```dart
class NotificationDebugger {
  static Future<void> testNotification() async {
    await notificationService.showCustomNotification(
      title: 'Test Notification',
      body: 'This is a test notification',
      payload: 'test',
    );
  }
  
  static Future<void> listScheduledNotifications() async {
    final notifications = await _notifications.pendingNotificationRequests();
    for (final notification in notifications) {
      debugPrint('Scheduled: ${notification.id} at ${notification.payload}');
    }
  }
}
```

#### Reminder State Inspector
```dart
class ReminderInspector {
  static Future<void> inspectReminder(String reminderId) async {
    final reminder = await reminderProvider.getReminderById(reminderId);
    
    debugPrint('Reminder Info:');
    debugPrint('  ID: ${reminder.id}');
    debugPrint('  Title: ${reminder.title}');
    debugPrint('  Trigger: ${reminder.triggerTime}');
    debugPrint('  Active: ${reminder.isActive}');
    debugPrint('  Completed: ${reminder.isCompleted}');
    debugPrint('  Next Trigger: ${reminder.nextTriggerTime}');
    
    // Check notification status
    final isScheduled = await _isNotificationScheduled(reminderId);
    debugPrint('  Notification Scheduled: $isScheduled');
  }
}
```

---

## Conclusion

The Reminders feature provides a comprehensive notification system that enhances the productivity suite by ensuring users never miss important tasks and events. With its flexible scheduling, rich customization options, and robust cross-platform support, it serves as a critical component of the iSuite ecosystem.

The feature is designed with scalability and maintainability in mind, using clean architecture principles and comprehensive testing to ensure reliable operation across all supported platforms.

---

**Note**: This documentation is updated with each feature version. Always refer to the latest version in the repository for current implementation details.
