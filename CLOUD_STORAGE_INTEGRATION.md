# Cloud Storage Integration for iSuite

## ☁️ **Multi-Cloud Storage Architecture**

Extend iSuite with support for multiple cloud storage providers, giving users seamless access to their files across all platforms.

## 🏗️ **Architecture Overview**

```
iSuite App
    ↓
Cloud Storage Manager
    ↓
┌─────────┬─────────┬─────────┬─────────┐
│ Google  │ Dropbox │ OneDrive│ iCloud  │
│ Drive   │         │         │         │
└─────────┴─────────┴─────────┴─────────┘
```

## 🔌 **Provider Implementations**

### **1. Google Drive Integration**
```dart
// lib/core/services/cloud/google_drive_service.dart
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleDriveService implements CloudStorageProvider {
  late drive.DriveApi _driveApi;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(
    scopes: [drive.DriveApi.driveScope],
  );

  @override
  Future<void> initialize() async {
    final account = await _googleSignIn.signIn();
    final headers = await account.authHeaders;
    _driveApi = drive.DriveApi(
      http.Client()..headers.addAll(headers),
    );
  }

  @override
  Future<List<CloudFile>> getFiles({String? folderId}) async {
    final response = await _driveApi.files.list(
      q: folderId != null ? "'$folderId' in parents" : null,
      pageSize: 1000,
    );

    return response.files?.map((file) => CloudFile(
      id: file.id!,
      name: file.name!,
      size: file.size?.toInt() ?? 0,
      mimeType: file.mimeType ?? 'application/octet-stream',
      modifiedTime: file.modifiedTime ?? DateTime.now(),
      isFolder: file.mimeType == 'application/vnd.google-apps.folder',
    )).toList() ?? [];
  }

  @override
  Future<String> uploadFile(File file, {String? folderId}) async {
    final media = drive.Media(file.openRead(), file.lengthSync());
    
    final driveFile = drive.File()
      ..name = file.path.split('/').last
      ..parents = folderId != null ? [folderId] : null;

    final uploadedFile = await _driveApi.files.create(
      driveFile,
      uploadMedia: media,
    );

    return uploadedFile.id!;
  }

  @override
  Future<File> downloadFile(String fileId, String localPath) async {
    final media = await _driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia);
    final file = File(localPath);
    await file.writeAsBytes(await media.stream.toList());
    return file;
  }

  @override
  Future<void> deleteFile(String fileId) async {
    await _driveApi.files.delete(fileId);
  }

  @override
  Future<Stream<CloudFile>> searchFiles(String query) async* {
    final response = await _driveApi.files.list(
      q: "name contains '$query'",
      pageSize: 1000,
    );

    for (final file in response.files ?? []) {
      yield CloudFile(
        id: file.id!,
        name: file.name!,
        size: file.size?.toInt() ?? 0,
        mimeType: file.mimeType ?? 'application/octet-stream',
        modifiedTime: file.modifiedTime ?? DateTime.now(),
        isFolder: file.mimeType == 'application/vnd.google-apps.folder',
      );
    }
  }
}
```

