import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/services/filters_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart'; // Pour debugPrint et listEquals

part 'filters_providers.g.dart'; // Nécessaire pour la génération de code

@Riverpod(keepAlive: true)
FiltersService filtersService(Ref ref) { // Modifié pour utiliser Ref générique
  return FiltersService();
}

@riverpod
Future<List<NiveauSelectionItem>> niveaux(Ref ref) async { // Modifié pour utiliser Ref générique
  debugPrint("[FiltersProvider.generated] niveauxProvider: Chargement...");
  final service = ref.watch(filtersServiceProvider);
  final niveaux = await service.getNiveaux();
  debugPrint("[FiltersProvider.generated] niveauxProvider: Chargé, ${niveaux.length} items.");
  return niveaux;
}

@riverpod
Future<List<SerieSelectionItem>> seriesForSelection(Ref ref) async { // Modifié pour utiliser Ref générique
  debugPrint("[FiltersProvider.generated] seriesForSelectionProvider: Chargement...");
  final service = ref.watch(filtersServiceProvider);
  final series = await service.getSeriesForSelection();
  debugPrint("[FiltersProvider.generated] seriesForSelectionProvider: Chargé, ${series.length} items.");
  return series;
}

@riverpod
Future<List<MatiereSelectionItem>> allMatieres(Ref ref) async { // Modifié pour utiliser Ref générique
  debugPrint("[FiltersProvider.generated] allMatieresProvider: Chargement...");
  final service = ref.watch(filtersServiceProvider);
  final matieres = await service.getAllMatieres();
  debugPrint("[FiltersProvider.generated] allMatieresProvider: Chargé, ${matieres.length} items.");
  return matieres;
}

@Riverpod(keepAlive: true)
class SelectedNiveauCode extends _$SelectedNiveauCode {
  @override
  String? build() => null;

  void update(String? newCode) {
    if (state != newCode) {
      state = newCode;
      debugPrint("[FiltersProvider.generated] SelectedNiveauCode: Mis à jour à '$newCode'.");
    }
  }
}

@Riverpod(keepAlive: true)
class SelectedSeriesCodesForFilter extends _$SelectedSeriesCodesForFilter {
  @override
  List<String> build() => [];

  void update(List<String> newCodes) {
    if (!listEquals(state, newCodes)) {
      state = List.from(newCodes);
      debugPrint("[FiltersProvider.generated] SelectedSeriesCodesForFilter: Mis à jour à $newCodes.");
    }
  }
}

@riverpod
Future<List<MatiereSelectionItem>> filteredMatieresList(Ref ref) async { // Modifié pour utiliser Ref générique
  debugPrint("[FiltersProvider.generated] filteredMatieresListProvider: Recalcul...");
  final filtersService = ref.watch(filtersServiceProvider);
  
  final List<MatiereSelectionItem> allMatieres = await ref.watch(allMatieresProvider.future);
  debugPrint("[FiltersProvider.generated] filteredMatieresListProvider: allMatieresProvider complété, ${allMatieres.length} items.");
  
  final niveauCode = ref.watch(selectedNiveauCodeProvider);
  List<String> seriesCodes = ref.watch(selectedSeriesCodesForFilterProvider);
  debugPrint("[FiltersProvider.generated] filteredMatieresListProvider: Niveau='$niveauCode', Séries=$seriesCodes");

  if (niveauCode == null) {
    debugPrint("[FiltersProvider.generated] filteredMatieresListProvider: Aucun niveau sélectionné, retour liste vide.");
    return [];
  }

  List<String> codesPourRequete = List.from(seriesCodes);
  if (niveauCode == '3eme') {
    codesPourRequete = ['TC'];
  } else {
    if (codesPourRequete.isEmpty) {
        debugPrint("[FiltersProvider.generated] filteredMatieresListProvider: Niveau $niveauCode sans séries sélectionnées, retour liste vide.");
        return [];
    }
  }
  debugPrint("[FiltersProvider.generated] filteredMatieresListProvider: Codes pour requête BDD: $codesPourRequete");
  
  final List<int> filteredMatiereIds = await filtersService.getMatiereIdsByNiveauAndSeries(niveauCode, codesPourRequete);
  debugPrint("[FiltersProvider.generated] filteredMatieresListProvider: IDs de matières filtrés reçus: $filteredMatiereIds");
  
  final List<MatiereSelectionItem> filteredList = allMatieres
      .where((matiere) => filteredMatiereIds.contains(matiere.id))
      .toList();
  
  debugPrint("[FiltersProvider.generated] filteredMatieresListProvider: Liste finale de matières filtrées: ${filteredList.length} items.");
  return filteredList;
}
