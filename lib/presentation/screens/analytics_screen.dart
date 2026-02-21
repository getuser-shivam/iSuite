import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils.dart';
import '../../domain/models/analytics.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsProvider _analyticsProvider;

  @override
  void initState() {
    super.initState();
    _analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Analytics Dashboard'),
          actions: [
            PopupMenuButton<TimePeriod>(
              onSelected: (period) => _analyticsProvider.setTimePeriod(period),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: TimePeriod.today,
                  child: Text('Today'),
                ),
                const PopupMenuItem(
                  value: TimePeriod.week,
                  child: Text('This Week'),
                ),
                const PopupMenuItem(
                  value: TimePeriod.month,
                  child: Text('This Month'),
                ),
                const PopupMenuItem(
                  value: TimePeriod.quarter,
                  child: Text('This Quarter'),
                ),
                const PopupMenuItem(
                  value: TimePeriod.year,
                  child: Text('This Year'),
                ),
                const PopupMenuItem(
                  value: TimePeriod.all,
                  child: Text('All Time'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(_getPeriodLabel(_analyticsProvider.selectedPeriod)),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => _showExportDialog(context),
              icon: const Icon(Icons.share),
              tooltip: 'Export Analytics',
            ),
            IconButton(
              onPressed: () => _analyticsProvider.refreshAnalytics(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Consumer<AnalyticsProvider>(
          builder: (context, analyticsProvider, child) {
            if (analyticsProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (analyticsProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      analyticsProvider.error!,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => analyticsProvider.refreshAnalytics(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!analyticsProvider.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No data available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => analyticsProvider.refreshAnalytics(),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => analyticsProvider.refreshAnalytics(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummarySection(analyticsProvider),
                    const SizedBox(height: 24),
                    _buildTasksSection(analyticsProvider),
                    const SizedBox(height: 24),
                    _buildNotesSection(analyticsProvider),
                    const SizedBox(height: 24),
                    _buildFilesSection(analyticsProvider),
                    const SizedBox(height: 24),
                    _buildEventsSection(analyticsProvider),
                    const SizedBox(height: 24),
                    _buildTrendsSection(analyticsProvider),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _buildSummarySection(AnalyticsProvider provider) {
    final summary = provider.summaryStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildSummaryCard(
              'Total Items',
              summary['totalItems'].toString(),
              Icons.inventory,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Productivity Score',
              '${summary['productivityScore'].toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.green,
            ),
            _buildSummaryCard(
              'Most Active Category',
              summary['mostActiveCategory'].toString(),
              Icons.category,
              Colors.orange,
            ),
            _buildSummaryCard(
              'Most Used Feature',
              summary['mostUsedFeature'].toString(),
              Icons.star,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTasksSection(AnalyticsProvider provider) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Tasks',
                  provider.totalTasks.toString(),
                  Icons.task,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  provider.completedTasks.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressIndicator(
            'Completion Rate',
            provider.taskCompletionRate / 100,
            '${provider.taskCompletionRate.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 16),
          _buildChartPlaceholder(
              'Task Status Distribution', provider.taskStatusDistribution),
          const SizedBox(height: 16),
          _buildChartPlaceholder(
              'Task Priority Distribution', provider.taskPriorityDistribution),
        ],
      );

  Widget _buildNotesSection(AnalyticsProvider provider) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Notes',
                  provider.totalNotes.toString(),
                  Icons.note,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Word Count',
                  provider.totalWordCount.toString(),
                  Icons.text_fields,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChartPlaceholder(
              'Note Type Distribution', provider.noteTypeDistribution),
          const SizedBox(height: 16),
          _buildChartPlaceholder(
              'Note Status Distribution', provider.noteStatusDistribution),
        ],
      );

  Widget _buildFilesSection(AnalyticsProvider provider) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Files',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Files',
                  provider.totalFiles.toString(),
                  Icons.folder,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Size',
                  provider.formattedTotalFileSize,
                  Icons.storage,
                  Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChartPlaceholder(
              'File Type Distribution', provider.fileTypeDistribution),
        ],
      );

  Widget _buildEventsSection(AnalyticsProvider provider) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendar Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Events',
                  provider.totalEvents.toString(),
                  Icons.event,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Upcoming',
                  provider.upcomingEvents.toString(),
                  Icons.schedule,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChartPlaceholder(
              'Event Type Distribution', provider.eventTypeDistribution),
        ],
      );

  Widget _buildTrendsSection(AnalyticsProvider provider) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trends',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartPlaceholder('Task Completion Trend (Last 30 Days)',
              provider.taskCompletionTrend),
          const SizedBox(height: 16),
          _buildChartPlaceholder(
              'Note Creation Trend (Last 30 Days)', provider.noteCreationTrend),
          const SizedBox(height: 16),
          _buildChartPlaceholder(
              'File Upload Trend (Last 30 Days)', provider.fileUploadTrend),
          const SizedBox(height: 16),
          _buildChartPlaceholder('Event Creation Trend (Last 30 Days)',
              provider.eventCreationTrend),
        ],
      );

  Widget _buildSummaryCard(
          String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildStatCard(
          String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildProgressIndicator(String label, double progress, String value) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.7
                  ? Colors.green
                  : progress > 0.4
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ],
      );

  Widget _buildChartPlaceholder(String title, List<dynamic> data) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (data.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: data.map((point) {
                  if (point is ChartDataPoint) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(point.label),
                          ),
                          Text(
                            point.value.toStringAsFixed(0),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  } else if (point is TimeSeriesData) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            AppUtils.formatDate(point.date),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(point.label),
                          ),
                          Text(
                            point.value.toStringAsFixed(0),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '📊 Chart visualization requires fl_chart package',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return 'Today';
      case TimePeriod.week:
        return 'Week';
      case TimePeriod.month:
        return 'Month';
      case TimePeriod.quarter:
        return 'Quarter';
      case TimePeriod.year:
        return 'Year';
      case TimePeriod.all:
        return 'All';
    }
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final jsonData = await _analyticsProvider.exportAnalyticsAsJson();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Analytics'),
          content: SingleChildScrollView(
            child: SelectableText(jsonData),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Copy to clipboard functionality would require clipboard package
                AppUtils.showSuccessSnackBar(
                    context, 'Analytics data copied to clipboard');
                Navigator.of(context).pop();
              },
              child: const Text('Copy'),
            ),
          ],
        ),
      );
    }
  }
}
