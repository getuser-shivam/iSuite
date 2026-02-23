import 'package:flutter/material.dart';
import '../../core/ui/ui_config_service.dart';
import 'github_service.dart';

class GitHubIntegrationScreen extends StatefulWidget {
  const GitHubIntegrationScreen({super.key});

  @override
  State<GitHubIntegrationScreen> createState() => _GitHubIntegrationScreenState();
}

class _GitHubIntegrationScreenState extends State<GitHubIntegrationScreen> {
  final _githubService = GitHubService();
  final _uiConfig = UIConfigService();
  final _tokenController = TextEditingController();
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  String _analysis = '';
  bool _isAuthenticated = false;

  void _authenticate() {
    if (_tokenController.text.isNotEmpty) {
      _githubService.authenticate(_tokenController.text);
      setState(() {
        _isAuthenticated = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authenticated successfully')),
      );
    }
  }

  Future<void> _readHistory() async {
    if (!_isAuthenticated) return;

    try {
      final commits = await _githubService.getCommitHistory(
        _ownerController.text,
        _repoController.text,
      );
      final analysis = await _githubService.analyzeCommits(commits);
      setState(() {
        _analysis = analysis;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateReadme() async {
    if (!_isAuthenticated) return;

    try {
      await _githubService.updateReadme(
        _ownerController.text,
        _repoController.text,
        _analysis,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('README updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _commitAndPush() async {
    if (!_isAuthenticated) return;

    try {
      await _githubService.commitAndPush(
        _ownerController.text,
        _repoController.text,
        'Automated commit from iSuite',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Committed and pushed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GitHub Integration',
          style: TextStyle(
            fontSize: _uiConfig.getDouble('ui.font_size') + 2,
            fontWeight: FontWeight.bold,
            color: _uiConfig.getColor('ui.on_primary'),
          ),
        ),
        backgroundColor: _uiConfig.getColor('ui.primary_color'),
      ),
      body: Padding(
        padding: EdgeInsets.all(_uiConfig.getDouble('ui.padding')),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'GitHub Personal Access Token',
                  labelStyle: TextStyle(
                    fontSize: _uiConfig.getDouble('ui.font_size'),
                    color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
                  ),
                ),
                obscureText: true,
                style: TextStyle(
                  fontSize: _uiConfig.getDouble('ui.font_size'),
                  color: _uiConfig.getColor('ui.on_surface'),
                ),
              ),
              SizedBox(height: _uiConfig.getDouble('ui.padding')),
              ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _uiConfig.getColor('ui.primary_color'),
                  foregroundColor: _uiConfig.getColor('ui.on_primary'),
                  padding: EdgeInsets.symmetric(
                    horizontal: _uiConfig.getDouble('ui.padding') * 2,
                    vertical: _uiConfig.getDouble('ui.padding'),
                  ),
                ),
                child: Text(
                  'Authenticate',
                  style: TextStyle(
                    fontSize: _uiConfig.getDouble('ui.font_size'),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isAuthenticated) ...[
                SizedBox(height: _uiConfig.getDouble('ui.padding')),
                TextField(
                  controller: _ownerController,
                  decoration: InputDecoration(
                    labelText: 'Repository Owner',
                    labelStyle: TextStyle(
                      fontSize: _uiConfig.getDouble('ui.font_size'),
                      color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: _uiConfig.getDouble('ui.font_size'),
                    color: _uiConfig.getColor('ui.on_surface'),
                  ),
                ),
                SizedBox(height: _uiConfig.getDouble('ui.padding')),
                TextField(
                  controller: _repoController,
                  decoration: InputDecoration(
                    labelText: 'Repository Name',
                    labelStyle: TextStyle(
                      fontSize: _uiConfig.getDouble('ui.font_size'),
                      color: _uiConfig.getColor('ui.on_surface').withOpacity(0.7),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: _uiConfig.getDouble('ui.font_size'),
                    color: _uiConfig.getColor('ui.on_surface'),
                  ),
                ),
                SizedBox(height: _uiConfig.getDouble('ui.padding')),
                ElevatedButton(
                  onPressed: _readHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _uiConfig.getColor('ui.primary_color'),
                    foregroundColor: _uiConfig.getColor('ui.on_primary'),
                    padding: EdgeInsets.symmetric(
                      horizontal: _uiConfig.getDouble('ui.padding') * 2,
                      vertical: _uiConfig.getDouble('ui.padding'),
                    ),
                  ),
                  child: Text(
                    'Read History & Analyze',
                    style: TextStyle(
                      fontSize: _uiConfig.getDouble('ui.font_size'),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_analysis.isNotEmpty) ...[
                  SizedBox(height: _uiConfig.getDouble('ui.padding')),
                  Text(
                    'Analysis:',
                    style: TextStyle(
                      fontSize: _uiConfig.getDouble('ui.font_size') + 2,
                      fontWeight: FontWeight.bold,
                      color: _uiConfig.getColor('ui.on_surface'),
                    ),
                  ),
                  SizedBox(height: _uiConfig.getDouble('ui.padding') / 2),
                  Text(
                    _analysis,
                    style: TextStyle(
                      fontSize: _uiConfig.getDouble('ui.font_size'),
                      color: _uiConfig.getColor('ui.on_surface'),
                    ),
                  ),
                  SizedBox(height: _uiConfig.getDouble('ui.padding')),
                  ElevatedButton(
                    onPressed: _updateReadme,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _uiConfig.getColor('ui.secondary_color'),
                      foregroundColor: _uiConfig.getColor('ui.on_secondary'),
                      padding: EdgeInsets.symmetric(
                        horizontal: _uiConfig.getDouble('ui.padding') * 2,
                        vertical: _uiConfig.getDouble('ui.padding'),
                      ),
                    ),
                    child: Text(
                      'Update README',
                      style: TextStyle(
                        fontSize: _uiConfig.getDouble('ui.font_size'),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: _uiConfig.getDouble('ui.padding') / 2),
                  ElevatedButton(
                    onPressed: _commitAndPush,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _uiConfig.getColor('ui.accent_color'),
                      foregroundColor: _uiConfig.getColor('ui.on_accent'),
                      padding: EdgeInsets.symmetric(
                        horizontal: _uiConfig.getDouble('ui.padding') * 2,
                        vertical: _uiConfig.getDouble('ui.padding'),
                      ),
                    ),
                    child: Text(
                      'Commit & Push',
                      style: TextStyle(
                        fontSize: _uiConfig.getDouble('ui.font_size'),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
