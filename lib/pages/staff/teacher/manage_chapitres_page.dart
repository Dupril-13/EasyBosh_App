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

class ManageChapitresPage extends ConsumerStatefulWidget {
  final Function(ChapitreModel chapitre) onChapitreSelected;
  final String? initialNiveauCode;
  final String? initialSerieCode;
  final int? initialMatiereId; 
  final Function(String? newNiveauCode, String? newSerieCode, int? newMatiereId)? onFiltersChanged;
  final VoidCallback? onAddChapitre;
  final Function(ChapitreModel chapitre)? onEditChapitre;

  const ManageChapitresPage({
    super.key,
    required this.onChapitreSelected,
    this.initialNiveauCode,
    this.initialSerieCode,
    this.initialMatiereId,
    this.onFiltersChanged,
    this.onAddChapitre,
    this.onEditChapitre,
  });

  @override
  ConsumerState<ManageChapitresPage> createState() => _ManageChapitresPageState();
}

class _ManageChapitresPageState extends ConsumerState<ManageChapitresPage> {
  String? _selectedNiveauCode;
  String? _selectedSerieCode;
  int? _selectedMatiereId;

  @override
  void initState() {
    super.initState();
    _selectedNiveauCode = widget.initialNiveauCode;
    if (_selectedNiveauCode == '3eme') {
      _selectedSerieCode = widget.initialSerieCode ?? 'TC'; 
    } else {
      _selectedSerieCode = widget.initialSerieCode;
    }
    _selectedMatiereId = widget.initialMatiereId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool niveauFetched = false;
      bool serieFetched = false;

      if (ref.read(niveauProvider).niveaux.isEmpty) {
        await ref.read(niveauProvider.notifier).fetchNiveaux();
        niveauFetched = true;
      }
      if (ref.read(serieProvider).series.isEmpty) {
        await ref.read(serieProvider.notifier).fetchSeries();
        serieFetched = true;
      }
      
      if (mounted && (niveauFetched || serieFetched)) {
         setState(() {}); 
      }
      
      final niveaux = ref.read(niveauProvider).niveaux;
      final series = ref.read(serieProvider).series;

      if (_selectedNiveauCode != null && !niveaux.any((n) => n.code == _selectedNiveauCode)) {
          _selectedNiveauCode = null;
          _selectedSerieCode = null; 
          _selectedMatiereId = null; 
      }
      if (_selectedNiveauCode == '3eme') {
          if (!series.any((s) => s.code == 'TC')) {
             _selectedSerieCode = null; 
          } else {
             _selectedSerieCode = 'TC'; 
          }
      } else if (_selectedSerieCode != null && !series.any((s) => s.code == _selectedSerieCode)) {
          _selectedSerieCode = null;
          _selectedMatiereId = null; 
      }

      String? effectiveSerieCodeForFetch = _selectedSerieCode;
      if (_selectedNiveauCode == '3eme') {
         effectiveSerieCodeForFetch = 'TC'; 
      }

      if (_selectedNiveauCode != null && effectiveSerieCodeForFetch != null) {
        await ref.read(matiereProvider.notifier).fetchMatieres(
          niveauCode: _selectedNiveauCode!,
          serieCode: effectiveSerieCodeForFetch
        );
        if (mounted) setState((){}); 

        if (_selectedMatiereId != null && !ref.read(matiereProvider).matieres.any((m) => m.id == _selectedMatiereId)){
            _selectedMatiereId = null; 
        }
        if (mounted) setState((){});

        _fetchFilteredChapitres(); 

      } else {
        ref.read(matiereProvider.notifier).clearDataAndError(); 
        ref.read(chapitreProvider.notifier).clearChapitres();
      }
      widget.onFiltersChanged?.call(_selectedNiveauCode, _selectedSerieCode, _selectedMatiereId);
    });
  }
  
  void _fetchFilteredMatieresAndChapitres() {
    String? serieCodeToFetch = _selectedSerieCode;
    if (_selectedNiveauCode == '3eme') {
      serieCodeToFetch = 'TC'; 
    }

    if (_selectedNiveauCode != null && serieCodeToFetch != null) {
      ref.read(matiereProvider.notifier).fetchMatieres(
        niveauCode: _selectedNiveauCode!,
        serieCode: serieCodeToFetch
      ).then((_) {
        if (mounted) {
          bool matiereChanged = false;
          if (_selectedMatiereId != null && !ref.read(matiereProvider).matieres.any((m) => m.id == _selectedMatiereId)) {
            _selectedMatiereId = null;
            matiereChanged = true;
          }
          if(matiereChanged && mounted) {
            setState(() {}); 
          }
        }
        _fetchFilteredChapitres(); 
        widget.onFiltersChanged?.call(_selectedNiveauCode, _selectedSerieCode, _selectedMatiereId);
      });
    } else {
      ref.read(matiereProvider.notifier).clearDataAndError();
      ref.read(chapitreProvider.notifier).clearChapitres();
      widget.onFiltersChanged?.call(_selectedNiveauCode, _selectedSerieCode, _selectedMatiereId);
    }
  }

  void _fetchFilteredChapitres() {
    String? effectiveSerieCode = _selectedSerieCode;
    if (_selectedNiveauCode == '3eme') {
      effectiveSerieCode = 'TC'; 
    }

    if (_selectedMatiereId != null && _selectedNiveauCode != null && effectiveSerieCode != null) {
      ref.read(chapitreProvider.notifier).fetchChapitres(
        _selectedMatiereId!,
        niveauCode: _selectedNiveauCode, 
        serieCode: effectiveSerieCode     
      );
    } else {
      ref.read(chapitreProvider.notifier).clearChapitres();
    }
     widget.onFiltersChanged?.call(_selectedNiveauCode, _selectedSerieCode, _selectedMatiereId);
  }

  void _onNiveauChanged(String? newNiveauCode) {
    if (newNiveauCode == _selectedNiveauCode) return;
    setState(() {
      _selectedNiveauCode = newNiveauCode;
      _selectedMatiereId = null; 
      if (newNiveauCode == '3eme') {
        _selectedSerieCode = 'TC'; 
      } else {
        _selectedSerieCode = null; 
      }
    });
    _fetchFilteredMatieresAndChapitres();
  }

  void _onSerieChanged(String? newSerieCode) {
    if (_selectedNiveauCode == '3eme') return; 
    if (newSerieCode == _selectedSerieCode) return;
    setState(() {
      _selectedSerieCode = newSerieCode;
      _selectedMatiereId = null; 
    });
    _fetchFilteredMatieresAndChapitres();
  }

  void _onMatiereChanged(int? newMatiereId) {
    if (newMatiereId == _selectedMatiereId) return;
    setState(() {
      _selectedMatiereId = newMatiereId;
    });
    _fetchFilteredChapitres(); 
  }
  
  List<DropdownMenuItem<String?>> _buildSerieDropdownItems(List<SerieModel> allSeries, String? currentNiveauCode) {
    if (currentNiveauCode == null) {
      return [const DropdownMenuItem<String?>(value: null, child: Text("Sélectionner un niveau d'abord", style: TextStyle(color: Colors.grey)))]; 
    }
    if (currentNiveauCode == '3eme') {
      final tcSerie = allSeries.firstWhere((s) => s.code == 'TC', 
                        orElse: () => SerieModel(id: -1, code: 'TC', nom: 'Tronc Commun', type: 'Tronc Commun')); 
      return [DropdownMenuItem<String?>(
        value: tcSerie.code,
        child: Text(tcSerie.nom, overflow: TextOverflow.ellipsis),
      )];
    }

    return allSeries
        .where((serie) => serie.code != 'TC') 
        .map((serie) {
          String displayName = serie.nom;
          if (serie.code == 'TI' && serie.nom.contains('(Informatique)')) {
            displayName = 'Série TI'; 
          }
          return DropdownMenuItem<String?>(
            value: serie.code,
            child: Text(displayName, overflow: TextOverflow.ellipsis),
          );
        }).toList();
  }

  Widget _buildAddChapterButton(BuildContext context) {
    String? currentSerieCode = _selectedSerieCode;
    if (_selectedNiveauCode == '3eme') currentSerieCode = 'TC';

    bool canAdd = _selectedNiveauCode != null && currentSerieCode != null && _selectedMatiereId != null;

    return ElevatedButton.icon(
      onPressed: canAdd && widget.onAddChapitre != null 
                 ? widget.onAddChapitre 
                 : null, 
      icon: const Icon(Icons.add),
      label: const Text('Ajouter Chapitre'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapitreState = ref.watch(chapitreProvider);
    final matiereState = ref.watch(matiereProvider);
    final niveauState = ref.watch(niveauProvider);
    final serieState = ref.watch(serieProvider);

    final List<NiveauModel> niveaux = niveauState.niveaux;
    final List<SerieModel> seriesRaw = serieState.series; 
    final List<MatiereModel> matieres = matiereState.matieres;
    
    String? effectiveSerieCode = _selectedSerieCode;
    if (_selectedNiveauCode == '3eme') {
      effectiveSerieCode = 'TC';
    }

    final bool filtersFullySelected = _selectedNiveauCode != null && effectiveSerieCode != null && _selectedMatiereId != null;
    final bool canReorder = filtersFullySelected && chapitreState.chapitres.isNotEmpty; 

    Widget content;
    String loadingMessage = "Chargement des filtres...";
    if (niveauState.isLoading && niveaux.isEmpty) loadingMessage = "Chargement des niveaux...";
    else if (serieState.isLoading && seriesRaw.isEmpty) loadingMessage = "Chargement des séries...";
    else if (matiereState.isLoading && matieres.isEmpty && _selectedNiveauCode != null && effectiveSerieCode != null) loadingMessage = "Chargement des matières...";
    else if (chapitreState.isLoading && _selectedMatiereId != null) loadingMessage = "Chargement des chapitres..."; 

    bool mainLoading = (niveauState.isLoading && niveaux.isEmpty) || 
                       (serieState.isLoading && seriesRaw.isEmpty) || 
                       (matiereState.isLoading && matieres.isEmpty && _selectedNiveauCode != null && effectiveSerieCode != null && _selectedMatiereId == null) || 
                       (chapitreState.isLoading && _selectedMatiereId != null); 

    if (mainLoading) {
      content = Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(semanticsLabel: loadingMessage), const SizedBox(height:10), Text(loadingMessage)]));
    } else if (_selectedNiveauCode == null ) {
       content = const Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Icons.filter_list_off_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Veuillez sélectionner un Niveau pour commencer.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                ],
            ),
        );
    } else if (effectiveSerieCode == null && _selectedNiveauCode != '3eme') { 
       content = const Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                     Icon(Icons.filter_list_off_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Veuillez sélectionner une Série pour ce niveau.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                ],
            ),
        );
    } else if (matieres.isEmpty && !matiereState.isLoading && _selectedNiveauCode != null && effectiveSerieCode != null) {
        content = const Center(child: Text("Aucune matière disponible pour ce niveau et cette série.", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,));
    } else if (_selectedMatiereId == null && _selectedNiveauCode != null && effectiveSerieCode != null) {
        content = const Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Icons.filter_list_off_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Veuillez sélectionner une Matière.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                ],
            ),
        );
    } else if (chapitreState.chapitres.isEmpty && !chapitreState.isLoading && filtersFullySelected) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Aucun chapitre trouvé pour cette sélection.', style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
            const SizedBox(height: 8),
            if (widget.onAddChapitre != null)
              const Text('Vous pouvez en ajouter un en utilisant le bouton ci-dessus.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    } else if (chapitreState.errorMessage != null && filtersFullySelected) {
        content = Center(child: Text("Erreur lors du chargement des chapitres: ${chapitreState.errorMessage}", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,));
    }
    else {
      final List<ChapitreModel> currentChapitres = chapitreState.chapitres;
      content = ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: currentChapitres.length,
        itemBuilder: (context, index) {
          final chapitre = currentChapitres[index];
          return Card(
            key: ValueKey(chapitre.id),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white)), 
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              title: Text(chapitre.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                chapitre.description ?? 'Pas de description',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.secondary),
                    tooltip: 'Modifier ce chapitre',
                    onPressed: () => widget.onEditChapitre?.call(chapitre),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    tooltip: 'Supprimer ce chapitre',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) => AlertDialog(
                          title: const Text('Confirmer suppression'),
                          content: Text('Supprimer "${chapitre.nom}"? Les leçons associées pourraient aussi être supprimées ou affectées.'),
                          actions: <Widget>[
                            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
                            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text('Supprimer', style: TextStyle(color: Theme.of(context).colorScheme.error))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final success = await ref.read(chapitreProvider.notifier).deleteChapitre(
                          chapitre.id,
                          currentMatiereId: _selectedMatiereId, 
                          currentNiveauCode: _selectedNiveauCode, 
                          currentSerieCode: effectiveSerieCode 
                        );
                        if (mounted && success) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${chapitre.nom}" supprimé.'), backgroundColor: Colors.green,));
                        } else if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${ref.read(chapitreProvider).errorMessage ?? "Erreur lors de la suppression"}'), backgroundColor: Colors.red,));
                        }
                      }
                    },
                  ),
                  if (canReorder) ...[
                    const SizedBox(width: 8),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Tooltip(message: 'Réorganiser ce chapitre', child: Icon(Icons.drag_handle)),
                    ),
                  ],
                ],
              ),
              onTap: () => widget.onChapitreSelected(chapitre),
            ),
          );
        },
        onReorder: (int oldIndex, int newIndex) {
          if (!canReorder || _selectedMatiereId == null || _selectedNiveauCode == null || effectiveSerieCode == null) return;
          if (oldIndex < newIndex) newIndex -= 1;
          
          List<ChapitreModel> reorderedList = List.from(chapitreState.chapitres);
          final ChapitreModel item = reorderedList.removeAt(oldIndex);
          reorderedList.insert(newIndex, item);
          
          ref.read(chapitreProvider.notifier).updateChapitresOrder(
            reorderedList, 
            matiereId: _selectedMatiereId!, 
            niveauCode: _selectedNiveauCode, 
            serieCode: effectiveSerieCode 
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Niveau (Classe)', border: OutlineInputBorder()),
                  value: _selectedNiveauCode,
                  hint: const Text('Choisir Niveau'),
                  items: niveaux.map((niveau) => DropdownMenuItem<String?>(
                    value: niveau.code,
                    child: Text(niveau.nom, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: _onNiveauChanged,
                  validator: (value) => value == null ? 'Champ requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Série',
                    border: const OutlineInputBorder(),
                    filled: _selectedNiveauCode == '3eme', // Correction: 'filled' dans InputDecoration
                    fillColor: _selectedNiveauCode == '3eme' ? Colors.grey[200] : null,
                  ),
                  value: _selectedNiveauCode == '3eme' ? 'TC' : _selectedSerieCode, 
                  hint: const Text('Choisir Série'),
                  disabledHint: _selectedNiveauCode == null ? const Text('Choisir un niveau') 
                                : (_selectedNiveauCode == '3eme' ? const Text('Tronc Commun (Auto)') : null),
                  items: _buildSerieDropdownItems(seriesRaw, _selectedNiveauCode),
                  onChanged: (_selectedNiveauCode != null && _selectedNiveauCode != '3eme') ? _onSerieChanged : null, 
                  validator: (value) => (_selectedNiveauCode != null && _selectedNiveauCode != '3eme' && value == null) ? 'Champ requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()),
                  value: _selectedMatiereId,
                  hint: const Text('Choisir Matière'),
                  disabledHint: (_selectedNiveauCode == null || effectiveSerieCode == null) 
                                ? const Text('Niveau et Série requis') 
                                : (matiereState.isLoading ? const Text('Chargement...') : null),
                  items: matieres.map((matiere) => DropdownMenuItem<int?>(
                    value: matiere.id,
                    child: Text(matiere.nom, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (_selectedNiveauCode != null && effectiveSerieCode != null && !matiereState.isLoading) 
                             ? _onMatiereChanged 
                             : null,
                  validator: (value) => (_selectedNiveauCode != null && effectiveSerieCode != null && value == null) // Correction: _selectedNiveauCode
                                       ? 'Champ requis' 
                                       : null,
                ),
              ),
              const SizedBox(width: 16),
              _buildAddChapterButton(context),
            ],
          ),
          const SizedBox(height: 16),
          if (niveauState.errorMessage != null)
            Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text('Erreur Niveaux: ${niveauState.errorMessage}', style: const TextStyle(color: Colors.red))),
          if (serieState.errorMessage != null)
            Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text('Erreur Séries: ${serieState.errorMessage}', style: const TextStyle(color: Colors.red))),
          if (matiereState.errorMessage != null && (_selectedNiveauCode != null && effectiveSerieCode != null) )
            Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text('Erreur Matières: ${matiereState.errorMessage}', style: const TextStyle(color: Colors.red))),
          Expanded(child: content),
        ],
      ),
    );
  }
}
