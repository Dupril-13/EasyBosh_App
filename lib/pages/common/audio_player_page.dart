import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerPage extends StatefulWidget {
  final String audioUrl;
  final String lessonTitle;

  const AudioPlayerPage({
    Key? key,
    required this.audioUrl,
    required this.lessonTitle,
  }) : super(key: key);

  @override
  _AudioPlayerPageState createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
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
    print("AudioPlayerPage: Initializing for URL: ${widget.audioUrl}");
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    if (!mounted) return;
    try {
      await _audioPlayer.setSourceUrl(widget.audioUrl);
      // Listener for duration changes
      _audioPlayer.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      // Listener for position changes
      _audioPlayer.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      // Listener for player state changes
      _audioPlayer.onPlayerStateChanged.listen((s) {
        if (mounted) {
          setState(() => _playerState = s);
          _isPlaying = s == PlayerState.playing;
          if (s == PlayerState.completed) {
            _position = _duration; // Mark as completed
          }
        }
        print("AudioPlayerPage: Player state changed to: $s");
      });
      // Listener for errors
      _audioPlayer.onPlayerComplete.listen((event) {
         if (mounted) {
            setState(() {
              _playerState = PlayerState.completed;
              _isPlaying = false;
              _position = _duration;
            });
         }
         print("AudioPlayerPage: Playback completed.");
      });

      final initialDuration = await _audioPlayer.getDuration();
      if (mounted) {
        setState(() {
          _duration = initialDuration ?? Duration.zero;
          _isLoading = false;
        });
      } // Removed comma here
      print("AudioPlayerPage: AudioPlayer initialized. Initial duration: $initialDuration");
    } catch (e) {
      print("AudioPlayerPage: Error initializing audio player: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Impossible de charger l'audio: ${e.toString()}";
        });
      }
    }
  }

  @override
  void dispose() {
    print("AudioPlayerPage: Disposing player for URL: ${widget.audioUrl}");
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (!mounted) return;
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_playerState == PlayerState.paused) {
      await _audioPlayer.resume();
    } else if (_playerState == PlayerState.completed) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.resume();
    } else { // Stopped or initial state
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
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
                  Text('Chargement de l\'audio...'),
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
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.audiotrack, size: 100, color: Colors.blueAccent),
                        const SizedBox(height: 20),
                        Text(
                          widget.lessonTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        Slider(
                          min: 0,
                          max: _duration.inSeconds.toDouble(),
                          value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                          onChanged: (value) async {
                            final newPosition = Duration(seconds: value.toInt());
                            await _audioPlayer.seek(newPosition);
                             // Optionally resume playback if it was paused due to seek
                            if (!_isPlaying && _playerState == PlayerState.paused) {
                              await _audioPlayer.resume();
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_position)),
                              Text(_formatDuration(_duration - _position)), // Remaining time
                              // Text(_formatDuration(_duration)), // Total time
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                          iconSize: 64.0,
                          onPressed: _playPause,
                        ),
                        const SizedBox(height: 10),
                         Text(_playerState.toString().split('.').last.toUpperCase(), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
      ),
    );
  }
}
