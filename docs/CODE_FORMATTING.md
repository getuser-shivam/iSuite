# iSuite Code Formatting Guide

## 📋 Formatting Standards

This document defines the **code formatting standards** for the iSuite project to ensure **consistency, readability, and maintainability** across all Dart and Flutter code files.

## 🎯 General Formatting Rules

### 📋 **Line Length**
- **Maximum Line Length**: 80 characters
- **Preferred Line Length**: 70-80 characters for readability
- **Exceptions**: URLs, long string literals, or import statements

### 📋 **Indentation**
- **Indentation Size**: 2 spaces (no tabs)
- **Continuation Indentation**: 4 spaces for wrapped lines
- **Consistent**: Use the same indentation throughout

### 📋 **Spacing**
- **No Trailing Spaces**: Remove spaces at end of lines
- **Single Blank Lines**: Between logical sections
- **Double Blank Lines**: Between major sections (classes, top-level functions)

## 🐍 Dart Formatting

### 📋 **Class Declaration**
```dart
// ✅ CORRECT: Proper class formatting
/// AI File Organizer Service
/// 
/// Provides intelligent file organization capabilities.
class AIFileOrganizerService {
  // ---------------------------------------------------------------------------
  // Public Properties
  // ---------------------------------------------------------------------------
  
  /// Service name for identification
  final String serviceName;
  
  /// List of organized files
  final List<FileSystemEntity> organizedFiles;
  
  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  
  /// Creates a new AI file organizer service
  /// 
  /// [serviceName] is the name of the service
  /// [organizedFiles] is the initial list of organized files
  AIFileOrganizerService({
    required this.serviceName,
    List<FileSystemEntity>? organizedFiles,
  }) : organizedFiles = organizedFiles ?? [];
  
  // ---------------------------------------------------------------------------
  // Public Methods
  // ---------------------------------------------------------------------------
  
  /// Initializes the service
  Future<void> initialize() async {
    // Implementation
  }
}

// ❌ INCORRECT: Poor formatting
class AIFileOrganizerService{
final String serviceName;
final List<FileSystemEntity> organizedFiles;
AIFileOrganizerService({required this.serviceName,this.organizedFiles=[]}):organizedFiles=organizedFiles??[];
Future<void> initialize() async{
// Implementation
}
}
```

### 📋 **Method Declaration**
```dart
// ✅ CORRECT: Proper method formatting
/// Validates the configuration parameters
/// 
/// [config] is the configuration to validate
/// [strictMode] enables strict validation
/// Returns [ValidationResult] with validation status
Future<ValidationResult> validateConfiguration(
  CentralParameterizedConfig config, {
  bool strictMode = false,
}) async {
  // Implementation
}

/// Processes the network event
/// 
/// [event] is the network event to process
/// [callback] is the optional callback for progress updates
void processNetworkEvent(
  NetworkEvent event, {
  ProgressCallback? callback,
}) {
  // Implementation
}

// ❌ INCORRECT: Poor method formatting
Future<ValidationResult> validateConfiguration(
CentralParameterizedConfig config,
{bool strictMode=false}) async{
// Implementation
}

void processNetworkEvent(NetworkEvent event,{ProgressCallback? callback}){
// Implementation
}
```

### 📋 **Constructor Formatting**
```dart
// ✅ CORRECT: Proper constructor formatting
/// Creates a new service instance
ServiceManager({
  required String serviceName,
  ServiceConfiguration? configuration,
  List<Service>? dependencies,
}) : serviceName = serviceName,
     configuration = configuration ?? ServiceConfiguration.defaultConfig(),
     dependencies = dependencies ?? [];

/// Creates a new configuration instance
ConfigurationManager.default()
    : _config = CentralParameterizedConfig.instance,
      _validator = ConfigurationValidator();

// ❌ INCORRECT: Poor constructor formatting
ServiceManager({required String serviceName,ServiceConfiguration? configuration,List<Service>? dependencies}):serviceName=serviceName,configuration=configuration??ServiceConfiguration.defaultConfig(),dependencies=dependencies??[];

ConfigurationManager.default():_config=CentralParameterizedConfig.instance,_validator=ConfigurationValidator();
```

