import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

import 'services/cloud_service.dart';
import 'services/file_operations_service.dart';
import 'widgets/file_preview.dart';
import 'widgets/enhanced_file_manager_with_qr.dart';

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({super.key});

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
    const BrowserScreen(),
    const CloudScreen(),
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
            label: 'Browser',
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owlfiles'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _ActionCard(
                  icon: Icons.folder_open,
                  title: 'Local Files',
                  subtitle: 'Browse device storage',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BrowserScreen()),
                  ),
                ),
                _ActionCard(
                  icon: Icons.cloud_upload,
                  title: 'Upload Files',
                  subtitle: 'Upload to cloud',
                  onTap: () => _uploadFile(context),
                ),
                _ActionCard(
                  icon: Icons.search,
                  title: 'Search Files',
                  subtitle: 'Find your files',
                  onTap: () => _searchFiles(context),
                ),
                _ActionCard(
                  icon: Icons.storage,
                  title: 'Storage Info',
                  subtitle: 'View storage usage',
                  onTap: () => _showStorageInfo(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Files',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _getRecentFiles(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No recent files'));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final file = snapshot.data![index];
                      return ListTile(
                        leading: _getFileIcon(file),
                        title: Text(file.split('/').last),
                        subtitle: Text(file),
                        onTap: () => _openFile(context, file),
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

  Widget _getFileIcon(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.blue);
      case 'jpg':
      case 'png':
      case 'gif':
        return const Icon(Icons.image, color: Colors.green);
      case 'mp4':
      case 'avi':
        return const Icon(Icons.video_file, color: Colors.purple);
      case 'mp3':
      case 'wav':
        return const Icon(Icons.audio_file, color: Colors.orange);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  Future<List<String>> _getRecentFiles() async {
    // Simulate recent files - in real app, would track actual recent files
    return [
      '/storage/emulated/0/Download/document.pdf',
      '/storage/emulated/0/Pictures/image.jpg',
      '/storage/emulated/0/Documents/notes.txt',
    ];
  }

  void _uploadFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: ${result.files.single.name}')),
      );
    }
  }

  void _searchFiles(BuildContext context) {
    showSearch(
      context: context,
      delegate: FileSearchDelegate(),
    );
  }

  void _showStorageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StorageItem('Internal Storage', '32 GB', '15 GB used'),
            _StorageItem('SD Card', '64 GB', '40 GB used'),
            _StorageItem('Cloud Storage', '100 GB', '25 GB used'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openFile(BuildContext context, String filePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $filePath')),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageItem extends StatelessWidget {
  final String name;
  final String total;
  final String used;

  const _StorageItem(this.name, this.total, this.used);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('$used of $total', style: TextStyle(color: Colors.grey[600])),
          LinearProgressIndicator(
            value: 0.6, // Simulated usage
            backgroundColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnhancedFileManagerFixed();
  }
}

class CloudScreen extends StatelessWidget {
  const CloudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Storage'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const Center(
        child: Text('Cloud storage functionality coming soon'),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Storage Management'),
            subtitle: const Text('Manage device and cloud storage'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            subtitle: const Text('App lock and permissions'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Configure app notifications'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('App version and information'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class FileSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Simulate search results
    return FutureBuilder<List<String>>(
      future: _performSearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No files found'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final file = snapshot.data![index];
            return ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(file.split('/').last),
              subtitle: Text(file),
              onTap: () => close(context, file),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  Future<List<String>> _performSearch(String query) async {
    // Simulate search - in real app, would search actual files
    await Future.delayed(const Duration(milliseconds: 500));
    if (query.isEmpty) return [];
    return [
      '/storage/emulated/0/Download/$query.pdf',
      '/storage/emulated/0/Documents/$query.docx',
      '/storage/emulated/0/Pictures/$query.jpg',
    ];
  }
}

class NewConnectionScreen extends StatelessWidget {
  const NewConnectionScreen({super.key});

  static const List<ConnectionItem> connections = [
    ConnectionItem('Local Storage', 'assets/icons/local.png', 'local'),
    ConnectionItem('Google Drive', 'assets/icons/googledrive.png', 'cloud'),
    ConnectionItem('Dropbox', 'assets/icons/dropbox.png', 'cloud'),
    ConnectionItem('OneDrive', 'assets/icons/onedrive.png', 'cloud'),
    ConnectionItem('FTP', 'assets/icons/ftp.png', 'network'),
    ConnectionItem('SFTP', 'assets/icons/sftp.png', 'network'),
    ConnectionItem('WebDAV', 'assets/icons/webdav.png', 'network'),
    ConnectionItem('NAS', 'assets/icons/nas.png', 'network'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Connection'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final connection = connections[index];
            return ConnectionCard(
              title: connection.title,
              iconPath: connection.iconPath,
              onTap: () => _handleConnectionTap(context, connection),
            );
          },
        ),
      ),
    );
  }

  void _handleConnectionTap(BuildContext context, ConnectionItem connection) {
    switch (connection.category) {
      case 'local':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BrowserScreen()),
        );
        break;
      case 'cloud':
        _showCloudAuthDialog(context, connection.title);
        break;
      case 'network':
        _showNetworkConfigDialog(context, connection.title);
        break;
    }
  }

  void _showCloudAuthDialog(BuildContext context, String service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect to $service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email/Username',
                hintText: 'Enter your email or username',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connected to $service')),
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showNetworkConfigDialog(BuildContext context, String service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect to $service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Server Address',
                hintText: 'e.g., 192.168.1.100',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: 'e.g., 21, 22, 8080',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter username',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connected to $service')),
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class ConnectionCard extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback onTap;

  const ConnectionCard({
    super.key,
    required this.title,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getIconColor(title).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(title),
                size: 28,
                color: _getIconColor(title),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String title) {
    switch (title.toLowerCase()) {
      case 'local storage':
        return Icons.storage;
      case 'google drive':
        return Icons.cloud_queue;
      case 'dropbox':
        return Icons.cloud_upload;
      case 'onedrive':
        return Icons.cloud_download;
      case 'ftp':
      case 'sftp':
        return Icons.folder_shared;
      case 'webdav':
        return Icons.language;
      case 'nas':
        return Icons.dns;
      default:
        return Icons.folder;
    }
  }

  Color _getIconColor(String title) {
    switch (title.toLowerCase()) {
      case 'local storage':
        return Colors.blue;
      case 'google drive':
        return Colors.red[600]!;
      case 'dropbox':
        return Colors.blue[600]!;
      case 'onedrive':
        return Colors.blue[700]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

class ConnectionItem {
  final String title;
  final String iconPath;
  final String category;

  const ConnectionItem(this.title, this.iconPath, this.category);
}
