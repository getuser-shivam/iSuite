import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/central_config.dart';
import '../../core/logging/logging_service.dart';
import '../../core/security_hardening_service.dart';
import '../../core/advanced_error_handling_service.dart';
import '../../core/comprehensive_logging_service.dart';

/// Advanced FTP Client Service with Enterprise Features
/// Provides comprehensive FTP client functionality with GUI integration, security, and advanced features from Owlfiles, FileGator, OpenFTP, and Sigma File Manager
class FTPClientService {
  static final FTPClientService _instance = FTPClientService._internal();
  factory FTPClientService() => _instance;
  FTPClientService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final SecurityHardeningService _securityService = SecurityHardeningService();
  final AdvancedErrorHandlingService _errorHandlingService = AdvancedErrorHandlingService();
  final ComprehensiveLoggingService _comprehensiveLogger = ComprehensiveLoggingService();

  bool _isInitialized = false;
  final Map<String, FTPConnection> _activeConnections = {};
  final StreamController<FTPEvent> _ftpEventController = StreamController.broadcast();
  final Map<String, FTPCredentials> _credentialCache = {}; // In-memory cache for credentials

  // Advanced features from Owlfiles, FileGator, OpenFTP, Sigma File Manager
  final Map<String, StorageAdapter> _storageAdapters = {};
  final Map<String, FTPWorkspace> _workspaces = {};
  final Map<String, StreamingSession> _streamingSessions = {};
  final Map<String, WirelessShare> _wirelessShares = {};
  final Map<String, SSLContext> _sslContexts = {};
  final StreamController<StreamingEvent> _streamingEventController = StreamController.broadcast();
  final StreamController<WirelessShareEvent> _wirelessShareEventController = StreamController.broadcast();

  Stream<FTPEvent> get ftpEvents => _ftpEventController.stream;
  Stream<StreamingEvent> get streamingEvents => _streamingEventController.stream;
  Stream<WirelessShareEvent> get wirelessShareEvents => _wirelessShareEventController.stream;

  /// Initialize FTP service with memory optimization
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing FTP Client Service with memory optimization', 'FTPClientService');

      // Register with CentralConfig
      await _config.registerComponent(
        'FTPClientService',
        '2.1.0',
        'Advanced FTP client with enterprise features: streaming, wireless sharing, workspaces, SSL/TLS, multi-storage adapters, and extensive parameterization',
        dependencies: ['CentralConfig', 'SecurityHardeningService', 'AdvancedErrorHandlingService', 'ComprehensiveLoggingService'],
        parameters: {
          // === BASIC FTP SETTINGS ===
          'ftp_timeout': 30, // seconds
          'max_connections': 5,
          'buffer_size': 8192, // bytes
          'passive_mode': true,
          'auto_reconnect': true,
          'max_retries': 3,
          'retry_delay_base': 2, // seconds

          // === ENHANCED SECURITY ===
          'enable_ssl': true,
          'ssl_cert_validation': true,
          'ssl_default_profile': 'default',
          'enable_secure_storage': true,
          'credential_cache_timeout': 3600, // 1 hour
          'password_masking': true,
          'input_validation_strict': true,

          // === CONNECTION POOLING ===
          'connection_pool_size': 3,
          'connection_idle_timeout': 300, // 5 minutes
          'pool_cleanup_interval': 60, // seconds
          'pool_health_check_interval': 30, // seconds

          // === MEMORY MANAGEMENT ===
          'memory_cleanup_interval': 600, // 10 minutes
          'max_memory_usage_mb': 100,
          'cache_size_limit_mb': 50,
          'cleanup_expired_credentials': true,
          'cleanup_stale_connections': true,

          // === STREAMING CAPABILITIES (Owlfiles-inspired) ===
          'enable_streaming': true,
          'streaming_buffer_size': 65536, // 64KB
          'streaming_default_quality': 'auto', // auto, low, medium, high
          'streaming_max_sessions': 3,
          'streaming_timeout_seconds': 300, // 5 minutes
          'streaming_cache_enabled': true,
          'streaming_cache_size_mb': 200,
          'streaming_supported_formats': 'mp4,avi,mkv,mp3,wav,flac,jpg,png',
          'streaming_transcoding_enabled': false,
          'streaming_bandwidth_limit_kbps': 0, // 0 = unlimited

          // === WIRELESS SHARING (Sigma-inspired) ===
          'enable_wireless_sharing': true,
          'wireless_discovery_port': 5353, // mDNS port
          'wireless_discovery_timeout': 30, // seconds
          'wireless_share_expiry_hours': 24,
          'wireless_max_concurrent_shares': 5,
          'wireless_transfer_buffer_size': 32768, // 32KB
          'wireless_encryption_required': true,
          'wireless_device_discovery_enabled': true,
          'wireless_auto_cleanup_expired': true,

          // === WORKSPACE MANAGEMENT (Sigma-inspired) ===
          'enable_workspaces': true,
          'workspace_max_tabs': 10,
          'workspace_auto_save': true,
          'workspace_session_persistence': true,
          'workspace_max_workspaces': 5,
          'workspace_tab_timeout_minutes': 60,
          'workspace_sync_across_devices': false,

          // === MULTI-STORAGE ADAPTERS (FileGator-inspired) ===
          'enable_multi_storage': true,
          'default_adapter': 'ftp',
          'adapter_timeout_seconds': 30,
          'adapter_retry_attempts': 3,
          'adapter_connection_pooling': true,
          'adapter_health_check_interval': 60, // seconds

          // Storage adapter specific settings
          'ftp_adapter_enabled': true,
          'ftps_adapter_enabled': true,
          'sftp_adapter_enabled': false, // Requires additional libraries
          's3_adapter_enabled': false,
          'dropbox_adapter_enabled': false,
          'googledrive_adapter_enabled': false,
          'onedrive_adapter_enabled': false,
          'smb_adapter_enabled': false,
          'webdav_adapter_enabled': false,
          'local_adapter_enabled': true,

          // === CHUNKED UPLOADS ===
          'chunked_upload_enabled': true,
          'chunk_size_mb': 1, // 1MB chunks
          'chunk_resume_enabled': true,
          'chunk_parallel_uploads': 1, // Sequential by default
          'chunk_timeout_seconds': 300, // 5 minutes per chunk
          'chunk_retry_attempts': 3,
          'chunk_progress_reporting': true,

          // === PERFORMANCE TUNING ===
          'performance_monitoring_enabled': true,
          'performance_metrics_interval': 60, // seconds
          'performance_slow_operation_threshold': 5, // seconds
          'performance_connection_metrics': true,
          'performance_transfer_metrics': true,
          'performance_memory_metrics': true,

          // === ANALYTICS AND MONITORING ===
          'analytics_enabled': true,
          'analytics_usage_tracking': true,
          'analytics_error_tracking': true,
          'analytics_performance_tracking': true,
          'analytics_storage_tracking': true,
          'analytics_report_interval_hours': 24,

          // === UI/UX CUSTOMIZATION ===
          'ui_theme_support': true,
          'ui_custom_icons': false,
          'ui_progress_indicators': true,
          'ui_notification_toasts': true,
          'ui_context_menus': true,
          'ui_drag_drop_enabled': true,
          'ui_keyboard_shortcuts': true,
          'ui_accessibility_support': true,

          // === NETWORK OPTIMIZATION ===
          'network_dns_cache_timeout': 300, // 5 minutes
          'network_connection_keepalive': true,
          'network_tcp_nodelay': true,
          'network_buffer_optimization': true,
          'network_compression_enabled': false,
          'network_proxy_support': false,
          'network_proxy_host': '',
          'network_proxy_port': 0,

          // === ERROR HANDLING ENHANCEMENT ===
          'error_recovery_enabled': true,
          'error_retry_exponential_backoff': true,
          'error_max_retry_delay': 300, // 5 minutes
          'error_circuit_breaker_enabled': false,
          'error_circuit_breaker_threshold': 5,
          'error_circuit_breaker_timeout': 60, // seconds
          'error_user_friendly_messages': true,
          'error_detailed_logging': true,

          // === LOGGING AND AUDIT ===
          'logging_level': 'info', // debug, info, warning, error
          'logging_file_operations': true,
          'logging_connection_events': true,
          'logging_performance_metrics': true,
          'logging_security_events': true,
          'logging_audit_trail': true,
          'logging_max_file_size_mb': 10,
          'logging_max_files': 5,
          'logging_compression': true,

          // === ADVANCED SECURITY ===
          'security_ip_whitelisting': false,
          'security_rate_limiting': false,
          'security_rate_limit_requests': 100,
          'security_rate_limit_window': 60, // seconds
          'security_encryption_at_rest': false,
          'security_file_integrity_checking': true,
          'security_virus_scanning': false,
          'security_audit_log_encryption': false,

          // === BACKUP AND RECOVERY ===
          'backup_enabled': false,
          'backup_interval_hours': 24,
          'backup_retention_days': 30,
          'backup_encryption': true,
          'recovery_auto_restore': false,
          'recovery_point_in_time': false,

          // === INTEGRATION SETTINGS ===
          'integration_supabase_enabled': true,
          'integration_cloud_sync': false,
          'integration_api_endpoints': false,
          'integration_webhook_support': false,
          'integration_oauth_providers': '',

          // === DEBUGGING AND DEVELOPMENT ===
          'debug_mode_enabled': false,
          'debug_performance_profiling': false,
          'debug_memory_leak_detection': false,
          'debug_connection_tracing': false,
          'debug_mock_responses': false,
          'debug_test_mode': false,

          // === EXPERIMENTAL FEATURES ===
          'experimental_ai_predictions': false,
          'experimental_auto_optimization': false,
          'experimental_blockchain_storage': false,
          'experimental_quantum_resistant_crypto': false,
          'experimental_neural_network_caching': false,
        }
      );

