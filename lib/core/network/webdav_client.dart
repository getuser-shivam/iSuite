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

/// WebDAV Client Service
/// Features: WebDAV protocol support, cloud storage integration, versioning
/// Performance: Optimized transfers, caching, compression, encryption
/// Security: SSL/TLS, OAuth2, secure authentication, access control
/// References: FileGator, Tiny File Manager, cloud storage APIs
class WebDAVClient {
  static WebDAVClient? _instance;
  static WebDAVClient get instance => _instance ??= WebDAVClient._internal();
  WebDAVClient._internal();

  // Configuration
  late final bool _enableSSL;
  late final bool _enableCompression;
  late final bool _enableCaching;
  late final bool _enableVersioning;
  late final bool _enableEncryption;
  late final int _maxConnections;
  late final int _timeoutSeconds;
  late final int _chunkSize;
  
  // Connection management
  final Map<String, WebDAVConnection> _connections = {};
  final Map<String, WebDAVTransfer> _activeTransfers = {};
  final List<WebDAVServer> _savedServers = [];
  
  // Cache
  final Map<String, WebDAVCacheEntry> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Timer? _cacheCleanupTimer;
  
  // Cloud providers
  final Map<CloudProvider, CloudProviderHandler> _cloudProviders = {};
  
  // Security
  final Map<String, String> _encryptionKeys = {};
  final Map<String, OAuthToken> _oauthTokens = {};
  
  // Event streams
  final StreamController<WebDAVEvent> _eventController = 
      StreamController<WebDAVEvent>.broadcast();
  final StreamController<WebDAVTransferProgress> _progressController = 
      StreamController<WebDAVTransferProgress>.broadcast();
  
  Stream<WebDAVEvent> get webdavEvents => _eventController.stream;
  Stream<WebDAVTransferProgress> get transferProgress => _progressController.stream;

