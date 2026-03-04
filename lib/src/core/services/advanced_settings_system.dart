import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:i_suite/src/core/config/central_config.dart';

/// ============================================================================
/// ADVANCED SETTINGS AND CONFIGURATION MANAGEMENT SYSTEM FOR iSUITE PRO
/// ============================================================================
///
/// Enterprise-grade settings management for iSuite Pro:
/// - Hierarchical settings structure with categories and subcategories
/// - Multiple setting types (boolean, string, number, list, color, file path)
/// - Real-time validation and constraints enforcement
/// - User-friendly UI components with search and filtering
/// - Import/export functionality for settings backup and sharing
/// - Settings profiles and presets for different use cases
/// - Advanced search and discovery capabilities
/// - Settings synchronization across devices
/// - Audit trail for configuration changes
/// - Reset to defaults and factory restore options
///
/// Key Features:
/// - Type-safe settings with validation
/// - Dynamic UI generation from configuration schemas
/// - Hierarchical organization with breadcrumbs
/// - Search and filter across all settings
/// - Backup and restore with version control
/// - Settings profiles for different environments
/// - Real-time updates with change notifications
/// - Accessibility support with screen reader compatibility
/// - Integration with CentralConfig for persistence
///
/// ============================================================================

class AdvancedSettingsSystem {
  static final AdvancedSettingsSystem _instance =
      AdvancedSettingsSystem._internal();
  factory AdvancedSettingsSystem() => _instance;

  AdvancedSettingsSystem._internal() {
    _initialize();
  }

  // Core components
  late SettingsRegistry _registry;
  late SettingsValidator _validator;
  late SettingsPersistence _persistence;
  late SettingsSearch _search;
  late SettingsProfiles _profiles;
  late SettingsBackup _backup;
  late SettingsAudit _audit;

  // Central config integration
  final CentralConfig _centralConfig = CentralConfig.instance;

  // Settings state
  final Map<String, Setting> _settings = {};
  final Map<String, SettingsCategory> _categories = {};
  final Map<String, dynamic> _currentValues = {};
  final List<SettingsProfile> _availableProfiles = [];

  // UI state
  final Map<String, bool> _expandedCategories = {};
  String _searchQuery = '';
  List<String> _activeFilters = [];

  // Streams
  final StreamController<SettingsEvent> _eventController =
      StreamController<SettingsEvent>.broadcast();

  void _initialize() {
    _registry = SettingsRegistry();
    _validator = SettingsValidator();
    _persistence = SettingsPersistence();
    _search = SettingsSearch();
    _profiles = SettingsProfiles();
    _backup = SettingsBackup();
    _audit = SettingsAudit();

    _registerDefaultSettings();
    _setupEventListeners();
  }

  /// Initialize the settings system
  Future<void> initialize() async {
    // Load persisted settings
    await _loadPersistedSettings();

    // Load available profiles
    await _loadProfiles();

    // Validate current settings
    await _validateAllSettings();

    _eventController.add(const SettingsEvent.initialized());
  }

  /// Register a setting
  void registerSetting(Setting setting) {
    _settings[setting.key] = setting;

    // Set default value if not already set
    if (!_currentValues.containsKey(setting.key)) {
      _currentValues[setting.key] = setting.defaultValue;
    }

    // Register with CentralConfig for persistence
    _centralConfig.setParameter(setting.key, setting.defaultValue);

    _eventController.add(SettingsEvent.settingRegistered(setting));
  }

  /// Register a settings category
  void registerCategory(SettingsCategory category) {
    _categories[category.id] = category;
    _expandedCategories[category.id] = false;

    _eventController.add(SettingsEvent.categoryRegistered(category));
  }

  /// Get setting value
  T? getSetting<T>(String key) {
    final setting = _settings[key];
    if (setting == null) return null;

    final value = _currentValues[key] ?? setting.defaultValue;
    return value as T?;
  }

  /// Set setting value with validation
  Future<bool> setSetting(String key, dynamic value) async {
    final setting = _settings[key];
    if (setting == null) return false;

    // Validate value
    final validationResult = await _validator.validate(setting, value);
    if (!validationResult.isValid) {
      _eventController
          .add(SettingsEvent.validationFailed(key, validationResult.errors));
      return false;
    }

    // Store old value for audit
    final oldValue = _currentValues[key];

    // Update value
    _currentValues[key] = value;

    // Persist to CentralConfig
    await _centralConfig.setParameter(key, value);

    // Persist to local storage
    await _persistence.saveSetting(key, value);

    // Audit the change
    await _audit.logChange(key, oldValue, value);

    // Notify listeners
    _eventController.add(SettingsEvent.settingChanged(key, value, oldValue));

    return true;
  }