### 📋 **Function Parameters**
```dart
// ✅ CORRECT: Proper parameter formatting
Future<void> performOperation(
  String operationName,
  Map<String, dynamic> parameters, {
  Duration timeout = const Duration(seconds: 30),
  bool retryOnError = false,
  ProgressCallback? onProgress,
}) async {
  // Implementation
}

// ❌ INCORRECT: Poor parameter formatting
Future<void> performOperation(String operationName,Map<String,dynamic> parameters,{Duration timeout=Duration(seconds:30),bool retryOnError=false,ProgressCallback? onProgress}) async{
// Implementation
}
```

### 📋 **Conditional Statements**
```dart
// ✅ CORRECT: Proper conditional formatting
if (isServiceInitialized && hasValidConfiguration) {
  await startService();
} else if (!isServiceInitialized) {
  await initializeService();
} else {
  await validateConfiguration();
}

// ✅ CORRECT: Multi-line conditions
if (isServiceInitialized &&
    hasValidConfiguration &&
    networkConnectionAvailable) {
  await startService();
}

// ✅ CORRECT: Switch statement
switch (serviceState) {
  case ServiceState.uninitialized:
    await initializeService();
    break;
  case ServiceState.initializing:
    logger.info('Service is initializing');
    break;
  case ServiceState.initialized:
    await startService();
    break;
  case ServiceState.error:
    await handleError();
    break;
  case ServiceState.disposed:
    logger.warning('Service is disposed');
    break;
}

// ❌ INCORRECT: Poor conditional formatting
if(isServiceInitialized&&hasValidConfiguration){
await startService();
}else if(!isServiceInitialized){
await initializeService();
}else{
await validateConfiguration();
}

switch(serviceState){
case ServiceState.uninitialized:
await initializeService();
break;
case ServiceState.initializing:
logger.info('Service is initializing');
break;
}
```

### 📋 **Loop Statements**
```dart
// ✅ CORRECT: Proper loop formatting
for (final service in activeServices) {
  await service.validateConfiguration();
}

for (int i = 0; i < maxRetries; i++) {
  try {
    await performOperation();
    break;
  } catch (e) {
    if (i == maxRetries - 1) rethrow;
    await Future.delayed(Duration(seconds: i + 1));
  }
}

while (!isServiceReady) {
  await Future.delayed(Duration(milliseconds: 100));
  checkServiceReady();
}

// ❌ INCORRECT: Poor loop formatting
for(final service in activeServices){
await service.validateConfiguration();
}

for(int i=0;i<maxRetries;i++){
try{
await performOperation();
break;
}catch(e){
if(i==maxRetries-1)rethrow;
await Future.delayed(Duration(seconds:i+1));
}
}

while(!isServiceReady){
await Future.delayed(Duration(milliseconds:100));
checkServiceReady();
}
```

### 📋 **Collection Operations**
```dart
// ✅ CORRECT: Proper collection formatting
final validServices = services.where((service) => service.isValid).toList();
final serviceNames = services.map((service) => service.name).toList();
final groupedServices = services.groupBy((service) => service.type);

// ✅ CORRECT: Multi-line collection operations
final processedServices = services
    .where((service) => service.isValid)
    .map((service) => service.process())
    .where((service) => service.isProcessed)
    .toList();

// ✅ CORRECT: Collection literals
final configuration = {
  'service_name': serviceName,
  'max_concurrent_tasks': maxConcurrentTasks,
  'timeout_seconds': timeout.inSeconds,
  'enable_logging': enableLogging,
};

final supportedProtocols = [
    'ftp',
    'ftps',
    'sftp',
    'webdav',
    'smb',
  ];

// ❌ INCORRECT: Poor collection formatting
final validServices=services.where((service)=>service.isValid).toList();
final serviceNames=services.map((service)=>service.name).toList();
final groupedServices=services.groupBy((service)=>service.type);

final processedServices=services.where((service)=>service.isValid).map((service)=>service.process()).where((service)=>service.isProcessed).toList();

final configuration={'service_name':serviceName,'max_concurrent_tasks':maxConcurrentTasks,'timeout_seconds':timeout.inSeconds,'enable_logging':enableLogging};
final supportedProtocols=['ftp','ftps','sftp','webdav','smb'];
```

## 📱 Flutter Widget Formatting

