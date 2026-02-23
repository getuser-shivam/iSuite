import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:indexed_db' as idb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/config/central_config.dart';
import '../../core/logging/logging_service.dart';
import '../../core/advanced_performance_service.dart';

/// Progressive Web App Service with Offline-First Capabilities
/// Provides modern PWA features including service workers, offline support, app installation, and background sync
class ProgressiveWebAppService {
  static final ProgressiveWebAppService _instance = ProgressiveWebAppService._internal();
  factory ProgressiveWebAppService() => _instance;
  ProgressiveWebAppService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final AdvancedPerformanceService _performanceService = AdvancedPerformanceService();

  StreamController<PWAEvent> _pwaEventController = StreamController.broadcast();
  StreamController<OfflineEvent> _offlineEventController = StreamController.broadcast();
  StreamController<SyncEvent> _syncEventController = StreamController.broadcast();

  Stream<PWAEvent> get pwaEvents => _pwaEventController.stream;
  Stream<OfflineEvent> get offlineEvents => _offlineEventController.stream;
  Stream<SyncEvent> get syncEvents => _syncEventController.stream;

  // Service Worker management
  ServiceWorkerManager? _serviceWorkerManager;
  final Map<String, ServiceWorker> _registeredWorkers = {};

  // Offline storage and caching
  final Map<String, CacheManager> _cacheManagers = {};
  final Map<String, OfflineStorage> _offlineStorages = {};

  // Background sync and queuing
  final Map<String, BackgroundSyncManager> _syncManagers = {};
  final Map<String, SyncQueue> _syncQueues = {};

  // App installation and updates
  AppInstaller? _appInstaller;
  AppUpdater? _appUpdater;

  // Push notifications
  PushNotificationManager? _pushManager;

  // Network monitoring
  NetworkMonitor? _networkMonitor;

  // PWA state
  bool _isInitialized = false;
  bool _isOnline = true;
  bool _isInstalled = false;
  String _updateAvailable = '';

  /// Initialize Progressive Web App service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Progressive Web App service', 'ProgressiveWebAppService');

      // Register with CentralConfig
      await _config.registerComponent(
        'ProgressiveWebAppService',
        '2.0.0',
        'Progressive Web App service with offline-first capabilities, service workers, and app installation',
        dependencies: ['CentralConfig', 'AdvancedPerformanceService'],
        parameters: {
          // Core PWA settings
          'pwa.enabled': true,
          'pwa.offline_first': true,
          'pwa.service_worker_enabled': true,
          'pwa.background_sync_enabled': true,
          'pwa.push_notifications_enabled': true,

          // Service Worker configuration
          'pwa.sw.scope': '/',
          'pwa.sw.update_strategy': 'immediate', // immediate, on_next_load, manual
          'pwa.sw.cache_strategy': 'network_first', // cache_first, network_first, cache_only, network_only
          'pwa.sw.cache_name': 'isuite-v1',

          // Offline storage
          'pwa.offline.storage_enabled': true,
          'pwa.offline.cache_max_size': 100 * 1024 * 1024, // 100MB
          'pwa.offline.sync_on_reconnect': true,
          'pwa.offline.fallback_page': '/offline.html',

          // Background sync
          'pwa.sync.max_retries': 3,
          'pwa.sync.retry_delay': 5000, // 5 seconds
          'pwa.sync.queue_max_size': 1000,
          'pwa.sync.network_timeout': 30000, // 30 seconds

          // App installation
          'pwa.install.prompt_strategy': 'auto', // auto, manual, on_interaction
          'pwa.install.related_apps': true,
          'pwa.install.shortcuts': true,

          // Push notifications
          'pwa.push.vapid_key': '',
          'pwa.push.default_icon': '/icons/notification-icon.png',
          'pwa.push.badge': '/icons/badge.png',
          'pwa.push.silent': false,

          // Network monitoring
          'pwa.network.online_check_interval': 30000, // 30 seconds
          'pwa.network.offline_timeout': 5000, // 5 seconds

          // Performance optimization
          'pwa.performance.lazy_loading': true,
          'pwa.performance.code_splitting': true,
          'pwa.performance.preloading': true,
          'pwa.performance.bundle_optimization': true,

          // Security
          'pwa.security.https_required': true,
          'pwa.security.cors_enabled': true,
          'pwa.security.content_security_policy': true,
        }
      );

