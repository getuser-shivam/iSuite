import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/central_config.dart';

/// AI Service for LLM integration
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  final String _model = 'glm-4-flash';

  bool get isConfigured => _getApiKey() != null;

  String? _getApiKey() {
    // Try to get from environment or config
    final config = CentralConfig.instance;
    return config.getParameter('ai.api_key');
  }

  /// Generate AI response for file management queries
  Future<String> generateResponse(String userQuery, String context) async {
    if (!isConfigured) {
      return _getFallbackResponse(userQuery);
    }

    try {
      final messages = [
        {
          'role': 'system',
          'content': '''You are an intelligent file management assistant for iSuite. 
You help users with file operations, organization, and management tasks.
Provide helpful, concise responses focused on file management.
Context: $context'''
        },
        {
          'role': 'user',
          'content': userQuery
        }
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${_getApiKey()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        return content.isNotEmpty ? content : _getFallbackResponse(userQuery);
      } else {
        print('AI API error: ${response.statusCode} - ${response.body}');
        return _getFallbackResponse(userQuery);
      }
    } catch (e) {
      print('AI service error: $e');
      return _getFallbackResponse(userQuery);
    }
  }

  /// Analyze file content and provide insights
  Future<String> analyzeFileContent(String fileName, String contentType, String content) async {
    if (!isConfigured) {
      return 'AI analysis not available - please configure API key in settings.';
    }

    try {
      final prompt = '''
Analyze this file and provide insights:
File: $fileName
Type: $contentType
Content: ${content.substring(0, 1000)}${content.length > 1000 ? '...' : ''}

Provide:
1. Summary of content
2. Key topics/themes
3. Suggested organization/category
4. Any notable information
''';

      return await generateResponse(prompt, 'File analysis request');
    } catch (e) {
      return 'Unable to analyze file content. Error: $e';
    }
  }

  /// Suggest file organization
  Future<String> suggestOrganization(List<String> fileNames, List<String> fileTypes) async {
    if (!isConfigured) {
      return _getOrganizationFallback(fileNames, fileTypes);
    }

    try {
      final fileList = fileNames.asMap().entries.map((e) => '${e.key + 1}. ${e.value} (${fileTypes[e.key]})').join('\n');
      final prompt = '''
Based on these files, suggest how to organize them:
$fileList

Provide:
1. Recommended folder structure
2. Grouping suggestions
3. Naming conventions
4. Any cleanup recommendations
''';

      return await generateResponse(prompt, 'File organization request');
    } catch (e) {
      return _getOrganizationFallback(fileNames, fileTypes);
    }
  }

  /// Search files with AI understanding
  Future<String> intelligentSearch(String query, List<String> availableFiles) async {
    if (!isConfigured) {
      // Simple text search fallback
      final matches = availableFiles.where((file) =>
        file.toLowerCase().contains(query.toLowerCase())).toList();
      return 'Found ${matches.length} files matching "$query":\n${matches.take(10).join('\n')}';
    }

    try {
      final fileList = availableFiles.take(50).join('\n'); // Limit for API
      final prompt = '''
Search these files for: "$query"

Available files:
$fileList

Return the most relevant files with brief explanations of why they match.
''';

      return await generateResponse(prompt, 'Intelligent file search');
    } catch (e) {
      // Fallback to simple search
      final matches = availableFiles.where((file) =>
        file.toLowerCase().contains(query.toLowerCase())).toList();
      return 'Found ${matches.length} files matching "$query":\n${matches.take(10).join('\n')}';
    }
  }

  String _getFallbackResponse(String query) {
    // Enhanced fallback responses based on query type
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('organize') || lowerQuery.contains('sort')) {
      return 'To organize your files:\n• Create folders by type (Documents, Images, Videos)\n• Use consistent naming\n• Remove duplicates\n• Archive old files\n\nTry the file operations in the File Manager tab!';
    }

    if (lowerQuery.contains('search') || lowerQuery.contains('find')) {
      return 'Use the search bar in File Manager to find files by name or content. You can also filter by recent files or hidden files.';
    }

    if (lowerQuery.contains('cloud') || lowerQuery.contains('sync')) {
      return 'Connect to Google Drive or Dropbox in the Cloud tab to sync your files across devices.';
    }

    if (lowerQuery.contains('backup') || lowerQuery.contains('copy')) {
      return 'Use file operations in File Manager:\n• Select files with the checklist button\n• Choose copy/cut/paste\n• Files are managed locally and can be synced to cloud';
    }

    if (lowerQuery.contains('delete') || lowerQuery.contains('remove')) {
      return '⚠️ Be careful with deletions!\n• Select files in File Manager\n• Use the delete button\n• Confirm the action\n• Deleted files go to system recycle bin';
    }

    return 'I\'m your file management assistant! I can help with:\n• File organization and sorting\n• Search and filtering\n• Cloud sync setup\n• File operations (copy, move, delete)\n• Backup and recovery\n\nTry asking about specific file tasks!';
  }

  String _getOrganizationFallback(List<String> fileNames, List<String> fileTypes) {
    // Analyze file types and suggest organization
    final typeGroups = <String, List<String>>{};

    for (int i = 0; i < fileNames.length; i++) {
      final type = fileTypes[i];
      typeGroups.putIfAbsent(type, () => []).add(fileNames[i]);
    }

    String suggestion = 'Suggested organization:\n\n';

    if (typeGroups.containsKey('PDF Document')) {
      suggestion += '📄 Documents/ → ${typeGroups['PDF Document']!.length} PDFs\n';
    }

    if (typeGroups.containsKey('JPEG Image') || typeGroups.containsKey('PNG Image')) {
      final imageCount = (typeGroups['JPEG Image']?.length ?? 0) + (typeGroups['PNG Image']?.length ?? 0);
      suggestion += '🖼️ Images/ → $imageCount images\n';
    }

    if (typeGroups.containsKey('MP4 Video')) {
      suggestion += '🎥 Videos/ → ${typeGroups['MP4 Video']!.length} videos\n';
    }

    if (typeGroups.containsKey('MP3 Audio')) {
      suggestion += '🎵 Music/ → ${typeGroups['MP3 Audio']!.length} audio files\n';
    }

    suggestion += '\n💡 Tip: Create folders by project, date, or purpose for better organization.';

    return suggestion;
  }
}
