import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/utils.dart';

class NotificationService {
  factory NotificationService() => _instance;

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      final permissionStatus = await Permission.notification.request();
      if (permissionStatus.isDenied) {
        AppUtils.logWarning(
            'NotificationService', 'Notification permission denied');
        return;
      }

      // Initialize notification settings
      const androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosInitializationSettings = DarwinInitializationSettings();

      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      AppUtils.logInfo('NotificationService',
          'Notification service initialized successfully');
    } catch (e) {
      AppUtils.logError(
          'NotificationService', 'Failed to initialize notifications', e);
    }
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    try {
      final payload = response.payload;
      if (payload != null) {
        // Handle notification tap - could navigate to specific reminder
        AppUtils.logInfo('NotificationService',
            'Notification tapped with payload: $payload');
        // TODO: Navigate to reminder details screen
      }
    } catch (e) {
      AppUtils.logError(
          'NotificationService', 'Error handling notification tap', e);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      AppUtils.logWarning(
          'NotificationService', 'Notification service not initialized');
      return;
    }

    try {
      const androidNotificationDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      AppUtils.logInfo('NotificationService', 'Notification shown: $title');
    } catch (e) {
      AppUtils.logError(
          'NotificationService', 'Failed to show notification', e);
    }
  }

  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) {
      AppUtils.logWarning(
          'NotificationService', 'Notification service not initialized');
      return;
    }

    try {
      // Convert to timezone-aware datetime
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Don't schedule if time is in the past
      if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        AppUtils.logInfo(
            'NotificationService', 'Skipping past notification: $title');
        return;
      }

      const androidNotificationDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      AppUtils.logInfo('NotificationService',
          'Reminder notification scheduled: $title at $scheduledTime');
    } catch (e) {
      AppUtils.logError(
          'NotificationService', 'Failed to schedule reminder notification', e);
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      AppUtils.logInfo('NotificationService', 'Notification cancelled: $id');
    } catch (e) {
      AppUtils.logError(
          'NotificationService', 'Failed to cancel notification', e);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      AppUtils.logInfo('NotificationService', 'All notifications cancelled');
    } catch (e) {
      AppUtils.logError(
          'NotificationService', 'Failed to cancel all notifications', e);
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];

    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      AppUtils.logError(
          'NotificationService', 'Failed to get pending notifications', e);
      return [];
    }
  }

  // Test notification for debugging
  Future<void> showTestNotification() async {
    await showNotification(
      id: 999,
      title: 'Test Notification',
      body: 'This is a test notification from iSuite',
      payload: 'test',
    );
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final permissionStatus = await Permission.notification.status;
      return permissionStatus.isGranted;
    } catch (e) {
      AppUtils.logError(
          'NotificationService', 'Failed to check notification permission', e);
      return false;
    }
  }

  // Request permissions again
  Future<bool> requestPermissions() async {
    try {
      final permissionStatus = await Permission.notification.request();
      return permissionStatus.isGranted;
    } catch (e) {
      AppUtils.logError('NotificationService',
          'Failed to request notification permission', e);
      return false;
    }
  }
}
