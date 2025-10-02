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
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manage_exams_page.g.dart';

// --- Riverpod Notifiers for Filters (using code generation) ---

@riverpod
class SelectedNiveauCodeExams extends _$SelectedNiveauCodeExams {
  @override
  String? build() {
    return null; // Initial state
  }
  void set(String? value) {
    state = value;
  }
}

@riverpod
class SelectedSerieCodeExams extends _$SelectedSerieCodeExams {
  @override
  String? build() {
    return null;
  }
  void set(String? value) {
    state = value;
  }
}

@riverpod
class SelectedMatiereIdExams extends _$SelectedMatiereIdExams {
  @override
  int? build() {
    return null;
  }
  void set(int? value) {
    state = value;
  }
}

@riverpod
class SelectedEpreuveTypeExams extends _$SelectedEpreuveTypeExams {
  @override
  EpreuveType? build() {
    return null;
  }
  void set(EpreuveType? value) {
    state = value;
  }
}

@riverpod
class SelectedEpreuveStatutExams extends _$SelectedEpreuveStatutExams {
  @override
  EpreuveStatut? build() {
    return null;
  }
  void set(EpreuveStatut? value) {
    state = value;
  }
}
// --- End of Filter Notifiers ---

// Provider for filtered exams - this can remain a FutureProvider
final filteredExamsProvider = FutureProvider<List<Epreuve>>((ref) async {
  final niveauCode = ref.watch(selectedNiveauCodeExamsProvider);
  final serieCode = ref.watch(selectedSerieCodeExamsProvider);
  final matiereId = ref.watch(selectedMatiereIdExamsProvider);
  final epreuveType = ref.watch(selectedEpreuveTypeExamsProvider); // Corrected name
  final epreuveStatut = ref.watch(selectedEpreuveStatutExamsProvider); // Corrected name
  
  final epreuveService = ref.read(epreuveServiceProvider);

  return await epreuveService.fetchFilteredEpreuves(
    niveauCode: niveauCode,
    serieCode: serieCode,
    matiereId: matiereId,
    epreuveType: epreuveType,
    epreuveStatut: epreuveStatut,
  );
});

class ManageExamsPage extends ConsumerStatefulWidget {
  const ManageExamsPage({super.key});

  @override
  _ManageExamsPageState createState() => _ManageExamsPageState();
}

