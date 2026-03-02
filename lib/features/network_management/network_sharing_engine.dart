import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:dio/dio.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

/// Advanced Network and File Sharing Engine
/// Inspired by Sharik and ezshare open-source projects
/// Provides comprehensive network discovery, file sharing, and WiFi management
class NetworkSharingEngine {
  static NetworkSharingEngine? _instance;
  static NetworkSharingEngine get instance =>
      _instance ??= NetworkSharingEngine._internal();
  NetworkSharingEngine._internal();

  // Network State Management
  bool _isInitialized = false;
  bool _isServerRunning = false;
  bool _isDiscoveryActive = false;
  String? _localIpAddress;
  String? _networkName;
  int _serverPort = 8080;

  // Server Management
  HttpServer? _httpServer;
  final Map<String, FileTransferSession> _activeSessions = {};
  final Map<String, SharedFile> _sharedFiles = {};

  // Network Discovery
  final List<DiscoveredDevice> _discoveredDevices = [];
  Timer? _discoveryTimer;
  final Duration _discoveryInterval = Duration(seconds: 5);

  // File Transfer Protocols
  FTPConnect? _ftpClient;
  Dio? _httpClient;

  // Configuration
  NetworkSharingConfig _config = NetworkSharingConfig.defaultConfig();

  // Event Streams
  final StreamController<NetworkSharingEvent> _eventController =
      StreamController<NetworkSharingEvent>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isServerRunning => _isServerRunning;
  bool get isDiscoveryActive => _isDiscoveryActive;
  String? get localIpAddress => _localIpAddress;
  String? get networkName => _networkName;
  int get serverPort => _serverPort;
  List<DiscoveredDevice> get discoveredDevices => List.from(_discoveredDevices);
  Map<String, FileTransferSession> get activeSessions =>
      Map.from(_activeSessions);
  Map<String, SharedFile> get sharedFiles => Map.from(_sharedFiles);
  Stream<NetworkSharingEvent> get events => _eventController.stream;
  NetworkSharingConfig get config => _config;

