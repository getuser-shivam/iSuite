import 'package:flutter_test/flutter_test.dart';
import 'package:i_suite/core/services/data_validation_service.dart';

void main() {
  group('DataValidationService', () {
    final service = DataValidationService();

    test('validateEmail - valid email', () {
      final result = service.validateEmail('test@example.com');
      expect(result.isValid, true);
      expect(result.errorMessage, null);
    });

    test('validateEmail - empty email', () {
      final result = service.validateEmail('');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Email is required');
    });

    test('validateEmail - invalid format', () {
      final result = service.validateEmail('invalid-email');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Invalid email format');
    });

    test('validateEmail - too long', () {
      final longEmail = 'a' * 250 + '@example.com';
      final result = service.validateEmail(longEmail);
      expect(result.isValid, false);
      expect(result.errorMessage, 'Email too long');
    });

    test('validatePassword - valid password', () {
      final result = service.validatePassword('Password123');
      expect(result.isValid, true);
    });

    test('validatePassword - empty password', () {
      final result = service.validatePassword('');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Password is required');
    });

    test('validatePassword - too short', () {
      final result = service.validatePassword('Pass1');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Password must be at least 8 characters');
    });

    test('validatePassword - no uppercase', () {
      final result = service.validatePassword('password123');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Password must contain uppercase letter');
    });

    test('validatePassword - no lowercase', () {
      final result = service.validatePassword('PASSWORD123');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Password must contain lowercase letter');
    });

    test('validatePassword - no number', () {
      final result = service.validatePassword('Password');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Password must contain number');
    });

    test('validateFileName - valid name', () {
      final result = service.validateFileName('document.txt');
      expect(result.isValid, true);
    });

    test('validateFileName - empty name', () {
      final result = service.validateFileName('');
      expect(result.isValid, false);
      expect(result.errorMessage, 'File name is required');
    });

    test('validateFileName - invalid characters', () {
      final result = service.validateFileName('doc<ument.txt');
      expect(result.isValid, false);
      expect(result.errorMessage, 'File name contains invalid characters');
    });

    test('validateFileName - too long', () {
      final longName = 'a' * 256;
      final result = service.validateFileName(longName);
      expect(result.isValid, false);
      expect(result.errorMessage, 'File name too long');
    });

    test('validateUrl - valid URL', () {
      final result = service.validateUrl('https://example.com');
      expect(result.isValid, true);
    });

    test('validateUrl - invalid URL', () {
      final result = service.validateUrl('not-a-url');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Invalid URL format');
    });

    test('sanitizeText - removes harmful characters', () {
      final result = service.sanitizeText('<script>alert("xss")</script>');
      expect(result, 'scriptalert("xss")/script');
    });

    test('validateFileSize - valid size', () {
      final result = service.validateFileSize(1024 * 1024); // 1MB
      expect(result.isValid, true);
    });

    test('validateFileSize - too large', () {
      final result = service.validateFileSize(200 * 1024 * 1024); // 200MB, default max 100MB
      expect(result.isValid, false);
      expect(result.errorMessage, 'File size exceeds 100MB limit');
    });
  });
}
