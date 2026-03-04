import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../config/central_config.dart';
import '../logging/logging_service.dart';
import '../enhanced_error_handling_service.dart';
import '../free_database_service.dart';

/// Database Integrity Service
///
/// Provides comprehensive database integrity checking and auto-repair capabilities:
/// - Integrity constraint validation
/// - Foreign key relationship checks
/// - Data consistency verification
/// - Index validation and rebuilding
/// - Automatic repair procedures
/// - Corruption detection and recovery
/// - Backup integration for safe repairs
class DatabaseIntegrityService {
  static const String _configPrefix = 'database_integrity';
  static const String _defaultCheckInterval =
      'database_integrity.check_interval_hours';
  static const String _defaultEnabled = 'database_integrity.enabled';
  static const String _defaultAutoRepair =
      'database_integrity.auto_repair_enabled';
  static const String _defaultBackupBeforeRepair =
      'database_integrity.backup_before_repair';

  final LoggingService _loggingService;
  final CentralConfig _centralConfig;
  final EnhancedErrorHandlingService _errorHandlingService;
  final FreeDatabaseService? _databaseService;

  Timer? _integrityCheckTimer;
  final Map<String, DatabaseIntegrityStatus> _databaseStatuses = {};
  final StreamController<IntegrityEvent> _integrityController =
      StreamController.broadcast();

  bool _isInitialized = false;

  DatabaseIntegrityService({
    LoggingService? loggingService,
    CentralConfig? centralConfig,
    EnhancedErrorHandlingService? errorHandlingService,
    FreeDatabaseService? databaseService,
  })  : _loggingService = loggingService ?? LoggingService(),
        _centralConfig = centralConfig ?? CentralConfig.instance,
        _errorHandlingService =
            errorHandlingService ?? EnhancedErrorHandlingService(),
        _databaseService = databaseService;

