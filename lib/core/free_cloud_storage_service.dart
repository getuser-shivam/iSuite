import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../config/central_config.dart';
import 'logging_service.dart';

/// Free Cloud Storage Service for iSuite
/// Provides access to FREE cloud storage options - no paid accounts required!
/// Supports multiple free cloud storage providers with generous free tiers
class FreeCloudStorageService {
  static final FreeCloudStorageService _instance = FreeCloudStorageService._internal();
  factory FreeCloudStorageService() => _instance;

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();

  // Free cloud storage providers
  static const Map<CloudProvider, Map<String, dynamic>> _freeProviders = {
    CloudProvider.github: {
      'name': 'GitHub',
      'free_tier_gb': 500, // GitHub Packages/LFS has limits
      'max_file_size_mb': 100,
      'api_docs': 'https://docs.github.com/en/rest',
      'free_features': ['public_repos', 'releases', 'pages'],
    },
    CloudProvider.gitlab: {
      'name': 'GitLab',
      'free_tier_gb': 10, // GitLab has 10GB free storage
      'max_file_size_mb': 100,
      'api_docs': 'https://docs.gitlab.com/ee/api/',
      'free_features': ['repos', 'ci_cd', 'pages'],
    },
    CloudProvider.dropbox: {
      'name': 'Dropbox',
      'free_tier_gb': 2, // 2GB free
      'max_file_size_mb': 100,
      'api_docs': 'https://www.dropbox.com/developers/documentation',
      'free_features': ['file_sync', 'sharing', 'versioning'],
    },
    CloudProvider.googledrive: {
      'name': 'Google Drive',
      'free_tier_gb': 15, // 15GB free
      'max_file_size_mb': 100,
      'api_docs': 'https://developers.google.com/drive/api',
      'free_features': ['docs', 'sheets', 'slides', 'photos'],
    },
    CloudProvider.onedrive: {
      'name': 'OneDrive',
      'free_tier_gb': 5, // 5GB free
      'max_file_size_mb': 100,
      'api_docs': 'https://docs.microsoft.com/en-us/onedrive/developer/',
      'free_features': ['office_online', 'sharing', 'sync'],
    },
    CloudProvider.box: {
      'name': 'Box',
      'free_tier_gb': 10, // 10GB free
      'max_file_size_mb': 250,
      'api_docs': 'https://developer.box.com/',
      'free_features': ['collaboration', 'workflow', 'security'],
    },
    CloudProvider.mediafire: {
      'name': 'MediaFire',
      'free_tier_gb': 10, // 10GB free
      'max_file_size_mb': 2000, // 2GB per file
      'api_docs': 'https://www.mediafire.com/developers/',
      'free_features': ['file_sharing', 'remote_upload'],
    },
    CloudProvider.mega: {
      'name': 'MEGA',
      'free_tier_gb': 20, // 20GB free
      'max_file_size_mb': 5000, // 5GB per file
      'api_docs': 'https://mega.nz/developers',
      'free_features': ['end_to_end_encryption', 'file_sharing'],
    },
  };

  // Active provider and settings
  CloudProvider _activeProvider = CloudProvider.dropbox; // Default to Dropbox (simple API)
  bool _isInitialized = false;
  final Map<String, dynamic> _providerConfigs = {};

  // Upload/download tracking
  final Map<String, CloudOperation> _activeOperations = {};
  final StreamController<CloudEvent> _cloudEventController = StreamController.broadcast();

  Stream<CloudEvent> get cloudEvents => _cloudEventController.stream;

  FreeCloudStorageService._internal();

