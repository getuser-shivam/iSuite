import 'dart:async';
import '../../core/config/central_config.dart';
import 'package:flutter/material.dart';
import 'advanced_ui_service.dart';

/// User Onboarding Service
/// Provides interactive tutorials, feature walkthroughs, and user guidance
class UserOnboardingService {
  static final UserOnboardingService _instance = UserOnboardingService._internal();
  factory UserOnboardingService() => _instance;
  UserOnboardingService._internal();

  final AdvancedUIService _uiService = AdvancedUIService();
  final StreamController<OnboardingEvent> _onboardingEventController = StreamController.broadcast();

  Stream<OnboardingEvent> get onboardingEvents => _onboardingEventController.stream;

  // Tutorial and walkthrough data
  final Map<String, Tutorial> _tutorials = {};
  final Map<String, UserProgress> _userProgress = {};
  final Map<String, FeatureHighlight> _featureHighlights = {};
  final Map<String, ContextualHelp> _contextualHelp = {};

  // Onboarding flows
  final Map<String, OnboardingFlow> _onboardingFlows = {};
  final Map<String, TooltipSequence> _tooltipSequences = {};

  bool _isInitialized = false;

  // Configuration
  static const String _progressStorageKey = 'user_onboarding_progress';
  static const Duration _tutorialStepDelay = Duration(milliseconds: 500);
  static const Duration _highlightDuration = Duration(seconds: 3);

  /// Initialize user onboarding service
  Future<void> initialize({
    List<Tutorial>? tutorials,
    List<OnboardingFlow>? flows,
    Map<String, FeatureHighlight>? highlights,
  }) async {
    if (_isInitialized) return;

    try {
      // Load default tutorials
      await _loadDefaultTutorials();

      // Add custom tutorials
      if (tutorials != null) {
        for (final tutorial in tutorials) {
          _tutorials[tutorial.tutorialId] = tutorial;
        }
      }

      // Load default flows
      await _loadDefaultFlows();

      // Add custom flows
      if (flows != null) {
        for (final flow in flows) {
          _onboardingFlows[flow.flowId] = flow;
        }
      }

      // Add feature highlights
      if (highlights != null) {
        _featureHighlights.addAll(highlights);
      } else {
        await _loadDefaultHighlights();
      }

      // Load user progress
      await _loadUserProgress();

      _isInitialized = true;
      _emitOnboardingEvent(OnboardingEventType.serviceInitialized);

    } catch (e) {
      _emitOnboardingEvent(OnboardingEventType.initializationFailed, error: e.toString());
      rethrow;
    }
  }

  /// Start an interactive tutorial
  Future<TutorialResult> startTutorial({
    required String tutorialId,
    required BuildContext context,
    required String userId,
    bool forceRestart = false,
  }) async {
    final tutorial = _tutorials[tutorialId];
    if (tutorial == null) {
      throw OnboardingException('Tutorial not found: $tutorialId');
    }

    final progress = _getOrCreateUserProgress(userId, tutorialId);

    if (!forceRestart && progress.isCompleted) {
      return TutorialResult(
        tutorialId: tutorialId,
        completed: true,
        stepsCompleted: tutorial.steps.length,
        timeSpent: progress.totalTimeSpent,
      );
    }

    _emitOnboardingEvent(OnboardingEventType.tutorialStarted,
      details: 'Tutorial: $tutorialId, User: $userId');

    try {
      final result = await _runTutorial(tutorial, progress, context);

      // Update progress
      progress.isCompleted = result.completed;
      progress.lastCompletedStep = result.stepsCompleted;
      progress.totalTimeSpent += result.timeSpent;
      progress.lastAccessed = DateTime.now();

      await _saveUserProgress(userId, progress);

      _emitOnboardingEvent(OnboardingEventType.tutorialCompleted,
        details: 'Tutorial: $tutorialId, Completed: ${result.completed}');

      return result;

    } catch (e) {
      _emitOnboardingEvent(OnboardingEventType.tutorialFailed,
        details: 'Tutorial: $tutorialId', error: e.toString());
      rethrow;
    }
  }

  /// Start onboarding flow for new users
  Future<OnboardingFlowResult> startOnboardingFlow({
    required String flowId,
    required BuildContext context,
    required String userId,
  }) async {
    final flow = _onboardingFlows[flowId];
    if (flow == null) {
      throw OnboardingException('Onboarding flow not found: $flowId');
    }

    _emitOnboardingEvent(OnboardingEventType.flowStarted,
      details: 'Flow: $flowId, User: $userId');

    try {
      final result = await _runOnboardingFlow(flow, context, userId);

      _emitOnboardingEvent(OnboardingEventType.flowCompleted,
        details: 'Flow: $flowId, Completed: ${result.completed}');

      return result;

    } catch (e) {
      _emitOnboardingEvent(OnboardingEventType.flowFailed,
        details: 'Flow: $flowId', error: e.toString());
      rethrow;
    }
  }

