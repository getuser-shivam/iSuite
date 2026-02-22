import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/ai_engine.dart';
import '../../core/base_component.dart';
import '../../core/utils.dart';

class AIAssistantProvider extends BaseProvider {
  static const String _id = 'ai_assistant_provider';
  
  @override
  String get id => _id;
  
  @override
  String get name => 'AI Assistant Provider';
  
  @override
  String get version => '1.0.0';
  
  @override
  List<Type> get dependencies => [];

  // AI Engine
  final AIEngine _aiEngine = AIEngine.instance;
  
  // Speech Recognition
  stt.SpeechToText? _speech;
  bool _isListening = false;
  String _spokenText = '';
  double _confidence = 0.0;
  
  // Text to Speech
  FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  
  // Conversation State
  List<AIConversationMessage> _conversation = [];
  bool _isProcessing = false;
  String? _error;
  
  // AI Capabilities
  bool _voiceEnabled = false;
  bool _contextAware = true;
  bool _proactiveSuggestions = true;
  Timer? _suggestionTimer;

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isProcessing => _isProcessing;
  String get spokenText => _spokenText;
  double get confidence => _confidence;
  String? get error => _error;
  List<AIConversationMessage> get conversation => List.from(_conversation);
  bool get voiceEnabled => _voiceEnabled;
  bool get contextAware => _contextAware;
  bool get proactiveSuggestions => _proactiveSuggestions;

  AIAssistantProvider() {
    // Set default parameters
    _parameters['voice_enabled'] = false;
    _parameters['context_aware'] = true;
    _parameters['proactive_suggestions'] = true;
    _parameters['suggestion_interval'] = Duration(minutes: 10);
    _parameters['max_conversation_length'] = 50;
    _parameters['tts_speed'] = 1.0;
    _parameters['tts_pitch'] = 1.0;
    _parameters['tts_volume'] = 1.0;
  }

  @override
  Future<void> onInitialize() async {
    try {
      // Initialize AI Engine
      await _aiEngine.initialize();
      
      // Initialize speech recognition
      await _initializeSpeechRecognition();
      
      // Initialize text to speech
      await _initializeTextToSpeech();
      
      // Start proactive suggestions
      if (_proactiveSuggestions) {
        _startProactiveSuggestions();
      }
      
      // Add welcome message
      _addMessage(AIConversationMessage(
        text: 'Hello! I\'m your AI assistant. I can help you with tasks, notes, files, and productivity. How can I assist you today?',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.greeting,
      ));
      
      AppUtils.logInfo('AIAssistantProvider', 'AI Assistant initialized successfully');
    } catch (e) {
      setError('Failed to initialize AI Assistant: $e');
      AppUtils.logError('AIAssistantProvider', 'Initialization failed', e);
    }
  }

  Future<void> _initializeSpeechRecognition() async {
    _speech = stt.SpeechToText();
    
    await _speech!.initialize(
      onError: (error) {
        setError('Speech recognition error: $error');
        _isListening = false;
        notifyListeners();
      },
      onStatus: (status) {
        if (status == 'done') {
          _isListening = false;
          notifyListeners();
        }
      },
    );
  }

  Future<void> _initializeTextToSpeech() async {
    await _flutterTts.setLanguage('en_US');
    await _flutterTts.setSpeechRate(getParameter<double>('tts_speed', 1.0));
    await _flutterTts.setPitch(getParameter<double>('tts_pitch', 1.0));
    await _flutterTts.setVolume(getParameter<double>('tts_volume', 1.0));
    
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
    
    _flutterTts.setErrorHandler((msg) {
      setError('Text to speech error: $msg');
      _isSpeaking = false;
      notifyListeners();
    });
  }

  void _startProactiveSuggestions() {
    final interval = getParameter<Duration>('suggestion_interval', Duration(minutes: 10));
    _suggestionTimer = Timer.periodic(interval, (_) async {
      if (!_isProcessing && !_isListening && !_isSpeaking) {
        final suggestions = await _aiEngine.generateSmartSuggestions();
        if (suggestions.isNotEmpty) {
          _showProactiveSuggestion(suggestions.first);
        }
      }
    });
  }

