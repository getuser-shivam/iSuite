import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';
import 'central_config.dart';

/// Configuration Hot-Reload Service
/// Provides dynamic configuration reloading without app restart
class ConfigurationHotReloadService {
  static final ConfigurationHotReloadService _instance = ConfigurationHotReloadService._internal();
  factory ConfigurationHotReloadService() => _instance;
  ConfigurationHotReloadService._internal();

  final CentralConfig _centralConfig = CentralConfig.instance;
  final StreamController<ConfigurationReloadEvent> _reloadEventController = StreamController.broadcast();

  Stream<ConfigurationReloadEvent> get reloadEvents => _reloadEventController.stream;

  // File watching
  final Map<String, FileWatcher> _fileWatchers = {};
  final Map<String, ConfigurationFile> _watchedFiles = {};

  // Reload management
  final Map<String, ConfigurationSnapshot> _configurationSnapshots = {};
  final Queue<ConfigurationChange> _pendingChanges = Queue();

  // Configuration validation
  final Map<String, ConfigurationValidator> _validators = {};

  bool _isInitialized = false;
  bool _hotReloadEnabled = true;
  Timer? _debounceTimer;

  // Configuration
  static const Duration _reloadDebounceTime = Duration(milliseconds: 500);
  static const int _maxConfigurationHistory = 10;
  static const String _configBackupDirectory = '.config_backups';

