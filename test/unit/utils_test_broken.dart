import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:isuite/core/utils.dart';

void main() {
  group('AppUtils Tests', () {
    group('Date and Time Utilities', () {
      test('formatDate should format date correctly', () {
        final date = DateTime(2023, 12, 25);
        final formatted = AppUtils.formatDate(date);
        expect(formatted, equals('12/25/2023'));
      });

      test('formatTime should format time in 12-hour format by default', () {
        final time = DateTime(2023, 12, 25, 14, 30);
        final formatted = AppUtils.formatTime(time);
        expect(formatted, equals('02:30 PM'));
      });

      test('formatTime should format time in 24-hour format when requested', () {
        final time = DateTime(2023, 12, 25, 14, 30);
        final formatted = AppUtils.formatTime(time, use24Hour: true);
        expect(formatted, equals('14:30'));
      });

      test('getRelativeTime should return "Just now" for recent times', () {
        final recent = DateTime.now().subtract(const Duration(seconds: 30));
        final relative = AppUtils.getRelativeTime(recent);
        expect(relative, equals('Just now'));
      });

      test('getRelativeTime should return minutes for minute differences', () {
        final past = DateTime.now().subtract(const Duration(minutes: 5));
        final relative = AppUtils.getRelativeTime(past);
        expect(relative, equals('5 minutes ago'));
      });

      test('getRelativeTime should return hours for hour differences', () {
        final past = DateTime.now().subtract(const Duration(hours: 2));
        final relative = AppUtils.getRelativeTime(past);
        expect(relative, equals('2 hours ago'));
      });

      test('getRelativeTime should return days for day differences', () {
        final past = DateTime.now().subtract(const Duration(days: 3));
        final relative = AppUtils.getRelativeTime(past);
        expect(relative, equals('3 days ago'));
      });

      test('isToday should return true for today\'s date', () {
        final today = DateTime.now();
        expect(AppUtils.isToday(today), isTrue);
      });

      test('isToday should return false for yesterday\'s date', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(AppUtils.isToday(yesterday), isFalse);
      });

      test('isYesterday should return true for yesterday\'s date', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(AppUtils.isYesterday(yesterday), isTrue);
      });

      test('isYesterday should return false for today\'s date', () {
        final today = DateTime.now();
        expect(AppUtils.isYesterday(today), isFalse);
      });
    });

    group('String Utilities', () {
      test('capitalize should capitalize first letter', () {
        final result = AppUtils.capitalize('hello');
        expect(result, equals('Hello'));
      });

      test('capitalize should handle empty string', () {
        final result = AppUtils.capitalize('');
        expect(result, equals(''));
      });

      test('capitalize should handle single character', () {
        final result = AppUtils.capitalize('a');
        expect(result, equals('A'));
      });

      test('capitalizeWords should capitalize each word', () {
        final result = AppUtils.capitalizeWords('hello world');
        expect(result, equals('Hello World'));
      });

      test('capitalizeWords should handle empty string', () {
        final result = AppUtils.capitalizeWords('');
        expect(result, equals(''));
      });

      test('truncate should truncate long text', () {
        final result = AppUtils.truncate('This is a very long text', length: 10);
        expect(result, equals('This is a...'));
      });

      test('truncate should truncate text', () {
        final result = AppUtils.truncate('This is a very long text that needs to be truncated', length: 20);
        expect(result.length, lessThanOrEqualTo(23)); // 20 + '...'
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

      test('isValidPhone should validate phone numbers', () {
        expect(AppUtils.isValidPhone('+1234567890'), isTrue);
        expect(AppUtils.isValidPhone('(123) 456-7890'), isTrue);
        expect(AppUtils.isValidPhone('1234567890'), isTrue);
      });

      test('isValidPhone should reject invalid phone numbers', () {
        expect(AppUtils.isValidPhone('abc'), isFalse);
        expect(AppUtils.isValidPhone(''), isFalse);
      });

      test('isValidUrl should validate URLs', () {
        expect(AppUtils.isValidUrl('https://example.com'), isTrue);
        expect(AppUtils.isValidUrl('http://example.com'), isTrue);
      });

      test('isValidUrl should reject invalid URLs', () {
        expect(AppUtils.isValidUrl('not-a-url'), isFalse);
        expect(AppUtils.isValidUrl('ftp://example.com'), isFalse);
      });
    });

    group('File Utilities', () {
      test('getFileExtension should return correct extension', () {
        expect(AppUtils.getFileExtension('document.pdf'), equals('pdf'));
        expect(AppUtils.getFileExtension('image.JPG'), equals('jpg'));
      });

      test('getFileName should return filename without path', () {
        expect(AppUtils.getFileName('/path/to/file.txt'), equals('file.txt'));
        expect(AppUtils.getFileName('file.txt'), equals('file.txt'));
      });

      test('formatFileSize should format bytes correctly', () {
        expect(AppUtils.formatFileSize(512), equals('512 B'));
        expect(AppUtils.formatFileSize(1024), equals('1.0 KB'));
        expect(AppUtils.formatFileSize(1024 * 1024), equals('1.0 MB'));
        expect(AppUtils.formatFileSize(1024 * 1024 * 1024), equals('1.0 GB'));
      });

      test('isImageFile should identify image files', () {
        expect(AppUtils.isImageFile('photo.jpg'), isTrue);
        expect(AppUtils.isImageFile('image.png'), isTrue);
        expect(AppUtils.isImageFile('document.pdf'), isFalse);
      });

      test('isVideoFile should identify video files', () {
        expect(AppUtils.isVideoFile('video.mp4'), isTrue);
        expect(AppUtils.isVideoFile('movie.avi'), isTrue);
        expect(AppUtils.isVideoFile('image.jpg'), isFalse);
      });

      test('isAudioFile should identify audio files', () {
        expect(AppUtils.isAudioFile('song.mp3'), isTrue);
        expect(AppUtils.isAudioFile('music.wav'), isTrue);
        expect(AppUtils.isAudioFile('video.mp4'), isFalse);
      });

      test('isDocumentFile should identify document files', () {
        expect(AppUtils.isDocumentFile('document.pdf'), isTrue);
        expect(AppUtils.isDocumentFile('text.txt'), isTrue);
        expect(AppUtils.isDocumentFile('image.jpg'), isFalse);
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

      test('randomInt should generate random integers in range', () {
        final result = AppUtils.randomInt(1, 10);
        expect(result, greaterThanOrEqualTo(1));
        expect(result, lessThanOrEqualTo(10));
      });

      test('randomDouble should generate random double', () {
        final result = AppUtils.randomDouble();
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThan(1.0));
      });
    });

    group('Animation Utilities', () {
      test('getAnimationDuration should return correct duration', () {
        expect(AppUtils.getAnimationDuration(AnimationSpeed.slow), 
               equals(const Duration(milliseconds: 800)));
        expect(AppUtils.getAnimationDuration(AnimationSpeed.medium), 
               equals(const Duration(milliseconds: 300)));
        expect(AppUtils.getAnimationDuration(AnimationSpeed.fast), 
               equals(const Duration(milliseconds: 150)));
      });

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
  });
}
