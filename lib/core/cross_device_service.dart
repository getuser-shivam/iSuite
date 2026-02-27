import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/central_config.dart';
import 'logging_service.dart';

/// Cross-Device Optimization Service for iSuite
/// Optimizes the app experience for Android, iOS, and Windows
/// Handles platform-specific features and provides unified API
class CrossDeviceService {
  static final CrossDeviceService _instance = CrossDeviceService._internal();
  factory CrossDeviceService() => _instance;

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Connectivity _connectivity = Connectivity();

  // Device information
  BaseDeviceInfo? _deviceInfo;
  bool _isInitialized = false;

  // Platform-specific optimizations
  final Map<TargetPlatform, PlatformOptimization> _platformOptimizations = {};

  // Connectivity monitoring
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;

  // Platform-specific features
  final Map<String, dynamic> _platformCapabilities = {};

  final StreamController<DeviceEvent> _deviceEventController = StreamController.broadcast();

  Stream<DeviceEvent> get deviceEvents => _deviceEventController.stream;

  CrossDeviceService._internal();

  /// Initialize cross-device service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register with CentralConfig
      await _config.registerComponent(
        'CrossDeviceService',
        '1.0.0',
        'Cross-device optimization service for Android, iOS, and Windows platforms',
        dependencies: ['CentralConfig', 'LoggingService'],
        parameters: {
          // Platform optimizations
          'device.android.optimization_enabled': true,
          'device.ios.optimization_enabled': true,
          'device.windows.optimization_enabled': true,

          // Performance settings
          'device.performance.adaptive_enabled': true,
          'device.performance.low_end_threshold_mb': 1024, // 1GB RAM
          'device.performance.high_end_threshold_mb': 4096, // 4GB RAM

          // UI adaptations
          'device.ui.adaptive_layout_enabled': true,
          'device.ui.touch_target_min_size': 44.0,
          'device.ui.font_scale_adaptive': true,

          // Platform features
          'device.android.gestures_enabled': true,
          'device.ios.haptic_feedback_enabled': true,
          'device.windows.keyboard_shortcuts_enabled': true,

          // Connectivity
          'device.connectivity.monitoring_enabled': true,
          'device.connectivity.auto_retry_enabled': true,

          // Storage optimizations
          'device.storage.cache_optimization_enabled': true,
          'device.storage.offline_sync_enabled': true,

          // Security adaptations
          'device.security.biometric_enabled': true,
          'device.security.secure_storage_enabled': true,
        }
      );

      // Get device information
      await _loadDeviceInfo();

      // Setup platform optimizations
      await _setupPlatformOptimizations();

      // Setup connectivity monitoring
      await _setupConnectivityMonitoring();

      // Load platform capabilities
      await _loadPlatformCapabilities();

      _isInitialized = true;
      _emitDeviceEvent(DeviceEventType.initialized);

      _logger.info('Cross-Device Service initialized for ${Platform.operatingSystem}', 'CrossDeviceService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Cross-Device Service', 'CrossDeviceService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get device information
  BaseDeviceInfo? get deviceInfo => _deviceInfo;

  /// Get current platform
  TargetPlatform get currentPlatform {
    if (Platform.isAndroid) return TargetPlatform.android;
    if (Platform.isIOS) return TargetPlatform.iOS;
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isMacOS) return TargetPlatform.macOS;
    if (Platform.isLinux) return TargetPlatform.linux;
    return TargetPlatform.fuchsia; // Fallback
  }

  /// Check if platform is supported
  bool isPlatformSupported(TargetPlatform platform) {
    return [TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.windows].contains(platform);
  }

  /// Get platform-specific optimizations
  PlatformOptimization getPlatformOptimization(TargetPlatform platform) {
    return _platformOptimizations[platform] ?? PlatformOptimization.defaultFor(platform);
  }

  /// Get current platform optimization
  PlatformOptimization get currentOptimization => getPlatformOptimization(currentPlatform);

  /// Check device capability
  bool hasCapability(String capability) {
    return _platformCapabilities[capability] == true;
  }

