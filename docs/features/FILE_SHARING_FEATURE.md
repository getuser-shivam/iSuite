# File Sharing Feature

## Overview

The File Sharing feature provides comprehensive multi-protocol file transfer capabilities for iSuite. This feature enables users to connect to various file servers, transfer files securely, and manage file sharing connections across all supported platforms (Android, iOS, Windows).

## Key Features

### 🔗 Multi-Protocol Support
- **FTP (File Transfer Protocol)**: Standard file transfer with optional SSL/TLS encryption
- **SFTP (SSH File Transfer Protocol)**: Secure file transfer over SSH
- **HTTP/HTTPS**: Web-based file transfer with authentication
- **SMB (Server Message Block)**: Windows file sharing protocol
- **WebDAV**: Web-based distributed authoring and versioning
- **Bluetooth**: Direct device-to-device file transfer
- **WiFi Direct**: Peer-to-peer file sharing

### 📁 Connection Management
- **Connection Profiles**: Save and manage multiple server connections
- **Authentication**: Support for username/password and key-based authentication
- **Secure Connections**: SSL/TLS encryption for supported protocols
- **Connection Monitoring**: Real-time connection status and health

### 📤 File Transfer Operations
- **Upload Files**: Transfer files from device to remote server
- **Download Files**: Retrieve files from remote server to device
- **Batch Transfers**: Multiple file operations in a single session
- **Transfer Queue**: Manage multiple concurrent transfers
- **Progress Tracking**: Real-time transfer progress and speed monitoring
- **Resume/Pause**: Control transfer operations with resume capability

### 📊 Transfer Monitoring
- **Real-time Progress**: Live progress bars and transfer statistics
- **Speed Monitoring**: Current and average transfer speeds
- **Transfer History**: Log of completed and failed transfers
- **Error Handling**: Comprehensive error reporting and recovery

### 🎛️ Advanced Features
- **Directory Browsing**: Navigate remote file systems
- **File Management**: Create, delete, and rename remote files/directories
- **Search & Filter**: Find files on remote servers
- **Compression**: Automatic compression for large transfers
- **Synchronization**: Sync local and remote directories

## User Interface

### File Sharing Screen
The main File Sharing screen provides access to all file transfer features:

- **Connections List**: Manage saved server connections
- **Active Transfers**: Monitor ongoing file transfers
- **Add Connection**: Create new server connection profiles
- **Transfer History**: View completed transfer logs

### Connection Details
Each connection provides:
- **Connection Status**: Active/inactive status indicator
- **Transfer Statistics**: Upload/download counts and speeds
- **Server Information**: Host, port, protocol, and authentication details
- **Quick Actions**: Connect, disconnect, upload, download buttons

### Transfer Management
Transfer operations include:
- **File Picker**: Native file selection for uploads
- **Progress Dialogs**: Detailed transfer progress with speed graphs
- **Error Notifications**: Clear error messages with retry options
- **Transfer Controls**: Pause, resume, and cancel operations

## Technical Implementation

### Core Components

#### FileSharingModel
```dart
class FileSharingModel {
  final String id;                    // Unique connection identifier
  final String name;                  // Connection display name
  final FileSharingProtocol protocol; // Transfer protocol
  final String host;                  // Server hostname/IP
  final int port;                     // Server port
  final String username;              // Authentication username
  final String? password;             // Authentication password
  final String? remotePath;           // Default remote directory
  final String? localPath;            // Default local directory
  final bool isSecure;                // SSL/TLS encryption
  final bool isActive;                // Connection status
  final DateTime createdAt;           // Creation timestamp
  final DateTime updatedAt;           // Last update timestamp
  final DateTime? lastConnected;      // Last connection time
}
```

#### FileTransferModel
```dart
class FileTransferModel {
  final String id;              // Unique transfer identifier
  final String fileName;        // File name
  final String filePath;        // Local file path
  final TransferType type;      // Upload/Download/Sync
  final TransferStatus status;  // Transfer status
  final int totalBytes;         // Total file size
  final int transferredBytes;   // Bytes transferred
  final double speed;           // Transfer speed (bytes/second)
  final DateTime startTime;     // Transfer start time
  final DateTime? endTime;      // Transfer end time
  final String? errorMessage;   // Error description
}
```

#### FileSharingProvider
The FileSharingProvider manages file transfer state and operations:

- **addConnection()**: Create new server connection profile
- **removeConnection()**: Delete server connection profile
- **uploadFile()**: Upload file to remote server
- **downloadFile()**: Download file from remote server
- **cancelTransfer()**: Cancel ongoing transfer
- **listRemoteFiles()**: Browse remote directory contents

