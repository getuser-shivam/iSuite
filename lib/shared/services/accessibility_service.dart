import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'central_config.dart';

/// Advanced Accessibility Service
/// Provides comprehensive accessibility validation, improvements, and compliance checking
class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final StreamController<AccessibilityEvent> _accessibilityEventController = StreamController.broadcast();

  Stream<AccessibilityEvent> get accessibilityEvents => _accessibilityEventController.stream;

  // Accessibility state
  bool _isInitialized = false;
  bool _screenReaderEnabled = false;
  bool _highContrastEnabled = false;
  bool _keyboardNavigationEnabled = true;
  double _fontScale = 1.0;
  Color _focusHighlightColor = const Color(0xFF6B35FF);
  double _minimumTouchTarget = 44.0;
  Duration _screenReaderDelay = const Duration(milliseconds: 1000);

  // Accessibility validation
  final Map<String, AccessibilityValidator> _validators = {};
  final Map<String, AccessibilityIssue> _currentIssues = {};

  // Compliance tracking
  final Map<ComplianceStandard, ComplianceStatus> _complianceStatus = {};

  // Screen reader management
  final Map<String, ScreenReaderAnnouncement> _pendingAnnouncements = {};

  /// Initialize accessibility service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load accessibility configuration
      await _loadAccessibilityConfiguration();

      // Initialize validators
      _initializeValidators();

      // Set up accessibility monitoring
      _setupAccessibilityMonitoring();

      // Perform initial accessibility audit
      await _performInitialAccessibilityAudit();

      _isInitialized = true;
      _emitAccessibilityEvent(AccessibilityEventType.serviceInitialized);

    } catch (e) {
      _emitAccessibilityEvent(AccessibilityEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Validate widget accessibility
  Future<AccessibilityValidationResult> validateWidgetAccessibility(
    BuildContext context,
    Widget widget, {
    bool includeChildren = true,
    List<AccessibilityRule>? customRules,
  }) async {
    final issues = <AccessibilityIssue>[];
    final warnings = <AccessibilityWarning>[];

    try {
      // Get render object
      final renderObject = context.findRenderObject();
      if (renderObject == null) {
        issues.add(AccessibilityIssue(
          type: AccessibilityIssueType.missingRenderObject,
          severity: AccessibilitySeverity.error,
          message: 'Widget does not have a render object',
          element: context.widget,
        ));
        return AccessibilityValidationResult(
          isAccessible: false,
          issues: issues,
          warnings: warnings,
          score: 0.0,
        );
      }

      // Run all validators
      final allRules = customRules ?? _validators.values.map((v) => v.rule).toList();

      for (final rule in allRules) {
        final result = await rule.validate(context, widget, renderObject);
        issues.addAll(result.issues);
        warnings.addAll(result.warnings);
      }

      // Calculate accessibility score
      final score = _calculateAccessibilityScore(issues, warnings);

      final isAccessible = issues.where((issue) => issue.severity == AccessibilitySeverity.error).isEmpty;

      return AccessibilityValidationResult(
        isAccessible: isAccessible,
        issues: issues,
        warnings: warnings,
        score: score,
      );

    } catch (e) {
      issues.add(AccessibilityIssue(
        type: AccessibilityIssueType.validationError,
        severity: AccessibilitySeverity.error,
        message: 'Accessibility validation failed: $e',
        element: widget,
      ));

      return AccessibilityValidationResult(
        isAccessible: false,
        issues: issues,
        warnings: warnings,
        score: 0.0,
      );
    }
  }

  /// Perform comprehensive accessibility audit
  Future<AccessibilityAuditResult> performAccessibilityAudit({
    bool includeAllScreens = true,
    List<String>? specificScreens,
    bool includeSemanticTree = true,
  }) async {
    _emitAccessibilityEvent(AccessibilityEventType.auditStarted);

    try {
      final screenResults = <String, AccessibilityValidationResult>{};
      final globalIssues = <AccessibilityIssue>[];
      final globalWarnings = <AccessibilityWarning>[];

      // Get screens to audit
      final screensToAudit = specificScreens ?? await _getAvailableScreens();

      for (final screenName in screensToAudit) {
        final screenResult = await _auditScreen(screenName, includeSemanticTree: includeSemanticTree);
        screenResults[screenName] = screenResult;

        globalIssues.addAll(screenResult.issues);
        globalWarnings.addAll(screenResult.warnings);
      }

      // Calculate overall score
      final overallScore = _calculateOverallAccessibilityScore(screenResults.values);

      // Generate compliance report
      final complianceReport = await _generateComplianceReport(globalIssues, globalWarnings);

      final result = AccessibilityAuditResult(
        overallScore: overallScore,
        screenResults: screenResults,
        globalIssues: globalIssues,
        globalWarnings: globalWarnings,
        complianceReport: complianceReport,
        auditTimestamp: DateTime.now(),
      );

      _emitAccessibilityEvent(
        AccessibilityEventType.auditCompleted,
        details: 'Score: ${(overallScore * 100).round()}%, Issues: ${globalIssues.length}'
      );

      return result;

    } catch (e) {
      _emitAccessibilityEvent(AccessibilityEventType.auditFailed, error: e.toString());
      rethrow;
    }
  }

  /// Announce content to screen reader
  Future<void> announceToScreenReader(String message, {
    String? assertionId,
    AnnounceMode mode = AnnounceMode.polite,
  }) async {
    if (!_screenReaderEnabled) return;

    final announcement = ScreenReaderAnnouncement(
      id: assertionId ?? 'announcement_${DateTime.now().millisecondsSinceEpoch}',
      message: message,
      mode: mode,
      timestamp: DateTime.now(),
    );

    _pendingAnnouncements[announcement.id] = announcement;

    // Schedule announcement
    Future.delayed(_screenReaderDelay, () {
      if (_pendingAnnouncements.containsKey(announcement.id)) {
        _performScreenReaderAnnouncement(announcement);
        _pendingAnnouncements.remove(announcement.id);
      }
    });

    _emitAccessibilityEvent(AccessibilityEventType.screenReaderAnnouncement,
      details: message);
  }

  /// Set focus to accessible element
  Future<void> setAccessibilityFocus(BuildContext context, {
    FocusNode? focusNode,
    String? semanticLabel,
  }) async {
    if (focusNode != null) {
      FocusScope.of(context).requestFocus(focusNode);
    }

    if (semanticLabel != null && _screenReaderEnabled) {
      await announceToScreenReader('Focused on $semanticLabel');
    }

    _emitAccessibilityEvent(AccessibilityEventType.focusChanged,
      details: semanticLabel ?? 'focusNode');
  }

  /// Adjust font scale for better readability
  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.5, 3.0);

    // Update configuration
    await _config.setParameter('accessibility.font_scale', _fontScale, source: 'accessibility_service');

    // Notify listeners
    await _config.notifyConfigurationChanged();

    _emitAccessibilityEvent(AccessibilityEventType.fontScaleChanged,
      details: 'Scale: $_fontScale');
  }

  /// Enable or disable high contrast mode
  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastEnabled = enabled;

    await _config.setParameter('accessibility.high_contrast_enabled', enabled, source: 'accessibility_service');
    await _config.notifyConfigurationChanged();

    _emitAccessibilityEvent(
      enabled ? AccessibilityEventType.highContrastEnabled : AccessibilityEventType.highContrastDisabled
    );
  }

  /// Configure keyboard navigation
  Future<void> setKeyboardNavigationEnabled(bool enabled) async {
    _keyboardNavigationEnabled = enabled;

    await _config.setParameter('accessibility.keyboard_navigation_enabled', enabled, source: 'accessibility_service');
    await _config.notifyConfigurationChanged();

    _emitAccessibilityEvent(
      enabled ? AccessibilityEventType.keyboardNavigationEnabled : AccessibilityEventType.keyboardNavigationDisabled
    );
  }

  /// Generate accessibility improvements report
  Future<AccessibilityImprovementReport> generateImprovementReport(
    AccessibilityAuditResult auditResult
  ) async {
    final improvements = <AccessibilityImprovement>[];
    final priorityIssues = <AccessibilityIssue>[];

    // Analyze issues and generate improvements
    for (final issue in auditResult.globalIssues) {
      priorityIssues.add(issue);

      final improvement = _generateImprovementForIssue(issue);
      if (improvement != null) {
        improvements.add(improvement);
      }
    }

    // Sort improvements by impact
    improvements.sort((a, b) => b.impactScore.compareTo(a.impactScore));

    return AccessibilityImprovementReport(
      auditResult: auditResult,
      improvements: improvements,
      priorityIssues: priorityIssues,
      estimatedImplementationTime: _estimateImplementationTime(improvements),
      generatedAt: DateTime.now(),
    );
  }

  /// Create accessible theme data
  ThemeData createAccessibleTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      // High contrast colors if enabled
      primaryColor: _highContrastEnabled ? Colors.black : baseTheme.primaryColor,
      scaffoldBackgroundColor: _highContrastEnabled ? Colors.white : baseTheme.scaffoldBackgroundColor,

      // Larger text for better readability
      textTheme: baseTheme.textTheme.apply(
        fontSizeFactor: _fontScale,
        fontSizeDelta: _fontScale > 1.0 ? 2.0 : 0.0,
      ),

      // Focus highlight
      focusColor: _focusHighlightColor,

      // Button themes with minimum touch targets
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(_minimumTouchTarget, _minimumTouchTarget),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(_minimumTouchTarget, _minimumTouchTarget),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(_minimumTouchTarget, _minimumTouchTarget),
        ),
      ),
    );
  }

  // Private methods

  Future<void> _loadAccessibilityConfiguration() async {
    _screenReaderEnabled = _config.getParameter('accessibility.screen_reader_enabled', defaultValue: false);
    _highContrastEnabled = _config.getParameter('accessibility.high_contrast_enabled', defaultValue: false);
    _keyboardNavigationEnabled = _config.getParameter('accessibility.keyboard_navigation_enabled', defaultValue: true);
    _fontScale = _config.getParameter('accessibility.font_scale', defaultValue: 1.0);
    _focusHighlightColor = Color(_config.getParameter('accessibility.focus_highlight_color', defaultValue: 0xFF6B35FF));
    _minimumTouchTarget = _config.getParameter('accessibility.minimum_touch_target', defaultValue: 44.0);
    _screenReaderDelay = Duration(milliseconds: _config.getParameter('accessibility.screen_reader_delay', defaultValue: 1000));
  }

  void _initializeValidators() {
    // Color contrast validator
    _validators['color_contrast'] = AccessibilityValidator(
      name: 'Color Contrast',
      rule: ColorContrastRule(),
    );

    // Touch target size validator
    _validators['touch_target'] = AccessibilityValidator(
      name: 'Touch Target Size',
      rule: TouchTargetSizeRule(minimumSize: _minimumTouchTarget),
    );

    // Semantic labeling validator
    _validators['semantic_label'] = AccessibilityValidator(
      name: 'Semantic Labeling',
      rule: SemanticLabelingRule(),
    );

    // Keyboard navigation validator
    _validators['keyboard_navigation'] = AccessibilityValidator(
      name: 'Keyboard Navigation',
      rule: KeyboardNavigationRule(),
    );

    // Screen reader support validator
    _validators['screen_reader'] = AccessibilityValidator(
      name: 'Screen Reader Support',
      rule: ScreenReaderSupportRule(),
    );
  }

  void _setupAccessibilityMonitoring() {
    // Monitor configuration changes
    _config.addChangeListener((changedKeys) {
      if (changedKeys.any((key) => key.startsWith('accessibility.'))) {
        _handleAccessibilityConfigurationChange(changedKeys);
      }
    });
  }

  Future<void> _performInitialAccessibilityAudit() async {
    // Perform basic accessibility check
    final auditResult = await performAccessibilityAudit(includeAllScreens: false);
    if (auditResult.globalIssues.isNotEmpty) {
      _emitAccessibilityEvent(AccessibilityEventType.accessibilityIssuesDetected,
        details: '${auditResult.globalIssues.length} issues found');
    }
  }

  Future<List<String>> _getAvailableScreens() async {
    // In a real implementation, this would scan the app's routes/screens
    // For now, return a placeholder list
    return ['home', 'settings', 'profile'];
  }

  Future<AccessibilityValidationResult> _auditScreen(String screenName, {bool includeSemanticTree = true}) async {
    // Placeholder implementation - in real app, this would navigate to screen and audit
    // For now, return mock results
    return AccessibilityValidationResult(
      isAccessible: true,
      issues: [],
      warnings: [
        AccessibilityWarning(
          type: AccessibilityWarningType.lowContrast,
          message: 'Some text may have low contrast',
          suggestion: 'Increase contrast ratio to at least 4.5:1',
        ),
      ],
      score: 0.85,
    );
  }

  Future<ComplianceReport> _generateComplianceReport(
    List<AccessibilityIssue> issues,
    List<AccessibilityWarning> warnings,
  ) async {
    final report = ComplianceReport();

    // WCAG compliance check
    final wcagCompliant = issues.where((issue) => issue.severity == AccessibilitySeverity.error).isEmpty;
    report.addResult(
      ComplianceStandard.wcag21,
      ComplianceResult(
        isCompliant: wcagCompliant,
        violations: issues.map((i) => i.message).toList(),
        recommendations: warnings.map((w) => w.suggestion ?? w.message).toList(),
      ),
    );

    return report;
  }

  void _handleAccessibilityConfigurationChange(List<String> changedKeys) {
    for (final key in changedKeys) {
      switch (key) {
        case 'accessibility.screen_reader_enabled':
          _screenReaderEnabled = _config.getParameter(key, defaultValue: false);
          break;
        case 'accessibility.high_contrast_enabled':
          _highContrastEnabled = _config.getParameter(key, defaultValue: false);
          break;
        case 'accessibility.keyboard_navigation_enabled':
          _keyboardNavigationEnabled = _config.getParameter(key, defaultValue: true);
          break;
        case 'accessibility.font_scale':
          _fontScale = _config.getParameter(key, defaultValue: 1.0);
          break;
        case 'accessibility.focus_highlight_color':
          _focusHighlightColor = Color(_config.getParameter(key, defaultValue: 0xFF6B35FF));
          break;
        case 'accessibility.minimum_touch_target':
          _minimumTouchTarget = _config.getParameter(key, defaultValue: 44.0);
          break;
        case 'accessibility.screen_reader_delay':
          _screenReaderDelay = Duration(milliseconds: _config.getParameter(key, defaultValue: 1000));
          break;
      }
    }

    _emitAccessibilityEvent(AccessibilityEventType.configurationChanged,
      details: 'Keys: ${changedKeys.join(", ")}');
  }

  void _performScreenReaderAnnouncement(ScreenReaderAnnouncement announcement) {
    // In Flutter, this would use SemanticsService.announce
    // For now, just log the announcement
    _emitAccessibilityEvent(AccessibilityEventType.screenReaderAnnouncement,
      details: announcement.message);
  }

  double _calculateAccessibilityScore(List<AccessibilityIssue> issues, List<AccessibilityWarning> warnings) {
    final errorCount = issues.where((issue) => issue.severity == AccessibilitySeverity.error).length;
    final warningCount = warnings.length;

    // Base score starts at 1.0, reduced by issues
    double score = 1.0;

    // Each error reduces score by 0.2
    score -= errorCount * 0.2;

    // Each warning reduces score by 0.05
    score -= warningCount * 0.05;

    return score.clamp(0.0, 1.0);
  }

  double _calculateOverallAccessibilityScore(Iterable<AccessibilityValidationResult> results) {
    if (results.isEmpty) return 0.0;

    final totalScore = results.fold<double>(0.0, (sum, result) => sum + result.score);
    return totalScore / results.length;
  }

  AccessibilityImprovement? _generateImprovementForIssue(AccessibilityIssue issue) {
    // Generate improvement suggestions based on issue type
    switch (issue.type) {
      case AccessibilityIssueType.lowContrast:
        return AccessibilityImprovement(
          title: 'Improve Color Contrast',
          description: 'Increase contrast ratio between text and background colors',
          impactScore: 0.8,
          estimatedTime: const Duration(hours: 4),
          difficulty: ImprovementDifficulty.medium,
          codeExample: '''
Text(
  'Example text',
  style: TextStyle(
    color: Colors.black, // High contrast color
    backgroundColor: Colors.white,
  ),
)
''',
        );

      case AccessibilityIssueType.smallTouchTarget:
        return AccessibilityImprovement(
          title: 'Increase Touch Target Size',
          description: 'Ensure all interactive elements meet minimum touch target size',
          impactScore: 0.9,
          estimatedTime: const Duration(hours: 2),
          difficulty: ImprovementDifficulty.easy,
          codeExample: '''
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    minimumSize: Size(44, 44), // Minimum touch target
  ),
  child: Text('Button'),
)
''',
        );

      case AccessibilityIssueType.missingSemanticLabel:
        return AccessibilityImprovement(
          title: 'Add Semantic Labels',
          description: 'Provide semantic labels for screen readers',
          impactScore: 0.7,
          estimatedTime: const Duration(hours: 1),
          difficulty: ImprovementDifficulty.easy,
          codeExample: '''
Semantics(
  label: 'Save button',
  child: IconButton(
    icon: Icon(Icons.save),
    onPressed: () {},
  ),
)
''',
        );

      default:
        return null;
    }
  }

  Duration _estimateImplementationTime(List<AccessibilityImprovement> improvements) {
    final totalMinutes = improvements.fold<int>(0, (sum, improvement) =>
      sum + improvement.estimatedTime.inMinutes);
    return Duration(minutes: totalMinutes);
  }

  void _emitAccessibilityEvent(AccessibilityEventType type, {
    String? details,
    String? error,
  }) {
    final event = AccessibilityEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _accessibilityEventController.add(event);
  }

  void dispose() {
    _accessibilityEventController.close();
  }
}

