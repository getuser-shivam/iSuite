import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:iSuite/core/logging/logging_service.dart';
import 'package:iSuite/core/config/central_config.dart';

/// Advanced Security Service for iSuite
///
/// Provides enterprise-grade security features including encryption,
/// secure communication, audit logging, and compliance management.

class AdvancedSecurityService {
  static final AdvancedSecurityService _instance =
      AdvancedSecurityService._internal();
  factory AdvancedSecurityService() => _instance;
  AdvancedSecurityService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;

  bool _isInitialized = false;
  late Encrypter _encrypter;
  late Key _encryptionKey;
  late IV _initializationVector;

  // Security event tracking
  final List<SecurityEvent> _securityEvents = [];
  final Map<String, SecurityPolicy> _securityPolicies = {};

  // Audit logging
  final List<AuditEntry> _auditLog = [];
  final Map<String, ComplianceCheck> _complianceChecks = {};

  /// Initialize the advanced security service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Advanced Security Service', 'Security');

      // Register with CentralConfig with comprehensive parameterization
      await _config.registerComponent('AdvancedSecurityService', '1.0.0',
          'Advanced security service with encryption, authentication, access control, audit logging, threat detection, and compliance using comprehensive centralized parameterization',
          dependencies: [
            'CentralConfig',
            'EncryptionService',
            'AuditLoggingService',
            'ThreatDetectionService'
          ],
          parameters: {
            // === ENCRYPTION ===
            'security.encryption.enabled': _config.getParameter(
                'security.encryption.enabled',
                defaultValue: true),
            'security.encryption.algorithm': _config.getParameter(
                'security.encryption.algorithm',
                defaultValue: 'AES-256-GCM'),
            'security.encryption.key_rotation_days': _config.getParameter(
                'security.encryption.key_rotation_days',
                defaultValue: 90),
            'security.encryption.key_derivation': _config.getParameter(
                'security.encryption.key_derivation',
                defaultValue: 'PBKDF2'),
            'security.encryption.certificate_validation': _config.getParameter(
                'security.encryption.certificate_validation',
                defaultValue: true),

            // === AUTHENTICATION ===
            'security.auth.multi_factor_enabled': _config.getParameter(
                'security.auth.multi_factor_enabled',
                defaultValue: true),
            'security.auth.session_timeout_minutes': _config.getParameter(
                'security.auth.session_timeout_minutes',
                defaultValue: 30),
            'security.auth.password_policy_complexity': _config.getParameter(
                'security.auth.password_policy_complexity',
                defaultValue: 'strong'),
            'security.auth.login_attempt_limit': _config.getParameter(
                'security.auth.login_attempt_limit',
                defaultValue: 5),
            'security.auth.account_lockout_minutes': _config.getParameter(
                'security.auth.account_lockout_minutes',
                defaultValue: 15),
            'security.auth.biometric_auth_enabled': _config.getParameter(
                'security.auth.biometric_auth_enabled',
                defaultValue: true),
            'security.auth.oauth_providers': _config.getParameter(
                'security.auth.oauth_providers',
                defaultValue: 'google,microsoft,github'),

            // Compliance settings
            'security.compliance.gdpr_enabled': true,
            'security.compliance.soc2_enabled': true,
            'security.compliance.auto_reporting': true,

            // Threat detection settings
            'security.threat_detection.enabled': true,
            'security.threat_detection.anomaly_threshold': 0.8,
            'security.threat_detection.block_suspicious': true,

            // Key management settings
            'security.key_management.auto_rotate': true,
            'security.key_management.backup_enabled': true,
          });

      // Initialize encryption
      await _initializeEncryption();

      // Load security policies
      await _loadSecurityPolicies();

      // Initialize compliance checks
      await _initializeComplianceChecks();

