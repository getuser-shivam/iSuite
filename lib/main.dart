/// ============================================================================
/// iSuite Pro - Advanced File & Network Management Application
///
/// A comprehensive, enterprise-grade Flutter application for file management,
/// network operations, and productivity enhancement with AI-powered features.
///
/// Key Features:
/// - Advanced File Operations (local & cloud storage)
/// - Network Discovery & Peer-to-Peer Sharing
/// - AI-Powered Analytics & Intelligence
/// - Real-time Collaboration & Synchronization
/// - Enterprise Monitoring & Health Checks
/// - Cross-platform Support (Android, iOS, Windows, Linux, macOS, Web)
///
/// Architecture:
/// - Clean Architecture with layered separation
/// - Riverpod for state management
/// - Centralized configuration system
/// - Modular feature-based organization
/// - Comprehensive error handling & recovery
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/network_page.dart';
import 'presentation/pages/files_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/ai_analysis_page.dart';
import 'core/riverpod_providers.dart';
import 'core/widgets/error_boundary.dart';
import 'infrastructure/monitoring/performance_monitor.dart';
import 'core/config/central_config.dart';
import 'src/presentation/screens/network/ftp_browser_screen.dart';
import 'l10n/app_localizations.dart';

/// Enhanced iSuite Pro Application with Riverpod State Management & Enterprise Architecture
///
/// This is the main application class that orchestrates the entire iSuite ecosystem.
/// It provides:
/// - Multi-provider architecture with Riverpod
/// - Theme management with dynamic configuration
/// - Error boundaries for crash recovery
/// - Performance monitoring throughout the app
/// - Localization support for multiple languages
/// - Responsive design for all screen sizes
class ISuiteApp extends ConsumerStatefulWidget {
  const ISuiteApp({super.key});

  @override
  ConsumerState<ISuiteApp> createState() => _ISuiteAppState();
}

/// State management for the main iSuite application
///
/// Handles:
/// - Dynamic theme loading and configuration
/// - Application lifecycle management
/// - Error recovery and user feedback
/// - Performance monitoring integration
class _ISuiteAppState extends ConsumerState<ISuiteApp> {
  /// Light theme configuration - loaded asynchronously for performance
  ThemeData? _lightTheme;

  /// Dark theme configuration - loaded asynchronously for performance
  ThemeData? _darkTheme;

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  /// Loads both light and dark themes asynchronously
  ///
  /// This prevents UI blocking during theme initialization and allows
  /// for dynamic theme configuration based on CentralConfig parameters.
  Future<void> _loadThemes() async {
    final lightTheme = await _buildEnhancedLightTheme();
    final darkTheme = await _buildEnhancedDarkTheme();

    setState(() {
      _lightTheme = lightTheme;
      _darkTheme = darkTheme;
    });
  }

  /// Builds the enhanced light theme with CentralConfig parameters
  ///
  /// Features:
  /// - Dynamic color scheme based on configuration
  /// - Material 3 design system
  /// - Responsive component themes
  /// - Accessibility-compliant contrast ratios
  Future<ThemeData> _buildEnhancedLightTheme() async {
    final themeProvider = ref.read(themeProvider.notifier);
    return await themeProvider.buildLightTheme();
  }

  /// Builds the enhanced dark theme with CentralConfig parameters
  ///
  /// Features:
  /// - Consistent with light theme but optimized for dark mode
  /// - Proper contrast ratios for readability
  /// - Energy-efficient dark color schemes
  Future<ThemeData> _buildEnhancedDarkTheme() async {
    final themeProvider = ref.read(themeProvider.notifier);
    return await themeProvider.buildDarkTheme();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while themes are being loaded
    if (_lightTheme == null || _darkTheme == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'iSuite Pro',
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.system,
      home: const ISuiteHomePage(),
      debugShowCheckedModeBanner: false,

      /// Performance monitoring wrapper for the entire application
      /// Provides real-time performance metrics and memory monitoring
      builder: (context, child) {
        return PerformanceMonitor(
          child: ErrorBoundary(
            child: child ?? const SizedBox(),
          ),
        );
      },
    );
  }
}

