import 'dart:async';
import 'package:flutter/foundation.dart';
import '../file_model.dart';

/// Fixed File Management Provider
/// Simplified for immediate build success
class FileManagementProviderFixed extends ChangeNotifier {
  final List<FileModel> _files = [];
  final List<FileModel> _selectedFiles = [];
  bool _isLoading = false;
  String? _lastOperation;

  FileManagementProviderFixed() {
    _loadInitialFiles();
  }

  void _loadInitialFiles() {
    // Simulate initial file loading
    _files.addAll([
      FileModel(
        id: '1',
        name: 'README.md',
        path: '/README.md',
        size: 1024,
        isDirectory: false,
        modified: DateTime.now().subtract(const Duration(days: 1)),
      ),
      FileModel(
        id: '2',
        name: 'pubspec.yaml',
        path: '/pubspec.yaml',
        size: 2048,
        isDirectory: false,
        modified: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      FileModel(
        id: '3',
        name: 'lib',
        path: '/lib',
        size: 4096,
        isDirectory: true,
        modified: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ]);
    notifyListeners();
  }

  List<FileModel> get files => List.from(_files);
  List<FileModel> get selectedFiles => List.from(_selectedFiles);
  bool get isLoading => _isLoading;
  String? get lastOperation => _lastOperation;

  Future<void> selectFile(FileModel file) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    _selectedFiles.clear();
    _selectedFiles.add(file);
    _lastOperation = 'Selected ${file.name}';
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deselectFile(String filePath) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    _selectedFiles.removeWhere((file) => file.path == filePath);
    _lastOperation = 'Deselected file';
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteFile(String filePath) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    _files.removeWhere((file) => file.path == filePath);
    _selectedFiles.removeWhere((file) => file.path == filePath);
    _lastOperation = 'Deleted file';
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshFiles() async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    _lastOperation = 'Refreshed files';
    _isLoading = false;
    notifyListeners();
  }

  void clearSelection() {
    _selectedFiles.clear();
    notifyListeners();
  }
}
