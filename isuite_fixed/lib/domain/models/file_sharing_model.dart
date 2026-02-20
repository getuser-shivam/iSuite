import 'package:equatable/equatable.dart';

enum TransferType {
  upload,
  download,
  sync,
}

enum TransferStatus {
  pending,
  inProgress,
  completed,
  failed,
  paused,
  cancelled,
}

enum FileSharingProtocol {
  ftp,
  sftp,
  http,
  https,
  smb,
  webdav,
  bluetooth,
  wifiDirect,
}

class FileSharingModel extends Equatable {
  const FileSharingModel({
    required this.id,
    required this.name,
    required this.protocol,
    required this.host,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.port = 21,
    this.password,
    this.remotePath,
    this.localPath,
    this.isSecure = false,
    this.isActive = false,
    this.lastConnected,
    this.maxConnections,
    this.currentConnections = 0,
    this.metadata = const {},
    this.activeTransfers = const [],
    this.customHeaders = const {},
  });

  factory FileSharingModel.fromJson(Map<String, dynamic> json) =>
      FileSharingModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        protocol: FileSharingProtocol.values
            .firstWhere((p) => p.name == json['protocol']),
        host: json['host'] as String,
        port: json['port'] as int? ?? 21,
        username: json['username'] as String,
        password: json['password'] as String?,
        remotePath: json['remotePath'] as String?,
        localPath: json['localPath'] as String?,
        isSecure: json['isSecure'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        lastConnected: json['lastConnected'] != null
            ? DateTime.parse(json['lastConnected'] as String)
            : null,
        maxConnections: json['maxConnections'] as int?,
        currentConnections: json['currentConnections'] as int? ?? 0,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
        activeTransfers: (json['activeTransfers'] as List?)
                ?.map((t) =>
                    FileTransferModel.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        customHeaders:
            Map<String, String>.from(json['customHeaders'] as Map? ?? {}),
      );
  final String id;
  final String name;
  final String? description;
  final FileSharingProtocol protocol;
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? remotePath;
  final String? localPath;
  final bool isSecure;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastConnected;
  final int? maxConnections;
  final int currentConnections;
  final Map<String, dynamic> metadata;
  final List<FileTransferModel> activeTransfers;
  final Map<String, String> customHeaders;

  FileSharingModel copyWith({
    String? id,
    String? name,
    String? description,
    FileSharingProtocol? protocol,
    String? host,
    int? port,
    String? username,
    String? password,
    String? remotePath,
    String? localPath,
    bool? isSecure,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastConnected,
    int? maxConnections,
    int? currentConnections,
    Map<String, dynamic>? metadata,
    List<FileTransferModel>? activeTransfers,
    Map<String, String>? customHeaders,
  }) =>
      FileSharingModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        protocol: protocol ?? this.protocol,
        host: host ?? this.host,
        port: port ?? this.port,
        username: username ?? this.username,
        password: password ?? this.password,
        remotePath: remotePath ?? this.remotePath,
        localPath: localPath ?? this.localPath,
        isSecure: isSecure ?? this.isSecure,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastConnected: lastConnected ?? this.lastConnected,
        maxConnections: maxConnections ?? this.maxConnections,
        currentConnections: currentConnections ?? this.currentConnections,
        metadata: metadata ?? this.metadata,
        activeTransfers: activeTransfers ?? this.activeTransfers,
        customHeaders: customHeaders ?? this.customHeaders,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'protocol': protocol.name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'remotePath': remotePath,
        'localPath': localPath,
        'isSecure': isSecure,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastConnected': lastConnected?.toIso8601String(),
        'maxConnections': maxConnections,
        'currentConnections': currentConnections,
        'metadata': metadata,
        'activeTransfers': activeTransfers.map((t) => t.toJson()).toList(),
        'customHeaders': customHeaders,
      };

  // Computed properties
  String get fullAddress => '$host:$port';
  String get protocolText {
    switch (protocol) {
      case FileSharingProtocol.ftp:
        return 'FTP';
      case FileSharingProtocol.sftp:
        return 'SFTP';
      case FileSharingProtocol.http:
        return 'HTTP';
      case FileSharingProtocol.https:
        return 'HTTPS';
      case FileSharingProtocol.smb:
        return 'SMB';
      case FileSharingProtocol.webdav:
        return 'WebDAV';
      case FileSharingProtocol.bluetooth:
        return 'Bluetooth';
      case FileSharingProtocol.wifiDirect:
        return 'WiFi Direct';
    }
  }