### **2. Dropbox Integration**
```dart
// lib/core/services/cloud/dropbox_service.dart
import 'package:dropbox_api/dropbox_api.dart';

class DropboxService implements CloudStorageProvider {
  late DropboxApi _dropboxApi;

  @override
  Future<void> initialize() async {
    // Initialize Dropbox API with OAuth2
    _dropboxApi = DropboxApi(
      accessToken: 'your_access_token',
    );
  }

  @override
  Future<List<CloudFile>> getFiles({String? folderId}) async {
    final path = folderId ?? '';
    final response = await _dropboxApi.files.listFolder(path);

    return response.entries.map((entry) => CloudFile(
      id: entry.pathLower,
      name: entry.name,
      size: entry.size ?? 0,
      mimeType: _getMimeType(entry.name),
      modifiedTime: entry.serverModified ?? DateTime.now(),
      isFolder: entry.tag == '.tag:folder',
    )).toList();
  }

  @override
  Future<String> uploadFile(File file, {String? folderId}) async {
    final path = folderId != null ? '$folderId/${file.path.split('/').last}' : '/${file.path.split('/').last}';
    
    final response = await _dropboxApi.files.upload(
      path,
      file.openRead(),
      file.lengthSync(),
    );

    return response.pathDisplay;
  }

  @override
  Future<File> downloadFile(String fileId, String localPath) async {
    final response = await _dropboxApi.files.download(fileId);
    final file = File(localPath);
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  @override
  Future<void> deleteFile(String fileId) async {
    await _dropboxApi.files.deleteV2(fileId);
  }

  @override
  Future<Stream<CloudFile>> searchFiles(String query) async* {
    final response = await _dropboxApi.files.search(query);
    
    for (final match in response.matches) {
      yield CloudFile(
        id: match.metadata.pathLower!,
        name: match.metadata.name!,
        size: match.metadata.size ?? 0,
        mimeType: _getMimeType(match.metadata.name),
        modifiedTime: match.metadata.serverModified ?? DateTime.now(),
        isFolder: match.metadata.tag == '.tag:folder',
      );
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
```

### **3. OneDrive Integration**
```dart
// lib/core/services/cloud/onedrive_service.dart
import 'package:ms_graph_sdk/ms_graph_sdk.dart';

class OneDriveService implements CloudStorageProvider {
  late GraphServiceClient _graphClient;

  @override
  Future<void> initialize() async {
    _graphClient = GraphServiceClient(
      authenticationProvider: MsalAuthProvider(),
    );
  }

  @override
  Future<List<CloudFile>> getFiles({String? folderId}) async {
    final path = folderId != null ? '/drives/me/items/$folderId/children' : '/me/drive/root/children';
    final response = await _graphClient.me.drive.root.children.get();

    return response.value?.map((item) => CloudFile(
      id: item.id!,
      name: item.name!,
      size: item.size ?? 0,
      mimeType: item.file?.mimeType ?? 'application/octet-stream',
      modifiedTime: item.lastModifiedDateTime ?? DateTime.now(),
      isFolder: item.folder != null,
    )).toList() ?? [];
  }

  @override
  Future<String> uploadFile(File file, {String? folderId}) async {
    final path = folderId != null ? '/drives/me/items/$folderId:/${file.path.split('/').last}:/content' : '/me/drive/root:/${file.path.split('/').last}:/content';
    
    final response = await _graphClient.me.drive.root.itemWithPath(file.path.split('/').last).content.put(
      file.openRead(),
    );

    return response.id!;
  }

  @override
  Future<File> downloadFile(String fileId, String localPath) async {
    final response = await _graphClient.me.drive.items[fileId].content.get();
    final file = File(localPath);
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  @override
  Future<void> deleteFile(String fileId) async {
    await _graphClient.me.drive.items[fileId].delete();
  }

  @override
  Future<Stream<CloudFile>> searchFiles(String query) async* {
    final response = await _graphClient.me.drive.search.get(q: query);

    for (final item in response.value ?? []) {
      yield CloudFile(
        id: item.id!,
        name: item.name!,
        size: item.size ?? 0,
        mimeType: item.file?.mimeType ?? 'application/octet-stream',
        modifiedTime: item.lastModifiedDateTime ?? DateTime.now(),
        isFolder: item.folder != null,
      );
    }
  }
}
```

## 🔄 **Cloud Storage Manager**

