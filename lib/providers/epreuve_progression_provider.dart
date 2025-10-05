import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:easybosh_v2/services/epreuve_progression_service.dart';
import 'package:easybosh_v2/main.dart';


class EpreuveProgressionNotifier extends Notifier<Map<int, EpreuveProgressionModel>> {
  EpreuveProgressionService get _progressionService =>
      EpreuveProgressionService(ref.read(supabaseClientProvider));

  @override
  Map<int, EpreuveProgressionModel> build() => {};

  // Charger les progressions d'un utilisateur
  Future<void> fetchProgressions(String userId) async {
    try {
      final progressions = await _progressionService.getUserProgressions(userId);
      state = {for (var p in progressions) p.epreuveId: p};
    } catch (e) {
      print('Erreur lors du chargement des progressions: $e');
    }
  }

  // Démarrer une épreuve
  Future<void> startEpreuve(int epreuveId, String userId) async {
    try {
      await _progressionService.startEpreuve(epreuveId, userId);
      await fetchProgressions(userId);
    } catch (e) {
      print('Erreur lors du démarrage de l\'épreuve: $e');
      rethrow;
    }
  }

  // Soumettre une épreuve
  Future<void> submitEpreuve(int epreuveId, String userId, int tempsPasse) async {
    try {
      await _progressionService.submitEpreuve(epreuveId, userId, tempsPasse);
      await fetchProgressions(userId);
    } catch (e) {
      print('Erreur lors de la soumission de l\'épreuve: $e');
      rethrow;
    }
  }

  // Vérifier si une épreuve est commencée
  bool isEpreuveStarted(int epreuveId) {
    return state.containsKey(epreuveId) && state[epreuveId]!.commenced;
  }

  // Vérifier si une épreuve est terminée
  bool isEpreuveCompleted(int epreuveId) {
    return state.containsKey(epreuveId) && state[epreuveId]!.termine;
  }

  // Obtenir le statut d'une épreuve
  String getEpreuveStatus(int epreuveId) {
    if (!state.containsKey(epreuveId)) return 'Nouveau';
    if (state[epreuveId]!.termine) return 'Terminé';
    if (state[epreuveId]!.commenced) return 'En cours';
    return 'Nouveau';
  }
}

final epreuveProgressionProvider = NotifierProvider<EpreuveProgressionNotifier, Map<int, EpreuveProgressionModel>>(() {
  return EpreuveProgressionNotifier();
});