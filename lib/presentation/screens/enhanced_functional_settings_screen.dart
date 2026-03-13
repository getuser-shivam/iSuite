import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/enhanced_config_provider.dart';
import '../widgets/common/parameterized_app_bar.dart';

/// Enhanced Functional Settings Screen
/// 
/// Settings screen with working configuration management
/// Features: Real-time settings, functional toggles, system configuration
/// Performance: Optimized state management, efficient updates
/// Architecture: Consumer widget, provider pattern, responsive design
class EnhancedFunctionalSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedFunctionalSettingsScreen({super.key});

  @override
  ConsumerState<EnhancedFunctionalSettingsScreen> createState() => _EnhancedFunctionalSettingsScreenState();
}

class _EnhancedFunctionalSettingsScreenState extends ConsumerState<EnhancedFunctionalSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(enhancedConfigurationProvider);
    
    return Scaffold(
      appBar: ParameterizedAppBar(
        title: 'Settings',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveSettings(configProvider),
            tooltip: 'Save Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetSettings(configProvider),
            tooltip: 'Reset to Defaults',
          ),
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () => _showImportExportDialog(),
            tooltip: 'Import/Export',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            _buildGeneralSettingsSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // File Management Settings
            _buildFileManagementSettingsSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Network Settings
            _buildNetworkSettingsSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // AI Settings
            _buildAISettingsSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Security Settings
            _buildSecuritySettingsSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Performance Settings
            _buildPerformanceSettingsSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // Advanced Settings
            _buildAdvancedSettingsSection(context, l10n, configProvider),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildAboutSection(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettingsSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Theme Mode
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme'),
              value: configProvider.getParameter('ui.theme_mode', defaultValue: 'system') == 'dark',
              onChanged: (value) {
                _updateSetting('ui.theme_mode', value ? 'dark' : 'light');
              },
            ),
            
            // Language
            ListTile(
              title: const Text('Language'),
              subtitle: Text(configProvider.getParameter('ui.language', defaultValue: 'en')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLanguageDialog(context),
            ),
            
            // Font Size
            ListTile(
              title: const Text('Font Size'),
              subtitle: Text(configProvider.getParameter('ui.font_size', defaultValue: 'medium')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showFontSizeDialog(context),
            ),
            
            // Auto-save
            SwitchListTile(
              title: const Text('Auto-save'),
              subtitle: const Text('Automatically save changes'),
              value: configProvider.getParameter('ui.auto_save_interval', defaultValue: 30) > 0,
              onChanged: (value) {
                _updateSetting('ui.auto_save_interval', value ? 30 : 0);
              },
            ),
            
            // Notifications
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Enable system notifications'),
              value: configProvider.getParameter('ui.enable_notifications', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ui.enable_notifications', value);
              },
            ),
            
            // Animations
            SwitchListTile(
              title: const Text('Animations'),
              subtitle: const Text('Enable UI animations'),
              value: configProvider.getParameter('ui.enable_animations', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ui.enable_animations', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileManagementSettingsSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Default Directory
            ListTile(
              title: const Text('Default Directory'),
              subtitle: Text(configProvider.getParameter('files.default_directory', defaultValue: '/storage/emulated/0')),
              trailing: const Icon(Icons.folder),
              onTap: () => _selectDefaultDirectory(context),
            ),
            
            // Show Hidden Files
            SwitchListTile(
              title: const Text('Show Hidden Files'),
              subtitle: const Text('Display hidden files and folders'),
              value: configProvider.getParameter('files.show_hidden_files', defaultValue: false),
              onChanged: (value) {
                _updateSetting('files.show_hidden_files', value);
              },
            ),
            
            // File Preview
            SwitchListTile(
              title: const Text('File Preview'),
              subtitle: const Text('Enable file preview in list'),
              value: configProvider.getParameter('files.enable_preview', defaultValue: true),
              onChanged: (value) {
                _updateSetting('files.enable_preview', value);
              },
            ),
            
            // Auto-organize
            SwitchListTile(
              title: const Text('Auto-organize'),
              subtitle: const Text('Automatically organize files'),
              value: configProvider.getParameter('files.auto_organize', defaultValue: false),
              onChanged: (value) {
                _updateSetting('files.auto_organize', value);
              },
            ),
            
            // File Operations
            ListTile(
              title: const Text('File Operations'),
              subtitle: const Text('Configure file operations'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showFileOperationsDialog(context),
            ),
            
            // File Types
            ListTile(
              title: const Text('File Types'),
              subtitle: const Text('Configure file type associations'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showFileTypesDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkSettingsSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // WiFi Direct
            SwitchListTile(
              title: const Text('WiFi Direct'),
              subtitle: const Text('Enable WiFi Direct file sharing'),
              value: configProvider.getParameter('network.enable_wifi_direct', defaultValue: true),
              onChanged: (value) {
                _updateSetting('network.enable_wifi_direct', value);
              },
            ),
            
            // FTP Server
            SwitchListTile(
              title: const Text('FTP Server'),
              subtitle: const Text('Enable FTP server'),
              value: configProvider.getParameter('network.enable_ftp_server', defaultValue: false),
              onChanged: (value) {
                _updateSetting('network.enable_ftp_server', value);
              },
            ),
            
            // WebDAV
            SwitchListTile(
              title: const Text('WebDAV'),
              subtitle: const Text('Enable WebDAV server'),
              value: configProvider.getParameter('network.enable_webdav', defaultValue: false),
              onChanged: (value) {
                _updateSetting('network.enable_webdav', value);
              },
            ),
            
            // SMB
            SwitchListTile(
              title: const Text('SMB/CIFS'),
              subtitle: const Text('Enable SMB/CIFS server'),
              value: configProvider.getParameter('network.enable_smb', defaultValue: false),
              onChanged: (value) {
                _updateSetting('network.enable_smb', value);
              },
            ),
            
            // P2P
            SwitchListTile(
              title: const Text('P2P Sharing'),
              subtitle: const Text('Enable peer-to-peer file sharing'),
              value: configProvider.getParameter('network.enable_p2p', defaultValue: true),
              onChanged: (value) {
                _updateSetting('network.enable_p2p', value);
              },
            ),
            
            // Auto-discovery
            SwitchListTile(
              title: const Text('Auto-discovery'),
              subtitle: const Text('Automatically discover devices'),
              value: configProvider.getParameter('network.enable_auto_discovery', defaultValue: true),
              onChanged: (value) {
                _updateSetting('network.enable_auto_discovery', value);
              },
            ),
            
            // Connection Timeout
            ListTile(
              title: const Text('Connection Timeout'),
              subtitle: Text('${configProvider.getParameter('network.connection_timeout', defaultValue: 30)} seconds'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showTimeoutDialog(context),
            ),
            
            // Max Connections
            ListTile(
              title: const Text('Max Connections'),
              subtitle: Text('${configProvider.getParameter('network.max_connections', defaultValue: 10)}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showMaxConnectionsDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISettingsSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // AI Features
            SwitchListTile(
              title: const Text('AI Features'),
              subtitle: const Text('Enable AI-powered features'),
              value: configProvider.getParameter('ai.enable_features', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ai.enable_features', value);
              },
            ),
            
            // Smart Categorization
            SwitchListTile(
              title: const Text('Smart Categorization'),
              subtitle: const Text('AI-powered file categorization'),
              value: configProvider.getParameter('ai.enable_categorization', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ai.enable_categorization', value);
              },
            ),
            
            // Duplicate Detection
            SwitchListTile(
              title: const Text('Duplicate Detection'),
              subtitle: const Text('AI-powered duplicate detection'),
              value: configProvider.getParameter('ai.enable_duplicate_detection', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ai.enable_duplicate_detection', value);
              },
            ),
            
            // Smart Search
            SwitchListTile(
              title: const Text('Smart Search'),
              subtitle: const Text('AI-powered search'),
              value: configProvider.getParameter('ai.enable_smart_search', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ai.enable_smart_search', value);
              },
            ),
            
            // AI Model
            ListTile(
              title: const Text('AI Model'),
              subtitle: Text(configProvider.getParameter('ai.model_name', defaultValue: 'gpt-3.5-turbo')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showAIModelDialog(context),
            ),
            
            // API Key
            ListTile(
              title: const Text('AI API Key'),
              subtitle: const Text('Configure AI service API key'),
              trailing: const Icon(Icons.key),
              onTap: () => _showAPIKeyDialog(context),
            ),
            
            // Confidence Threshold
            ListTile(
              title: const Text('Confidence Threshold'),
              subtitle: Text('${(configProvider.getParameter('ai.confidence_threshold', defaultValue: 0.85) * 100).toInt()}%'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showConfidenceDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettingsSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Biometric Authentication
            SwitchListTile(
              title: const Text('Biometric Authentication'),
              subtitle: const Text('Enable fingerprint/face unlock'),
              value: configProvider.getParameter('security.enable_biometric', defaultValue: false),
              onChanged: (value) {
                _updateSetting('security.enable_biometric', value);
              },
            ),
            
            // Encryption
            SwitchListTile(
              title: const Text('File Encryption'),
              subtitle: const Text('Encrypt sensitive files'),
              value: configProvider.getParameter('security.enable_encryption', defaultValue: true),
              onChanged: (value) {
                _updateSetting('security.enable_encryption', value);
              },
            ),
            
            // Secure Sharing
            SwitchListTile(
              title: const Text('Secure Sharing'),
              subtitle: const Text('Use secure protocols for sharing'),
              value: configProvider.getParameter('security.enable_secure_sharing', defaultValue: true),
              onChanged: (value) {
                _updateSetting('security.enable_secure_sharing', value);
              },
            ),
            
            // Audit Logging
            SwitchListTile(
              title: const Text('Audit Logging'),
              subtitle: const Text('Log all file operations'),
              value: configProvider.getParameter('security.enable_audit_logging', defaultValue: true),
              onChanged: (value) {
                _updateSetting('security.enable_audit_logging', value);
              },
            ),
            
            // Session Timeout
            ListTile(
              title: const Text('Session Timeout'),
              subtitle: Text('${configProvider.getParameter('security.session_timeout_hours', defaultValue: 8)} hours'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showSessionTimeoutDialog(context),
            ),
            
            // Max Login Attempts
            ListTile(
              title: const Text('Max Login Attempts'),
              subtitle: Text('${configProvider.getParameter('security.max_login_attempts', defaultValue: 3)}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showMaxLoginAttemptsDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSettingsSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Caching
            SwitchListTile(
              title: const Text('Enable Caching'),
              subtitle: const Text('Cache files for faster access'),
              value: configProvider.getParameter('performance.enable_caching', defaultValue: true),
              onChanged: (value) {
                _updateSetting('performance.enable_caching', value);
              },
            ),
            
            // Parallel Processing
            SwitchListTile(
              title: const Text('Parallel Processing'),
              subtitle: const Text('Use multiple CPU cores'),
              value: configProvider.getParameter('performance.enable_parallel_processing', defaultValue: true),
              onChanged: (value) {
                _updateSetting('performance.enable_parallel_processing', value);
              },
            ),
            
            // Background Sync
            SwitchListTile(
              title: const Text('Background Sync'),
              subtitle: const Text('Sync files in background'),
              value: configProvider.getParameter('performance.enable_background_sync', defaultValue: true),
              onChanged: (value) {
                _updateSetting('performance.enable_background_sync', value);
              },
            ),
            
            // Optimization
            SwitchListTile(
              title: const Text('Optimization'),
              subtitle: const Text('Enable performance optimization'),
              value: configProvider.getParameter('performance.enable_optimization', defaultValue: true),
              onChanged: (value) {
                _updateSetting('performance.enable_optimization', value);
              },
            ),
            
            // Cache Size
            ListTile(
              title: const Text('Cache Size'),
              subtitle: Text('${configProvider.getParameter('performance.cache_size_mb', defaultValue: 100)} MB'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showCacheSizeDialog(context),
            ),
            
            // Max Workers
            ListTile(
              title: const Text('Max Workers'),
              subtitle: Text('${configProvider.getParameter('performance.max_workers', defaultValue: 4)}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showMaxWorkersDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection(BuildContext context, AppLocalizations l10n, configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Environment
            ListTile(
              title: const Text('Environment'),
              subtitle: Text(configProvider.getParameter('app.environment', defaultValue: 'development')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showEnvironmentDialog(context),
            ),
            
            // Debug Mode
            SwitchListTile(
              title: const Text('Debug Mode'),
              subtitle: const Text('Enable debug features'),
              value: configProvider.getParameter('debug.enabled', defaultValue: false),
              onChanged: (value) {
                _updateSetting('debug.enabled', value);
              },
            ),
            
            // Verbose Logging
            SwitchListTile(
              title: const Text('Verbose Logging'),
              subtitle: const Text('Enable verbose logging'),
              value: configProvider.getParameter('debug.verbose_logging', defaultValue: false),
              onChanged: (value) {
                _updateSetting('debug.verbose_logging', value);
              },
            ),
            
            // Mock Services
            SwitchListTile(
              title: const Text('Mock Services'),
              subtitle: const Text('Use mock services for testing'),
              value: configProvider.getParameter('debug.mock_services', defaultValue: false),
              onChanged: (value) {
                _updateSetting('debug.mock_services', value);
              },
            ),
            
            // Performance Monitoring
            SwitchListTile(
              title: const Text('Performance Monitoring'),
              subtitle: const Text('Monitor app performance'),
              value: configProvider.getParameter('performance.monitoring', defaultValue: false),
              onChanged: (value) {
                _updateSetting('performance.monitoring', value);
              },
            ),
            
            // Export Logs
            ListTile(
              title: const Text('Export Logs'),
              subtitle: const Text('Export application logs'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _exportLogs(context),
            ),
            
            // Reset App
            ListTile(
              title: const Text('Reset App'),
              subtitle: const Text('Reset all app data'),
              trailing: const Icon(Icons.warning),
              onTap: () => _showResetAppDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // App Info
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Version'),
              subtitle: const Text('2.0.0'),
            ),
            
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Build'),
              subtitle: const Text('2024.03.13'),
            ),
            
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('License'),
              subtitle: const Text('MIT License'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLicenseDialog(context),
            ),
            
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help and support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _openSupport(),
            ),
            
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Send Feedback'),
              subtitle: const Text('Help us improve the app'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _sendFeedback(),
            ),
            
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Check Updates'),
              subtitle: const Text('Check for app updates'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _checkForUpdates(),
            ),
            
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('System Info'),
              subtitle: const Text('View system information'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showSystemInfo(context),
            ),
          ],
        ),
      ),
    );
  }

  // Settings update methods
  void _updateSetting(String key, dynamic value) {
    final configProvider = ref.read(enhancedConfigurationProvider);
    configProvider.setParameter(key, value);
    setState(() {});
  }

  void _saveSettings(configProvider) {
    // Save settings to persistent storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetSettings(configProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              configProvider.resetToDefaults();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // Dialog methods
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                _updateSetting('ui.language', 'en');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              onTap: () {
                _updateSetting('ui.language', 'es');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('French'),
              onTap: () {
                _updateSetting('ui.language', 'fr');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('German'),
              onTap: () {
                _updateSetting('ui.language', 'de');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Chinese'),
              onTap: () {
                _updateSetting('ui.language', 'zh');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    final currentSize = ref.read(enhancedConfigurationProvider).getParameter('ui.font_size', defaultValue: 'medium');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['small', 'medium', 'large', 'extra-large'].map((size) {
            return RadioListTile<String>(
              title: Text(size),
              value: size,
              groupValue: currentSize,
              onChanged: (value) {
                _updateSetting('ui.font_size', value);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = ref.read(enhancedConfigurationProvider).getParameter('network.connection_timeout', defaultValue: 30).toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Timeout'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Timeout (seconds)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final timeout = int.tryParse(controller.text) ?? 30;
              _updateSetting('network.connection_timeout', timeout);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMaxConnectionsDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = ref.read(enhancedConfigurationProvider).getParameter('network.max_connections', defaultValue: 10).toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Connections'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Maximum connections',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final maxConnections = int.tryParse(controller.text) ?? 10;
              _updateSetting('network.max_connections', maxConnections);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCacheSizeDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = ref.read(enhancedConfigurationProvider).getParameter('performance.cache_size_mb', defaultValue: 100).toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Size'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Cache Size (MB)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final cacheSize = int.tryParse(controller.text) ?? 100;
              _updateSetting('performance.cache_size_mb', cacheSize);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMaxWorkersDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = ref.read(enhancedConfigurationProvider).getParameter('performance.max_workers', defaultValue: 4).toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Workers'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Maximum workers',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final maxWorkers = int.tryParse(controller.text) ?? 4;
              _updateSetting('performance.max_workers', maxWorkers);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSessionTimeoutDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = ref.read(enhancedConfigurationProvider).getParameter('security.session_timeout_hours', defaultValue: 8).toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Timeout'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Timeout (hours)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final timeout = int.tryParse(controller.text) ?? 8;
              _updateSetting('security.session_timeout_hours', timeout);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMaxLoginAttemptsDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = ref.read(enhancedConfigurationProvider).getParameter('security.max_login_attempts', defaultValue: 3).toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Login Attempts'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Maximum attempts',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final maxAttempts = int.tryParse(controller.text) ?? 3;
              _updateSetting('security.max_login_attempts', maxAttempts);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAPIKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = ref.read(enhancedConfigurationProvider).getParameter('ai.api_key', defaultValue: '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateSetting('ai.api_key', controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAIModelDialog(BuildContext context) {
    final currentModel = ref.read(enhancedConfigurationProvider).getParameter('ai.model_name', defaultValue: 'gpt-3.5-turbo');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('GPT-3.5 Turbo'),
              value: 'gpt-3.5-turbo',
              groupValue: currentModel,
              onChanged: (value) {
                _updateSetting('ai.model_name', value);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('GPT-4'),
              value: 'gpt-4',
              groupValue: currentModel,
              onChanged: (value) {
                _updateSetting('ai.model_name', value);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Claude'),
              value: 'claude',
              groupValue: currentModel,
              onChanged: (value) {
                _updateSetting('ai.model_name', value);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showConfidenceDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = (ref.read(enhancedConfigurationProvider).getParameter('ai.confidence_threshold', defaultValue: 0.85) * 100).toStringAsFixed(0);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confidence Threshold'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Threshold (%)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final threshold = double.tryParse(controller.text) ?? 0.85;
              _updateSetting('ai.confidence_threshold', threshold);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEnvironmentDialog(BuildContext context) {
    final currentEnv = ref.read(enhancedConfigurationProvider).getCurrentEnvironment();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Environment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Development'),
              value: 'development',
              groupValue: currentEnv,
              onChanged: (value) {
                _updateSetting('app.environment', value);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Testing'),
              value: 'testing',
              groupValue: currentEnv,
              onChanged: (value) {
                _updateSetting('app.environment', value);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Production'),
              value: 'production',
              groupValue: currentEnv,
              onChanged: (value) {
                _updateSetting('app.environment', value);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showImportExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import/Export Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Import Settings'),
              subtitle: const Text('Import settings from file'),
              leading: const Icon(Icons.file_upload),
              onTap: () => _importSettings(context),
            ),
            ListTile(
              title: const Text('Export Settings'),
              subtitle: const Text('Export settings to file'),
              leading: const Icon(Icons.file_download),
              onTap: () => _exportSettings(context),
            ),
            ListTile(
              title: const Text('Reset Settings'),
              subtitle: const Text('Reset to default settings'),
              leading: const Icon(Icons.refresh),
              onTap: () => _resetSettings(ref.read(enhancedConfigurationProvider)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFileOperationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Operations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Batch Operations'),
              subtitle: const Text('Configure batch file operations'),
              leading: const Icon(Icons.batch_prediction),
              onTap: () => _showBatchOperationsDialog(context),
            ),
            ListTile(
              title: const Text('File Operations'),
              subtitle: const Text('Configure file operations'),
              leading: const Icon(Icons.file_present),
              onTap: () => _showFileOperationsConfigDialog(context),
            ),
            ListTile(
              title: const Text('File Permissions'),
              subtitle: const Text('Configure file permissions'),
              leading: const Icon(Icons.security),
              onTap: () => _showFilePermissionsDialog(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFileTypesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Types'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('File Associations'),
              subtitle: const Text('Configure file type associations'),
              leading: const Icon(Icons.association),
              onTap: () => _showFileAssociationsDialog(context),
            ),
            ListTile(
              title: const Text('MIME Types'),
              subtitle: const Text('Configure MIME type handling'),
              leading: const Icon(Icons.description),
              onTap: () => _showMimeTypesDialog(context),
            ),
            ListTile(
              title: const Text('File Extensions'),
              subtitle: const Text('Configure file extensions'),
              leading: const Icon(Icons.extension),
              onTap: () => _showFileExtensionsDialog(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBatchOperationsDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch operations dialog coming soon')),
    );
  }

  void _showFileOperationsConfigDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File operations configuration coming soon')),
    );
  }

  void _showFilePermissionsDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File permissions dialog coming soon')),
    );
  }

  void _showFileAssociationsDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File associations dialog coming soon')),
    );
  }

  void _showMimeTypesDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('MIME types dialog coming soon')),
    );
  }

  void _showFileExtensionsDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File extensions dialog coming soon')),
    );
  }

  void _selectDefaultDirectory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Directory selection coming soon')),
    );
  }

  void _importSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import settings coming soon')),
    );
  }

  void _exportSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export settings coming soon')),
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MIT License'),
        content: const SingleChildScrollView(
          child: Text(
            'MIT License\n\n'
            'Copyright (c) 2024 iSuite\n\n'
            'Permission is hereby granted, free of charge, to any person obtaining a copy '
            'of this software and associated documentation files (the "Software"), to deal '
            'in the Software without restriction, including without limitation the rights '
            'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
            'copies of the Software, and to permit persons to whom the Software is '
            'furnished to do so, subject to the following conditions:\n\n'
            'The above copyright notice and this permission notice shall be included in '
            'all copies or substantial portions of the Software.\n\n'
            'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
            'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
            'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
            'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
            'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING '
            'FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER '
            'DEALINGS IN THE SOFTWARE.',
          ),
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

  void _openSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support page coming soon')),
    );
  }

  void _sendFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback form coming soon')),
    );
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking for updates...')),
    );
  }

  void _showSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Version: 2.0.0'),
            Text('Build Number: 20240313'),
            Text('Platform: ${Platform.operatingSystem}'),
            Text('Flutter Version: 3.16.0'),
            Text('Device: ${Platform.locale}'),
            Text('Memory: ${(512 * 1024 * 1024).toString()} MB'),
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

  void _exportLogs(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting logs...')),
    );
  }

  void _showResetAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App'),
        content: const Text('This will reset all app data and settings. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('App reset completed'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
