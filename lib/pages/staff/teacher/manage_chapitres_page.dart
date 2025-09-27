import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/providers/chapitre_provider.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
// import './edit_chapitre_page.dart'; // N'est plus utilisé pour la navigation directe

class ManageChapitresPage extends ConsumerStatefulWidget {
  final Function(ChapitreModel chapitre) onChapitreSelected;
  final int? initialSelectedMatiereId;
  final Function(int? newMatiereId)? onMatiereFilterChanged;
  final VoidCallback? onAddChapitre; // Callback pour demander l'ajout
  final Function(ChapitreModel chapitre)? onEditChapitre; // Callback pour demander l'édition

  const ManageChapitresPage({
    super.key, 
    required this.onChapitreSelected,
    this.initialSelectedMatiereId,
    this.onMatiereFilterChanged,
    this.onAddChapitre,
    this.onEditChapitre,
  });

  @override
  ConsumerState<ManageChapitresPage> createState() => _ManageChapitresPageState();
}

class _ManageChapitresPageState extends ConsumerState<ManageChapitresPage> {
  int? _selectedMatiereIdFilter;

  @override
  void initState() {
    super.initState();
    _selectedMatiereIdFilter = widget.initialSelectedMatiereId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matiereNotifier = ref.read(matiereProvider.notifier);
      final matiereState = ref.read(matiereProvider);

      Future<void> fetchInitialData() async {
        if (matiereState.matieres.isEmpty) {
          await matiereNotifier.fetchMatieres();
        }
        if (mounted) {
          final currentMatiereFilter = _selectedMatiereIdFilter;
          final matieres = ref.read(matiereProvider).matieres;
          if (currentMatiereFilter != null && !matieres.any((m) => m.id == currentMatiereFilter)) {
             _selectedMatiereIdFilter = null;
             widget.onMatiereFilterChanged?.call(null);
          }
          ref.read(chapitreProvider.notifier).fetchChapitres(matiereId: _selectedMatiereIdFilter);
        }
      }
      fetchInitialData();
    });
  }

  @override
  void didUpdateWidget(covariant ManageChapitresPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedMatiereId != oldWidget.initialSelectedMatiereId) {
      setState(() {
        _selectedMatiereIdFilter = widget.initialSelectedMatiereId;
      });
      ref.read(chapitreProvider.notifier).fetchChapitres(matiereId: _selectedMatiereIdFilter);
    }
  }

  // _navigateToEditChapitrePage est supprimée.
  
  Widget _buildAddChapterButton(BuildContext context) {
    // Appelle le callback du parent au lieu de naviguer directement.
    return ElevatedButton.icon(
        onPressed: widget.onAddChapitre, // Utilisation du callback
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
    final List<MatiereModel> matieres = matiereState.matieres;
    final bool canReorder = _selectedMatiereIdFilter != null;

    Widget content;

    if (chapitreState.isLoading && chapitreState.chapitres.isEmpty && _selectedMatiereIdFilter != null && matieres.isNotEmpty) {
      content = const Center(child: CircularProgressIndicator(semanticsLabel: "Chargement des chapitres..."));
    } else if (matiereState.isLoading && matieres.isEmpty) {
      content = const Center(child: CircularProgressIndicator(semanticsLabel: "Chargement des matières..."));
    } else if (matiereState.errorMessage != null && matieres.isEmpty) {
      content = Center(child: Text("Erreur de chargement des matières: ${matiereState.errorMessage}"));
    } else if (chapitreState.errorMessage != null && chapitreState.chapitres.isEmpty && _selectedMatiereIdFilter != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(chapitreState.errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(chapitreProvider.notifier).fetchChapitres(matiereId: _selectedMatiereIdFilter);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    } else if (_selectedMatiereIdFilter == null && matieres.isNotEmpty) {
        content = const Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Icons.filter_list, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Veuillez sélectionner une matière pour voir et gérer les chapitres.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                ],
            ),
        );
    } else if (chapitreState.chapitres.isEmpty && _selectedMatiereIdFilter != null && matieres.isNotEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_special_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Aucun chapitre pour cette matière.', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Appuyez sur le bouton ci-dessus pour ajouter.', textAlign: TextAlign.center),
          ],
        ),
      );
    } else if (matieres.isEmpty && !matiereState.isLoading) {
      content = const Center(child: Text("Aucune matière disponible. Veuillez d'abord ajouter des matières."));
    } else {
      final List<ChapitreModel> currentChapitres = List.from(chapitreState.chapitres);

      content = ReorderableListView.builder(
        buildDefaultDragHandles: false, 
        itemCount: currentChapitres.length,
        itemBuilder: (context, index) {
          final chapitre = currentChapitres[index];
          final matiereAssociee = matieres.firstWhere((m) => m.id == chapitre.matiereId, 
            orElse: () => MatiereModel(
              id: 0, 
              nom: 'Inconnue', 
              code: 'INCONNU',
              type: 'obligatoire', 
              createdAt: DateTime.now()
            )
          );

          return Card(
            key: ValueKey(chapitre.id),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${chapitre.ordre}', style: const TextStyle(color: Colors.white)),
                backgroundColor: Theme.of(context).colorScheme.primary, 
              ),
              title: Text(chapitre.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                "Matière: ${matiereAssociee.nom}\n${chapitre.description ?? 'Pas de description'}",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.secondary),
                    tooltip: 'Modifier ce chapitre',
                    onPressed: () {
                      widget.onEditChapitre?.call(chapitre); // Utilisation du callback
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    tooltip: 'Supprimer ce chapitre',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('Confirmer suppression'),
                            content: Text('Supprimer "${chapitre.nom}"? Les leçons associées pourraient être affectées.'),
                            actions: <Widget>[
                              TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
                              TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text('Supprimer', style: TextStyle(color: Theme.of(context).colorScheme.error))),
                            ],
                          );
                        },
                      );
                      if (confirm == true) {
                        final success = await ref.read(chapitreProvider.notifier).deleteChapitre(chapitre.id);
                        if (mounted && success) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${chapitre.nom}" supprimé.')));
                        } else if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${ref.read(chapitreProvider).errorMessage ?? "Erreur lors de la suppression"}')));
                        }
                      }
                    },
                  ),
                  if (canReorder) ...[
                    const SizedBox(width: 8),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Tooltip(
                        message: 'Réorganiser ce chapitre',
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ],
                ],
              ),
              onTap: () {
                widget.onChapitreSelected(chapitre);
              },
            ),
          );
        },
        onReorder: (int oldIndex, int newIndex) {
          if (!canReorder) return;

          setState(() { 
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final ChapitreModel item = currentChapitres.removeAt(oldIndex);
            currentChapitres.insert(newIndex, item);
            
            ref.read(chapitreProvider.notifier).updateChapitresOrder(currentChapitres, _selectedMatiereIdFilter!);
          });
        },
      );
    }

    // Ce widget ne doit plus avoir son propre Scaffold, il est intégré.
    // Le padding et la structure globale sont gérés par TeacherDashboardPage.
    return Padding(
      padding: const EdgeInsets.all(16.0), // Padding pour le contenu interne de cette "vue"
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (matieres.isNotEmpty)
                PopupMenuButton<int?>(
                  tooltip: 'Filtrer par matière',
                  onSelected: (int? matiereId) {
                    setState(() {
                      _selectedMatiereIdFilter = matiereId;
                    });
                    widget.onMatiereFilterChanged?.call(_selectedMatiereIdFilter);
                    ref.read(chapitreProvider.notifier).fetchChapitres(matiereId: _selectedMatiereIdFilter);
                  },
                  itemBuilder: (BuildContext context) {
                    List<PopupMenuItem<int?>> items = [
                      const PopupMenuItem<int?>(
                        value: null, 
                        child: Text('Sélectionner une matière...'),
                      ),
                    ];
                    items.addAll(matieres.map((matiere) {
                      return PopupMenuItem<int?>(
                        value: matiere.id,
                        child: Text(matiere.nom),
                      );
                    }).toList());
                    return items;
                  },
                  child: Chip(
                    avatar: const Icon(Icons.filter_list, size: 18),
                    label: Text(_selectedMatiereIdFilter != null && matieres.any((m) => m.id == _selectedMatiereIdFilter)
                        ? matieres.firstWhere((m) => m.id == _selectedMatiereIdFilter).nom 
                        : 'Sélectionner une matière'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                )
              else if (matiereState.isLoading)
                 const CircularProgressIndicator()
              else 
                 const Text("Aucune matière à filtrer."),

              // Afficher le bouton "Ajouter Chapitre" seulement si une matière est sélectionnée
              // et si le callback onAddChapitre est fourni (ce qui devrait toujours être le cas depuis TeacherDashboardPage)
              if (_selectedMatiereIdFilter != null && widget.onAddChapitre != null)
                 _buildAddChapterButton(context),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: content),
        ],
      ),
    );
  }
}