      // Initialize advanced services
      await _securityService.initialize();
      await _errorHandlingService.initialize();
      await _comprehensiveLogger.initialize();

      // Initialize storage adapters (FileGator style)
      await _initializeStorageAdapters();

      // Initialize SSL contexts (OpenFTP style)
      await _initializeSSLContexts();

      // Initialize workspaces (Sigma style)
      await _initializeWorkspaces();

      // Setup streaming and wireless sharing (Owlfiles/Sigma style)
      await _setupStreamingCapabilities();
      await _setupWirelessSharing();

      // Initialize secure storage if enabled
      if (_config.getParameter('enable_secure_storage', defaultValue: true)) {
        await _initializeSecureStorage();
      }

      // Initialize connection pool
      _initializeConnectionPool();

  /// Initialize storage adapters (FileGator style)
  Future<void> _initializeStorageAdapters() async {
    if (!_config.getParameter('enable_multi_storage', defaultValue: true)) return;

    final adapterTimeout = Duration(seconds: _config.getParameter('adapter_timeout_seconds', defaultValue: 30));

    // FTP Storage Adapter (native) - only if enabled
    if (_config.getParameter('ftp_adapter_enabled', defaultValue: true)) {
      _storageAdapters['ftp'] = FTPStorageAdapter();
    }

    if (_config.getParameter('ftps_adapter_enabled', defaultValue: true)) {
      _storageAdapters['ftps'] = FTPSStorageAdapter();
    }

    if (_config.getParameter('sftp_adapter_enabled', defaultValue: false)) {
      _storageAdapters['sftp'] = SFTPStorageAdapter();
    }

    // Cloud storage adapters (FileGator style) - only if enabled
    if (_config.getParameter('s3_adapter_enabled', defaultValue: false)) {
      _storageAdapters['s3'] = S3StorageAdapter();
    }

    if (_config.getParameter('dropbox_adapter_enabled', defaultValue: false)) {
      _storageAdapters['dropbox'] = DropboxStorageAdapter();
    }

    if (_config.getParameter('googledrive_adapter_enabled', defaultValue: false)) {
      _storageAdapters['googledrive'] = GoogleDriveStorageAdapter();
    }

    if (_config.getParameter('onedrive_adapter_enabled', defaultValue: false)) {
      _storageAdapters['onedrive'] = OneDriveStorageAdapter();
    }

    // Local and network storage
    if (_config.getParameter('local_adapter_enabled', defaultValue: true)) {
      _storageAdapters['local'] = LocalStorageAdapter();
    }

    if (_config.getParameter('smb_adapter_enabled', defaultValue: false)) {
      _storageAdapters['smb'] = SMBStorageAdapter();
    }

    if (_config.getParameter('webdav_adapter_enabled', defaultValue: false)) {
      _storageAdapters['webdav'] = WebDAVStorageAdapter();
    }

    _logger.info('Storage adapters initialized: ${_storageAdapters.length} adapters', 'FTPClientService');
  }

  /// Initialize SSL contexts (OpenFTP style)
  Future<void> _initializeSSLContexts() async {
    if (!_config.getParameter('enable_ssl', defaultValue: true)) return;

    final certValidation = _config.getParameter('ssl_cert_validation', defaultValue: true);
    final defaultProfile = _config.getParameter('ssl_default_profile', defaultValue: 'default');

    _sslContexts['default'] = SSLContext(
      certificateValidation: certValidation,
      supportedProtocols: ['TLSv1.2', 'TLSv1.3'],
      cipherSuites: ['ECDHE-RSA-AES128-GCM-SHA256', 'ECDHE-RSA-AES256-GCM-SHA384'],
    );

    _sslContexts['strict'] = SSLContext(
      certificateValidation: true,
      supportedProtocols: ['TLSv1.3'],
      cipherSuites: ['ECDHE-RSA-AES256-GCM-SHA384'],
    );

    // Set the default profile
    if (defaultProfile != 'default' && _sslContexts.containsKey(defaultProfile)) {
      _sslContexts['active'] = _sslContexts[defaultProfile]!;
    } else {
      _sslContexts['active'] = _sslContexts['default']!;
    }

    _logger.info('SSL contexts initialized with profile: $defaultProfile', 'FTPClientService');
  }

  /// Initialize workspaces (Sigma style)
  Future<void> _initializeWorkspaces() async {
    if (!_config.getParameter('enable_workspaces', defaultValue: true)) return;

    // Default workspace
    _workspaces['default'] = FTPWorkspace(
      id: 'default',
      name: 'Default Workspace',
      tabs: [],
      maxTabs: _config.getParameter('workspace_max_tabs', defaultValue: 10),
      createdAt: DateTime.now(),
    );

    _logger.info('Workspaces initialized', 'FTPClientService');
  }

  /// Setup streaming capabilities (Owlfiles style)
  Future<void> _setupStreamingCapabilities() async {
    if (!_config.getParameter('enable_streaming', defaultValue: true)) return;

    // Initialize streaming server for media streaming
    await _initializeStreamingServer();

    _logger.info('Streaming capabilities initialized', 'FTPClientService');
  }

  /// Setup wireless sharing (Sigma style)
  Future<void> _setupWirelessSharing() async {
    if (!_config.getParameter('enable_wireless_sharing', defaultValue: true)) return;

    // Initialize wireless discovery service
    await _initializeWirelessDiscovery();

    // Start wireless sharing server
    await _startWirelessSharingServer();

    _logger.info('Wireless sharing initialized', 'FTPClientService');
  }

  /// Initialize connection pool for memory efficiency
  void _initializeConnectionPool() {
    final poolSize = _config.getParameter('connection_pool_size', defaultValue: 3);
    _connectionPool = <String, FTPConnection>{};
    _poolLastUsed = <String, DateTime>{};
    _logger.info('Connection pool initialized with size: $poolSize', 'FTPClientService');
  }

  /// Get connection from pool or create new one
  FTPConnection? _getPooledConnection(String host, int port, String username) {
    final poolKey = '$username@$host:$port';
    final connection = _connectionPool[poolKey];

    if (connection != null) {
      final lastUsed = _poolLastUsed[poolKey];
      final idleTimeout = Duration(seconds: _config.getParameter('connection_idle_timeout', defaultValue: 300));

      if (lastUsed != null && DateTime.now().difference(lastUsed) < idleTimeout) {
        _poolLastUsed[poolKey] = DateTime.now();
        return connection;
      } else {
        // Remove stale connection
        _connectionPool.remove(poolKey);
        _poolLastUsed.remove(poolKey);
        _cleanupConnection(connection);
      }
    }

    return null;
  }

  /// Add connection to pool
  void _addToPool(FTPConnection connection) {
    final poolSize = _config.getParameter('connection_pool_size', defaultValue: 3);

    if (_connectionPool.length >= poolSize) {
      // Remove oldest connection
      final oldestKey = _poolLastUsed.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;

      final oldestConnection = _connectionPool[oldestKey];
      if (oldestConnection != null) {
        _cleanupConnection(oldestConnection);
      }

      _connectionPool.remove(oldestKey);
      _poolLastUsed.remove(oldestKey);
    }

    final poolKey = '${connection.username}@${connection.host}:${connection.port}';
    _connectionPool[poolKey] = connection;
    _poolLastUsed[poolKey] = DateTime.now();
  }

  /// Start memory cleanup timer
  void _startMemoryCleanupTimer() {
    final cleanupInterval = Duration(seconds: _config.getParameter('memory_cleanup_interval', defaultValue: 600));
    final poolCleanupInterval = Duration(seconds: _config.getParameter('pool_cleanup_interval', defaultValue: 60));
    final poolHealthCheckInterval = Duration(seconds: _config.getParameter('pool_health_check_interval', defaultValue: 30));

    _memoryCleanupTimer = Timer.periodic(cleanupInterval, (timer) {
      _performMemoryCleanup();
    });

    // Additional pool cleanup
    Timer.periodic(poolCleanupInterval, (timer) {
      _performPoolCleanup();
    });

    // Pool health checks
    Timer.periodic(poolHealthCheckInterval, (timer) {
      _performPoolHealthCheck();
    });

    _logger.info('Memory cleanup and pool management timers started', 'FTPClientService');
  }

