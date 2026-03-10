import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'performance_optimization_service.dart';
import '../../core/config/central_config.dart';

/// Plugin Marketplace Service
/// Provides secure plugin installation, sandboxing, and marketplace functionality
class PluginMarketplaceService {
  static final PluginMarketplaceService _instance =
      PluginMarketplaceService._internal();
  factory PluginMarketplaceService() => _instance;
  PluginMarketplaceService._internal();

  final PerformanceOptimizationService _performanceService =
      PerformanceOptimizationService();
  final CentralConfig _config = CentralConfig.instance;
  final StreamController<PluginEvent> _pluginEventController =
      StreamController.broadcast();

  Stream<PluginEvent> get pluginEvents => _pluginEventController.stream;

  // Plugin management
  final Map<String, PluginInfo> _installedPlugins = {};
  final Map<String, PluginSandbox> _pluginSandboxes = {};
  final Map<String, PluginMarketplaceItem> _marketplaceItems = {};

  // Security and permissions
  final Map<String, PluginPermissions> _pluginPermissions = {};
  final Map<String, PluginSecurityProfile> _securityProfiles = {};

  // Marketplace
  final Map<String, PluginRepository> _pluginRepositories = {};
  final Map<String, PluginUpdateInfo> _availableUpdates = {};

  bool _isInitialized = false;

  // Configuration
  static const String _pluginsDirectory = 'plugins';
  static const String _marketplaceUrl = 'https://marketplace.isuite.com/api';
  static const Duration _updateCheckInterval = Duration(hours: 24);
  static const int _maxConcurrentPlugins = 10;

  Timer? _updateCheckTimer;
  Semaphore _pluginSemaphore = Semaphore(_maxConcurrentPlugins);

  /// Initialize plugin marketplace service
  Future<void> initialize({
    List<String>? repositoryUrls,
    Map<String, PluginSecurityProfile>? securityProfiles,
  }) async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent('PluginMarketplaceService', '1.0.0',
          'Secure plugin marketplace with sandboxing and installation',
          dependencies: [
            'PerformanceOptimizationService'
          ],
          parameters: {
            'plugins_directory': 'plugins',
            'marketplace_url': 'https://marketplace.isuite.com/api',
            'update_check_interval': 86400000, // 24 hours in ms
            'max_concurrent_plugins': 10,
            'plugin_timeout': 30000, // 30 seconds
            'max_plugin_memory': 50 * 1024 * 1024, // 50MB
            'security_profile': 'restricted',
            'auto_update_enabled': true,
            'plugin_validation_enabled': true,
          });

      // Register component relationships
      await _config.registerComponentRelationship(
        'PluginMarketplaceService',
        'PerformanceOptimizationService',
        RelationshipType.depends_on,
        'Uses performance optimization for plugin execution monitoring',
      );

      await _config.registerComponentRelationship(
        'PluginMarketplaceService',
        'AdvancedSecurityManager',
        RelationshipType.depends_on,
        'Uses security manager for plugin sandboxing and validation',
      );

      // Initialize directories
      await _initializePluginDirectories();

      // Load installed plugins
      await _loadInstalledPlugins();

      // Initialize repositories
      if (repositoryUrls != null) {
        for (final url in repositoryUrls) {
          await addRepository(url);
        }
      } else {
        await addRepository(_marketplaceUrl);
      }

      // Load security profiles
      if (securityProfiles != null) {
        _securityProfiles.addAll(securityProfiles);
      } else {
        await _initializeDefaultSecurityProfiles();
      }

      // Start update checking
      _startUpdateChecking();

