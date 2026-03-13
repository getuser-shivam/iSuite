import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/central_parameterized_config.dart';
import '../logging/enhanced_logger.dart';
import 'enhanced_supabase_service.dart';

/// Supabase Repository Interface
/// 
/// Defines the contract for Supabase data operations
/// Architecture: Repository pattern, interface segregation
/// Purpose: Clean separation of concerns, testability
abstract class ISupabaseRepository {
  Future<SupabaseResponse> getUsers({List<String>? columns, String? filter});
  Future<SupabaseResponse> getUserById(String id);
  Future<SupabaseResponse> createUser(Map<String, dynamic> userData);
  Future<SupabaseResponse> updateUser(String id, Map<String, dynamic> userData);
  Future<SupabaseResponse> deleteUser(String id);
  
  Future<SupabaseResponse> getFiles({List<String>? columns, String? filter});
  Future<SupabaseResponse> getFileById(String id);
  Future<SupabaseResponse> createFile(Map<String, dynamic> fileData);
  Future<SupabaseResponse> updateFile(String id, Map<String, dynamic> fileData);
  Future<SupabaseResponse> deleteFile(String id);
  
  Future<SupabaseResponse> getNetworkDevices({List<String>? columns, String? filter});
  Future<SupabaseResponse> createNetworkDevice(Map<String, dynamic> deviceData);
  Future<SupabaseResponse> updateNetworkDevice(String id, Map<String, dynamic> deviceData);
  Future<SupabaseResponse> deleteNetworkDevice(String id);
  
  Future<SupabaseResponse> getFileTransfers({List<String>? columns, String? filter});
  Future<SupabaseResponse> createFileTransfer(Map<String, dynamic> transferData);
  Future<SupabaseResponse> updateFileTransfer(String id, Map<String, dynamic> transferData);
  Future<SupabaseResponse> deleteFileTransfer(String id);
  
  Stream<List<Map<String, dynamic>>> watchFiles();
  Stream<List<Map<String, dynamic>>> watchNetworkDevices();
  Stream<List<Map<String, dynamic>>> watchFileTransfers();
}

/// Supabase Repository Implementation
/// 
/// Implements the Supabase repository with proper organization
/// Features: CRUD operations, caching, error handling, real-time subscriptions
/// Performance: Optimized queries, connection pooling, caching
/// Architecture: Repository pattern, service layer, error handling
class SupabaseRepository implements ISupabaseRepository {
  final EnhancedSupabaseService _supabaseService;
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheTimeout = Duration(minutes: 5);
  
  SupabaseRepository(this._supabaseService);
  
  // User Operations
  @override
  Future<SupabaseResponse> getUsers({List<String>? columns, String? filter}) async {
    return await _supabaseService.query(
      'users',
      columns: columns,
      filter: filter,
      useCache: true,
    );
  }
  
  @override
  Future<SupabaseResponse> getUserById(String id) async {
    return await _supabaseService.query(
      'users',
      filter: 'id=eq.$id',
      useCache: true,
    );
  }
  
  @override
  Future<SupabaseResponse> createUser(Map<String, dynamic> userData) async {
    // Add timestamps
    userData['created_at'] = DateTime.now().toIso8601String();
    userData['updated_at'] = DateTime.now().toIso8601String();
    
    return await _supabaseService.insert('users', userData);
  }
  
  @override
  Future<SupabaseResponse> updateUser(String id, Map<String, dynamic> userData) async {
    userData['updated_at'] = DateTime.now().toIso8601String();
    
    return await _supabaseService.update('users', userData, 'id=eq.$id');
  }
  
  @override
  Future<SupabaseResponse> deleteUser(String id) async {
    return await _supabaseService.delete('users', 'id=eq.$id');
  }
  
