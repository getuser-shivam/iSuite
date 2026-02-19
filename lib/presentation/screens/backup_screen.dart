import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/backup_provider.dart';
import '../../domain/models/backup.dart';
import '../../core/utils.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _backupNameController = TextEditingController();
  final TextEditingController _backupDescriptionController = TextEditingController();
  final TextEditingController _restoreDataController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  BackupType _selectedBackupType = BackupType.full;
  BackupType _selectedRestoreType = BackupType.full;
  bool _encryptBackup = false;
  bool _hasPassword = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _backupNameController.dispose();
    _backupDescriptionController.dispose();
    _restoreDataController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create Backup', icon: Icon(Icons.backup)),
            Tab(text: 'Restore Backup', icon: Icon(Icons.restore)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateBackupTab(),
          _buildRestoreBackupTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCreateBackupTab() {
    return Consumer<BackupProvider>(
      builder: (context, backupProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Backup',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Backup type selection
              const Text('Backup Type', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<BackupType>(
                value: _selectedBackupType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: BackupType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getBackupTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedBackupType = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Backup name
              TextField(
                controller: _backupNameController,
                decoration: const InputDecoration(
                  labelText: 'Backup Name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Backup description
              TextField(
                controller: _backupDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Encryption options
              SwitchListTile(
                title: const Text('Encrypt Backup'),
                subtitle: const Text('Protect backup with password'),
                value: _encryptBackup,
                onChanged: (value) {
                  setState(() => _encryptBackup = value);
                },
              ),

              if (_encryptBackup) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],

              const SizedBox(height: 24),

              // Progress indicator
              if (backupProvider.isLoading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  backupProvider.progressMessage ?? 'Processing...',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],

              // Error message
              if (backupProvider.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          backupProvider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Create backup button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: backupProvider.isLoading ? null : _createBackup,
                  icon: const Icon(Icons.backup),
                  label: const Text('Create Backup'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Statistics
              _buildStatisticsCard(backupProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestoreBackupTab() {
    return Consumer<BackupProvider>(
      builder: (context, backupProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Restore Backup',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: Restoring will add data to existing items. Make sure to backup current data first.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Restore type selection
              const Text('Restore Type', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<BackupType>(
                value: _selectedRestoreType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: BackupType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getBackupTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRestoreType = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Backup data input
              TextField(
                controller: _restoreDataController,
                decoration: const InputDecoration(
                  labelText: 'Backup Data (JSON)',
                  border: OutlineInputBorder(),
                  hintText: 'Paste your backup JSON data here',
                ),
                maxLines: 10,
              ),

              const SizedBox(height: 16),

              // Password for encrypted backups
              SwitchListTile(
                title: const Text('Backup is Encrypted'),
                subtitle: const Text('Enter password to decrypt'),
                value: _hasPassword,
                onChanged: (value) {
                  setState(() => _hasPassword = value);
                },
              ),

              if (_hasPassword) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],

              const SizedBox(height: 16),

              // Validate button
              OutlinedButton.icon(
                onPressed: _restoreDataController.text.isEmpty ? null : _validateBackup,
                icon: const Icon(Icons.check_circle),
                label: const Text('Validate Backup'),
              ),

              const SizedBox(height: 16),

              // Progress indicator
              if (backupProvider.isLoading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  backupProvider.progressMessage ?? 'Processing...',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],

              // Error message
              if (backupProvider.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          backupProvider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Restore backup button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (backupProvider.isLoading || _restoreDataController.text.isEmpty)
                      ? null
                      : _restoreBackup,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore Backup'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<BackupProvider>(
      builder: (context, backupProvider, child) {
        if (backupProvider.backupHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No backup history',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Create Your First Backup'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: backupProvider.backupHistory.length,
          itemBuilder: (context, index) {
            final backup = backupProvider.backupHistory[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getBackupStatusIcon(backup.status),
                  color: _getBackupStatusColor(backup.status),
                ),
                title: Text(backup.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_getBackupTypeLabel(backup.type)} • ${backup.formattedSize}'),
                    Text(backup.formattedDate),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleBackupAction(value, backup),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View Details'),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Text('Export'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
                onTap: () => _showBackupDetails(backup),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatisticsCard(BackupProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backup Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Backups',
                    provider.completedBackups.length.toString(),
                    Icons.backup,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Size',
                    provider.formattedTotalBackupSize,
                    Icons.storage,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.latestBackup != null) ...[
              const Text(
                'Latest Backup',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                '${provider.latestBackup!.name} • ${provider.latestBackup!.formattedDate}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _createBackup() async {
    final name = _backupNameController.text.trim();
    final description = _backupDescriptionController.text.trim();
    final password = _encryptBackup ? _passwordController.text : null;

    final backupData = await Provider.of<BackupProvider>(context, listen: false)
        .createBackup(
      type: _selectedBackupType,
      name: name,
      description: description,
      encrypt: _encryptBackup,
      password: password,
    );

    if (backupData != null && mounted) {
      _showBackupCreatedDialog(backupData);
    }
  }

  void _restoreBackup() async {
    final success = await Provider.of<BackupProvider>(context, listen: false)
        .restoreBackup(
      backupData: _restoreDataController.text,
      type: _selectedRestoreType,
      password: _hasPassword ? _passwordController.text : null,
    );

    if (success && mounted) {
      AppUtils.showSuccessSnackBar(context, 'Backup restored successfully');
      _restoreDataController.clear();
      _passwordController.clear();
      setState(() => _hasPassword = false);
    }
  }

  void _validateBackup() async {
    final isValid = await Provider.of<BackupProvider>(context, listen: false)
        .validateBackup(_restoreDataController.text);

    if (mounted) {
      if (isValid) {
        final stats = await Provider.of<BackupProvider>(context, listen: false)
            .getBackupStats(_restoreDataController.text);

        _showBackupStatsDialog(stats);
      } else {
        AppUtils.showErrorSnackBar(context, 'Invalid backup data');
      }
    }
  }

  void _showBackupCreatedDialog(String backupData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Created'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Backup data (copy and save securely):'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: SelectableText(
                    backupData,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
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

  void _showBackupStatsDialog(Map<String, int> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Contents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: stats.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_getStatLabel(entry.key)),
                  Text('${entry.value} items'),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBackupDetails(BackupModel backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(backup.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${_getBackupTypeLabel(backup.type)}'),
              Text('Status: ${backup.status.name}'),
              Text('Size: ${backup.formattedSize}'),
              Text('Created: ${backup.formattedDate}'),
              if (backup.description != null) Text('Description: ${backup.description}'),
              if (backup.isEncrypted) const Text('Encrypted: Yes'),
              if (backup.completedAt != null)
                Text('Duration: ${backup.duration.inSeconds}s'),
            ],
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

  void _handleBackupAction(String action, BackupModel backup) {
    switch (action) {
      case 'view':
        _showBackupDetails(backup);
        break;
      case 'export':
        // Export functionality
        AppUtils.showSuccessSnackBar(context, 'Export functionality coming soon');
        break;
      case 'delete':
        _showDeleteBackupDialog(backup);
        break;
    }
  }

  void _showDeleteBackupDialog(BackupModel backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Are you sure you want to delete "${backup.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<BackupProvider>(context, listen: false)
                  .deleteBackup(backup.id);
              Navigator.of(context).pop();
              AppUtils.showSuccessSnackBar(context, 'Backup deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getBackupTypeLabel(BackupType type) {
    switch (type) {
      case BackupType.full:
        return 'Full Backup';
      case BackupType.tasks:
        return 'Tasks Only';
      case BackupType.notes:
        return 'Notes Only';
      case BackupType.files:
        return 'Files Only';
      case BackupType.calendar:
        return 'Calendar Only';
      case BackupType.custom:
        return 'Custom Backup';
    }
  }

  IconData _getBackupStatusIcon(BackupStatus status) {
    switch (status) {
      case BackupStatus.pending:
        return Icons.schedule;
      case BackupStatus.inProgress:
        return Icons.sync;
      case BackupStatus.completed:
        return Icons.check_circle;
      case BackupStatus.failed:
        return Icons.error;
    }
  }

  Color _getBackupStatusColor(BackupStatus status) {
    switch (status) {
      case BackupStatus.pending:
        return Colors.grey;
      case BackupStatus.inProgress:
        return Colors.blue;
      case BackupStatus.completed:
        return Colors.green;
      case BackupStatus.failed:
        return Colors.red;
    }
  }

  String _getStatLabel(String key) {
    switch (key) {
      case 'tasks':
        return 'Tasks';
      case 'notes':
        return 'Notes';
      case 'files':
        return 'Files';
      case 'events':
        return 'Events';
      default:
        return key;
    }
  }
}