class ISuiteHomePage extends ConsumerWidget {
  const ISuiteHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final selectedIndex = ref.watch(navigationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'iSuite Pro',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        centerTitle: true,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final healthStatus = ref.watch(systemHealthProvider);
              return IconButton(
                icon: Icon(
                  healthStatus.status == HealthStatus.healthy
                    ? Icons.health_and_safety
                    : healthStatus.status == HealthStatus.warning
                    ? Icons.warning
                    : Icons.error,
                  color: healthStatus.status == HealthStatus.healthy
                    ? Colors.green
                    : healthStatus.status == HealthStatus.warning
                    ? Colors.orange
                    : Colors.red,
                ),
                onPressed: () => _showSystemHealth(context, ref),
                tooltip: 'System Health: ${healthStatus.status.name}',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context, ref),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          HomePage(),
          NetworkPage(),
          FilesPage(),
          AIAnalysisPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(navigationProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
            selectedIcon: Icon(Icons.home_outlined),
          ),
          NavigationDestination(
            icon: Icon(Icons.wifi),
            label: 'Network',
            selectedIcon: Icon(Icons.wifi_outlined),
          ),
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: 'Files',
            selectedIcon: Icon(Icons.folder_outlined),
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'AI Analysis',
            selectedIcon: Icon(Icons.analytics_outlined),
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
            selectedIcon: Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final fabState = ref.watch(fabProvider);
          return FloatingActionButton.extended(
            onPressed: fabState.onPressed,
            icon: Icon(fabState.icon),
            label: Text(fabState.label),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          );
        },
      ),
    );
  }

  void _showSystemHealth(BuildContext context, WidgetRef ref) {
    final healthStatus = ref.read(systemHealthProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Health'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${healthStatus.status.name.toUpperCase()}'),
            Text('Score: ${healthStatus.score.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            if (healthStatus.issues.isNotEmpty) ...[
              const Text('Issues:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...healthStatus.issues.map((issue) => Text('• $issue')),
            ],
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

  void _navigateToSettings(BuildContext context, WidgetRef ref) {
    ref.read(navigationProvider.notifier).state = 4; // Settings index
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize CentralConfig first
  await CentralConfig.instance.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: ISuiteApp(),
    ),
  );
}
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return PerformanceMonitor(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => NetworkProvider()),
          Provider(create: (_) => SupabaseProvider()), // Enhanced Supabase services
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: 'iSuite Pro - Advanced File & Network Manager',
              debugShowCheckedModeBanner: false,
              theme: _lightTheme,
              darkTheme: _darkTheme,
              themeMode: themeProvider.themeMode,
              home: const ErrorBoundary(
                child: ISuiteHomePage(),
                fallbackBuilder: _buildErrorFallback,
              ),
              routes: {
                '/home': (context) => const ErrorBoundary(child: HomePage()),
                '/network': (context) => const ErrorBoundary(child: NetworkPage()),
                '/files': (context) => const ErrorBoundary(child: FilesPage()),
                '/ai-analysis': (context) => const ErrorBoundary(child: AIAnalysisPage()),
                '/settings': (context) => const ErrorBoundary(child: SettingsPage()),
              },
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaleFactor: themeProvider.textScaleFactor.clamp(0.8, 2.0),
                    boldText: themeProvider.useHighContrast,
                  ),
                  child: ScrollConfiguration(
                    behavior: const _CustomScrollBehavior(),
                    child: _buildAccessibilityWrapper(child!),
                  ),
                );
              },
              // Enhanced localization support
              localizationsDelegates: const [
                // Add localization delegates when needed
              ],
              supportedLocales: const [
                Locale('en', ''), // English
                Locale('es', ''), // Spanish
                Locale('fr', ''), // French
                Locale('de', ''), // German
                Locale('zh', ''), // Chinese
                Locale('ja', ''), // Japanese
              ],
              // Custom error handling
              onUnknownRoute: (settings) => MaterialPageRoute(
                builder: (context) => const ErrorBoundary(
                  child: Scaffold(
                    body: Center(
                      child: Text('Page not found'),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildErrorFallback(BuildContext context, FlutterErrorDetails details) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Error'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'The application encountered an unexpected error.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Restart the app
                  runApp(const ISuiteApp());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessibilityWrapper(Widget child) {
    return Semantics(
      label: 'iSuite Pro Application',
      child: ExcludeSemantics(
        excluding: false,
        child: child,
      ),
    );
  }

  Future<ThemeData> _buildEnhancedLightTheme() async {
    final baseTheme = ThemeData.light();

    // Get UI parameters from central config
    final primaryColor = await CentralConfig.instance.getParameter<int>('ui.primary_color') ?? 0xFF2196F3;
    final borderRadiusLarge = await CentralConfig.instance.getParameter<double>('ui.border_radius_large') ?? 16.0;
    final borderRadiusMedium = await CentralConfig.instance.getParameter<double>('ui.border_radius_medium') ?? 12.0;
    final elevationMedium = await CentralConfig.instance.getParameter<double>('ui.elevation_medium') ?? 2.0;
    final elevationHigh = await CentralConfig.instance.getParameter<double>('ui.elevation_high') ?? 4.0;
    final elevationXHigh = await CentralConfig.instance.getParameter<double>('ui.elevation_xhigh') ?? 8.0;
    final fontSizeXLarge = await CentralConfig.instance.getParameter<double>('ui.font_size_xlarge') ?? 18.0;
    final fontSizeMedium = await CentralConfig.instance.getParameter<double>('ui.font_size_medium') ?? 14.0;
    final animationDurationFast = await CentralConfig.instance.getParameter<int>('ui.animation_duration_fast') ?? 200;
    final paddingHorizontal = await CentralConfig.instance.getParameter<double>('ui.padding_medium') ?? 24.0;
    final paddingVertical = await CentralConfig.instance.getParameter<double>('ui.padding_medium') ?? 12.0;
    final marginHorizontal = await CentralConfig.instance.getParameter<double>('ui.margin_small') ?? 8.0;
    final marginVertical = await CentralConfig.instance.getParameter<double>('ui.margin_small') ?? 4.0;
    final contentPaddingHorizontal = await CentralConfig.instance.getParameter<double>('ui.padding_medium') ?? 16.0;
    final contentPaddingVertical = await CentralConfig.instance.getParameter<double>('ui.padding_medium') ?? 12.0;

    return baseTheme.copyWith(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(primaryColor),
        brightness: Brightness.light,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),

      // Enhanced Typography Scale
      typography: Typography.material2021().copyWith(
        englishLike: Typography.englishLike2021,
        dense: Typography.dense2021,
        tall: Typography.tall2021,
      ),

      textTheme: _buildEnhancedTextTheme(Brightness.light),

      // Advanced Component Themes
      appBarTheme: AppBarTheme(
        elevation: await CentralConfig.instance.getParameter<double>('appbar.elevation') ?? 0.0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const ColorScheme.light().onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: elevationHigh,
        titleTextStyle: TextStyle(
          fontSize: await CentralConfig.instance.getParameter<double>('appbar.title_font_size') ?? 20.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        toolbarTextStyle: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w500,
        ),
      ),

      cardTheme: CardTheme(
        elevation: elevationMedium,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: marginHorizontal, vertical: marginVertical),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: await CentralConfig.instance.getParameter<double>('ui.elevation_low') ?? 0.0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          animationDuration: Duration(milliseconds: animationDurationFast),
          enableFeedback: true,
          alignment: Alignment.center,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const ColorScheme.light().primary.withOpacity(0.8);
            }
            return const ColorScheme.light().primary;
          }),
          foregroundColor: WidgetStateProperty.all(
            const ColorScheme.light().onPrimary,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: await CentralConfig.instance.getParameter<double>('fab.elevation') ?? 6.0,
        focusElevation: await CentralConfig.instance.getParameter<double>('fab.elevation') ?? 6.0 + 2.0,
        hoverElevation: await CentralConfig.instance.getParameter<double>('fab.elevation') ?? 6.0 + 2.0,
        backgroundColor: const ColorScheme.light().primaryContainer,
        foregroundColor: const ColorScheme.light().onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(await CentralConfig.instance.getParameter<double>('fab.size') ?? 56.0 / 2),
        ),
        extendedPadding: EdgeInsets.symmetric(horizontal: await CentralConfig.instance.getParameter<double>('fab.extended_padding_horizontal') ?? 16.0),
        extendedIconLabelSpacing: await CentralConfig.instance.getParameter<double>('fab.extended_icon_spacing') ?? 8.0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: await CentralConfig.instance.getParameter<double>('ui.elevation_low') ?? 0.0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: const ColorScheme.light().primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: await CentralConfig.instance.getParameter<double>('bottom_nav.height') ?? 80.0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const ColorScheme.light().surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(
            color: const ColorScheme.light().outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(
            color: ColorScheme.light().primary,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: contentPaddingHorizontal, vertical: contentPaddingVertical),
      ),

      // Enhanced Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: _CustomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // Custom Component Themes
      sliderTheme: SliderThemeData(
        trackHeight: await CentralConfig.instance.getParameter<double>('ui.elevation_low') ?? 4.0,
        activeTrackColor: const ColorScheme.light().primary,
        inactiveTrackColor: const ColorScheme.light().surfaceVariant,
        thumbColor: const ColorScheme.light().primary,
        overlayColor: const ColorScheme.light().primary.withOpacity(0.2),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: await CentralConfig.instance.getParameter<double>('ui.icon_size_medium') ?? 8.0),
        overlayShape: RoundSliderOverlayShape(overlayRadius: await CentralConfig.instance.getParameter<double>('ui.icon_size_large') ?? 20.0),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const ColorScheme.light().primary;
          }
          return const ColorScheme.light().surfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const ColorScheme.light().primary.withOpacity(0.3);
          }
          return const ColorScheme.light().surfaceVariant.withOpacity(0.3);
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(await CentralConfig.instance.getParameter<double>('ui.border_radius_small') ?? 4.0),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const ColorScheme.light().primary;
          }
          return const ColorScheme.light().onSurfaceVariant;
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearTrackColor: ColorScheme.light.surfaceVariant,
        circularTrackColor: ColorScheme.light.surfaceVariant,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const ColorScheme.light().surfaceContainerHighest,
        contentTextStyle: TextStyle(
          color: const ColorScheme.light().onSurface,
        ),
        actionTextColor: const ColorScheme.light().primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(await CentralConfig.instance.getParameter<double>('ui.border_radius_small') ?? 8.0),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogTheme(
        backgroundColor: const ColorScheme.light().surface,
        elevation: elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(await CentralConfig.instance.getParameter<double>('ui.border_radius_xlarge') ?? 20.0),
        ),
        titleTextStyle: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.w600,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorScheme.light.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  Future<ThemeData> _buildEnhancedDarkTheme() async {
    final baseTheme = ThemeData.dark();

    // Get UI parameters from central config (same as light theme for consistency)
    final primaryColor = await CentralConfig.instance.getParameter<int>('ui.primary_color') ?? 0xFF2196F3;
    final borderRadiusLarge = await CentralConfig.instance.getParameter<double>('ui.border_radius_large') ?? 16.0;
    final borderRadiusMedium = await CentralConfig.instance.getParameter<double>('ui.border_radius_medium') ?? 12.0;
    final elevationMedium = await CentralConfig.instance.getParameter<double>('ui.elevation_medium') ?? 2.0;
    final fontSizeXLarge = await CentralConfig.instance.getParameter<double>('ui.font_size_xlarge') ?? 18.0;
    final contentPaddingHorizontal = await CentralConfig.instance.getParameter<double>('ui.padding_medium') ?? 16.0;
    final contentPaddingVertical = await CentralConfig.instance.getParameter<double>('ui.padding_medium') ?? 12.0;

    return baseTheme.copyWith(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(primaryColor),
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),

      textTheme: _buildEnhancedTextTheme(Brightness.dark),

      // Similar enhancements for dark theme
      appBarTheme: AppBarTheme(
        elevation: await CentralConfig.instance.getParameter<double>('appbar.elevation') ?? 0.0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const ColorScheme.dark().onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: await CentralConfig.instance.getParameter<double>('ui.elevation_high') ?? 4.0,
        titleTextStyle: TextStyle(
          fontSize: await CentralConfig.instance.getParameter<double>('appbar.title_font_size') ?? 20.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),

      cardTheme: CardTheme(
        elevation: elevationMedium,
        shadowColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(
          horizontal: await CentralConfig.instance.getParameter<double>('ui.margin_small') ?? 8.0,
          vertical: await CentralConfig.instance.getParameter<double>('ui.margin_small') ?? 4.0
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: await CentralConfig.instance.getParameter<double>('ui.elevation_low') ?? 0.0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: await CentralConfig.instance.getParameter<double>('ui.padding_medium') ?? 24.0,
            vertical: await CentralConfig.instance.getParameter<double>('ui.padding_medium') ?? 12.0
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          animationDuration: Duration(milliseconds: await CentralConfig.instance.getParameter<int>('ui.animation_duration_fast') ?? 200),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const ColorScheme.dark().primary.withOpacity(0.8);
            }
            return const ColorScheme.dark().primary;
          }),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const ColorScheme.dark().surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(
            color: const ColorScheme.dark().outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(
            color: ColorScheme.dark().primary,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: contentPaddingHorizontal, vertical: contentPaddingVertical),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: _CustomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  TextTheme _buildEnhancedTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.dark ? Colors.white : Colors.black;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.16,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.22,
        color: baseColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.25,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.29,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.33,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
        height: 1.27,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.5,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: baseColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: baseColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: baseColor,
      ),
    );
  }
}