### 📋 **Widget Declaration**
```dart
// ✅ CORRECT: Proper widget formatting
class FileListItemWidget extends StatelessWidget {
  const FileListItemWidget({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
  });

  final FileSystemEntity file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_getIconForFile()),
      title: Text(
        file.path.split('/').last,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        _formatFileSize(),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

// ❌ INCORRECT: Poor widget formatting
class FileListItemWidget extends StatelessWidget{
const FileListItemWidget({super.key,required this.file,this.onTap,this.onLongPress});
final FileSystemEntity file;
final VoidCallback? onTap;
final VoidCallback? onLongPress;
@override
Widget build(BuildContext context){
return ListTile(
leading:Icon(_getIconForFile()),
title:Text(file.path.split('/').last,style:Theme.of(context).textTheme.titleMedium),
subtitle:Text(_formatFileSize(),style:Theme.of(context).textTheme.bodySmall),
onTap:onTap,
onLongPress:onLongPress,
);
}
```

### 📋 **Widget Tree Formatting**
```dart
// ✅ CORRECT: Proper widget tree formatting
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('File Manager'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return FileListItemWidget(
                file: file,
                onTap: () => _handleFileTap(file),
                onLongPress: () => _handleFileLongPress(file),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _refreshFiles,
                  child: const Text('Refresh'),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: _organizeFiles,
                  child: const Text('Organize'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ❌ INCORRECT: Poor widget tree formatting
@override
Widget build(BuildContext context){
return Scaffold(
appBar:AppBar(title:Text('File Manager'),backgroundColor:Theme.of(context).colorScheme.inversePrimary),
body:Column(children:[
Expanded(child:ListView.builder(itemCount:files.length,itemBuilder:(context,index){
final file=files[index];
return FileListItemWidget(file:file,onTap:()=>_handleFileTap(file),onLongPress:()=>_handleFileLongPress(file));
})),
Container(padding:const EdgeInsets.all(16.0),child:Row(children:[
Expanded(child:ElevatedButton(onPressed:_refreshFiles,child:const Text('Refresh'))),
const SizedBox(width:16.0),
Expanded(child:ElevatedButton(onPressed:_organizeFiles,child:const Text('Organize'))),
]),
),
],),
);
}
```

### 📋 **Method Chaining**
```dart
// ✅ CORRECT: Proper method chaining
Future<List<NetworkDevice>> discoverDevices() async {
  return await _networkDiscovery
      .startDiscovery()
      .then((_) => _networkDiscovery.getDiscoveredDevices())
      .timeout(Duration(seconds: 30))
      .catchError((error) => throw NetworkDiscoveryException(error.toString()));
}

// ✅ CORRECT: Multi-line method chaining
Future<List<ProcessedFile>> processFiles(List<File> files) async {
  return files
      .where((file) => file.existsSync())
      .map((file) => _analyzeFile(file))
      .where((analysis) => analysis.isValid)
      .map((analysis) => _processFile(analysis))
      .where((processed) => processed.success)
      .toList();
}

// ❌ INCORRECT: Poor method chaining
Future<List<NetworkDevice>> discoverDevices()async{
return await _networkDiscovery.startDiscovery().then((_)=>_networkDiscovery.getDiscoveredDevices()).timeout(Duration(seconds:30)).catchError((error)=>throw NetworkDiscoveryException(error.toString()));
}

Future<List<ProcessedFile>> processFiles(List<File> files)async{
return files.where((file)=>file.existsSync()).map((file)=>_analyzeFile(file)).where((analysis)=>analysis.isValid).map((analysis)=>_processFile(analysis)).where((processed)=>processed.success).toList();
}
```

## 📝 Import and Export Formatting

### 📋 **Import Statements**
```dart
// ✅ CORRECT: Proper import formatting
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';

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

// ❌ INCORRECT: Poor import formatting
import 'dart:async';
import 'dart:convert';
import '../core/config/central_parameterized_config.dart';
import 'package:flutter/material.dart'
    'package:flutter_riverpod/flutter_riverpod.dart'
    'package:crypto/crypto.dart';
import '../core/ai/ai_file_organizer.dart'
    '../core/network/enhanced_network_file_sharing.dart'
    '../data/models/user_model.dart'
    '../data/repositories/user_repository.dart'
    '../screens/home_screen.dart'
    '../widgets/common/app_scaffold.dart';
```

