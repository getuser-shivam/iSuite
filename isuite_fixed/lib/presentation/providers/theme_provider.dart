import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/theme_model.dart';

class ThemeProvider extends ChangeNotifier {

  ThemeProvider() {
    _loadThemeData();
  }
  ThemeModel _currentTheme = ThemeModel.defaultLight();
  static const String _themeKey = 'theme_mode';
  static const String _customThemeKey = 'custom_theme';

  ThemeModel get currentTheme => _currentTheme;
  ThemeMode get themeMode => _currentTheme.mode;
  ThemeData get themeData => _currentTheme.toThemeData();

  bool get isDarkMode => _currentTheme.mode == ThemeMode.dark;
  bool get isLightMode => _currentTheme.mode == ThemeMode.light;
  bool get isSystemMode => _currentTheme.mode == ThemeMode.system;
  bool get isCustomTheme => _currentTheme.isCustom;

  Future<void> _loadThemeData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final savedThemeMode = prefs.getString(_themeKey);
    if (savedThemeMode != null) {
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == savedThemeMode,
        orElse: () => ThemeMode.system,
      );
      _currentTheme = _currentTheme.copyWith(mode: mode);
    }

    // Load custom theme
    final savedCustomTheme = prefs.getString(_customThemeKey);
    if (savedCustomTheme != null) {
      try {
        final themeData = ThemeModel.fromJson(savedCustomTheme as Map<String, dynamic>);
        _currentTheme = themeData;
      } catch (e) {
        // If loading fails, keep default
      }
    }

    notifyListeners();
  }

  Future<void> _saveThemeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _currentTheme.mode.name);
    if (_currentTheme.isCustom) {
      await prefs.setString(_customThemeKey, _currentTheme.toJson().toString());
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _currentTheme = _currentTheme.copyWith(mode: themeMode);
    notifyListeners();
    await _saveThemeData();
  }

  Future<void> setCurrentTheme(ThemeModel theme) async {
    _currentTheme = theme;
    notifyListeners();
    await _saveThemeData();
  }

  Future<void> setPresetTheme(ThemePreset preset) async {
    ThemeModel newTheme;
    switch (preset) {
      case ThemePreset.defaultLight:
        newTheme = ThemeModel.defaultLight();
        break;
      case ThemePreset.defaultDark:
        newTheme = ThemeModel.defaultDark();
        break;
      case ThemePreset.blue:
        newTheme = ThemeModel.blueTheme();
        break;
      case ThemePreset.green:
        newTheme = ThemeModel(
          id: 'green_theme',
          name: 'Green Theme',
          preset: ThemePreset.green,
          mode: _currentTheme.mode,
          primaryColor: const Color(0xFF4CAF50),
          secondaryColor: const Color(0xFF8BC34A),
          backgroundColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFF121212) : const Color(0xFFE8F5E8),
          surfaceColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
          onSecondaryColor: const Color(0xFF000000),
          onBackgroundColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
          onSurfaceColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
        );
        break;
      case ThemePreset.purple:
        newTheme = ThemeModel(
          id: 'purple_theme',
          name: 'Purple Theme',
          preset: ThemePreset.purple,
          mode: _currentTheme.mode,
          primaryColor: const Color(0xFF9C27B0),
          secondaryColor: const Color(0xFFBA68C8),
          backgroundColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFF121212) : const Color(0xFFF3E5F5),
          surfaceColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
          onSecondaryColor: const Color(0xFF000000),
          onBackgroundColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
          onSurfaceColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
        );
        break;
      case ThemePreset.orange:
        newTheme = ThemeModel(
          id: 'orange_theme',
          name: 'Orange Theme',
          preset: ThemePreset.orange,
          mode: _currentTheme.mode,
          primaryColor: const Color(0xFFFF9800),
          secondaryColor: const Color(0xFFFFCC80),
          backgroundColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFF121212) : const Color(0xFFFFF3E0),
          surfaceColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
          onPrimaryColor: const Color(0xFF000000),
          onSecondaryColor: const Color(0xFF000000),
          onBackgroundColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
          onSurfaceColor: _currentTheme.mode == ThemeMode.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
        );
        break;
      case ThemePreset.custom:
        // Keep current custom theme
        return;
    }

    await setCurrentTheme(newTheme);
  }

  Future<void> updateCustomColors({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
  }) async {
    final updatedTheme = _currentTheme.copyWith(
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
      surfaceColor: surfaceColor,
      preset: ThemePreset.custom,
      isCustom: true,
    );
    await setCurrentTheme(updatedTheme);
  }

  Future<void> resetToDefault() async {
    await setCurrentTheme(ThemeModel.defaultLight());
  }

  // Get available preset themes
  List<ThemeModel> get availablePresets => [
    ThemeModel.defaultLight(),
    ThemeModel.defaultDark(),
    ThemeModel.blueTheme(),
    const ThemeModel(
      id: 'green_theme',
      name: 'Green Theme',
      preset: ThemePreset.green,
      primaryColor: Color(0xFF4CAF50),
      secondaryColor: Color(0xFF8BC34A),
    ),
    const ThemeModel(
      id: 'purple_theme',
      name: 'Purple Theme',
      preset: ThemePreset.purple,
      primaryColor: Color(0xFF9C27B0),
      secondaryColor: Color(0xFFBA68C8),
    ),
    const ThemeModel(
      id: 'orange_theme',
      name: 'Orange Theme',
      preset: ThemePreset.orange,
      primaryColor: Color(0xFFFF9800),
      secondaryColor: Color(0xFFFFCC80),
    ),
  ];
}
  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.system);
        break;
      case ThemeMode.system:
        setThemeMode(ThemeMode.light);
        break;
    }
  }
}