  bool get isEncrypted =>
      protocol == FileSharingProtocol.sftp ||
      protocol == FileSharingProtocol.https ||
      protocol == FileSharingProtocol.webdav;
  bool get hasActiveTransfers => activeTransfers.isNotEmpty;
  int get totalTransfers => activeTransfers.length;
  int get activeUploads =>
      activeTransfers.where((t) => t.type == TransferType.upload).length;
  int get activeDownloads =>
      activeTransfers.where((t) => t.type == TransferType.download).length;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        protocol,
        host,
        port,
        username,
        password,
        remotePath,
        localPath,
        isSecure,
        isActive,
        createdAt,
        updatedAt,
        lastConnected,
        maxConnections,
        currentConnections,
        metadata,
        activeTransfers,
        customHeaders,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileSharingModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.protocol == protocol &&
        other.host == host &&
        other.port == port &&
        other.username == username &&
        other.password == password &&
        other.remotePath == remotePath &&
        other.localPath == localPath &&
        other.isSecure == isSecure &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastConnected == lastConnected &&
        other.maxConnections == maxConnections &&
        other.currentConnections == currentConnections &&
        other.metadata == metadata &&
        other.activeTransfers == activeTransfers &&
        other.customHeaders == customHeaders;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        protocol,
        host,
        port,
        username,
        password,
        remotePath,
        localPath,
        isSecure,
        isActive,
        createdAt,
        updatedAt,
        lastConnected,
        maxConnections,
        currentConnections,
        metadata,
        activeTransfers,
        customHeaders,
      );
}

class FileTransferModel extends Equatable {
  const FileTransferModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.type,
    required this.totalBytes,
    required this.startTime,
    this.status = TransferStatus.pending,
    this.transferredBytes = 0,
    this.speed = 0.0,
    this.endTime,
    this.errorMessage,
    this.metadata = const {},
  });

  factory FileTransferModel.fromJson(Map<String, dynamic> json) =>
      FileTransferModel(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        filePath: json['filePath'] as String,
        type: TransferType.values.firstWhere((t) => t.name == json['type']),
        status:
            TransferStatus.values.firstWhere((s) => s.name == json['status']),
        totalBytes: json['totalBytes'] as int,
        transferredBytes: json['transferredBytes'] as int? ?? 0,
        speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        errorMessage: json['errorMessage'] as String?,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
  final String id;
  final String fileName;
  final String filePath;
  final TransferType type;
  final TransferStatus status;
  final int totalBytes;
  final int transferredBytes;
  final double speed; // bytes per second
  final DateTime startTime;
  final DateTime? endTime;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  FileTransferModel copyWith({
    String? id,
    String? fileName,
    String? filePath,
    TransferType? type,
    TransferStatus? status,
    int? totalBytes,
    int? transferredBytes,
    double? speed,
    DateTime? startTime,
    DateTime? endTime,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) =>
      FileTransferModel(
        id: id ?? this.id,
        fileName: fileName ?? this.fileName,
        filePath: filePath ?? this.filePath,
        type: type ?? this.type,
        status: status ?? this.status,
        totalBytes: totalBytes ?? this.totalBytes,
        transferredBytes: transferredBytes ?? this.transferredBytes,
        speed: speed ?? this.speed,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        errorMessage: errorMessage ?? this.errorMessage,
        metadata: metadata ?? this.metadata,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'type': type.name,
        'status': status.name,
        'totalBytes': totalBytes,
        'transferredBytes': transferredBytes,
        'speed': speed,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'errorMessage': errorMessage,
        'metadata': metadata,
      };

  // Computed properties
  double get progress => totalBytes > 0 ? transferredBytes / totalBytes : 0.0;
  String get progressText => '${(progress * 100).toStringAsFixed(1)}%';
  String get speedText {
    if (speed < 1024) return '${speed.toStringAsFixed(1)} B/s';
    if (speed < 1024 * 1024) return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    if (speed < 1024 * 1024 * 1024)
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    return '${(speed / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }

  String get sizeText {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024)
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024)
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get isCompleted => status == TransferStatus.completed;
  bool get isFailed => status == TransferStatus.failed;
  bool get isInProgress => status == TransferStatus.inProgress;
  Duration? get duration => endTime?.difference(startTime);

  @override
  List<Object?> get props => [
        id,
        fileName,
        filePath,
        type,
        status,
        totalBytes,
        transferredBytes,
        speed,
        startTime,
        endTime,
        errorMessage,
        metadata,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileTransferModel &&
        other.id == id &&
        other.fileName == fileName &&
        other.filePath == filePath &&
        other.type == type &&
        other.status == status &&
        other.totalBytes == totalBytes &&
        other.transferredBytes == transferredBytes &&
        other.speed == speed &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.errorMessage == errorMessage &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        fileName,
        filePath,
        type,
        status,
        totalBytes,
        transferredBytes,
        speed,
        startTime,
        endTime,
        errorMessage,
        metadata,
      );
}
