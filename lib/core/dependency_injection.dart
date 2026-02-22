import 'package:get_it/get_it.dart';
import '../ai/ai_service.dart';
import '../ai/document_ai_service.dart';
import '../logging/logging_service.dart';
import '../notifications/notification_service.dart';
import '../../core/central_config.dart';

/// Service Locator for Dependency Injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final GetIt _getIt = GetIt.instance;
  bool _isInitialized = false;

  /// Initialize all services
  Future<void> initialize() async {
    if (_isInitialized) return;

    final logger = LoggingService();

    try {
      logger.info('Initializing service locator', 'ServiceLocator');

      // Register configuration service
      _getIt.registerLazySingleton<CentralConfig>(() => CentralConfig.instance);

      // Register logging service
      _getIt.registerLazySingleton<LoggingService>(() => LoggingService());

      // Register notification service
      _getIt.registerLazySingletonAsync<NotificationService>(() async {
        final service = NotificationService();
        await service.initialize();
        return service;
      });

      // Register AI services
      _getIt.registerLazySingleton<AIService>(() => AIService());
      _getIt.registerLazySingleton<DocumentAIService>(() => DocumentAIService());

      // Wait for async services to initialize
      await _getIt.allReady();

      _isInitialized = true;
      logger.info('Service locator initialized successfully', 'ServiceLocator');

    } catch (e, stackTrace) {
      logger.error('Failed to initialize service locator', 'ServiceLocator',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get a service instance
  T get<T extends Object>() => _getIt.get<T>();

  /// Check if a service is registered
  bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();

  /// Reset all services (useful for testing)
  void reset() {
    _getIt.reset();
    _isInitialized = false;
  }

  /// Register a mock service for testing
  void registerMock<T extends Object>(T mockService) {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
    _getIt.registerSingleton<T>(mockService);
  }

  /// Register a factory for dynamic service creation
  void registerFactory<T extends Object>(FactoryFunc<T> factory) {
    _getIt.registerFactory<T>(factory);
  }
}

/// Base service class with common functionality
abstract class BaseService {
  final LoggingService _logger = ServiceLocator().get<LoggingService>();
  final CentralConfig _config = ServiceLocator().get<CentralConfig>();

  LoggingService get logger => _logger;
  CentralConfig get config => _config;

  /// Log service-specific information
  void logInfo(String message) => _logger.info(message, runtimeType.toString());
  void logWarning(String message) => _logger.warning(message, runtimeType.toString());
  void logError(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.error(message, runtimeType.toString(), error: error, stackTrace: stackTrace);

  /// Performance monitoring
  void startTiming(String operation) => _logger.log(LogLevel.INFO, 'Starting: $operation', runtimeType.toString());
  void endTiming(String operation) => _logger.log(LogLevel.INFO, 'Completed: $operation', runtimeType.toString());
}

/// Enhanced AI Service with dependency injection
class EnhancedAIService extends BaseService {
  final AIService _aiService = ServiceLocator().get<AIService>();

  Future<String> generateResponse(String query, String context) async {
    logInfo('Generating AI response for query: $query');

    try {
      final result = await _aiService.generateResponse(query, context);
      logInfo('AI response generated successfully');
      return result;
    } catch (e, stackTrace) {
      logError('Failed to generate AI response', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// Enhanced Document AI Service with dependency injection
class EnhancedDocumentAIService extends BaseService {
  final DocumentAIService _documentAIService = ServiceLocator().get<DocumentAIService>();

  Future<DocumentAIResult> processDocument(File file) async {
    logInfo('Processing document: ${file.path}');

    try {
      final result = await _documentAIService.processDocument(file);
      logInfo('Document processed successfully with confidence: ${result.confidence}');
      return result;
    } catch (e, stackTrace) {
      logError('Failed to process document', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// Enhanced Notification Service with dependency injection
class EnhancedNotificationService extends BaseService {
  final NotificationService _notificationService = ServiceLocator().get<NotificationService>();

  Future<void> initialize() async {
    logInfo('Initializing notification service');
    await _notificationService.initialize();
    logInfo('Notification service initialized');
  }

  void showFileOperationNotification({
    required String title,
    required String body,
  }) {
    logInfo('Showing file operation notification: $title');
    _notificationService.showFileOperationNotification(
      title: title,
      body: body,
    );
  }
}

/// Service factory for creating service instances
class ServiceFactory {
  static final ServiceFactory _instance = ServiceFactory._internal();
  factory ServiceFactory() => _instance;
  ServiceFactory._internal();

  T createService<T extends BaseService>() {
    switch (T) {
      case EnhancedAIService:
        return EnhancedAIService() as T;
      case EnhancedDocumentAIService:
        return EnhancedDocumentAIService() as T;
      case EnhancedNotificationService:
        return EnhancedNotificationService() as T;
      default:
        throw UnsupportedError('Service type $T not supported');
    }
  }
}
