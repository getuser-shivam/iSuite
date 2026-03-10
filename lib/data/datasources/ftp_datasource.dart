import 'dart:io';
import 'package:ftpconnect/ftpconnect.dart';
import '../../domain/entities/ftp_connection.dart';
import '../../domain/entities/ftp_file.dart';

/// FTP Data Source - Data Layer
/// References: OpenFTP client implementation, ftpconnect package
class FtpDataSource {
  FTPConnect? _ftpConnect;

  Future<void> connect(FtpConnection connection) async {
    _ftpConnect = FTPConnect(
      connection.host,
      port: connection.port,
      user: connection.username,
      pass: connection.password,
      securityType: connection.secure ? SecurityType.FTPS : SecurityType.FTP,
    );
    await _ftpConnect!.connect();
  }

  Future<void> disconnect() async {
    await _ftpConnect?.disconnect();
    _ftpConnect = null;
  }

  Future<List<FtpFile>> listFiles(String path) async {
    if (_ftpConnect == null) throw Exception('Not connected to FTP server');

    final list = await _ftpConnect!.listDirectoryContent();
    return list.map((ftpEntry) => FtpFile(
      name: ftpEntry.name,
      path: path + '/' + ftpEntry.name,
      isDirectory: ftpEntry.type == FTPEntryType.DIR,
      size: ftpEntry.size ?? 0,
      modified: ftpEntry.modifyTime ?? DateTime.now(),
    )).toList();
  }

  Future<void> downloadFile(String remotePath, String localPath) async {
    if (_ftpConnect == null) throw Exception('Not connected to FTP server');
    await _ftpConnect!.downloadFile(remotePath, File(localPath));
  }

  Future<void> uploadFile(String localPath, String remotePath) async {
    if (_ftpConnect == null) throw Exception('Not connected to FTP server');
    await _ftpConnect!.uploadFile(File(localPath));
  }

  Future<void> createDirectory(String path) async {
    if (_ftpConnect == null) throw Exception('Not connected to FTP server');
    await _ftpConnect!.makeDirectory(path);
  }

  Future<void> delete(String path) async {
    if (_ftpConnect == null) throw Exception('Not connected to FTP server');
    await _ftpConnect!.deleteFile(path);
  }
}
