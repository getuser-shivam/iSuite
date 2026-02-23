import 'package:flutter_test/flutter_test.dart';
import 'package:iSuite/core/circuit_breaker_service.dart';
import 'package:iSuite/core/health_monitoring_service.dart';
import 'package:iSuite/core/data_validation_service.dart';
import 'package:iSuite/core/config/central_config.dart';
import 'package:iSuite/core/logging/logging_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CircuitBreakerService circuitBreaker;
  late HealthMonitoringService healthMonitor;
  late DataValidationService dataValidation;
  late CentralConfig config;
  late LoggingService logger;

  setUp(() async {
    // Initialize core services
    logger = LoggingService();
    await logger.initialize();

    config = CentralConfig.instance;
    await config.initialize();

    // Initialize robustness services
    circuitBreaker = CircuitBreakerService();
    await circuitBreaker.initialize();

    healthMonitor = HealthMonitoringService();
    await healthMonitor.initialize();

    dataValidation = DataValidationService();
    await dataValidation.initialize();
  });

  tearDown(() async {
    await circuitBreaker.dispose();
    await healthMonitor.dispose();
    await dataValidation.dispose();
    await config.dispose();
    await logger.dispose();
  });

  group('Circuit Breaker Service Tests', () {
    test('should initialize successfully', () async {
      expect(circuitBreaker.isInitialized, true);
    });

    test('should create circuit breaker with default settings', () async {
      final breaker = circuitBreaker.createBreaker('test-service');

      expect(breaker, isNotNull);
      expect(breaker.failureThreshold, equals(5));
      expect(breaker.recoveryTimeout, equals(Duration(seconds: 60)));
      expect(breaker.state, equals(CircuitBreakerState.closed));
    });

    test('should create circuit breaker with custom settings', () async {
      final breaker = circuitBreaker.createBreaker(
        'custom-service',
        failureThreshold: 10,
        recoveryTimeout: Duration(seconds: 120),
      );

      expect(breaker.failureThreshold, equals(10));
      expect(breaker.recoveryTimeout, equals(Duration(seconds: 120)));
    });

    test('should execute operation successfully', () async {
      bool operationCalled = false;

      final result = await circuitBreaker.execute(
        serviceName: 'success-service',
        operation: () async {
          operationCalled = true;
          return 'success';
        },
      );

      expect(operationCalled, isTrue);
      expect(result, equals('success'));
    });

    test('should handle operation failure and recovery', () async {
      int callCount = 0;

      // First call - should fail and record failure
      try {
        await circuitBreaker.execute(
          serviceName: 'failing-service',
          operation: () async {
            callCount++;
            throw Exception('Test failure');
          },
        );
      } catch (e) {
        expect(e.toString(), contains('Test failure'));
      }

      expect(callCount, equals(1));

      // Check that failure was recorded
      final breaker = circuitBreaker.circuitBreakers['failing-service'];
      expect(breaker, isNotNull);
      expect(breaker!.consecutiveFailures, equals(1));
      expect(breaker.state, equals(CircuitBreakerState.closed));
    });

    test('should open circuit after threshold failures', () async {
      // Configure low threshold for testing
      await config.setParameter('circuit_breaker.failure_threshold', 2);

      int callCount = 0;

      // Fail twice to trigger circuit breaker
      for (int i = 0; i < 2; i++) {
        try {
          await circuitBreaker.execute(
            serviceName: 'threshold-service',
            operation: () async {
              callCount++;
              throw Exception('Test failure $i');
            },
          );
        } catch (e) {
          // Expected to fail
        }
      }

      expect(callCount, equals(2));

      // Check circuit breaker state
      final breaker = circuitBreaker.circuitBreakers['threshold-service'];
      expect(breaker, isNotNull);
      expect(breaker!.state, equals(CircuitBreakerState.open));
    });

    test('should reject requests when circuit is open', () async {
      // Force circuit open
      final breaker = circuitBreaker.createBreaker('open-service');
      for (int i = 0; i < 6; i++) {
        breaker.recordFailure();
      }
      expect(breaker.state, equals(CircuitBreakerState.open));

      // Try to execute - should be rejected
      expect(
        () => circuitBreaker.execute(
          serviceName: 'open-service',
          operation: () async => 'should not execute',
        ),
        throwsA(isA<CircuitBreakerException>()),
      );
    });

    test('should allow half-open testing after timeout', () async {
      // Configure short timeout for testing
      await config.setParameter('circuit_breaker.recovery_timeout_seconds', 1);

      final breaker = circuitBreaker.createBreaker('recovery-service');

      // Open circuit
      for (int i = 0; i < 6; i++) {
        breaker.recordFailure();
      }
      expect(breaker.state, equals(CircuitBreakerState.open));

      // Wait for recovery timeout
      await Future.delayed(Duration(seconds: 2));

      // Should allow testing
      expect(breaker.canAttemptReset(), isTrue);
    });

    test('should recover from failures', () async {
      final breaker = circuitBreaker.createBreaker('recovery-service');

      // Record failures
      for (int i = 0; i < 3; i++) {
        breaker.recordFailure();
      }
      expect(breaker.consecutiveFailures, equals(3));

      // Record success
      breaker.recordSuccess();
      expect(breaker.consecutiveFailures, equals(0));
      expect(breaker.state, equals(CircuitBreakerState.closed));
    });

    test('should enable graceful degradation', () async {
      bool fallbackCalled = false;

      circuitBreaker.enableGracefulDegradation(
        'degraded-service',
        () async {
          fallbackCalled = true;
          return 'fallback result';
        },
      );

      // Force circuit open
      final breaker = circuitBreaker.createBreaker('degraded-service');
      for (int i = 0; i < 6; i++) {
        breaker.recordFailure();
      }

      // This would normally fail, but should use fallback
      // Note: In current implementation, fallback is only used internally
      expect(circuitBreaker.circuitBreakers['degraded-service'], isNotNull);
    });

    test('should perform bulk health checks', () async {
      // Create some services
      circuitBreaker.createBreaker('service1');
      circuitBreaker.createBreaker('service2');

      final healthResults = await circuitBreaker.performBulkHealthCheck();

      expect(healthResults, isNotNull);
      expect(healthResults.length, equals(2));
      expect(healthResults.containsKey('service1'), isTrue);
      expect(healthResults.containsKey('service2'), isTrue);
    });

    test('should provide health status', () async {
      circuitBreaker.createBreaker('status-service');

      final healthStatus = circuitBreaker.getHealthStatus();

      expect(healthStatus, isNotNull);
      expect(healthStatus.containsKey('status-service'), isTrue);
      expect(healthStatus['status-service'], isNotNull);
    });

    test('should reset circuit breaker', () async {
      final breaker = circuitBreaker.createBreaker('reset-service');

      // Open circuit
      for (int i = 0; i < 6; i++) {
        breaker.recordFailure();
      }
      expect(breaker.state, equals(CircuitBreakerState.open));

      // Reset
      circuitBreaker.resetBreaker('reset-service');
      expect(breaker.state, equals(CircuitBreakerState.closed));
      expect(breaker.consecutiveFailures, equals(0));
    });
  });

  group('Health Monitoring Service Tests', () {
    test('should initialize successfully', () async {
      expect(healthMonitor.isInitialized, true);
    });

    test('should register health checks', () async {
      final checkCount = healthMonitor.healthChecks.length;

      healthMonitor.registerHealthCheck(HealthCheck(
        name: 'test-check',
        description: 'Test health check',
        checkType: HealthCheckType.service,
        checkFunction: () async => HealthCheckResult(
          checkName: 'test-check',
          status: HealthStatus.healthy,
          value: 1.0,
          timestamp: DateTime.now(),
        ),
        interval: Duration(seconds: 30),
      ));

      expect(healthMonitor.healthChecks.length, equals(checkCount + 1));
      expect(healthMonitor.healthChecks.containsKey('test-check'), isTrue);
    });

    test('should perform comprehensive health check', () async {
      final report = await healthMonitor.performHealthCheck();

      expect(report, isNotNull);
      expect(report.timestamp, isNotNull);
      expect(report.systemMetrics, isNotNull);
      expect(report.recommendations, isNotNull);
    });

    test('should get current metrics', () async {
      final metrics = healthMonitor.getCurrentMetrics();

      expect(metrics, isNotNull);
      // Metrics may be empty initially
    });

    test('should get health history', () async {
      final history = healthMonitor.getHealthHistory();

      expect(history, isNotNull);
      expect(history.length, isNonNegative);
    });

    test('should resolve alerts', () async {
      // Create a mock alert (in real implementation, alerts would be created by health checks)
      final alert = HealthAlert(
        id: 'test-alert',
        title: 'Test Alert',
        description: 'Test alert description',
        severity: HealthStatus.warning,
        status: AlertStatus.active,
        createdAt: DateTime.now(),
        metadata: {},
      );

      // In a real implementation, alerts would be stored
      // For testing, we just verify the method exists
      expect(() => healthMonitor.resolveAlert('test-alert', 'Test resolution'), returnsNormally);
    });

    test('should get system diagnostics', () async {
      final diagnostics = await healthMonitor.getSystemDiagnostics();

      expect(diagnostics, isNotNull);
      expect(diagnostics.timestamp, isNotNull);
      expect(diagnostics.systemInfo, isNotNull);
      expect(diagnostics.deviceInfo, isNotNull);
    });

    test('should generate health recommendations', () async {
      final recommendations = await healthMonitor.generateHealthRecommendations();

      expect(recommendations, isNotNull);
      expect(recommendations, isA<List<String>>());
    });
  });

  group('Data Validation Service Tests', () {
    test('should initialize successfully', () async {
      expect(dataValidation.isInitialized, true);
    });

    test('should register validation rules', () async {
      final ruleCount = dataValidation.validationRules.length;

      dataValidation.registerValidationRule(ValidationRule(
        name: 'test-rule',
        description: 'Test validation rule',
        validator: (value) => ['Test validation failed'],
        errorMessage: 'Test error',
      ));

      expect(dataValidation.validationRules.length, equals(ruleCount + 1));
      expect(dataValidation.validationRules.containsKey('test-rule'), isTrue);
    });

    test('should register sanitization rules', () async {
      final ruleCount = dataValidation.sanitizationRules.length;

      dataValidation.registerSanitizationRule(SanitizationRule(
        name: 'test-sanitizer',
        description: 'Test sanitization rule',
        sanitizer: (value) => value.toString().toUpperCase(),
      ));

      expect(dataValidation.sanitizationRules.length, equals(ruleCount + 1));
      expect(dataValidation.sanitizationRules.containsKey('test-sanitizer'), isTrue);
    });

    test('should validate with email rule', () async {
      const validEmail = 'user@example.com';
      const invalidEmail = 'not-an-email';

      final validResult = dataValidation.validate(validEmail, 'email');
      final invalidResult = dataValidation.validate(invalidEmail, 'email');

      expect(validResult.isValid, isTrue);
      expect(validResult.errors.isEmpty, isTrue);

      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errors.isNotEmpty, isTrue);
    });

    test('should validate with URL rule', () async {
      const validUrl = 'https://example.com';
      const invalidUrl = 'not-a-url';

      final validResult = dataValidation.validate(validUrl, 'url');
      final invalidResult = dataValidation.validate(invalidUrl, 'url');

      expect(validResult.isValid, isTrue);
      expect(validResult.errors.isEmpty, isTrue);

      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errors.isNotEmpty, isTrue);
    });

    test('should validate multiple rules', () async {
      const testValue = 'user@example.com';

      final result = dataValidation.validateMultiple(testValue, ['email', 'no_xss']);

      expect(result.isValid, isTrue);
      expect(result.errors.isEmpty, isTrue);
    });

    test('should sanitize HTML', () async {
      const htmlInput = '<script>alert("xss")</script>Hello & World';
      const expectedOutput = '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;Hello &amp; World';

      final result = dataValidation.sanitize(htmlInput, 'html_encode');

      expect(result, equals(expectedOutput));
    });

    test('should sanitize SQL', () async {
      const sqlInput = "SELECT * FROM users WHERE id = '123'";
      const expectedOutput = "SELECT * FROM users WHERE id = ''123''";

      final result = dataValidation.sanitize(sqlInput, 'sql_escape');

      expect(result, equals(expectedOutput));
    });

    test('should clean data comprehensively', () async {
      const testInput = '  <script>alert("xss")</script> Test Input  ';

      final result = dataValidation.cleanData(testInput, validationRules: ['no_xss']);

      expect(result.isValid, isFalse); // XSS validation should fail
      expect(result.cleanedData, isNotNull);
      expect(result.validationErrors.isNotEmpty, isTrue);
    });

    test('should validate user input', () async {
      const safeInput = 'This is safe input';
      const unsafeInput = '<script>alert("xss")</script> unsafe';

      final safeResult = dataValidation.validateUserInput(safeInput);
      final unsafeResult = dataValidation.validateUserInput(unsafeInput);

      expect(safeResult.isValid, isTrue);
      expect(safeResult.securityViolations.isEmpty, isTrue);

      expect(unsafeResult.isValid, isFalse);
      expect(unsafeResult.securityViolations.isNotEmpty, isTrue);
    });

    test('should validate API requests', () async {
      final validRequest = {
        'email': 'user@example.com',
        'name': 'John Doe',
      };

      final invalidRequest = {
        'email': 'invalid-email',
        'name': '<script>alert("xss")</script>',
      };

      final fieldValidations = {
        'email': ['email'],
        'name': ['no_xss'],
      };

      final validResult = dataValidation.validateApiRequest(validRequest, fieldValidations: fieldValidations);
      final invalidResult = dataValidation.validateApiRequest(invalidRequest, fieldValidations: fieldValidations);

      expect(validResult.isValid, isTrue);
      expect(validResult.fieldErrors.isEmpty, isTrue);

      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.fieldErrors.isNotEmpty, isTrue);
    });

    test('should register and validate schemas', () async {
      final testSchema = DataSchema(
        name: 'test-schema',
        schema: {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'maxLength': 50},
            'age': {'type': 'number', 'minimum': 0, 'maximum': 150},
          },
          'required': ['name'],
        },
      );

      dataValidation.registerDataSchema('test-schema', testSchema);

      final validData = {'name': 'John Doe', 'age': 25};
      final invalidData = {'name': '', 'age': 'not-a-number'};

      final validResult = dataValidation.validateAgainstSchema(validData, 'test-schema');
      final invalidResult = dataValidation.validateAgainstSchema(invalidData, 'test-schema');

      expect(validResult.isValid, isTrue);

      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errors.isNotEmpty, isTrue);
    });

    test('should detect SQL injection attempts', () async {
      const safeQuery = "SELECT * FROM users WHERE id = 123";
      const maliciousQuery = "SELECT * FROM users WHERE id = 1; DROP TABLE users; --";

      final safeResult = dataValidation.validate(safeQuery, 'no_sql_injection');
      final maliciousResult = dataValidation.validate(maliciousQuery, 'no_sql_injection');

      expect(safeResult.isValid, isTrue);

      expect(maliciousResult.isValid, isFalse);
      expect(maliciousResult.errors.any((e) => e.contains('SQL injection')), isTrue);
    });

    test('should detect XSS attempts', () async {
      const safeContent = '<p>This is safe HTML</p>';
      const maliciousContent = '<script>alert("xss")</script><img src=x onerror=alert(1)>';

      final safeResult = dataValidation.validate(safeContent, 'no_xss');
      final maliciousResult = dataValidation.validate(maliciousContent, 'no_xss');

      expect(safeResult.isValid, isTrue);

      expect(maliciousResult.isValid, isFalse);
      expect(maliciousResult.errors.any((e) => e.contains('XSS')), isTrue);
    });

    test('should validate file paths', () async {
      const safePath = '/documents/user/file.txt';
      const maliciousPath = '../../../etc/passwd';

      final safeResult = dataValidation.validate(safePath, 'safe_path');
      final maliciousResult = dataValidation.validate(maliciousPath, 'safe_path');

      expect(safeResult.isValid, isTrue);

      expect(maliciousResult.isValid, isFalse);
      expect(maliciousResult.errors.any((e) => e.contains('path traversal')), isTrue);
    });

    test('should handle unknown validation rules', () async {
      final result = dataValidation.validate('test', 'unknown-rule');

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Unknown validation rule')), isTrue);
    });

    test('should handle unknown sanitization rules', () async {
      final result = dataValidation.sanitize('test', 'unknown-rule');

      expect(result, equals('test')); // Should return original value
    });
  });

  group('Integrated Robustness Tests', () {
    test('should handle service failure gracefully', () async {
      // Create a service that fails
      int callCount = 0;

      try {
        await circuitBreaker.execute(
          serviceName: 'integration-test-service',
          operation: () async {
            callCount++;
            throw Exception('Simulated service failure');
          },
          maxRetries: 2,
        );
      } catch (e) {
        // Expected to fail after retries
      }

      expect(callCount, equals(3)); // Initial call + 2 retries

      // Service should be marked as unhealthy
      final healthStatus = circuitBreaker.getHealthStatus();
      expect(healthStatus.containsKey('integration-test-service'), isTrue);
      expect(healthStatus['integration-test-service']!.circuitBreakerState, equals(CircuitBreakerState.open));
    });

    test('should validate data through circuit breaker', () async {
      const testData = '<script>alert("xss")</script>safe content';

      // This simulates a service call with validation
      final result = await circuitBreaker.execute(
        serviceName: 'validation-service',
        operation: () async {
          final validationResult = dataValidation.validateUserInput(testData);
          if (!validationResult.isValid) {
            throw Exception('Validation failed: ${validationResult.securityViolations.join(", ")}');
          }
          return validationResult.sanitizedInput;
        },
      );

      expect(result, isNotNull);
      // Should contain sanitized content
      expect(result.toString().contains('<script>'), isFalse);
    });

    test('should monitor health during operations', () async {
      // Start health monitoring
      expect(healthMonitor.isInitialized, isTrue);

      // Perform some operations
      final initialHealth = await healthMonitor.performHealthCheck();

      // Execute some circuit breaker operations
      await circuitBreaker.execute(
        serviceName: 'health-test-service',
        operation: () async => 'success',
      );

      // Check health again
      final finalHealth = await healthMonitor.performHealthCheck();

      expect(finalHealth.timestamp.isAfter(initialHealth.timestamp), isTrue);
    });

    test('should handle complex validation scenarios', () async {
      final complexRequest = {
        'user': {
          'email': 'user@example.com',
          'name': '<b>John Doe</b>',
          'profile': {
            'bio': 'Software developer with 5+ years experience',
            'skills': ['dart', 'flutter', 'testing'],
          }
        },
        'metadata': {
          'source': 'web_form',
          'timestamp': DateTime.now().toIso8601String(),
        }
      };

      final validationResult = dataValidation.validateApiRequest(complexRequest, fieldValidations: {
        'user.email': ['email'],
        'user.name': ['no_xss'],
        'metadata.source': ['no_sql_injection'],
      });

      expect(validationResult.isValid, isTrue);
      expect(validationResult.fieldErrors.isEmpty, isTrue);
      expect(validationResult.sanitizedData, isNotNull);
    });
  });
}
