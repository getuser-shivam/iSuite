import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart' as http;
import '../../../core/central_config.dart';

/// Google Drive integration service
class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  GoogleSignInAccount? _currentUser;
  DriveApi? _driveApi;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Initialize Google Sign In
  Future<void> initialize() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initializeDriveApi();
      }
    } catch (e) {
      print('Google Drive initialization error: $e');
    }
  }

  /// Sign in to Google
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initializeDriveApi();
        _isAuthenticated = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Google sign in error: $e');
      return false;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _driveApi = null;
      _isAuthenticated = false;
    } catch (e) {
      print('Google sign out error: $e');
    }
  }

  /// Initialize Drive API
  Future<void> _initializeDriveApi() async {
    final authHeaders = await _currentUser!.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = DriveApi(authenticateClient);
    _driveApi = driveApi;
  }

  /// Generic retry mechanism
  Future<T> _retryOperation<T>(
    Future<T> Function() operation,
    int maxRetries,
    Duration delay,
  ) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay * attempts);
      }
    }
    throw Exception('Retry operation failed');
  }

  /// List files from Google Drive with retry
  Future<List<File>?> listFiles({String? folderId, int maxResults = 50}) async {
    if (_driveApi == null) return null;

    return _retryOperation(
      () async {
        final query = folderId != null ? "'$folderId' in parents" : null;
        final response = await _driveApi!.files.list(
          q: query,
          spaces: 'drive',
          pageSize: maxResults,
          orderBy: 'modifiedTime desc',
          fields: 'files(id,name,mimeType,modifiedTime,size,parents)',
        );
        return response.files;
      },
      3, // max retries
      const Duration(seconds: 1), // delay
    ).catchError((e) {
      print('Error listing files after retries: $e');
      return null;
    });
  }

  /// Upload file to Google Drive
  Future<String?> uploadFile(String filePath, String fileName, {String? folderId}) async {
    if (_driveApi == null) return null;

    try {
      final file = File();
      file.name = fileName;

      if (folderId != null) {
        file.parents = [folderId];
      }

      final media = Media(
        File(filePath).openRead(),
        await File(filePath).length(),
      );

      final response = await _driveApi.files.create(
        file,
        uploadMedia: media,
      );

      return response.id;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Download file from Google Drive
  Future<bool> downloadFile(String fileId, String destinationPath) async {
    if (_driveApi == null) return false;

    try {
      final media = await _driveApi.files.get(
        fileId,
        downloadOptions: DownloadOptions.fullMedia,
      ) as Media;

      final file = File(destinationPath);
      await file.writeAsBytes(await media.stream.toBytes());
      return true;
    } catch (e) {
      print('Error downloading file: $e');
      return false;
    }
  }

  /// Delete file from Google Drive
  Future<bool> deleteFile(String fileId) async {
    if (_driveApi == null) return false;

    try {
      await _driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Create folder in Google Drive
  Future<String?> createFolder(String folderName, {String? parentId}) async {
    if (_driveApi == null) return null;

    try {
      final folder = File();
      folder.name = folderName;
      folder.mimeType = 'application/vnd.google-apps.folder';

      if (parentId != null) {
        folder.parents = [parentId];
      }

      final response = await _driveApi.files.create(folder);
      return response.id;
    } catch (e) {
      print('Error creating folder: $e');
      return null;
    }
  }
}

/// Custom HTTP client for Google API authentication
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