  /// Initialize free cloud storage service
  Future<void> initialize({CloudProvider? preferredProvider}) async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent(
        'FreeCloudStorageService',
        '1.0.0',
        'Free cloud storage service supporting multiple providers with generous free tiers',
        dependencies: ['CentralConfig', 'LoggingService'],
        parameters: {
          // Provider selection
          'cloud.provider.active': (preferredProvider ?? CloudProvider.dropbox).toString().split('.').last,
          'cloud.provider.fallback_enabled': true,

          // Storage settings
          'cloud.storage.auto_backup_enabled': false,
          'cloud.storage.compression_enabled': true,
          'cloud.storage.encryption_enabled': false,

          // Upload settings
          'cloud.upload.chunk_size_mb': 5,
          'cloud.upload.max_concurrent': 3,
          'cloud.upload.retry_attempts': 3,

          // Sync settings
          'cloud.sync.auto_sync_enabled': false,
          'cloud.sync.conflict_strategy': 'rename', // rename, overwrite, skip
          'cloud.sync.bandwidth_limit_kb': 0, // 0 = unlimited

          // Free tier optimizations
          'cloud.free_tier.optimize_for_free': true,
          'cloud.free_tier.auto_cleanup_enabled': false,
          'cloud.free_tier.usage_warnings_enabled': true,

          // Provider-specific settings
          'cloud.dropbox.app_key': '', // User needs to provide
          'cloud.dropbox.app_secret': '',
          'cloud.github.token': '',
          'cloud.gitlab.token': '',
        }
      );

      // Get active provider from config
      final configProvider = await _config.getParameter<String>('cloud.provider.active', defaultValue: 'dropbox');
      _activeProvider = CloudProvider.values.firstWhere(
        (provider) => provider.toString().split('.').last == configProvider,
        orElse: () => CloudProvider.dropbox,
      );

      // Load provider configurations
      await _loadProviderConfigs();

      _isInitialized = true;
      _emitCloudEvent(CloudEventType.initialized);

