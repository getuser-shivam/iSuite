import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/central_config.dart';
import '../../core/component_factory.dart';
import '../../core/base_component.dart';
import '../../core/app_theme.dart';
import '../../core/component_registry.dart';

class ThemeProvider extends BaseProvider implements ParameterizedComponent {
  static const String _id = 'theme_provider';
  
  @override
  String get id => _id;
  
  @override
  String get name => 'Theme Provider';
  
  @override
  String get version => '1.0.0';
  
  @override
  List<Type> get dependencies => [];

  ThemeMode _themeMode = ThemeMode.system;
  bool _useCustomTheme = false;
  CustomThemeData? _customTheme;
  final List<CustomThemeData> _savedThemes = [];

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get useCustomTheme => _useCustomTheme;
  CustomThemeData? get customTheme => _customTheme;
  List<CustomThemeData> get savedThemes => List.from(_savedThemes);

  ThemeProvider() {
    _initializeFromConfig();
  }

  Future<void> _initializeFromConfig() async {
    await CentralConfig.instance.initialize();
    
    // Set default parameters from central config
    _parameters['default_theme'] = CentralConfig.instance.getParameter('app_theme', 'system');
    _parameters['enable_custom_themes'] = CentralConfig.instance.getParameter('enable_custom_themes', true);
    _parameters['theme_cache_size'] = CentralConfig.instance.getParameter('theme_cache_size', 10);
    _parameters['auto_switch_theme'] = CentralConfig.instance.getParameter('auto_switch_theme', true);
    _parameters['transition_duration'] = CentralConfig.instance.getParameter('theme_transition_duration', Duration(milliseconds: 300));
    _parameters['primary_color'] = CentralConfig.instance.getParameter('primary_color', '#1976D2');
    _parameters['font_size'] = CentralConfig.instance.getParameter('font_size', 14.0);
    _parameters['font_family'] = CentralConfig.instance.getParameter('font_family', 'Roboto');
  }

  @override
  void updateParameters(Map<String, dynamic> parameters) {
    for (final entry in parameters.entries) {
      switch (entry.key) {
        case 'app_theme':
        case 'default_theme':
          _parameters['default_theme'] = entry.value as String;
          break;
        case 'enable_custom_themes':
          _parameters['enable_custom_themes'] = entry.value as bool;
          break;
        case 'theme_cache_size':
          _parameters['theme_cache_size'] = entry.value as int;
          break;
        case 'auto_switch_theme':
          _parameters['auto_switch_theme'] = entry.value as bool;
          break;
        case 'theme_transition_duration':
        case 'transition_duration':
          _parameters['transition_duration'] = entry.value as Duration;
          break;
        case 'primary_color':
          _parameters['primary_color'] = entry.value as String;
          break;
        case 'font_size':
          _parameters['font_size'] = entry.value as double;
          break;
        case 'font_family':
          _parameters['font_family'] = entry.value as String;
          break;
      }
    }
    notifyListeners();
  }

  // Get configuration parameters
  Map<String, dynamic> getConfigurationParameters() {
    return {
      'default_theme': _parameters['default_theme'],
      'enable_custom_themes': _parameters['enable_custom_themes'],
      'theme_cache_size': _parameters['theme_cache_size'],
      'auto_switch_theme': _parameters['auto_switch_theme'],
      'transition_duration': _parameters['transition_duration'],
      'primary_color': _parameters['primary_color'],
      'font_size': _parameters['font_size'],
      'font_family': _parameters['font_family'],
    };
  }

  @override
  Future<void> onInitialize() async {
    await _loadThemePreferences();
    await _loadSavedThemes();
  }

  @override
  void onParametersUpdated(Map<String, dynamic> updatedParameters) {
    // React to parameter changes
    if (updatedParameters.containsKey('auto_switch_theme')) {
      final autoSwitch = getParameter<bool>('auto_switch_theme');
      if (autoSwitch != null && !autoSwitch) {
        // Disable auto-switching if parameter changed to false
        // This could trigger additional logic
      }
    }
  }

  Future<void> _loadThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
      
