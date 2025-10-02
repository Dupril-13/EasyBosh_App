import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/providers/filters_providers.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CreateEditEpreuvePage extends ConsumerStatefulWidget {
  final String? epreuveId;
  final VoidCallback onCancel;
  final VoidCallback onSubmitted;

  const CreateEditEpreuvePage({
    super.key, 
    this.epreuveId,
    required this.onCancel,
    required this.onSubmitted,
  });

  @override
  _CreateEditEpreuvePageState createState() => _CreateEditEpreuvePageState();
}

class _CreateEditEpreuvePageState extends ConsumerState<CreateEditEpreuvePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titreController;
  late TextEditingController _dureeController;
  late TextEditingController _descriptionController;
  late TextEditingController _anneeExamenController;
  late TextEditingController _nomEtablissementController;
  late TextEditingController _villeEtablissementController;

  EpreuveType? _selectedEpreuveType;
  NiveauSelectionItem? _selectedNiveauLocalUI;
  MatiereSelectionItem? _selectedMatiereLocalUI;
  Map<String, bool> _selectedSeriesMapUI = {}; 
  bool _isActif = true;
  TypeExamenOfficiel? _selectedTypeExamenOfficiel;
  DateTime? _selectedDateCompositionCollege;

  bool get _isEditing => widget.epreuveId != null;
  bool _isSeriesSelectionDisabled = false;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController();
    _dureeController = TextEditingController();
    _descriptionController = TextEditingController();
    _anneeExamenController = TextEditingController(text: DateTime.now().year.toString());
    _nomEtablissementController = TextEditingController();
    _villeEtablissementController = TextEditingController();

    if (_isEditing) {
      // TODO: Charger les données de l'épreuve et initialiser les champs
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _dureeController.dispose();
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

  void _changeYear(int amount) {
    int currentYear = int.tryParse(_anneeExamenController.text) ?? DateTime.now().year;
    currentYear += amount;
    if (currentYear > 2000 && currentYear <= DateTime.now().year + 1) {
      setState(() {
        _anneeExamenController.text = currentYear.toString();
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print('Formulaire valide, soumission en cours...');
      // TODO: Implémenter la sauvegarde
      widget.onSubmitted(); // Appel du callback
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

    seriesAsyncValue.whenData((seriesList) {
      if (_selectedSeriesMapUI.isEmpty && seriesList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedSeriesMapUI = { for (var serie in seriesList) serie.code : false };
            });
          }
        });
      }
    });

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Align(
            alignment: Alignment.topLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text("Retour à la liste"),
              onPressed: widget.onCancel, // Appel du callback
            ),
          ),
          const SizedBox(height: 16),
          Text('Informations Générales', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(controller: _titreController, decoration: const InputDecoration(labelText: 'Titre de l\'épreuve', border: OutlineInputBorder()), validator: (value) => (value == null || value.isEmpty) ? 'Titre requis.' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField<EpreuveType>(
            value: _selectedEpreuveType,
            decoration: const InputDecoration(labelText: 'Type d\'épreuve', border: OutlineInputBorder()),
            items: [EpreuveType.ancienSujet, EpreuveType.sujetCollege].map((EpreuveType type) {
              return DropdownMenuItem<EpreuveType>(value: type, child: Text(type.displayName));
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Série(s) concernée(s)', style: Theme.of(context).textTheme.titleMedium),
                  if (seriesList.isNotEmpty) ...seriesList.map((serie) => CheckboxListTile(
                        title: Text(serie.nomDisplay),
                        value: _isSeriesSelectionDisabled ? false : (_selectedSeriesMapUI[serie.code] ?? false),
                        onChanged: _isSeriesSelectionDisabled ? null : (bool? value) => setState(() => _selectedSeriesMapUI[serie.code] = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading, dense: true, enabled: !_isSeriesSelectionDisabled
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
              hint: const Text('Sélectionnez d\'abord niveau/série'),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur chargement matières: $err'),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _dureeController, decoration: const InputDecoration(labelText: 'Durée (minutes)', border: OutlineInputBorder(), hintText: 'Ex: 120'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0) ? 'Durée invalide.' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description / Consignes', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 4, minLines: 2),
          const SizedBox(height: 16),
          if (_selectedEpreuveType == EpreuveType.ancienSujet) ...[
            Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Détails - Ancien Sujet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anneeExamenController, 
                    decoration: const InputDecoration(labelText: 'Année Examen', border: OutlineInputBorder()), 
                    keyboardType: TextInputType.number, 
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) < 2000 || int.parse(v) > DateTime.now().year + 1) ? 'Année invalide.' : null,
                  ),
                ),
                IconButton(onPressed: () => _changeYear(-1), icon: const Icon(Icons.remove_circle_outline)),
                IconButton(onPressed: () => _changeYear(1), icon: const Icon(Icons.add_circle_outline)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TypeExamenOfficiel>(
              value: _selectedTypeExamenOfficiel,
              decoration: const InputDecoration(labelText: 'Type Examen Officiel', border: OutlineInputBorder()), 
              items: TypeExamenOfficiel.values.where((teo) {
                  final niveauCode = ref.watch(selectedNiveauCodeProvider); 
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
            ListTile(title: Text(_selectedDateCompositionCollege == null ? 'Date de Composition' : 'Date Composition: ${DateFormat('dd/MM/yyyy').format(_selectedDateCompositionCollege!)}'), trailing: const Icon(Icons.calendar_today), onTap: () async {
              final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDateCompositionCollege ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
              if (picked != null) setState(() => _selectedDateCompositionCollege = picked);
            }),
            const SizedBox(height: 16),
          ],

          Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Publication', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          SwitchListTile(
            title: const Text('Activer l\'épreuve'),
            subtitle: Text(_isActif ? 'L\'épreuve sera visible par les utilisateurs concernés.' : 'L\'épreuve sera enregistrée comme brouillon.'),
            value: _isActif,
            onChanged: (bool value) {
              setState(() {
                _isActif = value;
              });
            },
            secondary: Icon(_isActif ? Icons.check_circle_outline : Icons.unpublished_outlined),
          ),
          const SizedBox(height: 24),
          Center(child: ElevatedButton.icon(icon: const Icon(Icons.save_alt_outlined), label: Text(_isEditing ? 'Mettre à jour' : 'Sauvegarder'), onPressed: _submitForm, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)))),
        ],
      ),
    );
  }
}

extension EpreuveEnumDisplay on EpreuveType {
    String get displayName {
        switch (this) {
            case EpreuveType.ancienSujet: return 'Ancien Sujet d\'Examen';
            case EpreuveType.sujetCollege: return 'Sujet de Collège Connu';
            default: return toString().split('.').last;
        }
    }
}
