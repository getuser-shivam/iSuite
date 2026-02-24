import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/network_page.dart';
import 'presentation/pages/files_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/ai_analysis_page.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/network_provider.dart';
import 'core/supabase_provider.dart';
import 'core/widgets/error_boundary.dart';
import 'core/widgets/performance_monitor.dart';

/// Enhanced iSuite Pro Application with Advanced Features & Enterprise Architecture
class ISuiteApp extends StatelessWidget {
  const ISuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
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
              theme: _buildEnhancedLightTheme(),
              darkTheme: _buildEnhancedDarkTheme(),
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

  ThemeData _buildEnhancedLightTheme() {
    final baseTheme = ThemeData.light();

    return baseTheme.copyWith(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
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
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const ColorScheme.light().onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 4,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        toolbarTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          animationDuration: const Duration(milliseconds: 200),
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
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        backgroundColor: const ColorScheme.light().primaryContainer,
        foregroundColor: const ColorScheme.light().onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
        extendedIconLabelSpacing: 8,
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: const ColorScheme.light().primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 80,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const ColorScheme.light().surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const ColorScheme.light().outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const ColorScheme.light().primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        trackHeight: 4,
        activeTrackColor: const ColorScheme.light().primary,
        inactiveTrackColor: const ColorScheme.light().surfaceVariant,
        thumbColor: const ColorScheme.light().primary,
        overlayColor: const ColorScheme.light().primary.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
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
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const ColorScheme.light().primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(
          const ColorScheme.light().onPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
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
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogTheme(
        backgroundColor: const ColorScheme.light().surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
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

  ThemeData _buildEnhancedDarkTheme() {
    final baseTheme = ThemeData.dark();

    return baseTheme.copyWith(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),

      textTheme: _buildEnhancedTextTheme(Brightness.dark),

      // Similar enhancements for dark theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const ColorScheme.dark().onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 4,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),

      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          animationDuration: const Duration(milliseconds: 200),
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const ColorScheme.dark().outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const ColorScheme.dark().primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Supabase Manager with enhanced organization
  try {
    await SupabaseManager().initialize();
    debugPrint('Supabase Manager initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Supabase Manager: $e');
    // Continue without Supabase for demo purposes
  }

  runApp(const ISuiteApp());
}
