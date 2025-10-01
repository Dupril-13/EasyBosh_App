import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class CompactAudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String lessonTitle;

  const CompactAudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    required this.lessonTitle,
  }) : super(key: key);

  @override
  _CompactAudioPlayerWidgetState createState() => _CompactAudioPlayerWidgetState();
}

class _CompactAudioPlayerWidgetState extends State<CompactAudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  PlayerState _playerState = PlayerState.stopped;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Set loading true at the beginning of init
      _errorMessage = null;
    });
    try {
      await _audioPlayer.setSourceUrl(widget.audioUrl);

      _audioPlayer.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      _audioPlayer.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _audioPlayer.onPlayerStateChanged.listen((s) {
        if (mounted) {
          setState(() {
            _playerState = s;
            _isPlaying = s == PlayerState.playing;
            if (s == PlayerState.completed) {
              _position = Duration.zero; // Reset position on completion for UI
               _isPlaying = false; // Ensure play icon resets
            }
          });
        }
      });
       _audioPlayer.onPlayerComplete.listen((event) { // Handles actual completion
         if (mounted) {
            setState(() {
              _playerState = PlayerState.completed;
              _isPlaying = false;
              _position = _duration; // Show full progress
            });
         }
      });


      final initialDuration = await _audioPlayer.getDuration();
      if (mounted) {
        setState(() {
          _duration = initialDuration ?? Duration.zero;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erreur chargement audio";
        });
        print("CompactAudioPlayer Error: ${e.toString()}");
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.release(); // More complete cleanup
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (!mounted) return;
    try {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else if (_playerState == PlayerState.paused) {
        await _audioPlayer.resume();
      } else if (_playerState == PlayerState.completed) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.resume();
      } else { // Stopped or initial
        await _audioPlayer.play(UrlSource(widget.audioUrl));
      }
    } catch (e) {
       print("CompactAudioPlayer _playPause Error: ${e.toString()}");
       if(mounted) {
         setState(() {
           _errorMessage = "Erreur de lecture";
         });
       }
    }
  }

  String _formatDuration(Duration d) {
    if (d.inMilliseconds < 0) d = Duration.zero; // Sanitize negative durations
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text("Audio en chargement...", style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
            IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _initAudioPlayer, tooltip: "Réessayer",)
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      margin: const EdgeInsets.only(top: 8.0), // Space from lesson content
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.lessonTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13, // Slightly smaller for compact view
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8)
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                iconSize: 36.0,
                onPressed: _playPause,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 24.0,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_position),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary.withOpacity(0.9)),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                    activeTrackColor: Theme.of(context).primaryColor,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: Theme.of(context).primaryColor,
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                    value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                    onChanged: (value) async {
                      if (!_isLoading) { // Prevent seek while still loading/error
                        final newPosition = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(newPosition);
                        // If paused, and user scrubs, it might be good to stay paused or auto-play.
                        // For now, it will update position. If user presses play, it resumes.
                      }
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(_duration),
                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