      _logger.info('Free Cloud Storage Service initialized with ${_activeProvider.name} provider', 'FreeCloudStorageService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Free Cloud Storage Service', 'FreeCloudStorageService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Upload file to free cloud storage
  Future<CloudUploadResult> uploadFile(
    String localFilePath, {
    String? remotePath,
    bool encrypt = false,
    Map<String, String>? metadata,
    void Function(double)? onProgress,
  }) async {
    if (!_isInitialized) throw StateError('Cloud storage service not initialized');

    final file = File(localFilePath);
    if (!await file.exists()) {
      throw Exception('Local file does not exist: $localFilePath');
    }

    final fileSize = await file.length();
    final maxSize = (_freeProviders[_activeProvider]?['max_file_size_mb'] ?? 100) * 1024 * 1024;

    if (fileSize > maxSize) {
      throw Exception('File too large: ${fileSize ~/ (1024 * 1024)}MB (max: ${maxSize ~/ (1024 * 1024)}MB for ${_activeProvider.name})');
    }

    final operationId = _generateOperationId();
    final operation = CloudOperation(
      id: operationId,
      type: CloudOperationType.upload,
      localPath: localFilePath,
      remotePath: remotePath ?? path.basename(localFilePath),
      fileSize: fileSize,
      startTime: DateTime.now(),
    );

    _activeOperations[operationId] = operation;
    _emitCloudEvent(CloudEventType.uploadStarted, data: {'operation_id': operationId, 'file': localFilePath});

    try {
      String? resultUrl;

      switch (_activeProvider) {
        case CloudProvider.dropbox:
          resultUrl = await _uploadToDropbox(file, remotePath, onProgress);
          break;
        case CloudProvider.github:
          resultUrl = await _uploadToGitHub(file, remotePath, onProgress);
          break;
        case CloudProvider.gitlab:
          resultUrl = await _uploadToGitLab(file, remotePath, onProgress);
          break;
        case CloudProvider.googledrive:
          resultUrl = await _uploadToGoogleDrive(file, remotePath, onProgress);
          break;
        case CloudProvider.onedrive:
          resultUrl = await _uploadToOneDrive(file, remotePath, onProgress);
          break;
        default:
          throw Exception('Upload not implemented for ${_activeProvider.name}');
      }

      operation.endTime = DateTime.now();
      operation.status = CloudOperationStatus.completed;

      final result = CloudUploadResult(
        success: true,
        operationId: operationId,
        fileUrl: resultUrl,
        fileSize: fileSize,
        uploadTime: operation.endTime!.difference(operation.startTime),
        provider: _activeProvider,
      );

      _emitCloudEvent(CloudEventType.uploadCompleted, data: {'operation_id': operationId, 'url': resultUrl});
      _logger.info('File uploaded successfully to ${_activeProvider.name}: $localFilePath', 'FreeCloudStorageService');

      return result;

    } catch (e) {
      operation.endTime = DateTime.now();
      operation.status = CloudOperationStatus.failed;
      operation.error = e.toString();

      _emitCloudEvent(CloudEventType.uploadFailed, data: {'operation_id': operationId, 'error': e.toString()});
      _logger.error('File upload failed: $localFilePath', 'FreeCloudStorageService', error: e);

      return CloudUploadResult(
        success: false,
        operationId: operationId,
        error: e.toString(),
        provider: _activeProvider,
      );
    } finally {
      _activeOperations.remove(operationId);
    }
  }

  /// Download file from free cloud storage
  Future<CloudDownloadResult> downloadFile(
    String remotePath,
    String localPath, {
    void Function(double)? onProgress,
  }) async {
    if (!_isInitialized) throw StateError('Cloud storage service not initialized');

    final operationId = _generateOperationId();
    final operation = CloudOperation(
      id: operationId,
      type: CloudOperationType.download,
      remotePath: remotePath,
      localPath: localPath,
      startTime: DateTime.now(),
    );

    _activeOperations[operationId] = operation;
    _emitCloudEvent(CloudEventType.downloadStarted, data: {'operation_id': operationId, 'remote_path': remotePath});

    try {
      int bytesDownloaded = 0;

      switch (_activeProvider) {
        case CloudProvider.dropbox:
          bytesDownloaded = await _downloadFromDropbox(remotePath, localPath, onProgress);
          break;
        case CloudProvider.github:
          bytesDownloaded = await _downloadFromGitHub(remotePath, localPath, onProgress);
          break;
        case CloudProvider.gitlab:
          bytesDownloaded = await _downloadFromGitLab(remotePath, localPath, onProgress);
          break;
        case CloudProvider.googledrive:
          bytesDownloaded = await _downloadFromGoogleDrive(remotePath, localPath, onProgress);
          break;
        case CloudProvider.onedrive:
          bytesDownloaded = await _downloadFromOneDrive(remotePath, localPath, onProgress);
          break;
        default:
          throw Exception('Download not implemented for ${_activeProvider.name}');
      }

      operation.endTime = DateTime.now();
      operation.status = CloudOperationStatus.completed;
      operation.fileSize = bytesDownloaded;

      final result = CloudDownloadResult(
        success: true,
        operationId: operationId,
        localPath: localPath,
        fileSize: bytesDownloaded,
        downloadTime: operation.endTime!.difference(operation.startTime),
        provider: _activeProvider,
      );

      _emitCloudEvent(CloudEventType.downloadCompleted, data: {'operation_id': operationId, 'local_path': localPath});
      _logger.info('File downloaded successfully from ${_activeProvider.name}: $remotePath', 'FreeCloudStorageService');

      return result;

    } catch (e) {
      operation.endTime = DateTime.now();
      operation.status = CloudOperationStatus.failed;
      operation.error = e.toString();

      _emitCloudEvent(CloudEventType.downloadFailed, data: {'operation_id': operationId, 'error': e.toString()});
      _logger.error('File download failed: $remotePath', 'FreeCloudStorageService', error: e);

      return CloudDownloadResult(
        success: false,
        operationId: operationId,
        error: e.toString(),
        provider: _activeProvider,
      );
    } finally {
      _activeOperations.remove(operationId);
    }
  }

  /// List files in cloud storage
  Future<List<CloudFileInfo>> listFiles({String? folderPath}) async {
    if (!_isInitialized) throw StateError('Cloud storage service not initialized');

    try {
      switch (_activeProvider) {
        case CloudProvider.dropbox:
          return await _listDropboxFiles(folderPath);
        case CloudProvider.github:
          return await _listGitHubFiles(folderPath);
        case CloudProvider.gitlab:
          return await _listGitLabFiles(folderPath);
        case CloudProvider.googledrive:
          return await _listGoogleDriveFiles(folderPath);
        case CloudProvider.onedrive:
          return await _listOneDriveFiles(folderPath);
        default:
          throw Exception('List files not implemented for ${_activeProvider.name}');
      }
    } catch (e) {
      _logger.error('Failed to list files from ${_activeProvider.name}', 'FreeCloudStorageService', error: e);
      return [];
    }
  }

  /// Delete file from cloud storage
  Future<bool> deleteFile(String remotePath) async {
    if (!_isInitialized) throw StateError('Cloud storage service not initialized');

    try {
      switch (_activeProvider) {
        case CloudProvider.dropbox:
          return await _deleteDropboxFile(remotePath);
        case CloudProvider.github:
          return await _deleteGitHubFile(remotePath);
        case CloudProvider.gitlab:
          return await _deleteGitLabFile(remotePath);
        case CloudProvider.googledrive:
          return await _deleteGoogleDriveFile(remotePath);
        case CloudProvider.onedrive:
          return await _deleteOneDriveFile(remotePath);
        default:
          throw Exception('Delete file not implemented for ${_activeProvider.name}');
      }
    } catch (e) {
      _logger.error('Failed to delete file from ${_activeProvider.name}: $remotePath', 'FreeCloudStorageService', error: e);
      return false;
    }
  }

  /// Get storage usage information
  Future<CloudStorageUsage> getStorageUsage() async {
    if (!_isInitialized) throw StateError('Cloud storage service not initialized');

    try {
      // Most free providers don't have detailed API for usage
      // Return estimated usage based on provider limits
      final providerInfo = _freeProviders[_activeProvider]!;
      final freeTierGB = providerInfo['free_tier_gb'] as int;

      return CloudStorageUsage(
        provider: _activeProvider,
        usedBytes: 0, // Unknown for free tiers
        totalBytes: freeTierGB * 1024 * 1024 * 1024,
        freeBytes: freeTierGB * 1024 * 1024 * 1024,
        lastUpdated: DateTime.now(),
        isFreeTier: true,
      );
    } catch (e) {
      _logger.error('Failed to get storage usage', 'FreeCloudStorageService', error: e);
      return CloudStorageUsage.empty(_activeProvider);
    }
  }

  /// Switch to different cloud provider
  Future<void> switchProvider(CloudProvider newProvider) async {
    if (newProvider == _activeProvider) return;

    _logger.info('Switching cloud provider from ${_activeProvider.name} to ${newProvider.name}', 'FreeCloudStorageService');

    _activeProvider = newProvider;
    await _config.setParameter('cloud.provider.active', newProvider.toString().split('.').last);

    _emitCloudEvent(CloudEventType.providerSwitched, data: {'new_provider': newProvider.name});
    _logger.info('Successfully switched to ${newProvider.name} provider', 'FreeCloudStorageService');
  }

  /// Get available free providers
  List<CloudProvider> getAvailableProviders() {
    return CloudProvider.values.where((provider) {
      final providerInfo = _freeProviders[provider];
      return providerInfo != null && (providerInfo['free_tier_gb'] as int) > 0;
    }).toList();
  }

  /// Get current active provider
  CloudProvider get activeProvider => _activeProvider;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get provider information
  Map<String, dynamic> getProviderInfo(CloudProvider provider) {
    return Map<String, dynamic>.from(_freeProviders[provider] ?? {});
  }

  /// Private helper methods

  Future<void> _loadProviderConfigs() async {
    for (final provider in CloudProvider.values) {
      final providerInfo = _freeProviders[provider];
      if (providerInfo != null) {
        _providerConfigs[provider] = providerInfo;
      }
    }
  }

  String _generateOperationId() {
    return 'cloud_op_${DateTime.now().millisecondsSinceEpoch}_${_activeOperations.length}';
  }

  // Provider-specific implementations (simplified examples)
  // In real implementation, these would use actual APIs with proper authentication

  Future<String?> _uploadToDropbox(File file, String? remotePath, void Function(double)? onProgress) async {
    // Simplified Dropbox upload using their API
    // Would require proper OAuth authentication in real implementation
    final url = 'https://content.dropboxapi.com/2/files/upload';
    final headers = {
      'Authorization': 'Bearer ${await _getAccessToken(CloudProvider.dropbox)}',
      'Content-Type': 'application/octet-stream',
      'Dropbox-API-Arg': jsonEncode({
        'path': remotePath ?? '/${path.basename(file.path)}',
        'mode': 'add',
        'autorename': true,
        'mute': false,
      }),
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: await file.readAsBytes(),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['path_display'];
    } else {
      throw Exception('Dropbox upload failed: ${response.statusCode}');
    }
  }

  Future<String?> _uploadToGitHub(File file, String? remotePath, void Function(double)? onProgress) async {
    // GitHub upload using their API
    final token = await _config.getParameter<String>('cloud.github.token');
    if (token == null || token.isEmpty) {
      throw Exception('GitHub token not configured. Get one from: https://github.com/settings/tokens');
    }

    // This would upload to a release or use GitHub's LFS
    // Simplified example
    throw Exception('GitHub upload not fully implemented - requires repository and release setup');
  }

  Future<String?> _uploadToGitLab(File file, String? remotePath, void Function(double)? onProgress) async {
    // GitLab upload using their API
    final token = await _config.getParameter<String>('cloud.gitlab.token');
    if (token == null || token.isEmpty) {
      throw Exception('GitLab token not configured. Get one from: https://gitlab.com/-/profile/personal_access_tokens');
    }

    throw Exception('GitLab upload not fully implemented - requires project setup');
  }

  Future<String?> _uploadToGoogleDrive(File file, String? remotePath, void Function(double)? onProgress) async {
    // Google Drive upload using their API
    // Would require OAuth2 authentication
    throw Exception('Google Drive upload requires OAuth2 authentication setup');
  }

  Future<String?> _uploadToOneDrive(File file, String? remotePath, void Function(double)? onProgress) async {
    // OneDrive upload using Microsoft Graph API
    // Would require OAuth2 authentication
    throw Exception('OneDrive upload requires OAuth2 authentication setup');
  }

  Future<int> _downloadFromDropbox(String remotePath, String localPath, void Function(double)? onProgress) async {
    final url = 'https://content.dropboxapi.com/2/files/download';
    final headers = {
      'Authorization': 'Bearer ${await _getAccessToken(CloudProvider.dropbox)}',
      'Dropbox-API-Arg': jsonEncode({'path': remotePath}),
    };

    final response = await http.post(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);
      return response.bodyBytes.length;
    } else {
      throw Exception('Dropbox download failed: ${response.statusCode}');
    }
  }

