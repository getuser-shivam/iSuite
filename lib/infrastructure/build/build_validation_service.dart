import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'build_optimization_service.dart';

/// Comprehensive Build Validation Service
/// Performs quality checks, security scans, and validation throughout the build process
class BuildValidationService {
  static final BuildValidationService _instance = BuildValidationService._internal();
  factory BuildValidationService() => _instance;
  BuildValidationService._internal();

  final BuildOptimizationService _buildOptimization = BuildOptimizationService();
  final StreamController<ValidationEvent> _validationEventController = StreamController.broadcast();

  Stream<ValidationEvent> get validationEvents => _validationEventController.stream;

  // Validation rules and configurations
  final Map<String, ValidationRule> _validationRules = {};
  final Map<String, SecurityRule> _securityRules = {};
  final Map<String, QualityThreshold> _qualityThresholds = {};

  bool _isInitialized = false;

  // Default quality thresholds
  static const QualityThreshold _defaultCodeQualityThreshold = QualityThreshold(
    minTestCoverage: 0.8,
    maxCyclomaticComplexity: 10,
    maxLinesPerFunction: 50,
    maxDuplicateLines: 0.05,
  );

  static const QualityThreshold _defaultSecurityThreshold = QualityThreshold(
    minTestCoverage: 0.9,
    maxCyclomaticComplexity: 5,
    maxLinesPerFunction: 30,
    maxDuplicateLines: 0.02,
  );

  /// Initialize validation service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadValidationRules();
      await _loadSecurityRules();
      await _initializeQualityThresholds();