  /// Show contextual help
  Future<void> showContextualHelp({
    required String helpId,
    required BuildContext context,
    Offset? position,
  }) async {
    final help = _contextualHelp[helpId];
    if (help == null) return;

    _emitOnboardingEvent(OnboardingEventType.helpShown,
      details: 'Help: $helpId');

    await _displayContextualHelp(help, context, position);
  }

  /// Highlight a feature
  Future<void> highlightFeature({
    required String featureId,
    required BuildContext context,
    String? message,
    Duration? duration,
  }) async {
    final highlight = _featureHighlights[featureId];
    if (highlight == null) return;

    _emitOnboardingEvent(OnboardingEventType.featureHighlighted,
      details: 'Feature: $featureId');

    await _showFeatureHighlight(highlight, context, message, duration);
  }

  /// Create tooltip sequence
  Future<TooltipSequenceResult> runTooltipSequence({
    required String sequenceId,
    required BuildContext context,
    required List<TooltipConfig> tooltips,
  }) async {
    final sequence = TooltipSequence(
      sequenceId: sequenceId,
      tooltips: tooltips,
      currentIndex: 0,
    );

    _tooltipSequences[sequenceId] = sequence;

    _emitOnboardingEvent(OnboardingEventType.tooltipSequenceStarted,
      details: 'Sequence: $sequenceId');

    try {
      final result = await _runTooltipSequence(sequence, context);

      _tooltipSequences.remove(sequenceId);

      _emitOnboardingEvent(OnboardingEventType.tooltipSequenceCompleted,
        details: 'Sequence: $sequenceId, Completed: ${result.completed}');

      return result;

    } catch (e) {
      _tooltipSequences.remove(sequenceId);
      _emitOnboardingEvent(OnboardingEventType.tooltipSequenceFailed,
        details: 'Sequence: $sequenceId', error: e.toString());
      rethrow;
    }
  }

  /// Get user onboarding progress
  OnboardingProgress getUserProgress(String userId) {
    final completedTutorials = _userProgress.entries
        .where((entry) => entry.key.startsWith('$userId:') && entry.value.isCompleted)
        .length;

    final totalTutorials = _tutorials.length;
    final completionRate = totalTutorials > 0 ? completedTutorials / totalTutorials : 0.0;

    final recentActivity = _userProgress.entries
        .where((entry) => entry.key.startsWith('$userId:'))
        .map((entry) => entry.value.lastAccessed)
        .where((date) => date != null)
        .toList()
      ..sort((a, b) => b!.compareTo(a!));

    return OnboardingProgress(
      userId: userId,
      completedTutorials: completedTutorials,
      totalTutorials: totalTutorials,
      completionRate: completionRate,
      recentActivity: recentActivity.isNotEmpty ? recentActivity.first : null,
      achievements: _calculateAchievements(userId),
    );
  }

  /// Create guided tour overlay
  OverlayEntry createGuidedTourOverlay({
    required BuildContext context,
    required List<TourStep> steps,
    VoidCallback? onComplete,
    VoidCallback? onSkip,
  }) {
    return OverlayEntry(
      builder: (context) => GuidedTourOverlay(
        steps: steps,
        onComplete: () {
          onComplete?.call();
          this.remove();
        },
        onSkip: () {
          onSkip?.call();
          this.remove();
        },
      ),
    );
  }

  /// Generate personalized recommendations
  Future<List<OnboardingRecommendation>> getPersonalizedRecommendations(String userId) async {
    final progress = getUserProgress(userId);
    final recommendations = <OnboardingRecommendation>[];

    // Recommend next tutorial
    final nextTutorial = _findNextRecommendedTutorial(userId);
    if (nextTutorial != null) {
      recommendations.add(OnboardingRecommendation(
        type: RecommendationType.tutorial,
        title: 'Try: ${nextTutorial.title}',
        description: nextTutorial.description,
        action: () => startTutorial(
          tutorialId: nextTutorial.tutorialId,
          context: null, // Would need context
          userId: userId,
        ),
        priority: RecommendationPriority.high,
      ));
    }

    // Recommend feature exploration
    final unusedFeatures = _findUnusedFeatures(userId);
    for (final feature in unusedFeatures.take(2)) {
      recommendations.add(OnboardingRecommendation(
        type: RecommendationType.feature,
        title: 'Explore: $feature',
        description: 'Discover how to use this powerful feature',
        action: () => highlightFeature(
          featureId: feature,
          context: null, // Would need context
        ),
        priority: RecommendationPriority.medium,
      ));
    }

    // Achievement notifications
    final newAchievements = _checkForNewAchievements(userId);
    for (final achievement in newAchievements) {
      recommendations.add(OnboardingRecommendation(
        type: RecommendationType.achievement,
        title: '🎉 Achievement Unlocked!',
        description: achievement.description,
        action: () {}, // Show achievement dialog
        priority: RecommendationPriority.high,
      ));
    }

    return recommendations;
  }

