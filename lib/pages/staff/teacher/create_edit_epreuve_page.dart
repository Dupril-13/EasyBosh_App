import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/pages/staff/teacher/manage_exams_page.dart';
import 'package:easybosh_v2/providers/filters_providers.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
import 'package:easybosh_v2/services/epreuve_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _selectedEtablissement;
  bool _showCustomEtablissementField = false;

  final List<Map<String, String>> _etablissementsCameroun = [
    {'nom': 'Autre (Personnalisé)', 'ville': ''},
    {'nom': 'Collège Vogt', 'ville': 'Yaoundé'},
    {'nom': 'Lycée Général Leclerc', 'ville': 'Yaoundé'},
    {'nom': 'Lycée Joss', 'ville': 'Douala'},
    {'nom': 'Collège de la Retraite', 'ville': 'Yaoundé'},
    {'nom': 'Lycée Bilingue de Yaoundé', 'ville': 'Yaoundé'},
    {'nom': 'Collège Adventiste de Yaoundé', 'ville': 'Yaoundé'},
    {'nom': 'Collège François Xavier Vogt', 'ville': 'Yaoundé'},
    {'nom': 'Lycée Classique de Bafoussam', 'ville': 'Bafoussam'},
    {'nom': 'Lycée de Maroua', 'ville': 'Maroua'},
    {'nom': 'Lycée Bilingue de Buea', 'ville': 'Buea'},
    {'nom': 'Collège Jean Tabi', 'ville': 'Yaoundé'},
    {'nom': 'Lycée de Bamenda', 'ville': 'Bamenda'},
    {'nom': 'Collège Libermann', 'ville': 'Douala'},
    {'nom': 'Lycée de Garoua', 'ville': 'Garoua'},
    {'nom': 'Collège Saint Michel', 'ville': 'Yaoundé'},
    {'nom': 'Lycée de Ngaoundéré', 'ville': 'Ngaoundéré'},
    {'nom': 'Collège de la Salle', 'ville': 'Douala'},
    {'nom': 'Lycée Bilingue de Kribi', 'ville': 'Kribi'},
    {'nom': 'Collège Saint Benoît', 'ville': 'Yaoundé'},
    {'nom': 'Lycée de Limbé', 'ville': 'Limbé'},
  ];

  bool get _isEditing => widget.epreuveId != null;

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEpreuveData());
    } else {
      _dataLoaded = true;
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
        final etablissementFromDB = epreuve.nomEtablissement ?? '';
        final etablissementExists = _etablissementsCameroun.any((e) => e['nom'] == etablissementFromDB);
        if (etablissementExists) {
          _selectedEtablissement = etablissementFromDB;
          final etablissement = _etablissementsCameroun.firstWhere((e) => e['nom'] == etablissementFromDB);
          _villeEtablissementController.text = etablissement['ville'] ?? '';
        } else {
          _selectedEtablissement = 'Autre (Personnalisé)';
          _showCustomEtablissementField = true;
          _nomEtablissementController.text = etablissementFromDB;
          _villeEtablissementController.text = epreuve.villeEtablissement ?? '';
        }
        _selectedDateCompositionCollege = epreuve.dateCompositionCollege;
      }
      _dataLoaded = true;
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (result != null) {
      PlatformFile file = result.files.first;
      if (kIsWeb && file.bytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur de chargement'), backgroundColor: Colors.red));
        return;
      }
      setState(() { _sujetPdfFile = file; _sujetNetworkUrl = null; });
    }
  }

  Future<void> _pickCorrigeFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (result != null) {
      PlatformFile file = result.files.first;
      if (kIsWeb && file.bytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur de chargement'), backgroundColor: Colors.red));
        return;
      }
      setState(() { _corrigePdfFile = file; _corrigeNetworkUrl = null; });
    }
  }

  void _onNiveauChanged(NiveauSelectionItem? newValue) {
    setState(() {
      _selectedNiveauLocalUI = newValue;
      _selectedMatiereLocalUI = null;
      if (_selectedSeriesMapUI.isNotEmpty) _selectedSeriesMapUI.keys.forEach((key) => _selectedSeriesMapUI[key] = false);
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

  void _onEtablissementChanged(String? value) {
    setState(() {
      _selectedEtablissement = value;
      if (value == 'Autre (Personnalisé)') {
        _showCustomEtablissementField = true;
        _nomEtablissementController.clear();
        _villeEtablissementController.clear();
      } else {
        _showCustomEtablissementField = false;
        final etablissement = _etablissementsCameroun.firstWhere((e) => e['nom'] == value);
        _villeEtablissementController.text = etablissement['ville'] ?? '';
      }
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _sujetPdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF sujet requis'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    final selectedSeries = _selectedSeriesMapUI.entries.where((e) => e.value).map((e) => e.key).toList();
    if (_selectedNiveauLocalUI?.code == '3eme' && !selectedSeries.contains('TC')) selectedSeries.add('TC');
    String? nomEtablissement;
    if (_selectedEpreuveType == EpreuveType.sujetCollege) {
      nomEtablissement = _showCustomEtablissementField ? _nomEtablissementController.text : _selectedEtablissement;
    }
    final epreuveData = {
      'nom': _titreController.text,
      'type': Epreuve.typeToString(_selectedEpreuveType!),
      'niveau_code': _selectedNiveauLocalUI!.code,
      'series_codes': selectedSeries,
      'matiere_id': _selectedMatiereLocalUI!.id,
      'duree': int.parse(_dureeController.text),
      'description': _descriptionController.text,
      'statut': _isActif ? 'publiee' : 'brouillon',
      'annee': _selectedEpreuveType == EpreuveType.ancienSujet ? (int.tryParse(_anneeExamenController.text) ?? DateTime.now().year) : DateTime.now().year,
      'session': _selectedEpreuveType == EpreuveType.ancienSujet && _selectedTypeExamenOfficiel != null ? Epreuve.typeExamenOfficielToString(_selectedTypeExamenOfficiel!) : null,
      'nom_etablissement': nomEtablissement,
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
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Épreuve ${_isEditing ? "mise à jour" : "créée"}!'), backgroundColor: Colors.green));
      widget.onSubmitted();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_dataLoaded) return const Center(child: SizedBox(width: 50, height: 50, child: CircularProgressIndicator()));
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
                Align(alignment: Alignment.topLeft, child: TextButton.icon(icon: const Icon(Icons.arrow_back), label: const Text("Retour"), onPressed: widget.onCancel)),
                const SizedBox(height: 16),
                Text(_isEditing ? 'Modifier l\'épreuve' : 'Créer une épreuve', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextFormField(controller: _titreController, decoration: const InputDecoration(labelText: 'Titre', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requis' : null),
                const SizedBox(height: 16),
                DropdownButtonFormField<EpreuveType>(value: _selectedEpreuveType, decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()), items: [EpreuveType.ancienSujet, EpreuveType.sujetCollege].map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(), onChanged: (v) => setState(() => _selectedEpreuveType = v), validator: (v) => v == null ? 'Requis' : null),
                const SizedBox(height: 16),
                niveauxAsyncValue.when(
                    data: (niveaux) => DropdownButtonFormField<NiveauSelectionItem>(value: _selectedNiveauLocalUI, items: niveaux.map((n) => DropdownMenuItem(value: n, child: Text(n.nomDisplay))).toList(), onChanged: _onNiveauChanged, decoration: const InputDecoration(labelText: 'Niveau', border: OutlineInputBorder()), validator: (v) => v == null ? 'Requis' : null),
                    loading: () => const SizedBox(height: 60, child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))),
                    error: (err, _) => Text('Erreur: $err')
                ),
                const SizedBox(height: 16),
                seriesAsyncValue.when(data: (seriesList) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Série(s)', style: Theme.of(context).textTheme.titleMedium), ...seriesList.map((serie) => CheckboxListTile(title: Text(serie.nomDisplay), value: _selectedNiveauLocalUI?.code == '3eme' && serie.code == 'TC' ? true : (_selectedSeriesMapUI[serie.code] ?? false), onChanged: _selectedNiveauLocalUI?.code == '3eme' ? null : (val) => _onSerieChanged(serie.code, val ?? false), controlAffinity: ListTileControlAffinity.leading))]), loading: () => const SizedBox.shrink(), error: (err, _) => Text('Erreur: $err')),
                const SizedBox(height: 16),
                DropdownButtonFormField<MatiereSelectionItem>(value: _selectedMatiereLocalUI, items: matieresState.matieres.map((m) => DropdownMenuItem(value: MatiereSelectionItem(id: m.id, nomDisplay: m.nom), child: Text(m.nom))).toList(), onChanged: (v) => setState(() => _selectedMatiereLocalUI = v), decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()), validator: (v) => v == null ? 'Requis' : null, hint: Text(matieresState.isLoading ? 'Chargement...' : (matieresState.errorMessage ?? 'Sélectionnez niveau/série'))),
                const SizedBox(height: 16),
                TextFormField(controller: _dureeController, decoration: const InputDecoration(labelText: 'Durée (min)', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0) ? 'Invalide' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 4, minLines: 2),
                if (_selectedEpreuveType == EpreuveType.ancienSujet) ...[
                  const SizedBox(height: 16),
                  TextFormField(controller: _anneeExamenController, decoration: const InputDecoration(labelText: 'Année *', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) { if (v == null || v.isEmpty) return 'Requis'; final year = int.tryParse(v); if (year == null || year < 2000 || year > DateTime.now().year + 1) return 'Invalide'; return null; }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TypeExamenOfficiel>(value: _selectedTypeExamenOfficiel, decoration: const InputDecoration(labelText: 'Examen *', border: OutlineInputBorder()), items: TypeExamenOfficiel.values.map((type) { String label = type == TypeExamenOfficiel.bepc ? 'BEPC' : type == TypeExamenOfficiel.probatoire ? 'Probatoire' : 'Baccalauréat'; return DropdownMenuItem(value: type, child: Text(label)); }).toList(), onChanged: (v) => setState(() => _selectedTypeExamenOfficiel = v), validator: (v) => v == null ? 'Requis' : null),
                ],
                if (_selectedEpreuveType == EpreuveType.sujetCollege) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(value: _selectedEtablissement, decoration: const InputDecoration(labelText: 'Établissement *', border: OutlineInputBorder()), items: _etablissementsCameroun.map((e) => DropdownMenuItem(value: e['nom'], child: Text(e['nom']!))).toList(), onChanged: _onEtablissementChanged, validator: (v) => v == null ? 'Requis' : null),
                  if (_showCustomEtablissementField) ...[const SizedBox(height: 16), TextFormField(controller: _nomEtablissementController, decoration: const InputDecoration(labelText: 'Nom personnalisé *', border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null)],
                  const SizedBox(height: 16),
                  TextFormField(controller: _villeEtablissementController, decoration: InputDecoration(labelText: 'Ville', border: const OutlineInputBorder(), enabled: _showCustomEtablissementField)),
                  const SizedBox(height: 16),
                  Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)), child: ListTile(title: const Text('Date'), subtitle: Text(_selectedDateCompositionCollege != null ? DateFormat('dd/MM/yyyy').format(_selectedDateCompositionCollege!) : 'Non définie'), trailing: const Icon(Icons.calendar_today), onTap: () async { final picked = await showDatePicker(context: context, initialDate: _selectedDateCompositionCollege ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365))); if (picked != null) setState(() => _selectedDateCompositionCollege = picked); })),
                ],
                const SizedBox(height: 16),
                _buildFileUploadField(label: 'Sujet (PDF)', file: _sujetPdfFile, networkUrl: _sujetNetworkUrl, onPickFile: _pickSujetFile, onRemoveFile: () => setState(() { _sujetPdfFile = null; _sujetNetworkUrl = null; }), isMandatory: !_isEditing),
                const SizedBox(height: 16),
                _buildFileUploadField(label: 'Corrigé (PDF)', file: _corrigePdfFile, networkUrl: _corrigeNetworkUrl, onPickFile: _pickCorrigeFile, onRemoveFile: () => setState(() { _corrigePdfFile = null; _corrigeNetworkUrl = null; })),
                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: _isLoading ? null : widget.onCancel, child: const Text('Annuler')), const SizedBox(width: 12), ElevatedButton.icon(icon: const Icon(Icons.publish_outlined), label: Text(_isEditing ? 'Mettre à jour' : 'Publier'), onPressed: _isLoading ? null : _submitForm)]),
              ],
            ),
            if (_isLoading) Container(color: Colors.black.withOpacity(0.5), child: const Center(child: SizedBox(width: 50, height: 50, child: CircularProgressIndicator()))),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadField({required String label, PlatformFile? file, String? networkUrl, required VoidCallback onPickFile, required VoidCallback onRemoveFile, bool isMandatory = false}) {
    final String? fileName = file?.name ?? (networkUrl != null ? p.basename(networkUrl) : null);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(label, style: Theme.of(context).textTheme.titleMedium), if (isMandatory) const Text(' *', style: TextStyle(color: Colors.red))]), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.picture_as_pdf_outlined, color: Colors.red.shade700), const SizedBox(width: 12), Expanded(child: Text(fileName ?? 'Aucun fichier', overflow: TextOverflow.ellipsis)), if (fileName != null) IconButton(icon: const Icon(Icons.close, size: 20), onPressed: onRemoveFile) else TextButton(child: const Text('Choisir'), onPressed: onPickFile)]))]);
  }
}