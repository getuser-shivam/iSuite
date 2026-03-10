import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/gradient_card.dart';
import '../../core/widgets/slide_in_animation.dart';
import '../../core/widgets/scale_animation.dart';
import '../../core/widgets/pulse_animation.dart';

/// AI-Powered File Analysis and Organization Page
class AIAnalysisPage extends StatefulWidget {
  const AIAnalysisPage({super.key});

  @override
  State<AIAnalysisPage> createState() => _AIAnalysisPageState();
}

class _AIAnalysisPageState extends State<AIAnalysisPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  Map<String, dynamic> _analysisResults = {};
  List<Map<String, dynamic>> _fileCategories = [];
  List<Map<String, dynamic>> _organizationSuggestions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAnalysisData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeAnalysisData() {
    // Mock AI analysis data - in real app, this would come from ML models
    _analysisResults = {
      'totalFiles': 1247,
      'analyzedFiles': 892,
      'categories': 15,
      'duplicates': 23,
      'largeFiles': 45,
      'unusedFiles': 156,
      'organizationScore': 78,
    };

    _fileCategories = [
      {
        'name': 'Documents',
        'count': 234,
        'size': '2.4 GB',
        'color': Colors.blue
      },
      {'name': 'Images', 'count': 456, 'size': '8.7 GB', 'color': Colors.green},
      {
        'name': 'Videos',
        'count': 89,
        'size': '24.3 GB',
        'color': Colors.orange
      },
      {
        'name': 'Music',
        'count': 167,
        'size': '12.1 GB',
        'color': Colors.purple
      },
      {
        'name': 'Applications',
        'count': 23,
        'size': '3.2 GB',
        'color': Colors.red
      },
      {'name': 'Archives', 'count': 78, 'size': '5.8 GB', 'color': Colors.teal},
    ];

    _organizationSuggestions = [
      {
        'type': 'consolidate',
        'title': 'Consolidate Document Folders',
        'description': 'Merge 5 document folders into organized structure',
        'impact': 'High',
        'files': 89
      },
      {
        'type': 'archive',
        'title': 'Archive Old Photos',
        'description': 'Move photos older than 2 years to archive',
        'impact': 'Medium',
        'files': 234
      },
      {
        'type': 'delete',
        'title': 'Remove Temporary Files',
        'description': 'Delete 156 unused temporary files',
        'impact': 'Low',
        'files': 156
      },
      {
        'type': 'rename',
        'title': 'Standardize Naming',
        'description': 'Apply consistent naming to 67 files',
        'impact': 'Medium',
        'files': 67
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI File Analysis'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
            Tab(text: 'Suggestions', icon: Icon(Icons.lightbulb)),
            Tab(text: 'Insights', icon: Icon(Icons.insights)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCategoriesTab(),
          _buildSuggestionsTab(),
          _buildInsightsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startAIAnalysis,
        icon: _isAnalyzing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.psychology),
        label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Files'),
        backgroundColor:
            _isAnalyzing ? Colors.grey : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analysis Status Card
          SlideInAnimation(
            direction: SlideDirection.fromTop,
            delay: const Duration(milliseconds: 100),
            child: GradientCard(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        PulseAnimation(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.psychology,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Analysis Status',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Intelligent file organization and insights',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_isAnalyzing) ...[
                      LinearProgressIndicator(
                        value: _analysisProgress,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_analysisProgress * 100).toInt()}% Complete',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricItem('Files',
                              _analysisResults['totalFiles'].toString()),
                          _buildMetricItem('Categories',
                              _analysisResults['categories'].toString()),
                          _buildMetricItem('Score',
                              '${_analysisResults['organizationScore']}%'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Stats Grid
          SlideInAnimation(
            direction: SlideDirection.fromBottom,
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Quick Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),

          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildInsightCard(
                context,
                'Duplicates Found',
                _analysisResults['duplicates'].toString(),
                Icons.copy,
                Colors.red,
                '23 duplicate files detected',
              ),
              _buildInsightCard(
                context,
                'Large Files',
                _analysisResults['largeFiles'].toString(),
                Icons.storage,
                Colors.orange,
                'Files over 100MB',
              ),
              _buildInsightCard(
                context,
                'Unused Files',
                _analysisResults['unusedFiles'].toString(),
                Icons.access_time,
                Colors.blue,
                'Not accessed in 6+ months',
              ),
              _buildInsightCard(
                context,
                'Well Organized',
                '${_analysisResults['organizationScore']}%',
                Icons.check_circle,
                Colors.green,
                'Organization score',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activity
          SlideInAnimation(
            direction: SlideDirection.fromBottom,
            delay: const Duration(milliseconds: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent AI Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 16),
                _buildRecentActivity(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File Categories',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-powered file categorization and analysis',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _fileCategories.length,
              itemBuilder: (context, index) {
                final category = _fileCategories[index];
                return SlideInAnimation(
                  direction: SlideDirection.fromLeft,
                  delay: Duration(milliseconds: 100 + (index * 50)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: category['color'].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(category['name']),
                          color: category['color'],
                        ),
                      ),
                      title: Text(category['name']),
                      subtitle: Text(
                          '${category['count']} files • ${category['size']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _viewCategoryFiles(category),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editCategory(category),
                          ),
                        ],
                      ),
                      onTap: () => _viewCategoryDetails(category),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Organization Suggestions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Smart recommendations to optimize your file organization',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _organizationSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _organizationSuggestions[index];
                return SlideInAnimation(
                  direction: SlideDirection.fromRight,
                  delay: Duration(milliseconds: 100 + (index * 100)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      _getSuggestionColor(suggestion['impact'])
                                          .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getSuggestionIcon(suggestion['type']),
                                  color:
                                      _getSuggestionColor(suggestion['impact']),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggestion['title'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      suggestion['description'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      _getSuggestionColor(suggestion['impact'])
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getSuggestionColor(
                                            suggestion['impact'])
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  suggestion['impact'],
                                  style: TextStyle(
                                    color: _getSuggestionColor(
                                        suggestion['impact']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '${suggestion['files']} files affected',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _applySuggestion(suggestion),
                                icon: const Icon(Icons.auto_fix_high, size: 16),
                                label: const Text('Apply'),
                              ),
                              TextButton.icon(
                                onPressed: () => _dismissSuggestion(suggestion),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Dismiss'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Insights & Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deep analysis of your file usage patterns and trends',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInsightSection(
                    'File Usage Patterns',
                    [
                      _buildPatternItem('Most active folder',
                          'Documents/Projects', '89% of recent activity'),
                      _buildPatternItem('Peak usage time', '2-4 PM weekdays',
                          'Highest file operations'),
                      _buildPatternItem('Common file types',
                          'PDF, DOCX, Images', '75% of total files'),
                      _buildPatternItem('Storage growth', '+2.3 GB/month',
                          'Average monthly increase'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInsightSection(
                    'Optimization Opportunities',
                    [
                      _buildPatternItem('Space savings', '3.2 GB available',
                          'Delete unused files'),
                      _buildPatternItem('Duplicate files', '23 sets found',
                          'Consolidate duplicates'),
                      _buildPatternItem('Large files', '45 files >100MB',
                          'Consider compression'),
                      _buildPatternItem('Archive candidates',
                          '156 files unused', 'Move to archive'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInsightSection(
                    'Security Insights',
                    [
                      _buildPatternItem('Shared files', '67 files accessible',
                          'Review permissions'),
                      _buildPatternItem('Backup coverage', '78% backed up',
                          'Increase backup coverage'),
                      _buildPatternItem('Sensitive data', '12 files flagged',
                          'Check for PII'),
                      _buildPatternItem('Access patterns', 'Normal activity',
                          'No unusual access detected'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        AnimatedCounter(
          value:
              int.tryParse(value.replaceAll(',', '').replaceAll('%', '')) ?? 0,
          duration: const Duration(milliseconds: 1500),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return GradientCard(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                AnimatedCounter(
                  value: int.tryParse(value.replaceAll(',', '')) ?? 0,
                  duration: const Duration(milliseconds: 1000),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {
        'action': 'Analyzed 892 files',
        'time': '2m ago',
        'icon': Icons.search,
        'color': Colors.blue
      },
      {
        'action': 'Found 23 duplicates',
        'time': '5m ago',
        'icon': Icons.copy,
        'color': Colors.orange
      },
      {
        'action': 'Generated organization suggestions',
        'time': '8m ago',
        'icon': Icons.lightbulb,
        'color': Colors.green
      },
      {
        'action': 'Completed usage pattern analysis',
        'time': '12m ago',
        'icon': Icons.analytics,
        'color': Colors.purple
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return SlideInAnimation(
          direction: SlideDirection.fromBottom,
          delay: Duration(milliseconds: 500 + (index * 100)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activity['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                activity['icon'],
                color: activity['color'],
                size: 16,
              ),
            ),
            title: Text(activity['action']),
            subtitle: Text(activity['time']),
          ),
        );
      },
    );
  }

  Widget _buildInsightSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildPatternItem(String label, String value, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'documents':
        return Icons.description;
      case 'images':
        return Icons.image;
      case 'videos':
        return Icons.video_library;
      case 'music':
        return Icons.music_note;
      case 'applications':
        return Icons.apps;
      case 'archives':
        return Icons.archive;
      default:
        return Icons.folder;
    }
  }

  Color _getSuggestionColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getSuggestionIcon(String type) {
    switch (type) {
      case 'consolidate':
        return Icons.merge;
      case 'archive':
        return Icons.archive;
      case 'delete':
        return Icons.delete;
      case 'rename':
        return Icons.edit;
      default:
        return Icons.lightbulb;
    }
  }

  void _startAIAnalysis() async {
    if (_isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    // Simulate AI analysis progress
    for (double progress = 0; progress <= 1.0; progress += 0.1) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _analysisProgress = progress);
    }

    setState(() {
      _isAnalyzing = false;
      _analysisProgress = 1.0;
    });

    // Show completion notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'AI analysis completed! Check insights for recommendations.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _viewCategoryFiles(Map<String, dynamic> category) {
    // Navigate to category file view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${category['name']} files...')),
    );
  }

  void _editCategory(Map<String, dynamic> category) {
    // Show category edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${category['name']} category...')),
    );
  }

  void _viewCategoryDetails(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${category['name']} Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Files: ${category['count']}'),
            Text('Total Size: ${category['size']}'),
            const SizedBox(height: 16),
            const Text('AI Analysis:'),
            const Text('• Well organized structure'),
            const Text('• Regular usage patterns'),
            const Text('• Good backup coverage'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _viewCategoryFiles(category);
            },
            child: const Text('View Files'),
          ),
        ],
      ),
    );
  }

  void _applySuggestion(Map<String, dynamic> suggestion) {
    // Apply the organization suggestion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied suggestion: ${suggestion['title']}')),
    );
  }

  void _dismissSuggestion(Map<String, dynamic> suggestion) {
    setState(() {
      _organizationSuggestions.remove(suggestion);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suggestion dismissed')),
    );
  }
}
