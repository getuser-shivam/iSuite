/// Core Library - Enterprise iSuite Foundation
/// Comprehensive collection of enterprise-grade services, utilities, and components
/// organized in clean architecture following separation of concerns principles.

library core;

// Export configuration management (Foundation)
export 'config/central_config.dart';
export 'config/index.dart';

// Export logging services (Infrastructure)
export 'utils/logging/index.dart';

// Export core utilities (Foundation)
export 'utils/index.dart';

// Export core services (Business Logic)
export 'services/index.dart';

// Export managers (Business Logic)
export 'managers/index.dart';

// Export models (Data)
export 'models/index.dart';

// Export providers (State Management)
export 'providers/index.dart';

// Export UI components (Presentation)
export 'ui/index.dart';

// Core constants and extensions (Foundation)
export 'utils/constants.dart';
export 'utils/extensions.dart';

// Core component base classes (Foundation)
export 'models/base_component.dart';

// Core dependency injection (Infrastructure)
export 'utils/dependency_injection.dart';

// Core error handling (Infrastructure)
export 'utils/error_boundary.dart';

// Core cross-platform optimization (Infrastructure)
export 'utils/cross_platform_optimizer.dart';

// Core theme and UI utilities (Presentation)
export 'utils/app_theme.dart';
export 'utils/theme_provider.dart';
export 'utils/ui_helper.dart';

// Core routing (Presentation)
export 'utils/app_router.dart';

// Core component factory (Foundation)
export 'utils/component_factory.dart';
export 'utils/component_registry.dart';

// Core input validation (Business Logic)
export 'utils/input_validator.dart';

// Core data table utilities (Presentation)
export 'utils/enhanced_data_table.dart';

// Core search delegate (Presentation)
export 'utils/enhanced_search_delegate.dart';

// Core secure storage (Infrastructure)
export 'utils/enhanced_secure_storage.dart';

// Core parameterization utilities (Foundation)
export 'utils/enhanced_parameterization.dart';

// Core framework integration (Infrastructure)
export 'utils/free_framework_integrator.dart';
