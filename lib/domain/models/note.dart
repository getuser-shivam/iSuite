import 'package:equatable/equatable.dart';

enum NoteType {
  text('Text'),
  checklist('Checklist'),
  markdown('Markdown'),
  code('Code'),
  drawing('Drawing'),
  voice('Voice'),
  image('Image'),
  document('Document'),
  other('Other');
}

enum NoteStatus {
  draft('Draft'),
  published('Published'),
  archived('Archived'),
  deleted('Deleted');
}

enum NotePriority {
  low('Low', 1, Colors.grey),
  medium('Medium', 2, Colors.orange),
  high('High', 3, Colors.red),
  urgent('Urgent', 4, Colors.purple);
}

enum NoteCategory {
  personal('Personal'),
  work('Work'),
  study('Study'),
  ideas('Ideas'),
  meeting('Meeting'),
  project('Project'),
  shopping('Shopping'),
  health('Health'),
  finance('Finance'),
  travel('Travel'),
  other('Other');
}

class Note extends Equatable {
  final String id;
  final String title;
  final String? content;
  final NoteType type;
  final NoteStatus status;
  final NotePriority priority;
  final NoteCategory category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? dueDate;
  final bool isPinned;
  final bool isArchived;
  final bool isFavorite;
  final String? userId;
  final Map<String, dynamic> metadata;
  final List<String> attachments;
  final String? color;
  final int? wordCount;
  final int? readingTime;
  final bool isEncrypted;
  final String? password;

  const Note({
    required this.id,
    required this.title,
    this.content,
    this.type = NoteType.text,
    this.status = NoteStatus.draft,
    this.priority = NotePriority.medium,
    this.category = NoteCategory.personal,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
    this.isPinned = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.userId,
    this.metadata = const {},
    this.attachments = const [],
    this.color,
    this.wordCount,
    this.readingTime,
    this.isEncrypted = false,
    this.password,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    NoteType? type,
    NoteStatus? status,
    NotePriority? priority,
    NoteCategory? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    bool? isPinned,
    bool? isArchived,
    bool? isFavorite,
    String? userId,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    String? color,
    int? wordCount,
    int? readingTime,
    bool? isEncrypted,
    String? password,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      color: color ?? this.color,
      wordCount: wordCount ?? this.wordCount,
      readingTime: readingTime ?? this.readingTime,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'status': status.name,
      'priority': priority.value,
      'category': category.name,
      'tags': tags,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isFavorite': isFavorite,
      'userId': userId,
      'metadata': metadata,
      'attachments': attachments,
      'color': color,
      'wordCount': wordCount,
      'readingTime': readingTime,
      'isEncrypted': isEncrypted,
      'password': password,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'],
      type: NoteType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NoteType.text,
      ),
      status: NoteStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => NoteStatus.draft,
      ),
      priority: NotePriority.values.firstWhere(
        (p) => p.value == (json['priority'] ?? 2),
        orElse: () => NotePriority.medium,
      ),
      category: NoteCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => NoteCategory.personal,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
      dueDate: json['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'])
          : null,
      isPinned: json['isPinned'] ?? false,
      isArchived: json['isArchived'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      userId: json['userId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      attachments: List<String>.from(json['attachments'] ?? []),
      color: json['color'],
      wordCount: json['wordCount'],
      readingTime: json['readingTime'],
      isEncrypted: json['isEncrypted'] ?? false,
      password: json['password'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        type,
        status,
        priority,
        category,
        tags,
        createdAt,
        updatedAt,
        dueDate,
        isPinned,
        isArchived,
        isFavorite,
        userId,
        metadata,
        attachments,
        color,
        wordCount,
        readingTime,
        isEncrypted,
        password,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other);

  @override
  int get hashCode => hashValues([
        id,
        title,
        content,
        type.name,
        status.name,
        priority.value,
        category.name,
        tags.join(','),
        createdAt.millisecondsSinceEpoch,
        updatedAt?.millisecondsSinceEpoch ?? 0,
        dueDate?.millisecondsSinceEpoch ?? 0,
        isPinned,
        isArchived,
        isFavorite,
        userId ?? '',
        metadata.toString(),
        attachments.join(','),
        color ?? '',
        wordCount ?? 0,
        readingTime ?? 0,
        isEncrypted,
        password ?? '',
      ]);

  // Computed properties
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays ~/ 7)} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays ~/ 30)} months ago';
    } else {
      return '${(difference.inDays ~/ 365)} years ago';
    }
  }

  String get excerpt {
    if (content == null || content!.isEmpty) {
      return '';
    }
    
    final words = content!.split(' ');
    if (words.length <= 10) {
      return words.join(' ');
    } else {
      return '${words.take(10).join(' ')}...';
    }
  }

  bool get isEmpty => content == null || content!.trim().isEmpty;

  bool get isOverdue {
    if (dueDate == null || status == NoteStatus.completed || status == NoteStatus.archived) {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return now.isSameDay(due);
  }

  bool get isDueSoon {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 3));
    return dueDate!.isBefore(soon) && !dueDate!.isBefore(now);
  }

  String get priorityLabel {
    return priority.label;
  }

  Color get priorityColor {
    return priority.color;
  }

  String get categoryLabel {
    return category.label;
  }

  String get typeLabel {
    return type.label;
  }

  String get statusLabel {
    return status.label;
  }

  int get estimatedReadingTime {
    if (wordCount != null && readingTime != null) {
      return wordCount! * readingTime!;
    }
    return 0;
  }
}