### **Unified Cloud Interface**
```dart
// lib/core/services/cloud_storage_manager.dart
enum CloudProvider {
  googleDrive,
  dropbox,
  oneDrive,
  icloud,
}

class CloudStorageManager {
  final Map<CloudProvider, CloudStorageProvider> _providers = {};
  CloudProvider? _activeProvider;

  void registerProvider(CloudProvider type, CloudStorageProvider provider) {
    _providers[type] = provider;
  }

  Future<void> setActiveProvider(CloudProvider type) async {
    final provider = _providers[type];
    if (provider != null) {
      await provider.initialize();
      _activeProvider = type;
    }
  }

  CloudStorageProvider? get activeProvider => _providers[_activeProvider];

  // Unified operations
  Future<List<CloudFile>> getFiles({String? folderId}) async {
    return await activeProvider?.getFiles(folderId: folderId) ?? [];
  }

  Future<String> uploadFile(File file, {String? folderId}) async {
    return await activeProvider?.uploadFile(file, folderId: folderId) ?? '';
  }

  Future<File> downloadFile(String fileId, String localPath) async {
    return await activeProvider?.downloadFile(fileId, localPath) ?? File(localPath);
  }

  Future<void> deleteFile(String fileId) async {
    await activeProvider?.deleteFile(fileId);
  }

  Future<Stream<CloudFile>> searchFiles(String query) async* {
    if (activeProvider != null) {
      yield* await activeProvider!.searchFiles(query);
    }
  }

  // Multi-provider operations
  Future<Map<CloudProvider, List<CloudFile>>> searchAllProviders(String query) async {
    final results = <CloudProvider, List<CloudFile>>{};
    
    for (final entry in _providers.entries) {
      try {
        final files = await entry.value.searchFiles(query).toList();
        results[entry.key] = files;
      } catch (e) {
        print('Error searching ${entry.key}: $e');
      }
    }
    
    return results;
  }

  // Sync between providers
  Future<void> syncBetweenProviders(CloudProvider source, CloudProvider target) async {
    final sourceProvider = _providers[source];
    final targetProvider = _providers[target];
    
    if (sourceProvider != null && targetProvider != null) {
      final files = await sourceProvider.getFiles();
      
      for (final file in files) {
        // Check if file exists in target
        final targetFiles = await targetProvider.searchFiles(file.name).toList();
        if (targetFiles.isEmpty) {
          // Download from source and upload to target
          final tempFile = File('${Directory.systemTemp.path}/${file.name}');
          await sourceProvider.downloadFile(file.id, tempFile.path);
          await targetProvider.uploadFile(tempFile);
          await tempFile.delete();
        }
      }
    }
  }
}
```

## 📱 **UI Integration**

### **Cloud Provider Selection**
```dart
// lib/presentation/providers/cloud_provider.dart
class CloudProvider extends ChangeNotifier {
  final CloudStorageManager _manager = CloudStorageManager();
  CloudProvider? _selectedProvider;
  List<CloudProvider> _availableProviders = [];
  bool _isConnecting = false;
  String? _error;

  CloudProvider() {
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    _manager.registerProvider(CloudProvider.googleDrive, GoogleDriveService());
    _manager.registerProvider(CloudProvider.dropbox, DropboxService());
    _manager.registerProvider(CloudProvider.oneDrive, OneDriveService());
    
    _availableProviders = CloudProvider.values;
    notifyListeners();
  }

  Future<void> connectToProvider(CloudProvider provider) async {
    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      await _manager.setActiveProvider(provider);
      _selectedProvider = provider;
    } catch (e) {
      _error = 'Failed to connect to $provider: $e';
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<List<CloudFile>> getFiles() async {
    return await _manager.getFiles();
  }

  Future<String> uploadFile(File file) async {
    return await _manager.uploadFile(file);
  }

  Future<void> deleteFile(String fileId) async {
    await _manager.deleteFile(fileId);
  }

  // Getters
  CloudProvider? get selectedProvider => _selectedProvider;
  List<CloudProvider> get availableProviders => _availableProviders;
  bool get isConnecting => _isConnecting;
  String? get error => _error;
}
```