      _isInitialized = true;
      _logger.info(
          'Advanced Security Service initialized successfully', 'Security');
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to initialize Advanced Security Service', 'Security',
          error: e, stackTrace: stackTrace);
      // Continue with limited functionality
      _isInitialized = true;
    }
  }

  Future<void> _initializeEncryption() async {
    // Generate or load encryption key
    final keyString = await _config
        .getParameter('security.encryption.master_key', defaultValue: '');

    if (keyString.isEmpty) {
      // Generate a new random key
      _encryptionKey = Key.fromSecureRandom(32); // AES-256
      // In production, this key should be securely stored and managed
      await _config.setParameter(
          'security.encryption.master_key', base64Encode(_encryptionKey.bytes));
    } else {
      _encryptionKey = Key(base64Decode(keyString));
    }

    // Generate initialization vector
    _initializationVector = IV.fromSecureRandom(16);

    // Create encrypter
    _encrypter = Encrypter(AES(_encryptionKey));

    _logger.info('Encryption initialized with AES-256', 'Security');
  }

  Future<void> _loadSecurityPolicies() async {
    // Define default security policies
    _securityPolicies['data_encryption'] = SecurityPolicy(
      name: 'Data Encryption Policy',
      description:
          'All sensitive data must be encrypted at rest and in transit',
      rules: [
        'Encrypt PII data automatically',
        'Use AES-256 for data encryption',
        'Rotate encryption keys every 90 days',
        'Secure key storage and management',
      ],
      severity: SecuritySeverity.high,
      automated: true,
    );

    _securityPolicies['access_control'] = SecurityPolicy(
      name: 'Access Control Policy',
      description: 'Implement role-based access control for all resources',
      rules: [
        'Authenticate all user requests',
        'Authorize based on user roles and permissions',
        'Implement session management and timeouts',
        'Log all access attempts and failures',
      ],
      severity: SecuritySeverity.high,
      automated: true,
    );

    _securityPolicies['audit_logging'] = SecurityPolicy(
      name: 'Audit Logging Policy',
      description: 'Comprehensive logging of all security-relevant events',
      rules: [
        'Log authentication events',
        'Log authorization decisions',
        'Log data access and modifications',
        'Log security policy violations',
        'Retain logs for compliance period',
      ],
      severity: SecuritySeverity.medium,
      automated: true,
    );

    _logger.info(
        'Security policies loaded: ${_securityPolicies.length} policies',
        'Security');
  }

  Future<void> _initializeComplianceChecks() async {
    _complianceChecks['gdpr'] = ComplianceCheck(
      standard: 'GDPR',
      enabled: await _config.getParameter('security.compliance.gdpr_enabled',
          defaultValue: true),
      requirements: [
        'Data minimization',
        'Purpose limitation',
        'Consent management',
        'Data subject rights',
        'Data breach notification',
        'Privacy by design',
      ],
      lastAudit: DateTime.now(),
      complianceScore: 0.0,
    );

    _complianceChecks['soc2'] = ComplianceCheck(
      standard: 'SOC 2',
      enabled: await _config.getParameter('security.compliance.soc2_enabled',
          defaultValue: true),
      requirements: [
        'Security',
        'Availability',
        'Processing integrity',
        'Confidentiality',
        'Privacy',
      ],
      lastAudit: DateTime.now(),
      complianceScore: 0.0,
    );

    _logger.info(
        'Compliance checks initialized: ${_complianceChecks.length} standards',
        'Security');
  }

  /// Encrypt data using AES-256
  Future<String> encryptData(String plainText) async {
    if (!_isInitialized) await initialize();

    try {
      final encrypted =
          _encrypter.encrypt(plainText, iv: _initializationVector);
      final result =
          '${base64Encode(_initializationVector.bytes)}:${encrypted.base64}';

      await _logSecurityEvent(
          SecurityEventType.dataEncrypted, 'Data encryption successful',
          metadata: {'data_size': plainText.length});

      return result;
    } catch (e) {
      await _logSecurityEvent(
          SecurityEventType.encryptionFailed, 'Data encryption failed',
          metadata: {'error': e.toString()});
      throw SecurityException('Encryption failed: ${e.toString()}');
    }
  }

  /// Decrypt data using AES-256
  Future<String> decryptData(String encryptedData) async {
    if (!_isInitialized) await initialize();

    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw SecurityException('Invalid encrypted data format');
      }

      final iv = IV(base64Decode(parts[0]));
      final encrypted = Encrypted(base64Decode(parts[1]));
      final decrypted = _encrypter.decrypt(encrypted, iv: iv);

      await _logSecurityEvent(
          SecurityEventType.dataDecrypted, 'Data decryption successful');

      return decrypted;
    } catch (e) {
      await _logSecurityEvent(
          SecurityEventType.decryptionFailed, 'Data decryption failed',
          metadata: {'error': e.toString()});
      throw SecurityException('Decryption failed: ${e.toString()}');
    }
  }

  /// Generate secure hash for data integrity
  String generateSecureHash(String data) {
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify data integrity using hash
  bool verifyDataIntegrity(String data, String expectedHash) {
    final actualHash = generateSecureHash(data);
    return actualHash == expectedHash;
  }

  /// Log security event for audit trail
  Future<void> _logSecurityEvent(
    SecurityEventType type,
    String description, {
    String? userId,
    String? resource,
    Map<String, dynamic>? metadata,
  }) async {
    final event = SecurityEvent(
      id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      timestamp: DateTime.now(),
      description: description,
      userId: userId,
      resource: resource,
      metadata: metadata ?? {},
    );

    _securityEvents.add(event);

    // Keep only last 1000 events in memory
    if (_securityEvents.length > 1000) {
      _securityEvents.removeRange(0, _securityEvents.length - 1000);
    }

    // Log to audit system
    await _logAuditEntry('security_event', event.toString(), userId: userId);

    // Log to security logger
    _logger.info('Security Event: ${type.name} - $description', 'Security');
  }

  /// Log audit entry for compliance
  Future<void> _logAuditEntry(
    String action,
    String details, {
    String? userId,
    String? resource,
    String? ipAddress,
    Map<String, dynamic>? additionalData,
  }) async {
    final entry = AuditEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      action: action,
      userId: userId,
      resource: resource,
      ipAddress: ipAddress,
      details: details,
      additionalData: additionalData ?? {},
    );

    _auditLog.add(entry);

    // Keep only last 5000 audit entries in memory
    if (_auditLog.length > 5000) {
      _auditLog.removeRange(0, _auditLog.length - 5000);
    }

    // In production, this would be persisted to secure storage
    _logger.info('Audit Entry: $action - $details', 'Audit');
  }

  /// Check compliance against standards
  Future<ComplianceReport> checkCompliance({String? standard}) async {
    final report = ComplianceReport(
      timestamp: DateTime.now(),
      standards: {},
      overallScore: 0.0,
      violations: [],
      recommendations: [],
    );

    final standardsToCheck =
        standard != null ? [standard] : _complianceChecks.keys;

    for (final std in standardsToCheck) {
      final check = _complianceChecks[std];
      if (check != null && check.enabled) {
        final complianceResult = await _evaluateCompliance(check);
        report.standards[std] = complianceResult;
      }
    }

    // Calculate overall score
    if (report.standards.isNotEmpty) {
      final scores = report.standards.values.map((r) => r.score).toList();
      report.overallScore = scores.reduce((a, b) => a + b) / scores.length;
    }

    // Generate recommendations
    report.recommendations = _generateComplianceRecommendations(report);

    return report;
  }

  Future<ComplianceResult> _evaluateCompliance(ComplianceCheck check) async {
    // Simplified compliance evaluation
    // In production, this would include detailed checks
    double score = 0.0;
    final violations = <String>[];

    // Check audit logging
    if (_auditLog.isEmpty) {
      violations.add('No audit logs found');
    } else {
      score += 0.3;
    }

    // Check encryption
    if (_isInitialized) {
      score += 0.3;
    } else {
      violations.add('Encryption not properly initialized');
    }

    // Check security policies
    if (_securityPolicies.isNotEmpty) {
      score += 0.4;
    } else {
      violations.add('No security policies defined');
    }

    return ComplianceResult(
      standard: check.standard,
      score: score.clamp(0.0, 1.0),
      violations: violations,
      lastChecked: DateTime.now(),
    );
  }

  List<String> _generateComplianceRecommendations(ComplianceReport report) {
    final recommendations = <String>[];

    for (final entry in report.standards.entries) {
      final result = entry.value;
      if (result.score < 0.8) {
        recommendations.add(
            'Improve ${entry.key} compliance score (currently ${(result.score * 100).round()}%)');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('All compliance standards are adequately met');
    }

    return recommendations;
  }

  /// Detect security threats and anomalies
  Future<ThreatDetectionResult> detectThreats() async {
    final result = ThreatDetectionResult(
      timestamp: DateTime.now(),
      threats: [],
      anomalies: [],
      riskLevel: ThreatRiskLevel.low,
      recommendations: [],
    );

    // Analyze security events for patterns
    final recentEvents = _securityEvents
        .where((e) =>
            e.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 24))))
        .toList();

    // Check for brute force attempts
    final failedAuthEvents = recentEvents
        .where((e) => e.type == SecurityEventType.authenticationFailed)
        .toList();

    if (failedAuthEvents.length > 10) {
      result.threats.add(SecurityThreat(
        type: ThreatType.bruteForce,
        severity: ThreatSeverity.high,
        description:
            '${failedAuthEvents.length} failed authentication attempts detected',
        detectedAt: DateTime.now(),
      ));
      result.riskLevel = ThreatRiskLevel.high;
    }

    // Check for unusual access patterns
    final accessEvents = recentEvents
        .where((e) => e.type == SecurityEventType.resourceAccessed)
        .toList();

    // Simple anomaly detection (in production, use ML models)
    if (accessEvents.length > 100) {
      result.anomalies.add(SecurityAnomaly(
        type: AnomalyType.unusualTraffic,
        confidence: 0.8,
        description: 'High volume of resource access detected',
        detectedAt: DateTime.now(),
      ));
    }

    // Generate recommendations
    result.recommendations = _generateThreatRecommendations(result);

    return result;
  }

  List<String> _generateThreatRecommendations(ThreatDetectionResult result) {
    final recommendations = <String>[];

    for (final threat in result.threats) {
      switch (threat.type) {
        case ThreatType.bruteForce:
          recommendations
              .add('Implement rate limiting for authentication endpoints');
          recommendations.add('Enable multi-factor authentication');
          break;
        case ThreatType.suspiciousAccess:
          recommendations.add('Review access control policies');
          recommendations.add('Implement session timeouts');
          break;
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('No immediate security threats detected');
    }

    return recommendations;
  }

  /// Generate security report
  Future<SecurityReport> generateSecurityReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final report = SecurityReport(
      period: DateRange(start, end),
      generatedAt: DateTime.now(),
      summary: {},
      events: [],
      threats: [],
      compliance: {},
      recommendations: [],
    );

    // Filter events for the period
    final periodEvents = _securityEvents
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();

    final periodAuditEntries = _auditLog
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();

    // Generate summary
    report.summary = {
      'total_security_events': periodEvents.length,
      'total_audit_entries': periodAuditEntries.length,
      'unique_users': periodEvents
          .map((e) => e.userId)
          .where((id) => id != null)
          .toSet()
          .length,
      'critical_events':
          periodEvents.where((e) => e.type.name.contains('Failed')).length,
    };

    // Include recent events
    report.events = periodEvents.take(50).toList();

    // Include threat detection
    final threatResult = await detectThreats();
    report.threats = threatResult.threats;

    // Include compliance status
    final complianceReport = await checkCompliance();
    report.compliance = complianceReport.standards;

    // Generate recommendations
    report.recommendations = _generateSecurityRecommendations(report);

    return report;
  }

  List<String> _generateSecurityRecommendations(SecurityReport report) {
    final recommendations = <String>[];

    // Analyze event patterns
    final criticalEvents = report.summary['critical_events'] as int? ?? 0;
    if (criticalEvents > 10) {
      recommendations.add(
          'High number of critical security events detected - review security policies');
    }

    // Analyze threats
    if (report.threats.isNotEmpty) {
      recommendations.add(
          'Security threats detected - implement immediate remediation measures');
    }

    // Analyze compliance
    for (final entry in report.compliance.entries) {
      if (entry.value.score < 0.8) {
        recommendations.add(
            'Improve ${entry.key} compliance (score: ${(entry.value.score * 100).round()}%)');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('Security posture is strong - continue monitoring');
    }

    return recommendations;
  }

  /// Rotate encryption keys
  Future<void> rotateEncryptionKeys() async {
    try {
      // Generate new key
      final newKey = Key.fromSecureRandom(32);

      // In production, securely backup old key and transition gradually
      _encryptionKey = newKey;
      _initializationVector = IV.fromSecureRandom(16);

      // Update stored key
      await _config.setParameter(
          'security.encryption.master_key', base64Encode(_encryptionKey.bytes));

      await _logSecurityEvent(
          SecurityEventType.keyRotated, 'Encryption keys rotated successfully');

      _logger.info('Encryption keys rotated successfully', 'Security');
    } catch (e) {
      await _logSecurityEvent(
          SecurityEventType.keyRotationFailed, 'Key rotation failed',
          metadata: {'error': e.toString()});
      throw SecurityException('Key rotation failed: ${e.toString()}');
    }
  }

  // Getters
  bool get isInitialized => _isInitialized;
  List<SecurityEvent> get securityEvents => List.from(_securityEvents);
  List<AuditEntry> get auditLog => List.from(_auditLog);
  Map<String, SecurityPolicy> get securityPolicies =>
      Map.from(_securityPolicies);
  Map<String, ComplianceCheck> get complianceChecks =>
      Map.from(_complianceChecks);
}