  Future<int> _downloadFromGitHub(String remotePath, String localPath, void Function(double)? onProgress) async {
    // GitHub download implementation
    throw Exception('GitHub download not implemented');
  }

  Future<int> _downloadFromGitLab(String remotePath, String localPath, void Function(double)? onProgress) async {
    // GitLab download implementation
    throw Exception('GitLab download not implemented');
  }

  Future<int> _downloadFromGoogleDrive(String remotePath, String localPath, void Function(double)? onProgress) async {
    // Google Drive download implementation
    throw Exception('Google Drive download not implemented');
  }

  Future<int> _downloadFromOneDrive(String remotePath, String localPath, void Function(double)? onProgress) async {
    // OneDrive download implementation
    throw Exception('OneDrive download not implemented');
  }

  Future<List<CloudFileInfo>> _listDropboxFiles(String? folderPath) async {
    // Dropbox list files implementation
    return [];
  }

  Future<List<CloudFileInfo>> _listGitHubFiles(String? folderPath) async {
    // GitHub list files implementation
    return [];
  }

  Future<List<CloudFileInfo>> _listGitLabFiles(String? folderPath) async {
    // GitLab list files implementation
    return [];
  }

  Future<List<CloudFileInfo>> _listGoogleDriveFiles(String? folderPath) async {
    // Google Drive list files implementation
    return [];
  }