  /// Get adaptive UI settings
  Future<AdaptiveUISettings> getAdaptiveUISettings(BuildContext context) async {
    final platform = currentPlatform;
    final optimization = getPlatformOptimization(platform);

    // Get device-specific metrics
    final screenSize = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final orientation = MediaQuery.of(context).orientation;

    // Calculate adaptive values
    final touchTargetSize = await _calculateAdaptiveTouchTarget();
    final fontScale = await _calculateAdaptiveFontScale(context);
    final layoutDensity = _calculateAdaptiveLayoutDensity(screenSize);

    return AdaptiveUISettings(
      platform: platform,
      screenSize: screenSize,
      pixelRatio: pixelRatio,
      orientation: orientation,
      touchTargetSize: touchTargetSize,
      fontScale: fontScale,
      layoutDensity: layoutDensity,
      optimization: optimization,
      hapticEnabled: hasCapability('haptic_feedback'),
      keyboardShortcutsEnabled: hasCapability('keyboard_shortcuts'),
    );
  }

  /// Get performance recommendations
  Future<PerformanceRecommendation> getPerformanceRecommendation() async {
    final deviceMemory = await _getDeviceMemory();
    final deviceCPU = await _getDeviceCPUInfo();
    final connectivity = _currentConnectivity;

    // Analyze device capabilities
    final isLowEnd = deviceMemory < (await _config.getParameter<int>('device.performance.low_end_threshold_mb', defaultValue: 1024));
    final isHighEnd = deviceMemory > (await _config.getParameter<int>('device.performance.high_end_threshold_mb', defaultValue: 4096));

    final recommendations = <String>[];

    if (isLowEnd) {
      recommendations.addAll([
        'Enable memory optimization',
        'Reduce image quality',
        'Disable heavy animations',
        'Use smaller cache sizes',
        'Limit concurrent operations',
      ]);
    } else if (isHighEnd) {
      recommendations.addAll([
        'Enable high-quality graphics',
        'Increase cache sizes',
        'Enable advanced features',
        'Allow more concurrent operations',
      ]);
    }

    // Connectivity-based recommendations
    if (connectivity == ConnectivityResult.mobile) {
      recommendations.addAll([
        'Optimize for mobile data usage',
        'Use compressed images',
        'Enable offline mode',
      ]);
    } else if (connectivity == ConnectivityResult.wifi) {
      recommendations.addAll([
        'Enable high-quality content',
        'Allow larger downloads',
        'Enable real-time features',
      ]);
    }

    return PerformanceRecommendation(
      deviceMemoryMB: deviceMemory,
      deviceCPU: deviceCPU,
      connectivity: connectivity,
      isLowEnd: isLowEnd,
      isHighEnd: isHighEnd,
      recommendations: recommendations,
    );
  }

  /// Execute platform-specific action
  Future<void> executePlatformAction(PlatformAction action, [Map<String, dynamic>? parameters]) async {
    final platform = currentPlatform;

    try {
      switch (platform) {
        case TargetPlatform.android:
          await _executeAndroidAction(action, parameters);
          break;
        case TargetPlatform.iOS:
          await _executeIOSAction(action, parameters);
          break;
        case TargetPlatform.windows:
          await _executeWindowsAction(action, parameters);
          break;
        default:
          _logger.warning('Platform action not supported: $platform', 'CrossDeviceService');
      }

      _emitDeviceEvent(DeviceEventType.platformActionExecuted,
        data: {'action': action.toString(), 'platform': platform.toString()});

    } catch (e) {
      _logger.error('Platform action failed: $action', 'CrossDeviceService', error: e);
      rethrow;
    }
  }