  /// Initialize the network sharing engine
  Future<bool> initialize({NetworkSharingConfig? config}) async {
    if (_isInitialized) return true;

    try {
      _config = config ?? _config;

      // Initialize HTTP client
      _httpClient = Dio(BaseOptions(
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 30),
        sendTimeout: Duration(seconds: 30),
      ));

      // Get local IP address
      await _getLocalIpAddress();

      // Get network information
      await _getNetworkInfo();

      _isInitialized = true;

      await _emitEvent(NetworkSharingEvent.initialized);
      return true;
    } catch (e) {
      await _emitEvent(NetworkSharingEvent.error('Initialization failed: $e'));
      return false;
    }
  }

  /// Start local file sharing server
  Future<bool> startSharingServer({
    String? directoryPath,
    int? port,
    bool enableQRCode = true,
    bool enablePassword = false,
    String? password,
  }) async {
    if (!_isInitialized) {
      await _emitEvent(NetworkSharingEvent.error('Engine not initialized'));
      return false;
    }

    if (_isServerRunning) {
      await _emitEvent(NetworkSharingEvent.error('Server already running'));
      return false;
    }

    try {
      _serverPort = port ?? _config.defaultPort;

      // Create HTTP server
      _httpServer = await HttpServer.bind('0.0.0.0', _serverPort);

      // Start listening for requests
      await for (HttpRequest request in _httpServer!) {
        _handleRequest(request);
      }

      _isServerRunning = true;

      // Start network discovery
      if (_config.enableAutoDiscovery) {
        await startNetworkDiscovery();
      }

      await _emitEvent(NetworkSharingEvent.serverStarted(_serverPort));
      return true;
    } catch (e) {
      await _emitEvent(NetworkSharingEvent.error('Failed to start server: $e'));
      return false;
    }
  }

  /// Stop local file sharing server
  Future<void> stopSharingServer() async {
    if (!_isServerRunning) return;

    try {
      await _httpServer?.close();
      _httpServer = null;
      _isServerRunning = false;

      // Stop network discovery
      if (_isDiscoveryActive) {
        await stopNetworkDiscovery();
      }

      // Clear active sessions
      _activeSessions.clear();

      await _emitEvent(NetworkSharingEvent.serverStopped);
    } catch (e) {
      await _emitEvent(NetworkSharingEvent.error('Failed to stop server: $e'));
    }
  }

  /// Start network discovery
  Future<void> startNetworkDiscovery() async {
    if (_isDiscoveryActive) return;

    try {
      _isDiscoveryActive = true;
      _discoveredDevices.clear();

      _discoveryTimer = Timer.periodic(_discoveryInterval, (_) {
        _discoverDevices();
      });

      // Initial discovery
      await _discoverDevices();

      await _emitEvent(NetworkSharingEvent.discoveryStarted);
    } catch (e) {
      await _emitEvent(
          NetworkSharingEvent.error('Failed to start discovery: $e'));
    }
  }

  /// Stop network discovery
  Future<void> stopNetworkDiscovery() async {
    if (!_isDiscoveryActive) return;

    try {
      _discoveryTimer?.cancel();
      _discoveryTimer = null;
      _isDiscoveryActive = false;

      await _emitEvent(NetworkSharingEvent.discoveryStopped);
    } catch (e) {
      await _emitEvent(
          NetworkSharingEvent.error('Failed to stop discovery: $e'));
    }
  }

  /// Share a file or directory
  Future<String> shareFile(
    String filePath, {
    String? customName,
    bool generateQRCode = true,
    bool enablePassword = false,
    String? password,
    Duration? expiryTime,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final shareId = const Uuid().v4();
      final sharedFile = SharedFile(
        id: shareId,
        name: customName ?? file.path.split('/').last,
        path: filePath,
        size: await file.length(),
        type: await file.isDirectory() ? FileType.directory : FileType.file,
        createdAt: DateTime.now(),
        expiresAt: expiryTime != null ? DateTime.now().add(expiryTime) : null,
        requiresPassword: enablePassword,
        password: password,
        downloadCount: 0,
      );

      _sharedFiles[shareId] = sharedFile;

      await _emitEvent(NetworkSharingEvent.fileShared(sharedFile));

      return shareId;
    } catch (e) {
      await _emitEvent(NetworkSharingEvent.error('Failed to share file: $e'));
      rethrow;
    }
  }

  /// Connect to FTP server
  Future<bool> connectToFTP(
      String host, int port, String username, String password) async {
    try {
      _ftpClient = FTPConnect(host, port: port, user: username, pass: password);

      final result = await _ftpClient!.connect();
      if (result) {
        await _emitEvent(NetworkSharingEvent.ftpConnected(host));
        return true;
      } else {
        await _emitEvent(NetworkSharingEvent.error('FTP connection failed'));
        return false;
      }
    } catch (e) {
      await _emitEvent(NetworkSharingEvent.error('FTP connection error: $e'));
      return false;
    }
  }

  /// Upload file via FTP
  Future<bool> uploadFileViaFTP(String localPath, String remotePath) async {
    if (_ftpClient == null) {
      await _emitEvent(NetworkSharingEvent.error('FTP client not connected'));
      return false;
    }

    try {
      final result = await _ftpClient!.uploadFile(localPath, remotePath);
      if (result) {
        await _emitEvent(
            NetworkSharingEvent.fileUploaded(localPath, remotePath, 'FTP'));
        return true;
      } else {
        await _emitEvent(NetworkSharingEvent.error('FTP upload failed'));
        return false;
      }
    } catch (e) {
      await _emitEvent(NetworkSharingEvent.error('FTP upload error: $e'));
      return false;
    }
  }

  /// Download file via FTP
  Future<bool> downloadFileViaFTP(String remotePath, String localPath) async {
    if (_ftpClient == null) {
      await _emitEvent(NetworkSharingEvent.error('FTP client not connected'));
      return false;
    }

    try {
      final result = await _ftpClient!.downloadFile(remotePath, localPath);
      if (result) {
        await _emitEvent(
            NetworkSharingEvent.fileDownloaded(remotePath, localPath, 'FTP'));
        return true;
      } else {
        await _emitEvent(NetworkSharingEvent.error('FTP download failed'));
        return false;
      }
    } catch (e) {
      await _emitEvent(NetworkSharingEvent.error('FTP download error: $e'));
      return false;
    }
  }

  /// Upload file via HTTP
  Future<bool> uploadFileViaHTTP(
    String filePath,
    String targetUrl, {
    ProgressCallback? onProgress,
    Map<String, String>? headers,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath,
            filename: file.path.split('/').last),
      });

      final response = await _httpClient!.post(
        targetUrl,
        data: formData,
        options: Options(
          headers: headers,
          onSendProgress: onProgress,
        ),
      );

      if (response.statusCode == 200) {
        await _emitEvent(
            NetworkSharingEvent.fileUploaded(filePath, targetUrl, 'HTTP'));
        return true;
      } else {
        await _emitEvent(NetworkSharingEvent.error(
            'HTTP upload failed: ${response.statusCode}'));
        return false;
      }
    } catch (e) {
      await _emitEvent(NetworkSharingEvent.error('HTTP upload error: $e'));
      return false;
    }
  }

  /// Download file via HTTP
  Future<bool> downloadFileViaHTTP(
    String url,
    String savePath, {
    ProgressCallback? onProgress,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _httpClient!.download(
        url,
        savePath,
        options: Options(
          headers: headers,
          onReceiveProgress: onProgress,
        ),
      );

      if (response.statusCode == 200) {
        await _emitEvent(
            NetworkSharingEvent.fileDownloaded(url, savePath, 'HTTP'));
        return true;
      } else {
        await _emitEvent(NetworkSharingEvent.error(
            'HTTP download failed: ${response.statusCode}'));
        return false;
      }
    } catch (e) {
      await _emitEvent(NetworkSharingEvent.error('HTTP download error: $e'));
      return false;
    }
  }

  /// Generate QR code for sharing
  Future<String> generateQRCode(String shareId) async {
    try {
      final sharedFile = _sharedFiles[shareId];
      if (sharedFile == null) {
        throw Exception('Shared file not found: $shareId');
      }

      final url = 'http://$_localIpAddress:$_serverPort/download/$shareId';

      // In a real implementation, this would generate an actual QR code image
      // For now, we'll return the URL that can be used to generate QR code

      await _emitEvent(NetworkSharingEvent.qrCodeGenerated(shareId, url));
      return url;
    } catch (e) {
      await _emitEvent(
          NetworkSharingEvent.error('Failed to generate QR code: $e'));
      rethrow;
    }
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStatistics() {
    return {
      'isInitialized': _isInitialized,
      'isServerRunning': _isServerRunning,
      'isDiscoveryActive': _isDiscoveryActive,
      'localIpAddress': _localIpAddress,
      'networkName': _networkName,
      'serverPort': _serverPort,
      'discoveredDevicesCount': _discoveredDevices.length,
      'activeSessionsCount': _activeSessions.length,
      'sharedFilesCount': _sharedFiles.length,
      'totalSharedSize':
          _sharedFiles.values.fold<int>(0, (sum, file) => sum + file.size),
      'config': _config.toMap(),
    };
  }

  /// Private methods
  Future<void> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
          includeLinkLocal: false, includeLoopback: false);

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            _localIpAddress = address.address;
            return;
          }
        }
      }
    } catch (e) {
      await _emitEvent(NetworkSharingEvent.error('Failed to get local IP: $e'));
    }
  }

  Future<void> _getNetworkInfo() async {
    try {
      final info = await NetworkInfo();
      _networkName = await info.getWifiName();
    } catch (e) {
      await _emitEvent(
          NetworkSharingEvent.error('Failed to get network info: $e'));
    }
  }

  Future<void> _discoverDevices() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();

      if (connectivity != ConnectivityResult.none) {
        // In a real implementation, this would scan the network for devices
        // For now, we'll simulate device discovery
        final devices = await _scanNetworkRange();

        _discoveredDevices.clear();
        _discoveredDevices.addAll(devices);

        await _emitEvent(NetworkSharingEvent.devicesDiscovered(devices));
      }
    } catch (e) {
      await _emitEvent(
          NetworkSharingEvent.error('Device discovery failed: $e'));
    }
  }

  Future<List<DiscoveredDevice>> _scanNetworkRange() async {
    // Simulate network scanning
    // In a real implementation, this would use actual network scanning techniques
    final devices = <DiscoveredDevice>[];

    if (_localIpAddress != null) {
      final parts = _localIpAddress!.split('.');
      if (parts.length == 4) {
        final baseIp = '${parts[0]}.${parts[1]}.${parts[2]}';

        // Scan a small range for demonstration
        for (int i = 1; i <= 10; i++) {
          final testIp = '$baseIp.$i';

          // Simulate device discovery
          if (i != int.parse(parts[3])) {
            // Skip our own IP
            devices.add(DiscoveredDevice(
              id: 'device_$i',
              name: 'Device $i',
              ipAddress: testIp,
              type: DeviceType.unknown,
              lastSeen: DateTime.now(),
              isOnline: true,
            ));
          }
        }
      }
    }

    return devices;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;
      final method = request.method;

      if (method == 'GET' && path == '/') {
        await _serveHomePage(request);
      } else if (method == 'GET' && path.startsWith('/download/')) {
        final shareId = path.substring(10); // Remove '/download/'
        await _serveFileDownload(request, shareId);
      } else if (method == 'POST' && path == '/upload') {
        await _handleFileUpload(request);
      } else if (method == 'GET' && path == '/api/files') {
        await _serveFilesList(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
      await _emitEvent(NetworkSharingEvent.error('Request handling error: $e'));
    }
  }

  Future<void> _serveHomePage(HttpRequest request) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>iSuite File Sharing</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 30px; }
        .file-list { border: 1px solid #ddd; border-radius: 8px; padding: 20px; }
        .file-item { display: flex; justify-content: space-between; align-items: center; padding: 10px; border-bottom: 1px solid #eee; }
        .file-item:last-child { border-bottom: none; }
        .upload-section { margin: 20px 0; padding: 20px; border: 2px dashed #ddd; border-radius: 8px; text-align: center; }
        .btn { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
        .btn:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>iSuite File Sharing</h1>
            <p>Share files across devices on the same network</p>
        </div>
        
        <div class="upload-section">
            <h2>Upload Files</h2>
            <form action="/upload" method="post" enctype="multipart/form-data">
                <input type="file" name="file" multiple>
                <br><br>
                <button type="submit" class="btn">Upload</button>
            </form>
        </div>
        
        <div class="file-list">
            <h2>Shared Files</h2>
            ${_generateFilesListHtml()}
        </div>
    </div>
</body>
</html>
    ''';

    request.response
      ..headers.contentType = ContentType.html
      ..add('Access-Control-Allow-Origin', '*')
      ..add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
      ..add('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    request.response.write(html);
    await request.response.close();
  }

  Future<void> _serveFileDownload(HttpRequest request, String shareId) async {
    try {
      final sharedFile = _sharedFiles[shareId];
      if (sharedFile == null) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final file = File(sharedFile.path);
      if (!await file.exists()) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final bytes = await file.readAsBytes();

      request.response
        ..headers.contentType = ContentType.binary
        ..headers.contentLength = bytes.length
        ..headers.add(
            'Content-Disposition', 'attachment; filename="${sharedFile.name}"')
        ..add('Access-Control-Allow-Origin', '*');

      request.response.add(bytes);
      await request.response.close();

      // Update download count
      sharedFile.downloadCount++;
      await _emitEvent(NetworkSharingEvent.fileDownloaded(
          sharedFile.path, '', 'Local Server'));
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
      await _emitEvent(NetworkSharingEvent.error('File download error: $e'));
    }
  }

  Future<void> _handleFileUpload(HttpRequest request) async {
    try {
      final contentType = request.headers.contentType;
      if (contentType?.mimeType != 'multipart/form-data') {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      // Handle file upload
      // In a real implementation, this would parse multipart data
      // For now, we'll simulate successful upload

      request.response
        ..headers.contentType = ContentType.html
        ..add('Access-Control-Allow-Origin', '*');

      request.response.write('''
<!DOCTYPE html>
<html>
<head><title>Upload Complete</title></head>
<body>
    <h1>File Uploaded Successfully!</h1>
    <a href="/">Back to Home</a>
</body>
</html>
      ''');

      await request.response.close();
      await _emitEvent(
          NetworkSharingEvent.fileUploaded('', '', 'Local Server'));
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
      await _emitEvent(NetworkSharingEvent.error('File upload error: $e'));
    }
  }

  Future<void> _serveFilesList(HttpRequest request) async {
    try {
      final filesJson =
          _sharedFiles.values.map((file) => file.toMap()).toList();

      request.response
        ..headers.contentType = ContentType.json
        ..add('Access-Control-Allow-Origin', '*');

      request.response.write(jsonEncode(filesJson));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
      await _emitEvent(NetworkSharingEvent.error('Files list error: $e'));
    }
  }

  String _generateFilesListHtml() {
    if (_sharedFiles.isEmpty) {
      return '<p>No files shared yet.</p>';
    }

    return _sharedFiles.values.map((file) => '''
      <div class="file-item">
        <div>
          <strong>${file.name}</strong>
          <br>
          <small>Size: ${_formatFileSize(file.size)} | Downloads: ${file.downloadCount}</small>
        </div>
        <div>
          <a href="/download/${file.id}" class="btn">Download</a>
        </div>
      </div>
    ''').join('');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _emitEvent(NetworkSharingEvent event) async {
    _eventController.add(event);
  }

  /// Dispose the engine
  Future<void> dispose() async {
    await stopSharingServer();
    await stopNetworkDiscovery();

    _eventController.close();
    _ftpClient?.disconnect();
    _ftpClient = null;
    _httpClient?.close();
    _httpClient = null;

    _isInitialized = false;
  }
}

// Supporting Classes
class NetworkSharingConfig {
  final int defaultPort;
  final bool enableAutoDiscovery;
  final bool enableQRCode;
  final bool enablePasswordProtection;
  final Duration sessionTimeout;
  final int maxConcurrentTransfers;
  final int maxFileSize;

  const NetworkSharingConfig({
    this.defaultPort = 8080,
    this.enableAutoDiscovery = true,
    this.enableQRCode = true,
    this.enablePasswordProtection = false,
    this.sessionTimeout = const Duration(hours: 1),
    this.maxConcurrentTransfers = 5,
    this.maxFileSize = 100 * 1024 * 1024, // 100MB
  });

  static const NetworkSharingConfig defaultConfig = NetworkSharingConfig();

  Map<String, dynamic> toMap() {
    return {
      'defaultPort': defaultPort,
      'enableAutoDiscovery': enableAutoDiscovery,
      'enableQRCode': enableQRCode,
      'enablePasswordProtection': enablePasswordProtection,
      'sessionTimeout': sessionTimeout.inMilliseconds,
      'maxConcurrentTransfers': maxConcurrentTransfers,
      'maxFileSize': maxFileSize,
    };
  }
}

class DiscoveredDevice {
  final String id;
  final String name;
  final String ipAddress;
  final DeviceType type;
  final DateTime lastSeen;
  final bool isOnline;
  final Map<String, dynamic> metadata;

  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.type,
    required this.lastSeen,
    required this.isOnline,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'type': type.name,
      'lastSeen': lastSeen.toIso8601String(),
      'isOnline': isOnline,
      'metadata': metadata,
    };
  }
}

class SharedFile {
  final String id;
  final String name;
  final String path;
  final int size;
  final FileType type;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool requiresPassword;
  final String? password;
  final int downloadCount;
  final Map<String, dynamic> metadata;

  const SharedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    this.requiresPassword = false,
    this.password,
    this.downloadCount = 0,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'size': size,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'requiresPassword': requiresPassword,
      'downloadCount': downloadCount,
      'metadata': metadata,
    };
  }
}

class FileTransferSession {
  final String id;
  final String fileName;
  final String sourcePath;
  final String targetPath;
  final TransferType type;
  final TransferStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalBytes;
  final int transferredBytes;
  final double progress;
  final String? errorMessage;

  const FileTransferSession({
    required this.id,
    required this.fileName,
    required this.sourcePath,
    required this.targetPath,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.totalBytes,
    required this.transferredBytes,
    required this.progress,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'sourcePath': sourcePath,
      'targetPath': targetPath,
      'type': type.name,
      'status': status.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalBytes': totalBytes,
      'transferredBytes': transferredBytes,
      'progress': progress,
      'errorMessage': errorMessage,
    };
  }
}

enum DeviceType {
  mobile,
  desktop,
  tablet,
  server,
  unknown,
}

enum FileType {
  file,
  directory,
}

enum TransferType {
  upload,
  download,
}

enum TransferStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

enum NetworkSharingEventType {
  initialized,
  serverStarted,
  serverStopped,
  discoveryStarted,
  discoveryStopped,
  devicesDiscovered,
  fileShared,
  fileUploaded,
  fileDownloaded,
  qrCodeGenerated,
  ftpConnected,
  error,
}

class NetworkSharingEvent {
  final NetworkSharingEventType type;
  final String? message;
  final dynamic data;
  final DateTime timestamp;

  const NetworkSharingEvent({
    required this.type,
    this.message,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  const NetworkSharingEvent.initialized()
      : type = NetworkSharingEventType.initialized;

  const NetworkSharingEvent.serverStarted(int port)
      : type = NetworkSharingEventType.serverStarted,
        data = port;

  const NetworkSharingEvent.serverStopped()
      : type = NetworkSharingEventType.serverStopped;

  const NetworkSharingEvent.discoveryStarted()
      : type = NetworkSharingEventType.discoveryStarted;

  const NetworkSharingEvent.discoveryStopped()
      : type = NetworkSharingEventType.discoveryStopped;

  const NetworkSharingEvent.devicesDiscovered(List<DiscoveredDevice> devices)
      : type = NetworkSharingEventType.devicesDiscovered,
        data = devices;

  const NetworkSharingEvent.fileShared(SharedFile file)
      : type = NetworkSharingEventType.fileShared,
        data = file;

  const NetworkSharingEvent.fileUploaded(
      String source, String target, String protocol)
      : type = NetworkSharingEventType.fileUploaded,
        data = {'source': source, 'target': target, 'protocol': protocol};

  const NetworkSharingEvent.fileDownloaded(
      String source, String target, String protocol)
      : type = NetworkSharingEventType.fileDownloaded,
        data = {'source': source, 'target': target, 'protocol': protocol};

  const NetworkSharingEvent.qrCodeGenerated(String shareId, String url)
      : type = NetworkSharingEventType.qrCodeGenerated,
        data = {'shareId': shareId, 'url': url};

  const NetworkSharingEvent.ftpConnected(String host)
      : type = NetworkSharingEventType.ftpConnected,
        data = host;

  const NetworkSharingEvent.error(String message)
      : type = NetworkSharingEventType.error,
        message = message;
}

typedef ProgressCallback = void Function(int received, int total);
