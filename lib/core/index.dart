// Core Layer Index - Enterprise Services
// ============================================================================
// This file exports all core services and infrastructure components
// for the iSuite Pro enterprise application.
//
// Core Layer Responsibilities:
// - Enterprise services (analytics, security, backup, etc.)
// - Infrastructure components (monitoring, error handling, etc.)
// - Configuration management
// - Utilities and constants
//
// Architecture: Clean Architecture - Core/Infrastructure Layer
// ============================================================================

// Configuration
export 'config/central_config.dart';

// Services
export 'services/accessibility_system.dart';
export 'services/advanced_security_system.dart';
export 'services/advanced_settings_system.dart';
export 'services/analytics_system.dart';
export 'services/backup_restore_system.dart';
export 'services/crash_reporting_system.dart';
export 'services/deployment_system.dart';
export 'services/internationalization_system.dart';
export 'services/realtime_collaboration_system.dart';
export 'services/secure_api_client.dart';

// Infrastructure
export 'infrastructure/error_recovery_service.dart';
export 'infrastructure/performance_monitor.dart';
export 'infrastructure/logging_service.dart';

// Constants
export 'constants.dart';

// Utils
export 'utils/extensions.dart';
export 'utils/utils.dart';

// All core exports
library i_suite_core;
