import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ftp_connection.dart';
import '../../domain/entities/ftp_file.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../../core/services/logging_service.dart'; // Import logging service for robustness
import '../../data/repositories/ftp_repository_impl.dart';
import '../../data/datasources/ftp_datasource.dart';

/// FTP State - Presentation Layer
/// References: Riverpod state management
class FtpState {
  final FtpConnection? connection;
  final List<FtpFile> files;
  final String currentPath;
  final bool isConnected;
  final bool isLoading;
  final String? error;

  const FtpState({
    this.connection,
    this.files = const [],
    this.currentPath = '/',
    this.isConnected = false,
    this.isLoading = false,
    this.error,
  });

  FtpState copyWith({
    FtpConnection? connection,
    List<FtpFile>? files,
    String? currentPath,
    bool? isConnected,
    bool? isLoading,
    String? error,
  }) {
    return FtpState(
      connection: connection ?? this.connection,
      files: files ?? this.files,
      currentPath: currentPath ?? this.currentPath,
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// FTP State Notifier - Presentation Layer
/// References: Owlfile file operations, FileGator UI
class FtpStateNotifier extends StateNotifier<FtpState> {
  final FtpRepository _repository;

  FtpStateNotifier(this._repository) : super(const FtpState());

  Future<void> connect(FtpConnection connection) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.connect(connection);
      LoggingService.instance.info('FTP connected successfully to ${connection.host}:${connection.port}');
      state = state.copyWith(
        connection: connection,
        isConnected: true,
        isLoading: false,
      );
      await listFiles('/');
    } catch (e) {
      LoggingService.instance.error('FTP connection failed for ${connection.host}:${connection.port}: $e');
      state = state.copyWith(
        isConnected: false,
        isLoading: false,
        error: 'Failed to connect to FTP server. Check host, port, username, and password.',
      );
    }
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
    state = const FtpState();
  }

  Future<void> listFiles(String path) async {
    if (!state.isConnected) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final files = await _repository.listFiles(path);
      LoggingService.instance.info('FTP listed ${files.length} files in $path');
      state = state.copyWith(
        files: files,
        currentPath: path,
        isLoading: false,
      );
    } catch (e) {
      LoggingService.instance.error('FTP listFiles failed for $path: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to list files. Check network connection.',
      );
    }
  }

  Future<void> downloadFile(FtpFile file, String localPath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.downloadFile(file.path, localPath);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> uploadFile(String localPath, String remotePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.uploadFile(localPath, remotePath);
      await listFiles(state.currentPath); // Refresh
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createDirectory(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createDirectory('${state.currentPath}/$name');
      await listFiles(state.currentPath); // Refresh
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> delete(FtpFile file) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.delete(file.path);
      await listFiles(state.currentPath); // Refresh
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> lockFile(FtpFile file) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.lockFile(file.path);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> unlockFile(FtpFile file) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.unlockFile(file.path);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> batchDownloadCurrentDirectory(String localPath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final files = state.files.where((f) => !f.isDirectory).toList();
      await _repository.batchDownload(files, localPath);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> batchUploadFiles(List<String> localPaths) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.batchUpload(localPaths, state.currentPath);
      await listFiles(state.currentPath); // Refresh
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
