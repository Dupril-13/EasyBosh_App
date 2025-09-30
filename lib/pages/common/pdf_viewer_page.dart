import 'dart:io';
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
  String? _localPdfPath;
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
    try {
      print("PDF URL being used for viewing: ${widget.pdfUrl}"); // Added print
      final dir = await getApplicationDocumentsDirectory();
      final filename = '${widget.lessonTitle.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}_preview.pdf';
      final filePath = '${dir.path}/$filename';

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
          _localPdfPath = filePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading PDF for viewing: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = 'Erreur de chargement du PDF: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length)}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement du PDF: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length)}')),
        );
      }
    }
  }

  Future<void> _downloadAndOpenFile() async {
    if (_isDownloading) return;
    print("PDF URL being used for download: ${widget.pdfUrl}"); // Added print for download function too

    var storageStatus = await Permission.storage.status;
    
    if (Platform.isAndroid) {
        final androidInfo = await Dio().get('https://api.ipify.org'); 
        // final androidInfo = await DeviceInfoPlugin().androidInfo; 
        // if (androidInfo.version.sdkInt >= 33) { // Android 13+ 
        //   storageStatus = await Permission.manageExternalStorage.status; 
        //   if (storageStatus != PermissionStatus.granted) { 
        //     storageStatus = await Permission.manageExternalStorage.request(); 
        //   } 
        // } else 
        if (storageStatus != PermissionStatus.granted) {
            storageStatus = await Permission.storage.request();
        }
    } else if (Platform.isIOS) {
        // iOS does not require explicit permission for app's document directory
    } 
    // else {
    //     // Fallback for other platforms or older Android versions if needed
    //     storageStatus = await Permission.storage.request(); 
    // }

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
      final filePath = '${downloadsDir!.path}/$fileName';

      await Dio().download(
        widget.pdfUrl,
        filePath,
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
                OpenFilex.open(filePath);
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
          if (_localPdfPath != null && !_isDownloading)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Télécharger le PDF',
              onPressed: _downloadAndOpenFile,
            ),
          if (_isDownloading)
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
          : _localPdfPath == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_loadingMessage.isNotEmpty ? _loadingMessage : 'Impossible de charger le PDF. Vérifiez l\'URL ou votre connexion.', textAlign: TextAlign.center,),
                  )
                )
              : PDFView(
                  filePath: _localPdfPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
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
                        setState(() { _loadingMessage = 'Erreur d\'affichage PDF: $error'; _localPdfPath = null; });
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