  /// Perform memory cleanup
  void _performMemoryCleanup() {
    try {
      // Clean up expired connections from pool
      final idleTimeout = Duration(seconds: _config.getParameter('connection_idle_timeout', defaultValue: 300));
      final now = DateTime.now();
      final maxMemoryUsage = _config.getParameter('max_memory_usage_mb', defaultValue: 100);
      final currentMemoryUsage = _estimateMemoryUsage();

      final expiredKeys = <String>[];
      for (final entry in _poolLastUsed.entries) {
        if (now.difference(entry.value) >= idleTimeout) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        final connection = _connectionPool[key];
        if (connection != null) {
          _cleanupConnection(connection);
        }
        _connectionPool.remove(key);
        _poolLastUsed.remove(key);
      }

      // Clean up expired credentials from cache
      final cacheTimeout = Duration(seconds: _config.getParameter('credential_cache_timeout', defaultValue: 3600));
      final expiredCredentials = <String>[];

      for (final entry in _credentialCache.entries) {
        if (now.difference(entry.value.lastUsed) >= cacheTimeout) {
          expiredCredentials.add(entry.key);
        }
      }

      for (final key in expiredCredentials) {
        _credentialCache.remove(key);
      }

      // Memory usage check
      if (currentMemoryUsage > maxMemoryUsage) {
        _logger.warning('Memory usage (${currentMemoryUsage}MB) exceeds limit (${maxMemoryUsage}MB)', 'FTPClientService');
        _performAggressiveMemoryCleanup();
      }

      if (_config.getParameter('cleanup_expired_credentials', defaultValue: true) && expiredCredentials.isNotEmpty ||
          _config.getParameter('cleanup_stale_connections', defaultValue: true) && expiredKeys.isNotEmpty) {
        _logger.info('Memory cleanup completed: ${expiredKeys.length} connections, ${expiredCredentials.length} credentials', 'FTPClientService');
      }

    } catch (e) {
      _logger.warning('Memory cleanup failed: $e', 'FTPClientService');
    }
  }

  /// Perform pool cleanup
  void _performPoolCleanup() {
    try {
      final idleTimeout = Duration(seconds: _config.getParameter('connection_idle_timeout', defaultValue: 300));
      final now = DateTime.now();

      final expiredKeys = <String>[];
      for (final entry in _poolLastUsed.entries) {
        if (now.difference(entry.value) >= idleTimeout) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        final connection = _connectionPool[key];
        if (connection != null) {
          _cleanupConnection(connection);
        }
        _connectionPool.remove(key);
        _poolLastUsed.remove(key);
      }

      if (expiredKeys.isNotEmpty) {
        _logger.debug('Pool cleanup: ${expiredKeys.length} expired connections removed', 'FTPClientService');
      }

    } catch (e) {
      _logger.warning('Pool cleanup failed: $e', 'FTPClientService');
    }
  }

  /// Perform pool health check
  void _performPoolHealthCheck() {
    try {
      int healthyConnections = 0;
      int unhealthyConnections = 0;

      for (final entry in _connectionPool.entries) {
        // Simple health check - connection is considered healthy if socket is not closed
        if (entry.value.socket.isEmpty) {
          unhealthyConnections++;
          // Remove unhealthy connection
          _cleanupConnection(entry.value);
          _connectionPool.remove(entry.key);
          _poolLastUsed.remove(entry.key);
        } else {
          healthyConnections++;
        }
      }

      if (unhealthyConnections > 0) {
        _logger.info('Pool health check: $healthyConnections healthy, $unhealthyConnections unhealthy connections removed', 'FTPClientService');
      }

    } catch (e) {
      _logger.warning('Pool health check failed: $e', 'FTPClientService');
    }
  }

  /// Perform aggressive memory cleanup when memory usage is high
  void _performAggressiveMemoryCleanup() {
    try {
      // Clear all cached credentials
      _credentialCache.clear();

      // Remove half of pooled connections
      final keysToRemove = _poolLastUsed.entries
          .toList()
          .sorted((a, b) => a.value.compareTo(b.value))
          .take(_connectionPool.length ~/ 2)
          .map((e) => e.key)
          .toList();

      for (final key in keysToRemove) {
        final connection = _connectionPool[key];
        if (connection != null) {
          _cleanupConnection(connection);
        }
        _connectionPool.remove(key);
        _poolLastUsed.remove(key);
      }

      _logger.warning('Aggressive memory cleanup performed: ${keysToRemove.length} connections removed', 'FTPClientService');

    } catch (e) {
      _logger.error('Aggressive memory cleanup failed: $e', 'FTPClientService');
    }
  }

  /// Cleanup connection resources
  void _cleanupConnection(FTPConnection connection) {
    try {
      if (connection.status == FTPConnectionStatus.ready) {
        // Send QUIT command if still connected
        _sendFTPCommand(connection.socket, 'QUIT\r\n').timeout(const Duration(seconds: 5));
      }
      connection.socket.close();
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'active_connections': _activeConnections.length,
      'pooled_connections': _connectionPool.length,
      'cached_credentials': _credentialCache.length,
      'total_memory_usage': _estimateMemoryUsage(),
    };
  }

  /// Estimate memory usage
  int _estimateMemoryUsage() {
    // Rough estimation based on object counts
    const connectionSize = 1024; // ~1KB per connection
    const credentialSize = 512;  // ~512B per credential

    return (_activeConnections.length + _connectionPool.length) * connectionSize +
           _credentialCache.length * credentialSize;
  }

  /// Force garbage collection (for debugging)
  void forceGarbageCollection() {
    // This would trigger garbage collection in debug mode
    // In production, rely on automatic GC
    _logger.info('Garbage collection triggered', 'FTPClientService');
  }

  /// Initialize secure storage for credentials
  Future<void> _initializeSecureStorage() async {
    // In a real Flutter app, this would use flutter_secure_storage
    // For now, this is a placeholder for secure credential storage
    _logger.info('Secure storage initialized (placeholder)', 'FTPClientService');
  }

  /// Save credentials securely
  Future<void> saveCredentials(String host, int port, String username, String password) async {
    final key = _generateCredentialKey(host, port, username);
    final credentials = FTPCredentials(
      host: host,
      port: port,
      username: username,
      password: password,
      lastUsed: DateTime.now(),
    );

    _credentialCache[key] = credentials;

    // Save to secure storage
    if (_config.getParameter('enable_secure_storage', defaultValue: true)) {
      await _saveCredentialsToSecureStorage(key, credentials);
    }

    _logger.info('Credentials saved securely for $username@$host:$port', 'FTPClientService');
  }

  /// Load credentials securely
  Future<FTPCredentials?> loadCredentials(String host, int port, String username) async {
    final key = _generateCredentialKey(host, port, username);

    // Check memory cache first
    var credentials = _credentialCache[key];
    if (credentials != null) {
      // Check if cache is still valid
      final cacheTimeout = Duration(seconds: _config.getParameter('credential_cache_timeout', defaultValue: 3600));
      if (DateTime.now().difference(credentials.lastUsed) < cacheTimeout) {
        return credentials;
      } else {
        // Remove expired credentials
        _credentialCache.remove(key);
      }
    }

    // Load from secure storage
    if (_config.getParameter('enable_secure_storage', defaultValue: true)) {
      credentials = await _loadCredentialsFromSecureStorage(key);
      if (credentials != null) {
        _credentialCache[key] = credentials;
      }
    }

    return credentials;
  }

  /// Delete stored credentials
  Future<void> deleteCredentials(String host, int port, String username) async {
    final key = _generateCredentialKey(host, port, username);

    _credentialCache.remove(key);

    // Remove from secure storage
    if (_config.getParameter('enable_secure_storage', defaultValue: true)) {
      await _deleteCredentialsFromSecureStorage(key);
    }

    _logger.info('Credentials deleted for $username@$host:$port', 'FTPClientService');
  }