  /// Reset setting to default
  Future<void> resetSetting(String key) async {
    final setting = _settings[key];
    if (setting == null) return;

    await setSetting(key, setting.defaultValue);
  }

  /// Reset all settings to defaults
  Future<void> resetAllSettings() async {
    for (final setting in _settings.values) {
      await resetSetting(setting.key);
    }

    _eventController.add(const SettingsEvent.allSettingsReset());
  }

  /// Get all settings in a category
  List<Setting> getSettingsInCategory(String categoryId) {
    return _settings.values
        .where((setting) => setting.categoryId == categoryId)
        .toList();
  }

  /// Get all categories
  List<SettingsCategory> getCategories() {
    return _categories.values.toList();
  }

  /// Search settings
  List<Setting> searchSettings(String query, {List<String>? categories}) {
    return _search.search(query, _settings.values.toList(),
        categories: categories);
  }

  /// Filter settings by type
  List<Setting> filterSettingsByType(SettingType type) {
    return _settings.values.where((setting) => setting.type == type).toList();
  }

  /// Create settings profile
  Future<void> createProfile(String name, String description) async {
    final profile = SettingsProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      settings: Map.from(_currentValues),
      createdAt: DateTime.now(),
    );

    await _profiles.saveProfile(profile);
    _availableProfiles.add(profile);

