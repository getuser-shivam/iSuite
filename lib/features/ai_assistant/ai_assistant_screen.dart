import 'package:flutter/material.dart';
import '../../../core/central_config.dart';
import '../../../services/ai/ai_service.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading; // For AI thinking indicator

  const Message(this.text, this.isUser, this.timestamp, {this.isLoading = false});
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<Message> _messages = [
    Message('Hello! I\'m your AI file management assistant. How can I help you today?', false, DateTime.now()),
  ];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CentralConfig _config = CentralConfig.instance;
  final AIService _aiService = AIService();

  bool _isAiThinking = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isAiThinking) return;

    setState(() {
      _messages.add(Message(text, true, DateTime.now()));
      _isAiThinking = true;
      // Add thinking indicator
      _messages.add(Message('🤔 Thinking...', false, DateTime.now(), isLoading: true));
    });
    _inputController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    try {
      // Get AI response
      final context = 'User has access to: File Manager, Network Tools, FTP Client, Cloud Storage (Google Drive, Dropbox), Settings';
      final response = await _aiService.generateResponse(text, context);

      // Remove thinking indicator and add real response
      setState(() {
        _messages.removeLast(); // Remove thinking message
        _messages.add(Message(response, false, DateTime.now()));
        _isAiThinking = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _messages.removeLast(); // Remove thinking message
        _messages.add(Message('Sorry, I encountered an error: ${e.toString()}\n\nTry checking your AI configuration in Settings.', false, DateTime.now()));
        _isAiThinking = false;
      });
    }

    // Scroll to bottom again
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _generateAiResponse(String query) {
    final lowerQuery = query.toLowerCase();

    // AI-powered file organization
    if (lowerQuery.contains('organize') || lowerQuery.contains('sort') || lowerQuery.contains('categorize')) {
      return '🤖 AI File Organization:\n\nI can help you organize your files intelligently! Based on research with LLMs like those in LlamaFS and Local-File-Organizer, here are AI-powered organization suggestions:\n\n'
             '📁 By Content Type: Documents, Images, Videos, Music, Archives\n'
             '📅 By Date: Recent, This Month, This Year, Older\n'
             '📊 By Usage: Frequently Used, Rarely Used, Archive\n'
             '🔍 By Smart Analysis: Work, Personal, Projects, Downloads\n\n'
             'Would you like me to help implement any of these organization strategies?';
    }

    // AI search and find
    else if (lowerQuery.contains('search') || lowerQuery.contains('find') || lowerQuery.contains('locate')) {
      return '🔍 AI-Powered Search:\n\nI can enhance your file search with LLM-based semantic understanding:\n\n'
             '📝 Natural Language: "Find my tax documents from last year"\n'
             '🖼️ Content Search: "Find images of cats" (analyzes image content)\n'
             '📄 Text Analysis: "Find documents about machine learning"\n'
             '🔗 Smart Matching: Understands synonyms and related terms\n\n'
             'Try using advanced search in the Files tab!';
    }

    // Network assistance
    else if (lowerQuery.contains('network') || lowerQuery.contains('wifi') || lowerQuery.contains('ping')) {
      return '🌐 Network Diagnostics:\n\nYour network tools include:\n\n'
             '📡 WiFi Scanner: Discover and analyze wireless networks\n'
             '🏓 Ping Tool: Test connectivity to hosts\n'
             '🗺️ Traceroute: Map network paths and identify issues\n'
             '🔍 Port Scanner: Check for open ports on remote hosts\n\n'
             'Use the Network tab for comprehensive network management!';
    }

    // FTP assistance
    else if (lowerQuery.contains('ftp') || lowerQuery.contains('upload') || lowerQuery.contains('download')) {
      return '☁️ FTP File Transfer:\n\nEfficient file sharing with:\n\n'
             '🔗 Server Connection: Connect to any FTP/SFTP server\n'
             '📁 Directory Navigation: Browse remote file systems\n'
             '⬆️ Upload Manager: Transfer files with progress tracking\n'
             '⬇️ Download Queue: Batch download multiple files\n\n'
             'Access FTP tools in the FTP tab!';
    }

    // General AI assistance
    else if (lowerQuery.contains('help') || lowerQuery.contains('what can you do')) {
      return '🧠 AI Assistant Capabilities:\n\n'
             '📂 File Organization: Smart categorization and folder management\n'
             '🔎 Intelligent Search: Natural language and content-based finding\n'
             '🌐 Network Tools: Diagnostics, monitoring, and troubleshooting\n'
             '📤 File Transfer: FTP/SFTP client with advanced features\n'
             '📊 Analytics: File usage statistics and recommendations\n'
             '🔒 Security: Safe file operations and privacy protection\n\n'
             'What specific task would you like help with?';
    }

    // Default response
    else {
      return '🤔 I understand you\'re asking about: "$query"\n\n'
             'I\'m designed to help with file management, organization, search, network tools, and FTP operations. '
             'Try asking about:\n\n'
             '• Organizing files by type or content\n'
             '• Searching for specific files\n'
             '• Network diagnostics and tools\n'
             '• FTP file transfers\n'
             '• General file management help\n\n'
             'How can I assist you today?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Assistant'),
        elevation: _config.getParameter('ui.app_bar.elevation', defaultValue: 4.0),
        backgroundColor: _config.primaryColor,
        foregroundColor: _config.surfaceColor,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Container(
              margin: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
              decoration: BoxDecoration(
                color: _config.surfaceColor,
                borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 8.0)),
                boxShadow: [
                  BoxShadow(
                    color: _config.primaryColor.withOpacity(0.1),
                    blurRadius: _config.getParameter('ui.shadow.blur_radius', defaultValue: 4.0),
                    offset: Offset(0, _config.getParameter('ui.shadow.elevation.low', defaultValue: 2.0)),
                  ),
                ],
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
            decoration: BoxDecoration(
              color: _config.surfaceColor,
              border: Border(
                top: BorderSide(
                  color: _config.primaryColor.withOpacity(_config.getParameter('ui.opacity.disabled', defaultValue: 0.5)),
                  width: _config.getParameter('ui.border_width.thin', defaultValue: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'Ask me about file management, organization, search...',
                      hintStyle: TextStyle(color: _config.primaryColor.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 8.0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 8.0)),
                        borderSide: BorderSide(color: _config.primaryColor),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: _config.getParameter('ui.spacing.medium', defaultValue: 20.0),
                        vertical: _config.getParameter('ui.spacing.medium', defaultValue: 20.0) / 2,
                      ),
                    ),
                    style: TextStyle(color: _config.primaryColor),
                    maxLines: _config.getParameter('ui.ai_assistant.message_max_lines', defaultValue: 3),
                    minLines: _config.getParameter('ui.ai_assistant.message_min_lines', defaultValue: 1),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: _config.getParameter('ui.spacing.medium', defaultValue: 20.0)),
                ElevatedButton.icon(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send, size: _config.getParameter('ui.ai_assistant.send_icon_size', defaultValue: 18.0)),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _config.primaryColor,
                    foregroundColor: _config.surfaceColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: _config.getParameter('ui.spacing.medium', defaultValue: 20.0),
                      vertical: _config.getParameter('ui.spacing.medium', defaultValue: 20.0) / 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = isUser
        ? EdgeInsets.only(
            left: _config.getParameter('ui.ai_assistant.message_max_width', defaultValue: 300.0)!,
            bottom: _config.getParameter('ui.ai_assistant.message_spacing', defaultValue: 8.0)!,
          )
        : EdgeInsets.only(
            right: _config.getParameter('ui.ai_assistant.message_max_width', defaultValue: 300.0)!,
            bottom: _config.getParameter('ui.ai_assistant.message_spacing', defaultValue: 8.0)!,
          );

    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: _config.getParameter('ui.ai_assistant.message_max_width', defaultValue: 300.0)!,
            ),
            padding: EdgeInsets.all(_config.getParameter('ui.ai_assistant.message_spacing', defaultValue: 8.0)!),
            decoration: BoxDecoration(
              color: isUser ? _config.primaryColor : _config.secondaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 8.0)!),
            ),
            child: message.isLoading
                ? SizedBox(
                    width: _config.getParameter('ui.ai_assistant.message_max_width', defaultValue: 300.0)! * 0.6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: _config.getParameter('ui.ai_assistant.typing_indicator_size', defaultValue: 16.0),
                          height: _config.getParameter('ui.ai_assistant.typing_indicator_size', defaultValue: 16.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isUser ? _config.surfaceColor : _config.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI thinking...',
                          style: TextStyle(
                            color: isUser ? _config.surfaceColor : _config.primaryColor,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? _config.surfaceColor : _config.primaryColor,
                      fontSize: 14,
                    ),
                  ),
          ),
          if (!message.isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: _config.primaryColor.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
