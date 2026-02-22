import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

class FileOperationsService {
  static Future<String> compressFiles(List<String> filePaths, String outputPath) async {
    try {
      final archive = Archive();
      
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final fileName = file.path.split('/').last;
          archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
        }
      }
      
      final zipFile = File(outputPath);
      await zipFile.writeAsBytes(ZipEncoder().encode(archive));
      
      return outputPath;
    } catch (e) {
      throw Exception('Compression failed: $e');
    }
  }

  static Future<List<String>> extractFiles(String zipPath, String outputDir) async {
    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final extractedFiles = <String>[];
      
      for (final file in archive) {
        final filePath = '$outputDir/${file.name}';
        final outputFile = File(filePath);
        
        // Create directory if it doesn't exist
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>);
        
        extractedFiles.add(filePath);
      }
      
      return extractedFiles;
    } catch (e) {
      throw Exception('Extraction failed: $e');
    }
  }

  static Future<String> encryptFile(String filePath, String password) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Generate key from password
      final keyBytes = utf8.encode(password);
      final key = sha256.convert(keyBytes).bytes;
      
      // Simple XOR encryption (in production, use proper encryption like AES)
      final encryptedBytes = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ key[i % key.length],
      );
      
      final encryptedPath = '${filePath}.encrypted';
      await File(encryptedPath).writeAsBytes(encryptedBytes);
      
      return encryptedPath;
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  static Future<String> decryptFile(String encryptedFilePath, String password) async {
    try {
      final file = File(encryptedFilePath);
      final encryptedBytes = await file.readAsBytes();
      
      // Generate key from password
      final keyBytes = utf8.encode(password);
      final key = sha256.convert(keyBytes).bytes;
      
      // Simple XOR decryption (in production, use proper decryption like AES)
      final decryptedBytes = List<int>.generate(
        encryptedBytes.length,
        (i) => encryptedBytes[i] ^ key[i % key.length],
      );
      
      // Remove .encrypted extension
      final originalPath = encryptedFilePath.replaceAll('.encrypted', '');
      await File(originalPath).writeAsBytes(decryptedBytes);
      
      return originalPath;
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  static Future<Map<String, dynamic>> calculateFileHashes(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      return {
        'md5': md5.convert(bytes).toString(),
        'sha1': sha1.convert(bytes).toString(),
        'sha256': sha256.convert(bytes).toString(),
        'size': bytes.length,
      };
    } catch (e) {
      throw Exception('Hash calculation failed: $e');
    }
  }

  static Future<bool> verifyFileIntegrity(String filePath, Map<String, String> expectedHashes) async {
    try {
      final actualHashes = await calculateFileHashes(filePath);
      
      return actualHashes['md5'] == expectedHashes['md5'] &&
             actualHashes['sha1'] == expectedHashes['sha1'] &&
             actualHashes['sha256'] == expectedHashes['sha256'];
    } catch (e) {
      return false;
    }
  }

  static Future<String> createBackup(List<String> filePaths, String backupPath) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupDir = Directory('$backupPath/backup_$timestamp');
      await backupDir.create(recursive: true);
      
      final backedUpFiles = <String>[];
      
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          final backupFilePath = '${backupDir.path}/$fileName';
          await file.copy(backupFilePath);
          backedUpFiles.add(backupFilePath);
        }
      }
      
      // Create backup manifest
      final manifest = {
        'timestamp': timestamp,
        'files': filePaths,
        'backedUpFiles': backedUpFiles,
        'hashes': <String, Map<String, String>>{},
      };
      
      for (final filePath in filePaths) {
        final hashes = await calculateFileHashes(filePath);
        manifest['hashes'][filePath] = {
          'md5': hashes['md5'],
          'sha1': hashes['sha1'],
          'sha256': hashes['sha256'],
        };
      }
      
      final manifestFile = File('${backupDir.path}/manifest.json');
      await manifestFile.writeAsString(jsonEncode(manifest));
      
      return backupDir.path;
    } catch (e) {
      throw Exception('Backup failed: $e');
    }
  }

  static Future<List<String>> restoreFromBackup(String backupPath, String restorePath) async {
    try {
      final backupDir = Directory(backupPath);
      final manifestFile = File('${backupDir.path}/manifest.json');
      
      if (!await manifestFile.exists()) {
        throw Exception('Backup manifest not found');
      }
      
      final manifestContent = await manifestFile.readAsString();
      final manifest = jsonDecode(manifestContent);
      
      final restoredFiles = <String>[];
      final restoreDir = Directory(restorePath);
      await restoreDir.create(recursive: true);
      
      // Verify file integrity before restoring
      final files = manifest['files'] as List<String>;
      final hashes = manifest['hashes'] as Map<String, dynamic>;
      
      for (final filePath in files) {
        final backupFilePath = '${backupDir.path}/${filePath.split('/').last}';
        final backupFile = File(backupFilePath);
        
        if (await backupFile.exists()) {
          // Verify integrity
          final expectedHashes = hashes[filePath] as Map<String, String>;
          final isValid = await verifyFileIntegrity(backupFilePath, expectedHashes);
          
          if (isValid) {
            final restoredFilePath = '$restorePath/${filePath.split('/').last}';
            await backupFile.copy(restoredFilePath);
            restoredFiles.add(restoredFilePath);
          } else {
            throw Exception('File integrity check failed for $filePath');
          }
        }
      }
      
      return restoredFiles;
    } catch (e) {
      throw Exception('Restore failed: $e');
    }
  }

  static Future<Map<String, dynamic>> getDetailedFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();
      final extension = filePath.split('.').last.toLowerCase();
      
      return {
        'name': file.path.split('/').last,
        'path': filePath,
        'size': stat.size,
        'modified': stat.modified,
        'accessed': stat.accessed,
        'type': extension,
        'isDirectory': false,
        'permissions': await _getFilePermissions(file),
        'hashes': await calculateFileHashes(filePath),
      };
    } catch (e) {
      throw Exception('Failed to get file info: $e');
    }
  }

  static Future<Map<String, bool>> _getFilePermissions(File file) async {
    try {
      final stat = await file.stat();
      final mode = stat.mode;
      
      return {
        'read': mode & 0o444 != 0,
        'write': mode & 0o222 != 0,
        'execute': mode & 0o111 != 0,
      };
    } catch (e) {
      return {
        'read': false,
        'write': false,
        'execute': false,
      };
    }
  }

  static Future<void> setFilePermissions(String filePath, Map<String, bool> permissions) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();
      var mode = stat.mode;
      
      if (permissions['read'] == true) {
        mode |= 0o444;
      } else {
        mode &= ~0o444;
      }
      
      if (permissions['write'] == true) {
        mode |= 0o222;
      } else {
        mode &= ~0o222;
      }
      
      if (permissions['execute'] == true) {
        mode |= 0o111;
      } else {
        mode &= ~0o111;
      }
      
      // In a real implementation, you'd use platform-specific APIs
      debugPrint('Setting permissions for $filePath to: $mode');
    } catch (e) {
      throw Exception('Failed to set permissions: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> searchFilesByContent(
    String directoryPath,
    String searchTerm, {
    bool caseSensitive = false,
    bool useRegex = false,
  }) async {
    try {
      final directory = Directory(directoryPath);
      final files = await directory.list(recursive: true).toList();
      final results = <Map<String, dynamic>>[];
      
      for (final file in files) {
        if (file is File) {
          final content = await file.readAsString();
          final fileName = file.path.split('/').last;
          
          bool matches = false;
          
          if (useRegex) {
            try {
              final pattern = RegExp(searchTerm, caseSensitive: caseSensitive);
              matches = pattern.hasMatch(content);
            } catch (e) {
              continue; // Skip invalid regex
            }
          } else {
            final searchContent = caseSensitive ? content : content.toLowerCase();
            final searchTermAdjusted = caseSensitive ? searchTerm : searchTerm.toLowerCase();
            matches = searchContent.contains(searchTermAdjusted);
          }
          
          if (matches) {
            results.add({
              'path': file.path,
              'name': fileName,
              'size': await file.length(),
              'modified': await file.lastModified(),
              'matches': _findContentMatches(content, searchTerm, caseSensitive),
            });
          }
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('Content search failed: $e');
    }
  }

  static List<Map<String, dynamic>> _findContentMatches(
    String content,
    String searchTerm,
    bool caseSensitive,
  ) {
    final matches = <Map<String, dynamic>>[];
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final searchContent = caseSensitive ? line : line.toLowerCase();
      final searchTermAdjusted = caseSensitive ? searchTerm : searchTerm.toLowerCase();
      
      int index = searchContent.indexOf(searchTermAdjusted);
      while (index != -1) {
        matches.add({
          'line': i + 1,
          'column': index + 1,
          'text': line,
          'context': _getContext(lines, i, 3),
        });
        
        index = searchContent.indexOf(searchTermAdjusted, index + 1);
      }
    }
    
    return matches;
  }

  static List<String> _getContext(List<String> lines, int currentLine, int contextLines) {
    final start = (currentLine - contextLines).clamp(0, lines.length - 1);
    final end = (currentLine + contextLines).clamp(0, lines.length - 1);
    
    return lines.sublist(start, end + 1);
  }

  static Future<Map<String, dynamic>> analyzeStorageUsage(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      final files = await directory.list(recursive: true).toList();
      
      var totalSize = 0;
      var fileCount = 0;
      var folderCount = 0;
      final fileTypes = <String, int>{};
      
      for (final file in files) {
        if (file is File) {
          fileCount++;
          final size = await file.length();
          totalSize += size;
          
          final extension = file.path.split('.').last.toLowerCase();
          fileTypes[extension] = (fileTypes[extension] ?? 0) + 1;
        } else {
          folderCount++;
        }
      }
      
      return {
        'totalSize': totalSize,
        'fileCount': fileCount,
        'folderCount': folderCount,
        'fileTypes': fileTypes,
        'largestFiles': await _findLargestFiles(directoryPath),
        'duplicateFiles': await _findDuplicateFiles(directoryPath),
      };
    } catch (e) {
      throw Exception('Storage analysis failed: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _findLargestFiles(String directoryPath, {int limit = 10}) async {
    try {
      final directory = Directory(directoryPath);
      final files = await directory.list(recursive: true).toList();
      final fileSizes = <Map<String, int>>{};
      
      for (final file in files) {
        if (file is File) {
          final size = await file.length();
          fileSizes[file.path] = size;
        }
      }
      
      final sortedFiles = fileSizes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedFiles.take(limit).map((entry) => {
        'path': entry.key,
        'name': entry.key.split('/').last,
        'size': entry.value,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _findDuplicateFiles(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      final files = await directory.list(recursive: true).toList();
      final fileHashes = <String, List<String>>{};
      
      // Calculate hashes for all files
      for (final file in files) {
        if (file is File) {
          final hashes = await calculateFileHashes(file.path);
          final md5Hash = hashes['md5']!;
          
          if (!fileHashes.containsKey(md5Hash)) {
            fileHashes[md5Hash] = [];
          }
          fileHashes[md5Hash]!.add(file.path);
        }
      }
      
      // Find duplicates
      final duplicates = fileHashes.entries
          .where((entry) => entry.value.length > 1)
          .map((entry) => {
                'hash': entry.key,
                'files': entry.value,
                'count': entry.value.length,
              })
          .toList();
      
      return duplicates;
    } catch (e) {
      return [];
    }
  }
}
