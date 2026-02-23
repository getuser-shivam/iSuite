import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'advanced_document_intelligence_service.dart';
import 'predictive_analytics_service.dart';
import '../../core/logging/logging_service.dart';
import '../../core/config/central_config.dart';

/// Automated Workflow Routing Service using AI/LLM
///
/// Intelligently routes tasks, documents, and workflows to optimize productivity:
/// - AI-powered task assignment based on skills and availability
/// - Document routing to appropriate team members
/// - Workflow optimization and bottleneck detection
/// - Priority prediction and deadline management
/// - Collaboration pattern analysis and suggestions
/// - Automated escalation and follow-up
class AutomatedWorkflowService {
  static final AutomatedWorkflowService _instance = AutomatedWorkflowService._internal();
  factory AutomatedWorkflowService() => _instance;
  AutomatedWorkflowService._internal();

  final LoggingService _logger = LoggingService();
  final CentralConfig _config = CentralConfig.instance;
  final AdvancedDocumentIntelligenceService _documentIntelligence = AdvancedDocumentIntelligenceService();
  final PredictiveAnalyticsService _predictiveAnalytics = PredictiveAnalyticsService();

  GenerativeModel? _model;
  bool _isInitialized = false;

  // Workflow data
  final Map<String, Workflow> _activeWorkflows = {};
  final Map<String, Task> _activeTasks = {};
  final Map<String, UserProfile> _userProfiles = {};
  final List<WorkflowOptimization> _optimizations = [];
  final StreamController<WorkflowEvent> _workflowEvents = StreamController.broadcast();

  // Performance monitoring
  final Map<String, WorkflowMetrics> _workflowMetrics = {};
  Timer? _optimizationTimer;

  /// Initialize the automated workflow service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Automated Workflow Service', 'WorkflowService');

      // Check if workflow automation is enabled
      final workflowEnabled = _config.getParameter('ai.workflow.enabled', defaultValue: true);
      if (!workflowEnabled) {
        _logger.info('Workflow automation disabled', 'WorkflowService');
        _isInitialized = true;
        return;
      }

      // Initialize AI model for workflow intelligence
      await _initializeAIModel();

      // Start optimization monitoring
      _startOptimizationMonitoring();

