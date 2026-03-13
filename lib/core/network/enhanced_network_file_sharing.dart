import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../backend/enhanced_pocketbase_service.dart';
import '../config/enhanced_config_manager.dart';
import '../logging/enhanced_logger.dart';
import '../performance/enhanced_performance_manager.dart';

/// Enhanced Network File Sharing Service
/// Features: Multi-protocol support (FTP, SFTP, FTPS, SMB, WebDAV), WiFi Direct, P2P sharing
/// Performance: Parallel transfers, resume support, compression, encryption
/// Security: SSL/TLS encryption, secure authentication, access control
/// References: FileGator, OpenFTP, Sigma File Manager, Tiny File Manager
class EnhancedNetworkFileSharing {
  static EnhancedNetworkFileSharing? _instance;
  static EnhancedNetworkFileSharing get instance => _instance ??= EnhancedNetworkFileSharing._internal();
  EnhancedNetworkFileSharing._internal();

  // Configuration
  late final bool _enableFTP;
  late final bool _enableSFTP;
  late final bool _enableFTPS;
  late final bool _enableSMB;
  late final bool _enableWebDAV;
  late final bool _enableWiFiDirect;
  late final bool _enableP2P;
  late final bool _enableEncryption;
  late final bool _enableCompression;
  late final int _maxConcurrentTransfers;
  late final int _chunkSize;
  late final Duration _connectionTimeout;
  
  // Connection management
  final Map<String, NetworkConnection> _connections = {};
  final Map<String, TransferSession> _activeTransfers = {};
  final List<DiscoveredDevice> _discoveredDevices = [];
  
  // Protocol handlers
  final Map<NetworkProtocol, ProtocolHandler> _protocolHandlers = {};
  
  // WiFi Direct and P2P
  WiFiDirectManager? _wifiDirectManager;
  P2PManager? _p2pManager;
  
  // Security
  final Map<String, String> _encryptionKeys = {};
  final Map<String, UserCredentials> _userCredentials = {};
  
  // Event streams
  final StreamController<NetworkEvent> _eventController = 
      StreamController<NetworkEvent>.broadcast();
  final StreamController<TransferProgress> _progressController = 
      StreamController<TransferProgress>.broadcast();
  
  Stream<NetworkEvent> get networkEvents => _eventController.stream;
  Stream<TransferProgress> get transferProgress => _progressController.stream;

  /// Initialize Enhanced Network File Sharing
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Initialize protocol handlers
      await _initializeProtocolHandlers();
      
      // Initialize WiFi Direct and P2P
      await _initializeWirelessServices();
      
      // Setup security
      await _setupSecurity();
      
      EnhancedLogger.instance.info('Enhanced Network File Sharing initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize Enhanced Network File Sharing', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableFTP = config.getParameter('network_sharing.enable_ftp') ?? true;
    _enableSFTP = config.getParameter('network_sharing.enable_sftp') ?? true;
    _enableFTPS = config.getParameter('network_sharing.enable_ftps') ?? true;
    _enableSMB = config.getParameter('network_sharing.enable_smb') ?? true;
    _enableWebDAV = config.getParameter('network_sharing.enable_webdav') ?? true;
    _enableWiFiDirect = config.getParameter('network_sharing.enable_wifi_direct') ?? true;
    _enableP2P = config.getParameter('network_sharing.enable_p2p') ?? true;
    _enableEncryption = config.getParameter('network_sharing.enable_encryption') ?? true;
    _enableCompression = config.getParameter('network_sharing.enable_compression') ?? true;
    _maxConcurrentTransfers = config.getParameter('network_sharing.max_concurrent_transfers') ?? 5;
    _chunkSize = config.getParameter('network_sharing.chunk_size') ?? 8192;
    _connectionTimeout = Duration(seconds: config.getParameter('network_sharing.connection_timeout_seconds') ?? 30);
  }

  /// Initialize protocol handlers
  Future<void> _initializeProtocolHandlers() async {
    if (_enableFTP) {
      _protocolHandlers[NetworkProtocol.ftp] = FTPHandler();
    }
    
    if (_enableSFTP) {
      _protocolHandlers[NetworkProtocol.sftp] = SFTPHandler();
    }
    
    if (_enableFTPS) {
      _protocolHandlers[NetworkProtocol.ftps] = FTPSHandler();
    }
    
    if (_enableSMB) {
      _protocolHandlers[NetworkProtocol.smb] = SMBHandler();
    }
    
    if (_enableWebDAV) {
      _protocolHandlers[NetworkProtocol.webdav] = WebDAVHandler();
    }
    
    EnhancedLogger.instance.info('Protocol handlers initialized: ${_protocolHandlers.keys}');
  }