  // File Operations
  @override
  Future<SupabaseResponse> getFiles({List<String>? columns, String? filter}) async {
    return await _supabaseService.query(
      'files',
      columns: columns,
      filter: filter,
      orderBy: 'created_at.desc',
      useCache: true,
    );
  }
  
  @override
  Future<SupabaseResponse> getFileById(String id) async {
    return await _supabaseService.query(
      'files',
      filter: 'id=eq.$id',
      useCache: true,
    );
  }
  
  @override
  Future<SupabaseResponse> createFile(Map<String, dynamic> fileData) async {
    // Add timestamps
    fileData['created_at'] = DateTime.now().toIso8601String();
    fileData['updated_at'] = DateTime.now().toIso8601String();
    
    // Set default values
    fileData['status'] = fileData['status'] ?? 'active';
    fileData['size'] = fileData['size'] ?? 0;
    
    return await _supabaseService.insert('files', fileData);
  }
  
  @override
  Future<SupabaseResponse> updateFile(String id, Map<String, dynamic> fileData) async {
    fileData['updated_at'] = DateTime.now().toIso8601String();
    
    return await _supabaseService.update('files', fileData, 'id=eq.$id');
  }
  
  @override
  Future<SupabaseResponse> deleteFile(String id) async {
    return await _supabaseService.delete('files', 'id=eq.$id');
  }
  
  // Network Device Operations
  @override
  Future<SupabaseResponse> getNetworkDevices({List<String>? columns, String? filter}) async {
    return await _supabaseService.query(
      'network_devices',
      columns: columns,
      filter: filter,
      orderBy: 'last_seen.desc',
      useCache: true,
    );
  }
  
  @override
  Future<SupabaseResponse> createNetworkDevice(Map<String, dynamic> deviceData) async {
    // Add timestamps
    deviceData['created_at'] = DateTime.now().toIso8601String();
    deviceData['updated_at'] = DateTime.now().toIso8601String();
    deviceData['last_seen'] = DateTime.now().toIso8601String();
    
    // Set default values
    deviceData['status'] = deviceData['status'] ?? 'online';
    deviceData['connection_type'] = deviceData['connection_type'] ?? 'unknown';
    
    return await _supabaseService.insert('network_devices', deviceData);
  }
  
  @override
  Future<SupabaseResponse> updateNetworkDevice(String id, Map<String, dynamic> deviceData) async {
    deviceData['updated_at'] = DateTime.now().toIso8601String();
    deviceData['last_seen'] = DateTime.now().toIso8601String();
    
    return await _supabaseService.update('network_devices', deviceData, 'id=eq.$id');
  }
  
  @override
  Future<SupabaseResponse> deleteNetworkDevice(String id) async {
    return await _supabaseService.delete('network_devices', 'id=eq.$id');
  }
  
  // File Transfer Operations
  @override
  Future<SupabaseResponse> getFileTransfers({List<String>? columns, String? filter}) async {
    return await _supabaseService.query(
      'file_transfers',
      columns: columns,
      filter: filter,
      orderBy: 'created_at.desc',
      useCache: true,
    );
  }
  
  @override
  Future<SupabaseResponse> createFileTransfer(Map<String, dynamic> transferData) async {
    // Add timestamps
    transferData['created_at'] = DateTime.now().toIso8601String();
    transferData['updated_at'] = DateTime.now().toIso8601String();
    
    // Set default values
    transferData['status'] = transferData['status'] ?? 'pending';
    transferData['progress'] = transferData['progress'] ?? 0.0;
    transferData['bytes_transferred'] = transferData['bytes_transferred'] ?? 0;
    
    return await _supabaseService.insert('file_transfers', transferData);
  }
  
  @override
  Future<SupabaseResponse> updateFileTransfer(String id, Map<String, dynamic> transferData) async {
    transferData['updated_at'] = DateTime.now().toIso8601String();
    
    return await _supabaseService.update('file_transfers', transferData, 'id=eq.$id');
  }
  
