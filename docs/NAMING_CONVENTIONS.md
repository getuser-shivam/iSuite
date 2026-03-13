# iSuite Naming Conventions and Formatting Guide

## 📋 Naming Conventions

This document defines the **standard naming conventions** and **formatting rules** for the iSuite project to ensure **consistency, readability, and maintainability** across all code files.

## 🎯 General Principles

### 📋 **Consistency Rules**
- **Be Consistent**: Use the same naming convention throughout the project
- **Be Descriptive**: Names should clearly describe the purpose of the item
- **Be Concise**: Keep names short but meaningful
- **Follow Standards**: Use industry-standard conventions for each language

### 📋 **Clarity Rules**
- **Avoid Abbreviations**: Use full words unless widely understood
- **Use Meaningful Names**: Names should reveal intent
- **Avoid Generic Names**: Avoid names like `data`, `info`, `manager` unless necessary
- **Be Specific**: Use specific names that describe the exact purpose

## 📁 File and Directory Naming

### 📋 **Directory Names**
```dart
// ✅ CORRECT: Use snake_case for directories
lib/core/ai_services/
lib/core/network_services/
lib/presentation/screens/
lib/data/repositories/

// ❌ INCORRECT: Do not use camelCase or spaces
lib/core/aiServices/
lib/core/Network Services/
lib/Presentation/Screens/
```

### 📋 **File Names**
```dart
// ✅ CORRECT: Use snake_case for all files
ai_file_organizer.dart
enhanced_network_file_sharing.dart
central_parameterized_config.dart
application_orchestrator.dart

// ❌ INCORRECT: Do not use camelCase, PascalCase, or spaces
aiFileOrganizer.dart
EnhancedNetworkFileSharing.dart
application orchestrator.dart
```

### 📋 **Test File Names**
```dart
// ✅ CORRECT: Use snake_case with _test suffix
ai_file_organizer_test.dart
network_services_integration_test.dart
config_parameterization_test.dart

// ❌ INCORRECT: Do not use other patterns
AiFileOrganizerTest.dart
ai_file_organizerTest.dart
test_ai_file_organizer.dart
```

## 🐍 Dart Naming Conventions

### 📋 **Class Names**
```dart
// ✅ CORRECT: Use PascalCase for classes
class AIFileOrganizer {}
class EnhancedNetworkFileSharing {}
class CentralParameterizedConfig {}
class ApplicationOrchestrator {}

// ❌ INCORRECT: Do not use snake_case or camelCase
class ai_file_organizer {}
class enhancedNetworkFileSharing {}
class applicationOrchestrator {}
```

### 📋 **Abstract Classes**
```dart
// ✅ CORRECT: Use PascalCase, optionally start with 'Abstract' or 'Base'
abstract class AbstractService {}
abstract class BaseService {}
abstract class ComponentInterface {}

// ❌ INCORRECT: Do not use prefixes like 'I' (C# convention)
abstract class IService {}
abstract class IComponentInterface {}
```

### 📋 **Interface Names**
```dart
// ✅ CORRECT: Use PascalCase, describe capability
class FileRepository {}
class NetworkService {}
class ConfigurationProvider {}

// ❌ INCORRECT: Do not use 'I' prefix (not Dart convention)
class IFileRepository {}
class INetworkService {}
class IConfigurationProvider {}
```

### 📋 **Method Names**
```dart
// ✅ CORRECT: Use camelCase, start with verb
void initializeService() {}
String getConfigurationValue() {}
Future<bool> validateConfiguration() {}
void handleServiceEvent() {}

// ❌ INCORRECT: Do not use snake_case or PascalCase
void initialize_service() {}
String GetConfigurationValue() {}
void HandleServiceEvent() {}
```

### 📋 **Variable Names**
```dart
// ✅ CORRECT: Use camelCase, be descriptive
String configurationValue;
int maxConcurrentTasks;
bool isServiceInitialized;
List<NetworkDevice> discoveredDevices;

// ❌ INCORRECT: Do not use snake_case or unclear names
String configuration_value;
int max_concurrent_tasks;
bool service_initialized;
List<NetworkDevice> devices;
```