  /// Get platform-specific shortcuts
  Map<LogicalKeyboardKey, Intent> getPlatformShortcuts(BuildContext context) {
    final platform = currentPlatform;

    switch (platform) {
      case TargetPlatform.windows:
        return _getWindowsShortcuts();
      case TargetPlatform.macOS:
        return _getMacShortcuts();
      default:
        return {};
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current connectivity status
  ConnectivityResult get connectivity => _currentConnectivity;

  /// Private helper methods

  Future<void> _loadDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        _deviceInfo = await _deviceInfo.androidInfo;
      } else if (Platform.isIOS) {
        _deviceInfo = await _deviceInfo.iosInfo;
      } else if (Platform.isWindows) {
        _deviceInfo = await _deviceInfo.windowsInfo;
      } else if (Platform.isMacOS) {
        _deviceInfo = await _deviceInfo.macOsInfo;
      } else if (Platform.isLinux) {
        _deviceInfo = await _deviceInfo.linuxInfo;
      }

      _logger.debug('Device info loaded for ${Platform.operatingSystem}', 'CrossDeviceService');

    } catch (e) {
      _logger.error('Failed to load device info', 'CrossDeviceService', error: e);
    }
  }

  Future<void> _setupPlatformOptimizations() async {
    // Android optimizations
    _platformOptimizations[TargetPlatform.android] = PlatformOptimization(
      platform: TargetPlatform.android,
      recommendedCacheSize: 50 * 1024 * 1024, // 50MB
      recommendedThreadPoolSize: 4,
      enableHapticFeedback: true,
      enableGestures: true,
      enableBiometric: true,
      preferredImageFormat: 'webp',
      memoryOptimizationLevel: MemoryOptimizationLevel.moderate,
    );

    // iOS optimizations
    _platformOptimizations[TargetPlatform.iOS] = PlatformOptimization(
      platform: TargetPlatform.iOS,
      recommendedCacheSize: 100 * 1024 * 1024, // 100MB
      recommendedThreadPoolSize: 2,
      enableHapticFeedback: true,
      enableGestures: true,
      enableBiometric: true,
      preferredImageFormat: 'heic',
      memoryOptimizationLevel: MemoryOptimizationLevel.aggressive,
    );

    // Windows optimizations
    _platformOptimizations[TargetPlatform.windows] = PlatformOptimization(
      platform: TargetPlatform.windows,
      recommendedCacheSize: 200 * 1024 * 1024, // 200MB
      recommendedThreadPoolSize: 8,
      enableHapticFeedback: false,
      enableGestures: false,
      enableBiometric: false,
      preferredImageFormat: 'png',
      memoryOptimizationLevel: MemoryOptimizationLevel.conservative,
    );
  }

  Future<void> _setupConnectivityMonitoring() async {
    final monitoringEnabled = await _config.getParameter<bool>('device.connectivity.monitoring_enabled', defaultValue: true);
    if (!monitoringEnabled) return;

    _currentConnectivity = await _connectivity.checkConnectivity();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final previous = _currentConnectivity;
      _currentConnectivity = result;

      if (previous != result) {
        _emitDeviceEvent(DeviceEventType.connectivityChanged,
          data: {'from': previous.toString(), 'to': result.toString()});
        _logger.info('Connectivity changed: $previous -> $result', 'CrossDeviceService');
      }
    });
  }

  Future<void> _loadPlatformCapabilities() async {
    final platform = currentPlatform;

    switch (platform) {
      case TargetPlatform.android:
        _platformCapabilities.addAll({
          'haptic_feedback': true,
          'biometric_auth': true,
          'gesture_navigation': true,
          'split_screen': true,
          'picture_in_picture': true,
          'notification_channels': true,
        });
        break;

      case TargetPlatform.iOS:
        _platformCapabilities.addAll({
          'haptic_feedback': true,
          'biometric_auth': true,
          'gesture_navigation': true,
          'split_screen': false,
          'picture_in_picture': true,
          'notification_channels': false,
        });
        break;

      case TargetPlatform.windows:
        _platformCapabilities.addAll({
          'haptic_feedback': false,
          'biometric_auth': false,
          'gesture_navigation': false,
          'split_screen': true,
          'picture_in_picture': false,
          'notification_channels': false,
          'keyboard_shortcuts': true,
          'window_management': true,
        });
        break;

      default:
        break;
    }
  }

  Future<double> _calculateAdaptiveTouchTarget() async {
    final baseSize = await _config.getParameter<double>('device.ui.touch_target_min_size', defaultValue: 44.0);
    final platform = currentPlatform;

    // Adjust for platform conventions
    switch (platform) {
      case TargetPlatform.iOS:
        return baseSize; // iOS standard
      case TargetPlatform.android:
        return baseSize * 1.1; // Slightly larger for Android
      case TargetPlatform.windows:
        return baseSize * 1.2; // Larger for mouse/keyboard interaction
      default:
        return baseSize;
    }
  }

  Future<double> _calculateAdaptiveFontScale(BuildContext context) async {
    if (!await _config.getParameter<bool>('device.ui.font_scale_adaptive', defaultValue: true)) {
      return 1.0;
    }

    final mediaQuery = MediaQuery.of(context);
    final platform = currentPlatform;

    // Base scale from system
    double scale = mediaQuery.textScaleFactor;

    // Platform adjustments
    switch (platform) {
      case TargetPlatform.windows:
        // Windows users often prefer slightly larger text
        scale *= 1.05;
        break;
      case TargetPlatform.android:
        // Android devices vary widely, keep system default
        break;
      case TargetPlatform.iOS:
        // iOS text is generally well-sized
        break;
      default:
        break;
    }

    // Clamp to reasonable range
    return scale.clamp(0.8, 2.0);
  }

  LayoutDensity _calculateAdaptiveLayoutDensity(Size screenSize) {
    final platform = currentPlatform;

    // Determine density based on screen size and platform
    if (screenSize.width > 1200) {
      return LayoutDensity.comfortable;
    } else if (screenSize.width > 600) {
      return LayoutDensity.standard;
    } else {
      return LayoutDensity.compact;
    }
  }

  Future<int> _getDeviceMemory() async {
    // Estimate based on device info and platform defaults
    if (_deviceInfo is AndroidDeviceInfo) {
      // Could get more precise info on Android
      return 2048; // Default estimate
    } else if (_deviceInfo is IosDeviceInfo) {
      // iOS devices vary widely
      return 4096; // Default estimate
    } else {
      // Windows/Linux - check system info
      return 8192; // Default estimate for desktop
    }
  }

  Future<String> _getDeviceCPUInfo() async {
    // Basic CPU info estimation
    final platform = currentPlatform;
    switch (platform) {
      case TargetPlatform.android:
        return 'ARM-based';
      case TargetPlatform.iOS:
        return 'Apple Silicon';
      case TargetPlatform.windows:
        return 'x86/x64';
      default:
        return 'Unknown';
    }
  }

  Future<void> _executeAndroidAction(PlatformAction action, Map<String, dynamic>? parameters) async {
    switch (action) {
      case PlatformAction.requestNotificationPermission:
        // Android-specific notification setup
        break;
      case PlatformAction.enablePictureInPicture:
        // Android PiP mode
        break;
      case PlatformAction.shareContent:
        // Android share intent
        break;
      default:
        _logger.warning('Android action not implemented: $action', 'CrossDeviceService');
    }
  }

  Future<void> _executeIOSAction(PlatformAction action, Map<String, dynamic>? parameters) async {
    switch (action) {
      case PlatformAction.enableHapticFeedback:
        // iOS haptic feedback
        break;
      case PlatformAction.requestNotificationPermission:
        // iOS notification permissions
        break;
      case PlatformAction.shareContent:
        // iOS share sheet
        break;
      default:
        _logger.warning('iOS action not implemented: $action', 'CrossDeviceService');
    }
  }

  Future<void> _executeWindowsAction(PlatformAction action, Map<String, dynamic>? parameters) async {
    switch (action) {
      case PlatformAction.openFileLocation:
        // Windows file explorer
        break;
      case PlatformAction.showSystemTray:
        // Windows system tray
        break;
      case PlatformAction.registerGlobalShortcut:
        // Windows global shortcuts
        break;
      default:
        _logger.warning('Windows action not implemented: $action', 'CrossDeviceService');
    }
  }

  Map<LogicalKeyboardKey, Intent> _getWindowsShortcuts() {
    return {
      LogicalKeyboardKey.keyS.control: const SaveIntent(),
      LogicalKeyboardKey.keyO.control: const OpenIntent(),
      LogicalKeyboardKey.keyN.control: const NewIntent(),
      LogicalKeyboardKey.f11: const FullscreenIntent(),
    };
  }

  Map<LogicalKeyboardKey, Intent> _getMacShortcuts() {
    return {
      LogicalKeyboardKey.keyS.meta: const SaveIntent(),
      LogicalKeyboardKey.keyO.meta: const OpenIntent(),
      LogicalKeyboardKey.keyN.meta: const NewIntent(),
      LogicalKeyboardKey.f11: const FullscreenIntent(),
    };
  }

  void _emitDeviceEvent(DeviceEventType type, {Map<String, dynamic>? data}) {
    final event = DeviceEvent(
      type: type,
      platform: currentPlatform,
      timestamp: DateTime.now(),
      data: data,
    );
    _deviceEventController.add(event);
  }

  /// Dispose service
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _deviceEventController.close();
    _isInitialized = false;
    _logger.info('Cross-Device Service disposed', 'CrossDeviceService');
  }
}