  /// Register custom tutorial
  void registerTutorial(Tutorial tutorial) {
    _tutorials[tutorial.tutorialId] = tutorial;
    _emitOnboardingEvent(OnboardingEventType.tutorialRegistered,
      details: 'Tutorial: ${tutorial.tutorialId}');
  }

  /// Register contextual help
  void registerContextualHelp(String helpId, ContextualHelp help) {
    _contextualHelp[helpId] = help;
    _emitOnboardingEvent(OnboardingEventType.helpRegistered,
      details: 'Help: $helpId');
  }

  /// Export onboarding data
  Future<String> exportOnboardingData({
    bool includeProgress = true,
    bool includeTutorials = false,
    bool includeFlows = false,
  }) async {
    final data = <String, dynamic>{};

    if (includeProgress) {
      data['userProgress'] = _userProgress.map((key, value) => MapEntry(key, value.toJson()));
    }

    if (includeTutorials) {
      data['tutorials'] = _tutorials.map((key, value) => MapEntry(key, value.toJson()));
    }

    if (includeFlows) {
      data['flows'] = _onboardingFlows.map((key, value) => MapEntry(key, value.toJson()));
    }

    return json.encode(data);
  }

  // Private methods

  Future<void> _loadDefaultTutorials() async {
    // File Management Tutorial
    _tutorials['file_management_basics'] = Tutorial(
      tutorialId: 'file_management_basics',
      title: 'File Management Basics',
      description: 'Learn the fundamentals of managing files in iSuite',
      steps: [
        TutorialStep(
          stepId: 'welcome',
          title: 'Welcome to iSuite!',
          content: 'iSuite is a powerful file manager with advanced features. Let\'s get you started.',
          targetElement: 'main_screen',
          position: TooltipPosition.bottom,
        ),
        TutorialStep(
          stepId: 'file_browser',
          title: 'File Browser',
          content: 'This is your file browser. Click on folders to navigate through your files.',
          targetElement: 'file_list',
          position: TooltipPosition.right,
        ),
        TutorialStep(
          stepId: 'file_operations',
          title: 'File Operations',
          content: 'Right-click on files to see available operations like copy, move, and delete.',
          targetElement: 'file_context_menu',
          position: TooltipPosition.top,
        ),
        TutorialStep(
          stepId: 'search_feature',
          title: 'Search & Filter',
          content: 'Use the search bar to quickly find files. Try searching for file types or content.',
          targetElement: 'search_bar',
          position: TooltipPosition.bottom,
        ),
      ],
      estimatedDuration: const Duration(minutes: 5),
      difficulty: TutorialDifficulty.beginner,
      prerequisites: [],
    );

    // Cloud Storage Tutorial
    _tutorials['cloud_storage_setup'] = Tutorial(
      tutorialId: 'cloud_storage_setup',
      title: 'Cloud Storage Integration',
      description: 'Connect and manage your cloud storage accounts',
      steps: [
        TutorialStep(
          stepId: 'cloud_overview',
          title: 'Cloud Storage Overview',
          content: 'iSuite supports multiple cloud providers. Let\'s connect your first account.',
          targetElement: 'cloud_section',
          position: TooltipPosition.left,
        ),
        TutorialStep(
          stepId: 'add_account',
          title: 'Add Cloud Account',
          content: 'Click here to add a new cloud storage account.',
          targetElement: 'add_cloud_button',
          position: TooltipPosition.bottom,
        ),
        TutorialStep(
          stepId: 'select_provider',
          title: 'Choose Provider',
          content: 'Select your preferred cloud storage provider from the available options.',
          targetElement: 'provider_selection',
          position: TooltipPosition.center,
        ),
        TutorialStep(
          stepId: 'authorize',
          title: 'Authorize Access',
          content: 'Follow the authorization process to grant iSuite access to your cloud storage.',
          targetElement: 'auth_dialog',
          position: TooltipPosition.center,
        ),
        TutorialStep(
          stepId: 'sync_files',
          title: 'Sync Your Files',
          content: 'Once connected, you can upload, download, and sync files with your cloud storage.',
          targetElement: 'cloud_file_list',
          position: TooltipPosition.right,
        ),
      ],
      estimatedDuration: const Duration(minutes: 8),
      difficulty: TutorialDifficulty.intermediate,
      prerequisites: ['file_management_basics'],
    );

    // Advanced Features Tutorial
    _tutorials['advanced_features'] = Tutorial(
      tutorialId: 'advanced_features',
      title: 'Advanced Features',
      description: 'Discover powerful features like AI analysis and batch operations',
      steps: [
        TutorialStep(
          stepId: 'ai_analysis_intro',
          title: 'AI-Powered Analysis',
          content: 'iSuite uses AI to analyze your files and provide intelligent insights.',
          targetElement: 'ai_analysis_tab',
          position: TooltipPosition.top,
        ),
        TutorialStep(
          stepId: 'batch_operations',
          title: 'Batch Operations',
          content: 'Perform operations on multiple files at once for efficiency.',
          targetElement: 'batch_operations_menu',
          position: TooltipPosition.left,
        ),
        TutorialStep(
          stepId: 'file_sync',
          title: 'File Synchronization',
          content: 'Keep your files synchronized across devices and cloud storage.',
          targetElement: 'sync_settings',
          position: TooltipPosition.right,
        ),
        TutorialStep(
          stepId: 'performance_monitoring',
          title: 'Performance Monitoring',
          content: 'Monitor app performance and optimize your experience.',
          targetElement: 'performance_dashboard',
          position: TooltipPosition.bottom,
        ),
      ],
      estimatedDuration: const Duration(minutes: 10),
      difficulty: TutorialDifficulty.advanced,
      prerequisites: ['cloud_storage_setup'],
    );
  }