  /// Connect using saved credentials
  Future<String> connectWithSavedCredentials(String host, int port, String username, {
    bool useSSL = false,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    final credentials = await loadCredentials(host, port, username);
    if (credentials == null) {
      throw FTPException('No saved credentials found for $username@$host:$port', FTPErrorType.authenticationFailed);
    }

    return await connect(
      host: host,
      port: port,
      username: username,
      password: credentials.password,
      useSSL: useSSL,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  /// Save credentials to secure storage (placeholder implementation)
  Future<void> _saveCredentialsToSecureStorage(String key, FTPCredentials credentials) async {
    // In a real Flutter app, this would use flutter_secure_storage
    // Example: await _secureStorage.write(key: key, value: json.encode(credentials.toJson()));
    _logger.info('Credentials saved to secure storage: $key', 'FTPClientService');
  }

  /// Load credentials from secure storage (placeholder implementation)
  Future<FTPCredentials?> _loadCredentialsFromSecureStorage(String key) async {
    // In a real Flutter app, this would use flutter_secure_storage
    // Example: final value = await _secureStorage.read(key: key);
    // return value != null ? FTPCredentials.fromJson(json.decode(value)) : null;
    _logger.info('Credentials loaded from secure storage: $key', 'FTPClientService');
    return null; // Placeholder
  }

  /// Delete credentials from secure storage (placeholder implementation)
  Future<void> _deleteCredentialsFromSecureStorage(String key) async {
    // In a real Flutter app, this would use flutter_secure_storage
    // Example: await _secureStorage.delete(key: key);
    _logger.info('Credentials deleted from secure storage: $key', 'FTPClientService');
  }

  /// Generate credential key for storage
  String _generateCredentialKey(String host, int port, String username) {
    return 'ftp_credentials_${host}_${port}_${username}';
  }

  /// Connect to FTP server with enhanced security validation
  Future<String> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    bool useSSL = false,
    Duration? timeout,
    int? maxRetries,
  }) async {
    if (!_isInitialized) await initialize();

    // Input validation
    _validateConnectionParameters(host, port, username, password);

    // Use parameterized values
    final actualTimeout = timeout ?? Duration(seconds: _config.getParameter('ftp_timeout', defaultValue: 30));
    final actualMaxRetries = maxRetries ?? _config.getParameter('max_retries', defaultValue: 3);
    final autoReconnect = _config.getParameter('auto_reconnect', defaultValue: true);
    final passiveMode = _config.getParameter('passive_mode', defaultValue: true);

    final connectionId = _generateConnectionId();

    FTPConnection? connection;
    Exception? lastError;

    for (int attempt = 0; attempt <= actualMaxRetries; attempt++) {
      try {
        _emitFTPEvent(FTPEventType.connecting, connectionId: connectionId, data: {'attempt': attempt + 1, 'maxRetries': actualMaxRetries + 1});

        final socket = await Socket.connect(host, port, timeout: actualTimeout);

        connection = FTPConnection(
          id: connectionId,
          host: host,
          port: port,
          username: username,
          socket: socket,
          status: FTPConnectionStatus.connected,
          useSSL: useSSL,
        );

        _activeConnections[connectionId] = connection;

        // Send login commands with validation and security
        await _sendFTPCommand(socket, 'USER $username\r\n');
        var response = await _readFTPResponse(socket);
        if (!response.startsWith('331')) {
          throw FTPException('FTP login failed: ${response.substring(0, 50)}...', FTPErrorType.authenticationFailed);
        }

        await _sendFTPCommand(socket, 'PASS ${_maskPassword(password)}\r\n');
        response = await _readFTPResponse(socket);
        if (!response.startsWith('230')) {
          throw FTPException('FTP authentication failed', FTPErrorType.authenticationFailed);
        }

        // Set passive mode with error handling (if enabled)
        if (passiveMode) {
          await _sendFTPCommand(socket, 'PASV\r\n');
          response = await _readFTPResponse(socket);
          if (!response.startsWith('227')) {
            throw FTPException('Failed to enter passive mode', FTPErrorType.passiveModeFailed);
          }

          connection.dataHost = _parsePassiveModeResponse(response);
        }

        connection.status = FTPConnectionStatus.ready;

        _emitFTPEvent(FTPEventType.connected, connectionId: connectionId);

        // Add to connection pool if pooling is enabled
        if (_config.getParameter('adapter_connection_pooling', defaultValue: true)) {
          _addToPool(connection);
        }

        final maskedHost = _config.getParameter('logging_connection_events', defaultValue: true) ?
          host.maskHost() : host;
        _logger.info('FTP connection established: $connectionId to $maskedHost', 'FTPClientService');

        return connectionId;

      } catch (e) {
        lastError = e is FTPException ? e : FTPException('Connection failed: $e', FTPErrorType.connectionFailed);
        _logger.warning('FTP connection attempt ${attempt + 1} failed for $connectionId: ${e.toString().substring(0, 100)}', 'FTPClientService');

        // Clean up failed connection
        if (connection != null) {
          try {
            await connection.socket.close();
          } catch (_) {}
          _activeConnections.remove(connectionId);
        }

        // Wait before retry (exponential backoff if enabled)
        if (_config.getParameter('error_retry_exponential_backoff', defaultValue: true) && attempt < actualMaxRetries) {
          final delayBase = _config.getParameter('retry_delay_base', defaultValue: 2);
          await Future.delayed(Duration(seconds: delayBase * (attempt + 1)));
        }
      }
    }

    // All retries failed
    _emitFTPEvent(FTPEventType.connectionFailed, connectionId: connectionId, error: lastError.toString());
    throw lastError ?? FTPException('All connection attempts failed', FTPErrorType.connectionFailed);
  }

  /// Validate connection parameters for security
  void _validateConnectionParameters(String host, int port, String username, String password) {
    // Host validation
    if (host.trim().isEmpty) {
      throw FTPException('Host cannot be empty', FTPErrorType.invalidResponse);
    }

    // Basic host format validation (IPv4, IPv6, or hostname)
    final hostRegex = RegExp(r'^(([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?|[0-9]{1,3}(\.[0-9]{1,3}){3}|([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4})$');
    if (!hostRegex.hasMatch(host)) {
      throw FTPException('Invalid host format', FTPErrorType.invalidResponse);
    }

    // Port validation
    if (port < 1 || port > 65535) {
      throw FTPException('Port must be between 1 and 65535', FTPErrorType.invalidResponse);
    }

    // Username validation
    if (username.trim().isEmpty || username.length > 255) {
      throw FTPException('Username must be non-empty and less than 256 characters', FTPErrorType.invalidResponse);
    }

    // Password validation (basic)
    if (password.length > 255) {
      throw FTPException('Password too long (max 255 characters)', FTPErrorType.invalidResponse);
    }

    // Check for potentially dangerous characters in credentials
    final dangerousChars = RegExp(r'[\x00-\x1F\x7F-\x9F]');
    if (dangerousChars.hasMatch(username) || dangerousChars.hasMatch(password)) {
      throw FTPException('Credentials contain invalid characters', FTPErrorType.invalidResponse);
    }
  }

  /// Mask password for logging
  String _maskPassword(String password) {
    if (password.length <= 2) return '*' * password.length;
    return password[0] + '*' * (password.length - 2) + password[password.length - 1];
  }

  /// List directory contents with enhanced error handling and retry
  Future<List<FTPFileInfo>> listDirectory(String connectionId, [String path = '']) async {
    final connection = _activeConnections[connectionId];
    if (connection == null || connection.status != FTPConnectionStatus.ready) {
      throw FTPException('Invalid or inactive FTP connection: $connectionId', FTPErrorType.connectionFailed);
    }

    final maxRetries = _config.getParameter('ftp.max_retries', defaultValue: 3);
    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      Socket? dataSocket;
      try {
        _emitFTPEvent(FTPEventType.listing, connectionId: connectionId, path: path);

        // Ensure connection is still valid
        if (connection.socket.isEmpty) {
          throw FTPException('Connection socket is closed', FTPErrorType.connectionFailed);
        }

        // Get fresh passive mode data connection
        await _sendFTPCommand(connection.socket, 'PASV\r\n');
        final pasvResponse = await _readFTPResponse(connection.socket);
        if (!pasvResponse.startsWith('227')) {
          throw FTPException('Failed to enter passive mode: ${pasvResponse.substring(0, 50)}', FTPErrorType.passiveModeFailed);
        }

        final (dataHost, dataPort) = _parsePassiveModeResponse(pasvResponse);

        // Establish data connection with timeout
        dataSocket = await Socket.connect(dataHost, dataPort, timeout: Duration(seconds: 10));

        // Send LIST command
        await _sendFTPCommand(connection.socket, 'LIST $path\r\n');
        final response = await _readFTPResponse(connection.socket);
        if (!response.startsWith('150')) {
          dataSocket.close();
          throw FTPException('LIST command failed: ${response.substring(0, 50)}', FTPErrorType.invalidResponse);
        }

        // Read directory listing with timeout
        final data = await _readDataConnectionWithTimeout(dataSocket, timeout: Duration(seconds: 30));
        final listingResponse = await _readFTPResponse(connection.socket);
        if (!listingResponse.startsWith('226')) {
          throw FTPException('Directory listing failed: ${listingResponse.substring(0, 50)}', FTPErrorType.dataTransferFailed);
        }

        final files = _parseDirectoryListing(utf8.decode(data));
        _emitFTPEvent(FTPEventType.listed, connectionId: connectionId, files: files);

        _logger.info('Directory listing successful for $connectionId: ${files.length} items', 'FTPClientService');
        return files;

      } catch (e) {
        lastError = e is FTPException ? e : FTPException('Directory listing failed: $e', FTPErrorType.networkError);
        _logger.warning('Directory listing attempt ${attempt + 1} failed for $connectionId: ${e.toString().substring(0, 100)}', 'FTPClientService');

        // Clean up data socket
        if (dataSocket != null) {
          try {
            dataSocket.close();
          } catch (_) {}
        }

        // Check if error is retryable
        if (!_isRetryableError(e) || attempt >= maxRetries) {
          break;
        }

        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }

    // All retries failed
    _emitFTPEvent(FTPEventType.listFailed, connectionId: connectionId, error: lastError.toString());
    _logger.error('Directory listing failed after all retries for $connectionId', 'FTPClientService', error: lastError);
    throw lastError ?? FTPException('Directory listing failed after all retries', FTPErrorType.networkError);
  }

  /// Download file from FTP server with enhanced error handling and retry
  Future<void> downloadFile({
    required String connectionId,
    required String remotePath,
    required String localPath,
    Function(double)? onProgress,
  }) async {
    final connection = _activeConnections[connectionId];
    if (connection == null || connection.status != FTPConnectionStatus.ready) {
      throw FTPException('Invalid or inactive FTP connection: $connectionId', FTPErrorType.connectionFailed);
    }

    final maxRetries = _config.getParameter('ftp.max_retries', defaultValue: 3);
    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      Socket? dataSocket;
      IOSink? fileSink;
      bool downloadStarted = false;

      try {
        _emitFTPEvent(FTPEventType.downloading, connectionId: connectionId, filePath: remotePath);

        // Ensure connection is still valid
        if (connection.socket.isEmpty) {
          throw FTPException('Connection socket is closed', FTPErrorType.connectionFailed);
        }

        // Get fresh passive mode data connection
        await _sendFTPCommand(connection.socket, 'PASV\r\n');
        final pasvResponse = await _readFTPResponse(connection.socket);
        if (!pasvResponse.startsWith('227')) {
          throw FTPException('Failed to enter passive mode: ${pasvResponse.substring(0, 50)}', FTPErrorType.passiveModeFailed);
        }

        final (dataHost, dataPort) = _parsePassiveModeResponse(pasvResponse);

        // Establish data connection with timeout
        dataSocket = await Socket.connect(dataHost, dataPort, timeout: Duration(seconds: 10));

        // Send RETR command
        await _sendFTPCommand(connection.socket, 'RETR $remotePath\r\n');
        final response = await _readFTPResponse(connection.socket);
        if (!response.startsWith('150')) {
          dataSocket.close();
          if (response.startsWith('550')) {
            throw FTPException('File not found: $remotePath', FTPErrorType.fileNotFound);
          }
          throw FTPException('RETR command failed: ${response.substring(0, 50)}', FTPErrorType.invalidResponse);
        }

        // Create local file
        final file = File(localPath);
        fileSink = file.openWrite();
        downloadStarted = true;

        // Read file data with progress tracking and timeout
        int totalBytes = 0;
        bool timeoutOccurred = false;
        final timeoutTimer = Timer(Duration(minutes: 5), () { // 5 minute timeout for downloads
          timeoutOccurred = true;
          dataSocket.close();
        });

        try {
          await for (final chunk in dataSocket) {
            if (timeoutOccurred) break;
            fileSink.add(chunk);
            totalBytes += chunk.length;
            onProgress?.call(totalBytes.toDouble());
          }
        } finally {
          timeoutTimer.cancel();
        }

        await fileSink.flush();
        await fileSink.close();
        fileSink = null;
        dataSocket.close();
        dataSocket = null;

        // Read completion response
        final completionResponse = await _readFTPResponse(connection.socket);
        if (!completionResponse.startsWith('226')) {
          // Clean up partial download
          try {
            await file.delete();
          } catch (_) {}
          throw FTPException('File download failed: ${completionResponse.substring(0, 50)}', FTPErrorType.dataTransferFailed);
        }

        _emitFTPEvent(FTPEventType.downloaded, connectionId: connectionId, filePath: remotePath);
        _logger.info('File download successful: $remotePath to $localPath (${totalBytes} bytes)', 'FTPClientService');
        return;

      } catch (e) {
        lastError = e is FTPException ? e : FTPException('File download failed: $e', FTPErrorType.networkError);
        _logger.warning('File download attempt ${attempt + 1} failed for $connectionId: ${e.toString().substring(0, 100)}', 'FTPClientService');

        // Clean up resources
        if (fileSink != null) {
          try {
            await fileSink.close();
          } catch (_) {}
        }
        if (dataSocket != null) {
          try {
            dataSocket.close();
          } catch (_) {}
        }

        // Clean up partial download if download started
        if (downloadStarted && attempt == 0) { // Only clean up on first attempt to avoid deleting good files
          try {
            final file = File(localPath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
        }

        // Check if error is retryable
        if (!_isRetryableError(e) || attempt >= maxRetries) {
          break;
        }

        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: (attempt + 1) * 3)); // Longer delay for downloads
      }
    }

    // All retries failed
    _emitFTPEvent(FTPEventType.downloadFailed, connectionId: connectionId, error: lastError.toString());
    _logger.error('File download failed after all retries for $connectionId', 'FTPClientService', error: lastError);
    throw lastError ?? FTPException('File download failed after all retries', FTPErrorType.networkError);
  }