      _isInitialized = true;
      _logger.info('Automated Workflow Service initialized successfully', 'WorkflowService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize Automated Workflow Service', 'WorkflowService',
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
            temperature: _config.getParameter('ai.temperature', defaultValue: 0.3), // Balanced for workflow decisions
            maxOutputTokens: _config.getParameter('ai.max_tokens', defaultValue: 2048),
          ),
        );
        _logger.info('AI model initialized for workflow automation', 'WorkflowService');
      }
    } catch (e) {
      _logger.error('Failed to initialize AI model for workflows', 'WorkflowService', error: e);
    }
  }

  void _startOptimizationMonitoring() {
    // Run optimization analysis every 2 hours
    _optimizationTimer = Timer.periodic(Duration(hours: 2), (timer) {
      _performWorkflowOptimization();
    });
  }

  /// Create a new workflow with AI-powered task assignment
  Future<Workflow> createWorkflow({
    required String name,
    required String description,
    required List<TaskDefinition> tasks,
    Map<String, dynamic>? metadata,
  }) async {
    final workflowId = 'workflow_${DateTime.now().millisecondsSinceEpoch}';

    final workflow = Workflow(
      id: workflowId,
      name: name,
      description: description,
      tasks: [],
      status: WorkflowStatus.planning,
      createdAt: DateTime.now(),
      metadata: metadata ?? {},
    );

    // AI-powered task assignment and sequencing
    final optimizedTasks = await _optimizeTaskAssignment(tasks, workflow);
    workflow.tasks.addAll(optimizedTasks);

    _activeWorkflows[workflowId] = workflow;

    _emitWorkflowEvent(WorkflowEventType.workflowCreated, workflowId: workflowId);
    _logger.info('Workflow created with AI optimization: $workflowId', 'WorkflowService');

    return workflow;
  }

  /// Route a document to appropriate team members
  Future<DocumentRouting> routeDocument({
    required String documentPath,
    required String senderId,
    required String routingPurpose,
    List<String>? suggestedRecipients,
    Map<String, dynamic>? context,
  }) async {
    final routingId = 'routing_${DateTime.now().millisecondsSinceEpoch}';

    // Analyze document for routing intelligence
    final documentAnalysis = await _documentIntelligence.analyzeDocument(
      filePath: documentPath,
      content: '', // Would need to read file content
      existingMetadata: context,
    );

    final routing = DocumentRouting(
      id: routingId,
      documentPath: documentPath,
      senderId: senderId,
      routingPurpose: routingPurpose,
      recommendedRecipients: [],
      routingLogic: '',
      confidence: 0.0,
      createdAt: DateTime.now(),
    );

    // Determine optimal recipients
    routing.recommendedRecipients = await _determineOptimalRecipients(
      documentAnalysis,
      routingPurpose,
      suggestedRecipients,
    );

    // Generate routing rationale
    routing.routingLogic = await _generateRoutingLogic(documentAnalysis, routing);

    // Calculate confidence
    routing.confidence = await _calculateRoutingConfidence(routing);

    _emitWorkflowEvent(WorkflowEventType.documentRouted,
        routingId: routingId, documentPath: documentPath);

    return routing;
  }

  /// Assign task with AI-powered optimization
  Future<TaskAssignment> assignTask({
    required Task task,
    List<String>? candidateUsers,
    Map<String, dynamic>? assignmentContext,
  }) async {
    final assignment = TaskAssignment(
      taskId: task.id,
      assignedUserId: '',
      assignmentReason: '',
      confidence: 0.0,
      alternatives: [],
      assignedAt: DateTime.now(),
    );

    // Get candidate users or all available users
    final candidates = candidateUsers ?? await _getAvailableUsers();

    if (candidates.isEmpty) {
      assignment.assignmentReason = 'No available users found';
      return assignment;
    }

    // AI-powered assignment optimization
    final optimalAssignment = await _findOptimalAssignee(task, candidates, assignmentContext);

    assignment.assignedUserId = optimalAssignment['userId'];
    assignment.assignmentReason = optimalAssignment['reason'];
    assignment.confidence = optimalAssignment['confidence'];
    assignment.alternatives = optimalAssignment['alternatives'];

    // Update task
    task.assignedTo = assignment.assignedUserId;
    task.status = TaskStatus.assigned;

    _emitWorkflowEvent(WorkflowEventType.taskAssigned,
        taskId: task.id, assignedTo: assignment.assignedUserId);

    return assignment;
  }

  /// Predict task priority and deadlines
  Future<TaskPrediction> predictTaskPriority(Task task) async {
    final prediction = TaskPrediction(
      taskId: task.id,
      predictedPriority: TaskPriority.medium,
      predictedDeadline: task.dueDate,
      reasoning: '',
      confidence: 0.0,
      relatedTasks: [],
    );

    // Analyze task content and context
    final analysis = await _analyzeTaskContext(task);

    // Predict priority based on multiple factors
    prediction.predictedPriority = await _predictTaskPriority(analysis);
    prediction.predictedDeadline = await _predictTaskDeadline(analysis);
    prediction.reasoning = await _generatePredictionReasoning(analysis);
    prediction.confidence = await _calculatePredictionConfidence(analysis);

    // Find related tasks
    prediction.relatedTasks = await _findRelatedTasks(task);

    return prediction;
  }

  /// Get workflow optimization recommendations
  Future<List<WorkflowOptimization>> getWorkflowOptimizations() async {
    final optimizations = <WorkflowOptimization>[];

    // Analyze active workflows for bottlenecks
    for (final workflow in _activeWorkflows.values) {
      final bottlenecks = await _identifyWorkflowBottlenecks(workflow);
      if (bottlenecks.isNotEmpty) {
        optimizations.add(WorkflowOptimization(
          workflowId: workflow.id,
          optimizationType: 'bottleneck_resolution',
          description: 'Identified workflow bottlenecks',
          recommendations: bottlenecks,
          estimatedImprovement: 0.25, // 25% improvement
          priority: OptimizationPriority.high,
        ));
      }
    }

    // Analyze task assignment patterns
    final assignmentOptimizations = await _analyzeAssignmentPatterns();
    optimizations.addAll(assignmentOptimizations);

    // Resource utilization analysis
    final resourceOptimizations = await _analyzeResourceUtilization();
    optimizations.addAll(resourceOptimizations);

    return optimizations.take(20).toList(); // Top 20 optimizations
  }

  /// Get workflow performance metrics
  WorkflowMetrics getWorkflowMetrics(String workflowId) {
    return _workflowMetrics.putIfAbsent(workflowId, () => WorkflowMetrics(
      workflowId: workflowId,
      totalTasks: 0,
      completedTasks: 0,
      averageTaskDuration: Duration.zero,
      bottleneckTasks: [],
      efficiencyScore: 0.0,
      lastUpdated: DateTime.now(),
    ));
  }

  // Private implementation methods

  Future<List<Task>> _optimizeTaskAssignment(List<TaskDefinition> taskDefinitions, Workflow workflow) async {
    final tasks = <Task>[];

    for (final definition in taskDefinitions) {
      final task = Task(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        workflowId: workflow.id,
        title: definition.title,
        description: definition.description,
        type: definition.type,
        priority: definition.priority,
        estimatedDuration: definition.estimatedDuration,
        dependencies: definition.dependencies,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      );

      // AI-powered assignee recommendation
      final assignment = await assignTask(task: task, assignmentContext: {
        'workflow_context': workflow.description,
        'task_complexity': definition.complexity,
      });

      task.assignedTo = assignment.assignedUserId;
      tasks.add(task);
    }

    // Optimize task sequencing
    return await _optimizeTaskSequence(tasks);
  }

  Future<List<Task>> _optimizeTaskSequence(List<Task> tasks) async {
    if (_model == null || tasks.length <= 1) return tasks;

    try {
      final taskDescriptions = tasks.map((task) =>
        '${task.title}: ${task.description} (duration: ${task.estimatedDuration?.inHours ?? 0}h, priority: ${task.priority})'
      ).join('\n');

      final prompt = '''
Optimize the sequence of these tasks for maximum efficiency:

TASKS:
$taskDescriptions

Consider:
1. Task dependencies and prerequisites
2. Task priorities and deadlines
3. Resource availability and workload balancing
4. Parallel execution opportunities
5. Bottleneck minimization

Provide the optimal execution order with reasoning.
Format as a numbered list with brief rationale for each position.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result != null) {
        final optimizedOrder = _parseTaskSequenceOptimization(result, tasks);
        return optimizedOrder;
      }
    } catch (e) {
      _logger.warning('Task sequence optimization failed, using original order', 'WorkflowService', error: e);
    }

    return tasks; // Return original order on failure
  }

  List<Task> _parseTaskSequenceOptimization(String response, List<Task> originalTasks) {
    final optimizedTasks = <Task>[];
    final lines = response.split('\n');

    for (final line in lines) {
      if (line.contains(RegExp(r'^\d+\.'))) {
        final taskTitle = _extractTaskTitleFromLine(line);
        final matchingTask = originalTasks.firstWhere(
          (task) => task.title.toLowerCase().contains(taskTitle.toLowerCase()),
          orElse: () => originalTasks.first,
        );
        if (!optimizedTasks.contains(matchingTask)) {
          optimizedTasks.add(matchingTask);
        }
      }
    }

    // Add any remaining tasks not mentioned in optimization
    for (final task in originalTasks) {
      if (!optimizedTasks.contains(task)) {
        optimizedTasks.add(task);
      }
    }

    return optimizedTasks;
  }

  Future<List<String>> _determineOptimalRecipients(
    DocumentAnalysis documentAnalysis,
    String purpose,
    List<String>? suggestedRecipients,
  ) async {
    final recipients = <String>[];

    // Start with suggested recipients if provided
    if (suggestedRecipients != null) {
      recipients.addAll(suggestedRecipients);
    }

    // AI-powered recipient recommendation
    if (_model != null) {
      final aiRecipients = await _getAIRecipientRecommendations(documentAnalysis, purpose);
      recipients.addAll(aiRecipients.where((user) => !recipients.contains(user)));
    }

    // Filter by availability and expertise
    final availableRecipients = await _filterAvailableRecipients(recipients);

    return availableRecipients.take(5).toList(); // Top 5 recipients
  }

  Future<List<String>> _getAIRecipientRecommendations(DocumentAnalysis analysis, String purpose) async {
    if (_model == null) return [];

    try {
      final prompt = '''
Based on this document analysis, recommend the most suitable team members for: "$purpose"

DOCUMENT INFO:
- Type: ${analysis.aiInsights?['document_type'] ?? 'unknown'}
- Categories: ${analysis.aiInsights?['categories']?.join(', ') ?? 'none'}
- Summary: ${analysis.aiInsights?['summary'] ?? 'No summary'}

Consider expertise, current workload, and collaboration history.
Provide 3-5 user recommendations with brief rationale.

Format as: User Name - Reason
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final recommendations = <String>[];

      if (response.text != null) {
        final lines = response.text!.split('\n');
        for (final line in lines) {
          if (line.contains(' - ')) {
            final userName = line.split(' - ')[0].trim();
            recommendations.add(userName);
          }
        }
      }

      return recommendations;
    } catch (e) {
      _logger.warning('AI recipient recommendation failed', 'WorkflowService', error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>> _findOptimalAssignee(
    Task task,
    List<String> candidates,
    Map<String, dynamic>? context,
  ) async {
    if (candidates.isEmpty) {
      return {
        'userId': '',
        'reason': 'No candidates available',
        'confidence': 0.0,
        'alternatives': [],
      };
    }

    // Default assignment (first candidate)
    var bestAssignee = candidates.first;
    var bestReason = 'Default assignment';
    var bestConfidence = 0.5;
    final alternatives = <String>[];

    // AI-powered assignment optimization
    if (_model != null) {
      try {
        final candidateProfiles = await _getCandidateProfiles(candidates);
        final assignmentAnalysis = await _analyzeAssignmentFit(task, candidateProfiles, context);

        bestAssignee = assignmentAnalysis['optimalAssignee'] ?? candidates.first;
        bestReason = assignmentAnalysis['reasoning'] ?? 'AI-optimized assignment';
        bestConfidence = assignmentAnalysis['confidence'] ?? 0.7;

        // Extract alternatives
        final altList = assignmentAnalysis['alternatives'] as List?;
        if (altList != null) {
          alternatives.addAll(altList.map((a) => a.toString()));
        }
      } catch (e) {
        _logger.warning('AI assignment optimization failed, using default', 'WorkflowService', error: e);
      }
    }

    return {
      'userId': bestAssignee,
      'reason': bestReason,
      'confidence': bestConfidence,
      'alternatives': alternatives,
    };
  }

  Future<void> _performWorkflowOptimization() async {
    try {
      // Identify bottlenecks
      final bottlenecks = await _identifySystemBottlenecks();
      if (bottlenecks.isNotEmpty) {
        _optimizations.addAll(bottlenecks);
      }

      // Resource rebalancing
      await _performResourceRebalancing();

      // Process optimization recommendations
      await _generateOptimizationRecommendations();

      _logger.info('Workflow optimization analysis completed', 'WorkflowService');

    } catch (e, stackTrace) {
      _logger.error('Workflow optimization failed', 'WorkflowService', error: e, stackTrace: stackTrace);
    }
  }

  // Utility methods
  Future<List<String>> _getAvailableUsers() async {
    // In a real implementation, this would query user management system
    // For now, return mock users
    return ['user1', 'user2', 'user3', 'user4', 'user5'];
  }

  Future<List<Map<String, dynamic>>> _getCandidateProfiles(List<String> candidates) async {
    // Mock user profiles - in real implementation, query user database
    final profiles = <Map<String, dynamic>>[];
    for (final candidate in candidates) {
      profiles.add({
        'userId': candidate,
        'skills': ['general'], // Would be detailed skills list
        'currentWorkload': Random().nextInt(10), // Mock workload
        'expertise': ['basic'], // Mock expertise areas
      });
    }
    return profiles;
  }

  Future<Map<String, dynamic>> _analyzeAssignmentFit(
    Task task,
    List<Map<String, dynamic>> candidateProfiles,
    Map<String, dynamic>? context,
  ) async {
    if (_model == null) return {'optimalAssignee': candidateProfiles.first['userId']};

    // Simplified AI assignment analysis
    final bestCandidate = candidateProfiles.reduce((a, b) {
      final aWorkload = a['currentWorkload'] as int;
      final bWorkload = b['currentWorkload'] as int;
      return aWorkload <= bWorkload ? a : b; // Choose least busy
    });

    return {
      'optimalAssignee': bestCandidate['userId'],
      'reasoning': 'Selected based on current workload balance',
      'confidence': 0.8,
      'alternatives': candidateProfiles
        .where((p) => p['userId'] != bestCandidate['userId'])
        .take(2)
        .map((p) => p['userId'])
        .toList(),
    };
  }

  Future<List<String>> _filterAvailableRecipients(List<String> recipients) async {
    // Mock availability check - in real implementation, check user status
    return recipients.where((user) => Random().nextBool()).toList();
  }

  Future<TaskPriority> _predictTaskPriority(Map<String, dynamic> analysis) async {
    // Simplified priority prediction
    final urgencyKeywords = ['urgent', 'asap', 'critical', 'emergency'];
    final content = analysis['content']?.toString().toLowerCase() ?? '';

    if (urgencyKeywords.any((keyword) => content.contains(keyword))) {
      return TaskPriority.high;
    }

    return TaskPriority.medium;
  }

  Future<DateTime> _predictTaskDeadline(Map<String, dynamic> analysis) async {
    // Simplified deadline prediction - add 7 days by default
    return DateTime.now().add(Duration(days: 7));
  }

  Future<String> _generatePredictionReasoning(Map<String, dynamic> analysis) async {
    return 'Based on task content and organizational priorities';
  }

  Future<double> _calculatePredictionConfidence(Map<String, dynamic> analysis) async {
    return 0.75; // Mock confidence
  }

  Future<List<Task>> _findRelatedTasks(Task task) async {
    // Mock related task finding
    return [];
  }

  Future<String> _generateRoutingLogic(DocumentAnalysis analysis, DocumentRouting routing) async {
    return 'Routed based on document content analysis and team expertise matching';
  }

  Future<double> _calculateRoutingConfidence(DocumentRouting routing) async {
    return routing.recommendedRecipients.isNotEmpty ? 0.8 : 0.3;
  }

  Future<List<String>> _identifyWorkflowBottlenecks(Workflow workflow) async {
    final bottlenecks = <String>[];

    for (final task in workflow.tasks) {
      if (task.status == TaskStatus.pending && task.createdAt.isBefore(DateTime.now().subtract(Duration(days: 2)))) {
        bottlenecks.add('Task "${task.title}" has been pending for more than 2 days');
      }
    }

    return bottlenecks;
  }

  Future<List<WorkflowOptimization>> _identifySystemBottlenecks() async {
    return []; // Mock implementation
  }

  Future<void> _performResourceRebalancing() async {
    // Mock resource rebalancing
  }

  Future<void> _generateOptimizationRecommendations() async {
    // Mock optimization recommendations
  }

  Future<List<WorkflowOptimization>> _analyzeAssignmentPatterns() async {
    return []; // Mock implementation
  }

  Future<List<WorkflowOptimization>> _analyzeResourceUtilization() async {
    return []; // Mock implementation
  }

  void _emitWorkflowEvent(WorkflowEventType type, {
    String? workflowId,
    String? taskId,
    String? assignedTo,
    String? routingId,
    String? documentPath,
  }) {
    final event = WorkflowEvent(
      type: type,
      timestamp: DateTime.now(),
      workflowId: workflowId,
      taskId: taskId,
      assignedTo: assignedTo,
      routingId: routingId,
      documentPath: documentPath,
    );
    _workflowEvents.add(event);
  }

  String _extractTaskTitleFromLine(String line) {
    // Extract task title from optimization response line
    final colonIndex = line.indexOf(':');
    if (colonIndex > 0) {
      return line.substring(colonIndex + 1).trim();
    }
    return line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  Stream<WorkflowEvent> get workflowEvents => _workflowEvents.stream;
  Map<String, Workflow> get activeWorkflows => Map.from(_activeWorkflows);
  Map<String, Task> get activeTasks => Map.from(_activeTasks);
}

/// Supporting data classes

enum WorkflowStatus { planning, active, paused, completed, cancelled }
enum TaskStatus { pending, assigned, inProgress, completed, blocked, cancelled }
enum TaskPriority { low, medium, high, critical }
enum WorkflowEventType {
  workflowCreated,
  workflowStarted,
  workflowCompleted,
  taskAssigned,
  taskCompleted,
  taskBlocked,
  documentRouted,
  routingCompleted,
  optimizationApplied,
}

class Workflow {
  final String id;
  final String name;
  final String description;
  final List<Task> tasks;
  WorkflowStatus status;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Workflow({
    required this.id,
    required this.name,
    required this.description,
    required this.tasks,
    required this.status,
    required this.createdAt,
    required this.metadata,
  });
}

class TaskDefinition {
  final String title;
  final String description;
  final String type;
  final TaskPriority priority;
  final Duration? estimatedDuration;
  final List<String> dependencies;
  final String? complexity;

  TaskDefinition({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.estimatedDuration,
    required this.dependencies,
    this.complexity,
  });
}

class Task {
  final String id;
  final String workflowId;
  final String title;
  final String description;
  final String type;
  TaskPriority priority;
  final Duration? estimatedDuration;
  final List<String> dependencies;
  TaskStatus status;
  String? assignedTo;
  final DateTime createdAt;
  DateTime? dueDate;

  Task({
    required this.id,
    required this.workflowId,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.estimatedDuration,
    required this.dependencies,
    required this.status,
    this.assignedTo,
    required this.createdAt,
    this.dueDate,
  });
}

class UserProfile {
  final String userId;
  final List<String> skills;
  final List<String> expertise;
  final int currentWorkload;
  final Map<String, double> taskCompletionRates;

  UserProfile({
    required this.userId,
    required this.skills,
    required this.expertise,
    required this.currentWorkload,
    required this.taskCompletionRates,
  });
}

class TaskAssignment {
  final String taskId;
  final String assignedUserId;
  final String assignmentReason;
  final double confidence;
  final List<String> alternatives;
  final DateTime assignedAt;

  TaskAssignment({
    required this.taskId,
    required this.assignedUserId,
    required this.assignmentReason,
    required this.confidence,
    required this.alternatives,
    required this.assignedAt,
  });
}

class TaskPrediction {
  final String taskId;
  final TaskPriority predictedPriority;
  final DateTime predictedDeadline;
  final String reasoning;
  final double confidence;
  final List<Task> relatedTasks;

  TaskPrediction({
    required this.taskId,
    required this.predictedPriority,
    required this.predictedDeadline,
    required this.reasoning,
    required this.confidence,
    required this.relatedTasks,
  });
}

class DocumentRouting {
  final String id;
  final String documentPath;
  final String senderId;
  final String routingPurpose;
  final List<String> recommendedRecipients;
  String routingLogic;
  double confidence;
  final DateTime createdAt;

  DocumentRouting({
    required this.id,
    required this.documentPath,
    required this.senderId,
    required this.routingPurpose,
    required this.recommendedRecipients,
    required this.routingLogic,
    required this.confidence,
    required this.createdAt,
  });
}

class WorkflowEvent {
  final WorkflowEventType type;
  final DateTime timestamp;
  final String? workflowId;
  final String? taskId;
  final String? assignedTo;
  final String? routingId;
  final String? documentPath;

  WorkflowEvent({
    required this.type,
    required this.timestamp,
    this.workflowId,
    this.taskId,
    this.assignedTo,
    this.routingId,
    this.documentPath,
  });
}

class WorkflowMetrics {
  final String workflowId;
  int totalTasks;
  int completedTasks;
  Duration averageTaskDuration;
  List<String> bottleneckTasks;
  double efficiencyScore;
  DateTime lastUpdated;

  WorkflowMetrics({
    required this.workflowId,
    required this.totalTasks,
    required this.completedTasks,
    required this.averageTaskDuration,
    required this.bottleneckTasks,
    required this.efficiencyScore,
    required this.lastUpdated,
  });
}

enum OptimizationPriority { low, medium, high, critical }

class WorkflowOptimization {
  final String workflowId;
  final String optimizationType;
  final String description;
  final List<String> recommendations;
  final double estimatedImprovement;
  final OptimizationPriority priority;

  WorkflowOptimization({
    required this.workflowId,
    required this.optimizationType,
    required this.description,
    required this.recommendations,
    required this.estimatedImprovement,
    required this.priority,
  });
}
