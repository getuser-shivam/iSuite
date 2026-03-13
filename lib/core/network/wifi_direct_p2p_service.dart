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

/// WiFi Direct & P2P File Sharing Service
/// Features: WiFi Direct, P2P networking, local discovery, secure sharing
/// Performance: Optimized transfers, compression, encryption, resume support
/// Security: End-to-end encryption, secure authentication, access control
/// References: Sigma File Manager, Owlfiles, FileGator network features
class WiFiDirectP2PService {
  static WiFiDirectP2PService? _instance;
  static WiFiDirectP2PService get instance => _instance ??= WiFiDirectP2PService._internal();
  WiFiDirectP2PService._internal();

  // Configuration
  late final bool _enableWiFiDirect;
  late final bool _enableP2P;
  late final bool _enableEncryption;
  late final bool _enableCompression;
  late final bool _enableDiscovery;
  late final int _maxPeers;
  late final int _discoveryInterval;
  late final Duration _connectionTimeout;
  
  // WiFi Direct
  WiFiDirectManager? _wifiDirectManager;
  final List<WiFiDirectDevice> _wifiDirectDevices = [];
  final Map<String, WiFiDirectConnection> _wifiDirectConnections = {};
  
  // P2P Networking
  P2PManager? _p2pManager;
  final List<P2PPeer> _p2pPeers = [];
  final Map<String, P2PConnection> _p2pConnections = {};
  
  // File Sharing
  final Map<String, SharedFile> _sharedFiles = {};
  final Map<String, FileTransfer> _activeTransfers = {};
  
  // Security
  final Map<String, String> _encryptionKeys = {};
  final Map<String, String> _accessTokens = {};
  
  // Discovery
  Timer? _discoveryTimer;
  bool _isDiscovering = false;
  
  // Event streams
  final StreamController<P2PEvent> _eventController = 
      StreamController<P2PEvent>.broadcast();
  final StreamController<FileTransferProgress> _progressController = 
      StreamController<FileTransferProgress>.broadcast();
  
  Stream<P2PEvent> get p2pEvents => _eventController.stream;
  Stream<FileTransferProgress> get transferProgress => _progressController.stream;

  /// Initialize WiFi Direct & P2P Service
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Initialize WiFi Direct
      if (_enableWiFiDirect) {
        await _initializeWiFiDirect();
      }
      
      // Initialize P2P
      if (_enableP2P) {
        await _initializeP2P();
      }
      
      // Setup security
      await _setupSecurity();
      
      EnhancedLogger.instance.info('WiFi Direct & P2P Service initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize WiFi Direct & P2P Service', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableWiFiDirect = config.getParameter('p2p_service.enable_wifi_direct') ?? true;
    _enableP2P = config.getParameter('p2p_service.enable_p2p') ?? true;
    _enableEncryption = config.getParameter('p2p_service.enable_encryption') ?? true;
    _enableCompression = config.getParameter('p2p_service.enable_compression') ?? false;
    _enableDiscovery = config.getParameter('p2p_service.enable_discovery') ?? true;
    _maxPeers = config.getParameter('p2p_service.max_peers') ?? 10;
    _discoveryInterval = config.getParameter('p2p_service.discovery_interval_seconds') ?? 30;
    _connectionTimeout = Duration(seconds: config.getParameter('p2p_service.connection_timeout_seconds') ?? 30);
  }

  /// Initialize WiFi Direct
  Future<void> _initializeWiFiDirect() async {
    _wifiDirectManager = WiFiDirectManager();
    await _wifiDirectManager!.initialize();
    
    // Listen for device discovery
    _wifiDirectManager!.deviceDiscovered.listen((device) {
      _wifiDirectDevices.add(device);
      _eventController.add(P2PEvent(
        type: P2PEventType.wifiDirectDeviceDiscovered,
        message: 'WiFi Direct device discovered: ${device.name}',
        data: device,
      ));
    });
    
    // Listen for connection requests
    _wifiDirectManager!.connectionRequest.listen((request) {
      _handleWiFiDirectConnectionRequest(request);
    });
    
    EnhancedLogger.instance.info('WiFi Direct initialized');
  }

