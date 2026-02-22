import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/central_config.dart';

/// Media Player Screen for streaming videos and playing audio
class MediaPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> mediaFile;

  const MediaPlayerScreen({Key? key, required this.mediaFile}) : super(key: key);

  @override
  State<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isVideo = false;
  bool _isPlaying = false;
  bool _isInitialized = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  final CentralConfig _config = CentralConfig.instance;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initializeMedia() async {
    final fileName = widget.mediaFile['name'] as String;
    final extension = fileName.split('.').last.toLowerCase();

    // Determine if it's video or audio
    final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv'];
    final audioExtensions = ['mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'];

    if (videoExtensions.contains(extension)) {
      _isVideo = true;
      await _initializeVideo();
    } else if (audioExtensions.contains(extension)) {
      _isVideo = false;
      await _initializeAudio();
    } else {
      // Unsupported format
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unsupported media format')),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isInitialized = true);
  }

  Future<void> _initializeVideo() async {
    // For demo, we'll use a network URL or asset
    // In real app, this would load from file path
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
    );

    await _videoController!.initialize();
    _videoController!.addListener(_videoListener);

    setState(() {
      _duration = _videoController!.value.duration;
    });
  }

  Future<void> _initializeAudio() async {
    _audioPlayer = AudioPlayer();

    // For demo, use a sample audio URL
    // In real app, load from file path
    await _audioPlayer!.setUrl(
      'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
    );

    _audioPlayer!.positionStream.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer!.durationStream.listen((duration) {
      setState(() => _duration = duration ?? Duration.zero);
    });

    _audioPlayer!.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });
  }

  void _videoListener() {
    if (_videoController != null) {
      setState(() {
        _position = _videoController!.value.position;
        _isPlaying = _videoController!.value.isPlaying;
      });
    }
  }

  void _playPause() {
    if (_isVideo) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    } else {
      if (_isPlaying) {
        _audioPlayer!.pause();
      } else {
        _audioPlayer!.play();
      }
    }
  }

  void _seekTo(Duration position) {
    if (_isVideo) {
      _videoController!.seekTo(position);
    } else {
      _audioPlayer!.seek(position);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Media Player'),
          backgroundColor: _config.primaryColor,
          foregroundColor: _config.surfaceColor,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mediaFile['name']),
        backgroundColor: _config.primaryColor,
        foregroundColor: _config.surfaceColor,
        elevation: _config.cardElevation,
      ),
      body: Column(
        children: [
          // Media display area
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: _isVideo
                    ? _buildVideoPlayer()
                    : _buildAudioPlayer(),
              ),
            ),
          ),

          // Controls
          _buildMediaControls(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null) return const SizedBox();

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 100,
            color: _config.primaryColor,
          ),
          const SizedBox(height: 20),
          Text(
            widget.mediaFile['name'],
            style: TextStyle(
              color: _config.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Audio File',
            style: TextStyle(
              color: _config.primaryColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _config.surfaceColor,
        border: Border(
          top: BorderSide(
            color: _config.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Progress bar
          Slider(
            value: _position.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble(),
            onChanged: (value) {
              _seekTo(Duration(seconds: value.toInt()));
            },
            activeColor: _config.primaryColor,
          ),

          // Time display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(
                    color: _config.primaryColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(
                    color: _config.primaryColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 48,
                ),
                onPressed: _playPause,
                color: _config.primaryColor,
              ),
              const SizedBox(width: 32),
              IconButton(
                icon: const Icon(Icons.replay_10, size: 32),
                onPressed: () {
                  final newPosition = _position - const Duration(seconds: 10);
                  _seekTo(newPosition.isNegative ? Duration.zero : newPosition);
                },
                color: _config.primaryColor,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10, size: 32),
                onPressed: () {
                  final newPosition = _position + const Duration(seconds: 10);
                  _seekTo(newPosition > _duration ? _duration : newPosition);
                },
                color: _config.primaryColor,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Additional controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  // Volume control (simplified)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Volume control not implemented')),
                  );
                },
                color: _config.primaryColor,
              ),
              const SizedBox(width: 32),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () {
                  // Fullscreen toggle (for video)
                  if (_isVideo) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fullscreen mode not implemented')),
                    );
                  }
                },
                color: _config.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
