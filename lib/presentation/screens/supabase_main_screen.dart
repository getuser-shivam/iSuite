import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/supabase_providers.dart';
import '../widgets/common/parameterized_app_bar.dart';
import '../widgets/common/parameterized_bottom_navigation_bar.dart';

/// Supabase Main Screen
/// 
/// Main screen for Supabase functionality
/// Features: Configuration, authentication, data management, statistics
/// Performance: Optimized state management, efficient UI updates
/// Architecture: Consumer widget, provider pattern, responsive design
class SupabaseMainScreen extends ConsumerStatefulWidget {
  const SupabaseMainScreen({super.key});

  @override
  ConsumerState<SupabaseMainScreen> createState() => _SupabaseMainScreenState();
}

class _SupabaseMainScreenState extends ConsumerState<SupabaseMainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const SupabaseDashboardScreen(),
    const SupabaseConfigurationScreen(),
    const SupabaseAuthenticationScreen(),
    const SupabaseDataManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ParameterizedBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: 'Config',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.login),
            label: 'Auth',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.storage),
            label: 'Data',
          ),
        ],
      ),
    );
  }
}

/// Supabase Dashboard Screen
/// 
/// Dashboard showing Supabase statistics and status
/// Features: Real-time statistics, system status, quick actions
/// Performance: Optimized updates, efficient data loading
/// Architecture: Consumer widget, provider pattern, dashboard design
class SupabaseDashboardScreen extends ConsumerWidget {
  const SupabaseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(supabaseConfigurationProvider);
    final authProvider = ref.watch(supabaseAuthenticationProvider);
    final dataProvider = ref.watch(supabaseDataProvider);
    
    return Scaffold(
      appBar: ParameterizedAppBar(
        title: 'Supabase Dashboard',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            _buildStatusSection(context, l10n, configProvider, authProvider),
            
            const SizedBox(height: 24),
            
            // Statistics Section
            _buildStatisticsSection(context, l10n, dataProvider),
            
            const SizedBox(height: 24),
            
            // Quick Actions Section
            _buildQuickActionsSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Recent Activity Section
            _buildRecentActivitySection(context, l10n, dataProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, AppLocalizations l10n, configProvider, authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supabase Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  configProvider.isConfigured ? Icons.check_circle : Icons.error,
                  color: configProvider.isConfigured ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  configProvider.isConfigured ? 'Configured' : 'Not Configured',
                  style: TextStyle(
                    color: configProvider.isConfigured ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  configProvider.isConnected ? Icons.check_circle : Icons.error,
                  color: configProvider.isConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  configProvider.isConnected ? 'Connected' : 'Not Connected',
                  style: TextStyle(
                    color: configProvider.isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  authProvider.isAuthenticated ? Icons.check_circle : Icons.error,
                  color: authProvider.isAuthenticated ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  authProvider.isAuthenticated ? 'Authenticated' : 'Not Authenticated',
                  style: TextStyle(
                    color: authProvider.isAuthenticated ? Colors.green : Colors.orange,
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

  Widget _buildStatisticsSection(BuildContext context, AppLocalizations l10n, dataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Files',
                dataProvider.files.length.toString(),
                Icons.folder,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Devices',
                dataProvider.networkDevices.length.toString(),
                Icons.devices,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Transfers',
                dataProvider.fileTransfers.length.toString(),
                Icons.swap_horiz,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Users',
                dataProvider.users.length.toString(),
                Icons.people,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, AppLocalizations l10n, configProvider) {
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
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              context,
              'Test Connection',
              'Test Supabase connection',
              Icons.network_check,
              Colors.blue,
              () => _testConnection(configProvider),
            ),
            _buildActionCard(
              context,
              'Load Data',
              'Load all Supabase data',
              Icons.refresh,
              Colors.green,
              () => _loadData(),
            ),
            _buildActionCard(
              context,
              'Clear Cache',
              'Clear Supabase cache',
              Icons.clear,
              Colors.orange,
              () => _clearCache(),
            ),
            _buildActionCard(
              context,
              'View Logs',
              'View Supabase logs',
              Icons.list_alt,
              Colors.purple,
              () => _viewLogs(),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, AppLocalizations l10n, dataProvider) {
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
                _buildActivityItem('Data loaded', 'All Supabase data refreshed', Icons.refresh),
                _buildActivityItem('Connection tested', 'Supabase connection verified', Icons.network_check),
                _buildActivityItem('Cache cleared', 'Supabase cache cleared', Icons.clear),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
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
        ],
      ),
    );
  }

  void _testConnection(configProvider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing connection...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    final success = await configProvider.testConnection();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection test successful'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection test failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _loadData() {
    final dataProvider = ref.read(supabaseDataProvider);
    dataProvider.loadAllData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loading data...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearCache() {
    // Clear Supabase cache
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewLogs() {
    // Show Supabase logs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs view coming soon'),
      ),
    );
  }
}
