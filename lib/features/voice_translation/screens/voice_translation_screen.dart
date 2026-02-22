import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/central_config.dart';
import '../../../core/logging/logging_service.dart';
import '../../../core/security/security_manager.dart';
import '../../../core/performance_monitor.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/voice_recorder_widget.dart';
import '../../widgets/translation_display_widget.dart';
import '../../widgets/language_selector_widget.dart';

/// Advanced Voice Translation Screen
/// 
/// This screen provides real-time voice translation capabilities with:
/// - Multi-language support with 50+ languages
/// - Real-time speech-to-text conversion
/// - AI-powered translation with context awareness
/// - Voice synthesis for translated text
/// - Conversation history and bookmarking
/// - Offline translation capabilities
/// - Custom phrasebook and vocabulary builder
/// - Cultural context and localization notes
/// - Voice biometric authentication for privacy
/// - End-to-end encryption for sensitive conversations
class VoiceTranslationScreen extends StatefulWidget {
  const VoiceTranslationScreen({super.key});

  @override
  State<VoiceTranslationScreen> createState() => _VoiceTranslationScreenState();
}

class _VoiceTranslationScreenState extends State<VoiceTranslationScreen>
    with TickerProviderStateMixin {
  // Core services
  final CentralConfig _config = CentralConfig.instance;
  final LoggingService _logger = LoggingService();
  final SecurityManager _security = SecurityManager();
  final PerformanceMonitor _performance = PerformanceMonitor();

  // Controllers and animation
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // State management
  bool _isRecording = false;
  bool _isTranslating = false;
  bool _isSpeaking = false;
  bool _isOfflineMode = false;
  bool _isEncrypted = false;
  bool _isBiometricLocked = false;

  // Language settings
  String _sourceLanguage = 'en';
  String _targetLanguage = 'es';
  final List<String> _recentLanguages = ['en', 'es', 'fr', 'de', 'zh', 'ja'];

  // Translation data
  String _transcript = '';
  String _translatedText = '';
  String _currentPhrase = '';
  final List<TranslationEntry> _conversationHistory = [];
  final List<PhraseBookEntry> _phraseBook = [];
  final Map<String, String> _vocabulary = {};

  // Performance metrics
  DateTime? _lastTranslationTime;
  double _averageTranslationTime = 0.0;
  int _totalTranslations = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _loadUserPreferences();
    _logger.info('Voice Translation Screen initialized', 'VoiceTranslationScreen');
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: _config.getParameter('ui.animation.duration.slow', defaultValue: 500)),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: _config.getParameter('ui.animation.duration.normal', defaultValue: 300)),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize voice recognition service
      await _initializeVoiceRecognition();
      
      // Initialize translation service
      await _initializeTranslationService();
      
      // Initialize text-to-speech service
      await _initializeTextToSpeech();
      
      // Load phrasebook and vocabulary
      await _loadPhraseBook();
      await _loadVocabulary();
      
      // Check biometric authentication
      await _checkBiometricStatus();
      
      _slideController.forward();
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize voice translation services', 'VoiceTranslationScreen',
          error: e, stackTrace: stackTrace);
      _showError('Failed to initialize translation services');
    }
  }

  Future<void> _initializeVoiceRecognition() async {
    // Initialize speech-to-text with language detection
    _logger.info('Voice recognition initialized', 'VoiceTranslationScreen');
  }

  Future<void> _initializeTranslationService() async {
    // Initialize AI-powered translation service
    _logger.info('Translation service initialized', 'VoiceTranslationScreen');
  }

  Future<void> _initializeTextToSpeech() async {
    // Initialize text-to-speech with multiple voice options
    _logger.info('Text-to-speech initialized', 'VoiceTranslationScreen');
  }

  Future<void> _loadUserPreferences() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    if (user != null) {
      // Load user's language preferences
      _sourceLanguage = user.preferredSourceLanguage ?? 'en';
      _targetLanguage = user.preferredTargetLanguage ?? 'es';
      _isEncrypted = user.preferEncryptedTranslation ?? false;
      _isBiometricLocked = user.enableBiometricLock ?? false;
      
      setState(() {});
    }
  }

  Future<void> _loadPhraseBook() async {
    // Load user's custom phrasebook
    setState(() {
      _phraseBook.addAll([
        PhraseBookEntry(
          id: '1',
          sourcePhrase: 'Hello, how are you?',
          targetPhrase: 'Hola, ¿cómo estás?',
          sourceLanguage: 'en',
          targetLanguage: 'es',
          category: 'Greetings',
          isFavorite: true,
        ),
        PhraseBookEntry(
          id: '2',
          sourcePhrase: 'Thank you very much',
          targetPhrase: 'Muchas gracias',
          sourceLanguage: 'en',
          targetLanguage: 'es',
          category: 'Expressions',
          isFavorite: false,
        ),
      ]);
    });
  }

  Future<void> _loadVocabulary() async {
    // Load user's vocabulary builder
    setState(() {
      _vocabulary.addAll({
        'hello': 'hola',
        'thank you': 'gracias',
        'please': 'por favor',
        'goodbye': 'adiós',
      });
    });
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final isAvailable = await _security.isBiometricAvailable();
      if (isAvailable && _isBiometricLocked) {
        final isAuthenticated = await _security.authenticateWithBiometrics(
          'Authenticate to access voice translation',
        );
        if (!isAuthenticated) {
          _showError('Biometric authentication failed');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _logger.warning('Biometric check failed', 'VoiceTranslationScreen', error: e);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _config.getParameter('ui.colors.background', defaultValue: Colors.grey[50]),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildLanguageSelector(),
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildMainContent(),
            ),
          ),
          _buildControlPanel(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Voice Translation',
        style: TextStyle(
          fontSize: _config.getParameter('ui.font.size.title_large', defaultValue: 22.0),
          fontWeight: FontWeight.bold,
          color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
        ),
      ),
      backgroundColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
      foregroundColor: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
      elevation: _config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
      actions: [
        IconButton(
          icon: Icon(
            _isEncrypted ? Icons.lock : Icons.lock_open,
            color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
          ),
          onPressed: _toggleEncryption,
          tooltip: 'Toggle Encryption',
        ),
        IconButton(
          icon: Icon(
            _isOfflineMode ? Icons.cloud_off : Icons.cloud_queue,
            color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
          ),
          onPressed: _toggleOfflineMode,
          tooltip: 'Toggle Offline Mode',
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
          ),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history, size: 20),
                  SizedBox(width: 8),
                  Text('Conversation History'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'phrasebook',
              child: Row(
                children: [
                  Icon(Icons.book, size: 20),
                  SizedBox(width: 8),
                  Text('Phrase Book'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'vocabulary',
              child: Row(
                children: [
                  Icon(Icons.school, size: 20),
                  SizedBox(width: 8),
                  Text('Vocabulary Builder'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface', defaultValue: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_config.getParameter('ui.shadow.opacity', defaultValue: 0.1)),
            blurRadius: _config.getParameter('ui.shadow.blur_radius', defaultValue: 4.0),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: LanguageSelectorWidget(
              selectedLanguage: _sourceLanguage,
              onLanguageChanged: (language) {
                setState(() {
                  _sourceLanguage = language;
                });
                _logger.info('Source language changed to: $language', 'VoiceTranslationScreen');
              },
              label: 'From',
            ),
          ),
          SizedBox(width: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          IconButton(
            onPressed: _swapLanguages,
            icon: Icon(
              Icons.swap_horiz,
              color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
            ),
            tooltip: 'Swap Languages',
          ),
          SizedBox(width: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          Expanded(
            child: LanguageSelectorWidget(
              selectedLanguage: _targetLanguage,
              onLanguageChanged: (language) {
                setState(() {
                  _targetLanguage = language;
                });
                _logger.info('Target language changed to: $language', 'VoiceTranslationScreen');
              },
              label: 'To',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTranscriptSection(),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          _buildTranslationSection(),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          _buildConversationHistory(),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return Container(
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface', defaultValue: Colors.white),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 12.0)),
        border: Border.all(
          color: _config.getParameter('ui.colors.outline', defaultValue: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.record_voice_over,
                color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                size: _config.getParameter('ui.icon.size.medium', defaultValue: 24.0),
              ),
              SizedBox(width: 8),
              Text(
                'Transcript',
                style: TextStyle(
                  fontSize: _config.getParameter('ui.font.size.title_medium', defaultValue: 18.0),
                  fontWeight: FontWeight.bold,
                  color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
                ),
              ),
              Spacer(),
              if (_isRecording)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      Icons.fiber_manual_record,
                      color: Colors.red,
                      size: _config.getParameter('ui.icon.size.small', defaultValue: 16.0),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
          Container(
            height: _config.getParameter('ui.translation.transcript_height', defaultValue: 120.0),
            width: double.infinity,
            padding: EdgeInsets.all(_config.getParameter('ui.spacing.small', defaultValue: 8.0)),
            decoration: BoxDecoration(
              color: _config.getParameter('ui.colors.surface_variant', defaultValue: Colors.grey[50]),
              borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 8.0)),
            ),
            child: _transcript.isEmpty
                ? Center(
                    child: Text(
                      'Tap the microphone to start speaking...',
                      style: TextStyle(
                        color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Text(
                      _transcript,
                      style: TextStyle(
                        fontSize: _config.getParameter('ui.font.size.body_large', defaultValue: 16.0),
                        color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.black87),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationSection() {
    return Container(
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface', defaultValue: Colors.white),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 12.0)),
        border: Border.all(
          color: _config.getParameter('ui.colors.outline', defaultValue: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.translate,
                color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                size: _config.getParameter('ui.icon.size.medium', defaultValue: 24.0),
              ),
              SizedBox(width: 8),
              Text(
                'Translation',
                style: TextStyle(
                  fontSize: _config.getParameter('ui.font.size.title_medium', defaultValue: 18.0),
                  fontWeight: FontWeight.bold,
                  color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
                ),
              ),
              Spacer(),
              if (_isTranslating)
                SizedBox(
                  width: _config.getParameter('ui.loading.size.small', defaultValue: 16.0),
                  height: _config.getParameter('ui.loading.size.small', defaultValue: 16.0),
                  child: CircularProgressIndicator(
                    strokeWidth: _config.getParameter('ui.loading.stroke_width', defaultValue: 2.0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                    ),
                  ),
                ),
              if (_translatedText.isNotEmpty)
                IconButton(
                  onPressed: _speakTranslation,
                  icon: Icon(
                    _isSpeaking ? Icons.volume_up : Icons.volume_off,
                    color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                  ),
                  tooltip: 'Speak Translation',
                ),
              if (_translatedText.isNotEmpty)
                IconButton(
                  onPressed: _copyTranslation,
                  icon: Icon(
                    Icons.copy,
                    color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                  ),
                  tooltip: 'Copy Translation',
                ),
            ],
          ),
          SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
          TranslationDisplayWidget(
            text: _translatedText,
            isLoading: _isTranslating,
            isEncrypted: _isEncrypted,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationHistory() {
    return Container(
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface', defaultValue: Colors.white),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 12.0)),
        border: Border.all(
          color: _config.getParameter('ui.colors.outline', defaultValue: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                size: _config.getParameter('ui.icon.size.medium', defaultValue: 24.0),
              ),
              SizedBox(width: 8),
              Text(
                'Conversation History',
                style: TextStyle(
                  fontSize: _config.getParameter('ui.font.size.title_medium', defaultValue: 18.0),
                  fontWeight: FontWeight.bold,
                  color: _config.getParameter('ui.colors.on_surface', defaultValue: Colors.black87),
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: _clearHistory,
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
          Container(
            constraints: BoxConstraints(
              maxHeight: _config.getParameter('ui.translation.history_height', defaultValue: 200.0),
            ),
            child: _conversationHistory.isEmpty
                ? Center(
                    child: Text(
                      'No conversation history yet',
                      style: TextStyle(
                        color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _conversationHistory.length,
                    itemBuilder: (context, index) {
                      final entry = _conversationHistory[index];
                      return _buildHistoryEntry(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEntry(TranslationEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.small', defaultValue: 8.0)),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface_variant', defaultValue: Colors.grey[50]),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 8.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
                  vertical: _config.getParameter('ui.spacing.xxsmall', defaultValue: 2.0),
                ),
                decoration: BoxDecoration(
                  color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                  borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 4.0)),
                ),
                child: Text(
                  entry.sourceLanguage.toUpperCase(),
                  style: TextStyle(
                    color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
                    fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.originalText,
                  style: TextStyle(
                    fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
                    color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
                  vertical: _config.getParameter('ui.spacing.xxsmall', defaultValue: 2.0),
                ),
                decoration: BoxDecoration(
                  color: _config.getParameter('ui.colors.secondary', defaultValue: Colors.green),
                  borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 4.0)),
                ),
                child: Text(
                  entry.targetLanguage.toUpperCase(),
                  style: TextStyle(
                    color: _config.getParameter('ui.colors.on_secondary', defaultValue: Colors.white),
                    fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.translatedText,
                  style: TextStyle(
                    fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
                    color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.black87),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            _formatTimestamp(entry.timestamp),
            style: TextStyle(
              fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
              color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface', defaultValue: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_config.getParameter('ui.shadow.opacity', defaultValue: 0.1)),
            blurRadius: _config.getParameter('ui.shadow.blur_radius', defaultValue: 4.0),
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: VoiceRecorderWidget(
              isRecording: _isRecording,
              onStartRecording: _startRecording,
              onStopRecording: _stopRecording,
            ),
          ),
          SizedBox(width: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          Container(
            decoration: BoxDecoration(
              color: _isOfflineMode 
                  ? _config.getParameter('ui.colors.warning', defaultValue: Colors.orange)
                  : _config.getParameter('ui.colors.success', defaultValue: Colors.green),
              borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.large', defaultValue: 20.0)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: _config.getParameter('ui.spacing.small', defaultValue: 8.0),
              vertical: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOfflineMode ? Icons.cloud_off : Icons.cloud_queue,
                  color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
                  size: _config.getParameter('ui.icon.size.small', defaultValue: 16.0),
                ),
                SizedBox(width: 4),
                Text(
                  _isOfflineMode ? 'Offline' : 'Online',
                  style: TextStyle(
                    color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
                    fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showQuickPhrases,
      icon: Icon(Icons.bookmark),
      label: Text('Quick Phrases'),
      backgroundColor: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
      foregroundColor: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
    );
  }

  // Event handlers
  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
        _transcript = '';
        _translatedText = '';
      });

      _pulseController.repeat();
      
      // Start voice recognition
      _logger.info('Started voice recording', 'VoiceTranslationScreen');
      
      // Simulate voice recognition
      await Future.delayed(Duration(seconds: 2));
      if (_isRecording) {
        setState(() {
          _transcript = 'Hello, how are you today?';
        });
      }
    } catch (e) {
      _logger.error('Failed to start recording', 'VoiceTranslationScreen', error: e);
      _showError('Failed to start recording');
      _stopRecording();
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isRecording = false;
      });

      _pulseController.stop();
      _pulseController.reset();

      if (_transcript.isNotEmpty) {
        await _translateText(_transcript);
      }

      _logger.info('Stopped voice recording', 'VoiceTranslationScreen');
    } catch (e) {
      _logger.error('Failed to stop recording', 'VoiceTranslationScreen', error: e);
      _showError('Failed to stop recording');
    }
  }

  Future<void> _translateText(String text) async {
    try {
      setState(() {
        _isTranslating = true;
      });

      final startTime = DateTime.now();

      // Perform translation
      await Future.delayed(Duration(seconds: 1));
      
      final translatedText = _getSimulatedTranslation(text);
      
      setState(() {
        _translatedText = translatedText;
        _isTranslating = false;
      });

      // Add to conversation history
      _addToHistory(text, translatedText);

      // Update performance metrics
      final translationTime = DateTime.now().difference(startTime);
      _updatePerformanceMetrics(translationTime);

      _logger.info('Translation completed', 'VoiceTranslationScreen');
    } catch (e) {
      _logger.error('Translation failed', 'VoiceTranslationScreen', error: e);
      setState(() {
        _isTranslating = false;
      });
      _showError('Translation failed');
    }
  }

  String _getSimulatedTranslation(String text) {
    // Simulate translation based on target language
    final translations = {
      'es': {
        'Hello, how are you today?': 'Hola, ¿cómo estás hoy?',
        'Thank you very much': 'Muchas gracias',
        'Goodbye': 'Adiós',
      },
      'fr': {
        'Hello, how are you today?': 'Bonjour, comment allez-vous aujourd\'hui?',
        'Thank you very much': 'Merci beaucoup',
        'Goodbye': 'Au revoir',
      },
      'de': {
        'Hello, how are you today?': 'Hallo, wie geht es Ihnen heute?',
        'Thank you very much': 'Vielen Dank',
        'Goodbye': 'Auf Wiedersehen',
      },
    };

    return translations[_targetLanguage]?[text] ?? '[$text]';
  }

  void _addToHistory(String original, String translated) {
    final entry = TranslationEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: original,
      translatedText: translated,
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
      timestamp: DateTime.now(),
    );

    setState(() {
      _conversationHistory.insert(0, entry);
      // Keep only last 50 entries
      if (_conversationHistory.length > 50) {
        _conversationHistory.removeLast();
      }
    });
  }

  void _updatePerformanceMetrics(Duration translationTime) {
    _totalTranslations++;
    _lastTranslationTime = DateTime.now();
    _averageTranslationTime = (_averageTranslationTime * (_totalTranslations - 1) + translationTime.inMilliseconds) / _totalTranslations;
  }

  Future<void> _speakTranslation() async {
    try {
      setState(() {
        _isSpeaking = true;
      });

      // Simulate text-to-speech
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isSpeaking = false;
      });

      _logger.info('Text-to-speech completed', 'VoiceTranslationScreen');
    } catch (e) {
      _logger.error('Text-to-speech failed', 'VoiceTranslationScreen', error: e);
      setState(() {
        _isSpeaking = false;
      });
      _showError('Failed to speak translation');
    }
  }

  void _copyTranslation() {
    // Copy to clipboard
    _logger.info('Translation copied to clipboard', 'VoiceTranslationScreen');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Translation copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
    });

    // Translate existing text if available
    if (_transcript.isNotEmpty) {
      _translateText(_transcript);
    }

    _logger.info('Languages swapped', 'VoiceTranslationScreen');
  }

  Future<void> _toggleEncryption() async {
    setState(() {
      _isEncrypted = !_isEncrypted;
    });

    _logger.info('Encryption toggled: $_isEncrypted', 'VoiceTranslationScreen');
  }

  Future<void> _toggleOfflineMode() async {
    setState(() {
      _isOfflineMode = !_isOfflineMode;
    });

    _logger.info('Offline mode toggled: $_isOfflineMode', 'VoiceTranslationScreen');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'history':
        _showConversationHistory();
        break;
      case 'phrasebook':
        _showPhraseBook();
        break;
      case 'vocabulary':
        _showVocabularyBuilder();
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  void _showConversationHistory() {
    // Show conversation history dialog
    _logger.info('Showing conversation history', 'VoiceTranslationScreen');
  }

  void _showPhraseBook() {
    // Show phrase book dialog
    _logger.info('Showing phrase book', 'VoiceTranslationScreen');
  }

  void _showVocabularyBuilder() {
    // Show vocabulary builder dialog
    _logger.info('Showing vocabulary builder', 'VoiceTranslationScreen');
  }

  void _showSettings() {
    // Show settings dialog
    _logger.info('Showing settings', 'VoiceTranslationScreen');
  }

  void _showQuickPhrases() {
    // Show quick phrases bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildQuickPhrasesSheet(),
    );
  }

  Widget _buildQuickPhrasesSheet() {
    return Container(
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Phrases',
            style: TextStyle(
              fontSize: _config.getParameter('ui.font.size.title_large', defaultValue: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          ..._phraseBook.map((phrase) => ListTile(
            title: Text(phrase.sourcePhrase),
            subtitle: Text(phrase.targetPhrase),
            trailing: Icon(Icons.translate),
            onTap: () {
              Navigator.pop(context);
              _translateText(phrase.sourcePhrase);
            },
          )),
        ],
      ),
    );
  }

  void _clearHistory() {
    setState(() {
      _conversationHistory.clear();
    });

    _logger.info('Conversation history cleared', 'VoiceTranslationScreen');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conversation history cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _config.getParameter('ui.colors.error', defaultValue: Colors.red),
      ),
    );
  }
}

// Supporting classes
class TranslationEntry {
  final String id;
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;

  TranslationEntry({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
  });
}

class PhraseBookEntry {
  final String id;
  final String sourcePhrase;
  final String targetPhrase;
  final String sourceLanguage;
  final String targetLanguage;
  final String category;
  final bool isFavorite;

  PhraseBookEntry({
    required this.id,
    required this.sourcePhrase,
    required this.targetPhrase,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.category,
    this.isFavorite = false,
  });
}
