import '../entities/ftp_connection.dart';
import '../repositories/ftp_repository.dart';

/// Connect FTP Use Case - Domain Layer
/// References: Owlfile connection management
class ConnectFtpUseCase {
  final FtpRepository repository;

  const ConnectFtpUseCase(this.repository);

  Future<void> execute(FtpConnection connection) async {
    await repository.connect(connection);
  }
}