/// Supporting data classes and enums

class AccessibilityValidator {
  final String name;
  final AccessibilityRule rule;

  AccessibilityValidator({
    required this.name,
    required this.rule,
  });
}

abstract class AccessibilityRule {
  Future<AccessibilityValidationResult> validate(BuildContext context, Widget widget, RenderObject renderObject);
}

class ColorContrastRule extends AccessibilityRule {
  @override
  Future<AccessibilityValidationResult> validate(BuildContext context, Widget widget, RenderObject renderObject) async {
    // Placeholder implementation - would analyze actual colors
    return AccessibilityValidationResult(
      isAccessible: true,
      issues: [],
      warnings: [
        AccessibilityWarning(
          type: AccessibilityWarningType.lowContrast,
          message: 'Potential low contrast detected',
          suggestion: 'Verify contrast ratio meets WCAG guidelines',
        ),
      ],
      score: 0.9,
    );
  }
}

class TouchTargetSizeRule extends AccessibilityRule {
  final double minimumSize;

  TouchTargetSizeRule({required this.minimumSize});

  @override
  Future<AccessibilityValidationResult> validate(BuildContext context, Widget widget, RenderObject renderObject) async {
    // Placeholder implementation - would check actual sizes
    return AccessibilityValidationResult(
      isAccessible: true,
      issues: [],
      warnings: [],
      score: 1.0,
    );
  }
}

