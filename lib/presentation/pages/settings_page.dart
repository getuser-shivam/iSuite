import 'package:flutter/material.dart';

/// Settings Page - App Configuration and Preferences
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Settings state
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _autoBackup = false;
  bool _analyticsEnabled = true;
  String _language = 'English';
  String _theme = 'System';
  double _fontSize = 14.0;

  final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];
  final List<String> _themes = ['Light', 'Dark', 'System'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          _buildThemeSetting(),
          _buildLanguageSetting(),
          _buildFontSizeSetting(),

          _buildSectionHeader('Behavior'),
          _buildNotificationSetting(),
          _buildAutoBackupSetting(),
          _buildAnalyticsSetting(),

          _buildSectionHeader('Storage'),
          _buildStorageInfo(),
          _buildClearCacheSetting(),
          _buildBackupSettings(),

          _buildSectionHeader('Network'),
          _buildNetworkSettings(),
          _buildSecuritySettings(),

          _buildSectionHeader('About'),
          _buildAboutSection(),
          _buildVersionInfo(),
          _buildSupportSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeSetting() {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Theme'),
      subtitle: Text(_theme),
      trailing: DropdownButton<String>(
        value: _theme,
        items: _themes.map((theme) {
          return DropdownMenuItem(
            value: theme,
            child: Text(theme),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _theme = value);
            _applyTheme(value);
          }
        },
      ),
    );
  }

  Widget _buildLanguageSetting() {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Language'),
      subtitle: Text(_language),
      trailing: DropdownButton<String>(
        value: _language,
        items: _languages.map((lang) {
          return DropdownMenuItem(
            value: lang,
            child: Text(lang),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _language = value);
            _applyLanguage(value);
          }
        },
      ),
    );
  }

  Widget _buildFontSizeSetting() {
    return ListTile(
      leading: const Icon(Icons.text_fields),
      title: const Text('Font Size'),
      subtitle: Text('${_fontSize.toInt()}pt'),
      trailing: SizedBox(
        width: 120,
        child: Slider(
          value: _fontSize,
          min: 10,
          max: 20,
          divisions: 10,
          label: '${_fontSize.toInt()}pt',
          onChanged: (value) {
            setState(() => _fontSize = value);
          },
          onChangeEnd: (value) => _applyFontSize(value),
        ),
      ),
    );
  }

  Widget _buildNotificationSetting() {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications),
      title: const Text('Notifications'),
      subtitle: const Text('Enable push notifications'),
      value: _notificationsEnabled,
      onChanged: (value) {
        setState(() => _notificationsEnabled = value);
        _applyNotificationSetting(value);
      },
    );
  }

  Widget _buildAutoBackupSetting() {
    return SwitchListTile(
      secondary: const Icon(Icons.backup),
      title: const Text('Auto Backup'),
      subtitle: const Text('Automatically backup data'),
      value: _autoBackup,
      onChanged: (value) {
        setState(() => _autoBackup = value);
        _applyAutoBackupSetting(value);
      },
    );
  }

  Widget _buildAnalyticsSetting() {
    return SwitchListTile(
      secondary: const Icon(Icons.analytics),
      title: const Text('Analytics'),
      subtitle: const Text('Help improve the app'),
      value: _analyticsEnabled,
      onChanged: (value) {
        setState(() => _analyticsEnabled = value);
        _applyAnalyticsSetting(value);
      },
    );
  }

  Widget _buildStorageInfo() {
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('Storage Usage'),
      subtitle: const Text('2.4 GB used of 64 GB'),
      trailing: ElevatedButton(
        onPressed: _showStorageDetails,
        child: const Text('Details'),
      ),
    );
  }

  Widget _buildClearCacheSetting() {
    return ListTile(
      leading: const Icon(Icons.cleaning_services),
      title: const Text('Clear Cache'),
      subtitle: const Text('Free up storage space'),
      trailing: ElevatedButton(
        onPressed: _clearCache,
        child: const Text('Clear'),
      ),
    );
  }

  Widget _buildBackupSettings() {
    return ListTile(
      leading: const Icon(Icons.backup),
      title: const Text('Backup & Restore'),
      subtitle: const Text('Manage data backups'),
      trailing: ElevatedButton(
        onPressed: _manageBackups,
        child: const Text('Manage'),
      ),
    );
  }

  Widget _buildNetworkSettings() {
    return ListTile(
      leading: const Icon(Icons.wifi),
      title: const Text('Network Settings'),
      subtitle: const Text('WiFi, mobile data, sync'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showNetworkSettings,
    );
  }

  Widget _buildSecuritySettings() {
    return ListTile(
      leading: const Icon(Icons.security),
      title: const Text('Security & Privacy'),
      subtitle: const Text('Passwords, encryption, permissions'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showSecuritySettings,
    );
  }

  Widget _buildAboutSection() {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('About iSuite'),
      subtitle: const Text('File & Network Manager'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showAboutDialog,
    );
  }

  Widget _buildVersionInfo() {
    return ListTile(
      leading: const Icon(Icons.system_update),
      title: const Text('Version'),
      subtitle: const Text('iSuite v1.0.0 (Build 2024.01.15)'),
      trailing: ElevatedButton(
        onPressed: _checkForUpdates,
        child: const Text('Check'),
      ),
    );
  }

  Widget _buildSupportSection() {
    return ListTile(
      leading: const Icon(Icons.help),
      title: const Text('Help & Support'),
      subtitle: const Text('FAQ, contact, feedback'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showSupportOptions,
    );
  }

  void _applyTheme(String theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Theme changed to $theme')),
    );
  }

  void _applyLanguage(String language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language changed to $language')),
    );
  }

  void _applyFontSize(double size) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Font size changed to ${size.toInt()}pt')),
    );
  }

  void _applyNotificationSetting(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notifications ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  void _applyAutoBackupSetting(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Auto backup ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  void _applyAnalyticsSetting(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Analytics ${enabled ? 'enabled' : 'disabled'}')),
    );
  }

  void _showStorageDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Details'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents: 1.2 GB'),
            Text('Images: 800 MB'),
            Text('Videos: 200 MB'),
            Text('Cache: 150 MB'),
            Text('Other: 50 MB'),
            Divider(),
            Text('Total: 2.4 GB'),
            Text('Available: 61.6 GB'),
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

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will delete temporary files and free up storage space. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _performCacheClear();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _performCacheClear() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully!')),
    );
  }

  void _manageBackups() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Management'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.backup),
              title: Text('Create Backup'),
              subtitle: Text('Backup all data now'),
            ),
            ListTile(
              leading: Icon(Icons.restore),
              title: Text('Restore Backup'),
              subtitle: Text('Restore from previous backup'),
            ),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('Schedule Backups'),
              subtitle: Text('Set automatic backup schedule'),
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

  void _showNetworkSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('WiFi Only'),
              subtitle: const Text('Use WiFi for large transfers only'),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Auto Sync'),
              subtitle: const Text('Automatically sync data'),
              value: true,
              onChanged: (value) {},
            ),
            ListTile(
              title: const Text('Bandwidth Limit'),
              subtitle: const Text('Limit transfer speed'),
              trailing: const Text('Unlimited'),
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

  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security & Privacy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Biometric Lock'),
              subtitle: const Text('Use fingerprint/face unlock'),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('File Encryption'),
              subtitle: const Text('Encrypt sensitive files'),
              value: true,
              onChanged: (value) {},
            ),
            ListTile(
              title: const Text('Change Password'),
              subtitle: const Text('Update app password'),
              trailing: const Icon(Icons.chevron_right),
            ),
            ListTile(
              title: const Text('Privacy Settings'),
              subtitle: const Text('Manage data sharing'),
              trailing: const Icon(Icons.chevron_right),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About iSuite'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('iSuite - Enterprise File & Network Manager'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            Text('Build: 2024.01.15'),
            SizedBox(height: 8),
            Text('Features:'),
            Text('• Advanced File Management'),
            Text('• Network Device Discovery'),
            Text('• FTP/SMB/WebDAV Support'),
            Text('• Real-time Sync'),
            Text('• Security & Encryption'),
            Text('• Cross-platform Compatibility'),
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

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking for updates...')),
    );

    // Simulate update check
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have the latest version')),
        );
      }
    });
  }

  void _showSupportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('FAQ'),
              subtitle: const Text('Frequently asked questions'),
              onTap: () => _openFAQ(),
            ),
            ListTile(
              leading: const Icon(Icons.contact_support),
              title: const Text('Contact Support'),
              subtitle: const Text('Get help from our team'),
              onTap: () => _contactSupport(),
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Send Feedback'),
              subtitle: const Text('Help us improve'),
              onTap: () => _sendFeedback(),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Report Bug'),
              subtitle: const Text('Found an issue?'),
              onTap: () => _reportBug(),
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

  void _openFAQ() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening FAQ...')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening support chat...')),
    );
  }

  void _sendFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening feedback form...')),
    );
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening bug report form...')),
    );
  }
}
