import 'package:equatable/equatable.dart';

enum RecurrenceType {
  none('None'),
  daily('Daily'),
  weekly('Weekly'),
  biweekly('Bi-weekly'),
  monthly('Monthly'),
  yearly('Yearly'),
  custom('Custom');
}

enum EventStatus {
  tentative('Tentative'),
  confirmed('Confirmed'),
  cancelled('Cancelled'),
  completed('Completed');
}

enum EventPriority {
  low('Low', 1, Colors.grey),
  medium('Medium', 2, Colors.orange),
  high('High', 3, Colors.red),
  urgent('Urgent', 4, Colors.purple);
}

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

class CalendarEvent extends Equatable {

  CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime, required this.createdAt, this.description,
    this.endTime,
    this.dueDate,
    this.status = EventStatus.tentative,
    this.type = EventType.personal,
    this.priority = EventPriority.medium,
    this.recurrence = RecurrenceType.none,
    this.attendees = const [],
    this.location,
    this.notes,
    this.userId,
    this.updatedAt,
    this.tags = const [],
    this.reminders = const [],
    this.isAllDay = false,
    this.isRecurring = false,
    this.recurrencePattern,
    this.metadata = const {},
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] ?? 0),
      endTime: json['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          : null,
      dueDate: json['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'])
          : null,
      status: EventStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EventStatus.tentative,
      ),
      type: EventType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => EventType.personal,
      ),
      priority: EventPriority.values.firstWhere(
        (p) => p.value == (json['priority'] ?? 2),
        orElse: () => EventPriority.medium,
      ),
      recurrence: RecurrenceType.values.firstWhere(
        (r) => r.name == json['recurrence'],
        orElse: () => RecurrenceType.none,
      ),
      attendees: List<String>.from(json['attendees'] ?? []),
      location: json['location'],
      notes: json['notes'],
      userId: json['userId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
      isAllDay: json['isAllDay'] ?? false,
      isRecurring: json['isRecurring'] ?? false,
      recurrencePattern: json['recurrencePattern'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  final String id;
  final String title;
  String? description;
  DateTime startTime;
  DateTime? endTime;
  DateTime? dueDate;
  EventStatus status;
  EventType type;
  EventPriority priority;
  RecurrenceType recurrence;
  List<String> attendees;
  String? location;
  String? notes;
  String? userId;
  DateTime createdAt;
  DateTime? updatedAt;
  List<String> tags;
  List<String> reminders;
  bool isAllDay;
  bool isRecurring;
  String? recurrencePattern;
  Map<String, dynamic> metadata;

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? dueDate,
    EventStatus? status,
    EventType? type,
    EventPriority? priority,
    RecurrenceType? recurrence,
    List<String>? attendees,
    String? location,
    String? notes,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isAllDay,
    bool? isRecurring,
    String? recurrencePattern,
    Map<String, dynamic>? metadata,
  }) => CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      attendees: attendees ?? this.attendees,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      isAllDay: isAllDay ?? this.isAllDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      metadata: metadata ?? this.metadata,
    );

  Map<String, dynamic> toJson() => {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'status': status.name,
      'type': type.name,
      'priority': priority.value,
      'recurrence': recurrence.name,
      'attendees': attendees,
      'location': location,
      'notes': notes,
      'userId': userId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'tags': tags,
      'isAllDay': isAllDay,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'metadata': metadata,
    };

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startTime,
        endTime,
        dueDate,
        status,
        type,
        priority,
        recurrence,
        attendees,
        location,
        notes,
        userId,
        createdAt,
        updatedAt,
        tags,
        isAllDay,
        isRecurring,
        recurrencePattern,
        metadata,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other);

  @override
  int get hashCode => hashValues([
        id,
        title,
        description,
        startTime.millisecondsSinceEpoch,
        endTime?.millisecondsSinceEpoch ?? 0,
        dueDate?.millisecondsSinceEpoch ?? 0,
        status.name,
        type.name,
        priority.value,
        recurrence.name,
        attendees.join(','),
        location ?? '',
        notes ?? '',
        userId ?? '',
        createdAt.millisecondsSinceEpoch,
        updatedAt.millisecondsSinceEpoch,
        tags.join(','),
        isAllDay,
        isRecurring,
        recurrencePattern ?? '',
        metadata.toString(),
      ]);

  String get formattedTimeRange() {
    if (startTime == null && endTime == null) {
      return 'All day';
    }
    
    if (endTime == null) {
      return AppUtils.formatDate(startTime);
    }
    
    if (endTime != null) {
      final start = AppUtils.formatDate(startTime);
      final end = AppUtils.formatDate(endTime);
      return '$start - $end';
    }
    
    return AppUtils.formatDate(startTime);
  }

  bool get isOverdue() {
    if (dueDate == null || status == EventStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isToday() => startTime.isToday;

  bool get isFuture() => startTime.isAfter(DateTime.now());

  bool get isPast() => startTime.isBefore(DateTime.now());

  bool get isAllDayEvent() {
    if (endTime == null) return false;
    final start = DateTime(startTime.year, startTime.month, startTime.day);
    final end = DateTime(endTime.year, endTime.month, endTime.day);
    return start.isAtSameDay(end);
  }

  Duration get duration {
    if (endTime == null) {
      return Duration.zero;
    }
    return endTime.difference(startTime);
  }

  String get formattedTimeRange() {
    if (startTime == null && endTime == null) {
      return 'All day';
    }
    
    if (startTime.isToday && endTime.isToday) {
      return 'Today, ${AppUtils.formatTime(startTime)} - ${AppUtils.formatTime(endTime)}';
    }
    
    if (startTime.isToday && !endTime.isToday()) {
      return 'Today, ${AppUtils.formatTime(startTime)} - Tomorrow';
    }
    
    return '${AppUtils.formatDate(startTime)} - ${AppUtils.formatDate(endTime)}';
  }
}
