import 'package:flutter/material.dart';
import '../config/central_config.dart';

/// Notification model
class AppNotification {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  final String? actionUrl;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.timestamp,
    this.actionUrl,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    IconData? icon,
    Color? color,
    DateTime? timestamp,
    String? actionUrl,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      timestamp: timestamp ?? this.timestamp,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// App Provider - Manages global app state with central configuration
class AppProvider extends ChangeNotifier {
  final CentralConfig _config = CentralConfig.instance;

  // Centralized parameters
  late int _maxNotifications;
  late Duration _notificationAutoHideDuration;
  late bool _enableNotificationSounds;
  late bool _enableNotificationVibration;
  late Color _defaultNotificationColor;
  late bool _enableNotificationGrouping;

  int _notificationCount = 0;
  final List<AppNotification> _notifications = [];
  bool _isInitialized = false;

  // Getters
  int get notificationCount => _notificationCount;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationCount => _notifications.where((n) => !n.isRead).length;
  int get maxNotifications => _maxNotifications;
  bool get isInitialized => _isInitialized;

  AppProvider() {
    _initializeProvider();
  }

  /// Initialize provider with central configuration
  Future<void> _initializeProvider() async {
    try {
      // Register component with central config
      await _config.initialize();

      // Load centralized parameters
      _maxNotifications = await _config.getParameter<int>('app.notifications.max_count') ?? 50;
      _notificationAutoHideDuration = Duration(
        seconds: await _config.getParameter<int>('app.notifications.auto_hide_seconds') ?? 5,
      );
      _enableNotificationSounds = await _config.getParameter<bool>('app.notifications.enable_sounds') ?? true;
      _enableNotificationVibration = await _config.getParameter<bool>('app.notifications.enable_vibration') ?? true;
      _enableNotificationGrouping = await _config.getParameter<bool>('app.notifications.enable_grouping') ?? true;

      // Load default notification color
      final colorValue = await _config.getParameter<int>('app.notifications.default_color');
      _defaultNotificationColor = colorValue != null ? Color(colorValue) : Colors.blue;

      _isInitialized = true;
      notifyListeners();

      // Set up parameter change listeners
      _setupParameterListeners();

    } catch (e) {
      debugPrint('AppProvider initialization error: $e');
      // Use fallback defaults
      _setFallbackDefaults();
    }
  }

  void _setFallbackDefaults() {
    _maxNotifications = 50;
    _notificationAutoHideDuration = const Duration(seconds: 5);
    _enableNotificationSounds = true;
    _enableNotificationVibration = true;
    _enableNotificationGrouping = true;
    _defaultNotificationColor = Colors.blue;
    _isInitialized = true;
  }

  /// Set up listeners for parameter changes
  void _setupParameterListeners() {
    _config.events.listen((event) {
      if (event.type == ConfigEventType.parameterChanged) {
        switch (event.parameterKey) {
          case 'app.notifications.max_count':
            _maxNotifications = event.newValue ?? 50;
            _enforceMaxNotifications();
            notifyListeners();
            break;
          case 'app.notifications.enable_sounds':
            _enableNotificationSounds = event.newValue ?? true;
            break;
          case 'app.notifications.enable_vibration':
            _enableNotificationVibration = event.newValue ?? true;
            break;
          case 'app.notifications.enable_grouping':
            _enableNotificationGrouping = event.newValue ?? true;
            break;
          case 'app.notifications.default_color':
            if (event.newValue is int) {
              _defaultNotificationColor = Color(event.newValue);
            }
            break;
        }
      }
    });
  }

  /// Add notification with central configuration
  void addNotification({
    required String title,
    required String message,
    IconData? icon,
    Color? color,
    String? actionUrl,
    bool autoHide = true,
  }) {
    if (!_isInitialized) return;

    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      icon: icon ?? Icons.notifications,
      color: color ?? _defaultNotificationColor,
      timestamp: DateTime.now(),
      actionUrl: actionUrl,
    );

    _notifications.insert(0, notification);
    _notificationCount = _notifications.length;

    // Enforce max notifications limit
    _enforceMaxNotifications();

    notifyListeners();

    // Auto-hide notification if enabled
    if (autoHide && _notificationAutoHideDuration.inSeconds > 0) {
      Future.delayed(_notificationAutoHideDuration, () {
        if (_notifications.contains(notification)) {
          markNotificationAsRead(notification.id);
        }
      });
    }

    // Play sound if enabled
    if (_enableNotificationSounds) {
      _playNotificationSound();
    }

    // Trigger vibration if enabled
    if (_enableNotificationVibration) {
      _triggerVibration();
    }
  }