class SemanticLabelingRule extends AccessibilityRule {
  @override
  Future<AccessibilityValidationResult> validate(BuildContext context, Widget widget, RenderObject renderObject) async {
    // Placeholder implementation - would check semantic labels
    return AccessibilityValidationResult(
      isAccessible: true,
      issues: [],
      warnings: [],
      score: 1.0,
    );
  }
}

class KeyboardNavigationRule extends AccessibilityRule {
  @override
  Future<AccessibilityValidationResult> validate(BuildContext context, Widget widget, RenderObject renderObject) async {
    // Placeholder implementation - would check keyboard navigation
    return AccessibilityValidationResult(
      isAccessible: true,
      issues: [],
      warnings: [],
      score: 1.0,
    );
  }
}

class ScreenReaderSupportRule extends AccessibilityRule {
  @override
  Future<AccessibilityValidationResult> validate(BuildContext context, Widget widget, RenderObject renderObject) async {
    // Placeholder implementation - would check screen reader support
    return AccessibilityValidationResult(
      isAccessible: true,
      issues: [],
      warnings: [],
      score: 1.0,
    );
  }
}

class AccessibilityValidationResult {
  final bool isAccessible;
  final List<AccessibilityIssue> issues;
  final List<AccessibilityWarning> warnings;
  final double score;