      _isInitialized = true;
      _emitValidationEvent(ValidationEventType.serviceInitialized);

    } catch (e) {
      _emitValidationEvent(ValidationEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Perform comprehensive pre-build validation
  Future<PreBuildValidationResult> validatePreBuild(String projectPath) async {
    _emitValidationEvent(ValidationEventType.preBuildValidationStarted, details: projectPath);

    try {
      final results = await Future.wait([
        _validateProjectStructure(projectPath),
        _validateDependencies(projectPath),
        _validateConfigurationFiles(projectPath),
        _validateEnvironmentSetup(projectPath),
      ]);

      final overallSuccess = results.every((result) => result.success);
      final allErrors = results.expand((result) => result.errors).toList();
      final allWarnings = results.expand((result) => result.warnings).toList();

      final validationResult = PreBuildValidationResult(
        success: overallSuccess,
        projectPath: projectPath,
        validationResults: results,
        errors: allErrors,
        warnings: allWarnings,
        timestamp: DateTime.now(),
      );

      _emitValidationEvent(
        overallSuccess ? ValidationEventType.preBuildValidationPassed : ValidationEventType.preBuildValidationFailed,
        details: 'Errors: ${allErrors.length}, Warnings: ${allWarnings.length}'
      );

      return validationResult;

    } catch (e) {
      _emitValidationEvent(ValidationEventType.preBuildValidationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Perform comprehensive post-build validation
  Future<PostBuildValidationResult> validatePostBuild(
    String projectPath,
    List<BuildArtifact> artifacts,
    BuildMode mode,
  ) async {
    _emitValidationEvent(ValidationEventType.postBuildValidationStarted,
      details: 'Artifacts: ${artifacts.length}, Mode: $mode');

    try {
      final results = await Future.wait([
        _validateBuildArtifacts(artifacts),
        _validateCodeQuality(projectPath),
        _performSecurityScan(projectPath, artifacts),
        _validatePerformanceMetrics(projectPath),
        _validateTestCoverage(projectPath),
      ]);

      final overallSuccess = results.every((result) => result.success);
      final allErrors = results.expand((result) => result.errors).toList();
      final allWarnings = results.expand((result) => result.warnings).toList();

      // Determine quality score
      final qualityScore = _calculateQualityScore(results, mode);

      final validationResult = PostBuildValidationResult(
        success: overallSuccess,
        projectPath: projectPath,
        artifacts: artifacts,
        buildMode: mode,
        validationResults: results,
        qualityScore: qualityScore,
        errors: allErrors,
        warnings: allWarnings,
        timestamp: DateTime.now(),
      );

      _emitValidationEvent(
        overallSuccess ? ValidationEventType.postBuildValidationPassed : ValidationEventType.postBuildValidationFailed,
        details: 'Quality Score: ${(qualityScore * 100).round()}%, Errors: ${allErrors.length}, Warnings: ${allWarnings.length}'
      );

      return validationResult;

    } catch (e) {
      _emitValidationEvent(ValidationEventType.postBuildValidationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Perform continuous validation during development
  Future<ContinuousValidationResult> validateContinuous(String projectPath) async {
    try {
      final results = await Future.wait([
        _validateCodeStyle(projectPath),
        _validateSecurityIssues(projectPath),
        _validatePerformanceRegressions(projectPath),
      ]);

      final hasCriticalIssues = results.any((result) => result.errors.isNotEmpty);

      return ContinuousValidationResult(
        timestamp: DateTime.now(),
        projectPath: projectPath,
        validationResults: results,
        hasCriticalIssues: hasCriticalIssues,
      );

    } catch (e) {
      return ContinuousValidationResult(
        timestamp: DateTime.now(),
        projectPath: projectPath,
        validationResults: [],
        hasCriticalIssues: true,
        error: e.toString(),
      );
    }
  }

  /// Validate and optimize dependencies
  Future<DependencyValidationResult> validateDependencies(String projectPath) async {
    try {
      final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
      final pubspecLockFile = File(path.join(projectPath, 'pubspec.lock'));

      if (!await pubspecFile.exists()) {
        return DependencyValidationResult(
          success: false,
          errors: ['pubspec.yaml not found'],
          warnings: [],
        );
      }

      final pubspecContent = await pubspecFile.readAsString();
      final dependencies = _parsePubspecDependencies(pubspecContent);

      final errors = <String>[];
      final warnings = <String>[];

      // Check for vulnerable dependencies
      final vulnerabilities = await _checkDependencyVulnerabilities(dependencies);
      errors.addAll(vulnerabilities.map((v) => 'Vulnerable dependency: ${v.package} - ${v.description}'));

      // Check for outdated dependencies
      final outdated = await _checkOutdatedDependencies(projectPath);
      warnings.addAll(outdated.map((o) => 'Outdated dependency: ${o.package} (current: ${o.current}, latest: ${o.latest})'));

      // Check for license compatibility
      final licenseIssues = await _checkLicenseCompatibility(dependencies);
      warnings.addAll(licenseIssues.map((l) => 'License issue: ${l.package} - ${l.issue}'));

      // Check dependency tree size
      if (dependencies.length > 100) {
        warnings.add('Large dependency tree (${dependencies.length} packages) may impact build performance');
      }

      return DependencyValidationResult(
        success: errors.isEmpty,
        dependencyCount: dependencies.length,
        vulnerabilities: vulnerabilities,
        outdatedDependencies: outdated,
        licenseIssues: licenseIssues,
        errors: errors,
        warnings: warnings,
      );

    } catch (e) {
      return DependencyValidationResult(
        success: false,
        errors: [e.toString()],
        warnings: [],
      );
    }
  }

  /// Generate comprehensive validation report
  Future<String> generateValidationReport({
    required PreBuildValidationResult preBuildResult,
    required PostBuildValidationResult postBuildResult,
    bool includeRecommendations = true,
  }) async {
    final report = StringBuffer();
    report.writeln('Build Validation Report');
    report.writeln('Generated: ${DateTime.now()}');
    report.writeln('=' * 60);

    // Pre-build validation
    report.writeln('\nPRE-BUILD VALIDATION:');
    report.writeln('Status: ${preBuildResult.success ? 'PASSED' : 'FAILED'}');
    report.writeln('Project: ${preBuildResult.projectPath}');

    if (preBuildResult.errors.isNotEmpty) {
      report.writeln('\nErrors:');
      for (final error in preBuildResult.errors) {
        report.writeln('  • $error');
      }
    }

    if (preBuildResult.warnings.isNotEmpty) {
      report.writeln('\nWarnings:');
      for (final warning in preBuildResult.warnings) {
        report.writeln('  • $warning');
      }
    }

    // Post-build validation
    report.writeln('\nPOST-BUILD VALIDATION:');
    report.writeln('Status: ${postBuildResult.success ? 'PASSED' : 'FAILED'}');
    report.writeln('Build Mode: ${postBuildResult.buildMode}');
    report.writeln('Quality Score: ${(postBuildResult.qualityScore * 100).round()}%');
    report.writeln('Artifacts: ${postBuildResult.artifacts.length}');

    if (postBuildResult.errors.isNotEmpty) {
      report.writeln('\nErrors:');
      for (final error in postBuildResult.errors) {
        report.writeln('  • $error');
      }
    }

    if (postBuildResult.warnings.isNotEmpty) {
      report.writeln('\nWarnings:');
      for (final warning in postBuildResult.warnings) {
        report.writeln('  • $warning');
      }
    }

    if (includeRecommendations) {
      report.writeln('\nRECOMMENDATIONS:');
      final recommendations = _generateRecommendations(preBuildResult, postBuildResult);
      for (final recommendation in recommendations) {
        report.writeln('  • $recommendation');
      }
    }

    return report.toString();
  }

  // Private validation methods

  Future<ValidationResult> _validateProjectStructure(String projectPath) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Check for essential files
    final essentialFiles = [
      'pubspec.yaml',
      'lib/main.dart',
      'analysis_options.yaml',
    ];

    for (final file in essentialFiles) {
      if (!await File(path.join(projectPath, file)).exists()) {
        errors.add('Missing essential file: $file');
      }
    }

    // Check directory structure
    final essentialDirs = [
      'lib',
      'test',
    ];

    for (final dir in essentialDirs) {
      if (!await Directory(path.join(projectPath, dir)).exists()) {
        warnings.add('Missing recommended directory: $dir');
      }
    }

    // Check for common issues
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      if (!content.contains('flutter:')) {
        errors.add('pubspec.yaml missing Flutter configuration');
      }
    }

    return ValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<ValidationResult> _validateDependencies(String projectPath) async {
    final dependencyResult = await validateDependencies(projectPath);

    return ValidationResult(
      success: dependencyResult.success,
      errors: dependencyResult.errors,
      warnings: dependencyResult.warnings,
    );
  }

  Future<ValidationResult> _validateConfigurationFiles(String projectPath) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate analysis_options.yaml
    final analysisOptions = File(path.join(projectPath, 'analysis_options.yaml'));
    if (await analysisOptions.exists()) {
      final content = await analysisOptions.readAsString();
      if (!content.contains('linter:')) {
        warnings.add('analysis_options.yaml missing linter configuration');
      }
    } else {
      warnings.add('analysis_options.yaml not found (recommended for code quality)');
    }

    // Validate pubspec.yaml format
    final pubspec = File(path.join(projectPath, 'pubspec.yaml'));
    if (await pubspec.exists()) {
      final content = await pubspec.readAsString();
      if (!content.contains('name:') || !content.contains('version:')) {
        errors.add('pubspec.yaml missing required fields (name, version)');
      }
    }

    return ValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<ValidationResult> _validateEnvironmentSetup(String projectPath) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Check Flutter version
    try {
      final result = await Process.run('flutter', ['--version'], workingDirectory: projectPath);
      if (result.exitCode != 0) {
        errors.add('Flutter not found or not properly configured');
      } else {
        final version = result.stdout.toString();
        if (version.contains('1.')) {
          warnings.add('Using older Flutter version, consider upgrading');
        }
      }
    } catch (e) {
      errors.add('Cannot determine Flutter version: $e');
    }

    // Check Dart SDK
    try {
      final result = await Process.run('dart', ['--version'], workingDirectory: projectPath);
      if (result.exitCode != 0) {
        errors.add('Dart SDK not found or not properly configured');
      }
    } catch (e) {
      errors.add('Cannot determine Dart SDK version: $e');
    }

    return ValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<ValidationResult> _validateBuildArtifacts(List<BuildArtifact> artifacts) async {
    final errors = <String>[];
    final warnings = <String>[];

    for (final artifact in artifacts) {
      final file = File(artifact.path);

      if (!await file.exists()) {
        errors.add('Build artifact not found: ${artifact.path}');
        continue;
      }

      final stat = await file.stat();
      final actualSize = stat.size;

      // Check file size
      if (actualSize == 0) {
        errors.add('Build artifact is empty: ${artifact.path}');
      }

      // Check file modification time (should be recent)
      final age = DateTime.now().difference(stat.modified);
      if (age > Duration(hours: 1)) {
        warnings.add('Build artifact is old: ${artifact.path} (${age.inMinutes} minutes old)');
      }

      // Platform-specific validations
      if (artifact.path.endsWith('.apk')) {
        if (actualSize < 1024 * 1024) { // Less than 1MB
          warnings.add('APK file seems too small: ${artifact.path} (${(actualSize / 1024).round()}KB)');
        }
      } else if (artifact.path.endsWith('.ipa')) {
        if (actualSize < 5 * 1024 * 1024) { // Less than 5MB
          warnings.add('IPA file seems too small: ${artifact.path} (${(actualSize / 1024 / 1024).toStringAsFixed(1)}MB)');
        }
      }
    }

    return ValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<ValidationResult> _validateCodeQuality(String projectPath) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Run Flutter analyze
      final analyzeResult = await Process.run('flutter', ['analyze'], workingDirectory: projectPath);

      if (analyzeResult.exitCode != 0) {
        final output = analyzeResult.stdout.toString() + analyzeResult.stderr.toString();
        final issues = _parseAnalysisOutput(output);

        errors.addAll(issues.where((issue) => issue.severity == 'error').map((issue) => issue.message));
        warnings.addAll(issues.where((issue) => issue.severity == 'warning').map((issue) => issue.message));
      }

      // Check code metrics
      final metricsResult = await _analyzeCodeMetrics(projectPath);
      warnings.addAll(metricsResult.warnings);
      errors.addAll(metricsResult.errors);

    } catch (e) {
      errors.add('Code quality validation failed: $e');
    }

    return ValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<ValidationResult> _performSecurityScan(String projectPath, List<BuildArtifact> artifacts) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Check for hardcoded secrets
    final secretPatterns = [
      RegExp(r'api[_-]?key\s*[=:]\s*["\'][^"\']+["\']', caseSensitive: false),
      RegExp(r'secret[_-]?key\s*[=:]\s*["\'][^"\']+["\']', caseSensitive: false),
      RegExp(r'password\s*[=:]\s*["\'][^"\']+["\']', caseSensitive: false),
    ];

    final libDir = Directory(path.join(projectPath, 'lib'));
    if (await libDir.exists()) {
      await for (final file in libDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          final content = await file.readAsString();
          for (final pattern in secretPatterns) {
            if (pattern.hasMatch(content)) {
              errors.add('Potential hardcoded secret found in: ${file.path}');
            }
          }
        }
      }
    }

    // Check for debug code in release builds
    for (final artifact in artifacts) {
      if (artifact.path.contains('release') || artifact.path.contains('prod')) {
        warnings.add('Release build artifact found - ensure no debug code is included');
      }
    }

    return ValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<ValidationResult> _validatePerformanceMetrics(String projectPath) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Check bundle size
    final libDir = Directory(path.join(projectPath, 'lib'));
    if (await libDir.exists()) {
      int totalSize = 0;
      int fileCount = 0;

      await for (final file in libDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          totalSize += await file.length();
          fileCount++;
        }
      }

      if (totalSize > 5 * 1024 * 1024) { // 5MB
        warnings.add('Large codebase detected (${(totalSize / 1024 / 1024).toStringAsFixed(1)}MB, $fileCount files)');
      }
    }

    return ValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<ValidationResult> _validateTestCoverage(String projectPath) async {
    final errors = <String>[];
    final warnings = <String>[];

    final testDir = Directory(path.join(projectPath, 'test'));
    if (!await testDir.exists()) {
      warnings.add('No test directory found');
      return ValidationResult(success: true, errors: errors, warnings: warnings);
    }

    // Count test files
    int testFileCount = 0;
    await for (final file in testDir.list(recursive: true)) {
      if (file is File && file.path.endsWith('_test.dart')) {
        testFileCount++;
      }
    }

    if (testFileCount == 0) {
      warnings.add('No test files found');
    } else if (testFileCount < 5) {
      warnings.add('Limited test coverage (only $testFileCount test files)');
    }

    return ValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<ValidationResult> _validateCodeStyle(String projectPath) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Run dart format --dry-run
      final formatResult = await Process.run('dart', ['format', '--dry-run', '--set-exit-if-changed', '.'],
        workingDirectory: projectPath);

      if (formatResult.exitCode != 0) {
        warnings.add('Code formatting issues found - run "dart format ." to fix');
      }
    } catch (e) {
      warnings.add('Cannot check code formatting: $e');
    }

    return ValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  Future<ValidationResult> _validateSecurityIssues(String projectPath) async {
    // Placeholder for security validation
    return ValidationResult(
      success: true,
      errors: [],
      warnings: ['Security validation not fully implemented'],
    );
  }

  Future<ValidationResult> _validatePerformanceRegressions(String projectPath) async {
    // Placeholder for performance regression checks
    return ValidationResult(
      success: true,
      errors: [],
      warnings: ['Performance regression checks not fully implemented'],
    );
  }

  // Helper methods

  Future<void> _loadValidationRules() async {
    // Load custom validation rules
    _validationRules['email'] = ValidationRule(
      name: 'email',
      validator: (value) => value is String && _isValidEmail(value),
      description: 'Valid email format',
    );

    _validationRules['phone'] = ValidationRule(
      name: 'phone',
      validator: (value) => value is String && _isValidPhone(value),
      description: 'Valid phone number format',
    );
  }

  Future<void> _loadSecurityRules() async {
    // Load security validation rules
    _securityRules['no_hardcoded_secrets'] = SecurityRule(
      name: 'no_hardcoded_secrets',
      check: _checkNoHardcodedSecrets,
      severity: SecuritySeverity.critical,
      description: 'No hardcoded secrets or API keys',
    );

    _securityRules['secure_dependencies'] = SecurityRule(
      name: 'secure_dependencies',
      check: _checkSecureDependencies,
      severity: SecuritySeverity.high,
      description: 'Dependencies are from trusted sources',
    );
  }

  Future<void> _initializeQualityThresholds() async {
    _qualityThresholds['code'] = _defaultCodeQualityThreshold;
    _qualityThresholds['security'] = _defaultSecurityThreshold;
  }

  Map<String, dynamic> _parsePubspecDependencies(String content) {
    // Simplified parsing - in real implementation, use YAML parser
    final dependencies = <String, dynamic>{};
    // Implementation would parse actual pubspec.yaml
    return dependencies;
  }

  Future<List<Vulnerability>> _checkDependencyVulnerabilities(Map<String, dynamic> dependencies) async {
    // Placeholder - would integrate with vulnerability databases
    return [];
  }

  Future<List<OutdatedDependency>> _checkOutdatedDependencies(String projectPath) async {
    // Placeholder - would check pub outdated
    return [];
  }

  Future<List<LicenseIssue>> _checkLicenseCompatibility(Map<String, dynamic> dependencies) async {
    // Placeholder - would check license compatibility
    return [];
  }

  List<AnalysisIssue> _parseAnalysisOutput(String output) {
    // Parse flutter analyze output
    final issues = <AnalysisIssue>[];
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.contains('error') || line.contains('warning')) {
        final severity = line.contains('error') ? 'error' : 'warning';
        issues.add(AnalysisIssue(severity: severity, message: line.trim()));
      }
    }

    return issues;
  }

  Future<CodeMetricsResult> _analyzeCodeMetrics(String projectPath) async {
    // Placeholder for code metrics analysis
    return CodeMetricsResult(
      totalLines: 0,
      complexityScore: 0.0,
      errors: [],
      warnings: ['Code metrics analysis not fully implemented'],
    );
  }

  double _calculateQualityScore(List<ValidationResult> results, BuildMode mode) {
    if (results.isEmpty) return 0.0;

    final totalWeight = results.length;
    double totalScore = 0.0;

    for (final result in results) {
      final weight = _getValidationWeight(result);
      final score = result.success ? 1.0 : (result.warnings.isEmpty ? 0.0 : 0.5);
      totalScore += weight * score;
    }

    return totalScore / totalWeight;
  }

  double _getValidationWeight(ValidationResult result) {
    // Assign weights based on validation type
    return 1.0; // Equal weight for now
  }

  List<String> _generateRecommendations(
    PreBuildValidationResult preBuild,
    PostBuildValidationResult postBuild,
  ) {
    final recommendations = <String>[];

    if (!preBuild.success) {
      recommendations.add('Fix pre-build validation errors before proceeding');
    }

    if (postBuild.qualityScore < 0.8) {
      recommendations.add('Improve code quality to achieve higher quality score');
    }

    if (postBuild.errors.isNotEmpty) {
      recommendations.add('Address all post-build validation errors');
    }

    if (postBuild.warnings.length > 10) {
      recommendations.add('Review and fix validation warnings to improve code quality');
    }

    return recommendations;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[^\d+]'), ''));
  }

  Future<bool> _checkNoHardcodedSecrets(String content) {
    // Check for common secret patterns
    final secretPatterns = [
      RegExp(r'api[_-]?key\s*[=:]\s*["\'][^"\']+["\']', caseSensitive: false),
      RegExp(r'secret[_-]?key\s*[=:]\s*["\'][^"\']+["\']', caseSensitive: false),
    ];

    return Future.value(!secretPatterns.any((pattern) => pattern.hasMatch(content)));
  }

  Future<bool> _checkSecureDependencies(String content) {
    // Placeholder - would check dependency sources
    return Future.value(true);
  }

  void _emitValidationEvent(ValidationEventType type, {
    String? details,
    String? error,
  }) {
    final event = ValidationEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _validationEventController.add(event);
  }

  void dispose() {
    _validationEventController.close();
  }
}

/// Validation result base class
class ValidationResult {
  final bool success;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.success,
    required this.errors,
    required this.warnings,
  });
}