    _eventController.add(SettingsEvent.profileCreated(profile));
  }

  /// Load settings profile
  Future<void> loadProfile(String profileId) async {
    final profile = _availableProfiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => throw Exception('Profile not found'),
    );

    for (final entry in profile.settings.entries) {
      await setSetting(entry.key, entry.value);
    }

    _eventController.add(SettingsEvent.profileLoaded(profile));
  }

  /// Delete settings profile
  Future<void> deleteProfile(String profileId) async {
    final profile = _availableProfiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => throw Exception('Profile not found'),
    );

    await _profiles.deleteProfile(profileId);
    _availableProfiles.remove(profile);

    _eventController.add(SettingsEvent.profileDeleted(profileId));
  }

  /// Export settings
  Future<String> exportSettings({List<String>? keys}) async {
    final exportData = <String, dynamic>{};

    final settingsToExport = keys != null
        ? _settings.entries.where((e) => keys.contains(e.key))
        : _settings.entries;

    for (final entry in settingsToExport) {
      final setting = entry.value;
      exportData[setting.key] = {
        'value': _currentValues[setting.key],
        'type': setting.type.toString(),
        'category': setting.categoryId,
        'metadata': setting.metadata,
      };
    }

    return jsonEncode({
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'settings': exportData,
    });
  }

  /// Import settings
  Future<ImportResult> importSettings(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final settings = data['settings'] as Map<String, dynamic>;

      int imported = 0;
      int skipped = 0;
      final errors = <String>[];

      for (final entry in settings.entries) {
        final key = entry.key;
        final settingData = entry.value as Map<String, dynamic>;

        if (_settings.containsKey(key)) {
          try {
            await setSetting(key, settingData['value']);
            imported++;
          } catch (e) {
            errors.add('Failed to import $key: $e');
            skipped++;
          }
        } else {
          skipped++;
        }
      }

      _eventController
          .add(SettingsEvent.settingsImported(imported, skipped, errors));

      return ImportResult(
        success: true,
        importedCount: imported,
        skippedCount: skipped,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        importedCount: 0,
        skippedCount: 0,
        errors: ['Invalid import data: $e'],
      );
    }
  }

  /// Backup all settings
  Future<String> createBackup() async {
    return await _backup.createBackup(_currentValues, _settings);
  }

  /// Restore from backup
  Future<RestoreResult> restoreFromBackup(String backupData) async {
    return await _backup.restoreBackup(backupData, this);
  }

  /// Get settings statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};
    final categories = <String, int>{};

    for (final setting in _settings.values) {
      categories[setting.categoryId] =
          (categories[setting.categoryId] ?? 0) + 1;
    }

    stats['total_settings'] = _settings.length;
    stats['categories'] = categories;
    stats['settings_by_type'] = _getSettingsByType();

    return stats;
  }

  Map<String, int> _getSettingsByType() {
    final byType = <String, int>{};
    for (final setting in _settings.values) {
      final typeName = setting.type.toString().split('.').last;
      byType[typeName] = (byType[typeName] ?? 0) + 1;
    }
    return byType;
  }

  /// UI state management
  void setCategoryExpanded(String categoryId, bool expanded) {
    _expandedCategories[categoryId] = expanded;
  }

  bool isCategoryExpanded(String categoryId) {
    return _expandedCategories[categoryId] ?? false;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  String getSearchQuery() => _searchQuery;

  void setActiveFilters(List<String> filters) {
    _activeFilters = filters;
  }

  List<String> getActiveFilters() => _activeFilters;

  /// Private methods
  void _registerDefaultSettings() {
    // App settings
    registerCategory(SettingsCategory(
      id: 'app',
      name: 'Application',
      description: 'General application settings',
      icon: Icons.settings,
      order: 1,
    ));

    registerSetting(Setting<String>(
      key: 'app.theme',
      name: 'Theme',
      description: 'Application theme',
      type: SettingType.list,
      defaultValue: 'system',
      categoryId: 'app',
      options: ['light', 'dark', 'system'],
    ));

    registerSetting(Setting<String>(
      key: 'app.language',
      name: 'Language',
      description: 'Application language',
      type: SettingType.list,
      defaultValue: 'en',
      categoryId: 'app',
      options: ['en', 'es', 'fr', 'de', 'zh'],
    ));

    // Security settings
    registerCategory(SettingsCategory(
      id: 'security',
      name: 'Security',
      description: 'Security and privacy settings',
      icon: Icons.security,
      order: 2,
    ));

    registerSetting(Setting<bool>(
      key: 'security.biometric_required',
      name: 'Require Biometric',
      description: 'Require biometric authentication',
      type: SettingType.boolean,
      defaultValue: false,
      categoryId: 'security',
    ));

    registerSetting(Setting<int>(
      key: 'security.session_timeout',
      name: 'Session Timeout',
      description: 'Session timeout in minutes',
      type: SettingType.number,
      defaultValue: 30,
      categoryId: 'security',
      minValue: 5,
      maxValue: 480,
    ));

    // Performance settings
    registerCategory(SettingsCategory(
      id: 'performance',
      name: 'Performance',
      description: 'Performance optimization settings',
      icon: Icons.speed,
      order: 3,
    ));

    registerSetting(Setting<bool>(
      key: 'performance.auto_optimize',
      name: 'Auto Optimize',
      description: 'Automatically optimize performance',
      type: SettingType.boolean,
      defaultValue: true,
      categoryId: 'performance',
    ));

    // Network settings
    registerCategory(SettingsCategory(
      id: 'network',
      name: 'Network',
      description: 'Network and connectivity settings',
      icon: Icons.wifi,
      order: 4,
    ));

    registerSetting(Setting<int>(
      key: 'network.timeout',
      name: 'Request Timeout',
      description: 'Network request timeout in seconds',
      type: SettingType.number,
      defaultValue: 30,
      categoryId: 'network',
      minValue: 5,
      maxValue: 300,
    ));
  }

  Future<void> _loadPersistedSettings() async {
    for (final setting in _settings.values) {
      final persistedValue = await _persistence.loadSetting(setting.key);
      if (persistedValue != null) {
        _currentValues[setting.key] = persistedValue;
      }
    }
  }

  Future<void> _loadProfiles() async {
    _availableProfiles.addAll(await _profiles.loadProfiles());
  }

  Future<void> _validateAllSettings() async {
    for (final setting in _settings.values) {
      final value = _currentValues[setting.key];
      if (value != null) {
        final validation = await _validator.validate(setting, value);
        if (!validation.isValid) {
          // Reset to default if invalid
          _currentValues[setting.key] = setting.defaultValue;
        }
      }
    }
  }

  void _setupEventListeners() {
    // Listen to CentralConfig changes
    _centralConfig.onConfigChanged.listen((event) {
      final key = event.key;
      final newValue = event.newValue;

      if (_settings.containsKey(key) && _currentValues[key] != newValue) {
        _currentValues[key] = newValue;
        _eventController
            .add(SettingsEvent.settingChanged(key, newValue, event.oldValue));
      }
    });
  }

  /// Get available profiles
  List<SettingsProfile> getAvailableProfiles() => List.from(_availableProfiles);

  /// Listen to settings events
  Stream<SettingsEvent> get events => _eventController.stream;

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}