  Future<void> _loadDefaultFlows() async {
    _onboardingFlows['new_user_flow'] = OnboardingFlow(
      flowId: 'new_user_flow',
      title: 'Welcome to iSuite',
      description: 'Complete setup and learn the basics',
      steps: [
        FlowStep(
          stepId: 'welcome_screen',
          title: 'Welcome!',
          content: 'Welcome to iSuite! Let\'s get you set up.',
          type: StepType.information,
        ),
        FlowStep(
          stepId: 'permissions_setup',
          title: 'Permissions',
          content: 'We need some permissions to manage your files effectively.',
          type: StepType.action,
        ),
        FlowStep(
          stepId: 'file_management_tutorial',
          title: 'File Management',
          content: 'Learn how to navigate and manage your files.',
          type: StepType.tutorial,
          tutorialId: 'file_management_basics',
        ),
        FlowStep(
          stepId: 'cloud_setup',
          title: 'Cloud Storage',
          content: 'Connect your cloud storage for seamless file access.',
          type: StepType.optional,
        ),
      ],
      targetAudience: ['new_users'],
      estimatedDuration: const Duration(minutes: 15),
    );

    _onboardingFlows['power_user_flow'] = OnboardingFlow(
      flowId: 'power_user_flow',
      title: 'Power User Setup',
      description: 'Advanced features for experienced users',
      steps: [
        FlowStep(
          stepId: 'advanced_features_intro',
          title: 'Advanced Features',
          content: 'Discover the powerful features designed for advanced users.',
          type: StepType.information,
        ),
        FlowStep(
          stepId: 'ai_analysis_tutorial',
          title: 'AI Analysis',
          content: 'Learn to use AI-powered file analysis and organization.',
          type: StepType.tutorial,
          tutorialId: 'advanced_features',
        ),
        FlowStep(
          stepId: 'automation_setup',
          title: 'Automation',
          content: 'Set up automated workflows and file processing.',
          type: StepType.configuration,
        ),
        FlowStep(
          stepId: 'performance_optimization',
          title: 'Performance Tuning',
          content: 'Optimize iSuite for your specific use case.',
          type: StepType.configuration,
        ),
      ],
      targetAudience: ['power_users', 'it_professionals'],
      estimatedDuration: const Duration(minutes: 20),
    );
  }