### 📋 **Constant Names**
```dart
// ✅ CORRECT: Use SCREAMING_SNAKE_CASE
const int MAX_FILE_SIZE = 1024 * 1024 * 100; // 100MB
const String DEFAULT_CONFIG_PATH = 'config/central_config.yaml';
const Duration DEFAULT_TIMEOUT = Duration(seconds: 30);

// ❌ INCORRECT: Do not use camelCase or lowercase
const int maxFileSize = 1024 * 1024 * 100;
const String defaultConfigPath = 'config/central_config.yaml';
const duration defaultTimeout = Duration(seconds: 30);
```

### 📋 **Private Members**
```dart
// ✅ CORRECT: Use camelCase with underscore prefix
class ServiceManager {
  String _serviceName;
  List<Service> _activeServices;
  bool _isInitialized;
  
  void _initializeService() {}
}

// ❌ INCORRECT: Do not use other patterns
class ServiceManager {
  String serviceName; // Should be private
  List<Service> activeServices; // Should be private
  bool m_isInitialized; // Not Dart convention
  
  void initializeService() {} // Should be private
}
```

### 📋 **Static Members**
```dart
// ✅ CORRECT: Use camelCase, no special prefix
class ServiceRegistry {
  static ServiceRegistry? _instance;
  static ServiceRegistry get instance => _instance ??= ServiceRegistry._internal();
  static const String DEFAULT_CONFIG_KEY = 'default';
  
  static void registerService() {}
}

// ❌ INCORRECT: Do not use 's' prefix or other patterns
class ServiceRegistry {
  static ServiceRegistry? s_instance; // Not Dart convention
  static ServiceRegistry get Instance() => _instance ??= ServiceRegistry._internal();
  static const String kDefaultConfigKey = 'default'; // Not needed
  
  static void RegisterService() {} // Should be lowercase
}
```

### 📋 **Enum Names**
```dart
// ✅ CORRECT: Use PascalCase for enum type, camelCase for values
enum ServiceState {
  uninitialized,
  initializing,
  initialized,
  error,
  disposed,
}

enum NetworkProtocol {
  ftp,
  ftps,
  sftp,
  webdav,
  smb,
}

// ❌ INCORRECT: Do not use other patterns
enum serviceState { // Should be PascalCase
  UNINITIALIZED, // Should be camelCase
  INITIALIZING,
  INITIALIZED,
}

enum NetworkProtocol {
  FTP, // Should be lowercase
  FTPS,
  SFTP,
}
```

### 📋 **Type Parameter Names**
```dart
// ✅ CORRECT: Use single letter (T, E, K, V) or descriptive names
class ServiceRegistry<T> {}
class Repository<E> {}
class Map<K, V> {}
class ConfigurationProvider<TConfig> {}

// ❌ INCORRECT: Do not use unclear abbreviations
class ServiceRegistry<TService> {}
class Repository<TEntity> {}
class Map<TKey, TValue> {}
```

## 📁 Package and Import Naming

### 📋 **Package Names**
```dart
// ✅ CORRECT: Use snake_case, be descriptive
package:isuite.core.ai_services
package:isuite.core.network_services
package:isuite.presentation.screens
package:isuite.data.repositories

// ❌ INCORRECT: Do not use camelCase or unclear names
package:isuite.core.aiServices
package:isuite.core.networkServices
package:isuite.Presentation.Screens
```

### 📋 **Import Statements**
```dart
// ✅ CORRECT: Group imports, use relative paths for internal imports
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../core/config/central_parameterized_config.dart';
import '../core/ai/ai_file_organizer.dart';
import '../core/network/enhanced_network_file_sharing.dart';

// Data imports
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

// Presentation imports
import '../screens/home_screen.dart';
import '../widgets/common/app_scaffold.dart';

// ❌ INCORRECT: Do not mix imports, use absolute paths unnecessarily
import 'dart:async';
import '../core/config/central_parameterized_config.dart';
import 'package:flutter/material.dart';
import 'package:isuite/core/ai/ai_file_organizer.dart'; // Use relative path
```

