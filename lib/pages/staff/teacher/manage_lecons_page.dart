import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/providers/lecon_provider.dart';
import 'package:easybosh_v2/providers/chapitre_provider.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
// import './edit_lecon_page.dart'; // N'est plus utilisé pour la navigation directe

class ManageLeconsPage extends ConsumerStatefulWidget {
  final int chapitreId;
  final VoidCallback onBackToChapitres;
  final VoidCallback? onAddLecon; // Callback pour demander l'ajout
  final Function(LeconModel lecon)? onEditLecon; // Callback pour demander l'édition

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // S'assurer que les données contextuelles (matières, chapitres) sont chargées si nécessaire.
      // Cela est surtout pour l'affichage du nom de la matière/chapitre.
      if (ref.read(matiereProvider).matieres.isEmpty) {
        ref.read(matiereProvider.notifier).fetchMatieres();
      }
      // Le chapitre spécifique devrait être chargé par son provider si besoin, 
      // mais une liste générale peut aider.
      // ref.read(chapitreProvider.notifier).fetchChapitres(); 
      
      // Charger les leçons pour le chapitre actuel.
      ref.read(leconProvider.notifier).fetchLecons(chapitreId: widget.chapitreId);
    });
  }

  @override
  void didUpdateWidget(covariant ManageLeconsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapitreId != widget.chapitreId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(leconProvider.notifier).fetchLecons(chapitreId: widget.chapitreId);
      });
    }
  }

  // _navigateToEditLeconPage est supprimée.

  Widget _buildAddLessonButton(BuildContext context) {
    // Appelle le callback du parent au lieu de naviguer directement.
    return ElevatedButton.icon(
      onPressed: widget.onAddLecon, // Utilisation du callback
      icon: const Icon(Icons.add),
      label: const Text('Ajouter Leçon'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leconState = ref.watch(leconProvider);
    final matiereState = ref.watch(matiereProvider);
    final chapitreGlobalState = ref.watch(chapitreProvider); // Pour les détails du chapitre et matière

    ChapitreModel? currentChapitre;
    MatiereModel? currentMatiere;

    // Essayer de trouver le chapitre actuel dans l'état global des chapitres.
    try {
        currentChapitre = chapitreGlobalState.chapitres.firstWhere((ch) => ch.id == widget.chapitreId);
    } catch (e) {
        // Essayer avec chapitrePourEdition si jamais il est chargé là
        if (chapitreGlobalState.chapitrePourEdition?.id == widget.chapitreId) {
            currentChapitre = chapitreGlobalState.chapitrePourEdition;
        } else {
          // Si le chapitre n'est pas trouvé, on peut déclencher un fetch pour ce chapitre spécifique
          // ou afficher un état de chargement/erreur pour le nom du chapitre.
          // Pour l'instant, on laisse un placeholder.
          // Consider calling: ref.read(chapitreProvider.notifier).chargerChapitrePourDetails(widget.chapitreId);
        }
    }
    // Si le chapitre est trouvé et a un matiereId, trouver la matière.
    if (currentChapitre != null && currentChapitre.matiereId != null && matiereState.matieres.isNotEmpty) {
        try {
            currentMatiere = matiereState.matieres.firstWhere((m) => m.id == currentChapitre!.matiereId);
        } catch (e) { /* Matière non trouvée, currentMatiere restera null */ }
    }

    Widget content;
    if (leconState.isLoading && leconState.lecons.isEmpty) {
      content = const Center(child: CircularProgressIndicator(semanticsLabel: "Chargement des leçons..."));
    } else if (leconState.errorMessage != null && leconState.lecons.isEmpty) {
      content = Center(child: Text(leconState.errorMessage!, style: const TextStyle(color: Colors.red)));
    } else if (leconState.lecons.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              currentChapitre != null 
                ? 'Aucune leçon pour \"${currentChapitre.nom}\".' 
                : 'Aucune leçon pour ce chapitre.',
              style: const TextStyle(fontSize: 18), textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (widget.onAddLecon != null) // N'afficher que si le callback est fourni
              const Text('Appuyez sur le bouton ci-dessus pour ajouter.', textAlign: TextAlign.center),
          ],
        ),
      );
    } else {
      final List<LeconModel> currentLecons = List.from(leconState.lecons); 

      content = ReorderableListView.builder(
        buildDefaultDragHandles: false, 
        itemCount: currentLecons.length,
        itemBuilder: (context, index) {
          final lecon = currentLecons[index];
          return Card(
            key: ValueKey(lecon.id), 
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${lecon.ordre}', style: const TextStyle(color: Colors.white)),
                backgroundColor: Theme.of(context).colorScheme.secondary, 
              ),
              title: Text(lecon.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                "Type: ${lecon.type.replaceAll('_',' ').toUpperCase()}\n${lecon.description ?? 'Pas de description'}",
                maxLines: 2, overflow: TextOverflow.ellipsis
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                             tooltip: "Modifier cette leçon",
                             onPressed: () => widget.onEditLecon?.call(lecon)), // Utilisation du callback
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
                      } else if(mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${ref.read(leconProvider).errorMessage ?? "Erreur lors de la suppression"}')));
                      }
                    }
                  }),
                  const SizedBox(width: 8), 
                  ReorderableDragStartListener(
                    index: index,
                    child: const Tooltip(
                      message: 'Réorganiser cette leçon',
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ],
              ),
              // Déclencher l'édition aussi sur le tap du ListTile pour une meilleure UX
              onTap: () => widget.onEditLecon?.call(lecon), // Utilisation du callback
            ),
          );
        },
        onReorder: (int oldIndex, int newIndex) {
          setState(() { 
            if (oldIndex < newIndex) {
              newIndex -= 1; 
            }
            final LeconModel item = currentLecons.removeAt(oldIndex);
            currentLecons.insert(newIndex, item);
            ref.read(leconProvider.notifier).updateLeconsOrder(currentLecons, widget.chapitreId);
          });
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0), // Padding pour le contenu interne de cette "vue"
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                label: Text(currentMatiere != null ? 'Retour à \"${currentMatiere.nom}\"' : 'Retour aux Chapitres'),
                onPressed: widget.onBackToChapitres,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              ),
              if (widget.onAddLecon != null) // N'afficher que si le callback est fourni
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
          Expanded(child: content),
        ],
      ),
    );
  }
}
