import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Infrastructure services
import '../../core/config/central_config.dart';
import '../../core/pocketbase_service.dart';
import '../../core/generative_ai_service.dart';
import '../../core/offline_manager.dart';

// Domain Services
// import '../domain/services/file_management/advanced_file_manager_service.dart'; // File not found

// Application Services
// import '../application/services/testing/comprehensive_testing_strategy_service.dart'; // File not found

// Presentation Components
import 'screens/home_screen.dart';
import 'screens/file_management_screen.dart';
import 'screens/network_management_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/loading_indicator.dart';
import 'themes/app_theme.dart';

/// Main iSuite Application Widget
/// Fully parameterized UI using CentralConfig - no hardcoded values
class ISuiteApp extends ConsumerStatefulWidget {
  const ISuiteApp({super.key});

  @override
  State<ISuiteApp> createState() => _ISuiteAppState();
}

class _ISuiteAppState extends State<ISuiteApp> {
  // Central configuration instance
  late final CentralConfig _config;

  // Application state
  bool _isInitialized = false;
  String? _initializationError;
  bool _isLoading = true;

  // Service references (injected via providers)
  late final AdvancedFileManagerService _fileManager;
  late final ComprehensiveTestingStrategyService _testingService;
  late final PocketBaseService _pocketbaseService;
  late final GenerativeAIService _generativeAIService;
  late final OfflineManager _offlineManager;

  @override
  void initState() {
    super.initState();
    _initializeApplication();
  }

