// Shared Layer Index - Common Components
// ============================================================================
// This file exports all shared/common components
// for the iSuite Pro enterprise application.
//
// Shared Layer Responsibilities:
// - Common widgets and UI components
// - Shared models and utilities
// - Cross-cutting concerns
// - Reusable components
//
// Architecture: Clean Architecture - Shared Layer
/// ============================================================================

library i_suite_shared;

// Widgets
export 'widgets/custom_button.dart';
export 'widgets/loading_spinner.dart';
export 'widgets/error_dialog.dart';

// Models
export 'models/api_response.dart';
export 'models/pagination.dart';
export 'models/result.dart';

// Utils
export 'utils/date_formatter.dart';
export 'utils/string_extensions.dart';
export 'utils/validation_utils.dart';

// All shared exports