/// Pre-build validation result
class PreBuildValidationResult extends ValidationResult {
  final String projectPath;
  final List<ValidationResult> validationResults;
  final DateTime timestamp;

  PreBuildValidationResult({
    required super.success,
    required super.errors,
    required super.warnings,
    required this.projectPath,
    required this.validationResults,
    required this.timestamp,
  });
}

/// Post-build validation result
class PostBuildValidationResult extends ValidationResult {
  final String projectPath;
  final List<BuildArtifact> artifacts;
  final BuildMode buildMode;
  final List<ValidationResult> validationResults;
  final double qualityScore;
  final DateTime timestamp;

  PostBuildValidationResult({
    required super.success,
    required super.errors,
    required super.warnings,
    required this.projectPath,
    required this.artifacts,
    required this.buildMode,
    required this.validationResults,
    required this.qualityScore,
    required this.timestamp,
  });
}

/// Continuous validation result
class ContinuousValidationResult {
  final DateTime timestamp;
  final String projectPath;
  final List<ValidationResult> validationResults;
  final bool hasCriticalIssues;
  final String? error;

  ContinuousValidationResult({
    required this.timestamp,
    required this.projectPath,
    required this.validationResults,
    required this.hasCriticalIssues,
    this.error,
  });
}

/// Dependency validation result
class DependencyValidationResult extends ValidationResult {
  final int dependencyCount;
  final List<Vulnerability> vulnerabilities;
  final List<OutdatedDependency> outdatedDependencies;
  final List<LicenseIssue> licenseIssues;