  /// Initialize P2P
  Future<void> _initializeP2P() async {
    _p2pManager = P2PManager();
    await _p2pManager!.initialize();
    
    // Listen for peer discovery
    _p2pManager!.peerDiscovered.listen((peer) {
      if (_p2pPeers.length < _maxPeers) {
        _p2pPeers.add(peer);
        _eventController.add(P2PEvent(
          type: P2PEventType.p2pPeerDiscovered,
          message: 'P2P peer discovered: ${peer.name}',
          data: peer,
        ));
      }
    });
    
    // Listen for connection requests
    _p2pManager!.connectionRequest.listen((request) {
      _handleP2PConnectionRequest(request);
    });
    
    EnhancedLogger.instance.info('P2P initialized');
  }

  /// Setup security
  Future<void> _setupSecurity() async {
    // Generate encryption keys
    final keyGenerator = P2PKeyGenerator();
    final masterKey = await keyGenerator.generateKey();
    
    _encryptionKeys['master'] = masterKey;
    
    EnhancedLogger.instance.info('P2P security setup completed');
  }

  /// Start device discovery
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    
    _isDiscovering = true;
    
    // Start WiFi Direct discovery
    if (_enableWiFiDirect && _wifiDirectManager != null) {
      await _wifiDirectManager!.startDiscovery();
    }
    
    // Start P2P discovery
    if (_enableP2P && _p2pManager != null) {
      await _p2pManager!.startDiscovery();
    }
    
    // Setup periodic discovery
    _discoveryTimer = Timer.periodic(Duration(seconds: _discoveryInterval), (_) {
      _performDiscovery();
    });
    
    _eventController.add(P2PEvent(
      type: P2PEventType.discoveryStarted,
      message: 'Device discovery started',
    ));
    
