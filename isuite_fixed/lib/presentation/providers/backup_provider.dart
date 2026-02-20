import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../data/repositories/backup_repository.dart';
import '../../domain/models/backup.dart';

class BackupProvider extends ChangeNotifier {
  BackupProvider() {
    _loadBackupHistory();
  }
  List<BackupModel> _backupHistory = [];
  bool _isLoading = false;
  String? _error;
  String? _progressMessage;
  double _progress = 0;

  // Getters
  List<BackupModel> get backupHistory => _backupHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get progressMessage => _progressMessage;
  double get progress => _progress;

  Future<void> _loadBackupHistory() async {
    try {
      _backupHistory = await BackupRepository.getBackupHistory();
      notifyListeners();
    } catch (e) {
      AppUtils.logError('Failed to load backup history', error: e);
    }
  }

  Future<String?> createBackup({
    required BackupType type,
    String name = '',
    String? description,
    bool encrypt = false,
    String? password,
  }) async {
    _isLoading = true;
    _error = null;
    _progressMessage = 'Preparing backup...';
    _progress = 0.0;
    notifyListeners();

    try {
      AppUtils.logInfo('Creating backup: ${type.name}', tag: 'BackupProvider');

      _progressMessage = 'Collecting data...';
      _progress = 0.2;
      notifyListeners();

      final backupData = await BackupRepository.createBackup(
        type: type,
        name: name,
        description: description,
        encrypt: encrypt,
        password: password,
      );

      _progressMessage = 'Finalizing backup...';
      _progress = 0.8;
      notifyListeners();

      // Calculate size and create backup model
      final size = encrypt ? backupData.length : backupData.length;
      final backup = BackupModel(
        id: AppUtils.generateRandomId(),
        name: name.isEmpty
            ? 'Backup ${DateTime.now().toString().split('.')[0]}'
            : name,
        description: description,
        type: type,
        status: BackupStatus.completed,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        size: size,
        isEncrypted: encrypt,
        password: password,
      );

      // Save backup metadata
      await BackupRepository.saveBackupMetadata(backup);
      _backupHistory.insert(0, backup);

      _progressMessage = 'Backup completed!';
      _progress = 1.0;
      notifyListeners();

      AppUtils.logInfo('Backup created successfully: ${backup.id}',
          tag: 'BackupProvider');

      // Reset progress after a delay
      Future.delayed(const Duration(seconds: 2), () {
        _progressMessage = null;
        _progress = 0.0;
        notifyListeners();
      });

      return backupData;
    } catch (e) {
      _error = 'Failed to create backup: ${e.toString()}';
      _progressMessage = 'Backup failed';
      AppUtils.logError('Failed to create backup',
          tag: 'BackupProvider', error: e);
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> restoreBackup({
    required String backupData,
    required BackupType type,
    String? password,
  }) async {
    _isLoading = true;
    _error = null;
    _progressMessage = 'Validating backup...';
    _progress = 0.0;
    notifyListeners();

    try {
      AppUtils.logInfo('Restoring backup: ${type.name}', tag: 'BackupProvider');

      // Validate backup
      final isValid = await BackupRepository.validateBackup(backupData);
      if (!isValid) {
        throw Exception('Invalid backup file');
      }

      _progressMessage = 'Preparing restore...';
      _progress = 0.2;
      notifyListeners();

      await BackupRepository.restoreBackup(
        backupData: backupData,
        type: type,
        password: password,
      );

      _progressMessage = 'Restore completed!';
      _progress = 1.0;
      notifyListeners();

      AppUtils.logInfo('Backup restored successfully', tag: 'BackupProvider');

      // Reset progress after a delay
      Future.delayed(const Duration(seconds: 2), () {
        _progressMessage = null;
        _progress = 0.0;
        notifyListeners();
      });

      return true;
    } catch (e) {
      _error = 'Failed to restore backup: ${e.toString()}';
      _progressMessage = 'Restore failed';
      AppUtils.logError('Failed to restore backup',
          tag: 'BackupProvider', error: e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<Map<String, int>> getBackupStats(String backupData) async {
    try {
      return await BackupRepository.getBackupStats(backupData);
    } catch (e) {
      AppUtils.logError('Failed to get backup stats', error: e);
      return {};
    }
  }

  Future<bool> validateBackup(String backupData) async {
    try {
      return await BackupRepository.validateBackup(backupData);
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetProgress() {
    _progressMessage = null;
    _progress = 0.0;
    notifyListeners();
  }

  // Helper methods
  List<BackupModel> get completedBackups =>
      _backupHistory.where((backup) => backup.isCompleted).toList();

  List<BackupModel> get failedBackups =>
      _backupHistory.where((backup) => backup.isFailed).toList();

  BackupModel? get latestBackup {
    final completed = completedBackups;
    return completed.isNotEmpty ? completed.first : null;
  }

  int get totalBackupSize =>
      _backupHistory.fold<int>(0, (sum, backup) => sum + backup.size);

  String get formattedTotalBackupSize {
    final totalBytes = totalBackupSize;
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024)
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024)
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Export functionality
  Future<String> exportBackupData(String backupData) async {
    // In a real app, this would save to file or share
    // For now, return the data as is
    return backupData;
  }

  // Cleanup methods
  Future<void> deleteBackup(String backupId) async {
    try {
      _backupHistory.removeWhere((backup) => backup.id == backupId);
      notifyListeners();
      AppUtils.logInfo('Backup deleted: $backupId', tag: 'BackupProvider');
    } catch (e) {
      AppUtils.logError('Failed to delete backup', error: e);
    }
  }

  Future<void> clearBackupHistory() async {
    try {
      _backupHistory.clear();
      notifyListeners();
      AppUtils.logInfo('Backup history cleared', tag: 'BackupProvider');
    } catch (e) {
      AppUtils.logError('Failed to clear backup history', error: e);
    }
  }
}
