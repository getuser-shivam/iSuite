import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AccessibilityEngine {
  static AccessibilityEngine? _instance;
  static AccessibilityEngine get instance => _instance ??= AccessibilityEngine._internal();
  AccessibilityEngine._internal();

  // TTS Engine
  FlutterTts? _tts;
  bool _ttsInitialized = false;
  bool _speechEnabled = false;
  double _speechRate = 1.0;
  double _speechPitch = 1.0;
  double _speechVolume = 1.0;
  String _speechLanguage = 'en-US';

  // Screen Reader
  bool _screenReaderEnabled = false;
  bool _highContrastMode = false;
  bool _largeTextMode = false;
  bool _reducedMotionMode = false;
  bool _focusMode = false;

  // Visual Adjustments
  double _textScaleFactor = 1.0;
  double _fontScale = 1.0;
  Color _highContrastColor = Colors.black;
  Color _highContrastBackground = Colors.white;
  double _brightness = 1.0;
  double _contrast = 1.0;

  // Navigation
  bool _keyboardNavigation = false;
  bool _voiceNavigation = false;
  bool _switchNavigation = false;
  bool _eyeTracking = false;

  // Input Methods
  bool _voiceInputEnabled = false;
  bool _gestureInputEnabled = true;
  bool _switchInputEnabled = false;
  bool _eyeTrackingEnabled = false;

  // Assistive Features
  bool _captioningEnabled = false;
  bool _hapticFeedbackEnabled = true;
  bool _audioDescriptionsEnabled = false;
  bool _brailleSupportEnabled = false;

  // Configuration
  bool _isInitialized = false;
  SharedPreferences? _prefs;
  final Map<String, AccessibilitySetting> _settings = {};
  final List<AccessibilityEvent> _eventLog = [];

  // Focus Management
  FocusNode? _currentFocus;
  final List<FocusNode> _focusHistory = [];
  int _focusIndex = 0;

  // Voice Commands
  final Map<String, VoiceCommand> _voiceCommands = {};
  bool _voiceCommandListening = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get speechEnabled => _speechEnabled;
  bool get screenReaderEnabled => _screenReaderEnabled;
  bool get highContrastMode => _highContrastMode;
  bool get largeTextMode => _largeTextMode;
  bool get reducedMotionMode => _reducedMotionMode;
  bool get focusMode => _focusMode;
  double get textScaleFactor => _textScaleFactor;
  double get fontScale => _fontScale;
  bool get keyboardNavigation => _keyboardNavigation;
  bool get voiceNavigation => _voiceNavigation;
  bool get captioningEnabled => _captioningEnabled;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  Map<String, AccessibilitySetting> get settings => Map.from(_settings);
  List<AccessibilityEvent> get eventLog => List.from(_eventLog);

  /// Initialize Accessibility Engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize preferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize TTS
      await _initializeTTS();

      // Load settings
      await _loadSettings();

      // Initialize voice commands
      await _initializeVoiceCommands();

      // Detect system accessibility settings
      await _detectSystemSettings();

      _isInitialized = true;
      await _logAccessibilityEvent(AccessibilityEventType.initialized, {
        'speechEnabled': _speechEnabled,
        'screenReaderEnabled': _screenReaderEnabled,
        'highContrastMode': _highContrastMode,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _initializeTTS() async {
    try {
      _tts = FlutterTts();
      
      await _tts!.setLanguage(_speechLanguage);
      await _tts!.setSpeechRate(_speechRate);
      await _tts!.setPitch(_speechPitch);
      await _tts!.setVolume(_speechVolume);
      
      _tts!.setStartHandler(() {
        _ttsInitialized = true;
      });

      _tts!.setCompletionHandler(() {
        _ttsInitialized = false;
      });

      _tts!.setErrorHandler((msg) {
        _ttsInitialized = false;
      });

      _tts!.setCancelHandler(() {
        _ttsInitialized = false;
      });
    } catch (e) {
      _tts = null;
    }
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _speechEnabled = _prefs!.getBool('speech_enabled') ?? false;
    _screenReaderEnabled = _prefs!.getBool('screen_reader_enabled') ?? false;
    _highContrastMode = _prefs!.getBool('high_contrast_mode') ?? false;
    _largeTextMode = _prefs!.getBool('large_text_mode') ?? false;
    _reducedMotionMode = _prefs!.getBool('reduced_motion_mode') ?? false;
    _focusMode = _prefs!.getBool('focus_mode') ?? false;
    _textScaleFactor = _prefs!.getDouble('text_scale_factor') ?? 1.0;
    _fontScale = _prefs!.getDouble('font_scale') ?? 1.0;
    _keyboardNavigation = _prefs!.getBool('keyboard_navigation') ?? false;
    _voiceNavigation = _prefs!.getBool('voice_navigation') ?? false;
    _captioningEnabled = _prefs!.getBool('captioning_enabled') ?? false;
    _hapticFeedbackEnabled = _prefs!.getBool('haptic_feedback_enabled') ?? true;
    _speechRate = _prefs!.getDouble('speech_rate') ?? 1.0;
    _speechPitch = _prefs!.getDouble('speech_pitch') ?? 1.0;
    _speechVolume = _prefs!.getDouble('speech_volume') ?? 1.0;
    _speechLanguage = _prefs!.getString('speech_language') ?? 'en-US';
  }

  Future<void> _initializeVoiceCommands() async {
    _voiceCommands['next'] = VoiceCommand(
      phrase: 'next',
      action: () => _navigateNext(),
      description: 'Navigate to next element',
    );

    _voiceCommands['previous'] = VoiceCommand(
      phrase: 'previous',
      action: () => _navigatePrevious(),
      description: 'Navigate to previous element',
    );

    _voiceCommands['select'] = VoiceCommand(
      phrase: 'select',
      action: () => _selectCurrent(),
      description: 'Select current element',
    );

    _voiceCommands['back'] = VoiceCommand(
      phrase: 'back',
      action: () => _goBack(),
      description: 'Go back',
    );

    _voiceCommands['home'] = VoiceCommand(
      phrase: 'home',
      action: () => _goHome(),
      description: 'Go to home',
    );

    _voiceCommands['read'] = VoiceCommand(
      phrase: 'read',
      action: () => _readCurrent(),
      description: 'Read current element',
    );

    _voiceCommands['stop'] = VoiceCommand(
      phrase: 'stop',
      action: () => _stopSpeech(),
      description: 'Stop speech',
    );

    _voiceCommands['help'] = VoiceCommand(
      phrase: 'help',
      action: () => _speakHelp(),
      description: 'Speak help information',
    );
  }

  Future<void> _detectSystemSettings() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Check Android accessibility settings
        // This would require platform-specific implementation
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Check iOS accessibility settings
        // This would require platform-specific implementation
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Text-to-Speech
  Future<void> speak(String text, {bool interrupt = false}) async {
    if (!_speechEnabled || _tts == null) return;

    try {
      if (interrupt && _ttsInitialized) {
        await _tts!.stop();
      }

      await _tts!.speak(text);
      
      await _logAccessibilityEvent(AccessibilityEventType.speech, {
        'text': text,
        'interrupt': interrupt,
      });
    } catch (e) {
      await _logAccessibilityEvent(AccessibilityEventType.speechError, {
        'error': e.toString(),
      });
    }
  }

  Future<void> stopSpeech() async {
    if (_tts == null) return;

    try {
      await _tts!.stop();
      await _logAccessibilityEvent(AccessibilityEventType.speechStopped, {});
    } catch (e) {
      // Handle error
    }
  }

  /// Screen Reader
  Future<void> announceScreenChange(String screenName, String? description) async {
    if (!_screenReaderEnabled) return;

    final message = description != null 
        ? 'You are now on $screenName. $description'
        : 'You are now on $screenName';

    await speak(message);
  }

  Future<void> announceElement(String element, String? description) async {
    if (!_screenReaderEnabled) return;

    final message = description != null 
        ? '$element. $description'
        : element;

    await speak(message);
  }

  /// Focus Management
  void requestFocus(FocusNode focusNode) {
    if (_currentFocus != null) {
      _currentFocus!.unfocus();
      _focusHistory.add(_currentFocus!);
    }

    focusNode.requestFocus();
    _currentFocus = focusNode;
    _focusIndex = _focusHistory.length;

    if (_screenReaderEnabled) {
      _announceFocusChange(focusNode);
    }
  }

  void _announceFocusChange(FocusNode focusNode) {
    // In a real implementation, this would get the semantic label
    // For now, we'll use a generic announcement
    announceElement('Element', 'Focused');
  }

  void navigateNext() {
    if (_focusIndex < _focusHistory.length - 1) {
      _focusIndex++;
      final nextFocus = _focusHistory[_focusIndex];
      requestFocus(nextFocus);
    }
  }

  void navigatePrevious() {
    if (_focusIndex > 0) {
      _focusIndex--;
      final previousFocus = _focusHistory[_focusIndex];
      requestFocus(previousFocus);
    }
  }

  void selectCurrent() {
    if (_currentFocus != null) {
      // In a real implementation, this would trigger the action
      _provideHapticFeedback();
    }
  }

  void goBack() {
    // Navigate back
    _provideHapticFeedback();
  }

  void goHome() {
    // Navigate to home
    _provideHapticFeedback();
  }

  void readCurrent() {
    if (_currentFocus != null) {
      // Read the current focused element
      announceElement('Current Element', null);
    }
  }

  /// Settings Management
  Future<void> setSpeechEnabled(bool enabled) async {
    _speechEnabled = enabled;
    await _prefs?.setBool('speech_enabled', enabled);
    await _logAccessibilityEvent(AccessibilityEventType.settingChanged, {
      'setting': 'speech_enabled',
      'value': enabled,
    });
  }

  Future<void> setScreenReaderEnabled(bool enabled) async {
    _screenReaderEnabled = enabled;
    await _prefs?.setBool('screen_reader_enabled', enabled);
    await _logAccessibilityEvent(AccessibilityEventType.settingChanged, {
      'setting': 'screen_reader_enabled',
      'value': enabled,
    });
  }

  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastMode = enabled;
    await _prefs?.setBool('high_contrast_mode', enabled);
    await _logAccessibilityEvent(AccessibilityEventType.settingChanged, {
      'setting': 'high_contrast_mode',
      'value': enabled,
    });
  }

  Future<void> setLargeTextMode(bool enabled) async {
    _largeTextMode = enabled;
    _textScaleFactor = enabled ? 1.5 : 1.0;
    await _prefs?.setBool('large_text_mode', enabled);
    await _prefs?.setDouble('text_scale_factor', _textScaleFactor);
    await _logAccessibilityEvent(AccessibilityEventType.settingChanged, {
      'setting': 'large_text_mode',
      'value': enabled,
    });
  }

  Future<void> setReducedMotionMode(bool enabled) async {
    _reducedMotionMode = enabled;
    await _prefs?.setBool('reduced_motion_mode', enabled);
    await _logAccessibilityEvent(AccessibilityEventType.settingChanged, {
      'setting': 'reduced_motion_mode',
      'value': enabled,
    });
  }

  Future<void> setTextScaleFactor(double scale) async {
    _textScaleFactor = scale;
    await _prefs?.setDouble('text_scale_factor', scale);
    await _logAccessibilityEvent(AccessibilityEventType.settingChanged, {
      'setting': 'text_scale_factor',
      'value': scale,
    });
  }

  Future<void> setKeyboardNavigation(bool enabled) async {
    _keyboardNavigation = enabled;
    await _prefs?.setBool('keyboard_navigation', enabled);
    await _logAccessibilityEvent(AccessibilityEventType.settingChanged, {
      'setting': 'keyboard_navigation',
      'value': enabled,
    });
  }

  Future<void> setCaptioningEnabled(bool enabled) async {
    _captioningEnabled = enabled;
    await _prefs?.setBool('captioning_enabled', enabled);
    await _logAccessibilityEvent(AccessibilityEventType.settingChanged, {
      'setting': 'captioning_enabled',
      'value': enabled,
    });
  }

  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    _hapticFeedbackEnabled = enabled;
    await _prefs?.setBool('haptic_feedback_enabled', enabled);
    await _logAccessibilityEvent(AccessibilityEventType.settingChanged, {
      'setting': 'haptic_feedback_enabled',
      'value': enabled,
    });
  }

  Future<void> setSpeechSettings({
    double? rate,
    double? pitch,
    double? volume,
    String? language,
  }) async {
    if (rate != null) {
      _speechRate = rate;
      await _tts?.setSpeechRate(rate);
      await _prefs?.setDouble('speech_rate', rate);
    }

    if (pitch != null) {
      _speechPitch = pitch;
      await _tts?.setPitch(pitch);
      await _prefs?.setDouble('speech_pitch', pitch);
    }

    if (volume != null) {
      _speechVolume = volume;
      await _tts?.setVolume(volume);
      await _prefs?.setDouble('speech_volume', volume);
    }

    if (language != null) {
      _speechLanguage = language;
      await _tts?.setLanguage(language);
      await _prefs?.setString('speech_language', language);
    }

    await _logAccessibilityEvent(AccessibilityEventType.settingChanged, {
      'speechRate': _speechRate,
      'speechPitch': _speechPitch,
      'speechVolume': _speechVolume,
      'speechLanguage': _speechLanguage,
    });
  }

  /// Haptic Feedback
  void _provideHapticFeedback() {
    if (!_hapticFeedbackEnabled) return;

    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      // Handle error
    }
  }

  void provideHapticFeedback(HapticType type) {
    if (!_hapticFeedbackEnabled) return;

    try {
      switch (type) {
        case HapticType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticType.selection:
          HapticFeedback.selectionClick();
          break;
        case HapticType.notification:
          HapticFeedback.notificationFeedback();
          break;
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Voice Commands
  Future<void> processVoiceCommand(String command) async {
    final normalizedCommand = command.toLowerCase().trim();
    
    for (final voiceCommand in _voiceCommands.values) {
      if (normalizedCommand.contains(voiceCommand.phrase.toLowerCase())) {
        await voiceCommand.action();
        await _logAccessibilityEvent(AccessibilityEventType.voiceCommand, {
          'command': normalizedCommand,
          'matched': voiceCommand.phrase,
        });
        return;
      }
    }

    // Command not found
    await speak('Command not recognized');
    await _logAccessibilityEvent(AccessibilityEventType.voiceCommandNotFound, {
      'command': normalizedCommand,
    });
  }

  Future<void> _speakHelp() async {
    final helpText = '''
Available voice commands:
- Next: Navigate to next element
- Previous: Navigate to previous element
- Select: Select current element
- Back: Go back
- Home: Go to home
- Read: Read current element
- Stop: Stop speech
- Help: Speak this help information
    ''';

    await speak(helpText);
  }

  /// Accessibility Theme
  ThemeData getAccessibilityTheme(ThemeData baseTheme) {
    if (!_highContrastMode) return baseTheme;

    return baseTheme.copyWith(
      brightness: Brightness.dark,
      primaryColor: Colors.white,
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey[900],
      textTheme: baseTheme.textTheme.copyWith(
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontSize: (baseTheme.textTheme.bodyLarge?.fontSize ?? 14) * _textScaleFactor,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontSize: (baseTheme.textTheme.bodyMedium?.fontSize ?? 14) * _textScaleFactor,
        ),
        bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontSize: (baseTheme.textTheme.bodySmall?.fontSize ?? 12) * _textScaleFactor,
        ),
        titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontSize: (baseTheme.textTheme.titleLarge?.fontSize ?? 20) * _textScaleFactor,
        ),
        titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontSize: (baseTheme.textTheme.titleMedium?.fontSize ?? 16) * _textScaleFactor,
        ),
        titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontSize: (baseTheme.textTheme.titleSmall?.fontSize ?? 14) * _textScaleFactor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          textStyle: TextStyle(
            fontSize: 14 * _textScaleFactor,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white),
          textStyle: TextStyle(
            fontSize: 14 * _textScaleFactor,
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
        size: 24 * _textScaleFactor,
      ),
    );
  }

  /// Accessibility Information
  Map<String, dynamic> getAccessibilityInfo() {
    return {
      'isInitialized': _isInitialized,
      'speechEnabled': _speechEnabled,
      'screenReaderEnabled': _screenReaderEnabled,
      'highContrastMode': _highContrastMode,
      'largeTextMode': _largeTextMode,
      'reducedMotionMode': _reducedMotionMode,
      'focusMode': _focusMode,
      'textScaleFactor': _textScaleFactor,
      'fontScale': _fontScale,
      'keyboardNavigation': _keyboardNavigation,
      'voiceNavigation': _voiceNavigation,
      'captioningEnabled': _captioningEnabled,
      'hapticFeedbackEnabled': _hapticFeedbackEnabled,
      'speechSettings': {
        'rate': _speechRate,
        'pitch': _speechPitch,
        'volume': _speechVolume,
        'language': _speechLanguage,
      },
      'voiceCommands': _voiceCommands.map((k, v) => MapEntry(k, v.toMap())),
      'currentFocus': _currentFocus?.toString(),
      'focusHistoryLength': _focusHistory.length,
    };
  }

  /// Accessibility Audit
  Map<String, dynamic> performAccessibilityAudit() {
    final issues = <String>[];
    final suggestions = <String>[];

    // Check text scaling
    if (_textScaleFactor < 1.0) {
      issues.add('Text scale factor is less than 1.0');
      suggestions.add('Consider increasing text scale for better readability');
    }

    // Check contrast
    if (!_highContrastMode) {
      suggestions.add('Consider enabling high contrast mode for better visibility');
    }

    // Check screen reader
    if (!_screenReaderEnabled) {
      suggestions.add('Consider enabling screen reader for visually impaired users');
    }

    // Check haptic feedback
    if (!_hapticFeedbackEnabled) {
      suggestions.add('Consider enabling haptic feedback for better user feedback');
    }

    // Check keyboard navigation
    if (!_keyboardNavigation) {
      suggestions.add('Consider enabling keyboard navigation for accessibility');
    }

    return {
      'score': _calculateAccessibilityScore(issues.length),
      'issues': issues,
      'suggestions': suggestions,
      'compliance': _checkCompliance(),
    };
  }

  double _calculateAccessibilityScore(int issueCount) {
    const maxIssues = 10;
    final score = max(0, (maxIssues - issueCount) / maxIssues * 100);
    return score;
  }

  Map<String, bool> _checkCompliance() {
    return {
      'wcag_aa': _checkWCAGCompliance('AA'),
      'wcag_aaa': _checkWCAGCompliance('AAA'),
      'section508': _checkSection508Compliance(),
    };
  }

  bool _checkWCAGCompliance(String level) {
    // Simplified WCAG compliance check
    switch (level) {
      case 'AA':
        return _screenReaderEnabled && _keyboardNavigation && _hapticFeedbackEnabled;
      case 'AAA':
        return _screenReaderEnabled && _keyboardNavigation && _hapticFeedbackEnabled && 
               _highContrastMode && _largeTextMode;
      default:
        return false;
    }
  }

  bool _checkSection508Compliance() {
    // Simplified Section 508 compliance check
    return _screenReaderEnabled && _keyboardNavigation && _hapticFeedbackEnabled;
  }

  /// Log accessibility event
  Future<void> _logAccessibilityEvent(AccessibilityEventType type, Map<String, dynamic> data) async {
    final event = AccessibilityEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    _eventLog.add(event);

    // Limit event log size
    if (_eventLog.length > 1000) {
      _eventLog.removeRange(0, _eventLog.length - 1000);
    }
  }

  /// Dispose accessibility engine
  Future<void> dispose() async {
    await _tts?.stop();
    _tts = null;
    _currentFocus?.unfocus();
    _focusHistory.clear();
    _voiceCommands.clear();
    _eventLog.clear();
    _isInitialized = false;
  }
}

// Accessibility Models
class AccessibilitySetting {
  final String name;
  final String description;
  final dynamic value;
  final AccessibilitySettingType type;

  const AccessibilitySetting({
    required this.name,
    required this.description,
    required this.value,
    required this.type,
  });
}

class AccessibilityEvent {
  final String id;
  final AccessibilityEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const AccessibilityEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class VoiceCommand {
  final String phrase;
  final VoidCallback action;
  final String description;

  const VoiceCommand({
    required this.phrase,
    required this.action,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'phrase': phrase,
      'description': description,
    };
  }
}

// Enums
enum AccessibilitySettingType {
  boolean,
  number,
  string,
  enum,
}

enum AccessibilityEventType {
  initialized,
  speech,
  speechStopped,
  speechError,
  settingChanged,
  focusChanged,
  navigation,
  voiceCommand,
  voiceCommandNotFound,
  hapticFeedback,
  captioning,
  braille,
  screenReader,
  highContrast,
  largeText,
  reducedMotion,
  keyboardNavigation,
  voiceNavigation,
  unknown,
}

enum HapticType {
  light,
  medium,
  heavy,
  selection,
  notification,
}