  Future<List<CloudFileInfo>> _listOneDriveFiles(String? folderPath) async {
    // OneDrive list files implementation
    return [];
  }

  Future<bool> _deleteDropboxFile(String remotePath) async {
    // Dropbox delete implementation
    return false;
  }

  Future<bool> _deleteGitHubFile(String remotePath) async {
    // GitHub delete implementation
    return false;
  }

  Future<bool> _deleteGitLabFile(String remotePath) async {
    // GitLab delete implementation
    return false;
  }

  Future<bool> _deleteGoogleDriveFile(String remotePath) async {
    // Google Drive delete implementation
    return false;
  }

  Future<bool> _deleteOneDriveFile(String remotePath) async {
    // OneDrive delete implementation
    return false;
  }

  Future<String?> _getAccessToken(CloudProvider provider) async {
    // In real implementation, this would handle OAuth2 flows
    // For now, return configured tokens or throw helpful errors
    switch (provider) {
      case CloudProvider.dropbox:
        final appKey = await _config.getParameter<String>('cloud.dropbox.app_key');
        final appSecret = await _config.getParameter<String>('cloud.dropbox.app_secret');
        if (appKey == null || appSecret == null || appKey.isEmpty || appSecret.isEmpty) {
          throw Exception('Dropbox not configured. Get API credentials from: https://www.dropbox.com/developers/apps');
        }
        // This would do OAuth2 flow in real implementation
        return 'dropbox_access_token_placeholder';
      case CloudProvider.github:
        final token = await _config.getParameter<String>('cloud.github.token');
        if (token == null || token.isEmpty) {
          throw Exception('GitHub token not configured. Get one from: https://github.com/settings/tokens');
        }
        return token;
      case CloudProvider.gitlab:
        final token = await _config.getParameter<String>('cloud.gitlab.token');
        if (token == null || token.isEmpty) {
          throw Exception('GitLab token not configured. Get one from: https://gitlab.com/-/profile/personal_access_tokens');
        }
        return token;
      default:
        throw Exception('${provider.name} authentication not implemented');
    }
  }

