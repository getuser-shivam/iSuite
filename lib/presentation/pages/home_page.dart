import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/network_provider.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/gradient_card.dart';
import '../../core/widgets/slide_in_animation.dart';
import '../../core/widgets/scale_animation.dart';
import '../../core/widgets/pulse_animation.dart';

/// Enhanced Home Page with Advanced Animations and Interactions
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start card animations with staggered delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Enhanced App Bar with Hero animation
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(context).colorScheme.surface.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.apps,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'iSuite Pro',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Advanced File & Network Manager',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  Consumer<AppProvider>(
                    builder: (context, appProvider, child) {
                      return ScaleAnimation(
                        child: IconButton(
                          icon: Badge(
                            isLabelVisible: appProvider.notificationCount > 0,
                            label: AnimatedCounter(
                              value: appProvider.notificationCount,
                              duration: const Duration(milliseconds: 300),
                            ),
                            child: const Icon(Icons.notifications),
                          ),
                          onPressed: () => _showEnhancedNotifications(context),
                        ),
                      );
                    },
                  ),
                  ScaleAnimation(
                    child: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _showEnhancedSearch(context),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: _handleMenuSelection,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'refresh',
                        child: ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text('Refresh'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Quick Settings'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'about',
                        child: ListTile(
                          leading: Icon(Icons.info),
                          title: Text('About'),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(themeProvider.uiPaddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section with Animation
                      SlideInAnimation(
                        direction: SlideDirection.fromTop,
                        delay: themeProvider.uiAnimationDelayMedium,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: themeProvider.uiMarginSmall),
                            Text(
                              'Your advanced productivity suite is ready',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: themeProvider.uiMarginLarge),
                          ],
                        ),
                      ),

                      // Stats Cards with Staggered Animation
                      SlideInAnimation(
                        direction: SlideDirection.fromLeft,
                        delay: themeProvider.uiAnimationDelayLong,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'Files',
                                '1,247',
                                Icons.folder,
                                themeProvider.uiCardPrimaryColor,
                                '+12%',
                              ),
                            ),
                            SizedBox(width: themeProvider.uiMarginMedium),
                            Expanded(
                              child: Consumer<NetworkProvider>(
                                builder: (context, networkProvider, child) {
                                  return _buildStatCard(
                                    context,
                                    'Devices',
                                    networkProvider.deviceCount.toString(),
                                    Icons.devices,
                                    themeProvider.uiCardSecondaryColor,
                                    '+${networkProvider.onlineDeviceCount}',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: themeProvider.uiMarginMedium),

                      // Quick Actions Grid with Scale Animations
                      SlideInAnimation(
                        direction: SlideDirection.fromRight,
                        delay: themeProvider.uiAnimationDelayXLong,
                        child: Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),

                      SizedBox(height: themeProvider.uiMarginMedium),

                      // Feature Grid with Staggered Animations
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: themeProvider.uiGridCrossAxisCount,
                          crossAxisSpacing: themeProvider.uiGridCrossAxisSpacing,
                          mainAxisSpacing: themeProvider.uiGridMainAxisSpacing,
                          childAspectRatio: themeProvider.uiGridChildAspectRatio,
                        ),
                        itemCount: _features.length,
                        itemBuilder: (context, index) {
                          return SlideInAnimation(
                            direction: index % 2 == 0 ? SlideDirection.fromLeft : SlideDirection.fromRight,
                            delay: Duration(milliseconds: themeProvider.uiAnimationDelayXLong.inMilliseconds + (index * 100)),
                            child: ScaleAnimation(
                              delay: Duration(milliseconds: themeProvider.uiAnimationDelayXLong.inMilliseconds + (index * 100) + 100),
                              child: _buildFeatureCard(context, _features[index]),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: themeProvider.uiMarginLarge),

                      // Recent Activity Section
                      SlideInAnimation(
                        direction: SlideDirection.fromBottom,
                        delay: Duration(milliseconds: themeProvider.uiAnimationDelayXLong.inMilliseconds + 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Activity',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: themeProvider.uiMarginMedium),
                            _buildRecentActivityList(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showEnhancedQuickActions(context),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _getFabIcon(),
              key: ValueKey<IconData>(_getFabIcon()),
            ),
          ),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _getFabLabel(),
              key: ValueKey<String>(_getFabLabel()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GradientCard(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(themeProvider.uiOpacityMedium),
          color.withOpacity(themeProvider.uiOpacityLow),
        ],
      ),
      borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusLarge),
      child: Padding(
        padding: EdgeInsets.all(themeProvider.uiPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(themeProvider.uiPaddingSmall),
                  decoration: BoxDecoration(
                    color: color.withOpacity(themeProvider.uiOpacityMedium),
                    borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusMedium),
                  ),
                  child: Icon(icon, color: color, size: themeProvider.uiIconSizeMedium),
                ),
                const Spacer(),
                Text(
                  trend,
                  style: TextStyle(
                    color: color,
                    fontSize: themeProvider.uiFontSizeSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: themeProvider.uiMarginMedium),
            AnimatedCounter(
              value: int.tryParse(value.replaceAll(',', '')) ?? 0,
              duration: themeProvider.uiAnimationDurationMedium,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: themeProvider.uiMarginSmall),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, Map<String, dynamic> feature) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GradientCard(
      gradient: LinearGradient(
        colors: [
          (feature['color'] as Color).withOpacity(themeProvider.uiOpacityHigh),
          (feature['color'] as Color).withOpacity(themeProvider.uiOpacityLow),
        ],
      ),
      borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusLarge),
      child: InkWell(
        onTap: () => _navigateToFeature(feature['route']),
        borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusLarge),
        child: Padding(
          padding: EdgeInsets.all(themeProvider.uiPaddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulseAnimation(
                child: Container(
                  padding: EdgeInsets.all(themeProvider.uiPaddingMedium),
                  decoration: BoxDecoration(
                    color: (feature['color'] as Color).withOpacity(themeProvider.uiOpacityMedium),
                    borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusLarge),
                  ),
                  child: Icon(
                    feature['icon'],
                    color: feature['color'],
                    size: themeProvider.uiIconSizeXLarge,
                  ),
                ),
              ),
              SizedBox(height: themeProvider.uiMarginMedium),
              Text(
                feature['title'],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: themeProvider.uiMarginSmall),
              Text(
                feature['subtitle'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final activities = [
      {'title': 'File uploaded', 'subtitle': 'document.pdf', 'time': '2m ago', 'icon': Icons.upload_file, 'color': themeProvider.uiCardSuccessColor},
      {'title': 'Network scan', 'subtitle': '3 devices found', 'time': '5m ago', 'icon': Icons.wifi_find, 'color': themeProvider.uiCardInfoColor},
      {'title': 'Backup created', 'subtitle': 'backup_2024.zip', 'time': '1h ago', 'icon': Icons.backup, 'color': themeProvider.uiCardWarningColor},
      {'title': 'Settings updated', 'subtitle': 'Theme changed', 'time': '2h ago', 'icon': Icons.settings, 'color': themeProvider.uiCardSecondaryColor},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return SlideInAnimation(
          direction: SlideDirection.fromLeft,
          delay: Duration(milliseconds: themeProvider.uiAnimationDelayXLong.inMilliseconds + 1000 + (index * 100)),
          child: Card(
            margin: EdgeInsets.only(bottom: themeProvider.uiMarginSmall),
            elevation: themeProvider.uiElevationLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusMedium),
            ),
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(themeProvider.uiPaddingSmall),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(themeProvider.uiOpacityLow),
                  borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusSmall),
                ),
                child: Icon(
                  activity['icon'],
                  color: activity['color'],
                  size: themeProvider.uiIconSizeSmall,
                ),
              ),
              title: Text(activity['title']),
              subtitle: Text(activity['subtitle']),
              trailing: Text(
                activity['time'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () => _showActivityDetails(context, activity),
            ),
          ),
        );
      },
    );
  }

  // Feature data
  static const List<Map<String, dynamic>> _features = [
    {
      'title': 'Files',
      'subtitle': 'Browse & manage files',
      'icon': Icons.folder,
      'color': Colors.blue,
      'route': '/files',
    },
    {
      'title': 'Network',
      'subtitle': 'Device discovery & tools',
      'icon': Icons.wifi,
      'color': Colors.green,
      'route': '/network',
    },
    {
      'title': 'Analytics',
      'subtitle': 'Performance insights',
      'icon': Icons.analytics,
      'color': Colors.purple,
      'route': '/analytics',
    },
    {
      'title': 'Settings',
      'subtitle': 'App preferences',
      'icon': Icons.settings,
      'color': Colors.orange,
      'route': '/settings',
    },
  ];

  void _showEnhancedNotifications(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(themeProvider.uiBorderRadiusLarge)),
        ),
        child: Column(
          children: [
            Container(
              height: themeProvider.uiBorderRadiusLarge,
              width: themeProvider.uiIconSizeXXLarge,
              margin: EdgeInsets.symmetric(vertical: themeProvider.uiMarginMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(themeProvider.uiOpacityLow),
                borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusSmall),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(themeProvider.uiPaddingMedium),
              child: Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const Divider(),
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  if (appProvider.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: themeProvider.uiIconSizeXXLarge,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(themeProvider.uiOpacityHigh),
                          ),
                          SizedBox(height: themeProvider.uiMarginMedium),
                          Text(
                            'No notifications',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(themeProvider.uiPaddingMedium),
                    itemCount: appProvider.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = appProvider.notifications[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: themeProvider.uiMarginSmall),
                        elevation: themeProvider.uiElevationLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusMedium),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: notification.color.withOpacity(themeProvider.uiOpacityMedium),
                            child: Icon(
                              notification.icon,
                              color: notification.color,
                            ),
                          ),
                          title: Text(notification.title),
                          subtitle: Text(notification.message),
                          trailing: IconButton(
                            icon: Icon(Icons.close, size: themeProvider.uiIconSizeSmall),
                            onPressed: () => appProvider.removeNotification(notification.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnhancedSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: EnhancedSearchDelegate(),
    );
  }

  void _showEnhancedQuickActions(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(themeProvider.uiPaddingMedium),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(themeProvider.uiBorderRadiusLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: themeProvider.uiMarginMedium),
            Wrap(
              spacing: themeProvider.uiMarginMedium,
              runSpacing: themeProvider.uiMarginMedium,
              children: [
                _buildEnhancedActionTile(
                  context,
                  'New Folder',
                  Icons.create_new_folder,
                  themeProvider.uiCardPrimaryColor,
                  () => _createNewFolder(context),
                ),
                _buildEnhancedActionTile(
                  context,
                  'Network Scan',
                  Icons.wifi_find,
                  themeProvider.uiCardSecondaryColor,
                  () => _startNetworkScan(context),
                ),
                _buildEnhancedActionTile(
                  context,
                  'Upload File',
                  Icons.upload_file,
                  themeProvider.uiCardWarningColor,
                  () => _uploadFile(context),
                ),
                _buildEnhancedActionTile(
                  context,
                  'System Info',
                  Icons.info,
                  themeProvider.uiCardInfoColor,
                  () => _showSystemInfo(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedActionTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusLarge),
      child: Container(
        width: themeProvider.uiCardActionTileWidth,
        height: themeProvider.uiCardActionTileHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(themeProvider.uiOpacityMedium),
              color.withOpacity(themeProvider.uiOpacityLow),
            ],
          ),
          borderRadius: BorderRadius.circular(themeProvider.uiBorderRadiusLarge),
          border: Border.all(
            color: color.withOpacity(themeProvider.uiOpacityHigh),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleAnimation(
              child: Icon(
                icon,
                color: color,
                size: themeProvider.uiIconSizeXXLarge,
              ),
            ),
            SizedBox(height: themeProvider.uiMarginSmall),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: themeProvider.uiFontSizeSmall,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFeature(String route) {
    // Navigate to the feature
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to $route')),
    );
  }

  void _showActivityDetails(BuildContext context, Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details: ${activity['subtitle']}'),
            Text('Time: ${activity['time']}'),
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

  void _createNewFolder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating new folder...')),
    );
  }

  void _startNetworkScan(BuildContext context) {
    final networkProvider = Provider.of<NetworkProvider>(context, listen: false);
    networkProvider.startNetworkScan();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network scan started...')),
    );
  }

  void _uploadFile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File upload feature coming soon!')),
    );
  }

  void _showSystemInfo(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'iSuite Pro',
      applicationVersion: '3.0.0',
      applicationIcon: const Icon(Icons.apps, size: 48),
      children: [
        const Text('Enhanced File & Network Management Suite'),
        const Text('Advanced animations, real-time monitoring, enterprise features'),
      ],
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'refresh':
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refreshed!')),
        );
        break;
      case 'settings':
        _navigateToFeature('/settings');
        break;
      case 'about':
        _showSystemInfo(context);
        break;
    }
  }

  IconData _getFabIcon() {
    // Context-aware FAB icon based on current page state
    return Icons.add;
  }

  String _getFabLabel() {
    // Context-aware FAB label
    return 'Quick Action';
  }
}