      _isInitialized = true;
      _emitPluginEvent(PluginEventType.serviceInitialized);
    } catch (e) {
      _emitPluginEvent(PluginEventType.initializationFailed,
          error: e.toString());
      rethrow;
    }
  }

  /// Search marketplace for plugins
  Future<List<PluginMarketplaceItem>> searchPlugins({
    String? query,
    List<String>? categories,
    PluginSortOrder sortBy = PluginSortOrder.downloads,
    int maxResults = 50,
  }) async {
    _emitPluginEvent(PluginEventType.marketplaceSearchStarted,
        details: 'Query: "$query", Categories: ${categories?.join(', ')}');

    try {
      final allItems = <PluginMarketplaceItem>[];

      // Search all repositories
      for (final repository in _pluginRepositories.values) {
        final items = await repository.searchPlugins(
          query: query,
          categories: categories,
        );
        allItems.addAll(items);
      }

      // Remove duplicates and apply sorting
      final uniqueItems = _deduplicateMarketplaceItems(allItems);
      _sortMarketplaceItems(uniqueItems, sortBy);

      final results = uniqueItems.take(maxResults).toList();

      _emitPluginEvent(PluginEventType.marketplaceSearchCompleted,
          details: 'Found ${results.length} plugins');

      return results;
    } catch (e) {
      _emitPluginEvent(PluginEventType.marketplaceSearchFailed,
          error: e.toString());
      rethrow;
    }
  }

  /// Install plugin from marketplace
  Future<PluginInstallationResult> installPlugin({
    required String pluginId,
    required PluginMarketplaceItem marketplaceItem,
    bool enableAfterInstall = true,
    Function(double)? onProgress,
  }) async {
    if (_installedPlugins.containsKey(pluginId)) {
      throw PluginException('Plugin $pluginId is already installed');
    }

    _emitPluginEvent(PluginEventType.installationStarted,
        details: 'Plugin: ${marketplaceItem.name} (${pluginId})');

    try {
      // Download plugin
      final pluginData =
          await _downloadPlugin(marketplaceItem, onProgress: (progress) {
        onProgress?.call(progress * 0.3);
      });

      // Verify plugin integrity
      await _verifyPluginIntegrity(pluginData, marketplaceItem);

      onProgress?.call(0.4);

      // Extract plugin
      final pluginDirectory = await _extractPlugin(pluginData, pluginId);

      onProgress?.call(0.6);

      // Validate plugin manifest
      final manifest = await _validatePluginManifest(pluginDirectory);

      onProgress?.call(0.8);

      // Create plugin info
      final pluginInfo = PluginInfo(
        id: pluginId,
        name: marketplaceItem.name,
        version: marketplaceItem.version,
        description: marketplaceItem.description,
        author: marketplaceItem.author,
        manifest: manifest,
        installPath: pluginDirectory.path,
        installedAt: DateTime.now(),
        isEnabled: false,
      );

      // Set up permissions
      await _setupPluginPermissions(pluginInfo, manifest);

      // Install plugin
      _installedPlugins[pluginId] = pluginInfo;
      await _savePluginInfo(pluginInfo);

      onProgress?.call(0.9);

      // Enable plugin if requested
      if (enableAfterInstall) {
        await enablePlugin(pluginId);
      }

      onProgress?.call(1.0);

      final result = PluginInstallationResult(
        success: true,
        pluginId: pluginId,
        pluginInfo: pluginInfo,
        installationTime: DateTime.now().difference(pluginInfo.installedAt),
      );

      _emitPluginEvent(PluginEventType.installationCompleted,
          details: 'Plugin: ${marketplaceItem.name} installed successfully');

      return result;
    } catch (e) {
      _emitPluginEvent(PluginEventType.installationFailed,
          details: 'Plugin: ${marketplaceItem.name}', error: e.toString());
      rethrow;
    }
  }

  /// Enable plugin
  Future<void> enablePlugin(String pluginId) async {
    final plugin = _installedPlugins[pluginId];
    if (plugin == null) {
      throw PluginException('Plugin $pluginId not found');
    }

    if (plugin.isEnabled) return;

    _emitPluginEvent(PluginEventType.pluginEnabling,
        details: 'Plugin: ${plugin.name}');

    try {
      // Create sandbox
      final sandbox = await _createPluginSandbox(plugin);

      // Load plugin in sandbox
      await sandbox.loadPlugin();

      // Register plugin
      _pluginSandboxes[pluginId] = sandbox;
      plugin.isEnabled = true;

      await _savePluginInfo(plugin);

      _emitPluginEvent(PluginEventType.pluginEnabled,
          details: 'Plugin: ${plugin.name} enabled successfully');
    } catch (e) {
      _emitPluginEvent(PluginEventType.pluginEnableFailed,
          details: 'Plugin: ${plugin.name}', error: e.toString());
      rethrow;
    }
  }

  /// Disable plugin
  Future<void> disablePlugin(String pluginId) async {
    final plugin = _installedPlugins[pluginId];
    if (plugin == null) {
      throw PluginException('Plugin $pluginId not found');
    }

    if (!plugin.isEnabled) return;

    _emitPluginEvent(PluginEventType.pluginDisabling,
        details: 'Plugin: ${plugin.name}');

    try {
      // Unload from sandbox
      final sandbox = _pluginSandboxes[pluginId];
      if (sandbox != null) {
        await sandbox.unloadPlugin();
        _pluginSandboxes.remove(pluginId);
      }

      plugin.isEnabled = false;
      await _savePluginInfo(plugin);

      _emitPluginEvent(PluginEventType.pluginDisabled,
          details: 'Plugin: ${plugin.name} disabled successfully');
    } catch (e) {
      _emitPluginEvent(PluginEventType.pluginDisableFailed,
          details: 'Plugin: ${plugin.name}', error: e.toString());
      rethrow;
    }
  }

  /// Uninstall plugin
  Future<void> uninstallPlugin(String pluginId) async {
    final plugin = _installedPlugins[pluginId];
    if (plugin == null) {
      throw PluginException('Plugin $pluginId not found');
    }

    _emitPluginEvent(PluginEventType.uninstallationStarted,
        details: 'Plugin: ${plugin.name}');

    try {
      // Disable plugin first
      if (plugin.isEnabled) {
        await disablePlugin(pluginId);
      }

      // Remove plugin directory
      final pluginDir = Directory(plugin.installPath);
      if (await pluginDir.exists()) {
        await pluginDir.delete(recursive: true);
      }

      // Clean up permissions
      _pluginPermissions.remove(pluginId);

      // Remove from installed plugins
      _installedPlugins.remove(pluginId);
      await _removePluginInfo(pluginId);

      _emitPluginEvent(PluginEventType.uninstallationCompleted,
          details: 'Plugin: ${plugin.name} uninstalled successfully');
    } catch (e) {
      _emitPluginEvent(PluginEventType.uninstallationFailed,
          details: 'Plugin: ${plugin.name}', error: e.toString());
      rethrow;
    }
  }

  /// Update plugin
  Future<PluginUpdateResult> updatePlugin({
    required String pluginId,
    required PluginMarketplaceItem newVersion,
    Function(double)? onProgress,
  }) async {
    final currentPlugin = _installedPlugins[pluginId];
    if (currentPlugin == null) {
      throw PluginException('Plugin $pluginId not found');
    }

    _emitPluginEvent(PluginEventType.updateStarted,
        details: 'Plugin: ${currentPlugin.name} to ${newVersion.version}');

    try {
      // Backup current plugin
      await _backupPlugin(currentPlugin);

      // Install new version
      final installResult = await installPlugin(
        pluginId: '${pluginId}_temp',
        marketplaceItem: newVersion,
        enableAfterInstall: false,
        onProgress: (progress) => onProgress?.call(progress * 0.7),
      );

      onProgress?.call(0.8);

      // Migrate settings if needed
      await _migratePluginSettings(currentPlugin, installResult.pluginInfo);

      onProgress?.call(0.9);

      // Replace old plugin
      await uninstallPlugin(pluginId);

      // Rename new plugin
      final newPluginInfo = installResult.pluginInfo;
      newPluginInfo.id = pluginId;

      _installedPlugins[pluginId] = newPluginInfo;
      await _savePluginInfo(newPluginInfo);

      // Enable new version
      if (currentPlugin.isEnabled) {
        await enablePlugin(pluginId);
      }

      onProgress?.call(1.0);

      final result = PluginUpdateResult(
        success: true,
        pluginId: pluginId,
        oldVersion: currentPlugin.version,
        newVersion: newVersion.version,
        updateTime: DateTime.now().difference(currentPlugin.installedAt),
      );

      _emitPluginEvent(PluginEventType.updateCompleted,
          details:
              'Plugin: ${currentPlugin.name} updated to ${newVersion.version}');

      return result;
    } catch (e) {
      // Restore backup on failure
      await _restorePluginBackup(currentPlugin);

      _emitPluginEvent(PluginEventType.updateFailed,
          details: 'Plugin: ${currentPlugin.name}', error: e.toString());
      rethrow;
    }
  }

  /// Check for plugin updates
  Future<List<PluginUpdateInfo>> checkForUpdates() async {
    _emitPluginEvent(PluginEventType.updateCheckStarted);

    try {
      final updates = <PluginUpdateInfo>[];

      for (final plugin in _installedPlugins.values) {
        for (final repository in _pluginRepositories.values) {
          final latestVersion = await repository.getLatestVersion(plugin.id);
          if (latestVersion != null &&
              _isNewerVersion(latestVersion, plugin.version)) {
            updates.add(PluginUpdateInfo(
              pluginId: plugin.id,
              currentVersion: plugin.version,
              latestVersion: latestVersion,
              marketplaceItem:
                  await repository.getPluginInfo(plugin.id, latestVersion),
            ));
          }
        }
      }

      _availableUpdates.clear();
      for (final update in updates) {
        _availableUpdates[update.pluginId] = update;
      }

      _emitPluginEvent(PluginEventType.updateCheckCompleted,
          details: 'Found ${updates.length} updates available');

      return updates;
    } catch (e) {
      _emitPluginEvent(PluginEventType.updateCheckFailed, error: e.toString());
      rethrow;
    }
  }

  /// Execute plugin action
  Future<dynamic> executePluginAction({
    required String pluginId,
    required String actionName,
    Map<String, dynamic>? parameters,
  }) async {
    final sandbox = _pluginSandboxes[pluginId];
    if (sandbox == null) {
      throw PluginException('Plugin $pluginId is not enabled');
    }

    return await _pluginSemaphore.acquire(() async {
      try {
        return await sandbox.executeAction(actionName, parameters ?? {});
      } finally {
        _pluginSemaphore.release();
      }
    });
  }

  /// Get plugin statistics
  PluginStatistics getPluginStatistics() {
    final enabledPlugins =
        _installedPlugins.values.where((p) => p.isEnabled).length;
    final totalPlugins = _installedPlugins.length;
    final marketplaceItems = _marketplaceItems.length;

    return PluginStatistics(
      totalPlugins: totalPlugins,
      enabledPlugins: enabledPlugins,
      marketplaceItems: marketplaceItems,
      availableUpdates: _availableUpdates.length,
      averagePluginSize: _calculateAveragePluginSize(),
      mostPopularCategories: _getMostPopularCategories(),
    );
  }

  /// Export plugin configuration
  Future<String> exportPluginConfiguration({
    bool includeSettings = true,
    bool includePermissions = true,
  }) async {
    final config = <String, dynamic>{};

    if (includeSettings) {
      config['installedPlugins'] =
          _installedPlugins.map((key, value) => MapEntry(key, value.toJson()));
    }

    if (includePermissions) {
      config['permissions'] =
          _pluginPermissions.map((key, value) => MapEntry(key, value.toJson()));
    }

    config['repositories'] =
        _pluginRepositories.map((key, value) => MapEntry(key, value.toJson()));

    return json.encode(config);
  }

  // Private methods

  Future<void> _initializePluginDirectories() async {
    final pluginsDir = Directory(_pluginsDirectory);
    if (!await pluginsDir.exists()) {
      await pluginsDir.create(recursive: true);
    }

    // Create subdirectories
    final subDirs = ['installed', 'backups', 'temp', 'cache'];
    for (final subDir in subDirs) {
      final dir = Directory('$_pluginsDirectory/$subDir');
      if (!await dir.exists()) {
        await dir.create();
      }
    }
  }

  Future<void> _loadInstalledPlugins() async {
    final installedDir = Directory('$_pluginsDirectory/installed');

    if (!await installedDir.exists()) return;

    await for (final entity in installedDir.list()) {
      if (entity is Directory) {
        try {
          final pluginInfo = await _loadPluginInfo(entity.path);
          if (pluginInfo != null) {
            _installedPlugins[pluginInfo.id] = pluginInfo;

            // Re-enable if it was enabled
            if (pluginInfo.isEnabled) {
              await enablePlugin(pluginInfo.id);
            }
          }
        } catch (e) {
          // Skip corrupted plugin
        }
      }
    }
  }

  Future<PluginInfo?> _loadPluginInfo(String pluginPath) async {
    final manifestFile = File('$pluginPath/manifest.json');
    if (!await manifestFile.exists()) return null;

    final manifestContent = await manifestFile.readAsString();
    final manifest = json.decode(manifestContent) as Map<String, dynamic>;

    final infoFile = File('$pluginPath/info.json');
    if (!await infoFile.exists()) return null;

    final infoContent = await infoFile.readAsString();
    final info = json.decode(infoContent) as Map<String, dynamic>;

    return PluginInfo.fromJson(info);
  }

  Future<void> _initializeDefaultSecurityProfiles() async {
    _securityProfiles['trusted'] = PluginSecurityProfile(
      name: 'trusted',
      allowedPermissions: [
        PluginPermission.fileRead,
        PluginPermission.fileWrite,
        PluginPermission.networkAccess,
        PluginPermission.uiAccess,
      ],
      resourceLimits: ResourceLimits(
        maxMemory: 50 * 1024 * 1024, // 50MB
        maxCpuTime: const Duration(seconds: 30),
        maxFileSize: 10 * 1024 * 1024, // 10MB
      ),
      sandboxLevel: SandboxLevel.standard,
    );

    _securityProfiles['restricted'] = PluginSecurityProfile(
      name: 'restricted',
      allowedPermissions: [
        PluginPermission.fileRead,
        PluginPermission.uiAccess,
      ],
      resourceLimits: ResourceLimits(
        maxMemory: 10 * 1024 * 1024, // 10MB
        maxCpuTime: const Duration(seconds: 10),
        maxFileSize: 1 * 1024 * 1024, // 1MB
      ),
      sandboxLevel: SandboxLevel.strict,
    );
  }

  void _startUpdateChecking() {
    _updateCheckTimer = Timer.periodic(_updateCheckInterval, (timer) async {
      try {
        await checkForUpdates();
      } catch (e) {
        // Log update check failure
      }
    });
  }

  Future<void> addRepository(String url) async {
    final repository = PluginRepository(
      url: url,
      name: 'Repository ${url.hashCode}',
      lastUpdated: DateTime.now(),
    );

    _pluginRepositories[url] = repository;
  }

  List<PluginMarketplaceItem> _deduplicateMarketplaceItems(
      List<PluginMarketplaceItem> items) {
    final seen = <String>{};
    return items.where((item) {
      final key = '${item.id}:${item.version}';
      return seen.add(key);
    }).toList();
  }

  void _sortMarketplaceItems(
      List<PluginMarketplaceItem> items, PluginSortOrder sortBy) {
    switch (sortBy) {
      case PluginSortOrder.downloads:
        items.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
        break;
      case PluginSortOrder.rating:
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case PluginSortOrder.recent:
        items.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        break;
      case PluginSortOrder.name:
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }

  Future<Uint8List> _downloadPlugin(
    PluginMarketplaceItem item, {
    required Function(double) onProgress,
  }) async {
    // Implementation would download from marketplace
    // Placeholder for actual download logic
    return Uint8List(0);
  }

  Future<void> _verifyPluginIntegrity(
      Uint8List pluginData, PluginMarketplaceItem item) async {
    final calculatedHash = sha256.convert(pluginData).toString();
    if (calculatedHash != item.checksum) {
      throw PluginException('Plugin integrity check failed');
    }
  }

  Future<Directory> _extractPlugin(
      Uint8List pluginData, String pluginId) async {
    final tempDir = Directory('$_pluginsDirectory/temp/$pluginId');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    // Extract plugin files (placeholder)
    final pluginDir = Directory('$_pluginsDirectory/installed/$pluginId');
    if (!await pluginDir.exists()) {
      await pluginDir.create(recursive: true);
    }

    return pluginDir;
  }

  Future<PluginManifest> _validatePluginManifest(Directory pluginDir) async {
    final manifestFile = File('${pluginDir.path}/manifest.json');
    if (!await manifestFile.exists()) {
      throw PluginException('Plugin manifest not found');
    }

    final manifestContent = await manifestFile.readAsString();
    final manifest = json.decode(manifestContent) as Map<String, dynamic>;

    return PluginManifest.fromJson(manifest);
  }

  Future<void> _setupPluginPermissions(
      PluginInfo plugin, PluginManifest manifest) async {
    final permissions = PluginPermissions(
      pluginId: plugin.id,
      grantedPermissions: manifest.requiredPermissions,
      resourceLimits:
          _securityProfiles[manifest.securityProfile]?.resourceLimits ??
              ResourceLimits.defaultLimits(),
      securityProfile: manifest.securityProfile,
    );

    _pluginPermissions[plugin.id] = permissions;
  }

  Future<PluginSandbox> _createPluginSandbox(PluginInfo plugin) async {
    final securityProfile =
        _securityProfiles[plugin.manifest.securityProfile] ??
            _securityProfiles['restricted']!;

    return PluginSandbox(
      pluginInfo: plugin,
      securityProfile: securityProfile,
      permissions: _pluginPermissions[plugin.id]!,
    );
  }

  Future<void> _savePluginInfo(PluginInfo plugin) async {
    final infoFile = File('${plugin.installPath}/info.json');
    await infoFile.writeAsString(json.encode(plugin.toJson()));
  }

  Future<void> _removePluginInfo(String pluginId) async {
    final plugin = _installedPlugins[pluginId];
    if (plugin != null) {
      final infoFile = File('${plugin.installPath}/info.json');
      if (await infoFile.exists()) {
        await infoFile.delete();
      }
    }
  }

  Future<void> _backupPlugin(PluginInfo plugin) async {
    final backupDir =
        Directory('$_pluginsDirectory/backups/${plugin.id}_${plugin.version}');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    // Copy plugin files to backup
    final pluginDir = Directory(plugin.installPath);
    await _copyDirectory(pluginDir, backupDir);
  }

  Future<void> _restorePluginBackup(PluginInfo plugin) async {
    final backupDir =
        Directory('$_pluginsDirectory/backups/${plugin.id}_${plugin.version}');
    if (await backupDir.exists()) {
      final pluginDir = Directory(plugin.installPath);
      await _copyDirectory(backupDir, pluginDir);
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: true)) {
      final relativePath = path.relative(entity.path, from: source.path);
      final destPath = path.join(destination.path, relativePath);

      if (entity is File) {
        await entity.copy(destPath);
      } else if (entity is Directory) {
        await Directory(destPath).create(recursive: true);
      }
    }
  }

  Future<void> _migratePluginSettings(
      PluginInfo oldPlugin, PluginInfo newPlugin) async {
    // Migrate plugin settings between versions
    // Implementation would copy settings files and migrate data
  }

  bool _isNewerVersion(String newVersion, String currentVersion) {
    // Simple version comparison
    return newVersion.compareTo(currentVersion) > 0;
  }

  double _calculateAveragePluginSize() {
    if (_installedPlugins.isEmpty) return 0.0;

    final totalSize = _installedPlugins.values.fold<int>(0, (sum, plugin) {
      // Calculate plugin directory size
      return sum + 1024 * 1024; // Placeholder: 1MB per plugin
    });

    return totalSize / _installedPlugins.length;
  }

  List<String> _getMostPopularCategories() {
    final categoryCount = <String, int>{};

    for (final item in _marketplaceItems.values) {
      for (final category in item.categories) {
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
    }

    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }

  void _emitPluginEvent(
    PluginEventType type, {
    String? details,
    String? error,
  }) {
    final event = PluginEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _pluginEventController.add(event);
  }

  void dispose() {
    _updateCheckTimer?.cancel();
    _pluginEventController.close();

    // Clean up sandboxes
    for (final sandbox in _pluginSandboxes.values) {
      sandbox.dispose();
    }
  }
}

