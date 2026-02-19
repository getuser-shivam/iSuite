import 'package:flutter/material.dart';

extension StringExtensions on String {
  bool get isEmail => RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(this);
  
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);
  
  bool get isAlphabetic => RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  
  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  
  String get capitalizeFirst {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
  
  String get capitalizeWords {
    return split(' ').map((word) => word.capitalizeFirst).join(' ');
  }
  
  String get removeExtraSpaces {
    return trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  String? get nullIfEmpty => isEmpty ? null : this;
  
  bool get isValidUrl {
    try {
      final uri = Uri.parse(this);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  String maskEmail({int visibleChars = 2, String maskChar = '*'}) {
    if (!isEmail) return this;
    
    final parts = split('@');
    if (parts.length != 2) return this;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= visibleChars) return this;
    
    final maskedUsername = username.substring(0, visibleChars) + 
                          maskChar * (username.length - visibleChars);
    
    return '$maskedUsername@$domain';
  }
}

extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);
    
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
  
  DateTime get startOfDay => DateTime(year, month, day, 0, 0, 0);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  DateTime get startOfWeek {
    final start = subtract(Duration(days: weekday - 1));
    return DateTime(start.year, start.month, start.day);
  }
  DateTime get endOfWeek {
    final end = add(Duration(days: DateTime.daysPerWeek - weekday));
    return DateTime(end.year, end.month, end.day);
  }
  
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
  
  bool isSameWeek(DateTime other) {
    final startOfWeekThis = startOfWeek;
    final startOfWeekOther = other.startOfWeek;
    return startOfWeekThis.year == startOfWeekOther.year &&
           startOfWeekThis.month == startOfWeekOther.month &&
           startOfWeekThis.day == startOfWeekOther.day;
  }
  
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }
  
  bool isSameYear(DateTime other) {
    return year == other.year;
  }
}

extension ListExtensions<T> on List<T> {
  List<T> get unique {
    final seen = <T>{};
    return where((element) => seen.add(element)).toList();
  }
  
  T? get firstOrNull => isEmpty ? null : first;
  
  T? get lastOrNull => isEmpty ? null : last;
  
  List<T> get reversedList => reversed.toList();
  
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
  
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
  
  List<T> whereNotNull() => where((element) => element != null).cast<T>();
  
  bool get isNullOrEmpty => isEmpty;
  
  bool get isNotNullOrEmpty => isNotEmpty;
}

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;
  bool isMobile() => MediaQuery.of(this).size.width < 600;
  bool isTablet() => MediaQuery.of(this).size.width >= 600 && MediaQuery.of(this).size.width < 1200;
  bool isDesktop() => MediaQuery.of(this).size.width >= 1200;
  
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
  
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
  
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }
  
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }
}

extension ColorExtensions on Color {
  Color get lighter => withOpacity(0.7);
  Color get muchLighter => withOpacity(0.4);
  Color get darker => withOpacity(0.8);
  
  Color get complementary {
    final hsl = HSLColor.fromColor(this);
    return hsl.withHue((hsl.hue + 180) % 360).toColor();
  }
  
  String get toHex {
    return '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
  
  MaterialColor toMaterialColor() {
    final int red = this.red;
    final int green = this.green;
    final int blue = this.blue;

    final Map<int, Color> shades = {
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

    return MaterialColor(value, shades);
  }
}

extension NumExtensions on num {
  Duration get milliseconds => Duration(milliseconds: toInt());
  Duration get seconds => Duration(seconds: toInt());
  Duration get minutes => Duration(minutes: toInt());
  Duration get hours => Duration(hours: toInt());
  Duration get days => Duration(days: toInt());
  
  String formatFileSize() {
    if (this < 1024) return '${toInt()} B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  bool isBetween(num min, num max) => this >= min && this <= max;
  
  num clamp(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}
