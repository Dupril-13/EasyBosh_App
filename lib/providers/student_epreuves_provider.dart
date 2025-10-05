import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/services/epreuve_service.dart';
import 'package:easybosh_v2/providers/auth_provider.dart';
import 'package:easybosh_v2/core/providers/auth_provider.dart';
import 'package:easybosh_v2/main.dart';

// Provider pour récupérer TOUTES les épreuves publiées pour l'étudiant
final studentEpreuvesProvider = FutureProvider.autoDispose<List<Epreuve>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final epreuveService = ref.read(epreuveServiceProvider);

  if (currentUser == null || currentUser.role != 'student') {
    return [];
  }

  // Récupérer uniquement les épreuves PUBLIÉES correspondant au profil de l'étudiant
  return await epreuveService.fetchFilteredEpreuves(
    niveauCode: currentUser.niveauCode,
    serieCode: currentUser.serieCode,
    epreuveStatut: EpreuveStatut.publiee,
  );
});

// Provider pour une épreuve spécifique par ID
final epreuveByIdProvider = FutureProvider.family.autoDispose<Epreuve, int>((ref, epreuveId) async {
  final epreuveService = ref.read(epreuveServiceProvider);
  return await epreuveService.getEpreuveById(epreuveId);
});

// Provider pour les épreuves filtrées par type
final epreuvesByTypeProvider = FutureProvider.family.autoDispose<List<Epreuve>, EpreuveType>((ref, type) async {
  final allEpreuves = await ref.watch(studentEpreuvesProvider.future);
  return allEpreuves.where((e) => e.typeEpreuve == type).toList();
});

// Provider pour compter les épreuves par type
final epreuvesCountByTypeProvider = FutureProvider.family.autoDispose<int, EpreuveType>((ref, type) async {
  final epreuvesByType = await ref.watch(epreuvesByTypeProvider(type).future);
  return epreuvesByType.length;
});