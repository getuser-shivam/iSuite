import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/config_provider.dart';
import '../providers/functional_providers.dart';
import '../widgets/common/parameterized_app_bar.dart';
import '../../core/orchestrator/application_orchestrator.dart';

/// Enhanced Parameterized Main Screen
/// 
/// Main application screen with central parameterized configuration
/// Features: Real-time configuration updates, system statistics, status monitoring
/// Performance: Optimized state management, efficient UI updates
/// Architecture: Provider pattern, responsive design, parameterized UI
class EnhancedParameterizedMainScreen extends ConsumerStatefulWidget {
  const EnhancedParameterizedMainScreen({super.key});

  @override
  ConsumerState<EnhancedParameterizedMainScreen> createState() => _EnhancedParameterizedMainScreenState();
}

class _EnhancedParameterizedMainScreenState extends ConsumerState<EnhancedParameterizedMainScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(configurationProvider);
    final appOrchestrator = ApplicationOrchestrator.instance;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(configProvider.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => configProvider.reloadConfiguration(),
            tooltip: l10n.configuration,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showConfigurationDialog(context),
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Status Section
            _buildSystemStatusSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Configuration Section
            _buildConfigurationSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Components Section
            _buildComponentsSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Services Section
            _buildServicesSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Application Status Section
            _buildApplicationStatusSection(context, l10n, configProvider, appOrchestrator),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(context, l10n, configProvider),
          ],
        ),
      ),
    );
  }

  /// Build system status section
  Widget _buildSystemStatusSection(BuildContext context, AppLocalizations l10n, ConfigurationProvider configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.systemStatus,
              style: Theme.of(context).textTheme.titleLarge,
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
                  l10n.allSystemsOperational,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.centralParameterizationActive,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Application info
            Row(
              children: [
                Icon(
                  Icons.apps,
                  color: Colors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${configProvider.appName} v${configProvider.appVersion}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.developer_mode,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Environment: ${configProvider.appEnvironment}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build configuration section
  Widget _buildConfigurationSection(BuildContext context, AppLocalizations l10n, ConfigurationProvider configProvider) {
    final configStats = configProvider.configStats;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.configurationSystem,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(context, l10n.totalParameters, configStats['total_parameters']?.toString() ?? '0'),
            _buildStatRow(context, l10n.cachedParameters, configStats['cached_parameters']?.toString() ?? '0'),
            _buildStatRow(context, l10n.configurationSources, configStats['sources_count']?.toString() ?? '0'),
            _buildStatRow(
              context, 
              l10n.cacheHitRate, 
              '${((configStats['cache_hit_rate'] ?? 0.0) * 100).toStringAsFixed(1)}%'
            ),
          ],
        ),
      ),
    );
  }

  /// Build components section
  Widget _buildComponentsSection(BuildContext context, AppLocalizations l10n, ConfigurationProvider configProvider) {
    final componentStats = configProvider.componentStats;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.componentSystem,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(context, l10n.totalComponents, componentStats['total_components']?.toString() ?? '0'),
            _buildStatRow(context, l10n.initializedComponents, componentStats['initialized_components']?.toString() ?? '0'),
            _buildStatRow(context, l10n.dependencies, componentStats['dependencies_count']?.toString() ?? '0'),
            _buildStatRow(context, l10n.observers, componentStats['observers_count']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  /// Build services section
  Widget _buildServicesSection(BuildContext context, AppLocalizations l10n, ConfigurationProvider configProvider) {
    final orchestratorStats = configProvider.orchestratorStats;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.serviceSystem,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(context, l10n.totalServices, orchestratorStats['total_services']?.toString() ?? '0'),
            _buildStatRow(context, l10n.initializedServices, orchestratorStats['initialized_services']?.toString() ?? '0'),
            _buildStatRow(context, l10n.dependencies, orchestratorStats['dependencies_count']?.toString() ?? '0'),
            _buildStatRow(context, l10n.observers, orchestratorStats['observers_count']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  /// Build application status section
  Widget _buildApplicationStatusSection(
    BuildContext context, 
    AppLocalizations l10n, 
    ConfigurationProvider configProvider,
    ApplicationOrchestrator appOrchestrator,
  ) {
    final appStats = configProvider.appStats;
    final uptime = appOrchestrator.getUptime();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.applicationStatistics,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context, 
              l10n.initializationDuration, 
              '${appStats['initialization_duration'] ?? 0}ms'
            ),
            _buildStatRow(
              context, 
              l10n.uptime, 
              '${uptime.inMinutes}m ${uptime.inSeconds % 60}s'
            ),
            _buildStatRow(context, l10n.startupSteps, appStats['startup_steps']?.toString() ?? '0'),
            _buildStatRow(context, l10n.completedSteps, appStats['completed_steps']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  /// Build statistics row
  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n, ConfigurationProvider configProvider) {
    return Column(
      children: [
        // Primary action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showConfigurationDialog(context),
                icon: const Icon(Icons.settings),
                label: Text(l10n.configuration),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showStatisticsDialog(context),
                icon: const Icon(Icons.analytics),
                label: Text(l10n.statistics),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Secondary action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => configProvider.reloadConfiguration(),
                icon: const Icon(Icons.refresh),
                label: Text('Reload Config'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportConfiguration(context),
                icon: const Icon(Icons.download),
                label: Text('Export Config'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Show configuration dialog
  void _showConfigurationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ConfigurationDialog(),
    );
  }

  /// Show statistics dialog
  void _showStatisticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _StatisticsDialog(),
    );
  }

  /// Export configuration
  void _exportConfiguration(BuildContext context) {
    final configProvider = ref.read(configurationProvider);
    
    configProvider.exportConfiguration().then((yamlData) {
      // Show export dialog or save to file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export configuration: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}

/// Configuration Dialog
class _ConfigurationDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(configurationProvider);
    
    return AlertDialog(
      title: Text(l10n.configuration),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI Services Configuration
            _buildConfigSection(
              context,
              'AI Services',
              [
                _buildConfigSwitch(
                  context,
                  'File Organizer',
                  configProvider.aiFileOrganizerEnabled,
                  (value) => configProvider.updateConfiguration('ai_services.enable_file_organizer', value),
                ),
                _buildConfigSwitch(
                  context,
                  'Advanced Search',
                  configProvider.aiAdvancedSearchEnabled,
                  (value) => configProvider.updateConfiguration('ai_services.enable_advanced_search', value),
                ),
                _buildConfigSwitch(
                  context,
                  'Smart Categorizer',
                  configProvider.aiSmartCategorizerEnabled,
                  (value) => configProvider.updateConfiguration('ai_services.enable_smart_categorizer', value),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Network Services Configuration
            _buildConfigSection(
              context,
              'Network Services',
              [
                _buildConfigSwitch(
                  context,
                  'File Sharing',
                  configProvider.networkFileSharingEnabled,
                  (value) => configProvider.updateConfiguration('network_services.enable_file_sharing', value),
                ),
                _buildConfigSwitch(
                  context,
                  'FTP Client',
                  configProvider.ftpClientEnabled,
                  (value) => configProvider.updateConfiguration('network_services.enable_ftp_client', value),
                ),
                _buildConfigSwitch(
                  context,
                  'WiFi Direct',
                  configProvider.wifiDirectEnabled,
                  (value) => configProvider.updateConfiguration('network_services.enable_wifi_direct', value),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Performance Configuration
            _buildConfigSection(
              context,
              'Performance',
              [
                _buildConfigSwitch(
                  context,
                  'Caching',
                  configProvider.cachingEnabled,
                  (value) => configProvider.updateConfiguration('performance.enable_caching', value),
                ),
                _buildConfigSwitch(
                  context,
                  'Parallel Processing',
                  configProvider.parallelProcessingEnabled,
                  (value) => configProvider.updateConfiguration('performance.enable_parallel_processing', value),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _buildConfigSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildConfigSwitch(
    BuildContext context,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }
}

/// Statistics Dialog
class _StatisticsDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(configurationProvider);
    
    return AlertDialog(
      title: Text(l10n.systemStatistics),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailedStats(context, configProvider.configStats),
            
            const SizedBox(height: 16),
            
            Text(
              'Component Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailedStats(context, configProvider.componentStats),
            
            const SizedBox(height: 16),
            
            Text(
              'Service Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailedStats(context, configProvider.orchestratorStats),
            
            const SizedBox(height: 16),
            
            Text(
              'Application Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailedStats(context, configProvider.appStats),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(BuildContext context, Map<String, dynamic> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: stats.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  entry.value.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
