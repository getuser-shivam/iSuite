import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// === INFRASTRUCTURE LAYER (Lowest Level - External Concerns) ===
// Core infrastructure services that everything else depends on
import 'infrastructure/core/config/central_config.dart';
import 'infrastructure/core/logging/logging_service.dart';
import 'infrastructure/core/security/security_hardening_service.dart';
import 'infrastructure/core/error_handling/advanced_error_handling_service.dart';

// === APPLICATION CORE LAYER (Orchestration Layer) ===
// Services that manage and orchestrate the application
import 'application/core/component_registry/central_component_registry_service.dart';

// Placeholder for app initializer - will be created
// import 'application/core/initialization/app_initializer.dart';

// === DOMAIN LAYER (Business Logic) ===
// Core business services containing domain logic
import 'domain/services/file_management/advanced_file_manager_service.dart';
import 'domain/services/network/ftp_client_service.dart';
import 'domain/services/database/supabase_service.dart';
import 'domain/services/caching/advanced_caching_service.dart';

// === APPLICATION LAYER (Use Cases) ===
// Application-specific services implementing use cases
import 'application/services/testing/comprehensive_testing_strategy_service.dart';

// Placeholder for analytics and performance services
// import 'application/services/analytics/advanced_analytics_service.dart';
// import 'application/services/performance/advanced_performance_service.dart';

// === INFRASTRUCTURE SERVICES LAYER (External Integrations) ===
// Services handling external integrations and communications
import 'infrastructure/services/cloud/cloud_storage_service.dart';
import 'infrastructure/services/cloud/advanced_file_operations_service.dart';

// === PRESENTATION LAYER (UI) ===
// UI components and app structure
import 'presentation/app.dart';
import 'presentation/providers/app_providers.dart';

/// Main Application Entry Point
/// Organized with clear architectural layers and proper dependency hierarchy
///
/// Architecture Layers (from lowest to highest):
/// 1. Infrastructure Layer - External concerns (frameworks, external APIs)
/// 2. Application Core Layer - Application orchestration and management
/// 3. Domain Layer - Business logic and domain services
/// 4. Application Layer - Use cases and application-specific logic
/// 5. Infrastructure Services Layer - External integrations
/// 6. Presentation Layer - UI and user interaction
///
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize application with proper hierarchical dependency order
  await initializeApplication();

  // Run the application
  runApp(
    ProviderScope(
      child: const ISuiteApp(),
      overrides: await getAppProviders(),
    ),
  );
}

/// Initialize Application with Hierarchical Dependency Order
/// Each layer depends only on lower layers, creating a clean dependency flow
Future<void> initializeApplication() async {
  final logger = LoggingService();

  try {
    logger.info('Starting iSuite application initialization with hierarchical architecture', 'main');

    // === PHASE 1: INFRASTRUCTURE LAYER ===
    // Initialize core infrastructure (no dependencies)
    await _initializeInfrastructureLayer();

    // === PHASE 2: APPLICATION CORE LAYER ===
    // Initialize application orchestration (depends on infrastructure)
    await _initializeApplicationCoreLayer();

    // === PHASE 3: DOMAIN LAYER ===
    // Initialize business logic (depends on infrastructure)
    await _initializeDomainLayer();

    // === PHASE 4: APPLICATION LAYER ===
    // Initialize use cases (depends on domain)
    await _initializeApplicationLayer();

    // === PHASE 5: INFRASTRUCTURE SERVICES LAYER ===
    // Initialize external integrations (depends on domain/application)
    await _initializeInfrastructureServicesLayer();

    logger.info('iSuite application initialization completed successfully', 'main');

  } catch (e, stackTrace) {
    // Emergency logging if initialization fails
    debugPrint('CRITICAL: Application initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');

    // Attempt fallback initialization
    await _emergencyInitialization();
    rethrow;
  }
}