      // Initialize PWA components
      await _initializeServiceWorkers();
      await _initializeOfflineStorage();
      await _initializeBackgroundSync();
      await _initializeAppInstallation();
      await _initializePushNotifications();
      await _initializeNetworkMonitoring();

      // Check current PWA state
      await _checkPWAState();

      // Setup PWA monitoring
      _setupPWAMonitoring();

      _isInitialized = true;
      _logger.info('Progressive Web App service initialized successfully', 'ProgressiveWebAppService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Progressive Web App service', 'ProgressiveWebAppService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Register service worker
  Future<bool> registerServiceWorker(String scriptUrl, {
    String scope = '/',
    ServiceWorkerUpdateStrategy updateStrategy = ServiceWorkerUpdateStrategy.immediate,
  }) async {
    try {
      if (!kIsWeb) {
        _logger.info('Service workers not supported on this platform', 'ProgressiveWebAppService');
        return false;
      }

      final registration = await html.window.navigator.serviceWorker!.register(
        scriptUrl,
        {
          'scope': scope,
        },
      );

      final worker = ServiceWorker(
        scriptUrl: scriptUrl,
        scope: scope,
        state: ServiceWorkerState.installing,
        registration: registration,
        updateStrategy: updateStrategy,
      );

      _registeredWorkers[scriptUrl] = worker;

      // Listen for state changes
      registration.onUpdateFound.listen((event) {
        _handleServiceWorkerUpdate(registration);
      });

      registration.onStateChange.listen((event) {
        _handleServiceWorkerStateChange(registration, event);
      });

      _emitPWAEvent(PWAEventType.serviceWorkerRegistered, data: {
        'script_url': scriptUrl,
        'scope': scope,
        'update_strategy': updateStrategy.toString(),
      });

      _logger.info('Service worker registered: $scriptUrl', 'ProgressiveWebAppService');
      return true;

    } catch (e) {
      _logger.error('Service worker registration failed: $scriptUrl', 'ProgressiveWebAppService', error: e);
      return false;
    }
  }

  /// Cache resources for offline use
  Future<void> cacheResources(List<String> urls, {
    String cacheName = 'isuite-resources',
    CacheStrategy strategy = CacheStrategy.cacheFirst,
  }) async {
    try {
      if (!kIsWeb) return;

      final cache = await html.window.caches!.open(cacheName);

      for (final url in urls) {
        try {
          final response = await html.window.fetch(url);
          await cache.put(url, response);
        } catch (e) {
          _logger.warning('Failed to cache resource: $url', 'ProgressiveWebAppService', error: e);
        }
      }

      _emitPWAEvent(PWAEventType.resourcesCached, data: {
        'cache_name': cacheName,
        'resource_count': urls.length,
        'strategy': strategy.toString(),
      });

      _logger.info('Cached ${urls.length} resources in $cacheName', 'ProgressiveWebAppService');

    } catch (e) {
      _logger.error('Resource caching failed', 'ProgressiveWebAppService', error: e);
    }
  }

  /// Queue operation for background sync
  Future<String> queueForSync(String operationId, Map<String, dynamic> data, {
    String syncTag = 'default',
    Duration? delay,
  }) async {
    try {
      final queue = _syncQueues[syncTag] ??= SyncQueue(tag: syncTag);

      final operation = SyncOperation(
        id: operationId,
        data: data,
        queuedAt: DateTime.now(),
        delay: delay,
        retryCount: 0,
      );

      await queue.add(operation);

      _emitSyncEvent(SyncEventType.operationQueued, data: {
        'operation_id': operationId,
        'sync_tag': syncTag,
        'delay': delay?.inSeconds,
      });

      // If online, try to sync immediately
      if (_isOnline) {
        await _processSyncQueue(syncTag);
      }

      return operationId;

    } catch (e) {
      _logger.error('Failed to queue operation for sync: $operationId', 'ProgressiveWebAppService', error: e);
      rethrow;
    }
  }

  /// Get cached data for offline use
  Future<dynamic> getCachedData(String key, {String cacheName = 'isuite-data'}) async {
    try {
      if (!kIsWeb) return null;

      final cache = await html.window.caches!.open(cacheName);
      final response = await cache.match(key);

      if (response != null) {
        final data = await response.json();
        return data;
      }

      return null;

    } catch (e) {
      _logger.error('Failed to get cached data: $key', 'ProgressiveWebAppService', error: e);
      return null;
    }
  }

  /// Store data for offline use
  Future<void> storeOfflineData(String key, dynamic data, {
    String cacheName = 'isuite-data',
  }) async {
    try {
      if (!kIsWeb) return;

      final cache = await html.window.caches!.open(cacheName);
      final response = html.Response.json(data);
      await cache.put(key, response);

      _emitPWAEvent(PWAEventType.dataStoredOffline, data: {
        'key': key,
        'cache_name': cacheName,
      });

    } catch (e) {
      _logger.error('Failed to store offline data: $key', 'ProgressiveWebAppService', error: e);
    }
  }

  /// Check if app can be installed
  Future<PWAInstallResult> canInstallApp() async {
    try {
      if (!kIsWeb) {
        return PWAInstallResult(
          canInstall: false,
          reason: 'Not running on web platform',
        );
      }

      final beforeInstallPrompt = html.window.event as html.BeforeInstallPromptEvent?;
      final isStandalone = html.window.matchMedia('(display-mode: standalone)').matches;

      if (beforeInstallPrompt != null && !isStandalone) {
        return PWAInstallResult(
          canInstall: true,
          reason: 'App can be installed',
          installPrompt: beforeInstallPrompt,
        );
      }

      return PWAInstallResult(
        canInstall: false,
        reason: isStandalone ? 'App already installed' : 'Installation not available',
      );

    } catch (e) {
      _logger.error('Failed to check app installation capability', 'ProgressiveWebAppService', error: e);

      return PWAInstallResult(
        canInstall: false,
        reason: 'Error checking installation capability',
      );
    }
  }

  /// Install the app
  Future<bool> installApp() async {
    try {
      final installResult = await canInstallApp();

      if (!installResult.canInstall || installResult.installPrompt == null) {
        return false;
      }

      // Show installation prompt
      installResult.installPrompt!.prompt();

      // Wait for user response
      final choice = await installResult.installPrompt!.userChoice;

      final installed = choice.outcome == 'accepted';

      if (installed) {
        _isInstalled = true;
        _emitPWAEvent(PWAEventType.appInstalled, data: {
          'platform': 'web',
        });
      }

      return installed;

    } catch (e) {
      _logger.error('App installation failed', 'ProgressiveWebAppService', error: e);
      return false;
    }
  }

  /// Subscribe to push notifications
  Future<PushSubscriptionResult> subscribeToPushNotifications({
    String? vapidKey,
    String? serverKey,
  }) async {
    try {
      if (!kIsWeb || _pushManager == null) {
        return PushSubscriptionResult(
          success: false,
          error: 'Push notifications not supported',
        );
      }

      final subscription = await _pushManager!.subscribe(
        vapidKey: vapidKey,
        serverKey: serverKey,
      );

      _emitPWAEvent(PWAEventType.pushSubscribed, data: {
        'endpoint': subscription.endpoint,
      });

      return PushSubscriptionResult(
        success: true,
        subscription: subscription,
      );

    } catch (e) {
      _logger.error('Push notification subscription failed', 'ProgressiveWebAppService', error: e);

      return PushSubscriptionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Send push notification
  Future<bool> sendPushNotification(String title, String body, {
    String? icon,
    String? badge,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (_pushManager == null) return false;

      await _pushManager!.sendNotification(
        title: title,
        body: body,
        icon: icon,
        badge: badge,
        data: data,
      );

      _emitPWAEvent(PWAEventType.pushSent, data: {
        'title': title,
        'has_data': data != null,
      });

      return true;

    } catch (e) {
      _logger.error('Push notification send failed', 'ProgressiveWebAppService', error: e);
      return false;
    }
  }

  /// Get PWA status and capabilities
  Future<PWAStatus> getPWAStatus() async {
    try {
      final installResult = await canInstallApp();
      final cacheStatus = await _getCacheStatus();
      final syncStatus = await _getSyncStatus();
      final networkStatus = await _getNetworkStatus();

      return PWAStatus(
        isInstalled: _isInstalled,
        canInstall: installResult.canInstall,
        isOnline: _isOnline,
        serviceWorkerRegistered: _registeredWorkers.isNotEmpty,
        cacheEnabled: cacheStatus.enabled,
        backgroundSyncEnabled: syncStatus.enabled,
        pushNotificationsEnabled: _pushManager != null,
        offlineStorageSize: cacheStatus.size,
        syncQueueSize: syncStatus.queueSize,
        networkType: networkStatus.type,
        lastUpdated: DateTime.now(),
      );

    } catch (e) {
      _logger.error('Failed to get PWA status', 'ProgressiveWebAppService', error: e);

      return PWAStatus(
        isInstalled: false,
        canInstall: false,
        isOnline: true,
        serviceWorkerRegistered: false,
        cacheEnabled: false,
        backgroundSyncEnabled: false,
        pushNotificationsEnabled: false,
        offlineStorageSize: 0,
        syncQueueSize: 0,
        networkType: 'unknown',
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Clear all caches and offline data
  Future<void> clearOfflineData() async {
    try {
      if (!kIsWeb) return;

      final cacheNames = await html.window.caches!.keys();

      for (final cacheName in cacheNames) {
        await html.window.caches!.delete(cacheName);
      }

      // Clear IndexedDB data
      await _clearIndexedDB();

      _emitPWAEvent(PWAEventType.offlineDataCleared);

      _logger.info('Offline data cleared successfully', 'ProgressiveWebAppService');

    } catch (e) {
      _logger.error('Failed to clear offline data', 'ProgressiveWebAppService', error: e);
    }
  }

  // Core implementation methods (simplified)

  Future<void> _initializeServiceWorkers() async {
    _serviceWorkerManager = ServiceWorkerManager();

    _logger.info('Service worker management initialized', 'ProgressiveWebAppService');
  }

  Future<void> _initializeOfflineStorage() async {
    if (kIsWeb) {
      _cacheManagers['default'] = WebCacheManager();
    }

    _offlineStorages['default'] = OfflineStorage(
      maxSize: _config.getParameter('pwa.offline.cache_max_size', defaultValue: 100 * 1024 * 1024),
      strategy: CacheStrategy.networkFirst,
    );

    _logger.info('Offline storage initialized', 'ProgressiveWebAppService');
  }

  Future<void> _initializeBackgroundSync() async {
    _syncManagers['default'] = BackgroundSyncManager();
    _syncQueues['default'] = SyncQueue(tag: 'default');

    _logger.info('Background sync initialized', 'ProgressiveWebAppService');
  }

  Future<void> _initializeAppInstallation() async {
    if (kIsWeb) {
      _appInstaller = WebAppInstaller();
      _appUpdater = WebAppUpdater();
    }

    _logger.info('App installation initialized', 'ProgressiveWebAppService');
  }

  Future<void> _initializePushNotifications() async {
    if (kIsWeb) {
      _pushManager = WebPushNotificationManager(
        vapidKey: _config.getParameter('pwa.push.vapid_key', defaultValue: ''),
      );
    }

    _logger.info('Push notifications initialized', 'ProgressiveWebAppService');
  }

  Future<void> _initializeNetworkMonitoring() async {
    _networkMonitor = NetworkMonitor();

    // Listen for network changes
    _networkMonitor!.networkChanges.listen((isOnline) {
      _handleNetworkChange(isOnline);
    });

    _logger.info('Network monitoring initialized', 'ProgressiveWebAppService');
  }

  Future<void> _checkPWAState() async {
    if (!kIsWeb) return;

    // Check if app is installed
    _isInstalled = html.window.matchMedia('(display-mode: standalone)').matches;

    // Check online status
    _isOnline = html.window.navigator.onLine ?? true;
  }

  void _setupPWAMonitoring() {
    // Setup periodic PWA health checks
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _performPWAHealthCheck();
    });
  }

  Future<void> _performPWAHealthCheck() async {
    try {
      // Check service worker status
      await _checkServiceWorkerHealth();

      // Check cache status
      await _checkCacheHealth();

      // Check sync queue health
      await _checkSyncHealth();

    } catch (e) {
      _logger.error('PWA health check failed', 'ProgressiveWebAppService', error: e);
    }
  }

  // Helper methods (simplified implementations)

  Future<void> _handleServiceWorkerUpdate(html.ServiceWorkerRegistration registration) async {}
  Future<void> _handleServiceWorkerStateChange(html.ServiceWorkerRegistration registration, html.Event event) async {}
  Future<void> _handleNetworkChange(bool isOnline) async {
    _isOnline = isOnline;

    _emitOfflineEvent(
      isOnline ? OfflineEventType.backOnline : OfflineEventType.wentOffline,
      data: {'timestamp': DateTime.now()},
    );

    // Process sync queue if back online
    if (isOnline) {
      await _processAllSyncQueues();
    }
  }

  Future<void> _processSyncQueue(String tag) async {}
  Future<void> _processAllSyncQueues() async {}
  Future<void> _checkServiceWorkerHealth() async {}
  Future<void> _checkCacheHealth() async {}
  Future<void> _checkSyncHealth() async {}
  Future<CacheStatus> _getCacheStatus() async => CacheStatus(enabled: true, size: 0);
  Future<SyncStatus> _getSyncStatus() async => SyncStatus(enabled: true, queueSize: 0);
  Future<NetworkStatus> _getNetworkStatus() async => NetworkStatus(type: 'unknown');
  Future<void> _clearIndexedDB() async {}

  // Event emission methods
  void _emitPWAEvent(PWAEventType type, {Map<String, dynamic>? data}) {
    final event = PWAEvent(type: type, timestamp: DateTime.now(), data: data ?? {});
    _pwaEventController.add(event);
  }

  void _emitOfflineEvent(OfflineEventType type, {Map<String, dynamic>? data}) {
    final event = OfflineEvent(type: type, timestamp: DateTime.now(), data: data ?? {});
    _offlineEventController.add(event);
  }

  void _emitSyncEvent(SyncEventType type, {Map<String, dynamic>? data}) {
    final event = SyncEvent(type: type, timestamp: DateTime.now(), data: data ?? {});
    _syncEventController.add(event);
  }

  /// Dispose resources
  void dispose() {
    _pwaEventController.close();
    _offlineEventController.close();
    _syncEventController.close();
  }
}

/// Supporting data classes and enums

enum PWAEventType {
  serviceWorkerRegistered,
  serviceWorkerUpdated,
  resourcesCached,
  dataStoredOffline,
  offlineDataCleared,
  appInstalled,
  appUpdated,
  pushSubscribed,
  pushSent,
  updateAvailable,
}

enum OfflineEventType {
  wentOffline,
  backOnline,
  offlineDataSynced,
  syncFailed,
}

enum SyncEventType {
  operationQueued,
  operationSynced,
  operationFailed,
  queueProcessed,
}

enum ServiceWorkerState {
  installing,
  installed,
  activating,
  activated,
  redundant,
}

enum ServiceWorkerUpdateStrategy {
  immediate,
  onNextLoad,
  manual,
}

enum CacheStrategy {
  cacheFirst,
  networkFirst,
  cacheOnly,
  networkOnly,
  staleWhileRevalidate,
}

class ServiceWorker {
  final String scriptUrl;
  final String scope;
  ServiceWorkerState state;
  final html.ServiceWorkerRegistration registration;
  final ServiceWorkerUpdateStrategy updateStrategy;

  ServiceWorker({
    required this.scriptUrl,
    required this.scope,
    required this.state,
    required this.registration,
    required this.updateStrategy,
  });
}

class ServiceWorkerManager {
  // Service worker management implementation
}

class CacheManager {
  // Cache management implementation
}

class WebCacheManager extends CacheManager {
  // Web-specific cache management
}

class OfflineStorage {
  final int maxSize;
  final CacheStrategy strategy;

  OfflineStorage({
    required this.maxSize,
    required this.strategy,
  });
}

class BackgroundSyncManager {
  // Background sync management implementation
}

class SyncQueue {
  final String tag;
  final List<SyncOperation> _operations = [];

  SyncQueue({required this.tag});

  Future<void> add(SyncOperation operation) async {
    _operations.add(operation);
  }

  Future<SyncOperation?> next() async {
    return _operations.isNotEmpty ? _operations.removeAt(0) : null;
  }
}

class SyncOperation {
  final String id;
  final Map<String, dynamic> data;
  final DateTime queuedAt;
  final Duration? delay;
  int retryCount;

  SyncOperation({
    required this.id,
    required this.data,
    required this.queuedAt,
    this.delay,
    this.retryCount = 0,
  });
}

class AppInstaller {
  // App installation implementation
}

class WebAppInstaller extends AppInstaller {
  // Web-specific app installation
}

class AppUpdater {
  // App update management
}

class WebAppUpdater extends AppUpdater {
  // Web-specific app updates
}

class PushNotificationManager {
  // Push notification management
}

class WebPushNotificationManager extends PushNotificationManager {
  final String? vapidKey;

  WebPushNotificationManager({this.vapidKey});

  Future<html.PushSubscription> subscribe({String? vapidKey, String? serverKey}) async {
    // Web push subscription implementation
    throw UnimplementedError();
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    String? icon,
    String? badge,
    Map<String, dynamic>? data,
  }) async {
    // Send push notification implementation
  }
}

class NetworkMonitor {
  final StreamController<bool> _networkChanges = StreamController.broadcast();

  Stream<bool> get networkChanges => _networkChanges.stream;

  void dispose() {
    _networkChanges.close();
  }
}

class PWAInstallResult {
  final bool canInstall;
  final String reason;
  final html.BeforeInstallPromptEvent? installPrompt;

  PWAInstallResult({
    required this.canInstall,
    required this.reason,
    this.installPrompt,
  });
}

class PushSubscriptionResult {
  final bool success;
  final html.PushSubscription? subscription;
  final String? error;

  PushSubscriptionResult({
    required this.success,
    this.subscription,
    this.error,
  });
}

class PWAStatus {
  final bool isInstalled;
  final bool canInstall;
  final bool isOnline;
  final bool serviceWorkerRegistered;
  final bool cacheEnabled;
  final bool backgroundSyncEnabled;
  final bool pushNotificationsEnabled;
  final int offlineStorageSize;
  final int syncQueueSize;
  final String networkType;
  final DateTime lastUpdated;

  PWAStatus({
    required this.isInstalled,
    required this.canInstall,
    required this.isOnline,
    required this.serviceWorkerRegistered,
    required this.cacheEnabled,
    required this.backgroundSyncEnabled,
    required this.pushNotificationsEnabled,
    required this.offlineStorageSize,
    required this.syncQueueSize,
    required this.networkType,
    required this.lastUpdated,
  });
}

class CacheStatus {
  final bool enabled;
  final int size;

  CacheStatus({
    required this.enabled,
    required this.size,
  });
}

class SyncStatus {
  final bool enabled;
  final int queueSize;

  SyncStatus({
    required this.enabled,
    required this.queueSize,
  });
}

class NetworkStatus {
  final String type;

  NetworkStatus({
    required this.type,
  });
}

class PWAEvent {
  final PWAEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  PWAEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class OfflineEvent {
  final OfflineEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  OfflineEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class SyncEvent {
  final SyncEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  SyncEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}
