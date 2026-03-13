import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/config/central_parameterized_config.dart';
import '../../core/ai/ai_file_organizer.dart';
import '../../core/ai/ai_advanced_search.dart';
import '../../core/ai/smart_file_categorizer.dart';
import '../../core/ai/ai_duplicate_detector.dart';
import '../../core/ai/ai_file_recommendations.dart';
import '../../core/network/enhanced_network_file_sharing.dart';
import '../../core/network/advanced_ftp_client.dart';
import '../../core/network/wifi_direct_p2p_service.dart';
import '../../core/network/webdav_client.dart';
import '../../core/network/network_discovery_service.dart';
import '../../core/network/network_security_service.dart';
import '../../core/network/network_file_sharing_integration.dart';
import '../../core/backend/enhanced_pocketbase_service.dart';
import '../providers/config_provider.dart';

/// File Management Provider
/// 
/// Manages file operations and AI services
/// Features: File organization, search, categorization, duplicate detection
/// Performance: Optimized file operations, background processing
/// Architecture: Provider pattern, service integration, state management
class FileManagementProvider extends ChangeNotifier {
  final CentralParameterizedConfig _config;
  final AIFileOrganizer _aiFileOrganizer;
  final AIAdvancedSearch _aiAdvancedSearch;
  final SmartFileCategorizer _smartFileCategorizer;
  final AIDuplicateDetector _aiDuplicateDetector;
  final AIFileRecommendations _aiFileRecommendations;
  
  // State
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> _organizedFiles = [];
  List<FileSystemEntity> _searchResults = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _duplicates = [];
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  String _currentDirectory = '';
  String _searchQuery = '';
  
  FileManagementProvider({
    required CentralParameterizedConfig config,
    required AIFileOrganizer aiFileOrganizer,
    required AIAdvancedSearch aiAdvancedSearch,
    required SmartFileCategorizer smartFileCategorizer,
    required AIDuplicateDetector aiDuplicateDetector,
    required AIFileRecommendations aiFileRecommendations,
  }) : _config = config,
       _aiFileOrganizer = aiFileOrganizer,
       _aiAdvancedSearch = aiAdvancedSearch,
       _smartFileCategorizer = smartFileCategorizer,
       _aiDuplicateDetector = aiDuplicateDetector,
       _aiFileRecommendations = aiFileRecommendations;
  
  // Getters
  List<FileSystemEntity> get files => List.unmodifiable(_files);
  List<FileSystemEntity> get organizedFiles => List.unmodifiable(_organizedFiles);
  List<FileSystemEntity> get searchResults => List.unmodifiable(_searchResults);
  List<Map<String, dynamic>> get categories => List.unmodifiable(_categories);
  List<Map<String, dynamic>> get duplicates => List.unmodifiable(_duplicates);
  List<Map<String, dynamic>> get recommendations => List.unmodifiable(_recommendations);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentDirectory => _currentDirectory;
  String get searchQuery => _searchQuery;
  