  AccessibilityValidationResult({
    required this.isAccessible,
    required this.issues,
    required this.warnings,
    required this.score,
  });
}

class AccessibilityAuditResult {
  final double overallScore;
  final Map<String, AccessibilityValidationResult> screenResults;
  final List<AccessibilityIssue> globalIssues;
  final List<AccessibilityWarning> globalWarnings;
  final ComplianceReport complianceReport;
  final DateTime auditTimestamp;

  AccessibilityAuditResult({
    required this.overallScore,
    required this.screenResults,
    required this.globalIssues,
    required this.globalWarnings,
    required this.complianceReport,
    required this.auditTimestamp,
  });
}

class AccessibilityIssue {
  final AccessibilityIssueType type;
  final AccessibilitySeverity severity;
  final String message;
  final Widget? element;
  final String? suggestion;

  AccessibilityIssue({
    required this.type,
    required this.severity,
    required this.message,
    this.element,
    this.suggestion,
  });
}

class AccessibilityWarning {
  final AccessibilityWarningType type;
  final String message;
  final String? suggestion;

  AccessibilityWarning({
    required this.type,
    required this.message,
    this.suggestion,
  });
}

class AccessibilityImprovement {
  final String title;
  final String description;
  final double impactScore;
  final Duration estimatedTime;
  final ImprovementDifficulty difficulty;
  final String? codeExample;

