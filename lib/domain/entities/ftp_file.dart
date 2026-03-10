/// FTP File Entity - Domain Layer
/// References: FileGator file management, Sigma File Manager
class FtpFile {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modified;

  const FtpFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
