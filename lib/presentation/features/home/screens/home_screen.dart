import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: AppConfig.cardElevation,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: AppConfig.iconSize * 4,
              color: AppConfig.primaryColor,
            ),
            SizedBox(height: AppConfig.defaultPadding),
            Text(
              'Welcome to ${AppConfig.appName}',
              style: TextStyle(
                fontSize: AppConfig.titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConfig.defaultPadding / 2),
            Text(
              'Your comprehensive file manager',
              style: TextStyle(
                fontSize: AppConfig.bodyFontSize,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: AppConfig.defaultPadding),
            ElevatedButton(
              onPressed: () {
                // Navigate to file management
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                ),
              ),
              child: Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
