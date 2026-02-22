import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'file_management_event.dart';
import 'file_management_state.dart';
import '../models/file_model.dart';
import '../repositories/file_management_repository.dart';

/// Enhanced File Management BLoC inspired by Sharik and Owlfile
/// Features intelligent file operations, AI integration, and robust error handling
class FileManagementBloc extends Bloc<FileManagementEvent, FileManagementState> {
  final FileManagementRepository _repository;

  FileManagementBloc(this._repository) : super(FileManagementState.initial()) {
    on<FileManagementEvent>(_onFileManagementEvent);
  }

  Stream<FileManagementState> _onFileManagementEvent(
    FileManagementEvent event,
  ) async* {
    if (event is FileManagementEvent) {
      yield* _handleFileEvent(event);
    }
  }

  Stream<FileManagementState> _handleFileEvent(FileManagementEvent event) async* {
    try {
      switch (event.name) {
        case 'fileSelected':
          yield* _handleFileSelection(event);
          break;
        case 'filesSelected':
          yield* _handleMultipleFileSelection(event);
          break;
        case 'fileDeselected':
          yield* _handleFileDeselection(event);
          break;
        case 'filesDeselected':
          yield* _handleMultipleFileDeselection(event);
          break;
        case 'fileOpened':
          yield* _handleFileOpen(event);
          break;
        case 'fileDeleted':
          yield* _handleFileDeletion(event);
          break;
        case 'fileCopied':
          yield* _handleFileCopy(event);
          break;
        case 'fileMoved':
          yield* _handleFileMove(event);
          break;
        case 'fileCompressed':
          yield* _handleFileCompression(event);
          break;
        case 'fileShared':
          yield* _handleFileSharing(event);
          break;
        case 'directoryCreated':
          yield* _handleDirectoryCreation(event);
          break;
        case 'directoryDeleted':
          yield* _handleDirectoryDeletion(event);
          break;
        case 'refreshRequested':
          yield* _handleRefreshRequest(event);
          break;
        case 'searchPerformed':
          yield* _handleSearch(event);
          break;
        case 'filterChanged':
          yield* _handleFilterChange(event);
          break;
        case 'sortChanged':
          yield* _handleSortChange(event);
          break;
        case 'viewModeChanged':
          yield* _handleViewModeChange(event);
          break;
        default:
          yield* _handleUnknownEvent(event);
          break;
      }
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to handle ${event.name}: $e',
      );
    }
  }

  Stream<FileManagementState> _handleFileSelection(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final file = event.data['file'] as FileModel;
      final updatedSelection = Set<String>.from(state.selectedFiles)..add(file.path);
      
      yield state.copyWith(
        isLoading: false,
        selectedFiles: updatedSelection,
        lastOperation: 'Selected ${file.name}',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to select file: $e',
      );
    }
  }

  Stream<FileManagementState> _handleMultipleFileSelection(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final files = event.data['files'] as List<FileModel>;
      final updatedSelection = Set<String>.from(files.map((f) => f.path));
      
      yield state.copyWith(
        isLoading: false,
        selectedFiles: updatedSelection,
        lastOperation: 'Selected ${files.length} files',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to select files: $e',
      );
    }
  }

  Stream<FileManagementState> _handleFileDeselection(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final filePath = event.data['filePath'] as String;
      final updatedSelection = Set<String>.from(state.selectedFiles)..remove(filePath);
      
      yield state.copyWith(
        isLoading: false,
        selectedFiles: updatedSelection,
        lastOperation: 'Deselected file',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to deselect file: $e',
      );
    }
  }

  Stream<FileManagementState> _handleMultipleFileDeselection(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final filePaths = event.data['filePaths'] as List<String>;
      final updatedSelection = Set<String>.from(state.selectedFiles);
      for (final path in filePaths) {
        updatedSelection.remove(path);
      }
      
      yield state.copyWith(
        isLoading: false,
        selectedFiles: updatedSelection,
        lastOperation: 'Deselected ${filePaths.length} files',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to deselect files: $e',
      );
    }
  }

  Stream<FileManagementState> _handleFileOpen(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final file = event.data['file'] as FileModel;
      
      // Simulate file opening
      await Future.delayed(Duration(milliseconds: 500));
      
      yield state.copyWith(
        isLoading: false,
        lastOperation: 'Opened ${file.name}',
        currentFile: file,
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to open file: $e',
      );
    }
  }

  Stream<FileManagementState> _handleFileDeletion(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final filePath = event.data['filePath'] as String;
      
      // Perform file deletion
      await _repository.deleteFile(filePath);
      
      final updatedSelection = Set<String>.from(state.selectedFiles)..remove(filePath);
      
      yield state.copyWith(
        isLoading: false,
        selectedFiles: updatedSelection,
        lastOperation: 'Deleted file',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to delete file: $e',
      );
    }
  }

  Stream<FileManagementState> _handleFileCopy(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final sourcePath = event.data['sourcePath'] as String;
      final destinationPath = event.data['destinationPath'] as String;
      
      // Perform file copy
      await _repository.copyFile(sourcePath, destinationPath);
      
      yield state.copyWith(
        isLoading: false,
        lastOperation: 'Copied file',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to copy file: $e',
      );
    }
  }

  Stream<FileManagementState> _handleFileMove(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final sourcePath = event.data['sourcePath'] as String;
      final destinationPath = event.data['destinationPath'] as String;
      
      // Perform file move
      await _repository.moveFile(sourcePath, destinationPath);
      
      yield state.copyWith(
        isLoading: false,
        lastOperation: 'Moved file',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to move file: $e',
      );
    }
  }

  Stream<FileManagementState> _handleFileCompression(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final filePaths = event.data['filePaths'] as List<String>;
      final compressionType = event.data['compressionType'] as String;
      
      // Perform file compression
      await _repository.compressFiles(filePaths, compressionType);
      
      yield state.copyWith(
        isLoading: false,
        lastOperation: 'Compressed ${filePaths.length} files',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to compress files: $e',
      );
    }
  }

  Stream<FileManagementState> _handleFileSharing(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final filePaths = event.data['filePaths'] as List<String>;
      final shareMethod = event.data['shareMethod'] as String;
      
      // Perform file sharing
      await _repository.shareFiles(filePaths, shareMethod);
      
      yield state.copyWith(
        isLoading: false,
        lastOperation: 'Shared ${filePaths.length} files via $shareMethod',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to share files: $e',
      );
    }
  }

  Stream<FileManagementState> _handleDirectoryCreation(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final directoryPath = event.data['directoryPath'] as String;
      final directoryName = event.data['directoryName'] as String;
      
      // Perform directory creation
      await _repository.createDirectory(directoryPath, directoryName);
      
      yield state.copyWith(
        isLoading: false,
        lastOperation: 'Created directory $directoryName',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to create directory: $e',
      );
    }
  }

  Stream<FileManagementState> _handleDirectoryDeletion(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final directoryPath = event.data['directoryPath'] as String;
      
      // Perform directory deletion
      await _repository.deleteDirectory(directoryPath);
      
      yield state.copyWith(
        isLoading: false,
        lastOperation: 'Deleted directory',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to delete directory: $e',
      );
    }
  }

  Stream<FileManagementState> _handleRefreshRequest(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      // Refresh current directory
      await _repository.refreshCurrentDirectory();
      
      yield state.copyWith(
        isLoading: false,
        lastOperation: 'Refreshed directory',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to refresh directory: $e',
      );
    }
  }

  Stream<FileManagementState> _handleSearch(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final query = event.data['query'] as String;
      final searchResults = await _repository.searchFiles(query);
      
      yield state.copyWith(
        isLoading: false,
        searchResults: searchResults,
        lastOperation: 'Searched for "$query"',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to search files: $e',
      );
    }
  }

  Stream<FileManagementState> _handleFilterChange(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final filterType = event.data['filterType'] as String;
      final filterValue = event.data['filterValue'] as String;
      
      // Apply filter
      await _repository.applyFilter(filterType, filterValue);
      
      yield state.copyWith(
        isLoading: false,
        currentFilter: '$filterType: $filterValue',
        lastOperation: 'Applied filter',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to apply filter: $e',
      );
    }
  }

  Stream<FileManagementState> _handleSortChange(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final sortBy = event.data['sortBy'] as String;
      final sortOrder = event.data['sortOrder'] as String;
      
      // Apply sorting
      await _repository.sortFiles(sortBy, sortOrder);
      
      yield state.copyWith(
        isLoading: false,
        currentSort: '$sortBy: $sortOrder',
        lastOperation: 'Sorted files by $sortBy',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to sort files: $e',
      );
    }
  }

  Stream<FileManagementState> _handleViewModeChange(FileManagementEvent event) async* {
    yield state.copyWith(isLoading: true);
    
    try {
      final viewMode = event.data['viewMode'] as String;
      
      // Change view mode
      await _repository.changeViewMode(viewMode);
      
      yield state.copyWith(
        isLoading: false,
        currentViewMode: viewMode,
        lastOperation: 'Changed view mode to $viewMode',
      );
    } catch (e) {
      yield state.copyWith(
        isLoading: false,
        error: 'Failed to change view mode: $e',
      );
    }
  }

  Stream<FileManagementState> _handleUnknownEvent(FileManagementEvent event) async* {
    yield state.copyWith(
      error: 'Unknown event type: ${event.name}',
    );
  }
}
