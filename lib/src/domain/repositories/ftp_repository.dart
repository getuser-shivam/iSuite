import '../entities/ftp_connection.dart';
import '../entities/ftp_file.dart';

/// FTP Repository Interface - Domain Layer
/// References: Clean Architecture repository pattern, FileGator repository
abstract class FtpRepository {
  Future<void> connect(FtpConnection connection);
  Future<void> disconnect();
  Future<List<FtpFile>> listFiles(String path);
  Future<void> downloadFile(String remotePath, String localPath);
  Future<void> uploadFile(String localPath, String remotePath);
  Future<void> createDirectory(String path);
  Future<void> delete(String path);
  Future<void> lockFile(String path);
  Future<void> unlockFile(String path);
  Future<void> batchDownload(List<FtpFile> files, String localPath);
  Future<void> batchUpload(List<String> localPaths, String remotePath);
}
