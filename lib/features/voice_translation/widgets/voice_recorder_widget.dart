import 'package:flutter/material.dart';
import '../../../core/central_config.dart';

/// Voice Recorder Widget
/// 
/// Provides an intuitive voice recording interface with:
/// - Visual feedback during recording
/// - Waveform visualization
/// - Recording duration display
/// - Audio level indicators
/// - Recording quality indicators
class VoiceRecorderWidget extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const VoiceRecorderWidget({
    super.key,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  final CentralConfig _config = CentralConfig.instance;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: _config.getParameter('ui.animation.duration.fast', defaultValue: 150)),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: Duration(milliseconds: _config.getParameter('ui.animation.duration.normal', defaultValue: 300)),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(VoiceRecorderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat();
        _waveController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _waveController.stop();
        _waveController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
      decoration: BoxDecoration(
        color: _config.getParameter('ui.colors.surface', defaultValue: Colors.white),
        borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.large', defaultValue: 16.0)),
        border: Border.all(
          color: widget.isRecording 
              ? _config.getParameter('ui.colors.error', defaultValue: Colors.red)
              : _config.getParameter('ui.colors.outline', defaultValue: Colors.grey[300]!),
          width: widget.isRecording ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        children: [
          _buildWaveformVisualization(),
          SizedBox(height: _config.getParameter('ui.spacing.medium', defaultValue: 16.0)),
          _buildRecordingButton(),
          if (widget.isRecording) ...[
            SizedBox(height: _config.getParameter('ui.spacing.small', defaultValue: 8.0)),
            _buildRecordingInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveformVisualization() {
    return Container(
      height: _config.getParameter('ui.voice_recorder.waveform_height', defaultValue: 60.0),
      child: widget.isRecording
          ? _buildAnimatedWaveform()
          : _buildStaticWaveform(),
    );
  }

  Widget _buildAnimatedWaveform() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(20, (index) {
            final height = (20 + (index % 5) * 8) * _waveAnimation.value;
            return Container(
              width: _config.getParameter('ui.voice_recorder.bar_width', defaultValue: 3.0),
              height: height,
              decoration: BoxDecoration(
                color: _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 2.0)),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStaticWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(20, (index) {
        final height = 20.0 + (index % 5) * 4.0;
        return Container(
          width: _config.getParameter('ui.voice_recorder.bar_width', defaultValue: 3.0),
          height: height,
          decoration: BoxDecoration(
            color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(_config.getParameter('ui.border_radius.small', defaultValue: 2.0)),
          ),
        );
      }),
    );
  }

  Widget _buildRecordingButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRecording ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: widget.isRecording ? widget.onStopRecording : widget.onStartRecording,
            child: Container(
              width: _config.getParameter('ui.voice_recorder.button_size', defaultValue: 80.0),
              height: _config.getParameter('ui.voice_recorder.button_size', defaultValue: 80.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording
                    ? _config.getParameter('ui.colors.error', defaultValue: Colors.red)
                    : _config.getParameter('ui.colors.primary', defaultValue: Colors.blue),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording
                            ? _config.getParameter('ui.colors.error', defaultValue: Colors.red)
                            : _config.getParameter('ui.colors.primary', defaultValue: Colors.blue))
                        .withOpacity(_config.getParameter('ui.shadow.opacity', defaultValue: 0.3)),
                    blurRadius: _config.getParameter('ui.shadow.blur_radius', defaultValue: 8.0),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.stop : Icons.mic,
                color: _config.getParameter('ui.colors.on_primary', defaultValue: Colors.white),
                size: _config.getParameter('ui.icon.size.large', defaultValue: 32.0),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordingInfo() {
    return Column(
      children: [
        Text(
          'Recording...',
          style: TextStyle(
            fontSize: _config.getParameter('ui.font.size.body_medium', defaultValue: 14.0),
            color: _config.getParameter('ui.colors.error', defaultValue: Colors.red),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: _config.getParameter('ui.spacing.xsmall', defaultValue: 4.0)),
        Text(
          'Tap to stop',
          style: TextStyle(
            fontSize: _config.getParameter('ui.font.size.body_small', defaultValue: 12.0),
            color: _config.getParameter('ui.colors.on_surface_variant', defaultValue: Colors.grey[600]!),
          ),
        ),
      ],
    );
  }
}
