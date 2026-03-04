/// FTP Connection Entity - Domain Layer
/// References: Owlfile FTP support, OpenFTP client/server
class FtpConnection {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool secure;

  const FtpConnection({
    required this.host,
    this.port = 21,
    required this.username,
    required this.password,
    this.secure = false,
  });

  FtpConnection copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    bool? secure,
  }) {
    return FtpConnection(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      secure: secure ?? this.secure,
    );
  }
}
