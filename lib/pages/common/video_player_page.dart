import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart'; 
import '../../../utils/download_service.dart'; // Import du DownloadService

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
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  final DownloadService _downloadService = DownloadService(); 
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    print("VideoPlayerPage: Initializing for URL: ${widget.videoUrl}");
    // Pour le web, s'assurer que l'URL est utilisable directement par le navigateur/video_player.
    // Pour les plateformes mobiles, l'URL peut être une URL de stockage direct.
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _videoPlayerController.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: Container(
          color: Colors.black, 
          child: const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white, fontSize: 16), 
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      );
      setState(() {
        _isLoading = false;
      });
      print("VideoPlayerPage: Chewie controller initialized. Duration: ${_videoPlayerController.value.duration}");
    } catch (error) {
      if (!mounted) return;
      print("VideoPlayerPage: Error initializing video controller: $error");
      setState(() {
        _isLoading = false;
        _errorMessage = "Impossible de charger la vidéo: ${error.toString()}";
      });
    }
  }

  @override
  void dispose() {
    print("VideoPlayerPage: Disposing controllers for URL: ${widget.videoUrl}");
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _handleDownload() async {
    if (kIsWeb) { // Ne pas tenter de télécharger sur le web si le service n'est pas compatible
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le téléchargement n\'est pas disponible sur cette plateforme.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (widget.videoUrl.isEmpty) return;
    if (_isDownloading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Un téléchargement est déjà en cours.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    String filename = widget.videoUrl.split('/').last;
    if (filename.isEmpty || !filename.contains('.')) { 
      filename = "${widget.lessonTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_')}.mp4";
    }
    if (!filename.toLowerCase().endsWith('.mp4') && !filename.toLowerCase().endsWith('.mov')) {
        filename += '.mp4';
    }

    final String? filePath = await _downloadService.downloadFile(
      context: context, 
      url: widget.videoUrl,
      filename: filename,
      onReceiveProgress: (received, total) {
        print("VideoPlayerPage - Progression du téléchargement: $received / $total");
      },
    );

    if (mounted) {
        setState(() {
          _isDownloading = false;
        });
    }

    if (filePath != null) {
      print("Fichier vidéo sauvegardé: $filePath");
    } else {
      print("Échec du téléchargement de la vidéo.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), 
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20), 
        actions: [
          // Conditionnellement afficher le bouton de téléchargement
          if (!kIsWeb && widget.videoUrl.isNotEmpty) 
            _isDownloading
              ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))))
                )
              : IconButton(
                  icon: const Icon(Iconsax.document_download_copy, semanticLabel: "Télécharger la vidéo"),
                  onPressed: _handleDownload, 
                  tooltip: "Télécharger la vidéo",
                ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  SizedBox(height: 20),
                  Text('Chargement de la vidéo...', style: TextStyle(color: Colors.white)),
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
                : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                    ? Chewie(controller: _chewieController!) 
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 50),
                          SizedBox(height: 10),
                          Text(
                            'Erreur lors de l\'initialisation du lecteur vidéo.',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
      ),
    );
  }
}