/// Supporting data classes and enums

enum PluginEventType {
  serviceInitialized,
  initializationFailed,
  marketplaceSearchStarted,
  marketplaceSearchCompleted,
  marketplaceSearchFailed,
  installationStarted,
  installationCompleted,
  installationFailed,
  pluginEnabling,
  pluginEnabled,
  pluginEnableFailed,
  pluginDisabling,
  pluginDisabled,
  pluginDisableFailed,
  uninstallationStarted,
  uninstallationCompleted,
  uninstallationFailed,
  updateStarted,
  updateCompleted,
  updateFailed,
  updateCheckStarted,
  updateCheckCompleted,
  updateCheckFailed,
}

enum PluginSortOrder {
  downloads,
  rating,
  recent,
  name,
}

enum SandboxLevel {
  none, // No sandboxing
  basic, // Basic isolation
  standard, // Standard security
  strict, // Maximum security
}

enum PluginPermission {
  fileRead,
  fileWrite,
  fileDelete,
  networkAccess,
  uiAccess,
  systemInfo,
  pluginCommunication,
  externalProcess,
}

/// Data classes

class PluginInfo {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final PluginManifest manifest;
  final String installPath;
  final DateTime installedAt;
  bool isEnabled;

  PluginInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.manifest,
    required this.installPath,
    required this.installedAt,
    required this.isEnabled,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'description': description,
        'author': author,
        'manifest': manifest.toJson(),
        'installPath': installPath,
        'installedAt': installedAt.toIso8601String(),
        'isEnabled': isEnabled,
      };

  factory PluginInfo.fromJson(Map<String, dynamic> json) {
    return PluginInfo(
      id: json['id'],
      name: json['name'],
      version: json['version'],
      description: json['description'],
      author: json['author'],
      manifest: PluginManifest.fromJson(json['manifest']),
      installPath: json['installPath'],
      installedAt: DateTime.parse(json['installedAt']),
      isEnabled: json['isEnabled'],
    );
  }
}

