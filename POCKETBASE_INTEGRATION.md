# PocketBase Integration Guide for iSuite

## 🚀 **Why PocketBase is Perfect for iSuite**

PocketBase is an **open-source, self-hosted backend** that's ideal for file management applications:

### **Key Benefits**
- **Single Executable**: Just download and run - no complex setup
- **Built-in File Storage**: Native file handling with metadata
- **Real-time Database**: Live updates across all connected clients
- **SQLite Backend**: Perfect for file metadata and indexing
- **Cross-Platform**: Runs on Windows, Linux, macOS
- **MIT License**: Completely free and open source
- **Lightweight**: <10MB executable, minimal resource usage

## 📦 **Quick Setup**

### **1. Download PocketBase**
```bash
# Windows
curl -L https://github.com/pocketbase/pocketbase/releases/download/v0.22.20/pocketbase_0.22.20_windows_amd64.zip -o pocketbase.zip

# Linux
curl -L https://github.com/pocketbase/pocketbase/releases/download/v0.22.20/pocketbase_0.22.20_linux_amd64.zip -o pocketbase.zip

# macOS
curl -L https://github.com/pocketbase/pocketbase/releases/download/v0.22.20/pocketbase_0.22.20_darwin_amd64.zip -o pocketbase.zip
```

### **2. Extract and Run**
```bash
unzip pocketbase.zip
cd pocketbase
./pocketbase serve
```

### **3. Access Admin Panel**
Open http://localhost:8090/_/ in your browser

## 🔧 **Integration with iSuite**

### **Add PocketBase Dependency**
```yaml
# pubspec.yaml
dependencies:
  pocketbase: ^0.10.0+1
  http: ^1.2.0
  path_provider: ^2.1.0
```

### **Create PocketBase Service**
```dart
// lib/core/services/pocketbase_service.dart
import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  late final PocketBase _client;
  bool _isConnected = false;

  Future<void> initialize() async {
    _client = PocketBase('http://localhost:8090');
    
    // Test connection
    try {
      await _client.collection('files').getList(1, 1);
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      throw Exception('Failed to connect to PocketBase: $e');
    }
  }

  bool get isConnected => _isConnected;
  PocketBase get client => _client;
}
```

### **File Management Service**
```dart
// lib/core/services/file_service.dart
import '../models/file_model.dart';
import 'pocketbase_service.dart';

class FileService {
  final PocketBaseService _pb = PocketBaseService();

  // Get all files with real-time updates
  Stream<List<FileModel>> getFilesStream() {
    return _pb.client.collection('files').subscribe('*').map((event) {
      return event.records.map((record) => FileModel.fromPocketBase(record)).toList();
    });
  }

  // Get files with pagination
  Future<List<FileModel>> getFiles({int page = 1, int limit = 50}) async {
    final result = await _pb.client.collection('files').getList(page: page, perPage: limit);
    return result.items.map((record) => FileModel.fromPocketBase(record)).toList();
  }

  // Upload file with progress
  Future<String> uploadFile(File file, {Map<String, dynamic>? metadata}) async {
    final fileBytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;
    
    final record = await _pb.client.collection('files').create(
      body: {
        'name': fileName,
        'size': fileBytes.length,
        'type': _getFileType(fileName),
        'created_at': DateTime.now().toIso8601String(),
        ...?metadata,
      },
      files: [HttpFile('file', fileBytes, fileName)],
    );
    
    return record.id;
  }

  // Download file
  Future<File> downloadFile(String fileId, String localPath) async {
    final record = await _pb.client.collection('files').getOne(fileId);
    final fileUrl = _pb.client.files.getUrl(record, record.data['file']);
    
    final response = await http.get(Uri.parse(fileUrl));
    final file = File(localPath);
    await file.writeAsBytes(response.bodyBytes);
    
    return file;
  }

  // Delete file
  Future<void> deleteFile(String fileId) async {
    await _pb.client.collection('files').delete(fileId);
  }

  // Search files
  Future<List<FileModel>> searchFiles(String query) async {
    final result = await _pb.client.collection('files').getFullList(
      filter: 'name ~ "$query" || description ~ "$query"',
    );
    return result.map((record) => FileModel.fromPocketBase(record)).toList();
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
        return 'document';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'flac':
        return 'audio';
      default:
        return 'other';
    }
  }
}
```

