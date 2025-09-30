import 'dart:typed_data';
import 'dart:io' show Platform; // Ajouté pour Platform.is...
import 'package:flutter/foundation.dart' show kIsWeb; // Ajouté pour kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart'; // Ajouté pour url_launcher
import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/providers/lecon_provider.dart';
import 'package:easybosh_v2/providers/chapitre_provider.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
import 'package:easybosh_v2/pages/common/pdf_viewer_page.dart'; // Gardé au cas où, mais l'aperçu utilisera url_launcher

class EditLeconPage extends ConsumerStatefulWidget {
  final int? leconId;
  final int? chapitreId;
  final VoidCallback? onSubmitted;
  final VoidCallback? onCancel;

  const EditLeconPage({
    super.key,
    this.leconId,
    required this.chapitreId,
    this.onSubmitted,
    this.onCancel,
  });

  @override
  ConsumerState<EditLeconPage> createState() => _EditLeconPageState();
}

class _EditLeconPageState extends ConsumerState<EditLeconPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _dureeEstimeeController;
  late TextEditingController _urlMediaController;

  final List<String> _leconTypes = ['pdf', 'video', 'audio']; // MODIFIÉ: 'text_rich' retiré
  late String _selectedLeconType;

  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  int? _currentSelectedChapitreId;
  bool _actif = true;
  int _currentOrdreForEditing = 0;

  bool _isFormInitialized = false;
  bool _isLoadingLeconDetails = false;
  bool _isDisposed = false;

  VideoPlayerController? _videoController;

  bool get _isEditing => widget.leconId != null;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _descriptionController = TextEditingController();
    _dureeEstimeeController = TextEditingController();
    _urlMediaController = TextEditingController();
    _selectedLeconType = _leconTypes.first;
    _currentSelectedChapitreId = widget.chapitreId;

    if (!_isEditing) {
      _isFormInitialized = true;
    } else {
      _isLoadingLeconDetails = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ref.read(matiereProvider).matieres.isEmpty) {
        await ref.read(matiereProvider.notifier).fetchMatieres();
      }
      final chapitreNotifier = ref.read(chapitreProvider.notifier);
      if (!chapitreNotifier.state.chapitres.any((ch) => ch.id == _currentSelectedChapitreId) &&
          _currentSelectedChapitreId != null) {
        await chapitreNotifier.chargerChapitrePourEdition(_currentSelectedChapitreId!); 
      }

      if (_isEditing && widget.leconId != null) {
        await ref.read(leconProvider.notifier).chargerLeconPourEdition(widget.leconId!);
        if (mounted) setState(() => _isLoadingLeconDetails = false);
      } else {
        if (mounted) setState(() => _isFormInitialized = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant EditLeconPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEditing && widget.leconId != oldWidget.leconId && widget.leconId != null) {
      setState(() {
        _isFormInitialized = false;
        _isLoadingLeconDetails = true;
        _selectedFileName = null; 
        _selectedFileBytes = null;
        _videoController?.dispose();
        _videoController = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(leconProvider.notifier).chargerLeconPourEdition(widget.leconId!);
        if (mounted) setState(() => _isLoadingLeconDetails = false);
      });
    }
    if (widget.chapitreId != oldWidget.chapitreId) {
      setState(() {
        _currentSelectedChapitreId = widget.chapitreId;
      });
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    if (!mounted || _isDisposed) return;
    await _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _videoController!.initialize();
      if (mounted && !_isDisposed) {
        setState(() {});
      }
    } catch (e) {
      print("Erreur d'initialisation du lecteur vidéo (EditLeconPage): $e");
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur chargement vidéo: ${e.toString().substring(0,100)}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _populateFormFields(LeconModel lecon) async {
    if (!mounted || _isDisposed) return;
    _nomController.text = lecon.nom;
    _descriptionController.text = lecon.description ?? '';
    _currentOrdreForEditing = lecon.ordre;
    _dureeEstimeeController.text = lecon.dureeEstimee?.toString() ?? '';
    _selectedLeconType = _leconTypes.contains(lecon.type) ? lecon.type : _leconTypes.first;
    _urlMediaController.text = lecon.urlMedia ?? '';
    _currentSelectedChapitreId = lecon.chapitreId;
    _actif = lecon.actif;
    _selectedFileName = null;
    _selectedFileBytes = null;

    if (lecon.type == 'video' && lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
      if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
        await _initializeVideoPlayer(lecon.urlMedia!);
      } else {
        await _videoController?.dispose();
        _videoController = null;
      }
    } else {
      await _videoController?.dispose();
      _videoController = null;
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _isFormInitialized = true;
        _isLoadingLeconDetails = false;
      });
    }
  }
  
  List<String>? _getAllowedExtensionsForType(String type) {
    if (type == 'pdf') return ['pdf'];
    if (type == 'video') return ['mp4', 'mov', 'avi', 'mkv', 'webm'];
    if (type == 'audio') return ['mp3', 'wav', 'aac', 'ogg', 'm4a'];
    return null; // Pour 'text_rich' ou autres, pas de sélection de fichier direct pour l'instant
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _getAllowedExtensionsForType(_selectedLeconType),
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      if (mounted && !_isDisposed) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFileBytes = result.files.single.bytes;
          _urlMediaController.clear();
          _videoController?.dispose(); 
          _videoController = null;
        });
      }
    } else {
       if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun fichier sélectionné ou erreur de lecture.')),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if(mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir l\'URL: $url')),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nomController.dispose();
    _descriptionController.dispose();
    _dureeEstimeeController.dispose();
    _urlMediaController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_currentSelectedChapitreId == null) {
        if (mounted && !_isDisposed) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Chapitre ID manquant.'), backgroundColor: Colors.red));
        return;
      }
      _formKey.currentState!.save();

      final bool isCurrentlyEditing = _isEditing && widget.leconId != null;
      LeconModel? leconActuelleSiEdition = isCurrentlyEditing ? ref.read(leconProvider).leconPourEdition : null;

      if (isCurrentlyEditing && leconActuelleSiEdition == null) {
        if (mounted && !_isDisposed) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Leçon à éditer non chargée.'), backgroundColor: Colors.red));
        return;
      }

      String? finalUrlMedia = _selectedFileBytes != null ? null : (_urlMediaController.text.isEmpty ? null : _urlMediaController.text);

      final leconDetails = LeconModel(
        id: isCurrentlyEditing ? widget.leconId! : 0,
        nom: _nomController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        chapitreId: _currentSelectedChapitreId!,
        ordre: isCurrentlyEditing ? _currentOrdreForEditing : 0,
        type: _selectedLeconType,
        urlMedia: finalUrlMedia,
        contenu: null, // text_rich n'est plus géré ici
        createdAt: isCurrentlyEditing ? leconActuelleSiEdition!.createdAt : DateTime.now(),
        updatedAt: isCurrentlyEditing ? DateTime.now() : null,
        dureeEstimee: _dureeEstimeeController.text.isEmpty ? null : int.tryParse(_dureeEstimeeController.text),
        actif: _actif,
        createdBy: isCurrentlyEditing ? leconActuelleSiEdition!.createdBy : null,
      );

      bool success;
      if (isCurrentlyEditing) {
        success = await ref.read(leconProvider.notifier).updateLecon(leconDetails, fileBytes: _selectedFileBytes, fileName: _selectedFileName);
      } else {
        success = await ref.read(leconProvider.notifier).addLecon(leconDetails, fileBytes: _selectedFileBytes, fileName: _selectedFileName);
      }

      if (mounted && !_isDisposed) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leçon ${isCurrentlyEditing ? "mise à jour" : "ajoutée"} avec succès!'), backgroundColor: Colors.green));
          widget.onSubmitted?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${ref.read(leconProvider).errorMessage ?? "Une erreur inconnue s\'est produite."}'), backgroundColor: Colors.red));
        }
      }
    }
  }
  
  Widget _buildContentViewer(LeconModel lecon) {
    // Ce visualiseur est pour l'aperçu dans le formulaire d'édition
    switch (lecon.type) {
      case 'video':
        if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
          if (_videoController != null && _videoController!.value.isInitialized) {
            return Column(
              children: [
                AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)),
                VideoProgressIndicator(_videoController!, allowScrubbing: true),
                IconButton(
                  icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () => setState(() => _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play()),
                )
              ],
            );
          } else if (lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
            return const Center(child: CircularProgressIndicator(semanticsLabel: "Chargement vidéo..."));
          }
          return const Text("URL vidéo manquante ou erreur de chargement.");
        } else { // Desktop (Windows, Linux, macOS)
          if (lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
            return ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ouvrir la vidéo avec le lecteur par défaut'),
              onPressed: () => _launchURL(lecon.urlMedia!),
            );
          }
          return const Text("Aperçu vidéo non disponible sur Desktop.");
        }
      case 'pdf':
        if (lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
           return ElevatedButton.icon(
             icon: const Icon(Icons.open_in_new),
             label: Text(kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS 
                         ? 'Ouvrir le PDF avec le lecteur par défaut' 
                         : 'Ouvrir le PDF'), // Mobile utilisera aussi url_launcher ici
             onPressed: () => _launchURL(lecon.urlMedia!),
           );
        }
        return const Text("URL PDF manquante.");
      case 'audio':
         if (lecon.urlMedia != null && lecon.urlMedia!.isNotEmpty) {
          return ElevatedButton.icon(
            icon: const Icon(Icons.audiotrack_outlined),
            label: const Text('Ouvrir l\'audio avec le lecteur par défaut'),
            onPressed: () => _launchURL(lecon.urlMedia!),
          );
        }
        return const Text("URL audio manquante.");
      default: // 'text_rich' n'est plus un type ici, donc pas d'aperçu spécifique
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LeconModel?>(
      leconProvider.select((s) => s.leconPourEdition),
      (previous, next) async {
        if (_isEditing && next != null && next.id == widget.leconId) {
          if(!_isFormInitialized || _nomController.text != next.nom) {
            await _populateFormFields(next);
          }
        } else if (_isEditing && next == null && widget.leconId != null && !ref.read(leconProvider).isLoading) {
           if(mounted && !_isDisposed) {
            setState((){
              _isFormInitialized = true; 
              _isLoadingLeconDetails = false;
            });
          }
        }
      }
    );

    final leconState = ref.watch(leconProvider);
    final chapitreState = ref.watch(chapitreProvider);
    final matiereState = ref.watch(matiereProvider);

    final chapitreParent = chapitreState.chapitres.firstWhere((ch) => ch.id == _currentSelectedChapitreId,
        orElse: () => chapitreState.chapitrePourEdition?.id == _currentSelectedChapitreId
                      ? chapitreState.chapitrePourEdition!
                      : ChapitreModel(id: _currentSelectedChapitreId ?? 0, nom: "Chargement...", ordre: 0, createdAt: DateTime.now(), actif: true, matiereId: 0)); // Ajout matiereId pour éviter null error
    
    MatiereModel? matiereDuChapitre;
    if (chapitreParent.matiereId != 0 && matiereState.matieres.isNotEmpty) {
      try {
        matiereDuChapitre = matiereState.matieres.firstWhere((m) => m.id == chapitreParent.matiereId);
      } catch (e) { /* Peut arriver si la matière n'est pas encore chargée */ }
    }
    
    if ((_isEditing && !_isFormInitialized && _isLoadingLeconDetails) || (!_isFormInitialized && _currentSelectedChapitreId == null) ) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(semanticsLabel: "Chargement du formulaire...")),
      );
    }
    if (_isEditing && _isFormInitialized && leconState.leconPourEdition == null && widget.leconId != null && !leconState.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Erreur: Impossible de charger les détails de la leçon. ${leconState.errorMessage ?? ''}", style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: widget.onCancel ?? () => Navigator.of(context).pop(), child: const Text('Retour'))
        ])),
      );
    }
    if (_currentSelectedChapitreId == null) {
        return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("Erreur : ID du chapitre manquant.")));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            if (widget.onCancel != null) Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Align(alignment: Alignment.topLeft, child: TextButton.icon(icon: const Icon(Icons.arrow_back_ios, size: 16.0), label: const Text("Retour"), onPressed: widget.onCancel, style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, alignment: Alignment.centerLeft)))),
            if (chapitreParent.nom != "Chargement...") Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Text("Matière: ${matiereDuChapitre?.nom ?? ''} > Chapitre: ${chapitreParent.nom}", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
            TextFormField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom de la leçon *', border: OutlineInputBorder()), validator: (value) => value == null || value.isEmpty ? 'Nom requis' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLeconType,
              items: _leconTypes.map((String type) => DropdownMenuItem<String>(value: type, child: Text(type.replaceAll('_', ' ').toUpperCase()))).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLeconType = newValue;
                    _urlMediaController.clear();
                    _selectedFileName = null;
                    _selectedFileBytes = null;
                    if (newValue != 'video') {
                       _videoController?.dispose();
                       _videoController = null;
                    } else if (_isEditing && leconState.leconPourEdition?.type == 'video' && leconState.leconPourEdition?.urlMedia != null && leconState.leconPourEdition!.urlMedia!.isNotEmpty) {
                        if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
                            _initializeVideoPlayer(leconState.leconPourEdition!.urlMedia!);
                        }
                    }
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Type de leçon *', border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? 'Type requis' : null,
            ),
            const SizedBox(height: 16),
            if (_isEditing && leconState.leconPourEdition != null && ((leconState.leconPourEdition!.urlMedia != null && leconState.leconPourEdition!.urlMedia!.isNotEmpty) || (leconState.leconPourEdition!.type == 'text_rich' /*Conservé au cas où même si type retiré*/ && leconState.leconPourEdition!.contenu != null)) && _selectedFileBytes == null) ...[
              const Divider(height: 32, thickness: 1),
              Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text("Aperçu du contenu actuel:", style: Theme.of(context).textTheme.titleMedium)),
              _buildContentViewer(leconState.leconPourEdition!),
              const Divider(height: 32, thickness: 1),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Média (${_selectedLeconType.toUpperCase()})', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_selectedFileName != null) ...[
                  ListTile(
                    leading: Icon(Icons.insert_drive_file_outlined, color: Theme.of(context).colorScheme.primary),
                    title: Text(_selectedFileName!),
                    subtitle: const Text('Nouveau fichier prêt'),
                    trailing: IconButton(icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.error), onPressed: () {
                      setState(() {
                        _selectedFileName = null; _selectedFileBytes = null;
                        if (_isEditing && leconState.leconPourEdition?.type == 'video' && leconState.leconPourEdition?.urlMedia != null && leconState.leconPourEdition!.urlMedia!.isNotEmpty) {
                          if (kIsWeb || Platform.isAndroid || Platform.isIOS) _initializeVideoPlayer(leconState.leconPourEdition!.urlMedia!);
                        }
                      });
                    }),
                  ),
                  const SizedBox(height: 8), Center(child: Text("OU", style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant))), const SizedBox(height: 8),
                ],
                ElevatedButton.icon(icon: const Icon(Icons.upload_file_outlined), label: Text(_selectedFileName == null ? 'Choisir un fichier' : 'Changer le fichier'), onPressed: _pickFile, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40))),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlMediaController,
                  decoration: InputDecoration(labelText: _selectedFileName == null ? 'URL du Média (si aucun fichier)' : 'URL (ignorée si fichier choisi)', border: const OutlineInputBorder(), filled: _selectedFileName != null, fillColor: _selectedFileName != null ? Theme.of(context).colorScheme.onSurface.withOpacity(0.04) : null),
                  keyboardType: TextInputType.url, enabled: _selectedFileName == null,
                  validator: (value) {
                    if (_selectedFileName == null && (_selectedLeconType == 'video' || _selectedLeconType == 'pdf' || _selectedLeconType == 'audio') && (value == null || value.isEmpty)) return 'URL requise ou choisir un fichier';
                    if (value != null && value.isNotEmpty) {
                      final Uri? uri = Uri.tryParse(value);
                      if (uri == null || !uri.hasAbsolutePath || !uri.isAbsolute || !uri.toString().startsWith('http')) return 'URL invalide (doit commencer par http:// ou https://)';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_selectedLeconType == 'video' && value.isNotEmpty && _selectedFileName == null) {
                      if (kIsWeb || Platform.isAndroid || Platform.isIOS) _initializeVideoPlayer(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _dureeEstimeeController, decoration: const InputDecoration(labelText: 'Durée Estimée (minutes)', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (value) => (value != null && value.isNotEmpty && int.tryParse(value) == null) ? 'Nombre invalide' : null),
            const SizedBox(height: 16),
            SwitchListTile(title: const Text('Actif'), subtitle: Text(_actif ? 'Leçon visible.' : 'Leçon masquée.'), value: _actif, onChanged: (bool value) => setState(() => _actif = value), activeColor: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null) TextButton(onPressed: widget.onCancel, child: const Text('Annuler')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: leconState.isLoading ? null : _submitForm, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: leconState.isLoading ? const SizedBox(width: 20, height: 20, child:CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isEditing ? 'Mettre à jour' : 'Ajouter')),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
