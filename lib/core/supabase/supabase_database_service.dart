import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/central_config.dart';
import '../logging_service.dart';

/// Supabase Database Service - Handles data operations with caching and offline support
class SupabaseDatabaseService {
  final CentralConfig _config;
  final LoggingService _logger;

  SupabaseClient? _client;
  User? _currentUser;
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  bool _isInitialized = false;

  SupabaseDatabaseService(this._config, this._logger);

  Future<void> initialize() async {
    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool? ascending,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _client!.from(table);

      if (select != null) query = query.select(select);
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending ?? true);
      }
      if (limit != null) query = query.limit(limit);
      if (offset != null) query = query.offset(offset);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.error('Database query failed', 'SupabaseDatabaseService',
          error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> insert(
      String table, Map<String, dynamic> data) async {
    try {
      final response =
          await _client!.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      _logger.error('Database insert failed', 'SupabaseDatabaseService',
          error: e);
      return null;
    }
  }

  Future<bool> update(String table, Map<String, dynamic> data,
      Map<String, dynamic> filters) async {
    try {
      var query = _client!.from(table);
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query.update(data);
      return true;
    } catch (e) {
      _logger.error('Database update failed', 'SupabaseDatabaseService',
          error: e);
      return false;
    }
  }

  Future<bool> delete(String table, Map<String, dynamic> filters) async {
    try {
      var query = _client!.from(table);
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query.delete();
      return true;
    } catch (e) {
      _logger.error('Database delete failed', 'SupabaseDatabaseService',
          error: e);
      return false;
    }
  }

  Future<bool> healthCheck() async {
    try {
      await _client!.from('user_profiles').select('count').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    final isHealthy = await healthCheck();
    return {
      'service': 'database',
      'initialized': _isInitialized,
      'healthy': isHealthy,
      'user': _currentUser?.id,
      'cache_size': _cache.length,
    };
  }
}
