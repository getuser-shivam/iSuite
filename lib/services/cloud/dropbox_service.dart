import 'dart:io';
import 'package:dropbox_api/dropbox_api.dart';
import '../../../core/central_config.dart';

/// Dropbox integration service
class DropboxService {
  static final DropboxService _instance = DropboxService._internal();
  factory DropboxService() => _instance;
  DropboxService._internal();

  DropboxClient? _client;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  /// Initialize Dropbox client with access token
  Future<void> initialize(String accessToken) async {
    try {
      _client = DropboxClient(accessToken);
      _isAuthenticated = true;
    } catch (e) {
      print('Dropbox initialization error: $e');
      _isAuthenticated = false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _client = null;
    _isAuthenticated = false;
  }

  /// List files from Dropbox
  Future<List<Metadata>?> listFiles({String path = '', int limit = 50}) async {
    if (_client == null) return null;

    try {
      final response = await _client!.files.listFolder(
        ListFolderArg(path: path, limit: limit),
      );

      return response.result?.entries ?? [];
    } catch (e) {
      print('Error listing Dropbox files: $e');
      return null;
    }
  }

  /// Upload file to Dropbox
  Future<String?> uploadFile(String localFilePath, String dropboxPath) async {
    if (_client == null) return null;

    try {
      final file = File(localFilePath);
      final content = await file.readAsBytes();

      final response = await _client!.files.upload(
        UploadArg(
          path: dropboxPath,
          mode: WriteMode.add(WriteModeAddArg()),
        ),
        content,
      );

      return response.result?.pathLower;
    } catch (e) {
      print('Error uploading to Dropbox: $e');
      return null;
    }
  }

  /// Download file from Dropbox
  Future<bool> downloadFile(String dropboxPath, String localFilePath) async {
    if (_client == null) return false;

    try {
      final response = await _client!.files.download(
        DownloadArg(path: dropboxPath),
      );

      final file = File(localFilePath);
      await file.writeAsBytes(response.result!.fileBinary!);
      return true;
    } catch (e) {
      print('Error downloading from Dropbox: $e');
      return false;
    }
  }

  /// Delete file from Dropbox
  Future<bool> deleteFile(String dropboxPath) async {
    if (_client == null) return false;

    try {
      await _client!.files.deleteV2(DeleteArg(path: dropboxPath));
      return true;
    } catch (e) {
      print('Error deleting Dropbox file: $e');
      return false;
    }
  }

  /// Create folder in Dropbox
  Future<String?> createFolder(String folderPath) async {
    if (_client == null) return null;

    try {
      final response = await _client!.files.createFolderV2(
        CreateFolderArg(path: folderPath),
      );

      return response.result?.metadata.pathLower;
    } catch (e) {
      print('Error creating Dropbox folder: $e');
      return null;
    }
  }

  /// Get account info
  Future<FullAccount?> getAccountInfo() async {
    if (_client == null) return null;

    try {
      final response = await _client!.users.getCurrentAccount();
      return response.result;
    } catch (e) {
      print('Error getting Dropbox account info: $e');
      return null;
    }
  }
}
