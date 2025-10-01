import 'dart:async';
import 'dart:typed_data'; // Ajout pour Uint8List (PDF)
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/providers/lecon_provider.dart';
import 'package:easybosh_v2/providers/chapitre_provider.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
import '../../../widgets/common/compact_audio_player.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; 
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:webview_flutter/webview_flutter.dart';


class LeconPreviewPage extends ConsumerStatefulWidget {
  final LeconModel lecon;

  const LeconPreviewPage({Key? key, required this.lecon}) : super(key: key);

  @override
  _LeconPreviewPageState createState() => _LeconPreviewPageState();
}

class _LeconPreviewPageState extends ConsumerState<LeconPreviewPage> {
  VideoPlayerController? _videoController;
  bool _isDisposed = false;
  
  WebViewController? _webViewController;

  Uint8List? _pdfPreviewBytes;
  bool _isLoadingPdfPreview = false;
  String? _pdfPreviewError;
  Key _pdfViewerKey = UniqueKey(); 

  @override
  void initState() {
    super.initState();
    if (widget.lecon.type == 'video' && widget.lecon.urlMedia != null && widget.lecon.urlMedia!.isNotEmpty) {
      _initializeVideoPlayer(widget.lecon.urlMedia!);
    }
    
    if (widget.lecon.type == 'pdf' && widget.lecon.urlMedia != null && widget.lecon.urlMedia!.isNotEmpty) {
      final isHttpUrl = widget.lecon.urlMedia!.toLowerCase().startsWith('http');
      print("DEBUG initState: LeconType: ${widget.lecon.type}, PDF URL: ${widget.lecon.urlMedia}");
      print("DEBUG initState: Platform checks: kIsWeb=$kIsWeb, Platform.isAndroid=${Platform.isAndroid}, Platform.isIOS=${Platform.isIOS}, Platform.isWindows=${Platform.isWindows}");

      if (kIsWeb && isHttpUrl) {
        print("DEBUG initState: Initializing WebView for Web.");
        _initializeWebViewForPdfOnWeb(widget.lecon.urlMedia!); 
      } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        print("DEBUG initState: Loading PDF preview for Android/iOS.");
        _loadPdfPreviewFromUrl(widget.lecon.urlMedia!);
      } else if (!kIsWeb && Platform.isWindows) {
        print("DEBUG initState: Detected Windows. No direct PDF load/preview initialization here. Fallback will be handled by _buildContentViewer.");
      } else {
        print("DEBUG initState: PDF - No specific platform action for PDF in initState. isHttpUrl=$isHttpUrl");
      }
    }
  }

  Future<void> _initializeWebViewForPdfOnWeb(String pdfUrl) async {
    if (!mounted || _isDisposed) return;
    final WebViewController controller = WebViewController();

    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {},
        onPageStarted: (String url) {
          print("WebView (PDF Direct): Page commencée à charger: $url");
        },
        onPageFinished: (String url) {
          print("WebView (PDF Direct): Page finie de charger: $url");
           if (mounted && !_isDisposed) {
            setState(() {
              _pdfPreviewError = null; 
            });
          }
        },
        onWebResourceError: (WebResourceError error) {
          print("WebView (PDF Direct) Erreur de ressource: ${error.description}, URL: ${error.url}, ErrorType: ${error.errorType}");
          if (mounted && !_isDisposed) {
            setState(() {
              if (error.url == pdfUrl || error.url == Uri.encodeComponent(pdfUrl)) {
                 _pdfPreviewError = "Erreur chargement PDF: ${error.description}";
              } else {
                 _pdfPreviewError = "Erreur WebView: ${error.description}";
              }
            });
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
      ),
    );
    
    print("WebView (PDF Direct): Tentative de chargement direct de l'URL PDF: $pdfUrl");

    try {
      await controller.loadRequest(Uri.parse(pdfUrl));
      if (mounted && !_isDisposed) {
        setState(() {
          _webViewController = controller;
        });
      }
    } catch (e) {
      print("Exception pendant le chargement direct du PDF dans WebView: $e");
      if (mounted && !_isDisposed) {
        setState(() {
          _pdfPreviewError = "Exception WebView: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    if (!mounted || _isDisposed) return;
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _videoController!.initialize();
      if (mounted && !_isDisposed) {
        setState(() {});
      }
    } catch (e) {
      print("Erreur d'initialisation du lecteur vidéo dans LeconPreviewPage: $e");
      if (mounted && !_isDisposed && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de chargement de la vidéo: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadPdfPreviewFromUrl(String url) async {
    if (!mounted || _isDisposed) return;
    if (!url.toLowerCase().startsWith('http')) {
      if (mounted && !_isDisposed) {
        setState(() {
          _pdfPreviewError = "URL invalide pour le chargement des bytes (doit commencer par http ou https).";
          _isLoadingPdfPreview = false;
        });
      }
      return;
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _isLoadingPdfPreview = true;
        _pdfPreviewError = null;
        _pdfPreviewBytes = null;
        _pdfViewerKey = UniqueKey(); 
      });
    }

    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (mounted && !_isDisposed) {
        setState(() {
          _pdfPreviewBytes = Uint8List.fromList(response.data!);
          _isLoadingPdfPreview = false;
        });
      }
    } catch (e) {
      print("Erreur de chargement de l'aperçu PDF depuis URL (LeconPreviewPage): $e");
      if (mounted && !_isDisposed) {
        setState(() {
          _pdfPreviewError = "Erreur chargement PDF: ${e.toString().substring(0, e.toString().length > 50 ? 50 : e.toString().length)}...";
          _isLoadingPdfPreview = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildInfoDetailRow(BuildContext context, String label, String? value, {bool isSelectable = false, bool isHeader = false, bool isMarkdown = false}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 2),
          isSelectable
              ? SelectableText(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue, decoration: TextDecoration.underline))
              : (isHeader ? const SizedBox.shrink() : Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

   Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted && !_isDisposed && context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Impossible d'ouvrir l'URL: $url"), backgroundColor: Colors.red),
          );
      }
    }
  }

  Widget _buildInfoColumn(BuildContext context) {
    final lecon = widget.lecon;
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lecon.nom, 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            _buildInfoDetailRow(context, 'Type:', lecon.type.toUpperCase()),
            _buildInfoDetailRow(context, 'Statut:', lecon.actif ? 'Actif (Visible)' : 'Inactif (Masqué)'),
            _buildInfoDetailRow(context, 'Durée estimée:', lecon.dureeEstimee != null ? "${lecon.dureeEstimee} minutes" : 'Non définie'),
            _buildInfoDetailRow(context, 'Description:', lecon.description?.isNotEmpty == true ? lecon.description : 'Non définie', isMarkdown: true), 
            const SizedBox(height: 8),
            _buildInfoDetailRow(context, 'URL Média:', lecon.urlMedia ?? 'Non défini', isSelectable: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContentArea(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey.shade50, 
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.5), 
        child: _buildContentViewer(widget.lecon, context),
      ),
    );
  }

  Widget _buildPdfFallback(String pdfUrl, String errorMessage, String actionMessage, bool isHttpUrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(isHttpUrl ? Icons.open_in_new : Icons.launch ), 
              label: Text(actionMessage),
              onPressed: () => _launchURL(pdfUrl),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondaryContainer),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildContentViewer(LeconModel lecon, BuildContext context) {
    final String? mediaUrl = lecon.urlMedia; // Renommé pour plus de clarté
    // Log initial pour le débogage
    print("DEBUG: _buildContentViewer CALLED. LeconType: ${lecon.type}, Media URL: $mediaUrl");
    print("DEBUG: Platform checks: kIsWeb=$kIsWeb, Platform.isAndroid=${Platform.isAndroid}, Platform.isIOS=${Platform.isIOS}, Platform.isWindows=${Platform.isWindows}");

    switch (lecon.type) {
      case 'video':
        if (mediaUrl == null || mediaUrl.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("Vidéo non disponible ou URL manquante.")));
        }
        Widget videoPlayerWidget;
        if (_videoController != null && _videoController!.value.isInitialized) {
          videoPlayerWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min, // Important pour Column dans un Expanded
            children: [
              Expanded( // Pour que VideoPlayer prenne la place disponible
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              VideoProgressIndicator(_videoController!, allowScrubbing: true),
              IconButton(
                icon: Icon(_videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 32, color: Theme.of(context).colorScheme.primary),
                onPressed: () => setState(() {
                  _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                }),
              ),
            ],
          );
        } else {
          videoPlayerWidget = const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(semanticsLabel: "Chargement de la vidéo...")));
        }
        
        return Container( // Assure que le Column ne dépasse pas les contraintes
          constraints: const BoxConstraints(maxHeight: 450.0), 
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              Expanded(child: videoPlayerWidget), // Le lecteur vidéo
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.download_for_offline_outlined),
                label: const Text("Télécharger la vidéo"),
                onPressed: () => _launchURL(mediaUrl),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.tertiaryContainer),
              ),
            ],
          ),
        );

      case 'pdf':
        final String? pdfUrl = mediaUrl; // alias pour la clarté dans cette section
        print("DEBUG: PDF case entered.");
        if (pdfUrl == null || pdfUrl.isEmpty) {
          print("DEBUG: PDF Url is null or empty. Returning fallback.");
          return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("PDF non disponible ou URL manquante.")));
        }
        final bool isHttpUrl = pdfUrl.toLowerCase().startsWith('http');
        print("DEBUG: PDF isHttpUrl=$isHttpUrl");

        if (kIsWeb && isHttpUrl) {
          print("DEBUG: PDF branch for kIsWeb. Initializing WebView.");
          if (_webViewController != null) {
            return WebViewWidget(controller: _webViewController!); 
          }
          if (_pdfPreviewError != null) { 
             return _buildPdfFallback(pdfUrl, "Erreur d'affichage du PDF avec WebView:\n$_pdfPreviewError", "Ouvrir le PDF externe", true);
          }
          return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 8), Text("Chargement du PDF (Web)...")])) );
        }
        
        print("DEBUG: PDF - Checking non-Web platforms. !kIsWeb=${!kIsWeb}");
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
            print("DEBUG: PDF - Android/iOS branch entered. Android=${Platform.isAndroid}, iOS=${Platform.isIOS}");
            if (_isLoadingPdfPreview) {
              print("DEBUG: PDF - Android/iOS: isLoadingPdfPreview = true");
              return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 8), Text("Chargement PDF (Mobile)...")])));
            } else if (_pdfPreviewError != null) {
              print("DEBUG: PDF - Android/iOS: _pdfPreviewError is not null: $_pdfPreviewError");
              return _buildPdfFallback(pdfUrl, "Erreur chargement PDF natif: $_pdfPreviewError", "Réessayer d'ouvrir externe", isHttpUrl);
            } else if (_pdfPreviewBytes != null) {
              print("DEBUG: PDF - Android/iOS: _pdfPreviewBytes is not null. ATTEMPTING TO BUILD PDFView.");
              return PDFView(
                key: _pdfViewerKey,
                pdfData: _pdfPreviewBytes!,
                enableSwipe: true, swipeHorizontal: false, autoSpacing: false,
                pageFling: true, pageSnap: true, fitPolicy: FitPolicy.BOTH,
                preventLinkNavigation: false,
                 onError: (error) {
                  print("DEBUG: PDFView onError: $error");
                  if (mounted && !_isDisposed) setState(() => _pdfPreviewError = error.toString());
                },
                onPageError: (page, error) {
                  print("DEBUG: PDFView onPageError: page $page, error $error");
                  if (mounted && !_isDisposed) setState(() => _pdfPreviewError = 'Erreur page $page: ${error.toString()}');
                },
              );
            } else if (!isHttpUrl) {
                print("DEBUG: PDF - Android/iOS: URL non-HTTP pour chargement direct.");
                return _buildPdfFallback(pdfUrl, "URL non HTTP, ne peut être chargée pour aperçu direct sur mobile.", "Tenter d'ouvrir", false);
            } else {
              print("DEBUG: PDF - Android/iOS: Fallback - Préparation de l'aperçu PDF pour mobile...");
              return _buildPdfFallback(pdfUrl, "Impossible de charger l'aperçu PDF. Vérifiez l'URL et la connexion.", "Tenter d'ouvrir externe", isHttpUrl);
            }
        }

        print("DEBUG: PDF - Checking Windows branch. !kIsWeb=${!kIsWeb}, Platform.isWindows=${Platform.isWindows}");
        if (!kIsWeb && Platform.isWindows) {
             print("DEBUG: PDF - Windows branch entered. Returning _buildPdfFallback.");
             return _buildPdfFallback(pdfUrl, 
                "L'aperçu PDF intégré n'est pas directement supporté sur Windows Desktop.\nUtilisez le bouton ci-dessous pour ouvrir le fichier.", 
                "Ouvrir avec l'application par défaut", 
                isHttpUrl);
        }
        
        print("DEBUG: PDF - Final fallback branch entered. _pdfPreviewError: $_pdfPreviewError");
        return _buildPdfFallback(pdfUrl, 
            _pdfPreviewError ?? "Configuration non supportée pour l'affichage PDF intégré (Fallback final).", 
            "Tenter d'ouvrir le PDF", isHttpUrl);

      case 'audio':
        if (mediaUrl == null || mediaUrl.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("Audio non disponible ou URL manquante.")));
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column( // Enveloppe dans une Column pour ajouter le bouton en dessous
            mainAxisSize: MainAxisSize.min,
            children: [
              CompactAudioPlayerWidget(
                audioUrl: mediaUrl,
                lessonTitle: lecon.nom,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.download_for_offline_outlined),
                label: const Text("Télécharger l'audio"),
                onPressed: () => _launchURL(mediaUrl),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.tertiaryContainer),
              ),
            ],
          ),
        );
      
      default:
        print("DEBUG: Default case in switch. Type: ${lecon.type}");
        return Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("Type de contenu '${lecon.type}' non supporté pour l'aperçu.")));
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lecon.nom, overflow: TextOverflow.ellipsis),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant, 
        elevation: 1,
      ),
      body: SafeArea( 
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1, 
                child: _buildInfoColumn(context),
              ),
              const SizedBox(width: 16.0), 
              Expanded(
                flex: 2, 
                child: _buildMediaContentArea(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Le reste de la page ManageLeconsPage (liste des leçons, etc.) reste inchangé.

class ManageLeconsPage extends ConsumerStatefulWidget {
  final int chapitreId;
  final VoidCallback onBackToChapitres;
  final VoidCallback? onAddLecon;
  final Function(LeconModel lecon)? onEditLecon;

  const ManageLeconsPage({
    super.key,
    required this.chapitreId,
    required this.onBackToChapitres,
    this.onAddLecon,
    this.onEditLecon,
  });

  @override
  ConsumerState<ManageLeconsPage> createState() => _ManageLeconsPageState();
}

class _ManageLeconsPageState extends ConsumerState<ManageLeconsPage> {
  String _selectedLeconType = 'pdf';
  final List<String> _chipTypes = ['pdf', 'video', 'audio'];
  Map<String, int> _lessonsCountsPerType = {};
  List<LeconModel> _leconsAffichees = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataAndProcessLecons();
    });
  }

  @override
  void didUpdateWidget(covariant ManageLeconsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapitreId != widget.chapitreId) {
      setState(() {
        _selectedLeconType = _chipTypes.isNotEmpty ? _chipTypes.first : 'pdf';
        _lessonsCountsPerType = {};
        _leconsAffichees = [];
      });
      _fetchDataAndProcessLecons();
    }
  }

  Future<void> _fetchDataAndProcessLecons() async {
    if (!mounted) return;
    await ref.read(leconProvider.notifier).fetchLecons(chapitreId: widget.chapitreId);
    if (mounted) {
      _processLecons();
    }
  }

  void _processLecons() {
    if (!mounted) return;
    final leconState = ref.read(leconProvider);
    final allLeconsForChapter = List<LeconModel>.from(leconState.lecons.where((l) => l.chapitreId == widget.chapitreId));

    Map<String, int> counts = {};
    for (String type in _chipTypes) {
      counts[type] = allLeconsForChapter.where((lecon) => lecon.type.toLowerCase() == type).length;
    }

    if (_chipTypes.isNotEmpty) {
      if (!counts.containsKey(_selectedLeconType) || (counts[_selectedLeconType] ?? 0) == 0 ){
          _selectedLeconType = _chipTypes.firstWhere((t) => (counts[t] ?? 0) > 0, orElse: () => _chipTypes.first);
      }
    } else {
      _selectedLeconType = 'pdf'; 
    }
    
    List<LeconModel> filtered = allLeconsForChapter
        .where((lecon) => lecon.type.toLowerCase() == _selectedLeconType)
        .toList();

    filtered.sort((a, b) {
      final orderA = a.ordreParType?[_selectedLeconType] ?? a.ordre;
      final orderB = b.ordreParType?[_selectedLeconType] ?? b.ordre;
      return orderA.compareTo(orderB);
    });


    if (mounted) {
      setState(() {
        _lessonsCountsPerType = counts;
        _leconsAffichees = filtered;
      });
    }
  }

  void _navigateToLeconPreview(LeconModel lecon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeconPreviewPage(lecon: lecon),
      ),
    );
  }

  Widget _buildAddLessonButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: widget.onAddLecon,
      icon: const Icon(Icons.add),
      label: const Text('Ajouter Leçon'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_chipTypes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: _chipTypes.map((type) {
          final bool isEnabled = (_lessonsCountsPerType[type] ?? 0) > 0;
          final bool isSelected = _selectedLeconType == type;
          return ChoiceChip(
            label: Text("${type.replaceAll('_', ' ').toUpperCase()} (${_lessonsCountsPerType[type] ?? 0})"),
            selected: isSelected,
            backgroundColor: Colors.grey[200],
            selectedColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : (isEnabled ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[500]),
            ),
            shape: StadiumBorder(side: BorderSide(color: Colors.grey[300]!)),
            showCheckmark: false,
            onSelected: (isEnabled || _lessonsCountsPerType.values.every((c) => c == 0))
                ? (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedLeconType = type;
                      });
                      _processLecons(); 
                    }
                  }
                : null,
            disabledColor: Colors.grey[300]?.withOpacity(0.5),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leconState = ref.watch(leconProvider);
    final matiereState = ref.watch(matiereProvider);
    final chapitreGlobalState = ref.watch(chapitreProvider);

    ref.listen(leconProvider.select((s) => s.lecons), (previous, next) {
      if (mounted && next.any((l) => l.chapitreId == widget.chapitreId)) { 
        _processLecons();
      }
    });

    ChapitreModel? currentChapitre;
    MatiereModel? currentMatiere;
    try {
      currentChapitre = chapitreGlobalState.chapitres.firstWhere((ch) => ch.id == widget.chapitreId);
    } catch (e) {
      if (chapitreGlobalState.chapitrePourEdition?.id == widget.chapitreId) {
        currentChapitre = chapitreGlobalState.chapitrePourEdition;
      }
    }
    if (currentChapitre != null && currentChapitre.matiereId != null && matiereState.matieres.isNotEmpty) {
      try {
        currentMatiere = matiereState.matieres.firstWhere((m) => m.id == currentChapitre!.matiereId);
      } catch (e) { }
    }

    Widget content;
    if (leconState.isLoading && _leconsAffichees.isEmpty && _lessonsCountsPerType.isEmpty) {
      content = const Center(child: CircularProgressIndicator(semanticsLabel: "Chargement des leçons..."));
    } else if (leconState.errorMessage != null && _leconsAffichees.isEmpty && (_lessonsCountsPerType.isEmpty || _lessonsCountsPerType.values.every((c) => c == 0))) {
      content = Center(child: Text(leconState.errorMessage!, style: const TextStyle(color: Colors.red)));
    } else if (_chipTypes.isNotEmpty && (_lessonsCountsPerType[_selectedLeconType] ?? 0) == 0 && _chipTypes.contains(_selectedLeconType) && !leconState.isLoading && _lessonsCountsPerType.values.any((c) => c > 0) ) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucune leçon de type "${_selectedLeconType.replaceAll('_', ' ').toUpperCase()}" trouvée pour ce chapitre.',
              style: const TextStyle(fontSize: 18), textAlign: TextAlign.center,
            ),
             Text(
              'Essayez un autre type de média ci-dessus.',
              style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center,
            ),
            if (widget.onAddLecon != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: const Text('Ou vous pouvez en ajouter une nouvelle.', textAlign: TextAlign.center),
              ),
          ],
        ),
      );
    } else if (_leconsAffichees.isEmpty && !leconState.isLoading) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              currentChapitre != null
                  ? 'Aucune leçon à afficher pour le chapitre "${currentChapitre.nom}".'
                  : 'Aucune leçon à afficher pour ce chapitre.',
              style: const TextStyle(fontSize: 18), textAlign: TextAlign.center,
            ),
            if (widget.onAddLecon != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: const Text('Appuyez sur le bouton ci-dessus pour ajouter votre première leçon.', textAlign: TextAlign.center),
              ),
          ],
        ),
      );
    } else {
      content = ReorderableListView.builder(
        buildDefaultDragHandles: false, 
        itemCount: _leconsAffichees.length,
        itemBuilder: (context, index) {
          final lecon = _leconsAffichees[index];
          return Card(
            key: ValueKey("${_selectedLeconType}_${lecon.id}_${lecon.ordreParType?[_selectedLeconType] ?? lecon.ordre}"),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8.0, left:4.0), 
                      child: Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                  ),
                  CircleAvatar(
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    radius: 16,
                  ),
                ],
              ),
              title: Text(lecon.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '''Type: ${lecon.type.replaceAll('_', ' ').toUpperCase()}${lecon.dureeEstimee != null ? ' - ${lecon.dureeEstimee} min' : ''}
${lecon.description?.isNotEmpty == true ? lecon.description! : 'Pas de description'}''',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                      tooltip: "Modifier cette leçon",
                      onPressed: () => widget.onEditLecon?.call(lecon)),
                  IconButton(
                      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                      tooltip: "Supprimer cette leçon",
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) => AlertDialog(
                                  title: const Text('Confirmer suppression'),
                                  content: Text('Supprimer la leçon "${lecon.nom}"? Cette action est irréversible.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
                                    TextButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(true),
                                        child: Text('Supprimer', style: TextStyle(color: Theme.of(context).colorScheme.error)))
                                  ],
                                ));
                        if (confirm == true) {
                          final success = await ref.read(leconProvider.notifier).deleteLecon(lecon.id);
                          if (mounted && success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${lecon.nom}" supprimé.'), backgroundColor: Colors.green,));
                          } else if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Erreur: ${ref.read(leconProvider).errorMessage ?? "Erreur lors de la suppression"}'), backgroundColor: Colors.red,));
                          }
                        }
                      }),
                ],
              ),
              onTap: () => _navigateToLeconPreview(lecon),
            ),
          );
        },
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final LeconModel itemMoved = _leconsAffichees.removeAt(oldIndex);
            _leconsAffichees.insert(newIndex, itemMoved);

            List<Future<void>> updateFutures = [];
            for (int i = 0; i < _leconsAffichees.length; i++) {
              LeconModel currentLecon = _leconsAffichees[i];
              Map<String, int> updatedOrdreParType = Map.from(currentLecon.ordreParType ?? {});
              updatedOrdreParType[_selectedLeconType] = i + 1; 
              updateFutures.add(ref.read(leconProvider.notifier).updateLeconSpecificOrder(currentLecon.id, _selectedLeconType, i + 1));
            }

            Future.wait(updateFutures).then((_) async {
              await ref.read(leconProvider.notifier).fetchLecons(chapitreId: widget.chapitreId); 
            }).catchError((error) {
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la mise à jour de l'ordre: $error"), backgroundColor: Colors.red,));
                ref.read(leconProvider.notifier).fetchLecons(chapitreId: widget.chapitreId);
              }
            });
          });
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible( 
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  label: Text(currentMatiere != null && currentMatiere.nom.isNotEmpty ? 'Retour à "${currentMatiere.nom}"' : 'Retour aux Chapitres', overflow: TextOverflow.ellipsis),
                  onPressed: widget.onBackToChapitres,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                ),
              ),
              if (widget.onAddLecon != null) _buildAddLessonButton(context),
            ],
          ),
          const SizedBox(height: 8),
          if (currentChapitre != null && currentChapitre.nom.isNotEmpty && currentChapitre.nom != 'Chargement...')
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
              child: RichText(
                text: TextSpan(
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    children: [
                      if (currentMatiere != null && currentMatiere.nom.isNotEmpty) ...[
                        TextSpan(text: 'Matière: ${currentMatiere.nom} '),
                        const TextSpan(text: '> '),
                      ],
                      TextSpan(text: 'Chapitre: ${currentChapitre.nom}'),
                    ]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Padding(
                padding: EdgeInsets.only(bottom: 12.0, left: 4.0),
                child: Text("Chargement des détails du chapitre...", style: TextStyle(fontStyle: FontStyle.italic))),
          
          _buildFilterChips(),
          
          Expanded(child: content),
        ],
      ),
    );
  }
}