  AccessibilityImprovement({
    required this.title,
    required this.description,
    required this.impactScore,
    required this.estimatedTime,
    required this.difficulty,
    this.codeExample,
  });
}

class AccessibilityImprovementReport {
  final AccessibilityAuditResult auditResult;
  final List<AccessibilityImprovement> improvements;
  final List<AccessibilityIssue> priorityIssues;
  final Duration estimatedImplementationTime;
  final DateTime generatedAt;

  AccessibilityImprovementReport({
    required this.auditResult,
    required this.improvements,
    required this.priorityIssues,
    required this.estimatedImplementationTime,
    required this.generatedAt,
  });
}

class ScreenReaderAnnouncement {
  final String id;
  final String message;
  final AnnounceMode mode;
  final DateTime timestamp;

  ScreenReaderAnnouncement({
    required this.id,
    required this.message,
    required this.mode,
    required this.timestamp,
  });
}

enum AccessibilityIssueType {
  lowContrast,
  smallTouchTarget,
  missingSemanticLabel,
  missingFocusIndicator,
  keyboardNavigationIssue,
  screenReaderIssue,
  missingRenderObject,
  validationError,
}

enum AccessibilityWarningType {
  lowContrast,
  suboptimalTouchTarget,
  missingHint,
  complexNavigation,
}

enum AccessibilitySeverity {
  error,
  warning,
  info,
}

enum ImprovementDifficulty {
  easy,
  medium,
  hard,
}

enum AnnounceMode {
  polite,
  assertive,
}

/// Accessibility event types
enum AccessibilityEventType {
  serviceInitialized,
  initializationFailed,
  auditStarted,
  auditCompleted,
  auditFailed,
  screenReaderAnnouncement,
  focusChanged,
  fontScaleChanged,
  highContrastEnabled,
  highContrastDisabled,
  keyboardNavigationEnabled,
  keyboardNavigationDisabled,
  configurationChanged,
  accessibilityIssuesDetected,
}

/// Accessibility event
class AccessibilityEvent {
  final AccessibilityEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  AccessibilityEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}