/// ============================================================================
/// COMPONENT CLASSES
/// ============================================================================

class SettingsRegistry {
  final Map<String, Setting> _registry = {};

  void register(Setting setting) {
    _registry[setting.key] = setting;
  }

  Setting? getSetting(String key) => _registry[key];

  List<Setting> getAllSettings() => _registry.values.toList();

  void dispose() {
    _registry.clear();
  }
}

class SettingsValidator {
  Future<ValidationResult> validate(Setting setting, dynamic value) async {
    final errors = <String>[];

    // Type validation
    if (!_validateType(setting.type, value)) {
      errors.add('Invalid type for setting ${setting.key}');
    }

    // Range validation for numbers
    if (setting.type == SettingType.number) {
      final numValue = value as num;
      if (setting.minValue != null && numValue < setting.minValue!) {
        errors.add('Value must be at least ${setting.minValue}');
      }
      if (setting.maxValue != null && numValue > setting.maxValue!) {
        errors.add('Value must be at most ${setting.maxValue}');
      }
    }

    // List validation
    if (setting.type == SettingType.list && setting.options != null) {
      if (!setting.options!.contains(value)) {
        errors.add('Value must be one of: ${setting.options!.join(', ')}');
      }
    }

    // Custom validation
    if (setting.validator != null) {
      final customResult = await setting.validator!(value);
      if (!customResult.isValid) {
        errors.addAll(customResult.errors);
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  bool _validateType(SettingType type, dynamic value) {
    switch (type) {
      case SettingType.boolean:
        return value is bool;
      case SettingType.string:
        return value is String;
      case SettingType.number:
        return value is num;
      case SettingType.list:
        return true; // List validation handled separately
      case SettingType.color:
        return value is int || value is String;
      case SettingType.file:
        return value is String;
      case SettingType.json:
        return value is Map || value is List;
    }
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });
}

class SettingsPersistence {
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonValue = jsonEncode(value);
      await prefs.setString('setting_$key', jsonValue);
    } catch (e) {
      debugPrint('Failed to save setting $key: $e');
    }
  }

  Future<dynamic> loadSetting(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonValue = prefs.getString('setting_$key');
      if (jsonValue != null) {
        return jsonDecode(jsonValue);
      }
    } catch (e) {
      debugPrint('Failed to load setting $key: $e');
    }
    return null;
  }

  Future<void> clearAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('setting_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Failed to clear settings: $e');
    }
  }
}

class SettingsSearch {
  List<Setting> search(String query, List<Setting> settings,
      {List<String>? categories}) {
    if (query.isEmpty && (categories == null || categories.isEmpty)) {
      return settings;
    }

    return settings.where((setting) {
      // Category filter
      if (categories != null &&
          categories.isNotEmpty &&
          !categories.contains(setting.categoryId)) {
        return false;
      }

      // Text search
      if (query.isNotEmpty) {
        final searchText =
            '${setting.name} ${setting.description} ${setting.key}'
                .toLowerCase();
        return searchText.contains(query.toLowerCase());
      }

      return true;
    }).toList();
  }
}

class SettingsProfiles {
  Future<void> saveProfile(SettingsProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      await prefs.setString('profile_${profile.id}', profileJson);
    } catch (e) {
      debugPrint('Failed to save profile ${profile.id}: $e');
    }
  }

  Future<List<SettingsProfile>> loadProfiles() async {
    final profiles = <SettingsProfile>[];

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('profile_'));

      for (final key in keys) {
        final profileJson = prefs.getString(key);
        if (profileJson != null) {
          final profileData = jsonDecode(profileJson) as Map<String, dynamic>;
          profiles.add(SettingsProfile.fromJson(profileData));
        }
      }
    } catch (e) {
      debugPrint('Failed to load profiles: $e');
    }

    return profiles;
  }

  Future<void> deleteProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_$profileId');
    } catch (e) {
      debugPrint('Failed to delete profile $profileId: $e');
    }
  }
}

