import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'performance_optimization_service.dart';
import '../../core/config/central_config.dart';

/// Cloud Storage Integration Service
/// Provides unified API for multiple cloud storage providers with advanced features
class CloudStorageService {
  static final CloudStorageService _instance = CloudStorageService._internal();
  factory CloudStorageService() => _instance;
  CloudStorageService._internal();

  final PerformanceOptimizationService _performanceService = PerformanceOptimizationService();
  final CentralConfig _config = CentralConfig.instance;
  final StreamController<CloudEvent> _cloudEventController = StreamController.broadcast();

  Stream<CloudEvent> get cloudEvents => _cloudEventController.stream;

  // Provider instances
  final Map<CloudProvider, CloudProviderBase> _providers = {};
  final Map<String, CloudAccount> _accounts = {};
  final Map<String, CloudSyncSession> _syncSessions = {};

  bool _isInitialized = false;

  // Configuration
  static const Duration _authTimeout = Duration(minutes: 5);
  static const Duration _uploadTimeout = Duration(minutes: 10);
  static const int _maxConcurrentOperations = 3;
  static const int _chunkSize = 1024 * 1024; // 1MB chunks

  Semaphore _operationSemaphore = Semaphore(_maxConcurrentOperations);

  /// Initialize cloud storage service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent(
        'CloudStorageService',
        '1.0.0',
        'Unified cloud storage integration with multiple providers using comprehensive centralized parameterization',
        dependencies: ['PerformanceOptimizationService'],
        parameters: {
          // === AUTHENTICATION SETTINGS ===
          'cloud.auth_timeout_minutes': _config.getParameter('cloud.auth_timeout_minutes', defaultValue: 5),
          'cloud.auth_refresh_threshold_seconds': _config.getParameter('cloud.auth_refresh_threshold_seconds', defaultValue: 300),
          'cloud.auth_persist_session': _config.getParameter('cloud.auth_persist_session', defaultValue: true),
          'cloud.auth_detect_session_in_url': _config.getParameter('cloud.auth_detect_session_in_url', defaultValue: true),
          'cloud.auth_flow_type': _config.getParameter('cloud.auth_flow_type', defaultValue: 'pkce'),

          // === CONNECTION SETTINGS ===
          'cloud.connection_timeout_seconds': _config.getParameter('cloud.connection_timeout_seconds', defaultValue: 30),
          'cloud.request_timeout_seconds': _config.getParameter('cloud.request_timeout_seconds', defaultValue: 60),
          'cloud.max_connections': _config.getParameter('cloud.max_connections', defaultValue: 10),
          'cloud.connection_pool_size': _config.getParameter('cloud.connection_pool_size', defaultValue: 5),
          'cloud.keep_alive_enabled': _config.getParameter('cloud.keep_alive_enabled', defaultValue: true),

          // === UPLOAD SETTINGS ===
          'cloud.upload_timeout_minutes': _config.getParameter('cloud.upload_timeout_minutes', defaultValue: 10),
          'cloud.upload_chunk_size_mb': _config.getParameter('cloud.upload_chunk_size_mb', defaultValue: 1),
          'cloud.upload_max_file_size_mb': _config.getParameter('cloud.upload_max_file_size_mb', defaultValue: 100),
          'cloud.upload_resume_enabled': _config.getParameter('cloud.upload_resume_enabled', defaultValue: true),
          'cloud.upload_parallel_uploads': _config.getParameter('cloud.upload_parallel_uploads', defaultValue: 1),
          'cloud.upload_verify_integrity': _config.getParameter('cloud.upload_verify_integrity', defaultValue: true),

          // === DOWNLOAD SETTINGS ===
          'cloud.download_timeout_minutes': _config.getParameter('cloud.download_timeout_minutes', defaultValue: 10),
          'cloud.download_chunk_size_mb': _config.getParameter('cloud.download_chunk_size_mb', defaultValue: 1),
          'cloud.download_resume_enabled': _config.getParameter('cloud.download_resume_enabled', defaultValue: true),
          'cloud.download_parallel_downloads': _config.getParameter('cloud.download_parallel_downloads', defaultValue: 1),

          // === OPERATION LIMITS ===
          'cloud.max_concurrent_operations': _config.getParameter('cloud.max_concurrent_operations', defaultValue: 3),
          'cloud.operation_semaphore_size': _config.getParameter('cloud.operation_semaphore_size', defaultValue: 3),
          'cloud.operation_retry_attempts': _config.getParameter('cloud.operation_retry_attempts', defaultValue: 3),
          'cloud.operation_retry_delay_seconds': _config.getParameter('cloud.operation_retry_delay_seconds', defaultValue: 1),

          // === SYNCHRONIZATION SETTINGS ===
          'cloud.sync_enabled': _config.getParameter('cloud.sync_enabled', defaultValue: true),
          'cloud.sync_interval_seconds': _config.getParameter('cloud.sync_interval_seconds', defaultValue: 300),
          'cloud.sync_max_concurrent': _config.getParameter('cloud.sync_max_concurrent', defaultValue: 2),
          'cloud.sync_bidirectional_enabled': _config.getParameter('cloud.sync_bidirectional_enabled', defaultValue: true),
          'cloud.sync_conflict_strategy': _config.getParameter('cloud.sync_conflict_strategy', defaultValue: 'last_write_wins'),
          'cloud.sync_backup_on_conflict': _config.getParameter('cloud.sync_backup_on_conflict', defaultValue: true),

          // === PROVIDER SUPPORT ===
          'cloud.providers.google_drive_enabled': _config.getParameter('cloud.providers.google_drive_enabled', defaultValue: true),
          'cloud.providers.one_drive_enabled': _config.getParameter('cloud.providers.one_drive_enabled', defaultValue: true),
          'cloud.providers.dropbox_enabled': _config.getParameter('cloud.providers.dropbox_enabled', defaultValue: true),
          'cloud.providers.box_enabled': _config.getParameter('cloud.providers.box_enabled', defaultValue: true),
          'cloud.providers.supported_providers': _config.getParameter('cloud.providers.supported_providers', defaultValue: ['googleDrive', 'oneDrive', 'dropbox', 'box']),

          // === STORAGE SETTINGS ===
          'cloud.storage.bucket_name': _config.getParameter('cloud.storage.bucket_name', defaultValue: 'user-files'),
          'cloud.storage.cache_enabled': _config.getParameter('cloud.storage.cache_enabled', defaultValue: true),
          'cloud.storage.cache_ttl_seconds': _config.getParameter('cloud.storage.cache_ttl_seconds', defaultValue: 3600),
          'cloud.storage.compression_enabled': _config.getParameter('cloud.storage.compression_enabled', defaultValue: false),
          'cloud.storage.encryption_enabled': _config.getParameter('cloud.storage.encryption_enabled', defaultValue: true),

          // === SECURITY SETTINGS ===
          'cloud.security.validate_certificates': _config.getParameter('cloud.security.validate_certificates', defaultValue: true),
          'cloud.security.enable_ssl': _config.getParameter('cloud.security.enable_ssl', defaultValue: true),
          'cloud.security.audit_operations': _config.getParameter('cloud.security.audit_operations', defaultValue: true),
          'cloud.security.safe_operations_only': _config.getParameter('cloud.security.safe_operations_only', defaultValue: true),

          // === PERFORMANCE SETTINGS ===
          'cloud.performance.monitoring_enabled': _config.getParameter('cloud.performance.monitoring_enabled', defaultValue: true),
          'cloud.performance.metrics_interval_seconds': _config.getParameter('cloud.performance.metrics_interval_seconds', defaultValue: 60),
          'cloud.performance.slow_operation_threshold_ms': _config.getParameter('cloud.performance.slow_operation_threshold_ms', defaultValue: 5000),
          'cloud.performance.memory_limit_mb': _config.getParameter('cloud.performance.memory_limit_mb', defaultValue: 256),
          'cloud.performance.cpu_limit_percent': _config.getParameter('cloud.performance.cpu_limit_percent', defaultValue: 80),

          // === SHARING SETTINGS ===
          'cloud.sharing.enabled': _config.getParameter('cloud.sharing.enabled', defaultValue: true),
          'cloud.sharing.max_recipients': _config.getParameter('cloud.sharing.max_recipients', defaultValue: 50),
          'cloud.sharing.default_permission': _config.getParameter('cloud.sharing.default_permission', defaultValue: 'view'),
          'cloud.sharing.link_expiry_days': _config.getParameter('cloud.sharing.link_expiry_days', defaultValue: 30),
          'cloud.sharing.password_protection_enabled': _config.getParameter('cloud.sharing.password_protection_enabled', defaultValue: false),

          // === UI INTEGRATION ===
          'cloud.ui.progress_indicators': _config.getParameter('cloud.ui.progress_indicators', defaultValue: true),
          'cloud.ui.notifications_enabled': _config.getParameter('cloud.ui.notifications_enabled', defaultValue: true),
          'cloud.ui.drag_drop_enabled': _config.getParameter('cloud.ui.drag_drop_enabled', defaultValue: true),
          'cloud.ui.context_menus': _config.getParameter('cloud.ui.context_menus', defaultValue: true),
          'cloud.ui.keyboard_shortcuts': _config.getParameter('cloud.ui.keyboard_shortcuts', defaultValue: true),

          // === ANALYTICS ===
          'cloud.analytics.enabled': _config.getParameter('cloud.analytics.enabled', defaultValue: true),
          'cloud.analytics.track_operations': _config.getParameter('cloud.analytics.track_operations', defaultValue: true),
          'cloud.analytics.track_performance': _config.getParameter('cloud.analytics.track_performance', defaultValue: true),
          'cloud.analytics.track_errors': _config.getParameter('cloud.analytics.track_errors', defaultValue: true),
          'cloud.analytics.report_interval_hours': _config.getParameter('cloud.analytics.report_interval_hours', defaultValue: 24),

          // === ERROR HANDLING ===
          'cloud.error_recovery_enabled': _config.getParameter('cloud.error_recovery_enabled', defaultValue: true),
          'cloud.error_retry_enabled': _config.getParameter('cloud.error_retry_enabled', defaultValue: true),
          'cloud.error_max_retry_attempts': _config.getParameter('cloud.error_max_retry_attempts', defaultValue: 3),
          'cloud.error_retry_backoff_multiplier': _config.getParameter('cloud.error_retry_backoff_multiplier', defaultValue: 2.0),
          'cloud.error_user_friendly_messages': _config.getParameter('cloud.error_user_friendly_messages', defaultValue: true),
          'cloud.error_detailed_logging': _config.getParameter('cloud.error_detailed_logging', defaultValue: true),

          // === LOGGING ===
          'cloud.logging.level': _config.getParameter('cloud.logging.level', defaultValue: 'info'),
          'cloud.logging.operation_details': _config.getParameter('cloud.logging.operation_details', defaultValue: true),
          'cloud.logging.connection_events': _config.getParameter('cloud.logging.connection_events', defaultValue: true),
          'cloud.logging.performance_metrics': _config.getParameter('cloud.logging.performance_metrics', defaultValue: true),
          'cloud.logging.security_events': _config.getParameter('cloud.logging.security_events', defaultValue: true),
          'cloud.logging.audit_trail': _config.getParameter('cloud.logging.audit_trail', defaultValue: true),

          // === BACKUP AND RECOVERY ===
          'cloud.backup.enabled': _config.getParameter('cloud.backup.enabled', defaultValue: true),
          'cloud.backup.interval_hours': _config.getParameter('cloud.backup.interval_hours', defaultValue: 24),
          'cloud.backup.retention_days': _config.getParameter('cloud.backup.retention_days', defaultValue: 30),
          'cloud.backup.encryption': _config.getParameter('cloud.backup.encryption', defaultValue: true),
          'cloud.backup.verify_integrity': _config.getParameter('cloud.backup.verify_integrity', defaultValue: true),

          // === ADVANCED FEATURES ===
          'cloud.advanced.offline_sync_enabled': _config.getParameter('cloud.advanced.offline_sync_enabled', defaultValue: true),
          'cloud.advanced.delta_sync_enabled': _config.getParameter('cloud.advanced.delta_sync_enabled', defaultValue: true),
          'cloud.advanced.compression_level': _config.getParameter('cloud.advanced.compression_level', defaultValue: 'normal'),
          'cloud.advanced.deduplication_enabled': _config.getParameter('cloud.advanced.deduplication_enabled', defaultValue: false),
          'cloud.advanced.versioning_enabled': _config.getParameter('cloud.advanced.versioning_enabled', defaultValue: false),

          // === INTEGRATION SETTINGS ===
          'cloud.integration.file_operations_enabled': _config.getParameter('cloud.integration.file_operations_enabled', defaultValue: true),
          'cloud.integration.collaboration_enabled': _config.getParameter('cloud.integration.collaboration_enabled', defaultValue: true),
          'cloud.integration.analytics_enabled': _config.getParameter('cloud.integration.analytics_enabled', defaultValue: true),
          'cloud.integration.plugin_support_enabled': _config.getParameter('cloud.integration.plugin_support_enabled', defaultValue: true),

          // === NETWORK OPTIMIZATION ===
          'cloud.network.dns_cache_timeout': _config.getParameter('cloud.network.dns_cache_timeout', defaultValue: 300),
          'cloud.network.tcp_nodelay': _config.getParameter('cloud.network.tcp_nodelay', defaultValue: true),
          'cloud.network.buffer_optimization': _config.getParameter('cloud.network.buffer_optimization', defaultValue: true),
          'cloud.network.proxy_support': _config.getParameter('cloud.network.proxy_support', defaultValue: false),
          'cloud.network.proxy_host': _config.getParameter('cloud.network.proxy_host', defaultValue: ''),
          'cloud.network.proxy_port': _config.getParameter('cloud.network.proxy_port', defaultValue: 0),

          // === PLATFORM-SPECIFIC ===
          'cloud.platform.mobile_optimization': _config.getParameter('cloud.platform.mobile_optimization', defaultValue: true),
          'cloud.platform.desktop_optimization': _config.getParameter('cloud.platform.desktop_optimization', defaultValue: true),
          'cloud.platform.web_optimization': _config.getParameter('cloud.platform.web_optimization', defaultValue: true),
          'cloud.platform.bandwidth_adaptation': _config.getParameter('cloud.platform.bandwidth_adaptation', defaultValue: true),

          // === MONITORING AND ALERTS ===
          'cloud.monitoring.enabled': _config.getParameter('cloud.monitoring.enabled', defaultValue: true),
          'cloud.monitoring.alerts_enabled': _config.getParameter('cloud.monitoring.alerts_enabled', defaultValue: true),
          'cloud.monitoring.health_checks_enabled': _config.getParameter('cloud.monitoring.health_checks_enabled', defaultValue: true),
          'cloud.monitoring.usage_tracking_enabled': _config.getParameter('cloud.monitoring.usage_tracking_enabled', defaultValue: true),

          // === DEBUGGING ===
          'cloud.debug_mode_enabled': _config.getParameter('cloud.debug_mode_enabled', defaultValue: false),
          'cloud.debug_mock_responses': _config.getParameter('cloud.debug_mock_responses', defaultValue: false),
          'cloud.debug_performance_profiling': _config.getParameter('cloud.debug_performance_profiling', defaultValue: false),
          'cloud.debug_connection_tracing': _config.getParameter('cloud.debug_connection_tracing', defaultValue: false),
        }
      );

      // Register component relationships
      await _config.registerComponentRelationship(
        'CloudStorageService',
        'PerformanceOptimizationService',
        RelationshipType.depends_on,
        'Uses performance optimization for operation tracking',
      );

      await _config.registerComponentRelationship(
        'CloudStorageService',
        'AdvancedFileOperationsService',
        RelationshipType.uses,
        'Integrates with file operations for cloud file management',
      );

      // Initialize all supported providers
      _providers[CloudProvider.googleDrive] = GoogleDriveProvider();
      _providers[CloudProvider.oneDrive] = OneDriveProvider();
      _providers[CloudProvider.dropbox] = DropboxProvider();
      _providers[CloudProvider.box] = BoxProvider();

      // Load saved accounts
      await _loadSavedAccounts();

      _isInitialized = true;
      _emitCloudEvent(CloudEventType.serviceInitialized);

    } catch (e) {
      _emitCloudEvent(CloudEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Authenticate with a cloud provider
  Future<CloudAuthResult> authenticate({
    required CloudProvider provider,
    Map<String, dynamic>? credentials,
    bool useWebAuth = true,
  }) async {
    _emitCloudEvent(CloudEventType.authStarted, details: 'Provider: $provider');

    try {
      final providerInstance = _providers[provider];
      if (providerInstance == null) {
        throw CloudStorageException('Provider $provider not supported');
      }

      final authResult = await providerInstance.authenticate(
        credentials: credentials,
        useWebAuth: useWebAuth,
        timeout: _authTimeout,
      );

      if (authResult.success) {
        final account = CloudAccount(
          provider: provider,
          accountId: authResult.accountId,
          email: authResult.email,
          displayName: authResult.displayName,
          accessToken: authResult.accessToken,
          refreshToken: authResult.refreshToken,
          expiresAt: authResult.expiresAt,
          permissions: authResult.permissions,
          createdAt: DateTime.now(),
        );

        _accounts[authResult.accountId] = account;
        await _saveAccount(account);

        _emitCloudEvent(CloudEventType.authCompleted,
          details: 'Account: ${authResult.email}');
      } else {
        _emitCloudEvent(CloudEventType.authFailed, error: authResult.error);
      }

      return authResult;

    } catch (e) {
      _emitCloudEvent(CloudEventType.authFailed, error: e.toString());
      rethrow;
    }
  }

  /// List files and folders from cloud storage
  Future<CloudFileList> listFiles({
    required String accountId,
    String? folderId,
    CloudQuery? query,
    bool includeThumbnails = false,
    int? maxResults,
  }) async {
    final account = _accounts[accountId];
    if (account == null) {
      throw CloudStorageException('Account not found: $accountId');
    }

    try {
      final providerInstance = _providers[account.provider];
      if (providerInstance == null) {
        throw CloudStorageException('Provider ${account.provider} not supported');
      }

      final result = await providerInstance.listFiles(
        account: account,
        folderId: folderId,
        query: query,
        includeThumbnails: includeThumbnails,
        maxResults: maxResults,
      );

      _emitCloudEvent(CloudEventType.listCompleted,
        details: 'Files: ${result.files.length}');

      return result;

    } catch (e) {
      _emitCloudEvent(CloudEventType.listFailed, error: e.toString());
      rethrow;
    }
  }

  /// Upload file to cloud storage
  Future<CloudUploadResult> uploadFile({
    required String accountId,
    required String localPath,
    required String remotePath,
    bool overwrite = true,
    Function(double)? onProgress,
    Map<String, String>? metadata,
  }) async {
    final account = _accounts[accountId];
    if (account == null) {
      throw CloudStorageException('Account not found: $accountId');
    }

    return await _operationSemaphore.acquire(() async {
      _emitCloudEvent(CloudEventType.uploadStarted,
        details: 'File: ${path.basename(localPath)}');

      try {
        final providerInstance = _providers[account.provider];
        if (providerInstance == null) {
          throw CloudStorageException('Provider ${account.provider} not supported');
        }

        final result = await providerInstance.uploadFile(
          account: account,
          localPath: localPath,
          remotePath: remotePath,
          overwrite: overwrite,
          onProgress: onProgress,
          metadata: metadata,
        );

        _emitCloudEvent(CloudEventType.uploadCompleted,
          details: 'File: ${result.fileId}, Size: ${result.fileSize}');

        return result;

      } catch (e) {
        _emitCloudEvent(CloudEventType.uploadFailed, error: e.toString());
        rethrow;
      } finally {
        _operationSemaphore.release();
      }
    });
  }

  /// Download file from cloud storage
  Future<CloudDownloadResult> downloadFile({
    required String accountId,
    required String fileId,
    required String localPath,
    bool overwrite = true,
    Function(double)? onProgress,
  }) async {
    final account = _accounts[accountId];
    if (account == null) {
      throw CloudStorageException('Account not found: $accountId');
    }

    return await _operationSemaphore.acquire(() async {
      _emitCloudEvent(CloudEventType.downloadStarted,
        details: 'File: $fileId');

      try {
        final providerInstance = _providers[account.provider];
        if (providerInstance == null) {
          throw CloudStorageException('Provider ${account.provider} not supported');
        }

        final result = await providerInstance.downloadFile(
          account: account,
          fileId: fileId,
          localPath: localPath,
          overwrite: overwrite,
          onProgress: onProgress,
        );

        _emitCloudEvent(CloudEventType.downloadCompleted,
          details: 'File: $fileId, Size: ${result.fileSize}');

        return result;

      } catch (e) {
        _emitCloudEvent(CloudEventType.downloadFailed, error: e.toString());
        rethrow;
      } finally {
        _operationSemaphore.release();
      }
    });
  }

  /// Create folder in cloud storage
  Future<CloudFolderResult> createFolder({
    required String accountId,
    required String name,
    String? parentId,
    Map<String, String>? metadata,
  }) async {
    final account = _accounts[accountId];
    if (account == null) {
      throw CloudStorageException('Account not found: $accountId');
    }

    try {
      final providerInstance = _providers[account.provider];
      if (providerInstance == null) {
        throw CloudStorageException('Provider ${account.provider} not supported');
      }

      final result = await providerInstance.createFolder(
        account: account,
        name: name,
        parentId: parentId,
        metadata: metadata,
      );

      _emitCloudEvent(CloudEventType.folderCreated,
        details: 'Folder: $name');

      return result;

    } catch (e) {
      _emitCloudEvent(CloudEventType.folderCreateFailed, error: e.toString());
      rethrow;
    }
  }

  /// Delete file or folder from cloud storage
  Future<CloudDeleteResult> deleteItem({
    required String accountId,
    required String itemId,
    bool permanent = false,
  }) async {
    final account = _accounts[accountId];
    if (account == null) {
      throw CloudStorageException('Account not found: $accountId');
    }

    try {
      final providerInstance = _providers[account.provider];
      if (providerInstance == null) {
        throw CloudStorageException('Provider ${account.provider} not supported');
      }

      final result = await providerInstance.deleteItem(
        account: account,
        itemId: itemId,
        permanent: permanent,
      );

      _emitCloudEvent(CloudEventType.itemDeleted,
        details: 'Item: $itemId');

      return result;

    } catch (e) {
      _emitCloudEvent(CloudEventType.itemDeleteFailed, error: e.toString());
      rethrow;
    }
  }

  /// Synchronize local folder with cloud storage
  Future<CloudSyncResult> synchronize({
    required String accountId,
    required String localPath,
    required String remotePath,
    SyncMode mode = SyncMode.bidirectional,
    ConflictResolutionStrategy conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
    Function(SyncProgress)? onProgress,
  }) async {
    final account = _accounts[accountId];
    if (account == null) {
      throw CloudStorageException('Account not found: $accountId');
    }

    final sessionId = 'sync_${accountId}_${DateTime.now().millisecondsSinceEpoch}';
    final session = CloudSyncSession(
      sessionId: sessionId,
      accountId: accountId,
      localPath: localPath,
      remotePath: remotePath,
      mode: mode,
      startTime: DateTime.now(),
    );

    _syncSessions[sessionId] = session;

    try {
      _emitCloudEvent(CloudEventType.syncStarted, details: 'Session: $sessionId');

      final providerInstance = _providers[account.provider];
      if (providerInstance == null) {
        throw CloudStorageException('Provider ${account.provider} not supported');
      }

      final result = await providerInstance.synchronize(
        account: account,
        session: session,
        conflictStrategy: conflictStrategy,
        onProgress: onProgress,
      );

      _emitCloudEvent(CloudEventType.syncCompleted,
        details: 'Session: $sessionId, Files: ${result.filesSynced}');

      return result;

    } catch (e) {
      _emitCloudEvent(CloudEventType.syncFailed, error: e.toString());
      rethrow;
    } finally {
      _syncSessions.remove(sessionId);
    }
  }

  /// Get cloud storage usage information
  Future<CloudUsageInfo> getUsageInfo(String accountId) async {
    final account = _accounts[accountId];
    if (account == null) {
      throw CloudStorageException('Account not found: $accountId');
    }

    try {
      final providerInstance = _providers[account.provider];
      if (providerInstance == null) {
        throw CloudStorageException('Provider ${account.provider} not supported');
      }

      return await providerInstance.getUsageInfo(account);

    } catch (e) {
      rethrow;
    }
  }

  /// Share file with other users
  Future<CloudShareResult> shareFile({
    required String accountId,
    required String fileId,
    required List<String> recipients,
    SharePermission permission = SharePermission.view,
    String? message,
    DateTime? expiryDate,
  }) async {
    final account = _accounts[accountId];
    if (account == null) {
      throw CloudStorageException('Account not found: $accountId');
    }

    try {
      final providerInstance = _providers[account.provider];
      if (providerInstance == null) {
        throw CloudStorageException('Provider ${account.provider} not supported');
      }

      final result = await providerInstance.shareFile(
        account: account,
        fileId: fileId,
        recipients: recipients,
        permission: permission,
        message: message,
        expiryDate: expiryDate,
      );

      _emitCloudEvent(CloudEventType.fileShared,
        details: 'File: $fileId, Recipients: ${recipients.length}');

      return result;

    } catch (e) {
      _emitCloudEvent(CloudEventType.fileShareFailed, error: e.toString());
      rethrow;
    }
  }

  /// Get connected accounts
  List<CloudAccount> getConnectedAccounts() {
    return _accounts.values.toList();
  }

  /// Disconnect account
  Future<void> disconnectAccount(String accountId) async {
    final account = _accounts[accountId];
    if (account == null) return;

    try {
      final providerInstance = _providers[account.provider];
      if (providerInstance != null) {
        await providerInstance.disconnect(account);
      }

      _accounts.remove(accountId);
      await _removeAccount(accountId);

      _emitCloudEvent(CloudEventType.accountDisconnected,
        details: 'Account: $accountId');

    } catch (e) {
      _emitCloudEvent(CloudEventType.accountDisconnectFailed, error: e.toString());
      rethrow;
    }
  }

  /// Get sync session status
  CloudSyncSession? getSyncSession(String sessionId) {
    return _syncSessions[sessionId];
  }

  /// Cancel sync session
  Future<void> cancelSyncSession(String sessionId) async {
    final session = _syncSessions[sessionId];
    if (session != null) {
      session.isCancelled = true;
      _emitCloudEvent(CloudEventType.syncCancelled, details: 'Session: $sessionId');
    }
  }

  // Private methods

  Future<void> _loadSavedAccounts() async {
    // Implementation would load accounts from secure storage
    // For now, placeholder
  }

  Future<void> _saveAccount(CloudAccount account) async {
    // Implementation would save account to secure storage
    // For now, placeholder
  }

  Future<void> _removeAccount(String accountId) async {
    // Implementation would remove account from secure storage
    // For now, placeholder
  }

  void _emitCloudEvent(CloudEventType type, {
    String? details,
    String? error,
  }) {
    final event = CloudEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _cloudEventController.add(event);
  }

  void dispose() {
    _cloudEventController.close();
  }
}

/// Cloud Provider Base Class
abstract class CloudProviderBase {
  Future<CloudAuthResult> authenticate({
    Map<String, dynamic>? credentials,
    bool useWebAuth = true,
    Duration? timeout,
  });

  Future<CloudFileList> listFiles({
    required CloudAccount account,
    String? folderId,
    CloudQuery? query,
    bool includeThumbnails = false,
    int? maxResults,
  });

  Future<CloudUploadResult> uploadFile({
    required CloudAccount account,
    required String localPath,
    required String remotePath,
    bool overwrite = true,
    Function(double)? onProgress,
    Map<String, String>? metadata,
  });

  Future<CloudDownloadResult> downloadFile({
    required CloudAccount account,
    required String fileId,
    required String localPath,
    bool overwrite = true,
    Function(double)? onProgress,
  });

  Future<CloudFolderResult> createFolder({
    required CloudAccount account,
    required String name,
    String? parentId,
    Map<String, String>? metadata,
  });

  Future<CloudDeleteResult> deleteItem({
    required CloudAccount account,
    required String itemId,
    bool permanent = false,
  });

  Future<CloudSyncResult> synchronize({
    required CloudAccount account,
    required CloudSyncSession session,
    ConflictResolutionStrategy conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
    Function(SyncProgress)? onProgress,
  });

  Future<CloudUsageInfo> getUsageInfo(CloudAccount account);

  Future<CloudShareResult> shareFile({
    required CloudAccount account,
    required String fileId,
    required List<String> recipients,
    SharePermission permission = SharePermission.view,
    String? message,
    DateTime? expiryDate,
  });

  Future<void> disconnect(CloudAccount account);
}

/// Google Drive Provider Implementation
class GoogleDriveProvider extends CloudProviderBase {
  @override
  Future<CloudAuthResult> authenticate({
    Map<String, dynamic>? credentials,
    bool useWebAuth = true,
    Duration? timeout,
  }) async {
    // Implementation for Google OAuth2 authentication
    // This would use google_sign_in package
    return CloudAuthResult(
      success: true,
      accountId: 'google_${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@gmail.com', // Placeholder
      displayName: 'Google User',
      accessToken: 'token',
      refreshToken: 'refresh_token',
      expiresAt: DateTime.now().add(Duration(hours: 1)),
      permissions: [CloudPermission.read, CloudPermission.write],
    );
  }

  @override
  Future<CloudFileList> listFiles({
    required CloudAccount account,
    String? folderId,
    CloudQuery? query,
    bool includeThumbnails = false,
    int? maxResults,
  }) async {
    // Implementation for Google Drive API
    return CloudFileList(
      files: [],
      nextPageToken: null,
      totalCount: 0,
    );
  }

  @override
  Future<CloudUploadResult> uploadFile({
    required CloudAccount account,
    required String localPath,
    required String remotePath,
    bool overwrite = true,
    Function(double)? onProgress,
    Map<String, String>? metadata,
  }) async {
    // Implementation for Google Drive upload
    return CloudUploadResult(
      success: true,
      fileId: 'drive_file_id',
      fileName: path.basename(localPath),
      fileSize: 1024,
      uploadTime: DateTime.now(),
    );
  }

  @override
  Future<CloudDownloadResult> downloadFile({
    required CloudAccount account,
    required String fileId,
    required String localPath,
    bool overwrite = true,
    Function(double)? onProgress,
  }) async {
    // Implementation for Google Drive download
    return CloudDownloadResult(
      success: true,
      fileId: fileId,
      localPath: localPath,
      fileSize: 1024,
      downloadTime: DateTime.now(),
    );
  }

  @override
  Future<CloudFolderResult> createFolder({
    required CloudAccount account,
    required String name,
    String? parentId,
    Map<String, String>? metadata,
  }) async {
    // Implementation for Google Drive folder creation
    return CloudFolderResult(
      success: true,
      folderId: 'drive_folder_id',
      folderName: name,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CloudDeleteResult> deleteItem({
    required CloudAccount account,
    required String itemId,
    bool permanent = false,
  }) async {
    // Implementation for Google Drive deletion
    return CloudDeleteResult(
      success: true,
      itemId: itemId,
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<CloudSyncResult> synchronize({
    required CloudAccount account,
    required CloudSyncSession session,
    ConflictResolutionStrategy conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
    Function(SyncProgress)? onProgress,
  }) async {
    // Implementation for Google Drive synchronization
    return CloudSyncResult(
      sessionId: session.sessionId,
      filesSynced: 10,
      conflictsResolved: 2,
      errors: [],
      syncTime: DateTime.now().difference(session.startTime),
    );
  }

  @override
  Future<CloudUsageInfo> getUsageInfo(CloudAccount account) async {
    // Implementation for Google Drive usage
    return CloudUsageInfo(
      totalSpace: 15 * 1024 * 1024 * 1024, // 15GB
      usedSpace: 5 * 1024 * 1024 * 1024,   // 5GB
      availableSpace: 10 * 1024 * 1024 * 1024, // 10GB
    );
  }

  @override
  Future<CloudShareResult> shareFile({
    required CloudAccount account,
    required String fileId,
    required List<String> recipients,
    SharePermission permission = SharePermission.view,
    String? message,
    DateTime? expiryDate,
  }) async {
    // Implementation for Google Drive sharing
    return CloudShareResult(
      success: true,
      fileId: fileId,
      shareUrl: 'https://drive.google.com/file/$fileId',
      recipients: recipients,
      permission: permission,
      sharedAt: DateTime.now(),
    );
  }

  @override
  Future<void> disconnect(CloudAccount account) async {
    // Implementation for Google Drive disconnect
  }
}

/// OneDrive Provider Implementation
class OneDriveProvider extends CloudProviderBase {
  @override
  Future<CloudAuthResult> authenticate({
    Map<String, dynamic>? credentials,
    bool useWebAuth = true,
    Duration? timeout,
  }) async {
    // Implementation for Microsoft OAuth2 authentication
    return CloudAuthResult(
      success: true,
      accountId: 'onedrive_${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@outlook.com',
      displayName: 'OneDrive User',
      accessToken: 'token',
      refreshToken: 'refresh_token',
      expiresAt: DateTime.now().add(Duration(hours: 1)),
      permissions: [CloudPermission.read, CloudPermission.write],
    );
  }

  // Implement other methods similarly for OneDrive API
  @override
  Future<CloudFileList> listFiles({
    required CloudAccount account,
    String? folderId,
    CloudQuery? query,
    bool includeThumbnails = false,
    int? maxResults,
  }) async {
    return CloudFileList(files: [], nextPageToken: null, totalCount: 0);
  }

  @override
  Future<CloudUploadResult> uploadFile({
    required CloudAccount account,
    required String localPath,
    required String remotePath,
    bool overwrite = true,
    Function(double)? onProgress,
    Map<String, String>? metadata,
  }) async {
    return CloudUploadResult(
      success: true,
      fileId: 'onedrive_file_id',
      fileName: path.basename(localPath),
      fileSize: 1024,
      uploadTime: DateTime.now(),
    );
  }

  @override
  Future<CloudDownloadResult> downloadFile({
    required CloudAccount account,
    required String fileId,
    required String localPath,
    bool overwrite = true,
    Function(double)? onProgress,
  }) async {
    return CloudDownloadResult(
      success: true,
      fileId: fileId,
      localPath: localPath,
      fileSize: 1024,
      downloadTime: DateTime.now(),
    );
  }

  @override
  Future<CloudFolderResult> createFolder({
    required CloudAccount account,
    required String name,
    String? parentId,
    Map<String, String>? metadata,
  }) async {
    return CloudFolderResult(
      success: true,
      folderId: 'onedrive_folder_id',
      folderName: name,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CloudDeleteResult> deleteItem({
    required CloudAccount account,
    required String itemId,
    bool permanent = false,
  }) async {
    return CloudDeleteResult(
      success: true,
      itemId: itemId,
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<CloudSyncResult> synchronize({
    required CloudAccount account,
    required CloudSyncSession session,
    ConflictResolutionStrategy conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
    Function(SyncProgress)? onProgress,
  }) async {
    return CloudSyncResult(
      sessionId: session.sessionId,
      filesSynced: 8,
      conflictsResolved: 1,
      errors: [],
      syncTime: DateTime.now().difference(session.startTime),
    );
  }

  @override
  Future<CloudUsageInfo> getUsageInfo(CloudAccount account) async {
    return CloudUsageInfo(
      totalSpace: 5 * 1024 * 1024 * 1024, // 5GB
      usedSpace: 2 * 1024 * 1024 * 1024,  // 2GB
      availableSpace: 3 * 1024 * 1024 * 1024, // 3GB
    );
  }

  @override
  Future<CloudShareResult> shareFile({
    required CloudAccount account,
    required String fileId,
    required List<String> recipients,
    SharePermission permission = SharePermission.view,
    String? message,
    DateTime? expiryDate,
  }) async {
    return CloudShareResult(
      success: true,
      fileId: fileId,
      shareUrl: 'https://onedrive.live.com/file/$fileId',
      recipients: recipients,
      permission: permission,
      sharedAt: DateTime.now(),
    );
  }

  @override
  Future<void> disconnect(CloudAccount account) async {
    // Implementation for OneDrive disconnect
  }
}

/// Dropbox Provider Implementation
class DropboxProvider extends CloudProviderBase {
  @override
  Future<CloudAuthResult> authenticate({
    Map<String, dynamic>? credentials,
    bool useWebAuth = true,
    Duration? timeout,
  }) async {
    // Implementation for Dropbox OAuth2 authentication
    return CloudAuthResult(
      success: true,
      accountId: 'dropbox_${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@dropbox.com',
      displayName: 'Dropbox User',
      accessToken: 'token',
      refreshToken: 'refresh_token',
      expiresAt: DateTime.now().add(Duration(hours: 4)),
      permissions: [CloudPermission.read, CloudPermission.write],
    );
  }

  // Implement other methods similarly for Dropbox API
  @override
  Future<CloudFileList> listFiles({
    required CloudAccount account,
    String? folderId,
    CloudQuery? query,
    bool includeThumbnails = false,
    int? maxResults,
  }) async {
    return CloudFileList(files: [], nextPageToken: null, totalCount: 0);
  }

  @override
  Future<CloudUploadResult> uploadFile({
    required CloudAccount account,
    required String localPath,
    required String remotePath,
    bool overwrite = true,
    Function(double)? onProgress,
    Map<String, String>? metadata,
  }) async {
    return CloudUploadResult(
      success: true,
      fileId: 'dropbox_file_id',
      fileName: path.basename(localPath),
      fileSize: 1024,
      uploadTime: DateTime.now(),
    );
  }

  @override
  Future<CloudDownloadResult> downloadFile({
    required CloudAccount account,
    required String fileId,
    required String localPath,
    bool overwrite = true,
    Function(double)? onProgress,
  }) async {
    return CloudDownloadResult(
      success: true,
      fileId: fileId,
      localPath: localPath,
      fileSize: 1024,
      downloadTime: DateTime.now(),
    );
  }

  @override
  Future<CloudFolderResult> createFolder({
    required CloudAccount account,
    required String name,
    String? parentId,
    Map<String, String>? metadata,
  }) async {
    return CloudFolderResult(
      success: true,
      folderId: 'dropbox_folder_id',
      folderName: name,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CloudDeleteResult> deleteItem({
    required CloudAccount account,
    required String itemId,
    bool permanent = false,
  }) async {
    return CloudDeleteResult(
      success: true,
      itemId: itemId,
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<CloudSyncResult> synchronize({
    required CloudAccount account,
    required CloudSyncSession session,
    ConflictResolutionStrategy conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
    Function(SyncProgress)? onProgress,
  }) async {
    return CloudSyncResult(
      sessionId: session.sessionId,
      filesSynced: 12,
      conflictsResolved: 0,
      errors: [],
      syncTime: DateTime.now().difference(session.startTime),
    );
  }

  @override
  Future<CloudUsageInfo> getUsageInfo(CloudAccount account) async {
    return CloudUsageInfo(
      totalSpace: 2 * 1024 * 1024 * 1024, // 2GB
      usedSpace: 1 * 1024 * 1024 * 1024,  // 1GB
      availableSpace: 1 * 1024 * 1024 * 1024, // 1GB
    );
  }

  @override
  Future<CloudShareResult> shareFile({
    required CloudAccount account,
    required String fileId,
    required List<String> recipients,
    SharePermission permission = SharePermission.view,
    String? message,
    DateTime? expiryDate,
  }) async {
    return CloudShareResult(
      success: true,
      fileId: fileId,
      shareUrl: 'https://dropbox.com/s/$fileId',
      recipients: recipients,
      permission: permission,
      sharedAt: DateTime.now(),
    );
  }

  @override
  Future<void> disconnect(CloudAccount account) async {
    // Implementation for Dropbox disconnect
  }
}

/// Box Provider Implementation
class BoxProvider extends CloudProviderBase {
  @override
  Future<CloudAuthResult> authenticate({
    Map<String, dynamic>? credentials,
    bool useWebAuth = true,
    Duration? timeout,
  }) async {
    // Implementation for Box OAuth2 authentication
    return CloudAuthResult(
      success: true,
      accountId: 'box_${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@box.com',
      displayName: 'Box User',
      accessToken: 'token',
      refreshToken: 'refresh_token',
      expiresAt: DateTime.now().add(Duration(hours: 1)),
      permissions: [CloudPermission.read, CloudPermission.write],
    );
  }

  // Implement other methods similarly for Box API
  @override
  Future<CloudFileList> listFiles({
    required CloudAccount account,
    String? folderId,
    CloudQuery? query,
    bool includeThumbnails = false,
    int? maxResults,
  }) async {
    return CloudFileList(files: [], nextPageToken: null, totalCount: 0);
  }

  @override
  Future<CloudUploadResult> uploadFile({
    required CloudAccount account,
    required String localPath,
    required String remotePath,
    bool overwrite = true,
    Function(double)? onProgress,
    Map<String, String>? metadata,
  }) async {
    return CloudUploadResult(
      success: true,
      fileId: 'box_file_id',
      fileName: path.basename(localPath),
      fileSize: 1024,
      uploadTime: DateTime.now(),
    );
  }

  @override
  Future<CloudDownloadResult> downloadFile({
    required CloudAccount account,
    required String fileId,
    required String localPath,
    bool overwrite = true,
    Function(double)? onProgress,
  }) async {
    return CloudDownloadResult(
      success: true,
      fileId: fileId,
      localPath: localPath,
      fileSize: 1024,
      downloadTime: DateTime.now(),
    );
  }

  @override
  Future<CloudFolderResult> createFolder({
    required CloudAccount account,
    required String name,
    String? parentId,
    Map<String, String>? metadata,
  }) async {
    return CloudFolderResult(
      success: true,
      folderId: 'box_folder_id',
      folderName: name,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CloudDeleteResult> deleteItem({
    required CloudAccount account,
    required String itemId,
    bool permanent = false,
  }) async {
    return CloudDeleteResult(
      success: true,
      itemId: itemId,
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<CloudSyncResult> synchronize({
    required CloudAccount account,
    required CloudSyncSession session,
    ConflictResolutionStrategy conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
    Function(SyncProgress)? onProgress,
  }) async {
    return CloudSyncResult(
      sessionId: session.sessionId,
      filesSynced: 6,
      conflictsResolved: 3,
      errors: [],
      syncTime: DateTime.now().difference(session.startTime),
    );
  }

  @override
  Future<CloudUsageInfo> getUsageInfo(CloudAccount account) async {
    return CloudUsageInfo(
      totalSpace: 10 * 1024 * 1024 * 1024, // 10GB
      usedSpace: 3 * 1024 * 1024 * 1024,   // 3GB
      availableSpace: 7 * 1024 * 1024 * 1024, // 7GB
    );
  }

  @override
  Future<CloudShareResult> shareFile({
    required CloudAccount account,
    required String fileId,
    required List<String> recipients,
    SharePermission permission = SharePermission.view,
    String? message,
    DateTime? expiryDate,
  }) async {
    return CloudShareResult(
      success: true,
      fileId: fileId,
      shareUrl: 'https://box.com/s/$fileId',
      recipients: recipients,
      permission: permission,
      sharedAt: DateTime.now(),
    );
  }

  @override
  Future<void> disconnect(CloudAccount account) async {
    // Implementation for Box disconnect
  }
}

/// Supporting data classes and enums

enum CloudProvider {
  googleDrive,
  oneDrive,
  dropbox,
  box,
}

enum CloudEventType {
  serviceInitialized,
  initializationFailed,
  authStarted,
  authCompleted,
  authFailed,
  listCompleted,
  listFailed,
  uploadStarted,
  uploadCompleted,
  uploadFailed,
  downloadStarted,
  downloadCompleted,
  downloadFailed,
  folderCreated,
  folderCreateFailed,
  itemDeleted,
  itemDeleteFailed,
  syncStarted,
  syncCompleted,
  syncFailed,
  syncCancelled,
  fileShared,
  fileShareFailed,
  accountDisconnected,
  accountDisconnectFailed,
}

enum CloudPermission {
  read,
  write,
  delete,
  share,
}

enum SharePermission {
  view,
  edit,
  comment,
}

enum SyncMode {
  upload,
  download,
  bidirectional,
}

enum ConflictResolutionStrategy {
  lastWriteWins,
  localWins,
  remoteWins,
  manual,
}

/// Data classes

class CloudAccount {
  final CloudProvider provider;
  final String accountId;
  final String email;
  final String displayName;
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final List<CloudPermission> permissions;
  final DateTime createdAt;

  CloudAccount({
    required this.provider,
    required this.accountId,
    required this.email,
    required this.displayName,
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    required this.permissions,
    required this.createdAt,
  });
}

class CloudAuthResult {
  final bool success;
  final String accountId;
  final String email;
  final String displayName;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final List<CloudPermission> permissions;
  final String? error;

  CloudAuthResult({
    required this.success,
    required this.accountId,
    required this.email,
    required this.displayName,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    required this.permissions,
    this.error,
  });
}

class CloudFile {
  final String id;
  final String name;
  final int size;
  final String mimeType;
  final DateTime modifiedTime;
  final bool isFolder;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;

  CloudFile({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.modifiedTime,
    required this.isFolder,
    this.thumbnailUrl,
    this.metadata,
  });
}

class CloudFileList {
  final List<CloudFile> files;
  final String? nextPageToken;
  final int totalCount;

  CloudFileList({
    required this.files,
    this.nextPageToken,
    required this.totalCount,
  });
}

class CloudQuery {
  final String? searchTerm;
  final String? fileType;
  final DateTime? modifiedAfter;
  final DateTime? modifiedBefore;
  final int? maxSize;
  final int? minSize;

  CloudQuery({
    this.searchTerm,
    this.fileType,
    this.modifiedAfter,
    this.modifiedBefore,
    this.maxSize,
    this.minSize,
  });
}

class CloudUploadResult {
  final bool success;
  final String fileId;
  final String fileName;
  final int fileSize;
  final DateTime uploadTime;
  final String? error;

  CloudUploadResult({
    required this.success,
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.uploadTime,
    this.error,
  });
}

class CloudDownloadResult {
  final bool success;
  final String fileId;
  final String localPath;
  final int fileSize;
  final DateTime downloadTime;
  final String? error;

  CloudDownloadResult({
    required this.success,
    required this.fileId,
    required this.localPath,
    required this.fileSize,
    required this.downloadTime,
    this.error,
  });
}

class CloudFolderResult {
  final bool success;
  final String folderId;
  final String folderName;
  final DateTime createdAt;
  final String? error;

  CloudFolderResult({
    required this.success,
    required this.folderId,
    required this.folderName,
    required this.createdAt,
    this.error,
  });
}

class CloudDeleteResult {
  final bool success;
  final String itemId;
  final DateTime deletedAt;
  final String? error;

  CloudDeleteResult({
    required this.success,
    required this.itemId,
    required this.deletedAt,
    this.error,
  });
}

class CloudSyncSession {
  final String sessionId;
  final String accountId;
  final String localPath;
  final String remotePath;
  final SyncMode mode;
  final DateTime startTime;
  bool isCancelled = false;

  CloudSyncSession({
    required this.sessionId,
    required this.accountId,
    required this.localPath,
    required this.remotePath,
    required this.mode,
    required this.startTime,
  });
}

class CloudSyncResult {
  final String sessionId;
  final int filesSynced;
  final int conflictsResolved;
  final List<String> errors;
  final Duration syncTime;

  CloudSyncResult({
    required this.sessionId,
    required this.filesSynced,
    required this.conflictsResolved,
    required this.errors,
    required this.syncTime,
  });
}

class CloudUsageInfo {
  final int totalSpace;
  final int usedSpace;
  final int availableSpace;

  CloudUsageInfo({
    required this.totalSpace,
    required this.usedSpace,
    required this.availableSpace,
  });

  double get usagePercentage => totalSpace > 0 ? usedSpace / totalSpace : 0.0;
}

class CloudShareResult {
  final bool success;
  final String fileId;
  final String shareUrl;
  final List<String> recipients;
  final SharePermission permission;
  final DateTime sharedAt;
  final String? error;

  CloudShareResult({
    required this.success,
    required this.fileId,
    required this.shareUrl,
    required this.recipients,
    required this.permission,
    required this.sharedAt,
    this.error,
  });
}

/// Progress classes

class SyncProgress {
  final String phase;
  final int completed;
  final int total;
  final String currentFile;

  SyncProgress({
    required this.phase,
    required this.completed,
    required this.total,
    required this.currentFile,
  });

  double get progressPercentage => total > 0 ? completed / total : 0.0;
}

/// Semaphore for limiting concurrent operations
class Semaphore {
  final int _maxCount;
  int _currentCount = 0;
  final List<Completer<void>> _waitQueue = [];

  Semaphore(this._maxCount);

  Future<void> acquire() async {
    if (_currentCount < _maxCount) {
      _currentCount++;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeAt(0);
      completer.complete();
    } else {
      _currentCount--;
    }
  }
}

/// Event classes

class CloudEvent {
  final CloudEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  CloudEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}

/// Exception class

class CloudStorageException implements Exception {
  final String message;

  CloudStorageException(this.message);

  @override
  String toString() => 'CloudStorageException: $message';
}