  @override
  Future<SupabaseResponse> deleteFileTransfer(String id) async {
    return await _supabaseService.delete('file_transfers', 'id=eq.$id');
  }
  
  // Real-time Subscriptions
  @override
  Stream<List<Map<String, dynamic>>> watchFiles() {
    final controller = StreamController<List<Map<String, dynamic>>.broadcast();
    
    final channel = _supabaseService.subscribeToTable('files', onEvent: (payload) {
      if (payload.eventType == 'INSERT' || payload.eventType == 'UPDATE' || payload.eventType == 'DELETE') {
        _loadFiles().then((response) {
          if (response.success && response.data != null) {
            controller.add(List<Map<String, dynamic>>.from(response.data));
          }
        });
      }
    });
    
    // Initial load
    _loadFiles().then((response) {
      if (response.success && response.data != null) {
        controller.add(List<Map<String, dynamic>>.from(response.data));
      }
    });
    
    return controller.stream;
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchNetworkDevices() {
    final controller = StreamController<List<Map<String, dynamic>>.broadcast();
    
    final channel = _supabaseService.subscribeToTable('network_devices', onEvent: (payload) {
      if (payload.eventType == 'INSERT' || payload.eventType == 'UPDATE' || payload.eventType == 'DELETE') {
        _loadNetworkDevices().then((response) {
          if (response.success && response.data != null) {
            controller.add(List<Map<String, dynamic>>.from(response.data));
          }
        });
      }
    });
    
    // Initial load
    _loadNetworkDevices().then((response) {
      if (response.success && response.data != null) {
        controller.add(List<Map<String, dynamic>>.from(response.data));
      }
    });
    
    return controller.stream;
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchFileTransfers() {
    final controller = StreamController<List<Map<String, dynamic>>.broadcast();
    
    final channel = _supabaseService.subscribeToTable('file_transfers', onEvent: (payload) {
      if (payload.eventType == 'INSERT' || payload.eventType == 'UPDATE' || payload.eventType == 'DELETE') {
        _loadFileTransfers().then((response) {
          if (response.success && response.data != null) {
            controller.add(List<Map<String, dynamic>>.from(response.data));
          }
        });
      }
    });
    
    // Initial load
    _loadFileTransfers().then((response) {
      if (response.success && response.data != null) {
        controller.add(List<Map<String, dynamic>>.from(response.data));
      }
    });
    
    return controller.stream;
  }
  
  // Helper methods
  Future<SupabaseResponse> _loadFiles() async {
    return await getFiles();
  }
  
  Future<SupabaseResponse> _loadNetworkDevices() async {
    return await getNetworkDevices();
  }
  
  Future<SupabaseResponse> _loadFileTransfers() async {
    return await getFileTransfers();
  }
}

/// Supabase User Repository
/// 
/// Specialized repository for user operations
/// Features: User CRUD, authentication, profile management
/// Performance: Optimized queries, caching
/// Architecture: Repository pattern, single responsibility
class SupabaseUserRepository implements ISupabaseRepository {
  final SupabaseRepository _repository;
  
  SupabaseUserRepository(this._repository);
  
  // User-specific operations
  Future<SupabaseResponse> getUserProfile(String userId) async {
    return await _repository.getUsers(
      columns: ['id', 'email', 'name', 'avatar_url', 'created_at', 'updated_at'],
      filter: 'id=eq.$userId',
    );
  }
  
  Future<SupabaseResponse> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    return await _repository.updateUser(userId, profileData);
  }
  
  Future<SupabaseResponse> getUserFiles(String userId) async {
    return await _repository.getFiles(
      columns: ['id', 'name', 'path', 'size', 'type', 'created_at'],
      filter: 'user_id=eq.$userId',
    );
  }
  
  Future<SupabaseResponse> createUserFile(String userId, Map<String, dynamic> fileData) async {
    fileData['user_id'] = userId;
    return await _repository.createFile(fileData);
  }
  
  // Implement interface methods
  @override
  Future<SupabaseResponse> getUsers({List<String>? columns, String? filter}) {
    return _repository.getUsers(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> getUserById(String id) {
    return _repository.getUserById(id);
  }
  
  @override
  Future<SupabaseResponse> createUser(Map<String, dynamic> userData) {
    return _repository.createUser(userData);
  }
  
  @override
  Future<SupabaseResponse> updateUser(String id, Map<String, dynamic> userData) {
    return _repository.updateUser(id, userData);
  }
  
  @override
  Future<SupabaseResponse> deleteUser(String id) {
    return _repository.deleteUser(id);
  }
  
  @override
  Future<SupabaseResponse> getFiles({List<String>? columns, String? filter}) {
    return _repository.getFiles(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> getFileById(String id) {
    return _repository.getFileById(id);
  }
  
  @override
  Future<SupabaseResponse> createFile(Map<String, dynamic> fileData) {
    return _repository.createFile(fileData);
  }
  
  @override
  Future<SupabaseResponse> updateFile(String id, Map<String, dynamic> fileData) {
    return _repository.updateFile(id, fileData);
  }
  
  @override
  Future<SupabaseResponse> deleteFile(String id) {
    return _repository.deleteFile(id);
  }
  
  @override
  Future<SupabaseResponse> getNetworkDevices({List<String>? columns, String? filter}) {
    return _repository.getNetworkDevices(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> createNetworkDevice(Map<String, dynamic> deviceData) {
    return _repository.createNetworkDevice(deviceData);
  }
  
  @override
  Future<SupabaseResponse> updateNetworkDevice(String id, Map<String, dynamic> deviceData) {
    return _repository.updateNetworkDevice(id, deviceData);
  }
  
  @override
  Future<SupabaseResponse> deleteNetworkDevice(String id) {
    return _repository.deleteNetworkDevice(id);
  }
  
  @override
  Future<SupabaseResponse> getFileTransfers({List<String>? columns, String? filter}) {
    return _repository.getFileTransfers(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> createFileTransfer(Map<String, dynamic> transferData) {
    return _repository.createFileTransfer(transferData);
  }
  
  @override
  Future<SupabaseResponse> updateFileTransfer(String id, Map<String, dynamic> transferData) {
    return _repository.updateFileTransfer(id, transferData);
  }
  
  @override
  Future<SupabaseResponse> deleteFileTransfer(String id) {
    return _repository.deleteFileTransfer(id);
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchFiles() {
    return _repository.watchFiles();
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchNetworkDevices() {
    return _repository.watchNetworkDevices();
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchFileTransfers() {
    return _repository.watchFileTransfers();
  }
}

/// Supabase File Repository
/// 
/// Specialized repository for file operations
/// Features: File CRUD, metadata management, storage operations
/// Performance: Optimized queries, caching, batch operations
/// Architecture: Repository pattern, single responsibility
class SupabaseFileRepository implements ISupabaseRepository {
  final SupabaseRepository _repository;
  final EnhancedSupabaseService _supabaseService;
  
  SupabaseFileRepository(this._repository, this._supabaseService);
  
  // File-specific operations
  Future<SupabaseResponse> getFileMetadata(String fileId) async {
    return await _repository.getFiles(
      columns: ['id', 'name', 'path', 'size', 'type', 'mime_type', 'checksum', 'created_at', 'updated_at'],
      filter: 'id=eq.$fileId',
    );
  }
  
  Future<SupabaseResponse> updateFileMetadata(String fileId, Map<String, dynamic> metadata) async {
    return await _repository.updateFile(fileId, metadata);
  }
  
  Future<SupabaseResponse> uploadFile(String bucket, String path, Uint8List fileBytes, Map<String, dynamic> fileData) async {
    // Upload to storage
    final uploadResponse = await _supabaseService.uploadFile(bucket, path, fileBytes, metadata: {
      'content_type': fileData['mime_type'],
      'file_name': fileData['name'],
    });
    
    if (!uploadResponse.success) {
      return uploadResponse;
    }
    
    // Create database record
    fileData['storage_bucket'] = bucket;
    fileData['storage_path'] = path;
    fileData['storage_url'] = _supabaseService.getPublicUrl(bucket, path);
    
    return await _repository.createFile(fileData);
  }
  
  Future<SupabaseResponse> downloadFile(String bucket, String path) async {
    return await _supabaseService.downloadFile(bucket, path);
  }
  
  Future<SupabaseResponse> deleteFileAndStorage(String bucket, String path, String fileId) async {
    // Delete from storage
    final storageResponse = await _supabaseService.storage.from(bucket).remove([path]);
    
    if (storageResponse.error != null) {
      return SupabaseResponse.error('Storage deletion failed: ${storageResponse.error!.message}');
    }
    
    // Delete from database
    return await _repository.deleteFile(fileId);
  }
  
  // Batch operations
  Future<List<SupabaseResponse>> createMultipleFiles(List<Map<String, dynamic>> filesData) async {
    final responses = <SupabaseResponse>[];
    
    for (final fileData in filesData) {
      final response = await _repository.createFile(fileData);
      responses.add(response);
    }
    
    return responses;
  }
  
  // Search operations
  Future<SupabaseResponse> searchFiles(String query, {String? userId}) async {
    String filter = 'name.ilike.%$query%';
    if (userId != null) {
      filter += 'and user_id=eq.$userId';
    }
    
    return await _repository.getFiles(filter: filter);
  }
  
  // Implement interface methods
  @override
  Future<SupabaseResponse> getUsers({List<String>? columns, String? filter}) {
    return _repository.getUsers(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> getUserById(String id) {
    return _repository.getUserById(id);
  }
  
  @override
  Future<SupabaseResponse> createUser(Map<String, dynamic> userData) {
    return _repository.createUser(userData);
  }
  
  @override
  Future<SupabaseResponse> updateUser(String id, Map<String, dynamic> userData) {
    return _repository.updateUser(id, userData);
  }
  
  @override
  Future<SupabaseResponse> deleteUser(String id) {
    return _repository.deleteUser(id);
  }
  
  @override
  Future<SupabaseResponse> getFiles({List<String>? columns, String? filter}) {
    return _repository.getFiles(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> getFileById(String id) {
    return _repository.getFileById(id);
  }
  
  @override
  Future<SupabaseResponse> createFile(Map<String, dynamic> fileData) {
    return _repository.createFile(fileData);
  }
  
  @override
  Future<SupabaseResponse> updateFile(String id, Map<String, dynamic> fileData) {
    return _repository.updateFile(id, fileData);
  }
  
  @override
  Future<SupabaseResponse> deleteFile(String id) {
    return _repository.deleteFile(id);
  }
  
  @override
  Future<SupabaseResponse> getNetworkDevices({List<String>? columns, String? filter}) {
    return _repository.getNetworkDevices(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> createNetworkDevice(Map<String, dynamic> deviceData) {
    return _repository.createNetworkDevice(deviceData);
  }
  
  @override
  Future<SupabaseResponse> updateNetworkDevice(String id, Map<String, dynamic> deviceData) {
    return _repository.updateNetworkDevice(id, deviceData);
  }
  
  @override
  Future<SupabaseResponse> deleteNetworkDevice(String id) {
    return _repository.deleteNetworkDevice(id);
  }
  
  @override
  Future<SupabaseResponse> getFileTransfers({List<String>? columns, String? filter}) {
    return _repository.getFileTransfers(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> createFileTransfer(Map<String, dynamic> transferData) {
    return _repository.createFileTransfer(transferData);
  }
  
  @override
  Future<SupabaseResponse> updateFileTransfer(String id, Map<String, dynamic> transferData) {
    return _repository.updateFileTransfer(id, transferData);
  }
  
  @override
  Future<SupabaseResponse> deleteFileTransfer(String id) {
    return _repository.deleteFileTransfer(id);
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchFiles() {
    return _repository.watchFiles();
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchNetworkDevices() {
    return _repository.watchNetworkDevices();
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchFileTransfers() {
    return _repository.watchFileTransfers();
  }
}

/// Supabase Network Repository
/// 
/// Specialized repository for network device operations
/// Features: Device CRUD, connection management, discovery
/// Performance: Optimized queries, real-time updates
/// Architecture: Repository pattern, single responsibility
class SupabaseNetworkRepository implements ISupabaseRepository {
  final SupabaseRepository _repository;
  
  SupabaseNetworkRepository(this._repository);
  
  // Network-specific operations
  Future<SupabaseResponse> getOnlineDevices() async {
    return await _repository.getNetworkDevices(
      filter: 'status=eq.online',
    );
  }
  
  Future<SupabaseResponse> getDevicesByType(String type) async {
    return await _repository.getNetworkDevices(
      filter: 'connection_type=eq.$type',
    );
  }
  
  Future<SupabaseResponse> updateDeviceStatus(String deviceId, String status) async {
    return await _repository.updateNetworkDevice(deviceId, {
      'status': status,
      'last_seen': DateTime.now().toIso8601String(),
    });
  }
  
  Future<SupabaseResponse> updateDeviceConnectionInfo(String deviceId, Map<String, dynamic> connectionInfo) async {
    return await _repository.updateNetworkDevice(deviceId, {
      ...connectionInfo,
      'last_seen': DateTime.now().toIso8601String(),
    });
  }
  
  // Device discovery
  Future<SupabaseResponse> discoverDevices() async {
    return await _repository.getNetworkDevices(
      columns: ['id', 'name', 'type', 'address', 'connection_type', 'status', 'last_seen'],
      filter: 'status=eq.online',
    );
  }
  
  // Connection management
  Future<SupabaseResponse> recordConnection(String deviceId, Map<String, dynamic> connectionData) async {
    return await _repository.createNetworkDevice({
      ...connectionData,
      'id': deviceId,
      'status': 'connected',
      'connected_at': DateTime.now().toIso8601String(),
    });
  }
  
  Future<SupabaseResponse> recordDisconnection(String deviceId) async {
    return await _repository.updateNetworkDevice(deviceId, {
      'status': 'disconnected',
      'disconnected_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Implement interface methods
  @override
  Future<SupabaseResponse> getUsers({List<String>? columns, String? filter}) {
    return _repository.getUsers(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> getUserById(String id) {
    return _repository.getUserById(id);
  }
  
  @override
  Future<SupabaseResponse> createUser(Map<String, dynamic> userData) {
    return _repository.createUser(userData);
  }
  
  @override
  Future<SupabaseResponse> updateUser(String id, Map<String, dynamic> userData) {
    return _repository.updateUser(id, userData);
  }
  
  @override
  Future<SupabaseResponse> deleteUser(String id) {
    return _repository.deleteUser(id);
  }
  
  @override
  Future<SupabaseResponse> getFiles({List<String>? columns, String? filter}) {
    return _repository.getFiles(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> getFileById(String id) {
    return _repository.getFileById(id);
  }
  
  @override
  Future<SupabaseResponse> createFile(Map<String, dynamic> fileData) {
    return _repository.createFile(fileData);
  }
  
  @override
  Future<SupabaseResponse> updateFile(String id, Map<String, dynamic> fileData) {
    return _repository.updateFile(id, fileData);
  }
  
  @override
  Future<SupabaseResponse> deleteFile(String id) {
    return _repository.deleteFile(id);
  }
  
  @override
  Future<SupabaseResponse> getNetworkDevices({List<String>? columns, String? filter}) {
    return _repository.getNetworkDevices(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> createNetworkDevice(Map<String, dynamic> deviceData) {
    return _repository.createNetworkDevice(deviceData);
  }
  
  @override
  Future<SupabaseResponse> updateNetworkDevice(String id, Map<String, dynamic> deviceData) {
    return _repository.updateNetworkDevice(id, deviceData);
  }
  
  @override
  Future<SupabaseResponse> deleteNetworkDevice(String id) {
    return _repository.deleteNetworkDevice(id);
  }
  
  @override
  Future<SupabaseResponse> getFileTransfers({List<String>? columns, String? filter}) {
    return _repository.getFileTransfers(columns: columns, filter: filter);
  }
  
  @override
  Future<SupabaseResponse> createFileTransfer(Map<String, dynamic> transferData) {
    return _repository.createFileTransfer(transferData);
  }
  
  @override
  Future<SupabaseResponse> updateFileTransfer(String id, Map<String, dynamic> transferData) {
    return _repository.updateFileTransfer(id, transferData);
  }
  
  @override
  Future<SupabaseResponse> deleteFileTransfer(String id) {
    return _repository.deleteFileTransfer(id);
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchFiles() {
    return _repository.watchFiles();
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchNetworkDevices() {
    return _repository.watchNetworkDevices();
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watchFileTransfers() {
    return _repository.watchFileTransfers();
  }
}

/// Repository Factory
/// 
/// Creates and manages repository instances
/// Features: Singleton pattern, dependency injection, lazy initialization
/// Performance: Lazy loading, connection pooling
/// Architecture: Factory pattern, service locator
class SupabaseRepositoryFactory {
  static SupabaseRepositoryFactory? _instance;
  static SupabaseRepositoryFactory get instance => _instance ??= SupabaseRepositoryFactory._internal();
  SupabaseRepositoryFactory._internal();
  
  final Map<Type, dynamic> _repositories = {};
  
  T getRepository<T extends ISupabaseRepository>() {
    return _repositories[T] as T;
  }
  
  // Create repositories
  SupabaseRepository createGeneralRepository() {
    return _repositories.putIfAbsent(
      SupabaseRepository,
      () => SupabaseRepository(EnhancedSupabaseService.instance),
    ) as SupabaseRepository;
  }
  
  SupabaseUserRepository createUserRepository() {
    return _repositories.putIfAbsent(
      SupabaseUserRepository,
      () => SupabaseUserRepository(createGeneralRepository()),
    ) as SupabaseUserRepository;
  }
  
  SupabaseFileRepository createFileRepository() {
    return _repositories.putIfAbsent(
      SupabaseFileRepository,
      () => SupabaseFileRepository(createGeneralRepository(), EnhancedSupabaseService.instance),
    ) as SupabaseFileRepository;
  }
  
  SupabaseNetworkRepository createNetworkRepository() {
    return _repositories.putIfAbsent(
      SupabaseNetworkRepository,
      () => SupabaseNetworkRepository(createGeneralRepository()),
    ) as SupabaseNetworkRepository;
  }
  
  // Dispose all repositories
  void dispose() {
    _repositories.clear();
  }
}

/// Global repository getter for easy access
SupabaseRepositoryFactory getSupabaseRepositoryFactory() {
  return SupabaseRepositoryFactory.instance;
}

/// Global repository getters for easy access
SupabaseRepository getSupabaseRepository() {
  return getSupabaseRepositoryFactory().createGeneralRepository();
}

SupabaseUserRepository getSupabaseUserRepository() {
  return getSupabaseRepositoryFactory().createUserRepository();
}

SupabaseFileRepository getSupabaseFileRepository() {
  return getSupabaseRepositoryFactory().createFileRepository();
}

SupabaseNetworkRepository getSupabaseNetworkRepository() {
  return getSupabaseRepositoryFactory().createNetworkRepository();
}
