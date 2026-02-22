# Open-Source References for Network and File Sharing

## Primary Reference: Owlfile/OwnCloud
**Repository**: https://github.com/owncloud/core  
**Purpose**: Self-hosted file sharing and collaboration platform  
**Features Referenced**:
- File sharing with access control
- Cloud storage integration
- Multi-user collaboration
- Encryption and security
- Web-based file management

**Integration in iSuite**:
- iSuite is styled as "Owlfiles File Manager"
- Implements similar file sharing concepts
- References OwnCloud's sharing model for enterprise features

## Network Management References

### NetworkManager
**Repository**: https://github.com/NetworkManager/NetworkManager  
**Purpose**: Network configuration and management  
**Features Referenced**:
- WiFi network scanning and connection
- Network interface management
- Connection profiles
- VPN support

**Integration in iSuite**:
- WiFi scanner feature in `network_management.dart`
- Network connectivity monitoring
- References NetworkManager's scanning API concepts

### Additional Network Tools
- **wicd**: https://github.com/lizardsystem/wicd (WiFi connection manager)
- **ConnMan**: https://github.com/intel/connman (Connection manager)

## File Sharing Protocol References

### vsftpd (Very Secure FTP Daemon)
**Repository**: https://github.com/robbieh/vsftpd  
**Purpose**: Secure FTP server implementation  
**Features Referenced**:
- FTP protocol implementation
- Security features (SSL/TLS)
- User authentication
- File transfer operations

**Integration in iSuite**:
- FTP client in `ftp_client.dart`
- File upload/download functionality
- References vsftpd's secure FTP implementation

### Samba
**Repository**: https://github.com/samba-team/samba  
**Purpose**: SMB/CIFS file sharing  
**Features Referenced**:
- Network file sharing
- Windows compatibility
- Authentication and permissions
- Cross-platform file access

**Integration in iSuite**:
- Network file browsing concepts
- File sharing protocols support

## Flutter Plugin References

### WiFi Scanning
- **wifi_scan**: Flutter plugin for WiFi scanning
- References NetworkManager's WiFi scanning capabilities
- Used in `network_management.dart`

### FTP Client
- **ftpconnect**: Flutter FTP client plugin
- References vsftpd's FTP protocol implementation
- Used in `ftp_client.dart`

### Network Info
- **network_info_plus**: Network information retrieval
- **connectivity_plus**: Network connectivity monitoring

## Implementation Details

### New Features Added
1. **WiFi Network Scanner** (`network_management.dart`)
   - Scan available WiFi networks
   - Display signal strength and security
   - Show current connection info
   - References: NetworkManager WiFi scanning

2. **FTP File Client** (`ftp_client.dart`)
   - Connect to FTP servers
   - Browse remote files
   - Upload/download files
   - References: vsftpd secure FTP implementation

### Architecture References
- **OwnCloud**: File sharing architecture and user experience
- **NetworkManager**: Network management patterns
- **vsftpd**: Secure file transfer protocols

## Future Enhancements
Based on references:
- SMB file sharing (Samba)
- VPN support (NetworkManager)
- Advanced FTP features (vsftpd)
- Cloud storage sync (OwnCloud)
- Network diagnostics tools

---
*References taken from open-source GitHub repositories*
*Integration completed in iSuite network_management feature*