### **File Model for PocketBase**
```dart
// lib/core/models/file_model.dart
import 'package:pocketbase/pocketbase.dart';

class FileModel {
  final String id;
  final String name;
  final int size;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final List<String> tags;
  final bool isEncrypted;
  final String? fileUrl;

  FileModel({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.tags = const [],
    this.isEncrypted = false,
    this.fileUrl,
  });

  factory FileModel.fromPocketBase(RecordModel record) {
    return FileModel(
      id: record.id,
      name: record.data['name'] ?? '',
      size: record.data['size'] ?? 0,
      type: record.data['type'] ?? 'other',
      createdAt: DateTime.parse(record.data['created_at']),
      updatedAt: DateTime.parse(record.data['updated_at']),
      description: record.data['description'],
      tags: List<String>.from(record.data['tags'] ?? []),
      isEncrypted: record.data['is_encrypted'] ?? false,
      fileUrl: record.data['file'] != null 
          ? 'http://localhost:8090/api/files/files/${record.id}/${record.data['file']}'
          : null,
    );
  }

  FileModel copyWith({
    String? id,
    String? name,
    int? size,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    List<String>? tags,
    bool? isEncrypted,
    String? fileUrl,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }
}
```

## 🗄️ **Database Schema**

### **Files Collection**
```json
{
  "name": "files",
  "type": "base",
  "schema": [
    {
      "name": "name",
      "type": "text",
      "required": true
    },
    {
      "name": "size",
      "type": "number",
      "required": true
    },
    {
      "name": "type",
      "type": "select",
      "required": true,
      "options": {
        "values": ["image", "document", "video", "audio", "other"]
      }
    },
    {
      "name": "description",
      "type": "text"
    },
    {
      "name": "tags",
      "type": "relation",
      "options": {
        "collectionId": "tags",
        "maxSelect": 10
      }
    },
    {
      "name": "is_encrypted",
      "type": "bool",
      "default": false
    },
    {
      "name": "file",
      "type": "file",
      "required": true,
      "options": {
        "maxSelect": 1,
        "maxSize": 104857600
      }
    }
  ]
}
```

### **Tags Collection**
```json
{
  "name": "tags",
  "type": "base",
  "schema": [
    {
      "name": "name",
      "type": "text",
      "required": true,
      "unique": true
    },
    {
      "name": "color",
      "type": "text",
      "default": "#1976D2"
    }
  ]
}
```

## 🔐 **Authentication Integration**

### **User Authentication**
```dart
// lib/core/services/auth_service.dart
class AuthService {
  final PocketBaseService _pb = PocketBaseService();

  // Login
  Future<void> login(String email, String password) async {
    await _pb.client.collection('users').authWithPassword(email, password);
  }

  // Register
  Future<void> register(String email, String password, String name) async {
    await _pb.client.collection('users').create(
      body: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
      },
    );
    await login(email, password);
  }

  // Logout
  Future<void> logout() async {
    _pb.client.authStore.clear();
  }

  // Get current user
  User? get currentUser {
    if (_pb.client.authStore.isValid) {
      return User.fromPocketBase(_pb.client.authStore.model);
    }
    return null;
  }

  // Auth state stream
  Stream<bool> get authStateStream {
    return _pb.client.authStore.onChange.map((_) => _pb.client.authStore.isValid);
  }
}
```

## 📱 **Provider Integration**

