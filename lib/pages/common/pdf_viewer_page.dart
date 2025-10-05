import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String lessonTitle;
  final bool hideAppBar;

  const PdfViewerPage({
    Key? key,
    required this.pdfUrl,
    required this.lessonTitle,
    this.hideAppBar = false,
  }) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? _localPdfPathOrUrl;
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
      print("PDF URL for web viewing (direct): ${widget.pdfUrl}");
      if (mounted) {
        setState(() {
          _localPdfPathOrUrl = widget.pdfUrl;
          _isLoading = false;
        });
      }
    } else {
      try {
        print("PDF URL for native viewing (download): ${widget.pdfUrl}");
        final dir = await getApplicationDocumentsDirectory();
        final filename = '${widget.lessonTitle.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}_preview.pdf';
        final filePath = '${dir.path}/$filename';

        final file = File(filePath);

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
            _localPdfPathOrUrl = filePath;
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
            const SnackBar(content: Text('Erreur de chargement du PDF')),
          );
        }
      }
    }
  }

  Future<void> _downloadAndOpenFile() async {
    if (_isDownloading) return;
    print("PDF URL being used for download: ${widget.pdfUrl}");

    if (kIsWeb) {
      print("Web download button pressed - PDF should be viewable or downloaded by browser directly.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le PDF devrait s\'afficher ou être téléchargeable via les contrôles du navigateur.')),
      );
      return;
    }

    var storageStatus = await Permission.storage.status;
    if (Platform.isAndroid) {
      if (storageStatus != PermissionStatus.granted) {
        storageStatus = await Permission.storage.request();
      }
    }

    if (storageStatus != PermissionStatus.granted) {
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
      Directory? downloadsDir;
      if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        try {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) downloadsDir = await getExternalStorageDirectory();
        } catch (e) {
          print("Erreur accès direct Download: $e");
          downloadsDir = await getExternalStorageDirectory();
        }
        if (downloadsDir == null) downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final safeLessonTitle = widget.lessonTitle.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
      final fileName = '${safeLessonTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePathToOpen = '${downloadsDir!.path}/$fileName';

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
    // Si hideAppBar est true, ne pas afficher le Scaffold avec AppBar
    if (widget.hideAppBar) {
      return _buildPdfContent();
    }

    // Sinon, afficher avec l'AppBar complète (pour les leçons PDF)
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lessonTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Page ${_currentPage + 1} sur $_totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        actions: [
          if (!kIsWeb && _localPdfPathOrUrl != null && !_isDownloading)
            IconButton(
              icon: const Icon(Icons.download_outlined, color: Colors.blue),
              tooltip: 'Télécharger le PDF',
              onPressed: _downloadAndOpenFile,
            ),
          if (!kIsWeb && _isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: _downloadProgress > 0 && _downloadProgress < 1 ? _downloadProgress : null,
                  strokeWidth: 2.5,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
      body: _buildPdfContent(),
      floatingActionButton: !kIsWeb && _pdfViewController != null && _totalPages > 1
          ? Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Bouton Page Précédente
          if (_currentPage > 0)
            FloatingActionButton.small(
              heroTag: 'prev_page',
              onPressed: () {
                if (_currentPage > 0) {
                  _pdfViewController!.setPage(_currentPage - 1);
                }
              },
              tooltip: 'Page Précédente',
              backgroundColor: Colors.blue.shade600,
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
          const SizedBox(width: 12),
          // Bouton Page Suivante
          FloatingActionButton.small(
            heroTag: 'next_page',
            onPressed: () {
              if (_currentPage < _totalPages - 1) {
                _pdfViewController!.setPage(_currentPage + 1);
              } else {
                _pdfViewController!.setPage(0);
              }
            },
            tooltip: 'Page Suivante',
            backgroundColor: Colors.blue.shade600,
            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
          ),
        ],
      )
          : null,
    );
  }

  Widget _buildPdfContent() {
    // Affichage uniquement du téléchargement dans l'AppBar parent si hideAppBar
    if (widget.hideAppBar && !kIsWeb && _localPdfPathOrUrl != null) {
      // Ajouter juste l'icône de téléchargement dans l'AppBar parent via un widget retourné
      // Mais comme on ne peut pas modifier l'AppBar parent, on affiche juste le PDF
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_loadingMessage),
          ],
        ),
      );
    }

    if (_localPdfPathOrUrl == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _loadingMessage.isNotEmpty ? _loadingMessage : 'Impossible de charger le PDF. Vérifiez l\'URL ou votre connexion.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      children: [
        PDFView(
          filePath: _localPdfPathOrUrl!,
          enableSwipe: true,
          swipeHorizontal: kIsWeb,
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
            if (mounted) {
              setState(() {
                _loadingMessage = 'Erreur d\'affichage PDF: $error';
                _localPdfPathOrUrl = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur d\'affichage PDF: $error')));
            }
          },
          onPageError: (page, error) {
            print('Page $page: ${error.toString()}');
            if (mounted) {
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

        // Icône de téléchargement en haut à droite si hideAppBar = true
        if (widget.hideAppBar && !kIsWeb && _localPdfPathOrUrl != null)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isDownloading
                  ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _downloadProgress > 0 && _downloadProgress < 1 ? _downloadProgress : null,
                    strokeWidth: 2.5,
                    color: Colors.blue,
                  ),
                ),
              )
                  : IconButton(
                icon: const Icon(Icons.download_outlined, color: Colors.blue),
                tooltip: 'Télécharger le PDF',
                onPressed: _downloadAndOpenFile,
              ),
            ),
          ),
      ],
    );
  }
}