  DependencyValidationResult({
    required super.success,
    required super.errors,
    required super.warnings,
    required this.dependencyCount,
    required this.vulnerabilities,
    required this.outdatedDependencies,
    required this.licenseIssues,
  });
}

/// Supporting data classes

class ValidationRule {
  final String name;
  final bool Function(dynamic value) validator;
  final String description;

  ValidationRule({
    required this.name,
    required this.validator,
    required this.description,
  });
}

class SecurityRule {
  final String name;
  final Future<bool> Function(String content) check;
  final SecuritySeverity severity;
  final String description;

  SecurityRule({
    required this.name,
    required this.check,
    required this.severity,
    required this.description,
  });
}

class QualityThreshold {
  final double minTestCoverage;
  final int maxCyclomaticComplexity;
  final int maxLinesPerFunction;
  final double maxDuplicateLines;

  const QualityThreshold({
    required this.minTestCoverage,
    required this.maxCyclomaticComplexity,
    required this.maxLinesPerFunction,
    required this.maxDuplicateLines,
  });
}

enum SecuritySeverity {
  low,
  medium,
  high,
  critical,
}

class Vulnerability {
  final String package;
  final String version;
  final String description;
  final SecuritySeverity severity;

  Vulnerability({
    required this.package,
    required this.version,
    required this.description,
    required this.severity,
  });
}

class OutdatedDependency {
  final String package;
  final String current;
  final String latest;

  OutdatedDependency({
    required this.package,
    required this.current,
    required this.latest,
  });
}

class LicenseIssue {
  final String package;
  final String issue;

  LicenseIssue({
    required this.package,
    required this.issue,
  });
}

class AnalysisIssue {
  final String severity;
  final String message;

  AnalysisIssue({
    required this.severity,
    required this.message,
  });
}

class CodeMetricsResult {
  final int totalLines;
  final double complexityScore;
  final List<String> errors;
  final List<String> warnings;

  CodeMetricsResult({
    required this.totalLines,
    required this.complexityScore,
    required this.errors,
    required this.warnings,
  });
}

/// Validation event types
enum ValidationEventType {
  serviceInitialized,
  initializationFailed,
  preBuildValidationStarted,
  preBuildValidationPassed,
  preBuildValidationFailed,
  postBuildValidationStarted,
  postBuildValidationPassed,
  postBuildValidationFailed,
}

/// Validation event
class ValidationEvent {
  final ValidationEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  ValidationEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}
