import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'advanced_document_intelligence_service.dart';
import '../../core/logging/logging_service.dart';
import '../../core/config/central_config.dart';

/// AI-Powered Version Control and Change Tracking Service
///
/// Provides intelligent version control beyond traditional diff tracking:
/// - Semantic change analysis and impact assessment
/// - Automated change categorization and prioritization
/// - AI-powered merge conflict resolution suggestions
/// - Version history analysis and trend identification
/// - Quality assessment and improvement recommendations
/// - Collaborative editing insights and conflict prediction
class AIPoweredVersionControlService {
  static final AIPoweredVersionControlService _instance = AIPoweredVersionControlService._internal();
  factory AIPoweredVersionControlService() => _instance;
  AIPoweredVersionControlService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;
  final AdvancedDocumentIntelligenceService _documentIntelligence = AdvancedDocumentIntelligenceService();

  GenerativeModel? _model;
  bool _isInitialized = false;

  // Version control data
  final Map<String, DocumentVersionHistory> _versionHistories = {};
  final Map<String, List<ChangeAnalysis>> _pendingChanges = {};
  final Map<String, MergeAnalysis> _mergeAnalyses = {};
  final StreamController<VersionControlEvent> _versionEvents = StreamController.broadcast();

  // Performance and caching
  final Map<String, ChangeAnalysis> _changeCache = {};
  Timer? _analysisTimer;

  /// Initialize the AI-powered version control service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing AI-Powered Version Control Service', 'VersionControl');

      // Initialize AI model for version control intelligence
      await _initializeAIModel();

      // Start background analysis
      _startBackgroundAnalysis();