/// Platform Optimization Settings
class PlatformOptimization {
  final TargetPlatform platform;
  final int recommendedCacheSize;
  final int recommendedThreadPoolSize;
  final bool enableHapticFeedback;
  final bool enableGestures;
  final bool enableBiometric;
  final String preferredImageFormat;
  final MemoryOptimizationLevel memoryOptimizationLevel;

  PlatformOptimization({
    required this.platform,
    required this.recommendedCacheSize,
    required this.recommendedThreadPoolSize,
    required this.enableHapticFeedback,
    required this.enableGestures,
    required this.enableBiometric,
    required this.preferredImageFormat,
    required this.memoryOptimizationLevel,
  });

  factory PlatformOptimization.defaultFor(TargetPlatform platform) {
    return PlatformOptimization(
      platform: platform,
      recommendedCacheSize: 50 * 1024 * 1024,
      recommendedThreadPoolSize: 4,
      enableHapticFeedback: false,
      enableGestures: false,
      enableBiometric: false,
      preferredImageFormat: 'png',
      memoryOptimizationLevel: MemoryOptimizationLevel.moderate,
    );
  }
}

/// Memory Optimization Levels
enum MemoryOptimizationLevel {
  conservative,  // Desktop-style - more memory available
  moderate,      // Balanced approach
  aggressive,    // Mobile-style - memory constrained
}

