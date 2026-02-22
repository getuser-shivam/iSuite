import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/central_config.dart';
import '../../providers/user_provider.dart';
import '../../features/ai_assistant/intelligent_categorization_screen.dart';
import '../../features/plugins/plugin_marketplace_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final config = CentralConfig.instance;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: config.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: config.getParameter('ui.avatar.radius.large', defaultValue: 30.0),
                  backgroundColor: config.surfaceColor,
                  child: user != null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: config.getParameter('ui.font.size.large', defaultValue: 20.0),
                            fontWeight: FontWeight.bold,
                            color: config.primaryColor,
                            fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0),
                          color: config.primaryColor,
                        ),
                ),
                SizedBox(height: config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
                Text(
                  user?.name ?? 'Guest User',
                  style: TextStyle(
                    color: config.surfaceColor,
                    fontSize: config.getParameter('ui.font.size.headline_small', defaultValue: 20.0),
                    fontWeight: FontWeight.bold,
                    fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                  ),
                ),
                SizedBox(height: config.getParameter('ui.spacing.xsmall', defaultValue: 4.0)),
                Text(
                  user?.email ?? 'Please sign in',
                  style: TextStyle(
                    color: config.surfaceColor.withOpacity(config.getParameter('ui.opacity.secondary_text', defaultValue: 0.7)),
                    fontSize: config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
                    fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
            title: Text(
              'Home',
              style: TextStyle(
                fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/home');
            },
          ),
          ListTile(
            leading: Icon(Icons.person, size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
            title: Text(
              'Profile',
              style: TextStyle(
                fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.analytics, size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
            title: Text(
              'Analytics',
              style: TextStyle(
                fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/analytics');
            },
          ),
          ListTile(
            leading: Icon(Icons.document_scanner, size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
            title: Text(
              'Document AI',
              style: TextStyle(
                fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/document-ai');
            },
          ),
          ListTile(
            leading: Icon(Icons.auto_awesome, size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
            title: Text(
              'Smart Organization',
              style: TextStyle(
                fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/smart-organization');
            },
          ),
          ListTile(
            leading: Icon(Icons.group, size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
            title: Text(
              'Team Collaboration',
              style: TextStyle(
                fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/collaboration');
            },
          ),
          ListTile(
            leading: Icon(Icons.extension, size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
            title: Text(
              'Plugin Marketplace',
              style: TextStyle(
                fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/plugins');
            },
          ),
          ListTile(
            leading: Icon(Icons.search, size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
            title: Text(
              'Search',
              style: TextStyle(
                fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/search');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
            title: Text(
              'Settings',
              style: TextStyle(
                fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/settings');
            },
          ),
          const Divider(),
          if (user == null)
            ListTile(
              leading: Icon(Icons.login, size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
              title: Text(
                'Sign In',
                style: TextStyle(
                  fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLoginDialog(context, userProvider);
              },
            )
          else
            ListTile(
              leading: Icon(
                Icons.logout,
                color: config.getParameter('ui.colors.error', defaultValue: Colors.red),
                size: config.getParameter('ui.icon.size.medium', defaultValue: 24.0),
              ),
              title: Text(
                'Sign Out',
                style: TextStyle(
                  color: config.getParameter('ui.colors.error', defaultValue: Colors.red),
                  fontFamily: config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                userProvider.logout();
              },
            ),
        ],
      ),
    );
  }
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go('/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.go('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              context.go('/analytics');
            },
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner),
            title: const Text('Document AI'),
            onTap: () {
              Navigator.pop(context);
              context.go('/document-ai');
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Smart Organization'),
            onTap: () {
              Navigator.pop(context);
              context.go('/smart-organization');
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Team Collaboration'),
            onTap: () {
              Navigator.pop(context);
              context.go('/collaboration');
            },
          ),
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('Plugin Marketplace'),
            onTap: () {
              Navigator.pop(context);
              context.go('/plugins');
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
            onTap: () {
              Navigator.pop(context);
              context.go('/search');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.go('/settings');
            },
          ),
          const Divider(),
          if (user == null)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign In'),
              onTap: () {
                Navigator.pop(context);
                _showLoginDialog(context, userProvider);
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                userProvider.logout();
              },
            ),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context, UserProvider userProvider) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
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
              await userProvider.login(
                emailController.text.trim(),
                passwordController.text,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(userProvider.error ?? 'Signed in successfully'),
                    backgroundColor:
                        userProvider.error != null ? Colors.red : Colors.green,
                  ),
                );
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