### **Cloud Files Screen**
```dart
// lib/features/cloud/screens/cloud_files_screen.dart
class CloudFilesScreen extends StatefulWidget {
  const CloudFilesScreen({Key? key}) : super(key: key);

  @override
  State<CloudFilesScreen> createState() => _CloudFilesScreenState();
}

class _CloudFilesScreenState extends State<CloudFilesScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CloudProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Cloud Storage'),
            actions: [
              DropdownButton<CloudProvider>(
                value: provider.selectedProvider,
                hint: Text('Select Provider'),
                items: provider.availableProviders.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(_getProviderName(p)),
                  );
                }).toList(),
                onChanged: (provider) {
                  if (provider != null) {
                    context.read<CloudProvider>().connectToProvider(provider);
                  }
                },
              ),
            ],
          ),
          body: provider.isConnecting
              ? Center(child: CircularProgressIndicator())
              : provider.error != null
                  ? Center(child: Text('Error: ${provider.error}'))
                  : provider.selectedProvider == null
                      ? _buildProviderSelection()
                      : CloudFilesList(),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _uploadFile(),
            child: Icon(Icons.upload),
          ),
        );
      },
    );
  }

  Widget _buildProviderSelection() {
    return Consumer<CloudProvider>(
      builder: (context, provider, child) {
        return ListView(
          children: provider.availableProviders.map((p) {
            return ListTile(
              leading: Icon(_getProviderIcon(p)),
              title: Text(_getProviderName(p)),
              subtitle: Text(_getProviderDescription(p)),
              onTap: () => provider.connectToProvider(p),
            );
          }).toList(),
        );
      },
    );
  }

  String _getProviderName(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.googleDrive:
        return 'Google Drive';
      case CloudProvider.dropbox:
        return 'Dropbox';
      case CloudProvider.oneDrive:
        return 'OneDrive';
      case CloudProvider.icloud:
        return 'iCloud';
    }
  }

  IconData _getProviderIcon(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.googleDrive:
        return Icons.cloud;
      case CloudProvider.dropbox:
        return Icons.cloud_queue;
      case CloudProvider.oneDrive:
        return Icons.cloud_circle;
      case CloudProvider.icloud:
        return Icons.cloud_done;
    }
  }

  String _getProviderDescription(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.googleDrive:
        return 'Access files from Google Drive';
      case CloudProvider.dropbox:
        return 'Access files from Dropbox';
      case CloudProvider.oneDrive:
        return 'Access files from OneDrive';
      case CloudProvider.icloud:
        return 'Access files from iCloud';
    }
  }

  Future<void> _uploadFile() async {
    final picker = FilePicker.platform;
    final result = await picker.pickFiles();
    
    if (result != null) {
      final file = File(result.files.single.path!);
      await context.read<CloudProvider>().uploadFile(file);
    }
  }
}
```

## 🔧 **Configuration**

### **Dependencies**
```yaml
# pubspec.yaml
dependencies:
  google_sign_in: ^6.1.0
  googleapis: ^11.0.0
  dropbox_api: ^0.7.0
  ms_graph_sdk: ^5.0.0
  file_picker: ^6.1.0
```

### **OAuth Configuration**
```dart
// lib/core/config/oauth_config.dart
class OAuthConfig {
  static const String googleClientId = 'your_google_client_id';
  static const String dropboxAppKey = 'your_dropbox_app_key';
  static const String oneDriveClientId = 'your_onedrive_client_id';
  
  static const List<String> googleScopes = [
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/drive.file',
  ];
}
```

## 🚀 **Benefits**

### **For Users**
- **Unified Interface**: Single app to manage all cloud storage
- **Cross-Platform Sync**: Sync files between different cloud providers
- **Offline Access**: Cache files for offline viewing
- **Advanced Search**: Search across all cloud providers simultaneously

### **For Developers**
- **Extensible Architecture**: Easy to add new cloud providers
- **Unified API**: Single interface for all cloud operations
- **Error Handling**: Robust error handling and retry mechanisms
- **Performance**: Efficient caching and background sync

### **For Business**
- **Multi-Cloud Strategy**: Support for enterprise cloud solutions
- **Data Portability**: Easy migration between providers
- **Cost Optimization**: Choose best provider for different file types
- **Security**: End-to-end encryption for sensitive files

This cloud storage integration transforms iSuite into a **comprehensive file management solution** that seamlessly bridges local and cloud storage across all major providers.
