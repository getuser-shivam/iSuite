import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class PluginMarketplace {
  static PluginMarketplace? _instance;
  static PluginMarketplace get instance =>
      _instance ??= PluginMarketplace._internal();
  PluginMarketplace._internal();

  // Plugin Registry
  final Map<String, Plugin> _plugins = {};
  final Map<String, PluginVersion> _pluginVersions = {};
  final Map<String, PluginInstallation> _installations = {};

  // Marketplace Configuration
  bool _isInitialized = false;
  String? _marketplaceUrl;
  String? _apiToken;
  bool _enableAutoUpdate = true;
  bool _enableBetaPlugins = false;

  // Plugin Management
  final Map<String, PluginInstance> _loadedPlugins = {};
  final Map<String, StreamSubscription> _pluginSubscriptions = {};
  final Map<String, Timer> _pluginTimers = {};

  // Security
  final Map<String, String> _pluginSignatures = {};
  final Set<String> _trustedDevelopers = {};
  final Map<String, SecurityPolicy> _securityPolicies = {};

  // Analytics
  final Map<String, PluginAnalytics> _analytics = {};
  final List<MarketplaceEvent> _eventLog = [];

  // Configuration
  int _maxPlugins = 50;
  int _maxPluginSize = 100 * 1024 * 1024; // 100MB
  Duration _updateCheckInterval = Duration(hours: 24);
  Timer? _updateTimer;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get marketplaceUrl => _marketplaceUrl;
  bool get enableAutoUpdate => _enableAutoUpdate;
  bool get enableBetaPlugins => _enableBetaPlugins;
  Map<String, Plugin> get plugins => Map.from(_plugins);
  Map<String, PluginInstallation> get installations => Map.from(_installations);
  Map<String, PluginInstance> get loadedPlugins => Map.from(_loadedPlugins);
  List<MarketplaceEvent> get eventLog => List.from(_eventLog);

  /// Initialize Plugin Marketplace
  Future<bool> initialize({
    String? marketplaceUrl,
    String? apiToken,
    bool enableAutoUpdate = true,
    bool enableBetaPlugins = false,
    int? maxPlugins,
    int? maxPluginSize,
    Duration? updateCheckInterval,
  }) async {
    if (_isInitialized) return true;

    try {
      _marketplaceUrl = marketplaceUrl ?? 'https://plugins.isuite.app';
      _apiToken = apiToken;
      _enableAutoUpdate = enableAutoUpdate;
      _enableBetaPlugins = enableBetaPlugins;
      _maxPlugins = maxPlugins ?? _maxPlugins;
      _maxPluginSize = maxPluginSize ?? _maxPluginSize;
      _updateCheckInterval = updateCheckInterval ?? _updateCheckInterval;

      // Initialize security policies
      await _initializeSecurityPolicies();

      // Load installed plugins
      await _loadInstalledPlugins();

      // Start auto-update checker
      if (_enableAutoUpdate) {
        _startAutoUpdateChecker();
      }

      _isInitialized = true;
      await _logMarketplaceEvent(MarketplaceEventType.initialized, {
        'marketplaceUrl': _marketplaceUrl,
        'enableAutoUpdate': _enableAutoUpdate,
        'enableBetaPlugins': _enableBetaPlugins,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _initializeSecurityPolicies() async {
    _securityPolicies['default'] = SecurityPolicy(
      id: 'default',
      name: 'Default Security Policy',
      requireSignature: true,
      requireSandbox: true,
      allowedPermissions: [
        'storage.read',
        'storage.write',
        'network.http',
        'notifications.basic',
      ],
      blockedPermissions: [
        'system.root',
        'system.admin',
        'camera.access',
        'microphone.access',
      ],
      maxFileSize: _maxPluginSize,
      maxMemoryUsage: 100 * 1024 * 1024, // 100MB
    );

    _securityPolicies['strict'] = SecurityPolicy(
      id: 'strict',
      name: 'Strict Security Policy',
      requireSignature: true,
      requireSandbox: true,
      allowedPermissions: [
        'storage.read',
        'notifications.basic',
      ],
      blockedPermissions: [
        'storage.write',
        'network.http',
        'camera.access',
        'microphone.access',
        'system.root',
        'system.admin',
      ],
      maxFileSize: 50 * 1024 * 1024, // 50MB
      maxMemoryUsage: 50 * 1024 * 1024, // 50MB
    );
  }

  Future<void> _loadInstalledPlugins() async {
    // In a real implementation, this would load from local storage
    // For now, we'll simulate some installed plugins
    final pluginDir = Directory('plugins');
    if (await pluginDir.exists()) {
      final files = await pluginDir.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final pluginData = jsonDecode(content);
            final plugin = Plugin.fromMap(pluginData);
            _plugins[plugin.id] = plugin;
          } catch (e) {
            // Handle error
          }
        }
      }
    }
  }

  void _startAutoUpdateChecker() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_updateCheckInterval, (_) {
      _checkForUpdates();
    });
  }

  /// Browse plugins
  Future<List<Plugin>> browsePlugins({
    String? category,
    String? query,
    PluginSort sort = PluginSort.popularity,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url = Uri.parse('$_marketplaceUrl/api/plugins');
      final response = await http.get(
        url.replace(queryParameters: {
          'category': category,
          'query': query,
          'sort': sort.name,
          'page': page.toString(),
          'limit': limit.toString(),
          'beta': _enableBetaPlugins.toString(),
        }),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final plugins =
            (data['plugins'] as List).map((p) => Plugin.fromMap(p)).toList();

        // Cache plugins
        for (final plugin in plugins) {
          _plugins[plugin.id] = plugin;
        }

        return plugins;
      } else {
        throw Exception('Failed to browse plugins: ${response.statusCode}');
      }
    } catch (e) {
      await _logMarketplaceEvent(MarketplaceEventType.browseFailed, {
        'error': e.toString(),
      });
      return [];
    }
  }

  /// Get plugin details
  Future<Plugin?> getPluginDetails(String pluginId) async {
    // Check cache first
    if (_plugins.containsKey(pluginId)) {
      return _plugins[pluginId];
    }

    try {
      final url = Uri.parse('$_marketplaceUrl/api/plugins/$pluginId');
      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final plugin = Plugin.fromMap(data);
        _plugins[plugin.id] = plugin;
        return plugin;
      } else {
        return null;
      }
    } catch (e) {
      await _logMarketplaceEvent(MarketplaceEventType.detailsFailed, {
        'pluginId': pluginId,
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Install plugin
  Future<PluginInstallationResult> installPlugin(
    String pluginId, {
    String? version,
    SecurityPolicy? securityPolicy,
  }) async {
    if (_installations.length >= _maxPlugins) {
      return PluginInstallationResult(
        success: false,
        error: 'Maximum plugin limit reached',
      );
    }

    try {
      // Get plugin details
      final plugin = await getPluginDetails(pluginId);
      if (plugin == null) {
        return PluginInstallationResult(
          success: false,
          error: 'Plugin not found',
        );
      }

      // Check if already installed
      if (_installations.containsKey(pluginId)) {
        return PluginInstallationResult(
          success: false,
          error: 'Plugin already installed',
        );
      }

      // Get version to install
      final versionToInstall = version ?? plugin.latestVersion;

      // Download plugin
      final downloadResult = await _downloadPlugin(pluginId, versionToInstall);
      if (!downloadResult.success) {
        return PluginInstallationResult(
          success: false,
          error: downloadResult.error,
        );
      }

      // Verify plugin
      final verificationResult =
          await _verifyPlugin(pluginId, downloadResult.filePath!);
      if (!verificationResult.success) {
        return PluginInstallationResult(
          success: false,
          error: verificationResult.error,
        );
      }

      // Security check
      final securityResult = await _performSecurityCheck(
        pluginId,
        downloadResult.filePath!,
        securityPolicy ?? _securityPolicies['default']!,
      );
      if (!securityResult.success) {
        return PluginInstallationResult(
          success: false,
          error: securityResult.error,
        );
      }

      // Install plugin
      final installResult =
          await _performInstallation(pluginId, downloadResult.filePath!);
      if (!installResult.success) {
        return PluginInstallationResult(
          success: false,
          error: installResult.error,
        );
      }

      // Create installation record
      final installation = PluginInstallation(
        id: const Uuid().v4(),
        pluginId: pluginId,
        version: versionToInstall,
        installedAt: DateTime.now(),
        status: InstallationStatus.installed,
        filePath: downloadResult.filePath!,
      );

      _installations[pluginId] = installation;

      // Load plugin
      await _loadPlugin(pluginId);

      await _logMarketplaceEvent(MarketplaceEventType.pluginInstalled, {
        'pluginId': pluginId,
        'version': versionToInstall,
      });

      return PluginInstallationResult(
        success: true,
        installation: installation,
      );
    } catch (e) {
      await _logMarketplaceEvent(MarketplaceEventType.installationFailed, {
        'pluginId': pluginId,
        'error': e.toString(),
      });
      return PluginInstallationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<DownloadResult> _downloadPlugin(
      String pluginId, String version) async {
    try {
      final url =
          Uri.parse('$_marketplaceUrl/api/plugins/$pluginId/download/$version');
      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Save plugin file
        final pluginDir = Directory('plugins');
        if (!await pluginDir.exists()) {
          await pluginDir.create(recursive: true);
        }

        final filePath = '${pluginDir.path}/$pluginId-$version.ipk';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return DownloadResult(
          success: true,
          filePath: filePath,
          size: response.bodyBytes.length,
        );
      } else {
        return DownloadResult(
          success: false,
          error: 'Download failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return DownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<VerificationResult> _verifyPlugin(
      String pluginId, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return VerificationResult(
          success: false,
          error: 'Plugin file not found',
        );
      }

      // Calculate file hash
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();

      // Verify signature
      final signatureVerified = await _verifySignature(pluginId, hash);
      if (!signatureVerified) {
        return VerificationResult(
          success: false,
          error: 'Signature verification failed',
        );
      }

      return VerificationResult(success: true);
    } catch (e) {
      return VerificationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> _verifySignature(String pluginId, String hash) async {
    try {
      final url = Uri.parse('$_marketplaceUrl/api/plugins/$pluginId/verify');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'hash': hash}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<SecurityResult> _performSecurityCheck(
    String pluginId,
    String filePath,
    SecurityPolicy policy,
  ) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();

      // Check file size
      if (fileSize > policy.maxFileSize) {
        return SecurityResult(
          success: false,
          error: 'Plugin file size exceeds limit',
        );
      }

      // Extract plugin manifest
      final manifest = await _extractManifest(filePath);
      if (manifest == null) {
        return SecurityResult(
          success: false,
          error: 'Failed to extract plugin manifest',
        );
      }

      // Check permissions
      for (final permission in manifest.permissions) {
        if (policy.blockedPermissions.contains(permission)) {
          return SecurityResult(
            success: false,
            error: 'Plugin requires blocked permission: $permission',
          );
        }
      }

      return SecurityResult(success: true);
    } catch (e) {
      return SecurityResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<PluginManifest?> _extractManifest(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Extract ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find manifest.json
      for (final file in archive) {
        if (file.name == 'manifest.json') {
          final manifestBytes = file.content as List<int>;
          final manifestString = utf8.decode(manifestBytes);
          final manifestData = jsonDecode(manifestString);
          return PluginManifest.fromMap(manifestData);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<InstallationResult> _performInstallation(
      String pluginId, String filePath) async {
    try {
      final file = File(filePath);
      final pluginDir = Directory('plugins/$pluginId');

      // Create plugin directory
      if (!await pluginDir.exists()) {
        await pluginDir.create(recursive: true);
      }

      // Extract plugin
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filePath = '${pluginDir.path}/${file.name}';
        final extractedFile = File(filePath);

        // Create directory if needed
        if (file.name.endsWith('/')) {
          await extractedFile.create(recursive: true);
        } else {
          await extractedFile.parent.create(recursive: true);
          await extractedFile.writeAsBytes(file.content as List<int>);
        }
      }

      return InstallationResult(success: true);
    } catch (e) {
      return InstallationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Uninstall plugin
  Future<UninstallationResult> uninstallPlugin(String pluginId) async {
    try {
      // Check if plugin is installed
      final installation = _installations[pluginId];
      if (installation == null) {
        return UninstallationResult(
          success: false,
          error: 'Plugin not installed',
        );
      }

      // Unload plugin
      await _unloadPlugin(pluginId);

      // Remove plugin files
      final pluginDir = Directory('plugins/$pluginId');
      if (await pluginDir.exists()) {
        await pluginDir.delete(recursive: true);
      }

      // Remove installation record
      _installations.remove(pluginId);

      await _logMarketplaceEvent(MarketplaceEventType.pluginUninstalled, {
        'pluginId': pluginId,
      });

      return UninstallationResult(success: true);
    } catch (e) {
      await _logMarketplaceEvent(MarketplaceEventType.uninstallationFailed, {
        'pluginId': pluginId,
        'error': e.toString(),
      });
      return UninstallationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Load plugin
  Future<void> _loadPlugin(String pluginId) async {
    try {
      final plugin = _plugins[pluginId];
      if (plugin == null) return;

      final pluginDir = Directory('plugins/$pluginId');
      final manifestFile = File('${pluginDir.path}/manifest.json');

      if (!await manifestFile.exists()) {
        throw Exception('Plugin manifest not found');
      }

      final manifestContent = await manifestFile.readAsString();
      final manifestData = jsonDecode(manifestContent);
      final manifest = PluginManifest.fromMap(manifestData);

      // Create plugin instance
      final instance = PluginInstance(
        id: pluginId,
        manifest: manifest,
        loadedAt: DateTime.now(),
        isActive: true,
      );

      _loadedPlugins[pluginId] = instance;

      // Initialize plugin
      await _initializePlugin(instance);

      await _logMarketplaceEvent(MarketplaceEventType.pluginLoaded, {
        'pluginId': pluginId,
      });
    } catch (e) {
      await _logMarketplaceEvent(MarketplaceEventType.pluginLoadFailed, {
        'pluginId': pluginId,
        'error': e.toString(),
      });
    }
  }

  Future<void> _initializePlugin(PluginInstance instance) async {
    // In a real implementation, this would initialize the plugin
    // For now, we'll simulate initialization
    await Future.delayed(Duration(milliseconds: 100));
  }

  /// Unload plugin
  Future<void> _unloadPlugin(String pluginId) async {
    try {
      final instance = _loadedPlugins[pluginId];
      if (instance == null) return;

      // Cancel subscriptions
      final subscription = _pluginSubscriptions[pluginId];
      if (subscription != null) {
        await subscription.cancel();
        _pluginSubscriptions.remove(pluginId);
      }

      // Cancel timers
      final timer = _pluginTimers[pluginId];
      if (timer != null) {
        timer.cancel();
        _pluginTimers.remove(pluginId);
      }

      // Remove from loaded plugins
      _loadedPlugins.remove(pluginId);

      await _logMarketplaceEvent(MarketplaceEventType.pluginUnloaded, {
        'pluginId': pluginId,
      });
    } catch (e) {
      await _logMarketplaceEvent(MarketplaceEventType.pluginUnloadFailed, {
        'pluginId': pluginId,
        'error': e.toString(),
      });
    }
  }

  /// Update plugin
  Future<UpdateResult> updatePlugin(String pluginId) async {
    try {
      final installation = _installations[pluginId];
      if (installation == null) {
        return UpdateResult(
          success: false,
          error: 'Plugin not installed',
        );
      }

      // Check for updates
      final plugin = await getPluginDetails(pluginId);
      if (plugin == null) {
        return UpdateResult(
          success: false,
          error: 'Plugin not found',
        );
      }

      if (plugin.latestVersion == installation.version) {
        return UpdateResult(
          success: true,
          message: 'Plugin is up to date',
        );
      }

      // Uninstall current version
      final uninstallResult = await uninstallPlugin(pluginId);
      if (!uninstallResult.success) {
        return UpdateResult(
          success: false,
          error: 'Failed to uninstall current version',
        );
      }

      // Install new version
      final installResult =
          await installPlugin(pluginId, version: plugin.latestVersion);
      if (!installResult.success) {
        return UpdateResult(
          success: false,
          error: 'Failed to install new version',
        );
      }

      await _logMarketplaceEvent(MarketplaceEventType.pluginUpdated, {
        'pluginId': pluginId,
        'oldVersion': installation.version,
        'newVersion': plugin.latestVersion,
      });

      return UpdateResult(
        success: true,
        message: 'Plugin updated successfully',
      );
    } catch (e) {
      await _logMarketplaceEvent(MarketplaceEventType.updateFailed, {
        'pluginId': pluginId,
        'error': e.toString(),
      });
      return UpdateResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check for updates
  Future<void> _checkForUpdates() async {
    try {
      for (final installation in _installations.values) {
        final updateResult = await updatePlugin(installation.pluginId);
        if (updateResult.success &&
            updateResult.message != 'Plugin is up to date') {
          // Plugin was updated
        }
      }
    } catch (e) {
      await _logMarketplaceEvent(MarketplaceEventType.updateCheckFailed, {
        'error': e.toString(),
      });
    }
  }

  /// Get plugin analytics
  Future<PluginAnalytics?> getPluginAnalytics(String pluginId) async {
    try {
      final url = Uri.parse('$_marketplaceUrl/api/plugins/$pluginId/analytics');
      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analytics = PluginAnalytics.fromMap(data);
        _analytics[pluginId] = analytics;
        return analytics;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get marketplace statistics
  Map<String, dynamic> getMarketplaceStatistics() {
    return {
      'isInitialized': _isInitialized,
      'marketplaceUrl': _marketplaceUrl,
      'enableAutoUpdate': _enableAutoUpdate,
      'enableBetaPlugins': _enableBetaPlugins,
      'totalPlugins': _plugins.length,
      'installedPlugins': _installations.length,
      'loadedPlugins': _loadedPlugins.length,
      'maxPlugins': _maxPlugins,
      'trustedDevelopers': _trustedDevelopers.length,
      'securityPolicies': _securityPolicies.length,
      'eventLogSize': _eventLog.length,
      'configuration': {
        'maxPluginSize': _maxPluginSize,
        'updateCheckInterval': _updateCheckInterval.inHours,
      },
    };
  }

  /// Get headers for API requests
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': 'iSuite-PluginMarketplace/1.0',
    };

    if (_apiToken != null) {
      headers['Authorization'] = 'Bearer $_apiToken';
    }

    return headers;
  }

  /// Log marketplace event
  Future<void> _logMarketplaceEvent(
      MarketplaceEventType type, Map<String, dynamic> data) async {
    final event = MarketplaceEvent(
      id: const Uuid().v4(),
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    _eventLog.add(event);

    // Limit event log size
    if (_eventLog.length > 1000) {
      _eventLog.removeRange(0, _eventLog.length - 1000);
    }
  }

  /// Dispose plugin marketplace
  Future<void> dispose() async {
    _updateTimer?.cancel();

    // Unload all plugins
    for (final pluginId in _loadedPlugins.keys.toList()) {
      await _unloadPlugin(pluginId);
    }

    _plugins.clear();
    _installations.clear();
    _loadedPlugins.clear();
    _pluginSubscriptions.clear();
    _pluginTimers.clear();
    _analytics.clear();
    _eventLog.clear();

    _isInitialized = false;
  }
}

// Plugin Models
class Plugin {
  final String id;
  final String name;
  final String description;
  final String version;
  final String latestVersion;
  final String author;
  final String category;
  final List<String> tags;
  final String iconUrl;
  final List<String> screenshots;
  final double rating;
  final int downloads;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PluginManifest? manifest;
  final bool isBeta;
  final bool isPaid;
  final double? price;

  const Plugin({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.latestVersion,
    required this.author,
    required this.category,
    required this.tags,
    required this.iconUrl,
    required this.screenshots,
    required this.rating,
    required this.downloads,
    required this.createdAt,
    required this.updatedAt,
    this.manifest,
    this.isBeta = false,
    this.isPaid = false,
    this.price,
  });

  factory Plugin.fromMap(Map<String, dynamic> map) {
    return Plugin(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      version: map['version'],
      latestVersion: map['latestVersion'],
      author: map['author'],
      category: map['category'],
      tags: List<String>.from(map['tags'] ?? []),
      iconUrl: map['iconUrl'],
      screenshots: List<String>.from(map['screenshots'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      downloads: map['downloads'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      manifest: map['manifest'] != null
          ? PluginManifest.fromMap(map['manifest'])
          : null,
      isBeta: map['isBeta'] ?? false,
      isPaid: map['isPaid'] ?? false,
      price: map['price'],
    );
  }
}

class PluginManifest {
  final String name;
  final String version;
  final String description;
  final String author;
  final List<String> permissions;
  final List<String> dependencies;
  final Map<String, dynamic> metadata;

  const PluginManifest({
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.permissions,
    required this.dependencies,
    required this.metadata,
  });

  factory PluginManifest.fromMap(Map<String, dynamic> map) {
    return PluginManifest(
      name: map['name'],
      version: map['version'],
      description: map['description'],
      author: map['author'],
      permissions: List<String>.from(map['permissions'] ?? []),
      dependencies: List<String>.from(map['dependencies'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

class PluginInstallation {
  final String id;
  final String pluginId;
  final String version;
  final DateTime installedAt;
  final InstallationStatus status;
  final String filePath;

  const PluginInstallation({
    required this.id,
    required this.pluginId,
    required this.version,
    required this.installedAt,
    required this.status,
    required this.filePath,
  });
}

class PluginInstance {
  final String id;
  final PluginManifest manifest;
  final DateTime loadedAt;
  final bool isActive;

  const PluginInstance({
    required this.id,
    required this.manifest,
    required this.loadedAt,
    required this.isActive,
  });
}

class PluginAnalytics {
  final String pluginId;
  final int dailyActiveUsers;
  final int weeklyActiveUsers;
  final int monthlyActiveUsers;
  final int totalDownloads;
  final double averageRating;
  final Map<String, int> versionDistribution;
  final Map<String, int> countryDistribution;

  const PluginAnalytics({
    required this.pluginId,
    required this.dailyActiveUsers,
    required this.weeklyActiveUsers,
    required this.monthlyActiveUsers,
    required this.totalDownloads,
    required this.averageRating,
    required this.versionDistribution,
    required this.countryDistribution,
  });

  factory PluginAnalytics.fromMap(Map<String, dynamic> map) {
    return PluginAnalytics(
      pluginId: map['pluginId'],
      dailyActiveUsers: map['dailyActiveUsers'] ?? 0,
      weeklyActiveUsers: map['weeklyActiveUsers'] ?? 0,
      monthlyActiveUsers: map['monthlyActiveUsers'] ?? 0,
      totalDownloads: map['totalDownloads'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      versionDistribution:
          Map<String, int>.from(map['versionDistribution'] ?? {}),
      countryDistribution:
          Map<String, int>.from(map['countryDistribution'] ?? {}),
    );
  }
}

class SecurityPolicy {
  final String id;
  final String name;
  final bool requireSignature;
  final bool requireSandbox;
  final List<String> allowedPermissions;
  final List<String> blockedPermissions;
  final int maxFileSize;
  final int maxMemoryUsage;

  const SecurityPolicy({
    required this.id,
    required this.name,
    required this.requireSignature,
    required this.requireSandbox,
    required this.allowedPermissions,
    required this.blockedPermissions,
    required this.maxFileSize,
    required this.maxMemoryUsage,
  });
}

class MarketplaceEvent {
  final String id;
  final MarketplaceEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const MarketplaceEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

// Result Classes
class PluginInstallationResult {
  final bool success;
  final String? error;
  final PluginInstallation? installation;

  const PluginInstallationResult({
    required this.success,
    this.error,
    this.installation,
  });
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final int? size;
  final String? error;

  const DownloadResult({
    required this.success,
    this.filePath,
    this.size,
    this.error,
  });
}

class VerificationResult {
  final bool success;
  final String? error;

  const VerificationResult({
    required this.success,
    this.error,
  });
}

class SecurityResult {
  final bool success;
  final String? error;

  const SecurityResult({
    required this.success,
    this.error,
  });
}

class InstallationResult {
  final bool success;
  final String? error;

  const InstallationResult({
    required this.success,
    this.error,
  });
}

class UninstallationResult {
  final bool success;
  final String? error;

  const UninstallationResult({
    required this.success,
    this.error,
  });
}

class UpdateResult {
  final bool success;
  final String? message;
  final String? error;

  const UpdateResult({
    required this.success,
    this.message,
    this.error,
  });
}

// Enums
enum PluginSort {
  popularity,
  rating,
  downloads,
  newest,
  oldest,
  alphabetical,
}

enum InstallationStatus {
  installed,
  uninstalled,
  failed,
  updating,
}

enum MarketplaceEventType {
  initialized,
  browseFailed,
  detailsFailed,
  pluginInstalled,
  pluginUninstalled,
  pluginLoaded,
  pluginUnloaded,
  pluginLoadFailed,
  pluginUnloadFailed,
  installationFailed,
  uninstallationFailed,
  pluginUpdated,
  updateFailed,
  updateCheckFailed,
  unknown,
}
