import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../../core/utils.dart';
import '../../domain/models/task.dart';
import '../database_helper.dart';

class UserRepository {
  static UserRepository? _instance;
  static UserRepository get instance =>
      _instance ??= UserRepository._internal();
  UserRepository._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<User?> getCurrentUser() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'users',
        where: 'is_active = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppUtils.logError('Failed to get current user', error: e);
      return null;
    }
  }

  Future<User> createUser({
    required String name,
    required String email,
    String? avatarUrl,
    String? phone,
    String? timezone,
    String? language,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final user = User(
        id: AppUtils.generateId(),
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        phone: phone,
        timezone: timezone ?? 'UTC',
        language: language ?? 'en',
        isActive: true,
        emailVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insert('users', user.toMap());
      AppUtils.logInfo('Created user: ${user.email}');
      return user;
    } catch (e) {
      AppUtils.logError('Failed to create user', error: e);
      rethrow;
    }
  }

  Future<User?> getUserById(String userId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppUtils.logError('Failed to get user by ID', error: e);
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppUtils.logError('Failed to get user by email', error: e);
      return null;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      final db = await _databaseHelper.database;
      final updatedUser = user.copyWith(updatedAt: DateTime.now());

      final count = await db.update(
        'users',
        updatedUser.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );

      if (count > 0) {
        AppUtils.logInfo('Updated user: ${user.email}');
        return true;
      }
      return false;
    } catch (e) {
      AppUtils.logError('Failed to update user', error: e);
      return false;
    }
  }

  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? avatarUrl,
    String? phone,
    String? timezone,
    String? language,
  }) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedUser = user.copyWith(
        name: name ?? user.name,
        avatarUrl: avatarUrl ?? user.avatarUrl,
        phone: phone ?? user.phone,
        timezone: timezone ?? user.timezone,
        language: language ?? user.language,
        updatedAt: DateTime.now(),
      );

      return await updateUser(updatedUser);
    } catch (e) {
      AppUtils.logError('Failed to update user profile', error: e);
      return false;
    }
  }

  Future<bool> verifyEmail(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedUser = user.copyWith(
        emailVerified: true,
        updatedAt: DateTime.now(),
      );

      return await updateUser(updatedUser);
    } catch (e) {
      AppUtils.logError('Failed to verify email', error: e);
      return false;
    }
  }

  Future<bool> deactivateUser(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedUser = user.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      return await updateUser(updatedUser);
    } catch (e) {
      AppUtils.logError('Failed to deactivate user', error: e);
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final db = await _databaseHelper.database;

      // Delete user's data first (cascade delete would be better)
      await db.delete('tasks', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('notes', where: 'user_id = ?', whereArgs: [userId]);
      await db
          .delete('calendar_events', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('files', where: 'user_id = ?', whereArgs: [userId]);

      // Delete user
      final count =
          await db.delete('users', where: 'id = ?', whereArgs: [userId]);

      if (count > 0) {
        AppUtils.logInfo('Deleted user: $userId');
        return true;
      }
      return false;
    } catch (e) {
      AppUtils.logError('Failed to delete user', error: e);
      return false;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query('users', orderBy: 'created_at DESC');

      return maps.map((map) => User.fromMap(map)).toList();
    } catch (e) {
      AppUtils.logError('Failed to get all users', error: e);
      return [];
    }
  }

  Future<bool> updateLastLogin(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedUser = user.copyWith(
        lastLoginAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await updateUser(updatedUser);
    } catch (e) {
      AppUtils.logError('Failed to update last login', error: e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final db = await _databaseHelper.database;

      // Get task stats
      final taskResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_tasks,
          COUNT(CASE WHEN is_completed = 1 THEN 1 END) as completed_tasks,
          COUNT(CASE WHEN due_date < ? AND is_completed = 0 THEN 1 END) as overdue_tasks
        FROM tasks 
        WHERE user_id = ?
      ''', [DateTime.now().millisecondsSinceEpoch, userId]);

      // Get note stats
      final noteResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_notes,
          COUNT(CASE WHEN is_pinned = 1 THEN 1 END) as pinned_notes
        FROM notes 
        WHERE user_id = ?
      ''', [userId]);

      // Get file stats
      final fileResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_files,
          SUM(file_size) as total_size
        FROM files 
        WHERE user_id = ?
      ''', [userId]);

      return {
        'tasks': taskResult.isNotEmpty ? taskResult.first : {},
        'notes': noteResult.isNotEmpty ? noteResult.first : {},
        'files': fileResult.isNotEmpty ? fileResult.first : {},
      };
    } catch (e) {
      AppUtils.logError('Failed to get user stats', error: e);
      return {};
    }
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String timezone;
  final String language;
  final bool isActive;
  final bool emailVerified;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.timezone = 'UTC',
    this.language = 'en',
    this.isActive = true,
    this.emailVerified = false,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? phone,
    String? timezone,
    String? language,
    bool? isActive,
    bool? emailVerified,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      timezone: timezone ?? this.timezone,
      language: language ?? this.language,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'phone': phone,
      'timezone': timezone,
      'language': language,
      'is_active': isActive ? 1 : 0,
      'email_verified': emailVerified ? 1 : 0,
      'last_login_at': lastLoginAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      avatarUrl: map['avatar_url'],
      phone: map['phone'],
      timezone: map['timezone'] ?? 'UTC',
      language: map['language'] ?? 'en',
      isActive: (map['is_active'] ?? 1) == 1,
      emailVerified: (map['email_verified'] ?? 0) == 1,
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_login_at'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }
}
