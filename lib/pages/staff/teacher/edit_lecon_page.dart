import 'dart:typed_data'; // Ajouté pour Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart'; // Ajouté pour FilePicker
import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/providers/lecon_provider.dart';
import 'package:easybosh_v2/providers/chapitre_provider.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';

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

  // Variables d'état pour le fichier sélectionné
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  
  int? _currentSelectedChapitreId; 
  bool _actif = true;
  int _currentOrdreForEditing = 0; 
  
  bool _isFormInitialized = false;
  bool _isLoadingLeconDetails = false;

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
    _selectedFileName = null;
    _selectedFileBytes = null;

    if (!_isEditing) {
      _isFormInitialized = true;
    } else {
       _isLoadingLeconDetails = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if(ref.read(matiereProvider).matieres.isEmpty) {
        await ref.read(matiereProvider.notifier).fetchMatieres();
      }
      final chapitreNotifier = ref.read(chapitreProvider.notifier);
      if (!chapitreNotifier.state.chapitres.any((ch) => ch.id == _currentSelectedChapitreId) && _currentSelectedChapitreId != null) {
          await chapitreNotifier.chargerChapitrePourEdition(_currentSelectedChapitreId!); 
      }

      if (_isEditing && widget.leconId != null) {
        await ref.read(leconProvider.notifier).chargerLeconPourEdition(widget.leconId!);
        if(mounted) setState(() => _isLoadingLeconDetails = false);
      } else {
         if(mounted) setState(() => _isFormInitialized = true); 
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
        _selectedFileName = null; // Réinitialiser en cas de changement de leçon à éditer
        _selectedFileBytes = null;
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
      withData: true, // Important pour récupérer les bytes
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
        _selectedFileBytes = result.files.single.bytes;
        _urlMediaController.clear(); // Un nouveau fichier a été choisi, l'ancienne URL n'est plus pertinente
      });
    } else {
      // L'utilisateur a annulé ou le fichier n'a pas pu être lu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier sélectionné ou erreur de lecture.')),
      );
    }
  }

  Future<void> _populateFormFields(LeconModel lecon) async {
    _nomController.text = lecon.nom;
    _descriptionController.text = lecon.description ?? '';
    _currentOrdreForEditing = lecon.ordre;
    _dureeEstimeeController.text = lecon.dureeEstimee?.toString() ?? '';
    _selectedLeconType = _leconTypes.contains(lecon.type) ? lecon.type : _leconTypes.first;
    _urlMediaController.text = lecon.urlMedia ?? ''; 
    _currentSelectedChapitreId = lecon.chapitreId; 
    _actif = lecon.actif;
    _selectedFileName = null; // Assurer qu'aucun fichier n'est présélectionné au chargement
    _selectedFileBytes = null;
    
    if (mounted) {
      setState(() {
        _isFormInitialized = true;
        _isLoadingLeconDetails = false;
      });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _dureeEstimeeController.dispose();
    _urlMediaController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_currentSelectedChapitreId == null) { 
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Chapitre ID manquant.'), backgroundColor: Colors.red));
        return;
      }
      _formKey.currentState!.save();

      final bool isCurrentlyEditing = _isEditing && widget.leconId != null;
      LeconModel? leconActuelleSiEdition = isCurrentlyEditing ? ref.read(leconProvider).leconPourEdition : null;

      if (isCurrentlyEditing && leconActuelleSiEdition == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Leçon à éditer non chargée.'), backgroundColor: Colors.red));
        return;
      }

      // Logique pour déterminer urlMedia en fonction de la sélection de fichier
      String? finalUrlMedia;
      if (_selectedFileBytes != null) {
        // Un nouveau fichier a été sélectionné. L'URL sera définie après le téléversement.
        // Pour l'instant, on la met à null ou une placeholder si nécessaire pour le backend.
        finalUrlMedia = null; 
        // Les _selectedFileBytes et _selectedFileName seront utilisés par le Notifier.
      } else {
        // Aucun nouveau fichier sélectionné, utiliser l'URL du controller (existante ou nouvelle)
        finalUrlMedia = _urlMediaController.text.isEmpty ? null : _urlMediaController.text;
      }

      final leconDetails = LeconModel(
        id: isCurrentlyEditing ? widget.leconId! : 0,
        nom: _nomController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        chapitreId: _currentSelectedChapitreId!,
        ordre: isCurrentlyEditing ? _currentOrdreForEditing : 0, 
        type: _selectedLeconType,
        urlMedia: finalUrlMedia, 
        contenu: null, 
        createdAt: isCurrentlyEditing ? leconActuelleSiEdition!.createdAt : DateTime.now(), 
        updatedAt: isCurrentlyEditing ? DateTime.now() : null, 
        dureeEstimee: _dureeEstimeeController.text.isEmpty ? null : int.tryParse(_dureeEstimeeController.text),
        actif: _actif, 
        createdBy: isCurrentlyEditing ? leconActuelleSiEdition!.createdBy : null,
        // Potentiellement, ajouter les champs temporaires pour le fichier si le modèle est adapté:
        // fileBytesToUpload: _selectedFileBytes,
        // fileNameToUpload: _selectedFileName,
      );

      bool success;
      // Modification pour passer le fichier au notifier (nécessitera une maj du notifier)
      if (isCurrentlyEditing) {
        success = await ref.read(leconProvider.notifier).updateLecon(
          leconDetails, 
          fileBytes: _selectedFileBytes, 
          fileName: _selectedFileName
        );
      } else {
        success = await ref.read(leconProvider.notifier).addLecon(
          leconDetails, 
          fileBytes: _selectedFileBytes, 
          fileName: _selectedFileName
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leçon ${ isCurrentlyEditing ? "mise à jour" : "ajoutée"} avec succès!'), backgroundColor: Colors.green));
          widget.onSubmitted?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${ref.read(leconProvider).errorMessage ?? "Une erreur inconnue s\'est produite."}'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LeconModel?>(
      leconProvider.select((s) => s.leconPourEdition),
       (previous, next) async {
        if (_isEditing && next != null && next.id == widget.leconId) {
          if(!_isFormInitialized || _nomController.text != next.nom || (ref.read(leconProvider).leconPourEdition?.id != next.id) ) {
            await _populateFormFields(next);
          }
        } else if (_isEditing && next == null && widget.leconId != null && !ref.read(leconProvider).isLoading) {
           if(mounted) {
            setState((){
              _isFormInitialized = true; 
              _isLoadingLeconDetails = false;
            });
          }
        }
      }
    );

    final leconNotifier = ref.watch(leconProvider.notifier); 
    final leconState = ref.watch(leconProvider); 
    final chapitreState = ref.watch(chapitreProvider); 

    final chapitreParent = chapitreState.chapitres.firstWhere((ch) => ch.id == _currentSelectedChapitreId, 
        orElse: () => chapitreState.chapitrePourEdition?.id == _currentSelectedChapitreId 
                      ? chapitreState.chapitrePourEdition! 
                      : ChapitreModel(id: _currentSelectedChapitreId ?? 0, nom: "Chargement...", ordre: 0, createdAt: DateTime.now(), actif: true)); 
    
    final matiereDuChapitre = ref.watch(matiereProvider).matieres.firstWhere((m) => m.id == chapitreParent.matiereId, 
        orElse: () => MatiereModel(id: 0, nom: "...", code: "", type: "", createdAt: DateTime.now()));

    if ((_isEditing && !_isFormInitialized && _isLoadingLeconDetails) || 
        (!_isFormInitialized && _currentSelectedChapitreId == null) ) { 
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(semanticsLabel: "Chargement du formulaire de leçon...")),
      );
    }

    if (_isEditing && _isFormInitialized && leconState.leconPourEdition == null && widget.leconId != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Erreur: Impossible de charger les détails de la leçon. ${leconState.errorMessage ?? ''}", style: TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: widget.onCancel, child: const Text('Retour'))
            ],
          )
        ),
      );
    }
    
    if (_currentSelectedChapitreId == null) {
        return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text("Erreur : L'ID du chapitre est manquant pour ce formulaire."))
        );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true, 
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
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft
                    ),
                  ),
                ),
              ),

            if (chapitreParent.nom != "Chargement...")
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  "Matière: ${matiereDuChapitre.nom} > Chapitre: ${chapitreParent.nom}",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom de la leçon *', border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? 'Nom requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLeconType,
              items: _leconTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLeconType = newValue;
                    _urlMediaController.clear();
                    _selectedFileName = null;
                    _selectedFileBytes = null;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Type de leçon *', border: OutlineInputBorder()),
               validator: (value) => value == null || value.isEmpty ? 'Type requis' : null,
            ),
            const SizedBox(height: 16),

            // Nouvelle section pour le média (fichier ou URL)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Média de la Leçon (${_selectedLeconType.toUpperCase()})', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_selectedFileName != null) ...[
                  ListTile(
                    leading: Icon(Icons.insert_drive_file_outlined, color: Theme.of(context).colorScheme.primary),
                    title: Text(_selectedFileName!),
                    subtitle: const Text('Nouveau fichier prêt à être téléversé'),
                    trailing: IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.error),
                      onPressed: () {
                        setState(() {
                          _selectedFileName = null;
                          _selectedFileBytes = null;
                          // L'URL dans _urlMediaController (si elle vient d'une leçon existante) reste.
                          // L'utilisateur devra explicitement la modifier ou en choisir une nouvelle si besoin.
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: Text("OU", style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                  const SizedBox(height: 8),
                ],
                
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_selectedFileName == null ? 'Choisir un fichier' : 'Changer le fichier'),
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40), // Bouton pleine largeur
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _urlMediaController,
                  decoration: InputDecoration(
                    labelText: _selectedFileName == null 
                        ? 'URL du Média (si aucun fichier choisi)' 
                        : 'URL actuelle (sera ignorée si le nouveau fichier est téléversé)',
                    border: const OutlineInputBorder(),
                    filled: _selectedFileName != null, // Griser si un fichier est sélectionné
                    fillColor: _selectedFileName != null ? Theme.of(context).colorScheme.onSurface.withOpacity(0.04) : null,
                  ),
                  keyboardType: TextInputType.url,
                  enabled: _selectedFileName == null, // Désactivé si un nouveau fichier est sélectionné et prioritaire
                  validator: (value) {
                    // Validation active seulement si aucun nouveau fichier n'est sélectionné
                    if (_selectedFileName == null && (value == null || value.isEmpty)) {
                      return 'URL requise ou choisir un fichier';
                    }
                    if (value != null && value.isNotEmpty) {
                      final Uri? uri = Uri.tryParse(value);
                      // Vérification URL plus robuste
                      if (uri == null || !uri.hasAbsolutePath || !uri.isAbsolute) { 
                        if (!uri.toString().startsWith('http')) { // Tolérer les URL non http pour certains cas ? Non, soyons stricts.
                           return 'URL invalide. Doit commencer par http:// ou https://';
                        }
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _dureeEstimeeController,
              decoration: const InputDecoration(labelText: 'Durée Estimée (minutes)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                  return 'Nombre invalide pour la durée';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Actif'),
              subtitle: Text(_actif ? 'La leçon sera visible par les étudiants.' : 'La leçon sera masquée.'),
              value: _actif,
              onChanged: (bool value) {
                setState(() {
                  _actif = value;
                });
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Annuler'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: leconNotifier.state.isLoading ? null : _submitForm, 
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: leconNotifier.state.isLoading 
                      ? const SizedBox(width: 20, height: 20, child:CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEditing ? 'Mettre à jour' : 'Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 32), 
          ],
        ),
      ),
    );
  }
}