  void _emitCloudEvent(CloudEventType type, {Map<String, dynamic>? data}) {
    final event = CloudEvent(
      type: type,
      provider: _activeProvider,
      timestamp: DateTime.now(),
      data: data,
    );
    _cloudEventController.add(event);
  }
}

/// Cloud Storage Providers (All with FREE Tiers!)
enum CloudProvider {
  dropbox,      // 2GB free
  github,       // Unlimited public repos (with limits)
  gitlab,       // 10GB free
  googledrive,  // 15GB free
  onedrive,     // 5GB free
  box,          // 10GB free
  mediafire,    // 10GB free
  mega,         // 20GB free (most generous!)
}

/// Cloud Operation Types
enum CloudOperationType {
  upload,
  download,
  list,
  delete,
}

/// Cloud Operation Status
enum CloudOperationStatus {
  pending,
  inProgress,
  completed,
  failed,
}

/// Cloud Operation
class CloudOperation {
  final String id;
  final CloudOperationType type;
  final String? localPath;
  final String? remotePath;
  final int? fileSize;
  final DateTime startTime;
  DateTime? endTime;
  CloudOperationStatus status;
  String? error;

  CloudOperation({
    required this.id,
    required this.type,
    this.localPath,
    this.remotePath,
    this.fileSize,
    required this.startTime,
    this.endTime,
    this.status = CloudOperationStatus.pending,
    this.error,
  });

  Duration? get duration => endTime != null ? endTime!.difference(startTime) : null;
}

/// Cloud Upload Result
class CloudUploadResult {
  final bool success;
  final String operationId;
  final String? fileUrl;
  final int? fileSize;
  final Duration? uploadTime;
  final CloudProvider provider;
  final String? error;

  CloudUploadResult({
    required this.success,
    required this.operationId,
    this.fileUrl,
    this.fileSize,
    this.uploadTime,
    required this.provider,
    this.error,
  });
}

/// Cloud Download Result
class CloudDownloadResult {
  final bool success;
  final String operationId;
  final String? localPath;
  final int? fileSize;
  final Duration? downloadTime;
  final CloudProvider provider;
  final String? error;

  CloudDownloadResult({
    required this.success,
    required this.operationId,
    this.localPath,
    this.fileSize,
    this.downloadTime,
    required this.provider,
    this.error,
  });
}

/// Cloud File Information
class CloudFileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final bool isDirectory;
  final CloudProvider provider;

  CloudFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.isDirectory,
    required this.provider,
  });
}

/// Cloud Storage Usage
class CloudStorageUsage {
  final CloudProvider provider;
  final int usedBytes;
  final int totalBytes;
  final int freeBytes;
  final DateTime lastUpdated;
  final bool isFreeTier;