  /// Initialize WebDAV Client
  Future<void> initialize() async {
    try {
      // Load configuration
      await _loadConfiguration();
      
      // Initialize cloud providers
      await _initializeCloudProviders();
      
      // Load saved servers
      await _loadSavedServers();
      
      // Setup cache
      _setupCache();
      
      // Setup security
      await _setupSecurity();
      
      EnhancedLogger.instance.info('WebDAV Client initialized');
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to initialize WebDAV Client', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Load configuration
  Future<void> _loadConfiguration() async {
    final config = EnhancedConfigManager.instance;
    
    _enableSSL = config.getParameter('webdav_client.enable_ssl') ?? true;
    _enableCompression = config.getParameter('webdav_client.enable_compression') ?? false;
    _enableCaching = config.getParameter('webdav_client.enable_caching') ?? true;
    _enableVersioning = config.getParameter('webdav_client.enable_versioning') ?? false;
    _enableEncryption = config.getParameter('webdav_client.enable_encryption') ?? false;
    _maxConnections = config.getParameter('webdav_client.max_connections') ?? 5;
    _timeoutSeconds = config.getParameter('webdav_client.timeout_seconds') ?? 30;
    _chunkSize = config.getParameter('webdav_client.chunk_size') ?? 8192;
  }

  /// Initialize cloud providers
  Future<void> _initializeCloudProviders() async {
    // Google Drive
    _cloudProviders[CloudProvider.googleDrive] = GoogleDriveHandler();
    
    // OneDrive
    _cloudProviders[CloudProvider.oneDrive] = OneDriveHandler();
    
    // Dropbox
    _cloudProviders[CloudProvider.dropbox] = DropboxHandler();
    
    // Box
    _cloudProviders[CloudProvider.box] = BoxHandler();
    
    EnhancedLogger.instance.info('Cloud providers initialized: ${_cloudProviders.keys}');
  }

  /// Load saved servers
  Future<void> _loadSavedServers() async {
    try {
      final servers = await _getSavedServersFromStorage();
      _savedServers.addAll(servers);
      
      EnhancedLogger.instance.info('Loaded ${_savedServers.length} saved WebDAV servers');
    } catch (e) {
      EnhancedLogger.instance.warning('Failed to load saved servers: $e');
    }
  }

  /// Setup cache
  void _setupCache() {
    _cacheCleanupTimer = Timer.periodic(Duration(minutes: 10), (_) {
      _cleanupCache();
    });
  }

  /// Setup security
  Future<void> _setupSecurity() async {
    // Generate encryption keys
    final keyGenerator = WebDAVKeyGenerator();
    final masterKey = await keyGenerator.generateKey();
    
    _encryptionKeys['master'] = masterKey;
    
    EnhancedLogger.instance.info('WebDAV security setup completed');
  }

  /// Connect to WebDAV server
  Future<WebDAVConnection> connectToServer(WebDAVServer server, {bool useSSL = false}) async {
    final timer = EnhancedPerformanceManager.instance.startTimer('webdav_connect');
    
    try {
      // Check cache first
      final cacheKey = _generateCacheKey(server);
      final cached = _getCachedConnection(cacheKey);
      if (cached != null && cached.isValid) {
        timer.stop();
        return cached;
      }
      
      // Create new connection
      final connection = WebDAVConnection(
        id: _generateConnectionId(),
        server: server,
        useSSL: useSSL || _enableSSL,
        timeout: Duration(seconds: _timeoutSeconds),
      );
      
      // Connect
      await connection.connect();
      
      // Cache connection
      _cacheConnection(cacheKey, connection);
      
      // Add to connections
      _connections[connection.id] = connection;
      
      timer.stop();
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.connected,
        message: 'Connected to WebDAV server: ${server.host}:${server.port}',
        data: connection,
      ));
      
      return connection;
    } catch (e, stackTrace) {
      timer.stop();
      EnhancedLogger.instance.error('Failed to connect to WebDAV server: ${server.host}', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Connect to cloud provider
  Future<CloudProviderConnection> connectToCloudProvider(CloudProvider provider, Map<String, dynamic> credentials) async {
    final handler = _cloudProviders[provider];
    if (handler == null) {
      throw Exception('Cloud provider not supported: $provider');
    }
    
    try {
      final connection = await handler.connect(credentials);
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.cloudConnected,
        message: 'Connected to cloud provider: $provider',
        data: connection,
      ));
      
      return connection;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to connect to cloud provider: $provider', 
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
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.disconnected,
        message: 'Disconnected from WebDAV server',
        data: connectionId,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to disconnect from WebDAV server: $connectionId', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// List directory contents
  Future<List<WebDAVFile>> listDirectory(String connectionId, String remotePath, {
    bool useCache = true,
  }) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      // Check cache first
      if (useCache && _enableCaching) {
        final cacheKey = _generateListCacheKey(connectionId, remotePath);
        final cached = _getCachedList(cacheKey);
        if (cached != null && !cached.isExpired) {
          return cached.files;
        }
      }
      
      final files = await connection.listDirectory(remotePath);
      
      // Cache result
      if (_enableCaching) {
        final cacheKey = _generateListCacheKey(connectionId, remotePath);
        _cacheList(cacheKey, files);
      }
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.directoryListed,
        message: 'Listed ${files.length} items in $remotePath',
        data: files,
      ));
      
      return files;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to list directory: $remotePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Upload file to WebDAV server
  Future<String> uploadFile(String connectionId, String localPath, String remotePath, {
    ProgressCallback? onProgress,
    bool useCompression = false,
    bool createParentDirectories = false,
    Map<String, String>? metadata,
    bool overwrite = false,
  }) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    final timer = EnhancedPerformanceManager.instance.startTimer('webdav_upload');
    final transferId = _generateTransferId();
    
    try {
      // Create transfer session
      final transfer = WebDAVTransfer(
        id: transferId,
        type: WebDAVTransferType.upload,
        localPath: localPath,
        remotePath: remotePath,
        connectionId: connectionId,
        startTime: DateTime.now(),
        metadata: metadata ?? {},
      );
      
      _activeTransfers[transferId] = transfer;
      
      // Get local file info
      final localFile = File(localPath);
      final fileSize = await localFile.length();
      
      // Create parent directories if needed
      if (createParentDirectories) {
        final parentPath = remotePath.substring(0, remotePath.lastIndexOf('/'));
        if (parentPath.isNotEmpty) {
          await connection.createDirectory(parentPath);
        }
      }
      
      // Create progress callback
      ProgressCallback? progressCallback = (transferred, total) {
        final progress = transferred / total;
        _progressController.add(WebDAVTransferProgress(
          transferId: transferId,
          type: WebDAVTransferType.upload,
          progress: progress,
          transferredBytes: transferred,
          totalBytes: total,
          speed: _calculateTransferSpeed(transfer, transferred),
          eta: _calculateETA(transfer, transferred, total),
        ));
        
        onProgress?.call(transferred, total);
      };
      
      // Perform upload
      String result;
      if (useCompression && _enableCompression && _shouldCompress(localPath)) {
        result = await connection.uploadCompressed(localPath, remotePath, 
          progressCallback: progressCallback, overwrite: overwrite);
      } else {
        result = await connection.uploadFile(localPath, remotePath, 
          progressCallback: progressCallback, overwrite: overwrite);
      }
      
      // Set metadata if provided
      if (metadata != null && metadata.isNotEmpty) {
        await connection.setMetadata(remotePath, metadata);
      }
      
      // Update transfer
      transfer.endTime = DateTime.now();
      transfer.success = true;
      transfer.fileSize = fileSize;
      
      // Invalidate cache
      _invalidateDirectoryCache(connectionId, remotePath);
      
      timer.stop();
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.fileUploaded,
        message: 'Uploaded $localPath to $remotePath',
        data: transfer,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      
      // Update transfer with error
      final transfer = _activeTransfers[transferId];
      if (transfer != null) {
        transfer.endTime = DateTime.now();
        transfer.success = false;
        transfer.error = e.toString();
      }
      
      EnhancedLogger.instance.error('Failed to upload file: $localPath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _activeTransfers.remove(transferId);
    }
  }

  /// Download file from WebDAV server
  Future<String> downloadFile(String connectionId, String remotePath, String localPath, {
    ProgressCallback? onProgress,
    bool resume = false,
    bool verifyIntegrity = false,
  }) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    final timer = EnhancedPerformanceManager.instance.startTimer('webdav_download');
    final transferId = _generateTransferId();
    
    try {
      // Create transfer session
      final transfer = WebDAVTransfer(
        id: transferId,
        type: WebDAVTransferType.download,
        remotePath: remotePath,
        localPath: localPath,
        connectionId: connectionId,
        startTime: DateTime.now(),
        resume: resume,
      );
      
      _activeTransfers[transferId] = transfer;
      
      // Get remote file info
      final remoteFileInfo = await connection.getFileInfo(remotePath);
      
      // Check if local file exists for resume
      int startPosition = 0;
      if (resume) {
        final localFile = File(localPath);
        if (await localFile.exists()) {
          startPosition = await localFile.length();
          transfer.resumedFrom = startPosition;
        }
      }
      
      // Create progress callback
      ProgressCallback? progressCallback = (transferred, total) {
        final progress = (startPosition + transferred) / total;
        _progressController.add(WebDAVTransferProgress(
          transferId: transferId,
          type: WebDAVTransferType.download,
          progress: progress,
          transferredBytes: startPosition + transferred,
          totalBytes: total,
          speed: _calculateTransferSpeed(transfer, startPosition + transferred),
          eta: _calculateETA(transfer, startPosition + transferred, total),
        ));
        
        onProgress?.call(startPosition + transferred, total);
      };
      
      // Perform download
      String result;
      if (resume && startPosition > 0) {
        result = await connection.downloadFileResume(remotePath, localPath, 
          startPosition: startPosition, progressCallback: progressCallback);
      } else {
        result = await connection.downloadFile(remotePath, localPath, 
          progressCallback: progressCallback);
      }
      
      // Verify integrity if requested
      if (verifyIntegrity) {
        final localHash = await _calculateFileHash(File(localPath));
        final remoteHash = await connection.getFileHash(remotePath);
        if (localHash != remoteHash) {
          throw Exception('Integrity check failed: hash mismatch');
        }
      }
      
      // Update transfer
      transfer.endTime = DateTime.now();
      transfer.success = true;
      transfer.fileSize = remoteFileInfo.size;
      
      timer.stop();
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.fileDownloaded,
        message: 'Downloaded $remotePath to $localPath',
        data: transfer,
      ));
      
