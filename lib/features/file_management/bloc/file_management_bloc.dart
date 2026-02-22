import 'package:flutter_bloc/flutter_bloc.dart';
import 'file_model.dart';

// Events
abstract class FileManagementEvent extends Equatable {
  const FileManagementEvent();
}

class FileManagementLoadFilesRequested extends FileManagementEvent {
  final String directoryPath;

  const FileManagementLoadFilesRequested(this.directoryPath);

  @override
  List<Object> get props => [directoryPath];
}

class FileManagementFilesLoaded extends FileManagementEvent {
  final List<FileModel> files;

  const FileManagementFilesLoaded(this.files);

  @override
  List<Object> get props => [files];
}

class FileManagementFileSelected extends FileManagementEvent {
  final String fileId;

  const FileManagementFileSelected(this.fileId);

  @override
  List<Object> get props => [fileId];
}

class FileManagementFilesSelected extends FileManagementEvent {
  final List<String> fileIds;

  const FileManagementFilesSelected(this.fileIds);

  @override
  List<Object> get props => [fileIds];
}

class FileSelectionCleared extends FileManagementEvent {
  const FileSelectionCleared();
}

class FileManagementFileOperationRequested extends FileManagementEvent {
  final String operation;
  final List<String> fileIds;

  const FileManagementFileOperationRequested(this.operation, this.fileIds);

  @override
  List<Object> get props => [operation, fileIds];
}

class FileManagementShareRequested extends FileManagementEvent {
  final String fileId;
  final ShareType shareType;

  const FileManagementShareRequested(this.fileId, this.shareType);

  @override
  List<Object> get props => [fileId, shareType];
}

class FileManagementCompressRequested extends FileManagementEvent {
  final List<String> fileIds;
  final CompressionType compressionType;
  final String outputPath;

  const FileManagementCompressRequested(this.fileIds, this.compressionType, this.outputPath);

  @override
  List<Object> get props => [fileIds, compressionType, outputPath];
}

// States
abstract class FileManagementState extends Equatable {
  const FileManagementState();

  @override
  List<Object> get props => [];
}

class FileManagementInitial extends FileManagementState {
  const FileManagementInitial();
}

class FileManagementLoading extends FileManagementState {
  const FileManagementLoading();
}

class FileManagementLoaded extends FileManagementState {
  final List<FileModel> files;
  final String currentPath;
  final FileSortOrder sortOrder;
  final FileViewMode viewMode;

  const FileManagementLoaded({
    required this.files,
    required this.currentPath,
    required this.sortOrder,
    required this.viewMode,
  });

  @override
  List<Object> get props => [files, currentPath, sortOrder, viewMode];
}

class FileManagementError extends FileManagementState {
  final String error;

  const FileManagementError(this.error);

  @override
  List<Object> get props => [error];
}

class FileManagementOperationInProgress extends FileManagementState {
  final String operation;

  const FileManagementOperationInProgress(this.operation);

  @override
  List<Object> get props => [operation];
}

// BLoC
class FileManagementBloc extends Bloc<FileManagementEvent, FileManagementState> {
  FileManagementBloc() : super(const FileManagementInitial());

  @override
  Stream<FileManagementState> mapEventToState(FileManagementEvent event) {
    return event.when(
      loadFilesRequested: (directoryPath) async* {
        yield const FileManagementLoading();
        try {
          final files = await _loadFilesFromDirectory(directoryPath);
          yield FileManagementLoaded(
            files: files,
            currentPath: directoryPath,
            sortOrder: FileSortOrder.name,
            viewMode: FileViewMode.list,
          );
        } catch (e) {
          yield FileManagementError(error: e.toString());
        }
      },
      fileSelected: (fileId) async* {
        yield FileManagementOperationInProgress(operation: 'Selecting file');
        // Handle file selection logic
      },
      filesSelected: (fileIds) async* {
        yield FileManagementOperationInProgress(operation: 'Selecting files');
        // Handle multi-file selection logic
      },
      selectionCleared: () async* {
        yield FileManagementOperationInProgress(operation: 'Clearing selection');
        // Handle selection clear logic
      },
      fileOperationRequested: (operation, fileIds) async* {
        yield FileManagementOperationInProgress(operation: operation);
        try {
          final result = await _performFileOperation(operation, fileIds);
          if (result.success) {
            // Reload files after operation
            final currentPath = _getCurrentPath();
            final files = await _loadFilesFromDirectory(currentPath);
            yield FileManagementLoaded(
              files: files,
              currentPath: currentPath,
              sortOrder: FileSortOrder.name,
              viewMode: FileViewMode.list,
            );
          } else {
            yield FileManagementError(error: result.error!);
          }
        } catch (e) {
          yield FileManagementError(error: e.toString());
        }
      },
      shareRequested: (fileId, shareType) async* {
        yield FileManagementOperationInProgress(operation: 'Sharing file');
        try {
          final result = await _shareFile(fileId, shareType);
          if (result.success) {
            yield FileManagementLoaded(
              files: [], // Reload state
              currentPath: _getCurrentPath(),
              sortOrder: FileSortOrder.name,
              viewMode: FileViewMode.list,
            );
          } else {
            yield FileManagementError(error: result.error!);
          }
        } catch (e) {
          yield FileManagementError(error: e.toString());
        }
      },
      compressRequested: (fileIds, compressionType, outputPath) async* {
        yield FileManagementOperationInProgress(operation: 'Compressing files');
        try {
          final result = await _compressFiles(fileIds, compressionType, outputPath);
          if (result.success) {
            yield FileManagementLoaded(
              files: [], // Reload state
              currentPath: _getCurrentPath(),
              sortOrder: FileSortOrder.name,
              viewMode: FileViewMode.list,
            );
          } else {
            yield FileManagementError(error: result.error!);
          }
        } catch (e) {
          yield FileManagementError(error: e.toString());
        }
      },
    );
  }

  Future<List<FileModel>> _loadFilesFromDirectory(String directoryPath) async {
    // Implementation would use file_operations_service.dart
    // This is a placeholder for the BLoC pattern
    return [];
  }

  String _getCurrentPath() {
    // Implementation would track current path
    return '/';
  }

  Future<FileOperationResult> _performFileOperation(String operation, List<String> fileIds) async {
    // Implementation would use file_operations_service.dart
    // This is a placeholder for the BLoC pattern
    return const FileOperationResult(success: true);
  }

  Future<FileOperationResult> _shareFile(String fileId, ShareType shareType) async {
    // Implementation would use qr_share_service.dart
    // This is a placeholder for the BLoC pattern
    return const FileOperationResult(success: true);
  }

  Future<FileOperationResult> _compressFiles(List<String> fileIds, CompressionType compressionType, String outputPath) async {
    // Implementation would use file_operations_service.dart
    // This is a placeholder for the BLoC pattern
    return const FileOperationResult(success: true);
  }
}