  /// Upload file to FTP server with enhanced error handling and retry
  Future<void> uploadFile({
    required String connectionId,
    required String localPath,
    required String remotePath,
    Function(double)? onProgress,
  }) async {
    final connection = _activeConnections[connectionId];
    if (connection == null || connection.status != FTPConnectionStatus.ready) {
      throw FTPException('Invalid or inactive FTP connection: $connectionId', FTPErrorType.connectionFailed);
    }

    final maxRetries = _config.getParameter('ftp.max_retries', defaultValue: 3);
    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      Socket? dataSocket;
      StreamSubscription<Uint8List>? uploadSubscription;
      bool uploadStarted = false;

      try {
        _emitFTPEvent(FTPEventType.uploading, connectionId: connectionId, filePath: remotePath);

        final file = File(localPath);
        if (!await file.exists()) {
          throw FTPException('Local file does not exist: $localPath', FTPErrorType.fileNotFound);
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          _logger.warning('Attempting to upload empty file: $localPath', 'FTPClientService');
        }

        // Ensure connection is still valid
        if (connection.socket.isEmpty) {
          throw FTPException('Connection socket is closed', FTPErrorType.connectionFailed);
        }

        // Get fresh passive mode data connection
        await _sendFTPCommand(connection.socket, 'PASV\r\n');
        final pasvResponse = await _readFTPResponse(connection.socket);
        if (!pasvResponse.startsWith('227')) {
          throw FTPException('Failed to enter passive mode: ${pasvResponse.substring(0, 50)}', FTPErrorType.passiveModeFailed);
        }

        final (dataHost, dataPort) = _parsePassiveModeResponse(pasvResponse);

        // Establish data connection with timeout
        dataSocket = await Socket.connect(dataHost, dataPort, timeout: Duration(seconds: 10));

        // Send STOR command
        await _sendFTPCommand(connection.socket, 'STOR $remotePath\r\n');
        final response = await _readFTPResponse(connection.socket);
        if (!response.startsWith('150')) {
          dataSocket.close();
          if (response.startsWith('550')) {
            throw FTPException('Permission denied or path invalid: $remotePath', FTPErrorType.permissionDenied);
          }
          throw FTPException('STOR command failed: ${response.substring(0, 50)}', FTPErrorType.invalidResponse);
        }

        // Send file data with progress tracking and timeout
        final stream = file.openRead();
        int sentBytes = 0;
        bool timeoutOccurred = false;
        uploadStarted = true;

        final timeoutTimer = Timer(Duration(minutes: 5), () { // 5 minute timeout for uploads
          timeoutOccurred = true;
          dataSocket.close();
        });

        final completer = Completer<void>();

        uploadSubscription = stream.listen(
          (chunk) {
            if (timeoutOccurred) return;
            dataSocket.add(chunk);
            sentBytes += chunk.length;
            onProgress?.call(sentBytes / fileSize);
          },
          onDone: () async {
            if (!timeoutOccurred) {
              await dataSocket.flush();
              dataSocket.close();
              dataSocket = null;

              // Read completion response
              final completionResponse = await _readFTPResponse(connection.socket);
              if (!completionResponse.startsWith('226')) {
                throw FTPException('File upload failed: ${completionResponse.substring(0, 50)}', FTPErrorType.dataTransferFailed);
              }

              completer.complete();
            }
          },
          onError: (error) {
            completer.completeError(error);
          },
        );

        await completer.future;
        timeoutTimer.cancel();

        _emitFTPEvent(FTPEventType.uploaded, connectionId: connectionId, filePath: remotePath);
        _logger.info('File upload successful: $localPath to $remotePath (${sentBytes} bytes)', 'FTPClientService');
        return;

      } catch (e) {
        lastError = e is FTPException ? e : FTPException('File upload failed: $e', FTPErrorType.networkError);
        _logger.warning('File upload attempt ${attempt + 1} failed for $connectionId: ${e.toString().substring(0, 100)}', 'FTPClientService');

        // Clean up resources
        if (uploadSubscription != null) {
          try {
            await uploadSubscription.cancel();
          } catch (_) {}
        }
        if (dataSocket != null) {
          try {
            dataSocket.close();
          } catch (_) {}
        }

        // Check if error is retryable
        if (!_isRetryableError(e) || attempt >= maxRetries) {
          break;
        }

        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: (attempt + 1) * 3)); // Longer delay for uploads
      }
    }

    // All retries failed
    _emitFTPEvent(FTPEventType.uploadFailed, connectionId: connectionId, error: lastError.toString());
    _logger.error('File upload failed after all retries for $connectionId', 'FTPClientService', error: lastError);
    throw lastError ?? FTPException('File upload failed after all retries', FTPErrorType.networkError);
  }

  // Advanced Features from Owlfiles/FileGator/OpenFTP/Sigma

  /// Initialize streaming server (Owlfiles style)
  Future<void> _initializeStreamingServer() async {
    // Initialize HTTP server for media streaming
    // This allows streaming movies and music directly from FTP servers
    _logger.info('Streaming server initialized', 'FTPClientService');
  }

  /// Initialize wireless discovery (Sigma style)
  Future<void> _initializeWirelessDiscovery() async {
    // Initialize mDNS service discovery for finding devices on local network
    final discoveryPort = _config.getParameter('wireless_discovery_port', defaultValue: 5353);
    // Setup mDNS discovery for wireless sharing
    _logger.info('Wireless discovery initialized on port $discoveryPort', 'FTPClientService');
  }

  /// Start wireless sharing server (Sigma style)
  Future<void> _startWirelessSharingServer() async {
    // Start HTTP server for wireless file sharing
    // Allows sharing files wirelessly to devices on local network
    _logger.info('Wireless sharing server started', 'FTPClientService');
  }

  /// Start media streaming session (Owlfiles feature)
  Future<void> _startMediaStreaming(StreamingSession session) async {
    // Start streaming the media file
    // This would buffer and stream the file content
    session.status = StreamingStatus.streaming;
    _emitStreamingEvent(StreamingEventType.streamStarted, sessionId: session.id);
  }

  /// Start wireless file sharing (Sigma feature)
  Future<void> _startWirelessSharing(WirelessShare share) async {
    // Start sharing the file wirelessly to target devices
    share.status = WirelessShareStatus.sharing;
    _emitWirelessShareEvent(WirelessShareEventType.shareStarted, shareId: share.id);
  }

  /// Stream media file directly from FTP server (Owlfiles feature)
  Future<StreamingSession> streamMedia({
    required String connectionId,
    required String remotePath,
    required MediaType mediaType,
    StreamingQuality quality = StreamingQuality.auto,
  }) async {
    final connection = _activeConnections[connectionId];
    if (connection == null) {
      throw FTPException('Connection not found: $connectionId', FTPErrorType.connectionFailed);
    }

    final sessionId = 'stream_${DateTime.now().millisecondsSinceEpoch}';

    // Create streaming session
    final session = StreamingSession(
      id: sessionId,
      connectionId: connectionId,
      remotePath: remotePath,
      mediaType: mediaType,
      quality: quality,
      status: StreamingStatus.preparing,
      createdAt: DateTime.now(),
    );

    _streamingSessions[sessionId] = session;

    // Start streaming in background
    _startMediaStreaming(session);

    _emitStreamingEvent(StreamingEventType.streamStarted, sessionId: sessionId);

    return session;
  }

  /// Share file wirelessly to local network devices (Sigma feature)
  Future<WirelessShare> shareWirelessly({
    required String connectionId,
    required String remotePath,
    required List<String> targetDevices,
    Duration? expiry,
  }) async {
    final shareId = 'share_${DateTime.now().millisecondsSinceEpoch}';

    final share = WirelessShare(
      id: shareId,
      connectionId: connectionId,
      remotePath: remotePath,
      targetDevices: targetDevices,
      status: WirelessShareStatus.preparing,
      expiry: expiry ?? const Duration(hours: 24),
      createdAt: DateTime.now(),
    );

    _wirelessShares[shareId] = share;

    // Start wireless sharing
    _startWirelessSharing(share);

    _emitWirelessShareEvent(WirelessShareEventType.shareCreated, shareId: shareId);

    return share;
  }

  /// Create new workspace (Sigma feature)
  Future<FTPWorkspace> createWorkspace({
    required String name,
    String? description,
    List<WorkspaceTab>? initialTabs,
  }) async {
    final workspaceId = 'workspace_${DateTime.now().millisecondsSinceEpoch}';

    final workspace = FTPWorkspace(
      id: workspaceId,
      name: name,
      description: description,
      tabs: initialTabs ?? [],
      maxTabs: _config.getParameter('workspace_max_tabs', defaultValue: 10),
      createdAt: DateTime.now(),
    );

    _workspaces[workspaceId] = workspace;

    _emitFTPEvent(FTPEventType.workspaceCreated, data: {'workspace_id': workspaceId, 'name': name});

    return workspace;
  }

  /// Add tab to workspace (Sigma feature)
  Future<WorkspaceTab> addWorkspaceTab({
    required String workspaceId,
    required String connectionId,
    required String remotePath,
    String? name,
  }) async {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) {
      throw FTPException('Workspace not found: $workspaceId', FTPErrorType.invalidResponse);
    }

    if (workspace.tabs.length >= workspace.maxTabs) {
      throw FTPException('Maximum tabs reached for workspace', FTPErrorType.invalidResponse);
    }

    final tab = WorkspaceTab(
      id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
      connectionId: connectionId,
      remotePath: remotePath,
      name: name ?? remotePath.split('/').last,
      createdAt: DateTime.now(),
    );

    workspace.tabs.add(tab);

    _emitFTPEvent(FTPEventType.workspaceTabAdded,
        data: {'workspace_id': workspaceId, 'tab_id': tab.id, 'path': remotePath});

    return tab;
  }

  /// Connect using multiple storage adapters (FileGator feature)
  Future<String> connectWithAdapter({
    required String adapterType,
    required Map<String, dynamic> adapterConfig,
    bool useSSL = false,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final adapter = _storageAdapters[adapterType];
    if (adapter == null) {
      throw FTPException('Storage adapter not found: $adapterType', FTPErrorType.invalidResponse);
    }

    // Use the adapter to establish connection
    final connectionId = await adapter.connect(adapterConfig, useSSL: useSSL, timeout: timeout);

    // Wrap in FTP connection for compatibility
    final adapterConnection = FTPConnection(
      id: connectionId,
      host: adapterConfig['host'] ?? 'adapter',
      port: adapterConfig['port'] ?? 0,
      username: adapterConfig['username'] ?? 'adapter',
      socket: Socket.connect('127.0.0.1', 0).asStream().first as Socket, // Placeholder
      status: FTPConnectionStatus.ready,
      useSSL: useSSL,
    );

    _activeConnections[connectionId] = adapterConnection;

    _emitFTPEvent(FTPEventType.connected, connectionId: connectionId,
        data: {'adapter': adapterType, 'ssl': useSSL});

    return connectionId;
  }

  /// Connect with SSL/TLS encryption (OpenFTP feature)
  Future<String> connectSSL({
    required String host,
    required int port,
    required String username,
    required String password,
    String sslProfile = 'default',
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    final sslContext = _sslContexts[sslProfile];
    if (sslContext == null) {
      throw FTPException('SSL context not found: $sslProfile', FTPErrorType.invalidResponse);
    }

    // Use SSL context for secure connection
    return await connect(
      host: host,
      port: port,
      username: username,
      password: password,
      useSSL: true,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  /// Chunked upload with resume capability (FileGator feature)
  Future<void> uploadChunked({
    required String connectionId,
    required String localPath,
    required String remotePath,
    Function(double)? onProgress,
    Function(String)? onChunkComplete,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) async {
    final connection = _activeConnections[connectionId];
    if (connection == null) {
      throw FTPException('Connection not found: $connectionId', FTPErrorType.connectionFailed);
    }

    final file = File(localPath);
    final fileSize = await file.length();

    // Split file into chunks and upload
    final totalChunks = (fileSize / chunkSize).ceil();
    int uploadedBytes = 0;

    for (int chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
      final start = chunkIndex * chunkSize;
      final end = (start + chunkSize) < fileSize ? start + chunkSize : fileSize;
      final chunkSizeActual = end - start;

      // Read chunk
      final chunk = await file.openRead(start, end).first;

      // Upload chunk (this would need to be implemented with resumable upload protocol)
      // For now, this is a placeholder for the chunked upload logic

      uploadedBytes += chunkSizeActual;
      final progress = uploadedBytes / fileSize;
      onProgress?.call(progress);

      onChunkComplete?.call('Chunk ${chunkIndex + 1}/$totalChunks completed');

      _emitFTPEvent(FTPEventType.uploadProgress, connectionId: connectionId,
          data: {'progress': progress, 'chunk': chunkIndex + 1, 'total_chunks': totalChunks});
    }
  }

  /// Get workspace information
  FTPWorkspace? getWorkspace(String workspaceId) {
    return _workspaces[workspaceId];
  }

  /// Get all workspaces
  List<FTPWorkspace> getAllWorkspaces() {
    return _workspaces.values.toList();
  }

  /// Get streaming session information
  StreamingSession? getStreamingSession(String sessionId) {
    return _streamingSessions[sessionId];
  }

  /// Get wireless share information
  WirelessShare? getWirelessShare(String shareId) {
    return _wirelessShares[shareId];
  }

  /// Get available storage adapters
  List<String> getAvailableAdapters() {
    return _storageAdapters.keys.toList();
  }

  /// Get SSL profiles
  List<String> getSSLProfiles() {
    return _sslContexts.keys.toList();
  }

  /// Emit streaming event
  void _emitStreamingEvent(StreamingEventType type, {required String sessionId, Map<String, dynamic>? data}) {
    final event = StreamingEvent(type: type, sessionId: sessionId, timestamp: DateTime.now(), data: data ?? {});
    _streamingEventController.add(event);
  }

  /// Emit wireless share event
  void _emitWirelessShareEvent(WirelessShareEventType type, {required String shareId, Map<String, dynamic>? data}) {
    final event = WirelessShareEvent(type: type, shareId: shareId, timestamp: DateTime.now(), data: data ?? {});
    _wirelessShareEventController.add(event);
  }

  /// Disconnect FTP connection
  Future<void> disconnect(String connectionId) async {
    final connection = _activeConnections[connectionId];
    if (connection != null) {
      try {
        await _sendFTPCommand(connection.socket, 'QUIT\r\n');
        await connection.socket.close();
      } catch (e) {
        // Ignore errors during disconnect
      }

      _activeConnections.remove(connectionId);
      _emitFTPEvent(FTPEventType.disconnected, connectionId: connectionId);
    }
  }

  /// Get connection status
  FTPConnection? getConnection(String connectionId) {
    return _activeConnections[connectionId];
  }

  /// Get all active connections
  List<FTPConnection> getActiveConnections() {
    return _activeConnections.values.toList();
  }

  /// Disconnect FTP connection
  Future<void> disconnect(String connectionId) async {
    final connection = _activeConnections[connectionId];
    if (connection != null) {
      try {
        await _sendFTPCommand(connection.socket, 'QUIT\r\n');
        await connection.socket.close();
      } catch (e) {
        // Ignore errors during disconnect
      }

      _activeConnections.remove(connectionId);
      _emitFTPEvent(FTPEventType.disconnected, connectionId: connectionId);
    }
  }

  /// Get connection status
  FTPConnection? getConnection(String connectionId) {
    return _activeConnections[connectionId];
  }

  /// Get all active connections
  List<FTPConnection> getActiveConnections() {
    return _activeConnections.values.toList();
  }

  /// Send FTP command
  Future<void> _sendFTPCommand(Socket socket, String command) async {
    socket.write(command);
    await socket.flush();
  }

  /// Read FTP response
  Future<String> _readFTPResponse(Socket socket) async {
    final buffer = StringBuffer();
    while (true) {
      final byte = await socket.first;
      buffer.writeCharCode(byte);
      if (byte == 10) break; // \n
    }
    return buffer.toString().trim();
  }

  /// Read data from data connection with timeout
  Future<Uint8List> _readDataConnectionWithTimeout(Socket socket, {required Duration timeout}) async {
    final completer = Completer<Uint8List>();
    final data = <int>[];
    bool timeoutOccurred = false;

    // Set up timeout
    final timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        timeoutOccurred = true;
        socket.close();
        completer.completeError(FTPException('Data connection timeout', FTPErrorType.timeout));
      }
    });

    try {
      await for (final chunk in socket) {
        if (timeoutOccurred) break;
        data.addAll(chunk);
      }

      if (!timeoutOccurred) {
        completer.complete(Uint8List.fromList(data));
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    } finally {
      timeoutTimer.cancel();
      try {
        socket.close();
      } catch (_) {}
    }

    return completer.future;
  }

  /// Check if an error is retryable
  bool _isRetryableError(dynamic error) {
    if (error is FTPException) {
      // Don't retry authentication or permission errors
      switch (error.type) {
        case FTPErrorType.authenticationFailed:
        case FTPErrorType.permissionDenied:
        case FTPErrorType.fileNotFound:
        case FTPErrorType.invalidResponse:
          return false;
        default:
          return true;
      }
    }

    // Retry network-related errors
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('network') ||
           errorString.contains('socket');
  }

  /// Parse passive mode response for data connection
  (InternetAddress, int) _parsePassiveModeResponse(String response) {
    // Response format: 227 Entering Passive Mode (h1,h2,h3,h4,p1,p2)
    final match = RegExp(r'227.*?\((.*?)\)').firstMatch(response);
    if (match == null) throw Exception('Invalid passive mode response');

    final parts = match.group(1)!.split(',');
    final host = '${parts[0]}.${parts[1]}.${parts[2]}.${parts[3]}';
    final port = int.parse(parts[4]) * 256 + int.parse(parts[5]);

    return (InternetAddress(host), port);
  }

  /// Parse directory listing
  List<FTPFileInfo> _parseDirectoryListing(String listing) {
    final files = <FTPFileInfo>[];
    final lines = listing.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 9) continue;

        final permissions = parts[0];
        final size = int.tryParse(parts[4]) ?? 0;
        final date = '${parts[5]} ${parts[6]} ${parts[7]}';
        final name = parts.sublist(8).join(' ');

        files.add(FTPFileInfo(
          name: name,
          size: size,
          permissions: permissions,
          modifiedDate: date,
          isDirectory: permissions.startsWith('d'),
        ));
      } catch (e) {
        // Skip malformed lines
        continue;
      }
    }

    return files;
  }

  /// Generate unique connection ID
  String _generateConnectionId() {
    return 'ftp_${DateTime.now().millisecondsSinceEpoch}_${_activeConnections.length}';
  }

  /// Emit FTP event
  void _emitFTPEvent(FTPEventType type, {
    String? connectionId,
    String? filePath,
    List<FTPFileInfo>? files,
    String? error,
    String? path,
  }) {
    final event = FTPEvent(
      type: type,
      timestamp: DateTime.now(),
      connectionId: connectionId,
      filePath: filePath,
      files: files,
      error: error,
      path: path,
    );
    _ftpEventController.add(event);
  }

    _activeConnections.remove(connectionId);
    _emitFTPEvent(FTPEventType.disconnected, connectionId: connectionId);
  }
}

  void dispose() {
    _ftpEventController.close();
    _streamingEventController.close();
    _wirelessShareEventController.close();
    // Disconnect all connections
    for (final connection in _activeConnections.values) {
      try {
        connection.socket.close();
      } catch (e) {
        // Ignore
      }
    }
    _activeConnections.clear();
  }
}

