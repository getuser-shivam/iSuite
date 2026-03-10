import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_provider.dart';
import '../../core/config/central_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _navigateToHome();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;

    final primaryColor = Color(config.getParameter('ui.primary_color', defaultValue: 0xFF1976D2) as int);
    final backgroundColor = Color(config.getParameter('ui.background_color', defaultValue: 0xFFFFFFFF) as int);
    final iconColor = Color(config.getParameter('ui.icon_color', defaultValue: 0xFF2196F3) as int);
    final textColor = Color(config.getParameter('ui.text_color', defaultValue: 0xFFFFFFFF) as int);
    final subtitleColor = Color(config.getParameter('ui.subtitle_color', defaultValue: 0xCCFFFFFF) as int);

    return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(config.getParameter('ui.border_radius', defaultValue: 20.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.apps,
                    size: 60,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  config.getParameter('app.name', defaultValue: 'iSuite'),
                  style: TextStyle(
                    fontSize: config.getParameter('ui.font_size_title', defaultValue: 32.0),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  config.getParameter('app.tagline', defaultValue: 'Your Productivity Suite'),
                  style: TextStyle(
                    fontSize: config.getParameter('ui.font_size_body', defaultValue: 16.0),
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
