import 'package:flutter/material.dart';
import '../../domain/models/file.dart';
import '../../data/repositories/file_repository.dart';
import '../../core/utils.dart';

class FileProvider extends ChangeNotifier {
  List<FileModel> _files = [];
  List<FileModel> _filteredFiles = [];
  FileType _selectedType = FileType.document;
  FileStatus _selectedStatus = FileStatus.completed;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  bool _isGridView = true;
  SortOption _sortBy = SortOption.updatedAt;
  bool _sortAscending = false;
  bool _showEncrypted = false;
  bool _showFavorites = false;
  String _selectedSizeFilter = 'all';

  // Getters
  List<FileModel> get files => _files;
  List<FileModel> get filteredFiles => _filteredFiles;
  FileType get selectedType => _selectedType;
  FileStatus get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGridView => _isGridView;
  SortOption get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  bool get showEncrypted => _showEncrypted;
  bool get showFavorites => _showFavorites;
  String get selectedSizeFilter => _selectedSizeFilter;

  // Computed properties
  int get totalFiles => _files.length;
  int get completedFiles => _files.where((file) => file.status == FileStatus.completed).length;
  int get uploadingFiles => _files.where((file) => file.status == FileStatus.uploading).length;
  int get processingFiles => _files.where((file) => file.status == FileStatus.processing).length;
  int get failedFiles => _files.where((file) => file.status == FileStatus.failed).length;
  int get deletedFiles => _files.where((file) => file.status == FileStatus.deleted).length;
  int get encryptedFiles => _files.where((file) => file.isEncrypted).length;
  int get favoriteFiles => _files.where((file) => file.tags.contains('favorite')).length;
  int get imageFiles => _files.where((file) => file.isImage).length;
  int get documentFiles => _files.where((file) => file.isDocument).length;
  int get videoFiles => _files.where((file) => file.isVideo).length;
  int get audioFiles => _files.where((file) => file.isAudio).length;
  int get archiveFiles => _files.where((file) => file.isArchive).length;

  double get totalSize {
    return _files.fold<double>(0, (sum, file) => sum + file.size);
  }