class PluginManifest {
  final String pluginId;
  final String version;
  final String mainScript;
  final List<String> requiredPermissions;
  final String securityProfile;
  final Map<String, dynamic> metadata;
  final List<PluginHook> hooks;

  PluginManifest({
    required this.pluginId,
    required this.version,
    required this.mainScript,
    required this.requiredPermissions,
    required this.securityProfile,
    required this.metadata,
    required this.hooks,
  });

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'version': version,
        'mainScript': mainScript,
        'requiredPermissions': requiredPermissions,
        'securityProfile': securityProfile,
        'metadata': metadata,
        'hooks': hooks.map((h) => h.toJson()).toList(),
      };

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      pluginId: json['pluginId'],
      version: json['version'],
      mainScript: json['mainScript'],
      requiredPermissions: List<String>.from(json['requiredPermissions']),
      securityProfile: json['securityProfile'],
      metadata: Map<String, dynamic>.from(json['metadata']),
      hooks:
          (json['hooks'] as List).map((h) => PluginHook.fromJson(h)).toList(),
    );
  }
}

class PluginHook {
  final String hookName;
  final String functionName;
  final HookType type;

  PluginHook({
    required this.hookName,
    required this.functionName,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'hookName': hookName,
        'functionName': functionName,
        'type': type.toString(),
      };

  factory PluginHook.fromJson(Map<String, dynamic> json) {
    return PluginHook(
      hookName: json['hookName'],
      functionName: json['functionName'],
      type: HookType.values.firstWhere((t) => t.toString() == json['type']),
    );
  }
}

class PluginMarketplaceItem {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final List<String> categories;
  final double rating;
  final int downloadCount;
  final DateTime lastUpdated;
  final String checksum;
  final int fileSize;
  final Map<String, dynamic> metadata;