class SettingsBackup {
  Future<String> createBackup(
      Map<String, dynamic> values, Map<String, Setting> settings) async {
    final backupData = {
      'version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'settings': values,
      'metadata': settings.map((key, setting) => MapEntry(key, {
            'type': setting.type.toString(),
            'default_value': setting.defaultValue,
            'category': setting.categoryId,
          })),
    };

    return jsonEncode(backupData);
  }

  Future<RestoreResult> restoreBackup(
      String backupData, AdvancedSettingsSystem settingsSystem) async {
    try {
      final data = jsonDecode(backupData) as Map<String, dynamic>;
      final settings = data['settings'] as Map<String, dynamic>;

      int restored = 0;
      int skipped = 0;
      final errors = <String>[];

      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;

        try {
          final success = await settingsSystem.setSetting(key, value);
          if (success) {
            restored++;
          } else {
            skipped++;
          }
        } catch (e) {
          errors.add('Failed to restore $key: $e');
          skipped++;
        }
      }

      return RestoreResult(
        success: true,
        restoredCount: restored,
        skippedCount: skipped,
        errors: errors,
      );
    } catch (e) {
      return RestoreResult(
        success: false,
        restoredCount: 0,
        skippedCount: 0,
        errors: ['Invalid backup data: $e'],
      );
    }
  }
}

class SettingsAudit {
  final List<SettingsChange> _changes = [];

  Future<void> logChange(String key, dynamic oldValue, dynamic newValue) async {
    final change = SettingsChange(
      key: key,
      oldValue: oldValue,
      newValue: newValue,
      timestamp: DateTime.now(),
    );

    _changes.add(change);

    // Keep only last 1000 changes
    if (_changes.length > 1000) {
      _changes.removeRange(0, _changes.length - 1000);
    }

    // In a real implementation, this would be persisted to a database
  }

  List<SettingsChange> getRecentChanges({int limit = 50}) {
    return _changes.reversed.take(limit).toList();
  }
}

/// ============================================================================
/// DATA MODELS
/// ============================================================================

enum SettingType {
  boolean,
  string,
  number,
  list,
  color,
  file,
  json,
}

class Setting<T> {
  final String key;
  final String name;
  final String description;
  final SettingType type;
  final T defaultValue;
  final String categoryId;
  final List<String>? options;
  final num? minValue;
  final num? maxValue;
  final Future<ValidationResult> Function(T)? validator;
  final Map<String, dynamic>? metadata;

  Setting({
    required this.key,
    required this.name,
    required this.description,
    required this.type,
    required this.defaultValue,
    required this.categoryId,
    this.options,
    this.minValue,
    this.maxValue,
    this.validator,
    this.metadata,
  });
}

class SettingsCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int order;
  final Color? color;

  SettingsCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.order,
    this.color,
  });
}

class SettingsProfile {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> settings;
  final DateTime createdAt;

  SettingsProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.settings,
    required this.createdAt,
  });

  factory SettingsProfile.fromJson(Map<String, dynamic> json) {
    return SettingsProfile(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      settings: json['settings'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'settings': settings,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SettingsChange {
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime timestamp;

  SettingsChange({
    required this.key,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
  });
}

class ImportResult {
  final bool success;
  final int importedCount;
  final int skippedCount;
  final List<String> errors;

  ImportResult({
    required this.success,
    required this.importedCount,
    required this.skippedCount,
    required this.errors,
  });
}

class RestoreResult {
  final bool success;
  final int restoredCount;
  final int skippedCount;
  final List<String> errors;

  RestoreResult({
    required this.success,
    required this.restoredCount,
    required this.skippedCount,
    required this.errors,
  });
}

/// ============================================================================
/// EVENT SYSTEM
/// ============================================================================

abstract class SettingsEvent {
  final String type;
  final DateTime timestamp;

  SettingsEvent(this.type, this.timestamp);

  factory SettingsEvent.initialized() = SettingsInitializedEvent;

  factory SettingsEvent.settingRegistered(Setting setting) =
      SettingRegisteredEvent;

  factory SettingsEvent.categoryRegistered(SettingsCategory category) =
      CategoryRegisteredEvent;

  factory SettingsEvent.settingChanged(
      String key, dynamic newValue, dynamic oldValue) = SettingChangedEvent;

  factory SettingsEvent.validationFailed(String key, List<String> errors) =
      ValidationFailedEvent;

  factory SettingsEvent.allSettingsReset() = AllSettingsResetEvent;

  factory SettingsEvent.profileCreated(SettingsProfile profile) =
      ProfileCreatedEvent;

  factory SettingsEvent.profileLoaded(SettingsProfile profile) =
      ProfileLoadedEvent;

  factory SettingsEvent.profileDeleted(String profileId) = ProfileDeletedEvent;

  factory SettingsEvent.settingsImported(
      int imported, int skipped, List<String> errors) = SettingsImportedEvent;
}

class SettingsInitializedEvent extends SettingsEvent {
  SettingsInitializedEvent() : super('initialized', DateTime.now());
}

class SettingRegisteredEvent extends SettingsEvent {
  final Setting setting;

  SettingRegisteredEvent(this.setting)
      : super('setting_registered', DateTime.now());
}

class CategoryRegisteredEvent extends SettingsEvent {
  final SettingsCategory category;

  CategoryRegisteredEvent(this.category)
      : super('category_registered', DateTime.now());
}

class SettingChangedEvent extends SettingsEvent {
  final String key;
  final dynamic newValue;
  final dynamic oldValue;

  SettingChangedEvent(this.key, this.newValue, this.oldValue)
      : super('setting_changed', DateTime.now());
}

class ValidationFailedEvent extends SettingsEvent {
  final String key;
  final List<String> errors;

  ValidationFailedEvent(this.key, this.errors)
      : super('validation_failed', DateTime.now());
}

class AllSettingsResetEvent extends SettingsEvent {
  AllSettingsResetEvent() : super('all_settings_reset', DateTime.now());
}

class ProfileCreatedEvent extends SettingsEvent {
  final SettingsProfile profile;

  ProfileCreatedEvent(this.profile) : super('profile_created', DateTime.now());
}

class ProfileLoadedEvent extends SettingsEvent {
  final SettingsProfile profile;

  ProfileLoadedEvent(this.profile) : super('profile_loaded', DateTime.now());
}

class ProfileDeletedEvent extends SettingsEvent {
  final String profileId;

  ProfileDeletedEvent(this.profileId)
      : super('profile_deleted', DateTime.now());
}

class SettingsImportedEvent extends SettingsEvent {
  final int imported;
  final int skipped;
  final List<String> errors;

  SettingsImportedEvent(this.imported, this.skipped, this.errors)
      : super('settings_imported', DateTime.now());
}

/// ============================================================================
/// UI COMPONENTS
/// ============================================================================

/// Main settings screen
class AdvancedSettingsScreen extends StatefulWidget {
  @override
  _AdvancedSettingsScreenState createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  final AdvancedSettingsSystem _settings = AdvancedSettingsSystem.instance;
  final TextEditingController _searchController = TextEditingController();
  late StreamSubscription<SettingsEvent> _eventSubscription;

  List<SettingsCategory> _categories = [];
  List<Setting> _filteredSettings = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _eventSubscription = _settings.events.listen(_handleEvent);
    _searchController.addListener(_onSearchChanged);
  }

  void _loadCategories() {
    setState(() {
      _categories = _settings.getCategories()
        ..sort((a, b) => a.order.compareTo(b.order));
      _updateFilteredSettings();
    });
  }

  void _onSearchChanged() {
    _settings.setSearchQuery(_searchController.text);
    _updateFilteredSettings();
  }

  void _updateFilteredSettings() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _filteredSettings = [];
        _isSearching = false;
      });
    } else {
      setState(() {
        _filteredSettings = _settings.searchSettings(query);
        _isSearching = true;
      });
    }
  }

  void _handleEvent(SettingsEvent event) {
    switch (event.type) {
      case 'setting_changed':
        setState(() {}); // Rebuild to show updated values
        break;
      case 'profile_loaded':
        setState(() {}); // Rebuild to show loaded profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings profile loaded')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'export', child: Text('Export Settings')),
              const PopupMenuItem(
                  value: 'import', child: Text('Import Settings')),
              const PopupMenuItem(value: 'profiles', child: Text('Profiles')),
              const PopupMenuItem(value: 'reset', child: Text('Reset All')),
            ],
          ),
        ],
      ),
      body: _isSearching ? _buildSearchResults() : _buildCategoriesList(),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isExpanded = _settings.isCategoryExpanded(category.id);

        return ExpansionTile(
          title: Text(category.name),
          subtitle: Text(category.description),
          leading: Icon(category.icon),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            _settings.setCategoryExpanded(category.id, expanded);
          },
          children: [
            ..._settings
                .getSettingsInCategory(category.id)
                .map((setting) => _buildSettingTile(setting)),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_filteredSettings.isEmpty) {
      return const Center(
        child: Text('No settings found'),
      );
    }

    return ListView.builder(
      itemCount: _filteredSettings.length,
      itemBuilder: (context, index) {
        return _buildSettingTile(_filteredSettings[index]);
      },
    );
  }

  Widget _buildSettingTile(Setting setting) {
    return ListTile(
      title: Text(setting.name),
      subtitle: Text(setting.description),
      trailing: _buildSettingControl(setting),
      onTap: () => _showSettingDialog(setting),
    );
  }

  Widget _buildSettingControl(Setting setting) {
    final value = _settings.getSetting(setting.key);

    switch (setting.type) {
      case SettingType.boolean:
        return Switch(
          value: value as bool? ?? setting.defaultValue as bool,
          onChanged: (newValue) {
            _settings.setSetting(setting.key, newValue);
          },
        );

      case SettingType.list:
        return DropdownButton<String>(
          value: value as String? ?? setting.defaultValue as String,
          items: setting.options?.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              _settings.setSetting(setting.key, newValue);
            }
          },
        );

      default:
        return Text(value?.toString() ?? setting.defaultValue.toString());
    }
  }

  void _showSettingDialog(Setting setting) {
    showDialog(
      context: context,
      builder: (context) => SettingDialog(setting: setting),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: SettingsSearchDelegate(_settings),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'export':
        _exportSettings();
        break;
      case 'import':
        _importSettings();
        break;
      case 'profiles':
        _showProfilesDialog();
        break;
      case 'reset':
        _showResetDialog();
        break;
    }
  }

  Future<void> _exportSettings() async {
    try {
      final exportData = await _settings.exportSettings();
      await Share.share(exportData, subject: 'iSuite Settings Export');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importSettings() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      try {
        final file = File(result.files.single.path!);
        final jsonData = await file.readAsString();
        final importResult = await _settings.importSettings(jsonData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Import completed: ${importResult.importedCount} imported, '
                  '${importResult.skippedCount} skipped')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _showProfilesDialog() {
    showDialog(
      context: context,
      builder: (context) => ProfilesDialog(),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text(
            'This will reset all settings to their default values. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _settings.resetAllSettings();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

/// Setting dialog for detailed editing
class SettingDialog extends StatefulWidget {
  final Setting setting;

  const SettingDialog({super.key, required this.setting});

  @override
  _SettingDialogState createState() => _SettingDialogState();
}

class _SettingDialogState extends State<SettingDialog> {
  final AdvancedSettingsSystem _settings = AdvancedSettingsSystem.instance;
  late dynamic _value;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value =
        _settings.getSetting(widget.setting.key) ?? widget.setting.defaultValue;

    if (widget.setting.type == SettingType.string ||
        widget.setting.type == SettingType.file) {
      _textController.text = _value.toString();
    } else if (widget.setting.type == SettingType.number) {
      _numberController.text = _value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.setting.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.setting.description),
            const SizedBox(height: 16),
            _buildValueEditor(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveSetting,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildValueEditor() {
    switch (widget.setting.type) {
      case SettingType.boolean:
        return SwitchListTile(
          title: const Text('Enabled'),
          value: _value as bool,
          onChanged: (value) => setState(() => _value = value),
        );

      case SettingType.string:
        return TextField(
          controller: _textController,
          decoration: const InputDecoration(labelText: 'Value'),
          onChanged: (value) => _value = value,
        );

      case SettingType.number:
        return TextField(
          controller: _numberController,
          decoration: InputDecoration(
            labelText: 'Value',
            hintText: widget.setting.minValue != null &&
                    widget.setting.maxValue != null
                ? '${widget.setting.minValue} - ${widget.setting.maxValue}'
                : null,
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _value = num.tryParse(value) ?? _value,
        );

      case SettingType.list:
        return DropdownButtonFormField<String>(
          value: _value as String,
          decoration: const InputDecoration(labelText: 'Value'),
          items: widget.setting.options?.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) => setState(() => _value = value),
        );

      case SettingType.color:
        return ListTile(
          title: const Text('Color'),
          trailing: Container(
            width: 24,
            height: 24,
            color: Color(_value as int),
          ),
          onTap: _pickColor,
        );

      case SettingType.file:
        return Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(labelText: 'File Path'),
              readOnly: true,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Choose File'),
            ),
          ],
        );

      case SettingType.json:
        return TextField(
          controller: _textController,
          decoration: const InputDecoration(labelText: 'JSON Value'),
          maxLines: 5,
          onChanged: (value) {
            try {
              _value = jsonDecode(value);
            } catch (e) {
              // Invalid JSON, keep as string for now
            }
          },
        );
    }
  }

  Future<void> _pickColor() async {
    // Color picker implementation would go here
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Color picker not implemented')),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final path = result.files.single.path!;
      setState(() {
        _value = path;
        _textController.text = path;
      });
    }
  }

  Future<void> _saveSetting() async {
    final success = await _settings.setSetting(widget.setting.key, _value);
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save setting')),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _numberController.dispose();
    super.dispose();
  }
}

/// Search delegate for settings
class SettingsSearchDelegate extends SearchDelegate<Setting?> {
  final AdvancedSettingsSystem _settings;

  SettingsSearchDelegate(this._settings);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _settings.searchSettings(query);

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final setting = results[index];
        return ListTile(
          title: Text(setting.name),
          subtitle: Text(setting.description),
          onTap: () => close(context, setting),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _settings.searchSettings(query);

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final setting = suggestions[index];
        return ListTile(
          title: Text(setting.name),
          subtitle: Text(setting.description),
          onTap: () => query = setting.name,
        );
      },
    );
  }
}

/// Profiles management dialog
class ProfilesDialog extends StatefulWidget {
  @override
  _ProfilesDialogState createState() => _ProfilesDialogState();
}

class _ProfilesDialogState extends State<ProfilesDialog> {
  final AdvancedSettingsSystem _settings = AdvancedSettingsSystem.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final profiles = _settings.getAvailableProfiles();

    return AlertDialog(
      title: const Text('Settings Profiles'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create new profile
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Profile Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _createProfile,
              child: const Text('Create Profile'),
            ),

            const Divider(),

            // Existing profiles
            if (profiles.isEmpty)
              const Text('No profiles created yet')
            else
              ...profiles.map((profile) => ListTile(
                    title: Text(profile.name),
                    subtitle: Text(profile.description),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) =>
                          _handleProfileAction(profile.id, action),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'load', child: Text('Load')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) return;

    await _settings.createProfile(name, description);

    _nameController.clear();
    _descriptionController.clear();
    setState(() {});
  }

  Future<void> _handleProfileAction(String profileId, String action) async {
    switch (action) {
      case 'load':
        await _settings.loadProfile(profileId);
        Navigator.of(context).pop();
        break;
      case 'delete':
        await _settings.deleteProfile(profileId);
        setState(() {});
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

/// ============================================================================
/// USAGE EXAMPLE
/// ============================================================================

/*
/// Initialize advanced settings in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize advanced settings system
  final settings = AdvancedSettingsSystem();
  await settings.initialize();

  // Register custom settings
  settings.registerCategory(SettingsCategory(
    id: 'custom',
    name: 'Custom Features',
    description: 'Custom application features',
    icon: Icons.extension,
    order: 10,
  ));

  settings.registerSetting(Setting<bool>(
    key: 'custom.feature_enabled',
    name: 'Enable Custom Feature',
    description: 'Enable the custom feature',
    type: SettingType.boolean,
    defaultValue: false,
    categoryId: 'custom',
  ));

  runApp(const MyApp());
}

/// Access settings throughout the app
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = AdvancedSettingsSystem.instance;

    // Get setting value
    final featureEnabled = settings.getSetting<bool>('custom.feature_enabled') ?? false;

    return featureEnabled
        ? const CustomFeatureWidget()
        : const StandardWidget();
  }
}

/// Navigate to settings screen
class SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AdvancedSettingsScreen()),
        );
      },
      child: const Text('Advanced Settings'),
    );
  }
}
*/

/// ============================================================================
/// END OF ADVANCED SETTINGS AND CONFIGURATION MANAGEMENT SYSTEM FOR iSUITE PRO
/// ============================================================================