class _ManageExamsPageState extends ConsumerState<ManageExamsPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Accessing notifiers via ref.read(provider.notifier)
      if (ref.read(niveauProvider).niveaux.isEmpty) {
        ref.read(niveauProvider.notifier).fetchNiveaux();
      }
      if (ref.read(serieProvider).series.isEmpty) {
        ref.read(serieProvider.notifier).fetchSeries();
      }
    });
  }

  void _navigateToCreateExamPage(BuildContext context) {
    context.go('/teacher/manage-exams/create');
  }

  String _getEpreuveTypeDisplay(EpreuveType type) {
    switch (type) {
      case EpreuveType.ancienSujet: return 'Ancien Sujet d\'Examen';
      case EpreuveType.sujetCollege: return 'Sujet de Collège Connu';
      case EpreuveType.examenBlanc: return 'Examen Blanc';
      case EpreuveType.epreuveExclusive: return 'Épreuve Exclusive';
    }
  }
  
  List<DropdownMenuItem<String?>> _buildSerieDropdownItems(List<SerieModel> allSeries, String? currentNiveauCode, String? selectedSerieCode) {
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

  @override
  Widget build(BuildContext context) {
    // Watch the new auto-generated providers
    final selectedNiveau = ref.watch(selectedNiveauCodeExamsProvider);
    final selectedSerie = ref.watch(selectedSerieCodeExamsProvider);
    final selectedMatiere = ref.watch(selectedMatiereIdExamsProvider);
    final selectedType = ref.watch(selectedEpreuveTypeExamsProvider); // Corrected name
    final selectedStatut = ref.watch(selectedEpreuveStatutExamsProvider); // Corrected name

    final niveauState = ref.watch(niveauProvider);
    final serieState = ref.watch(serieProvider);
    final matiereState = ref.watch(matiereProvider);
    
    final asyncEpreuves = ref.watch(filteredExamsProvider);

    final Widget content = asyncEpreuves.when(
      data: (epreuves) {
        if (epreuves.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'Aucune épreuve ne correspond aux filtres actuels.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else {
          return ListView.builder(
            itemCount: epreuves.length,
            itemBuilder: (context, index) {
              final epreuve = epreuves[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6), 
                child: ListTile(
                  title: Text(epreuve.nom),
                  subtitle: Text('${epreuve.typeEpreuveDisplay} - ${epreuve.niveauScolaireDisplay} - ${Epreuve.statutToStringDisplay(epreuve.statut)}'),
                  trailing: Icon(
                    epreuve.statut == EpreuveStatut.publiee ? Icons.check_circle_outline :
                    epreuve.statut == EpreuveStatut.brouillon ? Icons.edit_note_outlined :
                    epreuve.statut == EpreuveStatut.programmee ? Icons.alarm_on_outlined :
                    Icons.archive_outlined,
                    color: epreuve.statut == EpreuveStatut.publiee ? Colors.green :
                           epreuve.statut == EpreuveStatut.brouillon ? Colors.orange :
                           epreuve.statut == EpreuveStatut.programmee ? Colors.blue :
                           Colors.grey,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Modification de "${epreuve.nom}" (à implémenter).')),
                     );
                  },
                ),
              );
            },
          );
        }
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (err, stack) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Erreur lors du chargement des épreuves: $err',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Créer une nouvelle épreuve'),
                onPressed: () => _navigateToCreateExamPage(context),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Niveau (Classe)', border: OutlineInputBorder()),
            value: selectedNiveau,
            hint: const Text('Choisir Niveau'),
            items: niveauState.niveaux.map((niveau) => DropdownMenuItem<String?>(
              value: niveau.code,
              child: Text(niveau.nom, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (newNiveauCode) {
              // Use ref.read(provider.notifier).method()
              ref.read(selectedNiveauCodeExamsProvider.notifier).set(newNiveauCode);
              ref.read(selectedSerieCodeExamsProvider.notifier).set(null); 
              ref.read(selectedMatiereIdExamsProvider.notifier).set(null); 

              String? finalSerieCodeForMatiereFetch;

              if (newNiveauCode == '3eme') {
                ref.read(selectedSerieCodeExamsProvider.notifier).set('TC');
                finalSerieCodeForMatiereFetch = 'TC';
              } else {
                finalSerieCodeForMatiereFetch = null;
              }

              if (newNiveauCode != null) {
                if (finalSerieCodeForMatiereFetch != null) {
                  ref.read(matiereProvider.notifier).fetchMatieres(niveauCode: newNiveauCode, serieCode: finalSerieCodeForMatiereFetch); 
                } else {
                  ref.read(matiereProvider.notifier).clearDataAndError();
                }
              } else { 
                ref.read(matiereProvider.notifier).clearDataAndError();
              }
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Série',
              border: const OutlineInputBorder(),
              filled: selectedNiveau == '3eme',
              fillColor: selectedNiveau == '3eme' ? Colors.grey[200] : null,
            ),
            value: selectedNiveau == '3eme' ? 'TC' : selectedSerie, 
            hint: const Text('Choisir Série'),
            items: _buildSerieDropdownItems(serieState.series, selectedNiveau, selectedSerie),
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
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()),
            value: selectedMatiere,
            hint: const Text('Choisir Matière'),
            disabledHint: (selectedNiveau == null || (selectedNiveau != '3eme' && selectedSerie == null))
                          ? const Text('Niveau et Série requis') 
                          : (matiereState.isLoading ? const Text('Chargement...') : (matiereState.matieres.isEmpty && selectedNiveau != null && (selectedNiveau =='3eme' || selectedSerie != null)) ? const Text('Aucune matière') : null ),
            items: matiereState.matieres.map((matiere) => DropdownMenuItem<int?>(
              value: matiere.id,
              child: Text(matiere.nom, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (selectedNiveau == null || (selectedNiveau != '3eme' && selectedSerie == null) || matiereState.isLoading || matiereState.matieres.isEmpty) ? null : (newMatiereId) {
              ref.read(selectedMatiereIdExamsProvider.notifier).set(newMatiereId);
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<EpreuveType?>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Type d\'Épreuve', border: OutlineInputBorder()),
            value: selectedType,
            hint: const Text('Choisir Type'),
            items: EpreuveType.values.map((type) => DropdownMenuItem<EpreuveType?>(
              value: type,
              child: Text(_getEpreuveTypeDisplay(type), overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (value) {
              ref.read(selectedEpreuveTypeExamsProvider.notifier).set(value); // Corrected name
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<EpreuveStatut?>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Statut de l\'Épreuve', border: OutlineInputBorder()),
            value: selectedStatut,
            hint: const Text('Choisir Statut'),
            items: EpreuveStatut.values.map((statut) => DropdownMenuItem<EpreuveStatut?>(
              value: statut,
              child: Text(Epreuve.statutToStringDisplay(statut), overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (value) {
              ref.read(selectedEpreuveStatutExamsProvider.notifier).set(value); // Corrected name
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }
}