  Future<void> startListening() async {
    if (!_voiceEnabled || _speech == null || _isListening) return;

    try {
      _isListening = true;
      _spokenText = '';
      _confidence = 0.0;
      clearError();
      notifyListeners();

      await _speech!.listen(
        onResult: (result) {
          _spokenText = result.recognizedWords;
          _confidence = result.confidence;
          notifyListeners();
        },
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
      );
    } catch (e) {
      setError('Failed to start listening: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (_speech == null || !_isListening) return;

    try {
      await _speech!.stop();
      _isListening = false;
      notifyListeners();
      
      // Process the spoken text if any
      if (_spokenText.isNotEmpty) {
        await _processText(_spokenText);
      }
    } catch (e) {
      setError('Failed to stop listening: $e');
      notifyListeners();
    }
  }

  Future<void> _processText(String text) async {
    if (text.trim().isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      // Add user message
      _addMessage(AIConversationMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        type: MessageType.query,
      ));

      // Get AI response
      final response = await _aiEngine.processQuery(text);
      
      // Add AI response
      _addMessage(AIConversationMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.response,
        suggestions: response.suggestions,
        actions: response.actions,
        confidence: response.confidence,
      ));

      // Speak response if voice is enabled
      if (_voiceEnabled && response.confidence > 0.7) {
        await _speak(response.text);
      }

    } catch (e) {
      setError('Failed to process text: $e');
      _addMessage(AIConversationMessage(
        text: 'Sorry, I encountered an error processing your request.',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.error,
      ));
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _speak(String text) async {
    if (!_voiceEnabled || _isSpeaking) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      setError('Failed to speak: $e');
    }
  }

  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;

    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      setError('Failed to stop speaking: $e');
    }
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _processText(text);
  }

  void _addMessage(AIConversationMessage message) {
    _conversation.add(message);
    
    // Limit conversation length
    final maxLength = getParameter<int>('max_conversation_length', 50);
    if (_conversation.length > maxLength) {
      _conversation.removeRange(0, _conversation.length - maxLength);
    }
    
    notifyListeners();
  }

  void _showProactiveSuggestion(String suggestion) {
    _addMessage(AIConversationMessage(
      text: suggestion,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.suggestion,
    ));

    // Speak suggestion if voice is enabled
    if (_voiceEnabled) {
      _speak(suggestion);
    }
  }

  Future<void> executeAction(AIAction action) async {
    try {
      switch (action.type) {
        case AIActionType.createTask:
          await _executeCreateTask(action.data);
          break;
        case AIActionType.showTasks:
          await _executeShowTasks(action.data);
          break;
        case AIActionType.completeTask:
          await _executeCompleteTask(action.data);
          break;
        case AIActionType.optimizeSchedule:
          await _executeOptimizeSchedule(action.data);
          break;
        case AIActionType.showProductivity:
          await _executeShowProductivity(action.data);
          break;
        case AIActionType.showAnalytics:
          await _executeShowAnalytics(action.data);
          break;
        case AIActionType.showHelp:
          await _executeShowHelp(action.data);
          break;
        case AIActionType.showFeatures:
          await _executeShowFeatures(action.data);
          break;
      }
    } catch (e) {
      setError('Failed to execute action: $e');
    }
  }

  Future<void> _executeCreateTask(Map<String, dynamic> data) async {
    // This would integrate with TaskProvider
    _addMessage(AIConversationMessage(
      text: 'I\'ve created the task "${data['title']}" for you.',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.action_result,
    ));
  }

  Future<void> _executeShowTasks(Map<String, dynamic> data) async {
    // This would navigate to tasks screen with filter
    _addMessage(AIConversationMessage(
      text: 'Here are your ${data['filter'] ?? 'all'} tasks.',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.action_result,
    ));
  }

  Future<void> _executeCompleteTask(Map<String, dynamic> data) async {
    // This would complete the task
    _addMessage(AIConversationMessage(
      text: 'I\'ve completed the task for you.',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.action_result,
    ));
  }

  Future<void> _executeOptimizeSchedule(Map<String, dynamic> data) async {
    _addMessage(AIConversationMessage(
      text: 'I\'ve optimized your schedule based on your productivity patterns.',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.action_result,
    ));
  }

  Future<void> _executeShowProductivity(Map<String, dynamic> data) async {
    _addMessage(AIConversationMessage(
      text: 'Here\'s your productivity analysis.',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.action_result,
    ));
  }

  Future<void> _executeShowAnalytics(Map<String, dynamic> data) async {
    _addMessage(AIConversationMessage(
      text: 'Here are your analytics and insights.',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.action_result,
    ));
  }

  Future<void> _executeShowHelp(Map<String, dynamic> data) async {
    _addMessage(AIConversationMessage(
      text: 'Here\'s help for ${data['topic'] ?? 'general topics'}.',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.action_result,
    ));
  }

  Future<void> _executeShowFeatures(Map<String, dynamic> data) async {
    _addMessage(AIConversationMessage(
      text: 'I can help you with:\n• Task management\n• Note taking\n• File management\n• Calendar scheduling\n• Productivity analytics\n• Time optimization',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.action_result,
    ));
  }

  Future<void> clearConversation() async {
    _conversation.clear();
    _addMessage(AIConversationMessage(
      text: 'Conversation cleared. How can I help you?',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.greeting,
    ));
  }

  Future<List<AIRecommendation>> getRecommendations() async {
    return await _aiEngine.getRecommendations();
  }

  void toggleVoiceEnabled() {
    _voiceEnabled = !_voiceEnabled;
    setParameter('voice_enabled', _voiceEnabled);
    notifyListeners();
  }

  void toggleContextAware() {
    _contextAware = !_contextAware;
    setParameter('context_aware', _contextAware);
    notifyListeners();
  }

  void toggleProactiveSuggestions() {
    _proactiveSuggestions = !_proactiveSuggestions;
    setParameter('proactive_suggestions', _proactiveSuggestions);
    
    if (_proactiveSuggestions) {
      _startProactiveSuggestions();
    } else {
      _suggestionTimer?.cancel();
      _suggestionTimer = null;
    }
    
    notifyListeners();
  }

  Future<void> updateTtsSettings({
    double? speed,
    double? pitch,
    double? volume,
  }) async {
    if (speed != null) {
      await _flutterTts.setSpeechRate(speed);
      setParameter('tts_speed', speed);
    }
    if (pitch != null) {
      await _flutterTts.setPitch(pitch);
      setParameter('tts_pitch', pitch);
    }
    if (volume != null) {
      await _flutterTts.setVolume(volume);
      setParameter('tts_volume', volume);
    }
    notifyListeners();
  }

  @override
  void onDispose() {
    _suggestionTimer?.cancel();
    _speech?.cancel();
    _flutterTts.stop();
    _aiEngine.dispose();
    super.dispose();
  }
}

class AIConversationMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final List<String>? suggestions;
  final List<AIAction>? actions;
  final double? confidence;

  const AIConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.type,
    this.suggestions,
    this.actions,
    this.confidence,
  });

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

enum MessageType {
  query,
  response,
  greeting,
  suggestion,
  error,
  action_result,
}