  CloudStorageUsage({
    required this.provider,
    required this.usedBytes,
    required this.totalBytes,
    required this.freeBytes,
    required this.lastUpdated,
    required this.isFreeTier,
  });

  factory CloudStorageUsage.empty(CloudProvider provider) {
    return CloudStorageUsage(
      provider: provider,
      usedBytes: 0,
      totalBytes: 0,
      freeBytes: 0,
      lastUpdated: DateTime.now(),
      isFreeTier: true,
    );
  }

  double get usedGB => usedBytes / (1024 * 1024 * 1024);
  double get totalGB => totalBytes / (1024 * 1024 * 1024);
  double get freeGB => freeBytes / (1024 * 1024 * 1024);
  double get usagePercentage => totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0;
}

/// Cloud Event Types
enum CloudEventType {
  initialized,
  providerSwitched,
  uploadStarted,
  uploadProgress,
  uploadCompleted,
  uploadFailed,
  downloadStarted,
  downloadProgress,
  downloadCompleted,
  downloadFailed,
  fileListed,
  fileDeleted,
}

/// Cloud Event
class CloudEvent {
  final CloudEventType type;
  final CloudProvider provider;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  CloudEvent({
    required this.type,
    required this.provider,
    required this.timestamp,
    this.data,
  });
}

/// Free Cloud Storage Setup Helper
class FreeCloudStorageSetup {
  static Future<String> getSetupInstructions(CloudProvider provider) async {
    switch (provider) {
      case CloudProvider.dropbox:
        return '''
Free Dropbox Setup (2GB free):

1. Go to: https://www.dropbox.com/developers/apps
2. Click "Create app"
3. Choose "Scoped access" -> "App folder"
4. Name your app "iSuite Free Storage"
5. Get your App key and App secret
6. Set in iSuite config:
   - cloud.dropbox.app_key: YOUR_APP_KEY
   - cloud.dropbox.app_secret: YOUR_APP_SECRET

Benefits:
- 2GB free storage
- File versioning
- Sharing capabilities
- Cross-platform sync
''';
      case CloudProvider.github:
        return '''
Free GitHub Setup (unlimited public repos):

1. Go to: https://github.com/settings/tokens
2. Generate new token with "repo" scope
3. Set in iSuite config:
   - cloud.github.token: YOUR_TOKEN

Benefits:
- Unlimited public repositories
- GitHub Actions for automation
- GitHub Pages for hosting
- Community features
''';
      case CloudProvider.gitlab:
        return '''
Free GitLab Setup (10GB storage):

1. Go to: https://gitlab.com/-/profile/personal_access_tokens
2. Create token with "api" scope
3. Set in iSuite config:
   - cloud.gitlab.token: YOUR_TOKEN

Benefits:
- 10GB free storage
- Built-in CI/CD
- GitLab Pages
- Advanced project management
''';
      case CloudProvider.mega:
        return '''
Free MEGA Setup (20GB free - most generous!):

1. Go to: https://mega.nz/developers
2. Get your API key
3. Set in iSuite config:
   - cloud.mega.api_key: YOUR_API_KEY

Benefits:
- 20GB free storage (highest free tier!)
- End-to-end encryption
- File sharing and collaboration
- No file size limits within free tier
''';
      default:
        return '''
This cloud provider requires API setup. Please visit their developer portal to get started with free tier access.

Popular free tiers:
- Dropbox: 2GB free
- Google Drive: 15GB free
- OneDrive: 5GB free
- MEGA: 20GB free (best value!)
- GitLab: 10GB free
- GitHub: Unlimited public repos
''';
    }
  }

  static Future<List<CloudProvider>> getRecommendedProviders() async {
    // Return providers sorted by free storage amount
    return [
      CloudProvider.mega,        // 20GB - Best value!
      CloudProvider.googledrive, // 15GB
      CloudProvider.gitlab,      // 10GB
      CloudProvider.box,         // 10GB
      CloudProvider.mediafire,   // 10GB
      CloudProvider.onedrive,    // 5GB
      CloudProvider.dropbox,     // 2GB
      CloudProvider.github,      // Unlimited repos (with limits)
    ];
  }
}