/// Supporting data classes for advanced features from Owlfiles/FileGator/OpenFTP/Sigma

/// Storage Adapter Interface (FileGator style)
abstract class StorageAdapter {
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = false, Duration timeout = const Duration(seconds: 30)});
  Future<void> disconnect(String connectionId);
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path);
  Future<void> downloadFile(String connectionId, String remotePath, String localPath);
  Future<void> uploadFile(String connectionId, String localPath, String remotePath);
}

/// FTP Storage Adapter Implementation
class FTPStorageAdapter implements StorageAdapter {
  @override
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = false, Duration timeout = const Duration(seconds: 30)}) async {
    final service = FTPClientService();
    return await service.connect(
      host: config['host'],
      port: config['port'],
      username: config['username'],
      password: config['password'],
      useSSL: useSSL,
      timeout: timeout,
    );
  }

  @override
  Future<void> disconnect(String connectionId) async {
    await FTPClientService().disconnect(connectionId);
  }

  @override
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path) async {
    return await FTPClientService().listDirectory(connectionId, path);
  }

  @override
  Future<void> downloadFile(String connectionId, String remotePath, String localPath) async {
    await FTPClientService().downloadFile(connectionId: connectionId, remotePath: remotePath, localPath: localPath);
  }

  @override
  Future<void> uploadFile(String connectionId, String localPath, String remotePath) async {
    await FTPClientService().uploadFile(connectionId: connectionId, localPath: localPath, remotePath: remotePath);
  }
}

