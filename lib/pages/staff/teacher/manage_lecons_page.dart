import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/providers/lecon_provider.dart';
import 'package:easybosh_v2/providers/chapitre_provider.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';

class ManageLeconsPage extends ConsumerStatefulWidget {
  final int chapitreId;
  final VoidCallback onBackToChapitres;
  final VoidCallback? onAddLecon;
  final Function(LeconModel lecon)? onEditLecon;

  const ManageLeconsPage({
    super.key,
    required this.chapitreId,
    required this.onBackToChapitres,
    this.onAddLecon,
    this.onEditLecon,
  });

  @override
  ConsumerState<ManageLeconsPage> createState() => _ManageLeconsPageState();
}

class _ManageLeconsPageState extends ConsumerState<ManageLeconsPage> {
  String _selectedLeconType = 'pdf'; // Default to PDF
  final List<String> _chipTypes = ['pdf', 'video', 'audio'];
  Map<String, int> _lessonsCountsPerType = {};
  List<LeconModel> _leconsAffichees = []; // To hold the currently displayed (filtered and sorted) lecons

  @override
  void initState() {
    super.initState();
    print("MANAGE_LECONS_PAGE - initState: ChapitreId: ${widget.chapitreId}, Default selectedType: $_selectedLeconType");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataAndProcessLecons();
    });
  }

  @override
  void didUpdateWidget(covariant ManageLeconsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapitreId != widget.chapitreId) {
      print("MANAGE_LECONS_PAGE - didUpdateWidget: ChapitreId changed from ${oldWidget.chapitreId} to ${widget.chapitreId}");
      setState(() {
        _selectedLeconType = 'pdf'; // Reset to PDF on chapter change
        _lessonsCountsPerType = {};
        _leconsAffichees = [];
      });
      _fetchDataAndProcessLecons();
    }
  }

  Future<void> _fetchDataAndProcessLecons() async {
    if (!mounted) return;
    if (ref.read(matiereProvider).matieres.isEmpty) {
      await ref.read(matiereProvider.notifier).fetchMatieres();
    }
    if (!mounted) return;
    await ref.read(leconProvider.notifier).fetchLecons(chapitreId: widget.chapitreId);
    if (mounted) {
      _processLecons();
    }
  }

  void _processLecons() {
    if (!mounted) return;
    final leconState = ref.read(leconProvider);
    final allLeconsForChapter = List<LeconModel>.from(leconState.lecons);
    print("MANAGE_LECONS_PAGE - _processLecons: Total lecons fetched for chapter: ${allLeconsForChapter.length}");

    Map<String, int> counts = {};
    for (String type in _chipTypes) {
      counts[type] = allLeconsForChapter.where((lecon) => lecon.type?.toLowerCase() == type).length;
    }

    List<LeconModel> filtered = allLeconsForChapter
        .where((lecon) => lecon.type?.toLowerCase() == _selectedLeconType)
        .toList();

    filtered.sort((a, b) {
      final orderA = a.ordreParType?[_selectedLeconType];
      final orderB = b.ordreParType?[_selectedLeconType];
      if (orderA != null && orderB != null) return orderA.compareTo(orderB);
      if (orderA != null) return -1;
      if (orderB != null) return 1;
      return a.ordre.compareTo(b.ordre);
    });
    
    setState(() {
      _lessonsCountsPerType = counts;
      _leconsAffichees = filtered;
      print("MANAGE_LECONS_PAGE - _processLecons: Counts: $_lessonsCountsPerType, SelectedType: $_selectedLeconType, FilteredLecons: ${_leconsAffichees.length}");
    });
  }

  Widget _buildAddLessonButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: widget.onAddLecon,
      icon: const Icon(Icons.add),
      label: const Text('Ajouter Leçon'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildFilterChips() {
    print("MANAGE_LECONS_PAGE - _buildFilterChips: Selected type: $_selectedLeconType, Counts: $_lessonsCountsPerType");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: _chipTypes.map((type) {
          final bool isEnabled = (_lessonsCountsPerType[type] ?? 0) > 0;
          final bool isSelected = _selectedLeconType == type;
          return ChoiceChip(
            label: Text(type.toUpperCase()),
            selected: isSelected,
            backgroundColor: Colors.grey[200],
            selectedColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : (isEnabled ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[500]),
            ),
            shape: StadiumBorder(side: BorderSide(color: Colors.grey[300]!)),
            showCheckmark: false,
            onSelected: isEnabled 
                ? (bool selected) {
                    if (selected) {
                      print("MANAGE_LECONS_PAGE - Chip '${type.toUpperCase()}' selected.");
                      setState(() {
                        _selectedLeconType = type;
                      });
                      _processLecons();
                    }
                  }
                : null,
            disabledColor: Colors.grey[300]?.withOpacity(0.5),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leconState = ref.watch(leconProvider);
    final matiereState = ref.watch(matiereProvider);
    final chapitreGlobalState = ref.watch(chapitreProvider);

    ChapitreModel? currentChapitre;
    MatiereModel? currentMatiere;
    try {
        currentChapitre = chapitreGlobalState.chapitres.firstWhere((ch) => ch.id == widget.chapitreId);
    } catch (e) {
        if (chapitreGlobalState.chapitrePourEdition?.id == widget.chapitreId) {
            currentChapitre = chapitreGlobalState.chapitrePourEdition;
        }
    }
    if (currentChapitre != null && currentChapitre.matiereId != null && matiereState.matieres.isNotEmpty) {
        try {
            currentMatiere = matiereState.matieres.firstWhere((m) => m.id == currentChapitre!.matiereId);
        } catch (e) { /* Matière non trouvée */ }
    }

    print("MANAGE_LECONS_PAGE - Build: SelectedType: $_selectedLeconType, Displaying ${_leconsAffichees.length} lecons.");

    Widget content;
    if (leconState.isLoading && _leconsAffichees.isEmpty && _lessonsCountsPerType.isEmpty) {
      content = const Center(child: CircularProgressIndicator(semanticsLabel: "Chargement des leçons..."));
    } else if (leconState.errorMessage != null && _leconsAffichees.isEmpty && _lessonsCountsPerType.values.every((c) => c ==0) ) {
      content = Center(child: Text(leconState.errorMessage!, style: const TextStyle(color: Colors.red)));
    } else if (_lessonsCountsPerType[_selectedLeconType] == 0 && _chipTypes.contains(_selectedLeconType)) {
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_alt_off_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Aucune leçon de type "${_selectedLeconType.toUpperCase()}" trouvée pour ce chapitre.',
                style: const TextStyle(fontSize: 18), textAlign: TextAlign.center,
              ),
              if (widget.onAddLecon != null)
                Padding(
                  padding: const EdgeInsets.only(top:8.0),
                  child: const Text('Vous pouvez en ajouter une.', textAlign: TextAlign.center),
                ),
            ],
          ),
        );
    } else if (_leconsAffichees.isEmpty && !leconState.isLoading) {
         content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.library_books_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                currentChapitre != null 
                  ? 'Aucune leçon à afficher pour \"${currentChapitre.nom}\".' 
                  : 'Aucune leçon à afficher pour ce chapitre.',
                style: const TextStyle(fontSize: 18), textAlign: TextAlign.center,
              ),
              if (widget.onAddLecon != null)
                 Padding(
                  padding: const EdgeInsets.only(top:8.0),
                  child: const Text('Appuyez sur le bouton ci-dessus pour ajouter.', textAlign: TextAlign.center),
                ),
            ],
          ),
        );
    } else {
      content = ReorderableListView.builder(
        itemCount: _leconsAffichees.length,
        itemBuilder: (context, index) {
          final lecon = _leconsAffichees[index];
          return Card(
            key: ValueKey("${_selectedLeconType}_${lecon.id}"),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                backgroundColor: Theme.of(context).colorScheme.secondary, 
              ),
              title: Text(lecon.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                "Type: ${(lecon.type ?? 'N/A').replaceAll('_',' ').toUpperCase()}\n${lecon.description ?? 'Pas de description'}",
                maxLines: 2, overflow: TextOverflow.ellipsis
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                             tooltip: "Modifier cette leçon",
                             onPressed: () => widget.onEditLecon?.call(lecon)),
                  IconButton(icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                             tooltip: "Supprimer cette leçon",
                             onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context, 
                      builder: (BuildContext dialogContext) => AlertDialog(
                        title: const Text('Confirmer suppression'),
                        content: Text('Supprimer "${lecon.nom}"?'),
                        actions: [
                          TextButton(onPressed:()=>Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
                          TextButton(onPressed:()=>Navigator.of(dialogContext).pop(true), child: Text('Supprimer', style: TextStyle(color: Theme.of(context).colorScheme.error)))
                        ]
                      )
                    );
                    if (confirm == true) {
                      final success = await ref.read(leconProvider.notifier).deleteLecon(lecon.id);
                      if(mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${lecon.nom}" supprimé.')));
                        _processLecons();
                      } else if(mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${ref.read(leconProvider).errorMessage ?? "Erreur lors de la suppression"}')));
                      }
                    }
                  }),
                  const SizedBox(width: 8), 
                  ReorderableDragStartListener(
                    index: index,
                    child: const Tooltip(
                      message: 'Réorganiser cette leçon (pour ce type)',
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ],
              ),
              onTap: () => widget.onEditLecon?.call(lecon),
            ),
          );
        },
        onReorder: (int oldIndex, int newIndex) {
          print("MANAGE_LECONS_PAGE - onReorder: For type $_selectedLeconType, oldIndex: $oldIndex, newIndex: $newIndex");
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1; 
            }
            final LeconModel itemMoved = _leconsAffichees.removeAt(oldIndex);
            _leconsAffichees.insert(newIndex, itemMoved);

            List<Future<void>> updateFutures = [];
            List<LeconModel> updatedLeconsInView = [];

            for (int i = 0; i < _leconsAffichees.length; i++) {
              LeconModel currentLecon = _leconsAffichees[i];
              Map<String, int> updatedOrdreParType = Map.from(currentLecon.ordreParType ?? {});
              updatedOrdreParType[_selectedLeconType] = i + 1; // 1-based order

              LeconModel leconToUpdate = currentLecon.copyWith(ordreParType: updatedOrdreParType);
              updatedLeconsInView.add(leconToUpdate); // Keep the updated instance for the local list
              
              print("      Updating ${leconToUpdate.nom} -> ordreParType: ${leconToUpdate.ordreParType}");
              updateFutures.add(ref.read(leconProvider.notifier).updateLecon(leconToUpdate));
            }
            
            _leconsAffichees = updatedLeconsInView; // Update the list in state with new instances

            Future.wait(updateFutures).then((_){
                print("MANAGE_LECONS_PAGE - All lecons updated for type specific order.");
                 // Potentially call _processLecons() again if server might return different data
                 // or if updateLecon doesn't trigger a sufficient rebuild via the provider.
                 // For now, local state is updated, and provider should handle remote state.
                 // _processLecons(); 
            }).catchError((error){
                print("MANAGE_LECONS_PAGE - Error updating lecons for type specific order: $error");
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la mise à jour de l'ordre: $error")));
                }
                // Consider reverting local changes or re-fetching on error
                 _processLecons(); // Re-process to reflect actual state from provider if updates failed
            });
          });
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                label: Text(currentMatiere != null ? 'Retour à "${currentMatiere.nom}"' : 'Retour aux Chapitres'),
                onPressed: widget.onBackToChapitres,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              ),
              if (widget.onAddLecon != null)
                _buildAddLessonButton(context),
            ],
          ),
          const SizedBox(height: 8),
          if (currentChapitre != null && currentChapitre.nom.isNotEmpty && currentChapitre.nom != 'Chargement...')
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  children: [
                    if (currentMatiere != null && currentMatiere.nom.isNotEmpty) ...[
                       TextSpan(text: 'Matière: ${currentMatiere.nom} '),
                       const TextSpan(text: '> '),
                    ],
                    TextSpan(text: 'Chapitre: ${currentChapitre.nom}'),
                  ]
                ),
                 maxLines: 2, 
                overflow: TextOverflow.ellipsis,
              ),
            )
          else 
             const Padding(
                 padding: EdgeInsets.only(bottom: 12.0, left: 4.0),
                 child: Text("Chargement des détails du chapitre...", style: TextStyle(fontStyle: FontStyle.italic))
             ),
          _buildFilterChips(),
          Expanded(child: content),
        ],
      ),
    );
  }
}