### 📋 **Export Statements**
```dart
// ✅ CORRECT: Proper export formatting
// Core exports
export 'ai_file_organizer.dart';
export 'ai_advanced_search.dart';
export 'smart_file_categorizer.dart';

// Network exports
export 'enhanced_network_file_sharing.dart';
export 'advanced_ftp_client.dart';
export 'wifi_direct_p2p_service.dart';

// Configuration exports
export 'central_parameterized_config.dart';
export 'component_relationship_manager.dart';

// ❌ INCORRECT: Poor export formatting
export 'ai_file_organizer.dart' export 'ai_advanced_search.dart' export 'smart_file_categorizer.dart' export 'enhanced_network_file_sharing.dart' export 'advanced_ftp_client.dart' export 'wifi_direct_p2p_service.dart' export 'central_parameterized_config.dart' export 'component_relationship_manager.dart';
```

## 🔄 String and Comment Formatting

### 📋 **String Literals**
```dart
// ✅ CORRECT: Proper string formatting
final message = 'Service initialized successfully';
final errorMessage = 'Failed to connect to server: $host:$port';

// ✅ CORRECT: Multi-line strings
final longMessage = '''
This is a multi-line string that spans multiple lines.
It maintains proper indentation and formatting.
All lines are preserved exactly as written.
''';

// ✅ CORRECT: String interpolation
final greeting = 'Hello, $userName! You have $notificationCount notifications.';
final configInfo = 'Service: $serviceName, Port: $port, Timeout: ${timeout.inSeconds}s';

// ❌ INCORRECT: Poor string formatting
final message='Service initialized successfully';
final errorMessage='Failed to connect to server:$host:$port';

final longMessage='''This is a multi-line string that spans multiple lines.
It maintains proper indentation and formatting.
All lines are preserved exactly as written. '';

final greeting='Hello, $userName! You have $notificationCount notifications.';
final configInfo='Service:$serviceName,Port:$port,Timeout:${timeout.inSeconds}s';
```

### 📋 **Comments**
```dart
// ✅ CORRECT: Proper comment formatting
// This is a single-line comment with proper spacing
/// This is a dartdoc comment for documentation
// ---------------------------------------------------------------------------
// Section separator comment
// ---------------------------------------------------------------------------

/* 
 * This is a multi-line comment
 * that spans multiple lines
 * with proper formatting
 */

// ❌ INCORRECT: Poor comment formatting
//This is a single-line comment without proper spacing
///This is a dartdoc comment without proper spacing
// ---------------------------------------------------------------------------
//Section separator comment without proper spacing
//---------------------------------------------------------------------------

/*
* This is a multi-line comment
* without proper formatting
* and inconsistent indentation
*/
```

## 📊 Error Handling Formatting

### 📋 **Try-Catch Blocks**
```dart
// ✅ CORRECT: Proper error handling formatting
try {
  await service.initialize();
  logger.info('Service initialized successfully');
} on ServiceException catch (e) {
  logger.error('Service initialization failed: $e');
  rethrow;
} on TimeoutException catch (e) {
  logger.warning('Service initialization timed out: $e');
  throw ServiceInitializationException('Initialization timeout');
} catch (e, stackTrace) {
  logger.error('Unexpected error during initialization', error: e, stackTrace: stackTrace);
  throw ServiceInitializationException('Unexpected error: $e');
}

// ✅ CORRECT: Multi-line try-catch
try {
  await performComplexOperation(
    parameter1: value1,
    parameter2: value2,
    parameter3: value3,
  );
} on ValidationException catch (e) {
  logger.error('Validation failed: $e');
  throw ServiceException('Invalid parameters: $e');
} on NetworkException catch (e) {
  logger.error('Network error: $e');
  throw ServiceException('Network operation failed: $e');
} catch (e, stackTrace) {
  logger.error('Unexpected error: $e', error: e, stackTrace: stackTrace);
  throw ServiceException('Unexpected error: $e');
}

// ❌ INCORRECT: Poor error handling formatting
try{
await service.initialize();
logger.info('Service initialized successfully');
}catch(ServiceException e){
logger.error('Service initialization failed: $e');
rethrow;
}catch(TimeoutException e){
logger.warning('Service initialization timed out: $e');
throw ServiceInitializationException('Initialization timeout');
}catch(e,stackTrace){
logger.error('Unexpected error during initialization',error:e,stackTrace:stackTrace);
throw ServiceInitializationException('Unexpected error: $e');
}
```

