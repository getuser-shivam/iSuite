import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/central_config.dart';
import '../logging_service.dart';

/// Supabase Storage Service - Handles file uploads, downloads, and management
class SupabaseStorageService {
  final CentralConfig _config;
  final LoggingService _logger;

  SupabaseClient? _client;
  User? _currentUser;
  bool _isInitialized = false;

  SupabaseStorageService(this._config, this._logger);

  Future<void> initialize() async {
    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  Future<String?> uploadFile(
    String bucket,
    String filePath,
    List<int> fileBytes, {
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final fileOptions = FileOptions(
        contentType: contentType,
        upsert: true,
      );

      final response = await _client!.storage
          .from(bucket)
          .uploadBinary(filePath, fileBytes, fileOptions: fileOptions);

      if (response.isNotEmpty) {
        final publicUrl = _client!.storage.from(bucket).getPublicUrl(filePath);
        return publicUrl;
      }
      return null;
    } catch (e) {
      _logger.error('File upload failed', 'SupabaseStorageService', error: e);
      return null;
    }
  }

  Future<List<int>?> downloadFile(String bucket, String filePath) async {
    try {
      final response = await _client!.storage.from(bucket).download(filePath);
      return response;
    } catch (e) {
      _logger.error('File download failed', 'SupabaseStorageService', error: e);
      return null;
    }
  }

  Future<bool> deleteFile(String bucket, String filePath) async {
    try {
      await _client!.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      _logger.error('File deletion failed', 'SupabaseStorageService', error: e);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listFiles(String bucket,
      {String? path}) async {
    try {
      final response = await _client!.storage.from(bucket).list(path: path);
      return response.map((file) => file.toJson()).toList();
    } catch (e) {
      _logger.error('File listing failed', 'SupabaseStorageService', error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'service': 'storage',
      'initialized': _isInitialized,
      'user': _currentUser?.id,
    };
  }
}
