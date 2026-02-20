import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  // Date and Time Utilities
  static String formatDate(DateTime date, {String format = 'MM/dd/yyyy'}) =>
      DateFormat(format).format(date);

  static String formatTime(DateTime time, {bool use24Hour = false}) => use24Hour
      ? DateFormat('HH:mm').format(time)
      : DateFormat('hh:mm a').format(time);

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // String Utilities
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) =>
      text.split(' ').map(capitalize).join(' ');

  static String truncate(String text,
      {int length = 50, String suffix = '...'}) {
    if (text.length <= length) return text;
    return text.substring(0, length) + suffix;
  }

  static String getInitials(String name, {int maxInitials = 2}) {
    if (name.isEmpty) return '';

    final words = name.trim().split(' ');
    var initials = '';

    for (var i = 0; i < words.length && i < maxInitials; i++) {
      if (words[i].isNotEmpty) {
        initials += words[i][0].toUpperCase();
      }
    }

    return initials;
  }

  static bool isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email);

  static bool isValidPassword(String password) {
    if (password.length < 8) return false;

    final hasUppercase = password.contains(RegExp('[A-Z]'));
    final hasLowercase = password.contains(RegExp('[a-z]'));
    final hasDigits = password.contains(RegExp('[0-9]'));
    final hasSpecialCharacters =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasDigits;
  }

  static String generateRandomId({int length = 16}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var id = '';

    for (var i = 0; i < length; i++) {
      id += chars[(random + i) % chars.length];
    }

    return id;
  }

  // File Utilities
  static String getFileExtension(String fileName) =>
      fileName.split('.').last.toLowerCase();

  static String getFileName(String filePath) => filePath.split('/').last;

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static bool isImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  static bool isDocumentFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(extension);
  }

  // Color Utilities
  static Color getColorFromString(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16));
      } else if (colorString.startsWith('0x')) {
        return Color(int.parse(colorString));
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
    }
  }

  static MaterialColor createMaterialColor(Color color) {
    final red = color.red;
    final green = color.green;
    final blue = color.blue;

    final shades = <int, Color>{
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.value, shades);
  }

  // Validation Utilities
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!isValidPassword(value)) {
      return 'Password must contain uppercase, lowercase, and numbers';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateMinLength(
      String? value, String fieldName, int minLength) {
    if (value != null && value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  static String? validateMaxLength(
      String? value, String fieldName, int maxLength) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }
    return null;
  }

  // UI Utilities
  static void showSnackBar(BuildContext context, String message,
      {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) =>
      showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      );

  static Future<void> showLoadingDialog(BuildContext context,
          {String message = 'Loading...'}) =>
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(message),
              ],
            ),
          ),
        ),
      );

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Animation Utilities
  static Duration getAnimationDuration(AnimationSpeed speed) {
    switch (speed) {
      case AnimationSpeed.slow:
        return const Duration(milliseconds: 500);
      case AnimationSpeed.medium:
        return const Duration(milliseconds: 300);
      case AnimationSpeed.fast:
        return const Duration(milliseconds: 150);
    }
  }

  static Curve getAnimationCurve(AnimationType type) {
    switch (type) {
      case AnimationType.easeIn:
        return Curves.easeIn;
      case AnimationType.easeOut:
        return Curves.easeOut;
      case AnimationType.easeInOut:
        return Curves.easeInOut;
      case AnimationType.bounce:
        return Curves.bounceInOut;
      case AnimationType.elastic:
        return Curves.elasticOut;
    }
  }

  // Logging Utilities
  static void logInfo(String message, {String tag = 'AppUtils'}) {
    developer.log(message, name: tag, level: 800);
  }

  static void logWarning(String message, {String tag = 'AppUtils'}) {
    developer.log(message, name: tag, level: 900);
  }

  static void logError(String message,
      {String tag = 'AppUtils', Object? error, StackTrace? stackTrace}) {
    developer.log(message,
        name: tag, level: 1000, error: error, stackTrace: stackTrace);
  }

  static void logDebug(String message, {String tag = 'AppUtils'}) {
    developer.log(message, name: tag, level: 500);
  }
}

enum AnimationSpeed { slow, medium, fast }

enum AnimationType { easeIn, easeOut, easeInOut, bounce, elastic }