## 🏗️ Component and Service Naming

### 📋 **Service Classes**
```dart
// ✅ CORRECT: Use descriptive names with service type suffix
class AIFileOrganizerService {}
class NetworkFileSharingService {}
class ConfigurationManagementService {}
class PerformanceMonitoringService {}

// ❌ INCORRECT: Do not use generic or unclear names
class AIFileService {} // Too generic
class NetworkService {} // Too generic
class ConfigManager {} // Not descriptive enough
```

### 📋 **Manager Classes**
```dart
// ✅ CORRECT: Use descriptive names with Manager suffix
class ServiceRegistryManager {}
class ComponentLifecycleManager {}
class ConfigurationValidationManager {}
class PerformanceOptimizationManager {}

// ❌ INCORRECT: Do not use unclear names
class ServiceManager {} // Too generic
class ComponentManager {} // Not specific enough
class ConfigManager {} // Not descriptive
```

### 📋 **Provider Classes**
```dart
// ✅ CORRECT: Use descriptive names with Provider suffix
class ConfigurationProvider {}
class AuthenticationProvider {}
class NetworkServiceProvider {}
class StateManagementProvider {}

// ❌ INCORRECT: Do not use unclear names
class ConfigProvider {} // Not descriptive enough
class AuthProvider {} // Use full name
class NetworkProvider {} // Too generic
```

### 📋 **Handler Classes**
```dart
// ✅ CORRECT: Use descriptive names with Handler suffix
class EventHandler {}
class ConfigurationChangeHandler {}
class NetworkConnectionHandler {}
class FileOperationHandler {}

// ❌ INCORRECT: Do not use unclear names
class EventManager {} // Should be Handler
class ConfigHandler {} // Use full name
class ConnectionHandler {} // Not specific enough
```

## 📱 UI Component Naming

### 📋 **Screen Classes**
```dart
// ✅ CORRECT: Use descriptive names with Screen suffix
class HomeScreen {}
class FileManagementScreen {}
class NetworkSharingScreen {}
class SettingsScreen {}

// ❌ INCORRECT: Do not use unclear names
class Home {} // Should be HomeScreen
class FileManagement {} // Should be FileManagementScreen
class Network {} // Should be NetworkSharingScreen
```

### 📋 **Widget Classes**
```dart
// ✅ CORRECT: Use descriptive names with Widget suffix
class FileListWidget {}
class NetworkStatusWidget {}
class ConfigurationFormWidget {}
class ActionButtonWidget {}

// ❌ INCORRECT: Do not use unclear names
class FileList {} // Should be FileListWidget
class NetworkStatus {} // Should be NetworkStatusWidget
class ConfigForm {} // Should be ConfigurationFormWidget
```

### 📋 **Provider Classes (Riverpod)**
```dart
// ✅ CORRECT: Use descriptive names with Provider suffix
class ConfigurationNotifier extends ChangeNotifier {}
class AuthenticationNotifier extends ChangeNotifier {}
class NetworkStateNotifier extends StateNotifier<NetworkState> {}

// Provider instances
final configurationProvider = ChangeNotifierProvider((ref) => ConfigurationNotifier());
final authenticationProvider = ChangeNotifierProvider((ref) => AuthenticationNotifier());
final networkStateProvider = StateNotifierProvider<NetworkStateNotifier, NetworkState>((ref) => NetworkStateNotifier());

// ❌ INCORRECT: Do not use unclear names
class ConfigNotifier extends ChangeNotifier {} // Use full name
class AuthNotifier extends ChangeNotifier {} // Use full name
final configProvider = ChangeNotifierProvider((ref) => ConfigNotifier()); // Use full name
```

## 📝 Documentation and Comments