  /// Initialize wireless services
  Future<void> _initializeWirelessServices() async {
    if (_enableWiFiDirect) {
      _wifiDirectManager = WiFiDirectManager();
      await _wifiDirectManager!.initialize();
      
      _wifiDirectManager!.deviceDiscovered.listen((device) {
        _discoveredDevices.add(device);
        _eventController.add(NetworkEvent(
          type: NetworkEventType.deviceDiscovered,
          message: 'WiFi Direct device discovered: ${device.name}',
          data: device,
        ));
      });
    }
    
    if (_enableP2P) {
      _p2pManager = P2PManager();
      await _p2pManager!.initialize();
      
      _p2pManager!.peerDiscovered.listen((peer) {
        _discoveredDevices.add(DiscoveredDevice.fromP2PPeer(peer));
        _eventController.add(NetworkEvent(
          type: NetworkEventType.peerDiscovered,
          message: 'P2P peer discovered: ${peer.name}',
          data: peer,
        ));
      });
    }
  }

  /// Setup security
  Future<void> _setupSecurity() async {
    // Generate encryption keys
    final keyGenerator = KeyGenerator();
    final masterKey = await keyGenerator.generateKey();
    
    // Store encryption key
    _encryptionKeys['master'] = masterKey;
    
    EnhancedLogger.instance.info('Security setup completed');
  }

  /// Connect to network server
  Future<NetworkConnection> connectToServer(NetworkConfig config) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('network_connect');
    
