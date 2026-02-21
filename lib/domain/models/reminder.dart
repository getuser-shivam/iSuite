import 'package:equatable/equatable.dart';

enum ReminderRepeat {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

enum ReminderPriority {
  low,
  medium,
  high,
  urgent,
}

enum ReminderStatus {
  active,
  completed,
  dismissed,
  snoozed,
}

class ReminderModel extends Equatable {
  const ReminderModel({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.repeat = ReminderRepeat.none,
    this.priority = ReminderPriority.medium,
    this.status = ReminderStatus.active,
    this.snoozeUntil,
    this.completedAt,
    this.tags = const [],
    this.userId,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        dueDate: DateTime.parse(json['dueDate'] as String),
        repeat:
            ReminderRepeat.values.firstWhere((r) => r.name == json['repeat']),
        priority: ReminderPriority.values
            .firstWhere((p) => p.name == json['priority']),
        status:
            ReminderStatus.values.firstWhere((s) => s.name == json['status']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        snoozeUntil: json['snoozeUntil'] != null
            ? DateTime.parse(json['snoozeUntil'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        tags: List<String>.from(json['tags'] as List? ?? []),
        userId: json['userId'] as String?,
      );
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final ReminderRepeat repeat;
  final ReminderPriority priority;
  final ReminderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? snoozeUntil;
  final DateTime? completedAt;
  final List<String> tags;
  final String? userId;

  ReminderModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    ReminderRepeat? repeat,
    ReminderPriority? priority,
    ReminderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? snoozeUntil,
    DateTime? completedAt,
    List<String>? tags,
    String? userId,
  }) =>
      ReminderModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        repeat: repeat ?? this.repeat,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        snoozeUntil: snoozeUntil ?? this.snoozeUntil,
        completedAt: completedAt ?? this.completedAt,
        tags: tags ?? this.tags,
        userId: userId ?? this.userId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'repeat': repeat.name,
        'priority': priority.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'snoozeUntil': snoozeUntil?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'tags': tags,
        'userId': userId,
      };

  // Computed properties
  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && status == ReminderStatus.active;
  bool get isActive => status == ReminderStatus.active;
  bool get isCompleted => status == ReminderStatus.completed;
  bool get isSnoozed => status == ReminderStatus.snoozed;
  bool get isDismissed => status == ReminderStatus.dismissed;

  String get formattedDueDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDay == today) {
      return 'Today ${dueDate.hour}:${dueDate.minute.toString().padLeft(2, '0')}';
    } else if (dueDay == tomorrow) {
      return 'Tomorrow ${dueDate.hour}:${dueDate.minute.toString().padLeft(2, '0')}';
    } else {
      final difference = dueDay.difference(today).inDays;
      if (difference > 0 && difference <= 7) {
        return '${_getWeekdayName(dueDay.weekday)} ${dueDate.hour}:${dueDate.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dueDate.month}/${dueDate.day}/${dueDate.year} ${dueDate.hour}:${dueDate.minute.toString().padLeft(2, '0')}';
      }
    }
  }

  String get timeUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} left';
    } else {
      return 'Due now';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case ReminderPriority.low:
        return const Color(0xFF4CAF50); // Green
      case ReminderPriority.medium:
        return const Color(0xFFFF9800); // Orange
      case ReminderPriority.high:
        return const Color(0xFFF44336); // Red
      case ReminderPriority.urgent:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  IconData get priorityIcon {
    switch (priority) {
      case ReminderPriority.low:
        return Icons.arrow_downward;
      case ReminderPriority.medium:
        return Icons.remove;
      case ReminderPriority.high:
        return Icons.arrow_upward;
      case ReminderPriority.urgent:
        return Icons.priority_high;
    }
  }

  // Helper method
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        dueDate,
        repeat,
        priority,
        status,
        createdAt,
        updatedAt,
        snoozeUntil,
        completedAt,
        tags,
        userId,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.dueDate == dueDate &&
        other.repeat == repeat &&
        other.priority == priority &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.snoozeUntil == snoozeUntil &&
        other.completedAt == completedAt &&
        other.tags == tags &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        dueDate,
        repeat,
        priority,
        status,
        createdAt,
        updatedAt,
        snoozeUntil,
        completedAt,
        tags,
        userId,
      );
}
