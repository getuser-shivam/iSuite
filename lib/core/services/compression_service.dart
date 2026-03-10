import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

/// File Compression Service
/// Provides ZIP and TAR compression/decompression functionality
class CompressionService {
  /// Compress files into ZIP archive
  Future<String> compressToZip(
    List<File> files,
    String outputPath, {
    String? password,
    void Function(double)? onProgress,
  }) async {
    final archive = Archive();

    int processed = 0;
    for (final file in files) {
      if (await file.exists()) {
        final fileName = path.basename(file.path);
        final bytes = await file.readAsBytes();
        final archiveFile = ArchiveFile(fileName, bytes.length, bytes);
        archive.addFile(archiveFile);
      }

      processed++;
      onProgress?.call(processed / files.length);
    }

    final zipData = ZipEncoder(password: password).encode(archive);
    if (zipData == null) {
      throw Exception('Failed to encode ZIP archive');
    }

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(zipData);

    return outputPath;
  }

  /// Decompress ZIP archive
  Future<List<String>> decompressZip(
    String zipPath,
    String outputDir, {
    String? password,
    void Function(double)? onProgress,
  }) async {
    final zipFile = File(zipPath);
    final bytes = await zipFile.readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes, password: password);
    if (archive == null) {
      throw Exception('Failed to decode ZIP archive');
    }

    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final extractedFiles = <String>[];
    int processed = 0;

    for (final file in archive) {
      if (file.isFile) {
        final outputPath = path.join(outputDir, file.name);
        final outputFile = File(outputPath);

        // Create parent directories if needed
        final parentDir = outputFile.parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }

        await outputFile.writeAsBytes(file.content as List<int>);
        extractedFiles.add(outputPath);
      }

      processed++;
      onProgress?.call(processed / archive.length);
    }

    return extractedFiles;
  }

  /// Get supported compression formats
  List<String> getSupportedFormats() {
    return ['ZIP'];
  }

  /// Calculate compression ratio
  double calculateCompressionRatio(int originalSize, int compressedSize) {
    if (originalSize == 0) return 0.0;
    return ((originalSize - compressedSize) / originalSize) * 100.0;
  }

  /// Validate archive file
  Future<bool> validateArchive(String archivePath) async {
    try {
      final file = File(archivePath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      return archive != null;
    } catch (e) {
      return false;
    }
  }
}
