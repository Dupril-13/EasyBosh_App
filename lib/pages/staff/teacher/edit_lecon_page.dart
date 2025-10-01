import 'dart:typed_data';
// import 'dart:io' show Platform; // Potentially unused now
// import 'package:flutter/foundation.dart' show kIsWeb; // Potentially unused now
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:video_player/video_player.dart'; // Removed
// import 'package:url_launcher/url_launcher.dart'; // Removed
import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/providers/lecon_provider.dart';
import 'package:easybosh_v2/providers/chapitre_provider.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
// import '../../../widgets/common/compact_audio_player.dart'; // Removed
// import 'package:flutter_pdfview/flutter_pdfview.dart'; // Removed
// import 'package:dio/dio.dart'; // Removed

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

  final List<String> _leconTypes = ['pdf', 'video', 'audio'];
  late String _selectedLeconType;

  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  int? _currentSelectedChapitreId;
  bool _actif = true;
  int _currentOrdreForEditing = 0;

  bool _isFormInitialized = false;
  bool _isLoadingLeconDetails = false;
  bool _isDisposed = false;

  // All preview-related state variables removed
  // VideoPlayerController? _videoController;
  // Uint8List? _pdfPreviewBytes;
  // bool _isLoadingPdfPreview = false;
  // String? _pdfPreviewError;
  // Key _pdfViewerKey = UniqueKey(); 

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

    // _urlMediaController.addListener(_onUrlMediaChanged); // Listener removed as its purpose was preview

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Fetching general data remains
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
        // _populateFormFields is called via ref.listen now
        if (mounted) setState(() => _isLoadingLeconDetails = false); 
      } else {
        if (mounted) setState(() => _isFormInitialized = true);
      }
    });
  }

  // _onUrlMediaChanged removed as its purpose was preview
  // void _onUrlMediaChanged() { ... }

  @override
  void didUpdateWidget(covariant EditLeconPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEditing && widget.leconId != oldWidget.leconId && widget.leconId != null) {
      setState(() {
        _isFormInitialized = false;
        _isLoadingLeconDetails = true;
        _clearSelectedFile(); // Clear local file selection when a new lesson is loaded for editing
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

  void _clearSelectedFile() { // Renamed and simplified from _resetMediaPreviewStates
    if (!mounted || _isDisposed) return;
    setState(() {
      _selectedFileName = null;
      _selectedFileBytes = null;
    });
  }

  // _initializeVideoPlayer method removed
  // _loadPdfPreviewFromUrl method removed

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
    
    _clearSelectedFile(); // Ensure any locally picked file is cleared when populating from a lesson model

    // Preview initialization logic removed

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
    return null;
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
          _urlMediaController.clear(); // If a file is chosen, the URL is conceptually ignored by the backend
          // Preview-related state clearing removed
        });
      }
    } else {
       if (mounted && !_isDisposed && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun fichier sélectionné ou erreur de lecture.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // _urlMediaController.removeListener(_onUrlMediaChanged); // Listener removed
    _nomController.dispose();
    _descriptionController.dispose();
    _dureeEstimeeController.dispose();
    _urlMediaController.dispose();
    // _videoController?.dispose(); // Removed
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_currentSelectedChapitreId == null) {
        if (mounted && !_isDisposed && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Chapitre ID manquant.'), backgroundColor: Colors.red));
        return;
      }
      _formKey.currentState!.save();

      final bool isCurrentlyEditing = _isEditing && widget.leconId != null;
      LeconModel? leconActuelleSiEdition = isCurrentlyEditing ? ref.read(leconProvider).leconPourEdition : null;

      if (isCurrentlyEditing && leconActuelleSiEdition == null && widget.leconId != null) { // Added widget.leconId != null for robustness
        if (mounted && !_isDisposed && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Leçon à éditer non chargée.'), backgroundColor: Colors.red));
        return;
      }

      String? finalUrlMedia = _selectedFileBytes != null ? null : (_urlMediaController.text.isEmpty ? null : _urlMediaController.text);

      final leconDetails = LeconModel(
        id: isCurrentlyEditing ? widget.leconId! : 0,
        nom: _nomController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        chapitreId: _currentSelectedChapitreId!,
        ordre: isCurrentlyEditing ? _currentOrdreForEditing : (leconActuelleSiEdition?.ordre ?? 0), // Use existing order if editing, else 0
        type: _selectedLeconType,
        urlMedia: finalUrlMedia,
        contenu: null, // Contenu textuel n'est pas géré par ce formulaire
        createdAt: isCurrentlyEditing ? leconActuelleSiEdition!.createdAt : DateTime.now(),
        updatedAt: isCurrentlyEditing ? DateTime.now() : null,
        dureeEstimee: _dureeEstimeeController.text.isEmpty ? null : int.tryParse(_dureeEstimeeController.text),
        actif: _actif,
        createdBy: isCurrentlyEditing ? leconActuelleSiEdition!.createdBy : null, // Pourrait être l'ID de l'utilisateur actuel
      );

      bool success;
      if (isCurrentlyEditing) {
        success = await ref.read(leconProvider.notifier).updateLecon(leconDetails, fileBytes: _selectedFileBytes, fileName: _selectedFileName);
      } else {
        success = await ref.read(leconProvider.notifier).addLecon(leconDetails, fileBytes: _selectedFileBytes, fileName: _selectedFileName);
      }

      if (mounted && !_isDisposed && context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leçon ${isCurrentlyEditing ? "mise à jour" : "ajoutée"} avec succès!'), backgroundColor: Colors.green));
          widget.onSubmitted?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${ref.read(leconProvider).errorMessage ?? "Une erreur inconnue s\'est produite."}'), backgroundColor: Colors.red));
        }
      }
    }
  }
  
  // _buildContentViewer method removed

  @override
  Widget build(BuildContext context) {
    // Listener pour pré-remplir le formulaire lors de l'édition
    ref.listen<LeconModel?>(
      leconProvider.select((s) => s.leconPourEdition),
      (previous, next) async {
        if (_isEditing && next != null && next.id == widget.leconId) {
          // Vérifier si le formulaire a besoin d'être initialisé ou si les données ont changé
          if(!_isFormInitialized || _nomController.text != next.nom || _descriptionController.text != (next.description ?? '')) {
            await _populateFormFields(next);
          }
        } else if (_isEditing && next == null && widget.leconId != null && !ref.read(leconProvider).isLoading) {
           // Cas où la leçon éditée n'est plus disponible ou erreur de chargement
           if(mounted && !_isDisposed) {
            setState((){
              _isFormInitialized = true; // Permet d'afficher le message d'erreur au lieu du loader
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
                      : ChapitreModel(id: _currentSelectedChapitreId ?? 0, nom: "Chargement...", ordre: 0, createdAt: DateTime.now(), actif: true, matiereId: 0));
    
    MatiereModel? matiereDuChapitre;
    if (chapitreParent.matiereId != 0 && matiereState.matieres.isNotEmpty) {
      try {
        matiereDuChapitre = matiereState.matieres.firstWhere((m) => m.id == chapitreParent.matiereId);
      } catch (e) { /* Peut arriver si la matière n'est pas encore chargée */ }
    }
    
    if ((_isEditing && !_isFormInitialized && _isLoadingLeconDetails && leconState.leconPourEdition == null) || 
        (!_isEditing && !_isFormInitialized && _currentSelectedChapitreId == null) ) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(semanticsLabel: "Chargement du formulaire...")),
      );
    }
    if (_isEditing && _isFormInitialized && leconState.leconPourEdition == null && widget.leconId != null && !leconState.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Erreur: Impossible de charger les détails de la leçon. ${leconState.errorMessage ?? 'Vérifiez votre connexion ou réessayez.'}", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: widget.onCancel ?? () => Navigator.of(context).pop(), child: const Text('Retour'))
        ])),
      );
    }
    if (_currentSelectedChapitreId == null) {
        return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("Erreur : ID du chapitre manquant. Impossible de continuer.", textAlign: TextAlign.center, style: TextStyle(color: Colors.red))));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true, // Important pour ListView dans un Column/Row ou autre contexte scrollable
          children: <Widget>[
            if (widget.onCancel != null) 
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0), 
                child: Align(
                  alignment: Alignment.topLeft, 
                  child: TextButton.icon(
                    icon: const Icon(Icons.arrow_back_ios, size: 16.0),
                    label: const Text("Retour"), 
                    onPressed: widget.onCancel, 
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, alignment: Alignment.centerLeft)
                  )
                )
              ),
            if (chapitreParent.nom != "Chargement...") 
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0), 
                child: Text("Matière: ${matiereDuChapitre?.nom ?? 'N/A'} > Chapitre: ${chapitreParent.nom}", 
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)
                )
              ),
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
                    _clearSelectedFile(); // Clear file if type changes, as allowed extensions might differ
                    // Preview related logic removed
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Type de leçon *', border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? 'Type requis' : null,
            ),
            const SizedBox(height: 16),
            // Section d'aperçu du contenu a été retirée
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Média (${_selectedLeconType.toUpperCase()})', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_selectedFileName != null) ...[
                  ListTile(
                    leading: Icon(Icons.insert_drive_file_outlined, color: Theme.of(context).colorScheme.primary),
                    title: Text(_selectedFileName!),
                    subtitle: const Text('Fichier local prêt à être téléversé.'),
                    trailing: IconButton(icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.error), 
                      tooltip: "Retirer le fichier sélectionné",
                      onPressed: () {
                        _clearSelectedFile();
                        // _urlMediaController.clear(); // Ne pas effacer l'URL, l'utilisateur pourrait vouloir la réutiliser
                      }
                    ),
                  ),
                  const SizedBox(height: 8), 
                  Center(child: Text("OU", style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant))), 
                  const SizedBox(height: 8),
                ],
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_selectedFileName == null ? 'Choisir un fichier (${_selectedLeconType.toUpperCase()})' : 'Changer le fichier'), 
                  onPressed: _pickFile, 
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40))
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlMediaController,
                  decoration: InputDecoration(
                    labelText: _selectedFileName == null ? 'URL du Média (si aucun fichier choisi)' : 'URL (sera ignorée car un fichier est choisi)',
                    hintText: 'https://exemple.com/mon_media.${_selectedLeconType}',
                    border: const OutlineInputBorder(), 
                    filled: _selectedFileName != null, 
                    fillColor: _selectedFileName != null ? Theme.of(context).colorScheme.onSurface.withOpacity(0.04) : null
                  ),
                  keyboardType: TextInputType.url, 
                  enabled: _selectedFileName == null,
                  validator: (value) {
                    if (_selectedFileName == null && (_selectedLeconType == 'video' || _selectedLeconType == 'pdf' || _selectedLeconType == 'audio') && (value == null || value.isEmpty)) return 'URL requise ou choisir un fichier';
                    if (value != null && value.isNotEmpty) {
                      final Uri? uri = Uri.tryParse(value);
                      if (uri == null || !uri.hasAbsolutePath || !uri.isAbsolute || !uri.toString().startsWith('http')) return 'URL invalide (doit commencer par http:// ou https://)';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _dureeEstimeeController, decoration: const InputDecoration(labelText: 'Durée Estimée (minutes)', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (value) => (value != null && value.isNotEmpty && int.tryParse(value) == null) ? 'Nombre invalide' : null),
            const SizedBox(height: 16),
            SwitchListTile(title: const Text('Actif'), subtitle: Text(_actif ? 'Leçon visible par les étudiants.' : 'Leçon masquée pour les étudiants.'), value: _actif, onChanged: (bool value) => setState(() => _actif = value), activeColor: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null) TextButton(onPressed: widget.onCancel, child: const Text('Annuler')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: leconState.isLoading ? null : _submitForm, 
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), 
                  child: leconState.isLoading 
                    ? const SizedBox(width: 20, height: 20, child:CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text(_isEditing ? 'Mettre à jour' : 'Ajouter')
                ),
              ],
            ),
            const SizedBox(height: 32), // Espace en bas
          ],
        ),
      ),
    );
  }
}
