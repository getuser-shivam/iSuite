import 'package:flutter/foundation.dart';

enum FileType {
  document,
  image,
  video,
  audio,
  archive,
  other,
}

enum FileStatus {
  uploading,
  processing,
  completed,
  failed,
  deleted,
}

class FileModel extends Equatable {
  const FileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.uploadedAt,
    this.mimeType,
    this.thumbnail,
    this.metadata = const {},
    this.userId,
    this.isEncrypted = false,
    this.password,
    this.tags = const [],
    this.description,
    this.downloadCount,
    this.lastAccessed,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) => FileModel(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
        size: json['size'] as int,
        type: FileType.values.firstWhere((type) => type.name == json['type']),
        status: FileStatus.values
            .firstWhere((status) => status.name == json['status']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.parse(json['uploadedAt'] as String)
            : null,
        mimeType: json['mimeType'] as String?,
        thumbnail: json['thumbnail'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        userId: json['userId'] as String?,
        isEncrypted: json['isEncrypted'] as bool? ?? false,
        password: json['password'] as String?,
        tags: List<String>.from(json['tags'] as List? ?? []),
        description: json['description'] as String?,
        downloadCount: json['downloadCount'] as int?,
        lastAccessed: json['lastAccessed'] != null
            ? DateTime.parse(json['lastAccessed'] as String)
            : null,
      );
  final String id;
  final String name;
  final String path;
  final int size;
  final FileType type;
  final FileStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? uploadedAt;
  final String? mimeType;
  final String? thumbnail;
  final Map<String, dynamic> metadata;
  final String? userId;
  final bool isEncrypted;
  final String? password;
  final List<String> tags;
  final String? description;
  final int? downloadCount;
  final DateTime? lastAccessed;

  FileModel copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    FileType? type,
    FileStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? uploadedAt,
    String? mimeType,
    String? thumbnail,
    Map<String, dynamic>? metadata,
    String? userId,
    bool? isEncrypted,
    String? password,
    List<String>? tags,
    String? description,
    int? downloadCount,
    DateTime? lastAccessed,
  }) =>
      FileModel(
        id: id ?? this.id,
        name: name ?? this.name,
        path: path ?? this.path,
        size: size ?? this.size,
        type: type ?? this.type,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        mimeType: mimeType ?? this.mimeType,
        thumbnail: thumbnail ?? this.thumbnail,
        metadata: metadata ?? this.metadata,
        userId: userId ?? this.userId,
        isEncrypted: isEncrypted ?? this.isEncrypted,
        password: password ?? this.password,
        tags: tags ?? this.tags,
        description: description ?? this.description,
        downloadCount: downloadCount ?? this.downloadCount,
        lastAccessed: lastAccessed ?? this.lastAccessed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'size': size,
        'type': type.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'uploadedAt': uploadedAt?.toIso8601String(),
        'mimeType': mimeType,
        'thumbnail': thumbnail,
        'metadata': metadata,
        'userId': userId,
        'isEncrypted': isEncrypted,
        'password': password,
        'tags': tags,
        'description': description,
        'downloadCount': downloadCount,
        'lastAccessed': lastAccessed?.toIso8601String(),
      };

  // Computed properties
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String get fileExtension => name.split('.').last.toLowerCase();

  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg']
      .contains(fileExtension);

  bool get isDocument =>
      ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'].contains(fileExtension);

  bool get isVideo =>
      ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(fileExtension);

  bool get isAudio =>
      ['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(fileExtension);

  bool get isArchive =>
      ['zip', 'rar', '7z', 'tar', 'gz'].contains(fileExtension);

  bool get isEmpty => size == 0;

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        size,
        type,
        status,
        createdAt,
        updatedAt,
        uploadedAt,
        mimeType,
        thumbnail,
        metadata,
        userId,
        isEncrypted,
        password,
        tags,
        description,
        downloadCount,
        lastAccessed,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileModel &&
        other.id == id &&
        other.name == name &&
        other.path == path &&
        other.size == size &&
        other.type == type &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.uploadedAt == uploadedAt &&
        other.mimeType == mimeType &&
        other.thumbnail == thumbnail &&
        other.metadata == metadata &&
        other.userId == userId &&
        other.isEncrypted == isEncrypted &&
        other.password == password &&
        other.tags == tags &&
        other.description == description &&
        other.downloadCount == downloadCount &&
        other.lastAccessed == lastAccessed;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        path,
        size,
        type,
        status,
        createdAt,
        updatedAt,
        uploadedAt,
        mimeType,
        thumbnail,
        metadata,
        userId,
        isEncrypted,
        password,
        tags,
        description,
        downloadCount,
        lastAccessed,
      );
}
