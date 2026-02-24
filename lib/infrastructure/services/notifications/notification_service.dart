import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/central_config.dart';

/// Notification service for local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestSoundPermission: false,
            requestBadgePermission: false,
            requestAlertPermission: false,
          );

      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(defaultActionName: 'Open notification');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          print('Notification tapped: ${response.payload}');
        },
      );

      _isInitialized = true;
      print('Notification service initialized');
    } catch (e) {
      print('Failed to initialize notifications: $e');
    }
  }

  Future<void> showFileOperationNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'file_operations',
          'File Operations',
          channelDescription: 'Notifications for file operations',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showAiNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'ai_assistant',
          'AI Assistant',
          channelDescription: 'Notifications from AI assistant',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1000, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showCloudNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'cloud_sync',
          'Cloud Sync',
          channelDescription: 'Notifications for cloud synchronization',
          importance: Importance.low,
          priority: Priority.low,
        );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2000, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showBuildNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'build_system',
          'Build System',
          channelDescription: 'Notifications for build operations',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3000, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showErrorNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'error_alerts',
          'Error Alerts',
          channelDescription: 'Important error notifications',
          importance: Importance.max,
          priority: Priority.max,
        );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 4000, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
