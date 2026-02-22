import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/central_config.dart';
import '../../../core/logging/logging_service.dart';
import '../../../core/robustness_manager.dart';
import '../../../core/supabase_service.dart';

/// Enhanced App Configuration Service
/// Centralizes all UI configuration parameters and provides dynamic updates
class UIConfigService {
  static final UIConfigService _instance = UIConfigService._internal();
  factory UIConfigService() => _instance;
  UIConfigService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final RobustnessManager _robustness = RobustnessManager();

  // UI Configuration Keys
  static const String _primaryColorKey = 'ui.primary_color';
  static const String _secondaryColorKey = 'ui.secondary_color';
  static const String _accentColorKey = 'ui.accent_color';
  static const String _backgroundColorKey = 'ui.background_color';
  static const String _surfaceColorKey = 'ui.surface_color';
  static const String _errorColorKey = 'ui.error_color';
  static const String _successColorKey = 'ui.success_color';
  static const String _warningColorKey = 'ui.warning_color';
  static const String _fontFamilyKey = 'ui.font_family';
  static const String _fontSizeKey = 'ui.font_size';
  static const String _paddingKey = 'ui.padding';
  static const String _marginKey = 'ui.margin';
  static const String _borderRadiusKey = 'ui.border_radius';
  static const String _elevationKey = 'ui.elevation';
  static const String _animationDurationKey = 'ui.animation_duration';
  static const String _gridColumnsKey = 'ui.grid_columns';
  static const String _listItemHeightKey = 'ui.list_item_height';
  static const String _iconSizeKey = 'ui.icon_size';
  static const String _buttonHeightKey = 'ui.button_height';
  static const String _cardElevationKey = 'ui.card_elevation';
  static const String _appBarHeightKey = 'ui.app_bar_height';
  static const String _bottomNavHeightKey = 'ui.bottom_nav_height';
  static const String _fabSizeKey = 'ui.fab_size';
  static const String _dialogWidthKey = 'ui.dialog_width';
  static const String _dialogHeightKey = 'ui.dialog_height';
  static const String _sheetHeightKey = 'ui.sheet_height';
  static const String _chipHeightKey = 'ui.chip_height';
  static const String _tabBarHeightKey = 'ui.tab_bar_height';
  static const String _dividerHeightKey = 'ui.divider_height';
  static const String _progressBarHeightKey = 'ui.progress_bar_height';
  static const String _sliderHeightKey = 'ui.slider_height';
  static const String _switchHeightKey = 'ui.switch_height';
  static const String _checkboxSizeKey = 'ui.checkbox_size';
  static const String _radioSizeKey = 'ui.radio_size';
  static const String _textFieldHeightKey = 'ui.text_field_height';
  static const String _dropdownHeightKey = 'ui.dropdown_height';
  static const String _datePickerHeightKey = 'ui.date_picker_height';
  static const String _timePickerHeightKey = 'ui.time_picker_height';

