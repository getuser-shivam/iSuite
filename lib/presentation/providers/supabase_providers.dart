import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/backend/enhanced_supabase_service.dart';
import '../../core/backend/supabase_repository.dart';
import '../providers/config_provider.dart';

/// Supabase Configuration Provider
/// 
/// Manages Supabase configuration and state
/// Features: Configuration management, connection status, authentication state
/// Performance: Optimized state updates, efficient configuration access
/// Architecture: Provider pattern, state management, reactive updates
class SupabaseConfigurationProvider extends ChangeNotifier {
  final EnhancedSupabaseService _supabaseService;
  final CentralParameterizedConfig _config;
  
  // State
  bool _isConfigured = false;
  bool _isConnected = false;
  bool _isAuthenticated = false;
  String? _configurationError;
  String? _connectionError;
  Map<String, dynamic> _configuration = {};
  
  SupabaseConfigurationProvider({
    required EnhancedSupabaseService supabaseService,
    required CentralParameterizedConfig config,
  }) : _supabaseService = supabaseService,
       _config = config {
    
    // Load configuration
    _loadConfiguration();
    
    // Setup listeners
    _setupListeners();
  }
  
  // Getters
  bool get isConfigured => _isConfigured;
  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;
  String? get configurationError => _configurationError;
  String? get connectionError => _connectionError;
  Map<String, dynamic> get configuration => Map.unmodifiable(_configuration);
  
  // Supabase service getters
  String? get currentUserId => _supabaseService._currentUserId;
  User? get currentUser => _supabaseService.currentUser;
  Session? get currentSession => _supabaseService.currentSession;
  
  /// Load Supabase configuration
  void _loadConfiguration() {
    try {
      _configuration = {
        'url': _config.getParameter('supabase.url', defaultValue: ''),
        'anon_key': _config.getParameter('supabase.anon_key', defaultValue: ''),
        'database_url': _config.getParameter('supabase.database_url', defaultValue: ''),
        'storage_url': _config.getParameter('supabase.storage_url', defaultValue: ''),
        'functions_url': _config.getParameter('supabase.functions_url', defaultValue: ''),
        'enable_auth': _config.getParameter('supabase.enable_auth', defaultValue: true),
        'enable_realtime': _config.getParameter('supabase.enable_realtime', defaultValue: true),
        'enable_storage': _config.getParameter('supabase.enable_storage', defaultValue: true),
        'enable_functions': _config.getParameter('supabase.enable_functions', defaultValue: true),
        'cache_timeout': _config.getParameter('supabase.cache_timeout', defaultValue: 300),
        'connection_timeout': _config.getParameter('supabase.connection_timeout', defaultValue: 30),
      };
      
      // Check if configuration is valid
      _isConfigured = _validateConfiguration();
      
      if (_isConfigured) {
        _initializeSupabase();
      }
      
      notifyListeners();
    } catch (e) {
      _configurationError = e.toString();
      notifyListeners();
    }
  }
  
  /// Validate Supabase configuration
  bool _validateConfiguration() {
    final url = _configuration['url'] as String?;
    final anonKey = _configuration['anon_key'] as String?;
    
    return url != null && url.isNotEmpty && 
           anonKey != null && anonKey.isNotEmpty &&
           url.startsWith('https://');
  }
  
  /// Initialize Supabase service
  Future<void> _initializeSupabase() async {
    try {
      await _supabaseService.initialize();
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _connectionError = e.toString();
      notifyListeners();
    }
  }
  
  /// Setup event listeners
  void _setupListeners() {
    // Listen to Supabase events
    _supabaseService.events.listen((event) {
      _handleSupabaseEvent(event);
    });
    
    // Listen to configuration changes
    _config.configurationEvents.listen((event) {
      if (event.type == ConfigurationEventType.parameterChanged && 
          event.key.startsWith('supabase.')) {
        _loadConfiguration();
      }
    });
  }
  
  /// Handle Supabase events
  void _handleSupabaseEvent(SupabaseEvent event) {
    switch (event.type) {
      case SupabaseEventType.initialized:
        _isConnected = true;
        notifyListeners();
        break;
      case SupabaseEventType.signInSuccess:
        _isAuthenticated = true;
        notifyListeners();
        break;
      case SupabaseEventType.signOutSuccess:
        _isAuthenticated = false;
        notifyListeners();
        break;
      case SupabaseEventType.error:
        _connectionError = event.error;
        notifyListeners();
        break;
      default:
        break;
    }
  }
  
