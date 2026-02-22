import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/ai_assistant_provider.dart';
import '../../core/ai_engine.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/empty_state_widget.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIAssistantProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Assistant'),
            actions: [
              IconButton(
                icon: Icon(provider.voiceEnabled ? Icons.mic : Icons.mic_off),
                onPressed: provider.toggleVoiceEnabled,
                tooltip: 'Toggle Voice',
              ),
              IconButton(
                icon: const Icons.settings),
                onPressed: () => _showSettings(context, provider),
                tooltip: 'Settings',
              ),
              IconButton(
                icon: const Icons.clear),
                onPressed: provider.clearConversation,
                tooltip: 'Clear Conversation',
              ),
            ],
          ),
          body: Column(
            children: [
              // AI Status Bar
              _buildStatusBar(context, provider),
              
              // Conversation Area
              Expanded(
                child: _buildConversationArea(context, provider),
              ),
              
              // Input Area
              _buildInputArea(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(BuildContext context, AIAssistantProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // AI Status Indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: provider.isProcessing ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(provider),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          
          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(provider),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (provider.error != null)
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          
          // Voice Indicator
          if (provider.voiceEnabled)
            Row(
              children: [
                if (provider.isListening)
                  const Icon(Icons.mic, color: Colors.red, size: 20),
                if (provider.isSpeaking)
                  const Icon(Icons.volume_up, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
              ],
            ),
          
          // Recommendations Button
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () => _showRecommendations(context, provider),
            tooltip: 'Get Recommendations',
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AIAssistantProvider provider) {
    if (provider.error != null) return Colors.red;
    if (provider.isProcessing) return Colors.orange;
    if (provider.isListening) return Colors.blue;
    if (provider.isSpeaking) return Colors.green;
    return Colors.grey;
  }

  String _getStatusText(AIAssistantProvider provider) {
    if (provider.error != null) return 'Error occurred';
    if (provider.isProcessing) return 'Processing...';
    if (provider.isListening) return 'Listening...';
    if (provider.isSpeaking) return 'Speaking...';
    return 'AI Assistant Ready';
  }

  Widget _buildConversationArea(BuildContext context, AIAssistantProvider provider) {
    if (provider.conversation.isEmpty) {
      return const EmptyStateWidget(
        title: 'Start a conversation',
        subtitle: 'Ask me anything about tasks, notes, files, or productivity',
        icon: Icons.smart_toy_outlined,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.conversation.length,
      itemBuilder: (context, index) {
        final message = provider.conversation[index];
        return _buildMessageBubble(context, message, provider);
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    AIConversationMessage message,
    AIAssistantProvider provider,
  ) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: isUser
                        ? null
                        : Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message Text
                      Text(
                        message.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      
                      // Confidence Score (for AI responses)
                      if (!isUser && message.confidence != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 12,
                                color: _getConfidenceColor(message.confidence!),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(message.confidence! * 100).toInt()}% confident',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isUser
                                      ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Suggestions
                      if (message.suggestions != null && message.suggestions!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: message.suggestions!.map((suggestion) {
                              return ActionChip(
                                label: Text(suggestion),
                                onPressed: () => _handleSuggestion(context, suggestion, provider),
                                backgroundColor: isUser
                                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.1)
                                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: isUser
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      
                      // Actions
                      if (message.actions != null && message.actions!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: message.actions!.map((action) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: ElevatedButton.icon(
                                  onPressed: () => _handleAction(context, action, provider),
                                  icon: _getActionIcon(action.type),
                                  label: Text(action.label),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isUser
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.primary,
                                    foregroundColor: isUser
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    message.formattedTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            // User Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getActionIcon(AIActionType type) {
    switch (type) {
      case AIActionType.createTask:
        return Icons.add_task;
      case AIActionType.showTasks:
        return Icons.list;
      case AIActionType.completeTask:
        return Icons.check_circle;
      case AIActionType.optimizeSchedule:
        return Icons.schedule;
      case AIActionType.showProductivity:
        return Icons.trending_up;
      case AIActionType.showAnalytics:
        return Icons.analytics;
      case AIActionType.showHelp:
        return Icons.help;
      case AIActionType.showFeatures:
        return Icons.featured_play_list;
    }
  }

  Widget _buildInputArea(BuildContext context, AIAssistantProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Text Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (text) => _sendMessage(context, provider, text),
                ),
              ),
              const SizedBox(width: 8),
              
              // Send Button
              IconButton.filled(
                onPressed: () => _sendMessage(context, provider, _textController.text),
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          
          // Voice Controls
          if (provider.voiceEnabled) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Listen Button
                IconButton.filled(
                  onPressed: provider.isListening
                      ? provider.stopListening
                      : provider.startListening,
                  icon: Icon(
                    provider.isListening ? Icons.stop : Icons.mic,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: provider.isListening
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Speaking Indicator
                if (provider.isSpeaking)
                  Row(
                    children: [
                      Icon(
                        Icons.volume_up,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Speaking...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        onPressed: provider.stopSpeaking,
                        icon: const Icon(Icons.stop),
                        iconSize: 20,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, AIAssistantProvider provider, String text) {
    if (text.trim().isEmpty) return;
    
    provider.sendTextMessage(text);
    _textController.clear();
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSuggestion(BuildContext context, String suggestion, AIAssistantProvider provider) {
    provider.sendTextMessage(suggestion);
  }

  void _handleAction(BuildContext context, AIAction action, AIAssistantProvider provider) {
    provider.executeAction(action);
  }

  void _showSettings(BuildContext context, AIAssistantProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context) => _buildSettingsSheet(context, provider),
      ),
    );
  }

  Widget _buildSettingsSheet(BuildContext context, AIAssistantProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Assistant Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Voice Enabled'),
            subtitle: const Text('Enable voice commands and responses'),
            value: provider.voiceEnabled,
            onChanged: (_) => provider.toggleVoiceEnabled(),
          ),
          
          SwitchListTile(
            title: const Text('Context Aware'),
            subtitle: const Text('Use conversation context for better responses'),
            value: provider.contextAware,
            onChanged: (_) => provider.toggleContextAware(),
          ),
          
          SwitchListTile(
            title: const Text('Proactive Suggestions'),
            subtitle: const Text('Get helpful suggestions automatically'),
            value: provider.proactiveSuggestions,
            onChanged: (_) => provider.toggleProactiveSuggestions(),
          ),
          
          const Divider(),
          
          ListTile(
            title: const Text('Speech Settings'),
            subtitle: const Text('Adjust voice speed, pitch, and volume'),
            trailing: const Icon(Icons.tune),
            onTap: () => _showSpeechSettings(context, provider),
          ),
          
          ListTile(
            title: const Text('Clear Conversation'),
            subtitle: const Text('Start a fresh conversation'),
            trailing: const Icon(Icons.clear),
            onTap: () {
              Navigator.pop(context);
              provider.clearConversation();
            },
          ),
        ],
      ),
    );
  }

  void _showSpeechSettings(BuildContext context, AIAssistantProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Speech Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speed Slider
            ListTile(
              title: const Text('Speech Speed'),
              subtitle: Slider(
                value: provider.getParameter<double>('tts_speed', 1.0),
                min: 0.5,
                max: 2.0,
                divisions: 10,
                onChanged: (value) => provider.updateTtsSettings(speed: value),
              ),
            ),
            
            // Pitch Slider
            ListTile(
              title: const Text('Speech Pitch'),
              subtitle: Slider(
                value: provider.getParameter<double>('tts_pitch', 1.0),
                min: 0.5,
                max: 2.0,
                divisions: 10,
                onChanged: (value) => provider.updateTtsSettings(pitch: value),
              ),
            ),
            
            // Volume Slider
            ListTile(
              title: const Text('Speech Volume'),
              subtitle: Slider(
                value: provider.getParameter<double>('tts_volume', 1.0),
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) => provider.updateTtsSettings(volume: value),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRecommendations(BuildContext context, AIAssistantProvider provider) async {
    final recommendations = await provider.getRecommendations();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Recommendations',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final recommendation = recommendations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(_getRecommendationIcon(recommendation.type)),
                        title: Text(recommendation.title),
                        subtitle: Text(recommendation.description),
                        trailing: Chip(
                          label: Text(_getPriorityText(recommendation.priority)),
                          backgroundColor: _getPriorityColor(recommendation.priority),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.productivity:
        return Icons.trending_up;
      case RecommendationType.task:
        return Icons.task;
      case RecommendationType.time:
        return Icons.schedule;
      case RecommendationType.health:
        return Icons.favorite;
      case RecommendationType.learning:
        return Icons.school;
    }
  }

  String _getPriorityText(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low:
        return 'Low';
      case RecommendationPriority.medium:
        return 'Medium';
      case RecommendationPriority.high:
        return 'High';
      case RecommendationPriority.critical:
        return 'Critical';
    }
  }

  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low:
        return Colors.green;
      case RecommendationPriority.medium:
        return Colors.orange;
      case RecommendationPriority.high:
        return Colors.red;
      case RecommendationPriority.critical:
        return Colors.purple;
    }
  }
}
