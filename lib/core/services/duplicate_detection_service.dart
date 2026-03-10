import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../logging_service.dart';

/// Duplicate Detection Service for iSuite
/// Provides content-based duplicate file detection using hashing
class DuplicateDetectionService {
  static final DuplicateDetectionService _instance = DuplicateDetectionService._internal();
  factory DuplicateDetectionService() => _instance;
  DuplicateDetectionService._internal();

  final LoggingService _logger = LoggingService();

  /// Find duplicate files in the given list of paths
  Future<Map<String, List<String>>> findDuplicates(List<String> filePaths) async {
    _logger.info('Starting duplicate detection for ${filePaths.length} files', 'DuplicateDetectionService');

    final Map<String, List<String>> hashToFiles = {};
    final Map<String, List<String>> duplicates = {};

    for (final path in filePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final hash = await _calculateFileHash(file);
          if (hash != null) {
            hashToFiles.putIfAbsent(hash, () => []).add(path);
          }
        } else {
          _logger.warning('File not found: $path', 'DuplicateDetectionService');
        }
      } catch (e) {
        _logger.error('Error processing file $path: $e', 'DuplicateDetectionService');
      }
    }

    // Filter groups with more than one file
    hashToFiles.forEach((hash, files) {
      if (files.length > 1) {
        duplicates[hash] = files;
      }
    });

    _logger.info('Found ${duplicates.length} duplicate groups', 'DuplicateDetectionService');
    return duplicates;
  }

  /// Calculate SHA-256 hash of a file
  Future<String?> _calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes);
      return hash.toString();
    } catch (e) {
      _logger.error('Error calculating hash for ${file.path}: $e', 'DuplicateDetectionService');
      return null;
    }
  }

  /// Get duplicate statistics
  Map<String, int> getDuplicateStats(Map<String, List<String>> duplicates) {
    int totalDuplicates = 0;
    int wastedSpace = 0; // Would need file sizes, simplified

    duplicates.forEach((hash, files) {
      totalDuplicates += files.length - 1; // Extra copies
    });

    return {
      'duplicateGroups': duplicates.length,
      'totalDuplicates': totalDuplicates,
      'wastedSpace': wastedSpace, // Placeholder
    };
  }
}
