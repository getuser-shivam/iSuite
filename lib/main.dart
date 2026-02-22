import 'package:flutter/material.dart';
import 'features/file_management/screens/file_management_screen.dart';
import 'features/cloud_management/screens/cloud_management_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  runApp(const OwlfilesApp());
}

class OwlfilesApp extends StatelessWidget {
  const OwlfilesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Owlfiles',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const FileManagementScreen(),
    const CloudManagementScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
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
            icon: Icon(Icons.cloud),
            label: 'Cloud',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
