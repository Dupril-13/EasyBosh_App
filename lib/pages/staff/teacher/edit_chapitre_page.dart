import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/models/niveau_model.dart';
import 'package:easybosh_v2/models/serie_model.dart';
import 'package:easybosh_v2/providers/chapitre_provider.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
import 'package:easybosh_v2/providers/niveau_provider.dart';
import 'package:easybosh_v2/providers/serie_provider.dart';

class EditChapitrePage extends ConsumerStatefulWidget {
  final int? chapitreId;
  final int? matiereIdInitial; // Matière sélectionnée sur la page précédente
  final String? initialNiveauCode; // Niveau sélectionné sur la page précédente
  final String? initialSerieCode;  // Série sélectionnée sur la page précédente
  final VoidCallback? onSubmitted;
  final VoidCallback? onCancel;

  const EditChapitrePage({
    super.key, 
    this.chapitreId,
    this.matiereIdInitial,
    this.initialNiveauCode, // Ajouté
    this.initialSerieCode,  // Ajouté
    this.onSubmitted,
    this.onCancel,
  });

  @override
  ConsumerState<EditChapitrePage> createState() => _EditChapitrePageState();
}

class _EditChapitrePageState extends ConsumerState<EditChapitrePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _dureeEstimeeController;
  
  List<TextEditingController> _objectifsControllers = [];
  List<TextEditingController> _prerequisControllers = [];

  int? _selectedMatiereId;
  String? _selectedNiveauCode;
  String? _selectedSerieCode;
  bool _actif = true; 

  bool _isFormInitialized = false;
  bool _isLoadingChapitreDetails = false;

  bool get _isEditing => widget.chapitreId != null;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _descriptionController = TextEditingController();
    _dureeEstimeeController = TextEditingController();
    
    if (!_isEditing) {
      _addControllerToList(_objectifsControllers, callSetState: false);
      _addControllerToList(_prerequisControllers, callSetState: false);
      // Initialiser avec les valeurs passées pour un nouveau chapitre
      _selectedMatiereId = widget.matiereIdInitial;
      _selectedNiveauCode = widget.initialNiveauCode;
      _selectedSerieCode = widget.initialSerieCode;
      _isFormInitialized = true; 
    } else {
      _isLoadingChapitreDetails = true; 
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // S'assurer que les listes de base pour les dropdowns sont chargées
      // En mode édition, ces dropdowns seront désactivés mais afficheront les noms corrects.
      // En mode ajout, ils seront aussi désactivés et pré-remplis.
      bool needMatiereFetch = ref.read(matiereProvider).matieres.isEmpty;
      bool needNiveauFetch = ref.read(niveauProvider).niveaux.isEmpty;
      bool needSerieFetch = ref.read(serieProvider).series.isEmpty;

      List<Future> fetches = [];
      if (needMatiereFetch) fetches.add(ref.read(matiereProvider.notifier).fetchMatieres());
      if (needNiveauFetch) fetches.add(ref.read(niveauProvider.notifier).fetchNiveaux());
      if (needSerieFetch) fetches.add(ref.read(serieProvider.notifier).fetchSeries());
      
      if (fetches.isNotEmpty) await Future.wait(fetches);

      if (_isEditing && widget.chapitreId != null) {
        await ref.read(chapitreProvider.notifier).chargerChapitrePourEdition(widget.chapitreId!);
        // _populateFormFields sera appelé via le listener sur chapitrePourEdition
        // Cependant, si le chapitre n'est pas trouvé, _isLoadingChapitreDetails doit être false
        if (mounted && ref.read(chapitreProvider).chapitrePourEdition == null) {
           setState(() { _isLoadingChapitreDetails = false; _isFormInitialized = true; });
        }
      } else {
         if (mounted) {
            setState(() {
                 _isFormInitialized = true; // Déjà fait plus haut pour !_isEditing
            });
         }
      }
    });
  }
  
  @override
  void didUpdateWidget(covariant EditChapitrePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEditing && widget.chapitreId != oldWidget.chapitreId && widget.chapitreId != null) {
      setState(() {
        _isFormInitialized = false; 
        _isLoadingChapitreDetails = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(chapitreProvider.notifier).chargerChapitrePourEdition(widget.chapitreId!);
         if (mounted && ref.read(chapitreProvider).chapitrePourEdition == null) {
          setState(() {
            _isLoadingChapitreDetails = false; _isFormInitialized = true;
          });
        }
      });
    } else if (!_isEditing) {
        bool changed = false;
        if (widget.matiereIdInitial != _selectedMatiereId) {
            _selectedMatiereId = widget.matiereIdInitial; changed = true;
        }
        if (widget.initialNiveauCode != _selectedNiveauCode) {
            _selectedNiveauCode = widget.initialNiveauCode; changed = true;
        }
        if (widget.initialSerieCode != _selectedSerieCode) {
            _selectedSerieCode = widget.initialSerieCode; changed = true;
        }
        if (changed && mounted) setState(() {});
    }
  }

  void _addControllerToList(List<TextEditingController> controllers, {String initialText = '', bool callSetState = true}) {
    controllers.add(TextEditingController(text: initialText));
    if (callSetState && mounted) {
      setState(() {});
    }
  }

  void _removeControllerFromList(List<TextEditingController> controllers, int index) {
    if (index < controllers.length) {
      controllers[index].dispose();
      controllers.removeAt(index);
      if (mounted) setState(() {});
    }
  }

  void _populateFormFields(ChapitreModel chapitre) {
    _nomController.text = chapitre.nom;
    _descriptionController.text = chapitre.description ?? '';
    _selectedMatiereId = chapitre.matiereId;
    _actif = chapitre.actif;
    _selectedNiveauCode = chapitre.niveauCode; 
    _selectedSerieCode = chapitre.serieCode;   
    _dureeEstimeeController.text = chapitre.dureeEstimee?.toString() ?? '';

    for (var controller in _objectifsControllers) { controller.dispose(); }
    _objectifsControllers = [];
    if (chapitre.objectifs != null && chapitre.objectifs!.isNotEmpty) {
      for (var objectif in chapitre.objectifs!) {
        _addControllerToList(_objectifsControllers, initialText: objectif, callSetState: false);
      }
    } else {
      _addControllerToList(_objectifsControllers, callSetState: false); 
    }

    for (var controller in _prerequisControllers) { controller.dispose(); }
    _prerequisControllers = [];
    if (chapitre.prerequis != null && chapitre.prerequis!.isNotEmpty) {
      for (var prerequisItem in chapitre.prerequis!) {
        _addControllerToList(_prerequisControllers, initialText: prerequisItem, callSetState: false);
      }
    } else {
      _addControllerToList(_prerequisControllers, callSetState: false); 
    }
    if(mounted){
        setState(() {
            _isFormInitialized = true; 
            _isLoadingChapitreDetails = false; 
        });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _dureeEstimeeController.dispose();
    for (var controller in _objectifsControllers) { controller.dispose(); }
    for (var controller in _prerequisControllers) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Validation cruciale pour le contexte
      if (_selectedMatiereId == null || _selectedNiveauCode == null || _selectedSerieCode == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matière, Niveau et Série sont requis pour enregistrer le chapitre.'), backgroundColor: Colors.red));
        return;
      }
      _formKey.currentState!.save();

      ChapitreModel? chapitreActuelSiEdition = _isEditing ? ref.read(chapitreProvider).chapitrePourEdition : null;

      if (_isEditing && chapitreActuelSiEdition == null && widget.chapitreId != null) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Chapitre à éditer non chargé.'), backgroundColor: Colors.red));
        return;
      }

      List<String> objectifs = _objectifsControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
      List<String> prerequis = _prerequisControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

      final chapitreDetails = ChapitreModel(
        id: _isEditing ? widget.chapitreId! : 0,
        nom: _nomController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        matiereId: _selectedMatiereId, // Validé non null
        ordre: _isEditing ? chapitreActuelSiEdition!.ordre : 0, 
        actif: _actif,
        niveauCode: _selectedNiveauCode, // Validé non null
        serieCode: _selectedSerieCode,   // Validé non null
        dureeEstimee: _dureeEstimeeController.text.isEmpty ? null : int.tryParse(_dureeEstimeeController.text),
        objectifs: objectifs.isEmpty ? null : objectifs,
        prerequis: prerequis.isEmpty ? null : prerequis,
        createdAt: _isEditing ? chapitreActuelSiEdition!.createdAt : DateTime.now(), // La DB gère createdAt pour les nouveaux
        updatedAt: _isEditing ? DateTime.now() : null, // La DB gère updatedAt
        createdBy: _isEditing ? chapitreActuelSiEdition!.createdBy : null, // La DB gère created_by pour les nouveaux (via trigger/default ou provider)
      );

      bool success;
      if (_isEditing) {
        success = await ref.read(chapitreProvider.notifier).updateChapitre(chapitreDetails);
      } else {
        // Pour addChapitre, createdBy sera ajouté par le provider si l'utilisateur est connecté
        success = await ref.read(chapitreProvider.notifier).addChapitre(chapitreDetails);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chapitre ${ _isEditing ? "mis à jour" : "ajouté"} avec succès!'), backgroundColor: Colors.green));
          widget.onSubmitted?.call(); 
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${ref.read(chapitreProvider).errorMessage ?? "Une erreur inconnue s\'est produite."}'), backgroundColor: Colors.red));
        }
      }
    }
  }
  
  Widget _buildDynamicFieldList(BuildContext context, List<TextEditingController> controllers, String labelSingulier, String labelPluriel, VoidCallback addFieldCallback) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelPluriel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controllers[index],
                      decoration: InputDecoration(
                        labelText: '$labelSingulier ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (controllers.length > 1 || (labelSingulier == "Objectif" && controllers.length >=1) || (labelSingulier == "Prérequis" && controllers.length >=1)) 
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _removeControllerFromList(controllers, index),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: Text('Ajouter un $labelSingulier'),
            onPressed: addFieldCallback,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChapitreModel?>(
      chapitreProvider.select((s) => s.chapitrePourEdition),
      (previous, next) {
        if (_isEditing && next != null && next.id == widget.chapitreId) {
          // Comparer avec plus de champs si nécessaire pour éviter rebuilds inutiles
          if (!_isFormInitialized || _nomController.text != next.nom || _selectedNiveauCode != next.niveauCode) { 
             _populateFormFields(next);
          }
        } else if (_isEditing && next == null && widget.chapitreId != null && !ref.read(chapitreProvider).isLoading) {
          if(mounted) {
            setState((){
              _isFormInitialized = true; 
              _isLoadingChapitreDetails = false;
            });
          }
        }
      }
    );

    final chapitreNotifierState = ref.watch(chapitreProvider); 
    final matiereState = ref.watch(matiereProvider);
    final niveauState = ref.watch(niveauProvider);
    final serieState = ref.watch(serieProvider);

    final List<MatiereModel> matieres = matiereState.matieres;
    final List<NiveauModel> niveaux = niveauState.niveaux;
    final List<SerieModel> series = serieState.series;

    if (!_isFormInitialized || (_isEditing && _isLoadingChapitreDetails)) {
        return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(semanticsLabel: "Chargement du formulaire..."))
        );
    }
    
    if (_isEditing && chapitreNotifierState.chapitrePourEdition == null && widget.chapitreId != null && !chapitreNotifierState.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Erreur: Impossible de charger les détails du chapitre. ${chapitreNotifierState.errorMessage ?? ''}", style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: widget.onCancel, child: const Text('Retour'))
            ],
          )
        ),
      );
    }
    
    // S'assurer que les valeurs sélectionnées sont valides si les listes sont chargées
    if (_selectedNiveauCode != null && niveaux.isNotEmpty && !niveaux.any((n) => n.code == _selectedNiveauCode)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedNiveauCode = null); // ou widget.initialNiveauCode si pertinent et !_isEditing
      });
    }
    if (_selectedSerieCode != null && series.isNotEmpty && !series.any((s) => s.code == _selectedSerieCode)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedSerieCode = null);
      });
    }
    if (_selectedMatiereId != null && matieres.isNotEmpty && !matieres.any((m) => m.id == _selectedMatiereId)) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedMatiereId = null);
      });
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
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, alignment: Alignment.centerLeft),
                  ),
                ),
              ),

            // Matière Dropdown
            DropdownButtonFormField<int?>(
              value: _selectedMatiereId,
              hint: const Text('Sélectionner une matière *'),
              isExpanded: true,
              items: matieres.map((MatiereModel matiere) {
                return DropdownMenuItem<int?>(
                  value: matiere.id,
                  child: Text(matiere.nom),
                );
              }).toList(),
              // En mode édition, la matière ne doit pas être changée ici.
              // En mode ajout, elle est initialisée par matiereIdInitial et pourrait être modifiable
              // ou aussi désactivée si le contexte est strictement hérité.
              // Pour l'instant, on la désactive en édition.
              onChanged: _isEditing ? null : (int? newValue) => setState(() => _selectedMatiereId = newValue),
              validator: (value) => value == null ? 'Matière requise' : null,
              decoration: InputDecoration(
                labelText: 'Matière *',
                border: const OutlineInputBorder(),
                filled: _isEditing, // Griser si désactivé
                fillColor: _isEditing ? Colors.grey[200] : null,
              ),
            ),
            const SizedBox(height: 16),

            // Niveau Dropdown
            DropdownButtonFormField<String?>(
              value: _selectedNiveauCode,
              hint: const Text('Sélectionner un niveau *'), 
              isExpanded: true,
              items: niveaux.map((NiveauModel niveau) {
                return DropdownMenuItem<String?>(
                  value: niveau.code,
                  child: Text(niveau.nom),
                );
              }).toList(),
              // Niveau est fixé par le contexte, non modifiable ici.
              onChanged: null, // Toujours désactivé
              validator: (value) => value == null ? 'Niveau requis' : null,
              decoration: InputDecoration(
                labelText: 'Niveau *',
                border: const OutlineInputBorder(),
                filled: true, // Toujours grisé car non modifiable ici
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),

            // Série Dropdown
            DropdownButtonFormField<String?>(
              value: _selectedSerieCode,
              hint: const Text('Sélectionner une série *'), 
              isExpanded: true,
              items: series.map((SerieModel serie) {
                return DropdownMenuItem<String?>(
                  value: serie.code,
                  child: Text(serie.nom),
                );
              }).toList(),
              // Série est fixée par le contexte, non modifiable ici.
              onChanged: null, // Toujours désactivé
              validator: (value) => value == null ? 'Série requise' : null,
              decoration: InputDecoration(
                labelText: 'Série *',
                border: const OutlineInputBorder(),
                filled: true, // Toujours grisé car non modifiable ici
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: 'Nom du chapitre *', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.isEmpty) ? 'Nom du chapitre requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dureeEstimeeController,
              decoration: const InputDecoration(labelText: 'Durée Estimée (minutes)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) => (value != null && value.isNotEmpty && int.tryParse(value) == null) ? 'Durée invalide' : null,
            ),
            const SizedBox(height: 24),

            _buildDynamicFieldList(context, _objectifsControllers, 'Objectif', 'Objectifs Pédagogiques', () => _addControllerToList(_objectifsControllers)),
            const SizedBox(height: 24),

            _buildDynamicFieldList(context, _prerequisControllers, 'Prérequis', 'Prérequis du Chapitre', () => _addControllerToList(_prerequisControllers)),
            const SizedBox(height: 24),

            SwitchListTile(
              title: const Text('Actif'),
              subtitle: Text(_actif ? 'Le chapitre sera visible.' : 'Le chapitre sera masqué.'),
              value: _actif,
              onChanged: (bool val) => setState(() => _actif = val),
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
                  onPressed: chapitreNotifierState.isLoading ? null : _submitForm, 
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: chapitreNotifierState.isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