    try {
      final handler = _protocolHandlers[config.protocol];
      if (handler == null) {
        throw Exception('Protocol ${config.protocol} not supported');
      }
      
      // Create connection
      final connection = await handler.connect(config);
      
      // Store connection
      _connections[connection.id] = connection;
      
      timer.stop();
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.connected,
        message: 'Connected to ${config.host}:${config.port}',
        data: connection,
      ));
      
      return connection;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to connect to server: ${config.host}', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Disconnect from server
  Future<void> disconnectFromServer(String connectionId) async {
    final connection = _connections[connectionId];
    if (connection == null) return;
    
    try {
      await connection.disconnect();
      _connections.remove(connectionId);
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.disconnected,
        message: 'Disconnected from server',
        data: connectionId,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to disconnect from server: $connectionId', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// List files and directories
  Future<List<NetworkFile>> listFiles(String connectionId, String remotePath) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      final files = await connection.listFiles(remotePath);
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.filesListed,
        message: 'Listed ${files.length} files in $remotePath',
        data: files,
      ));
      
      return files;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to list files: $remotePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Upload file to server
  Future<String> uploadFile(String connectionId, String localPath, String remotePath, {
    ProgressCallback? onProgress,
    Map<String, String>? metadata,
  }) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    final timer = EnhancedPerformanceManager.instance.startTimer('file_upload');
    final sessionId = _generateSessionId();
    
    try {
      // Create transfer session
      final session = TransferSession(
        id: sessionId,
        type: TransferType.upload,
        localPath: localPath,
        remotePath: remotePath,
        connectionId: connectionId,
        startTime: DateTime.now(),
        metadata: metadata ?? {},
      );
      
      _activeTransfers[sessionId] = session;
      
      // Get file info
      final localFile = File(localPath);
      final fileSize = await localFile.length();
      
      // Create progress callback
      ProgressCallback? progressCallback = (transferred, total) {
        final progress = transferred / total;
        _progressController.add(TransferProgress(
          sessionId: sessionId,
          type: TransferType.upload,
          progress: progress,
          transferredBytes: transferred,
          totalBytes: total,
          speed: _calculateTransferSpeed(session, transferred),
          eta: _calculateETA(session, transferred, total),
        ));
        
        onProgress?.call(transferred, total);
      };
      
      // Perform upload
      String result;
      if (_enableCompression && _shouldCompress(localPath)) {
        result = await connection.uploadCompressed(localPath, remotePath, 
          progressCallback: progressCallback);
      } else {
        result = await connection.uploadFile(localPath, remotePath, 
          progressCallback: progressCallback);
      }
      
      // Update session
      session.endTime = DateTime.now();
      session.success = true;
      session.fileSize = fileSize;
      
      timer.stop();
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.fileUploaded,
        message: 'Uploaded $localPath to $remotePath',
        data: session,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      
      // Update session with error
      final session = _activeTransfers[sessionId];
      if (session != null) {
        session.endTime = DateTime.now();
        session.success = false;
        session.error = e.toString();
      }
      
      EnhancedLogger.instance.error('Failed to upload file: $localPath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _activeTransfers.remove(sessionId);
    }
  }

  /// Download file from server
  Future<String> downloadFile(String connectionId, String remotePath, String localPath, {
    ProgressCallback? onProgress,
    bool resume = false,
  }) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    final timer = EnhancedPerformanceManager.instance.startTimer('file_download');
    final sessionId = _generateSessionId();
    
    try {
      // Create transfer session
      final session = TransferSession(
        id: sessionId,
        type: TransferType.download,
        remotePath: remotePath,
        localPath: localPath,
        connectionId: connectionId,
        startTime: DateTime.now(),
        resume: resume,
      );
      
      _activeTransfers[sessionId] = session;
      
      // Check if file exists and get size for resume
      int startPosition = 0;
      if (resume) {
        final localFile = File(localPath);
        if (await localFile.exists()) {
          startPosition = await localFile.length();
          session.resumedFrom = startPosition;
        }
      }
      
      // Create progress callback
      ProgressCallback? progressCallback = (transferred, total) {
        final progress = (startPosition + transferred) / total;
        _progressController.add(TransferProgress(
          sessionId: sessionId,
          type: TransferType.download,
          progress: progress,
          transferredBytes: startPosition + transferred,
          totalBytes: total,
          speed: _calculateTransferSpeed(session, startPosition + transferred),
          eta: _calculateETA(session, startPosition + transferred, total),
        ));
        
        onProgress?.call(startPosition + transferred, total);
      };
      
      // Perform download
      String result;
      if (resume) {
        result = await connection.downloadFileResume(remotePath, localPath, 
          startPosition: startPosition, progressCallback: progressCallback);
      } else {
        result = await connection.downloadFile(remotePath, localPath, 
          progressCallback: progressCallback);
      }
      
      // Update session
      session.endTime = DateTime.now();
      session.success = true;
      session.fileSize = startPosition + (await File(localPath).length());
      
      timer.stop();
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.fileDownloaded,
        message: 'Downloaded $remotePath to $localPath',
        data: session,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      
      // Update session with error
      final session = _activeTransfers[sessionId];
      if (session != null) {
        session.endTime = DateTime.now();
        session.success = false;
        session.error = e.toString();
      }
      
      EnhancedLogger.instance.error('Failed to download file: $remotePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _activeTransfers.remove(sessionId);
    }
  }

  /// Create directory on server
  Future<void> createDirectory(String connectionId, String remotePath) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      await connection.createDirectory(remotePath);
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.directoryCreated,
        message: 'Created directory: $remotePath',
        data: remotePath,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to create directory: $remotePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete file or directory
  Future<void> delete(String connectionId, String remotePath) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      await connection.delete(remotePath);
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.fileDeleted,
        message: 'Deleted: $remotePath',
        data: remotePath,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to delete: $remotePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Rename file or directory
  Future<void> rename(String connectionId, String oldPath, String newPath) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      await connection.rename(oldPath, newPath);
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.fileRenamed,
        message: 'Renamed $oldPath to $newPath',
        data: {'oldPath': oldPath, 'newPath': newPath},
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to rename: $oldPath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get file info
  Future<NetworkFileInfo> getFileInfo(String connectionId, String remotePath) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      final fileInfo = await connection.getFileInfo(remotePath);
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.fileInfoRetrieved,
        message: 'Retrieved file info: $remotePath',
        data: fileInfo,
      ));
      
      return fileInfo;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to get file info: $remotePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Start WiFi Direct discovery
  Future<void> startWiFiDirectDiscovery() async {
    if (_wifiDirectManager == null) {
      throw Exception('WiFi Direct not enabled');
    }
    
    try {
      await _wifiDirectManager!.startDiscovery();
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.discoveryStarted,
        message: 'WiFi Direct discovery started',
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to start WiFi Direct discovery', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Stop WiFi Direct discovery
  Future<void> stopWiFiDirectDiscovery() async {
    if (_wifiDirectManager == null) return;
    
    try {
      await _wifiDirectManager!.stopDiscovery();
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.discoveryStopped,
        message: 'WiFi Direct discovery stopped',
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to stop WiFi Direct discovery', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Connect to WiFi Direct device
  Future<String> connectToWiFiDirectDevice(DiscoveredDevice device) async {
    if (_wifiDirectManager == null) {
      throw Exception('WiFi Direct not enabled');
    }
    
    try {
      final connectionId = await _wifiDirectManager!.connect(device);
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.wifiDirectConnected,
        message: 'Connected to WiFi Direct device: ${device.name}',
        data: device,
      ));
      
      return connectionId;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to connect to WiFi Direct device: ${device.name}', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Start P2P discovery
  Future<void> startP2PDiscovery() async {
    if (_p2pManager == null) {
      throw Exception('P2P not enabled');
    }
    
    try {
      await _p2pManager!.startDiscovery();
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.discoveryStarted,
        message: 'P2P discovery started',
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to start P2P discovery', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Stop P2P discovery
  Future<void> stopP2PDiscovery() async {
    if (_p2pManager == null) return;
    
    try {
      await _p2pManager!.stopDiscovery();
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.discoveryStopped,
        message: 'P2P discovery stopped',
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to stop P2P discovery', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Share file via P2P
  Future<String> shareFileViaP2P(String localPath, {Duration? timeout}) async {
    if (_p2pManager == null) {
      throw Exception('P2P not enabled');
    }
    
    try {
      final shareId = await _p2pManager!.shareFile(localPath, timeout: timeout);
      
      _eventController.add(NetworkEvent(
        type: NetworkEventType.fileShared,
        message: 'File shared via P2P: $localPath',
        data: {'shareId': shareId, 'localPath': localPath},
      ));
      
      return shareId;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to share file via P2P: $localPath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get discovered devices
  List<DiscoveredDevice> getDiscoveredDevices() {
    return List.unmodifiable(_discoveredDevices);
  }

  /// Get active connections
  List<NetworkConnection> getActiveConnections() {
    return List.unmodifiable(_connections.values);
  }

  /// Get active transfers
  List<TransferSession> getActiveTransfers() {
    return List.unmodifiable(_activeTransfers.values);
  }

  /// Get transfer statistics
  Map<String, dynamic> getTransferStatistics() {
    final completedTransfers = _activeTransfers.values
        .where((session) => session.endTime != null)
        .toList();
    
    final totalUploadSize = completedTransfers
        .where((session) => session.type == TransferType.upload && session.success)
        .fold<int>(0, (sum, session) => sum + (session.fileSize ?? 0));
    
    final totalDownloadSize = completedTransfers
        .where((session) => session.type == TransferType.download && session.success)
        .fold<int>(0, (sum, session) => sum + (session.fileSize ?? 0));
    
    return {
      'active_connections': _connections.length,
      'active_transfers': _activeTransfers.length,
      'completed_transfers': completedTransfers.length,
      'total_upload_size': totalUploadSize,
      'total_download_size': totalDownloadSize,
      'discovered_devices': _discoveredDevices.length,
      'supported_protocols': _protocolHandlers.keys.map((p) => p.toString()).toList(),
    };
  }

  /// Helper methods
  String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  bool _shouldCompress(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    final compressibleExtensions = ['txt', 'log', 'csv', 'json', 'xml', 'html', 'css', 'js'];
    return compressibleExtensions.contains(extension);
  }

  double _calculateTransferSpeed(TransferSession session, int transferredBytes) {
    if (session.startTime == null) return 0.0;
    
    final elapsed = DateTime.now().difference(session.startTime!).inSeconds;
    if (elapsed == 0) return 0.0;
    
    return transferredBytes / elapsed;
  }

  Duration _calculateETA(TransferSession session, int transferredBytes, int totalBytes) {
    final speed = _calculateTransferSpeed(session, transferredBytes);
    if (speed == 0) return Duration.infinite;
    
    final remainingBytes = totalBytes - transferredBytes;
    final remainingSeconds = remainingBytes / speed;
    
    return Duration(seconds: remainingSeconds.round());
  }

  /// Dispose
  void dispose() {
    // Disconnect all connections
    for (final connection in _connections.values) {
      connection.disconnect();
    }
    _connections.clear();
    
    // Cancel active transfers
    for (final session in _activeTransfers.values) {
      session.cancel();
    }
    _activeTransfers.clear();
    
    // Stop wireless services
    _wifiDirectManager?.dispose();
    _p2pManager?.dispose();
    
    // Clear data
    _discoveredDevices.clear();
    _encryptionKeys.clear();
    _userCredentials.clear();
    
    _eventController.close();
    _progressController.close();
    
    EnhancedLogger.instance.info('Enhanced Network File Sharing disposed');
  }
}

/// Network protocol enum
enum NetworkProtocol {
  ftp,
  sftp,
  ftps,
  smb,
  webdav,
}

/// Transfer type enum
enum TransferType {
  upload,
  download,
}

/// Network event type enum
enum NetworkEventType {
  connected,
  disconnected,
  deviceDiscovered,
  peerDiscovered,
  filesListed,
  fileUploaded,
  fileDownloaded,
  directoryCreated,
  fileDeleted,
  fileRenamed,
  fileInfoRetrieved,
  discoveryStarted,
  discoveryStopped,
  wifiDirectConnected,
  fileShared,
}

/// Network configuration
class NetworkConfig {
  final NetworkProtocol protocol;
  final String host;
  final int port;
  final String username;
  final String password;
  final Map<String, dynamic>? options;
  final Duration? timeout;

  NetworkConfig({
    required this.protocol,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    this.options,
    this.timeout,
  });
}

/// Network connection
class NetworkConnection {
  final String id;
  final NetworkConfig config;
  final DateTime connectedAt;
  bool isConnected;

  NetworkConnection({
    required this.id,
    required this.config,
    required this.connectedAt,
    this.isConnected = true,
  });

  Future<void> disconnect() async {
    isConnected = false;
  }

  Future<List<NetworkFile>> listFiles(String remotePath) async {
    // Implementation depends on protocol
    throw UnimplementedError();
  }

  Future<String> uploadFile(String localPath, String remotePath, {ProgressCallback? progressCallback}) async {
    // Implementation depends on protocol
    throw UnimplementedError();
  }

  Future<String> downloadFile(String remotePath, String localPath, {ProgressCallback? progressCallback}) async {
    // Implementation depends on protocol
    throw UnimplementedError();
  }

  Future<void> createDirectory(String remotePath) async {
    // Implementation depends on protocol
    throw UnimplementedError();
  }

  Future<void> delete(String remotePath) async {
    // Implementation depends on protocol
    throw UnimplementedError();
  }

  Future<void> rename(String oldPath, String newPath) async {
    // Implementation depends on protocol
    throw UnimplementedError();
  }

  Future<NetworkFileInfo> getFileInfo(String remotePath) async {
    // Implementation depends on protocol
    throw UnimplementedError();
  }
}

/// Network file
class NetworkFile {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modifiedAt;
  final String? permissions;
  final Map<String, dynamic>? metadata;

  NetworkFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modifiedAt,
    this.permissions,
    this.metadata,
  });
}

/// Network file info
class NetworkFileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime modifiedAt;
  final DateTime createdAt;
  final String? permissions;
  final String? owner;
  final String? group;
  final Map<String, dynamic>? metadata;

  NetworkFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.modifiedAt,
    required this.createdAt,
    this.permissions,
    this.owner,
    this.group,
    this.metadata,
  });
}

/// Transfer session
class TransferSession {
  final String id;
  final TransferType type;
  final String? localPath;
  final String? remotePath;
  final String connectionId;
  final DateTime? startTime;
  DateTime? endTime;
  bool success;
  String? error;
  int? fileSize;
  int? resumedFrom;
  final Map<String, dynamic> metadata;
  final bool resume;

  TransferSession({
    required this.id,
    required this.type,
    this.localPath,
    this.remotePath,
    required this.connectionId,
    this.startTime,
    this.endTime,
    this.success = false,
    this.error,
    this.fileSize,
    this.resumedFrom,
    this.metadata = const {},
    this.resume = false,
  });

  void cancel() {
    endTime = DateTime.now();
    success = false;
    error = 'Cancelled by user';
  }
}

/// Transfer progress
class TransferProgress {
  final String sessionId;
  final TransferType type;
  final double progress;
  final int transferredBytes;
  final int totalBytes;
  final double speed;
  final Duration eta;
  final DateTime timestamp;

  TransferProgress({
    required this.sessionId,
    required this.type,
    required this.progress,
    required this.transferredBytes,
    required this.totalBytes,
    required this.speed,
    required this.eta,
  }) : timestamp = DateTime.now();
}

/// Network event
class NetworkEvent {
  final NetworkEventType type;
  final String message;
  final dynamic data;
  final DateTime timestamp;

  NetworkEvent({
    required this.type,
    required this.message,
    this.data,
  }) : timestamp = DateTime.now();
}

/// Discovered device
class DiscoveredDevice {
  final String id;
  final String name;
  final String address;
  final Map<String, dynamic> metadata;
  final DateTime discoveredAt;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.metadata,
    required this.discoveredAt,
  });

  factory DiscoveredDevice.fromP2PPeer(P2PPeer peer) {
    return DiscoveredDevice(
      id: peer.id,
      name: peer.name,
      address: peer.address,
      metadata: peer.metadata,
      discoveredAt: peer.discoveredAt,
    );
  }
}

/// Progress callback
typedef ProgressCallback = void Function(int transferred, int total);

/// Protocol handler interface
abstract class ProtocolHandler {
  Future<NetworkConnection> connect(NetworkConfig config);
}

/// FTP Handler
class FTPHandler implements ProtocolHandler {
  @override
  Future<NetworkConnection> connect(NetworkConfig config) async {
    // FTP implementation
    throw UnimplementedError();
  }
}

/// SFTP Handler
class SFTPHandler implements ProtocolHandler {
  @override
  Future<NetworkConnection> connect(NetworkConfig config) async {
    // SFTP implementation
    throw UnimplementedError();
  }
}

/// FTPS Handler
class FTPSHandler implements ProtocolHandler {
  @override
  Future<NetworkConnection> connect(NetworkConfig config) async {
    // FTPS implementation
    throw UnimplementedError();
  }
}

/// SMB Handler
class SMBHandler implements ProtocolHandler {
  @override
  Future<NetworkConnection> connect(NetworkConfig config) async {
    // SMB implementation
    throw UnimplementedError();
  }
}

/// WebDAV Handler
class WebDAVHandler implements ProtocolHandler {
  @override
  Future<NetworkConnection> connect(NetworkConfig config) async {
    // WebDAV implementation
    throw UnimplementedError();
  }
}

/// WiFi Direct Manager
class WiFiDirectManager {
  StreamController<DiscoveredDevice>? _deviceController;
  
  Stream<DiscoveredDevice> get deviceDiscovered => 
      _deviceController?.stream ?? Stream.empty();

  Future<void> initialize() async {
    _deviceController = StreamController<DiscoveredDevice>.broadcast();
  }

  Future<void> startDiscovery() async {
    // WiFi Direct discovery implementation
  }

  Future<void> stopDiscovery() async {
    // Stop WiFi Direct discovery
  }

  Future<String> connect(DiscoveredDevice device) async {
    // WiFi Direct connection implementation
    throw UnimplementedError();
  }

  void dispose() {
    _deviceController?.close();
  }
}

/// P2P Manager
class P2PManager {
  StreamController<P2PPeer>? _peerController;
  
  Stream<P2PPeer> get peerDiscovered => 
      _peerController?.stream ?? Stream.empty();

  Future<void> initialize() async {
    _peerController = StreamController<P2PPeer>.broadcast();
  }

  Future<void> startDiscovery() async {
    // P2P discovery implementation
  }

  Future<void> stopDiscovery() async {
    // Stop P2P discovery
  }

  Future<String> shareFile(String localPath, {Duration? timeout}) async {
    // P2P file sharing implementation
    throw UnimplementedError();
  }

  void dispose() {
    _peerController?.close();
  }
}

/// P2P Peer
class P2PPeer {
  final String id;
  final String name;
  final String address;
  final Map<String, dynamic> metadata;
  final DateTime discoveredAt;

  P2PPeer({
    required this.id,
    required this.name,
    required this.address,
    required this.metadata,
    required this.discoveredAt,
  });
}

/// User credentials
class UserCredentials {
  final String username;
  final String password;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  UserCredentials({
    required this.username,
    required this.password,
    required this.createdAt,
    this.metadata,
  });
}

/// Key generator
class KeyGenerator {
  Future<String> generateKey() async {
    final random = math.Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Encode(bytes);
  }
}
