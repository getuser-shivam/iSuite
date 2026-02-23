import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/config/central_config.dart';
import '../../core/advanced_performance_service.dart';
import '../../core/logging/logging_service.dart';
import 'ai_file_analysis_service.dart';

/// Generative AI Service for Automated Code Generation, Documentation, and Intelligent Suggestions
/// Provides advanced AI-powered development assistance with code generation, documentation, and smart recommendations
class GenerativeAIService {
  static final GenerativeAIService _instance = GenerativeAIService._internal();
  factory GenerativeAIService() => _instance;
  GenerativeAIService._internal();

  final CentralConfig _config = CentralConfig.instance;
  final AdvancedPerformanceService _performanceService = AdvancedPerformanceService();
  final LoggingService _logger = LoggingService();
  final AIFileAnalysisService _aiAnalysisService = AIFileAnalysisService();

  StreamController<GenerationEvent> _generationEventController = StreamController.broadcast();
  StreamController<SuggestionEvent> _suggestionEventController = StreamController.broadcast();
  StreamController<DocumentationEvent> _documentationEventController = StreamController.broadcast();

  Stream<GenerationEvent> get generationEvents => _generationEventController.stream;
  Stream<SuggestionEvent> get suggestionEvents => _suggestionEventController.stream;
  Stream<DocumentationEvent> get documentationEvents => _documentationEventController.stream;

  // Generative AI models and configurations
  String? _llmApiKey;
  String? _llmEndpoint;
  String? _llmModel;
  Map<String, dynamic> _llmConfig = {};

  // Code generation templates and patterns
  final Map<String, CodeTemplate> _codeTemplates = {};
  final Map<String, GenerationPattern> _generationPatterns = {};
  final Map<String, CodeSnippet> _codeSnippets = {};

  // Documentation generation
  final Map<String, DocumentationTemplate> _documentationTemplates = {};
  final Map<String, APIDocumentation> _apiDocumentation = {};

  // Intelligent suggestions
  final Map<String, SuggestionRule> _suggestionRules = {};
  final Map<String, CodeAnalysis> _codeAnalyses = {};

  // Learning and adaptation
  final Map<String, UserCodingPattern> _userPatterns = {};
  final Map<String, ProjectCodebase> _projectKnowledge = {};

  bool _isInitialized = false;
  bool _generativeAIEnabled = true;

  /// Initialize generative AI service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing generative AI service', 'GenerativeAIService');

      // Register with CentralConfig
      await _config.registerComponent(
        'GenerativeAIService',
        '2.0.0',
        'Advanced generative AI for code generation, documentation, and intelligent suggestions',
        dependencies: ['CentralConfig', 'AIFileAnalysisService'],
        parameters: {
          // Generative AI Configuration
          'ai.generative.enabled': true,
          'ai.generative.llm_provider': 'openai',
          'ai.generative.llm_model': 'gpt-4',
          'ai.generative.llm_api_key': '',
          'ai.generative.llm_endpoint': 'https://api.openai.com/v1',
          'ai.generative.temperature': 0.7,
          'ai.generative.max_tokens': 2000,
          'ai.generative.timeout': 30000,

          // Code Generation Settings
          'ai.generative.code.templates_enabled': true,
          'ai.generative.code.patterns_enabled': true,
          'ai.generative.code.snippets_enabled': true,
          'ai.generative.code.boilerplate_enabled': true,
          'ai.generative.code.refactoring_enabled': true,

          // Documentation Settings
          'ai.generative.docs.api_enabled': true,
          'ai.generative.docs.code_enabled': true,
          'ai.generative.docs.readme_enabled': true,
          'ai.generative.docs.comments_enabled': true,

          // Suggestions Settings
          'ai.generative.suggestions.code_enabled': true,
          'ai.generative.suggestions.bugs_enabled': true,
          'ai.generative.suggestions.performance_enabled': true,
          'ai.generative.suggestions.security_enabled': true,

          // Learning Settings
          'ai.generative.learning.user_patterns': true,
          'ai.generative.learning.project_knowledge': true,
          'ai.generative.learning.adaptation': true,

          // Quality Settings
          'ai.generative.quality.confidence_threshold': 0.75,
          'ai.generative.quality.code_review': true,
          'ai.generative.quality.testing_suggestions': true,

          // Integration Settings
          'ai.generative.integrate_ide': true,
          'ai.generative.integrate_git': true,
          'ai.generative.integrate_ci_cd': true,
        }
      );

