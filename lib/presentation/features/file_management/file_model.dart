import 'package:equatable/equatable.dart';

class FileModel extends Equatable {
  final String id;
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final bool isDirectory;
  final String? mimeType;
  final String? downloadUrl;
  final Map<String, dynamic>? metadata;

  const FileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.isDirectory,
    this.mimeType,
    this.downloadUrl,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        size,
        modified,
        isDirectory,
        mimeType,
        downloadUrl,
        metadata,
      ];

  FileModel copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    DateTime? modified,
    bool? isDirectory,
    String? mimeType,
    String? downloadUrl,
    Map<String, dynamic>? metadata,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      modified: modified ?? this.modified,
      isDirectory: isDirectory ?? this.isDirectory,
      mimeType: mimeType ?? this.mimeType,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}

class FileOperationResult extends Equatable {
  final bool success;
  final String? error;
  final dynamic data;

  const FileOperationResult({
    required this.success,
    this.error,
    this.data,
  });

  @override
  List<Object?> get props => [success, error, data];
}

class ShareLink extends Equatable {
  final String id;
  final String url;
  final String fileName;
  final int fileSize;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int downloadCount;
  final String deviceId;
  final bool isExpired;

  const ShareLink({
    required this.id,
    required this.url,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    required this.expiresAt,
    required this.downloadCount,
    required this.deviceId,
    required this.isExpired,
  });

  @override
  List<Object?> get props => [
        id,
        url,
        fileName,
        fileSize,
        createdAt,
        expiresAt,
        downloadCount,
        deviceId,
        isExpired,
      ];
}

enum FileSortOrder {
  name,
  size,
  date,
  type,
}

enum FileViewMode {
  list,
  grid,
}

enum CompressionType {
  zip,
  rar,
  tar,
  gz,
}

enum ShareType {
  link,
  qr,
  system,
}
