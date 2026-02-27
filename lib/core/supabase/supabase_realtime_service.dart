import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/central_config.dart';
import '../logging_service.dart';

/// Supabase Real-time Service - Handles real-time subscriptions and live updates
class SupabaseRealtimeService {
  final CentralConfig _config;
  final LoggingService _logger;

  SupabaseClient? _client;
  User? _currentUser;
  final Map<String, RealtimeChannel> _channels = {};
  bool _isInitialized = false;

  SupabaseRealtimeService(this._config, this._logger);

  Future<void> initialize() async {
    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  Future<RealtimeChannel> subscribeToTable(
    String table,
    Function(Map<String, dynamic>) onUpdate, {
    String? filter,
  }) async {
    final channelName = 'table_$table${filter != null ? '_$filter' : ''}';

    if (_channels.containsKey(channelName)) {
      return _channels[channelName]!;
    }

    final channel = _client!.channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: filter != null ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: _currentUser?.id) : null,
          callback: (payload) {
            onUpdate(payload.newRecord ?? {});
          },
        )
        .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  Future<void> unsubscribeFromTable(String table, {String? filter}) async {
    final channelName = 'table_$table${filter != null ? '_$filter' : ''}';

    if (_channels.containsKey(channelName)) {
      await _channels[channelName]!.unsubscribe();
      _channels.remove(channelName);
    }
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'service': 'realtime',
      'initialized': _isInitialized,
      'active_channels': _channels.length,
      'user': _currentUser?.id,
    };
  }
}