  PluginMarketplaceItem({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.categories,
    required this.rating,
    required this.downloadCount,
    required this.lastUpdated,
    required this.checksum,
    required this.fileSize,
    required this.metadata,
  });
}

class PluginRepository {
  final String url;
  final String name;
  final DateTime lastUpdated;

  PluginRepository({
    required this.url,
    required this.name,
    required this.lastUpdated,
  });

  Future<List<PluginMarketplaceItem>> searchPlugins({
    String? query,
    List<String>? categories,
  }) async {
    // Implementation would query repository API
    return [];
  }

  Future<String?> getLatestVersion(String pluginId) async {
    // Implementation would check repository for latest version
    return null;
  }

  Future<PluginMarketplaceItem?> getPluginInfo(
      String pluginId, String version) async {
    // Implementation would fetch plugin info from repository
    return null;
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory PluginRepository.fromJson(Map<String, dynamic> json) {
    return PluginRepository(
      url: json['url'],
      name: json['name'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

class PluginPermissions {
  final String pluginId;
  final List<String> grantedPermissions;
  final ResourceLimits resourceLimits;
  final String securityProfile;

  PluginPermissions({
    required this.pluginId,
    required this.grantedPermissions,
    required this.resourceLimits,
    required this.securityProfile,
  });

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'grantedPermissions': grantedPermissions,
        'resourceLimits': resourceLimits.toJson(),
        'securityProfile': securityProfile,
      };

  factory PluginPermissions.fromJson(Map<String, dynamic> json) {
    return PluginPermissions(
      pluginId: json['pluginId'],
      grantedPermissions: List<String>.from(json['grantedPermissions']),
      resourceLimits: ResourceLimits.fromJson(json['resourceLimits']),
      securityProfile: json['securityProfile'],
    );
  }
}

class PluginSecurityProfile {
  final String name;
  final List<PluginPermission> allowedPermissions;
  final ResourceLimits resourceLimits;
  final SandboxLevel sandboxLevel;

  PluginSecurityProfile({
    required this.name,
    required this.allowedPermissions,
    required this.resourceLimits,
    required this.sandboxLevel,
  });
}

class ResourceLimits {
  final int maxMemory;
  final Duration maxCpuTime;
  final int maxFileSize;

  ResourceLimits({
    required this.maxMemory,
    required this.maxCpuTime,
    required this.maxFileSize,
  });

  factory ResourceLimits.defaultLimits() {
    return ResourceLimits(
      maxMemory: 25 * 1024 * 1024, // 25MB
      maxCpuTime: const Duration(seconds: 20),
      maxFileSize: 5 * 1024 * 1024, // 5MB
    );
  }

  Map<String, dynamic> toJson() => {
        'maxMemory': maxMemory,
        'maxCpuTime': maxCpuTime.inMilliseconds,
        'maxFileSize': maxFileSize,
      };

  factory ResourceLimits.fromJson(Map<String, dynamic> json) {
    return ResourceLimits(
      maxMemory: json['maxMemory'],
      maxCpuTime: Duration(milliseconds: json['maxCpuTime']),
      maxFileSize: json['maxFileSize'],
    );
  }
}

class PluginSandbox {
  final PluginInfo pluginInfo;
  final PluginSecurityProfile securityProfile;
  final PluginPermissions permissions;
  Isolate? _pluginIsolate;
  SendPort? _pluginSendPort;

  PluginSandbox({
    required this.pluginInfo,
    required this.securityProfile,
    required this.permissions,
  });

  Future<void> loadPlugin() async {
    // Create isolate for plugin execution
    final receivePort = ReceivePort();

    _pluginIsolate = await Isolate.spawn(
      _pluginIsolateEntry,
      PluginIsolateConfig(
        pluginPath: pluginInfo.installPath,
        permissions: permissions,
        securityProfile: securityProfile,
        sendPort: receivePort.sendPort,
      ),
    );

    // Wait for plugin to initialize
    final completer = Completer<void>();
    receivePort.listen((message) {
      if (message is SendPort) {
        _pluginSendPort = message;
        completer.complete();
      }
    });

    await completer.future;
  }

  Future<void> unloadPlugin() async {
    _pluginIsolate?.kill();
    _pluginIsolate = null;
    _pluginSendPort = null;
  }

  Future<dynamic> executeAction(
      String actionName, Map<String, dynamic> parameters) async {
    if (_pluginSendPort == null) {
      throw PluginException('Plugin not loaded');
    }

    final receivePort = ReceivePort();
    _pluginSendPort!.send(PluginMessage(
      type: 'execute_action',
      actionName: actionName,
      parameters: parameters,
      replyPort: receivePort.sendPort,
    ));

    final completer = Completer<dynamic>();
    receivePort.listen((message) {
      if (message is PluginResult) {
        if (message.success) {
          completer.complete(message.result);
        } else {
          completer.completeError(
              PluginException(message.error ?? 'Plugin execution failed'));
        }
      }
    });

    return completer.future;
  }

  void dispose() {
    unloadPlugin();
  }
}

class PluginInstallationResult {
  final bool success;
  final String pluginId;
  final PluginInfo pluginInfo;
  final Duration installationTime;

  PluginInstallationResult({
    required this.success,
    required this.pluginId,
    required this.pluginInfo,
    required this.installationTime,
  });
}

class PluginUpdateResult {
  final bool success;
  final String pluginId;
  final String oldVersion;
  final String newVersion;
  final Duration updateTime;

  PluginUpdateResult({
    required this.success,
    required this.pluginId,
    required this.oldVersion,
    required this.newVersion,
    required this.updateTime,
  });
}

class PluginUpdateInfo {
  final String pluginId;
  final String currentVersion;
  final String latestVersion;
  final PluginMarketplaceItem marketplaceItem;

  PluginUpdateInfo({
    required this.pluginId,
    required this.currentVersion,
    required this.latestVersion,
    required this.marketplaceItem,
  });
}

class PluginStatistics {
  final int totalPlugins;
  final int enabledPlugins;
  final int marketplaceItems;
  final int availableUpdates;
  final double averagePluginSize;
  final List<String> mostPopularCategories;

  PluginStatistics({
    required this.totalPlugins,
    required this.enabledPlugins,
    required this.marketplaceItems,
    required this.availableUpdates,
    required this.averagePluginSize,
    required this.mostPopularCategories,
  });
}

/// Isolate communication classes

class PluginIsolateConfig {
  final String pluginPath;
  final PluginPermissions permissions;
  final PluginSecurityProfile securityProfile;
  final SendPort sendPort;

  PluginIsolateConfig({
    required this.pluginPath,
    required this.permissions,
    required this.securityProfile,
    required this.sendPort,
  });
}

class PluginMessage {
  final String type;
  final String? actionName;
  final Map<String, dynamic>? parameters;
  final SendPort? replyPort;

  PluginMessage({
    required this.type,
    this.actionName,
    this.parameters,
    this.replyPort,
  });
}

class PluginResult {
  final bool success;
  final dynamic result;
  final String? error;

  PluginResult({
    required this.success,
    this.result,
    this.error,
  });
}

/// Plugin isolate entry point
void _pluginIsolateEntry(PluginIsolateConfig config) {
  final receivePort = ReceivePort();
  config.sendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is PluginMessage) {
      _handlePluginMessage(message, config);
    }
  });
}

void _handlePluginMessage(PluginMessage message, PluginIsolateConfig config) {
  // Plugin execution logic would go here
  // This is a placeholder for the actual plugin execution
  final result = PluginResult(
    success: true,
    result: {'action': message.actionName, 'executed': true},
  );

  message.replyPort?.send(result);
}

/// Enums

enum HookType {
  beforeAction,
  afterAction,
  onEvent,
  onStartup,
  onShutdown,
}

/// Event classes

class PluginEvent {
  final PluginEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  PluginEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}

/// Exception class

class PluginException implements Exception {
  final String message;

  PluginException(this.message);

  @override
  String toString() => 'PluginException: $message';
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
