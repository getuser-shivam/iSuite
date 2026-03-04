import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:collection';
import 'package:flutter/foundation.dart';

// Enums and classes first
enum ConfigEventType {
  initialized,
  parameterChanged,
  componentRegistered,
  componentNotified,
  componentParametersUpdated,
  configurationImported,
  resetToDefaults,
}

class ConfigEvent {
  final ConfigEventType type;
  final DateTime timestamp;
  final String? componentName;
  final String? parameterKey;
  final dynamic oldValue;
  final dynamic newValue;

  ConfigEvent({
    required this.type,
    required this.timestamp,
    this.componentName,
    this.parameterKey,
    this.oldValue,
    this.newValue,
  });

  @override
  String toString() {
    return 'ConfigEvent(type: $type, timestamp: $timestamp, componentName: $componentName)';
  }
}

enum RelationshipType {
  depends_on,
  provides_to,
  configures,
  monitors,
}

class ComponentRelationship {
  final String sourceComponent;
  final String targetComponent;
  final RelationshipType type;
  final DateTime createdAt;

  ComponentRelationship({
    required this.sourceComponent,
    required this.targetComponent,
    required this.type,
    required this.createdAt,
  });
}

class ComponentMetrics {
  final String componentName;
  final int accessCount;
  final Duration averageResponseTime;
  final Map<String, dynamic> performanceData;

  ComponentMetrics({
    required this.componentName,
    required this.accessCount,
    required this.averageResponseTime,
    required this.performanceData,
  });
}

class SystemHealthStatus {
  final int totalComponents;
  final int activeComponents;
  final int totalConnections;
  final int cacheSize;
  final int memoryUsage;
  final bool isHealthy;
  final DateTime lastHealthCheck;

  SystemHealthStatus({
    required this.totalComponents,
    required this.activeComponents,
    required this.totalConnections,
    required this.cacheSize,
    required this.memoryUsage,
    required this.isHealthy,
    required this.lastHealthCheck,
  });
}

class ComponentMemoryInfo {
  final String componentName;
  final int memoryUsage;
  final int cacheSize;

  ComponentMemoryInfo({
    required this.componentName,
    required this.memoryUsage,
    required this.cacheSize,
  });
}

class _CachedValue {
  final dynamic value;
  final DateTime expiry;

