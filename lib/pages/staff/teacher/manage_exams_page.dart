import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/models/niveau_model.dart';
import 'package:easybosh_v2/models/serie_model.dart';
import 'package:easybosh_v2/providers/matiere_provider.dart';
import 'package:easybosh_v2/providers/niveau_provider.dart';
import 'package:easybosh_v2/providers/serie_provider.dart';
import 'package:easybosh_v2/services/epreuve_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manage_exams_page.g.dart';

// --- Riverpod Notifiers for Filters ---

@riverpod
class SelectedNiveauCodeExams extends _$SelectedNiveauCodeExams {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

@riverpod
class SelectedSerieCodeExams extends _$SelectedSerieCodeExams {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

@riverpod
class SelectedMatiereIdExams extends _$SelectedMatiereIdExams {
  @override
  int? build() => null;
  void set(int? value) => state = value;
}

@riverpod
class SelectedEpreuveTypeExams extends _$SelectedEpreuveTypeExams {
  @override
  EpreuveType? build() => null;
  void set(EpreuveType? value) => state = value;
}

// --- Filtered Exams Provider ---

final filteredExamsProvider = FutureProvider.autoDispose<List<Epreuve>>((ref) async {
  final epreuveService = ref.read(epreuveServiceProvider);
  // We no longer filter by status, so we pass null.
  return epreuveService.fetchFilteredEpreuves(
    niveauCode: ref.watch(selectedNiveauCodeExamsProvider),
    serieCode: ref.watch(selectedSerieCodeExamsProvider),
    matiereId: ref.watch(selectedMatiereIdExamsProvider),
    epreuveType: ref.watch(selectedEpreuveTypeExamsProvider),
    epreuveStatut: null, 
  );
});

class ManageExamsPage extends ConsumerStatefulWidget {
  final VoidCallback onCreateExam;
  final Function(String epreuveId) onEditExam;

  const ManageExamsPage({
    super.key,
    required this.onCreateExam,
    required this.onEditExam,
  });