  void _enforceMaxNotifications() {
    if (_notifications.length > _maxNotifications) {
      final excess = _notifications.length - _maxNotifications;
      _notifications.removeRange(_maxNotifications, _notifications.length + excess);
      _notificationCount = _notifications.length;
    }
  }

  void removeNotification(String id) {
    final initialLength = _notifications.length;
    _notifications.removeWhere((notification) => notification.id == id);

    if (_notifications.length != initialLength) {
      _notificationCount = _notifications.length;
      notifyListeners();
    }
  }

  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    bool hasChanges = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications.clear();
    _notificationCount = 0;
    notifyListeners();
  }

  void clearReadNotifications() {
    _notifications.removeWhere((notification) => notification.isRead);
    _notificationCount = _notifications.length;
    notifyListeners();
  }

  /// Get notifications filtered by type
  List<AppNotification> getNotificationsByType(String type) {
    // This could be extended with notification types/categories
    return _notifications;
  }

  /// Get recent notifications
  List<AppNotification> getRecentNotifications({int limit = 10}) {
    return _notifications.take(limit).toList();
  }

  /// Search notifications
  List<AppNotification> searchNotifications(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _notifications.where((notification) =>
      notification.title.toLowerCase().contains(lowercaseQuery) ||
      notification.message.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Update notification settings via central config
  Future<void> updateNotificationSettings({
    int? maxCount,
    bool? enableSounds,
    bool? enableVibration,
    bool? enableGrouping,
    Color? defaultColor,
  }) async {
    if (maxCount != null) {
      await _config.setParameter('app.notifications.max_count', maxCount);
    }
    if (enableSounds != null) {
      await _config.setParameter('app.notifications.enable_sounds', enableSounds);
    }
    if (enableVibration != null) {
      await _config.setParameter('app.notifications.enable_vibration', enableVibration);
    }
    if (enableGrouping != null) {
      await _config.setParameter('app.notifications.enable_grouping', enableGrouping);
    }
    if (defaultColor != null) {
      await _config.setParameter('app.notifications.default_color', defaultColor.value);
    }
  }

  void _playNotificationSound() {
    // Platform-specific sound implementation would go here
    // For now, this is a placeholder
    debugPrint('Playing notification sound');
  }

  void _triggerVibration() {
    // Platform-specific vibration implementation would go here
    // For now, this is a placeholder
    debugPrint('Triggering vibration');
  }

  /// Get system health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'totalNotifications': _notificationCount,
      'unreadNotifications': unreadNotificationCount,
      'maxNotifications': _maxNotifications,
      'isInitialized': _isInitialized,
      'notificationSettings': {
        'sounds': _enableNotificationSounds,
        'vibration': _enableNotificationVibration,
        'grouping': _enableNotificationGrouping,
        'autoHide': _notificationAutoHideDuration.inSeconds,
      },
    };
  }

  /// Export notifications for backup
  Map<String, dynamic> exportNotifications() {
    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'notifications': _notifications.map((n) => {
        'id': n.id,
        'title': n.title,
        'message': n.message,
        'icon': n.icon.codePoint,
        'color': n.color.value,
        'timestamp': n.timestamp.toIso8601String(),
        'actionUrl': n.actionUrl,
        'isRead': n.isRead,
      }).toList(),
      'settings': {
        'maxCount': _maxNotifications,
        'enableSounds': _enableNotificationSounds,
        'enableVibration': _enableNotificationVibration,
        'enableGrouping': _enableNotificationGrouping,
        'defaultColor': _defaultNotificationColor.value,
      },
    };
  }

  /// Import notifications from backup
  Future<void> importNotifications(Map<String, dynamic> data) async {
    try {
      final notifications = data['notifications'] as List?;
      if (notifications != null) {
        _notifications.clear();
        for (final item in notifications) {
          final notification = AppNotification(
            id: item['id'],
            title: item['title'],
            message: item['message'],
            icon: IconData(item['icon'], fontFamily: 'MaterialIcons'),
            color: Color(item['color']),
            timestamp: DateTime.parse(item['timestamp']),
            actionUrl: item['actionUrl'],
            isRead: item['isRead'] ?? false,
          );
          _notifications.add(notification);
        }
        _notificationCount = _notifications.length;

        // Apply imported settings if available
        final settings = data['settings'];
        if (settings != null) {
          await updateNotificationSettings(
            maxCount: settings['maxCount'],
            enableSounds: settings['enableSounds'],
            enableVibration: settings['enableVibration'],
            enableGrouping: settings['enableGrouping'],
            defaultColor: settings['defaultColor'] != null ? Color(settings['defaultColor']) : null,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error importing notifications: $e');
    }
  }

  @override
  void dispose() {
    _config.dispose();
    super.dispose();
  }
}
