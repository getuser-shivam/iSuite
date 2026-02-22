import 'package:equatable/equatable.dart';

class SharedFile extends Equatable {
  final String id;
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final DateTime sharedAt;
  final DateTime? expiresAt;
  final bool isShared;
  final String? shareUrl;
  final String? qrCode;
  final int downloadCount;
  final Map<String, dynamic>? metadata;
  final String? password;
  final bool isPublic;

  const SharedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    required this.sharedAt,
    this.expiresAt,
    this.isShared = true,
    this.shareUrl,
    this.qrCode,
    this.downloadCount = 0,
    this.metadata,
    this.password,
    this.isPublic = true,
  });

  SharedFile copyWith({
    String? id,
    String? name,
    String? path,
    int? size,
    String? mimeType,
    DateTime? sharedAt,
    DateTime? expiresAt,
    bool? isShared,
    String? shareUrl,
    String? qrCode,
    int? downloadCount,
    Map<String, dynamic>? metadata,
    String? password,
    bool? isPublic,
  }) {
    return SharedFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      sharedAt: sharedAt ?? this.sharedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isShared: isShared ?? this.isShared,
      shareUrl: shareUrl ?? this.shareUrl,
      qrCode: qrCode ?? this.qrCode,
      downloadCount: downloadCount ?? this.downloadCount,
      metadata: metadata ?? this.metadata,
      password: password ?? this.password,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'size': size,
      'mimeType': mimeType,
      'sharedAt': sharedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'isShared': isShared,
      'shareUrl': shareUrl,
      'qrCode': qrCode,
      'downloadCount': downloadCount,
      'metadata': metadata,
      'password': password,
      'isPublic': isPublic,
    };
  }

  factory SharedFile.fromMap(Map<String, dynamic> map) {
    return SharedFile(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      size: map['size'] ?? 0,
      mimeType: map['mimeType'] ?? 'application/octet-stream',
      sharedAt: DateTime.fromMillisecondsSinceEpoch(map['sharedAt']),
      expiresAt: map['expiresAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt']) 
          : null,
      isShared: map['isShared'] ?? true,
      shareUrl: map['shareUrl'],
      qrCode: map['qrCode'],
      downloadCount: map['downloadCount'] ?? 0,
      metadata: map['metadata'],
      password: map['password'],
      isPublic: map['isPublic'] ?? true,
    );
  }

  // Computed properties
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isDocument => mimeType.contains('document') || 
                         mimeType.contains('pdf') || 
                         mimeType.contains('text');
  
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String get fileExtension {
    return name.split('.').last.toLowerCase();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        size,
        mimeType,
        sharedAt,
        expiresAt,
        isShared,
        shareUrl,
        qrCode,
        downloadCount,
        metadata,
        password,
        isPublic,
      ];

  @override
  String toString() {
    return 'SharedFile(id: $id, name: $name, size: $formattedSize, shared: $isShared)';
  }
}