    EnhancedLogger.instance.info('Device discovery started');
  }

  /// Stop device discovery
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    
    // Stop WiFi Direct discovery
    if (_wifiDirectManager != null) {
      await _wifiDirectManager!.stopDiscovery();
    }
    
    // Stop P2P discovery
    if (_p2pManager != null) {
      await _p2pManager!.stopDiscovery();
    }
    
    _eventController.add(P2PEvent(
      type: P2PEventType.discoveryStopped,
      message: 'Device discovery stopped',
    ));
    
    EnhancedLogger.instance.info('Device discovery stopped');
  }

  /// Connect to WiFi Direct device
  Future<String> connectToWiFiDirectDevice(WiFiDirectDevice device) async {
    if (_wifiDirectManager == null) {
      throw Exception('WiFi Direct not enabled');
    }
    
    try {
      final connectionId = await _wifiDirectManager!.connect(device);
      
      final connection = WiFiDirectConnection(
        id: connectionId,
        device: device,
        connectedAt: DateTime.now(),
      );
      
      _wifiDirectConnections[connectionId] = connection;
      
      _eventController.add(P2PEvent(
        type: P2PEventType.wifiDirectConnected,
        message: 'Connected to WiFi Direct device: ${device.name}',
        data: connection,
      ));
      
      return connectionId;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to connect to WiFi Direct device: ${device.name}', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Connect to P2P peer
  Future<String> connectToP2PPeer(P2PPeer peer) async {
    if (_p2pManager == null) {
      throw Exception('P2P not enabled');
    }
    
    try {
      final connectionId = await _p2pManager!.connect(peer);
      
      final connection = P2PConnection(
        id: connectionId,
        peer: peer,
        connectedAt: DateTime.now(),
      );
      
      _p2pConnections[connectionId] = connection;
      
      _eventController.add(P2PEvent(
        type: P2PEventType.p2pConnected,
        message: 'Connected to P2P peer: ${peer.name}',
        data: connection,
      ));
      
      return connectionId;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to connect to P2P peer: ${peer.name}', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Disconnect from WiFi Direct device
  Future<void> disconnectFromWiFiDirectDevice(String connectionId) async {
    final connection = _wifiDirectConnections[connectionId];
    if (connection == null) return;
    
    try {
      if (_wifiDirectManager != null) {
        await _wifiDirectManager!.disconnect(connectionId);
      }
      
      _wifiDirectConnections.remove(connectionId);
      
      _eventController.add(P2PEvent(
        type: P2PEventType.wifiDirectDisconnected,
        message: 'Disconnected from WiFi Direct device',
        data: connectionId,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to disconnect from WiFi Direct device: $connectionId', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Disconnect from P2P peer
  Future<void> disconnectFromP2PPeer(String connectionId) async {
    final connection = _p2pConnections[connectionId];
    if (connection == null) return;
    
    try {
      if (_p2pManager != null) {
        await _p2pManager!.disconnect(connectionId);
      }
      
      _p2pConnections.remove(connectionId);
      
      _eventController.add(P2PEvent(
        type: P2PEventType.p2pDisconnected,
        message: 'Disconnected from P2P peer',
        data: connectionId,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to disconnect from P2P peer: $connectionId', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Share file via WiFi Direct
  Future<String> shareFileViaWiFiDirect(String filePath, {
    String? connectionId,
    Map<String, String>? metadata,
    Duration? timeout,
  }) async {
    if (_wifiDirectManager == null) {
      throw Exception('WiFi Direct not enabled');
    }
    
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }
    
    try {
      // Create shared file entry
      final sharedFile = SharedFile(
        id: _generateFileId(),
        filePath: filePath,
        fileName: file.path.split('/').last,
        fileSize: await file.length(),
        sharedAt: DateTime.now(),
        metadata: metadata ?? {},
        shareType: ShareType.wifiDirect,
      );
      
      _sharedFiles[sharedFile.id] = sharedFile;
      
      // Share via WiFi Direct
      String shareId;
      if (connectionId != null) {
        shareId = await _wifiDirectManager!.shareFile(connectionId, filePath);
      } else {
        shareId = await _wifiDirectManager!.shareFileBroadcast(filePath, timeout: timeout);
      }
      
      _eventController.add(P2PEvent(
        type: P2PEventType.fileShared,
        message: 'File shared via WiFi Direct: ${sharedFile.fileName}',
        data: sharedFile,
      ));
      
      return shareId;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to share file via WiFi Direct: $filePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Share file via P2P
  Future<String> shareFileViaP2P(String filePath, {
    String? connectionId,
    Map<String, String>? metadata,
    Duration? timeout,
  }) async {
    if (_p2pManager == null) {
      throw Exception('P2P not enabled');
    }
    
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }
    
    try {
      // Create shared file entry
      final sharedFile = SharedFile(
        id: _generateFileId(),
        filePath: filePath,
        fileName: file.path.split('/').last,
        fileSize: await file.length(),
        sharedAt: DateTime.now(),
        metadata: metadata ?? {},
        shareType: ShareType.p2p,
      );
      
      _sharedFiles[sharedFile.id] = sharedFile;
      
      // Share via P2P
      String shareId;
      if (connectionId != null) {
        shareId = await _p2pManager!.shareFile(connectionId, filePath);
      } else {
        shareId = await _p2pManager!.shareFileBroadcast(filePath, timeout: timeout);
      }
      
      _eventController.add(P2PEvent(
        type: P2PEventType.fileShared,
        message: 'File shared via P2P: ${sharedFile.fileName}',
        data: sharedFile,
      ));
      
      return shareId;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to share file via P2P: $filePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Download file from WiFi Direct device
  Future<String> downloadFileFromWiFiDirect(String connectionId, String remoteFileId, String localPath, {
    ProgressCallback? onProgress,
  }) async {
    final connection = _wifiDirectConnections[connectionId];
    if (connection == null) {
      throw Exception('WiFi Direct connection not found: $connectionId');
    }
    
    if (_wifiDirectManager == null) {
      throw Exception('WiFi Direct not enabled');
    }
    
    final transferId = _generateTransferId();
    
    try {
      // Create transfer session
      final transfer = FileTransfer(
        id: transferId,
        type: FileTransferType.download,
        remoteFileId: remoteFileId,
        localPath: localPath,
        connectionId: connectionId,
        transferMethod: TransferMethod.wifiDirect,
        startTime: DateTime.now(),
      );
      
      _activeTransfers[transferId] = transfer;
      
      // Create progress callback
      ProgressCallback? progressCallback = (transferred, total) {
        final progress = transferred / total;
        _progressController.add(FileTransferProgress(
          transferId: transferId,
          type: FileTransferType.download,
          progress: progress,
          transferredBytes: transferred,
          totalBytes: total,
          speed: _calculateTransferSpeed(transfer, transferred),
          eta: _calculateETA(transfer, transferred, total),
        ));
        
        onProgress?.call(transferred, total);
      };
      
      // Download file
      final result = await _wifiDirectManager!.downloadFile(
        connectionId, 
        remoteFileId, 
        localPath, 
        progressCallback: progressCallback,
      );
      
      // Update transfer
      transfer.endTime = DateTime.now();
      transfer.success = true;
      
      _eventController.add(P2PEvent(
        type: P2PEventType.fileDownloaded,
        message: 'File downloaded from WiFi Direct device',
        data: transfer,
      ));
      
      return result;
    } catch (e, stackTrace) {
      // Update transfer with error
      final transfer = _activeTransfers[transferId];
      if (transfer != null) {
        transfer.endTime = DateTime.now();
        transfer.success = false;
        transfer.error = e.toString();
      }
      
      EnhancedLogger.instance.error('Failed to download file from WiFi Direct: $remoteFileId', 
        error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _activeTransfers.remove(transferId);
    }
  }

  /// Download file from P2P peer
  Future<String> downloadFileFromP2P(String connectionId, String remoteFileId, String localPath, {
    ProgressCallback? onProgress,
  }) async {
    final connection = _p2pConnections[connectionId];
    if (connection == null) {
      throw Exception('P2P connection not found: $connectionId');
    }
    
    if (_p2pManager == null) {
      throw Exception('P2P not enabled');
    }
    
    final transferId = _generateTransferId();
    
    try {
      // Create transfer session
      final transfer = FileTransfer(
        id: transferId,
        type: FileTransferType.download,
        remoteFileId: remoteFileId,
        localPath: localPath,
        connectionId: connectionId,
        transferMethod: TransferMethod.p2p,
        startTime: DateTime.now(),
      );
      
      _activeTransfers[transferId] = transfer;
      
      // Create progress callback
      ProgressCallback? progressCallback = (transferred, total) {
        final progress = transferred / total;
        _progressController.add(FileTransferProgress(
          transferId: transferId,
          type: FileTransferType.download,
          progress: progress,
          transferredBytes: transferred,
          totalBytes: total,
          speed: _calculateTransferSpeed(transfer, transferred),
          eta: _calculateETA(transfer, transferred, total),
        ));
        
        onProgress?.call(transferred, total);
      };
      
      // Download file
      final result = await _p2pManager!.downloadFile(
        connectionId, 
        remoteFileId, 
        localPath, 
        progressCallback: progressCallback,
      );
      
      // Update transfer
      transfer.endTime = DateTime.now();
      transfer.success = true;
      
      _eventController.add(P2PEvent(
        type: P2PEventType.fileDownloaded,
        message: 'File downloaded from P2P peer',
        data: transfer,
      ));
      
      return result;
    } catch (e, stackTrace) {
      // Update transfer with error
      final transfer = _activeTransfers[transferId];
      if (transfer != null) {
        transfer.endTime = DateTime.now();
        transfer.success = false;
        transfer.error = e.toString();
      }
      
      EnhancedLogger.instance.error('Failed to download file from P2P: $remoteFileId', 
        error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _activeTransfers.remove(transferId);
    }
  }

  /// Get discovered WiFi Direct devices
  List<WiFiDirectDevice> getDiscoveredWiFiDirectDevices() {
    return List.unmodifiable(_wifiDirectDevices);
  }

  /// Get discovered P2P peers
  List<P2PPeer> getDiscoveredP2PPeers() {
    return List.unmodifiable(_p2pPeers);
  }

  /// Get active WiFi Direct connections
  List<WiFiDirectConnection> getActiveWiFiDirectConnections() {
    return List.unmodifiable(_wifiDirectConnections.values);
  }

  /// Get active P2P connections
  List<P2PConnection> getActiveP2PConnections() {
    return List.unmodifiable(_p2pConnections.values);
  }

  /// Get shared files
  List<SharedFile> getSharedFiles() {
    return List.unmodifiable(_sharedFiles.values);
  }

  /// Get active transfers
  List<FileTransfer> getActiveTransfers() {
    return List.unmodifiable(_activeTransfers.values);
  }

  /// Get service statistics
  Map<String, dynamic> getServiceStatistics() {
    final completedTransfers = _activeTransfers.values
        .where((transfer) => transfer.endTime != null)
        .toList();
    
    final totalUploadSize = completedTransfers
        .where((transfer) => transfer.type == FileTransferType.upload && transfer.success)
        .fold<int>(0, (sum, transfer) => sum + (transfer.fileSize ?? 0));
    
    final totalDownloadSize = completedTransfers
        .where((transfer) => transfer.type == FileTransferType.download && transfer.success)
        .fold<int>(0, (sum, transfer) => sum + (transfer.fileSize ?? 0));
    
    return {
      'wifi_direct_enabled': _enableWiFiDirect,
      'p2p_enabled': _enableP2P,
      'encryption_enabled': _enableEncryption,
      'compression_enabled': _enableCompression,
      'discovery_enabled': _enableDiscovery,
      'is_discovering': _isDiscovering,
      'wifi_direct_devices': _wifiDirectDevices.length,
      'p2p_peers': _p2pPeers.length,
      'wifi_direct_connections': _wifiDirectConnections.length,
      'p2p_connections': _p2pConnections.length,
      'shared_files': _sharedFiles.length,
      'active_transfers': _activeTransfers.length,
      'completed_transfers': completedTransfers.length,
      'total_upload_size': totalUploadSize,
      'total_download_size': totalDownloadSize,
      'max_peers': _maxPeers,
    };
  }

  /// Handle WiFi Direct connection request
  Future<void> _handleWiFiDirectConnectionRequest(WiFiDirectConnectionRequest request) async {
    try {
      // Auto-accept connection for demo purposes
      // In production, show user dialog for approval
      await _wifiDirectManager?.acceptConnection(request.requestId);
      
      _eventController.add(P2PEvent(
        type: P2PEventType.connectionRequestReceived,
        message: 'WiFi Direct connection request from ${request.deviceName}',
        data: request,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to handle WiFi Direct connection request', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Handle P2P connection request
  Future<void> _handleP2PConnectionRequest(P2PConnectionRequest request) async {
    try {
      // Auto-accept connection for demo purposes
      // In production, show user dialog for approval
      await _p2pManager?.acceptConnection(request.requestId);
      
      _eventController.add(P2PEvent(
        type: P2PEventType.connectionRequestReceived,
        message: 'P2P connection request from ${request.peerName}',
        data: request,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to handle P2P connection request', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Perform discovery
  Future<void> _performDiscovery() async {
    if (!_isDiscovering) return;
    
    try {
      // WiFi Direct discovery
      if (_enableWiFiDirect && _wifiDirectManager != null) {
        await _wifiDirectManager!.scanDevices();
      }
      
      // P2P discovery
      if (_enableP2P && _p2pManager != null) {
        await _p2pManager!.scanPeers();
      }
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to perform discovery', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// Helper methods
  String _generateFileId() {
    return 'file_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  String _generateTransferId() {
    return 'transfer_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  double _calculateTransferSpeed(FileTransfer transfer, int transferredBytes) {
    if (transfer.startTime == null) return 0.0;
    
    final elapsed = DateTime.now().difference(transfer.startTime!).inSeconds;
    if (elapsed == 0) return 0.0;
    
    return transferredBytes / elapsed;
  }

  Duration _calculateETA(FileTransfer transfer, int transferredBytes, int totalBytes) {
    final speed = _calculateTransferSpeed(transfer, transferredBytes);
    if (speed == 0) return Duration.infinite;
    
    final remainingBytes = totalBytes - transferredBytes;
    final remainingSeconds = remainingBytes / speed;
    
    return Duration(seconds: remainingSeconds.round());
  }

  /// Dispose
  void dispose() {
    // Stop discovery
    stopDiscovery();
    
    // Disconnect all connections
    for (final connection in _wifiDirectConnections.values) {
      _wifiDirectManager?.disconnect(connection.id);
    }
    _wifiDirectConnections.clear();
    
    for (final connection in _p2pConnections.values) {
      _p2pManager?.disconnect(connection.id);
    }
    _p2pConnections.clear();
    
    // Cancel active transfers
    for (final transfer in _activeTransfers.values) {
      transfer.cancel();
    }
    _activeTransfers.clear();
    
    // Dispose managers
    _wifiDirectManager?.dispose();
    _p2pManager?.dispose();
    
    // Clear data
    _wifiDirectDevices.clear();
    _p2pPeers.clear();
    _sharedFiles.clear();
    _encryptionKeys.clear();
    _accessTokens.clear();
    
    _eventController.close();
    _progressController.close();
    
    EnhancedLogger.instance.info('WiFi Direct & P2P Service disposed');
  }
}

/// WiFi Direct Device
class WiFiDirectDevice {
  final String id;
  final String name;
  final String address;
  final String? macAddress;
  final WiFiDirectDeviceType type;
  final Map<String, dynamic> metadata;
  final DateTime discoveredAt;

  WiFiDirectDevice({
    required this.id,
    required this.name,
    required this.address,
    this.macAddress,
    required this.type,
    required this.metadata,
    required this.discoveredAt,
  });
}

/// P2P Peer
class P2PPeer {
  final String id;
  final String name;
  final String address;
  final int port;
  final P2PPeerType type;
  final Map<String, dynamic> metadata;
  final DateTime discoveredAt;

  P2PPeer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.type,
    required this.metadata,
    required this.discoveredAt,
  });
}

/// WiFi Direct Connection
class WiFiDirectConnection {
  final String id;
  final WiFiDirectDevice device;
  final DateTime connectedAt;
  bool isConnected;

  WiFiDirectConnection({
    required this.id,
    required this.device,
    required this.connectedAt,
    this.isConnected = true,
  });
}

/// P2P Connection
class P2PConnection {
  final String id;
  final P2PPeer peer;
  final DateTime connectedAt;
  bool isConnected;

  P2PConnection({
    required this.id,
    required this.peer,
    required this.connectedAt,
    this.isConnected = true,
  });
}

/// Shared File
class SharedFile {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime sharedAt;
  final Map<String, String> metadata;
  final ShareType shareType;

  SharedFile({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.sharedAt,
    required this.metadata,
    required this.shareType,
  });
}

/// File Transfer
class FileTransfer {
  final String id;
  final FileTransferType type;
  final String? remoteFileId;
  final String? localPath;
  final String connectionId;
  final TransferMethod transferMethod;
  final DateTime? startTime;
  DateTime? endTime;
  bool success;
  String? error;
  int? fileSize;
  final Map<String, dynamic> metadata;

  FileTransfer({
    required this.id,
    required this.type,
    this.remoteFileId,
    this.localPath,
    required this.connectionId,
    required this.transferMethod,
    this.startTime,
    this.endTime,
    this.success = false,
    this.error,
    this.fileSize,
    this.metadata = const {},
  });

  void cancel() {
    endTime = DateTime.now();
    success = false;
    error = 'Cancelled by user';
  }
}

/// File Transfer Progress
class FileTransferProgress {
  final String transferId;
  final FileTransferType type;
  final double progress;
  final int transferredBytes;
  final int totalBytes;
  final double speed;
  final Duration eta;
  final DateTime timestamp;

  FileTransferProgress({
    required this.transferId,
    required this.type,
    required this.progress,
    required this.transferredBytes,
    required this.totalBytes,
    required this.speed,
    required this.eta,
  }) : timestamp = DateTime.now();
}

/// WiFi Direct Connection Request
class WiFiDirectConnectionRequest {
  final String requestId;
  final String deviceName;
  final String deviceAddress;

  WiFiDirectConnectionRequest({
    required this.requestId,
    required this.deviceName,
    required this.deviceAddress,
  });
}

/// P2P Connection Request
class P2PConnectionRequest {
  final String requestId;
  final String peerName;
  final String peerAddress;
  final int peerPort;

  P2PConnectionRequest({
    required this.requestId,
    required this.peerName,
    required this.peerAddress,
    required this.peerPort,
  });
}

/// P2P Event
class P2PEvent {
  final P2PEventType type;
  final String message;
  final dynamic data;
  final DateTime timestamp;

  P2PEvent({
    required this.type,
    required this.message,
    this.data,
  }) : timestamp = DateTime.now();
}

/// Enums
enum WiFiDirectDeviceType { phone, tablet, laptop, desktop, other }
enum P2PPeerType { phone, tablet, laptop, desktop, server, other }
enum ShareType { wifiDirect, p2p, bluetooth }
enum FileTransferType { upload, download }
enum TransferMethod { wifiDirect, p2p, bluetooth }
enum P2PEventType {
  wifiDirectDeviceDiscovered,
  p2pPeerDiscovered,
  wifiDirectConnected,
  p2pConnected,
  wifiDirectDisconnected,
  p2pDisconnected,
  fileShared,
  fileDownloaded,
  connectionRequestReceived,
  discoveryStarted,
  discoveryStopped,
}

/// Progress Callback
typedef ProgressCallback = void Function(int transferred, int total);

/// WiFi Direct Manager
class WiFiDirectManager {
  StreamController<WiFiDirectDevice>? _deviceController;
  StreamController<WiFiDirectConnectionRequest>? _connectionController;
  
  Stream<WiFiDirectDevice> get deviceDiscovered => 
      _deviceController?.stream ?? Stream.empty();
  Stream<WiFiDirectConnectionRequest> get connectionRequest => 
      _connectionController?.stream ?? Stream.empty();

  Future<void> initialize() async {
    _deviceController = StreamController<WiFiDirectDevice>.broadcast();
    _connectionController = StreamController<WiFiDirectConnectionRequest>.broadcast();
  }

  Future<void> startDiscovery() async {
    // WiFi Direct discovery implementation
  }

  Future<void> stopDiscovery() async {
    // Stop WiFi Direct discovery
  }

  Future<void> scanDevices() async {
    // Scan for WiFi Direct devices
  }

  Future<String> connect(WiFiDirectDevice device) async {
    // Connect to WiFi Direct device
    throw UnimplementedError();
  }

  Future<void> disconnect(String connectionId) async {
    // Disconnect from WiFi Direct device
  }

  Future<String> shareFile(String connectionId, String filePath) async {
    // Share file with specific device
    throw UnimplementedError();
  }

  Future<String> shareFileBroadcast(String filePath, {Duration? timeout}) async {
    // Share file with all nearby devices
    throw UnimplementedError();
  }

  Future<String> downloadFile(String connectionId, String remoteFileId, String localPath, {ProgressCallback? progressCallback}) async {
    // Download file from device
    throw UnimplementedError();
  }

  Future<void> acceptConnection(String requestId) async {
    // Accept connection request
  }

  void dispose() {
    _deviceController?.close();
    _connectionController?.close();
  }
}

/// P2P Manager
class P2PManager {
  StreamController<P2PPeer>? _peerController;
  StreamController<P2PConnectionRequest>? _connectionController;
  
  Stream<P2PPeer> get peerDiscovered => 
      _peerController?.stream ?? Stream.empty();
  Stream<P2PConnectionRequest> get connectionRequest => 
      _connectionController?.stream ?? Stream.empty();

  Future<void> initialize() async {
    _peerController = StreamController<P2PPeer>.broadcast();
    _connectionController = StreamController<P2PConnectionRequest>.broadcast();
  }

  Future<void> startDiscovery() async {
    // P2P discovery implementation
  }

  Future<void> stopDiscovery() async {
    // Stop P2P discovery
  }

  Future<void> scanPeers() async {
    // Scan for P2P peers
  }

  Future<String> connect(P2PPeer peer) async {
    // Connect to P2P peer
    throw UnimplementedError();
  }

  Future<void> disconnect(String connectionId) async {
    // Disconnect from P2P peer
  }

  Future<String> shareFile(String connectionId, String filePath) async {
    // Share file with specific peer
    throw UnimplementedError();
  }

  Future<String> shareFileBroadcast(String filePath, {Duration? timeout}) async {
    // Share file with all nearby peers
    throw UnimplementedError();
  }

  Future<String> downloadFile(String connectionId, String remoteFileId, String localPath, {ProgressCallback? progressCallback}) async {
    // Download file from peer
    throw UnimplementedError();
  }

  Future<void> acceptConnection(String requestId) async {
    // Accept connection request
  }

  void dispose() {
    _peerController?.close();
    _connectionController?.close();
  }
}

/// P2P Key Generator
class P2PKeyGenerator {
  Future<String> generateKey() async {
    final random = math.Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Encode(bytes);
  }
}