  /// Initialize UI configuration with default values
  Future<void> initialize() async {
    try {
      _logger.info('Initializing UI configuration', 'UIConfigService');
      
      await _setupDefaultUIConfig();
      await _loadUserPreferences();
      
      _logger.info('UI configuration initialized successfully', 'UIConfigService');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize UI configuration', 'UIConfigService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Setup default UI configuration
  Future<void> _setupDefaultUIConfig() async {
    // Colors
    await _config.setParameter(_primaryColorKey, 0xFF1976D2, 
        description: 'Primary theme color');
    await _config.setParameter(_secondaryColorKey, 0xFFDCEDC8,
        description: 'Secondary theme color');
    await _config.setParameter(_accentColorKey, 0xFFFF9800,
        description: 'Accent color');
    await _config.setParameter(_backgroundColorKey, 0xFFF5F5F5,
        description: 'Background color');
    await _config.setParameter(_surfaceColorKey, 0xFFFFFFFF,
        description: 'Surface color');
    await _config.setParameter(_errorColorKey, 0xFFD32F2F,
        description: 'Error color');
    await _config.setParameter(_successColorKey, 0xFF388E3C,
        description: 'Success color');
    await _config.setParameter(_warningColorKey, 0xFFFFA000,
        description: 'Warning color');

    // Typography
    await _config.setParameter(_fontFamilyKey, 'Roboto',
        description: 'Default font family');
    await _config.setParameter(_fontSizeKey, 14.0,
        description: 'Default font size');

    // Spacing
    await _config.setParameter(_paddingKey, 16.0,
        description: 'Default padding');
    await _config.setParameter(_marginKey, 16.0,
        description: 'Default margin');

    // Appearance
    await _config.setParameter(_borderRadiusKey, 8.0,
        description: 'Default border radius');
    await _config.setParameter(_elevationKey, 2.0,
        description: 'Default elevation');

    // Animation
    await _config.setParameter(_animationDurationKey, 300,
        description: 'Default animation duration in milliseconds');

    // Layout
    await _config.setParameter(_gridColumnsKey, 2,
        description: 'Default grid columns');
    await _config.setParameter(_listItemHeightKey, 56.0,
        description: 'List item height');

    // Components
    await _config.setParameter(_iconSizeKey, 24.0,
        description: 'Default icon size');
    await _config.setParameter(_buttonHeightKey, 48.0,
        description: 'Default button height');
    await _config.setParameter(_cardElevationKey, 2.0,
        description: 'Card elevation');
    await _config.setParameter(_appBarHeightKey, 56.0,
        description: 'App bar height');
    await _config.setParameter(_bottomNavHeightKey, 56.0,
        description: 'Bottom navigation height');
    await _config.setParameter(_fabSizeKey, 56.0,
        description: 'Floating action button size');
    await _config.setParameter(_dialogWidthKey, 400.0,
        description: 'Dialog width');
    await _config.setParameter(_dialogHeightKey, 300.0,
        description: 'Dialog height');
    await _config.setParameter(_sheetHeightKey, 300.0,
        description: 'Bottom sheet height');
    await _config.setParameter(_chipHeightKey, 32.0,
        description: 'Chip height');
    await _config.setParameter(_tabBarHeightKey, 48.0,
        description: 'Tab bar height');
    await _config.setParameter(_dividerHeightKey, 1.0,
        description: 'Divider height');
    await _config.setParameter(_progressBarHeightKey, 4.0,
        description: 'Progress bar height');
    await _config.setParameter(_sliderHeightKey, 48.0,
        description: 'Slider height');
    await _config.setParameter(_switchHeightKey, 48.0,
        description: 'Switch height');
    await _config.setParameter(_checkboxSizeKey, 24.0,
        description: 'Checkbox size');
    await _config.setParameter(_radioSizeKey, 24.0,
        description: 'Radio button size');
    await _config.setParameter(_textFieldHeightKey, 56.0,
        description: 'Text field height');
    await _config.setParameter(_dropdownHeightKey, 48.0,
        description: 'Dropdown height');
    await _config.setParameter(_datePickerHeightKey, 300.0,
        description: 'Date picker height');
    await _config.setParameter(_timePickerHeightKey, 300.0,
        description: 'Time picker height');
  }

  /// Load user preferences from storage
  Future<void> _loadUserPreferences() async {
    try {
      // Load user customizations
      final userPreferences = await _config.getParameter('ui.user_preferences', defaultValue: {});
      
      if (userPreferences is Map) {
        for (final entry in userPreferences.entries) {
          await _config.setParameter(entry.key, entry.value);
        }
      }
    } catch (e) {
      _logger.warning('Failed to load user preferences', 'UIConfigService', error: e);
    }
  }

  /// Save user preferences
  Future<void> saveUserPreferences() async {
    try {
      final userPreferences = <String, dynamic>{};
      
      // Collect all UI parameters
      final allParameters = await _config.getAllParameters();
      
      for (final entry in allParameters.entries) {
        if (entry.key.startsWith('ui.')) {
          userPreferences[entry.key] = entry.value;
        }
      }
      
      await _config.setParameter('ui.user_preferences', userPreferences);
      _logger.info('User preferences saved', 'UIConfigService');
    } catch (e) {
      _logger.error('Failed to save user preferences', 'UIConfigService', error: e);
    }
  }

  /// Get color value
  Color getColor(String key) {
    final value = _config.getParameter(key, defaultValue: 0xFF000000);
    return Color(value as int);
  }

  /// Get double value
  double getDouble(String key) {
    return _config.getParameter(key, defaultValue: 0.0) as double;
  }

  /// Get int value
  int getInt(String key) {
    return _config.getParameter(key, defaultValue: 0) as int;
  }

  /// Get string value
  String getString(String key) {
    return _config.getParameter(key, defaultValue: '') as String;
  }

  /// Update color value
  Future<void> setColor(String key, Color value) async {
    await _config.setParameter(key, value.value);
    _notifyUIUpdate();
  }

  /// Update double value
  Future<void> setDouble(String key, double value) async {
    await _config.setParameter(key, value);
    _notifyUIUpdate();
  }

  /// Update int value
  Future<void> setInt(String key, int value) async {
    await _config.setParameter(key, value);
    _notifyUIUpdate();
  }

  /// Update string value
  Future<void> setString(String key, String value) async {
    await _config.setParameter(key, value);
    _notifyUIUpdate();
  }

  /// Notify UI of configuration changes
  void _notifyUIUpdate() {
    _logger.info('UI configuration updated', 'UIConfigService');
    // This would typically trigger a UI rebuild through a state management solution
  }

  /// Get theme data
  ThemeData getThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: getColor(_primaryColorKey),
        brightness: Brightness.light,
        primary: getColor(_primaryColorKey),
        secondary: getColor(_secondaryColorKey),
        surface: getColor(_surfaceColorKey),
        background: getColor(_backgroundColorKey),
        error: getColor(_errorColorKey),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onBackground: Colors.black,
        onError: Colors.white,
      ),
      fontFamily: getString(_fontFamilyKey),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: getDouble(_fontSizeKey)),
        bodyMedium: TextStyle(fontSize: getDouble(_fontSizeKey) - 2),
        bodySmall: TextStyle(fontSize: getDouble(_fontSizeKey) - 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(0, getDouble(_buttonHeightKey)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(getDouble(_borderRadiusKey)),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: getDouble(_cardElevationKey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(getDouble(_borderRadiusKey)),
        ),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: getDouble(_appBarHeightKey),
        elevation: getDouble(_elevationKey),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedFontSize: getDouble(_fontSizeKey) - 2,
        unselectedFontSize: getDouble(_fontSizeKey) - 4,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        size: getDouble(_fabSizeKey),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(getDouble(_borderRadiusKey)),
        ),
      ),
      chipTheme: ChipThemeData(
        labelPadding: EdgeInsets.symmetric(horizontal: getDouble(_paddingKey)),
        padding: EdgeInsets.symmetric(horizontal: getDouble(_paddingKey)),
      ),
      dividerTheme: DividerThemeData(
        thickness: getDouble(_dividerHeightKey),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearMinHeight: getDouble(_progressBarHeightKey),
        circularMinRadius: getDouble(_progressBarHeightKey) / 2,
      ),
      switchTheme: SwitchThemeData(
        thumbSize: MaterialStateProperty.all(getDouble(_switchHeightKey)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Get responsive dimensions based on screen size
  ResponsiveDimensions getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive values
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;
    
    return ResponsiveDimensions(
      padding: isDesktop ? getDouble(_paddingKey) * 1.5 : getDouble(_paddingKey),
      margin: isDesktop ? getDouble(_marginKey) * 1.5 : getDouble(_marginKey),
      fontSize: isDesktop ? getDouble(_fontSizeKey) * 1.2 : getDouble(_fontSizeKey),
      iconSize: isDesktop ? getDouble(_iconSizeKey) * 1.2 : getDouble(_iconSizeKey),
      buttonHeight: isDesktop ? getDouble(_buttonHeightKey) * 1.2 : getDouble(_buttonHeightKey),
      cardElevation: isDesktop ? getDouble(_cardElevationKey) * 1.5 : getDouble(_cardElevationKey),
      gridColumns: isTablet ? getInt(_gridColumnsKey) + 1 : getInt(_gridColumnsKey),
      listItemHeight: isDesktop ? getDouble(_listItemHeightKey) * 1.2 : getDouble(_listItemHeightKey),
    );
  }

  /// Apply accessibility settings
  Future<void> applyAccessibilitySettings() async {
    try {
      final accessibilityEnabled = _config.getParameter('accessibility.enabled', defaultValue: false);
      
      if (accessibilityEnabled) {
        // Increase font sizes
        await setDouble(_fontSizeKey, getDouble(_fontSizeKey) * 1.2);
        await setDouble(_iconSizeKey, getDouble(_iconSizeKey) * 1.2);
        
        // Increase spacing
        await setDouble(_paddingKey, getDouble(_paddingKey) * 1.2);
        await setDouble(_marginKey, getDouble(_marginKey) * 1.2);
        
        // Increase touch targets
        await setDouble(_buttonHeightKey, getDouble(_buttonHeightKey) * 1.2);
        await setDouble(_switchHeightKey, getDouble(_switchHeightKey) * 1.2);
        
        _logger.info('Accessibility settings applied', 'UIConfigService');
      }
    } catch (e) {
      _logger.error('Failed to apply accessibility settings', 'UIConfigService', error: e);
    }
  }

  /// Reset to default configuration
  Future<void> resetToDefaults() async {
    try {
      await _setupDefaultUIConfig();
      await saveUserPreferences();
      _logger.info('UI configuration reset to defaults', 'UIConfigService');
    } catch (e) {
      _logger.error('Failed to reset UI configuration', 'UIConfigService', error: e);
    }
  }

  /// Export configuration to JSON
  Map<String, dynamic> exportConfiguration() {
    return {
      'colors': {
        'primary': getColor(_primaryColorKey).value,
        'secondary': getColor(_secondaryColorKey).value,
        'accent': getColor(_accentColorKey).value,
        'background': getColor(_backgroundColorKey).value,
        'surface': getColor(_surfaceColorKey).value,
        'error': getColor(_errorColorKey).value,
        'success': getColor(_successColorKey).value,
        'warning': getColor(_warningColorKey).value,
      },
      'typography': {
        'fontFamily': getString(_fontFamilyKey),
        'fontSize': getDouble(_fontSizeKey),
      },
      'spacing': {
        'padding': getDouble(_paddingKey),
        'margin': getDouble(_marginKey),
      },
      'appearance': {
        'borderRadius': getDouble(_borderRadiusKey),
        'elevation': getDouble(_elevationKey),
      },
      'layout': {
        'gridColumns': getInt(_gridColumnsKey),
        'listItemHeight': getDouble(_listItemHeightKey),
      },
      'components': {
        'iconSize': getDouble(_iconSizeKey),
        'buttonHeight': getDouble(_buttonHeightKey),
        'cardElevation': getDouble(_cardElevationKey),
        'appBarHeight': getDouble(_appBarHeightKey),
        'bottomNavHeight': getDouble(_bottomNavHeightKey),
        'fabSize': getDouble(_fabSizeKey),
      },
    };
  }

  /// Import configuration from JSON
  Future<void> importConfiguration(Map<String, dynamic> config) async {
    try {
      // Import colors
      if (config['colors'] != null) {
        final colors = config['colors'] as Map<String, dynamic>;
        for (final entry in colors.entries) {
          final key = _getColorKey(entry.key);
          if (key != null) {
            await setColor(key, Color(entry.value as int));
          }
        }
      }

      // Import typography
      if (config['typography'] != null) {
        final typography = config['typography'] as Map<String, dynamic>;
        if (typography['fontFamily'] != null) {
          await setString(_fontFamilyKey, typography['fontFamily'] as String);
        }
        if (typography['fontSize'] != null) {
          await setDouble(_fontSizeKey, typography['fontSize'] as double);
        }
      }

      // Import spacing
      if (config['spacing'] != null) {
        final spacing = config['spacing'] as Map<String, dynamic>;
        if (spacing['padding'] != null) {
          await setDouble(_paddingKey, spacing['padding'] as double);
        }
        if (spacing['margin'] != null) {
          await setDouble(_marginKey, spacing['margin'] as double);
        }
      }

      // Import appearance
      if (config['appearance'] != null) {
        final appearance = config['appearance'] as Map<String, dynamic>;
        if (appearance['borderRadius'] != null) {
          await setDouble(_borderRadiusKey, appearance['borderRadius'] as double);
        }
        if (appearance['elevation'] != null) {
          await setDouble(_elevationKey, appearance['elevation'] as double);
        }
      }

      // Import layout
      if (config['layout'] != null) {
        final layout = config['layout'] as Map<String, dynamic>;
        if (layout['gridColumns'] != null) {
          await setInt(_gridColumnsKey, layout['gridColumns'] as int);
        }
        if (layout['listItemHeight'] != null) {
          await setDouble(_listItemHeightKey, layout['listItemHeight'] as double);
        }
      }

      // Import components
      if (config['components'] != null) {
        final components = config['components'] as Map<String, dynamic>;
        if (components['iconSize'] != null) {
          await setDouble(_iconSizeKey, components['iconSize'] as double);
        }
        if (components['buttonHeight'] != null) {
          await setDouble(_buttonHeightKey, components['buttonHeight'] as double);
        }
        if (components['cardElevation'] != null) {
          await setDouble(_cardElevationKey, components['cardElevation'] as double);
        }
        if (components['appBarHeight'] != null) {
          await setDouble(_appBarHeightKey, components['appBarHeight'] as double);
        }
        if (components['bottomNavHeight'] != null) {
          await setDouble(_bottomNavHeightKey, components['bottomNavHeight'] as double);
        }
        if (components['fabSize'] != null) {
          await setDouble(_fabSizeKey, components['fabSize'] as double);
        }
      }

      await saveUserPreferences();
      _logger.info('UI configuration imported successfully', 'UIConfigService');
    } catch (e) {
      _logger.error('Failed to import UI configuration', 'UIConfigService', error: e);
    }
  }

  /// Get color key from string name
  String? _getColorKey(String name) {
    switch (name) {
      case 'primary': return _primaryColorKey;
      case 'secondary': return _secondaryColorKey;
      case 'accent': return _accentColorKey;
      case 'background': return _backgroundColorKey;
      case 'surface': return _surfaceColorKey;
      case 'error': return _errorColorKey;
      case 'success': return _successColorKey;
      case 'warning': return _warningColorKey;
      default: return null;
    }
  }
}

/// Responsive dimensions for different screen sizes
class ResponsiveDimensions {
  final double padding;
  final double margin;
  final double fontSize;
  final double iconSize;
  final double buttonHeight;
  final double cardElevation;
  final int gridColumns;
  final double listItemHeight;

  ResponsiveDimensions({
    required this.padding,
    required this.margin,
    required this.fontSize,
    required this.iconSize,
    required this.buttonHeight,
    required this.cardElevation,
    required this.gridColumns,
    required this.listItemHeight,
  });
}

/// UI Theme extension for easy access to configuration
extension UIConfigExtension on BuildContext {
  UIConfigService get uiConfig => UIConfigService();
  
  /// Get responsive dimensions
  ResponsiveDimensions get responsive => uiConfig.getResponsiveDimensions(this);
  
  /// Get theme with configuration
  ThemeData get configuredTheme => uiConfig.getThemeData();
  
  /// Get color from configuration
  Color configColor(String key) => uiConfig.getColor(key);
  
  /// Get double from configuration
  double configDouble(String key) => uiConfig.getDouble(key);
  
  /// Get int from configuration
  int configInt(String key) => uiConfig.getInt(key);
  
  /// Get string from configuration
  String configString(String key) => uiConfig.getString(key);
}