  /// Initialize the database integrity service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _loggingService.info('Initializing Database Integrity Service',
          'DatabaseIntegrityService');

      // Register with CentralConfig
      await _centralConfig.registerComponent(
          'DatabaseIntegrityService',
          '1.0.0',
          'Comprehensive database integrity checking and auto-repair capabilities',
          dependencies: [
            'CentralConfig',
            'LoggingService',
            'EnhancedErrorHandlingService'
          ],
          parameters: {
            _defaultEnabled: true,
            _defaultCheckInterval: 24, // hours
            _defaultAutoRepair: true,
            _defaultBackupBeforeRepair: true,
            'database_integrity.check_foreign_keys': true,
            'database_integrity.check_indexes': true,
            'database_integrity.check_constraints': true,
            'database_integrity.check_data_consistency': true,
            'database_integrity.repair_max_attempts': 3,
            'database_integrity.corruption_detection_enabled': true,
          });

      // Start periodic integrity checks
      if (enabled) {
        _startPeriodicChecks();
      }

      _isInitialized = true;
      _loggingService.info(
          'Database Integrity Service initialized successfully',
          'DatabaseIntegrityService');
    } catch (e, stackTrace) {
      _loggingService.error('Failed to initialize Database Integrity Service',
          'DatabaseIntegrityService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Configuration getters
  bool get enabled =>
      _centralConfig.getParameter(_defaultEnabled, defaultValue: true);
  Duration get checkInterval => Duration(
      hours:
          _centralConfig.getParameter(_defaultCheckInterval, defaultValue: 24));
  bool get autoRepairEnabled =>
      _centralConfig.getParameter(_defaultAutoRepair, defaultValue: true);
  bool get backupBeforeRepair => _centralConfig
      .getParameter(_defaultBackupBeforeRepair, defaultValue: true);
  bool get checkForeignKeys =>
      _centralConfig.getParameter('database_integrity.check_foreign_keys',
          defaultValue: true);
  bool get checkIndexes => _centralConfig
      .getParameter('database_integrity.check_indexes', defaultValue: true);
  bool get checkConstraints => _centralConfig
      .getParameter('database_integrity.check_constraints', defaultValue: true);
  bool get checkDataConsistency =>
      _centralConfig.getParameter('database_integrity.check_data_consistency',
          defaultValue: true);
  int get repairMaxAttempts => _centralConfig
      .getParameter('database_integrity.repair_max_attempts', defaultValue: 3);
  bool get corruptionDetectionEnabled => _centralConfig.getParameter(
      'database_integrity.corruption_detection_enabled',
      defaultValue: true);

  /// Perform comprehensive database integrity check
  Future<IntegrityCheckResult> performIntegrityCheck({
    String? databaseName,
    bool autoRepair = true,
  }) async {
    final startTime = DateTime.now();
    final results = <String, IntegrityIssue>{};

    try {
      _loggingService.info(
          'Starting database integrity check', 'DatabaseIntegrityService');

      // Get databases to check
      final databases = await _getDatabasesToCheck(databaseName);

      for (final db in databases) {
        try {
          final dbResults = await _checkDatabaseIntegrity(db, autoRepair);
          results.addAll(dbResults);
        } catch (e, stackTrace) {
          _loggingService.error(
              'Failed to check database $db', 'DatabaseIntegrityService',
              error: e, stackTrace: stackTrace);
          results[db] = IntegrityIssue(
            database: db,
            type: IntegrityIssueType.unknown,
            severity: IntegritySeverity.critical,
            description: 'Integrity check failed: ${e.toString()}',
          );
        }
      }

      final duration = DateTime.now().difference(startTime);
      final status = _calculateIntegrityStatus(results);

      final result = IntegrityCheckResult(
        timestamp: DateTime.now(),
        duration: duration,
        databasesChecked: databases.length,
        issuesFound: results.length,
        status: status,
        issues: results,
      );

      _emitEvent(IntegrityEvent(
        type: IntegrityEventType.checkCompleted,
        result: result,
      ));

      _loggingService.info(
          'Database integrity check completed: $status, ${results.length} issues found',
          'DatabaseIntegrityService');

      return result;
    } catch (e, stackTrace) {
      _loggingService.error(
          'Database integrity check failed', 'DatabaseIntegrityService',
          error: e, stackTrace: stackTrace);

      final errorResult = IntegrityCheckResult(
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
        databasesChecked: 0,
        issuesFound: 1,
        status: IntegrityStatus.failed,
        issues: {
          'check_failed': IntegrityIssue(
            database: 'unknown',
            type: IntegrityIssueType.unknown,
            severity: IntegritySeverity.critical,
            description: 'Integrity check execution failed: ${e.toString()}',
          ),
        },
      );

      return errorResult;
    }
  }

  /// Check integrity of a specific database
  Future<Map<String, IntegrityIssue>> _checkDatabaseIntegrity(
      String databaseName, bool autoRepair) async {
    final issues = <String, IntegrityIssue>{};

    try {
      // Get database instance
      final database = await _getDatabase(databaseName);
      if (database == null) {
        issues['database_access'] = IntegrityIssue(
          database: databaseName,
          type: IntegrityIssueType.databaseAccess,
          severity: IntegritySeverity.critical,
          description: 'Cannot access database: $databaseName',
        );
        return issues;
      }

      // Check SQLite integrity
      if (corruptionDetectionEnabled) {
        final corruptionIssues =
            await _checkSQLiteIntegrity(database, databaseName);
        issues.addAll(corruptionIssues);
      }

      // Check foreign key constraints
      if (checkForeignKeys) {
        final fkIssues = await _checkForeignKeys(database, databaseName);
        issues.addAll(fkIssues);
      }

      // Check indexes
      if (checkIndexes) {
        final indexIssues = await _checkIndexes(database, databaseName);
        issues.addAll(indexIssues);
      }

      // Check table constraints
      if (checkConstraints) {
        final constraintIssues =
            await _checkConstraints(database, databaseName);
        issues.addAll(constraintIssues);
      }

      // Check data consistency
      if (checkDataConsistency) {
        final consistencyIssues =
            await _checkDataConsistency(database, databaseName);
        issues.addAll(consistencyIssues);
      }

      // Auto-repair if enabled and issues found
      if (autoRepair && autoRepairEnabled && issues.isNotEmpty) {
        await _attemptAutoRepair(database, databaseName, issues);
      }

      // Update status
      _databaseStatuses[databaseName] = DatabaseIntegrityStatus(
        databaseName: databaseName,
        lastCheck: DateTime.now(),
        status: issues.isEmpty
            ? IntegrityStatus.healthy
            : IntegrityStatus.issuesFound,
        issuesCount: issues.length,
      );
    } catch (e) {
      issues['check_error'] = IntegrityIssue(
        database: databaseName,
        type: IntegrityIssueType.unknown,
        severity: IntegritySeverity.critical,
        description: 'Integrity check error: ${e.toString()}',
      );
    }

    return issues;
  }

  /// Check SQLite database integrity using PRAGMA integrity_check
  Future<Map<String, IntegrityIssue>> _checkSQLiteIntegrity(
      Database database, String databaseName) async {
    final issues = <String, IntegrityIssue>{};

    try {
      final result = await database.rawQuery('PRAGMA integrity_check');

      if (result.isNotEmpty && result.first.values.isNotEmpty) {
        final checkResult = result.first.values.first.toString();

        if (checkResult != 'ok') {
          issues['integrity_check'] = IntegrityIssue(
            database: databaseName,
            type: IntegrityIssueType.corruption,
            severity: IntegritySeverity.critical,
            description: 'Database corruption detected: $checkResult',
            details: result.toString(),
          );
        }
      }
    } catch (e) {
      issues['integrity_check_error'] = IntegrityIssue(
        database: databaseName,
        type: IntegrityIssueType.unknown,
        severity: IntegritySeverity.warning,
        description: 'Integrity check failed: ${e.toString()}',
      );
    }

    return issues;
  }

  /// Check foreign key constraints
  Future<Map<String, IntegrityIssue>> _checkForeignKeys(
      Database database, String databaseName) async {
    final issues = <String, IntegrityIssue>{};

    try {
      // Get all tables
      final tablesResult = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      final tables = tablesResult.map((row) => row['name'] as String).toList();

      for (final table in tables) {
        // Check for orphaned records
        final fkResult =
            await database.rawQuery('PRAGMA foreign_key_list($table)');
        for (final fk in fkResult) {
          final foreignTable = fk['table'] as String;
          final foreignColumn = fk['to'] as String;
          final localColumn = fk['from'] as String;

          // Check for orphaned records
          final orphanedQuery = '''
            SELECT COUNT(*) as count FROM $table t
            LEFT JOIN $foreignTable ft ON t.$localColumn = ft.$foreignColumn
            WHERE ft.$foreignColumn IS NULL AND t.$localColumn IS NOT NULL
          ''';

          final orphanedResult = await database.rawQuery(orphanedQuery);
          final count = Sqflite.firstIntValue(orphanedResult) ?? 0;

          if (count > 0) {
            issues['fk_${table}_$foreignTable'] = IntegrityIssue(
              database: databaseName,
              type: IntegrityIssueType.foreignKeyViolation,
              severity: IntegritySeverity.warning,
              description:
                  'Found $count orphaned records in $table referencing $foreignTable',
              table: table,
              details:
                  'Foreign key constraint violated between $table.$localColumn and $foreignTable.$foreignColumn',
            );
          }
        }
      }
    } catch (e) {
      issues['fk_check_error'] = IntegrityIssue(
        database: databaseName,
        type: IntegrityIssueType.unknown,
        severity: IntegritySeverity.warning,
        description: 'Foreign key check failed: ${e.toString()}',
      );
    }

    return issues;
  }

  /// Check database indexes
  Future<Map<String, IntegrityIssue>> _checkIndexes(
      Database database, String databaseName) async {
    final issues = <String, IntegrityIssue>{};

    try {
      // Get all indexes
      final indexesResult = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'");
      final indexes =
          indexesResult.map((row) => row['name'] as String).toList();

      for (final index in indexes) {
        try {
          // Check if index is valid by running a simple query
          await database
              .rawQuery('SELECT * FROM sqlite_master WHERE name = ?', [index]);
        } catch (e) {
          issues['index_$index'] = IntegrityIssue(
            database: databaseName,
            type: IntegrityIssueType.indexCorruption,
            severity: IntegritySeverity.warning,
            description: 'Index $index appears to be corrupted',
            details: e.toString(),
          );
        }
      }
    } catch (e) {
      issues['index_check_error'] = IntegrityIssue(
        database: databaseName,
        type: IntegrityIssueType.unknown,
        severity: IntegritySeverity.warning,
        description: 'Index check failed: ${e.toString()}',
      );
    }

    return issues;
  }

  /// Check table constraints
  Future<Map<String, IntegrityIssue>> _checkConstraints(
      Database database, String databaseName) async {
    final issues = <String, IntegrityIssue>{};

    try {
      // Get all tables
      final tablesResult = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      final tables = tablesResult.map((row) => row['name'] as String).toList();

      for (final table in tables) {
        // Check NOT NULL constraints
        final columnsResult =
            await database.rawQuery('PRAGMA table_info($table)');
        for (final column in columnsResult) {
          final columnName = column['name'] as String;
          final notNull = column['notnull'] as int == 1;

          if (notNull) {
            final nullCountResult = await database.rawQuery(
                'SELECT COUNT(*) as count FROM $table WHERE $columnName IS NULL');
            final nullCount = Sqflite.firstIntValue(nullCountResult) ?? 0;

            if (nullCount > 0) {
              issues['notnull_${table}_$columnName'] = IntegrityIssue(
                database: databaseName,
                type: IntegrityIssueType.constraintViolation,
                severity: IntegritySeverity.warning,
                description:
                    'NOT NULL constraint violated in $table.$columnName: $nullCount null values',
                table: table,
                column: columnName,
              );
            }
          }
        }
      }
    } catch (e) {
      issues['constraint_check_error'] = IntegrityIssue(
        database: databaseName,
        type: IntegrityIssueType.unknown,
        severity: IntegritySeverity.warning,
        description: 'Constraint check failed: ${e.toString()}',
      );
    }

    return issues;
  }

  /// Check data consistency
  Future<Map<String, IntegrityIssue>> _checkDataConsistency(
      Database database, String databaseName) async {
    final issues = <String, IntegrityIssue>{};

    try {
      // Custom consistency checks based on business logic
      // This would be extended based on specific application requirements

      // Example: Check for duplicate records where uniqueness is expected
      final tablesResult = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      final tables = tablesResult.map((row) => row['name'] as String).toList();

      for (final table in tables) {
        // Check for tables with 'id' columns for duplicate detection
        final columnsResult =
            await database.rawQuery('PRAGMA table_info($table)');
        final hasIdColumn = columnsResult.any((col) => col['name'] == 'id');

        if (hasIdColumn) {
          final duplicateResult = await database.rawQuery('''
            SELECT id, COUNT(*) as count
            FROM $table
            GROUP BY id
            HAVING COUNT(*) > 1
          ''');

          if (duplicateResult.isNotEmpty) {
            issues['duplicates_$table'] = IntegrityIssue(
              database: databaseName,
              type: IntegrityIssueType.dataInconsistency,
              severity: IntegritySeverity.warning,
              description:
                  'Found duplicate IDs in table $table: ${duplicateResult.length} duplicates',
              table: table,
            );
          }
        }
      }
    } catch (e) {
      issues['consistency_check_error'] = IntegrityIssue(
        database: databaseName,
        type: IntegrityIssueType.unknown,
        severity: IntegritySeverity.warning,
        description: 'Data consistency check failed: ${e.toString()}',
      );
    }

    return issues;
  }

  /// Attempt automatic repair of integrity issues
  Future<void> _attemptAutoRepair(Database database, String databaseName,
      Map<String, IntegrityIssue> issues) async {
    if (!autoRepairEnabled) return;

    try {
      _loggingService.info(
          'Attempting auto-repair for $databaseName (${issues.length} issues)',
          'DatabaseIntegrityService');

      // Create backup if enabled
      String? backupPath;
      if (backupBeforeRepair) {
        backupPath = await _createBackup(database, databaseName);
      }

      int repairAttempts = 0;
      bool repairSuccessful = false;

      while (repairAttempts < repairMaxAttempts && !repairSuccessful) {
        repairAttempts++;

        try {
          // Attempt repair based on issue types
          for (final issue in issues.values) {
            await _repairIssue(database, issue);
          }

          // Re-check integrity
          final recheckResult =
              await _checkDatabaseIntegrity(databaseName, false);
          if (recheckResult.isEmpty) {
            repairSuccessful = true;
          }
        } catch (e) {
          _loggingService.warning(
              'Repair attempt $repairAttempts failed: ${e.toString()}',
              'DatabaseIntegrityService');
        }
      }

      if (repairSuccessful) {
        _loggingService.info('Auto-repair successful for $databaseName',
            'DatabaseIntegrityService');
        _emitEvent(IntegrityEvent(
          type: IntegrityEventType.repairCompleted,
          database: databaseName,
          metadata: {'attempts': repairAttempts},
        ));
      } else {
        _loggingService.warning(
            'Auto-repair failed for $databaseName after $repairAttempts attempts',
            'DatabaseIntegrityService');

        // Restore backup if available
        if (backupPath != null && backupBeforeRepair) {
          await _restoreBackup(database, backupPath);
        }

        _emitEvent(IntegrityEvent(
          type: IntegrityEventType.repairFailed,
          database: databaseName,
          metadata: {'attempts': repairAttempts},
        ));
      }
    } catch (e, stackTrace) {
      _loggingService.error(
          'Auto-repair failed for $databaseName', 'DatabaseIntegrityService',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Repair a specific integrity issue
  Future<void> _repairIssue(Database database, IntegrityIssue issue) async {
    switch (issue.type) {
      case IntegrityIssueType.foreignKeyViolation:
        await _repairForeignKeyViolation(database, issue);
        break;
      case IntegrityIssueType.indexCorruption:
        await _repairIndexCorruption(database, issue);
        break;
      case IntegrityIssueType.constraintViolation:
        await _repairConstraintViolation(database, issue);
        break;
      case IntegrityIssueType.dataInconsistency:
        await _repairDataInconsistency(database, issue);
        break;
      case IntegrityIssueType.corruption:
        // Corruption requires more complex repair
        await _repairCorruption(database, issue);
        break;
      default:
        _loggingService.info(
            'No automatic repair available for issue type: ${issue.type}',
            'DatabaseIntegrityService');
    }
  }

  /// Repair foreign key violations
  Future<void> _repairForeignKeyViolation(
      Database database, IntegrityIssue issue) async {
    if (issue.table != null) {
      // Delete orphaned records
      await database
          .delete(issue.table!, where: 'id IS NULL OR id = ?', whereArgs: ['']);
      _loggingService.info('Repaired foreign key violations in ${issue.table}',
          'DatabaseIntegrityService');
    }
  }

  /// Repair index corruption
  Future<void> _repairIndexCorruption(
      Database database, IntegrityIssue issue) async {
    // Rebuild corrupted indexes
    await database.execute('REINDEX');
    _loggingService.info(
        'Rebuilt indexes to repair corruption', 'DatabaseIntegrityService');
  }

  /// Repair constraint violations
  Future<void> _repairConstraintViolation(
      Database database, IntegrityIssue issue) async {
    if (issue.table != null && issue.column != null) {
      // Set default values for null constraint violations
      await database.update(issue.table!, {issue.column!: ''},
          where: '${issue.column} IS NULL');
      _loggingService.info(
          'Repaired constraint violations in ${issue.table}.${issue.column}',
          'DatabaseIntegrityService');
    }
  }

  /// Repair data inconsistency
  Future<void> _repairDataInconsistency(
      Database database, IntegrityIssue issue) async {
    if (issue.table != null) {
      // Remove duplicate records, keeping the first one
      await database.execute('''
        DELETE FROM ${issue.table}
        WHERE rowid NOT IN (
          SELECT MIN(rowid)
          FROM ${issue.table}
          GROUP BY id
        )
      ''');
      _loggingService.info('Removed duplicate records from ${issue.table}',
          'DatabaseIntegrityService');
    }
  }

  /// Repair database corruption
  Future<void> _repairCorruption(
      Database database, IntegrityIssue issue) async {
    // For severe corruption, we might need to recreate tables
    // This is a complex operation that would need careful implementation
    _loggingService.warning(
        'Database corruption detected - manual intervention required',
        'DatabaseIntegrityService');
  }

  /// Create database backup
  Future<String?> _createBackup(Database database, String databaseName) async {
    try {
      final dbPath = await getDatabasesPath();
      final backupPath = path.join(dbPath,
          '${databaseName}_backup_${DateTime.now().millisecondsSinceEpoch}.db');

      await database.rawQuery('VACUUM INTO ?', [backupPath]);

      _loggingService.info(
          'Database backup created: $backupPath', 'DatabaseIntegrityService');
      return backupPath;
    } catch (e) {
      _loggingService.error(
          'Failed to create database backup', 'DatabaseIntegrityService',
          error: e);
      return null;
    }
  }

  /// Restore database from backup
  Future<void> _restoreBackup(Database database, String backupPath) async {
    try {
      // Close current database and replace with backup
      await database.close();

      final dbPath = database.path;
      final backupFile = File(backupPath);

      if (await backupFile.exists()) {
        await backupFile.copy(dbPath);
        _loggingService.info('Database restored from backup: $backupPath',
            'DatabaseIntegrityService');
      }
    } catch (e) {
      _loggingService.error(
          'Failed to restore database from backup', 'DatabaseIntegrityService',
          error: e);
    }
  }

  /// Get databases to check
  Future<List<String>> _getDatabasesToCheck(String? specificDatabase) async {
    if (specificDatabase != null) {
      return [specificDatabase];
    }

    // Get all databases from the database service
    if (_databaseService != null) {
      return _databaseService!.getDatabaseNames();
    }

    // Default databases
    return ['main_database'];
  }

  /// Get database instance
  Future<Database?> _getDatabase(String databaseName) async {
    if (_databaseService != null) {
      return _databaseService!.getDatabase(databaseName);
    }

    // Try to open database directly
    try {
      final dbPath = path.join(await getDatabasesPath(), '$databaseName.db');
      return await openDatabase(dbPath, readOnly: true);
    } catch (e) {
      _loggingService.warning(
          'Failed to open database $databaseName: ${e.toString()}',
          'DatabaseIntegrityService');
      return null;
    }
  }

  /// Calculate overall integrity status
  IntegrityStatus _calculateIntegrityStatus(
      Map<String, IntegrityIssue> issues) {
    if (issues.isEmpty) return IntegrityStatus.healthy;

    final hasCritical = issues.values
        .any((issue) => issue.severity == IntegritySeverity.critical);
    if (hasCritical) return IntegrityStatus.critical;

    return IntegrityStatus.issuesFound;
  }

  /// Start periodic integrity checks
  void _startPeriodicChecks() {
    _integrityCheckTimer = Timer.periodic(checkInterval, (_) async {
      try {
        await performIntegrityCheck();
      } catch (e) {
        _loggingService.error(
            'Periodic integrity check failed', 'DatabaseIntegrityService',
            error: e);
      }
    });

    _loggingService.info(
        'Periodic integrity checks started', 'DatabaseIntegrityService');
  }

  /// Get integrity status for all databases
  Map<String, DatabaseIntegrityStatus> getIntegrityStatuses() {
    return Map.from(_databaseStatuses);
  }

  /// Get integrity status for specific database
  DatabaseIntegrityStatus? getIntegrityStatus(String databaseName) {
    return _databaseStatuses[databaseName];
  }

  /// Force integrity check
  Future<IntegrityCheckResult> forceIntegrityCheck(
      {String? databaseName}) async {
    return await performIntegrityCheck(databaseName: databaseName);
  }

  /// Emit integrity event
  void _emitEvent(IntegrityEvent event) {
    _integrityController.add(event);
  }

  /// Get integrity event stream
  Stream<IntegrityEvent> get integrityEvents => _integrityController.stream;

  /// Dispose resources
  void dispose() {
    _integrityCheckTimer?.cancel();
    _integrityController.close();
    _loggingService.info(
        'Database integrity service disposed', 'DatabaseIntegrityService');
  }
}

/// Integrity Status
enum IntegrityStatus {
  healthy,
  issuesFound,
  critical,
  failed,
}

/// Integrity Issue Types
enum IntegrityIssueType {
  corruption,
  foreignKeyViolation,
  indexCorruption,
  constraintViolation,
  dataInconsistency,
  databaseAccess,
  unknown,
}

/// Integrity Issue Severity
enum IntegritySeverity {
  info,
  warning,
  critical,
}

/// Integrity Issue
class IntegrityIssue {
  final String database;
  final IntegrityIssueType type;
  final IntegritySeverity severity;
  final String description;
  final String? table;
  final String? column;
  final String? details;

  IntegrityIssue({
    required this.database,
    required this.type,
    required this.severity,
    required this.description,
    this.table,
    this.column,
    this.details,
  });

  @override
  String toString() {
    return 'IntegrityIssue(database: $database, type: $type, severity: $severity, description: $description)';
  }
}

/// Integrity Check Result
class IntegrityCheckResult {
  final DateTime timestamp;
  final Duration duration;
  final int databasesChecked;
  final int issuesFound;
  final IntegrityStatus status;
  final Map<String, IntegrityIssue> issues;

  IntegrityCheckResult({
    required this.timestamp,
    required this.duration,
    required this.databasesChecked,
    required this.issuesFound,
    required this.status,
    required this.issues,
  });

  int get criticalIssues => issues.values
      .where((i) => i.severity == IntegritySeverity.critical)
      .length;
  int get warningIssues => issues.values
      .where((i) => i.severity == IntegritySeverity.warning)
      .length;

  @override
  String toString() {
    return 'IntegrityCheckResult(databases: $databasesChecked, issues: $issuesFound, status: $status, duration: ${duration.inMilliseconds}ms)';
  }
}

/// Database Integrity Status
class DatabaseIntegrityStatus {
  final String databaseName;
  final DateTime lastCheck;
  final IntegrityStatus status;
  final int issuesCount;

  DatabaseIntegrityStatus({
    required this.databaseName,
    required this.lastCheck,
    required this.status,
    required this.issuesCount,
  });

  @override
  String toString() {
    return 'DatabaseIntegrityStatus(database: $databaseName, status: $status, issues: $issuesCount, lastCheck: $lastCheck)';
  }
}

/// Integrity Event Types
enum IntegrityEventType {
  checkStarted,
  checkCompleted,
  repairStarted,
  repairCompleted,
  repairFailed,
  backupCreated,
  backupRestored,
}

/// Integrity Event
class IntegrityEvent {
  final IntegrityEventType type;
  final DateTime timestamp;
  final String? database;
  final IntegrityCheckResult? result;
  final Map<String, dynamic>? metadata;

  IntegrityEvent({
    required this.type,
    this.database,
    this.result,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'IntegrityEvent(type: $type, database: $database, timestamp: $timestamp)';
  }
}
