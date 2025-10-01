import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Ajout pour kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String lessonTitle;

  const PdfViewerPage({
    Key? key,
    required this.pdfUrl,
    required this.lessonTitle,
  }) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? _localPdfPathOrUrl; // Renommé pour plus de clarté
  bool _isLoading = true;
  String _loadingMessage = 'Chargement du PDF...';
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _loadPdfForViewing();
  }

  Future<void> _loadPdfForViewing() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Chargement du PDF...';
    });

    if (kIsWeb) {
      // Pour le web, utiliser l'URL directement
      print("PDF URL for web viewing (direct): ${widget.pdfUrl}");
      if (mounted) {
        setState(() {
          _localPdfPathOrUrl = widget.pdfUrl; // Utiliser l'URL
          _isLoading = false;
        });
      }
    } else {
      // Pour les plateformes natives, télécharger comme avant
      try {
        print("PDF URL for native viewing (download): ${widget.pdfUrl}");
        final dir = await getApplicationDocumentsDirectory();
        final filename = '${widget.lessonTitle.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}_preview.pdf';
        final filePath = '${dir.path}/$filename';
        
        final file = File(filePath);
        if (await file.exists()) {
          // Optionnel : vérifier la date ou la taille pour décider de re-télécharger
          // Pour l'instant, on le supprime pour s'assurer d'avoir la dernière version
          // await file.delete();
        }

        await Dio().download(
          widget.pdfUrl,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1 && mounted) {
              setState(() {
                _loadingMessage = 'Chargement: ${(received / total * 100).toStringAsFixed(0)}%';
              });
            }
          },
        );

        if (mounted) {
          setState(() {
            _localPdfPathOrUrl = filePath; // Utiliser le chemin local
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading PDF for native viewing: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadingMessage = 'Erreur de chargement du PDF: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length)}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de chargement du PDF')),
          );
        }
      }
    }
  }

  Future<void> _downloadAndOpenFile() async {
    if (_isDownloading) return;
    print("PDF URL being used for download: ${widget.pdfUrl}");

    // La logique de permission pour le téléchargement reste la même
    var storageStatus = await Permission.storage.status;
    if (Platform.isAndroid) {
        // Pour simplifier, on ne demande plus manageExternalStorage ici,
        // storage (accès aux fichiers médias) devrait suffire pour le dossier Download
        // Si Android 13+ (SDK 33+), les permissions sont plus granulaires (photos, videos, audio)
        // Pour les fichiers génériques dans Download, WRITE_EXTERNAL_STORAGE (avant SDK 29) ou pas de permission directe (après SDK 29, via MediaStore)
        // Permission.storage est un bon point de départ.
        if (storageStatus != PermissionStatus.granted) {
            storageStatus = await Permission.storage.request();
        }
    } else if (Platform.isIOS) {
        // iOS ne nécessite pas de permission explicite pour le dossier de l'application.
        // Pour enregistrer dans Photos, d'autres permissions seraient nécessaires.
    } 

    if (storageStatus != PermissionStatus.granted && !kIsWeb) { // Sur le web, le navigateur gère les téléchargements
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission de stockage refusée.')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      String filePathToOpen;
      if (kIsWeb) {
        // Sur le web, le téléchargement est géré par le navigateur en ouvrant l'URL
        // On peut simuler cela ou juste laisser le navigateur gérer via un lien
        // Pour l'instant, on ne fait rien de spécial ici pour le bouton "Télécharger" sur le web
        // car le PDF est déjà censé s'afficher en ligne.
        // On pourrait utiliser html.AnchorElement pour déclencher un téléchargement nommé.
        print("Web download button pressed - PDF should be viewable or downloaded by browser directly.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le PDF devrait s\'afficher ou être téléchargeable via les contrôles du navigateur.')),
        );
         if (mounted) {
          setState(() { _isDownloading = false; });
        }
        return; // Pour l'instant, pas d'action de téléchargement de fichier explicite pour le web ici.
      }

      Directory? downloadsDir;
      if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else { 
        try {
             downloadsDir = Directory('/storage/emulated/0/Download');
             if (!await downloadsDir.exists()) downloadsDir = await getExternalStorageDirectory();
        } catch (e) {
            print("Erreur accès direct Download: $e");
            downloadsDir = await getExternalStorageDirectory();
        }
        if (downloadsDir == null) downloadsDir = await getApplicationDocumentsDirectory();
      }
      
      final safeLessonTitle = widget.lessonTitle.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
      final fileName = '${safeLessonTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      filePathToOpen = '${downloadsDir!.path}/$fileName';

      await Dio().download(
        widget.pdfUrl,
        filePathToOpen,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF téléchargé: $fileName'),
            action: SnackBarAction(
              label: 'OUVRIR',
              onPressed: () {
                OpenFilex.open(filePathToOpen);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de téléchargement: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.lessonTitle, style: const TextStyle(fontSize: 18)),
            if (_totalPages > 0)
              Text('Page ${_currentPage + 1} sur $_totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          // Le bouton de téléchargement est moins pertinent sur le web si le PDF s'affiche déjà.
          // Mais on le laisse pour l'instant, il ne fera rien (ou on peut le cacher avec !kIsWeb).
          if (_localPdfPathOrUrl != null && !_isDownloading && !kIsWeb)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Télécharger le PDF',
              onPressed: _downloadAndOpenFile,
            ),
          if (_isDownloading && !kIsWeb) // Masquer la progression pour le web aussi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: _downloadProgress > 0 && _downloadProgress < 1 ? _downloadProgress : null,
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(_loadingMessage)]))
          : _localPdfPathOrUrl == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_loadingMessage.isNotEmpty ? _loadingMessage : 'Impossible de charger le PDF. Vérifiez l\'URL ou votre connexion.', textAlign: TextAlign.center,),
                  )
                )
              : PDFView(
                  filePath: _localPdfPathOrUrl!, // Utilisation de la variable renommée/modifiée
                  enableSwipe: true,
                  swipeHorizontal: kIsWeb, // Sur le web, le scroll horizontal peut être plus naturel
                  autoSpacing: true,
                  pageFling: true,
                  pageSnap: true,
                  defaultPage: _currentPage,
                  fitPolicy: FitPolicy.BOTH,
                  preventLinkNavigation: false, 
                  onRender: (pages) {
                    if (mounted) setState(() => _totalPages = pages ?? 0);
                  },
                  onError: (error) {
                    print(error.toString());
                     if(mounted) {
                        setState(() { 
                          _loadingMessage = 'Erreur d\'affichage PDF: $error'; 
                          _localPdfPathOrUrl = null; // Invalider le chemin/url en cas d'erreur
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur d\'affichage PDF: $error')));
                    }
                  },
                  onPageError: (page, error) {
                    print('Page $page: ${error.toString()}');
                     if(mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement page $page: $error')));
                    }
                  },
                  onViewCreated: (PDFViewController pdfViewController) {
                    _pdfViewController = pdfViewController;
                  },
                  onPageChanged: (int? page, int? total) {
                    if (page != null && total != null && mounted) {
                      setState(() {
                        _currentPage = page;
                        _totalPages = total;
                      });
                    }
                  },
                ),
        floatingActionButton: _pdfViewController != null && _totalPages > 1 ? FloatingActionButton.small(
          onPressed: () async {
            if(_currentPage < _totalPages -1) {
              _pdfViewController!.setPage(_currentPage +1);
            } else {
              _pdfViewController!.setPage(0);
            }
          },
          tooltip: 'Page Suivante',
          child: const Icon(Icons.arrow_forward_ios_rounded)
        ) : null,
    );
  }
}