  Future<void> _loadDefaultHighlights() async {
    _featureHighlights['search_feature'] = FeatureHighlight(
      featureId: 'search_feature',
      title: 'Powerful Search',
      description: 'Search through your files with advanced filters and AI-powered suggestions.',
      targetElement: 'search_bar',
      highlightColor: Colors.blue.withOpacity(0.3),
    );

    _featureHighlights['batch_operations'] = FeatureHighlight(
      featureId: 'batch_operations',
      title: 'Batch Operations',
      description: 'Perform operations on multiple files simultaneously for maximum efficiency.',
      targetElement: 'batch_menu',
      highlightColor: Colors.green.withOpacity(0.3),
    );

    _featureHighlights['cloud_sync'] = FeatureHighlight(
      featureId: 'cloud_sync',
      title: 'Cloud Synchronization',
      description: 'Keep your files synchronized across all your devices and cloud storage.',
      targetElement: 'sync_status',
      highlightColor: Colors.purple.withOpacity(0.3),
    );

    _featureHighlights['ai_insights'] = FeatureHighlight(
      featureId: 'ai_insights',
      title: 'AI Insights',
      description: 'Get intelligent insights about your files and usage patterns.',
      targetElement: 'ai_dashboard',
      highlightColor: Colors.orange.withOpacity(0.3),
    );
  }

  Future<void> _loadUserProgress() async {
    // Load user progress from storage
    // Implementation would load from persistent storage
  }

  UserProgress _getOrCreateUserProgress(String userId, String tutorialId) {
    final key = '$userId:$tutorialId';
    return _userProgress[key] ?? UserProgress(
      userId: userId,
      tutorialId: tutorialId,
      currentStep: 0,
      lastCompletedStep: 0,
      isCompleted: false,
      totalTimeSpent: Duration.zero,
      lastAccessed: DateTime.now(),
    );
  }

  Future<TutorialResult> _runTutorial(
    Tutorial tutorial,
    UserProgress progress,
    BuildContext context,
  ) async {
    final startTime = DateTime.now();
    int completedSteps = progress.lastCompletedStep;

    for (int i = progress.lastCompletedStep; i < tutorial.steps.length; i++) {
      final step = tutorial.steps[i];

      // Show tutorial step overlay
      final completer = Completer<void>();
      if (context != null) {
        _showTutorialStepOverlay(step, context, () {
          completer.complete();
        });
      } else {
        // Simulate step completion
        await Future.delayed(_tutorialStepDelay);
        completer.complete();
      }

      await completer.future;
      completedSteps = i + 1;
    }

    final timeSpent = DateTime.now().difference(startTime);
    final completed = completedSteps >= tutorial.steps.length;

    return TutorialResult(
      tutorialId: tutorial.tutorialId,
      completed: completed,
      stepsCompleted: completedSteps,
      timeSpent: timeSpent,
    );
  }

  Future<OnboardingFlowResult> _runOnboardingFlow(
    OnboardingFlow flow,
    BuildContext context,
    String userId,
  ) async {
    final startTime = DateTime.now();
    int completedSteps = 0;

    for (final step in flow.steps) {
      final completer = Completer<void>();

      switch (step.type) {
        case StepType.information:
          _showInformationStep(step, context, () => completer.complete());
          break;
        case StepType.action:
          _showActionStep(step, context, () => completer.complete());
          break;
        case StepType.tutorial:
          if (step.tutorialId != null) {
            await startTutorial(
              tutorialId: step.tutorialId!,
              context: context,
              userId: userId,
            );
          }
          completer.complete();
          break;
        case StepType.configuration:
          _showConfigurationStep(step, context, () => completer.complete());
          break;
      }

      await completer.future;
      completedSteps++;
    }

    final timeSpent = DateTime.now().difference(startTime);
    final completed = completedSteps >= flow.steps.length;

    return OnboardingFlowResult(
      flowId: flow.flowId,
      completed: completed,
      stepsCompleted: completedSteps,
      timeSpent: timeSpent,
    );
  }

  void _showTutorialStepOverlay(TutorialStep step, BuildContext context, VoidCallback onNext) {
    // Implementation would show overlay with step content
    // For now, just call onNext after delay
    Future.delayed(const Duration(seconds: 2), onNext);
  }

  void _showInformationStep(FlowStep step, BuildContext context, VoidCallback onNext) {
    // Implementation would show information dialog
    Future.delayed(const Duration(seconds: 1), onNext);
  }

  void _showActionStep(FlowStep step, BuildContext context, VoidCallback onNext) {
    // Implementation would show action prompt
    Future.delayed(const Duration(seconds: 1), onNext);
  }

  void _showConfigurationStep(FlowStep step, BuildContext context, VoidCallback onNext) {
    // Implementation would show configuration dialog
    Future.delayed(const Duration(seconds: 1), onNext);
  }

