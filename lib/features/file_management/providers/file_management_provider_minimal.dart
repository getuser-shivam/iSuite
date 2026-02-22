import 'package:flutter/foundation.dart';
import '../models/file_model.dart';

/// Minimal File Management Provider
/// Only essential methods for immediate build success
class FileManagementProviderMinimal extends ChangeNotifier {
  final List<FileModel> _files = [];
  final List<FileModel> _selectedFiles = [];
  bool _isLoading = false;
  String? _lastOperation;

  FileManagementProviderMinimal() {
    _files.addAll([
      FileModel(
        id: '1',
        name: 'README.md',
        path: '/README.md',
        size: 1024,
        isDirectory: false,
        modifiedAt: DateTime.now().subtract(Duration(days: 1)),
      ),
      FileModel(
        id: '2',
        name: 'pubspec.yaml',
        path: '/pubspec.yaml',
        size: 2048,
        isDirectory: false,
        modifiedAt: DateTime.now().subtract(Duration(hours: 2)),
      ),
    ]);
    notifyListeners();
  }

  List<FileModel> get files => List.from(_files);
  List<FileModel> get selectedFiles => List.from(_selectedFiles);
  bool get isLoading => _isLoading;
  String? get lastOperation => _lastOperation;

  void selectFile(FileModel file) {
    _selectedFiles.clear();
    _selectedFiles.add(file);
    _lastOperation = 'Selected ${file.name}';
    notifyListeners();
  }

  void deselectFile(String filePath) {
    _selectedFiles.remove(filePath);
    _lastOperation = 'Deselected file';
    notifyListeners();
  }

  void deleteFile(String filePath) {
    _files.removeWhere((file) => file.path == filePath);
    _selectedFiles.removeWhere((file) => file.path == filePath);
    _lastOperation = 'Deleted file';
    notifyListeners();
  }

  void refreshFiles() {
    _isLoading = true;
    notifyListeners();
    
    // Simulate refresh
    Future.delayed(Duration(milliseconds: 300));
    
    _lastOperation = 'Refreshed files';
    _isLoading = false;
    notifyListeners();
  }

  void clearSelection() {
    _selectedFiles.clear();
    notifyListeners();
  }
}