/// Phase 1: Infrastructure Layer Initialization
/// Core external concerns that everything depends on
Future<void> _initializeInfrastructureLayer() async {
  final logger = LoggingService();

  try {
    logger.info('Initializing Infrastructure Layer', 'main');

    // 1. Configuration Service (Foundation - everything needs config)
    await CentralConfig.instance.initialize();
    logger.info('✓ CentralConfig initialized', 'main');

    // 2. Security Service (Must be early - protects all other services)
    await SecurityHardeningService().initialize();
    logger.info('✓ SecurityHardeningService initialized', 'main');

    // 3. Logging Service (Depends on security for encryption)
    await LoggingService().initialize();
    logger.info('✓ LoggingService initialized', 'main');

    // 4. Error Handling Service (Other services need error recovery)
    await AdvancedErrorHandlingService().initialize();
    logger.info('✓ AdvancedErrorHandlingService initialized', 'main');

    logger.info('Infrastructure Layer initialization completed', 'main');

  } catch (e) {
    logger.error('Infrastructure Layer initialization failed: $e', 'main');
    rethrow;
  }
}

/// Phase 2: Application Core Layer Initialization
/// Application orchestration and management services
Future<void> _initializeApplicationCoreLayer() async {
  final logger = LoggingService();

  try {
    logger.info('Initializing Application Core Layer', 'main');

    // Component Registry Service (Manages all service relationships)
    await CentralComponentRegistryService().initialize();
    logger.info('✓ CentralComponentRegistryService initialized', 'main');

    // Future: App Initializer for complex initialization logic
    // await AppInitializer().initialize();

    logger.info('Application Core Layer initialization completed', 'main');

  } catch (e) {
    logger.error('Application Core Layer initialization failed: $e', 'main');
    rethrow;
  }
}

/// Phase 3: Domain Layer Initialization
/// Core business logic services
Future<void> _initializeDomainLayer() async {
  final logger = LoggingService();

  try {
    logger.info('Initializing Domain Layer', 'main');

    // Core domain services (can be initialized in parallel where possible)

    // File Management (Core business functionality)
    await AdvancedFileManagerService().initialize();
    logger.info('✓ AdvancedFileManagerService initialized', 'main');

    // Network Services (For file operations)
    await FTPClientService().initialize();
    logger.info('✓ FTPClientService initialized', 'main');

    // Database Services (Data persistence)
    await SupabaseService().initialize();
    logger.info('✓ SupabaseService initialized', 'main');

    // Caching Services (Performance optimization)
    await AdvancedCachingService().initialize();
    logger.info('✓ AdvancedCachingService initialized', 'main');

    logger.info('Domain Layer initialization completed', 'main');

  } catch (e) {
    logger.error('Domain Layer initialization failed: $e', 'main');
    rethrow;
  }
}

/// Phase 4: Application Layer Initialization
/// Use case implementations and application-specific logic
Future<void> _initializeApplicationLayer() async {
  final logger = LoggingService();

  try {
    logger.info('Initializing Application Layer', 'main');

    // Testing and Quality Assurance
    await ComprehensiveTestingStrategyService().initialize();
    logger.info('✓ ComprehensiveTestingStrategyService initialized', 'main');

    // Future: Analytics and Performance Services
    // await AdvancedAnalyticsService().initialize();
    // await AdvancedPerformanceService().initialize();

    logger.info('Application Layer initialization completed', 'main');

  } catch (e) {
    logger.error('Application Layer initialization failed: $e', 'main');
    rethrow;
  }
}

/// Phase 5: Infrastructure Services Layer Initialization
/// External integrations and communications
Future<void> _initializeInfrastructureServicesLayer() async {
  final logger = LoggingService();

  try {
    logger.info('Initializing Infrastructure Services Layer', 'main');

    // Cloud Storage Integration
    await CloudStorageService().initialize();
    logger.info('✓ CloudStorageService initialized', 'main');

    // Advanced File Operations
    await AdvancedFileOperationsService().initialize();
    logger.info('✓ AdvancedFileOperationsService initialized', 'main');

    // Future: Notification services, external APIs, etc.
    // await NotificationService().initialize();

    logger.info('Infrastructure Services Layer initialization completed', 'main');

  } catch (e) {
    logger.error('Infrastructure Services Layer initialization failed: $e', 'main');
    rethrow;
  }
}

/// Emergency Initialization Fallback
/// Used when normal initialization fails
Future<void> _emergencyInitialization() async {
  try {
    debugPrint('Attempting emergency initialization...');

    // Minimal services for emergency operation
    await CentralConfig.instance.initialize();
    await LoggingService().initialize();

    LoggingService().error('Application started in emergency mode', 'main');

  } catch (e) {
    // Absolute fallback - console only
    debugPrint('CRITICAL: Even emergency initialization failed: $e');
  }
}