  /// Update configuration
  Future<bool> updateConfiguration(Map<String, dynamic> newConfig) async {
    try {
      for (final entry in newConfig.entries) {
        await _config.setParameter(entry.key, entry.value);
      }
      
      _loadConfiguration();
      return true;
    } catch (e) {
      _configurationError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Test connection
  Future<bool> testConnection() async {
    try {
      if (!_isConfigured) {
        return false;
      }
      
      await _supabaseService._testConnection();
      _isConnected = true;
      _connectionError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _connectionError = e.toString();
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Clear errors
  void clearErrors() {
    _configurationError = null;
    _connectionError = null;
    notifyListeners();
  }
}

/// Supabase Authentication Provider
/// 
/// Manages Supabase authentication state and operations
/// Features: Authentication, user management, session handling
/// Performance: Optimized state updates, efficient authentication
/// Architecture: Provider pattern, state management, reactive updates
class SupabaseAuthenticationProvider extends ChangeNotifier {
  final EnhancedSupabaseService _supabaseService;
  
  // State
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _authError;
  User? _currentUser;
  Session? _currentSession;
  
  SupabaseAuthenticationProvider({
    required EnhancedSupabaseService supabaseService,
  }) : _supabaseService = supabaseService {
    
    // Setup listeners
    _setupListeners();
    
    // Check current authentication state
    _checkAuthState();
  }
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get authError => _authError;
  User? get currentUser => _currentUser;
  Session? get currentSession => _currentSession;
  
  /// Setup event listeners
  void _setupListeners() {
    _supabaseService.events.listen((event) {
      _handleSupabaseEvent(event);
    });
  }
  
  /// Check current authentication state
  void _checkAuthState() {
    _currentUser = _supabaseService.currentUser;
    _currentSession = _supabaseService.currentSession;
    _isAuthenticated = _currentUser != null;
    notifyListeners();
  }
  
  /// Handle Supabase events
  void _handleSupabaseEvent(SupabaseEvent event) {
    switch (event.type) {
      case SupabaseEventType.signInSuccess:
        _isAuthenticated = true;
        _authError = null;
        _checkAuthState();
        break;
      case SupabaseEventType.signOutSuccess:
        _isAuthenticated = false;
        _authError = null;
        _checkAuthState();
        break;
      case SupabaseEventType.signInError:
      case SupabaseEventType.signUpError:
      case SupabaseEventType.signOutError:
        _authError = event.error;
        _isLoading = false;
        notifyListeners();
        break;
      default:
        break;
    }
  }
  
  /// Sign up with email and password
  Future<bool> signUp(String email, String password, {Map<String, dynamic>? metadata}) async {
    try {
      _isLoading = true;
      _authError = null;
      notifyListeners();
      
      final response = await _supabaseService.signUp(email, password, metadata: metadata);
      
      _isLoading = false;
      notifyListeners();
      
      return response.success;
    } catch (e) {
      _isLoading = false;
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _authError = null;
      notifyListeners();
      
      final response = await _supabaseService.signIn(email, password);
      
      _isLoading = false;
      notifyListeners();
      
      return response.success;
    } catch (e) {
      _isLoading = false;
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Sign in with OAuth provider
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      _isLoading = true;
      _authError = null;
      notifyListeners();
      
      final response = await _supabaseService.signInWithOAuth(provider);
      
      _isLoading = false;
      notifyListeners();
      
      return response.success;
    } catch (e) {
      _isLoading = false;
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Sign out
  Future<bool> signOut() async {
    try {
      _isLoading = true;
      _authError = null;
      notifyListeners();
      
      final response = await _supabaseService.signOut();
      
      _isLoading = false;
      notifyListeners();
      
      return response.success;
    } catch (e) {
      _isLoading = false;
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Clear error
  void clearError() {
    _authError = null;
    notifyListeners();
  }
}

/// Supabase Data Provider
/// 
/// Manages Supabase data operations and state
/// Features: Data CRUD, caching, real-time updates, error handling
/// Performance: Optimized queries, efficient state management
/// Architecture: Provider pattern, repository pattern, reactive updates
class SupabaseDataProvider extends ChangeNotifier {
  final SupabaseRepository _repository;
  
  // State
  bool _isLoading = false;
  String? _dataError;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _files = [];
  List<Map<String, dynamic>> _networkDevices = [];
  List<Map<String, dynamic>> _fileTransfers = [];
  
  // Streams
  StreamSubscription<List<Map<String, dynamic>>>? _filesSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _networkDevicesSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _fileTransfersSubscription;
  
  SupabaseDataProvider({
    required SupabaseRepository repository,
  }) : _repository = repository {
    
    // Setup real-time subscriptions
    _setupRealtimeSubscriptions();
  }
  
  // Getters
  bool get isLoading => _isLoading;
  String? get dataError => _dataError;
  List<Map<String, dynamic>> get users => List.unmodifiable(_users);
  List<Map<String, dynamic>> get files => List.unmodifiable(_files);
  List<Map<String, dynamic>> get networkDevices => List.unmodifiable(_networkDevices);
  List<Map<String, dynamic>> get fileTransfers => List.unmodifiable(_fileTransfers);
  
  /// Setup real-time subscriptions
  void _setupRealtimeSubscriptions() {
    // Files subscription
    _filesSubscription = _repository.watchFiles().listen((data) {
      _files = data;
      notifyListeners();
    });
    
    // Network devices subscription
    _networkDevicesSubscription = _repository.watchNetworkDevices().listen((data) {
      _networkDevices = data;
      notifyListeners();
    });
    
    // File transfers subscription
    _fileTransfersSubscription = _repository.watchFileTransfers().listen((data) {
      _fileTransfers = data;
      notifyListeners();
    });
  }
  
  /// Load all data
  Future<void> loadAllData() async {
    try {
      _isLoading = true;
      _dataError = null;
      notifyListeners();
      
      await Future.wait([
        loadUsers(),
        loadFiles(),
        loadNetworkDevices(),
        loadFileTransfers(),
      ]);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _dataError = e.toString();
      notifyListeners();
    }
  }
  
  /// Load users
  Future<void> loadUsers() async {
    try {
      final response = await _repository.getUsers();
      if (response.success && response.data != null) {
        _users = List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      _dataError = e.toString();
    }
  }
  
  /// Load files
  Future<void> loadFiles() async {
    try {
      final response = await _repository.getFiles();
      if (response.success && response.data != null) {
        _files = List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      _dataError = e.toString();
    }
  }
  
  /// Load network devices
  Future<void> loadNetworkDevices() async {
    try {
      final response = await _repository.getNetworkDevices();
      if (response.success && response.data != null) {
        _networkDevices = List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      _dataError = e.toString();
    }
  }
  
  /// Load file transfers
  Future<void> loadFileTransfers() async {
    try {
      final response = await _repository.getFileTransfers();
      if (response.success && response.data != null) {
        _fileTransfers = List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      _dataError = e.toString();
    }
  }
  
  /// Create file
  Future<bool> createFile(Map<String, dynamic> fileData) async {
    try {
      final response = await _repository.createFile(fileData);
      return response.success;
    } catch (e) {
      _dataError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Update file
  Future<bool> updateFile(String id, Map<String, dynamic> fileData) async {
    try {
      final response = await _repository.updateFile(id, fileData);
      return response.success;
    } catch (e) {
      _dataError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Delete file
  Future<bool> deleteFile(String id) async {
    try {
      final response = await _repository.deleteFile(id);
      return response.success;
    } catch (e) {
      _dataError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Create network device
  Future<bool> createNetworkDevice(Map<String, dynamic> deviceData) async {
    try {
      final response = await _repository.createNetworkDevice(deviceData);
      return response.success;
    } catch (e) {
      _dataError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Update network device
  Future<bool> updateNetworkDevice(String id, Map<String, dynamic> deviceData) async {
    try {
      final response = await _repository.updateNetworkDevice(id, deviceData);
      return response.success;
    } catch (e) {
      _dataError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Delete network device
  Future<bool> deleteNetworkDevice(String id) async {
    try {
      final response = await _repository.deleteNetworkDevice(id);
      return response.success;
    } catch (e) {
      _dataError = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Clear error
  void clearError() {
    _dataError = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _filesSubscription?.cancel();
    _networkDevicesSubscription?.cancel();
    _fileTransfersSubscription?.cancel();
    super.dispose();
  }
}

/// Provider instances
final supabaseConfigurationProvider = ChangeNotifierProvider<SupabaseConfigurationProvider>((ref) {
  final configProvider = ref.watch(configurationProvider);
  return SupabaseConfigurationProvider(
    supabaseService: EnhancedSupabaseService.instance,
    config: configProvider._config,
  );
});

final supabaseAuthenticationProvider = ChangeNotifierProvider<SupabaseAuthenticationProvider>((ref) {
  return SupabaseAuthenticationProvider(
    supabaseService: EnhancedSupabaseService.instance,
  );
});

final supabaseDataProvider = ChangeNotifierProvider<SupabaseDataProvider>((ref) {
  return SupabaseDataProvider(
    repository: getSupabaseRepository(),
  );
});
