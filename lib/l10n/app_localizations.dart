import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'iSuite - Owlfiles File Manager'**
  String get appTitle;

  /// No description provided for @wifiScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Network Management'**
  String get wifiScreenTitle;

  /// No description provided for @ftpScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'FTP Client'**
  String get ftpScreenTitle;

  /// No description provided for @filesTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTabTitle;

  /// No description provided for @networkTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkTabTitle;

  /// No description provided for @ftpTabTitle.
  ///
  /// In en, this message translates to:
  /// **'FTP'**
  String get ftpTabTitle;

  /// No description provided for @aiTabTitle.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiTabTitle;

  /// No description provided for @settingsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTabTitle;

  /// No description provided for @currentConnectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Connection'**
  String get currentConnectionLabel;

  /// No description provided for @wifiNetworksLabel.
  ///
  /// In en, this message translates to:
  /// **'WiFi Networks'**
  String get wifiNetworksLabel;

  /// No description provided for @ftpHostLabel.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get ftpHostLabel;

  /// No description provided for @ftpPortLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get ftpPortLabel;

  /// No description provided for @ftpUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get ftpUsernameLabel;

  /// No description provided for @ftpPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get ftpPasswordLabel;

  /// No description provided for @connectButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectButtonLabel;

  /// No description provided for @disconnectButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectButtonLabel;

  /// No description provided for @scanButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan Networks'**
  String get scanButtonLabel;

  /// No description provided for @uploadButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadButtonLabel;

  /// No description provided for @downloadButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadButtonLabel;

  /// No description provided for @noNetworksFound.
  ///
  /// In en, this message translates to:
  /// **'No networks found'**
  String get noNetworksFound;

  /// No description provided for @remoteFiles.
  ///
  /// In en, this message translates to:
  /// **'Remote Files'**
  String get remoteFiles;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @fileUploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully'**
  String get fileUploaded;

  /// No description provided for @fileDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get fileDownloaded;

  /// No description provided for @portScanCompleted.
  ///
  /// In en, this message translates to:
  /// **'Port scan completed'**
  String get portScanCompleted;

  /// No description provided for @pinging.
  ///
  /// In en, this message translates to:
  /// **'Pinging'**
  String get pinging;

  /// No description provided for @tracingRoute.
  ///
  /// In en, this message translates to:
  /// **'Tracing route to'**
  String get tracingRoute;

  /// No description provided for @scanningPorts.
  ///
  /// In en, this message translates to:
  /// **'Scanning ports'**
  String get scanningPorts;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @darkThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable dark mode for better visibility in low light'**
  String get darkThemeSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get languageSubtitle;

  /// No description provided for @autoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get autoSave;

  /// No description provided for @autoSaveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically save changes and preferences'**
  String get autoSaveSubtitle;

  /// No description provided for @networkSettings.
  ///
  /// In en, this message translates to:
  /// **'Network Settings'**
  String get networkSettings;

  /// No description provided for @networkTimeout.
  ///
  /// In en, this message translates to:
  /// **'Network Timeout'**
  String get networkTimeout;

  /// No description provided for @networkTimeoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timeout for network operations (seconds)'**
  String get networkTimeoutSubtitle;

  /// No description provided for @batchSize.
  ///
  /// In en, this message translates to:
  /// **'Batch Size'**
  String get batchSize;

  /// No description provided for @batchSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Number of items to process in batches'**
  String get batchSizeSubtitle;

  /// No description provided for @aiAssistantSettings.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant Settings'**
  String get aiAssistantSettings;

  /// No description provided for @responseStyle.
  ///
  /// In en, this message translates to:
  /// **'Response Style'**
  String get responseStyle;

  /// No description provided for @responseStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose AI assistant response preferences'**
  String get responseStyleSubtitle;

  /// No description provided for @concise.
  ///
  /// In en, this message translates to:
  /// **'Concise'**
  String get concise;

  /// No description provided for @detailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get detailed;

  /// No description provided for @stepByStep.
  ///
  /// In en, this message translates to:
  /// **'Step by Step'**
  String get stepByStep;

  /// No description provided for @smartSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Smart Suggestions'**
  String get smartSuggestions;

  /// No description provided for @smartSuggestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable AI-powered file organization suggestions'**
  String get smartSuggestionsSubtitle;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @framework.
  ///
  /// In en, this message translates to:
  /// **'Framework'**
  String get framework;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully!'**
  String get settingsSaved;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @askAiPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask me about file management, organization, search...'**
  String get askAiPlaceholder;

  /// No description provided for @aiWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m your AI file management assistant. How can I help you today?'**
  String get aiWelcomeMessage;

  /// No description provided for @aiOrganizeResponse.
  ///
  /// In en, this message translates to:
  /// **'🤖 AI File Organization:\n\nI can help you organize your files intelligently! Based on research with LLMs like those in LlamaFS and Local-File-Organizer, here are AI-powered organization suggestions:\n\n📁 By Content Type: Documents, Images, Videos, Music, Archives\n📅 By Date: Recent, This Month, This Year, Older\n📊 By Usage: Frequently Used, Rarely Used, Archive\n🔍 By Smart Analysis: Work, Personal, Projects, Downloads\n\nWould you like me to help implement any of these organization strategies?'**
  String get aiOrganizeResponse;

  /// No description provided for @aiSearchResponse.
  ///
  /// In en, this message translates to:
  /// **'🔍 AI-Powered Search:\n\nI can enhance your file search with LLM-based semantic understanding:\n\n📝 Natural Language: \"Find my tax documents from last year\"\n🖼️ Content Search: \"Find images of cats\" (analyzes image content)\n📄 Text Analysis: \"Find documents about machine learning\"\n🔗 Smart Matching: Understands synonyms and related terms\n\nTry using advanced search in the Files tab!'**
  String get aiSearchResponse;

  /// No description provided for @aiNetworkResponse.
  ///
  /// In en, this message translates to:
  /// **'🌐 Network Diagnostics:\n\nYour network tools include:\n\n📡 WiFi Scanner: Discover and analyze wireless networks\n🏓 Ping Tool: Test connectivity to hosts\n🗺️ Traceroute: Map network paths and identify issues\n🔍 Port Scanner: Check for open ports on remote hosts\n\nUse the Network tab for comprehensive network management!'**
  String get aiNetworkResponse;

  /// No description provided for @aiFtpResponse.
  ///
  /// In en, this message translates to:
  /// **'☁️ FTP File Transfer:\n\nEfficient file sharing with:\n\n🔗 Server Connection: Connect to any FTP/SFTP server\n📁 Directory Navigation: Browse remote file systems\n⬆️ Upload Manager: Transfer files with progress tracking\n⬇️ Download Queue: Batch download multiple files\n\nAccess FTP tools in the FTP tab!'**
  String get aiFtpResponse;

  /// No description provided for @aiHelpResponse.
  ///
  /// In en, this message translates to:
  /// **'🧠 AI Assistant Capabilities:\n\n📂 File Organization: Smart categorization and folder management\n🔎 Intelligent Search: Natural language and content-based finding\n🌐 Network Tools: Diagnostics, monitoring, and troubleshooting\n📤 File Transfer: FTP/SFTP client with advanced features\n📊 Analytics: File usage statistics and recommendations\n🔒 Security: Safe file operations and privacy protection\n\nWhat specific task would you like help with?'**
  String get aiHelpResponse;

  /// No description provided for @aiDefaultResponse.
  ///
  /// In en, this message translates to:
  /// **'🤔 I understand you\'re asking about: \"{query}\"\n\nI\'m designed to help with file management, organization, search, network tools, and FTP operations. Try asking about:\n\n• Organizing files by type or content\n• Searching for specific files\n• Network diagnostics and tools\n• FTP file transfers\n• General file management help\n\nHow can I assist you today?'**
  String aiDefaultResponse(Object query);

  /// No description provided for @selectProject.
  ///
  /// In en, this message translates to:
  /// **'Select Project'**
  String get selectProject;

  /// No description provided for @flutterDoctor.
  ///
  /// In en, this message translates to:
  /// **'Flutter Doctor'**
  String get flutterDoctor;

  /// No description provided for @cleanCache.
  ///
  /// In en, this message translates to:
  /// **'Clean Cache'**
  String get cleanCache;

  /// No description provided for @pubCacheRepair.
  ///
  /// In en, this message translates to:
  /// **'Pub Cache Repair'**
  String get pubCacheRepair;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
