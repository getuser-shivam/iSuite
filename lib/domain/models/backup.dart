import 'package:equatable/equatable.dart';

enum BackupType {
  full,
  tasks,
  notes,
  files,
  calendar,
  custom,
}

enum BackupStatus {
  pending,
  inProgress,
  completed,
  failed,
}

class BackupModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final BackupType type;
  final BackupStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int size; // in bytes
  final String? filePath;
  final Map<String, dynamic> metadata;
  final bool isEncrypted;
  final String? password;

  const BackupModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.status = BackupStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.size = 0,
    this.filePath,
    this.metadata = const {},
    this.isEncrypted = false,
    this.password,
  });

  BackupModel copyWith({
    String? id,
    String? name,
    String? description,
    BackupType? type,
    BackupStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    int? size,
    String? filePath,
    Map<String, dynamic>? metadata,
    bool? isEncrypted,
    String? password,
  }) {
    return BackupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      size: size ?? this.size,
      filePath: filePath ?? this.filePath,
      metadata: metadata ?? this.metadata,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'size': size,
      'filePath': filePath,
      'metadata': metadata,
      'isEncrypted': isEncrypted,
      'password': password,
    };
  }

  factory BackupModel.fromJson(Map<String, dynamic> json) {
    return BackupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: BackupType.values.firstWhere((type) => type.name == json['type']),
      status: BackupStatus.values.firstWhere((status) => status.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      size: json['size'] as int? ?? 0,
      filePath: json['filePath'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      password: json['password'] as String?,
    );
  }

  // Computed properties
  String get formattedSize {
    if (size == 0) return '0 B';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  Duration get duration {
    if (completedAt == null) return Duration.zero;
    return completedAt!.difference(createdAt);
  }

  bool get isCompleted => status == BackupStatus.completed;
  bool get isFailed => status == BackupStatus.failed;
  bool get isInProgress => status == BackupStatus.inProgress;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        status,
        createdAt,
        completedAt,
        size,
        filePath,
        metadata,
        isEncrypted,
        password,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.type == type &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.size == size &&
        other.filePath == filePath &&
        other.metadata == metadata &&
        other.isEncrypted == isEncrypted &&
        other.password == password;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      type,
      status,
      createdAt,
      completedAt,
      size,
      filePath,
      metadata,
      isEncrypted,
      password,
    );
  }
}
