import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../providers/analytics_provider.dart';
import '../../../core/utils.dart';

class AdvancedAnalyticsDashboard extends StatefulWidget {
  const AdvancedAnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<AdvancedAnalyticsDashboard> createState() =>
      _AdvancedAnalyticsDashboardState();
}

class _AdvancedAnalyticsDashboardState extends State<AdvancedAnalyticsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _chartAnimationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Advanced Analytics'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _refreshData(provider),
                tooltip: 'Refresh Data',
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _exportData(provider),
                tooltip: 'Export Report',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettings(context, provider),
                tooltip: 'Settings',
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Metrics Overview
                  _buildMetricsOverview(context, provider),
                  const SizedBox(height: 24),

                  // Charts Section
                  _buildChartsSection(context, provider),
                  const SizedBox(height: 24),

                  // Insights Section
                  _buildInsightsSection(context, provider),
                  const SizedBox(height: 24),

                  // Predictions Section
                  _buildPredictionsSection(context, provider),
                  const SizedBox(height: 24),

                  // Detailed Analytics
                  _buildDetailedAnalytics(context, provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsOverview(
      BuildContext context, AnalyticsProvider provider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Metrics Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: _getCrossAxisCount(context),
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                context,
                'Productivity Score',
                '${provider.productivityScore.toStringAsFixed(1)}%',
                _getProductivityColor(provider.productivityScore),
                Icons.trending_up,
                provider.productivityTrend,
              ),
              _buildMetricCard(
                context,
                'Tasks Completed',
                '${provider.tasksCompleted}',
                Colors.blue,
                Icons.task_alt,
                provider.tasksCompletedTrend,
              ),
              _buildMetricCard(
                context,
                'Active Hours',
                '${provider.activeHours.toStringAsFixed(1)}h',
                Colors.green,
                Icons.access_time,
                provider.activeHoursTrend,
              ),
              _buildMetricCard(
                context,
                'Focus Time',
                '${provider.focusTime.toStringAsFixed(1)}h',
                Colors.orange,
                Icons.center_focus_strong,
                provider.focusTimeTrend,
              ),
              _buildMetricCard(
                context,
                'Goal Progress',
                '${provider.goalProgress.toStringAsFixed(1)}%',
                _getGoalColor(provider.goalProgress),
                Icons.flag,
                provider.goalProgressTrend,
              ),
              _buildMetricCard(
                context,
                'Efficiency',
                '${provider.efficiency.toStringAsFixed(1)}%',
                Colors.purple,
                Icons.speed,
                provider.efficiencyTrend,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
    Trend trend,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Icon(
                  _getTrendIcon(trend),
                  color: _getTrendColor(trend),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visual Analytics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Charts Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 1.2,
          children: [
            // Productivity Chart
            _buildProductivityChart(context, provider),

            // Task Distribution Chart
            _buildTaskDistributionChart(context, provider),

            // Time Analysis Chart
            _buildTimeAnalysisChart(context, provider),

            // Goal Progress Chart
            _buildGoalProgressChart(context, provider),
          ],
        ),
      ],
    );
  }

  Widget _buildProductivityChart(
      BuildContext context, AnalyticsProvider provider) {
    final data = provider.getProductivityData();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productivity Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FadeTransition(
                opacity: _chartAnimation,
                child: LineChart(
                  charts.LineChart(
                    [
                      charts.Series<ProductivityData, String>(
                        id: 'Productivity',
                        color: charts.ColorUtil.fromDartColor(
                            Theme.of(context).colorScheme.primary),
                        domainFn: (data, _) => data.date,
                        measureFn: (data, _) => data.score,
                        data: data,
                      ),
                    ],
                    animate: false,
                    primaryMeasureAxis: charts.NumericAxisSpec(
                      renderSpec: charts.SmallTickRendererSpec(
                        labelStyle: charts.TextStyleSpec(
                          fontSize: 10,
                        ),
                      ),
                    ),
                    domainAxis: charts.OrdinalAxisSpec(
                      renderSpec: charts.SmallTickRendererSpec(
                        labelStyle: charts.TextStyleSpec(
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDistributionChart(
      BuildContext context, AnalyticsProvider provider) {
    final data = provider.getTaskDistributionData();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FadeTransition(
                opacity: _chartAnimation,
                child: PieChart(
                  charts.PieChart(
                    [
                      charts.Series<TaskDistributionData, String>(
                        id: 'Tasks',
                        colorFn: (data, _) =>
                            charts.ColorUtil.fromDartColor(data.color),
                        domainFn: (data, _) => data.category,
                        measureFn: (data, _) => data.count,
                        data: data,
                        labelAccessorFn: (data, _) =>
                            '${data.category}: ${data.count}',
                      ),
                    ],
                    animate: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAnalysisChart(
      BuildContext context, AnalyticsProvider provider) {
    final data = provider.getTimeAnalysisData();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FadeTransition(
                opacity: _chartAnimation,
                child: BarChart(
                  charts.BarChart(
                    [
                      charts.Series<TimeAnalysisData, String>(
                        id: 'Time',
                        color: charts.ColorUtil.fromDartColor(
                            Theme.of(context).colorScheme.secondary),
                        domainFn: (data, _) => data.category,
                        measureFn: (data, _) => data.hours,
                        data: data,
                      ),
                    ],
                    animate: false,
                    vertical: false,
                    barRendererDecorator: charts.BarLabelDecorator(
                      labelPosition: charts.BarLabelPosition.outside,
                    ),
                    domainAxis: charts.OrdinalAxisSpec(
                      renderSpec: charts.SmallTickRendererSpec(
                        labelStyle: charts.TextStyleSpec(
                          fontSize: 10,
                        ),
                      ),
                    ),
                    primaryMeasureAxis: charts.NumericAxisSpec(
                      renderSpec: charts.SmallTickRendererSpec(
                        labelStyle: charts.TextStyleSpec(
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressChart(
      BuildContext context, AnalyticsProvider provider) {
    final data = provider.getGoalProgressData();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FadeTransition(
                opacity: _chartAnimation,
                child: BarChart(
                  charts.BarChart(
                    [
                      charts.Series<GoalProgressData, String>(
                        id: 'Goals',
                        color: charts.ColorUtil.fromDartColor(
                            Theme.of(context).colorScheme.tertiary),
                        domainFn: (data, _) => data.name,
                        measureFn: (data, _) => data.progress,
                        data: data,
                      ),
                    ],
                    animate: false,
                    vertical: false,
                    barRendererDecorator: charts.BarLabelDecorator(
                      labelPosition: charts.BarLabelPosition.inside,
                      labelStyle: charts.TextStyleSpec(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    domainAxis: charts.OrdinalAxisSpec(
                      renderSpec: charts.SmallTickRendererSpec(
                        labelStyle: charts.TextStyleSpec(
                          fontSize: 10,
                        ),
                      ),
                    ),
                    primaryMeasureAxis: charts.NumericAxisSpec(
                      renderSpec: charts.SmallTickRendererSpec(
                        labelStyle: charts.TextStyleSpec(
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(
      BuildContext context, AnalyticsProvider provider) {
    final insights = provider.getInsights();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Insights',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: insights.length,
          itemBuilder: (context, index) {
            final insight = insights[index];
            return _buildInsightCard(context, insight);
          },
        ),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context, AnalyticsInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getInsightColor(insight.type),
          child: Icon(
            _getInsightIcon(insight.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(insight.title),
        subtitle: Text(insight.description),
        trailing: Text(
          insight.priority.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getInsightColor(insight.type),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildPredictionsSection(
      BuildContext context, AnalyticsProvider provider) {
    final predictions = provider.getPredictions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Predictions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            final prediction = predictions[index];
            return _buildPredictionCard(context, prediction);
          },
        ),
      ],
    );
  }

  Widget _buildPredictionCard(BuildContext context, Prediction prediction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPredictionIcon(prediction.type),
                  color: _getPredictionColor(prediction.type),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        'Confidence: ${(prediction.confidence * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getPredictionColor(prediction.type),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              prediction.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (prediction.actionable) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _executePrediction(context, prediction),
                icon: Icon(_getPredictionActionIcon(prediction.type)),
                label: Text(_getPredictionActionText(prediction.type)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getPredictionColor(prediction.type),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalytics(
      BuildContext context, AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Analytics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Detailed Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 2.0,
          children: [
            _buildDetailCard(
              context,
              'Weekly Performance',
              '${provider.weeklyPerformance}% improvement',
              Icons.trending_up,
              Colors.green,
            ),
            _buildDetailCard(
              context,
              'Peak Productivity',
              provider.peakProductivityTime,
              Icons.access_time,
              Colors.blue,
            ),
            _buildDetailCard(
              context,
              'Task Completion Rate',
              '${provider.taskCompletionRate}%',
              Icons.task_alt,
              Colors.orange,
            ),
            _buildDetailCard(
              context,
              'Average Task Duration',
              provider.averageTaskDuration,
              Icons.timer,
              Colors.purple,
            ),
            _buildDetailCard(
              context,
              'Most Productive Day',
              provider.mostProductiveDay,
              Icons.calendar_today,
              Colors.red,
            ),
            _buildDetailCard(
              context,
              'Focus Sessions',
              '${provider.focusSessions}',
              Icons.center_focus_strong,
              Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }

  Color _getProductivityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getGoalColor(double progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 60) return Colors.blue;
    if (progress >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getTrendIcon(Trend trend) {
    switch (trend) {
      case Trend.up:
        return Icons.trending_up;
      case Trend.down:
        return Icons.trending_down;
      case Trend.stable:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(Trend trend) {
    switch (trend) {
      case Trend.up:
        return Colors.green;
      case Trend.down:
        return Colors.red;
      case Trend.stable:
        return Colors.grey;
    }
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.productivity:
        return Colors.blue;
      case InsightType.timeManagement:
        return Colors.green;
      case InsightType.task:
        return Colors.orange;
      case InsightType.goal:
        return Colors.purple;
      case InsightType.warning:
        return Colors.red;
      case InsightType.info:
        return Colors.grey;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.productivity:
        return Icons.trending_up;
      case InsightType.timeManagement:
        return Icons.schedule;
      case InsightType.task:
        return Icons.task;
      case InsightType.goal:
        return Icons.flag;
      case InsightType.warning:
        return Icons.warning;
      case InsightType.info:
        return Icons.info;
    }
  }

  Color _getPredictionColor(PredictionType type) {
    switch (type) {
      case PredictionType.productivity:
        return Colors.blue;
      case PredictionType.taskCompletion:
        return Colors.green;
      case PredictionType.timeOptimization:
        return Colors.orange;
      case PredictionType.goalAchievement:
        return Colors.purple;
      case PredictionType.risk:
        return Colors.red;
    }
  }

  IconData _getPredictionIcon(PredictionType type) {
    switch (type) {
      case PredictionType.productivity:
        return Icons.trending_up;
      case PredictionType.taskCompletion:
        return Icons.task_alt;
      case PredictionType.timeOptimization:
        return Icons.schedule;
      case PredictionType.goalAchievement:
        return Icons.flag;
      case PredictionType.risk:
        return Icons.warning;
    }
  }

  String _getPredictionActionText(PredictionType type) {
    switch (type) {
      case PredictionType.productivity:
        return 'Optimize';
      case PredictionType.taskCompletion:
        return 'Complete';
      case PredictionType.timeOptimization:
        return 'Adjust Schedule';
      case PredictionType.goalAchievement:
        return 'Celebrate';
      case PredictionType.risk:
        return 'Address';
    }
  }

  IconData _getPredictionActionIcon(PredictionType type) {
    switch (type) {
      case PredictionType.productivity:
        return Icons.speed;
      case PredictionType.taskCompletion:
        return Icons.check_circle;
      case PredictionType.timeOptimization:
        return Icons.schedule;
      case PredictionType.goalAchievement:
        return Icons.celebration;
      case PredictionType.risk:
        return Icons.warning;
    }
  }

  // Action Methods
  Future<void> _refreshData(AnalyticsProvider provider) async {
    await provider.refreshData();
  }

  Future<void> _exportData(AnalyticsProvider provider) async {
    await provider.exportReport();
  }

  void _showSettings(BuildContext context, AnalyticsProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics Settings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Auto-refresh'),
                subtitle: const Text('Automatically refresh analytics data'),
                value: provider.autoRefresh,
                onChanged: (value) => provider.setAutoRefresh(value),
              ),
              SwitchListTile(
                title: const Text('Show Predictions'),
                subtitle: const Text('Display AI-powered predictions'),
                value: provider.showPredictions,
                onChanged: (value) => provider.setShowPredictions(value),
              ),
              SwitchListTile(
                title: const Text('Enable Insights'),
                subtitle: const Text('Show AI-generated insights'),
                value: provider.showInsights,
                onChanged: (value) => provider.setShowInsights(value),
              ),
              ListTile(
                title: const Text('Export Format'),
                subtitle: Text(provider.exportFormat),
                trailing: DropdownButton<String>(
                  value: provider.exportFormat,
                  onChanged: (value) => provider.setExportFormat(value),
                  items: const ['JSON', 'CSV', 'PDF'],
                ),
              ),
              ListTile(
                title: const Text('Refresh Interval'),
                subtitle: Text(provider.refreshInterval.inMinutes.toString()),
                trailing: DropdownButton<int>(
                  value: provider.refreshInterval.inMinutes,
                  onChanged: (value) =>
                      provider.setRefreshInterval(Duration(minutes: value)),
                  items: [1, 5, 10, 15, 30, 60],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _executePrediction(BuildContext context, Prediction prediction) {
    // Execute prediction action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: 'Executing prediction: ${prediction.title}',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {},
        ),
      ),
    );
  }
}

// Data Models
class ProductivityData {
  final String date;
  final double score;

  ProductivityData({required this.date, required this.score});
}

class TaskDistributionData {
  final String category;
  final int count;
  final Color color;

  TaskDistributionData({
    required this.category,
    required this.count,
    required this.color,
  });
}

class TimeAnalysisData {
  final String category;
  final double hours;

  TimeAnalysisData({required this.category, required this.hours});
}

class GoalProgressData {
  final String name;
  final double progress;

  GoalProgressData({required this.name, required this.progress});
}

class AnalyticsInsight {
  final InsightType type;
  final String title;
  final String description;
  final InsightPriority priority;

  AnalyticsInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
  });
}

class Prediction {
  final PredictionType type;
  final String title;
  final String description;
  final double confidence;
  final bool actionable;
  final Map<String, dynamic>? data;

  Prediction({
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    this.actionable = true,
    this.data,
  });
}

// Enums
enum Trend { up, down, stable }

enum InsightType { productivity, timeManagement, task, goal, warning, info }

enum InsightPriority { low, medium, high, critical }

enum PredictionType {
  productivity,
  taskCompletion,
  timeOptimization,
  goalAchievement,
  risk
}

class FadeTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> opacity;
  final Duration duration;
  final Curve curve;

  const FadeTransition({
    Key? key,
    required this.child,
    required this.opacity,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: duration,
      curve: curve,
      child: child,
    );
  }
}