/// Adaptive UI Settings
class AdaptiveUISettings {
  final TargetPlatform platform;
  final Size screenSize;
  final double pixelRatio;
  final Orientation orientation;
  final double touchTargetSize;
  final double fontScale;
  final LayoutDensity layoutDensity;
  final PlatformOptimization optimization;
  final bool hapticEnabled;
  final bool keyboardShortcutsEnabled;

  AdaptiveUISettings({
    required this.platform,
    required this.screenSize,
    required this.pixelRatio,
    required this.orientation,
    required this.touchTargetSize,
    required this.fontScale,
    required this.layoutDensity,
    required this.optimization,
    required this.hapticEnabled,
    required this.keyboardShortcutsEnabled,
  });

  bool get isMobile => platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  bool get isDesktop => platform == TargetPlatform.windows || platform == TargetPlatform.macOS || platform == TargetPlatform.linux;
  bool get isLargeScreen => screenSize.width > 600;
  bool get isSmallScreen => screenSize.width <= 360;
}

/// Layout Density Options
enum LayoutDensity {
  compact,      // Dense layout for small screens
  standard,     // Normal layout
  comfortable,  // Spacious layout for large screens
}

/// Performance Recommendation
class PerformanceRecommendation {
  final int deviceMemoryMB;
  final String deviceCPU;
  final ConnectivityResult connectivity;
  final bool isLowEnd;
  final bool isHighEnd;
  final List<String> recommendations;

  PerformanceRecommendation({
    required this.deviceMemoryMB,
    required this.deviceCPU,
    required this.connectivity,
    required this.isLowEnd,
    required this.isHighEnd,
    required this.recommendations,
  });
}

/// Platform Actions
enum PlatformAction {
  requestNotificationPermission,
  enableHapticFeedback,
  enablePictureInPicture,
  shareContent,
  openFileLocation,
  showSystemTray,
  registerGlobalShortcut,
}

/// Device Event Types
enum DeviceEventType {
  initialized,
  connectivityChanged,
  platformActionExecuted,
  optimizationApplied,
  error,
}

/// Device Event
class DeviceEvent {
  final DeviceEventType type;
  final TargetPlatform platform;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  DeviceEvent({
    required this.type,
    required this.platform,
    required this.timestamp,
    this.data,
  });
}

/// Custom Intents for Shortcuts
class SaveIntent extends Intent {}
class OpenIntent extends Intent {}
class NewIntent extends Intent {}
class FullscreenIntent extends Intent {}
