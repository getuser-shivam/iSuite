import 'package:flutter/material.dart';
import '../../core/central_config.dart';
import '../../core/component_factory.dart';

/// Enhanced File Management Screen with centralized parameterization
class FileManagementScreen extends StatefulWidget {
  const FileManagementScreen({Key? key}) : super(key: key);

  @override
  State<FileManagementScreen> createState() => _FileManagementScreenState();
}

class _FileManagementScreenState extends State<FileManagementScreen>
    with ParameterizedComponent {
  late Map<String, dynamic> _configParameters;

  @override
  void initState() {
    super.initState();
    _initializeFromConfig();
  }

  Future<void> _initializeFromConfig() async {
    await CentralConfig.instance.initialize();

    setState(() {
      _configParameters = {
        'max_file_size': CentralConfig.instance
            .getParameter('max_file_size', 100 * 1024 * 1024),
        'allowed_file_types': CentralConfig.instance.getParameter(
            'allowed_file_types', ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png']),
        'enable_encryption':
            CentralConfig.instance.getParameter('enable_encryption', false),
        'theme_mode':
            CentralConfig.instance.getParameter('theme_mode', 'system'),
        'primary_color':
            CentralConfig.instance.getParameter('primary_color', '#1976D2'),
      };
    });
  }

  @override
  void updateParameters(Map<String, dynamic> parameters) {
    setState(() {
      _configParameters.addAll(parameters);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'iSuite File Manager',
          style: TextStyle(
            color: _configParameters['theme_mode'] == 'dark'
                ? Colors.white
                : Colors.black,
          ),
        ),
        backgroundColor: _configParameters['theme_mode'] == 'dark'
            ? Colors.grey[800]
            : Colors.white,
        foregroundColor: _configParameters['theme_mode'] == 'dark'
            ? Colors.white
            : Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 100,
              color: _configParameters['primary_color'] is String
                  ? _parseColor(_configParameters['primary_color'])
                  : Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              'iSuite File Manager',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _configParameters['theme_mode'] == 'dark'
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Enterprise-grade file management',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Centralized Configuration:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildConfigRow('Max File Size',
                      '${(_configParameters['max_file_size'] as int) / (1024 * 1024)} MB'),
                  _buildConfigRow('Allowed Types',
                      '${(_configParameters['allowed_file_types'] as List<String>).length} types'),
                  _buildConfigRow(
                      'Encryption',
                      _configParameters['enable_encryption']
                          ? 'Enabled'
                          : 'Disabled'),
                  _buildConfigRow('Theme', _configParameters['theme_mode']),
                  _buildConfigRow(
                      'Primary Color', _configParameters['primary_color']),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showParameterDialog,
              child: const Text('Update Parameters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
            int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
    }
  }

  void _showParameterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Parameters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _configParameters['theme_mode'],
              decoration: const InputDecoration(labelText: 'Theme Mode'),
              items: ['system', 'light', 'dark'].map((theme) {
                return DropdownMenuItem(value: theme, child: Text(theme));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  CentralConfig.instance.setParameter('theme_mode', value);
                  updateParameters({'theme_mode': value});
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Encryption'),
              value: _configParameters['enable_encryption'],
              onChanged: (value) {
                CentralConfig.instance.setParameter('enable_encryption', value);
                updateParameters({'enable_encryption': value});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Mixin for parameterized components
mixin ParameterizedComponent<T extends StatefulWidget> on State<T> {
  void updateParameters(Map<String, dynamic> parameters);
}