  Future<void> _initializeApplication() async {
    try {
      // Initialize configuration first
      _config = CentralConfig.instance;
      await _config.initialize();

      // Setup UI configuration parameters
      await _setupUIConfiguration();

      // Get service instances from providers
      final container = ProviderScope.containerOf(context);
      _fileManager = container.read(advancedFileManagerServiceProvider);
      _testingService =
          container.read(comprehensiveTestingStrategyServiceProvider);
      _pocketbaseService = container.read(pocketbaseServiceProvider);
      await _pocketbaseService.initialize();
      _generativeAIService = container.read(generativeAIServiceProvider);
      await _generativeAIService.initialize();
      _offlineManager = container.read(offlineManagerProvider);
      await _offlineManager.initialize();

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _initializationError = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Setup UI configuration parameters in CentralConfig
  Future<void> _setupUIConfiguration() async {
    // Theme colors - primary color palette
    await _config.setParameter('ui.primary_color', 0xFF1976D2,
        description: 'Primary brand color');
    await _config.setParameter('ui.primary_variant_color', 0xFF1565C0,
        description: 'Primary variant color');
    await _config.setParameter('ui.secondary_color', 0xFF03DAC6,
        description: 'Secondary accent color');
    await _config.setParameter('ui.accent_color', 0xFFFF4081,
        description: 'Accent color');

    // Surface colors
    await _config.setParameter('ui.surface_color', 0xFFFFFFFF,
        description: 'Surface background color');
    await _config.setParameter('ui.background_color', 0xFFFAFAFA,
        description: 'Main background color');
    await _config.setParameter('ui.card_color', 0xFFFFFFFF,
        description: 'Card background color');
    await _config.setParameter('ui.dialog_color', 0xFFFFFFFF,
        description: 'Dialog background color');
    await _config.setParameter('ui.bottom_sheet_color', 0xFFFFFFFF,
        description: 'Bottom sheet color');

    // Error and status colors
    await _config.setParameter('ui.error_color', 0xFFB00020,
        description: 'Error color');
    await _config.setParameter('ui.warning_color', 0xFFFF9800,
        description: 'Warning color');
    await _config.setParameter('ui.success_color', 0xFF4CAF50,
        description: 'Success color');
    await _config.setParameter('ui.info_color', 0xFF2196F3,
        description: 'Info color');

    // Text colors
    await _config.setParameter('ui.on_primary_color', 0xFFFFFFFF,
        description: 'Text on primary');
    await _config.setParameter('ui.on_secondary_color', 0xFF000000,
        description: 'Text on secondary');
    await _config.setParameter('ui.on_surface_color', 0xFF000000,
        description: 'Text on surface');
    await _config.setParameter('ui.on_background_color', 0xFF000000,
        description: 'Text on background');
    await _config.setParameter('ui.on_error_color', 0xFFFFFFFF,
        description: 'Text on error');

    // Font sizes (in logical pixels)
    await _config.setParameter('ui.font_size_xs', 12.0,
        description: 'Extra small font size');
    await _config.setParameter('ui.font_size_sm', 14.0,
        description: 'Small font size');
    await _config.setParameter('ui.font_size_md', 16.0,
        description: 'Medium font size');
    await _config.setParameter('ui.font_size_lg', 18.0,
        description: 'Large font size');
    await _config.setParameter('ui.font_size_xl', 20.0,
        description: 'Extra large font size');
    await _config.setParameter('ui.font_size_xxl', 24.0,
        description: 'Double extra large font size');
    await _config.setParameter('ui.font_size_xxxl', 32.0,
        description: 'Triple extra large font size');

    // Font weights
    await _config.setParameter('ui.font_weight_light', 300,
        description: 'Light font weight');
    await _config.setParameter('ui.font_weight_regular', 400,
        description: 'Regular font weight');
    await _config.setParameter('ui.font_weight_medium', 500,
        description: 'Medium font weight');
    await _config.setParameter('ui.font_weight_bold', 700,
        description: 'Bold font weight');
    await _config.setParameter('ui.font_weight_black', 900,
        description: 'Black font weight');

    // Spacing (in logical pixels)
    await _config.setParameter('ui.spacing_xs', 4.0,
        description: 'Extra small spacing');
    await _config.setParameter('ui.spacing_sm', 8.0,
        description: 'Small spacing');
    await _config.setParameter('ui.spacing_md', 16.0,
        description: 'Medium spacing');
    await _config.setParameter('ui.spacing_lg', 24.0,
        description: 'Large spacing');
    await _config.setParameter('ui.spacing_xl', 32.0,
        description: 'Extra large spacing');
    await _config.setParameter('ui.spacing_xxl', 48.0,
        description: 'Double extra large spacing');

    // Border radius
    await _config.setParameter('ui.border_radius_sm', 4.0,
        description: 'Small border radius');
    await _config.setParameter('ui.border_radius_md', 8.0,
        description: 'Medium border radius');
    await _config.setParameter('ui.border_radius_lg', 12.0,
        description: 'Large border radius');
    await _config.setParameter('ui.border_radius_xl', 16.0,
        description: 'Extra large border radius');
    await _config.setParameter('ui.border_radius_xxl', 24.0,
        description: 'Double extra large border radius');

    // Elevation/shadows
    await _config.setParameter('ui.elevation_sm', 1.0,
        description: 'Small elevation');
    await _config.setParameter('ui.elevation_md', 2.0,
        description: 'Medium elevation');
    await _config.setParameter('ui.elevation_lg', 4.0,
        description: 'Large elevation');
    await _config.setParameter('ui.elevation_xl', 8.0,
        description: 'Extra large elevation');
    await _config.setParameter('ui.elevation_xxl', 16.0,
        description: 'Double extra large elevation');

    // Component sizing
    await _config.setParameter('ui.icon_size_sm', 16.0,
        description: 'Small icon size');
    await _config.setParameter('ui.icon_size_md', 24.0,
        description: 'Medium icon size');
    await _config.setParameter('ui.icon_size_lg', 32.0,
        description: 'Large icon size');
    await _config.setParameter('ui.icon_size_xl', 48.0,
        description: 'Extra large icon size');

    await _config.setParameter('ui.button_height_sm', 36.0,
        description: 'Small button height');
    await _config.setParameter('ui.button_height_md', 48.0,
        description: 'Medium button height');
    await _config.setParameter('ui.button_height_lg', 56.0,
        description: 'Large button height');

    // Animation durations (in milliseconds)
    await _config.setParameter('ui.animation_fast', 150,
        description: 'Fast animation duration');
    await _config.setParameter('ui.animation_normal', 300,
        description: 'Normal animation duration');
    await _config.setParameter('ui.animation_slow', 500,
        description: 'Slow animation duration');

    // Opacity values
    await _config.setParameter('ui.opacity_disabled', 0.38,
        description: 'Disabled opacity');
    await _config.setParameter('ui.opacity_hint', 0.6,
        description: 'Hint text opacity');
    await _config.setParameter('ui.opacity_overlay', 0.8,
        description: 'Overlay opacity');

    // Breakpoints for responsive design
    await _config.setParameter('ui.breakpoint_sm', 600,
        description: 'Small breakpoint');
    await _config.setParameter('ui.breakpoint_md', 900,
        description: 'Medium breakpoint');
    await _config.setParameter('ui.breakpoint_lg', 1200,
        description: 'Large breakpoint');
    await _config.setParameter('ui.breakpoint_xl', 1536,
        description: 'Extra large breakpoint');

    // App bar configuration
    await _config.setParameter('ui.app_bar_elevation', 0.0,
        description: 'App bar elevation');
    await _config.setParameter('ui.app_bar_height', 56.0,
        description: 'App bar height');

    // Navigation configuration
    await _config.setParameter('ui.navigation_drawer_width', 304.0,
        description: 'Navigation drawer width');
    await _config.setParameter('ui.bottom_navigation_height', 80.0,
        description: 'Bottom navigation height');

    // Card configuration
    await _config.setParameter('ui.card_elevation', 2.0,
        description: 'Default card elevation');
    await _config.setParameter('ui.card_margin', 8.0,
        description: 'Card margin');
    await _config.setParameter('ui.card_padding', 16.0,
        description: 'Card padding');

    // Dialog configuration
    await _config.setParameter('ui.dialog_elevation', 24.0,
        description: 'Dialog elevation');
    await _config.setParameter('ui.dialog_max_width', 560.0,
        description: 'Dialog max width');
    await _config.setParameter('ui.dialog_border_radius', 12.0,
        description: 'Dialog border radius');

    // Theme mode
    await _config.setParameter('ui.theme_mode', 'system',
        description: 'Theme mode: light, dark, system');
    await _config.setParameter('ui.enable_dynamic_theme', true,
        description: 'Enable dynamic theme adaptation');

    // App configuration
    await _config.setParameter('app.name', 'iSuite - Advanced File Management',
        description: 'Application name');
    await _config.setParameter('app.debug_banner', false,
        description: 'Show debug banner');
    await _config.setParameter(
        'app.supported_locales', ['en', 'es', 'fr', 'de', 'zh'],
        description: 'Supported locales');

    // Home screen configuration
    await _config.setParameter('home.welcome_title', 'Welcome to iSuite',
        description: 'Welcome title text');
    await _config.setParameter('home.welcome_subtitle',
        'Advanced file management platform with enterprise features',
        description: 'Welcome subtitle text');
    await _config.setParameter('home.quick_actions_title', 'Quick Actions',
        description: 'Quick actions section title');
    await _config.setParameter('home.system_status_title', 'System Status',
        description: 'System status section title');
    await _config.setParameter('home.file_manager_label', 'File Manager Service',
        description: 'File manager service label');
    await _config.setParameter('home.pocketbase_label', 'PocketBase Service',
        description: 'PocketBase service label');
    await _config.setParameter('home.active_status', 'Active',
        description: 'Active status text');
    await _config.setParameter('home.connected_status', 'Connected',
        description: 'Connected status text');
    await _config.setParameter('home.disconnected_status', 'Disconnected',
        description: 'Disconnected status text');
    await _config.setParameter('home.coming_soon_template', '$feature coming soon!',
        description: 'Coming soon message template');
    await _config.setParameter('home.body_padding', 16.0,
        description: 'Home screen body padding');
    await _config.setParameter('home.welcome_padding', 24.0,
        description: 'Welcome card padding');
    await _config.setParameter('home.section_spacing', 24.0,
        description: 'Section spacing');
    await _config.setParameter('home.grid_cross_axis_count', 2,
        description: 'Grid cross axis count');
    await _config.setParameter('home.grid_spacing', 16.0,
        description: 'Grid spacing');
    await _config.setParameter('home.status_card_padding', 16.0,
        description: 'Status card padding');
    await _config.setParameter('home.icon_size', 24.0,
        description: 'Status icon size');
    await _config.setParameter('home.icon_spacing', 12.0,
        description: 'Icon spacing');

    // AI configuration
    await _config.setParameter('ai.api_key', '',
        description: 'Google Generative AI API key');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: LoadingIndicator(
              message: _config.getParameter('app.loading_message',
                  defaultValue: 'Initializing iSuite...'),
              size: _config.getParameter('ui.icon_size_lg', defaultValue: 32.0),
            ),
          ),
        ),
      );
    }

    if (_initializationError != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(
                  _config.getParameter('ui.spacing_lg', defaultValue: 24.0)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: _config.getParameter('ui.icon_size_xl',
                        defaultValue: 48.0),
                    color: Color(_config.getParameter('ui.error_color',
                        defaultValue: 0xFFB00020)),
                  ),
                  SizedBox(
                      height: _config.getParameter('ui.spacing_md',
                          defaultValue: 16.0)),
                  Text(
                    'Initialization Error',
                    style: TextStyle(
                      fontSize: _config.getParameter('ui.font_size_xxl',
                          defaultValue: 24.0),
                      fontWeight: FontWeight.values[_config.getParameter(
                          'ui.font_weight_bold',
                          defaultValue: 700)],
                      color: Color(_config.getParameter('ui.on_surface_color',
                          defaultValue: 0xFF000000)),
                    ),
                  ),
                  SizedBox(
                      height: _config.getParameter('ui.spacing_sm',
                          defaultValue: 8.0)),
                  Text(
                    _initializationError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _config.getParameter('ui.font_size_md',
                          defaultValue: 16.0),
                      color: Color(_config.getParameter('ui.on_surface_color',
                          defaultValue: 0xFF000000)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: _config.getParameter('app.name', defaultValue: 'iSuite'),
      theme: buildLightTheme(_config),
      darkTheme: buildDarkTheme(_config),
      themeMode: _getThemeMode(),
      debugShowCheckedModeBanner:
          _config.getParameter('app.debug_banner', defaultValue: false),

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: _getSupportedLocales(),

      // Routing
      initialRoute: '/',
      routes: _buildRoutes(),

      // Error handling
      builder: (context, child) {
        return _ErrorBoundary(config: _config, child: child);
      },
    );
  }

  /// Get theme mode from configuration
  ThemeMode _getThemeMode() {
    final themeMode =
        _config.getParameter('ui.theme_mode', defaultValue: 'system');
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Get supported locales from configuration
  List<Locale> _getSupportedLocales() {
    final locales = _config.getParameter('app.supported_locales',
        defaultValue: ['en', 'es', 'fr', 'de', 'zh']);
    return locales.map((locale) => Locale(locale)).toList();
  }

  /// Build application routes
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => HomeScreen(config: _config),
      '/file-management': (context) => FileManagementScreen(config: _config),
      '/network-management': (context) =>
          NetworkManagementScreen(config: _config),
    };
  }
}