/// Enhanced Search Delegate with Advanced Features
class EnhancedSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _getSearchResults(query);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
          ],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return SlideInAnimation(
            direction: SlideDirection.fromBottom,
            delay: Duration(milliseconds: index * 100),
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: result['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(result['icon'], color: result['color']),
                ),
                title: Text(result['title']),
                subtitle: Text(result['subtitle']),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _navigateToResult(context, result),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _getSuggestions(query);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.05),
          ],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ScaleAnimation(
            delay: Duration(milliseconds: index * 50),
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: suggestion['color'].withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(suggestion['icon'], color: suggestion['color'], size: 20),
                ),
                title: Text(suggestion['title']),
                subtitle: Text(suggestion['subtitle']),
                onTap: () {
                  query = suggestion['title'];
                  showResults(context);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getSuggestions(String query) {
    if (query.isEmpty) {
      return [
        {'title': 'Files', 'subtitle': 'Browse and manage files', 'icon': Icons.folder, 'color': Colors.blue, 'route': '/files'},
        {'title': 'Network', 'subtitle': 'Network tools and scanning', 'icon': Icons.wifi, 'color': Colors.green, 'route': '/network'},
        {'title': 'Settings', 'subtitle': 'App preferences', 'icon': Icons.settings, 'color': Colors.orange, 'route': '/settings'},
        {'title': 'Analytics', 'subtitle': 'Performance insights', 'icon': Icons.analytics, 'color': Colors.purple, 'route': '/analytics'},
      ];
    }

    return [
      {'title': 'Files', 'subtitle': 'Search in files', 'icon': Icons.folder, 'color': Colors.blue, 'route': '/files'},
      {'title': 'Network', 'subtitle': 'Network search', 'icon': Icons.wifi, 'color': Colors.green, 'route': '/network'},
      {'title': 'Settings', 'subtitle': 'Settings search', 'icon': Icons.settings, 'color': Colors.orange, 'route': '/settings'},
    ];
  }

  List<Map<String, dynamic>> _getSearchResults(String query) {
    // Enhanced search results with more context
    return [
      {'title': 'Documents Folder', 'subtitle': 'Found in Files - 247 items', 'icon': Icons.folder, 'color': Colors.blue, 'route': '/files'},
      {'title': 'WiFi Settings', 'subtitle': 'Found in Network Settings', 'icon': Icons.wifi, 'color': Colors.green, 'route': '/network'},
      {'title': 'Theme Preferences', 'subtitle': 'Found in Settings', 'icon': Icons.palette, 'color': Colors.purple, 'route': '/settings'},
      {'title': 'Storage Analytics', 'subtitle': 'Found in Analytics', 'icon': Icons.storage, 'color': Colors.orange, 'route': '/analytics'},
    ];
  }

  void _navigateToResult(BuildContext context, Map<String, dynamic> result) {
    final route = result['route'];
    if (route != null) {
      Navigator.of(context).pushNamed(route);
    }
    close(context, null);
  }
}
