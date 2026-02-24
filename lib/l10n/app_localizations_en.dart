// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'iSuite - Owlfiles File Manager';

  @override
  String get wifiScreenTitle => 'Network Management';

  @override
  String get ftpScreenTitle => 'FTP Client';

  @override
  String get filesTabTitle => 'Files';

  @override
  String get networkTabTitle => 'Network';

  @override
  String get ftpTabTitle => 'FTP';

  @override
  String get aiTabTitle => 'AI';

  @override
  String get settingsTabTitle => 'Settings';

  @override
  String get currentConnectionLabel => 'Current Connection';

  @override
  String get wifiNetworksLabel => 'WiFi Networks';

  @override
  String get ftpHostLabel => 'Host';

  @override
  String get ftpPortLabel => 'Port';

  @override
  String get ftpUsernameLabel => 'Username';

  @override
  String get ftpPasswordLabel => 'Password';

  @override
  String get connectButtonLabel => 'Connect';

  @override
  String get disconnectButtonLabel => 'Disconnect';

  @override
  String get scanButtonLabel => 'Scan Networks';

  @override
  String get uploadButtonLabel => 'Upload File';

  @override
  String get downloadButtonLabel => 'Download';

  @override
  String get noNetworksFound => 'No networks found';

  @override
  String get remoteFiles => 'Remote Files';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get fileUploaded => 'File uploaded successfully';

  @override
  String get fileDownloaded => 'Downloaded';

  @override
  String get portScanCompleted => 'Port scan completed';

  @override
  String get pinging => 'Pinging';

  @override
  String get tracingRoute => 'Tracing route to';

  @override
  String get scanningPorts => 'Scanning ports';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get help => 'Help';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get darkThemeSubtitle =>
      'Enable dark mode for better visibility in low light';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Select your preferred language';

  @override
  String get autoSave => 'Auto Save';

  @override
  String get autoSaveSubtitle => 'Automatically save changes and preferences';

  @override
  String get networkSettings => 'Network Settings';

  @override
  String get networkTimeout => 'Network Timeout';

  @override
  String get networkTimeoutSubtitle =>
      'Timeout for network operations (seconds)';

  @override
  String get batchSize => 'Batch Size';

  @override
  String get batchSizeSubtitle => 'Number of items to process in batches';

  @override
  String get aiAssistantSettings => 'AI Assistant Settings';

  @override
  String get responseStyle => 'Response Style';

  @override
  String get responseStyleSubtitle =>
      'Choose AI assistant response preferences';

  @override
  String get concise => 'Concise';

  @override
  String get detailed => 'Detailed';

  @override
  String get stepByStep => 'Step by Step';

  @override
  String get smartSuggestions => 'Smart Suggestions';

  @override
  String get smartSuggestionsSubtitle =>
      'Enable AI-powered file organization suggestions';

  @override
  String get version => 'Version';

  @override
  String get buildNumber => 'Build Number';

  @override
  String get framework => 'Framework';

  @override
  String get database => 'Database';

  @override
  String get settingsSaved => 'Settings saved successfully!';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get askAiPlaceholder =>
      'Ask me about file management, organization, search...';

  @override
  String get aiWelcomeMessage =>
      'Hello! I\'m your AI file management assistant. How can I help you today?';

  @override
  String get aiOrganizeResponse =>
      '🤖 AI File Organization:\n\nI can help you organize your files intelligently! Based on research with LLMs like those in LlamaFS and Local-File-Organizer, here are AI-powered organization suggestions:\n\n📁 By Content Type: Documents, Images, Videos, Music, Archives\n📅 By Date: Recent, This Month, This Year, Older\n📊 By Usage: Frequently Used, Rarely Used, Archive\n🔍 By Smart Analysis: Work, Personal, Projects, Downloads\n\nWould you like me to help implement any of these organization strategies?';

  @override
  String get aiSearchResponse =>
      '🔍 AI-Powered Search:\n\nI can enhance your file search with LLM-based semantic understanding:\n\n📝 Natural Language: \"Find my tax documents from last year\"\n🖼️ Content Search: \"Find images of cats\" (analyzes image content)\n📄 Text Analysis: \"Find documents about machine learning\"\n🔗 Smart Matching: Understands synonyms and related terms\n\nTry using advanced search in the Files tab!';

  @override
  String get aiNetworkResponse =>
      '🌐 Network Diagnostics:\n\nYour network tools include:\n\n📡 WiFi Scanner: Discover and analyze wireless networks\n🏓 Ping Tool: Test connectivity to hosts\n🗺️ Traceroute: Map network paths and identify issues\n🔍 Port Scanner: Check for open ports on remote hosts\n\nUse the Network tab for comprehensive network management!';

  @override
  String get aiFtpResponse =>
      '☁️ FTP File Transfer:\n\nEfficient file sharing with:\n\n🔗 Server Connection: Connect to any FTP/SFTP server\n📁 Directory Navigation: Browse remote file systems\n⬆️ Upload Manager: Transfer files with progress tracking\n⬇️ Download Queue: Batch download multiple files\n\nAccess FTP tools in the FTP tab!';

  @override
  String get aiHelpResponse =>
      '🧠 AI Assistant Capabilities:\n\n📂 File Organization: Smart categorization and folder management\n🔎 Intelligent Search: Natural language and content-based finding\n🌐 Network Tools: Diagnostics, monitoring, and troubleshooting\n📤 File Transfer: FTP/SFTP client with advanced features\n📊 Analytics: File usage statistics and recommendations\n🔒 Security: Safe file operations and privacy protection\n\nWhat specific task would you like help with?';

  @override
  String aiDefaultResponse(Object query) {
    return '🤔 I understand you\'re asking about: \"$query\"\n\nI\'m designed to help with file management, organization, search, network tools, and FTP operations. Try asking about:\n\n• Organizing files by type or content\n• Searching for specific files\n• Network diagnostics and tools\n• FTP file transfers\n• General file management help\n\nHow can I assist you today?';
  }

  @override
  String get selectProject => 'Select Project';

  @override
  String get flutterDoctor => 'Flutter Doctor';

  @override
  String get cleanCache => 'Clean Cache';

  @override
  String get pubCacheRepair => 'Pub Cache Repair';

  @override
  String get exit => 'Exit';

  @override
  String get ready => 'Ready';

  @override
  String get running => 'Running';

  @override
  String get completed => 'Completed';

  @override
  String get failed => 'Failed';
}
