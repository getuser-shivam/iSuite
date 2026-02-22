import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logging_service.dart';
import 'central_config.dart';

/// Enhanced Supabase Client Configuration
/// Provides proper initialization and configuration management
class SupabaseClientConfig {
  static const String _configKeyUrl = 'supabase.url';
  static const String _configKeyAnonKey = 'supabase.anon_key';
  static const String _configKeyServiceKey = 'supabase.service_key';
  static const String _configKeyDatabaseUrl = 'supabase.database_url';

  // Client instance
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  // Configuration
  static String get supabaseUrl => CentralConfig.instance.getParameter(_configKeyUrl, defaultValue: '');
  static String get supabaseAnonKey => CentralConfig.instance.getParameter(_configKeyAnonKey, defaultValue: '');
  static String get supabaseServiceKey => CentralConfig.instance.getParameter(_configKeyServiceKey, defaultValue: '');
  static String get supabaseDatabaseUrl => CentralConfig.instance.getParameter(_configKeyDatabaseUrl, defaultValue: '');

  /// Initialize Supabase client
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment variables
      await dotenv.load(fileName: '.env');

      // Get configuration from CentralConfig
      final url = supabaseUrl;
      final anonKey = supabaseAnonKey;

      if (url.isEmpty || anonKey.isEmpty) {
        throw Exception('Supabase URL and Anon Key must be configured in CentralConfig');
      }

      // Initialize Supabase
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        headers: _buildHeaders(),
      );

      _client = Supabase.instance.client;
      _isInitialized = true;

      LoggingService().info('Supabase client initialized successfully', 'SupabaseClientConfig');
    } catch (e, stackTrace) {
      LoggingService().error('Failed to initialize Supabase client', 'SupabaseClientConfig',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get Supabase client
  static SupabaseClient get client {
    if (!_isInitialized || _client == null) {
      throw StateError('Supabase client not initialized. Call initialize() first.');
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

  /// Build headers for Supabase requests
  static Map<String, String> _buildHeaders() {
    return {
      'apikey': supabaseAnonKey,
      'Authorization': 'Bearer $supabaseAnonKey',
      'Content-Type': 'application/json',
      'X-Client-Info': 'isuite-app',
      'X-Client-Version': '2.0.0',
      'X-Client-Name': 'iSuite',
      'X-Client-Platform': 'flutter',
      'X-Client-Environment': kDebugMode ? 'development' : 'production',
      'X-Client-User-Agent': 'isuite-app/2.0.0',
    };
  }

  /// Update configuration
  static Future<void> updateConfiguration({
    String? url,
    String? anonKey,
    String? serviceKey,
    String? databaseUrl,
  }) async {
    if (url != null) {
      await CentralConfig.instance.setParameter(_configKeyUrl, url);
    }
    if (anonKey != null) {
      await CentralConfig.instance.setParameter(_configKeyAnonKey, anonKey);
    }
    if (serviceKey != null) {
      await CentralConfig.instance.setParameter(_configKeyServiceKey, serviceKey);
    }
    if (databaseUrl != null) {
      await CentralConfig.instance.setParameter(_configKeyDatabaseUrl, databaseUrl);
    }

    // Reinitialize if already initialized
    if (_isInitialized) {
      reset();
      await initialize();
    }
  }
}

/// Supabase Database Tables
class SupabaseTables {
  // Core tables
  static const String users = 'users';
  static const String userProfiles = 'user_profiles';
  static const String userSessions = 'user_sessions';
  
  // File management tables
  static const String files = 'files';
  static const String fileConnections = 'file_connections';
  static const String fileMetadata = 'file_metadata';
  static const String fileVersions = 'file_versions';
  
  // Network management tables
  static const String networks = 'networks';
  static const String networkConnections = 'network_connections';
  static const String networkDevices = 'network_devices';
  
  // Task management tables
  static const String tasks = 'tasks';
  static const String taskComments = 'task_comments';
  static const String taskAttachments = 'task_attachments';
  
  // Calendar tables
  static const String calendarEvents = 'calendar_events';
  static const String calendarInvitations = 'calendar_invitations';
  
  // Notes tables
  static const String notes = 'notes';
  static const String noteTags = 'note_tags';
  static const String noteAttachments = 'note_attachments';
  
  // Reminders tables
  static const String reminders = 'reminders';
  static const String reminderNotifications = 'reminder_notifications';
  
  // Sync tables
  static const String syncMetadata = 'sync_metadata';
  static const String syncConflicts = 'sync_conflicts';
  static const String syncLogs = 'sync_logs';
  
  // Settings tables
  static const String userSettings = 'user_settings';
  static const String appSettings = 'app_settings';
  static const String featureFlags = 'feature_flags';
}

/// Supabase Storage Buckets
class SupabaseBuckets {
  static const String userFiles = 'user_files';
  static const String userBackups = 'user_backups';
  static const String userAvatars = 'user_avatars';
  static const String userDocuments = 'user_documents';
  static const String userMedia = 'user_media';
  static const String appAssets = 'app_assets';
  static const String tempFiles = 'temp_files';
  static const String sharedFiles = 'shared_files';
}

/// Supabase Database Functions
class SupabaseFunctions {
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

/// Supabase Realtime Subscriptions
class SupabaseSubscriptions {
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

/// Supabase Row Security Policies
class SupabasePolicies {
  // Users can only access their own data
  static const String ownDataPolicy = "auth.uid() = id";
  
  // Users can read their own profile
  static const String ownProfilePolicy = "auth.uid() = user_id";
  
  // Users can update their own profile
  static const String ownProfileUpdatePolicy = "auth.uid() = user_id";
  
  // Users can insert their own data
  static const String ownDataInsertPolicy = "auth.uid() = user_id";
  
  // Users can update their own data
  static const String ownDataUpdatePolicy = "auth.uid() = user_id";
  
  // Users can delete their own data
  static const String ownDataDeletePolicy = "auth.uid() = user_id";
  
  // Users can read public data
  static const String publicReadPolicy = "is_public = true";
  
  // Users can read shared data
  static const String sharedReadPolicy = "shared_with @> array[auth.uid()]";
  
  // Users can read data shared with them
  static const String sharedWithReadPolicy = "auth.uid() = ANY(shared_with)";
}

/// Supabase Database Triggers
class SupabaseTriggers {
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

/// Supabase Database Views
class SupabaseViews {
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

/// Supabase Database Indexes
class SupabaseIndexes {
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