/// Supporting classes and enums

enum SecurityEventType {
  authenticationSuccess,
  authenticationFailed,
  authorizationGranted,
  authorizationDenied,
  resourceAccessed,
  dataEncrypted,
  dataDecrypted,
  keyRotated,
  keyRotationFailed,
  encryptionFailed,
  decryptionFailed,
  policyViolation,
  threatDetected,
}

enum ThreatType {
  bruteForce,
  suspiciousAccess,
  dataExfiltration,
  unauthorizedAccess,
  malwareDetected,
}

enum ThreatSeverity {
  low,
  medium,
  high,
  critical,
}

enum ThreatRiskLevel {
  low,
  medium,
  high,
  critical,
}

enum AnomalyType {
  unusualTraffic,
  unusualLoginPattern,
  unusualDataAccess,
  unusualResourceUsage,
}

class SecurityEvent {
  final String id;
  final SecurityEventType type;
  final DateTime timestamp;
  final String description;
  final String? userId;
  final String? resource;
  final Map<String, dynamic> metadata;

  SecurityEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.description,
    this.userId,
    this.resource,
    required this.metadata,
  });

  @override
  String toString() =>
      '[$timestamp] $type: $description (User: $userId, Resource: $resource)';
}

class AuditEntry {
  final String id;
  final DateTime timestamp;
  final String action;
  final String? userId;
  final String? resource;
  final String? ipAddress;
  final String details;
  final Map<String, dynamic> additionalData;

  AuditEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    this.userId,
    this.resource,
    this.ipAddress,
    required this.details,
    required this.additionalData,
  });
}

class SecurityPolicy {
  final String name;
  final String description;
  final List<String> rules;
  final SecuritySeverity severity;
  final bool automated;

  SecurityPolicy({
    required this.name,
    required this.description,
    required this.rules,
    required this.severity,
    required this.automated,
  });
}

enum SecuritySeverity {
  low,
  medium,
  high,
  critical,
}

class ComplianceCheck {
  final String standard;
  final bool enabled;
  final List<String> requirements;
  final DateTime lastAudit;
  double complianceScore;

  ComplianceCheck({
    required this.standard,
    required this.enabled,
    required this.requirements,
    required this.lastAudit,
    required this.complianceScore,
  });
}

class ComplianceResult {
  final String standard;
  final double score;
  final List<String> violations;
  final DateTime lastChecked;

  ComplianceResult({
    required this.standard,
    required this.score,
    required this.violations,
    required this.lastChecked,
  });
}

class ComplianceReport {
  final DateTime timestamp;
  final Map<String, ComplianceResult> standards;
  final double overallScore;
  final List<String> violations;
  final List<String> recommendations;

  ComplianceReport({
    required this.timestamp,
    required this.standards,
    required this.overallScore,
    required this.violations,
    required this.recommendations,
  });
}