  _CachedValue(this.value, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class ReadWriteLock {
  int _readers = 0;
  bool _writer = false;
  final Queue<Completer<void>> _writerQueue = Queue<Completer<void>>();

  Future<T> read<T>(Future<T> Function() operation) async {
    while (_writer) {
      await _writerQueue.first;
    }
    _readers++;
    try {
      return await operation();
    } finally {
      _readers--;
    }
  }

  Future<T> write<T>(Future<T> Function() operation) async {
    final completer = Completer<void>();
    _writerQueue.add(completer);

    while (_readers > 0 || _writer) {
      await completer.future;
    }

    _writer = true;
    _writerQueue.remove(completer);

    try {
      return await operation();
    } finally {
      _writer = false;
      // Signal next writer
      if (_writerQueue.isNotEmpty) {
        _writerQueue.first.complete();
      }
    }
  }
}

/// Enhanced Central Configuration System
class CentralConfig {
  static CentralConfig? _instance;
  static CentralConfig get instance => _instance ??= CentralConfig._internal();
  CentralConfig._internal();

  // Enhanced caching system with relationship tracking
  final Map<String, _CachedValue> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _defaultCacheTTL = Duration(minutes: 5);
  final int _maxCacheSize = 1000;

  // Component relationship tracking
  final Map<String, Set<String>> _componentDependencies = {};
  final Map<String, Set<String>> _parameterDependencies = {};
  final Map<String, ComponentRelationship> _componentRelationships = {};

  // Performance monitoring with component metrics
  final Map<String, DateTime> _accessTimestamps = {};
  final Map<String, int> _accessCounts = {};
  final Map<String, Duration> _performanceMetrics = {};
  final Map<String, ComponentMetrics> _componentMetrics = {};

  // Hot-reload support with dependency propagation
  final Map<String, Function()> _configWatchers = {};
  final Map<String, Set<String>> _dependencyWatchers = {};

  // Environment-based configuration with component overrides
  final Map<String, String> _envOverrides = {};
  final Map<String, String> _platformOverrides = {};
  final Map<String, Map<String, dynamic>> _componentOverrides = {};

  // Memory optimization with component-aware cleanup
  final Map<String, WeakReference> _weakReferences = {};
  final Map<String, ComponentMemoryInfo> _componentMemoryInfo = {};

  // Thread safety with component-level locking
  final ReadWriteLock _lock = ReadWriteLock();
  final Map<String, ReadWriteLock> _componentLocks = {};
  bool _isInitialized = false;

  // Event streaming
  final StreamController<ConfigEvent> _eventController =
      StreamController.broadcast();

  Stream<ConfigEvent> get events => _eventController.stream;

  /// Initialize CentralConfig with enhanced features
  Future<void> initialize({bool enableHotReload = true}) async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  /// Setup UI configuration parameters
  Future<void> setupUIConfig() async {
    // UI Colors
    await setParameter('ui.primary_color', 0xFF2196F3, description: 'Primary theme color');
    await setParameter('ui.secondary_color', 0xFF03DAC6, description: 'Secondary theme color');
    await setParameter('ui.surface_color', 0xFFFFFFFF, description: 'Surface color');
    await setParameter('ui.background_color', 0xFFFAFAFA, description: 'Background color');
    await setParameter('ui.error_color', 0xFFB00020, description: 'Error color');
    await setParameter('ui.success_color', 0xFF4CAF50, description: 'Success color');
    await setParameter('ui.warning_color', 0xFFFF9800, description: 'Warning color');
    await setParameter('ui.info_color', 0xFF2196F3, description: 'Info color');

    // Typography
    await setParameter('ui.font_family_primary', 'Roboto', description: 'Primary font family');
    await setParameter('ui.font_family_secondary', 'Roboto', description: 'Secondary font family');
    await setParameter('ui.font_size_display_large', 57.0, description: 'Display large font size');
    await setParameter('ui.font_size_display_medium', 45.0, description: 'Display medium font size');
    await setParameter('ui.font_size_display_small', 36.0, description: 'Display small font size');
    await setParameter('ui.font_size_headline_large', 32.0, description: 'Headline large font size');
    await setParameter('ui.font_size_headline_medium', 28.0, description: 'Headline medium font size');
    await setParameter('ui.font_size_headline_small', 24.0, description: 'Headline small font size');
    await setParameter('ui.font_size_title_large', 22.0, description: 'Title large font size');
    await setParameter('ui.font_size_title_medium', 16.0, description: 'Title medium font size');
    await setParameter('ui.font_size_title_small', 14.0, description: 'Title small font size');
    await setParameter('ui.font_size_body_large', 16.0, description: 'Body large font size');
    await setParameter('ui.font_size_body_medium', 14.0, description: 'Body medium font size');
    await setParameter('ui.font_size_body_small', 12.0, description: 'Body small font size');
    await setParameter('ui.font_size_label_large', 14.0, description: 'Label large font size');
    await setParameter('ui.font_size_label_medium', 12.0, description: 'Label medium font size');
    await setParameter('ui.font_size_label_small', 11.0, description: 'Label small font size');

    // Spacing
    await setParameter('ui.spacing_xs', 4.0, description: 'Extra small spacing');
    await setParameter('ui.spacing_sm', 8.0, description: 'Small spacing');
    await setParameter('ui.spacing_md', 16.0, description: 'Medium spacing');
    await setParameter('ui.spacing_lg', 24.0, description: 'Large spacing');
    await setParameter('ui.spacing_xl', 32.0, description: 'Extra large spacing');

    // Component Sizes
    await setParameter('ui.app_bar_height', 56.0, description: 'App bar height');
    await setParameter('ui.bottom_nav_height', 80.0, description: 'Bottom navigation height');
    await setParameter('ui.fab_size', 56.0, description: 'FAB size');
    await setParameter('ui.button_height', 48.0, description: 'Button height');
    await setParameter('ui.card_min_height', 120.0, description: 'Card minimum height');
    await setParameter('ui.card_max_width', 400.0, description: 'Card maximum width');

    // Icon Sizes
    await setParameter('ui.icon_size_xs', 12.0, description: 'Extra small icon size');
    await setParameter('ui.icon_size_sm', 16.0, description: 'Small icon size');
    await setParameter('ui.icon_size_md', 20.0, description: 'Medium icon size');
    await setParameter('ui.icon_size_lg', 24.0, description: 'Large icon size');
    await setParameter('ui.icon_size_xl', 28.0, description: 'Extra large icon size');
    await setParameter('ui.icon_size_xxl', 32.0, description: 'Extra extra large icon size');

    // Letter Spacing
    await setParameter('ui.letter_spacing_display', -0.25, description: 'Display letter spacing');
    await setParameter('ui.letter_spacing_headline', 0.0, description: 'Headline letter spacing');
    await setParameter('ui.letter_spacing_title', 0.0, description: 'Title letter spacing');
    await setParameter('ui.letter_spacing_body', 0.5, description: 'Body letter spacing');
    await setParameter('ui.letter_spacing_label', 0.1, description: 'Label letter spacing');

    // Line Heights
    await setParameter('ui.line_height_display_large', 1.12, description: 'Display large line height');
    await setParameter('ui.line_height_display_medium', 1.16, description: 'Display medium line height');
    await setParameter('ui.line_height_display_small', 1.22, description: 'Display small line height');
    await setParameter('ui.line_height_headline_large', 1.25, description: 'Headline large line height');
    await setParameter('ui.line_height_headline_medium', 1.29, description: 'Headline medium line height');
    await setParameter('ui.line_height_headline_small', 1.33, description: 'Headline small line height');
    await setParameter('ui.line_height_title_large', 1.27, description: 'Title large line height');
    await setParameter('ui.line_height_title_medium', 1.5, description: 'Title medium line height');
    await setParameter('ui.line_height_title_small', 1.43, description: 'Title small line height');
    await setParameter('ui.line_height_body_large', 1.5, description: 'Body large line height');
    await setParameter('ui.line_height_body_medium', 1.43, description: 'Body medium line height');
    await setParameter('ui.line_height_body_small', 1.33, description: 'Body small line height');
    await setParameter('ui.line_height_label_large', 1.43, description: 'Label large line height');
    await setParameter('ui.line_height_label_medium', 1.33, description: 'Label medium line height');
    await setParameter('ui.line_height_label_small', 1.45, description: 'Label small line height');
    await setParameter('ui.card_primary_color', 0xFF2196F3,
        description: 'Primary card color');
    await setParameter('ui.card_secondary_color', 0xFF03DAC6,
        description: 'Secondary card color');
    await setParameter('ui.card_success_color', 0xFF4CAF50,
        description: 'Success card color');
    await setParameter('ui.card_warning_color', 0xFFFF9800,
        description: 'Warning card color');
    await setParameter('ui.card_error_color', 0xFFF44336,
        description: 'Error card color');
    await setParameter('ui.card_info_color', 0xFF2196F3,
        description: 'Info card color');

    // Spacing
    await setParameter('ui.padding_small', 8.0, description: 'Small padding');
    await setParameter('ui.padding_medium', 16.0,
        description: 'Medium padding');
    await setParameter('ui.padding_large', 24.0, description: 'Large padding');
    await setParameter('ui.margin_small', 4.0, description: 'Small margin');
    await setParameter('ui.margin_medium', 8.0, description: 'Medium margin');
    await setParameter('ui.margin_large', 16.0, description: 'Large margin');

    // Sharing configuration
    await setParameter('sharing.discovery_timeout', 30000,
        description: 'Discovery timeout (ms)');
    await setParameter('sharing.connection_timeout', 15000,
        description: 'Connection timeout (ms)');
    await setParameter('sharing.buffer_size', 8192,
        description: 'Transfer buffer size (bytes)');
    await setParameter('sharing.enable_encryption', true,
        description: 'Enable encrypted transfers');
    await setParameter('sharing.max_file_size', 104857600,
        description: 'Maximum file size (bytes)');
    await setParameter('sharing.auto_accept_transfers', false,
        description: 'Auto-accept transfers');
    await setParameter('sharing.transfer_retry_attempts', 3,
        description: 'Number of retry attempts');

    // Border Radius
    await setParameter('ui.border_radius_small', 4.0,
        description: 'Small border radius');
    await setParameter('ui.border_radius_medium', 8.0,
        description: 'Medium border radius');
    await setParameter('ui.border_radius_large', 12.0,
        description: 'Large border radius');
    await setParameter('ui.border_radius_xlarge', 16.0,
        description: 'Extra large border radius');

    // Elevation
    await setParameter('ui.elevation_low', 1.0, description: 'Low elevation');
    await setParameter('ui.elevation_medium', 2.0,
        description: 'Medium elevation');
    await setParameter('ui.elevation_high', 4.0, description: 'High elevation');
    await setParameter('ui.elevation_xhigh', 8.0,
        description: 'Extra high elevation');

    // Icon Sizes
    await setParameter('ui.icon_size_small', 16.0,
        description: 'Small icon size');
    await setParameter('ui.icon_size_medium', 20.0,
        description: 'Medium icon size');
    await setParameter('ui.icon_size_large', 24.0,
        description: 'Large icon size');
    await setParameter('ui.icon_size_xlarge', 28.0,
        description: 'Extra large icon size');
    await setParameter('ui.icon_size_xxlarge', 32.0,
        description: 'Extra extra large icon size');

    // Font Sizes
    await setParameter('ui.font_size_small', 12.0,
        description: 'Small font size');
    await setParameter('ui.font_size_medium', 14.0,
        description: 'Medium font size');
    await setParameter('ui.font_size_large', 16.0,
        description: 'Large font size');
    await setParameter('ui.font_size_xlarge', 18.0,
        description: 'Extra large font size');
    await setParameter('ui.font_size_xxlarge', 20.0,
        description: 'Extra extra large font size');
    await setParameter('ui.font_size_huge', 24.0,
        description: 'Huge font size');

    // Animation Durations
    await setParameter('ui.animation_duration_fast', 200,
        description: 'Fast animation duration (ms)');
    await setParameter('ui.animation_duration_medium', 300,
        description: 'Medium animation duration (ms)');
    await setParameter('ui.animation_duration_slow', 500,
        description: 'Slow animation duration (ms)');
    await setParameter('ui.animation_duration_slowest', 800,
        description: 'Slowest animation duration (ms)');

    // Animation Delays
    await setParameter('ui.animation_delay_short', 100,
        description: 'Short animation delay (ms)');
    await setParameter('ui.animation_delay_medium', 200,
        description: 'Medium animation delay (ms)');
    await setParameter('ui.animation_delay_long', 400,
        description: 'Long animation delay (ms)');
    await setParameter('ui.animation_delay_xlong', 600,
        description: 'Extra long animation delay (ms)');

    // Grid Layout
    await setParameter('ui.grid_cross_axis_count', 2,
        description: 'Grid cross axis count');
    await setParameter('ui.grid_cross_axis_spacing', 12.0,
        description: 'Grid cross axis spacing');
    await setParameter('ui.grid_main_axis_spacing', 12.0,
        description: 'Grid main axis spacing');
    await setParameter('ui.grid_child_aspect_ratio', 1.1,
        description: 'Grid child aspect ratio');

    // Card Dimensions
    await setParameter('ui.card_min_height', 120.0,
        description: 'Card minimum height');
    await setParameter('ui.card_max_width', 400.0,
        description: 'Card maximum width');
    await setParameter('ui.card_action_tile_width', 100.0,
        description: 'Action tile width');
    await setParameter('ui.card_action_tile_height', 100.0,
        description: 'Action tile height');

    // Opacity Values
    await setParameter('ui.opacity_low', 0.1, description: 'Low opacity');
    await setParameter('ui.opacity_medium', 0.2, description: 'Medium opacity');
    await setParameter('ui.opacity_high', 0.3, description: 'High opacity');
    await setParameter('ui.opacity_overlay', 0.8,
        description: 'Overlay opacity');

    // Blur Radius
    await setParameter('ui.blur_radius_small', 4.0,
        description: 'Small blur radius');
    await setParameter('ui.blur_radius_medium', 8.0,
        description: 'Medium blur radius');
    await setParameter('ui.blur_radius_large', 12.0,
        description: 'Large blur radius');

    // Shadow Offset
    await setParameter('ui.shadow_offset_x', 0.0,
        description: 'Shadow offset X');
    await setParameter('ui.shadow_offset_y', 4.0,
        description: 'Shadow offset Y');

    // Navigation & Routing
    await setParameter('navigation.enable_bottom_nav', true,
        description: 'Enable bottom navigation');
    await setParameter('navigation.enable_drawer', false,
        description: 'Enable navigation drawer');
    await setParameter('navigation.enable_fab', true,
        description: 'Enable floating action button');
    await setParameter('navigation.enable_app_bar', true,
        description: 'Enable app bar');
    await setParameter('navigation.enable_search', true,
        description: 'Enable global search');
    await setParameter('navigation.enable_notifications', true,
        description: 'Enable notifications');
    await setParameter('navigation.animation_duration_ms', 300,
        description: 'Navigation animation duration');
    await setParameter('navigation.transition_type', 'slide',
        description: 'Navigation transition type (slide, fade, scale)');
    await setParameter('navigation.enable_nested_navigation', true,
        description: 'Enable nested navigation');
    await setParameter('navigation.max_back_stack', 10,
        description: 'Maximum back stack size');
    await setParameter('navigation.enable_gestures', true,
        description: 'Enable gesture navigation');

    // App Bar Configuration
    await setParameter('appbar.enable_title_animation', true,
        description: 'Enable app bar title animation');
    await setParameter('appbar.elevation', 0.0,
        description: 'App bar elevation');
    await setParameter('appbar.height', 56.0, description: 'App bar height');
    await setParameter('appbar.enable_transparency', false,
        description: 'Enable transparent app bar');
    await setParameter('appbar.title_font_size', 20.0,
        description: 'App bar title font size');
    await setParameter('appbar.enable_actions_animation', true,
        description: 'Enable app bar actions animation');

    // Bottom Navigation
    await setParameter('bottom_nav.height', 80.0,
        description: 'Bottom navigation height');
    await setParameter('bottom_nav.enable_labels', false,
        description: 'Show labels in bottom navigation');
    await setParameter('bottom_nav.icon_size', 24.0,
        description: 'Bottom navigation icon size');
    await setParameter('bottom_nav.animation_duration_ms', 300,
        description: 'Bottom navigation animation duration');
    await setParameter('bottom_nav.enable_indicator', true,
        description: 'Enable bottom navigation indicator');
    await setParameter('bottom_nav.indicator_height', 3.0,
        description: 'Bottom navigation indicator height');

    // FAB (Floating Action Button)
    await setParameter('fab.size', 56.0, description: 'FAB size');
    await setParameter('fab.elevation', 6.0, description: 'FAB elevation');
    await setParameter('fab.extended_padding_horizontal', 16.0,
        description: 'FAB extended horizontal padding');
    await setParameter('fab.extended_icon_spacing', 8.0,
        description: 'FAB extended icon spacing');
    await setParameter('fab.animation_duration_ms', 200,
        description: 'FAB animation duration');
    await setParameter('fab.enable_hero_animation', true,
        description: 'Enable FAB hero animation');

    // Performance & Caching
    await setParameter('performance.enable_image_caching', true,
        description: 'Enable image caching');
    await setParameter('performance.image_cache_size_mb', 100,
        description: 'Image cache size in MB');
    await setParameter('performance.enable_list_virtualization', true,
        description: 'Enable list virtualization');
    await setParameter('performance.virtualization_threshold', 50,
        description: 'Virtualization threshold');
    await setParameter('performance.enable_preloading', true,
        description: 'Enable data preloading');
    await setParameter('performance.preload_distance', 5,
        description: 'Preload distance');
    await setParameter('performance.enable_compression', false,
        description: 'Enable data compression');
    await setParameter('performance.compression_level', 6,
        description: 'Compression level (1-9)');
    await setParameter('performance.enable_memory_optimization', true,
        description: 'Enable memory optimization');
    await setParameter('performance.gc_threshold_mb', 50,
        description: 'GC threshold in MB');

    // Error Handling & Recovery
    await setParameter('error.enable_error_boundary', true,
        description: 'Enable error boundaries');
    await setParameter('error.enable_error_reporting', false,
        description: 'Enable error reporting');
    await setParameter('error.error_report_endpoint', '',
        description: 'Error reporting endpoint');
    await setParameter('error.enable_retry_dialog', true,
        description: 'Enable retry dialogs');
    await setParameter('error.max_retry_attempts', 3,
        description: 'Maximum retry attempts');
    await setParameter('error.retry_delay_ms', 1000,
        description: 'Retry delay in milliseconds');
    await setParameter('error.enable_offline_fallback', true,
        description: 'Enable offline fallback');
    await setParameter('error.enable_error_toast', true,
        description: 'Enable error toast notifications');
    await setParameter('error.toast_duration_seconds', 4,
        description: 'Error toast duration');

    // Accessibility
    await setParameter('accessibility.enable_screen_reader', true,
        description: 'Enable screen reader support');
    await setParameter('accessibility.enable_high_contrast', false,
        description: 'Enable high contrast mode');
    await setParameter('accessibility.enable_reduced_motion', false,
        description: 'Enable reduced motion');
    await setParameter('accessibility.enable_large_text', false,
        description: 'Enable large text mode');
    await setParameter('accessibility.touch_target_size', 44.0,
        description: 'Minimum touch target size');
    await setParameter('accessibility.focus_indicator_width', 2.0,
        description: 'Focus indicator width');
    await setParameter('accessibility.enable_keyboard_navigation', true,
        description: 'Enable keyboard navigation');
    await setParameter('accessibility.announce_route_changes', true,
        description: 'Announce route changes');

    // Notifications
    await setParameter('notifications.enable_push', true,
        description: 'Enable push notifications');
    await setParameter('notifications.enable_local', true,
        description: 'Enable local notifications');
    await setParameter('notifications.enable_sound', true,
        description: 'Enable notification sounds');
    await setParameter('notifications.enable_vibration', true,
        description: 'Enable notification vibration');
    await setParameter('notifications.max_notifications', 50,
        description: 'Maximum stored notifications');
    await setParameter('notifications.auto_hide_seconds', 5,
        description: 'Auto-hide notification seconds');
    await setParameter('notifications.group_similar', true,
        description: 'Group similar notifications');
    await setParameter('notifications.enable_actions', true,
        description: 'Enable notification actions');

    // Search & Discovery
    await setParameter('search.enable_global_search', true,
        description: 'Enable global search');
    await setParameter('search.max_results', 100,
        description: 'Maximum search results');
    await setParameter('search.search_timeout_seconds', 10,
        description: 'Search timeout seconds');
    await setParameter('search.enable_fuzzy_search', true,
        description: 'Enable fuzzy search');
    await setParameter('search.enable_recent_searches', true,
        description: 'Enable recent searches');
    await setParameter('search.max_recent_searches', 10,
        description: 'Maximum recent searches');
    await setParameter('search.enable_search_suggestions', true,
        description: 'Enable search suggestions');
    await setParameter('search.enable_voice_search', false,
        description: 'Enable voice search');

    // Data Management
    await setParameter('data.enable_auto_save', true,
        description: 'Enable auto-save');
    await setParameter('data.auto_save_interval_seconds', 30,
        description: 'Auto-save interval');
    await setParameter('data.enable_backup', true,
        description: 'Enable automatic backups');
    await setParameter('data.backup_interval_hours', 24,
        description: 'Backup interval hours');
    await setParameter('data.backup_retention_days', 30,
        description: 'Backup retention days');
    await setParameter('data.enable_encryption', true,
        description: 'Enable data encryption');
    await setParameter('data.encryption_algorithm', 'AES-256-GCM',
        description: 'Encryption algorithm');
    await setParameter('data.enable_compression', false,
        description: 'Enable data compression');
    await setParameter('data.compression_algorithm', 'gzip',
        description: 'Compression algorithm');

    // Platform Specific
    await setParameter('platform.enable_platform_optimizations', true,
        description: 'Enable platform optimizations');
    await setParameter('platform.android.enable_biometric', true,
        description: 'Enable Android biometric');
    await setParameter('platform.ios.enable_face_id', true,
        description: 'Enable iOS Face ID');
    await setParameter('platform.windows.enable_system_integration', true,
        description: 'Enable Windows system integration');
    await setParameter('platform.web.enable_pwa', true,
        description: 'Enable Progressive Web App');
    await setParameter('platform.web.enable_service_worker', true,
        description: 'Enable service worker');

    // Analytics & Monitoring
    await setParameter('analytics.enable_analytics', false,
        description: 'Enable analytics');
    await setParameter('analytics.analytics_provider', 'none',
        description: 'Analytics provider (firebase, mixpanel, none)');
    await setParameter('analytics.enable_crash_reporting', false,
        description: 'Enable crash reporting');
    await setParameter('analytics.enable_performance_monitoring', true,
        description: 'Enable performance monitoring');
    await setParameter('analytics.sampling_rate', 1.0,
        description: 'Analytics sampling rate (0.0-1.0)');
    await setParameter('analytics.enable_user_tracking', false,
        description: 'Enable user tracking');
    await setParameter('analytics.anonymize_ip', true,
        description: 'Anonymize IP addresses');

    // Internationalization
    await setParameter('i18n.enable_i18n', true,
        description: 'Enable internationalization');
    await setParameter('i18n.default_locale', 'en',
        description: 'Default locale');
    await setParameter('i18n.supported_locales', 'en,es,fr,de,zh,ja',
        description: 'Supported locales');
    await setParameter('i18n.enable_rtl', true,
        description: 'Enable right-to-left support');
    await setParameter('i18n.enable_pluralization', true,
        description: 'Enable pluralization');
    await setParameter('i18n.date_format', 'medium',
        description: 'Date format (short, medium, long)');
    await setParameter('i18n.time_format', 'medium',
        description: 'Time format (short, medium, long)');

    // Security & Privacy
    await setParameter('security.enable_ssl_pinning', false,
        description: 'Enable SSL pinning');
    await setParameter('security.enable_certificate_validation', true,
        description: 'Enable certificate validation');
    await setParameter('security.enable_data_sanitization', true,
        description: 'Enable data sanitization');
    await setParameter('security.enable_privacy_mode', false,
        description: 'Enable privacy mode');
    await setParameter('security.session_timeout_minutes', 30,
        description: 'Session timeout minutes');
    await setParameter('security.enable_auto_lock', false,
        description: 'Enable auto-lock');
    await setParameter('security.auto_lock_timeout_minutes', 5,
        description: 'Auto-lock timeout minutes');
    await setParameter('security.enable_secure_storage', true,
        description: 'Enable secure storage');

    // Development & Debugging
    await setParameter('debug.enable_debug_mode', false,
        description: 'Enable debug mode');
    await setParameter('debug.enable_performance_overlay', false,
        description: 'Enable performance overlay');
    await setParameter('debug.enable_logging', true,
        description: 'Enable logging');
    await setParameter('debug.log_level', 'info',
        description: 'Log level (debug, info, warning, error)');
    await setParameter('debug.enable_hot_reload', true,
        description: 'Enable hot reload');
    await setParameter('debug.enable_dev_tools', false,
        description: 'Enable developer tools');
    await setParameter('debug.enable_mock_data', false,
        description: 'Enable mock data for testing');
    await setParameter('debug.enable_ui_inspector', false,
        description: 'Enable UI inspector');

    // Experimental Features
    await setParameter('experimental.enable_experimental_features', false,
        description: 'Enable experimental features');
    await setParameter('experimental.enable_ai_features', true,
        description: 'Enable AI features');
    await setParameter('experimental.enable_cloud_sync', true,
        description: 'Enable cloud synchronization');
    await setParameter('experimental.enable_collaboration', false,
        description: 'Enable collaboration features');
    await setParameter('experimental.enable_voice_commands', false,
        description: 'Enable voice commands');
    await setParameter('experimental.enable_ar_features', false,
        description: 'Enable AR features');
    await setParameter('experimental.enable_ml_features', false,
        description: 'Enable ML features');
    await setParameter('experimental.enable_blockchain', false,
        description: 'Enable blockchain features');

    // Third-party Integrations
    await setParameter('integrations.enable_google_drive', false,
        description: 'Enable Google Drive integration');
    await setParameter('integrations.enable_dropbox', false,
        description: 'Enable Dropbox integration');
    await setParameter('integrations.enable_onedrive', false,
        description: 'Enable OneDrive integration');
    await setParameter('integrations.enable_firebase', false,
        description: 'Enable Firebase integration');
    await setParameter('integrations.enable_stripe', false,
        description: 'Enable Stripe payment integration');
    await setParameter('integrations.enable_paypal', false,
        description: 'Enable PayPal payment integration');
    await setParameter('integrations.enable_social_login', false,
        description: 'Enable social login');
    await setParameter('integrations.enable_push_notifications', false,
        description: 'Enable push notifications');
  }

  /// Get parameter with caching and validation
  Future<T?> getParameter<T>(String key) async {
    return await _lock.read(() async {
      // Check cache first
      if (_cache.containsKey(key)) {
        final cachedValue = _cache[key]!;
        if (!cachedValue.isExpired) {
          _accessTimestamps[key] = DateTime.now();
          _accessCounts[key] = (_accessCounts[key] ?? 0) + 1;
          return cachedValue.value as T?;
        }
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }

      // Check environment overrides
      if (_envOverrides.containsKey(key)) {
        return _envOverrides[key] as T?;
      }

      // Check platform overrides
      if (_platformOverrides.containsKey(key)) {
        return _platformOverrides[key] as T?;
      }

      // Check component overrides
      for (final componentOverride in _componentOverrides.values) {
        if (componentOverride.containsKey(key)) {
          return componentOverride[key] as T?;
        }
      }

      return null;
    });
  }

  /// Set parameter with validation and caching
  Future<void> setParameter(String key, dynamic value,
      {String? description}) async {
    await _lock.write(() async {
      final oldValue = await getParameter(key);

      // Cache the value
      _cache[key] = _CachedValue(value, DateTime.now().add(_defaultCacheTTL));
      _cacheTimestamps[key] = DateTime.now();

      // Emit event
      _emitEvent(ConfigEventType.parameterChanged,
          parameterKey: key, oldValue: oldValue, newValue: value);

      // Perform cache cleanup if needed
      if (_cache.length > _maxCacheSize) {
        _cleanupCache();
      }
    });
  }

  void _emitEvent(ConfigEventType type,
      {String? componentName,
      String? parameterKey,
      dynamic oldValue,
      dynamic newValue}) {
    final event = ConfigEvent(
      type: type,
      timestamp: DateTime.now(),
      componentName: componentName,
      parameterKey: parameterKey,
      oldValue: oldValue,
      newValue: newValue,
    );

    // Add event to stream (non-blocking)
    Future.microtask(() {
      _eventController.add(event);
    });
  }

  void _cleanupCache() {
    if (_cache.length <= _maxCacheSize) return;

    // Sort by timestamp and remove oldest entries
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final entriesToRemove = sortedEntries.take(_cache.length - _maxCacheSize);
    for (final entry in entriesToRemove) {
      _cache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
    }
  }

  int _calculateTotalMemoryUsage() {
    int totalUsage = 0;
    for (final memoryInfo in _componentMemoryInfo.values) {
      totalUsage += memoryInfo.memoryUsage;
    }
    return totalUsage;
  }

  Future<void> _cleanupExpiredCache() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _defaultCacheTTL) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  Future<void> _cleanupWeakReferences() async {
    final deadReferences = <String>[];

    for (final entry in _weakReferences.entries) {
      if (entry.value.target == null) {
        deadReferences.add(entry.key);
      }
    }

    for (final key in deadReferences) {
      _weakReferences.remove(key);
    }
  }

  Future<void> _cleanupInactiveComponents() async {
    final now = DateTime.now();
    final inactiveThreshold = Duration(hours: 1);

    for (final entry in _componentMetrics.entries) {
      final componentName = entry.key;
      final metrics = entry.value;

      if (now.difference(metrics.performanceData['lastAccess'] ?? now) >
          inactiveThreshold) {
        _componentMetrics.remove(componentName);
        _componentMemoryInfo.remove(componentName);
      }
    }
  }

  void _updateDependencyTracking(
      String source, String target, RelationshipType type) {
    // Update component dependencies
    if (!_componentDependencies.containsKey(source)) {
      _componentDependencies[source] = <String>{};
    }
    _componentDependencies[source]!.add(target);

    // Update parameter dependencies based on relationship type
    switch (type) {
      case RelationshipType.depends_on:
        _addParameterDependency(source, target);
        break;
      case RelationshipType.configures:
        _addParameterDependency(target, source);
        break;
      case RelationshipType.monitors:
        _addParameterDependency(source, target);
        break;
      default:
        break;
    }
  }

  void _addParameterDependency(String source, String target) {
    final sourceParams = _getActiveParametersForComponent(source);
    final targetParams = _getActiveParametersForComponent(target);

    for (final sourceParam in sourceParams) {
      if (!_parameterDependencies.containsKey(sourceParam)) {
        _parameterDependencies[sourceParam] = <String>{};
      }
      _parameterDependencies[sourceParam]!.addAll(targetParams);
    }
  }

  List<String> _getActiveParametersForComponent(String componentName) {
    final componentPrefix = componentName.toLowerCase();
    return _cache.keys.where((key) => key.startsWith(componentPrefix)).toList();
  }

  /// Get system health status
  SystemHealthStatus getSystemHealthStatus() {
    return _lock.read(() {
      final totalComponents = _componentOverrides.length;
      final activeComponents = _componentMetrics.length;
      final totalConnections = _componentRelationships.length;
      final cacheSize = _cache.length;
      final memoryUsage = _calculateTotalMemoryUsage();

      return SystemHealthStatus(
        totalComponents: totalComponents,
        activeComponents: activeComponents,
        totalConnections: totalConnections,
        cacheSize: cacheSize,
        memoryUsage: memoryUsage,
        isHealthy: activeComponents >= totalComponents * 0.8,
        lastHealthCheck: DateTime.now(),
      );
    });
  }

  /// Perform automatic cleanup
  Future<void> performAutomaticCleanup() async {
    await _lock.write(() async {
      // Clean up expired cache entries
      await _cleanupExpiredCache();

      // Clean up weak references
      await _cleanupWeakReferences();

      // Clean up inactive components
      await _cleanupInactiveComponents();
    });
  }

  /// Update component metrics
  Future<void> updateComponentMetrics(
      String componentName, ComponentMetrics metrics) async {
    await _lock.write(() async {
      _componentMetrics[componentName] = metrics;
      _emitEvent(ConfigEventType.componentParametersUpdated,
          componentName: componentName);
    });
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}
