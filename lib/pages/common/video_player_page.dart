import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String lessonTitle;

  const VideoPlayerPage({
    Key? key,
    required this.videoUrl,
    required this.lessonTitle,
  }) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print("VideoPlayerPage: Initializing for URL: ${widget.videoUrl}");
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          // Auto-play or let user start? For now, let user start.
          // _controller.play();
          // _isPlaying = true;
        });
        print("VideoPlayerPage: Controller initialized. Duration: ${_controller.value.duration}");
      }).catchError((error) {
        if (!mounted) return;
        print("VideoPlayerPage: Error initializing video controller: $error");
        setState(() {
          _isLoading = false;
          _errorMessage = "Impossible de charger la vidéo: ${error.toString()}";
        });
      });

    _controller.addListener(() {
      if (!mounted) return;
      if (_isPlaying != _controller.value.isPlaying) {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      }
    });
  }

  @override
  void dispose() {
    print("VideoPlayerPage: Disposing controller for URL: ${widget.videoUrl}");
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!mounted) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        // If at the end, restart
        if (_controller.value.position >= _controller.value.duration) {
          _controller.seekTo(Duration.zero);
        }
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Chargement de la vidéo...'),
                ],
              )
            : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: <Widget>[
                            VideoPlayer(_controller),
                            _ControlsOverlay(controller: _controller, togglePlayPause: _togglePlayPause),
                            VideoProgressIndicator(_controller, allowScrubbing: true),
                          ],
                        ),
                      )
                    : const Text('Initialisation du lecteur vidéo...'),
      ),
      floatingActionButton: _controller.value.isInitialized && _errorMessage == null && !_isLoading
          ? FloatingActionButton(
              onPressed: _togglePlayPause,
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({Key? key, required this.controller, required this.togglePlayPause}) : super(key: key);

  final VideoPlayerController controller;
  final VoidCallback togglePlayPause;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: togglePlayPause,
        ),
      ],
    );
  }
}
