import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Domain Services (Business Logic)
import '../domain/services/file_management/advanced_file_manager_service.dart';
import '../domain/services/network/ftp_client_service.dart';
import '../domain/services/database/supabase_service.dart';

// Application Services (Use Cases)
import '../application/services/testing/comprehensive_testing_strategy_service.dart';

// Presentation Providers
import 'providers/app_providers.dart';

/// Application Providers for Dependency Injection
/// Organized by architectural layer following clean architecture principles
Future<List<Override>> getAppProviders() async {
  return [
    // === DOMAIN LAYER PROVIDERS ===
    // Core business services
    advancedFileManagerServiceProvider.overrideWithValue(
      AdvancedFileManagerService(),
    ),

    ftpClientServiceProvider.overrideWithValue(
      FTPClientService(),
    ),

    supabaseServiceProvider.overrideWithValue(
      SupabaseService(),
    ),

    // === APPLICATION LAYER PROVIDERS ===
    // Use case implementations
    comprehensiveTestingStrategyServiceProvider.overrideWithValue(
      ComprehensiveTestingStrategyService(),
    ),

    // === INFRASTRUCTURE LAYER PROVIDERS ===
    // External services (already initialized in main.dart)

    // === PRESENTATION LAYER PROVIDERS ===
    // UI state management providers
    // TODO: Add UI state providers as needed
  ];
}

/// Domain Service Providers
final advancedFileManagerServiceProvider = Provider<AdvancedFileManagerService>((ref) {
  throw UnimplementedError('AdvancedFileManagerService must be overridden');
});

final ftpClientServiceProvider = Provider<FTPClientService>((ref) {
  throw UnimplementedError('FTPClientService must be overridden');
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  throw UnimplementedError('SupabaseService must be overridden');
});

/// Application Service Providers
final comprehensiveTestingStrategyServiceProvider = Provider<ComprehensiveTestingStrategyService>((ref) {
  throw UnimplementedError('ComprehensiveTestingStrategyService must be overridden');
});

/// Infrastructure Service Providers
final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  throw UnimplementedError('CloudStorageService must be overridden');
});

final advancedFileOperationsServiceProvider = Provider<AdvancedFileOperationsService>((ref) {
  throw UnimplementedError('AdvancedFileOperationsService must be overridden');
});
