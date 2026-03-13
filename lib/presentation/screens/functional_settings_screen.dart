import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/config_provider.dart';
import '../widgets/common/parameterized_app_bar.dart';
import '../widgets/common/parameterized_bottom_navigation_bar.dart';

/// Functional Settings Screen
/// 
/// Settings screen with working configuration management
/// Features: Real-time settings, functional toggles, system configuration
/// Performance: Optimized state management, efficient updates
/// Architecture: Consumer widget, provider pattern, responsive design
class FunctionalSettingsScreen extends ConsumerStatefulWidget {
  const FunctionalSettingsScreen({super.key});

  @override
  ConsumerState<FunctionalSettingsScreen> createState() => _FunctionalSettingsScreenState();
}

class _FunctionalSettingsScreenState extends ConsumerState<FunctionalSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(configurationProvider);
    
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
              value: configProvider._config.getParameter('ui.theme_mode', defaultValue: 'system') == 'dark',
              onChanged: (value) {
                _updateSetting('ui.theme_mode', value ? 'dark' : 'light');
              },
            ),
            
            // Language
            ListTile(
              title: const Text('Language'),
              subtitle: Text(configProvider._config.getParameter('ui.language', defaultValue: 'en')),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLanguageDialog(context),
            ),
            
            // Auto-save
            SwitchListTile(
              title: const Text('Auto-save'),
              subtitle: const Text('Automatically save changes'),
              value: configProvider._config.getParameter('ui.auto_save', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ui.auto_save', value);
              },
            ),
            
            // Notifications
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Enable system notifications'),
              value: configProvider._config.getParameter('ui.enable_notifications', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ui.enable_notifications', value);
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
              subtitle: Text(configProvider._config.getParameter('file_manager.default_directory', defaultValue: '/storage/emulated/0')),
              trailing: const Icon(Icons.folder),
              onTap: () => _selectDefaultDirectory(context),
            ),
            
            // Show Hidden Files
            SwitchListTile(
              title: const Text('Show Hidden Files'),
              subtitle: const Text('Display hidden files and folders'),
              value: configProvider._config.getParameter('file_manager.show_hidden_files', defaultValue: false),
              onChanged: (value) {
                _updateSetting('file_manager.show_hidden_files', value);
              },
            ),
            
            // File Preview
            SwitchListTile(
              title: const Text('File Preview'),
              subtitle: const Text('Enable file preview in list'),
              value: configProvider._config.getParameter('file_manager.enable_preview', defaultValue: true),
              onChanged: (value) {
                _updateSetting('file_manager.enable_preview', value);
              },
            ),
            
            // Auto-organize
            SwitchListTile(
              title: const Text('Auto-organize'),
              subtitle: const Text('Automatically organize files'),
              value: configProvider._config.getParameter('file_manager.auto_organize', defaultValue: false),
              onChanged: (value) {
                _updateSetting('file_manager.auto_organize', value);
              },
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
              value: configProvider._config.getParameter('network.enable_wifi_direct', defaultValue: true),
              onChanged: (value) {
                _updateSetting('network.enable_wifi_direct', value);
              },
            ),
            
            // FTP Server
            SwitchListTile(
              title: const Text('FTP Server'),
              subtitle: const Text('Enable FTP server'),
              value: configProvider._config.getParameter('network.enable_ftp_server', defaultValue: false),
              onChanged: (value) {
                _updateSetting('network.enable_ftp_server', value);
              },
            ),
            
            // WebDAV
            SwitchListTile(
              title: const Text('WebDAV'),
              subtitle: const Text('Enable WebDAV server'),
              value: configProvider._config.getParameter('network.enable_webdav', defaultValue: false),
              onChanged: (value) {
                _updateSetting('network.enable_webdav', value);
              },
            ),
            
            // Auto-discovery
            SwitchListTile(
              title: const Text('Auto-discovery'),
              subtitle: const Text('Automatically discover devices'),
              value: configProvider._config.getParameter('network.enable_auto_discovery', defaultValue: true),
              onChanged: (value) {
                _updateSetting('network.enable_auto_discovery', value);
              },
            ),
            
            // Connection Timeout
            ListTile(
              title: const Text('Connection Timeout'),
              subtitle: Text('${configProvider._config.getParameter('network.connection_timeout', defaultValue: 30)} seconds'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showTimeoutDialog(context),
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
              value: configProvider._config.getParameter('ai.enable_features', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ai.enable_features', value);
              },
            ),
            
            // Smart Categorization
            SwitchListTile(
              title: const Text('Smart Categorization'),
              subtitle: const Text('AI-powered file categorization'),
              value: configProvider._config.getParameter('ai.enable_categorization', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ai.enable_categorization', value);
              },
            ),
            
            // Duplicate Detection
            SwitchListTile(
              title: const Text('Duplicate Detection'),
              subtitle: const Text('AI-powered duplicate detection'),
              value: configProvider._config.getParameter('ai.enable_duplicate_detection', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ai.enable_duplicate_detection', value);
              },
            ),
            
            // Smart Search
            SwitchListTile(
              title: const Text('Smart Search'),
              subtitle: const Text('AI-powered search'),
              value: configProvider._config.getParameter('ai.enable_smart_search', defaultValue: true),
              onChanged: (value) {
                _updateSetting('ai.enable_smart_search', value);
              },
            ),
            
            // API Key
            ListTile(
              title: const Text('AI API Key'),
              subtitle: const Text('Configure AI service API key'),
              trailing: const Icon(Icons.key),
              onTap: () => _showAPIKeyDialog(context),
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
              value: configProvider._config.getParameter('security.enable_biometric', defaultValue: false),
              onChanged: (value) {
                _updateSetting('security.enable_biometric', value);
              },
            ),
            
            // Encryption
            SwitchListTile(
              title: const Text('File Encryption'),
              subtitle: const Text('Encrypt sensitive files'),
              value: configProvider._config.getParameter('security.enable_encryption', defaultValue: false),
              onChanged: (value) {
                _updateSetting('security.enable_encryption', value);
              },
            ),
            
            // Secure Sharing
            SwitchListTile(
              title: const Text('Secure Sharing'),
              subtitle: const Text('Use secure protocols for sharing'),
              value: configProvider._config.getParameter('security.enable_secure_sharing', defaultValue: true),
              onChanged: (value) {
                _updateSetting('security.enable_secure_sharing', value);
              },
            ),
            
            // Audit Logging
            SwitchListTile(
              title: const Text('Audit Logging'),
              subtitle: const Text('Log all file operations'),
              value: configProvider._config.getParameter('security.enable_audit_logging', defaultValue: true),
              onChanged: (value) {
                _updateSetting('security.enable_audit_logging', value);
              },
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
              value: configProvider._config.getParameter('performance.enable_caching', defaultValue: true),
              onChanged: (value) {
                _updateSetting('performance.enable_caching', value);
              },
            ),
            
            // Parallel Processing
            SwitchListTile(
              title: const Text('Parallel Processing'),
              subtitle: const Text('Use multiple CPU cores'),
              value: configProvider._config.getParameter('performance.enable_parallel_processing', defaultValue: true),
              onChanged: (value) {
                _updateSetting('performance.enable_parallel_processing', value);
              },
            ),
            
            // Background Sync
            SwitchListTile(
              title: const Text('Background Sync'),
              subtitle: const Text('Sync files in background'),
              value: configProvider._config.getParameter('performance.enable_background_sync', defaultValue: true),
              onChanged: (value) {
                _updateSetting('performance.enable_background_sync', value);
              },
            ),
            
            // Cache Size
            ListTile(
              title: const Text('Cache Size'),
              subtitle: Text('${configProvider._config.getParameter('performance.cache_size_mb', defaultValue: 100)} MB'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showCacheSizeDialog(context),
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
          ],
        ),
      ),
    );
  }

  // Settings update methods
  void _updateSetting(String key, dynamic value) {
    final configProvider = ref.read(configurationProvider);
    configProvider._config.setParameter(key, value);
    setState(() {});
  }

  void _saveSettings(configProvider) {
    configProvider._config.saveConfiguration();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
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
              configProvider._config.resetToDefaults();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Colors.orange,
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

  void _showTimeoutDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = ref.read(configurationProvider)._config.getParameter('network.connection_timeout', defaultValue: 30).toString();
    
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

  void _showCacheSizeDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = ref.read(configurationProvider)._config.getParameter('performance.cache_size_mb', defaultValue: 100).toString();
    
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

  void _showAPIKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    controller.text = ref.read(configurationProvider)._config.getParameter('ai.api_key', defaultValue: '');
    
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

  // Action methods
  void _selectDefaultDirectory(BuildContext context) {
    // Implement directory selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Directory selection coming soon')),
    );
  }

  void _openSupport() {
    // Open support page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support page coming soon')),
    );
  }

  void _sendFeedback() {
    // Open feedback form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback form coming soon')),
    );
  }
}
