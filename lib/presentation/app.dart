import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/backend/pocketbase_service.dart';
import '../core/config/central_config.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/auth_screen.dart';
import '../presentation/screens/files_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/network_screen.dart';
import '../presentation/theme/app_theme.dart';

/// Main App Widget - Cross-Platform Free Solution
class ISuiteApp extends ConsumerStatefulWidget {
  const ISuiteApp({super.key});

  @override
  ConsumerState<ISuiteApp> createState() => _ISuiteAppState();
}

class _ISuiteAppState extends ConsumerState<ISuiteApp> {
  late final GoRouter _router;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize the app with all services
  Future<void> _initializeApp() async {
    try {
      // Initialize CentralConfig first
      await CentralConfig.instance.initialize();
      
      // Initialize PocketBase service
      await PocketBaseService.instance.initialize();
      
      // Setup UI configuration
      await CentralConfig.instance.setupUIConfig();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Failed to initialize app: $e');
      // Show error screen or retry
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading iSuite...'),
              ],
            ),
          ),
        ),
      );
    }

    // Watch authentication state
    final isAuthenticated = ref.watch(authProvider);

    return MaterialApp.router(
      title: 'iSuite - Free Cross-Platform Suite',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // Router configuration
      routerConfig: _router,
      
      // Builder for additional configuration
      builder: (context, child) {
        return MediaQuery(
          // Ensure font scale doesn't break layout
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

/// Authentication state provider
final authProvider = Provider<bool>((ref) {
  return PocketBaseService.instance.isAuthenticated;
});

/// Router configuration
GoRouter _createRouter() {
  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final isAuthenticated = PocketBaseService.instance.isAuthenticated;
      
      // Redirect to auth if not authenticated
      if (!isAuthenticated && !state.location.startsWith('/auth')) {
        return '/auth';
      }
      
      // Redirect to home if authenticated and on auth page
      if (isAuthenticated && state.location.startsWith('/auth')) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      // Authentication routes
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      
      // Main app routes
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/files',
            builder: (context, state) => const FilesScreen(),
          ),
          GoRoute(
            path: '/network',
            builder: (context, state) => const NetworkScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64),
            SizedBox(height: 16),
            Text('Page not found'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Main scaffold with navigation
class MainScaffold extends StatelessWidget {
  final Widget child;
  
  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final currentIndex = _getCurrentIndex(context);
        
        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onItemTapped(context, index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: 'Files',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.wifi),
              label: 'Network',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        );
      },
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).location;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/files')) return 1;
    if (location.startsWith('/network')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/files');
        break;
      case 2:
        context.go('/network');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}

/// App Theme Configuration
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