  Future<void> _displayContextualHelp(
    ContextualHelp help,
    BuildContext context,
    Offset? position,
  ) async {
    // Implementation would show contextual help overlay
  }

  Future<void> _showFeatureHighlight(
    FeatureHighlight highlight,
    BuildContext context,
    String? message,
    Duration? duration,
  ) async {
    // Implementation would show feature highlight overlay
    await Future.delayed(duration ?? _highlightDuration);
  }

  Future<TooltipSequenceResult> _runTooltipSequence(
    TooltipSequence sequence,
    BuildContext context,
  ) async {
    int completedTooltips = 0;

    for (final tooltip in sequence.tooltips) {
      final completer = Completer<void>();
      _showTooltip(tooltip, context, () {
        completer.complete();
        completedTooltips++;
      });

      await completer.future;
    }

    return TooltipSequenceResult(
      sequenceId: sequence.sequenceId,
      completed: completedTooltips >= sequence.tooltips.length,
      tooltipsShown: completedTooltips,
    );
  }

  void _showTooltip(TooltipConfig config, BuildContext context, VoidCallback onNext) {
    // Implementation would show tooltip
    Future.delayed(const Duration(seconds: 1), onNext);
  }

  Future<void> _saveUserProgress(String userId, UserProgress progress) async {
    final key = '$userId:${progress.tutorialId}';
    _userProgress[key] = progress;
    // Implementation would save to persistent storage
  }

  Tutorial? _findNextRecommendedTutorial(String userId) {
    final progress = getUserProgress(userId);

    // Find first incomplete tutorial
    for (final tutorial in _tutorials.values) {
      final tutorialProgress = _getOrCreateUserProgress(userId, tutorial.tutorialId);
      if (!tutorialProgress.isCompleted) {
        return tutorial;
      }
    }

    return null;
  }

  List<String> _findUnusedFeatures(String userId) {
    // Implementation would analyze user behavior to find unused features
    return ['batch_operations', 'cloud_sync', 'ai_analysis'];
  }

  List<Achievement> _calculateAchievements(String userId) {
    final progress = getUserProgress(userId);
    final achievements = <Achievement>[];

    if (progress.completionRate >= 0.5) {
      achievements.add(Achievement(
        achievementId: 'tutorial_master',
        title: 'Tutorial Master',
        description: 'Completed 50% of available tutorials',
        icon: '🎓',
        unlockedAt: DateTime.now(),
      ));
    }

    if (progress.completionRate >= 1.0) {
      achievements.add(Achievement(
        achievementId: 'onboarding_champion',
        title: 'Onboarding Champion',
        description: 'Completed all available tutorials',
        icon: '🏆',
        unlockedAt: DateTime.now(),
      ));
    }

    return achievements;
  }

  List<Achievement> _checkForNewAchievements(String userId) {
    // Implementation would check for newly unlocked achievements
    return [];
  }

  void _emitOnboardingEvent(OnboardingEventType type, {
    String? details,
    String? error,
  }) {
    final event = OnboardingEvent(
      type: type,
      timestamp: DateTime.now(),
      details: details,
      error: error,
    );

    _onboardingEventController.add(event);
  }

  void dispose() {
    _onboardingEventController.close();
  }
}

/// Supporting data classes and enums

enum OnboardingEventType {
  serviceInitialized,
  initializationFailed,
  tutorialRegistered,
  tutorialStarted,
  tutorialCompleted,
  tutorialFailed,
  flowStarted,
  flowCompleted,
  flowFailed,
  helpRegistered,
  helpShown,
  featureHighlighted,
  tooltipSequenceStarted,
  tooltipSequenceCompleted,
  tooltipSequenceFailed,
}

enum TutorialDifficulty {
  beginner,
  intermediate,
  advanced,
}

enum StepType {
  information,
  action,
  tutorial,
  configuration,
}

enum TooltipPosition {
  top,
  bottom,
  left,
  right,
  center,
}

enum RecommendationType {
  tutorial,
  feature,
  achievement,
}

enum RecommendationPriority {
  low,
  medium,
  high,
}

/// Data classes

class Tutorial {
  final String tutorialId;
  final String title;
  final String description;
  final List<TutorialStep> steps;
  final Duration estimatedDuration;
  final TutorialDifficulty difficulty;
  final List<String> prerequisites;

  Tutorial({
    required this.tutorialId,
    required this.title,
    required this.description,
    required this.steps,
    required this.estimatedDuration,
    required this.difficulty,
    required this.prerequisites,
  });

