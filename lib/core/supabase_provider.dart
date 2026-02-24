import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_manager.dart';

/// Enhanced Supabase Integration Provider
/// Provides centralized access to all Supabase services
class SupabaseProvider {
  static final SupabaseProvider _instance = SupabaseProvider._internal();
  factory SupabaseProvider() => _instance;

  final SupabaseManager _manager = SupabaseManager();

  SupabaseProvider._internal();

  /// Initialize all Supabase services
  Future<void> initialize() async {
    await _manager.initialize();
  }

  /// Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  /// Get auth service
  SupabaseAuthService get auth => _manager.auth;

  /// Get database service
  SupabaseDatabaseService get database => _manager.database;

  /// Get storage service
  SupabaseStorageService get storage => _manager.storage;

  /// Get realtime service
  SupabaseRealtimeService get realtime => _manager.realtime;

  /// Get offline service
  SupabaseOfflineService get offline => _manager.offline;

  /// Get current user
  User? get currentUser => _manager.auth._currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get system health status
  Future<Map<String, dynamic>> getSystemHealth() => _manager.getSystemHealth();

  /// Dispose all services
  void dispose() => _manager.dispose();
}

/// Supabase Configuration Helper
class SupabaseConfig {
  static const String url = 'your-supabase-url';
  static const String anonKey = 'your-supabase-anon-key';
  static const String serviceRoleKey = 'your-supabase-service-role-key';

  /// Get configuration for different environments
  static Map<String, String> getConfig(String environment) {
    switch (environment) {
      case 'development':
        return {
          'supabase.url': url,
          'supabase.anon_key': anonKey,
          'supabase.service_role_key': serviceRoleKey,
        };
      case 'staging':
        return {
          'supabase.url': 'your-staging-url',
          'supabase.anon_key': 'your-staging-anon-key',
          'supabase.service_role_key': 'your-staging-service-role-key',
        };
      case 'production':
        return {
          'supabase.url': 'your-production-url',
          'supabase.anon_key': 'your-production-anon-key',
          'supabase.service_role_key': 'your-production-service-role-key',
        };
      default:
        return getConfig('development');
    }
  }
}

/// Supabase Tables Schema
class SupabaseSchema {
  // User Management
  static const String users = 'auth.users';
  static const String userProfiles = 'public.user_profiles';
  static const String userPreferences = 'public.user_preferences';
  static const String userSessions = 'public.user_sessions';

  // File Management
  static const String files = 'public.files';
  static const String fileMetadata = 'public.file_metadata';
  static const String fileVersions = 'public.file_versions';
  static const String fileShares = 'public.file_shares';

  // Network Management
  static const String networkDevices = 'public.network_devices';
  static const String networkScans = 'public.network_scans';
  static const String networkConnections = 'public.network_connections';

  // Analytics & Monitoring
  static const String userActivity = 'public.user_activity';
  static const String systemMetrics = 'public.system_metrics';
  static const String errorLogs = 'public.error_logs';

  // Settings & Configuration
  static const String appSettings = 'public.app_settings';
  static const String userSettings = 'public.user_settings';

  // Real-time subscriptions
  static const String realtimeChannels = 'realtime.channels';
  static const String realtimeMessages = 'realtime.messages';
}

/// Supabase Storage Buckets
class SupabaseBuckets {
  static const String userFiles = 'user-files';
  static const String sharedFiles = 'shared-files';
  static const String tempFiles = 'temp-files';
  static const String backupFiles = 'backup-files';
  static const String avatarImages = 'avatar-images';
}

/// Supabase Real-time Events
class SupabaseEvents {
  static const String userOnline = 'user.online';
  static const String userOffline = 'user.offline';
  static const String fileShared = 'file.shared';
  static const String fileDownloaded = 'file.downloaded';
  static const String deviceConnected = 'device.connected';
  static const String deviceDisconnected = 'device.disconnected';
}

/// Supabase Error Types
enum SupabaseErrorType {
  network,
  authentication,
  authorization,
  database,
  storage,
  realtime,
  validation,
  unknown,
}

/// Enhanced Supabase Exception
class SupabaseException implements Exception {
  final String message;
  final SupabaseErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  SupabaseException(
    this.message, {
    this.type = SupabaseErrorType.unknown,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'SupabaseException: $message (Type: $type)';
}

/// Supabase Response Wrapper
class SupabaseResponse<T> {
  final bool success;
  final T? data;
  final SupabaseException? error;

  SupabaseResponse.success(this.data)
      : success = true,
        error = null;

  SupabaseResponse.error(this.error)
      : success = false,
        data = null;

  static SupabaseResponse<T> fromSupabase<T>(dynamic response) {
    try {
      if (response == null) {
        return SupabaseResponse.error(
          SupabaseException('Response is null', type: SupabaseErrorType.network),
        );
      }

      // Handle Supabase error format
      if (response is Map && response.containsKey('error')) {
        final error = response['error'];
        return SupabaseResponse.error(
          SupabaseException(
            error['message'] ?? 'Unknown error',
            type: SupabaseErrorType.database,
            originalError: error,
          ),
        );
      }

      return SupabaseResponse.success(response as T);
    } catch (e) {
      return SupabaseResponse.error(
        SupabaseException(
          'Response parsing failed: $e',
          type: SupabaseErrorType.validation,
          originalError: e,
        ),
      );
    }
  }
}

/// Supabase Query Builder Helper
class SupabaseQueryBuilder {
  final SupabaseClient _client;
  final String _table;

  SupabaseQueryBuilder(this._client, this._table);

  /// Build select query
  SupabaseQueryBuilder select([String? columns]) {
    _client.from(_table).select(columns ?? '*');
    return this;
  }

  /// Add where condition
  SupabaseQueryBuilder where(String column, dynamic value) {
    _client.from(_table).eq(column, value);
    return this;
  }

  /// Add order by
  SupabaseQueryBuilder order(String column, {bool ascending = true}) {
    _client.from(_table).order(column, ascending: ascending);
    return this;
  }

  /// Add limit
  SupabaseQueryBuilder limit(int count) {
    _client.from(_table).limit(count);
    return this;
  }

  /// Add offset
  SupabaseQueryBuilder offset(int count) {
    _client.from(_table).offset(count);
    return this;
  }

  /// Execute query
  Future<SupabaseResponse<List<Map<String, dynamic>>>> execute() async {
    try {
      final response = await _client.from(_table).select();
      return SupabaseResponse.success(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      return SupabaseResponse.error(
        SupabaseException(
          'Query execution failed: $e',
          type: SupabaseErrorType.database,
          originalError: e,
        ),
      );
    }
  }
}

/// Supabase Analytics Helper
class SupabaseAnalytics {
  final SupabaseDatabaseService _database;

  SupabaseAnalytics(this._database);

  /// Track user action
  Future<void> trackAction(String action, {Map<String, dynamic>? metadata}) async {
    final data = {
      'action': action,
      'user_id': _database._currentUser?.id,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };

    await _database.insert(SupabaseSchema.userActivity, data);
  }

  /// Track system metric
  Future<void> trackMetric(String metric, num value, {String? unit}) async {
    final data = {
      'metric': metric,
      'value': value,
      'unit': unit ?? 'count',
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _database.insert(SupabaseSchema.systemMetrics, data);
  }

  /// Log error
  Future<void> logError(String error, String context, {StackTrace? stackTrace}) async {
    final data = {
      'error': error,
      'context': context,
      'stack_trace': stackTrace?.toString(),
      'user_id': _database._currentUser?.id,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _database.insert(SupabaseSchema.errorLogs, data);
  }
}
