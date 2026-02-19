import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/constants.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> preferences;
  final bool isEmailVerified;
  final bool isPremium;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.createdAt,
    this.lastLoginAt,
    this.preferences = const {},
    this.isEmailVerified = false,
    this.isPremium = false,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    bool? isEmailVerified,
    bool? isPremium,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'preferences': preferences,
      'isEmailVerified': isEmailVerified,
      'isPremium': isPremium,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt'])
          : null,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPremium: json['isPremium'] ?? false,
    );
  }

  String get displayName => name.isNotEmpty ? name : email.split('@')[0];
  String get initials {
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return email[0].toUpperCase();
  }
}

class UserPreferences {
  final String language;
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final bool biometricEnabled;
  final String dateFormat;
  final String timeFormat;
  final bool autoBackupEnabled;

  const UserPreferences({
    this.language = 'en',
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.biometricEnabled = false,
    this.dateFormat = 'MM/dd/yyyy',
    this.timeFormat = '12h',
    this.autoBackupEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
      'biometricEnabled': biometricEnabled,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'autoBackupEnabled': autoBackupEnabled,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      language: json['language'] ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkModeEnabled: json['darkModeEnabled'] ?? false,
      biometricEnabled: json['biometricEnabled'] ?? false,
      dateFormat: json['dateFormat'] ?? 'MM/dd/yyyy',
      timeFormat: json['timeFormat'] ?? '12h',
      autoBackupEnabled: json['autoBackupEnabled'] ?? true,
    );
  }
}

class UserProvider extends ChangeNotifier {
  User? _user;
  UserPreferences _preferences = const UserPreferences();
  bool _isLoading = false;
  String? _error;
  bool _isSessionExpired = false;
  DateTime? _lastActivity;

  User? get user => _user;
  UserPreferences get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isSessionExpired => _isSessionExpired;
  bool get isPremium => _user?.isPremium ?? false;
  String get displayName => _user?.displayName ?? 'Guest';
  String get initials => _user?.initials ?? 'G';

  UserProvider() {
    _loadUser();
    _startSessionTimer();
  }

  Future<void> _loadUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      
      if (userJson != null) {
        final userData = json.decode(userJson);
        _user = User.fromJson(userData);
        
        // Check if session is expired (24 hours)
        if (_user!.lastLoginAt != null) {
          final now = DateTime.now();
          final difference = now.difference(_user!.lastLoginAt!);
          if (difference.inHours > 24) {
            _isSessionExpired = true;
            await logout();
            return;
          }
        }
        
        // Load preferences
        final prefsJson = prefs.getString('${AppConstants.userKey}_preferences');
        if (prefsJson != null) {
          final prefsData = json.decode(prefsJson);
          _preferences = UserPreferences.fromJson(prefsData);
        }
      }
      
      _lastActivity = DateTime.now();
    } catch (e) {
      _error = 'Failed to load user data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startSessionTimer() {
    // Update last activity every minute
    Future.delayed(const Duration(minutes: 1), () {
      if (_user != null) {
        _lastActivity = DateTime.now();
        _startSessionTimer();
      }
    });
  }

  Future<void> login(String email, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Please enter email and password');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      if (password.length < AppConstants.minPasswordLength) {
        throw Exception('Password must be at least ${AppConstants.minPasswordLength} characters');
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Demo login - in real app, this would be an API call
      _user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: email.split('@')[0].replaceAll('.', ' ').split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
        ).join(' '),
        email: email,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: true,
        isPremium: false,
        preferences: _preferences.toJson(),
      );

      // Save to local storage
      if (rememberMe) {
        await _saveUser();
      }

      _isSessionExpired = false;
      _lastActivity = DateTime.now();
      _error = null;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password, {String? confirmPassword}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate input
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('Please fill all fields');
      }

      if (name.length > AppConstants.maxUsernameLength) {
        throw Exception('Name is too long');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      if (password.length < AppConstants.minPasswordLength) {
        throw Exception('Password must be at least ${AppConstants.minPasswordLength} characters');
      }

      if (password.length > AppConstants.maxPasswordLength) {
        throw Exception('Password is too long');
      }

      if (confirmPassword != null && password != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      _user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: false,
        isPremium: false,
        preferences: _preferences.toJson(),
      );

      await _saveUser();
      _isSessionExpired = false;
      _lastActivity = DateTime.now();
      _error = null;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout({bool clearAll = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (clearAll) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.userKey);
        await prefs.remove('${AppConstants.userKey}_preferences');
      }
      
      _user = null;
      _isSessionExpired = false;
      _lastActivity = null;
      _error = null;
      
    } catch (e) {
      _error = 'Logout failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatar,
  }) async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate input
      if (name != null && name.isEmpty) {
        throw Exception('Name cannot be empty');
      }

      if (email != null && email.isNotEmpty && !_isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      _user = _user!.copyWith(
        name: name?.trim(),
        email: email?.trim(),
        avatar: avatar,
      );

      await _saveUser();
      _error = null;
      
    } catch (e) {
      _error = 'Update failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePreferences(UserPreferences newPreferences) async {
    _preferences = newPreferences;
    
    if (_user != null) {
      _user = _user!.copyWith(preferences: newPreferences.toJson());
      await _saveUser();
    }
    
    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate input
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        throw Exception('Please enter current and new password');
      }

      if (newPassword.length < AppConstants.minPasswordLength) {
        throw Exception('Password must be at least ${AppConstants.minPasswordLength} characters');
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // In real app, verify current password and update
      _error = null;
      
    } catch (e) {
      _error = 'Password change failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String password) async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (password.isEmpty) {
        throw Exception('Please enter your password');
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      await logout(clearAll: true);
      _error = null;
      
    } catch (e) {
      _error = 'Account deletion failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSession() async {
    if (_user == null) return;

    try {
      // Simulate session refresh
      await Future.delayed(const Duration(milliseconds: 500));
      
      _user = _user!.copyWith(lastLoginAt: DateTime.now());
      _isSessionExpired = false;
      _lastActivity = DateTime.now();
      
      await _saveUser();
      notifyListeners();
      
    } catch (e) {
      _error = 'Session refresh failed: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _saveUser() async {
    if (_user == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, json.encode(_user!.toJson()));
      await prefs.setString('${AppConstants.userKey}_preferences', json.encode(_preferences.toJson()));
    } catch (e) {
      debugPrint('Failed to save user data: $e');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}