class SecurityThreat {
  final ThreatType type;
  final ThreatSeverity severity;
  final String description;
  final DateTime detectedAt;

  SecurityThreat({
    required this.type,
    required this.severity,
    required this.description,
    required this.detectedAt,
  });
}

class SecurityAnomaly {
  final AnomalyType type;
  final double confidence;
  final String description;
  final DateTime detectedAt;

  SecurityAnomaly({
    required this.type,
    required this.confidence,
    required this.description,
    required this.detectedAt,
  });
}

class ThreatDetectionResult {
  final DateTime timestamp;
  final List<SecurityThreat> threats;
  final List<SecurityAnomaly> anomalies;
  final ThreatRiskLevel riskLevel;
  final List<String> recommendations;

  ThreatDetectionResult({
    required this.timestamp,
    required this.threats,
    required this.anomalies,
    required this.riskLevel,
    required this.recommendations,
  });
}

class SecurityReport {
  final DateRange period;
  final DateTime generatedAt;
  final Map<String, dynamic> summary;
  final List<SecurityEvent> events;
  final List<SecurityThreat> threats;
  final Map<String, ComplianceResult> compliance;
  final List<String> recommendations;

  SecurityReport({
    required this.period,
    required this.generatedAt,
    required this.summary,
    required this.events,
    required this.threats,
    required this.compliance,
    required this.recommendations,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
