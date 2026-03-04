// Domain Layer Index - Business Logic
// ============================================================================
// This file exports all domain layer components
// for the iSuite Pro enterprise application.
//
// Domain Layer Responsibilities:
// - Business entities and models
// - Use cases and business logic
// - Repository interfaces and contracts
// - Domain services
//
// Architecture: Clean Architecture - Domain Layer
// ============================================================================

// Entities
export 'entities/user.dart';
export 'entities/file_entity.dart';
export 'entities/network_entity.dart';
export 'entities/analytics_entity.dart';
export 'entities/ftp_connection.dart';
export 'entities/ftp_file.dart';

// Use Cases
export 'usecases/get_user_profile.dart';
export 'usecases/upload_file.dart';
export 'usecases/search_files.dart';
export 'usecases/connect_to_network.dart';
export 'usecases/analyze_data.dart';
export 'usecases/connect_ftp_usecase.dart';

// Repositories
export 'repositories/user_repository.dart';
export 'repositories/file_repository.dart';
export 'repositories/network_repository.dart';
export 'repositories/analytics_repository.dart';
export 'repositories/ftp_repository.dart';

// Services
export 'services/user_service.dart';
export 'services/file_service.dart';
export 'services/network_service.dart';
export 'services/analytics_service.dart';

// All domain exports
library i_suite_domain;
