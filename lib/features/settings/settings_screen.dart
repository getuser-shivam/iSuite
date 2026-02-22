import 'package:flutter/material.dart';
import '../../../core/central_config.dart';
import 'package:provider/provider.dart';
import '../../../core/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CentralConfig _config = CentralConfig.instance;
  late String _language;
  late int _networkTimeout;
  late int _batchSize;
  late bool _autoSave;
  late String _aiResponseStyle;
  late bool _smartSuggestions;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'en';
      _networkTimeout = prefs.getInt('networkTimeout') ?? 30;
      _batchSize = prefs.getInt('batchSize') ?? 100;
      _autoSave = prefs.getBool('autoSave') ?? true;
      _aiResponseStyle = prefs.getString('aiResponseStyle') ?? 'detailed';
      _smartSuggestions = prefs.getBool('smartSuggestions') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language);
    await prefs.setInt('networkTimeout', _networkTimeout);
    await prefs.setInt('batchSize', _batchSize);
    await prefs.setBool('autoSave', _autoSave);
    await prefs.setString('aiResponseStyle', _aiResponseStyle);
    await prefs.setBool('smartSuggestions', _smartSuggestions);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: _config.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        elevation: _config.cardElevation,
      ),
      body: ListView(
        padding: EdgeInsets.all(_config.defaultPadding),
        children: [
          _buildSectionHeader('General Settings'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => _buildSwitchTile(
              title: 'Dark Theme',
              subtitle: 'Enable dark mode for better visibility in low light',
              value: themeProvider.isDarkTheme,
              onChanged: (value) => themeProvider.toggleTheme(),
            ),
          ),
          _buildDropdownTile(
            title: 'Language',
            subtitle: 'Select your preferred language',
            value: _language,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'es', child: Text('Español')),
              DropdownMenuItem(value: 'fr', child: Text('Français')),
            ],
            onChanged: (value) => setState(() => _language = value ?? 'en'),
          ),
          _buildSwitchTile(
            title: 'Auto Save',
            subtitle: 'Automatically save changes and preferences',
            value: _autoSave,
            onChanged: (value) => setState(() => _autoSave = value),
          ),

          SizedBox(height: _config.defaultPadding),

          _buildSectionHeader('Network Settings'),
          _buildSliderTile(
            title: 'Network Timeout',
            subtitle: 'Timeout for network operations (seconds)',
            value: _networkTimeout.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            onChanged: (value) => setState(() => _networkTimeout = value.toInt()),
          ),
          _buildSliderTile(
            title: 'Batch Size',
            subtitle: 'Number of items to process in batches',
            value: _batchSize.toDouble(),
            min: 10,
            max: 500,
            divisions: 49,
            onChanged: (value) => setState(() => _batchSize = value.toInt()),
          ),

          SizedBox(height: _config.defaultPadding),

          _buildSectionHeader('AI Assistant Settings'),
          _buildDropdownTile(
            title: 'Response Style',
            subtitle: 'Choose AI assistant response preferences',
            value: _aiResponseStyle,
            items: const [
              DropdownMenuItem(value: 'concise', child: Text('Concise')),
              DropdownMenuItem(value: 'detailed', child: Text('Detailed')),
              DropdownMenuItem(value: 'step_by_step', child: Text('Step by Step')),
            ],
            onChanged: (value) => setState(() => _aiResponseStyle = value ?? 'detailed'),
          ),
          _buildTextFieldTile(
            title: 'AI API Key',
            subtitle: 'Configure API key for advanced AI features',
            initialValue: _config.getParameter('ai.api_key', defaultValue: ''),
            obscureText: true,
            onChanged: (value) => _config.setParameter('ai.api_key', value),
          ),
          _buildSwitchTile(
            title: 'Smart Suggestions',
            subtitle: 'Enable AI-powered file organization suggestions',
            value: _smartSuggestions,
            onChanged: (value) => setState(() => _smartSuggestions = value),
          ),

          SizedBox(height: _config.defaultPadding),

          _buildSectionHeader('About'),
          _buildInfoTile(
            title: 'Version',
            subtitle: '1.0.0',
          ),
          _buildInfoTile(
            title: 'Build Number',
            subtitle: '1',
          ),
          _buildInfoTile(
            title: 'Framework',
            subtitle: 'Flutter',
          ),
          _buildInfoTile(
            title: 'Database',
            subtitle: 'SQLite & Supabase',
          ),

          SizedBox(height: _config.defaultPadding * 2),

          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: Icon(Icons.save, color: _config.surfaceColor),
            label: Text('Save Settings', style: TextStyle(color: _config.surfaceColor)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _config.primaryColor,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_config.borderRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _config.defaultPadding / 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _config.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: _config.cardElevation / 2,
      margin: EdgeInsets.only(bottom: _config.defaultPadding / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_config.borderRadius),
      ),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(color: _config.primaryColor)),
        subtitle: Text(subtitle, style: TextStyle(color: _config.primaryColor.withOpacity(0.7))),
        value: value,
        onChanged: onChanged,
        activeColor: _config.accentColor,
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Card(
      elevation: _config.cardElevation / 2,
      margin: EdgeInsets.only(bottom: _config.defaultPadding / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_config.borderRadius),
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(color: _config.primaryColor)),
        subtitle: Text(subtitle, style: TextStyle(color: _config.primaryColor.withOpacity(0.7))),
        trailing: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(color: _config.primaryColor),
          dropdownColor: _config.surfaceColor,
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      elevation: _config.cardElevation / 2,
      margin: EdgeInsets.only(bottom: _config.defaultPadding / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_config.borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(_config.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: _config.primaryColor, fontWeight: FontWeight.w500)),
            Text(subtitle, style: TextStyle(color: _config.primaryColor.withOpacity(0.7))),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: value.toStringAsFixed(0),
              activeColor: _config.primaryColor,
              onChanged: onChanged,
            ),
            Text('${value.toStringAsFixed(0)}', style: TextStyle(color: _config.primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldTile({
    required String title,
    required String subtitle,
    required String initialValue,
    required bool obscureText,
    required ValueChanged<String> onChanged,
  }) {
    return Card(
      elevation: _config.cardElevation / 2,
      margin: EdgeInsets.only(bottom: _config.defaultPadding / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_config.borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(_config.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: _config.primaryColor, fontWeight: FontWeight.w500)),
            Text(subtitle, style: TextStyle(color: _config.primaryColor.withOpacity(0.7))),
            SizedBox(height: _config.defaultPadding / 2),
            TextFormField(
              initialValue: initialValue,
              obscureText: obscureText,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_config.borderRadius),
                ),
                filled: true,
                fillColor: _config.surfaceColor,
              ),
              onChanged: onChanged,
              style: TextStyle(color: _config.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    // TODO: Implement settings persistence
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: _config.primaryColor,
      ),
    );
  }
}
