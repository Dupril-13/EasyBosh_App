import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/main.dart'; // Pour supabaseClientProvider
import 'dart:math'; // Pour la fonction max

class ChapitreState {
  final List<ChapitreModel> chapitres;
  final ChapitreModel? chapitrePourEdition;
  final bool isLoading;
  final String? errorMessage;

  ChapitreState({
    this.chapitres = const [],
    this.chapitrePourEdition,
    this.isLoading = false,
    this.errorMessage,
  });

  ChapitreState copyWith({
    List<ChapitreModel>? chapitres,
    ChapitreModel? chapitrePourEdition,
    bool? isLoading,
    String? errorMessage,
    bool setToNullChapitrePourEdition = false,
  }) {
    return ChapitreState(
      chapitres: chapitres ?? this.chapitres,
      chapitrePourEdition: setToNullChapitrePourEdition ? null : (chapitrePourEdition ?? this.chapitrePourEdition),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ChapitreNotifier extends StateNotifier<ChapitreState> {
  final SupabaseClient _supabaseClient;

  ChapitreNotifier(this._supabaseClient) : super(ChapitreState());

  Future<void> chargerChapitrePourEdition(int chapitreId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, setToNullChapitrePourEdition: true);
    try {
      final response = await _supabaseClient
          .from('chapitres')
          .select()
          .eq('id', chapitreId)
          .single(); 

      state = state.copyWith(chapitrePourEdition: ChapitreModel.fromMap(response as Map<String, dynamic>), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (chargerChapitrePourEdition): ${e.toString()}");
    }
  }

  Future<void> fetchChapitres({int? matiereId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      PostgrestFilterBuilder query = _supabaseClient.from('chapitres').select();

      if (matiereId != null) {
        query = query.eq('matiere_id', matiereId);
      }
      final response = await query.order('ordre', ascending: true);

      final List<ChapitreModel> fetchedChapitres = (response as List)
          .map((data) => ChapitreModel.fromMap(data as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, chapitres: fetchedChapitres);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (fetchChapitres): ${e.toString()}");
    }
  }

  Future<bool> addChapitre(ChapitreModel chapitreSansOrdre) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Récupérer les chapitres existants pour la matière donnée
      int nouvelOrdre = 1;
      if (chapitreSansOrdre.matiereId != null) {
        final existingChapitresResponse = await _supabaseClient
            .from('chapitres')
            .select('ordre')
            .eq('matiere_id', chapitreSansOrdre.matiereId!)
            .order('ordre', ascending: false) // Trier par ordre décroissant
            .limit(1); // Prendre seulement celui avec l'ordre le plus élevé

        final List<dynamic> existingChapitresData = existingChapitresResponse as List<dynamic>; 
        if (existingChapitresData.isNotEmpty) {
          final maxOrdre = existingChapitresData.first['ordre'] as int? ?? 0;
          nouvelOrdre = maxOrdre + 1;
        } 
      } else {
        // Gérer le cas où matiereId est null, si cela est permis par votre logique
        // Pour l'instant, on suppose que matiereId est toujours fourni pour un nouveau chapitre
        // et que l'ordre est par matière. Si ce n'est pas le cas, cette logique doit être ajustée.
        // Si matiereId peut être null et l'ordre est global, la requête ci-dessus doit être modifiée.
      }

      // 2. Créer le ChapitreModel avec le nouvel ordre
      final chapitreData = chapitreSansOrdre.toMap();
      chapitreData['ordre'] = nouvelOrdre; // Assigner le nouvel ordre calculé
      
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser != null) {
        chapitreData['created_by'] = currentUser.id;
      } 
      // Assurer que les champs non fournis par le formulaire mais obligatoires ou avec valeurs par défaut sont là
      // exemple: createdAt, si non géré par DB (mais il l'est souvent)
      // chapitreData.putIfAbsent('createdAt', () => DateTime.now().toIso8601String()); 

      final response = await _supabaseClient
          .from('chapitres')
          .insert(chapitreData)
          .select();

      final List<ChapitreModel> newChapitresList = (response as List)
        .map((data) => ChapitreModel.fromMap(data as Map<String, dynamic>))
        .toList();

      if (newChapitresList.isNotEmpty) {
        // Mettre à jour la liste locale des chapitres
        // Il serait bon de re-fetch les chapitres de la matière pour avoir la liste ordonnée correctement
        // ou d'insérer le nouveau chapitre à la bonne place dans la liste existante.
        // Pour l'instant, on l'ajoute au début, puis un fetchChapitres s'assurera de l'ordre correct.
        // await fetchChapitres(matiereId: newChapitresList.first.matiereId);
        state = state.copyWith(
          isLoading: false,
          // Ajouter le nouveau chapitre à la liste existante et trier
          chapitres: [...state.chapitres, newChapitresList.first]..sort((a, b) => a.ordre.compareTo(b.ordre)),
        );
        return true;
      } else {
         throw Exception("N'a pas pu ajouter le chapitre et récupérer la confirmation.");
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (addChapitre): ${e.toString()}");
      return false;
    }
  }

  Future<bool> updateChapitre(ChapitreModel chapitreAMettreAJour) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final Map<String, dynamic> chapitreData = chapitreAMettreAJour.toMap();
      // S'assurer que updated_at est mis à jour si ce n'est pas géré automatiquement par la DB
      // chapitreData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabaseClient
          .from('chapitres')
          .update(chapitreData)
          .eq('id', chapitreAMettreAJour.id)
          .select();

      final List<ChapitreModel> updatedChapitresList = (response as List)
        .map((data) => ChapitreModel.fromMap(data as Map<String, dynamic>))
        .toList();
      
      if (updatedChapitresList.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          chapitres: state.chapitres.map((ch) => ch.id == chapitreAMettreAJour.id ? updatedChapitresList.first : ch).toList()..sort((a, b) => a.ordre.compareTo(b.ordre)),
          chapitrePourEdition: updatedChapitresList.first, 
        );
        return true;
      } else {
        // Si select() ne retourne rien après un update (peut arriver avec certains setups RLS ou si la ligne n'existe plus)
        // Re-fetch pour s'assurer que l'état local est cohérent, même si la confirmation directe manque.
        fetchChapitres(matiereId: chapitreAMettreAJour.matiereId); 
        state = state.copyWith(isLoading: false, errorMessage: "Chapitre mis à jour, mais n'a pas pu récupérer la confirmation. Liste rafraîchie.");
        return false; 
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (updateChapitre): ${e.toString()}");
      return false;
    }
  }

