# iSuite API Documentation

## Overview

This document provides comprehensive API documentation for the iSuite Flutter application's core services and features. All services follow a consistent singleton pattern with initialization methods and event-driven architecture.

## Table of Contents

1. [Core Services](#core-services)
2. [File Management](#file-management)
3. [Network Operations](#network-operations)
4. [AI & Analytics](#ai-analytics)
5. [Security & Authentication](#security-authentication)
6. [UI & Theming](#ui-theming)
7. [Build & Deployment](#build-deployment)
8. [Error Handling](#error-handling)

## Core Services

### CentralConfig

**Singleton Service for Centralized Configuration Management**

#### Initialization
```dart
await CentralConfig.instance.initialize();
```

#### Methods

##### Configuration Management
```dart
// Set parameter
await CentralConfig.instance.setParameter('app.name', 'iSuite');

// Get parameter with default
String appName = CentralConfig.instance.getParameter('app.name', defaultValue: 'Default App');

// Check if parameter exists
bool exists = CentralConfig.instance.hasParameter('app.name');
```

##### Component Registration
```dart
// Register component with dependencies
await CentralConfig.instance.registerComponent(
  componentId: 'fileManager',
  componentType: ComponentType.feature,
  dependencies: ['storage', 'network'],
  parameters: {
    'maxFileSize': 100 * 1024 * 1024, // 100MB
    'supportedFormats': ['pdf', 'doc', 'txt'],
  }
);
```

##### Parameter Validation
```dart
// Validate parameter
ValidationResult result = await CentralConfig.instance.validateParameter(
  key: 'network.timeout',
  value: 30,
  rules: [
    ValidationRule.min(5),
    ValidationRule.max(300),
  ]
);
```

##### Event Subscription
```dart
// Listen to configuration changes
StreamSubscription subscription = CentralConfig.instance.configurationChanges.listen((event) {
  print('Configuration changed: ${event.key} = ${event.newValue}');
});
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `app.name` | String | "iSuite" | Application name |
| `app.version` | String | "1.0.0" | Application version |
| `ui.theme` | String | "system" | Theme mode (light/dark/system) |
| `network.timeout` | int | 30 | Network timeout in seconds |
| `storage.maxFileSize` | int | 104857600 | Maximum file size (100MB) |

### PerformanceOptimizationService

**Service for Application Performance Monitoring and Optimization**

#### Initialization
```dart
await PerformanceOptimizationService.instance.initialize();
```

#### Methods

##### Operation Tracking
```dart
// Track synchronous operation
dynamic result = await performanceService.trackOperation(
  'file_upload',
  () => uploadFile(file),
);

// Track asynchronous operation
final result = await performanceService.trackAsyncOperation(
  'network_request',
  () => http.get(Uri.parse(url)),
);
```

##### Memory Management
```dart
// Get memory statistics
MemoryStatistics stats = performanceService.getMemoryStatistics();

// Optimize memory usage
MemoryCleanupResult result = await performanceService.optimizeMemory();

// Register object for monitoring
performanceService.registerObject('user_session', sessionData);
```

##### Caching Operations
```dart
// Cache expensive computation
final cachedResult = await performanceService.getCachedResult(
  'user_profile',
  () => fetchUserProfile(),
  ttl: Duration(hours: 1),
);

// Invalidate cache
await performanceService.invalidateCache('user_profile');
```

##### Performance Metrics
```dart
// Get current metrics
PerformanceMetrics metrics = performanceService.getPerformanceStatistics();

// Export metrics
String jsonData = await performanceService.exportMetrics(
  startTime: DateTime.now().subtract(Duration(days: 7)),
  endTime: DateTime.now(),
);
```

## File Management

### AdvancedFileOperationsService

**Comprehensive File Management with Batch Operations and AI Analysis**

#### Initialization
```dart
await AdvancedFileOperationsService.instance.initialize();
```

#### Methods

##### Batch Operations
```dart
// Copy multiple files
BatchOperationResult result = await fileService.performBatchOperation(
  type: BatchOperationType.copy,
  sourcePaths: ['/path/file1.txt', '/path/file2.txt'],
  destinationPath: '/destination/',
  options: BatchOperationOptions(overwrite: false),
);
```

##### File Search
```dart
// Advanced file search
SearchResult result = await fileService.searchFiles(
  directory: '/home/user',
  query: 'document',
  fileTypes: ['pdf', 'docx'],
  modifiedAfter: DateTime.now().subtract(Duration(days: 7)),
  maxResults: 50,
);
```

##### File Compression
```dart
// Compress files
CompressionResult result = await fileService.compressFiles(
  sourcePaths: ['file1.txt', 'file2.txt'],
  outputPath: 'archive.zip',
  format: CompressionFormat.zip,
  level: CompressionLevel.normal,
  onProgress: (progress) => print('Compression: ${(progress * 100).round()}%'),
);
```

##### Duplicate Detection
```dart
// Find duplicate files
DuplicateFilesResult result = await fileService.findDuplicateFiles(
  directory: '/home/user',
  includeSubdirectories: true,
  method: DuplicateDetectionMethod.contentHash,
  onProgress: (progress) => print('Scanning: ${progress.filesScanned} files'),
);
```

##### File Synchronization
```dart
// Synchronize directories
DirectorySyncResult result = await fileService.synchronizeDirectories(
  sourceDirectory: '/local/files',
  targetDirectory: '/remote/files',
  mode: SyncMode.bidirectional,
  conflictStrategy: ConflictResolutionStrategy.lastWriteWins,
  onProgress: (progress) => print('Sync: ${progress.completed}/${progress.total}'),
);
```

##### AI File Analysis
```dart
// Analyze file with AI
FileAnalysisResult analysis = await fileService.analyzeFile(
  filePath: 'document.pdf',
  depth: AnalysisDepth.detailed,
  onProgress: (progress) => print('Analysis: ${(progress * 100).round()}%'),
);

// Get organization suggestions
OrganizationSuggestions suggestions = await fileService.getOrganizationSuggestions(
  filePaths: ['file1.txt', 'file2.pdf', 'image.jpg'],
  strategy: OrganizationStrategy.automatic,
);
```

## Network Operations

### CloudStorageService

**Unified API for Multiple Cloud Storage Providers**

#### Initialization
```dart
await CloudStorageService.instance.initialize();
```

#### Methods

##### Authentication
```dart
// Authenticate with provider
CloudAuthResult auth = await cloudService.authenticate(
  provider: CloudProvider.googleDrive,
  useWebAuth: true,
);
```

##### File Operations
```dart
// List files
CloudFileList files = await cloudService.listFiles(
  accountId: auth.accountId,
  folderId: 'root',
  maxResults: 100,
);

// Upload file
CloudUploadResult upload = await cloudService.uploadFile(
  accountId: auth.accountId,
  localPath: '/local/file.txt',
  remotePath: '/remote/file.txt',
  onProgress: (progress) => print('Upload: ${(progress * 100).round()}%'),
);

// Download file
CloudDownloadResult download = await cloudService.downloadFile(
  accountId: auth.accountId,
  fileId: 'file_id_123',
  localPath: '/downloads/file.txt',
);
```

##### Folder Management
```dart
// Create folder
CloudFolderResult folder = await cloudService.createFolder(
  accountId: auth.accountId,
  name: 'New Folder',
  parentId: 'root',
);

// Delete item
CloudDeleteResult delete = await cloudService.deleteItem(
  accountId: auth.accountId,
  itemId: 'file_id_123',
  permanent: false,
);
```

##### Sharing and Permissions
```dart
// Share file
CloudShareResult share = await cloudService.shareFile(
  accountId: auth.accountId,
  fileId: 'file_id_123',
  recipients: ['user@example.com'],
  permission: SharePermission.view,
  message: 'Please review this document',
);
```

## AI & Analytics

### AIFileAnalysisService

**AI-Powered File Analysis and Intelligent Organization**

#### Initialization
```dart
await AIFileAnalysisService.instance.initialize();
```

#### Methods

##### File Analysis
```dart
// Analyze single file
FileAnalysisResult analysis = await aiService.analyzeFile(
  filePath: 'document.pdf',
  depth: AnalysisDepth.comprehensive,
);

// Batch analysis
BatchAnalysisResult batch = await aiService.analyzeFilesBatch(
  filePaths: ['doc1.pdf', 'doc2.docx', 'image.jpg'],
  depth: AnalysisDepth.detailed,
);
```

##### Intelligent Search
```dart
// Semantic search
SearchResult results = await aiService.intelligentSearch(
  query: 'project proposal budget',
  searchType: SearchType.semantic,
  maxResults: 20,
);
```

##### Content Analysis
```dart
// Extract text and analyze
List<String> text = await aiService.extractTextContent('document.pdf');
List<String> tags = await aiService.generateAITags(text, {});
```

##### Organization Intelligence
```dart
// Get smart organization suggestions
OrganizationSuggestions suggestions = await aiService.getOrganizationSuggestions(
  filePaths: filePaths,
  strategy: OrganizationStrategy.automatic,
);

// Find similar files
SimilarityResult similar = await aiService.findSimilarFiles(
  filePath: 'document.pdf',
  maxResults: 5,
  criteria: SimilarityCriteria.content,
);
```

## Security & Authentication

### AdvancedSecurityManager

**Enterprise-Grade Security Management**

#### Initialization
```dart
await AdvancedSecurityManager.instance.initialize();
```

#### Methods

##### Encryption
```dart
// Encrypt data
String encrypted = await securityManager.encryptData('sensitive data');

// Decrypt data
String decrypted = await securityManager.decryptData(encrypted);
```

##### Authentication
```dart
// Biometric authentication
bool authenticated = await securityManager.authenticateWithBiometrics(
  reason: 'Access secure files',
);

// Multi-factor authentication
bool mfaVerified = await securityManager.verifyMultiFactorCode(
  userId: 'user123',
  code: '123456',
);
```

##### Secure Storage
```dart
// Store sensitive data
await securityManager.storeSecureData('api_key', 'secret_key');

// Retrieve data
String? data = await securityManager.retrieveSecureData('api_key');
```

## UI & Theming

### AdvancedUIService

**Modern UI with Material Design 3 and Responsive Layouts**

#### Initialization
```dart
await AdvancedUIService.instance.initialize();
```

#### Methods

##### Theme Management
```dart
// Get theme data
ThemeData theme = uiService.getThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
);

// Adaptive text theme
TextTheme textTheme = uiService.getAdaptiveTextTheme(context);
```

##### Responsive Layouts
```dart
// Responsive container
Widget container = uiService.responsiveContainer(
  context: context,
  child: MyWidget(),
  padding: EdgeInsets.all(16),
);

// Adaptive grid
Widget grid = uiService.adaptiveGrid(
  context: context,
  children: widgetList,
  minCrossAxisCount: 2,
);
```

##### Modern Components
```dart
// Modern card
Widget card = uiService.modernCard(
  context: context,
  child: CardContent(),
  onTap: () => handleTap(),
  elevated: true,
);

// Adaptive button
Widget button = uiService.adaptiveButton(
  context: context,
  child: Text('Click Me'),
  onPressed: () => handlePress(),
  expanded: true,
);
```

## Build & Deployment

### BuildArtifactManagementService

**Artifact Storage, Versioning, and Distribution**

#### Initialization
```dart
await BuildArtifactManagementService.instance.initialize();
```

#### Methods

##### Artifact Storage
```dart
// Store build artifacts
ArtifactStorageResult result = await artifactService.storeArtifacts(
  buildId: 'build_123',
  artifacts: [buildArtifact],
  platform: TargetPlatform.android,
  version: '1.2.3',
);
```

##### Artifact Retrieval
```dart
// Retrieve artifacts
ArtifactRetrievalResult result = await artifactService.retrieveArtifacts(
  buildId: 'build_123',
  platform: TargetPlatform.android,
);
```

##### Distribution
```dart
// Distribute to channels
ArtifactDistributionResult dist = await artifactService.distributeArtifacts(
  artifactId: 'artifact_123',
  channels: ['production', 'staging'],
  mode: DistributionMode.automatic,
);
```

## Error Handling

### Global Error Handling

```dart
// Set up global error handling
FlutterError.onError = (FlutterErrorDetails details) {
  // Report to monitoring service
  monitoringService.reportError(
    error: details.exception,
    stackTrace: details.stack,
    context: {
      'library': details.library,
      'context': details.context.toString(),
    },
  );
};
```

### Service-Specific Error Handling

```dart
try {
  await fileService.uploadFile(params);
} on FileOperationException catch (e) {
  // Handle file operation errors
  monitoringService.log(
    loggerName: 'error',
    level: LogLevel.error,
    message: 'File upload failed',
    error: e,
  );
} on NetworkException catch (e) {
  // Handle network errors
  await retryWithBackoff(() => fileService.uploadFile(params));
}
```

## Event System

All services emit events through streams for reactive programming:

```dart
// Subscribe to service events
final subscription = fileService.operationEvents.listen((event) {
  switch (event.type) {
    case FileOperationEventType.batchCompleted:
      showSuccessSnackBar('Batch operation completed');
      break;
    case FileOperationEventType.batchFailed:
      showErrorSnackBar('Batch operation failed: ${event.error}');
      break;
  }
});
```

## Configuration Examples

### Basic App Configuration
```dart
await CentralConfig.instance.initialize();

// Set basic parameters
await CentralConfig.instance.setParameter('app.name', 'iSuite');
await CentralConfig.instance.setParameter('app.version', '2.0.0');
await CentralConfig.instance.setParameter('ui.theme', 'system');

// Configure services
await CentralConfig.instance.registerComponent(
  componentId: 'fileManager',
  componentType: ComponentType.feature,
  dependencies: ['storage', 'network'],
  parameters: {
    'maxFileSize': 100 * 1024 * 1024,
    'supportedFormats': ['pdf', 'doc', 'txt', 'jpg', 'png'],
  }
);
```

### Advanced Service Configuration
```dart
// Configure file operations
await CentralConfig.instance.setParameter('file.batch.size', 50);
await CentralConfig.instance.setParameter('file.search.cache.enabled', true);

// Configure network settings
await CentralConfig.instance.setParameter('network.timeout', 30);
await CentralConfig.instance.setParameter('network.retry.attempts', 3);

// Configure AI settings
await CentralConfig.instance.setParameter('ai.analysis.depth', 'detailed');
await CentralConfig.instance.setParameter('ai.cache.enabled', true);
```

This API documentation provides comprehensive coverage of all iSuite services. For implementation details and additional examples, refer to the source code and individual service documentation.