  Map<String, dynamic> toJson() => {
    'tutorialId': tutorialId,
    'title': title,
    'description': description,
    'steps': steps.map((s) => s.toJson()).toList(),
    'estimatedDuration': estimatedDuration.inMilliseconds,
    'difficulty': difficulty.toString(),
    'prerequisites': prerequisites,
  };

  factory Tutorial.fromJson(Map<String, dynamic> json) {
    return Tutorial(
      tutorialId: json['tutorialId'],
      title: json['title'],
      description: json['description'],
      steps: (json['steps'] as List).map((s) => TutorialStep.fromJson(s)).toList(),
      estimatedDuration: Duration(milliseconds: json['estimatedDuration']),
      difficulty: TutorialDifficulty.values.firstWhere((d) => d.toString() == json['difficulty']),
      prerequisites: List<String>.from(json['prerequisites']),
    );
  }
}

class TutorialStep {
  final String stepId;
  final String title;
  final String content;
  final String? targetElement;
  final TooltipPosition position;

  TutorialStep({
    required this.stepId,
    required this.title,
    required this.content,
    this.targetElement,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
    'stepId': stepId,
    'title': title,
    'content': content,
    'targetElement': targetElement,
    'position': position.toString(),
  };

  factory TutorialStep.fromJson(Map<String, dynamic> json) {
    return TutorialStep(
      stepId: json['stepId'],
      title: json['title'],
      content: json['content'],
      targetElement: json['targetElement'],
      position: TooltipPosition.values.firstWhere((p) => p.toString() == json['position']),
    );
  }
}

class TutorialResult {
  final String tutorialId;
  final bool completed;
  final int stepsCompleted;
  final Duration timeSpent;

  TutorialResult({
    required this.tutorialId,
    required this.completed,
    required this.stepsCompleted,
    required this.timeSpent,
  });
}

class OnboardingFlow {
  final String flowId;
  final String title;
  final String description;
  final List<FlowStep> steps;
  final List<String> targetAudience;
  final Duration estimatedDuration;

  OnboardingFlow({
    required this.flowId,
    required this.title,
    required this.description,
    required this.steps,
    required this.targetAudience,
    required this.estimatedDuration,
  });

  Map<String, dynamic> toJson() => {
    'flowId': flowId,
    'title': title,
    'description': description,
    'steps': steps.map((s) => s.toJson()).toList(),
    'targetAudience': targetAudience,
    'estimatedDuration': estimatedDuration.inMilliseconds,
  };

  factory OnboardingFlow.fromJson(Map<String, dynamic> json) {
    return OnboardingFlow(
      flowId: json['flowId'],
      title: json['title'],
      description: json['description'],
      steps: (json['steps'] as List).map((s) => FlowStep.fromJson(s)).toList(),
      targetAudience: List<String>.from(json['targetAudience']),
      estimatedDuration: Duration(milliseconds: json['estimatedDuration']),
    );
  }
}

class FlowStep {
  final String stepId;
  final String title;
  final String content;
  final StepType type;
  final String? tutorialId;

  FlowStep({
    required this.stepId,
    required this.title,
    required this.content,
    required this.type,
    this.tutorialId,
  });

  Map<String, dynamic> toJson() => {
    'stepId': stepId,
    'title': title,
    'content': content,
    'type': type.toString(),
    'tutorialId': tutorialId,
  };

  factory FlowStep.fromJson(Map<String, dynamic> json) {
    return FlowStep(
      stepId: json['stepId'],
      title: json['title'],
      content: json['content'],
      type: StepType.values.firstWhere((t) => t.toString() == json['type']),
      tutorialId: json['tutorialId'],
    );
  }
}

class OnboardingFlowResult {
  final String flowId;
  final bool completed;
  final int stepsCompleted;
  final Duration timeSpent;

  OnboardingFlowResult({
    required this.flowId,
    required this.completed,
    required this.stepsCompleted,
    required this.timeSpent,
  });
}

class UserProgress {
  final String userId;
  final String tutorialId;
  int currentStep;
  int lastCompletedStep;
  bool isCompleted;
  Duration totalTimeSpent;
  DateTime? lastAccessed;

