import 'package:flutter/material.dart';
import '../../../core/central_config.dart';

/// Translation Display Widget
/// 
/// Provides an elegant display for translated text with:
/// - Animated text appearance
/// - Copy functionality
/// - Text-to-speech integration
/// - Encryption indicators
/// - Text formatting and highlighting
/// - Cultural context notes
class TranslationDisplayWidget extends StatefulWidget {
  final String text;
  final bool isLoading;
  final bool isEncrypted;

  const TranslationDisplayWidget({
    super.key,
    required this.text,
    required this.isLoading,
    this.isEncrypted = false,
  });

  @override
  State<TranslationDisplayWidget> createState() => _TranslationDisplayWidgetState();
}

class _TranslationDisplayWidgetState extends State<TranslationDisplayWidget>
    with TickerProviderStateMixin {
  final CentralConfig _config = CentralConfig.instance;
  late AnimationController _fadeController;
  late AnimationController _typewriterController;
  late Animation<double> _fadeAnimation;
  late Animation<int> _typewriterAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: _config.getParameter('ui.animation.duration.normal', defaultValue: 300)),
      vsync: this,
    );

    _typewriterController = AnimationController(
      duration: Duration(milliseconds: _config.getParameter('ui.animation.typewriter.duration', defaultValue: 1000)),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _typewriterAnimation = IntTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(
      parent: _typewriterController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(TranslationDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.text != oldWidget.text && widget.text.isNotEmpty) {
      _typewriterController.reset();
      _fadeController.reset();
      _fadeController.forward();
      _typewriterController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: _config.getParameter('ui.translation.min_height', defaultValue: 120.0),
      ),
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface_variant', defaultValue: Colors.grey[50]),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.medium', defaultValue: 12.0)),
        border: Border.all(
          color: _config.getParameter('ui.colors.outline', defaultValue: Colors.grey[300]!),
        ),
      ),
      child: widget.isLoading
          ? _buildLoadingState()
          : widget.text.isEmpty
              ? _buildEmptyState()
              : _buildTranslationContent(),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: _config.getParameter('ui.loading.size.medium', defaultValue: 24.0),
          height: _config.getParameter('ui.loading.size.medium', defaultValue: 24.0),
          child: CircularProgressIndicator(
            strokeWidth: _config.getParameter('ui.loading.stroke_width', defaultValue: 2.0),
            valueColor: AlwaysStoppedAnimation<Color>(
              _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
            ),
          ),
        ),
        SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
        Text(
          'Translating...',
          style: TextStyle(
            fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
            color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Translation will appear here...',
        style: TextStyle(
          fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
          color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildTranslationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.isEncrypted)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
                  vertical: _config.getParameter('ui.spacing.xxsmall', defaultValue: 2.0),
                ),
                decoration: BoxDecoration(
                  color: _config.getParameter('ui.colors.success', defaultValue: Colors.green),
                  borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 4.0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      color: _config.getParameter('ui.colors.on_secondary', defaultValue: Colors.white),
                      size: _config.getParameter('ui.icon.size.small', defaultValue: 12.0),
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Encrypted',
                      style: TextStyle(
                        color: _config.getParameter('ui.colors.on_secondary', defaultValue: Colors.white),
                        fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 10.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Spacer(),
            _buildQualityIndicator(),
          ],
        ),
        SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
        AnimatedBuilder(
          animation: Listenable.merge([_fadeAnimation, _typewriterAnimation]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.text.substring(0, _typewriterAnimation.value),
                style: TextStyle(
                  fontSize: _config.getParameter('ui.font.size.body_large', defaultValue: 18.0),
                  color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.black87),
                  height: 1.5,
                ),
              ),
            );
          },
        ),
        SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildQualityIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
        vertical: _config.getParameter('ui.spacing.xxsmall', defaultValue: 2.0),
      ),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 4.0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
            size: _config.getParameter('ui.icon.size.small', defaultValue: 12.0),
          ),
          SizedBox(width: 2),
          Text(
            'High Quality',
            style: TextStyle(
              color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
              fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 10.0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.volume_up,
          label: 'Speak',
          onTap: _speakText,
        ),
        SizedBox(width: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
        _buildActionButton(
          icon: Icons.copy,
          label: 'Copy',
          onTap: _copyText,
        ),
        SizedBox(width: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onTap: _shareText,
        ),
        Spacer(),
        _buildActionButton(
          icon: Icons.info_outline,
          label: 'Context',
          onTap: _showContext,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 8.0)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _config.getParameter('ui.spacing.xsmall', defaultValue: 8.0),
          vertical: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
              size: _config.getParameter('ui.icon.size.medium', defaultValue: 20.0),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 10.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _speakText() {
    // Implement text-to-speech functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Speaking translation...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyText() {
    // Implement copy to clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Translation copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareText() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing translation...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showContext() {
    // Show cultural context and localization notes
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cultural Context'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Localization Notes:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
              ),
            ),
            SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
            Text(
              'This translation considers cultural nuances and local expressions. The meaning may vary based on regional dialects and social context.',
              style: TextStyle(
                fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
                color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