      // Initialize LLM configuration
      await _initializeLLMConfig();

      // Initialize code generation system
      await _initializeCodeGeneration();

      // Initialize documentation system
      await _initializeDocumentationSystem();

      // Initialize suggestion system
      await _initializeSuggestionSystem();

      // Initialize learning system
      await _initializeLearningSystem();

      _isInitialized = true;
      _logger.info('Generative AI service initialized successfully', 'GenerativeAIService');

    } catch (e, stackTrace) {
      _logger.error('Failed to initialize generative AI service', 'GenerativeAIService',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate code based on natural language description
  Future<CodeGenerationResult> generateCode({
    required String description,
    String? language,
    String? framework,
    String? context,
    List<String>? requirements,
    CodeGenerationOptions? options,
  }) async {
    try {
      _logger.info('Generating code from description: "$description"', 'GenerativeAIService');

      // Analyze requirements and context
      final analysis = await _analyzeCodeRequirements(description, context, requirements);

      // Generate code using AI
      final generatedCode = await _generateCodeWithAI(
        analysis,
        language ?? 'dart',
        framework,
        options
      );

      // Validate and improve generated code
      final validatedCode = await _validateAndImproveCode(generatedCode, analysis);

      // Generate tests for the code
      final tests = options?.includeTests ?? true ?
        await generateTestsForCode(validatedCode, language ?? 'dart') : null;

      // Generate documentation
      final documentation = options?.includeDocumentation ?? true ?
        await generateCodeDocumentation(validatedCode, description) : null;

      final result = CodeGenerationResult(
        description: description,
        generatedCode: validatedCode,
        language: language ?? 'dart',
        framework: framework,
        tests: tests,
        documentation: documentation,
        confidence: analysis.confidence,
        metadata: {
          'complexity': analysis.complexity,
          'patterns_used': analysis.patterns,
          'dependencies': analysis.dependencies,
        },
        generatedAt: DateTime.now(),
      );

      _emitGenerationEvent(GenerationEventType.codeGenerated, data: {
        'description': description,
        'language': language,
        'confidence': analysis.confidence,
        'code_length': validatedCode.length,
      });

      return result;

    } catch (e, stackTrace) {
      _logger.error('Code generation failed: $description', 'GenerativeAIService', error: e, stackTrace: stackTrace);

      return CodeGenerationResult(
        description: description,
        generatedCode: '// Error generating code: $e',
        language: language ?? 'dart',
        confidence: 0.0,
        generatedAt: DateTime.now(),
      );
    }
  }

  /// Generate comprehensive documentation
  Future<DocumentationResult> generateDocumentation({
    required String codeOrPath,
    DocumentationType type = DocumentationType.api,
    String? language,
    DocumentationOptions? options,
  }) async {
    try {
      _logger.info('Generating documentation for type: ${type.name}', 'GenerativeAIService');

      String codeContent;
      String filePath;

      // Handle both code content and file paths
      if (File(codeOrPath).existsSync()) {
        filePath = codeOrPath;
        codeContent = await File(codeOrPath).readAsString();
      } else {
        codeContent = codeOrPath;
        filePath = 'inline_code';
      }

      // Analyze code structure
      final analysis = await _aiAnalysisService.analyzeFileAdvanced(filePath);

      // Generate documentation based on type
      String documentation;
      Map<String, dynamic> metadata = {};

      switch (type) {
        case DocumentationType.api:
          documentation = await _generateAPIDocumentation(codeContent, analysis, language);
          metadata = await _extractAPIMetadata(codeContent, analysis);
          break;

        case DocumentationType.code:
          documentation = await _generateCodeDocumentation(codeContent, analysis, language);
          metadata = await _extractCodeMetadata(codeContent, analysis);
          break;

        case DocumentationType.readme:
          documentation = await _generateReadmeDocumentation(codeContent, analysis);
          metadata = {'type': 'readme'};
          break;

        case DocumentationType.comments:
          documentation = await _generateInlineComments(codeContent, analysis, language);
          metadata = {'type': 'comments'};
          break;
      }

      final result = DocumentationResult(
        sourceCode: codeContent,
        generatedDocumentation: documentation,
        type: type,
        language: language ?? _detectLanguage(codeContent),
        metadata: metadata,
        confidence: analysis.confidence,
        generatedAt: DateTime.now(),
      );

      _emitDocumentationEvent(DocumentationEventType.documentationGenerated, data: {
        'type': type.name,
        'language': language,
        'confidence': analysis.confidence,
        'doc_length': documentation.length,
      });

      return result;

    } catch (e, stackTrace) {
      _logger.error('Documentation generation failed', 'GenerativeAIService', error: e, stackTrace: stackTrace);

      return DocumentationResult(
        sourceCode: codeOrPath,
        generatedDocumentation: '/* Error generating documentation: $e */',
        type: type,
        confidence: 0.0,
        generatedAt: DateTime.now(),
      );
    }
  }

  /// Provide intelligent code suggestions
  Future<List<CodeSuggestion>> getCodeSuggestions({
    required String code,
    required String context,
    String? language,
    SuggestionContext? suggestionContext,
  }) async {
    try {
      _logger.info('Generating code suggestions for context: $context', 'GenerativeAIService');

      final suggestions = <CodeSuggestion>[];

      // Analyze code and context
      final analysis = await _analyzeCodeForSuggestions(code, context, language);

      // Bug detection and fixes
      if (_config.getParameter('ai.generative.suggestions.bugs_enabled', defaultValue: true)) {
        final bugSuggestions = await _generateBugFixSuggestions(analysis);
        suggestions.addAll(bugSuggestions);
      }

      // Performance improvements
      if (_config.getParameter('ai.generative.suggestions.performance_enabled', defaultValue: true)) {
        final perfSuggestions = await _generatePerformanceSuggestions(analysis);
        suggestions.addAll(perfSuggestions);
      }

      // Security improvements
      if (_config.getParameter('ai.generative.suggestions.security_enabled', defaultValue: true)) {
        final securitySuggestions = await _generateSecuritySuggestions(analysis);
        suggestions.addAll(securitySuggestions);
      }

      // Code quality improvements
      final qualitySuggestions = await _generateQualitySuggestions(analysis);
      suggestions.addAll(qualitySuggestions);

      // Sort by confidence and priority
      suggestions.sort((a, b) => (b.confidence * b.priority).compareTo(a.confidence * a.priority));

      // Limit suggestions
      if (suggestions.length > 10) {
        suggestions.removeRange(10, suggestions.length);
      }

      for (final suggestion in suggestions) {
        _emitSuggestionEvent(SuggestionEventType.suggestionGenerated, data: {
          'type': suggestion.type.name,
          'confidence': suggestion.confidence,
          'priority': suggestion.priority,
        });
      }

      return suggestions;

    } catch (e, stackTrace) {
      _logger.error('Code suggestions generation failed', 'GenerativeAIService', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Generate tests for code
  Future<TestGenerationResult> generateTestsForCode(String code, String language) async {
    try {
      _logger.info('Generating tests for $language code', 'GenerativeAIService');

      // Analyze code structure
      final analysis = await _analyzeCodeStructure(code, language);

      // Generate test cases
      final testCases = await _generateTestCases(analysis, language);

      // Generate test code
      final testCode = await _generateTestCode(testCases, analysis, language);

      // Generate test data
      final testData = await _generateTestData(analysis, language);

      final result = TestGenerationResult(
        sourceCode: code,
        generatedTests: testCode,
        testCases: testCases,
        testData: testData,
        coverage: _estimateTestCoverage(testCases, analysis),
        language: language,
        generatedAt: DateTime.now(),
      );

      _emitGenerationEvent(GenerationEventType.testsGenerated, data: {
        'language': language,
        'test_cases': testCases.length,
        'coverage_estimate': result.coverage,
      });

      return result;

    } catch (e, stackTrace) {
      _logger.error('Test generation failed', 'GenerativeAIService', error: e, stackTrace: stackTrace);

      return TestGenerationResult(
        sourceCode: code,
        generatedTests: '// Error generating tests: $e',
        testCases: [],
        testData: {},
        coverage: 0.0,
        language: language,
        generatedAt: DateTime.now(),
      );
    }
  }

  /// Provide intelligent code refactoring suggestions
  Future<List<RefactoringSuggestion>> getRefactoringSuggestions({
    required String code,
    required String language,
    RefactoringContext? context,
  }) async {
    try {
      _logger.info('Generating refactoring suggestions for $language code', 'GenerativeAIService');

      final suggestions = <RefactoringSuggestion>[];

      // Analyze code for refactoring opportunities
      final analysis = await _analyzeCodeForRefactoring(code, language, context);

      // Generate specific refactoring suggestions
      if (analysis.complexity > 10) {
        suggestions.add(RefactoringSuggestion(
          type: RefactoringType.extractMethod,
          description: 'Extract complex logic into separate methods',
          codeChanges: await _generateExtractMethodRefactoring(analysis),
          benefit: 'Improves readability and maintainability',
          confidence: 0.85,
        ));
      }

      if (analysis.duplicateCode.isNotEmpty) {
        suggestions.add(RefactoringSuggestion(
          type: RefactoringType.extractCommon,
          description: 'Extract duplicate code into reusable functions',
          codeChanges: await _generateExtractCommonRefactoring(analysis),
          benefit: 'Reduces code duplication and improves maintainability',
          confidence: 0.90,
        ));
      }

      if (analysis.longMethods.isNotEmpty) {
        suggestions.add(RefactoringSuggestion(
          type: RefactoringType.splitMethod,
          description: 'Split long methods into smaller, focused functions',
          codeChanges: await _generateSplitMethodRefactoring(analysis),
          benefit: 'Improves code readability and testability',
          confidence: 0.80,
        ));
      }

      // Sort by confidence
      suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

      return suggestions;

    } catch (e, stackTrace) {
      _logger.error('Refactoring suggestions generation failed', 'GenerativeAIService', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Generate project documentation (README, API docs, etc.)
  Future<ProjectDocumentation> generateProjectDocumentation({
    required String projectPath,
    ProjectDocumentationOptions? options,
  }) async {
    try {
      _logger.info('Generating project documentation for: $projectPath', 'GenerativeAIService');

      final projectDir = Directory(projectPath);

      // Analyze project structure
      final structure = await _analyzeProjectStructure(projectDir);

      // Generate README
      final readme = options?.includeReadme ?? true ?
        await _generateProjectReadme(structure) : null;

      // Generate API documentation
      final apiDocs = options?.includeApiDocs ?? true ?
        await _generateProjectAPIDocs(structure) : null;

      // Generate architecture documentation
      final architecture = options?.includeArchitecture ?? true ?
        await _generateArchitectureDocs(structure) : null;

      // Generate setup/installation guide
      final setupGuide = options?.includeSetupGuide ?? true ?
        await _generateSetupGuide(structure) : null;

      final documentation = ProjectDocumentation(
        projectPath: projectPath,
        readme: readme,
        apiDocumentation: apiDocs,
        architectureDocumentation: architecture,
        setupGuide: setupGuide,
        generatedAt: DateTime.now(),
        projectInfo: await _extractProjectInfo(structure),
      );

      _emitDocumentationEvent(DocumentationEventType.projectDocsGenerated, data: {
        'project_path': projectPath,
        'components': [
          if (readme != null) 'readme',
          if (apiDocs != null) 'api_docs',
          if (architecture != null) 'architecture',
          if (setupGuide != null) 'setup_guide',
        ].join(', '),
      });

      return documentation;

    } catch (e, stackTrace) {
      _logger.error('Project documentation generation failed', 'GenerativeAIService', error: e, stackTrace: stackTrace);

      return ProjectDocumentation(
        projectPath: projectPath,
        generatedAt: DateTime.now(),
      );
    }
  }

  // Core implementation methods (simplified)

  Future<void> _initializeLLMConfig() async {
    _generativeAIEnabled = _config.getParameter('ai.generative.enabled', defaultValue: true);
    _llmApiKey = _config.getParameter('ai.generative.llm_api_key', defaultValue: '');
    _llmEndpoint = _config.getParameter('ai.generative.llm_endpoint', defaultValue: 'https://api.openai.com/v1');
    _llmModel = _config.getParameter('ai.generative.llm_model', defaultValue: 'gpt-4');

    _llmConfig = {
      'temperature': _config.getParameter('ai.generative.temperature', defaultValue: 0.7),
      'max_tokens': _config.getParameter('ai.generative.max_tokens', defaultValue: 2000),
      'timeout': _config.getParameter('ai.generative.timeout', defaultValue: 30000),
    };
  }

  Future<void> _initializeCodeGeneration() async {
    // Initialize code templates and patterns
    _logger.info('Code generation system initialized', 'GenerativeAIService');
  }

  Future<void> _initializeDocumentationSystem() async {
    // Initialize documentation templates
    _logger.info('Documentation system initialized', 'GenerativeAIService');
  }

  Future<void> _initializeSuggestionSystem() async {
    // Initialize suggestion rules
    _logger.info('Suggestion system initialized', 'GenerativeAIService');
  }

  Future<void> _initializeLearningSystem() async {
    // Initialize learning and adaptation
    _logger.info('Learning system initialized', 'GenerativeAIService');
  }

  Future<CodeRequirementAnalysis> _analyzeCodeRequirements(String description, String? context, List<String>? requirements) async =>
    CodeRequirementAnalysis(confidence: 0.8, complexity: 5, patterns: [], dependencies: []);

  Future<String> _generateCodeWithAI(CodeRequirementAnalysis analysis, String language, String? framework, CodeGenerationOptions? options) async =>
    '// Generated code placeholder';

  Future<String> _validateAndImproveCode(String code, CodeRequirementAnalysis analysis) async => code;

  Future<String> _generateCodeDocumentation(String code, String description) async => '/* Documentation placeholder */';

  Future<CodeAnalysis> _analyzeCodeForSuggestions(String code, String context, String? language) async =>
    CodeAnalysis(complexity: 5, issues: [], patterns: []);

  Future<List<CodeSuggestion>> _generateBugFixSuggestions(CodeAnalysis analysis) async => [];
  Future<List<CodeSuggestion>> _generatePerformanceSuggestions(CodeAnalysis analysis) async => [];
  Future<List<CodeSuggestion>> _generateSecuritySuggestions(CodeAnalysis analysis) async => [];
  Future<List<CodeSuggestion>> _generateQualitySuggestions(CodeAnalysis analysis) async => [];

  Future<String> _generateAPIDocumentation(String code, FileAnalysisResult analysis, String? language) async => 'API Documentation placeholder';
  Future<Map<String, dynamic>> _extractAPIMetadata(String code, FileAnalysisResult analysis) async => {};
  Future<String> _generateCodeDocumentation(String code, FileAnalysisResult analysis, String? language) async => 'Code Documentation placeholder';
  Future<Map<String, dynamic>> _extractCodeMetadata(String code, FileAnalysisResult analysis) async => {};
  Future<String> _generateReadmeDocumentation(String code, FileAnalysisResult analysis) async => '# README placeholder';
  Future<String> _generateInlineComments(String code, FileAnalysisResult analysis, String? language) async => code;

  String _detectLanguage(String code) => 'dart';

  Future<ProjectStructure> _analyzeProjectStructure(Directory projectDir) async => ProjectStructure();
  Future<String> _generateProjectReadme(ProjectStructure structure) async => '# Project README';
  Future<String> _generateProjectAPIDocs(ProjectStructure structure) async => 'API Documentation';
  Future<String> _generateArchitectureDocs(ProjectStructure structure) async => 'Architecture Documentation';
  Future<String> _generateSetupGuide(ProjectStructure structure) async => 'Setup Guide';
  Future<ProjectInfo> _extractProjectInfo(ProjectStructure structure) async => ProjectInfo();

  Future<CodeStructureAnalysis> _analyzeCodeStructure(String code, String language) async => CodeStructureAnalysis();
  Future<List<TestCase>> _generateTestCases(CodeStructureAnalysis analysis, String language) async => [];
  Future<String> _generateTestCode(List<TestCase> testCases, CodeStructureAnalysis analysis, String language) async => '// Test code';
  Future<Map<String, dynamic>> _generateTestData(CodeStructureAnalysis analysis, String language) async => {};
  double _estimateTestCoverage(List<TestCase> testCases, CodeStructureAnalysis analysis) => 0.8;

  Future<RefactoringAnalysis> _analyzeCodeForRefactoring(String code, String language, RefactoringContext? context) async =>
    RefactoringAnalysis(complexity: 5, duplicateCode: [], longMethods: []);
  Future<CodeChanges> _generateExtractMethodRefactoring(RefactoringAnalysis analysis) async => CodeChanges();
  Future<CodeChanges> _generateExtractCommonRefactoring(RefactoringAnalysis analysis) async => CodeChanges();
  Future<CodeChanges> _generateSplitMethodRefactoring(RefactoringAnalysis analysis) async => CodeChanges();

  // Event emission methods
  void _emitGenerationEvent(GenerationEventType type, {Map<String, dynamic>? data}) {
    final event = GenerationEvent(type: type, timestamp: DateTime.now(), data: data ?? {});
    _generationEventController.add(event);
  }

  void _emitSuggestionEvent(SuggestionEventType type, {Map<String, dynamic>? data}) {
    final event = SuggestionEvent(type: type, timestamp: DateTime.now(), data: data ?? {});
    _suggestionEventController.add(event);
  }

  void _emitDocumentationEvent(DocumentationEventType type, {Map<String, dynamic>? data}) {
    final event = DocumentationEvent(type: type, timestamp: DateTime.now(), data: data ?? {});
    _documentationEventController.add(event);
  }

  /// Dispose resources
  void dispose() {
    _generationEventController.close();
    _suggestionEventController.close();
    _documentationEventController.close();
  }
}

/// Supporting data classes and enums

enum GenerationEventType {
  codeGenerated,
  testsGenerated,
  documentationGenerated,
  refactoringSuggested,
}

enum SuggestionEventType {
  suggestionGenerated,
  suggestionApplied,
  suggestionRejected,
}

enum DocumentationEventType {
  documentationGenerated,
  projectDocsGenerated,
  apiDocsGenerated,
}

enum DocumentationType {
  api,
  code,
  readme,
  comments,
}

enum RefactoringType {
  extractMethod,
  extractCommon,
  splitMethod,
  renameVariable,
  inlineMethod,
}

class CodeGenerationResult {
  final String description;
  final String generatedCode;
  final String language;
  final String? framework;
  final String? tests;
  final String? documentation;
  final double confidence;
  final Map<String, dynamic> metadata;
  final DateTime generatedAt;

  CodeGenerationResult({
    required this.description,
    required this.generatedCode,
    required this.language,
    this.framework,
    this.tests,
    this.documentation,
    required this.confidence,
    required this.metadata,
    required this.generatedAt,
  });
}

class DocumentationResult {
  final String sourceCode;
  final String generatedDocumentation;
  final DocumentationType type;
  final String language;
  final Map<String, dynamic> metadata;
  final double confidence;
  final DateTime generatedAt;

  DocumentationResult({
    required this.sourceCode,
    required this.generatedDocumentation,
    required this.type,
    required this.language,
    required this.metadata,
    required this.confidence,
    required this.generatedAt,
  });
}

class CodeSuggestion {
  final String type;
  final String description;
  final String code;
  final double confidence;
  final int priority;
  final Map<String, dynamic> metadata;

  CodeSuggestion({
    required this.type,
    required this.description,
    required this.code,
    required this.confidence,
    required this.priority,
    this.metadata = const {},
  });
}

class TestGenerationResult {
  final String sourceCode;
  final String generatedTests;
  final List<TestCase> testCases;
  final Map<String, dynamic> testData;
  final double coverage;
  final String language;
  final DateTime generatedAt;

  TestGenerationResult({
    required this.sourceCode,
    required this.generatedTests,
    required this.testCases,
    required this.testData,
    required this.coverage,
    required this.language,
    required this.generatedAt,
  });
}

class RefactoringSuggestion {
  final RefactoringType type;
  final String description;
  final CodeChanges codeChanges;
  final String benefit;
  final double confidence;

  RefactoringSuggestion({
    required this.type,
    required this.description,
    required this.codeChanges,
    required this.benefit,
    required this.confidence,
  });
}

class ProjectDocumentation {
  final String projectPath;
  final String? readme;
  final String? apiDocumentation;
  final String? architectureDocumentation;
  final String? setupGuide;
  final DateTime generatedAt;
  final ProjectInfo projectInfo;

  ProjectDocumentation({
    required this.projectPath,
    this.readme,
    this.apiDocumentation,
    this.architectureDocumentation,
    this.setupGuide,
    required this.generatedAt,
    required this.projectInfo,
  });
}

class GenerationEvent {
  final GenerationEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  GenerationEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class SuggestionEvent {
  final SuggestionEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  SuggestionEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class DocumentationEvent {
  final DocumentationEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  DocumentationEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

// Additional supporting classes (simplified)
class CodeTemplate {
  final String name;
  final String language;
  final String template;
  final List<String> parameters;

  CodeTemplate({
    required this.name,
    required this.language,
    required this.template,
    required this.parameters,
  });
}

class CodeGenerationOptions {
  final bool includeTests;
  final bool includeDocumentation;
  final bool includeComments;
  final String? styleGuide;
  final Map<String, dynamic> customOptions;

  CodeGenerationOptions({
    this.includeTests = true,
    this.includeDocumentation = true,
    this.includeComments = true,
    this.styleGuide,
    this.customOptions = const {},
  });
}

class DocumentationOptions {
  final bool includeExamples;
  final bool includeDiagrams;
  final String? format;
  final Map<String, dynamic> customOptions;

  DocumentationOptions({
    this.includeExamples = true,
    this.includeDiagrams = false,
    this.format = 'markdown',
    this.customOptions = const {},
  });
}

class SuggestionContext {
  final String filePath;
  final int cursorPosition;
  final String selectedCode;
  final Map<String, dynamic> ideContext;

  SuggestionContext({
    required this.filePath,
    required this.cursorPosition,
    required this.selectedCode,
    this.ideContext = const {},
  });
}

class CodeRequirementAnalysis {
  final double confidence;
  final int complexity;
  final List<String> patterns;
  final List<String> dependencies;

  CodeRequirementAnalysis({
    required this.confidence,
    required this.complexity,
    required this.patterns,
    required this.dependencies,
  });
}

class CodeAnalysis {
  final int complexity;
  final List<String> issues;
  final List<String> patterns;

  CodeAnalysis({
    required this.complexity,
    required this.issues,
    required this.patterns,
  });
}

class TestCase {
  final String name;
  final String description;
  final Map<String, dynamic> input;
  final dynamic expectedOutput;
  final String category;

  TestCase({
    required this.name,
    required this.description,
    required this.input,
    required this.expectedOutput,
    required this.category,
  });
}

class RefactoringContext {
  final String filePath;
  final String selectedCode;
  final Map<String, dynamic> codeMetrics;

  RefactoringContext({
    required this.filePath,
    required this.selectedCode,
    required this.codeMetrics,
  });
}

class RefactoringAnalysis {
  final int complexity;
  final List<String> duplicateCode;
  final List<String> longMethods;

  RefactoringAnalysis({
    required this.complexity,
    required this.duplicateCode,
    required this.longMethods,
  });
}

class CodeChanges {
  final List<String> additions;
  final List<String> deletions;
  final List<String> modifications;

  CodeChanges({
    this.additions = const [],
    this.deletions = const [],
    this.modifications = const [],
  });
}

class ProjectDocumentationOptions {
  final bool includeReadme;
  final bool includeApiDocs;
  final bool includeArchitecture;
  final bool includeSetupGuide;
  final String? outputFormat;

  ProjectDocumentationOptions({
    this.includeReadme = true,
    this.includeApiDocs = true,
    this.includeArchitecture = true,
    this.includeSetupGuide = true,
    this.outputFormat = 'markdown',
  });
}

class ProjectStructure {
  // Placeholder for project structure analysis
}

class ProjectInfo {
  // Placeholder for project information
}

class CodeStructureAnalysis {
  // Placeholder for code structure analysis
}
