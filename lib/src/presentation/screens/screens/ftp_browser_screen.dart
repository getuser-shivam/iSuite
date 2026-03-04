import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../core/riverpod_state_management.dart';
import '../providers/ftp_provider.dart';
import '../../domain/entities/ftp_connection.dart';
import '../../domain/entities/ftp_file.dart';

/// FTP Browser Screen - Presentation Layer
/// References: Open-source file browser, FileGator UI, Sigma File Manager interface
class FtpBrowserScreen extends ConsumerStatefulWidget {
  const FtpBrowserScreen({super.key});

  @override
  ConsumerState<FtpBrowserScreen> createState() => _FtpBrowserScreenState();
}

class _FtpBrowserScreenState extends ConsumerState<FtpBrowserScreen> {
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController(text: '21');
  final _searchController = TextEditingController();

  String _searchText = '';
  String _sortBy = 'name';
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final connection = FtpConnection(
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text) ?? 21,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
    await ftpNotifier.connect(connection);
  }

  @override
  Widget build(BuildContext context) {
    final ftpState = ref.watch(ftpStateProvider);
    final ftpNotifier = ref.read(ftpStateProvider.notifier);
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    return Scaffold(
      appBar: AppBar(
        title: Text(ftpState.isConnected ? 'FTP Browser' : 'FTP Connection'),
        actions: [
          if (ftpState.isConnected)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ftpNotifier.disconnect(),
              tooltip: 'Disconnect',
            ),
          if (ftpState.isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ftpNotifier.listFiles(ftpState.currentPath),
              tooltip: 'Refresh (F5)',
            ),
          if (ftpState.isConnected)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'batch_download':
                    _batchDownloadAll();
                    break;
                  case 'batch_upload':
                    _batchUpload();
                    break;
                  case 'toggle_theme':
                    // Toggle theme
                    final uiNotifier = ref.read(uiProvider.notifier);
                    final currentMode = ref.read(uiProvider).themeMode;
                    final nextMode = currentMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                    uiNotifier.setThemeMode(nextMode);
                    // Update theme
                    final themeNotifier = ref.read(themeProvider.notifier);
                    themeNotifier.updateTheme(
                      brightness: nextMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
                      highContrast: ref.read(uiProvider).highContrastEnabled,
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'batch_download',
                  child: Text('Batch Download All'),
                ),
                const PopupMenuItem(
                  value: 'batch_upload',
                  child: Text('Batch Upload Files'),
                ),
                const PopupMenuItem(
                  value: 'toggle_theme',
                  child: ListTile(
                    leading: Icon(Icons.brightness_6),
                    title: Text('Toggle Theme'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          if (isDesktop) {
            const SingleActivator(LogicalKeyboardKey.f5): () => ftpNotifier.listFiles(ftpState.currentPath),
            const SingleActivator(LogicalKeyboardKey.f5, control: true): () => ftpNotifier.disconnect(),
          }
        },
        child: Focus(
          autofocus: true,
          child: ftpState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ftpState.isConnected
                  ? _buildFileBrowser(ftpState, ftpNotifier, isDesktop)
                  : _buildConnectionForm(ftpState, ftpNotifier, isDesktop),
        ),
      ),
      floatingActionButton: ftpState.isConnected
          ? FloatingActionButton.extended(
              onPressed: () => _showUploadDialog(context, ftpNotifier),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
    );
  }

  Widget _buildConnectionForm(FtpState ftpState, FtpStateNotifier ftpNotifier, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ftpState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Text(
                ftpState.error!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          const SizedBox(height: 16),
          if (ftpState.error != null)
            ElevatedButton(
              onPressed: _connect,
              child: const Text('Retry Connection'),
            ),
          if (ftpState.error != null) const SizedBox(height: 16),
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(
              labelText: 'FTP Host',
              hintText: 'ftp.example.com',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '21',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _connect,
            child: const Text('Connect to FTP'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileBrowser(FtpState ftpState, FtpStateNotifier ftpNotifier) {
    final filteredFiles = ftpState.files.where((file) => 
      file.name.toLowerCase().contains(_searchText.toLowerCase())).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Text('Current Path: ${ftpState.currentPath}'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ftpNotifier.listFiles(ftpState.currentPath),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search files',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        if (ftpState.error != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade100,
            child: Text(
              ftpState.error!,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ftpNotifier.listFiles(ftpState.currentPath),
            child: ListView.builder(
              itemCount: filteredFiles.length,
              itemBuilder: (context, index) {
                final file = filteredFiles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      file.isDirectory ? Icons.folder : _getFileIcon(file),
                      color: file.isDirectory
                          ? Colors.blue
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    title: Text(file.name),
                    subtitle: file.isDirectory
                        ? const Text('Directory')
                        : Text(file.sizeFormatted),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'download':
                            // Implement download with file picker
                            break;
                          case 'delete':
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete File'),
                                content: Text('Delete ${file.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ftpNotifier.delete(file);
                            }
                            break;
                          case 'lock':
                            await ftpNotifier.lockFile(file);
                            break;
                          case 'unlock':
                            await ftpNotifier.unlockFile(file);
                            break;
                          case 'preview':
                            await _showPreviewDialog(context, file, ftpNotifier);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (!file.isDirectory)
                          const PopupMenuItem(
                            value: 'download',
                            child: Text('Download'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                        const PopupMenuItem(
                          value: 'lock',
                          child: Text('Lock File'),
                        ),
                        const PopupMenuItem(
                          value: 'unlock',
                          child: Text('Unlock File'),
                        ),
                        if (_isPreviewable(file))
                          const PopupMenuItem(
                            value: 'preview',
                            child: Text('Preview'),
                          ),
                      ],
                    ),
                    onTap: () {
                      if (file.isDirectory) {
                        ftpNotifier.listFiles(file.path);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showUploadDialog(BuildContext context, FtpStateNotifier ftpNotifier) {
    // Implement file picker for upload
    // For now, show placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload File'),
        content: const Text('File upload functionality to be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _isPreviewable(FtpFile file) {
    final ext = file.name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'txt', 'md', 'json'].contains(ext);
  }

  IconData _getFileIcon(FtpFile file) {
    final ext = file.name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return Icons.image;
    if (['mp3', 'wav', 'flac'].contains(ext)) return Icons.music_note;
    if (['mp4', 'avi', 'mkv'].contains(ext)) return Icons.video_file;
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf;
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) return Icons.archive;
    if (['json'].contains(ext)) return Icons.data_object;
    if (['txt'].contains(ext)) return Icons.text_snippet;
    if (['md'].contains(ext)) return Icons.article;
    if (['html', 'htm'].contains(ext)) return Icons.web;
    if (['css'].contains(ext)) return Icons.palette;
    if (['js'].contains(ext)) return Icons.javascript;
    if (['py'].contains(ext)) return Icons.code;
    if (['xml'].contains(ext)) return Icons.data_object;
    return Icons.file_present;
  }

  Future<void> _showPreviewDialog(BuildContext context, FtpFile file, FtpStateNotifier ftpNotifier) async {
    final ext = file.name.split('.').last.toLowerCase();
    Widget content;

    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      // For images, download to temp and show
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file.name}');
      await ftpNotifier.downloadFile(file, tempFile.path);
      content = Image.file(tempFile);
    } else if (['txt', 'md', 'json'].contains(ext)) {
      // For text, download and show
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file.name}');
      await ftpNotifier.downloadFile(file, tempFile.path);
      final text = await tempFile.readAsString();
      content = SingleChildScrollView(
        child: Text(text),
      );
    } else {
      content = const Text('Preview not supported for this file type.');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: SizedBox(
          width: 300,
          height: 400,
          child: content,
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

  Future<void> _batchDownloadAll() async {
    final localPath = (await getDownloadsDirectory())?.path ?? (await getTemporaryDirectory()).path;
    await ftpNotifier.batchDownloadCurrentDirectory(localPath);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch download completed')),
      );
    }
  }

  Future<void> _batchUpload() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      final paths = result.files.map((f) => f.path!).where((p) => p.isNotEmpty).toList();
      await ftpNotifier.batchUploadFiles(paths);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch upload completed')),
        );
      }
    }
  }

}