      // Override with central config if available
      final configTheme = CentralConfig.instance.getParameter('app_theme', 'system');
      if (configTheme != 'system') {
        switch (configTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
      }
      _useCustomTheme = prefs.getBool('use_custom_theme') ?? false;
      
      // Load custom theme if enabled
      if (_useCustomTheme) {
        final customThemeJson = prefs.getString('custom_theme');
        if (customThemeJson != null) {
          _customTheme = CustomThemeData.fromJson(customThemeJson);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme preferences: $e');
    }
  }

  Future<void> _loadSavedThemes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themesJson = prefs.getStringList('saved_themes') ?? [];
      
      _savedThemes.clear();
      for (final themeJson in themesJson) {
        final theme = CustomThemeData.fromJson(themeJson);
        _savedThemes.add(theme);
      }
      
      // Enforce cache size limit
      final maxCacheSize = getParameter<int>('theme_cache_size', 10);
      if (_savedThemes.length > maxCacheSize) {
        _savedThemes.removeRange(maxCacheSize, _savedThemes.length);
        await _saveSavedThemes();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load saved themes: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _saveThemePreferences();
    notifyListeners();
    
    // Publish theme change event
    ComponentCommunication.instance.publish('theme_changed', {
      'theme_mode': mode,
      'timestamp': DateTime.now(),
    });
  }

  Future<void> setCustomTheme(CustomThemeData? theme) async {
    if (_customTheme == theme) return;
    
    _customTheme = theme;
    _useCustomTheme = theme != null;
    await _saveThemePreferences();
    notifyListeners();
    
    // Publish custom theme change event
    ComponentCommunication.instance.publish('custom_theme_changed', {
      'theme': theme,
      'enabled': _useCustomTheme,
      'timestamp': DateTime.now(),
    });
  }

  Future<void> saveCustomTheme(CustomThemeData theme) async {
    if (!getParameter<bool>('enable_custom_themes', true)) {
      setError('Custom themes are disabled');
      return;
    }
    
    // Check for duplicates
    final existingIndex = _savedThemes.indexWhere((t) => t.name == theme.name);
    if (existingIndex != -1) {
      _savedThemes[existingIndex] = theme;
    } else {
      _savedThemes.add(theme);
    }
    
    // Enforce cache size limit
    final maxCacheSize = getParameter<int>('theme_cache_size', 10);
    if (_savedThemes.length > maxCacheSize) {
      _savedThemes.removeAt(0);
    }
    
    await _saveSavedThemes();
    notifyListeners();
    
    // Publish theme saved event
    ComponentCommunication.instance.publish('theme_saved', {
      'theme': theme,
      'total_themes': _savedThemes.length,
      'timestamp': DateTime.now(),
    });
  }

  Future<void> deleteCustomTheme(String themeName) async {
    _savedThemes.removeWhere((theme) => theme.name == themeName);
    
    // If deleted theme was in use, disable custom theme
    if (_customTheme?.name == themeName) {
      await setCustomTheme(null);
    }
    
    await _saveSavedThemes();
    notifyListeners();
    
    // Publish theme deleted event
    ComponentCommunication.instance.publish('theme_deleted', {
      'theme_name': themeName,
      'timestamp': DateTime.now(),
    });
  }

  Future<void> _saveThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', _themeMode.index);
      await prefs.setBool('use_custom_theme', _useCustomTheme);
      
      if (_customTheme != null) {
        await prefs.setString('custom_theme', _customTheme!.toJson());
      } else {
        await prefs.remove('custom_theme');
      }
    } catch (e) {
      debugPrint('Failed to save theme preferences: $e');
    }
  }

  Future<void> _saveSavedThemes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themesJson = _savedThemes.map((theme) => theme.toJson()).toList();
      await prefs.setStringList('saved_themes', themesJson);
    } catch (e) {
      debugPrint('Failed to save saved themes: $e');
    }
  }

  ThemeData get lightTheme => _useCustomTheme && _customTheme != null
      ? _customTheme!.toLightTheme()
      : AppTheme.lightTheme;

  ThemeData get darkTheme => _useCustomTheme && _customTheme != null
      ? _customTheme!.toDarkTheme()
      : AppTheme.darkTheme;

  // Theme validation
  bool isValidThemeName(String name) {
    return name.isNotEmpty && 
           name.length <= 50 && 
           !_savedThemes.any((theme) => theme.name == name);
  }

  // Theme export/import
  Map<String, dynamic> exportThemeSettings() {
    return {
      'theme_mode': _themeMode.name,
      'use_custom_theme': _useCustomTheme,
      'custom_theme': _customTheme?.toJson(),
      'saved_themes': _savedThemes.map((t) => t.toJson()).toList(),
      'parameters': _parameters,
    };
  }

  Future<void> importThemeSettings(Map<String, dynamic> settings) async {
    try {
      // Import theme mode
      if (settings['theme_mode'] != null) {
        final mode = ThemeMode.values.firstWhere(
          (m) => m.name == settings['theme_mode'],
          orElse: () => ThemeMode.system,
        );
        await setThemeMode(mode);
      }
      
      // Import custom theme
      if (settings['custom_theme'] != null) {
        final customTheme = CustomThemeData.fromJson(settings['custom_theme']);
        await setCustomTheme(customTheme);
      }
      
      // Import saved themes
      if (settings['saved_themes'] != null) {
        _savedThemes.clear();
        for (final themeJson in settings['saved_themes']) {
          final theme = CustomThemeData.fromJson(themeJson);
          _savedThemes.add(theme);
        }
        await _saveSavedThemes();
      }
      
      // Import parameters
      if (settings['parameters'] != null) {
        updateParameters(Map<String, dynamic>.from(settings['parameters']));
      }
      
      notifyListeners();
    } catch (e) {
      setError('Failed to import theme settings: $e');
    }
  }
}

class CustomThemeData {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color backgroundColor;
  final Color errorColor;
  final Brightness brightness;
  final String? fontFamily;
  final double fontSize;
  final Map<String, dynamic>? customProperties;

  const CustomThemeData({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.backgroundColor,
    required this.errorColor,
    required this.brightness,
    this.fontFamily,
    this.fontSize = 14.0,
    this.customProperties,
  });

  CustomThemeData copyWith({
    String? name,
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