### Protocol Implementations

#### FTP/SFTP
- Uses `ftpconnect` package for FTP operations
- Supports both plain FTP and secure FTPS
- SFTP implementation with SSH key support

#### HTTP/HTTPS
- Uses `dio` package for HTTP transfers
- Supports basic authentication and custom headers
- SSL certificate validation and pinning

#### SMB/WebDAV
- Platform-specific implementations
- Windows: Native SMB support
- Cross-platform: WebDAV fallback

### Storage Integration

#### Local Storage
- SQLite database for connection profiles and transfer history
- Local file system for temporary transfer storage
- Transfer resume capability with checkpoint saving

#### Cloud Storage
- Supabase Storage integration for cloud file backup
- Automatic cloud synchronization of transfer metadata
- Cross-device transfer history sharing

## Usage Guide

### Setting Up Connections
1. Open File Sharing from Settings > File Sharing
2. Tap the "+" button to add a new connection
3. Select the protocol (FTP, SFTP, HTTP, etc.)
4. Enter connection details:
   - Connection name
   - Server host/IP
   - Port number
   - Username and password
   - Remote/local paths
5. Test the connection
6. Save the connection profile

### File Upload
1. Select a saved connection
2. Tap the "Upload" action
3. Choose files using the file picker
4. Select remote destination directory
5. Monitor transfer progress
6. View transfer completion status

### File Download
1. Select a saved connection
2. Tap the "Download" action
3. Browse remote directories
4. Select files to download
5. Choose local destination
6. Monitor download progress

### Managing Transfers
- **Active Transfers**: View all ongoing transfers
- **Transfer Controls**: Pause, resume, or cancel transfers
- **Transfer History**: Review completed transfers
- **Error Recovery**: Retry failed transfers with error details

## Supported Protocols

| Protocol | Ports | Security | Platforms | Features |
|----------|-------|----------|-----------|----------|
| FTP | 21 | Optional SSL | All | Basic file transfer |
| FTPS | 990 | SSL/TLS | All | Secure FTP |
| SFTP | 22 | SSH | All | Secure file transfer |
| HTTP | 80 | None | All | Web transfer |
| HTTPS | 443 | SSL/TLS | All | Secure web transfer |
| SMB | 445 | NTLM/Kerberos | Windows | Windows sharing |
| WebDAV | 80/443 | SSL optional | All | WebDAV protocol |
| Bluetooth | N/A | Pairing | Mobile | Direct transfer |
| WiFi Direct | N/A | WPA2 | Mobile | P2P transfer |

## Performance Optimization

### Transfer Optimization
- **Chunked Transfer**: Large files transferred in optimized chunks
- **Compression**: Automatic compression for supported protocols
- **Parallel Transfers**: Multiple concurrent file operations
- **Bandwidth Management**: Adaptive transfer speeds

### Connection Management
- **Connection Pooling**: Reuse connections for multiple transfers
- **Keep-Alive**: Maintain persistent connections
- **Auto-Reconnection**: Automatic reconnection on network issues
- **Load Balancing**: Distribute transfers across multiple connections

### Storage Optimization
- **Local Caching**: Cache frequently accessed files
- **Incremental Sync**: Only transfer changed files
- **Deduplication**: Avoid duplicate file transfers
- **Cleanup**: Automatic cleanup of temporary files

## Security Features

### Authentication
- **Username/Password**: Standard authentication methods
- **SSH Keys**: Key-based authentication for SFTP
- **Token Authentication**: API tokens for cloud services
- **Certificate Authentication**: Client certificates for secure connections

### Encryption
- **SSL/TLS**: End-to-end encryption for supported protocols
- **SSH Encryption**: Secure shell encryption for SFTP
- **Data Encryption**: Optional local file encryption
- **Secure Storage**: Encrypted storage of credentials

### Access Control
- **Permission Management**: File permission handling
- **Access Logging**: Transfer activity logging
- **Connection Limits**: Configurable connection limits
- **IP Whitelisting**: Restrict connections by IP address

## Troubleshooting

### Connection Issues

#### "Connection failed"
- Verify server host and port are correct
- Check network connectivity and firewall settings
- Ensure server is running and accessible

#### "Authentication failed"
- Confirm username and password are correct
- Check if account is locked or expired
- Verify authentication method is supported

#### "Permission denied"
- Check file permissions on remote server
- Ensure user has read/write access
- Verify directory permissions

### Transfer Issues

#### "Transfer stalled"
- Check network stability and speed
- Verify sufficient disk space
- Restart transfer or try different protocol

