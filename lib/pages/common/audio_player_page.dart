import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; // url_launcher n'est plus utilisé directement ici pour le téléchargement
import 'package:iconsax_flutter/iconsax_flutter.dart'; 
import '../../../utils/download_service.dart'; // Import du DownloadService

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
  final DownloadService _downloadService = DownloadService(); // Instance du service
  bool _isDownloading = false;

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
      _audioPlayer.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      _audioPlayer.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _audioPlayer.onPlayerStateChanged.listen((s) {
        if (mounted) {
          setState(() => _playerState = s);
          _isPlaying = s == PlayerState.playing;
          if (s == PlayerState.completed) {
            _position = _duration; 
          }
        }
        print("AudioPlayerPage: Player state changed to: $s");
      });
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
      }
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
    } else { 
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> _handleDownload() async {
    if (widget.audioUrl.isEmpty) return;
     if (_isDownloading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Un téléchargement est déjà en cours.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    String filename = widget.audioUrl.split('/').last;
    if (filename.isEmpty || !filename.contains('.')) {
      filename = "${widget.lessonTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_')}.mp3";
    }
    if (!filename.toLowerCase().endsWith('.mp3') && 
        !filename.toLowerCase().endsWith('.m4a') && 
        !filename.toLowerCase().endsWith('.wav') && 
        !filename.toLowerCase().endsWith('.aac')) {
        filename += '.mp3'; // Default to mp3 if common audio extension is missing
    }

    final String? filePath = await _downloadService.downloadFile(
      context: context,
      url: widget.audioUrl,
      filename: filename,
      onReceiveProgress: (received, total) {
        print("AudioPlayerPage - Progression du téléchargement: $received / $total");
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
    }

    if (filePath != null) {
      print("Fichier audio sauvegardé: $filePath");
    } else {
      print("Échec du téléchargement de l'audio.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        actions: [
          if (widget.audioUrl.isNotEmpty)
            _isDownloading
              ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                )
              : IconButton(
                  icon: const Icon(Iconsax.document_download_copy, semanticLabel: "Télécharger l'audio"), 
                  onPressed: _handleDownload, // Appelle la nouvelle fonction de téléchargement
                  tooltip: "Télécharger l'audio",
                ),
        ],
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
                              Text(_formatDuration(_duration - _position)), 
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