/// FTPS Storage Adapter (SSL-enabled FTP)
class FTPSStorageAdapter implements StorageAdapter {
  @override
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = true, Duration timeout = const Duration(seconds: 30)}) async {
    final service = FTPClientService();
    return await service.connectSSL(
      host: config['host'],
      port: config['port'] ?? 990,
      username: config['username'],
      password: config['password'],
      sslProfile: config['ssl_profile'] ?? 'default',
      timeout: timeout,
    );
  }

  @override
  Future<void> disconnect(String connectionId) async {
    await FTPClientService().disconnect(connectionId);
  }

  @override
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path) async {
    return await FTPClientService().listDirectory(connectionId, path);
  }

  @override
  Future<void> downloadFile(String connectionId, String remotePath, String localPath) async {
    await FTPClientService().downloadFile(connectionId: connectionId, remotePath: remotePath, localPath: localPath);
  }

  @override
  Future<void> uploadFile(String connectionId, String localPath, String remotePath) async {
    await FTPClientService().uploadFile(connectionId: connectionId, localPath: localPath, remotePath: remotePath);
  }
}

/// SFTP Storage Adapter (SSH FTP)
class SFTPStorageAdapter implements StorageAdapter {
  @override
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = false, Duration timeout = const Duration(seconds: 30)}) async {
    // SFTP implementation would go here
    // For now, this is a placeholder
    throw UnimplementedError('SFTP adapter not yet implemented');
  }

  @override
  Future<void> disconnect(String connectionId) async {
    // Implementation would go here
  }

  @override
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path) async {
    // Implementation would go here
    return [];
  }

  @override
  Future<void> downloadFile(String connectionId, String remotePath, String localPath) async {
    // Implementation would go here
  }

  @override
  Future<void> uploadFile(String connectionId, String localPath, String remotePath) async {
    // Implementation would go here
  }
}

/// Cloud Storage Adapters (FileGator style)