  Future<void> updateChapitresOrder(List<ChapitreModel> chapitresReordonnes, int matiereId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Supabase ne permet pas de "batch update" simple avec des valeurs différentes par ligne via le client Dart directement de manière simple.
      // Nous devons faire des requêtes d'update individuelles ou utiliser une fonction RPC.
      // Option 1: Updates individuels (moins performant pour beaucoup d'items)
      for (int i = 0; i < chapitresReordonnes.length; i++) {
        final chapitre = chapitresReordonnes[i];
        await _supabaseClient
            .from('chapitres')
            .update({'ordre': i + 1}) // L'ordre est maintenant basé sur l'index (1-based)
            .eq('id', chapitre.id);
      }
      // Mettre à jour l'état local après toutes les mises à jour
      // Il est préférable de re-fetcher pour s'assurer de la cohérence avec la base de données
      await fetchChapitres(matiereId: matiereId);
      // Ou, si on est sûr que les updates ont réussi et que l'ordre local est bon :
      // state = state.copyWith(isLoading: false, chapitres: chapitresReordonnes.map((ch, index) => ch.copyWith(ordre: index + 1)).toList());
      state = state.copyWith(isLoading: false); // fetchChapitres mettra à jour l'état

    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (updateChapitresOrder): ${e.toString()}");
      // En cas d'erreur, re-fetcher pour revenir à l'état de la base de données
      await fetchChapitres(matiereId: matiereId);
    }
  }

  Future<bool> deleteChapitre(int chapitreId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabaseClient
          .from('chapitres')
          .delete()
          .eq('id', chapitreId);
      
      final matiereIdConcerne = state.chapitres.firstWhere((ch) => ch.id == chapitreId, orElse: () => ChapitreModel(id:0, nom:'', ordre:0, createdAt: DateTime.now(), actif: false, niveauCode: null, serieCode: null)).matiereId;

      state = state.copyWith(
        isLoading: false,
        chapitres: state.chapitres.where((ch) => ch.id != chapitreId).toList(),
      );
      if (state.chapitrePourEdition?.id == chapitreId) {
        state = state.copyWith(setToNullChapitrePourEdition: true);
      }
      // Après une suppression, il est bon de re-fetcher pour potentiellement réajuster les ordres si nécessaire
      // ou si la liste est affichée avec des numéros d'ordre visibles et consécutifs.
      // Pour l'instant, on se contente de retirer l'élément.
      // Si le glisser-déposer est la principale façon de gérer l'ordre, cela pourrait ne pas être nécessaire ici.
      if (matiereIdConcerne != null) {
        await fetchChapitres(matiereId: matiereIdConcerne); // Re-fetch pour la matière concernée
      }

      return true;
    } catch (e) {
      if (e is PostgrestException && e.code == '23503') { 
         state = state.copyWith(isLoading: false, errorMessage: "Impossible de supprimer: ce chapitre contient des leçons.");
      } else {
        state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (deleteChapitre): ${e.toString()}");
      }
      return false;
    }
  }
}

final chapitreProvider = StateNotifierProvider<ChapitreNotifier, ChapitreState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ChapitreNotifier(supabaseClient);
});
