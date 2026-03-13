import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/config/central_parameterized_config.dart';
import '../../core/orchestrator/application_orchestrator.dart';
import '../providers/config_provider.dart';

/// Parameterized App Bar
/// 
/// AppBar component that uses central configuration for customization
/// Features: Dynamic title, parameterized actions, theme-aware styling
/// Performance: Optimized rebuilds, efficient configuration access
/// Architecture: Consumer widget, parameterized design, responsive UI
class ParameterizedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ParameterizedAppBar({
    super.key,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.shadowColor,
    this.shape,
  });

  final String? title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final Color? shadowColor;
  final ShapeBorder? shape;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(configurationProvider);
    final theme = Theme.of(context);
    
    // Get configuration values
    final appTitle = title ?? configProvider.appName;
    final enableAnimations = configProvider.animationsEnabled;
    final appBarElevation = elevation ?? (enableAnimations ? 4.0 : 0.0);
    final appBarColor = backgroundColor ?? theme.appBarTheme.backgroundColor;
    final appBarForegroundColor = foregroundColor ?? theme.appBarTheme.foregroundColor;
    
    return AppBar(
      title: Text(
        appTitle,
        style: theme.appBarTheme.titleTextStyle,
      ),
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: appBarColor,
      foregroundColor: appBarForegroundColor,
      elevation: appBarElevation,
      shadowColor: shadowColor,
      shape: shape,
      actions: actions ?? _buildDefaultActions(context, ref, l10n),
    );
  }

  /// Build default actions
  List<Widget> _buildDefaultActions(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final configProvider = ref.watch(configurationProvider);
    
    return [
      // Refresh configuration action
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => _refreshConfiguration(context, ref),
        tooltip: l10n.configuration,
      ),
      
      // Settings action
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () => _openSettings(context),
        tooltip: l10n.settings,
      ),
      
      // More options (if enabled)
      if (configProvider._config.getParameter('ui.show_more_options', defaultValue: false))
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More options',
          onSelected: (value) => _handleMenuAction(context, ref, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export_config',
              child: Row(
                children: [
                  const Icon(Icons.download),
                  const SizedBox(width: 8),
                  Text('Export Config'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'import_config',
              child: Row(
                children: [
                  const Icon(Icons.upload),
                  const SizedBox(width: 8),
                  Text('Import Config'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reset_config',
              child: Row(
                children: [
                  const Icon(Icons.restore),
                  const SizedBox(width: 8),
                  Text('Reset Config'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'system_info',
              child: Row(
                children: [
                  const Icon(Icons.info),
                  const SizedBox(width: 8),
                  Text('System Info'),
                ],
              ),
            ),
          ],
        ),
    ];
  }

  /// Refresh configuration
  void _refreshConfiguration(BuildContext context, WidgetRef ref) {
    final configProvider = ref.read(configurationProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing configuration...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    configProvider.reloadConfiguration().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration refreshed successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh configuration: $error'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  /// Open settings
  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }

  /// Handle menu action
  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'export_config':
        _exportConfiguration(context, ref);
        break;
      case 'import_config':
        _importConfiguration(context, ref);
        break;
      case 'reset_config':
        _resetConfiguration(context, ref);
        break;
      case 'system_info':
        _showSystemInfo(context, ref);
        break;
    }
  }

  /// Export configuration
  void _exportConfiguration(BuildContext context, WidgetRef ref) {
    final configProvider = ref.read(configurationProvider);
    
    configProvider.exportConfiguration().then((yamlData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration exported successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export configuration: $error'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  /// Import configuration
  void _importConfiguration(BuildContext context, WidgetRef ref) {
    // This would open a file picker or dialog to import configuration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import configuration feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Reset configuration
  void _resetConfiguration(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Configuration'),
        content: const Text('Are you sure you want to reset all configuration to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final configProvider = ref.read(configurationProvider);
              configProvider.resetToDefaults();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuration reset to defaults'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  /// Show system information
  void _showSystemInfo(BuildContext context, WidgetRef ref) {
    final configProvider = ref.read(configurationProvider);
    final appOrchestrator = ApplicationOrchestrator.instance;
    final appStats = appOrchestrator.getApplicationStatistics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('App Name', configProvider.appName),
              _buildInfoRow('App Version', configProvider.appVersion),
              _buildInfoRow('Environment', configProvider.appEnvironment),
              _buildInfoRow('Debug Mode', configProvider.isDebugMode.toString()),
              _buildInfoRow('Theme Mode', configProvider.themeMode),
              _buildInfoRow('Language', configProvider.language),
              _buildInfoRow('Font Size', configProvider.fontSize),
              _buildInfoRow('Animations', configProvider.animationsEnabled.toString()),
              const SizedBox(height: 16),
              const Text('Application Statistics:', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildInfoRow('State', appStats['state'].toString()),
              _buildInfoRow('Init Duration', '${appStats['initialization_duration']}ms'),
              _buildInfoRow('Uptime', '${appStats['uptime']}ms'),
              _buildInfoRow('Startup Steps', appStats['startup_steps'].toString()),
              _buildInfoRow('Completed Steps', appStats['completed_steps'].toString()),
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

  /// Build information row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Parameterized Bottom Navigation Bar
/// 
/// Bottom navigation bar that uses central configuration
/// Features: Dynamic items, parameterized styling, theme-aware design
/// Performance: Optimized rebuilds, efficient configuration access
/// Architecture: Consumer widget, parameterized design, responsive UI
class ParameterizedBottomNavigationBar extends ConsumerWidget {
  const ParameterizedBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
    this.backgroundColor,
    this.elevation,
    this.fixedColor,
  });

  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem>? items;
  final Color? backgroundColor;
  final double? elevation;
  final Color? fixedColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ref.watch(configurationProvider);
    final theme = Theme.of(context);
    
    // Get configuration values
    final enableAnimations = configProvider.animationsEnabled;
    final navElevation = elevation ?? (enableAnimations ? 8.0 : 0.0);
    final navBackgroundColor = backgroundColor ?? theme.navigationBarTheme.backgroundColor;
    
    // Build default items if not provided
    final defaultItems = items ?? _buildDefaultItems(l10n);
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: defaultItems,
      backgroundColor: navBackgroundColor,
      elevation: navElevation,
      fixedColor: fixedColor,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: configProvider._config.getParameter('ui.nav_selected_font_size', defaultValue: 14.0),
      unselectedFontSize: configProvider._config.getParameter('ui.nav_unselected_font_size', defaultValue: 12.0),
      iconSize: configProvider._config.getParameter('ui.nav_icon_size', defaultValue: 24.0),
    );
  }

  /// Build default navigation items
  List<BottomNavigationBarItem> _buildDefaultItems(AppLocalizations l10n) {
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home),
        label: l10n.home,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.folder),
        label: l10n.files,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.network_check),
        label: l10n.network,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings),
        label: l10n.settings,
      ),
    ];
  }
}

/// Parameterized Floating Action Button
/// 
/// FAB that uses central configuration for styling and behavior
/// Features: Dynamic icon, parameterized styling, theme-aware design
/// Performance: Optimized rebuilds, efficient configuration access
/// Architecture: Consumer widget, parameterized design, responsive UI
class ParameterizedFloatingActionButton extends ConsumerWidget {
  const ParameterizedFloatingActionButton({
    super.key,
    this.onPressed,
    this.child,
    this.tooltip,
    this.heroTag,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget? child;
  final String? tooltip;
  final Object? heroTag;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configProvider = ref.watch(configurationProvider);
    final theme = Theme.of(context);
    
    // Get configuration values
    final enableAnimations = configProvider.animationsEnabled;
    final fabElevation = elevation ?? (enableAnimations ? 6.0 : 0.0);
    final fabBackgroundColor = backgroundColor ?? theme.floatingActionButtonTheme.backgroundColor;
    
    return FloatingActionButton(
      onPressed: onPressed,
      child: child ?? const Icon(Icons.add),
      tooltip: tooltip,
      heroTag: heroTag,
      elevation: fabElevation,
      backgroundColor: fabBackgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}