### 📋 **Class Documentation**
```dart
// ✅ CORRECT: Use proper dartdoc format
/// AI File Organizer Service
/// 
/// Provides intelligent file organization capabilities including:
/// - Automatic file categorization
/// - Smart folder structure creation
/// - Content-based file analysis
/// - Learning-based organization patterns
/// 
/// Example usage:
/// ```dart
/// final organizer = AIFileOrganizerService();
/// await organizer.initialize();
/// await organizer.organizeDirectory('/path/to/files');
/// ```
class AIFileOrganizerService {
  /// Initializes the AI file organizer service
  /// 
  /// Sets up necessary resources and loads configuration.
  /// Throws [ServiceInitializationException] if initialization fails.
  Future<void> initialize() async {
    // Implementation
  }
  
  /// Organizes files in the specified directory
  /// 
  /// [directoryPath] is the path to the directory to organize.
  /// [options] contains optional configuration for the organization process.
  /// Returns [OrganizationResult] with details about the operation.
  /// 
  /// Example:
  /// ```dart
  /// final result = await organizer.organizeDirectory(
  ///   '/path/to/files',
  ///   options: OrganizationOptions(enableLearning: true),
  /// );
  /// ```
  Future<OrganizationResult> organizeDirectory(
    String directoryPath, {
    OrganizationOptions? options,
  }) async {
    // Implementation
  }
}

// ❌ INCORRECT: Missing or incomplete documentation
class AIFileOrganizerService {
  // Initialize the service
  Future<void> initialize() async {
    // Implementation
  }
  
  // Organize files
  Future<OrganizationResult> organizeDirectory(String path) async {
    // Implementation
  }
}
```

### 📋 **Method Documentation**
```dart
// ✅ CORRECT: Complete documentation with parameters and return type
/// Validates the configuration parameters
/// 
/// Checks all configuration parameters for validity and consistency.
/// 
/// Parameters:
/// - [config] - The configuration to validate
/// - [strictMode] - If true, throws exceptions for invalid parameters
/// 
/// Returns [ValidationResult] containing validation status and any errors found.
/// 
/// Throws [ConfigurationException] if strictMode is true and validation fails.
/// 
/// Example:
/// ```dart
/// final result = await validateConfiguration(
///   config,
///   strictMode: true,
/// );
/// if (!result.isValid) {
///   print('Validation errors: ${result.errors}');
/// }
/// ```
Future<ValidationResult> validateConfiguration(
  CentralParameterizedConfig config, {
  bool strictMode = false,
}) async {
  // Implementation
}

// ❌ INCORRECT: Missing or incomplete documentation
/// Validate config
Future<ValidationResult> validateConfiguration(
  CentralParameterizedConfig config,
  bool strictMode,
) async {
  // Implementation
}
```

## 🔄 Variable and Function Naming Patterns

### 📋 **Boolean Variables**
```dart
// ✅ CORRECT: Use positive, descriptive names
bool isServiceInitialized;
bool hasValidConfiguration;
bool shouldRetryOperation;
bool canConnectToNetwork;
bool isUserAuthenticated;

// ❌ INCORRECT: Use negative or unclear names
bool serviceNotInitialized; // Use positive form
bool configInvalid; // Use isValid instead
bool retryOperation; // Use shouldRetry instead
bool networkConnection; // Use canConnect instead
bool userAuth; // Use isUserAuthenticated instead
```

### 📋 **Collection Variables**
```dart
// ✅ CORRECT: Use plural names for collections
List<Service> activeServices;
List<String> configurationKeys;
Map<String, dynamic> parameterValues;
Set<String> supportedProtocols;
Queue<NetworkEvent> eventQueue;

// ❌ INCORRECT: Use singular names for collections
List<Service> service; // Use services
List<String> key; // Use keys
Map<String, dynamic> value; // Use values
Set<String> protocol; // Use protocols
Queue<NetworkEvent> event; // Use events
```

### 📋 **Function Names**
```dart
// ✅ CORRECT: Use verb-noun pattern, be descriptive
void initializeServices();
String getConfigurationValue(String key);
bool validateParameters(Map<String, dynamic> params);
Future<List<NetworkDevice>> discoverDevices();
void handleServiceEvent(ServiceEvent event);