  UserProgress({
    required this.userId,
    required this.tutorialId,
    required this.currentStep,
    required this.lastCompletedStep,
    required this.isCompleted,
    required this.totalTimeSpent,
    this.lastAccessed,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'tutorialId': tutorialId,
    'currentStep': currentStep,
    'lastCompletedStep': lastCompletedStep,
    'isCompleted': isCompleted,
    'totalTimeSpent': totalTimeSpent.inMilliseconds,
    'lastAccessed': lastAccessed?.toIso8601String(),
  };

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'],
      tutorialId: json['tutorialId'],
      currentStep: json['currentStep'],
      lastCompletedStep: json['lastCompletedStep'],
      isCompleted: json['isCompleted'],
      totalTimeSpent: Duration(milliseconds: json['totalTimeSpent']),
      lastAccessed: json['lastAccessed'] != null ? DateTime.parse(json['lastAccessed']) : null,
    );
  }
}

class FeatureHighlight {
  final String featureId;
  final String title;
  final String description;
  final String targetElement;
  final Color highlightColor;

  FeatureHighlight({
    required this.featureId,
    required this.title,
    required this.description,
    required this.targetElement,
    required this.highlightColor,
  });
}

class ContextualHelp {
  final String helpId;
  final String title;
  final String content;
  final String? relatedTutorialId;
  final Map<String, dynamic>? metadata;

  ContextualHelp({
    required this.helpId,
    required this.title,
    required this.content,
    this.relatedTutorialId,
    this.metadata,
  });
}

class TooltipConfig {
  final String tooltipId;
  final String message;
  final String targetElement;
  final TooltipPosition position;
  final Duration? displayDuration;

  TooltipConfig({
    required this.tooltipId,
    required this.message,
    required this.targetElement,
    required this.position,
    this.displayDuration,
  });
}

class TooltipSequence {
  final String sequenceId;
  final List<TooltipConfig> tooltips;
  int currentIndex;

  TooltipSequence({
    required this.sequenceId,
    required this.tooltips,
    required this.currentIndex,
  });
}

class TooltipSequenceResult {
  final String sequenceId;
  final bool completed;
  final int tooltipsShown;

  TooltipSequenceResult({
    required this.sequenceId,
    required this.completed,
    required this.tooltipsShown,
  });
}

class TourStep {
  final String stepId;
  final String title;
  final String description;
  final String targetElement;
  final TooltipPosition position;
  final Widget? customWidget;

  TourStep({
    required this.stepId,
    required this.title,
    required this.description,
    required this.targetElement,
    required this.position,
    this.customWidget,
  });
}

class OnboardingProgress {
  final String userId;
  final int completedTutorials;
  final int totalTutorials;
  final double completionRate;
  final DateTime? recentActivity;
  final List<Achievement> achievements;

  OnboardingProgress({
    required this.userId,
    required this.completedTutorials,
    required this.totalTutorials,
    required this.completionRate,
    this.recentActivity,
    required this.achievements,
  });
}

class Achievement {
  final String achievementId;
  final String title;
  final String description;
  final String icon;
  final DateTime unlockedAt;

  Achievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });
}

class OnboardingRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final VoidCallback action;
  final RecommendationPriority priority;

  OnboardingRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
  });
}

/// Widget classes

class GuidedTourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const GuidedTourOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<GuidedTourOverlay> {
  int currentStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.steps[currentStepIndex];

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Highlight target element
          Positioned.fill(
            child: CustomPaint(
              painter: HighlightPainter(
                targetElement: currentStep.targetElement,
                highlightColor: Colors.blue.withOpacity(0.3),
              ),
            ),
          ),

          // Tour content
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 100,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentStep.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(currentStep.description),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: widget.onSkip,
                          child: const Text('Skip Tour'),
                        ),
                        Row(
                          children: [
                            if (currentStepIndex > 0)
                              TextButton(
                                onPressed: () {
                                  setState(() => currentStepIndex--);
                                },
                                child: const Text('Previous'),
                              ),
                            ElevatedButton(
                              onPressed: () {
                                if (currentStepIndex < widget.steps.length - 1) {
                                  setState(() => currentStepIndex++);
                                } else {
                                  widget.onComplete();
                                }
                              },
                              child: Text(
                                currentStepIndex < widget.steps.length - 1 ? 'Next' : 'Complete',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HighlightPainter extends CustomPainter {
  final String targetElement;
  final Color highlightColor;

  HighlightPainter({
    required this.targetElement,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Implementation would highlight the target element
    // This is a simplified version
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Event classes

class OnboardingEvent {
  final OnboardingEventType type;
  final DateTime timestamp;
  final String? details;
  final String? error;

  OnboardingEvent({
    required this.type,
    required this.timestamp,
    this.details,
    this.error,
  });
}

/// Exception class

class OnboardingException implements Exception {
  final String message;

  OnboardingException(this.message);

  @override
  String toString() => 'OnboardingException: $message';
}