  String get formattedTotalSize {
    final totalBytes = totalSize.toInt();
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024) return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  FileProvider() {
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Loading files...', tag: 'FileProvider');
      _files = await FileRepository.getAllFiles();
      _applyFiltersAndSort();
      AppUtils.logInfo('Files loaded successfully: ${_files.length} files', tag: 'FileProvider');
    } catch (e) {
      _error = 'Failed to load files: ${e.toString()}';
      AppUtils.logError('Failed to load files', tag: 'FileProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createFile({
    required String name,
    required String path,
    required int size,
    FileType type = FileType.document,
    String? mimeType,
    String? description,
    List<String> tags = const [],
    bool isEncrypted = false,
    String? password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Creating file: $name', tag: 'FileProvider');
      
      final file = FileModel(
        id: AppUtils.generateRandomId(),
        name: name.trim(),
        path: path.trim(),
        size: size,
        type: type,
        status: FileStatus.uploading,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mimeType: mimeType,
        description: description?.trim(),
        tags: tags,
        isEncrypted: isEncrypted,
        password: password,
      );

      final fileId = await FileRepository.createFile(file);
      
      // Update status to completed after successful creation
      final completedFile = file.copyWith(
        status: FileStatus.completed,
        uploadedAt: DateTime.now(),
      );
      await FileRepository.updateFile(completedFile);
      
      _files.insert(0, completedFile);
      _applyFiltersAndSort();
      
      _error = null;
      AppUtils.logInfo('File created successfully: ${file.id}', tag: 'FileProvider');
    } catch (e) {
      _error = 'Failed to create file: ${e.toString()}';
      AppUtils.logError('Failed to create file', tag: 'FileProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFile(FileModel file) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Updating file: ${file.name}', tag: 'FileProvider');
      
      final updatedFile = file.copyWith(updatedAt: DateTime.now());
      await FileRepository.updateFile(updatedFile);
      
      final index = _files.indexWhere((f) => f.id == file.id);
      if (index != -1) {
        _files[index] = updatedFile;
      }
      _applyFiltersAndSort();
      
      _error = null;
      AppUtils.logInfo('File updated successfully: ${file.id}', tag: 'FileProvider');
    } catch (e) {
      _error = 'Failed to update file: ${e.toString()}';
      AppUtils.logError('Failed to update file', tag: 'FileProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFile(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Deleting file: $id', tag: 'FileProvider');
      await FileRepository.deleteFile(id);
      _files.removeWhere((file) => file.id == id);
      _applyFiltersAndSort();
      
      _error = null;
      AppUtils.logInfo('File deleted successfully: $id', tag: 'FileProvider');
    } catch (e) {
      _error = 'Failed to delete file: ${e.toString()}';
      AppUtils.logError('Failed to delete file', tag: 'FileProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFileFavorite(String id) async {
    final file = _files.firstWhere((f) => f.id == id);
    final updatedTags = List<String>.from(file.tags);
    
    if (updatedTags.contains('favorite')) {
      updatedTags.remove('favorite');
    } else {
      updatedTags.add('favorite');
    }
    
    final updatedFile = file.copyWith(tags: updatedTags);
    await updateFile(updatedFile);
  }

  Future<void> toggleFileEncryption(String id, {String? password}) async {
    final file = _files.firstWhere((f) => f.id == id);
    final isEncrypted = !file.isEncrypted;
    await FileRepository.toggleFileEncryption(id, isEncrypted, password: password);
    
    final updatedFile = file.copyWith(isEncrypted: isEncrypted, password: password);
    final index = _files.indexWhere((f) => f.id == id);
    if (index != -1) {
      _files[index] = updatedFile;
    }
    
    notifyListeners();
  }

  void setTypeFilter(FileType type) {
    _selectedType = type;
    _applyFiltersAndSort();
  }

  void setStatusFilter(FileStatus status) {
    _selectedStatus = status;
    _applyFiltersAndSort();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
  }

  void setSizeFilter(String sizeFilter) {
    _selectedSizeFilter = sizeFilter;
    _applyFiltersAndSort();
  }

  void toggleEncryptedFilter() {
    _showEncrypted = !_showEncrypted;
    _applyFiltersAndSort();
  }

  void toggleFavoriteFilter() {
    _showFavorites = !_showFavorites;
    _applyFiltersAndSort();
  }

  void setSortOption(SortOption sortBy, {bool ascending = false}) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFiltersAndSort();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void clearFilters() {
    _selectedType = FileType.document;
    _selectedStatus = FileStatus.completed;
    _searchQuery = '';
    _selectedSizeFilter = 'all';
    _showEncrypted = false;
    _showFavorites = false;
    _sortBy = SortOption.updatedAt;
    _sortAscending = false;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredFiles = _files.where((file) {
      // Type filter
      if (_selectedType != FileType.document && file.type != _selectedType) {
        return false;
      }
      
      // Status filter
      if (_selectedStatus != FileStatus.completed && file.status != _selectedStatus) {
        return false;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final nameMatch = file.name.toLowerCase().contains(searchLower);
        final descriptionMatch = file.description?.toLowerCase().contains(searchLower) ?? false;
        final tagsMatch = file.tags.any((tag) => tag.toLowerCase().contains(searchLower));
        
        if (!nameMatch && !descriptionMatch && !tagsMatch) {
          return false;
        }
      }
      
      // Size filter
      if (_selectedSizeFilter != 'all') {
        switch (_selectedSizeFilter) {
          case 'small':
            return file.size < 1024 * 100; // < 100KB
          case 'medium':
            return file.size >= 1024 * 100 && file.size < 1024 * 1024; // 100KB - 1MB
          case 'large':
            return file.size >= 1024 * 1024 && file.size < 1024 * 1024 * 100; // 1MB - 100MB
          case 'huge':
            return file.size >= 1024 * 1024 * 100; // > 100MB
        }
      }
      
      // Encrypted filter
      if (!_showEncrypted && file.isEncrypted) {
        return false;
      }
      
      // Favorite filter
      if (_showFavorites && !file.tags.contains('favorite')) {
        return false;
      }
      
      return true;
    }).toList();

    // Apply sorting
    _filteredFiles.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case SortOption.name:
          comparison = a.name.compareTo(b.name);
          break;
        case SortOption.size:
          comparison = a.size.compareTo(b.size);
          break;
        case SortOption.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case SortOption.updatedAt:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case SortOption.type:
          comparison = a.type.name.compareTo(b.type.name);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    notifyListeners();
  }

  Future<void> refreshFiles() async {
    await _loadFiles();
  }

  Future<void> batchDeleteFiles(List<String> ids) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppUtils.logInfo('Batch deleting files: ${ids.length} files', tag: 'FileProvider');
      await FileRepository.batchDeleteFiles(ids);
      _files.removeWhere((file) => ids.contains(file.id));
      _applyFiltersAndSort();
      
      _error = null;
      AppUtils.logInfo('Files batch deleted successfully: ${ids.length} files', tag: 'FileProvider');
    } catch (e) {
      _error = 'Failed to batch delete files: ${e.toString()}';
      AppUtils.logError('Failed to batch delete files', tag: 'FileProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

enum SortOption {
  name,
  size,
  createdAt,
  updatedAt,
  type,
}