// ❌ INCORRECT: Use unclear or non-descriptive names
void init(); // Use initialize instead
String get(String key); // Be more specific
bool check(Map<String, dynamic> params); // Use validate instead
Future<List<NetworkDevice>> find(); // Be more specific
void handle(ServiceEvent event); // Be more specific
```

## 📋 **Error and Exception Naming**

### 📋 **Exception Classes**
```dart
// ✅ CORRECT: Use descriptive names with Exception suffix
class ServiceInitializationException extends Exception {}
class ConfigurationValidationException extends Exception {}
class NetworkConnectionException extends Exception {}
class FileOperationException extends Exception {}

// ❌ INCORRECT: Use unclear names
class ServiceError extends Exception {} // Use Exception suffix
class ConfigException extends Exception {} // Use full name
class NetworkError extends Exception {} // Be more specific
```

### 📋 **Error Codes**
```dart
// ✅ CORRECT: Use SCREAMING_SNAKE_CASE, be descriptive
class ErrorCodes {
  static const String SERVICE_INITIALIZATION_FAILED = 'SERVICE_INITIALIZATION_FAILED';
  static const String CONFIGURATION_VALIDATION_FAILED = 'CONFIGURATION_VALIDATION_FAILED';
  static const String NETWORK_CONNECTION_TIMEOUT = 'NETWORK_CONNECTION_TIMEOUT';
  static const String FILE_OPERATION_PERMISSION_DENIED = 'FILE_OPERATION_PERMISSION_DENIED';
}

// ❌ INCORRECT: Use unclear codes
class ErrorCodes {
  static const String SERVICE_ERROR = 'SERVICE_ERROR'; // Be more specific
  static const String CONFIG_ERROR = 'CONFIG_ERROR'; // Use full name
  static const String NETWORK_ERROR = 'NETWORK_ERROR'; // Be more specific
}
```

## 🎯 Configuration and Constants

### 📋 **Configuration Keys**
```dart
// ✅ CORRECT: Use hierarchical naming with dots
class ConfigKeys {
  // AI Services Configuration
  static const String AI_SERVICES_ENABLE_FILE_ORGANIZER = 'ai_services.enable_file_organizer';
  static const String AI_SERVICES_ENABLE_ADVANCED_SEARCH = 'ai_services.enable_advanced_search';
  static const String AI_SERVICES_MAX_CONCURRENT_TASKS = 'ai_services.max_concurrent_tasks';
  
  // Network Services Configuration
  static const String NETWORK_SERVICES_ENABLE_FILE_SHARING = 'network_services.enable_file_sharing';
  static const String NETWORK_SERVICES_MAX_CONCURRENT_OPERATIONS = 'network_services.max_concurrent_operations';
  
  // Performance Configuration
  static const String PERFORMANCE_ENABLE_CACHING = 'performance.enable_caching';
  static const String PERFORMANCE_CACHE_SIZE_MB = 'performance.cache_size_mb';
}

// ❌ INCORRECT: Use flat or unclear naming
class ConfigKeys {
  static const String AI_ORGANIZER = 'ai_organizer'; // Not hierarchical
  static const String AI_SEARCH = 'ai_search'; // Not hierarchical
  static const String NETWORK_SHARING = 'network_sharing'; // Not hierarchical
  static const String CACHING = 'caching'; // Not hierarchical
}
```

### 📋 **Event Type Names**
```dart
// ✅ CORRECT: Use descriptive enum names
enum ServiceEventType {
  initializing,
  initialized,
  error,
  restarted,
  disposed,
}

enum ConfigurationEventType {
  parameterChanged,
  configurationReloaded,
  configurationImported,
  configurationExported,
}

enum NetworkEventType {
  deviceDiscovered,
  deviceConnected,
  deviceDisconnected,
  fileTransferred,
  connectionError,
}

