import '../../domain/entities/ftp_connection.dart';
import '../../domain/entities/ftp_file.dart';
import '../../domain/repositories/ftp_repository.dart';
import '../datasources/ftp_datasource.dart';

/// FTP Repository Implementation - Data Layer
/// References: Repository pattern implementation
class FtpRepositoryImpl implements FtpRepository {
  final FtpDataSource dataSource;

  FtpRepositoryImpl(this.dataSource);

  // In-memory storage for locked files (client-side simulation)
  final Map<String, bool> _lockedFiles = {};

  @override
  Future<void> connect(FtpConnection connection) async {
    await dataSource.connect(connection);
  }

  @override
  Future<void> disconnect() async {
    await dataSource.disconnect();
  }

  @override
  Future<List<FtpFile>> listFiles(String path) async {
    return await dataSource.listFiles(path);
  }

  @override
  Future<void> downloadFile(String remotePath, String localPath) async {
    await dataSource.downloadFile(remotePath, localPath);
  }

  @override
  Future<void> uploadFile(String localPath, String remotePath) async {
    await dataSource.uploadFile(localPath, remotePath);
  }

  @override
  Future<void> createDirectory(String path) async {
    await dataSource.createDirectory(path);
  }

  @override
  Future<void> delete(String path) async {
    await dataSource.delete(path);
  }

  @override
  Future<void> lockFile(String path) async {
    _lockedFiles[path] = true;
  }

  @override
  Future<void> unlockFile(String path) async {
    _lockedFiles.remove(path);
  }

  @override
  Future<void> batchDownload(List<FtpFile> files, String localPath) async {
    for (final file in files) {
      if (!file.isDirectory) {
        await downloadFile(file.path, '$localPath/${file.name}');
      }
    }
  }

  @override
  Future<void> batchUpload(List<String> localPaths, String remotePath) async {
    for (final localPath in localPaths) {
      final fileName = localPath.split('/').last;
      await uploadFile(localPath, '$remotePath/$fileName');
    }
  }
}
