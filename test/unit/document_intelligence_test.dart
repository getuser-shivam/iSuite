import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iSuite/features/ai_assistant/advanced_document_intelligence_service.dart';
import 'package:iSuite/core/config/central_config.dart';
import 'package:iSuite/core/logging/logging_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdvancedDocumentIntelligenceService documentIntelligence;
  late CentralConfig config;
  late LoggingService logger;

  setUp(() async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});

    // Initialize core services
    logger = LoggingService();
    await logger.initialize();

    config = CentralConfig.instance;
    await config.initialize();

    // Configure AI settings for testing
    await config.setParameters({
      'ai.enabled': true,
      'ai.llm_provider': 'google',
      'ai.api_key': 'test_api_key',
      'ai.model_name': 'gemini-1.5-flash',
      'ai.temperature': 0.7,
      'ai.max_tokens': 1024,
      'ai.cache.enabled': true,
      'ai.cache.ttl': 3600,
      'ai.cache.max_size': 100,
      'ai.document_analysis.enabled': true,
      'ai.document_analysis.auto_categorize': true,
      'ai.document_analysis.extract_metadata': true,
      'ai.document_analysis.generate_summaries': true,
      'ai.document_analysis.confidence_threshold': 0.8,
    });

    // Initialize document intelligence service
    documentIntelligence = AdvancedDocumentIntelligenceService();
    await documentIntelligence.initialize();
  });

  tearDown(() async {
    await documentIntelligence.dispose();
    await config.dispose();
    await logger.dispose();
  });

  group('Advanced Document Intelligence Service Tests', () {
    test('should initialize successfully', () async {
      expect(documentIntelligence.isInitialized, true);
      expect(documentIntelligence.aiEnabled, false); // AI disabled in tests due to mock API
    });

    test('should analyze document without AI', () async {
      const testContent = '''
      This is a test document for analysis.
      It contains multiple lines of text.
      The content is used to test document analysis functionality.
      ''';

      final analysis = await documentIntelligence.analyzeDocument(
        filePath: '/test/document.txt',
        content: testContent,
      );

      expect(analysis, isNotNull);
      expect(analysis.filePath, equals('/test/document.txt'));
      expect(analysis.fileName, equals('document.txt'));
      expect(analysis.mimeType, equals('text/plain'));
      expect(analysis.fileSize, equals(testContent.length));
      expect(analysis.metadata, isNotNull);
      expect(analysis.metadata.containsKey('content_length'), isTrue);
      expect(analysis.metadata['content_length'], equals(testContent.length));
    });

    test('should extract basic metadata', () async {
      const testContent = 'Hello World\nThis is a test document.';

      final analysis = await documentIntelligence.analyzeDocument(
        filePath: '/test/sample.txt',
        content: testContent,
        existingMetadata: {'author': 'Test Author', 'created': '2024-01-01'},
      );

      expect(analysis.metadata['author'], equals('Test Author'));
      expect(analysis.metadata['created'], equals('2024-01-01'));
      expect(analysis.metadata['content_length'], equals(testContent.length));
      expect(analysis.metadata['line_count'], equals(2));
      expect(analysis.metadata['word_count'], equals(7));
      expect(analysis.metadata['encoding'], equals('utf-8'));
    });

    test('should handle different document types', () async {
      // Test JSON document
      const jsonContent = '{"name": "test", "value": 123}';
      final jsonAnalysis = await documentIntelligence.analyzeDocument(
        filePath: '/test/data.json',
        content: jsonContent,
      );
      expect(jsonAnalysis.mimeType, equals('application/json'));

      // Test Markdown document
      const mdContent = '# Title\n\nSome content here.';
      final mdAnalysis = await documentIntelligence.analyzeDocument(
        filePath: '/test/README.md',
        content: mdContent,
      );
      expect(mdAnalysis.mimeType, equals('text/markdown'));

      // Test unknown extension
      const unknownContent = 'Some unknown content';
      final unknownAnalysis = await documentIntelligence.analyzeDocument(
        filePath: '/test/file.unknown',
        content: unknownContent,
      );
      expect(unknownAnalysis.mimeType, equals('application/octet-stream'));
    });

    test('should handle empty documents', () async {
      const emptyContent = '';

      final analysis = await documentIntelligence.analyzeDocument(
        filePath: '/test/empty.txt',
        content: emptyContent,
      );

      expect(analysis.fileSize, equals(0));
      expect(analysis.metadata['content_length'], equals(0));
      expect(analysis.metadata['line_count'], equals(0));
      expect(analysis.metadata['word_count'], equals(0));
    });

    test('should handle large documents', () async {
      // Create a large document (100KB)
      final largeContent = 'A'.padRight(100 * 1024, 'B');

      final analysis = await documentIntelligence.analyzeDocument(
        filePath: '/test/large.txt',
        content: largeContent,
      );

      expect(analysis.fileSize, equals(100 * 1024));
      expect(analysis.metadata['content_length'], equals(100 * 1024));
      expect(analysis.metadata['word_count'], equals(1)); // Single long "word"
    });

    test('should handle documents with special characters', () async {
      const specialContent = 'Content with émojis 🎉 and spëcial chärs 中文';

      final analysis = await documentIntelligence.analyzeDocument(
        filePath: '/test/special.txt',
        content: specialContent,
      );

      expect(analysis.metadata['encoding'], equals('utf-8'));
      expect(analysis.metadata['content_length'], equals(specialContent.length));
    });

    test('should analyze sensitivity without AI', () async {
      const testContent = '''
      This document contains sensitive information.
      Email: user@example.com
      SSN: 123-45-6789
      Credit Card: 4111-1111-1111-1111
      ''';

      final sensitivity = await documentIntelligence.analyzeSensitivity(testContent);

      expect(sensitivity, isNotNull);
      expect(sensitivity.contentLength, equals(testContent.length));
      expect(sensitivity.containsPII, isTrue);
      expect(sensitivity.containsFinancial, isTrue);
      expect(sensitivity.containsHealth, isFalse);
      expect(sensitivity.sensitivityLevel, equals('high'));
    });

    test('should detect PII patterns', () async {
      // Test email detection
      const emailContent = 'Contact: user@test.com';
      final emailAnalysis = await documentIntelligence.analyzeSensitivity(emailContent);
      expect(emailAnalysis.containsPII, isTrue);

      // Test SSN detection
      const ssnContent = 'SSN: 123-45-6789';
      final ssnAnalysis = await documentIntelligence.analyzeSensitivity(ssnContent);
      expect(ssnAnalysis.containsPII, isTrue);

      // Test phone detection
      const phoneContent = 'Phone: 555-123-4567';
      final phoneAnalysis = await documentIntelligence.analyzeSensitivity(phoneContent);
      expect(phoneAnalysis.containsPII, isTrue);
    });

    test('should detect financial data', () async {
      const financialContent = '''
      Account balance: $1,234.56
      Transaction amount: 500.00 USD
      Account number: ACC-123456789
      ''';

      final analysis = await documentIntelligence.analyzeSensitivity(financialContent);

      expect(analysis.containsFinancial, isTrue);
      expect(analysis.containsPII, isFalse);
      expect(analysis.sensitivityLevel, equals('high'));
    });

    test('should handle non-sensitive content', () async {
      const normalContent = '''
      This is a normal document with regular content.
      It talks about general topics and has no sensitive information.
      Just regular text that should not trigger any warnings.
      ''';

      final analysis = await documentIntelligence.analyzeSensitivity(normalContent);

      expect(analysis.containsPII, isFalse);
      expect(analysis.containsFinancial, isFalse);
      expect(analysis.containsHealth, isFalse);
      expect(analysis.sensitivityLevel, equals('low'));
    });

    test('should generate organization suggestions', () async {
      // Create mock analyses
      final analyses = [
        DocumentAnalysis(
          filePath: '/docs/manual.pdf',
          fileName: 'manual.pdf',
          mimeType: 'application/pdf',
          fileSize: 1024000,
          analyzedAt: DateTime.now(),
          aiInsights: {'document_type': 'documentation', 'categories': ['manual', 'guide']},
        ),
        DocumentAnalysis(
          filePath: '/reports/quarterly.xlsx',
          fileName: 'quarterly.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          fileSize: 512000,
          analyzedAt: DateTime.now(),
          aiInsights: {'document_type': 'report', 'categories': ['financial', 'quarterly']},
        ),
        DocumentAnalysis(
          filePath: '/images/logo.png',
          fileName: 'logo.png',
          mimeType: 'image/png',
          fileSize: 256000,
          analyzedAt: DateTime.now(),
          aiInsights: {'document_type': 'image', 'categories': ['logo', 'brand']},
        ),
      ];

      final suggestions = await documentIntelligence.generateOrganizationSuggestions(analyses);

      expect(suggestions, isNotNull);
      expect(suggestions.totalDocuments, equals(3));
      expect(suggestions.folderStructure, isNotNull);
      expect(suggestions.tagSuggestions, isNotNull);
      expect(suggestions.tagSuggestions.contains('manual'), isTrue);
      expect(suggestions.tagSuggestions.contains('financial'), isTrue);
      expect(suggestions.tagSuggestions.contains('logo'), isTrue);
    });

    test('should generate search suggestions', () async {
      final analyses = [
        DocumentAnalysis(
          filePath: '/docs/api.txt',
          fileName: 'api.txt',
          mimeType: 'text/plain',
          fileSize: 5000,
          analyzedAt: DateTime.now(),
          aiInsights: {'summary': 'API documentation for the system'},
        ),
      ];

      const query = 'api documentation';
      final suggestions = await documentIntelligence.generateSearchSuggestions(query, analyses);

      expect(suggestions, isNotNull);
      expect(suggestions.isNotEmpty, isTrue);
      // Since AI is disabled in tests, it should return basic suggestions
      expect(suggestions.first, isA<String>());
    });

    test('should handle caching', () async {
      const testContent = 'Test content for caching';
      const filePath = '/test/cache.txt';

      // First analysis
      final analysis1 = await documentIntelligence.analyzeDocument(
        filePath: filePath,
        content: testContent,
      );

      // Second analysis (should use cache if enabled)
      final analysis2 = await documentIntelligence.analyzeDocument(
        filePath: filePath,
        content: testContent,
      );

      expect(analysis1.filePath, equals(analysis2.filePath));
      expect(analysis1.fileSize, equals(analysis2.fileSize));
      expect(analysis1.metadata['content_length'], equals(analysis2.metadata['content_length']));
    });

    test('should handle concurrent analysis requests', () async {
      final requests = List.generate(5, (i) => documentIntelligence.analyzeDocument(
        filePath: '/test/concurrent_$i.txt',
        content: 'Content for concurrent test $i',
      ));

      final results = await Future.wait(requests);

      expect(results.length, equals(5));
      for (final result in results) {
        expect(result, isNotNull);
        expect(result.fileSize, greaterThan(0));
      }
    });

    test('should handle malformed content gracefully', () async {
      const malformedContent = 'Content with null bytes: \x00\x01\x02';

      final analysis = await documentIntelligence.analyzeDocument(
        filePath: '/test/malformed.txt',
        content: malformedContent,
      );

      expect(analysis, isNotNull);
      expect(analysis.metadata['content_length'], equals(malformedContent.length));
    });

    test('should clean data with various rules', () async {
      const testInput = '  Test input with <script>alert("xss")</script> extra spaces  ';

      final result = documentIntelligence.cleanData(testInput, validationRules: ['no_xss']);

      expect(result.isValid, isFalse); // Should fail XSS validation
      expect(result.cleanedData, isNotNull);
      expect(result.validationErrors.isNotEmpty, isTrue);
    });

    test('should validate user input', () async {
      const safeInput = 'This is safe input';
      const unsafeInput = '<script>alert("xss")</script>';

      final safeResult = documentIntelligence.validateUserInput(safeInput);
      final unsafeResult = documentIntelligence.validateUserInput(unsafeInput);

      expect(safeResult.isValid, isTrue);
      expect(safeResult.securityViolations.isEmpty, isTrue);

      expect(unsafeResult.isValid, isFalse);
      expect(unsafeResult.securityViolations.isNotEmpty, isTrue);
    });

    test('should handle API validation', () async {
      final validRequest = {
        'email': 'user@example.com',
        'name': 'John Doe',
        'age': 25,
      };

      final invalidRequest = {
        'email': 'invalid-email',
        'name': '',
        'age': 'not-a-number',
      };

      final fieldValidations = {
        'email': ['email'],
        'name': ['no_xss'],
        'age': ['no_sql_injection'],
      };

      final validResult = documentIntelligence.validateApiRequest(validRequest, fieldValidations: fieldValidations);
      final invalidResult = documentIntelligence.validateApiRequest(invalidRequest, fieldValidations: fieldValidations);

      expect(validResult.isValid, isTrue);
      expect(validResult.fieldErrors.isEmpty, isTrue);

      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.fieldErrors.isNotEmpty, isTrue);
    });

    test('should detect language', () async {
      const englishText = 'Hello world, this is a test document in English.';
      const spanishText = 'Hola mundo, este es un documento de prueba en español.';

      final englishLang = await documentIntelligence.detectLanguage(englishText);
      final spanishLang = await documentIntelligence.detectLanguage(spanishText);

      expect(englishLang, isNotNull);
      expect(spanishLang, isNotNull);
      // In test environment without AI, these will return default values
      expect(englishLang, isA<String>());
      expect(spanishLang, isA<String>());
    });

    test('should handle dispose correctly', () async {
      expect(documentIntelligence.isInitialized, isTrue);

      await documentIntelligence.dispose();

      // After dispose, the service should not be initialized
      expect(documentIntelligence.isInitialized, isFalse);
    });

    test('should provide supported languages', () async {
      final languages = documentIntelligence.getSupportedLanguages();

      expect(languages, isNotNull);
      expect(languages.isNotEmpty, isTrue);
      expect(languages.containsKey('en'), isTrue);
      expect(languages['en'], equals('English'));
    });

    test('should generate translation statistics', () async {
      final stats = documentIntelligence.getTranslationStatistics();

      expect(stats, isNotNull);
      expect(stats.totalTranslations, equals(0)); // No translations in test
      expect(stats.uniqueLanguagePairs, equals(0));
      expect(stats.averageConfidence, equals(0.0));
    });
  });
}
