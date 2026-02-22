part of 'file_management_bloc.dart';

enum FileManagementEvent {
  fileSelected,
  filesSelected,
  fileDeselected,
  filesDeselected,
  fileOpened,
  fileDeleted,
  fileCopied,
  fileMoved,
  fileCompressed,
  fileShared,
  directoryCreated,
  directoryDeleted,
  refreshRequested,
  searchPerformed,
  filterChanged,
  sortChanged,
  viewModeChanged,
}

extension FileManagementEventExtension on FileManagementEvent {
  String get name {
    switch (this) {
      case FileManagementEvent.fileSelected:
        return 'fileSelected';
      case FileManagementEvent.filesSelected:
        return 'filesSelected';
      case FileManagementEvent.fileDeselected:
        return 'fileDeselected';
      case FileManagementEvent.filesDeselected:
        return 'filesDeselected';
      case FileManagementEvent.fileOpened:
        return 'fileOpened';
      case FileManagementEvent.fileDeleted:
        return 'fileDeleted';
      case FileManagementEvent.fileCopied:
        return 'fileCopied';
      case FileManagementEvent.fileMoved:
        return 'fileMoved';
      case FileManagementEvent.fileCompressed:
        return 'fileCompressed';
      case FileManagementEvent.fileShared:
        return 'fileShared';
      case FileManagementEvent.directoryCreated:
        return 'directoryCreated';
      case FileManagementEvent.directoryDeleted:
        return 'directoryDeleted';
      case FileManagementEvent.refreshRequested:
        return 'refreshRequested';
      case FileManagementEvent.searchPerformed:
        return 'searchPerformed';
      case FileManagementEvent.filterChanged:
        return 'filterChanged';
      case FileManagementEvent.sortChanged:
        return 'sortChanged';
      case FileManagementEvent.viewModeChanged:
        return 'viewModeChanged';
    }
  }
}
