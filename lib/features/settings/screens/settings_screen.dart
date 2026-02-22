import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Storage'),
            subtitle: const Text('Manage storage settings'),
            onTap: () {
              // Navigate to storage settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            subtitle: const Text('Manage security settings'),
            onTap: () {
              // Navigate to security settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync'),
            subtitle: const Text('Manage synchronization settings'),
            onTap: () {
              // Navigate to sync settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('App information'),
            onTap: () {
              // Show about dialog
            },
          ),
        ],
      ),
    );
  }
}