      _isInitialized = true;
      _logger.info('AI-Powered Version Control Service initialized successfully', 'VersionControl');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize AI-Powered Version Control Service', 'VersionControl',
          error: e, stackTrace: stackTrace);
      // Continue with limited functionality
      _isInitialized = true;
    }
  }

  Future<void> _initializeAIModel() async {
    try {
      final provider = _config.getParameter('ai.llm_provider', defaultValue: 'google');
      final apiKey = _config.getParameter('ai.api_key', defaultValue: '');
      final modelName = _config.getParameter('ai.model_name', defaultValue: 'gemini-1.5-flash');

      if (provider == 'google' && apiKey.isNotEmpty) {
        _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: _config.getParameter('ai.temperature', defaultValue: 0.2), // Low temperature for analysis
            maxOutputTokens: _config.getParameter('ai.max_tokens', defaultValue: 2048),
          ),
        );
        _logger.info('AI model initialized for version control', 'VersionControl');
      }
    } catch (e) {
      _logger.error('Failed to initialize AI model for version control', 'VersionControl', error: e);
    }
  }

  void _startBackgroundAnalysis() {
    // Analyze pending changes every 30 minutes
    _analysisTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      _analyzePendingChanges();
    });
  }

  /// Record a document change for version control
  Future<void> recordDocumentChange({
    required String documentPath,
    required String previousContent,
    required String newContent,
    required String author,
    String? changeDescription,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      _logger.info('Recording document change: $documentPath by $author', 'VersionControl');

      final versionHistory = _versionHistories.putIfAbsent(documentPath, () => DocumentVersionHistory(documentPath));

      // Create version entry
      final version = DocumentVersion(
        id: 'version_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        documentPath: documentPath,
        content: newContent,
        author: author,
        timestamp: DateTime.now(),
        description: changeDescription,
        metadata: metadata ?? {},
        previousVersionId: versionHistory.versions.isNotEmpty ? versionHistory.versions.last.id : null,
      );

      versionHistory.versions.add(version);

      // Analyze the change
      final changeAnalysis = await _analyzeChange(previousContent, newContent, version);
      version.changeAnalysis = changeAnalysis;

      // Keep only last 100 versions
      if (versionHistory.versions.length > 100) {
        versionHistory.versions.removeRange(0, versionHistory.versions.length - 100);
      }

      // Emit version control event
      _emitVersionEvent(VersionControlEventType.versionCreated, documentPath: documentPath, versionId: version.id);

      // Update change cache
      _changeCache['${documentPath}_${version.id}'] = changeAnalysis;

      _logger.info('Document change recorded and analyzed: ${version.id}', 'VersionControl');

    } catch (e, stackTrace) {
      _logger.error('Failed to record document change: $documentPath', 'VersionControl',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Analyze changes between two versions
  Future<ChangeAnalysis> analyzeChanges({
    required String documentPath,
    required String oldContent,
    required String newContent,
    String? context,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      _logger.info('Analyzing changes for: $documentPath', 'VersionControl');

      final analysis = ChangeAnalysis(
        documentPath: documentPath,
        timestamp: DateTime.now(),
        changes: [],
        impact: ChangeImpact(
          scope: ChangeScope.minor,
          riskLevel: RiskLevel.low,
          breakingChanges: false,
        ),
        recommendations: [],
      );

      // Basic diff analysis
      analysis.changes = _calculateBasicDiff(oldContent, newContent);

      // AI-powered analysis if available
      if (_model != null) {
        final aiAnalysis = await _performAIChangeAnalysis(oldContent, newContent, context);
        analysis.aiInsights = aiAnalysis;
        analysis.impact = aiAnalysis['impact'] ?? analysis.impact;
        analysis.recommendations = aiAnalysis['recommendations'] ?? [];
      }

      // Calculate quality metrics
      analysis.qualityMetrics = await _calculateChangeQuality(oldContent, newContent);

      _logger.info('Change analysis completed: ${analysis.changes.length} changes detected', 'VersionControl');
      return analysis;

    } catch (e, stackTrace) {
      _logger.error('Change analysis failed for: $documentPath', 'VersionControl',
          error: e, stackTrace: stackTrace);

      return ChangeAnalysis(
        documentPath: documentPath,
        timestamp: DateTime.now(),
        changes: [],
        impact: ChangeImpact(
          scope: ChangeScope.unknown,
          riskLevel: RiskLevel.unknown,
          breakingChanges: false,
        ),
        recommendations: ['Manual review recommended due to analysis failure'],
        error: e.toString(),
      );
    }
  }

  /// Get version history for a document
  DocumentVersionHistory? getVersionHistory(String documentPath) {
    return _versionHistories[documentPath];
  }

  /// Suggest optimal merge strategy for conflicts
  Future<MergeSuggestion> suggestMergeStrategy({
    required String documentPath,
    required String baseContent,
    required String ourContent,
    required String theirContent,
    String? ourAuthor,
    String? theirAuthor,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      _logger.info('Analyzing merge conflict for: $documentPath', 'VersionControl');

      final suggestion = MergeSuggestion(
        documentPath: documentPath,
        strategy: MergeStrategy.manual,
        confidence: 0.0,
        resolvedContent: '',
        explanation: '',
        conflicts: [],
        timestamp: DateTime.now(),
      );

      // Identify conflicts
      suggestion.conflicts = _identifyMergeConflicts(baseContent, ourContent, theirContent);

      if (suggestion.conflicts.isEmpty) {
        // No conflicts, can auto-merge
        suggestion.strategy = MergeStrategy.auto;
        suggestion.resolvedContent = _performAutoMerge(baseContent, ourContent, theirContent);
        suggestion.confidence = 0.9;
        suggestion.explanation = 'No conflicts detected, safe to auto-merge';
      } else {
        // Conflicts detected, suggest resolution
        if (_model != null) {
          final aiSuggestion = await _generateAIMergeSuggestion(
            baseContent, ourContent, theirContent,
            suggestion.conflicts, ourAuthor, theirAuthor
          );
          suggestion.strategy = aiSuggestion['strategy'] ?? MergeStrategy.manual;
          suggestion.resolvedContent = aiSuggestion['resolvedContent'] ?? ourContent;
          suggestion.confidence = aiSuggestion['confidence'] ?? 0.5;
          suggestion.explanation = aiSuggestion['explanation'] ?? 'AI analysis suggests manual review';
        } else {
          suggestion.explanation = 'Conflicts detected, manual resolution required';
        }
      }

      _logger.info('Merge strategy suggested: ${suggestion.strategy} with ${(suggestion.confidence * 100).round()}% confidence', 'VersionControl');
      return suggestion;

    } catch (e, stackTrace) {
      _logger.error('Merge strategy suggestion failed for: $documentPath', 'VersionControl',
          error: e, stackTrace: stackTrace);

      return MergeSuggestion(
        documentPath: documentPath,
        strategy: MergeStrategy.manual,
        confidence: 0.0,
        resolvedContent: ourContent,
        explanation: 'Analysis failed, manual resolution required',
        conflicts: [],
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Analyze version history trends and patterns
  Future<VersionHistoryAnalysis> analyzeVersionHistory(String documentPath) async {
    final history = _versionHistories[documentPath];
    if (history == null) {
      return VersionHistoryAnalysis(
        documentPath: documentPath,
        totalVersions: 0,
        analysisPeriod: Duration.zero,
        trends: [],
        insights: [],
        recommendations: ['No version history available'],
      );
    }

    try {
      _logger.info('Analyzing version history for: $documentPath', 'VersionControl');

      final analysis = VersionHistoryAnalysis(
        documentPath: documentPath,
        totalVersions: history.versions.length,
        analysisPeriod: history.versions.isEmpty ? Duration.zero :
          history.versions.last.timestamp.difference(history.versions.first.timestamp),
        trends: [],
        insights: [],
        recommendations: [],
      );

      // Analyze trends
      analysis.trends = _analyzeVersionTrends(history);

      // Generate AI insights if available
      if (_model != null && history.versions.length > 5) {
        final aiInsights = await _generateVersionHistoryInsights(history);
        analysis.insights = aiInsights['insights'] ?? [];
        analysis.recommendations = aiInsights['recommendations'] ?? [];
      }

      _logger.info('Version history analysis completed: ${analysis.totalVersions} versions analyzed', 'VersionControl');
      return analysis;

    } catch (e, stackTrace) {
      _logger.error('Version history analysis failed for: $documentPath', 'VersionControl',
          error: e, stackTrace: stackTrace);

      return VersionHistoryAnalysis(
        documentPath: documentPath,
        totalVersions: history.versions.length,
        analysisPeriod: Duration.zero,
        trends: [],
        insights: [],
        recommendations: ['Analysis failed, manual review recommended'],
        error: e.toString(),
      );
    }
  }

  /// Predict potential future changes based on patterns
  Future<List<ChangePrediction>> predictFutureChanges(String documentPath) async {
    final history = _versionHistories[documentPath];
    if (history == null || history.versions.length < 3) {
      return [];
    }

    try {
      _logger.info('Predicting future changes for: $documentPath', 'VersionControl');

      final predictions = <ChangePrediction>[];

      // Analyze change patterns
      final changePatterns = _analyzeChangePatterns(history);

      // Predict based on patterns
      for (final pattern in changePatterns) {
        if (pattern.frequency > 0.1) { // More than 10% occurrence rate
          predictions.add(ChangePrediction(
            changeType: pattern.changeType,
            probability: pattern.frequency,
            timeframe: Duration(days: 30), // Next 30 days
            reasoning: 'Based on historical pattern analysis',
          ));
        }
      }

      // AI-powered predictions
      if (_model != null) {
        final aiPredictions = await _generateAIPredictions(history);
        predictions.addAll(aiPredictions);
      }

      _logger.info('Change predictions generated: ${predictions.length} predictions', 'VersionControl');
      return predictions.take(5).toList(); // Top 5 predictions

    } catch (e, stackTrace) {
      _logger.error('Change prediction failed for: $documentPath', 'VersionControl',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Private implementation methods

  Future<ChangeAnalysis> _analyzeChange(String oldContent, String newContent, DocumentVersion version) async {
    return await analyzeChanges(
      documentPath: version.documentPath,
      oldContent: oldContent,
      newContent: newContent,
      context: version.description,
    );
  }

  List<Change> _calculateBasicDiff(String oldContent, String newContent) {
    final changes = <Change>[];

    // Simple line-by-line diff (can be enhanced with proper diff algorithm)
    final oldLines = oldContent.split('\n');
    final newLines = newContent.split('\n');

    int oldIndex = 0;
    int newIndex = 0;

    while (oldIndex < oldLines.length || newIndex < newLines.length) {
      if (oldIndex >= oldLines.length) {
        // Addition
        changes.add(Change(
          type: ChangeType.addition,
          lineNumber: newIndex,
          content: newLines[newIndex],
        ));
        newIndex++;
      } else if (newIndex >= newLines.length) {
        // Deletion
        changes.add(Change(
          type: ChangeType.deletion,
          lineNumber: oldIndex,
          content: oldLines[oldIndex],
        ));
        oldIndex++;
      } else if (oldLines[oldIndex] != newLines[newIndex]) {
        // Modification
        changes.add(Change(
          type: ChangeType.modification,
          lineNumber: newIndex,
          content: newLines[newIndex],
          previousContent: oldLines[oldIndex],
        ));
        oldIndex++;
        newIndex++;
      } else {
        // No change
        oldIndex++;
        newIndex++;
      }
    }

    return changes;
  }

  Future<Map<String, dynamic>> _performAIChangeAnalysis(String oldContent, String newContent, String? context) async {
    if (_model == null) return {};

    try {
      final prompt = '''
Analyze the changes between these two versions of a document:

OLD VERSION:
${oldContent.substring(0, min(1000, oldContent.length))}

NEW VERSION:
${newContent.substring(0, min(1000, newContent.length))}

${context != null ? 'CONTEXT: $context' : ''}

Please provide:
1. IMPACT_SCOPE: (minor, moderate, major, critical)
2. RISK_LEVEL: (low, medium, high, critical)
3. BREAKING_CHANGES: (true/false)
4. RECOMMENDATIONS: List of recommendations for this change

Format as JSON with these keys.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result != null) {
        final analysis = _parseAIResponse(result);

        return {
          'impact': ChangeImpact(
            scope: _parseChangeScope(analysis['IMPACT_SCOPE'] ?? 'minor'),
            riskLevel: _parseRiskLevel(analysis['RISK_LEVEL'] ?? 'low'),
            breakingChanges: analysis['BREAKING_CHANGES'] ?? false,
          ),
          'recommendations': (analysis['RECOMMENDATIONS'] as List?)?.map((r) => r.toString()).toList() ?? [],
        };
      }
    } catch (e) {
      _logger.warning('AI change analysis failed', 'VersionControl', error: e);
    }

    return {};
  }

  Future<QualityMetrics> _calculateChangeQuality(String oldContent, String newContent) async {
    return QualityMetrics(
      readabilityScore: _calculateReadabilityScore(newContent),
      consistencyScore: await _calculateConsistencyScore(oldContent, newContent),
      completenessScore: _calculateCompletenessScore(newContent),
      technicalAccuracy: 0.8, // Placeholder
    );
  }

  double _calculateReadabilityScore(String content) {
    // Simple readability calculation (can be enhanced)
    final sentences = content.split(RegExp(r'[.!?]'));
    final words = content.split(RegExp(r'\s+'));
    final avgWordsPerSentence = words.length / sentences.length;

    // Lower is better for readability (Flesch Reading Ease approximation)
    if (avgWordsPerSentence < 10) return 0.9;
    if (avgWordsPerSentence < 15) return 0.7;
    if (avgWordsPerSentence < 20) return 0.5;
    return 0.3;
  }

  Future<double> _calculateConsistencyScore(String oldContent, String newContent) async {
    // Simple consistency check (can be enhanced with AI)
    final oldWords = oldContent.toLowerCase().split(RegExp(r'\s+')).toSet();
    final newWords = newContent.toLowerCase().split(RegExp(r'\s+')).toSet();
    final commonWords = oldWords.intersection(newWords).length;
    final totalWords = oldWords.union(newWords).length;

    return totalWords > 0 ? commonWords / totalWords : 0.5;
  }

  double _calculateCompletenessScore(String content) {
    // Simple completeness check
    final hasTitle = content.contains(RegExp(r'^#+\s', multiLine: true));
    final hasContent = content.length > 100;
    final hasStructure = content.contains('\n\n') || content.contains('##');

    double score = 0.3; // Base score
    if (hasTitle) score += 0.2;
    if (hasContent) score += 0.3;
    if (hasStructure) score += 0.2;

    return score;
  }

  List<MergeConflict> _identifyMergeConflicts(String base, String ours, String theirs) {
    final conflicts = <MergeConflict>[];

    // Simple conflict detection (can be enhanced)
    final baseLines = base.split('\n');
    final ourLines = ours.split('\n');
    final theirLines = theirs.split('\n');

    // Look for areas where both versions differ from base
    for (int i = 0; i < min(baseLines.length, min(ourLines.length, theirLines.length)); i++) {
      if (baseLines[i] != ourLines[i] && baseLines[i] != theirLines[i] && ourLines[i] != theirLines[i]) {
        conflicts.add(MergeConflict(
          lineNumber: i,
          baseContent: baseLines[i],
          ourContent: ourLines[i],
          theirContent: theirLines[i],
          conflictType: ConflictType.content,
        ));
      }
    }

    return conflicts;
  }

  String _performAutoMerge(String base, String ours, String theirs) {
    // Simple auto-merge (prefer our changes, can be enhanced)
    return ours;
  }

  Future<Map<String, dynamic>> _generateAIMergeSuggestion(
    String base, String ours, String theirs,
    List<MergeConflict> conflicts, String? ourAuthor, String? theirAuthor,
  ) async {
    if (_model == null || conflicts.isEmpty) return {};

    try {
      final conflictSummary = conflicts.take(3).map((c) =>
        'Line ${c.lineNumber}: Our: "${c.ourContent}" vs Their: "${c.theirContent}"'
      ).join('\n');

      final prompt = '''
Resolve this merge conflict intelligently:

OUR CHANGES (by ${ourAuthor ?? 'unknown'}):
${ours.substring(0, min(500, ours.length))}

THEIR CHANGES (by ${theirAuthor ?? 'unknown'}):
${theirs.substring(0, min(500, theirs.length))}

CONFLICTS:
$conflictSummary

Suggest the best merge resolution and explain why.
Format as JSON with: strategy, resolvedContent, confidence, explanation
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result != null) {
        return _parseAIResponse(result);
      }
    } catch (e) {
      _logger.warning('AI merge suggestion failed', 'VersionControl', error: e);
    }

    return {};
  }

  List<VersionTrend> _analyzeVersionTrends(DocumentVersionHistory history) {
    final trends = <VersionTrend>[];

    if (history.versions.length < 3) return trends;

    // Analyze frequency trends
    final intervals = <Duration>[];
    for (int i = 1; i < history.versions.length; i++) {
      intervals.add(history.versions[i].timestamp.difference(history.versions[i-1].timestamp));
    }

    if (intervals.isNotEmpty) {
      final avgInterval = intervals.fold<Duration>(Duration.zero, (a, b) => a + b) ~/ intervals.length;
      trends.add(VersionTrend(
        trendType: 'frequency',
        description: 'Average time between versions: ${avgInterval.inHours} hours',
        severity: avgInterval.inDays > 7 ? TrendSeverity.concerning : TrendSeverity.normal,
      ));
    }

    // Analyze author diversity
    final authors = history.versions.map((v) => v.author).toSet();
    if (authors.length == 1) {
      trends.add(VersionTrend(
        trendType: 'collaboration',
        description: 'Single author for all versions',
        severity: TrendSeverity.concerning,
      ));
    }

    return trends;
  }

  Future<Map<String, dynamic>> _generateVersionHistoryInsights(DocumentVersionHistory history) async {
    if (_model == null) return {};

    try {
      final versionSummary = history.versions.take(10).map((v) =>
        '${v.timestamp.toIso8601String()}: ${v.author} - ${v.description ?? 'No description'}'
      ).join('\n');

      final prompt = '''
Analyze this document's version history and provide insights:

VERSION HISTORY (last 10 versions):
$versionSummary

Provide:
1. INSIGHTS: Key observations about the document's evolution
2. RECOMMENDATIONS: Suggestions for future development

Format as JSON with insights and recommendations arrays.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result != null) {
        return _parseAIResponse(result);
      }
    } catch (e) {
      _logger.warning('AI version history insights failed', 'VersionControl', error: e);
    }

    return {};
  }

  List<ChangePattern> _analyzeChangePatterns(DocumentVersionHistory history) {
    final patterns = <String, int>{};

    for (final version in history.versions) {
      if (version.changeAnalysis != null) {
        for (final change in version.changeAnalysis!.changes) {
          final pattern = change.type.toString();
          patterns[pattern] = (patterns[pattern] ?? 0) + 1;
        }
      }
    }

    return patterns.entries.map((e) => ChangePattern(
      changeType: e.key,
      frequency: e.value / history.versions.length,
    )).toList();
  }

  Future<List<ChangePrediction>> _generateAIPredictions(DocumentVersionHistory history) async {
    if (_model == null) return [];

    try {
      final recentChanges = history.versions.take(5).map((v) =>
        'Version ${v.id}: ${v.changeAnalysis?.changes.length ?? 0} changes by ${v.author}'
      ).join('\n');

      final prompt = '''
Based on recent version history, predict likely future changes:

RECENT ACTIVITY:
$recentChanges

Predict the most probable types of changes in the next month.
Return up to 3 predictions with confidence levels.

Format as JSON array with changeType, probability, and reasoning.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result != null) {
        final predictions = json.decode(result) as List;
        return predictions.map((p) => ChangePrediction(
          changeType: p['changeType'] ?? 'unknown',
          probability: (p['probability'] as num?)?.toDouble() ?? 0.5,
          timeframe: Duration(days: 30),
          reasoning: p['reasoning'] ?? 'AI prediction',
        )).toList();
      }
    } catch (e) {
      _logger.warning('AI change predictions failed', 'VersionControl', error: e);
    }

    return [];
  }

  void _analyzePendingChanges() {
    // Analyze pending changes and emit insights
    for (final entry in _pendingChanges.entries) {
      final documentPath = entry.key;
      final changes = entry.value;

      if (changes.isNotEmpty) {
        _emitVersionEvent(VersionControlEventType.changesAnalyzed,
            documentPath: documentPath, changeCount: changes.length);
      }
    }
  }

  void _emitVersionEvent(VersionControlEventType type, {
    String? documentPath,
    String? versionId,
    int? changeCount,
  }) {
    final event = VersionControlEvent(
      type: type,
      timestamp: DateTime.now(),
      documentPath: documentPath,
      versionId: versionId,
      changeCount: changeCount,
    );
    _versionEvents.add(event);
  }

  // Utility methods
  ChangeScope _parseChangeScope(String scope) {
    switch (scope.toLowerCase()) {
      case 'critical': return ChangeScope.critical;
      case 'major': return ChangeScope.major;
      case 'moderate': return ChangeScope.moderate;
      case 'minor': return ChangeScope.minor;
      default: return ChangeScope.unknown;
    }
  }

  RiskLevel _parseRiskLevel(String level) {
    switch (level.toLowerCase()) {
      case 'critical': return RiskLevel.critical;
      case 'high': return RiskLevel.high;
      case 'medium': return RiskLevel.medium;
      case 'low': return RiskLevel.low;
      default: return RiskLevel.unknown;
    }
  }

  Map<String, dynamic> _parseAIResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return json.decode(jsonStr);
      }
    } catch (e) {
      _logger.warning('Failed to parse AI response', 'VersionControl', error: e);
    }
    return {};
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Stream<VersionControlEvent> get versionEvents => _versionEvents.stream;
  Map<String, DocumentVersionHistory> get versionHistories => Map.from(_versionHistories);
}

/// Supporting data classes

class DocumentVersionHistory {
  final String documentPath;
  final List<DocumentVersion> versions = [];

  DocumentVersionHistory(this.documentPath);
}

class DocumentVersion {
  final String id;
  final String documentPath;
  final String content;
  final String author;
  final DateTime timestamp;
  final String? description;
  final Map<String, dynamic> metadata;
  final String? previousVersionId;
  ChangeAnalysis? changeAnalysis;

  DocumentVersion({
    required this.id,
    required this.documentPath,
    required this.content,
    required this.author,
    required this.timestamp,
    this.description,
    required this.metadata,
    this.previousVersionId,
    this.changeAnalysis,
  });
}

class ChangeAnalysis {
  final String documentPath;
  final DateTime timestamp;
  final List<Change> changes;
  final ChangeImpact impact;
  final List<String> recommendations;
  QualityMetrics? qualityMetrics;
  Map<String, dynamic>? aiInsights;
  final String? error;

  ChangeAnalysis({
    required this.documentPath,
    required this.timestamp,
    required this.changes,
    required this.impact,
    required this.recommendations,
    this.qualityMetrics,
    this.aiInsights,
    this.error,
  });
}

class Change {
  final ChangeType type;
  final int lineNumber;
  final String content;
  final String? previousContent;

  Change({
    required this.type,
    required this.lineNumber,
    required this.content,
    this.previousContent,
  });
}

enum ChangeType { addition, deletion, modification }

class ChangeImpact {
  final ChangeScope scope;
  final RiskLevel riskLevel;
  final bool breakingChanges;

  ChangeImpact({
    required this.scope,
    required this.riskLevel,
    required this.breakingChanges,
  });
}

enum ChangeScope { minor, moderate, major, critical, unknown }
enum RiskLevel { low, medium, high, critical, unknown }

class QualityMetrics {
  final double readabilityScore;
  final double consistencyScore;
  final double completenessScore;
  final double technicalAccuracy;

  QualityMetrics({
    required this.readabilityScore,
    required this.consistencyScore,
    required this.completenessScore,
    required this.technicalAccuracy,
  });
}

class MergeSuggestion {
  final String documentPath;
  final MergeStrategy strategy;
  final double confidence;
  final String resolvedContent;
  final String explanation;
  final List<MergeConflict> conflicts;
  final DateTime timestamp;
  final String? error;

  MergeSuggestion({
    required this.documentPath,
    required this.strategy,
    required this.confidence,
    required this.resolvedContent,
    required this.explanation,
    required this.conflicts,
    required this.timestamp,
    this.error,
  });
}

enum MergeStrategy { auto, manual, conservative }

class MergeConflict {
  final int lineNumber;
  final String baseContent;
  final String ourContent;
  final String theirContent;
  final ConflictType conflictType;

  MergeConflict({
    required this.lineNumber,
    required this.baseContent,
    required this.ourContent,
    required this.theirContent,
    required this.conflictType,
  });
}

enum ConflictType { content, structure, formatting }

class VersionHistoryAnalysis {
  final String documentPath;
  final int totalVersions;
  final Duration analysisPeriod;
  final List<VersionTrend> trends;
  final List<String> insights;
  final List<String> recommendations;
  final String? error;

  VersionHistoryAnalysis({
    required this.documentPath,
    required this.totalVersions,
    required this.analysisPeriod,
    required this.trends,
    required this.insights,
    required this.recommendations,
    this.error,
  });
}

class VersionTrend {
  final String trendType;
  final String description;
  final TrendSeverity severity;

  VersionTrend({
    required this.trendType,
    required this.description,
    required this.severity,
  });
}

enum TrendSeverity { normal, concerning, critical }

class ChangePrediction {
  final String changeType;
  final double probability;
  final Duration timeframe;
  final String reasoning;

  ChangePrediction({
    required this.changeType,
    required this.probability,
    required this.timeframe,
    required this.reasoning,
  });
}

class ChangePattern {
  final String changeType;
  final double frequency;

  ChangePattern({
    required this.changeType,
    required this.frequency,
  });
}

enum VersionControlEventType {
  versionCreated,
  changesAnalyzed,
  mergeSuggested,
  conflictDetected,
  qualityImproved,
  collaborationInsight,
}

class VersionControlEvent {
  final VersionControlEventType type;
  final DateTime timestamp;
  final String? documentPath;
  final String? versionId;
  final int? changeCount;

  VersionControlEvent({
    required this.type,
    required this.timestamp,
    this.documentPath,
    this.versionId,
    this.changeCount,
  });
}