#### "File corrupted"
- Check file integrity with checksums
- Retry transfer with different settings
- Verify local storage is not corrupted

#### "Out of memory"
- Reduce concurrent transfer count
- Increase device memory if possible
- Use chunked transfer for large files

### Platform-Specific Issues

#### Android
- Grant storage permissions for file access
- Enable background transfer permissions
- Check Android version compatibility

#### iOS
- Enable background app refresh
- Grant network permissions
- Check iOS file system restrictions

#### Windows
- Run as administrator for system directories
- Check Windows firewall settings
- Verify SMB service is running

## API Reference

### FileSharingProvider Methods

```dart
Future<void> addConnection(FileSharingModel connection)
Future<void> removeConnection(String connectionId)
Future<String> uploadFile(FileSharingModel connection, String filePath, {String? remotePath})
Future<String> downloadFile(FileSharingModel connection, String remoteFilePath, String localPath)
Future<void> cancelTransfer(String transferId)
Future<List<String>> listRemoteFiles(FileSharingModel connection, {String? remotePath})
Future<bool> createRemoteDirectory(FileSharingModel connection, String directoryPath)
```

### FileTransferModel Properties

```dart
String id                    // Unique transfer ID
String fileName              // File name
String filePath              // Local file path
TransferType type            // Upload/Download/Sync
TransferStatus status        // Current status
int totalBytes               // Total file size
int transferredBytes         // Bytes transferred
double speed                 // Transfer speed
DateTime startTime           // Start timestamp
DateTime? endTime            // Completion timestamp
String? errorMessage         // Error description
```

## Future Enhancements

- **Cloud Integration**: Direct integration with cloud storage providers
- **Advanced Sync**: Bidirectional synchronization with conflict resolution
- **Peer-to-Peer**: Direct device-to-device file sharing
- **Compression**: Advanced compression algorithms and formats
- **Encryption**: End-to-end encryption for all transfers
- **Backup Integration**: Automated backup file transfers
- **Media Streaming**: Stream media files during transfer
- **Collaboration**: Real-time collaborative file editing

## Support

For issues related to file sharing:
- Verify connection settings and server compatibility
- Check network connectivity and transfer speeds
- Ensure proper permissions and authentication
- Review transfer logs for detailed error information

---

**Note**: File sharing features may require appropriate server permissions and network access. Always ensure compliance with local data transfer regulations and organizational policies.

## Open-Source References

The iSuite file sharing implementation takes inspiration from several excellent open-source projects in the Flutter ecosystem:

### AirDash (simonbengtsson/airdash)
- **WebRTC-based P2P**: Inspired the potential for cross-network file sharing using WebRTC technology
- **Cross-platform support**: Multi-platform approach for Android, iOS, Linux, macOS, Windows
- **Native integration**: Mobile share sheet and desktop drag-and-drop functionality

### Photon (abhi16180/photon)
- **HTTP-based transfers**: Simple HTTP server approach for device-to-device transfers
- **Cross-platform compatibility**: Transfer between any devices running the application
- **Clean UI design**: Minimalist interface for file selection and transfer

### Flutter Sharez (Shreemanarjun/flutter_sharez)
- **Hotspot sharing**: WiFi hotspot creation for local network file sharing
- **Multi-format support**: Support for images, documents, videos, and other file types
- **Progress tracking**: Real-time transfer progress with speed indicators

### Bytes (alanrs2020/flutter-filesharing-app)
- **Offline sharing**: WiFi-based file transfer without internet dependency
- **PDF scanning**: Document digitization and sharing capabilities
- **Multi-file types**: Support for applications, music, PDFs, documents, archives

### Flutter Share Plugin (lubritto/flutter_share)
- **Platform sharing**: Native platform sharing APIs integration
- **File provider configuration**: Proper Android file sharing setup
- **Cross-platform compatibility**: Consistent sharing experience across iOS and Android

### Key Inspirations Applied

1. **P2P Capabilities**: WebRTC and local network discovery for direct device-to-device sharing
2. **HTTP Server Mode**: Built-in HTTP server for receiving files from other devices
3. **WiFi Direct/Bluetooth**: Platform-specific P2P protocols for nearby device sharing
4. **Hotspot Creation**: Automatic hotspot setup for local network file sharing
5. **QR Code Sharing**: Quick connection setup using QR codes
6. **Progress Visualization**: Real-time transfer progress with speed and ETA
7. **Batch Operations**: Multiple file selection and simultaneous transfers
8. **Security Features**: Encryption options and secure connection validation

These open-source projects provided valuable insights into user experience patterns, technical implementations, and cross-platform compatibility strategies that shaped the iSuite file sharing feature architecture.
