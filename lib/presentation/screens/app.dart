import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Infrastructure services
import '../../core/config/central_config.dart';
import '../../core/pocketbase_service.dart';
import '../../core/generative_ai_service.dart';
import '../../core/offline_manager.dart';
import '../../core/biometric_auth_service.dart';

// Presentation Components
import 'screens/home_screen.dart';
import 'screens/file_management_screen.dart';
import 'screens/file_compression_screen.dart';
import 'screens/screens/streaming_screen.dart';
import 'screens/screens/wireless_sharing_screen.dart';
import 'screens/screens/file_management_screen.dart';
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
  late final PocketBaseService _pocketbaseService;
  late final GenerativeAIService _generativeAIService;
  late final OfflineManager _offlineManager;
  final BiometricAuthService _biometricAuthService = BiometricAuthService();

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
      _pocketbaseService = container.read(pocketbaseServiceProvider);
      await _pocketbaseService.initialize();
      _generativeAIService = container.read(generativeAIServiceProvider);
      await _generativeAIService.initialize();
      _offlineManager = container.read(offlineManagerProvider);
      await _offlineManager.initialize();

      // Require biometric authentication for enhanced security
      if (await _biometricAuthService.isBiometricAvailable()) {
        final authenticated = await _biometricAuthService.authenticate();
        if (!authenticated) {
          setState(() {
            _initializationError = 'Biometric authentication failed. Please try again.';
            _isLoading = false;
          });
          return;
        }
      }

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

    // UI strings for internationalization and central control
    await _config.setParameter('ui.add_files_button', 'Add Files',
        description: 'Add files button text');
    await _config.setParameter('ui.compress_files_button', 'Compress Files',
        description: 'Compress files button text');
    await _config.setParameter('ui.decompress_file_button', 'Decompress File',
        description: 'Decompress file button text');
    await _config.setParameter('ui.select_zip_file', 'Select ZIP File',
        description: 'Select ZIP file button text');
    await _config.setParameter('ui.archive_name_label', 'Archive Name',
        description: 'Archive name text field label');
    await _config.setParameter('ui.output_directory_label', 'Output Directory',
        description: 'Output directory dropdown label');
    await _config.setParameter('ui.compression_success', 'Compression successful',
        description: 'Compression success message prefix');
    await _config.setParameter('ui.decompression_success', 'Decompression successful',
        description: 'Decompression success message prefix');
    await _config.setParameter('ui.select_files_and_name', 'Please select files and enter archive name',
        description: 'Validation message for compression');
    await _config.setParameter('ui.select_zip_and_directory', 'Please select ZIP file and output directory',
        description: 'Validation message for decompression');

    // Additional UI parameters
    await _config.setParameter('ui.accent_color', 0xFF448AFF,
        description: 'Accent color for UI elements');
    await _config.setParameter('ui.font_family', 'Roboto',
        description: 'Default font family');
    await _config.setParameter('ui.font_size_title', 20.0,
        description: 'Font size for titles');
    await _config.setParameter('ui.font_size_body', 14.0,
        description: 'Font size for body text');
    await _config.setParameter('ui.animation_duration', 300,
        description: 'Animation duration in milliseconds');
    await _config.setParameter('ui.border_radius', 8.0,
        description: 'Border radius for UI elements');
    await _config.setParameter('ui.elevation', 2.0,
        description: 'Default elevation for cards');

    // App feature parameters
    await _config.setParameter('app.cache_size', 100,
        description: 'Cache size in MB');
    await _config.setParameter('app.timeout', 30,
        description: 'Default timeout in seconds');
    await _config.setParameter('app.retry_attempts', 3,
        description: 'Number of retry attempts');

    // AI parameters
    await _config.setParameter('ai.max_tokens', 1000,
        description: 'Maximum tokens for AI responses');
    await _config.setParameter('ai.temperature', 0.7,
        description: 'AI temperature for creativity');

    // AI configuration
    await _config.setParameter('ai.api_key', '',
        description: 'Google Generative AI API key');
    await _config.setParameter('ai.model', 'gemini-1.5-flash',
        description: 'AI model to use for generative features');
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
      '/file-management': (context) => const FileManagementScreen(),
      '/file-compression': (context) => const FileCompressionScreen(),
      '/streaming': (context) => const StreamingScreen(),
      '/wireless-sharing': (context) => const WirelessSharingScreen(),
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

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: config.getParameter('home.grid_spacing', defaultValue: 16.0),
                mainAxisSpacing: config.getParameter('home.grid_spacing', defaultValue: 16.0),
              ),
              itemCount: 9, // Updated for 9 cards
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _QuickActionCard(
                      title: 'File Management',
                      subtitle: 'Organize and manage files',
                      icon: Icons.folder,
                      onTap: () => Navigator.pushNamed(context, '/file-management'),
                    );
                  case 1:
                    return _QuickActionCard(
                      title: 'Network Management',
                      subtitle: 'FTP, cloud, and network storage',
                      icon: Icons.wifi,
                      onTap: () =>
                          Navigator.pushNamed(context, '/network-management'),
                    );
                  case 2:
                    return _QuickActionCard(
                      title: 'Streaming',
                      subtitle: 'Stream media files',
                      icon: Icons.play_circle,
                      onTap: () => Navigator.pushNamed(context, '/streaming'),
                    );
                  case 3:
                    return _QuickActionCard(
                      title: 'Wireless Sharing',
                      subtitle: 'Share files wirelessly',
                      icon: Icons.share,
                      onTap: () => Navigator.pushNamed(context, '/wireless-sharing'),
                    );
                  case 4:
                    return _QuickActionCard(
                      title: 'AI Insights',
                      subtitle: 'Get AI-powered insights',
                      icon: Icons.smart_toy,
                      onTap: () => _showAIInsights(context),
                    );
                  case 5:
                    return _QuickActionCard(
                      title: 'File Compression',
                      subtitle: 'Compress and decompress files',
                      icon: Icons.archive,
                      onTap: () => Navigator.pushNamed(context, '/file-compression'),
                    );
                  case 6:
                    return _QuickActionCard(
                      title: 'Find Duplicates',
                      subtitle: 'Detect duplicate files',
                      icon: Icons.find_replace,
                      onTap: () => _showDuplicateDetection(context),
                    );
                  case 7:
                    return _QuickActionCard(
                      title: 'AI Text Generation',
                      subtitle: 'Generate text with AI',
                      icon: Icons.text_fields,
                      onTap: () => _showAITextGeneration(context),
                    );
                  case 8:
                    return _QuickActionCard(
                      title: 'AI Code Generation',
                      subtitle: 'Generate code with AI',
                      icon: Icons.code,
                      onTap: () => _showAICodeGeneration(context),
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAIInsights(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Insights coming soon!')),
    );
  }

  void _showDuplicateDetection(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate Detection coming soon!')),
    );
  }

  void _showAITextGeneration(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Text Generation coming soon!')),
    );
  }

  void _showAICodeGeneration(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Code Generation coming soon!')),
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
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
    final message = template.replaceAll('\$feature', feature);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAICodeGeneration(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AICodeGenerationDialog(),
    );
  }
}