  @override
  _ManageExamsPageState createState() => _ManageExamsPageState();
}

class _ManageExamsPageState extends ConsumerState<ManageExamsPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(niveauProvider).niveaux.isEmpty) {
        ref.read(niveauProvider.notifier).fetchNiveaux();
      }
      if (ref.read(serieProvider).series.isEmpty) {
        ref.read(serieProvider.notifier).fetchSeries();
      }
    });
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, Epreuve epreuve) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Voulez-vous vraiment supprimer l\'épreuve "${epreuve.nom}" ? Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref.read(epreuveServiceProvider).deleteEpreuve(epreuve.id!);
                  ref.invalidate(filteredExamsProvider); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Épreuve supprimée avec succès.'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la suppression: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<DropdownMenuItem<String?>> _buildSerieDropdownItems(List<SerieModel> allSeries, String? currentNiveauCode) {
    if (currentNiveauCode == null) {
      return []; // No level selected, no series to show except 'All'
    }
    if (currentNiveauCode == '3eme') {
      final tcSerie = allSeries.firstWhere((s) => s.code == 'TC', 
                        orElse: () => SerieModel(id: -1, code: 'TC', nom: 'Tronc Commun', type: 'Tronc Commun'));
      return [DropdownMenuItem<String?>(value: tcSerie.code, child: Text(tcSerie.nom, overflow: TextOverflow.ellipsis))];
    }
    return allSeries
        .where((serie) => serie.code != 'TC')
        .map((serie) => DropdownMenuItem<String?>(value: serie.code, child: Text(serie.nom, overflow: TextOverflow.ellipsis)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedNiveau = ref.watch(selectedNiveauCodeExamsProvider);
    final selectedSerie = ref.watch(selectedSerieCodeExamsProvider);
    final selectedMatiere = ref.watch(selectedMatiereIdExamsProvider);
    final selectedType = ref.watch(selectedEpreuveTypeExamsProvider);

    final niveauState = ref.watch(niveauProvider);
    final serieState = ref.watch(serieProvider);
    final matiereState = ref.watch(matiereProvider);
    final asyncEpreuves = ref.watch(filteredExamsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Créer une nouvelle épreuve'),
            onPressed: widget.onCreateExam,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(labelText: 'Niveau', border: OutlineInputBorder()),
                  value: selectedNiveau,
                  hint: const Text('Tous les niveaux'),
                  isExpanded: true,
                  items: [ 
                    const DropdownMenuItem<String?>(value: null, child: Text('Tous les niveaux')), ...niveauState.niveaux.map((niveau) => DropdownMenuItem<String?>(
                    value: niveau.code,
                    child: Text(niveau.nom, overflow: TextOverflow.ellipsis),
                  )).toList()],
                  onChanged: (newNiveauCode) {
                    ref.read(selectedNiveauCodeExamsProvider.notifier).set(newNiveauCode);
                    ref.read(selectedSerieCodeExamsProvider.notifier).set(null);
                    ref.read(selectedMatiereIdExamsProvider.notifier).set(null);
                    if (newNiveauCode == '3eme') {
                      ref.read(selectedSerieCodeExamsProvider.notifier).set('TC');
                      ref.read(matiereProvider.notifier).fetchMatieres(niveauCode: newNiveauCode, serieCode: 'TC');
                    } else if (newNiveauCode == null) {
                       ref.read(matiereProvider.notifier).clearDataAndError();
                    } 
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  decoration: InputDecoration(
                    labelText: 'Série',
                    border: const OutlineInputBorder(),
                    filled: selectedNiveau == '3eme',
                    fillColor: selectedNiveau == '3eme' ? Colors.grey[200] : null,
                    hintText: 'Toutes les séries',
                  ),
                  value: selectedNiveau == '3eme' ? 'TC' : selectedSerie,
                  isExpanded: true,
                  items: [const DropdownMenuItem<String?>(value: null, child: Text('Toutes les séries')), ..._buildSerieDropdownItems(serieState.series, selectedNiveau)],
                  onChanged: selectedNiveau == null || selectedNiveau == '3eme' ? null : (newSerieCode) {
                    ref.read(selectedSerieCodeExamsProvider.notifier).set(newSerieCode);
                    ref.read(selectedMatiereIdExamsProvider.notifier).set(null);
                    if (selectedNiveau != null && newSerieCode != null) {
                      ref.read(matiereProvider.notifier).fetchMatieres(niveauCode: selectedNiveau, serieCode: newSerieCode);
                    } else {
                       ref.read(matiereProvider.notifier).clearDataAndError();
                    }
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()),
                  value: selectedMatiere,
                  hint: const Text('Toutes les matières'),
                  isExpanded: true,
                  disabledHint: const Text('Niveau & Série requis'),
                  items: [const DropdownMenuItem<int?>(value: null, child: Text('Toutes les matières')), ...matiereState.matieres.map((matiere) => DropdownMenuItem<int?>(
                    value: matiere.id,
                    child: Text(matiere.nom, overflow: TextOverflow.ellipsis),
                  )).toList()],
                  onChanged: (matiereState.isLoading || (selectedNiveau != null && selectedSerie != null && matiereState.matieres.isEmpty && !matiereState.isLoading)) ? null : (newMatiereId) {
                    ref.read(selectedMatiereIdExamsProvider.notifier).set(newMatiereId);
                  },
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<EpreuveType?>(
                  decoration: const InputDecoration(labelText: 'Type d\'épreuve', border: OutlineInputBorder()),
                  value: selectedType,
                  hint: const Text('Tous les types'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<EpreuveType?>(value: null, child: Text('Tous les types')),
                    ...[EpreuveType.ancienSujet, EpreuveType.sujetCollege]
                        .map((type) => DropdownMenuItem<EpreuveType?>(
                              value: type,
                              child: Text(type.displayName, overflow: TextOverflow.ellipsis),
                            ))
                        .toList()
                  ],
                  onChanged: (value) => ref.read(selectedEpreuveTypeExamsProvider.notifier).set(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: asyncEpreuves.when(
              data: (epreuves) {
                if (epreuves.isEmpty) {
                  return const Center(child: Text('Aucune épreuve trouvée pour ces filtres.'));
                }
                return ListView.builder(
                  itemCount: epreuves.length,
                  itemBuilder: (context, index) {
                    final epreuve = epreuves[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(epreuve.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${epreuve.matiereDisplay} - ${epreuve.niveauScolaireDisplay} (${epreuve.seriesCodes.join(', ')})\nStatut: ${Epreuve.statutToStringDisplay(epreuve.statut)}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                              tooltip: 'Modifier',
                              onPressed: () => widget.onEditExam(epreuve.id.toString()),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Supprimer',
                              onPressed: () => _showDeleteConfirmationDialog(context, ref, epreuve),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erreur de chargement: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
