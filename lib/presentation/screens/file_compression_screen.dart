import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/file_compression_service.dart';

class FileCompressionScreen extends ConsumerStatefulWidget {
  const FileCompressionScreen({super.key});

  @override
  State<FileCompressionScreen> createState() => _FileCompressionScreenState();
}

class _FileCompressionScreenState extends ConsumerState<FileCompressionScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Compression'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Compress'),
            Tab(text: 'Decompress'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CompressTab(),
          _DecompressTab(),
        ],
      ),
    );
  }
}

class _CompressTab extends ConsumerStatefulWidget {
  @override
  State<_CompressTab> createState() => _CompressTabState();
}

class _CompressTabState extends ConsumerState<_CompressTab> {
  final List<String> _selectedFiles = [];
  final TextEditingController _archiveNameController = TextEditingController(text: 'archive');
  bool _isCompressing = false;
  String? _resultMessage;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files.map((file) => file.path!).where((path) => path.isNotEmpty));
      });
    }
  }

  Future<void> _compressFiles() async {
    if (_selectedFiles.isEmpty || _archiveNameController.text.isEmpty) {
      setState(() {
        _resultMessage = ref.read(fileCompressionServiceProvider).config?.getParameter('ui.select_files_and_name', defaultValue: 'Please select files and enter archive name');
      });
      return;
    }

    setState(() {
      _isCompressing = true;
      _resultMessage = null;
    });

    final service = ref.read(fileCompressionServiceProvider);
    final result = await service.compressFiles(_selectedFiles, _archiveNameController.text);

    setState(() {
      _isCompressing = false;
      final successPrefix = ref.read(fileCompressionServiceProvider).config?.getParameter('ui.compression_success', defaultValue: 'Compression successful');
      _resultMessage = result != null ? '$successPrefix: $result' : 'Compression failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(fileCompressionServiceProvider).config;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.add),
            label: Text(config?.getParameter('ui.add_files_button', defaultValue: 'Add Files') ?? 'Add Files'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedFiles.isEmpty
                ? const Center(child: Text('No files selected'))
                : ListView.builder(
                    itemCount: _selectedFiles.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.file_present),
                        title: Text(_selectedFiles[index].split('/').last),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              _selectedFiles.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
          TextField(
            controller: _archiveNameController,
            decoration: InputDecoration(labelText: config?.getParameter('ui.archive_name_label', defaultValue: 'Archive Name')),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isCompressing ? null : _compressFiles,
            child: _isCompressing
                ? const CircularProgressIndicator()
                : Text(config?.getParameter('ui.compress_files_button', defaultValue: 'Compress Files') ?? 'Compress Files'),
          ),
          if (_resultMessage != null) ...[
            const SizedBox(height: 16),
            Text(_resultMessage!, style: TextStyle(color: _resultMessage!.startsWith('Compression successful') ? Colors.green : Colors.red)),
          ],
        ],
      ),
    );
  }
}

class _DecompressTab extends ConsumerStatefulWidget {
  @override
  State<_DecompressTab> createState() => _DecompressTabState();
}

class _DecompressTabState extends ConsumerState<_DecompressTab> {
  String? _selectedZipPath;
  String? _selectedOutputDir;
  List<String> _availableDirs = [];
  bool _isDecompressing = false;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableDirs();
  }

  Future<void> _loadAvailableDirs() async {
    final service = ref.read(fileCompressionServiceProvider);
    final dirs = await service.getAvailableDirectories();
    setState(() {
      _availableDirs = dirs;
      _selectedOutputDir = dirs.isNotEmpty ? dirs.first : null;
    });
  }

  Future<void> _pickZipFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedZipPath = result.files.first.path;
      });
    }
  }

  Future<void> _decompressFile() async {
    if (_selectedZipPath == null || _selectedOutputDir == null) {
      setState(() {
        _resultMessage = ref.read(fileCompressionServiceProvider).config?.getParameter('ui.select_zip_and_directory', defaultValue: 'Please select ZIP file and output directory');
      });
      return;
    }

    setState(() {
      _isDecompressing = true;
      _resultMessage = null;
    });

    final service = ref.read(fileCompressionServiceProvider);
    final result = await service.decompressFile(_selectedZipPath!, _selectedOutputDir!);

    setState(() {
      _isDecompressing = false;
      final successPrefix = ref.read(fileCompressionServiceProvider).config?.getParameter('ui.decompression_success', defaultValue: 'Decompression successful');
      _resultMessage = result != null ? '$successPrefix: $result' : 'Decompression failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(fileCompressionServiceProvider).config;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _pickZipFile,
            icon: const Icon(Icons.file_open),
            label: Text(config?.getParameter('ui.select_zip_file', defaultValue: 'Select ZIP File') ?? 'Select ZIP File'),
          ),
          const SizedBox(height: 16),
          Text(_selectedZipPath ?? 'No file selected'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedOutputDir,
            items: _availableDirs.map((dir) {
              return DropdownMenuItem(value: dir, child: Text(dir));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedOutputDir = value;
              });
            },
            decoration: InputDecoration(labelText: config?.getParameter('ui.output_directory_label', defaultValue: 'Output Directory')),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isDecompressing ? null : _decompressFile,
            child: _isDecompressing
                ? const CircularProgressIndicator()
                : Text(config?.getParameter('ui.decompress_file_button', defaultValue: 'Decompress File') ?? 'Decompress File'),
          ),
          if (_resultMessage != null) ...[
            const SizedBox(height: 16),
            Text(_resultMessage!, style: TextStyle(color: _resultMessage!.startsWith('Decompression successful') ? Colors.green : Colors.red)),
          ],
        ],
      ),
    );
  }
}
