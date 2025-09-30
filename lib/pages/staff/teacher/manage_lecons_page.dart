import 'dart:async';
import 'dart:io' show Platform; // Ajouté pour Platform.is...
import 'package:flutter/foundation.dart' show kIsWeb; // Ajouté pour kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart'; // Ajouté pour url_launcher
import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/providers/lecon_provider.dart';
import 'package:easybosh_v2/providers/chapitre_provider.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
import 'package:easybosh_v2/pages/common/pdf_viewer_page.dart';

class LeconPreviewPage extends ConsumerStatefulWidget {
  final LeconModel lecon;

  const LeconPreviewPage({Key? key, required this.lecon}) : super(key: key);

  @override
  _LeconPreviewPageState createState() => _LeconPreviewPageState();
}

class _LeconPreviewPageState extends ConsumerState<LeconPreviewPage> {
  VideoPlayerController? _videoController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.lecon.type == 'video' && widget.lecon.urlMedia != null && widget.lecon.urlMedia!.isNotEmpty) {
      if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
        _initializeVideoPlayer(widget.lecon.urlMedia!);
      } else {
        print("Aperçu vidéo direct non supporté sur cette plateforme desktop. Utiliser un lien externe.");
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
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de chargement de la vidéo: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if(mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir l\'URL: $url')),
        );
      }
      throw 'Impossible d\'ouvrir l\'URL: $url';
    }
  }

  Widget _buildContentViewer(LeconModel lecon, BuildContext context) {
    switch (lecon.type) {
      case 'video':
        if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
          if (_videoController != null && _videoController!.value.isInitialized) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
                VideoProgressIndicator(_videoController!, allowScrubbing: true),
                IconButton(
                  icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow, size: 30),
                  onPressed: () => setState(() {
                    _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                  }),
                )
              ],
            );
          } else if (lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
            return const Center(child: CircularProgressIndicator(semanticsLabel: "Chargement de la vidéo..."));
          }
          return const Center(child: Text("Vidéo non disponible ou URL manquante."));
        } else { // Desktop (Windows, Linux, macOS)
          if (lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
            return ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ouvrir la vidéo avec le lecteur par défaut'),
              onPressed: () => _launchURL(lecon.urlMedia!),
            );
          }
          return const Center(child: Text("Aperçu vidéo non disponible sur Desktop. Lien externe possible."));
        }
      case 'pdf':
        if (lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
          if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            return ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(kIsWeb ? 'Ouvrir le PDF dans un nouvel onglet' : 'Ouvrir le PDF avec le lecteur par défaut'),
              onPressed: () => _launchURL(lecon.urlMedia!),
            );
          } else if (Platform.isAndroid || Platform.isIOS) {
            return ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Ouvrir le PDF'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerPage(pdfUrl: lecon.urlMedia!, lessonTitle: lecon.nom),
                  ),
                );
              },
            );
          }
        }
        return const Center(child: Text("PDF non disponible ou URL manquante."));
      case 'audio':
        if (lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
          return ElevatedButton.icon(
            icon: const Icon(Icons.audiotrack_outlined),
            label: const Text('Écouter l\'audio avec le lecteur par défaut'),
            onPressed: () => _launchURL(lecon.urlMedia!),
          );
        }
        return const Center(child: Text("Audio non disponible ou URL manquante."));
      default:
        return Center(child: Text("Type de contenu '${lecon.type}' non supporté pour l'aperçu."));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lecon.nom, overflow: TextOverflow.ellipsis),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Type: ${widget.lecon.type.toUpperCase()}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
            const SizedBox(height: 8),
            if (widget.lecon.description != null && widget.lecon.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text('Description: ${widget.lecon.description}', style: Theme.of(context).textTheme.bodyMedium),
              ),
            _buildContentViewer(widget.lecon, context),
            const SizedBox(height: 24),
            Text('URL Média brute: ${widget.lecon.urlMedia ?? 'Non défini'}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Actif: ${widget.lecon.actif ? 'Oui' : 'Non'}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

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
      if (mounted) _processLecons();
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
    } else if (_chipTypes.isNotEmpty && (_lessonsCountsPerType[_selectedLeconType] ?? 0) == 0 && _chipTypes.contains(_selectedLeconType) && !leconState.isLoading) {
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
            if (widget.onAddLecon != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: const Text('Vous pouvez en ajouter une.', textAlign: TextAlign.center),
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
                  ? 'Aucune leçon à afficher pour \"${currentChapitre.nom}\".'
                  : 'Aucune leçon à afficher pour ce chapitre.',
              style: const TextStyle(fontSize: 18), textAlign: TextAlign.center,
            ),
            if (widget.onAddLecon != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: const Text('Appuyez sur le bouton ci-dessus pour ajouter.', textAlign: TextAlign.center),
              ),
          ],
        ),
      );
    } else {
      content = ReorderableListView.builder(
        buildDefaultDragHandles: false, // MODIFIÉ ICI
        itemCount: _leconsAffichees.length,
        itemBuilder: (context, index) {
          final lecon = _leconsAffichees[index];
          return Card(
            key: ValueKey("${_selectedLeconType}_${lecon.id}_${lecon.ordreParType?[_selectedLeconType] ?? lecon.ordre}"),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            elevation: 2,
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener( // Poignée de drag explicitement placée à gauche
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8.0), // Espace entre la poignée et le numéro
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                  CircleAvatar(
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
              title: Text(lecon.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                "Type: ${lecon.type.replaceAll('_', ' ').toUpperCase()}\n${lecon.description ?? 'Pas de description'}",
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
                                  content: Text('Supprimer "${lecon.nom}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
                                    TextButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(true),
                                        child: Text('Supprimer', style: TextStyle(color: Theme.of(context).colorScheme.error)))
                                  ],
                                ));
                        if (confirm == true) {
                          final success = await ref.read(leconProvider.notifier).deleteLecon(lecon.id);
                          if (mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${lecon.nom}" supprimé.')));
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Erreur: ${ref.read(leconProvider).errorMessage ?? "Erreur lors de la suppression"}')));
                          }
                        }
                      }),
                  // SizedBox retiré d'ici
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
              LeconModel leconToUpdate = currentLecon.copyWith(ordreParType: updatedOrdreParType);
              updateFutures.add(ref.read(leconProvider.notifier).updateLeconSpecificOrder(leconToUpdate.id, _selectedLeconType, i + 1));
            }

            Future.wait(updateFutures).then((_) async {
              await ref.read(leconProvider.notifier).fetchLecons(chapitreId: widget.chapitreId); 
            }).catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la mise à jour de l'ordre: $error")));
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
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                label: Text(currentMatiere != null ? 'Retour à "${currentMatiere.nom}"' : 'Retour aux Chapitres'),
                onPressed: widget.onBackToChapitres,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
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