## 🎯 Async/Await Formatting

### 📋 **Async Functions**
```dart
// ✅ CORRECT: Proper async function formatting
Future<void> initializeService() async {
  try {
    await _loadConfiguration();
    await _connectToBackend();
    await _startEventListeners();
    logger.info('Service initialized successfully');
  } catch (e, stackTrace) {
    logger.error('Service initialization failed', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

// ✅ CORRECT: Async function with return value
Future<List<NetworkDevice>> discoverDevices() async {
  try {
    await _startDiscovery();
    await Future.delayed(Duration(seconds: 5));
    return await _getDiscoveredDevices();
  } finally {
    await _stopDiscovery();
  }
}

// ✅ CORRECT: Async function with parameters
Future<ServiceResult> performOperation(
  String operationName,
  Map<String, dynamic> parameters, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  return await _executeOperation(operationName, parameters)
      .timeout(timeout)
      .catchError((error) => ServiceResult.error(error.toString()));
}

// ❌ INCORRECT: Poor async function formatting
Future<void> initializeService()async{
try{
await _loadConfiguration();
await _connectToBackend();
await _startEventListeners();
logger.info('Service initialized successfully');
}catch(e,stackTrace){
logger.error('Service initialization failed',error:e,stackTrace:stackTrace);
rethrow;
}
}

Future<List<NetworkDevice>> discoverDevices()async{
try{
await _startDiscovery();
await Future.delayed(Duration(seconds:5));
return await _getDiscoveredDevices();
}finally{
await _stopDiscovery();
}
}
```

## 📋 **Lambda/Arrow Functions**
```dart
// ✅ CORRECT: Proper lambda formatting
final filteredServices = services.where((service) => service.isActive);
final serviceNames = services.map((service) => service.name);
final groupedServices = services.groupBy((service) => service.type);

// ✅ CORRECT: Multi-line lambda
final processedServices = services
    .where((service) => service.isValid)
    .map((service) => service.process())
    .where((processed) => processed.success);

// ✅ CORRECT: Lambda with multiple parameters
final sortedServices = services.sort((a, b) => a.name.compareTo(b.name));

// ❌ INCORRECT: Poor lambda formatting
final filteredServices=services.where((service)=>service.isActive);
final serviceNames=services.map((service)=>service.name);
final groupedServices=services.groupBy((service)=>service.type);

final processedServices=services.where((service)=>service.isValid).map((service)=>service.process()).where((processed)=>processed.success);

final sortedServices=services.sort((a,b)=>a.name.compareTo(b.name));
```

## 🎯 Formatting Checklist

### 📋 **Line Formatting**
- [ ] Maximum line length: 80 characters
- [ ] No trailing spaces
- [ ] Proper indentation: 2 spaces
- [ ] Consistent spacing around operators
- [ ] Single blank lines between logical sections

### 📋 **Class and Method Formatting**
- [ ] Classes use proper indentation
- [ ] Methods use proper parameter formatting
- [ ] Constructors use proper formatting
- [ ] Section comments are properly formatted

### 📋 **Control Flow Formatting**
- [ ] If statements use proper formatting
- [ ] Switch statements use proper formatting
- [ ] Loops use proper formatting
- [ ] Multi-line conditions are properly formatted

### 📋 **Widget Formatting**
- [ ] Widget trees are properly indented
- [ ] Parameters are properly formatted
- [ ] Method chaining is properly formatted
- [ ] Nested widgets are properly formatted

### 📋 **Import and Export Formatting**
- [ ] Imports are grouped logically
- [ ] No unused imports
- [ ] Proper spacing between import groups
- [ ] Exports are properly formatted

### 📋 **String and Comment Formatting**
- [ ] String literals use proper formatting
- [ ] Comments use proper spacing
- [ ] Dartdoc comments are properly formatted
- [ ] Multi-line strings are properly formatted

This formatting guide ensures **consistent, readable, and maintainable** code across the entire iSuite project! 🚀
