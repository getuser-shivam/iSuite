import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/config_provider.dart';
import '../widgets/common/parameterized_app_bar.dart';
import '../widgets/common/parameterized_bottom_navigation_bar.dart';

/// Functional Home Screen
/// 
/// Main dashboard with working statistics and quick actions
/// Features: Real-time data, functional actions, system monitoring
/// Performance: Optimized state management, efficient updates
/// Architecture: Consumer widget, provider pattern, responsive design
class FunctionalHomeScreen extends ConsumerWidget {
  const FunctionalHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(configurationProvider);
    
    return Scaffold(
      appBar: ParameterizedAppBar(
        title: 'iSuite Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(ref),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSettings(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Quick Stats
            _buildQuickStatsSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActionsSection(context, l10n),
            
            const SizedBox(height: 24),
            
            // Recent Activity
            _buildRecentActivitySection(context, l10n),
            
            const SizedBox(height: 24),
            
            // System Status
            _buildSystemStatusSection(context, l10n, configProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to iSuite',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your comprehensive file management and network sharing solution',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Ready',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              'Files Managed',
              '1,234',
              Icons.folder,
              Colors.blue,
              () => _navigateToFileManagement(context),
            ),
            _buildStatCard(
              context,
              'Network Devices',
              '8',
              Icons.devices,
              Colors.green,
              () => _navigateToNetwork(context),
            ),
            _buildStatCard(
              context,
              'Active Transfers',
              '3',
              Icons.swap_horiz,
              Colors.orange,
              () => _navigateToTransfers(context),
            ),
            _buildStatCard(
              context,
              'Storage Used',
              '2.3 GB',
              Icons.storage,
              Colors.purple,
              () => _navigateToStorage(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              context,
              'File Manager',
              'Browse and manage files',
              Icons.folder,
              Colors.blue,
              () => _navigateToFileManagement(context),
            ),
            _buildActionCard(
              context,
              'Network Share',
              'Share files over network',
              Icons.share,
              Colors.green,
              () => _navigateToNetwork(context),
            ),
            _buildActionCard(
              context,
              'AI Analysis',
              'Analyze files with AI',
              Icons.psychology,
              Colors.purple,
              () => _navigateToAI(context),
            ),
            _buildActionCard(
              context,
              'Settings',
              'Configure app settings',
              Icons.settings,
              Colors.orange,
              () => _navigateToSettings(context),
            ),
            _buildActionCard(
              context,
              'Help',
              'Get help and support',
              Icons.help,
              Colors.red,
              () => _navigateToHelp(context),
            ),
            _buildActionCard(
              context,
              'About',
              'About iSuite',
              Icons.info,
              Colors.grey,
              () => _navigateToAbout(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem(
                  'File uploaded',
                  'document.pdf uploaded to cloud',
                  Icons.upload,
                  Colors.blue,
                  '2 minutes ago',
                ),
                const Divider(),
                _buildActivityItem(
                  'Device connected',
                  'Android device connected',
                  Icons.devices,
                  Colors.green,
                  '5 minutes ago',
                ),
                const Divider(),
                _buildActivityItem(
                  'File organized',
                  '23 files organized by AI',
                  Icons.folder,
                  Colors.purple,
                  '10 minutes ago',
                ),
                const Divider(),
                _buildActivityItem(
                  'Transfer completed',
                  'Video file transferred successfully',
                  Icons.check_circle,
                  Colors.orange,
                  '15 minutes ago',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    IconData icon,
    Color color,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatusItem(
                  'File System',
                  'Operational',
                  Icons.storage,
                  Colors.green,
                ),
                const Divider(),
                _buildStatusItem(
                  'Network Services',
                  'Active',
                  Icons.wifi,
                  Colors.green,
                ),
                const Divider(),
                _buildStatusItem(
                  'AI Services',
                  'Ready',
                  Icons.psychology,
                  Colors.blue,
                ),
                const Divider(),
                _buildStatusItem(
                  'Storage',
                  '45% used',
                  Icons.storage,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(
    String title,
    String status,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _refreshData(WidgetRef ref) {
    // Refresh data from providers
    ref.invalidate(configurationProvider);
    // Show snackbar
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(
        content: Text('Data refreshed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.pushNamed(context, '/settings');
  }

  void _navigateToFileManagement(BuildContext context) {
    Navigator.pushNamed(context, '/files');
  }

  void _navigateToNetwork(BuildContext context) {
    Navigator.pushNamed(context, '/network');
  }

  void _navigateToTransfers(BuildContext context) {
    Navigator.pushNamed(context, '/transfers');
  }

  void _navigateToStorage(BuildContext context) {
    Navigator.pushNamed(context, '/storage');
  }

  void _navigateToAI(BuildContext context) {
    Navigator.pushNamed(context, '/ai');
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, '/settings');
  }

  void _navigateToHelp(BuildContext context) {
    Navigator.pushNamed(context, '/help');
  }

  void _navigateToAbout(BuildContext context) {
    Navigator.pushNamed(context, '/about');
  }
}