  /// Initialize hot-reload service
  Future<void> initialize({
    bool enableHotReload = true,
    List<String>? configFiles,
    Map<String, ConfigurationValidator>? validators,
  }) async {
    if (_isInitialized) return;

    try {
      _hotReloadEnabled = enableHotReload;

      // Initialize backup directory
      await _initializeBackupDirectory();

      // Load default validators
      _initializeDefaultValidators();

      // Add custom validators
      if (validators != null) {
        _validators.addAll(validators);
      }

      // Watch configuration files
      final filesToWatch = configFiles ?? await _discoverConfigurationFiles();
      for (final filePath in filesToWatch) {
        await _startWatchingFile(filePath);
      }

      // Create initial configuration snapshot
      await _createConfigurationSnapshot('initial');

      _isInitialized = true;
      _emitReloadEvent(ConfigurationReloadEventType.serviceInitialized);

    } catch (e) {
      _emitReloadEvent(ConfigurationReloadEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Enable or disable hot reload
  Future<void> setHotReloadEnabled(bool enabled) async {
    _hotReloadEnabled = enabled;

    if (enabled) {
      // Resume watching all files
      for (final filePath in _watchedFiles.keys) {
        await _startWatchingFile(filePath);
      }
      _emitReloadEvent(ConfigurationReloadEventType.hotReloadEnabled);
    } else {
      // Stop watching all files
      for (final watcher in _fileWatchers.values) {
        await watcher.events.drain();
      }
      _fileWatchers.clear();
      _emitReloadEvent(ConfigurationReloadEventType.hotReloadDisabled);
    }
  }

  /// Manually reload configuration
  Future<ConfigurationReloadResult> reloadConfiguration({
    bool validateBeforeReload = true,
    bool createBackup = true,
    String? reason,
  }) async {
    _emitReloadEvent(ConfigurationReloadEventType.manualReloadStarted, details: reason);

    try {
      // Create backup if requested
      String? backupId;
      if (createBackup) {
        backupId = await _createConfigurationSnapshot('manual_reload_${DateTime.now().millisecondsSinceEpoch}');
      }

      // Validate configuration if requested
      if (validateBeforeReload) {
        final validationResult = await _validateAllConfigurations();
        if (!validationResult.isValid) {
          _emitReloadEvent(ConfigurationReloadEventType.reloadValidationFailed,
            error: validationResult.errors.join('; '));
          return ConfigurationReloadResult(
            success: false,
            reloadedFiles: [],
            errors: validationResult.errors,
            warnings: validationResult.warnings,
          );
        }
      }

      // Reload all watched configuration files
      final reloadedFiles = <String>[];
      final errors = <String>[];
      final warnings = <String>[];

      for (final filePath in _watchedFiles.keys) {
        try {
          final reloadResult = await _reloadConfigurationFile(filePath);
          reloadedFiles.add(filePath);

          if (reloadResult.warnings.isNotEmpty) {
            warnings.addAll(reloadResult.warnings);
          }
        } catch (e) {
          errors.add('Failed to reload $filePath: $e');
        }
      }

      final success = errors.isEmpty;

      _emitReloadEvent(
        success ? ConfigurationReloadEventType.manualReloadCompleted : ConfigurationReloadEventType.manualReloadFailed,
        details: 'Reloaded ${reloadedFiles.length} files'
      );

      return ConfigurationReloadResult(
        success: success,
        reloadedFiles: reloadedFiles,
        backupId: backupId,
        errors: errors,
        warnings: warnings,
      );

    } catch (e) {
      _emitReloadEvent(ConfigurationReloadEventType.manualReloadFailed, error: e.toString());
      return ConfigurationReloadResult(
        success: false,
        reloadedFiles: [],
        errors: [e.toString()],
        warnings: [],
      );
    }
  }

  /// Rollback to previous configuration
  Future<ConfigurationReloadResult> rollbackConfiguration(String backupId) async {
    _emitReloadEvent(ConfigurationReloadEventType.rollbackStarted, details: backupId);

    try {
      final snapshot = _configurationSnapshots[backupId];
      if (snapshot == null) {
        throw ConfigurationException('Backup not found: $backupId');
      }

      // Restore configuration from snapshot
      final restoredFiles = <String>[];

      for (final entry in snapshot.fileContents.entries) {
        final filePath = entry.key;
        final content = entry.value;

        await File(filePath).writeAsString(content);
        restoredFiles.add(filePath);

        // Trigger reload for this file
        await _reloadConfigurationFile(filePath);
      }

      _emitReloadEvent(ConfigurationReloadEventType.rollbackCompleted,
        details: 'Restored ${restoredFiles.length} files from backup $backupId');

      return ConfigurationReloadResult(
        success: true,
        reloadedFiles: restoredFiles,
        backupId: backupId,
        errors: [],
        warnings: [],
      );

    } catch (e) {
      _emitReloadEvent(ConfigurationReloadEventType.rollbackFailed, error: e.toString());
      return ConfigurationReloadResult(
        success: false,
        reloadedFiles: [],
        errors: [e.toString()],
        warnings: [],
      );
    }
  }

  /// Get configuration reload status
  ConfigurationReloadStatus getReloadStatus() {
    return ConfigurationReloadStatus(
      isEnabled: _hotReloadEnabled,
      watchedFilesCount: _watchedFiles.length,
      pendingChangesCount: _pendingChanges.length,
      lastReloadTime: _getLastReloadTime(),
      backupCount: _configurationSnapshots.length,
    );
  }

  /// Add custom validator for configuration files
  void addValidator(String fileType, ConfigurationValidator validator) {
    _validators[fileType] = validator;
  }

  /// Remove validator
  void removeValidator(String fileType) {
    _validators.remove(fileType);
  }

  /// Get configuration change history
  List<ConfigurationChange> getConfigurationHistory({
    int limit = 50,
    DateTime? since,
  }) {
    var changes = _pendingChanges.toList().reversed.toList();

    if (since != null) {
      changes = changes.where((change) => change.timestamp.isAfter(since)).toList();
    }

    if (changes.length > limit) {
      changes = changes.take(limit).toList();
    }

    return changes;
  }

  /// Export configuration state
  Future<String> exportConfigurationState() async {
    final state = {
      'watchedFiles': _watchedFiles.map((key, value) => MapEntry(key, value.toJson())),
      'snapshots': _configurationSnapshots.map((key, value) => MapEntry(key, value.toJson())),
      'validators': _validators.keys.toList(),
      'hotReloadEnabled': _hotReloadEnabled,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return json.encode(state);
  }

  // Private methods

  Future<void> _initializeBackupDirectory() async {
    final dir = Directory(_configBackupDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  void _initializeDefaultValidators() {
    // JSON validator
    _validators['json'] = ConfigurationValidator(
      name: 'json',
      validate: _validateJsonConfiguration,
    );

    // YAML validator
    _validators['yaml'] = ConfigurationValidator(
      name: 'yaml',
      validate: _validateYamlConfiguration,
    );

    // Environment validator
    _validators['env'] = ConfigurationValidator(
      name: 'env',
      validate: _validateEnvironmentConfiguration,
    );
  }

  Future<List<String>> _discoverConfigurationFiles() async {
    final configFiles = <String>[];

    // Common configuration file patterns
    final patterns = [
      'config/*.json',
      'config/*.yaml',
      'config/*.yml',
      '*.config.json',
      '.env',
      'pubspec.yaml',
      'analysis_options.yaml',
    ];

    for (final pattern in patterns) {
      try {
        final files = await _findFilesMatchingPattern(pattern);
        configFiles.addAll(files);
      } catch (e) {
        // Skip patterns that don't match
      }
    }

    return configFiles;
  }

  Future<List<String>> _findFilesMatchingPattern(String pattern) async {
    final files = <String>[];

    // Simple pattern matching - in production, use a proper glob library
    if (pattern.contains('*')) {
      final dirPattern = pattern.split('/').first;
      final filePattern = pattern.split('/').last;

      if (dirPattern == '*' || dirPattern == 'config') {
        final dir = Directory(dirPattern == '*' ? '.' : dirPattern);
        if (await dir.exists()) {
          await for (final file in dir.list()) {
            if (file is File && _matchesFilePattern(file.path, filePattern)) {
              files.add(file.path);
            }
          }
        }
      }
    } else {
      final file = File(pattern);
      if (await file.exists()) {
        files.add(pattern);
      }
    }

    return files;
  }

  bool _matchesFilePattern(String filePath, String pattern) {
    final fileName = path.basename(filePath);
    final regexPattern = pattern.replaceAll('.', '\\.').replaceAll('*', '.*');
    final regex = RegExp('^$regexPattern\$');
    return regex.hasMatch(fileName);
  }

  Future<void> _startWatchingFile(String filePath) async {
    if (!_hotReloadEnabled) return;

    final file = File(filePath);
    if (!await file.exists()) return;

    final watcher = FileWatcher(filePath);
    _fileWatchers[filePath] = watcher;

    // Initialize file info
    final stat = await file.stat();
    _watchedFiles[filePath] = ConfigurationFile(
      path: filePath,
      lastModified: stat.modified,
      size: stat.size,
      type: _determineFileType(filePath),
    );

    // Listen for changes
    watcher.events.listen((event) {
      _handleFileChange(filePath, event);
    });
  }

  void _handleFileChange(String filePath, WatchEvent event) {
    // Debounce multiple rapid changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_reloadDebounceTime, () async {
      await _processFileChange(filePath, event);
    });
  }

  Future<void> _processFileChange(String filePath, WatchEvent event) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      final stat = await file.stat();
      final watchedFile = _watchedFiles[filePath];

      // Check if file actually changed
      if (watchedFile != null &&
          watchedFile.lastModified == stat.modified &&
          watchedFile.size == stat.size) {
        return; // No actual change
      }

      // Update file info
      _watchedFiles[filePath] = ConfigurationFile(
        path: filePath,
        lastModified: stat.modified,
        size: stat.size,
        type: watchedFile?.type ?? _determineFileType(filePath),
      );

      // Create change record
      final change = ConfigurationChange(
        filePath: filePath,
        changeType: _mapWatchEventType(event.type),
        timestamp: DateTime.now(),
        fileSize: stat.size,
      );

      _pendingChanges.add(change);

      // Maintain change history limit
      while (_pendingChanges.length > 1000) {
        _pendingChanges.removeFirst();
      }

      _emitReloadEvent(ConfigurationReloadEventType.fileChanged,
        details: '${event.type}: $filePath');

      // Auto-reload if enabled
      if (_hotReloadEnabled) {
        await _reloadConfigurationFile(filePath);
      }

    } catch (e) {
      _emitReloadEvent(ConfigurationReloadEventType.fileChangeError,
        details: filePath, error: e.toString());
    }
  }

  ConfigurationChangeType _mapWatchEventType(ChangeType type) {
    switch (type) {
      case ChangeType.ADD:
        return ConfigurationChangeType.created;
      case ChangeType.MODIFY:
        return ConfigurationChangeType.modified;
      case ChangeType.REMOVE:
        return ConfigurationChangeType.deleted;
      default:
        return ConfigurationChangeType.modified;
    }
  }

  Future<FileReloadResult> _reloadConfigurationFile(String filePath) async {
    _emitReloadEvent(ConfigurationReloadEventType.fileReloadStarted, details: filePath);

    try {
      final file = File(filePath);
      final content = await file.readAsString();

      // Validate content
      final validationResult = await _validateConfigurationFile(filePath, content);
      if (!validationResult.isValid) {
        throw ConfigurationException('Validation failed: ${validationResult.errors.join(", ")}');
      }

      // Reload configuration based on file type
      final reloadResult = await _applyConfigurationReload(filePath, content);

      _emitReloadEvent(ConfigurationReloadEventType.fileReloadCompleted, details: filePath);

      return FileReloadResult(
        success: true,
        filePath: filePath,
        warnings: validationResult.warnings,
      );

    } catch (e) {
      _emitReloadEvent(ConfigurationReloadEventType.fileReloadFailed,
        details: filePath, error: e.toString());

      return FileReloadResult(
        success: false,
        filePath: filePath,
        errors: [e.toString()],
        warnings: [],
      );
    }
  }

  Future<ConfigurationValidationResult> _validateConfigurationFile(String filePath, String content) async {
    final fileType = _determineFileType(filePath);
    final validator = _validators[fileType];

    if (validator != null) {
      return await validator.validate(content);
    }

    // Default validation - just check if it's valid JSON
    try {
      json.decode(content);
      return ConfigurationValidationResult.valid();
    } catch (e) {
      return ConfigurationValidationResult.invalid(['Invalid JSON format: $e']);
    }
  }

  Future<void> _applyConfigurationReload(String filePath, String content) async {
    final fileType = _determineFileType(filePath);

    switch (fileType) {
      case 'json':
        await _reloadJsonConfiguration(filePath, content);
        break;
      case 'yaml':
      case 'yml':
        await _reloadYamlConfiguration(filePath, content);
        break;
      case 'env':
        await _reloadEnvironmentConfiguration(filePath, content);
        break;
      default:
        // Generic reload through CentralConfig
        await _centralConfig.reloadConfiguration();
        break;
    }
  }

  Future<void> _reloadJsonConfiguration(String filePath, String content) async {
    try {
      final config = json.decode(content) as Map<String, dynamic>;

      // Reload through CentralConfig
      for (final entry in config.entries) {
        await _centralConfig.setParameter(entry.key, entry.value, source: 'hot_reload');
      }

      await _centralConfig.notifyConfigurationChanged();
    } catch (e) {
      throw ConfigurationException('Failed to reload JSON configuration: $e');
    }
  }

  Future<void> _reloadYamlConfiguration(String filePath, String content) async {
    // YAML parsing would require yaml package
    // For now, treat as generic reload
    await _centralConfig.reloadConfiguration();
  }

  Future<void> _reloadEnvironmentConfiguration(String filePath, String content) async {
    // Environment variables typically require app restart
    // Could implement partial reload for supported variables
    _emitReloadEvent(ConfigurationReloadEventType.environmentReloadNeeded,
      details: 'Environment variables require app restart');
  }

  Future<ConfigurationValidationResult> _validateJsonConfiguration(String content) async {
    try {
      json.decode(content);
      return ConfigurationValidationResult.valid();
    } catch (e) {
      return ConfigurationValidationResult.invalid(['Invalid JSON: $e']);
    }
  }

  Future<ConfigurationValidationResult> _validateYamlConfiguration(String content) async {
    // YAML validation would require yaml package
    return ConfigurationValidationResult.valid();
  }

  Future<ConfigurationValidationResult> _validateEnvironmentConfiguration(String content) async {
    final errors = <String>[];
    final warnings = <String>[];

    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      if (!trimmed.contains('=')) {
        errors.add('Invalid environment variable format: $trimmed');
      }
    }

    return ConfigurationValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<ConfigurationValidationResult> _validateAllConfigurations() async {
    final allErrors = <String>[];
    final allWarnings = <String>[];

    for (final filePath in _watchedFiles.keys) {
      try {
        final file = File(filePath);
        final content = await file.readAsString();

        final validation = await _validateConfigurationFile(filePath, content);
        allErrors.addAll(validation.errors);
        allWarnings.addAll(validation.warnings);
      } catch (e) {
        allErrors.add('Failed to validate $filePath: $e');
      }
    }

    return ConfigurationValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
    );
  }

  String _determineFileType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.json':
        return 'json';
      case '.yaml':
      case '.yml':
        return 'yaml';
      case '.env':
        return 'env';
      default:
        return 'unknown';
    }
  }

  Future<String> _createConfigurationSnapshot(String name) async {
    final snapshotId = '${name}_${DateTime.now().millisecondsSinceEpoch}';
    final fileContents = <String, String>{};

    for (final filePath in _watchedFiles.keys) {
      try {
        final content = await File(filePath).readAsString();
        fileContents[filePath] = content;
      } catch (e) {
        // Skip files that can't be read
      }
    }

    final snapshot = ConfigurationSnapshot(
      id: snapshotId,
      name: name,
      timestamp: DateTime.now(),
      fileContents: fileContents,
    );

    _configurationSnapshots[snapshotId] = snapshot;

    // Maintain snapshot limit
    if (_configurationSnapshots.length > _maxConfigurationHistory) {
      final oldestKey = _configurationSnapshots.keys.first;
      _configurationSnapshots.remove(oldestKey);
    }

    // Save to backup file
    final backupFile = File(path.join(_configBackupDirectory, '$snapshotId.json'));
    await backupFile.writeAsString(json.encode(snapshot.toJson()));

    return snapshotId;
  }

  DateTime? _getLastReloadTime() {
    if (_pendingChanges.isEmpty) return null;

    return _pendingChanges.map((change) => change.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  void _emitReloadEvent(ConfigurationReloadEventType type, {
    String? details,
    String? error,
  }) {
    final event = ConfigurationReloadEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _reloadEventController.add(event);
  }

  void dispose() {
    _debounceTimer?.cancel();
    for (final watcher in _fileWatchers.values) {
      watcher.events.drain();
    }
    _fileWatchers.clear();
    _reloadEventController.close();
  }
}

/// Supporting data classes

class ConfigurationFile {
  final String path;
  final DateTime lastModified;
  final int size;
  final String type;

  ConfigurationFile({
    required this.path,
    required this.lastModified,
    required this.size,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'lastModified': lastModified.toIso8601String(),
    'size': size,
    'type': type,
  };

  factory ConfigurationFile.fromJson(Map<String, dynamic> json) {
    return ConfigurationFile(
      path: json['path'],
      lastModified: DateTime.parse(json['lastModified']),
      size: json['size'],
      type: json['type'],
    );
  }
}

class ConfigurationSnapshot {
  final String id;
  final String name;
  final DateTime timestamp;
  final Map<String, String> fileContents;

  ConfigurationSnapshot({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.fileContents,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'timestamp': timestamp.toIso8601String(),
    'fileContents': fileContents,
  };

  factory ConfigurationSnapshot.fromJson(Map<String, dynamic> json) {
    return ConfigurationSnapshot(
      id: json['id'],
      name: json['name'],
      timestamp: DateTime.parse(json['timestamp']),
      fileContents: Map<String, String>.from(json['fileContents']),
    );
  }
}

class ConfigurationChange {
  final String filePath;
  final ConfigurationChangeType changeType;
  final DateTime timestamp;
  final int? fileSize;

  ConfigurationChange({
    required this.filePath,
    required this.changeType,
    required this.timestamp,
    this.fileSize,
  });

  @override
  String toString() {
    return '$changeType: $filePath at ${timestamp.toIso8601String()}';
  }
}

enum ConfigurationChangeType {
  created,
  modified,
  deleted,
}

class ConfigurationValidator {
  final String name;
  final Future<ConfigurationValidationResult> Function(String content) validate;

  ConfigurationValidator({
    required this.name,
    required this.validate,
  });
}

class ConfigurationValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ConfigurationValidationResult({
    required this.isValid,
    required this.errors,
    this.warnings = const [],
  });

  factory ConfigurationValidationResult.valid() {
    return ConfigurationValidationResult(isValid: true, errors: [], warnings: []);
  }

  factory ConfigurationValidationResult.invalid(List<String> errors, {List<String> warnings = const []}) {
    return ConfigurationValidationResult(isValid: false, errors: errors, warnings: warnings);
  }
}

class FileReloadResult {
  final bool success;
  final String filePath;
  final List<String> errors;
  final List<String> warnings;

  FileReloadResult({
    required this.success,
    required this.filePath,
    this.errors = const [],
    this.warnings = const [],
  });
}

class ConfigurationReloadResult {
  final bool success;
  final List<String> reloadedFiles;
  final String? backupId;
  final List<String> errors;
  final List<String> warnings;

  ConfigurationReloadResult({
    required this.success,
    required this.reloadedFiles,
    this.backupId,
    this.errors = const [],
    this.warnings = const [],
  });
}

class ConfigurationReloadStatus {
  final bool isEnabled;
  final int watchedFilesCount;
  final int pendingChangesCount;
  final DateTime? lastReloadTime;
  final int backupCount;

  ConfigurationReloadStatus({
    required this.isEnabled,
    required this.watchedFilesCount,
    required this.pendingChangesCount,
    this.lastReloadTime,
    required this.backupCount,
  });

  @override
  String toString() {
    return '''
Configuration Reload Status:
Enabled: $isEnabled
Watched Files: $watchedFilesCount
Pending Changes: $pendingChangesCount
Last Reload: $lastReloadTime
Backups: $backupCount
''';
  }
}

/// Configuration reload event types
enum ConfigurationReloadEventType {
  serviceInitialized,
  initializationFailed,
  hotReloadEnabled,
  hotReloadDisabled,
  fileChanged,
  fileChangeError,
  fileReloadStarted,
  fileReloadCompleted,
  fileReloadFailed,
  environmentReloadNeeded,
  manualReloadStarted,
  manualReloadCompleted,
  manualReloadFailed,
  reloadValidationFailed,
  rollbackStarted,
  rollbackCompleted,
  rollbackFailed,
}

/// Configuration reload event
class ConfigurationReloadEvent {
  final ConfigurationReloadEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  ConfigurationReloadEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}

/// Configuration exception
class ConfigurationException implements Exception {
  final String message;

  ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}
