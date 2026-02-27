import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/central_config.dart';
import '../logging_service.dart';

/// Supabase Auth Service - Handles user authentication and sessions
class SupabaseAuthService {
  final CentralConfig _config;
  final LoggingService _logger;

  SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSubscription;
  Function(User?)? onAuthStateChanged;

  User? _currentUser;
  bool _isInitialized = false;

  SupabaseAuthService(this._config, this._logger);

  Future<void> initialize() async {
    _client = Supabase.instance.client;

    // Setup auth state monitoring
    _authSubscription = _client!.auth.onAuthStateChange.listen((event) {
      _currentUser = event.session?.user;
      onAuthStateChanged?.call(_currentUser);
      _logger.info('Auth state changed: ${_currentUser?.id}', 'SupabaseAuthService');
    });

    _isInitialized = true;
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _createUserProfile(response.user!);
        return AuthResponse.success(response.user!);
      }

      return AuthResponse.error(response.error?.message ?? 'Sign in failed');
    } catch (e) {
      return AuthResponse.error(e.toString());
    }
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, {String? name}) async {
    try {
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      if (response.user != null) {
        await _createUserProfile(response.user!, name: name);
        return AuthResponse.success(response.user!);
      }

      return AuthResponse.error(response.error?.message ?? 'Sign up failed');
    } catch (e) {
      return AuthResponse.error(e.toString());
    }
  }

  Future<void> signOut() async {
    await _client!.auth.signOut();
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'service': 'auth',
      'initialized': _isInitialized,
      'user': _currentUser?.id,
      'session_valid': _client?.auth.currentSession != null,
    };
  }

  Future<void> _createUserProfile(User user, {String? name}) async {
    try {
      final profile = {
        'id': user.id,
        'email': user.email,
        'name': name ?? user.userMetadata?['name'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client!.from('user_profiles').upsert(profile);
    } catch (e) {
      _logger.error('Failed to create user profile', 'SupabaseAuthService', error: e);
    }
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}
