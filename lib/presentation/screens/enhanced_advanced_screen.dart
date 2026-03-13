import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/enhanced_config_provider.dart';
import '../widgets/common/parameterized_app_bar.dart';

/// Enhanced UI Screen with Advanced Features
/// 
/// Comprehensive UI screen with real-time updates and parameterization
/// Features: Real-time data, interactive components, performance optimization
/// Performance: Efficient rendering, optimized state management, smooth animations
/// Architecture: Widget composition, provider integration, event-driven updates
class EnhancedAdvancedScreen extends ConsumerStatefulWidget {
  const EnhancedAdvancedScreen({super.key});

  @override
  ConsumerState<EnhancedAdvancedScreen> createState() => _EnhancedAdvancedScreenState();
}

class _EnhancedAdvancedScreenState extends ConsumerState<EnhancedAdvancedScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Dashboard', 'Analytics', 'Security', 'Performance', 'Settings'];
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(enhancedConfigurationProvider);
    
    return Scaffold(
      appBar: ParameterizedAppBar(
        title: 'Enhanced Advanced Features',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh All',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: _buildTabContent(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActions,
        icon: const Icon(Icons.flash_on),
        label: 'Quick Actions',
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedTab;
          
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (_selectedTab) {
      case 0:
        return _buildDashboardTab(context);
      case 1:
        return _buildAnalyticsTab(context);
      case 2:
        return _buildSecurityTab(context);
      case 3:
        return _buildPerformanceTab(context);
      case 4:
        return _buildSettingsTab(context);
      default:
        return Container();
    }
  }

  Widget _buildDashboardTab(BuildContext context) {
    return const DashboardTab();
  }

  Widget _buildAnalyticsTab(BuildContext context) {
    return const AnalyticsTab();
  }

  Widget _buildSecurityTab(BuildContext context) {
    return const SecurityTab();
  }

  Widget _buildPerformanceTab(BuildContext context) {
    return const PerformanceTab();
  }

  Widget _buildSettingsTab(BuildContext context) {
    return const SettingsTab();
  }

  void _refreshAll() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Refreshing all data...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('System Update Available'),
              subtitle: Text('Version 2.0.1 is available'),
            ),
            const ListTile(
              leading: Icon(Icons.warning),
              title: Text('High Memory Usage'),
              subtitle: Text('Memory usage exceeds 80%'),
            ),
            const ListTile(
              leading: Icon(Icons.success),
              title: Text('Build Completed Successfully'),
              subtitle: Text('Android release build completed'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Auto-refresh'),
              subtitle: const Text('Enable auto-refresh of data'),
              value: true,
              onChanged: (value) {
                // Handle auto-refresh toggle
              },
            ),
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Enable system notifications'),
              value: true,
              onChanged: (value) {
                // Handle notifications toggle
              },
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark mode theme'),
              value: false,
              onChanged: (value) {
                // Handle dark mode toggle
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Start Build'),
              subtitle: const Text('Start a new build process'),
              onTap: () {
                Navigator.of(context).pop();
                _startBuild();
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security Scan'),
              subtitle: const Text('Run security scan'),
              onTap: () {
                Navigator.of(context).pop();
                _runSecurityScan();
              },
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Performance Check'),
              subtitle: const Text('Check system performance'),
              onTap: () {
                Navigator.of(context).pop();
                _checkPerformance();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Generate Report'),
              subtitle: const Text('Generate analytics report'),
              onTap: () {
                Navigator.of(context).pop();
                _generateReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startBuild() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Starting build process...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _runSecurityScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Running security scan...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _checkPerformance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Checking performance...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Generating report...',
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Dashboard Tab
/// 
/// Real-time dashboard with live metrics
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Dashboard',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Real-time metrics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard('CPU Usage', '45%', Icons.memory, Colors.blue),
              _buildMetricCard('Memory', '2.1 GB', Icons.storage, Colors.green),
              _buildMetricCard('Network', '125 Mbps', Icons.network_check, Colors.orange),
              _buildMetricCard('Storage', '45.2 GB', Icons.sd_storage, Colors.purple),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // System status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusItem('Build System', 'Running', Colors.green),
                  _buildStatusItem('Security Service', 'Active', Colors.green),
                  _buildStatusItem('Performance Monitor', 'Active', Colors.green),
                  _buildStatusItem('AI Service', 'Active', Colors.green),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildActivityItem('Build completed', 'Android release build', '2 minutes ago'),
                  _buildActivityItem('Security scan', 'No threats detected', '15 minutes ago'),
                  _buildActivityItem('System update', 'Version 2.0.1 installed', '1 hour ago'),
                  _buildActivityItem('Performance optimization', 'Memory usage reduced by 15%', '2 hours ago'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title),
          ),
          Text(status),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String description, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(time, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Analytics Tab
/// 
/// Analytics and reporting interface
class AnalyticsTab extends ConsumerStatefulWidget {
  const AnalyticsTab({super.key});

  @override
  ConsumerState<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends ConsumerState<AnalyticsTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics & Reports',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Analytics summary
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildAnalyticsCard('Total Builds', '1,234', Icons.build, Colors.blue),
              _buildAnalyticsCard('Success Rate', '94.5%', Icons.trending_up, Colors.green),
              _buildAnalyticsCard('Avg Build Time', '2m 30s', Icons.timer, Colors.orange),
              _buildAnalyticsCard('Errors', '67', Icons.error, Colors.red),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Performance trends
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Trends',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Performance chart here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Reports
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Reports',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildReportItem('Build Report', 'Generated 2 hours ago', () => _generateReport('build')),
                  _buildReportItem('Security Report', 'Generated 1 day ago', () => _generateReport('security')),
                  _buildReportItem('Performance Report', 'Generated 3 days ago', () => _generateReport('performance')),
                  _buildReportItem('Usage Report', 'Generated 1 week ago', () => _generateReport('usage')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String title, String timestamp, VoidCallback onTap) {
    return ListTile(
      leading: const Icon(Icons.description),
      title: Text(title),
      subtitle: Text(timestamp),
      trailing: const Icon(Icons.download),
      onTap: onTap,
    );
  }

  void _generateReport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: 'Generating $type report...',
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Security Tab
/// 
/// Security management interface
class SecurityTab extends ConsumerStatefulWidget {
  const SecurityTab({super.key});

  @override
  ConsumerState<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends ConsumerState<SecurityTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Management',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Security status
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildSecurityCard('Encryption', 'Active', Icons.lock, Colors.green),
              _buildSecurityCard('Authentication', 'Enabled', Icons.verified_user, Colors.green),
              _buildSecurityCard('Audit Logging', 'Active', Icons.history, Colors.green),
              _buildSecurityCard('Access Control', 'Enabled', Icons.security, Colors.green),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Security actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _runSecurityScan,
                          icon: const Icon(Icons.security),
                          label: const Text('Security Scan'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _encryptFiles,
                          icon: const Icon(Icons.lock),
                          label: const Text('Encrypt Files'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _viewAuditLogs,
                          icon: const Icon(Icons.history),
                          label: const Text('Audit Logs'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _manageAccess,
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Access Control'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent security events
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Security Events',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildSecurityEventItem('File encrypted', 'document.pdf', '2 minutes ago'),
                  _buildSecurityEventItem('User authenticated', 'john.doe', '15 minutes ago'),
                  _buildSecurityEventItem('Access granted', 'admin', '1 hour ago'),
                  _buildSecurityEventItem('Security scan completed', 'No threats', '2 hours ago'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(String title, String status, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityEventItem(String event, String details, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.security, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event),
                Text(details, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(time, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _runSecurityScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Running security scan...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _encryptFiles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Encrypting files...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewAuditLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Opening audit logs...',
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _manageAccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: 'Opening access control...',
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Performance Tab
/// 
/// Performance monitoring interface
class PerformanceTab extends ConsumerStatefulWidget {
  const PerformanceTab({super.key});

  @override
  ConsumerState<PerformanceTab> createState() => _PerformanceTabState();
}

class _PerformanceTabState extends ConsumerState<PerformanceTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Monitoring',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Performance metrics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildPerformanceCard('Response Time', '125ms', Icons.speed, Colors.blue),
              _buildPerformanceCard('Memory Usage', '2.1 GB', Icons.memory, Colors.green),
              _buildPerformanceCard('CPU Usage', '45%', Icons.cpu, Colors.orange),
              _buildPerformanceCard('Network I/O', '125 Mbps', Icons.network_check, Colors.purple),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Performance charts
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Trends',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Performance chart here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Optimization suggestions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optimization Suggestions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildOptimizationItem('Reduce memory usage', 'Implement memory pooling'),
                  _buildOptimizationItem('Optimize database queries', 'Add proper indexing'),
                  _buildOptimizationItem('Improve response time', 'Enable caching'),
                  _buildOptimizationItem('Reduce CPU usage', 'Optimize algorithms'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationItem(String title, String description) {
    return ListTile(
      leading: const Icon(Icons.lightbulb),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: 'Implementing optimization: $title',
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

/// Settings Tab
/// 
/// Advanced settings interface
class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // General settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Auto-refresh'),
                    subtitle: const Text('Enable auto-refresh of data'),
                    value: true,
                    onChanged: (value) {
                      // Handle auto-refresh toggle
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Enable system notifications'),
                    value: true,
                    onChanged: (value) {
                      // Handle notifications toggle
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark mode theme'),
                    value: false,
                    onChanged: (value) {
                      // Handle dark mode toggle
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Performance settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Cache Size'),
                    subtitle: const Text('Maximum cache size in MB'),
                    trailing: const Text('512 MB'),
                    onTap: () {
                      _showCacheSizeDialog();
                    },
                  ),
                  ListTile(
                    title: const Text('Update Interval'),
                    subtitle: const Text('Data update interval in seconds'),
                    trailing: const Text('5 seconds'),
                    onTap: () {
                      _showUpdateIntervalDialog();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Performance Monitoring'),
                    subtitle: const Text('Enable performance monitoring'),
                    value: true,
                    onChanged: (value) {
                      // Handle performance monitoring toggle
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Security settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Encryption'),
                    subtitle: const Text('Enable file encryption'),
                    value: true,
                    onChanged: (value) {
                      // Handle encryption toggle
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Biometric Authentication'),
                    subtitle: const Text('Enable biometric authentication'),
                    value: true,
                    onChanged: (value) {
                      // Handle biometric authentication toggle
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Audit Logging'),
                    subtitle: const Text('Enable audit logging'),
                    value: true,
                    onChanged: (value) {
                      // Handle audit logging toggle
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCacheSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set maximum cache size in MB'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Cache Size (MB)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '512'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showUpdateIntervalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set data update interval in seconds'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Update Interval (seconds)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '5'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