// ❌ INCORRECT: Use unclear or inconsistent names
enum ServiceEvent {
  init, // Use full name
  init_done, // Use consistent naming
  err, // Use full name
  restart, // Use past tense consistently
}
```

## 📝 File Organization and Structure

### 📋 **File Header Comments**
```dart
// ✅ CORRECT: Include proper file header
/// AI File Organizer Service
/// 
/// Provides intelligent file organization capabilities including:
/// - Automatic file categorization
/// - Smart folder structure creation
/// - Content-based file analysis
/// 
/// Author: iSuite Team
/// Version: 2.0.0
/// Since: 2024-01-01
library ai_file_organizer_service;

import 'dart:async';
import 'package:flutter/foundation.dart';
// ... other imports

// ❌ INCORRECT: Missing or incomplete file header
// AI file organizer
import 'dart:async';
import 'package:flutter/foundation.dart';
// ... other imports
```

### 📋 **Section Comments**
```dart
// ✅ CORRECT: Use descriptive section comments
// ============================================================================
// Service Initialization
// ============================================================================

class AIFileOrganizerService {
  // ---------------------------------------------------------------------------
  // Private Properties
  // ---------------------------------------------------------------------------
  
  final String _serviceName;
  final List<FileSystemEntity> _organizedFiles = [];
  
  // ---------------------------------------------------------------------------
  // Public Methods
  // ---------------------------------------------------------------------------
  
  Future<void> initialize() async {
    // Implementation
  }
  
  // ---------------------------------------------------------------------------
  // Private Methods
  // ---------------------------------------------------------------------------
  
  void _validateConfiguration() {
    // Implementation
  }
}

// ❌ INCORRECT: Use unclear or missing section comments
class AIFileOrganizerService {
  // Properties
  final String _serviceName;
  final List<FileSystemEntity> _organizedFiles = [];
  
  // Methods
  Future<void> initialize() async {
    // Implementation
  }
  
  // Private methods
  void _validateConfiguration() {
    // Implementation
  }
}
```

## 🎯 Best Practices Summary

### ✅ **DO's**
- ✅ Use `snake_case` for files and directories
- ✅ Use `PascalCase` for classes, enums, and interfaces
- ✅ Use `camelCase` for methods, variables, and functions
- ✅ Use `SCREAMING_SNAKE_CASE` for constants
- ✅ Use descriptive, meaningful names
- ✅ Use consistent naming throughout the project
- ✅ Document all public APIs with dartdoc
- ✅ Group imports logically
- ✅ Use positive names for boolean variables
- ✅ Use plural names for collections

### ❌ **DON'Ts**
- ❌ Don't use abbreviations unless widely understood
- ❌ Don't use single-letter names except for type parameters
- ❌ Don't use Hungarian notation or prefixes
- ❌ Don't use unclear or generic names
- ❌ Don't mix naming conventions
- ❌ Don't use spaces in file or directory names
- ❌ Don't use `I` prefix for interfaces (not Dart convention)
- ❌ Don't use `s_` or `k_` prefixes for static/const members
- ❌ Don't use negative names for boolean variables
- ❌ Don't use inconsistent naming patterns

## 🔄 Naming Convention Checklist

### 📋 **File and Directory Names**
- [ ] All files use `snake_case`
- [ ] All directories use `snake_case`
- [ ] No spaces in file/directory names
- [ ] Test files end with `_test.dart`
- [ ] Names are descriptive and meaningful

### 📋 **Class and Type Names**
- [ ] Classes use `PascalCase`
- [ ] Abstract classes use descriptive names
- [ ] Interfaces describe capabilities
- [ ] Enums use `PascalCase`, values use `camelCase`
- [ ] Type parameters are single letters or descriptive

### 📋 **Method and Variable Names**
- [ ] Methods use `camelCase` with verb-first pattern
- [ ] Variables use `camelCase`
- [ ] Private members use underscore prefix
- [ ] Static members use `camelCase`
- [ ] Constants use `SCREAMING_SNAKE_CASE`

### 📋 **Documentation**
- [ ] All public classes have dartdoc comments
- [ ] All public methods have documentation
- [ ] Parameters and return types are documented
- [ ] Examples are provided where appropriate
- [ ] File headers include version and author information

This naming convention guide ensures **consistency, readability, and maintainability** across the entire iSuite project! 🚀