/// Custom Page Transitions Builder for Windows
class _CustomPageTransitionsBuilder extends PageTransitionsBuilder {
  const _CustomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

/// Custom Scroll Behavior with Enhanced Performance
class _CustomScrollBehavior extends ScrollBehavior {
  const _CustomScrollBehavior();

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8,
      radius: const Radius.circular(4),
      child: child,
    );
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      showLeading: true,
      showTrailing: true,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  bool shouldNotify(covariant ScrollBehavior oldDelegate) => false;
}

class ISuiteHomePage extends StatefulWidget {
  const ISuiteHomePage({super.key});

  @override
  State<ISuiteHomePage> createState() => _ISuiteHomePageState();
}

class _ISuiteHomePageState extends State<ISuiteHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const NetworkPage(),
    const FilesPage(),
    const AIAnalysisPage(),
    const SettingsPage(),
    const FtpBrowserScreen(),
  ];

  final List<String> _pageTitles = [
    'Home',
    'Network',
    'Files',
    'AI Analysis',
    'Settings',
  ];

  final List<IconData> _pageIcons = [
    Icons.home,
    Icons.wifi,
    Icons.folder,
    Icons.psychology,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _pages.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _pageTitles[_currentIndex],
            key: ValueKey<String>(_pageTitles[_currentIndex]),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: appProvider.notificationCount > 0,
                  label: Text(appProvider.notificationCount.toString()),
                  child: const Icon(Icons.notifications),
                ),
                onPressed: () => _showNotifications(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About'),
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Help'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: List.generate(
          _pages.length,
          (index) => NavigationDestination(
            icon: Icon(_pageIcons[index]),
            label: _pageTitles[index],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return FloatingActionButton.extended(
          onPressed: () => _showQuickActions(context),
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
        );
      },
    );
  }

  IconData _getFabIcon() {
    switch (_currentIndex) {
      case 0: return Icons.add;
      case 1: return Icons.wifi_find;
      case 2: return Icons.create_new_folder;
      case 3: return Icons.tune;
      default: return Icons.add;
    }
  }

  String _getFabLabel() {
    switch (_currentIndex) {
      case 0: return 'Quick Action';
      case 1: return 'Scan Network';
      case 2: return 'New Folder';
      case 3: return 'Settings';
      default: return 'Action';
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        appProvider.clearNotifications();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (appProvider.notifications.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No notifications'),
                    ),
                  )
                else
                  ...appProvider.notifications.map((notification) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.color.withOpacity(0.2),
                      child: Icon(notification.icon, color: notification.color),
                    ),
                    title: Text(notification.title),
                    subtitle: Text(notification.message),
                    trailing: Text(
                      _formatTime(notification.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: EnhancedSearchDelegate(),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionTile(
                  context,
                  'New Folder',
                  Icons.create_new_folder,
                  Colors.blue,
                  () => _createNewFolder(context),
                ),
                _buildQuickActionTile(
                  context,
                  'Network Scan',
                  Icons.wifi_find,
                  Colors.green,
                  () => _startNetworkScan(context),
                ),
                _buildQuickActionTile(
                  context,
                  'Upload File',
                  Icons.upload_file,
                  Colors.orange,
                  () => _uploadFile(context),
                ),
                _buildQuickActionTile(
                  context,
                  'System Info',
                  Icons.info,
                  Colors.purple,
                  () => _showSystemInfo(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _createNewFolder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter folder name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (name) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Folder "$name" created successfully!')),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Create'),
          ),
        ],
      ),
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
      const SnackBar(content: Text('File upload feature - Coming soon!')),
    );
  }

  void _showSystemInfo(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'iSuite Pro',
      applicationVersion: '2.0.0',
      applicationIcon: const Icon(Icons.apps, size: 48),
      children: [
        const Text('Advanced File & Network Management Suite'),
        const Text('Built with Flutter for cross-platform excellence'),
        const Text('Features: AI-powered analytics, real-time sync, enterprise security'),
      ],
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'refresh':
        setState(() {});
        break;
      case 'about':
        _showSystemInfo(context);
        break;
      case 'help':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help system - Coming soon!')),
        );
        break;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Enhanced Search Delegate
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

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          leading: Icon(result['icon']),
          title: Text(result['title']),
          subtitle: Text(result['subtitle']),
          onTap: () => _navigateToResult(context, result),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _getSuggestions(query);

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: Icon(suggestion['icon']),
          title: Text(suggestion['title']),
          subtitle: Text(suggestion['subtitle']),
          onTap: () {
            query = suggestion['title'];
            showResults(context);
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getSuggestions(String query) {
    if (query.isEmpty) {
      return [
        {'title': 'Files', 'subtitle': 'Browse and manage files', 'icon': Icons.folder, 'route': '/files'},
        {'title': 'Network', 'subtitle': 'Network tools and scanning', 'icon': Icons.wifi, 'route': '/network'},
        {'title': 'Settings', 'subtitle': 'App preferences', 'icon': Icons.settings, 'route': '/settings'},
      ];
    }

    return [
      {'title': 'Files', 'subtitle': 'Search in files', 'icon': Icons.folder, 'route': '/files'},
      {'title': 'Network', 'subtitle': 'Network search', 'icon': Icons.wifi, 'route': '/network'},
    ];
  }

  List<Map<String, dynamic>> _getSearchResults(String query) {
    // Mock search results - in real app, this would search actual content
    return [
      {'title': 'Documents', 'subtitle': 'Found in Files', 'icon': Icons.folder, 'route': '/files'},
      {'title': 'WiFi Settings', 'subtitle': 'Found in Network', 'icon': Icons.wifi, 'route': '/network'},
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

/// Application Entry Point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Central Config with UI parameters
  await CentralConfig.instance.initialize();
  await CentralConfig.instance.setupUIConfig();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize PocketBase Client with enhanced organization
  try {
    await PocketBaseClientConfig.initialize();
    debugPrint('PocketBase Client initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize PocketBase Client: $e');
    // Continue without PocketBase for demo purposes
  }

  runApp(const ProviderScope(child: ISuiteApp()));
}
