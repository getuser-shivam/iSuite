import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logging_service.dart';
import 'central_config.dart';

/// Enhanced PocketBase Client Configuration
/// Provides proper initialization and configuration management
class PocketBaseClientConfig {
  static const String _configKeyUrl = 'pocketbase.url';
  static const String _configKeyToken = 'pocketbase.token';

  // Client instance
  static PocketBase? _client;
  static bool _isInitialized = false;

  // Configuration
  static String get pocketbaseUrl => CentralConfig.instance.getParameter(_configKeyUrl, defaultValue: '');
  static String get pocketbaseToken => CentralConfig.instance.getParameter(_configKeyToken, defaultValue: '');

  /// Initialize PocketBase client
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment variables
      await dotenv.load(fileName: '.env');

      // Get configuration from CentralConfig
      final url = pocketbaseUrl;

      if (url.isEmpty) {
        throw Exception('PocketBase URL must be configured in CentralConfig');
      }

      // Initialize PocketBase
      _client = PocketBase(url);

      // Set auth token if available
      final token = pocketbaseToken;
      if (token.isNotEmpty) {
        _client!.authStore.save(token, null);
      }

      _isInitialized = true;
      _isInitialized = true;

      LoggingService().info('PocketBase client initialized successfully', 'PocketBaseClientConfig');
    } catch (e, stackTrace) {
      LoggingService().error('Failed to initialize PocketBase client', 'PocketBaseClientConfig',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get PocketBase client
  static PocketBase get client {
    if (!_isInitialized || _client == null) {
      throw StateError('PocketBase client not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Check if initialized
  static bool get isInitialized => _isInitialized;

  /// Reset client (for testing)
  static void reset() {
    _client = null;
    _isInitialized = false;
  }

  /// Update configuration
  static Future<void> updateConfiguration({
    String? url,
    String? token,
  }) async {
    if (url != null) {
      await CentralConfig.instance.setParameter(_configKeyUrl, url);
    }
    if (token != null) {
      await CentralConfig.instance.setParameter(_configKeyToken, token);
    }

    // Reinitialize if already initialized
    if (_isInitialized) {
      reset();
      await initialize();
    }
  }
}

/// PocketBase Database Collections
class PocketBaseCollections {
  // Core collections
  static const String users = 'users';
  static const String userProfiles = 'user_profiles';
  static const String userSessions = 'user_sessions';
  
  // File management collections
  static const String files = 'files';
  static const String fileConnections = 'file_connections';
  static const String fileMetadata = 'file_metadata';
  static const String fileVersions = 'file_versions';
  
  // Network management collections
  static const String networks = 'networks';
  static const String networkConnections = 'network_connections';
  static const String networkDevices = 'network_devices';
  
  // Task management collections
  static const String tasks = 'tasks';
  static const String taskComments = 'task_comments';
  static const String taskAttachments = 'task_attachments';
  
  // Calendar collections
  static const String calendarEvents = 'calendar_events';
  static const String calendarInvitations = 'calendar_invitations';
  
  // Notes collections
  static const String notes = 'notes';
  static const String noteTags = 'note_tags';
  static const String noteAttachments = 'note_attachments';
  
  // Reminders collections
  static const String reminders = 'reminders';
  static const String reminderNotifications = 'reminder_notifications';
  
  // Sync collections
  static const String syncMetadata = 'sync_metadata';
  static const String syncConflicts = 'sync_conflicts';
  static const String syncLogs = 'sync_logs';
  
  // Settings collections
  static const String userSettings = 'user_settings';
  static const String appSettings = 'app_settings';
  static const String featureFlags = 'feature_flags';
}

/// PocketBase Storage Buckets
class PocketBaseBuckets {
  static const String userFiles = 'user_files';
  static const String userBackups = 'user_backups';
  static const String userAvatars = 'user_avatars';
  static const String userDocuments = 'user_documents';
  static const String userMedia = 'user_media';
  static const String appAssets = 'app_assets';
  static const String tempFiles = 'temp_files';
  static const String sharedFiles = 'shared_files';
}

/// PocketBase Database Functions
class PocketBaseFunctions {
  static const String searchFiles = 'search_files';
  static const String getFilePreview = 'get_file_preview';
  static const String generateThumbnail = 'generate_thumbnail';
  static const String calculateFileSize = 'calculate_file_size';
  static const String validateFileAccess = 'validate_file_access';
  static const String syncUserData = 'sync_user_data';
  static const String backupUserData = 'backup_user_data';
  static const String restoreUserData = 'restore_user_data';
  static const String cleanupExpiredFiles = 'cleanup_expired_files';
  static const String updateFileStatistics = 'update_file_statistics';
  static const String sendNotification = 'send_notification';
  static const String logUserActivity = 'log_user_activity';
}

/// PocketBase Realtime Subscriptions
class PocketBaseSubscriptions {
  static const String userUpdates = 'user_updates';
  static const String fileUpdates = 'file_updates';
  static const String networkUpdates = 'network_updates';
  static const String taskUpdates = 'task_updates';
  static const String calendarUpdates = 'calendar_updates';
  static const String noteUpdates = 'note_updates';
  static const String reminderUpdates = 'reminder_updates';
  static const String syncUpdates = 'sync_updates';
  static const String notificationUpdates = 'notification_updates';
}

/// PocketBase Collection Rules
class PocketBaseRules {
  // Users can only access their own data
  static const String ownDataRule = "@request.auth.id = id";
  
  // Users can read their own profile
  static const String ownProfileRule = "@request.auth.id = user_id";
  
  // Users can update their own profile
  static const String ownProfileUpdateRule = "@request.auth.id = user_id";
  
  // Users can insert their own data
  static const String ownDataInsertRule = "@request.auth.id = user_id";
  
  // Users can update their own data
  static const String ownDataUpdateRule = "@request.auth.id = user_id";
  
  // Users can delete their own data
  static const String ownDataDeleteRule = "@request.auth.id = user_id";
  
  // Users can read public data
  static const String publicReadRule = "is_public = true";
  
  // Users can read shared data
  static const String sharedReadRule = "@request.auth.id ?= shared_with";
  
  // Users can read data shared with them
  static const String sharedWithReadRule = "@request.auth.id ?= shared_with";
}

/// PocketBase Database Hooks
class PocketBaseHooks {
  static const String updateUserTimestamp = 'update_user_timestamp';
  static const String updateFileTimestamp = 'update_file_timestamp';
  static const String updateTaskTimestamp = 'update_task_timestamp';
  static const String updateCalendarTimestamp = 'update_calendar_timestamp';
  static const String updateNoteTimestamp = 'update_note_timestamp';
  static const String updateReminderTimestamp = 'update_reminder_timestamp';
  static const String updateSyncTimestamp = 'update_sync_timestamp';
  static const String logFileActivity = 'log_file_activity';
  static const String logUserActivity = 'log_user_activity';
  static const String sendNotification = 'send_notification';
  static const String updateStatistics = 'update_statistics';
  static const String cleanupOldData = 'cleanup_old_data';
}

/// PocketBase Database Views
class PocketBaseViews {
  static const String userDashboard = 'user_dashboard';
  static const String fileStatistics = 'file_statistics';
  static const String networkOverview = 'network_overview';
  static const String taskSummary = 'task_summary';
  static const String calendarOverview = 'calendar_overview';
  static const String noteSummary = 'note_summary';
  static const String reminderSummary = 'reminder_summary';
  static const String syncStatus = 'sync_status';
  static const String activityLog = 'activity_log';
  static const String systemHealth = 'system_health';
}

/// PocketBase Database Indexes
class PocketBaseIndexes {
  // User indexes
  static const String usersEmailIndex = 'users_email_idx';
  static const String usersNameIndex = 'users_name_idx';
  static const String usersCreatedAtIndex = 'users_created_at_idx';
  
  // File indexes
  static const String filesUserIdIndex = 'files_user_id_idx';
  static const String filesNameIndex = 'files_name_idx';
  static const String filesTypeIndex = 'files_type_idx';
  static const String filesSizeIndex = 'files_size_idx';
  static const String filesCreatedAtIndex = 'files_created_at_idx';
  static const String filesUpdatedAtIndex = 'files_updated_at_idx';
  
  // Network indexes
  static const String networksUserIdIndex = 'networks_user_id_idx';
  static const String networksNameIndex = 'networks_name_idx';
  static const String networksTypeIndex = 'networks_type_idx';
  static const String networksCreatedAtIndex = 'networks_created_at_idx';
  
  // Task indexes
  static const String tasksUserIdIndex = 'tasks_user_id_idx';
  static const String tasksStatusIndex = 'tasks_status_idx';
  static const String tasksPriorityIndex = 'tasks_priority_idx';
  static const String tasksDueDateIndex = 'tasks_due_date_idx';
  static const String tasksCreatedAtIndex = 'tasks_created_at_idx';
  
  // Calendar indexes
  static const String eventsUserIdIndex = 'events_user_id_idx';
  static const String eventsStartDateIndex = 'events_start_date_idx';
  static const String eventsEndDateIndex = 'events_end_date_idx';
  static const String eventsCreatedAtIndex = 'events_created_at_idx';
  
  // Note indexes
  static const String notesUserIdIndex = 'notes_user_id_idx';
  static const String notesTitleIndex = 'notes_title_idx';
  static const String notesTagIndex = 'notes_tag_idx';
  static const String notesCreatedAtIndex = 'notes_created_at_idx';
  
  // Reminder indexes
  static const String remindersUserIdIndex = 'reminders_user_id_idx';
  static const String remindersDueDateIndex = 'reminders_due_date_idx';
  static const String remindersStatusIndex = 'reminders_status_idx';
  static const String remindersCreatedAtIndex = 'reminders_created_at_idx';
}
