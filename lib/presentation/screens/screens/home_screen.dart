import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Infrastructure services
import '../../infrastructure/core/config/central_config.dart';

// Domain services
import '../../domain/services/file_management/advanced_file_manager_service.dart';

// Application services
import '../../application/services/testing/comprehensive_testing_strategy_service.dart';

// Presentation components
import '../widgets/app_drawer.dart';
import '../widgets/loading_indicator.dart';

/// Home Screen (Main Dashboard) using CentralConfig parameters
/// No hardcoded values - everything is configurable
class HomeScreen extends ConsumerWidget {
  final CentralConfig config;

  const HomeScreen({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileManager = ref.watch(advancedFileManagerServiceProvider);
    final testingService = ref.watch(comprehensiveTestingStrategyServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          config.getParameter('app.name', defaultValue: 'iSuite'),
          style: TextStyle(
            fontSize: config.getParameter('ui.font_size_xl', defaultValue: 20.0),
            fontWeight: FontWeight.values[config.getParameter('ui.font_weight_medium', defaultValue: 500)],
          ),
        ),
        elevation: config.getParameter('ui.app_bar_elevation', defaultValue: 0.0),
        backgroundColor: Color(config.getParameter('ui.primary_color', defaultValue: 0xFF1976D2)),
        foregroundColor: Color(config.getParameter('ui.on_primary_color', defaultValue: 0xFFFFFFFF)),
        toolbarHeight: config.getParameter('ui.app_bar_height', defaultValue: 56.0),
      ),
      drawer: AppDrawer(config: config),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(config.getParameter('ui.spacing_lg', defaultValue: 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              elevation: config.getParameter('ui.card_elevation', defaultValue: 2.0),
              margin: EdgeInsets.all(config.getParameter('ui.card_margin', defaultValue: 8.0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  config.getParameter('ui.border_radius_lg', defaultValue: 12.0),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(config.getParameter('ui.card_padding', defaultValue: 16.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to iSuite',
                      style: TextStyle(
                        fontSize: config.getParameter('ui.font_size_xxl', defaultValue: 24.0),
                        fontWeight: FontWeight.values[config.getParameter('ui.font_weight_bold', defaultValue: 700)],
                        color: Color(config.getParameter('ui.on_surface_color', defaultValue: 0xFF000000)),
                      ),
                    ),
                    SizedBox(height: config.getParameter('ui.spacing_sm', defaultValue: 8.0)),
                    Text(
                      'Advanced file management platform with enterprise features',
                      style: TextStyle(
                        fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
                        fontWeight: FontWeight.values[config.getParameter('ui.font_weight_regular', defaultValue: 400)],
                        color: Color(config.getParameter('ui.on_surface_color', defaultValue: 0xFF000000)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: config.getParameter('ui.spacing_xl', defaultValue: 32.0)),

            // Quick actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: config.getParameter('ui.font_size_xl', defaultValue: 20.0),
                fontWeight: FontWeight.values[config.getParameter('ui.font_weight_medium', defaultValue: 500)],
                color: Color(config.getParameter('ui.on_surface_color', defaultValue: 0xFF000000)),
              ),
            ),
            SizedBox(height: config.getParameter('ui.spacing_md', defaultValue: 16.0)),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: config.getParameter('ui.spacing_md', defaultValue: 16.0),
              mainAxisSpacing: config.getParameter('ui.spacing_md', defaultValue: 16.0),
              children: [
                _QuickActionCard(
                  title: 'File Management',
                  subtitle: 'Organize and manage files',
                  icon: Icons.folder,
                  onTap: () => Navigator.pushNamed(context, '/file-management'),
                  config: config,
                ),
                _QuickActionCard(
                  title: 'Network Management',
                  subtitle: 'FTP, cloud, and network storage',
                  icon: Icons.wifi,
                  onTap: () => Navigator.pushNamed(context, '/network-management'),
                  config: config,
                ),
                _QuickActionCard(
                  title: 'Streaming',
                  subtitle: 'Stream media files',
                  icon: Icons.play_circle,
                  onTap: () => _showComingSoon(context, 'Media Streaming', config),
                  config: config,
                ),
                _QuickActionCard(
                  title: 'Wireless Sharing',
                  subtitle: 'Share files wirelessly',
                  icon: Icons.share,
                  onTap: () => _showComingSoon(context, 'Wireless File Sharing', config),
                  config: config,
                ),
              ],
            ),

            SizedBox(height: config.getParameter('ui.spacing_xxl', defaultValue: 48.0)),

            // System status
            Text(
              'System Status',
              style: TextStyle(
                fontSize: config.getParameter('ui.font_size_xl', defaultValue: 20.0),
                fontWeight: FontWeight.values[config.getParameter('ui.font_weight_medium', defaultValue: 500)],
                color: Color(config.getParameter('ui.on_surface_color', defaultValue: 0xFF000000)),
              ),
            ),
            SizedBox(height: config.getParameter('ui.spacing_md', defaultValue: 16.0)),

            StreamBuilder(
              stream: fileManager.events,
              builder: (context, snapshot) {
                return Card(
                  elevation: config.getParameter('ui.card_elevation', defaultValue: 2.0),
                  margin: EdgeInsets.all(config.getParameter('ui.card_margin', defaultValue: 8.0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      config.getParameter('ui.border_radius_lg', defaultValue: 12.0),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(config.getParameter('ui.card_padding', defaultValue: 16.0)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Color(config.getParameter('ui.success_color', defaultValue: 0xFF4CAF50)),
                              size: config.getParameter('ui.icon_size_md', defaultValue: 24.0),
                            ),
                            SizedBox(width: config.getParameter('ui.spacing_sm', defaultValue: 8.0)),
                            Text(
                              'File Manager Service',
                              style: TextStyle(
                                fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
                                fontWeight: FontWeight.values[config.getParameter('ui.font_weight_medium', defaultValue: 500)],
                                color: Color(config.getParameter('ui.on_surface_color', defaultValue: 0xFF000000)),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Active',
                              style: TextStyle(
                                fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
                                fontWeight: FontWeight.values[config.getParameter('ui.font_weight_medium', defaultValue: 500)],
                                color: Color(config.getParameter('ui.success_color', defaultValue: 0xFF4CAF50)),
                              ),
                            ),
                          ],
                        ),
                        // Add more service status indicators as needed
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature, CentralConfig config) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Color(config.getParameter('ui.primary_color', defaultValue: 0xFF1976D2)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            config.getParameter('ui.border_radius_md', defaultValue: 8.0),
          ),
        ),
        margin: EdgeInsets.all(config.getParameter('ui.spacing_md', defaultValue: 16.0)),
      ),
    );
  }
}

/// Quick Action Card Widget using CentralConfig parameters
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final CentralConfig config;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: config.getParameter('ui.card_elevation', defaultValue: 2.0),
      margin: EdgeInsets.all(config.getParameter('ui.card_margin', defaultValue: 8.0)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_lg', defaultValue: 12.0),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          config.getParameter('ui.border_radius_lg', defaultValue: 12.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(config.getParameter('ui.card_padding', defaultValue: 16.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: config.getParameter('ui.icon_size_xl', defaultValue: 48.0),
                color: Color(config.getParameter('ui.primary_color', defaultValue: 0xFF1976D2)),
              ),
              SizedBox(height: config.getParameter('ui.spacing_md', defaultValue: 16.0)),
              Text(
                title,
                style: TextStyle(
                  fontSize: config.getParameter('ui.font_size_md', defaultValue: 16.0),
                  fontWeight: FontWeight.values[config.getParameter('ui.font_weight_medium', defaultValue: 500)],
                  color: Color(config.getParameter('ui.on_surface_color', defaultValue: 0xFF000000)),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: config.getParameter('ui.spacing_xs', defaultValue: 4.0)),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: config.getParameter('ui.font_size_sm', defaultValue: 14.0),
                  fontWeight: FontWeight.values[config.getParameter('ui.font_weight_regular', defaultValue: 400)],
                  color: Color(config.getParameter('ui.on_surface_color', defaultValue: 0xFF000000)).withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_config.appTitle),
        elevation: _config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
        backgroundColor: _config.primaryColor,
        foregroundColor: _config.surfaceColor,
        actions: [
          IconButton(
            onPressed: () => context.go('/search'),
            icon: Icon(Icons.search, size: _config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
            tooltip: 'Search',
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, size: _config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
                onPressed: () => _showNotifications(context),
              ),
              Positioned(
                right: _config.getParameter('ui.spacing.small', defaultValue: 8.0),
                top: _config.getParameter('ui.spacing.small', defaultValue: 8.0),
                child: Container(
                  width: _config.getParameter('ui.notification.badge_size', defaultValue: 8.0),
                  height: _config.getParameter('ui.notification.badge_size', defaultValue: 8.0),
                  decoration: BoxDecoration(
                    color: _config.getParameter('ui.colors.error', defaultValue: Colors.red),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: _config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(Duration(seconds: _config.getParameter('ui.refresh.delay', defaultValue: 1)));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Content refreshed'),
                backgroundColor: _config.getParameter('ui.colors.success', defaultValue: Colors.green),
                duration: Duration(milliseconds: _config.getParameter('ui.notification.duration.short', defaultValue: 2000)),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section with Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user != null) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: _config.getParameter('ui.avatar.radius.large', defaultValue: 30.0),
                              backgroundColor: _config.primaryColor,
                              child: Text(
                                user.initials,
                                style: TextStyle(
                                  fontSize: _config.getParameter('ui.font.size.large', defaultValue: 20.0),
                                  fontWeight: FontWeight.bold,
                                  color: _config.surfaceColor,
                                ),
                              ),
                            ),
                            SizedBox(width: _config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back, ${user.name}!',
                                    style: TextStyle(
                                      fontSize: _config.getParameter('ui.font.size.headline_small', defaultValue: 20.0),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: _config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                                    ),
                                  ),
                                  SizedBox(height: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0)),
                                  Text(
                                    'What would you like to do today?',
                                    style: TextStyle(
                                      fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
                                      color: _config.primaryColor.withOpacity(_config.getParameter('ui.opacity.secondary_text', defaultValue: 0.7)),
                                      fontFamily: _config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: _config.getParameter('ui.icon.size.medium', defaultValue: 24.0)),
                              onPressed: () => context.go('/profile'),
                              tooltip: 'Edit Profile',
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Welcome to iSuite!',
                          style: TextStyle(
                            fontSize: _config.getParameter('ui.font.size.headline_small', defaultValue: 20.0),
                            fontWeight: FontWeight.bold,
                            fontFamily: _config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                          ),
                        ),
                        SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
                        Text(
                          'Your comprehensive productivity suite',
                          style: TextStyle(
                            fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
                            color: _config.primaryColor.withOpacity(_config.getParameter('ui.opacity.secondary_text', defaultValue: 0.7)),
                            fontFamily: _config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                          ),
                        ),
                        SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showLoginDialog(context),
                            icon: Icon(Icons.login, size: _config.getParameter('ui.icon.size.small', defaultValue: 18.0)),
                            label: Text('Sign In'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _config.primaryColor,
                              foregroundColor: _config.surfaceColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: _config.getParameter('ui.spacing.medium', defaultValue: 20.0),
                                vertical: _config.getParameter('ui.spacing.medium', defaultValue: 20.0) / 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 8.0)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: _config.getParameter('ui.spacing.xlarge', defaultValue: 32.0)),

              // Quick Actions Section
              if (user != null) ...[
                const QuickActions(),
                SizedBox(height: _config.getParameter('ui.spacing.large', defaultValue: 24.0)),
              ],

              // Features Grid with Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: _config.getParameter('ui.grid.cross_axis_count', defaultValue: 2),
                  crossAxisSpacing: _config.getParameter('ui.grid.cross_axis_spacing', defaultValue: 16.0),
                  mainAxisSpacing: _config.getParameter('ui.grid.main_axis_spacing', defaultValue: 16.0),
                  childAspectRatio: _config.getParameter('ui.grid.child_aspect_ratio', defaultValue: 1.2),
                  children: [
                    FeatureCard(
                      icon: Icons.task_alt,
                      title: 'Tasks',
                      subtitle: 'Manage your tasks',
                      onTap: () => _navigateToFeature('tasks'),
                    ),
                    FeatureCard(
                      icon: Icons.calendar_today,
                      title: 'Calendar',
                      subtitle: 'View your schedule',
                      color: _config.getParameter('ui.colors.secondary', defaultValue: Colors.green),
                      onTap: () => _navigateToFeature('calendar'),
                    ),
                    FeatureCard(
                      icon: Icons.note_alt,
                      title: 'Notes',
                      subtitle: 'Take notes',
                      color: _config.getParameter('ui.colors.warning', defaultValue: Colors.orange),
                      onTap: () => _navigateToFeature('notes'),
                    ),
                    FeatureCard(
                      icon: Icons.cloud_upload,
                      title: 'Storage',
                      subtitle: 'File management',
                      color: _config.getParameter('ui.colors.accent', defaultValue: Colors.purple),
                      onTap: () => _navigateToFeature('storage'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: _config.getParameter('ui.spacing.large', defaultValue: 24.0)),

              // Recent Activity Section
              if (user != null) ...[
                const RecentActivity(),
                SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
              ],

              // Tips Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: _config.getParameter('ui.shadow.elevation.medium', defaultValue: 4.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 8.0)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: _config.primaryColor,
                              size: _config.getParameter('ui.icon.size.medium', defaultValue: 24.0),
                            ),
                            SizedBox(width: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
                            Text(
                              'Pro Tip',
                              style: TextStyle(
                                fontSize: _config.getParameter('ui.font.size.title_medium', defaultValue: 16.0),
                                fontWeight: FontWeight.bold,
                                color: _config.primaryColor,
                                fontFamily: _config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
                        Text(
                          'Swipe right on any task to mark it complete, or swipe left to delete it. Long press to see more options!',
                          style: TextStyle(
                            fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
                            fontFamily: _config.getParameter('ui.font.family.primary', defaultValue: 'Roboto'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              onPressed: () => _showQuickAddDialog(context),
              icon: Icon(Icons.add, size: _config.getParameter('ui.icon.size.small', defaultValue: 18.0)),
              label: Text('Quick Add'),
              backgroundColor: _config.primaryColor,
              foregroundColor: _config.surfaceColor,
            )
          : null,
    );
  }

  void _navigateToFeature(String feature) {
    switch (feature) {
      case 'tasks':
        context.go('/tasks');
        break;
      case 'calendar':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calendar feature coming soon!'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
        break;
      case 'notes':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes feature coming soon!'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
        break;
      case 'storage':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage feature coming soon!'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$feature feature coming soon!'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.task_alt, color: Colors.blue),
              title: Text('Task completed'),
              subtitle: Text('You completed 5 tasks today'),
              trailing: Text('2h ago'),
            ),
            const ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.green),
              title: Text('Meeting reminder'),
              subtitle: Text('Team meeting in 30 minutes'),
              trailing: Text('30m ago'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Clear All'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              await userProvider.login(
                emailController.text.trim(),
                passwordController.text,
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(userProvider.error ?? 'Signed in successfully'),
                    backgroundColor: userProvider.error != null ? Colors.red : Colors.green,
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

  void _showQuickAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('Add Task'),
              onTap: () {
                Navigator.pop(context);
                _navigateToFeature('tasks');
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_alt),
              title: const Text('Add Note'),
              onTap: () {
                Navigator.pop(context);
                _navigateToFeature('notes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Add Event'),
              onTap: () {
                Navigator.pop(context);
                _navigateToFeature('calendar');
              },
            ),
          ],
        ),
      ),
    );
  }
}
