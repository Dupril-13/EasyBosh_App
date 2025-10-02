import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/providers/filters_providers.dart'; // Assurez-vous que c'est le bon chemin
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CreateEditEpreuvePage extends ConsumerStatefulWidget {
  final String? epreuveId;
  const CreateEditEpreuvePage({super.key, this.epreuveId});

  @override
  _CreateEditEpreuvePageState createState() => _CreateEditEpreuvePageState();
}

class _CreateEditEpreuvePageState extends ConsumerState<CreateEditEpreuvePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titreController;
  late TextEditingController _dureeController;
  late TextEditingController _baremeController;
  late TextEditingController _descriptionController;
  late TextEditingController _anneeExamenController;
  late TextEditingController _nomEtablissementController;
  late TextEditingController _villeEtablissementController;

  EpreuveType? _selectedEpreuveType;
  // _selectedNiveau et _selectedMatiere sont pour la valeur affichée dans les Dropdowns.
  // L'état logique pour le filtrage est dans les providers Riverpod.
  NiveauSelectionItem? _selectedNiveauLocalUI;
  MatiereSelectionItem? _selectedMatiereLocalUI;
  Map<String, bool> _selectedSeriesMapUI = {}; 
  EpreuveStatut _selectedStatut = EpreuveStatut.brouillon;
  String? _selectedSessionExamen;
  TypeExamenOfficiel? _selectedTypeExamenOfficiel;
  DateTime? _selectedDateCompositionCollege;
  DateTime? _selectedDatePublicationProgrammee;

  bool get _isEditing => widget.epreuveId != null;
  bool _isSeriesSelectionDisabled = false;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController();
    _dureeController = TextEditingController();
    _baremeController = TextEditingController();
    _descriptionController = TextEditingController();
    _anneeExamenController = TextEditingController();
    _nomEtablissementController = TextEditingController();
    _villeEtablissementController = TextEditingController();

    if (_isEditing) {
      // TODO: Charger les données de l'épreuve existante et initialiser les champs
      // et appeler ref.read(selectedNiveauCodeProvider.notifier).update(...) etc.
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _dureeController.dispose();
    _baremeController.dispose();
    _descriptionController.dispose();
    _anneeExamenController.dispose();
    _nomEtablissementController.dispose();
    _villeEtablissementController.dispose();
    super.dispose();
  }

  void _onNiveauChanged(NiveauSelectionItem? newValue) {
    setState(() {
      _selectedNiveauLocalUI = newValue;
      _selectedMatiereLocalUI = null; 
      _selectedSeriesMapUI.keys.forEach((key) => _selectedSeriesMapUI[key] = false);
      _isSeriesSelectionDisabled = (newValue?.code == '3eme');
      
      // Mettre à jour les providers Riverpod générés
      ref.read(selectedNiveauCodeProvider.notifier).update(newValue?.code);
      ref.read(selectedSeriesCodesForFilterProvider.notifier).update([]);

      if (_selectedTypeExamenOfficiel == TypeExamenOfficiel.bepc && newValue?.code != '3eme') {
        _selectedTypeExamenOfficiel = null;
      }
      if ((_selectedTypeExamenOfficiel == TypeExamenOfficiel.probatoire || _selectedTypeExamenOfficiel == TypeExamenOfficiel.baccalaureat) && newValue?.code == '3eme'){
        _selectedTypeExamenOfficiel = null;
      }
    });
  }

  void _onSerieChanged(String serieCode, bool isSelected) {
    setState(() {
      _selectedSeriesMapUI[serieCode] = isSelected;
      _selectedMatiereLocalUI = null; 
      final List<String> currentSelectedSeries = [];
      _selectedSeriesMapUI.forEach((key, value) {
        if (value) currentSelectedSeries.add(key);
      });
      // Mettre à jour le provider Riverpod généré
      ref.read(selectedSeriesCodesForFilterProvider.notifier).update(currentSelectedSeries);
    });
  }

  Future<void> _selectDate(BuildContext context, {required bool isDateComposition}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isDateComposition ? _selectedDateCompositionCollege : _selectedDatePublicationProgrammee) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isDateComposition) {
          _selectedDateCompositionCollege = picked;
        } else {
          _selectedDatePublicationProgrammee = picked;
          if (_selectedStatut == EpreuveStatut.brouillon) {
            _selectedStatut = EpreuveStatut.programmee;
          }
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Lire les valeurs des providers pour la soumission
      final String? niveauCodeFromProvider = ref.read(selectedNiveauCodeProvider);
      List<String> seriesCodesFromProvider = ref.read(selectedSeriesCodesForFilterProvider);
      List<String> seriesCodesForSubmission = [];

      if (niveauCodeFromProvider == null) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le niveau scolaire n\'a pas été correctement sélectionné.'), backgroundColor: Colors.red),
        );
        return;
      }

      if (niveauCodeFromProvider == '3eme') {
        seriesCodesForSubmission.add('TC');
      } else {
        seriesCodesForSubmission.addAll(seriesCodesFromProvider);
      }
      
      if (seriesCodesForSubmission.isEmpty && niveauCodeFromProvider != '3eme'){
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez sélectionner au moins une série.'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_selectedStatut == EpreuveStatut.programmee && _selectedDatePublicationProgrammee == null){
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez sélectionner une date de publication pour le statut "Programmēe".'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_selectedMatiereLocalUI == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez sélectionner une matière.'), backgroundColor: Colors.red),
        );
        return;
      }

      final epreuveSimulee = Epreuve(
        id: _isEditing ? int.tryParse(widget.epreuveId!) : null, 
        nom: _titreController.text,
        typeEpreuve: _selectedEpreuveType!,
        matiereId: _selectedMatiereLocalUI!.id, // Utiliser l'état local pour l'UI
        niveauCode: niveauCodeFromProvider, // Utiliser la valeur du provider
        seriesCodes: seriesCodesForSubmission, // Utiliser la valeur du provider
        dureeMinutes: int.tryParse(_dureeController.text) ?? 0,
        bareme: double.tryParse(_baremeController.text) ?? 20.0,
        description: _descriptionController.text,
        statut: _selectedStatut,
        datePublicationProgrammee: _selectedStatut == EpreuveStatut.programmee ? _selectedDatePublicationProgrammee : null,
        anneeExamen: _selectedEpreuveType == EpreuveType.ancienSujet ? int.tryParse(_anneeExamenController.text) : null,
        sessionExamen: _selectedEpreuveType == EpreuveType.ancienSujet ? _selectedSessionExamen : null,
        nomEtablissement: _selectedEpreuveType == EpreuveType.sujetCollege ? _nomEtablissementController.text : null,
        villeEtablissement: _selectedEpreuveType == EpreuveType.sujetCollege ? _villeEtablissementController.text : null,
        dateCompositionCollege: _selectedEpreuveType == EpreuveType.sujetCollege ? _selectedDateCompositionCollege : null,
      );
      
      print('Épreuve à sauvegarder (toMap): ${epreuveSimulee.toMap()} ');
      // TODO: Implémenter la logique de sauvegarde réelle

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Épreuve mise à jour (simulation)!' : 'Épreuve créée (simulation)!'), backgroundColor: Colors.green,)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez corriger les erreurs du formulaire.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final niveauxAsyncValue = ref.watch(niveauxProvider);
    final seriesAsyncValue = ref.watch(seriesForSelectionProvider);
    final matieresFiltreesAsyncValue = ref.watch(filteredMatieresListProvider);

    final String? currentNiveauCodeFromProvider = ref.watch(selectedNiveauCodeProvider);
    // final List<String> currentSeriesCodesFromProvider = ref.watch(selectedSeriesCodesForFilterProvider);

    seriesAsyncValue.whenData((seriesList) {
        bool needsInitialization = _selectedSeriesMapUI.isEmpty;
        if (!needsInitialization && _selectedSeriesMapUI.length != seriesList.length) {
            needsInitialization = true;
        }
        if (needsInitialization && seriesList.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                    setState(() {
                        _selectedSeriesMapUI.clear();
                        for (var serie in seriesList) {
                            _selectedSeriesMapUI[serie.code] = false;
                        }
                    });
                }
            });
        }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'Épreuve' : 'Créer une Épreuve'),
        actions: [IconButton(icon: const Icon(Icons.save_outlined), onPressed: _submitForm, tooltip: 'Sauvegarder')],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text('Informations Générales', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(controller: _titreController, decoration: const InputDecoration(labelText: 'Titre de l\'épreuve', border: OutlineInputBorder()), validator: (value) => (value == null || value.isEmpty) ? 'Titre requis.' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField<EpreuveType>(
            value: _selectedEpreuveType,
            decoration: const InputDecoration(labelText: 'Type d\'épreuve', border: OutlineInputBorder()),
            items: EpreuveType.values.map((EpreuveType type) {
              String displayName = type.toString().split('.').last;
              try { displayName = Epreuve(nom: '', typeEpreuve: type, matiereId:0, niveauCode:'',seriesCodes:[], dureeMinutes:0,bareme:0).typeEpreuveDisplay; } catch (e) {/*ignore*/}
              return DropdownMenuItem<EpreuveType>(value: type, child: Text(displayName));
            }).toList(),
            onChanged: (EpreuveType? newValue) => setState(() => _selectedEpreuveType = newValue),
            validator: (value) => value == null ? 'Type requis.' : null,
          ),
          const SizedBox(height: 16),
          
          niveauxAsyncValue.when(
            data: (niveaux) => DropdownButtonFormField<NiveauSelectionItem>(
              value: _selectedNiveauLocalUI,
              decoration: const InputDecoration(labelText: 'Niveau Scolaire', border: OutlineInputBorder()),
              items: niveaux.map((n) => DropdownMenuItem<NiveauSelectionItem>(value: n, child: Text(n.nomDisplay))).toList(),
              onChanged: _onNiveauChanged,
              validator: (value) => value == null ? 'Niveau requis.' : null,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur chargement niveaux: $err'),
          ),
          const SizedBox(height: 16),

          seriesAsyncValue.when(
            data: (seriesList) {
              if (seriesList.isNotEmpty && (_selectedSeriesMapUI.isEmpty || _selectedSeriesMapUI.length != seriesList.length) && currentNiveauCodeFromProvider != '3eme') {
                 return const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),));
              }
              if (seriesList.isEmpty && currentNiveauCodeFromProvider != null && currentNiveauCodeFromProvider != '3eme') {
                  return const Text("Aucune série disponible pour ce niveau (hors 3ème).");
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Série(s) concernée(s)', style: Theme.of(context).textTheme.titleMedium),
                  if (seriesList.isNotEmpty) ...seriesList.map((serie) => CheckboxListTile(
                        title: Text(serie.nomDisplay),
                        value: _isSeriesSelectionDisabled ? false : (_selectedSeriesMapUI[serie.code] ?? false),
                        onChanged: _isSeriesSelectionDisabled ? null : (bool? value) => _onSerieChanged(serie.code, value ?? false),
                        controlAffinity: ListTileControlAffinity.leading, 
                        dense: true, 
                        enabled: !_isSeriesSelectionDisabled
                      )).toList()
                  else if (currentNiveauCodeFromProvider != null && currentNiveauCodeFromProvider != '3eme') 
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("Pas de séries à sélectionner pour ce niveau.")),
                  if (currentNiveauCodeFromProvider == '3eme') 
                    Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 0, bottom: 8), 
                        child: Text('Série: Tronc Commun (TC) automatique.', style: TextStyle(color: Colors.grey.shade700))
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur chargement séries: $err'),
          ),
          const SizedBox(height: 16),

          matieresFiltreesAsyncValue.when(
            data: (matieres) => DropdownButtonFormField<MatiereSelectionItem>(
              value: _selectedMatiereLocalUI,
              decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()),
              items: matieres.map((m) => DropdownMenuItem<MatiereSelectionItem>(value: m, child: Text(m.nomDisplay))).toList(),
              onChanged: (MatiereSelectionItem? newValue) => setState(() => _selectedMatiereLocalUI = newValue),
              validator: (value) => value == null ? 'Matière requise.' : null,
              hint: matieres.isEmpty && (currentNiveauCodeFromProvider != null && (currentNiveauCodeFromProvider == '3eme' || (_selectedSeriesMapUI.values.where((s) => s).isNotEmpty))) 
                  ? const Text('Aucune matière pour la sélection') 
                  : ((currentNiveauCodeFromProvider == null || (currentNiveauCodeFromProvider != '3eme' && !_selectedSeriesMapUI.values.any((isSelected) => isSelected))) ? const Text('Sélectionnez niveau/séries d\'abord') : null),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur chargement matières: $err'),
          ),
          const SizedBox(height: 16),

          TextFormField(controller: _dureeController, decoration: const InputDecoration(labelText: 'Durée (minutes)', border: OutlineInputBorder(), hintText: 'Ex: 120'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0) ? 'Durée invalide.' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _baremeController, decoration: const InputDecoration(labelText: 'Barème total', border: OutlineInputBorder(), hintText: 'Ex: 20'), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+.?[0-9]*$'))], validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Barème invalide.' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description / Consignes', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 4, minLines: 2),
          const SizedBox(height: 16),
          
          if (_selectedEpreuveType == EpreuveType.ancienSujet) ...[
            Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Détails - Ancien Sujet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
            TextFormField(controller: _anneeExamenController, decoration: const InputDecoration(labelText: 'Année Examen', border: OutlineInputBorder(), hintText: 'Ex: 2023'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (_selectedEpreuveType == EpreuveType.ancienSujet && (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) < 2000 || int.parse(v) > DateTime.now().year + 1)) ? 'Année invalide.' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(value: _selectedSessionExamen, decoration: const InputDecoration(labelText: 'Session Examen', border: OutlineInputBorder()), items: ['Normale', 'Rattrapage'].map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(), onChanged: (val) => setState(() => _selectedSessionExamen = val), validator: (v) => (_selectedEpreuveType == EpreuveType.ancienSujet && v == null) ? 'Session requise.' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<TypeExamenOfficiel>(
              value: _selectedTypeExamenOfficiel,
              decoration: const InputDecoration(labelText: 'Type Examen Officiel', border: OutlineInputBorder()), 
              items: TypeExamenOfficiel.values.where((teo) {
                  final niveauCode = ref.watch(selectedNiveauCodeProvider); // Lire l'état directement
                  if (niveauCode == '3eme') return teo == TypeExamenOfficiel.bepc;
                  if (niveauCode == '1ere') return teo == TypeExamenOfficiel.probatoire;
                  if (niveauCode == 'tle') return teo == TypeExamenOfficiel.baccalaureat;
                  return niveauCode == null; 
              }).map((teo) => DropdownMenuItem<TypeExamenOfficiel>(value: teo, child: Text(Epreuve.typeExamenOfficielToString(teo)))).toList(), 
              onChanged: (val) => setState(() => _selectedTypeExamenOfficiel = val), 
              validator: (v) => (_selectedEpreuveType == EpreuveType.ancienSujet && v == null) ? 'Type d\'examen requis.' : null
            ),
            const SizedBox(height: 16),
          ],
          if (_selectedEpreuveType == EpreuveType.sujetCollege) ...[
            Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Détails - Sujet Collège', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
            TextFormField(controller: _nomEtablissementController, decoration: const InputDecoration(labelText: 'Nom Établissement', border: OutlineInputBorder()), validator: (v) => (_selectedEpreuveType == EpreuveType.sujetCollege &&(v == null || v.isEmpty)) ? 'Nom requis.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _villeEtablissementController, decoration: const InputDecoration(labelText: 'Ville/Région Établissement', border: OutlineInputBorder()), validator: (v) => (_selectedEpreuveType == EpreuveType.sujetCollege && (v == null || v.isEmpty)) ? 'Ville requise.' : null),
            const SizedBox(height: 16),
            ListTile(title: Text(_selectedDateCompositionCollege == null ? 'Date de Composition' : 'Date Composition: ${DateFormat('dd/MM/yyyy').format(_selectedDateCompositionCollege!)}'), trailing: const Icon(Icons.calendar_today), onTap: () => _selectDate(context, isDateComposition: true)),
            const SizedBox(height: 16),
          ],

          Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Publication et Statut', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          DropdownButtonFormField<EpreuveStatut>(
            value: _selectedStatut,
            decoration: const InputDecoration(labelText: 'Statut de l\'épreuve', border: OutlineInputBorder()),
            items: EpreuveStatut.values.map((s) => DropdownMenuItem<EpreuveStatut>(value: s, child: Text(Epreuve.statutToStringDisplay(s)))).toList(),
            onChanged: (val) {
                setState(() => _selectedStatut = val! );
                if (_selectedStatut != EpreuveStatut.programmee) { _selectedDatePublicationProgrammee = null; }
            },
            validator: (v) => v == null ? 'Statut requis.' : null,
          ),
          const SizedBox(height: 16),
          if (_selectedStatut == EpreuveStatut.programmee) ListTile(title: Text(_selectedDatePublicationProgrammee == null ? 'Date de Publication Programmée' : 'Publiée le: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedDatePublicationProgrammee!)}'), trailing: const Icon(Icons.calendar_today), onTap: () async {
            final DateTime? pickedDate = await showDatePicker(context: context, initialDate: _selectedDatePublicationProgrammee ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2101));
            if (pickedDate != null) {
              final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDatePublicationProgrammee ?? DateTime.now()));
              if (pickedTime != null) {
                setState(() => _selectedDatePublicationProgrammee = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
              }
            }
          }),
          const SizedBox(height: 24),
          Center(child: ElevatedButton.icon(icon: const Icon(Icons.save_alt_outlined), label: Text(_isEditing ? 'Mettre à jour' : 'Sauvegarder'), onPressed: _submitForm, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)))),
        ])), 
      ),
    );
  }
}

// Extension pour obtenir les noms affichables des enums (si non déjà dans Epreuve)
extension EpreuveEnumDisplay on EpreuveType {
    String get displayName {
        switch (this) {
            case EpreuveType.ancienSujet: return 'Ancien Sujet d\'Examen';
            case EpreuveType.sujetCollege: return 'Sujet de Collège Connu';
            case EpreuveType.examenBlanc: return 'Examen Blanc';
            case EpreuveType.epreuveExclusive: return 'Épreuve Exclusive';
            default: return toString().split('.').last;
        }
    }
}
