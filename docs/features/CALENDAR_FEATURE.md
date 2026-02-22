# iSuite Calendar Feature Documentation

## Overview

The Calendar feature in iSuite provides comprehensive event management capabilities with scheduling, reminders, and recurring events. This documentation covers the complete implementation, usage, and integration of the calendar module.

## Table of Contents

- [Feature Overview](#feature-overview)
- [Architecture](#architecture)
- [Data Models](#data-models)
- [Repository Layer](#repository-layer)
- [State Management](#state-management)
- [UI Components](#ui-components)
- [Usage Examples](#usage-examples)
- [Integration Guide](#integration-guide)
- [API Reference](#api-reference)

---

## Feature Overview

### Core Capabilities

- **Event Management**: Create, read, update, and delete calendar events
- **Scheduling**: Set start/end times, due dates, and all-day events
- **Recurrence**: Support for daily, weekly, monthly, and yearly recurring events
- **Event Types**: Meeting, appointment, deadline, reminder, birthday, holiday, personal, work
- **Priority Levels**: Low, medium, high, urgent priority classification
- **Status Tracking**: Tentative, confirmed, cancelled, completed status management
- **Attendee Management**: Add and manage event attendees
- **Location Support**: Event location tracking and mapping
- **Tagging System**: Organize events with custom tags
- **Search & Filter**: Find events by title, description, tags, or date ranges

### User Interface Features

- **Calendar View**: Monthly, weekly, and daily calendar views
- **Event Cards**: Visual event representation with color coding
- **Quick Actions**: Fast event creation and management
- **Drag & Drop**: Move events between dates and times
- **Real-time Updates**: Live synchronization across all views
- **Responsive Design**: Optimized for mobile, tablet, and desktop

---

## Architecture

### Layer Structure

```
lib/
├── domain/
│   └── models/
│       └── calendar_event.dart          # Event domain model
├── data/
│   └── repositories/
│       └── calendar_repository.dart   # Data access layer
├── presentation/
│   ├── providers/
│   │   └── calendar_provider.dart     # State management
│   ├── screens/
│   │   └── calendar_screen.dart       # Main calendar UI
│   └── widgets/
│       ├── calendar_view.dart         # Calendar display widget
│       ├── event_card.dart            # Event card component
│       ├── event_dialog.dart          # Event creation/edit dialog
│       └── recurrence_picker.dart     # Recurrence selection
```

### Design Patterns

- **Repository Pattern**: Clean data access abstraction
- **Provider Pattern**: Reactive state management
- **Factory Pattern**: Event object creation
- **Observer Pattern**: UI updates on state changes

---

## Data Models

### CalendarEvent Model

The `CalendarEvent` class represents a calendar event with comprehensive properties:

```dart
class CalendarEvent extends Equatable {
  final String id;                    // Unique identifier
  final String title;                  // Event title
  final String? description;           // Event description
  final DateTime? startTime;           // Start time
  final DateTime? endTime;             // End time
  final DateTime? dueDate;             // Due date for deadlines
  final EventStatus status;            // Event status
  final EventType type;                // Event type
  final EventPriority priority;        // Priority level
  final RecurrenceType recurrence;     // Recurrence pattern
  final List<String> attendees;        // Attendee list
  final String? location;              // Event location
  final String? notes;                // Additional notes
  final String? userId;                // Owner user ID
  final DateTime createdAt;           // Creation timestamp
  final DateTime? updatedAt;          // Last update timestamp
  final List<String> tags;             // Event tags
  final bool isAllDay;                 // All-day event flag
  final bool isRecurring;              // Recurring event flag
  final String? recurrencePattern;    // Custom recurrence pattern
  final Map<String, dynamic> metadata;  // Additional metadata
}
```

### Enums

#### EventType
```dart
enum EventType {
  meeting('Meeting'),
  appointment('Appointment'),
  deadline('Deadline'),
  reminder('Reminder'),
  birthday('Birthday'),
  holiday('Holiday'),
  personal('Personal'),
  work('Work'),
  other('Other');
}
```

#### EventStatus
```dart
enum EventStatus {
  tentative('Tentative'),
  confirmed('Confirmed'),
  cancelled('Cancelled'),
  completed('Completed');
}
```

#### EventPriority
```dart
enum EventPriority {
  low('Low', 1, Colors.grey),
  medium('Medium', 2, Colors.orange),
  high('High', 3, Colors.red),
  urgent('Urgent', 4, Colors.purple);
}
```

#### RecurrenceType
```dart
enum RecurrenceType {
  none('None'),
  daily('Daily'),
  weekly('Weekly'),
  biweekly('Bi-weekly'),
  monthly('Monthly'),
  yearly('Yearly'),
  custom('Custom');
}
```

---

## Repository Layer

### CalendarRepository

The `CalendarRepository` provides data access methods for calendar events:

```dart
class CalendarRepository {
  // Event CRUD operations
  Future<List<CalendarEvent>> getAllEvents({String? userId});
  Future<CalendarEvent?> getEventById(String id);
  Future<String> createEvent(CalendarEvent event);
  Future<int> updateEvent(CalendarEvent event);
  Future<int> deleteEvent(String id);
  
  // Query operations
  Future<List<CalendarEvent>> getEventsByDate(DateTime date);
  Future<List<CalendarEvent>> getEventsByDateRange(DateTime start, DateTime end);
  Future<List<CalendarEvent>> getEventsByType(EventType type);
  Future<List<CalendarEvent>> getEventsByStatus(EventStatus status);
  Future<List<CalendarEvent>> getEventsByPriority(EventPriority priority);
  Future<List<CalendarEvent>> searchEvents(String query);
  
  // Recurring events
  Future<List<CalendarEvent>> getRecurringEvents();
  Future<List<CalendarEvent>> generateRecurringInstances(CalendarEvent event, DateTime start, DateTime end);
  
  // Statistics
  Future<Map<String, int>> getEventStatistics({String? userId});
  Future<int> getEventCount({String? userId});
  Future<int> getUpcomingEventCount({String? userId});
}
```

### Database Schema

```sql
CREATE TABLE calendar_events (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  start_time INTEGER,
  end_time INTEGER,
  due_date INTEGER,
  status TEXT NOT NULL DEFAULT 'tentative',
  type TEXT NOT NULL DEFAULT 'meeting',
  priority INTEGER NOT NULL DEFAULT 2,
  recurrence TEXT NOT NULL DEFAULT 'none',
  attendees TEXT, -- JSON array
  location TEXT,
  notes TEXT,
  user_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  tags TEXT, -- JSON array
  is_all_day INTEGER NOT NULL DEFAULT 0,
  is_recurring INTEGER NOT NULL DEFAULT 0,
  recurrence_pattern TEXT,
  metadata TEXT, -- JSON object
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_calendar_events_user_id ON calendar_events(user_id);
CREATE INDEX idx_calendar_events_start_time ON calendar_events(start_time);
CREATE INDEX idx_calendar_events_end_time ON calendar_events(end_time);
CREATE INDEX idx_calendar_events_status ON calendar_events(status);
CREATE INDEX idx_calendar_events_type ON calendar_events(type);
CREATE INDEX idx_calendar_events_priority ON calendar_events(priority);
CREATE INDEX idx_calendar_events_created_at ON calendar_events(created_at);
```

---

## State Management

### CalendarProvider

The `CalendarProvider` manages calendar state and provides reactive updates:

```dart
class CalendarProvider extends ChangeNotifier {
  List<CalendarEvent> _events = [];
  List<CalendarEvent> _filteredEvents = [];
  DateTime _selectedDate = DateTime.now();
  EventType? _selectedType;
  EventStatus? _selectedStatus;
  EventPriority? _selectedPriority;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  bool _isGridView = true;
  SortOption _sortBy = SortOption.startTime;
  bool _sortAscending = true;

  // Getters
  List<CalendarEvent> get events => _events;
  List<CalendarEvent> get filteredEvents => _filteredEvents;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGridView => _isGridView;

  // Event operations
  Future<void> loadEvents();
  Future<void> createEvent(CalendarEvent event);
  Future<void> updateEvent(CalendarEvent event);
  Future<void> deleteEvent(String eventId);
  Future<void> toggleEventStatus(CalendarEvent event);

  // Filtering and searching
  void setDateFilter(DateTime date);
  void setTypeFilter(EventType? type);
  void setStatusFilter(EventStatus? status);
  void setPriorityFilter(EventPriority? priority);
  void setSearchQuery(String query);
  void clearFilters();

  // View management
  void toggleViewMode();
  void setSortOption(SortOption sortBy, {bool ascending = true});
}
```

---

## UI Components

### CalendarScreen

The main calendar screen with multiple view modes:

```dart
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}
```

#### Features:
- **Monthly View**: Traditional calendar grid with event indicators
- **Weekly View**: 7-day week view with time slots
- **Daily View**: Single day view with detailed event timeline
- **Event List**: List view of all events
- **Quick Actions**: Fast event creation and navigation
- **Search & Filter**: Find events by various criteria

### CalendarView Widget

Reusable calendar display component:

```dart
class CalendarView extends StatelessWidget {
  final CalendarViewType viewType;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final Function(CalendarEvent) onEventTap;
  final Function(DateTime) onDateTap;

  const CalendarView({
    super.key,
    required this.viewType,
    required this.selectedDate,
    required this.events,
    required this.onEventTap,
    required this.onDateTap,
  });
}
```

### EventCard Widget

Visual representation of calendar events:

```dart
class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });
}
```

---

## Usage Examples

### Creating Events

```dart
// Simple event
final event = CalendarEvent(
  id: '1',
  title: 'Team Meeting',
  description: 'Weekly team sync',
  startTime: DateTime.now().add(Duration(hours: 1)),
  endTime: DateTime.now().add(Duration(hours: 2)),
  type: EventType.meeting,
  priority: EventPriority.medium,
  attendees: ['john@example.com', 'jane@example.com'],
  location: 'Conference Room A',
);

// Recurring event
final recurringEvent = CalendarEvent(
  id: '2',
  title: 'Daily Standup',
  startTime: DateTime.now().add(Duration(days: 1, hours: 9)),
  endTime: DateTime.now().add(Duration(days: 1, hours: 9, minutes: 30)),
  type: EventType.meeting,
  recurrence: RecurrenceType.daily,
  isRecurring: true,
);
```

### Using CalendarProvider

```dart
// Load events
await calendarProvider.loadEvents();

// Create event
await calendarProvider.createEvent(event);

// Update event
await calendarProvider.updateEvent(updatedEvent);

// Delete event
await calendarProvider.deleteEvent(eventId);

// Filter events
calendarProvider.setTypeFilter(EventType.meeting);
calendarProvider.setDateFilter(DateTime.now());
```

### Custom Event Creation

```dart
final customEvent = CalendarEvent(
  id: '3',
  title: 'Project Deadline',
  type: EventType.deadline,
  priority: EventPriority.urgent,
  dueDate: DateTime.now().add(Duration(days: 7)),
  tags: ['project', 'urgent'],
  metadata: {
    'project_id': 'proj_123',
    'department': 'engineering',
  },
);
```

---

## Integration Guide

### Adding Calendar to Existing App

1. **Add Dependencies**:
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  sqflite: ^2.3.0
  intl: ^0.18.1
  table_calendar: ^3.0.9
```

2. **Add Route**:
```dart
GoRoute(
  path: '/calendar',
  builder: (context, state) => const CalendarScreen(),
),
```

3. **Add Provider**:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CalendarProvider()),
    // ... other providers
  ],
  child: MyApp(),
)
```

4. **Add Navigation**:
```dart
// In home screen or navigation drawer
ListTile(
  leading: const Icon(Icons.calendar_today),
  title: const Text('Calendar'),
  onTap: () => context.go('/calendar'),
),
```

### Customizing Calendar

#### Custom Event Types
```dart
enum EventType {
  // ... existing types
  custom('Custom'),
  interview('Interview'),
  training('Training'),
}

// Add custom type handling in UI
Widget buildEventTypeIcon(EventType type) {
  switch (type) {
    case EventType.interview:
      return const Icon(Icons.business_center);
    case EventType.training:
      return const Icon(Icons.school);
    default:
      return const Icon(Icons.event);
  }
}
```

#### Custom Recurrence Patterns
```dart
class RecurrencePattern {
  final RecurrenceType type;
  final int interval; // Every N days/weeks/months
  final List<int> daysOfWeek; // For weekly recurrence
  final int dayOfMonth; // For monthly recurrence
  final int monthOfYear; // For yearly recurrence
  
  // Custom recurrence logic
  List<DateTime> generateOccurrences(DateTime start, DateTime end) {
    // Implementation for custom recurrence patterns
  }
}
```

---

## API Reference

### CalendarProvider Methods

#### Event Management
- `Future<void> loadEvents()` - Load all events from database
- `Future<void> createEvent(CalendarEvent event)` - Create new event
- `Future<void> updateEvent(CalendarEvent event)` - Update existing event
- `Future<void> deleteEvent(String eventId)` - Delete event by ID
- `Future<void> toggleEventStatus(CalendarEvent event)` - Toggle event status

#### Filtering and Searching
- `void setDateFilter(DateTime date)` - Filter by specific date
- `void setTypeFilter(EventType? type)` - Filter by event type
- `void setStatusFilter(EventStatus? status)` - Filter by status
- `void setPriorityFilter(EventPriority? priority)` - Filter by priority
- `void setSearchQuery(String query)` - Search events
- `void clearFilters()` - Clear all filters

#### View Management
- `void toggleViewMode()` - Switch between grid/list view
- `void setSortOption(SortOption sortBy, {bool ascending = true})` - Set sorting

### CalendarRepository Methods

#### CRUD Operations
- `Future<List<CalendarEvent>> getAllEvents({String? userId})` - Get all events
- `Future<CalendarEvent?> getEventById(String id)` - Get event by ID
- `Future<String> createEvent(CalendarEvent event)` - Create event
- `Future<int> updateEvent(CalendarEvent event)` - Update event
- `Future<int> deleteEvent(String id)` - Delete event

#### Query Methods
- `Future<List<CalendarEvent>> getEventsByDate(DateTime date)` - Get events for date
- `Future<List<CalendarEvent>> getEventsByDateRange(DateTime start, DateTime end)` - Get events in range
- `Future<List<CalendarEvent>> getEventsByType(EventType type)` - Get events by type
- `Future<List<CalendarEvent>> searchEvents(String query)` - Search events

---

## Best Practices

### Performance Optimization

1. **Lazy Loading**: Load events in batches for large datasets
2. **Caching**: Cache frequently accessed events
3. **Indexing**: Use proper database indexes for queries
4. **Pagination**: Implement pagination for event lists

### Error Handling

1. **Validation**: Validate event data before saving
2. **User Feedback**: Show clear error messages
3. **Recovery**: Provide options to recover from errors
4. **Logging**: Log errors for debugging

### User Experience

1. **Responsive Design**: Adapt to different screen sizes
2. **Accessibility**: Support screen readers and keyboard navigation
3. **Performance**: Smooth animations and transitions
4. **Intuitive**: Clear and consistent UI patterns

---

## Testing

### Unit Tests

```dart
// Test event creation
test('should create calendar event', () {
  final event = CalendarEvent(
    id: '1',
    title: 'Test Event',
    type: EventType.meeting,
  );
  
  expect(event.title, 'Test Event');
  expect(event.type, EventType.meeting);
});

// Test repository
test('should save and retrieve event', () async {
  final repository = CalendarRepository();
  final event = CalendarEvent(
    id: '1',
    title: 'Test Event',
    type: EventType.meeting,
  );
  
  await repository.createEvent(event);
  final retrieved = await repository.getEventById('1');
  
  expect(retrieved?.title, event.title);
});
```

### Widget Tests

```dart
testWidgets('calendar view should display events', (tester) async {
  final events = [
    CalendarEvent(
      id: '1',
      title: 'Test Event',
      type: EventType.meeting,
      startTime: DateTime.now(),
    ),
  ];

  await tester.pumpWidget(
    MaterialApp(
      home: CalendarView(
        viewType: CalendarViewType.monthly,
        selectedDate: DateTime.now(),
        events: events,
        onEventTap: (_) {},
        onDateTap: (_) {},
      ),
    ),
  );

  expect(find.text('Test Event'), findsOneWidget);
});
```

---

## Troubleshooting

### Common Issues

#### Event Not Saving
- Check database connection
- Verify event data validation
- Check for duplicate IDs

#### Calendar Not Updating
- Ensure provider is properly registered
- Check for missing notifyListeners() calls
- Verify data flow from repository to UI

#### Performance Issues
- Optimize database queries
- Implement pagination
- Use efficient widget rebuilding

### Debug Tips

1. **Logging**: Add debug prints for data flow
2. **Database Inspection**: Use SQLite browser to check data
3. **State Debugging**: Use Flutter DevTools to inspect provider state
4. **UI Debugging**: Use Flutter Inspector to examine widget tree

---

## Future Enhancements

### Planned Features

1. **Calendar Sync**: Integration with Google Calendar, Outlook
2. **Invitations**: Send and receive event invitations
3. **Reminders**: Multiple reminder options
4. **Time Zones**: Support for multiple time zones
5. **Export/Import**: Calendar data import/export
6. **Sharing**: Share calendars with other users
7. **Templates**: Event templates for common events
8. **Analytics**: Calendar usage statistics

### Technical Improvements

1. **Background Sync**: Background data synchronization
2. **Offline Mode**: Enhanced offline capabilities
3. **Performance**: Optimized rendering for large datasets
4. **Accessibility**: Improved screen reader support
5. **Internationalization**: Multi-language support

---

*Last updated: February 2026*
*Version: 1.0.0*