### **Updated FileProvider**
```dart
// lib/presentation/providers/file_provider.dart
class FileProvider extends ChangeNotifier implements ParameterizedComponent {
  final FileService _fileService = FileService();
  final AuthService _authService = AuthService();
  
  List<FileModel> _files = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<FileModel>>? _filesSubscription;

  FileProvider() {
    _initializeFromConfig();
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Listen to real-time updates
      _filesSubscription = _fileService.getFilesStream().listen((files) {
        _files = files;
        _isLoading = false;
        _error = null;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to initialize file service: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _filesSubscription?.cancel();
    super.dispose();
  }

  // Upload file
  Future<void> uploadFile(File file, {Map<String, dynamic>? metadata}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _fileService.uploadFile(file, metadata: metadata);
    } catch (e) {
      _error = 'Failed to upload file: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete file
  Future<void> deleteFile(String fileId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _fileService.deleteFile(fileId);
    } catch (e) {
      _error = 'Failed to delete file: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search files
  Future<List<FileModel>> searchFiles(String query) async {
    try {
      return await _fileService.searchFiles(query);
    } catch (e) {
      _error = 'Search failed: $e';
      return [];
    }
  }

  // Getters
  List<FileModel> get files => _files;
  bool get isLoading => _isLoading;
  String? get error => _error;
}
```

## 🚀 **Deployment**

### **Production Setup**
```bash
# 1. Download PocketBase
wget https://github.com/pocketbase/pocketbase/releases/download/v0.22.20/pocketbase_0.22.20_linux_amd64.zip

# 2. Extract
unzip pocketbase_0.22.20_linux_amd64.zip
cd pocketbase

# 3. Create data directory
mkdir data

# 4. Set up SSL (optional)
./pocketbase ssl --domain yourdomain.com

# 5. Run in production mode
./pocketbase serve --http=0.0.0.0:8080
```

### **Docker Deployment**
```dockerfile
# Dockerfile
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /pb

RUN wget https://github.com/pocketbase/pocketbase/releases/download/v0.22.20/pocketbase_0.22.20_linux_amd64.zip
RUN unzip pocketbase_0.22.20_linux_amd64.zip

EXPOSE 8090

CMD ["./pocketbase", "serve", "--http=0.0.0.0:8090"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  pocketbase:
    build: .
    ports:
      - "8090:8090"
    volumes:
      - ./data:/pb/pb_data
    restart: unless-stopped
```

## 📊 **Performance Optimizations**

### **File Upload with Progress**
```dart
class FileUploadService {
  Future<String> uploadFileWithProgress(
    File file, {
    Function(double)? onProgress,
    Map<String, dynamic>? metadata,
  }) async {
    final fileBytes = await file.readAsBytes();
    final chunkSize = 1024 * 1024; // 1MB chunks
    final totalChunks = (fileBytes.length / chunkSize).ceil();

    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = (i + 1) * chunkSize;
      final chunk = fileBytes.sublist(start, end > fileBytes.length ? fileBytes.length : end);
      
      // Upload chunk
      // Update progress
      onProgress?.call((i + 1) / totalChunks);
    }

    return 'file_id';
  }
}
```

### **Caching Strategy**
```dart
class FileCacheService {
  final Map<String, Uint8List> _cache = {};
  final int _maxCacheSize = 100 * 1024 * 1024; // 100MB

  Future<Uint8List?> getCachedFile(String fileId) async {
    return _cache[fileId];
  }

  Future<void> cacheFile(String fileId, Uint8List bytes) async {
    if (_cache.length * bytes.length > _maxCacheSize) {
      _clearOldestCache();
    }
    _cache[fileId] = bytes;
  }

  void _clearOldestCache() {
    // Implement LRU cache eviction
  }
}
```

## 🔧 **Migration Guide**

### **From Current System to PocketBase**
```dart
// lib/core/services/migration_service.dart
class MigrationService {
  final FileService _newService = FileService();
  final LegacyFileService _oldService = LegacyFileService();

  Future<void> migrateAllFiles() async {
    final oldFiles = await _oldService.getAllFiles();
    
    for (final oldFile in oldFiles) {
      try {
        final file = File(oldFile.path);
        await _newService.uploadFile(file, metadata: {
          'description': oldFile.description,
          'tags': oldFile.tags,
          'is_encrypted': oldFile.isEncrypted,
        });
      } catch (e) {
        print('Failed to migrate file ${oldFile.name}: $e');
      }
    }
  }
}
```

This PocketBase integration provides iSuite with a **modern, efficient, and scalable backend** that's perfect for file management applications while maintaining the open-source and self-hosted philosophy.
