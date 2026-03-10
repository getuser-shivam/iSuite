import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../logging/logging_service.dart';

/// File Compression Service for iSuite
/// Provides ZIP compression and decompression functionality
class FileCompressionService {
  static final FileCompressionService _instance = FileCompressionService._internal();
  factory FileCompressionService() => _instance;
  FileCompressionService._internal();

  final LoggingService _logger = LoggingService();

  /// Compress multiple files into a ZIP archive
  Future<String?> compressFiles(List<String> filePaths, String archiveName) async {
    try {
      _logger.info('Starting compression of ${filePaths.length} files to $archiveName', 'FileCompressionService');

      final archive = Archive();

      for (final filePath in filePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          final fileName = path.basename(filePath);
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          _logger.info('Added file: $fileName', 'FileCompressionService');
        } else {
          _logger.warning('File not found: $filePath', 'FileCompressionService');
        }
      }

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      if (zipData == null) {
        throw Exception('Failed to encode ZIP data');
      }

      // Save to downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }

      final archivePath = path.join(directory.path, '$archiveName.zip');
      final zipFile = File(archivePath);
      await zipFile.writeAsBytes(zipData);

      _logger.info('Compression completed: $archivePath', 'FileCompressionService');
      return archivePath;
    } catch (e) {
      _logger.error('Compression failed: $e', 'FileCompressionService');
      return null;
    }
  }

  /// Decompress a ZIP archive
  Future<String?> decompressFile(String zipPath, String outputDir) async {
    try {
      _logger.info('Starting decompression of $zipPath to $outputDir', 'FileCompressionService');

      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('ZIP file not found');
      }

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final outputDirectory = Directory(outputDir);
      if (!await outputDirectory.exists()) {
        await outputDirectory.create(recursive: true);
      }

      for (final file in archive) {
        final fileName = file.name;
        final filePath = path.join(outputDir, fileName);

        if (file.isFile) {
          final outputFile = File(filePath);
          await outputFile.parent.create(recursive: true);
          await outputFile.writeAsBytes(file.content as Uint8List);
          _logger.info('Extracted file: $fileName', 'FileCompressionService');
        } else {
          await Directory(filePath).create(recursive: true);
          _logger.info('Created directory: $fileName', 'FileCompressionService');
        }
      }

      _logger.info('Decompression completed to $outputDir', 'FileCompressionService');
      return outputDir;
    } catch (e) {
      _logger.error('Decompression failed: $e', 'FileCompressionService');
      return null;
    }
  }

  /// Get available output directories
  Future<List<String>> getAvailableDirectories() async {
    final dirs = <String>[];

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) dirs.add(downloads.path);

      final documents = await getApplicationDocumentsDirectory();
      dirs.add(documents.path);

      final external = await getExternalStorageDirectory();
      if (external != null) dirs.add(external.path);
    } catch (e) {
      _logger.error('Error getting directories: $e', 'FileCompressionService');
    }

    return dirs;
  }
}
