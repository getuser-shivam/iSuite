import 'package:flutter/material.dart';
import '../../../core/central_config.dart';
import '../../../services/cloud/google_drive_service.dart';
import '../../../services/cloud/dropbox_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Cloud Storage Screen for Google Drive and Dropbox integration
class CloudStorageScreen extends StatefulWidget {
  const CloudStorageScreen({Key? key}) : super(key: key);

  @override
  State<CloudStorageScreen> createState() => _CloudStorageScreenState();
}

class _CloudStorageScreenState extends State<CloudStorageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GoogleDriveService _googleDrive = GoogleDriveService();
  final DropboxService _dropbox = DropboxService();

  List<drive.File> _googleFiles = [];
  List<dynamic> _dropboxFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _googleDrive.initialize();
    setState(() {});
  }

  Future<void> _signInGoogle() async {
    setState(() => _isLoading = true);
    final success = await _googleDrive.signIn();
    if (success) {
      await _loadGoogleFiles();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signOutGoogle() async {
    await _googleDrive.signOut();
    setState(() => _googleFiles = []);
  }

  Future<void> _loadGoogleFiles() async {
    final files = await _googleDrive.listFiles();
    if (files != null) {
      setState(() => _googleFiles = files);
    }
  }

  Future<void> _signInDropbox() async {
    // For demo, use a hardcoded token - in real app, use OAuth flow
    const token = 'your_dropbox_access_token_here';
    await _dropbox.initialize(token);
    await _loadDropboxFiles();
    setState(() {});
  }

  Future<void> _loadDropboxFiles() async {
    final files = await _dropbox.listFiles();
    if (files != null) {
      setState(() => _dropboxFiles = files);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = CentralConfig.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.getParameter('ui.app_titles.cloud_storage', defaultValue: 'Cloud Storage')!),
        backgroundColor: config.getParameter('ui.app_bar.background_color', defaultValue: Colors.white)!,
        foregroundColor: config.getParameter('ui.app_bar.foreground_color', defaultValue: Colors.black)!,
        elevation: config.getParameter('ui.app_bar.elevation', defaultValue: 1)!,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Google Drive'),
            Tab(text: 'Dropbox'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGoogleDriveTab(),
                _buildDropboxTab(),
              ],
            ),
    );
  }

  Widget _buildGoogleDriveTab() {
    final config = CentralConfig.instance;

    if (!_googleDrive.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud,
              size: 64,
              color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Connect to Google Drive',
              style: TextStyle(
                fontSize: 18,
                color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _signInGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Sign In with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '${_googleFiles.length} files',
                style: TextStyle(
                  color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadGoogleFiles,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: _signOutGoogle,
                icon: const Icon(Icons.logout),
                tooltip: 'Sign Out',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _googleFiles.length,
            itemBuilder: (context, index) {
              final file = _googleFiles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    _getFileIcon(file.name ?? ''),
                    color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                  ),
                  title: Text(file.name ?? 'Unnamed'),
                  subtitle: Text(
                    'Modified: ${_formatDate(file.modifiedTime)} • Size: ${_formatSize(file.size)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadGoogleFile(file),
                  ),
                  onTap: () => _openGoogleFile(file),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropboxTab() {
    final config = CentralConfig.instance;

    if (!_dropbox.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_queue,
              size: 64,
              color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Connect to Dropbox',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _signInDropbox,
              icon: const Icon(Icons.login),
              label: const Text('Connect Dropbox'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '${_dropboxFiles.length} files',
                style: TextStyle(
                  color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue)!.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadDropboxFiles,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _dropboxFiles.length,
            itemBuilder: (context, index) {
              final file = _dropboxFiles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    _getFileIcon(file.name ?? ''),
                    color: config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                  ),
                  title: Text(file.name ?? 'Unnamed'),
                  subtitle: const Text('Dropbox file'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadDropboxFile(file),
                  ),
                  onTap: () => _openDropboxFile(file),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _downloadGoogleFile(drive.File file) {
    // TODO: Implement download with file picker for destination
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${file.name}...')),
    );
  }

  void _openGoogleFile(drive.File file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${file.name}')),
    );
  }

  void _downloadDropboxFile(dynamic file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${file.name}...')),
    );
  }

  void _openDropboxFile(dynamic file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${file.name}')),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatSize(int? size) {
    if (size == null) return 'Unknown';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).round()} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).round()} MB';
    return '${(size / (1024 * 1024 * 1024)).round()} GB';
  }
}