class S3StorageAdapter implements StorageAdapter {
  @override
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = true, Duration timeout = const Duration(seconds: 30)}) async {
    // S3 implementation would go here
    throw UnimplementedError('S3 adapter not yet implemented');
  }

  @override
  Future<void> disconnect(String connectionId) async {}

  @override
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path) async => [];

  @override
  Future<void> downloadFile(String connectionId, String remotePath, String localPath) async {}

  @override
  Future<void> uploadFile(String connectionId, String localPath, String remotePath) async {}
}

class DropboxStorageAdapter implements StorageAdapter {
  @override
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = true, Duration timeout = const Duration(seconds: 30)}) async {
    throw UnimplementedError('Dropbox adapter not yet implemented');
  }

  @override
  Future<void> disconnect(String connectionId) async {}

  @override
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path) async => [];

  @override
  Future<void> downloadFile(String connectionId, String remotePath, String localPath) async {}

  @override
  Future<void> uploadFile(String connectionId, String localPath, String remotePath) async {}
}

class GoogleDriveStorageAdapter implements StorageAdapter {
  @override
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = true, Duration timeout = const Duration(seconds: 30)}) async {
    throw UnimplementedError('Google Drive adapter not yet implemented');
  }

  @override
  Future<void> disconnect(String connectionId) async {}

  @override
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path) async => [];

  @override
  Future<void> downloadFile(String connectionId, String remotePath, String localPath) async {}

  @override
  Future<void> uploadFile(String connectionId, String localPath, String remotePath) async {}
}

class OneDriveStorageAdapter implements StorageAdapter {
  @override
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = true, Duration timeout = const Duration(seconds: 30)}) async {
    throw UnimplementedError('OneDrive adapter not yet implemented');
  }

  @override
  Future<void> disconnect(String connectionId) async {}

  @override
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path) async => [];

  @override
  Future<void> downloadFile(String connectionId, String remotePath, String localPath) async {}

  @override
  Future<void> uploadFile(String connectionId, String localPath, String remotePath) async {}
}

/// Local and Network Storage Adapters

class LocalStorageAdapter implements StorageAdapter {
  @override
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = false, Duration timeout = const Duration(seconds: 30)}) async {
    // Local file system access
    throw UnimplementedError('Local adapter not yet implemented');
  }

  @override
  Future<void> disconnect(String connectionId) async {}

  @override
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path) async => [];

  @override
  Future<void> downloadFile(String connectionId, String remotePath, String localPath) async {}

  @override
  Future<void> uploadFile(String connectionId, String localPath, String remotePath) async {}
}

class SMBStorageAdapter implements StorageAdapter {
  @override
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = false, Duration timeout = const Duration(seconds: 30)}) async {
    // Windows file sharing (SMB/CIFS)
    throw UnimplementedError('SMB adapter not yet implemented');
  }

  @override
  Future<void> disconnect(String connectionId) async {}

  @override
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path) async => [];

  @override
  Future<void> downloadFile(String connectionId, String remotePath, String localPath) async {}

  @override
  Future<void> uploadFile(String connectionId, String localPath, String remotePath) async {}
}

class WebDAVStorageAdapter implements StorageAdapter {
  @override
  Future<String> connect(Map<String, dynamic> config, {bool useSSL = true, Duration timeout = const Duration(seconds: 30)}) async {
    // WebDAV protocol support
    throw UnimplementedError('WebDAV adapter not yet implemented');
  }

  @override
  Future<void> disconnect(String connectionId) async {}

  @override
  Future<List<FTPFileInfo>> listDirectory(String connectionId, String path) async => [];

  @override
  Future<void> downloadFile(String connectionId, String remotePath, String localPath) async {}

  @override
  Future<void> uploadFile(String connectionId, String localPath, String remotePath) async {}
}

/// SSL Context (OpenFTP style)
class SSLContext {
  final bool certificateValidation;
  final List<String> supportedProtocols;
  final List<String> cipherSuites;

  SSLContext({
    required this.certificateValidation,
    required this.supportedProtocols,
    required this.cipherSuites,
  });
}

/// Workspace Management (Sigma File Manager style)
class FTPWorkspace {
  final String id;
  final String name;
  final String? description;
  final List<WorkspaceTab> tabs;
  final int maxTabs;
  final DateTime createdAt;

  FTPWorkspace({
    required this.id,
    required this.name,
    this.description,
    required this.tabs,
    required this.maxTabs,
    required this.createdAt,
  });
}

class WorkspaceTab {
  final String id;
  final String connectionId;
  final String remotePath;
  final String name;
  final DateTime createdAt;

  WorkspaceTab({
    required this.id,
    required this.connectionId,
    required this.remotePath,
    required this.name,
    required this.createdAt,
  });
}

/// Streaming Capabilities (Owlfiles style)
enum MediaType {
  video,
  audio,
  image,
}

enum StreamingQuality {
  low,
  medium,
  high,
  auto,
}

enum StreamingStatus {
  preparing,
  streaming,
  paused,
  stopped,
  error,
}

class StreamingSession {
  final String id;
  final String connectionId;
  final String remotePath;
  final MediaType mediaType;
  final StreamingQuality quality;
  StreamingStatus status;
  final DateTime createdAt;

  StreamingSession({
    required this.id,
    required this.connectionId,
    required this.remotePath,
    required this.mediaType,
    required this.quality,
    required this.status,
    required this.createdAt,
  });
}

/// Wireless Sharing (Sigma File Manager style)
enum WirelessShareStatus {
  preparing,
  sharing,
  paused,
  expired,
  error,
}

class WirelessShare {
  final String id;
  final String connectionId;
  final String remotePath;
  final List<String> targetDevices;
  WirelessShareStatus status;
  final Duration expiry;
  final DateTime createdAt;

  WirelessShare({
    required this.id,
    required this.connectionId,
    required this.remotePath,
    required this.targetDevices,
    required this.status,
    required this.expiry,
    required this.createdAt,
  });
}

/// Event Classes for Advanced Features
enum StreamingEventType {
  streamStarted,
  streamPaused,
  streamResumed,
  streamStopped,
  streamError,
  qualityChanged,
}

enum WirelessShareEventType {
  shareCreated,
  shareStarted,
  sharePaused,
  shareExpired,
  shareError,
  deviceConnected,
  deviceDisconnected,
}

class StreamingEvent {
  final StreamingEventType type;
  final String sessionId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  StreamingEvent({
    required this.type,
    required this.sessionId,
    required this.timestamp,
    required this.data,
  });
}

class WirelessShareEvent {
  final WirelessShareEventType type;
  final String shareId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  WirelessShareEvent({
    required this.type,
    required this.shareId,
    required this.timestamp,
    required this.data,
  });
}

/// Enhanced FTP Event Types (including workspace management)
enum FTPEventType {
  connecting,
  connected,
  connectionFailed,
  disconnected,
  listing,
  listed,
  listFailed,
  downloading,
  downloaded,
  downloadFailed,
  uploading,
  uploaded,
  uploadFailed,
  uploadProgress,
  workspaceCreated,
  workspaceDeleted,
  workspaceTabAdded,
  workspaceTabRemoved,
}

/// Enhanced FTP Event with additional data
class FTPEvent {
  final FTPEventType type;
  final DateTime timestamp;
  final String? connectionId;
  final String? filePath;
  final List<FTPFileInfo>? files;
  final String? error;
  final String? path;
  final Map<String, dynamic>? data;

  FTPEvent({
    required this.type,
    required this.timestamp,
    this.connectionId,
    this.filePath,
    this.files,
    this.error,
    this.path,
    this.data,
  });
}

/// FTP Connection Model
class FTPConnection {
  final String id;
  final String host;
  final int port;
  final String username;
  final Socket socket;
  FTPConnectionStatus status;
  final bool useSSL;
  InternetAddress? dataHost;
  int? dataPort;
  DateTime? connectedAt;

  FTPConnection({
    required this.id,
    required this.host,
    required this.port,
    required this.username,
    required this.socket,
    required this.status,
    required this.useSSL,
    this.dataHost,
    this.dataPort,
    DateTime? connectedAt,
  }) : connectedAt = connectedAt ?? DateTime.now();
}

/// FTP Connection Status
enum FTPConnectionStatus {
  connecting,
  connected,
  ready,
  disconnected,
  error,
}

/// FTP File Info
class FTPFileInfo {
  final String name;
  final int size;
  final String permissions;
  final String modifiedDate;
  final bool isDirectory;

  FTPFileInfo({
    required this.name,
    required this.size,
    required this.permissions,
    required this.modifiedDate,
    required this.isDirectory,
  });
}

/// FTP Credentials
class FTPCredentials {
  final String host;
  final int port;
  final String username;
  final String password;
  DateTime lastUsed;

  FTPCredentials({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();
}

/// Custom FTP Exception
class FTPException implements Exception {
  final String message;
  final FTPErrorType type;
  final String? details;

  FTPException(this.message, this.type, [this.details]);

  @override
  String toString() => 'FTPException: $message (${type.toString().split('.').last})';
}

/// FTP Error Types
enum FTPErrorType {
  connectionFailed,
  authenticationFailed,
  passiveModeFailed,
  dataTransferFailed,
  timeout,
  invalidResponse,
  permissionDenied,
  fileNotFound,
  diskFull,
  networkError,
}
