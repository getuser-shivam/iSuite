import 'package:github/github.dart';
import '../../core/ai_enhanced_service.dart';

class GitHubService {
  GitHub? _github;
  final AIEnhancedService _aiService = AIEnhancedService();

  void authenticate(String token) {
    _github = GitHub(auth: Authentication.withToken(token));
  }

  Future<List<RepositoryCommit>> getCommitHistory(String owner, String repo, {int perPage = 30}) async {
    if (_github == null) throw Exception('Not authenticated');

    final slug = RepositorySlug(owner, repo);
    final commits = await _github!.repositories.listCommits(slug).toList();
    return commits;
  }

  Future<String> analyzeCommits(List<RepositoryCommit> commits) async {
    // Basic analysis
    final analysis = StringBuffer();
    analysis.writeln('# GitHub History Analysis');
    analysis.writeln('Total commits: ${commits.length}');
    
    final authors = <String, int>{};
    final dates = <DateTime>[];
    
    for (final commit in commits) {
      final author = commit.author?.login ?? 'Unknown';
      authors[author] = (authors[author] ?? 0) + 1;
      if (commit.commit?.committer?.date != null) {
        dates.add(commit.commit!.committer!.date!);
      }
    }
    
    analysis.writeln('## Authors:');
    authors.forEach((author, count) {
      analysis.writeln('- $author: $count commits');
    });
    
    if (dates.isNotEmpty) {
      dates.sort();
      analysis.writeln('Date range: ${dates.first} to ${dates.last}');
    }

    // AI-enhanced analysis
    try {
      final aiAnalysis = await _generateAIAnalysis(commits, authors, dates);
      analysis.writeln('\n## AI-Enhanced Insights:');
      analysis.writeln(aiAnalysis);
    } catch (e) {
      analysis.writeln('\n## AI Analysis: Failed to generate (${e.toString()})');
    }
    
    return analysis.toString();
  }

  Future<String> _generateAIAnalysis(List<RepositoryCommit> commits, Map<String, int> authors, List<DateTime> dates) async {
    // Prepare commit messages for AI analysis
    final commitMessages = commits.take(10).map((c) => c.commit?.message ?? '').join('\n');
    
    const prompt = '''
Analyze this GitHub repository's recent commit history and provide insights:

Commit Messages (last 10):
{messages}

Authors: {authors}
Total Commits: {total}
Date Range: {range}

Provide a brief analysis including:
- Main development focus
- Team collaboration patterns
- Code quality indicators
- Recommendations for improvement

Keep it concise (200 words max).
''';

    final analysisPrompt = prompt
        .replaceAll('{messages}', commitMessages)
        .replaceAll('{authors}', authors.keys.join(', '))
        .replaceAll('{total}', commits.length.toString())
        .replaceAll('{range}', dates.isNotEmpty ? '${dates.first} to ${dates.last}' : 'Unknown');

    return await _aiService.generateContent(analysisPrompt);
  }

  Future<void> updateReadme(String owner, String repo, String newContent) async {
    if (_github == null) throw Exception('Not authenticated');

    final slug = RepositorySlug(owner, repo);
    
    // Get current README
    final readme = await _github!.repositories.getContents(slug, 'README.md');
    final sha = readme.file?.sha;
    
    if (sha != null) {
      // Update README
      await _github!.repositories.updateFile(
        slug,
        'README.md',
        'Update README with AI-enhanced analysis',
        newContent,
        sha,
      );
    }
  }

  Future<void> commitAndPush(String owner, String repo, String message) async {
    // For simplicity, assume changes are already staged locally
    // In a real implementation, this would require git commands or more API calls
    // For now, just update a file as example
    await updateReadme(owner, repo, 'Committed via iSuite AI-enhanced workflow\n$message');
  }

  /// AI-powered commit message generation
  Future<String> generateCommitMessage(String changes) async {
    const prompt = '''
Generate a concise, meaningful commit message for these changes:

Changes: {changes}

Follow conventional commit format. Keep it under 72 characters.
''';

    final messagePrompt = prompt.replaceAll('{changes}', changes);
    return await _aiService.generateContent(messagePrompt);
  }

  /// AI-powered code review suggestions
  Future<List<String>> generateCodeReviewSuggestions(String code) async {
    const prompt = '''
Review this code and provide 3 improvement suggestions:

Code:
{code}

Focus on:
1. Code quality and best practices
2. Performance optimizations  
3. Security considerations

Return as numbered list.
''';

    final reviewPrompt = prompt.replaceAll('{code}', code);
    final response = await _aiService.generateContent(reviewPrompt);
    
    // Parse suggestions
    final lines = response.split('\n');
    return lines.where((line) => line.trim().isNotEmpty && RegExp(r'^\d+\.').hasMatch(line))
        .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*'), ''))
        .take(3)
        .toList();
  }
}
