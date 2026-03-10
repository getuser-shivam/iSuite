// Data Layer Index - Data Access
// ============================================================================
// This file exports all data layer components
// for the iSuite Pro enterprise application.
//
// Data Layer Responsibilities:
// - Repository implementations
// - Data source implementations
// - Data models and DTOs
// - Database access and APIs
//
// Architecture: Clean Architecture - Data Layer
// ============================================================================

// Repositories
export 'repositories/user_repository_impl.dart';
export 'repositories/file_repository_impl.dart';
export 'repositories/network_repository_impl.dart';
export 'repositories/analytics_repository_impl.dart';
export 'repositories/ftp_repository_impl.dart';

// Data Sources
export 'datasources/user_remote_data_source.dart';
export 'datasources/file_local_data_source.dart';
export 'datasources/network_api_data_source.dart';
export 'datasources/analytics_cloud_data_source.dart';
export 'datasources/ftp_datasource.dart';

// Models
export 'models/user_model.dart';
export 'models/file_model.dart';
export 'models/network_model.dart';
export 'models/analytics_model.dart';

// All data exports
library i_suite_data;
