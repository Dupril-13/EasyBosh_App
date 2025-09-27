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
  final int? matiereIdInitial;
  final VoidCallback? onSubmitted; // Callback pour la soumission réussie
  final VoidCallback? onCancel;    // Callback pour l'annulation

  const EditChapitrePage({
    super.key, 
    this.chapitreId,
    this.matiereIdInitial,
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
      if (widget.matiereIdInitial != null) {
        _selectedMatiereId = widget.matiereIdInitial;
      }
      _isFormInitialized = true; 
    } else {
      _isLoadingChapitreDetails = true; 
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        ref.read(matiereProvider.notifier).fetchMatieres(),
        ref.read(niveauProvider.notifier).fetchNiveaux(),
        ref.read(serieProvider.notifier).fetchSeries(),
      ]);

      if (_isEditing && widget.chapitreId != null) {
        await ref.read(chapitreProvider.notifier).chargerChapitrePourEdition(widget.chapitreId!);
        if (mounted) {
          setState(() {
            _isLoadingChapitreDetails = false;
          });
        }
      } else {
         if (mounted) {
            setState(() {
                 _isFormInitialized = true;
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
         if (mounted) {
          setState(() {
            _isLoadingChapitreDetails = false;
          });
        }
      });
    } else if (!_isEditing && widget.matiereIdInitial != _selectedMatiereId) {
        setState(() {
            _selectedMatiereId = widget.matiereIdInitial;
        });
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
      if (_selectedMatiereId == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une matière.'), backgroundColor: Colors.red));
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
        matiereId: _selectedMatiereId,
        ordre: _isEditing ? chapitreActuelSiEdition!.ordre : 0, 
        actif: _actif,
        niveauCode: _selectedNiveauCode,
        serieCode: _selectedSerieCode,
        dureeEstimee: _dureeEstimeeController.text.isEmpty ? null : int.tryParse(_dureeEstimeeController.text),
        objectifs: objectifs.isEmpty ? null : objectifs,
        prerequis: prerequis.isEmpty ? null : prerequis,
        createdAt: _isEditing ? chapitreActuelSiEdition!.createdAt : DateTime.now(),
        updatedAt: _isEditing ? DateTime.now() : null,
        createdBy: _isEditing ? chapitreActuelSiEdition!.createdBy : null,
      );

      bool success;
      if (_isEditing) {
        success = await ref.read(chapitreProvider.notifier).updateChapitre(chapitreDetails);
      } else {
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
          if (!_isFormInitialized || _nomController.text != next.nom) { 
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

    final chapitreNotifier = ref.watch(chapitreProvider.notifier); 
    final chapitreState = ref.watch(chapitreProvider); 

    final matiereState = ref.watch(matiereProvider);
    final niveauState = ref.watch(niveauProvider);
    final serieState = ref.watch(serieProvider);

    final List<MatiereModel> matieres = matiereState.matieres;
    final List<NiveauModel> niveaux = niveauState.niveaux;
    final List<SerieModel> series = serieState.series;

    if ((_isEditing && !_isFormInitialized && _isLoadingChapitreDetails) || 
        (!_isEditing && !_isFormInitialized && (matiereState.isLoading || niveauState.isLoading || serieState.isLoading))) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(semanticsLabel: "Chargement du formulaire...")),
      );
    }
    
    if (_isEditing && _isFormInitialized && chapitreState.chapitrePourEdition == null && widget.chapitreId != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Erreur: Impossible de charger les détails du chapitre pour modification. ${chapitreState.errorMessage ?? ''}", style: TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: widget.onCancel, child: const Text('Retour'))
            ],
          )
        ),
      );
    }
    
    if (_selectedNiveauCode != null && niveaux.isNotEmpty && !niveaux.any((n) => n.code == _selectedNiveauCode)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedNiveauCode = null);
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
          shrinkWrap: true, // Maintenu pour une meilleure intégration
          children: <Widget>[
            // Bouton Retour en haut
            if (widget.onCancel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.arrow_back_ios, size: 16.0), // Petite icône
                    label: const Text("Retour"),
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      // Ajuster le style pour qu'il ressemble à un lien discret
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft
                    ),
                  ),
                ),
              ),

            if (matiereState.isLoading && matieres.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Chargement des matières...")))
            else if (matiereState.errorMessage != null && matieres.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Erreur matières: ${matiereState.errorMessage}', style: const TextStyle(color: Colors.red)))
            else if (matieres.isEmpty && !matiereState.isLoading)
               const ListTile(title: Text("Aucune matière disponible. Créez-en une d'abord."))
            else
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
                onChanged: (int? newValue) => setState(() => _selectedMatiereId = newValue),
                validator: (value) => value == null ? 'Matière requise' : null,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Matière *'),
              ),
            const SizedBox(height: 16),

            if (niveauState.isLoading && niveaux.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Chargement des niveaux...")))
            else if (niveauState.errorMessage != null && niveaux.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Erreur niveaux: ${niveauState.errorMessage}', style: const TextStyle(color: Colors.red)))
            else if (niveaux.isEmpty && !niveauState.isLoading)
               const ListTile(title: Text('Aucun niveau disponible.'))
            else
              DropdownButtonFormField<String?>(
                value: _selectedNiveauCode,
                hint: const Text('Sélectionner un niveau'), 
                isExpanded: true,
                items: niveaux.map((NiveauModel niveau) {
                  return DropdownMenuItem<String?>(
                    value: niveau.code,
                    child: Text(niveau.nom),
                  );
                }).toList(),
                onChanged: (String? newValue) => setState(() => _selectedNiveauCode = newValue),
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Niveau'),
              ),
            const SizedBox(height: 16),

            if (serieState.isLoading && series.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Chargement des séries...")))
            else if (serieState.errorMessage != null && series.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Erreur séries: ${serieState.errorMessage}', style: const TextStyle(color: Colors.red)))
            else if (series.isEmpty && !serieState.isLoading)
               const ListTile(title: Text('Aucune série disponible.'))
            else
              DropdownButtonFormField<String?>(
                value: _selectedSerieCode,
                hint: const Text('Sélectionner une série'), 
                isExpanded: true,
                items: series.map((SerieModel serie) {
                  return DropdownMenuItem<String?>(
                    value: serie.code,
                    child: Text(serie.nom),
                  );
                }).toList(),
                onChanged: (String? newValue) => setState(() => _selectedSerieCode = newValue),
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Série'),
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
                  onPressed: chapitreNotifier.state.isLoading ? null : _submitForm, 
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: chapitreNotifier.state.isLoading 
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
