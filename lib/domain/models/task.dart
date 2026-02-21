import 'package:equatable/equatable.dart';

enum TaskPriority {
  low('Low', 1, Colors.grey),
  medium('Medium', 2, Colors.orange),
  high('High', 3, Colors.red),
  urgent('Urgent', 4, Colors.purple);

  const TaskPriority(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

enum TaskStatus {
  todo('To Do', Colors.blue),
  inProgress('In Progress', Colors.orange),
  completed('Completed', Colors.green),
  cancelled('Cancelled', Colors.grey);

  const TaskStatus(this.label, this.color);
  final String label;
  final Color color;
}

enum TaskCategory {
  work('Work', Icons.work, Colors.blue),
  personal('Personal', Icons.person, Colors.green),
  shopping('Shopping', Icons.shopping_cart, Colors.orange),
  health('Health', Icons.favorite, Colors.red),
  education('Education', Icons.school, Colors.purple),
  finance('Finance', Icons.account_balance, Colors.teal),
  other('Other', Icons.category, Colors.grey);

  const TaskCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.category,
    required this.createdAt,
    this.description,
    this.status = TaskStatus.todo,
    this.dueDate,
    this.completedAt,
    this.tags = const [],
    this.userId,
    this.isRecurring = false,
    this.recurrencePattern,
    this.estimatedMinutes,
    this.actualMinutes,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        priority: TaskPriority.values.firstWhere(
          (p) => p.value == json['priority'],
          orElse: () => TaskPriority.medium,
        ),
        status: TaskStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TaskStatus.todo,
        ),
        category: TaskCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => TaskCategory.other,
        ),
        dueDate: json['dueDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'])
            : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
        completedAt: json['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
            : null,
        tags: List<String>.from(json['tags'] ?? []),
        userId: json['userId'],
        isRecurring: json['isRecurring'] ?? false,
        recurrencePattern: json['recurrencePattern'],
        estimatedMinutes: json['estimatedMinutes'],
        actualMinutes: json['actualMinutes'],
      );
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskCategory category;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> tags;
  final String? userId;
  final bool isRecurring;
  final String? recurrencePattern;
  final int? estimatedMinutes;
  final int? actualMinutes;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    TaskCategory? category,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? tags,
    String? userId,
    bool? isRecurring,
    String? recurrencePattern,
    int? estimatedMinutes,
    int? actualMinutes,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        category: category ?? this.category,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
        tags: tags ?? this.tags,
        userId: userId ?? this.userId,
        isRecurring: isRecurring ?? this.isRecurring,
        recurrencePattern: recurrencePattern ?? this.recurrencePattern,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        actualMinutes: actualMinutes ?? this.actualMinutes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.value,
        'status': status.label,
        'category': category.label,
        'dueDate': dueDate?.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'tags': tags,
        'userId': userId,
        'isRecurring': isRecurring,
        'recurrencePattern': recurrencePattern,
        'estimatedMinutes': estimatedMinutes,
        'actualMinutes': actualMinutes,
      };

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        priority,
        status,
        category,
        dueDate,
        createdAt,
        completedAt,
        tags,
        userId,
        isRecurring,
        recurrencePattern,
        estimatedMinutes,
        actualMinutes,
        completedAt,
      ];

  // Getters for computed properties
  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    return dueDate!.isToday;
  }

  bool get isDueSoon {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final difference = dueDate!.difference(now);
    return difference.inDays <= 1 && difference.inHours > 0;
  }

  String get dueDateFormatted {
    if (dueDate == null) return '';
    final now = DateTime.now();
    final difference = dueDate!.difference(now);

    if (difference.inDays == 0) {
      return 'Today ${dueDate!.hour.toString().padLeft(2, '0')}:${dueDate!.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${dueDate!.hour.toString().padLeft(2, '0')}:${dueDate!.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else {
      return 'Overdue';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  double get completionPercentage {
    if (estimatedMinutes == null || estimatedMinutes == 0) return 0;
    if (actualMinutes == null || actualMinutes == 0) return 0;
    return (actualMinutes! / estimatedMinutes!).clamp(0.0, 1.0);
  }

  String get estimatedTime {
    if (estimatedMinutes == null) return 'Not estimated';
    return '${estimatedMinutes} min';
  }

  String get actualTime {
    if (actualMinutes == null) return 'Not tracked';
    return '${actualMinutes} min';
  }
}
