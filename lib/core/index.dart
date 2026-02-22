/// Core Module Index
///
/// This file provides a centralized export of all core functionality
/// organized by logical domains for better maintainability and imports.
///
/// Organized Structure:
/// - config/: Configuration and dependency management
/// - security/: Security, encryption, and validation
/// - network/: Network operations and connectivity
/// - ai/: AI and machine learning services
/// - ui/: User interface components and utilities
/// - services/: Core application services
/// - utils/: Utility functions and helpers

// Configuration and Dependency Management
export 'config/central_config.dart';
export 'config/component_factory.dart';
export 'config/component_registry.dart';
export 'config/dependency_injection.dart';
export 'config/constants.dart';

// Security and Validation
export 'security/security_manager.dart';
export 'security/security_engine.dart';

// Network and Connectivity
export 'network/network_discovery_service.dart';
export 'network/virtual_drive_service.dart';
export 'network/offline_manager.dart';

// AI and Machine Learning
export 'ai/document_ai_service.dart';
export 'ai/intelligent_categorization_service.dart';

// User Interface
export 'ui/accessibility_manager.dart';
export 'ui/app_router.dart';
export 'ui/error_boundary.dart';
export 'ui/ui_helper.dart';

// Services
export 'services/plugin_manager.dart';
export 'services/collaboration_service.dart';
export 'services/performance_monitor.dart';
export 'services/logging_service.dart';
export 'services/notification_service.dart';

// Utilities and Extensions
export 'utils.dart';
export 'extensions.dart';

// Legacy exports (to be phased out)
export 'enhanced_parameterization.dart' show ParameterizedComponent;
export 'input_validator.dart';
export 'base_component.dart';
