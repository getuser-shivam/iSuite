import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../widgets/app_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, userProvider),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: user == null
          ? const Center(
              child: Text('Please sign in to view your profile'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Full Name'),
                          subtitle: Text(user.name),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(user.email),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Member Since'),
                          subtitle: const Text('February 2024'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showEditProfileDialog(context, userProvider),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showLogoutDialog(context, userProvider),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProvider userProvider) {
    final nameController = TextEditingController(text: userProvider.user?.name ?? '');
    final emailController = TextEditingController(text: userProvider.user?.email ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await userProvider.updateProfile(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(userProvider.error ?? 'Profile updated successfully'),
                      backgroundColor: userProvider.error != null ? Colors.red : Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await userProvider.logout();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signed out successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