      return result;
    } catch (e, stackTrace) {
      timer.stop();
      
      // Update transfer with error
      final transfer = _activeTransfers[transferId];
      if (transfer != null) {
        transfer.endTime = DateTime.now();
        transfer.success = false;
        transfer.error = e.toString();
      }
      
      EnhancedLogger.instance.error('Failed to download file: $remotePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _activeTransfers.remove(transferId);
    }
  }

  /// Create directory
  Future<void> createDirectory(String connectionId, String remotePath) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      await connection.createDirectory(remotePath);
      
      // Invalidate cache
      _invalidateDirectoryCache(connectionId, remotePath);
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.directoryCreated,
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
      
      // Invalidate cache
      _invalidateDirectoryCache(connectionId, remotePath);
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.fileDeleted,
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
      
      // Invalidate cache
      _invalidateDirectoryCache(connectionId, oldPath);
      _invalidateDirectoryCache(connectionId, newPath);
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.fileRenamed,
        message: 'Renamed $oldPath to $newPath',
        data: {'oldPath': oldPath, 'newPath': newPath},
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to rename: $oldPath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Copy file or directory
  Future<void> copy(String connectionId, String sourcePath, String destinationPath) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      await connection.copy(sourcePath, destinationPath);
      
      // Invalidate cache
      _invalidateDirectoryCache(connectionId, sourcePath);
      _invalidateDirectoryCache(connectionId, destinationPath);
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.fileCopied,
        message: 'Copied $sourcePath to $destinationPath',
        data: {'sourcePath': sourcePath, 'destinationPath': destinationPath},
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to copy: $sourcePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Move file or directory
  Future<void> move(String connectionId, String sourcePath, String destinationPath) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      await connection.move(sourcePath, destinationPath);
      
      // Invalidate cache
      _invalidateDirectoryCache(connectionId, sourcePath);
      _invalidateDirectoryCache(connectionId, destinationPath);
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.fileMoved,
        message: 'Moved $sourcePath to $destinationPath',
        data: {'sourcePath': sourcePath, 'destinationPath': destinationPath},
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to move: $sourcePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get file info
  Future<WebDAVFileInfo> getFileInfo(String connectionId, String remotePath) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      // Check cache first
      if (_enableCaching) {
        final cacheKey = _generateFileInfoCacheKey(connectionId, remotePath);
        final cached = _getCachedFileInfo(cacheKey);
        if (cached != null && !cached.isExpired) {
          return cached.fileInfo;
        }
      }
      
      final fileInfo = await connection.getFileInfo(remotePath);
      
      // Cache result
      if (_enableCaching) {
        final cacheKey = _generateFileInfoCacheKey(connectionId, remotePath);
        _cacheFileInfo(cacheKey, fileInfo);
      }
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.fileInfoRetrieved,
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

  /// Set metadata
  Future<void> setMetadata(String connectionId, String remotePath, Map<String, String> metadata) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      await connection.setMetadata(remotePath, metadata);
      
      // Invalidate cache
      _invalidateDirectoryCache(connectionId, remotePath);
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.metadataSet,
        message: 'Set metadata for: $remotePath',
        data: metadata,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to set metadata: $remotePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get metadata
  Future<Map<String, String>> getMetadata(String connectionId, String remotePath) async {
    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found: $connectionId');
    }
    
    try {
      // Check cache first
      if (_enableCaching) {
        final cacheKey = _generateMetadataCacheKey(connectionId, remotePath);
        final cached = _getCachedMetadata(cacheKey);
        if (cached != null && !cached.isExpired) {
          return cached.metadata;
        }
      }
      
      final metadata = await connection.getMetadata(remotePath);
      
      // Cache result
      if (_enableCaching) {
        final cacheKey = _generateMetadataCacheKey(connectionId, remotePath);
        _cacheMetadata(cacheKey, metadata);
      }
      
      return metadata;
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to get metadata: $remotePath', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Save server configuration
  Future<void> saveServer(WebDAVServer server) async {
    try {
      // Check if server already exists
      final existingIndex = _savedServers.indexWhere((s) => s.id == server.id);
      if (existingIndex != -1) {
        _savedServers[existingIndex] = server;
      } else {
        _savedServers.add(server);
      }
      
      // Save to storage
      await _saveServersToStorage();
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.serverSaved,
        message: 'Saved WebDAV server: ${server.host}:${server.port}',
        data: server,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to save server: ${server.host}', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete saved server
  Future<void> deleteServer(String serverId) async {
    try {
      _savedServers.removeWhere((server) => server.id == serverId);
      
      // Save to storage
      await _saveServersToStorage();
      
      _eventController.add(WebDAVEvent(
        type: WebDAVEventType.serverDeleted,
        message: 'Deleted WebDAV server: $serverId',
        data: serverId,
      ));
    } catch (e, stackTrace) {
      EnhancedLogger.instance.error('Failed to delete server: $serverId', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get saved servers
  List<WebDAVServer> getSavedServers() {
    return List.unmodifiable(_savedServers);
  }

  /// Test server connection
  Future<bool> testConnection(WebDAVServer server) async {
    try {
      final connection = WebDAVConnection(
        id: _generateConnectionId(),
        server: server,
        useSSL: _enableSSL,
        timeout: Duration(seconds: 10), // Short timeout for testing
      );
      
      await connection.connect();
      await connection.disconnect();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get active connections
  List<WebDAVConnection> getActiveConnections() {
    return List.unmodifiable(_connections.values);
  }

  /// Get active transfers
  List<WebDAVTransfer> getActiveTransfers() {
    return List.unmodifiable(_activeTransfers.values);
  }

  /// Get transfer statistics
  Map<String, dynamic> getTransferStatistics() {
    final completedTransfers = _activeTransfers.values
        .where((transfer) => transfer.endTime != null)
        .toList();
    
    final totalUploadSize = completedTransfers
        .where((transfer) => transfer.type == WebDAVTransferType.upload && transfer.success)
        .fold<int>(0, (sum, transfer) => sum + (transfer.fileSize ?? 0));
    
    final totalDownloadSize = completedTransfers
        .where((transfer) => transfer.type == WebDAVTransferType.download && transfer.success)
        .fold<int>(0, (sum, transfer) => sum + (transfer.fileSize ?? 0));
    
    return {
      'active_connections': _connections.length,
      'active_transfers': _activeTransfers.length,
      'completed_transfers': completedTransfers.length,
      'total_upload_size': totalUploadSize,
      'total_download_size': totalDownloadSize,
      'saved_servers': _savedServers.length,
      'cache_size': _cache.length,
      'ssl_enabled': _enableSSL,
      'compression_enabled': _enableCompression,
      'caching_enabled': _enableCaching,
      'versioning_enabled': _enableVersioning,
      'encryption_enabled': _enableEncryption,
      'cloud_providers': _cloudProviders.keys.map((p) => p.toString()).toList(),
    };
  }

  /// Helper methods
  String _generateConnectionId() {
    return 'webdav_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  String _generateTransferId() {
    return 'transfer_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  String _generateCacheKey(WebDAVServer server) {
    return '${server.host}:${server.port}:${server.username}';
  }

  String _generateListCacheKey(String connectionId, String remotePath) {
    return 'list:$connectionId:$remotePath';
  }

  String _generateFileInfoCacheKey(String connectionId, String remotePath) {
    return 'info:$connectionId:$remotePath';
  }

  String _generateMetadataCacheKey(String connectionId, String remotePath) {
    return 'meta:$connectionId:$remotePath';
  }

  bool _shouldCompress(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    final compressibleExtensions = ['txt', 'log', 'csv', 'json', 'xml', 'html', 'css', 'js', 'md'];
    return compressibleExtensions.contains(extension);
  }

  Future<String> _calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  double _calculateTransferSpeed(WebDAVTransfer transfer, int transferredBytes) {
    if (transfer.startTime == null) return 0.0;
    
    final elapsed = DateTime.now().difference(transfer.startTime!).inSeconds;
    if (elapsed == 0) return 0.0;
    
    return transferredBytes / elapsed;
  }

  Duration _calculateETA(WebDAVTransfer transfer, int transferredBytes, int totalBytes) {
    final speed = _calculateTransferSpeed(transfer, transferredBytes);
    if (speed == 0) return Duration.infinite;
    
    final remainingBytes = totalBytes - transferredBytes;
    final remainingSeconds = remainingBytes / speed;
    
    return Duration(seconds: remainingSeconds.round());
  }

  void _cacheConnection(String cacheKey, WebDAVConnection connection) {
    _cache[cacheKey] = WebDAVCacheEntry(
      key: cacheKey,
      connection: connection,
      timestamp: DateTime.now(),
      ttl: Duration(minutes: 5),
    );
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  WebDAVConnection? _getCachedConnection(String cacheKey) {
    final entry = _cache[cacheKey];
    if (entry != null && !entry.isExpired) {
      return entry.connection;
    }
    return null;
  }

  void _cacheList(String cacheKey, List<WebDAVFile> files) {
    _cache[cacheKey] = WebDAVCacheEntry(
      key: cacheKey,
      files: files,
      timestamp: DateTime.now(),
      ttl: Duration(minutes: 2),
    );
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  CachedList? _getCachedList(String cacheKey) {
    final entry = _cache[cacheKey];
    if (entry != null && !entry.isExpired) {
      return CachedList(files: entry.files, timestamp: entry.timestamp);
    }
    return null;
  }

  void _cacheFileInfo(String cacheKey, WebDAVFileInfo fileInfo) {
    _cache[cacheKey] = WebDAVCacheEntry(
      key: cacheKey,
      fileInfo: fileInfo,
      timestamp: DateTime.now(),
      ttl: Duration(minutes: 5),
    );
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  CachedFileInfo? _getCachedFileInfo(String cacheKey) {
    final entry = _cache[cacheKey];
    if (entry != null && !entry.isExpired) {
      return CachedFileInfo(fileInfo: entry.fileInfo, timestamp: entry.timestamp);
    }
    return null;
  }

  void _cacheMetadata(String cacheKey, Map<String, String> metadata) {
    _cache[cacheKey] = WebDAVCacheEntry(
      key: cacheKey,
      metadata: metadata,
      timestamp: DateTime.now(),
      ttl: Duration(minutes: 3),
    );
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  CachedMetadata? _getCachedMetadata(String cacheKey) {
    final entry = _cache[cacheKey];
    if (entry != null && !entry.isExpired) {
      return CachedMetadata(metadata: entry.metadata, timestamp: entry.timestamp);
    }
    return null;
  }

  void _invalidateDirectoryCache(String connectionId, String remotePath) {
    // Remove all cache entries related to this directory
    final keysToRemove = <String>[];
    
    for (final entry in _cache.entries) {
      if (entry.key.contains(remotePath)) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  void _cleanupCache() {
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (DateTime.now().difference(entry.value).inMinutes > 10) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      EnhancedLogger.instance.info('Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  Future<List<WebDAVServer>> _getSavedServersFromStorage() async {
    // Implementation would load from PocketBase or secure local storage
    return [];
  }

  Future<void> _saveServersToStorage() async {
    // Implementation would save to PocketBase or secure local storage
  }

  /// Dispose
  void dispose() {
    // Disconnect all connections
    for (final connection in _connections.values) {
      connection.disconnect();
    }
    _connections.clear();
    
    // Cancel active transfers
    for (final transfer in _activeTransfers.values) {
      transfer.cancel();
    }
    _activeTransfers.clear();
    
    // Clear cache
    _cache.clear();
    _cacheTimestamps.clear();
    _cacheCleanupTimer?.cancel();
    
    // Clear data
    _savedServers.clear();
    _encryptionKeys.clear();
    _oauthTokens.clear();
    
    _eventController.close();
    _progressController.close();
    
    EnhancedLogger.instance.info('WebDAV Client disposed');
  }
}

/// WebDAV Server configuration
class WebDAVServer {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final String? basePath;
  final bool useSSL;
  final Map<String, dynamic>? metadata;

  WebDAVServer({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    this.basePath,
    this.useSSL = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'base_path': basePath,
      'use_ssl': useSSL,
      'metadata': metadata,
    };
  }

  factory WebDAVServer.fromJson(Map<String, dynamic> json) {
    return WebDAVServer(
      id: json['id'],
      name: json['name'],
      host: json['host'],
      port: json['port'],
      username: json['username'],
      password: json['password'],
      basePath: json['base_path'],
      useSSL: json['use_ssl'] ?? false,
      metadata: json['metadata'],
    );
  }
}

/// WebDAV Connection
class WebDAVConnection {
  final String id;
  final WebDAVServer server;
  final bool useSSL;
  final Duration timeout;
  bool isConnected;

  WebDAVConnection({
    required this.id,
    required this.server,
    required this.useSSL,
    required this.timeout,
    this.isConnected = false,
  });

  Future<void> connect() async {
    // WebDAV connection implementation
    throw UnimplementedError();
  }

  Future<void> disconnect() async {
    // WebDAV disconnection implementation
    throw UnimplementedError();
  }

  Future<List<WebDAVFile>> listDirectory(String remotePath) async {
    // List directory implementation
    throw UnimplementedError();
  }

  Future<String> uploadFile(String localPath, String remotePath, {ProgressCallback? progressCallback, bool overwrite = false}) async {
    // Upload implementation
    throw UnimplementedError();
  }

  Future<String> uploadCompressed(String localPath, String remotePath, {ProgressCallback? progressCallback, bool overwrite = false}) async {
    // Compressed upload implementation
    throw UnimplementedError();
  }

  Future<String> downloadFile(String remotePath, String localPath, {ProgressCallback? progressCallback}) async {
    // Download implementation
    throw UnimplementedError();
  }

  Future<String> downloadFileResume(String remotePath, String localPath, {required int startPosition, ProgressCallback? progressCallback}) async {
    // Resume download implementation
    throw UnimplementedError();
  }

  Future<void> createDirectory(String remotePath) async {
    // Create directory implementation
    throw UnimplementedError();
  }

  Future<void> delete(String remotePath) async {
    // Delete implementation
    throw UnimplementedError();
  }

  Future<void> rename(String oldPath, String newPath) async {
    // Rename implementation
    throw UnimplementedError();
  }

  Future<void> copy(String sourcePath, String destinationPath) async {
    // Copy implementation
    throw UnimplementedError();
  }

  Future<void> move(String sourcePath, String destinationPath) async {
    // Move implementation
    throw UnimplementedError();
  }

  Future<WebDAVFileInfo> getFileInfo(String remotePath) async {
    // Get file info implementation
    throw UnimplementedError();
  }

  Future<String> getFileHash(String remotePath) async {
    // Get file hash implementation
    throw UnimplementedError();
  }

  Future<void> setMetadata(String remotePath, Map<String, String> metadata) async {
    // Set metadata implementation
    throw UnimplementedError();
  }

  Future<Map<String, String>> getMetadata(String remotePath) async {
    // Get metadata implementation
    throw UnimplementedError();
  }

  bool get isValid => true; // Implementation would check connection status
}

/// WebDAV File
class WebDAVFile {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modifiedAt;
  final DateTime? createdAt;
  final String? contentType;
  final String? etag;
  final Map<String, String>? metadata;

  WebDAVFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modifiedAt,
    this.createdAt,
    this.contentType,
    this.etag,
    this.metadata,
  });
}

/// WebDAV File Info
class WebDAVFileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime modifiedAt;
  final DateTime? createdAt;
  final String? contentType;
  final String? etag;
  final Map<String, String>? metadata;

  WebDAVFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.modifiedAt,
    this.createdAt,
    this.contentType,
    this.etag,
    this.metadata,
  });
}

/// WebDAV Transfer
class WebDAVTransfer {
  final String id;
  final WebDAVTransferType type;
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

  WebDAVTransfer({
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
  });

  void cancel() {
    endTime = DateTime.now();
    success = false;
    error = 'Cancelled by user';
  }
}

/// WebDAV Transfer Progress
class WebDAVTransferProgress {
  final String transferId;
  final WebDAVTransferType type;
  final double progress;
  final int transferredBytes;
  final int totalBytes;
  final double speed;
  final Duration eta;
  final DateTime timestamp;

  WebDAVTransferProgress({
    required this.transferId,
    required this.type,
    required this.progress,
    required this.transferredBytes,
    required this.totalBytes,
    required this.speed,
    required this.eta,
  }) : timestamp = DateTime.now();
}

/// WebDAV Event
class WebDAVEvent {
  final WebDAVEventType type;
  final String message;
  final dynamic data;
  final DateTime timestamp;

  WebDAVEvent({
    required this.type,
    required this.message,
    this.data,
  }) : timestamp = DateTime.now();
}

/// WebDAV Cache Entry
class WebDAVCacheEntry {
  final String key;
  final WebDAVConnection? connection;
  final List<WebDAVFile>? files;
  final WebDAVFileInfo? fileInfo;
  final Map<String, String>? metadata;
  final DateTime timestamp;
  final Duration ttl;

  WebDAVCacheEntry({
    required this.key,
    this.connection,
    this.files,
    this.fileInfo,
    this.metadata,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Cached List
class CachedList {
  final List<WebDAVFile> files;
  final DateTime timestamp;

  CachedList({
    required this.files,
    required this.timestamp,
  });
}

/// Cached File Info
class CachedFileInfo {
  final WebDAVFileInfo fileInfo;
  final DateTime timestamp;

  CachedFileInfo({
    required this.fileInfo,
    required this.timestamp,
  });
}

/// Cached Metadata
class CachedMetadata {
  final Map<String, String> metadata;
  final DateTime timestamp;

  CachedMetadata({
    required this.metadata,
    required this.timestamp,
  });
}

/// WebDAV Transfer Type
enum WebDAVTransferType {
  upload,
  download,
}

/// WebDAV Event Type
enum WebDAVEventType {
  connected,
  disconnected,
  directoryListed,
  fileUploaded,
  fileDownloaded,
  directoryCreated,
  fileDeleted,
  fileRenamed,
  fileCopied,
  fileMoved,
  fileInfoRetrieved,
  metadataSet,
  serverSaved,
  serverDeleted,
  cloudConnected,
}

/// Cloud Provider
enum CloudProvider {
  googleDrive,
  oneDrive,
  dropbox,
  box,
}

/// Cloud Provider Handler
abstract class CloudProviderHandler {
  Future<CloudProviderConnection> connect(Map<String, dynamic> credentials);
}

/// Google Drive Handler
class GoogleDriveHandler implements CloudProviderHandler {
  @override
  Future<CloudProviderConnection> connect(Map<String, dynamic> credentials) async {
    // Google Drive connection implementation
    throw UnimplementedError();
  }
}

/// OneDrive Handler
class OneDriveHandler implements CloudProviderHandler {
  @override
  Future<CloudProviderConnection> connect(Map<String, dynamic> credentials) async {
    // OneDrive connection implementation
    throw UnimplementedError();
  }
}

/// Dropbox Handler
class DropboxHandler implements CloudProviderHandler {
  @override
  Future<CloudProviderConnection> connect(Map<String, dynamic> credentials) async {
    // Dropbox connection implementation
    throw UnimplementedError();
  }
}

/// Box Handler
class BoxHandler implements CloudProviderHandler {
  @override
  Future<CloudProviderConnection> connect(Map<String, dynamic> credentials) async {
    // Box connection implementation
    throw UnimplementedError();
  }
}

/// Cloud Provider Connection
class CloudProviderConnection {
  final CloudProvider provider;
  final String connectionId;
  final DateTime connectedAt;
  bool isConnected;

  CloudProviderConnection({
    required this.provider,
    required this.connectionId,
    required this.connectedAt,
    this.isConnected = true,
  });
}

/// OAuth Token
class OAuthToken {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final Map<String, dynamic> metadata;

  OAuthToken({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    this.metadata = const {},
  });
}

/// Progress Callback
typedef ProgressCallback = void Function(int transferred, int total);

/// WebDAV Key Generator
class WebDAVKeyGenerator {
  Future<String> generateKey() async {
    final random = math.Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Encode(bytes);
  }
}
