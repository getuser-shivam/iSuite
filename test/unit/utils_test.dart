import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../lib/core/utils.dart';

void main() {
  group('String Utilities', () {
    test('capitalize should capitalize first letter', () {
      expect(AppUtils.capitalize('hello'), equals('Hello'));
      expect(AppUtils.capitalize('HELLO'), equals('Hello'));
      expect(AppUtils.capitalize(''), equals(''));
    });

    test('capitalizeWords should capitalize each word', () {
      expect(AppUtils.capitalizeWords('hello world'), equals('Hello World'));
      expect(AppUtils.capitalizeWords('HELLO WORLD'), equals('Hello World'));
      expect(AppUtils.capitalizeWords(''), equals(''));
    });

    test('truncate should truncate long text', () {
      final result = AppUtils.truncate('This is a very long text', length: 10);
      expect(result, equals('This is a...'));
    });

    test('truncate should truncate text', () {
      final result = AppUtils.truncate('This is a very long text that needs to be truncated', length: 20);
      expect(result.length, lessThanOrEqualTo(23)); // 20 + '...'
    });
  });

  group('Validation Utilities', () {
    test('isValidEmail should validate correct email', () {
      expect(AppUtils.isValidEmail('test@example.com'), isTrue);
    });

    test('isValidEmail should reject invalid email', () {
      expect(AppUtils.isValidEmail('invalid-email'), isFalse);
      expect(AppUtils.isValidEmail('test@'), isFalse);
      expect(AppUtils.isValidEmail('@example.com'), isFalse);
    });

    test('isValidPhone should validate correct phone', () {
      expect(AppUtils.isValidPhone('+1234567890'), isTrue);
      expect(AppUtils.isValidPhone('1234567890'), isTrue);
    });

    test('isValidPhone should reject invalid phone', () {
      expect(AppUtils.isValidPhone('abc'), isFalse);
      expect(AppUtils.isValidPhone(''), isFalse);
    });

    test('isValidUrl should validate correct URL', () {
      expect(AppUtils.isValidUrl('https://example.com'), isTrue);
      expect(AppUtils.isValidUrl('http://example.com'), isTrue);
    });

    test('isValidUrl should reject invalid URL', () {
      expect(AppUtils.isValidUrl('not-a-url'), isFalse);
      expect(AppUtils.isValidUrl(''), isFalse);
    });
  });

  group('Color Utilities', () {
    test('hexToColor should convert hex to color', () {
      final color = AppUtils.hexToColor('#FF0000');
      expect(color.value, equals(0xFFFF0000));
    });

    test('colorToHex should convert color to hex', () {
      final color = const Color(0xFFFF0000);
      final hex = AppUtils.colorToHex(color);
      expect(hex, equals('#FF0000'));
    });

    test('getContrastColor should return appropriate contrast color', () {
      final lightColor = const Color(0xFFFFFFFF);
      final darkColor = const Color(0xFF000000);
      
      expect(AppUtils.getContrastColor(lightColor), equals(Colors.black));
      expect(AppUtils.getContrastColor(darkColor), equals(Colors.white));
    });
  });

  group('Math Utilities', () {
    test('clamp should limit values within range', () {
      expect(AppUtils.clamp(5, 0, 10), equals(5));
      expect(AppUtils.clamp(-5, 0, 10), equals(0));
      expect(AppUtils.clamp(15, 0, 10), equals(10));
    });

    test('lerp should interpolate between values', () {
      expect(AppUtils.lerp(0, 10, 0.5), equals(5.0));
      expect(AppUtils.lerp(0, 10, 0.0), equals(0.0));
      expect(AppUtils.lerp(0, 10, 1.0), equals(10.0));
    });

    test('map should map value from one range to another', () {
      expect(AppUtils.map(5, 0, 10, 0, 100), equals(50.0));
      expect(AppUtils.map(0, 0, 10, 0, 100), equals(0.0));
      expect(AppUtils.map(10, 0, 10, 0, 100), equals(100.0));
    });
  });

  group('Date Utilities', () {
    test('formatDate should format date correctly', () {
      final date = DateTime(2023, 12, 25);
      final formatted = AppUtils.formatDate(date);
      expect(formatted, isNotEmpty);
    });

    test('isToday should check if date is today', () {
      final today = DateTime.now();
      expect(AppUtils.isToday(today), isTrue);
      
      final yesterday = today.subtract(const Duration(days: 1));
      expect(AppUtils.isToday(yesterday), isFalse);
    });

    test('daysBetween should calculate days between dates', () {
      final date1 = DateTime(2023, 1, 1);
      final date2 = DateTime(2023, 1, 5);
      expect(AppUtils.daysBetween(date1, date2), equals(4));
    });
  });

  group('Animation Utilities', () {
    test('getAnimationCurve should return correct curve', () {
      expect(AppUtils.getAnimationCurve(AnimationType.easeIn), equals(Curves.easeIn));
      expect(AppUtils.getAnimationCurve(AnimationType.easeOut), equals(Curves.easeOut));
      expect(AppUtils.getAnimationCurve(AnimationType.easeInOut), equals(Curves.easeInOut));
      expect(AppUtils.getAnimationCurve(AnimationType.bounce), equals(Curves.bounceOut));
      expect(AppUtils.getAnimationCurve(AnimationType.elastic), equals(Curves.elasticOut));
    });
  });

  group('Security Utilities', () {
    test('generateRandomPassword should generate password of correct length', () {
      final password = AppUtils.generateRandomPassword(12);
      expect(password.length, equals(12));
    });

    test('generateId should generate unique IDs', () {
      final id1 = AppUtils.generateId();
      final id2 = AppUtils.generateId();
      expect(id1, isNot(equals(id2)));
      expect(id1.length, greaterThan(0));
    });

    test('hashString should generate consistent hash', () {
      final input = 'test string';
      final hash1 = AppUtils.hashString(input);
      final hash2 = AppUtils.hashString(input);
      expect(hash1, equals(hash2));
      expect(hash1.length, greaterThan(0));
    });
  });

  group('Duration Utilities', () {
    test('formatDuration should format duration correctly', () {
      expect(AppUtils.formatDuration(const Duration(seconds: 30)), equals('30s'));
      expect(AppUtils.formatDuration(const Duration(minutes: 2, seconds: 30)), equals('2m 30s'));
      expect(AppUtils.formatDuration(const Duration(hours: 1, minutes: 2, seconds: 30)), equals('1h 2m 30s'));
    });
  });
}
