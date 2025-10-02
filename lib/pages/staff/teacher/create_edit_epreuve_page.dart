import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/pages/staff/teacher/manage_exams_page.dart'; // For providers
import 'package:easybosh_v2/providers/filters_providers.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
import 'package:easybosh_v2/services/epreuve_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

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

  PlatformFile? _sujetPdfFile;
  PlatformFile? _corrigePdfFile;
  String? _sujetNetworkUrl;
  String? _corrigeNetworkUrl;
  bool _isLoading = false;
  bool _dataLoaded = false;

  EpreuveType? _selectedEpreuveType;
  NiveauSelectionItem? _selectedNiveauLocalUI;
  MatiereSelectionItem? _selectedMatiereLocalUI;
  Map<String, bool> _selectedSeriesMapUI = {};
  bool _isActif = true;
  TypeExamenOfficiel? _selectedTypeExamenOfficiel;
  DateTime? _selectedDateCompositionCollege;

  bool get _isEditing => widget.epreuveId != null;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController();
    _dureeController = TextEditingController();
    _descriptionController = TextEditingController();
    _anneeExamenController = TextEditingController();
    _nomEtablissementController = TextEditingController();
    _villeEtablissementController = TextEditingController();

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEpreuveData());
    } else {
      _dataLoaded = true; // For creation mode, data is 'loaded' instantly
    }
  }

  void _loadEpreuveData() async {
    setState(() => _isLoading = true);
    try {
      final epreuveId = int.parse(widget.epreuveId!);
      final epreuve = await ref.read(epreuveServiceProvider).getEpreuveById(epreuveId);

      _titreController.text = epreuve.nom;
      _dureeController.text = epreuve.dureeMinutes.toString();
      _descriptionController.text = epreuve.description ?? '';
      _selectedEpreuveType = epreuve.typeEpreuve;

      final allNiveaux = await ref.read(niveauxProvider.future);
      final selectedNiveau = allNiveaux.firstWhere((n) => n.code == epreuve.niveauCode, orElse: () => allNiveaux.first);
      _selectedNiveauLocalUI = selectedNiveau;
      ref.read(selectedNiveauCodeExamsProvider.notifier).set(epreuve.niveauCode);
      
      final serieCodeForMatiere = epreuve.seriesCodes.isNotEmpty ? epreuve.seriesCodes.first : 'TC';
      await ref.read(matiereProvider.notifier).fetchMatieres(niveauCode: epreuve.niveauCode, serieCode: serieCodeForMatiere);
      
      final allMatieres = ref.read(matiereProvider).matieres;
      if (allMatieres.any((m) => m.id == epreuve.matiereId)) {
        final epreuveMatiere = allMatieres.firstWhere((m) => m.id == epreuve.matiereId);
        _selectedMatiereLocalUI = MatiereSelectionItem(id: epreuveMatiere.id, nomDisplay: epreuveMatiere.nom);
      }

      final allSeries = await ref.read(seriesForSelectionProvider.future);
      _selectedSeriesMapUI = { for (var s in allSeries) s.code : epreuve.seriesCodes.contains(s.code) };

      _isActif = epreuve.statut == EpreuveStatut.publiee;
      _sujetNetworkUrl = epreuve.sujetPdfUrl;
      _corrigeNetworkUrl = epreuve.corrigePdfUrl;

      if (epreuve.typeEpreuve == EpreuveType.ancienSujet) {
        _anneeExamenController.text = epreuve.anneeExamen?.toString() ?? DateTime.now().year.toString();
        _selectedTypeExamenOfficiel = Epreuve.stringToTypeExamenOfficiel(epreuve.sessionExamen);
      }

      if (epreuve.typeEpreuve == EpreuveType.sujetCollege) {
        _nomEtablissementController.text = epreuve.nomEtablissement ?? '';
        _villeEtablissementController.text = epreuve.villeEtablissement ?? '';
        _selectedDateCompositionCollege = epreuve.dateCompositionCollege;
      }
      _dataLoaded = true;
    } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur de chargement de l\'épreuve: $e"), backgroundColor: Colors.red));
    } finally {
        if(mounted) setState(() => _isLoading = false);
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

  Future<void> _pickSujetFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) setState(() {
      _sujetPdfFile = result.files.first;
      _sujetNetworkUrl = null;
    });
  }

  Future<void> _pickCorrigeFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) setState(() {
       _corrigePdfFile = result.files.first;
       _corrigeNetworkUrl = null;
    });
  }

  void _onNiveauChanged(NiveauSelectionItem? newValue) {
    setState(() {
      _selectedNiveauLocalUI = newValue;
      _selectedMatiereLocalUI = null;
      if (_selectedSeriesMapUI.isNotEmpty) {
        _selectedSeriesMapUI.keys.forEach((key) => _selectedSeriesMapUI[key] = false);
      }
      
      ref.read(selectedNiveauCodeExamsProvider.notifier).set(newValue?.code);

      final newSerieCode = (newValue?.code == '3eme') ? 'TC' : null;
      ref.read(selectedSerieCodeExamsProvider.notifier).set(newSerieCode);

      if(newValue != null && newSerieCode != null) {
        ref.read(matiereProvider.notifier).fetchMatieres(niveauCode: newValue.code, serieCode: newSerieCode);
      } else if (newValue != null) {
        ref.read(matiereProvider.notifier).clearDataAndError();
      }
    });
  }

  void _onSerieChanged(String serieCode, bool isSelected) {
    setState(() {
      _selectedSeriesMapUI[serieCode] = isSelected;
      _selectedMatiereLocalUI = null;
      final selectedSeries = _selectedSeriesMapUI.entries.where((e) => e.value).map((e) => e.key).toList();
      ref.read(selectedSerieCodeExamsProvider.notifier).set(selectedSeries.isNotEmpty ? selectedSeries.first : null);

      if(_selectedNiveauLocalUI != null && selectedSeries.isNotEmpty) {
        ref.read(matiereProvider.notifier).fetchMatieres(niveauCode: _selectedNiveauLocalUI!.code, serieCode: selectedSeries.first);
      } else {
        ref.read(matiereProvider.notifier).clearDataAndError();
      }
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _sujetPdfFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le fichier PDF du sujet est obligatoire pour une nouvelle épreuve.'), backgroundColor: Colors.red));
        return;
    }

    setState(() => _isLoading = true);

    final selectedSeries = _selectedSeriesMapUI.entries.where((e) => e.value).map((e) => e.key).toList();
    if (_selectedNiveauLocalUI?.code == '3eme' && !selectedSeries.contains('TC')) selectedSeries.add('TC');

    final epreuveData = {
      'nom': _titreController.text,
      'type': Epreuve.typeToString(_selectedEpreuveType!),
      'niveau_code': _selectedNiveauLocalUI!.code,
      'series_codes': selectedSeries,
      'matiere_id': _selectedMatiereLocalUI!.id,
      'duree': int.parse(_dureeController.text),
      'description': _descriptionController.text,
      'statut': _isActif ? 'publiee' : 'brouillon',
      'annee': _selectedEpreuveType == EpreuveType.ancienSujet ? int.tryParse(_anneeExamenController.text) : null,
      'session': _selectedEpreuveType == EpreuveType.ancienSujet && _selectedTypeExamenOfficiel != null ? Epreuve.typeExamenOfficielToString(_selectedTypeExamenOfficiel!) : null,
      'nom_etablissement': _selectedEpreuveType == EpreuveType.sujetCollege ? _nomEtablissementController.text : null,
      'ville_etablissement': _selectedEpreuveType == EpreuveType.sujetCollege ? _villeEtablissementController.text : null,
      'date_composition_college': _selectedEpreuveType == EpreuveType.sujetCollege && _selectedDateCompositionCollege != null ? _selectedDateCompositionCollege!.toIso8601String() : null,
    };

    try {
      final epreuveService = ref.read(epreuveServiceProvider);
      if (_isEditing) {
        await epreuveService.updateEpreuve(int.parse(widget.epreuveId!), epreuveData, _sujetPdfFile, _corrigePdfFile);
      } else {
        await epreuveService.createEpreuve(epreuveData, _sujetPdfFile!, _corrigePdfFile);
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Épreuve ${ _isEditing ? "mise à jour" : "créée"} avec succès!'), backgroundColor: Colors.green));
      widget.onSubmitted();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_dataLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final niveauxAsyncValue = ref.watch(niveauxProvider);
    final seriesAsyncValue = ref.watch(seriesForSelectionProvider);
    final matieresState = ref.watch(matiereProvider);

    return Form(
      key: _formKey,
      child: AbsorbPointer(
        absorbing: _isLoading,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: TextButton.icon(icon: const Icon(Icons.arrow_back), label: const Text("Retour à la liste"), onPressed: widget.onCancel),
                ),
                const SizedBox(height: 16),
                Text(_isEditing ? 'Modifier l\'épreuve' : 'Créer une nouvelle épreuve', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                TextFormField(controller: _titreController, decoration: const InputDecoration(labelText: 'Titre de l\'épreuve', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Titre requis.' : null),
                const SizedBox(height: 16),
                DropdownButtonFormField<EpreuveType>(
                  value: _selectedEpreuveType,
                  decoration: const InputDecoration(labelText: 'Type d\'épreuve', border: OutlineInputBorder()),
                  items: [EpreuveType.ancienSujet, EpreuveType.sujetCollege].map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
                  onChanged: (v) => setState(() => _selectedEpreuveType = v),
                  validator: (v) => v == null ? 'Type requis.' : null,
                ),
                const SizedBox(height: 16),
                 niveauxAsyncValue.when(
                  data: (niveaux) => DropdownButtonFormField<NiveauSelectionItem>(
                    value: _selectedNiveauLocalUI,
                    items: niveaux.map((n) => DropdownMenuItem(value: n, child: Text(n.nomDisplay))).toList(),
                    onChanged: _onNiveauChanged,
                    decoration: const InputDecoration(labelText: 'Niveau Scolaire', border: OutlineInputBorder()),
                    validator: (v) => v == null ? 'Niveau requis.' : null,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Erreur chargement niveaux: $err'),
                ),
                const SizedBox(height: 16),
                seriesAsyncValue.when(
                  data: (seriesList) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Série(s) concernée(s)', style: Theme.of(context).textTheme.titleMedium),
                      ...seriesList.map((serie) => CheckboxListTile(
                        title: Text(serie.nomDisplay),
                        value: _selectedNiveauLocalUI?.code == '3eme' && serie.code == 'TC' ? true : (_selectedSeriesMapUI[serie.code] ?? false),
                        onChanged: _selectedNiveauLocalUI?.code == '3eme' ? null : (val) => _onSerieChanged(serie.code, val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      )).toList(),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (err, st) => Text('Erreur chargement séries: $err'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MatiereSelectionItem>(
                  value: _selectedMatiereLocalUI,
                  items: matieresState.matieres.map((m) => DropdownMenuItem(value: MatiereSelectionItem(id: m.id, nomDisplay: m.nom), child: Text(m.nom))).toList(),
                  onChanged: (v) => setState(() => _selectedMatiereLocalUI = v),
                  decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()),
                  validator: (v) => v == null ? 'Matière requise.' : null,
                  hint: Text(matieresState.isLoading ? 'Chargement...' : (matieresState.errorMessage ?? 'Sélectionnez d\'abord niveau/série')),
                ),
                const SizedBox(height: 16),
                TextFormField(controller: _dureeController, decoration: const InputDecoration(labelText: 'Durée (minutes)', border: OutlineInputBorder(), hintText: 'Ex: 120'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0) ? 'Durée invalide.' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description / Consignes', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 4, minLines: 2),
                const SizedBox(height: 16),
                _buildFileUploadField(
                  label: 'Sujet de l\'épreuve (PDF)',
                  file: _sujetPdfFile,
                  networkUrl: _sujetNetworkUrl,
                  onPickFile: _pickSujetFile,
                  onRemoveFile: () => setState(() { _sujetPdfFile = null; _sujetNetworkUrl = null; }),
                  isMandatory: !_isEditing,
                ),
                const SizedBox(height: 16),
                _buildFileUploadField(
                  label: 'Corrigé de l\'épreuve (PDF, Optionnel)',
                  file: _corrigePdfFile,
                  networkUrl: _corrigeNetworkUrl,
                  onPickFile: _pickCorrigeFile,
                  onRemoveFile: () => setState(() { _corrigePdfFile = null; _corrigeNetworkUrl = null; }),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _isLoading ? null : widget.onCancel, child: const Text('Annuler')),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.publish_outlined),
                      label: Text(_isEditing ? 'Mettre à jour' : 'Publier'),
                      onPressed: _isLoading ? null : _submitForm,
                    ),
                  ],
                ),
              ],
            ),
            if (_isLoading) Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadField({
    required String label,
    PlatformFile? file,
    String? networkUrl,
    required VoidCallback onPickFile,
    required VoidCallback onRemoveFile,
    bool isMandatory = false,
  }) {
    final String? fileName = file?.name ?? (networkUrl != null ? p.basename(networkUrl) : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Text(label, style: Theme.of(context).textTheme.titleMedium), if (isMandatory) const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(child: Text(fileName ?? 'Aucun fichier sélectionné', overflow: TextOverflow.ellipsis)),
              if (fileName != null)
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: onRemoveFile)
              else
                TextButton(child: const Text('Choisir'), onPressed: onPickFile),
            ],
          ),
        ),
      ],
    );
  }
}