  /// Load files from directory
  Future<void> loadFiles(String directoryPath) async {
    try {
      _isLoading = true;
      _error = null;
      _currentDirectory = directoryPath;
      notifyListeners();
      
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        throw Exception('Directory does not exist: $directoryPath');
      }
      
      _files = await directory.list().toList();
      
      // Sort files by name
      _files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Organize files using AI
  Future<void> organizeFiles() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (!await _aiFileOrganizer.isInitialized()) {
        await _aiFileOrganizer.initialize();
      }
      
      final result = await _aiFileOrganizer.organizeDirectory(_currentDirectory);
      
      if (result.success) {
        _organizedFiles = result.organizedFiles;
        await loadFiles(_currentDirectory); // Reload to see changes
      } else {
        _error = result.errorMessage ?? 'Organization failed';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Search files using AI
  Future<void> searchFiles(String query) async {
    try {
      _isLoading = true;
      _error = null;
      _searchQuery = query;
      notifyListeners();
      
      if (query.isEmpty) {
        _searchResults = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      if (!await _aiAdvancedSearch.isInitialized()) {
        await _aiAdvancedSearch.initialize();
      }
      
      final results = await _aiAdvancedSearch.searchFiles(
        _currentDirectory,
        query,
        includeContent: true,
      );
      
      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Categorize files using AI
  Future<void> categorizeFiles() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (!await _smartFileCategorizer.isInitialized()) {
        await _smartFileCategorizer.initialize();
      }
      
      final result = await _smartFileCategorizer.categorizeFiles(_files);
      
      _categories = result.categories;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Find duplicate files using AI
  Future<void> findDuplicates() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (!await _aiDuplicateDetector.isInitialized()) {
        await _aiDuplicateDetector.initialize();
      }
      
      final result = await _aiDuplicateDetector.findDuplicates(_files);
      
      _duplicates = result.duplicates;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Get file recommendations using AI
  Future<void> getRecommendations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (!await _aiFileRecommendations.isInitialized()) {
        await _aiFileRecommendations.initialize();
      }
      
      final result = await _aiFileRecommendations.getRecommendations(_files);
      
      _recommendations = result.recommendations;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Delete file
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        await loadFiles(_currentDirectory);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Move file
  Future<bool> moveFile(String sourcePath, String targetPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.rename(targetPath);
        await loadFiles(_currentDirectory);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Copy file
  Future<bool> copyFile(String sourcePath, String targetPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(targetPath);
        await loadFiles(_currentDirectory);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Network Management Provider
/// 
/// Manages network services and file sharing
/// Features: Network discovery, file sharing, FTP, P2P, WebDAV
/// Performance: Optimized network operations, concurrent transfers
/// Architecture: Provider pattern, service integration, state management
class NetworkManagementProvider extends ChangeNotifier {
  final CentralParameterizedConfig _config;
  final EnhancedNetworkFileSharing _networkFileSharing;
  final AdvancedFTPClient _ftpClient;
  final WiFiDirectP2PService _wifiDirectService;
  final WebDAVClient _webdavClient;
  final NetworkDiscoveryService _discoveryService;
  final NetworkSecurityService _securityService;
  final NetworkFileSharingIntegration _integration;
  
  // State
  List<Map<String, dynamic>> _discoveredDevices = [];
  List<Map<String, dynamic>> _activeConnections = [];
  List<Map<String, dynamic>> _fileTransfers = [];
  List<Map<String, dynamic>> _networkServices = [];
  bool _isScanning = false;
  bool _isSharingEnabled = false;
  bool _isLoading = false;
  String? _error;
  
  NetworkManagementProvider({
    required CentralParameterizedConfig config,
    required EnhancedNetworkFileSharing networkFileSharing,
    required AdvancedFTPClient ftpClient,
    required WiFiDirectP2PService wifiDirectService,
    required WebDAVClient webdavClient,
    required NetworkDiscoveryService discoveryService,
    required NetworkSecurityService securityService,
    required NetworkFileSharingIntegration integration,
  }) : _config = config,
       _networkFileSharing = networkFileSharing,
       _ftpClient = ftpClient,
       _wifiDirectService = wifiDirectService,
       _webdavClient = webdavClient,
       _discoveryService = discoveryService,
       _securityService = securityService,
       _integration = integration;
  
  // Getters
  List<Map<String, dynamic>> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<Map<String, dynamic>> get activeConnections => List.unmodifiable(_activeConnections);
  List<Map<String, dynamic>> get fileTransfers => List.unmodifiable(_fileTransfers);
  List<Map<String, dynamic>> get networkServices => List.unmodifiable(_networkServices);
  bool get isScanning => _isScanning;
  bool get isSharingEnabled => _isSharingEnabled;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Initialize network services
  Future<void> initializeServices() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Initialize all network services
      await _networkFileSharing.initialize();
      await _ftpClient.initialize();
      await _wifiDirectService.initialize();
      await _webdavClient.initialize();
      await _discoveryService.initialize();
      await _securityService.initialize();
      await _integration.initialize();
      
      // Load network services status
      await _loadNetworkServices();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Start network discovery
  Future<void> startDiscovery() async {
    try {
      _isScanning = true;
      _error = null;
      notifyListeners();
      
      if (!await _discoveryService.isScanning()) {
        await _discoveryService.startDiscovery();
      }
      
      // Listen for discovery events
      _discoveryService.deviceDiscoveredStream.listen((device) {
        _discoveredDevices.add(device);
        notifyListeners();
      });
      
      // Scan for 30 seconds
      Timer(const Duration(seconds: 30), () {
        _isScanning = false;
        notifyListeners();
      });
      
    } catch (e) {
      _isScanning = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Stop network discovery
  Future<void> stopDiscovery() async {
    try {
      await _discoveryService.stopDiscovery();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  /// Connect to device
  Future<bool> connectToDevice(String deviceId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final device = _discoveredDevices.firstWhere((d) => d['id'] == deviceId);
      final result = await _networkFileSharing.connectToDevice(device);
      
      if (result.success) {
        _activeConnections.add({
          'id': deviceId,
          'name': device['name'],
          'type': device['type'],
          'connected_at': DateTime.now().toIso8601String(),
        });
      } else {
        _error = result.errorMessage ?? 'Connection failed';
      }
      
      _isLoading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Disconnect from device
  Future<bool> disconnectFromDevice(String deviceId) async {
    try {
      await _networkFileSharing.disconnectFromDevice(deviceId);
      _activeConnections.removeWhere((conn) => conn['id'] == deviceId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Start file sharing
  Future<bool> startFileSharing() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _networkFileSharing.startSharing();
      
      if (result.success) {
        _isSharingEnabled = true;
      } else {
        _error = result.errorMessage ?? 'Failed to start sharing';
      }
      
      _isLoading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Stop file sharing
  Future<bool> stopFileSharing() async {
    try {
      await _networkFileSharing.stopSharing();
      _isSharingEnabled = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Transfer file
  Future<bool> transferFile(String deviceId, String filePath, String targetPath) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final transfer = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'device_id': deviceId,
        'file_path': filePath,
        'target_path': targetPath,
        'status': 'transferring',
        'progress': 0.0,
        'started_at': DateTime.now().toIso8601String(),
      };
      
      _fileTransfers.add(transfer);
      notifyListeners();
      
      final result = await _networkFileSharing.transferFile(deviceId, filePath, targetPath);
      
      // Update transfer status
      final transferIndex = _fileTransfers.indexWhere((t) => t['id'] == transfer['id']);
      if (transferIndex != -1) {
        _fileTransfers[transferIndex]['status'] = result.success ? 'completed' : 'failed';
        _fileTransfers[transferIndex]['error'] = result.errorMessage;
        _fileTransfers[transferIndex]['completed_at'] = DateTime.now().toIso8601String();
      }
      
      _isLoading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Connect to FTP server
  Future<bool> connectToFtp(String host, int port, String username, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _ftpClient.connect(host, port, username, password);
      
      if (result.success) {
        _activeConnections.add({
          'id': 'ftp_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'FTP Server',
          'type': 'ftp',
          'host': host,
          'port': port,
          'connected_at': DateTime.now().toIso8601String(),
        });
      } else {
        _error = result.errorMessage ?? 'FTP connection failed';
      }
      
      _isLoading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Connect to WebDAV server
  Future<bool> connectToWebDAV(String url, String username, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _webdavClient.connect(url, username, password);
      
      if (result.success) {
        _activeConnections.add({
          'id': 'webdav_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'WebDAV Server',
          'type': 'webdav',
          'url': url,
          'connected_at': DateTime.now().toIso8601String(),
        });
      } else {
        _error = result.errorMessage ?? 'WebDAV connection failed';
      }
      
      _isLoading = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Load network services status
  Future<void> _loadNetworkServices() async {
    try {
      _networkServices = [
        {
          'name': 'Network File Sharing',
          'type': 'file_sharing',
          'enabled': await _networkFileSharing.isEnabled(),
          'status': await _networkFileSharing.getStatus(),
        },
        {
          'name': 'FTP Client',
          'type': 'ftp',
          'enabled': await _ftpClient.isEnabled(),
          'status': await _ftpClient.getStatus(),
        },
        {
          'name': 'WiFi Direct',
          'type': 'wifi_direct',
          'enabled': await _wifiDirectService.isEnabled(),
          'status': await _wifiDirectService.getStatus(),
        },
        {
          'name': 'WebDAV Client',
          'type': 'webdav',
          'enabled': await _webdavClient.isEnabled(),
          'status': await _webdavClient.getStatus(),
        },
        {
          'name': 'Network Discovery',
          'type': 'discovery',
          'enabled': await _discoveryService.isEnabled(),
          'status': await _discoveryService.getStatus(),
        },
        {
          'name': 'Network Security',
          'type': 'security',
          'enabled': await _securityService.isEnabled(),
          'status': await _securityService.getStatus(),
        },
      ];
    } catch (e) {
      _error = e.toString();
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Provider instances
final fileManagementProvider = ChangeNotifierProvider<FileManagementProvider>((ref) {
  final config = ref.watch(configurationProvider)._config;
  final aiFileOrganizer = AIFileOrganizer.instance;
  final aiAdvancedSearch = AIAdvancedSearch.instance;
  final smartFileCategorizer = SmartFileCategorizer.instance;
  final aiDuplicateDetector = AIDuplicateDetector.instance;
  final aiFileRecommendations = AIFileRecommendations.instance;
  
  return FileManagementProvider(
    config: config,
    aiFileOrganizer: aiFileOrganizer,
    aiAdvancedSearch: aiAdvancedSearch,
    smartFileCategorizer: smartFileCategorizer,
    aiDuplicateDetector: aiDuplicateDetector,
    aiFileRecommendations: aiFileRecommendations,
  );
});

final networkManagementProvider = ChangeNotifierProvider<NetworkManagementProvider>((ref) {
  final config = ref.watch(configurationProvider)._config;
  final networkFileSharing = EnhancedNetworkFileSharing.instance;
  final ftpClient = AdvancedFTPClient.instance;
  final wifiDirectService = WiFiDirectP2PService.instance;
  final webdavClient = WebDAVClient.instance;
  final discoveryService = NetworkDiscoveryService.instance;
  final securityService = NetworkSecurityService.instance;
  final integration = NetworkFileSharingIntegration.instance;
  
  return NetworkManagementProvider(
    config: config,
    networkFileSharing: networkFileSharing,
    ftpClient: ftpClient,
    wifiDirectService: wifiDirectService,
    webdavClient: webdavClient,
    discoveryService: discoveryService,
    securityService: securityService,
    integration: integration,
  );
});