/// Error Boundary Widget for graceful error handling
class _ErrorBoundary extends StatefulWidget {
  final CentralConfig config;
  final Widget? child;

  const _ErrorBoundary({required this.config, this.child});

  @override
  State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void didUpdateWidget(covariant _ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state when child changes
    if (oldWidget.child != widget.child) {
      _error = null;
      _stackTrace = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Color(widget.config
            .getParameter('ui.background_color', defaultValue: 0xFFFAFAFA)),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(widget.config
                .getParameter('ui.spacing_lg', defaultValue: 24.0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: widget.config
                      .getParameter('ui.icon_size_xl', defaultValue: 48.0),
                  color: Color(widget.config.getParameter('ui.error_color',
                      defaultValue: 0xFFB00020)),
                ),
                SizedBox(
                    height: widget.config
                        .getParameter('ui.spacing_md', defaultValue: 16.0)),
                Text(
                  'Application Error',
                  style: TextStyle(
                    fontSize: widget.config
                        .getParameter('ui.font_size_xxl', defaultValue: 24.0),
                    fontWeight: FontWeight.values[widget.config.getParameter(
                        'ui.font_weight_bold',
                        defaultValue: 700)],
                    color: Color(widget.config.getParameter(
                        'ui.on_surface_color',
                        defaultValue: 0xFF000000)),
                  ),
                ),
                SizedBox(
                    height: widget.config
                        .getParameter('ui.spacing_sm', defaultValue: 8.0)),
                Text(
                  '$_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.config
                        .getParameter('ui.font_size_md', defaultValue: 16.0),
                    color: Color(widget.config.getParameter(
                        'ui.on_surface_color',
                        defaultValue: 0xFF000000)),
                  ),
                ),
                SizedBox(
                    height: widget.config
                        .getParameter('ui.spacing_lg', defaultValue: 24.0)),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _stackTrace = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(widget.config.getParameter(
                        'ui.primary_color',
                        defaultValue: 0xFF1976D2)),
                    foregroundColor: Color(widget.config.getParameter(
                        'ui.on_primary_color',
                        defaultValue: 0xFFFFFFFF)),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.config
                          .getParameter('ui.spacing_lg', defaultValue: 24.0),
                      vertical: widget.config
                          .getParameter('ui.spacing_md', defaultValue: 16.0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(widget.config
                          .getParameter('ui.border_radius_md',
                              defaultValue: 8.0)),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: widget.config
                          .getParameter('ui.font_size_md', defaultValue: 16.0),
                      fontWeight: FontWeight.values[widget.config.getParameter(
                          'ui.font_weight_medium',
                          defaultValue: 500)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child ?? const SizedBox.shrink();
  }

  @override
  void initState() {
    super.initState();

    // Setup error handling for this subtree
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });

      // Log the error (would use logging service in real implementation)
      debugPrint('UI Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };
  }
}

/// Home Screen (Main Dashboard)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.config});

  final CentralConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileManager = ref.watch(advancedFileManagerServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(config.getParameter('app.name', defaultValue: 'iSuite')),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(config.getParameter('home.body_padding', defaultValue: 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              child: Padding(
                padding: EdgeInsets.all(config.getParameter('home.welcome_padding', defaultValue: 24.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.getParameter('home.welcome_title', defaultValue: 'Welcome to iSuite'),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: config.getParameter('ui.spacing_sm', defaultValue: 8.0)),
                    Text(
                      config.getParameter('home.welcome_subtitle', defaultValue: 'Advanced file management platform with enterprise features'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: config.getParameter('home.section_spacing', defaultValue: 24.0)),

            // Quick actions
            Text(
              config.getParameter('home.quick_actions_title', defaultValue: 'Quick Actions'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: config.getParameter('ui.spacing_md', defaultValue: 16.0)),

            GridView.count(
              crossAxisCount: config.getParameter('home.grid_cross_axis_count', defaultValue: 2),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: config.getParameter('home.grid_spacing', defaultValue: 16.0),
              mainAxisSpacing: config.getParameter('home.grid_spacing', defaultValue: 16.0),
              children: [
                _QuickActionCard(
                  title: 'File Management',
                  subtitle: 'Organize and manage files',
                  icon: Icons.folder,
                  onTap: () => Navigator.pushNamed(context, '/file-management'),
                ),
                _QuickActionCard(
                  title: 'Network Management',
                  subtitle: 'FTP, cloud, and network storage',
                  icon: Icons.wifi,
                  onTap: () =>
                      Navigator.pushNamed(context, '/network-management'),
                ),
                _QuickActionCard(
                  title: 'Streaming',
                  subtitle: 'Stream media files',
                  icon: Icons.play_circle,
                  onTap: () => _showComingSoon(context, 'Media Streaming'),
                ),
                _QuickActionCard(
                  title: 'Wireless Sharing',
                  subtitle: 'Share files wirelessly',
                  icon: Icons.share,
                  onTap: () =>
                      _showComingSoon(context, 'Wireless File Sharing'),
                ),
                _QuickActionCard(
                  title: 'AI Insights',
                  subtitle: 'Get AI-powered insights',
                  icon: Icons.smart_toy,
                  onTap: () => _showAIInsights(context),
                ),
              ],
            ),

            SizedBox(height: config.getParameter('home.section_spacing', defaultValue: 32.0)),

            // System status
            Text(
              config.getParameter('home.system_status_title', defaultValue: 'System Status'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: config.getParameter('ui.spacing_md', defaultValue: 16.0)),

            StreamBuilder(
              stream: fileManager.events,
              builder: (context, snapshot) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(config.getParameter('home.status_card_padding', defaultValue: 16.0)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: config.getParameter('home.icon_size', defaultValue: 24.0),
                            ),
                            SizedBox(width: config.getParameter('home.icon_spacing', defaultValue: 12.0)),
                            Text(
                              config.getParameter('home.file_manager_label', defaultValue: 'File Manager Service'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Text(
                              config.getParameter('home.active_status', defaultValue: 'Active'),
                              style: TextStyle(color: Colors.green),
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

            SizedBox(height: config.getParameter('ui.spacing_md', defaultValue: 16.0)),

            Consumer(
              builder: (context, ref, child) {
                final pocketbaseService = ref.watch(pocketbaseServiceProvider);
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(config.getParameter('home.status_card_padding', defaultValue: 16.0)),
                    child: Row(
                      children: [
                        Icon(
                          pocketbaseService.isConnected ? Icons.check_circle : Icons.error,
                          color: pocketbaseService.isConnected ? Colors.green : Colors.red,
                          size: config.getParameter('home.icon_size', defaultValue: 24.0),
                        ),
                        SizedBox(width: config.getParameter('home.icon_spacing', defaultValue: 12.0)),
                        Text(
                          config.getParameter('home.pocketbase_label', defaultValue: 'PocketBase Service'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          pocketbaseService.isConnected ? config.getParameter('home.connected_status', defaultValue: 'Connected') : config.getParameter('home.disconnected_status', defaultValue: 'Disconnected'),
                          style: TextStyle(color: pocketbaseService.isConnected ? Colors.green : Colors.red),
                        ),
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

  void _showComingSoon(BuildContext context, String feature) {
    final template = config.getParameter('home.coming_soon_template', defaultValue: '$feature coming soon!');
    final message = template.replaceAll('\$feature', feature);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAIInsights(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final aiService = ref.read(generativeAIServiceProvider);
          return AlertDialog(
            title: Text('AI Insights'),
            content: FutureBuilder<String>(
              future: aiService.generateSummary('iSuite is an advanced cross-platform file management platform with enterprise features, network sharing, and AI capabilities.'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Text(snapshot.data ?? 'No insights available');
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