class AITextGenerationDialog extends ConsumerStatefulWidget {
  const AITextGenerationDialog({super.key});

  @override
  State<AITextGenerationDialog> createState() => _AITextGenerationDialogState();
}

class _AITextGenerationDialogState extends ConsumerState<AITextGenerationDialog> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedText;

  Future<void> _generateText() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _generatedText = null;
    });

    final service = ref.read(generativeAIServiceProvider);
    final result = await service.generateText(_promptController.text);

    setState(() {
      _isGenerating = false;
      _generatedText = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Text Generation'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Enter your prompt',
                hintText: 'Describe what text to generate...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateText,
              child: _isGenerating
                  ? const CircularProgressIndicator()
                  : const Text('Generate Text'),
            ),
            if (_generatedText != null) ...[
              const SizedBox(height: 16),
              const Text('Generated Text:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_generatedText!),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class AICodeGenerationDialog extends ConsumerStatefulWidget {
  const AICodeGenerationDialog({super.key});

  @override
  State<AICodeGenerationDialog> createState() => _AICodeGenerationDialogState();
}

class _AICodeGenerationDialogState extends ConsumerState<AICodeGenerationDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedLanguage = 'dart';
  bool _isGenerating = false;
  String? _generatedCode;

  Future<void> _generateCode() async {
    if (_descriptionController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _generatedCode = null;
    });

    final service = ref.read(generativeAIServiceProvider);
    final result = await service.generateCode(_descriptionController.text, language: _selectedLanguage);

    setState(() {
      _isGenerating = false;
      _generatedCode = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Code Generation'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Describe the code to generate',
                hintText: 'E.g., Create a Flutter widget for a login form',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              items: ['dart', 'python', 'javascript', 'java', 'cpp'].map((lang) {
                return DropdownMenuItem(value: lang, child: Text(lang.toUpperCase()));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Programming Language'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateCode,
              child: _isGenerating
                  ? const CircularProgressIndicator()
                  : const Text('Generate Code'),
            ),
            if (_generatedCode != null) ...[
              const SizedBox(height: 16),
              const Text('Generated Code:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(_generatedCode!),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
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

/// Duplicate Detection Dialog Widget
class DuplicateDetectionDialog extends ConsumerStatefulWidget {
  const DuplicateDetectionDialog({super.key});

  @override
  State<DuplicateDetectionDialog> createState() => _DuplicateDetectionDialogState();
}

class _DuplicateDetectionDialogState extends ConsumerState<DuplicateDetectionDialog> {
  bool _isScanning = false;
  Map<String, List<String>>? _duplicates;

  Future<void> _scanForDuplicates() async {
    setState(() {
      _isScanning = true;
      _duplicates = null;
    });

    // For demo, use sample files. In real app, get from file picker or directory.
    final sampleFiles = [
      '/path/to/file1.txt',
      '/path/to/file2.txt',
      '/path/to/duplicate1.txt',
      '/path/to/duplicate2.txt',
    ];

    final service = ref.read(duplicateDetectionServiceProvider);
    final duplicates = await service.findDuplicates(sampleFiles);

    setState(() {
      _isScanning = false;
      _duplicates = duplicates;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Find Duplicate Files'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isScanning
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning for duplicates...'),
                ],
              )
            : _duplicates == null
                ? const Text('Click scan to find duplicate files.')
                : _duplicates!.isEmpty
                    ? const Text('No duplicates found.')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Found ${_duplicates!.length} duplicate groups:'),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _duplicates!.length,
                              itemBuilder: (context, index) {
                                final hash = _duplicates!.keys.elementAt(index);
                                final files = _duplicates![hash]!;
                                return ListTile(
                                  title: Text('Group ${index + 1} (${files.length} files)'),
                                  subtitle: Text(files.join('\n')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
      actions: [
        TextButton(
          onPressed: _isScanning ? null : _scanForDuplicates,
          child: Text(_duplicates != null ? 'Scan Again' : 'Scan'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
