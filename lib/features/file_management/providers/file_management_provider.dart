import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/file_management_bloc.dart';

class FileManagementProvider extends BlocProvider<FileManagementBloc, FileManagementState> {
  FileManagementProvider() : super(create: (_) => FileManagementBloc());

  void loadFiles(String directoryPath) {
    add(FileManagementLoadFilesRequested(directoryPath));
  }

  void selectFile(String fileId) {
    add(FileManagementFileSelected(fileId));
  }

  void selectFiles(List<String> fileIds) {
    add(FileManagementFilesSelected(fileIds));
  }

  void clearSelection() {
    add(const FileSelectionCleared());
  }

  void deleteFiles(List<String> fileIds) {
    add(FileManagementFileOperationRequested('delete', fileIds));
  }

  void copyFiles(List<String> fileIds) {
    add(FileManagementFileOperationRequested('copy', fileIds));
  }

  void moveFiles(List<String> fileIds) {
    add(FileManagementFileOperationRequested('move', fileIds));
  }

  void shareFile(String fileId, ShareType shareType) {
    add(FileManagementShareRequested(fileId, shareType));
  }

  void compressFiles(List<String> fileIds, CompressionType compressionType, String outputPath) {
    add(FileManagementCompressRequested(fileIds, compressionType, outputPath));
  }

  void sortFiles(FileSortOrder sortOrder) {
    // Implementation would update BLoC state
  }

  void changeViewMode(FileViewMode viewMode) {
    // Implementation would update BLoC state
  }
}
