import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/main.dart'; // Pour supabaseClientProvider

class ChapitreState {
  final List<ChapitreModel> chapitres;
  final ChapitreModel? chapitrePourEdition;
  final bool isLoading;
  final String? errorMessage;
  // Pour se souvenir des derniers filtres utilisés pour fetchChapitres
  final int? currentMatiereId;
  final String? currentNiveauCode;
  final String? currentSerieCode;

  ChapitreState({
    this.chapitres = const [],
    this.chapitrePourEdition,
    this.isLoading = false,
    this.errorMessage,
    this.currentMatiereId,
    this.currentNiveauCode,
    this.currentSerieCode,
  });

  ChapitreState copyWith({
    List<ChapitreModel>? chapitres,
    ChapitreModel? chapitrePourEdition,
    bool? isLoading,
    String? errorMessage,
    bool? resetErrorMessage = false,
    bool setToNullChapitrePourEdition = false,
    int? currentMatiereId,
    String? currentNiveauCode,
    String? currentSerieCode,
    bool resetCurrentFilters = false,
  }) {
    return ChapitreState(
      chapitres: chapitres ?? this.chapitres,
      chapitrePourEdition: setToNullChapitrePourEdition ? null : (chapitrePourEdition ?? this.chapitrePourEdition),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: resetErrorMessage == true ? null : errorMessage ?? this.errorMessage,
      currentMatiereId: resetCurrentFilters ? null : currentMatiereId ?? this.currentMatiereId,
      currentNiveauCode: resetCurrentFilters ? null : currentNiveauCode ?? this.currentNiveauCode,
      currentSerieCode: resetCurrentFilters ? null : currentSerieCode ?? this.currentSerieCode,
    );
  }
}

class ChapitreNotifier extends StateNotifier<ChapitreState> {
  final SupabaseClient _supabaseClient;

  ChapitreNotifier(this._supabaseClient) : super(ChapitreState());

  Future<void> chargerChapitrePourEdition(int chapitreId) async {
    state = state.copyWith(isLoading: true, resetErrorMessage: true, setToNullChapitrePourEdition: true);
    try {
      final response = await _supabaseClient
          .from('chapitres')
          .select()
          .eq('id', chapitreId)
          .single(); 

      state = state.copyWith(chapitrePourEdition: ChapitreModel.fromMap(response as Map<String, dynamic>), isLoading: false);
    } on PostgrestException catch (e) {
      print("Erreur Postgrest chargerChapitrePourEdition: ${e.message}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur DB (chargement chapitre): ${e.message}");
    } catch (e) {
      print("Erreur Générale chargerChapitrePourEdition: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur inattendue (chargement chapitre): $e");
    }
  }

  // Fetch chapitres REQUIERT matiereId, niveauCode, et serieCode
  Future<void> fetchChapitres({
    required int matiereId, 
    required String niveauCode, 
    required String serieCode
  }) async {
    state = state.copyWith(
      isLoading: true, 
      resetErrorMessage: true, 
      // Stocker les filtres actuels pour les opérations CRUD futures
      currentMatiereId: matiereId,
      currentNiveauCode: niveauCode,
      currentSerieCode: serieCode
    );
    try {
      final response = await _supabaseClient
          .from('chapitres')
          .select()
          .eq('matiere_id', matiereId)
          .eq('niveau_code', niveauCode)
          .eq('serie_code', serieCode)
          .order('ordre', ascending: true);

      final List<ChapitreModel> fetchedChapitres = (response as List)
          .map((data) => ChapitreModel.fromMap(data as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, chapitres: fetchedChapitres);
    } on PostgrestException catch (e) {
      print("Erreur Postgrest fetchChapitres: ${e.message}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur DB (liste chapitres): ${e.message}");
    } catch (e) {
      print("Erreur Générale fetchChapitres: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur inattendue (liste chapitres): $e");
    }
  }

  // Le ChapitreModel doit maintenant avoir matiereId, niveauCode, et serieCode renseignés
  Future<bool> addChapitre(ChapitreModel chapitreAAjouter) async {
    if (chapitreAAjouter.matiereId == null || chapitreAAjouter.niveauCode == null || chapitreAAjouter.serieCode == null) {
      state = state.copyWith(errorMessage: "Matière, Niveau et Série sont requis pour ajouter un chapitre.");
      return false;
    }
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      int nouvelOrdre = 1;
      final existingChapitresResponse = await _supabaseClient
          .from('chapitres')
          .select('ordre')
          .eq('matiere_id', chapitreAAjouter.matiereId!)
          .eq('niveau_code', chapitreAAjouter.niveauCode!)
          .eq('serie_code', chapitreAAjouter.serieCode!)
          .order('ordre', ascending: false)
          .limit(1);

      final List<dynamic> existingChapitresData = existingChapitresResponse as List<dynamic>; 
      if (existingChapitresData.isNotEmpty) {
        final maxOrdre = existingChapitresData.first['ordre'] as int? ?? 0;
        nouvelOrdre = maxOrdre + 1;
      }

      final chapitreData = chapitreAAjouter.copyWith(ordre: nouvelOrdre).toMap();
      
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser != null) {
        chapitreData['created_by'] = currentUser.id;
      }
      // created_at et updated_at sont gérés par la DB

      final response = await _supabaseClient
          .from('chapitres')
          .insert(chapitreData)
          .select();

      final List<ChapitreModel> newChapitresList = (response as List)
        .map((data) => ChapitreModel.fromMap(data as Map<String, dynamic>))
        .toList();

      if (newChapitresList.isNotEmpty) {
        await fetchChapitres(
          matiereId: chapitreAAjouter.matiereId!,
          niveauCode: chapitreAAjouter.niveauCode!,
          serieCode: chapitreAAjouter.serieCode!
        );
        return true;
      } else {
         throw Exception("N'a pas pu ajouter le chapitre et récupérer la confirmation.");
      }
    } on PostgrestException catch (e) {
      print("Erreur Postgrest addChapitre: ${e.message}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur DB (ajout chapitre): ${e.message}");
      return false;
    } catch (e) {
      print("Erreur Générale addChapitre: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur inattendue (ajout chapitre): $e");
      return false;
    }
  }

  Future<bool> updateChapitre(ChapitreModel chapitreAMettreAJour) async {
    if (chapitreAMettreAJour.matiereId == null || chapitreAMettreAJour.niveauCode == null || chapitreAMettreAJour.serieCode == null) {
      state = state.copyWith(errorMessage: "Matière, Niveau et Série sont requis pour mettre à jour un chapitre.");
      return false;
    }
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      final Map<String, dynamic> chapitreData = chapitreAMettreAJour.toMap();
      chapitreData['updated_at'] = DateTime.now().toIso8601String(); // Forcer la maj de updated_at

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
          chapitrePourEdition: state.chapitrePourEdition?.id == chapitreAMettreAJour.id ? updatedChapitresList.first : state.chapitrePourEdition,
        );
        // Si l'update concerne le chapitre en cours d'édition, le mettre à jour aussi
        // Le fetchChapitres ci-dessous le fera aussi mais c'est pour une réactivité immédiate de chapitrePourEdition
        // await fetchChapitres(
        //   matiereId: chapitreAMettreAJour.matiereId!,
        //   niveauCode: chapitreAMettreAJour.niveauCode!,
        //   serieCode: chapitreAMettreAJour.serieCode!
        // );
        return true;
      } else {
        await fetchChapitres( // Assurer la cohérence en cas d'échec de récupération
          matiereId: chapitreAMettreAJour.matiereId!,
          niveauCode: chapitreAMettreAJour.niveauCode!,
          serieCode: chapitreAMettreAJour.serieCode!
        );
        state = state.copyWith(isLoading: false, errorMessage: "Chapitre mis à jour, mais n'a pas pu récupérer la confirmation. Liste rafraîchie.");
        return false; 
      }
    } on PostgrestException catch (e) {
      print("Erreur Postgrest updateChapitre: ${e.message}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur DB (maj chapitre): ${e.message}");
      return false;
    } catch (e) {
      print("Erreur Générale updateChapitre: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur inattendue (maj chapitre): $e");
      return false;
    }
  }

  Future<void> updateChapitresOrder(List<ChapitreModel> chapitresReordonnes, {
    required int matiereId, 
    required String niveauCode, 
    required String serieCode
  }) async {
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      for (int i = 0; i < chapitresReordonnes.length; i++) {
        final chapitre = chapitresReordonnes[i];
        await _supabaseClient
            .from('chapitres')
            .update({'ordre': i + 1}) 
            .eq('id', chapitre.id);
      }
      await fetchChapitres(matiereId: matiereId, niveauCode: niveauCode, serieCode: serieCode);
      state = state.copyWith(isLoading: false); // fetchChapitres met à jour l'état
    } on PostgrestException catch (e) {
      print("Erreur Postgrest updateChapitresOrder: ${e.message}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur DB (ordre chapitres): ${e.message}");
      await fetchChapitres(matiereId: matiereId, niveauCode: niveauCode, serieCode: serieCode);
    } catch (e) {
      print("Erreur Générale updateChapitresOrder: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur inattendue (ordre chapitres): $e");
      await fetchChapitres(matiereId: matiereId, niveauCode: niveauCode, serieCode: serieCode);
    }
  }

  Future<bool> deleteChapitre(int chapitreId) async {
    // Pour le re-fetch, nous avons besoin du contexte du chapitre supprimé
    // Correction: chapitreASupprimer est maintenant ChapitreModel (non-nullable)
    final ChapitreModel chapitreASupprimer = state.chapitres.firstWhere((ch) => ch.id == chapitreId, orElse: () => ChapitreModel(id:0, nom:'', ordre:0, createdAt: DateTime.now(), actif: false)); // Placeholder
    
    // Les champs matiereId, niveauCode, serieCode peuvent être null dans le placeholder,
    // donc cette vérification reste pertinente.
    if (chapitreASupprimer.id == 0 || chapitreASupprimer.matiereId == null || chapitreASupprimer.niveauCode == null || chapitreASupprimer.serieCode == null) {
      // Si le chapitre n'a pas été trouvé (id == 0) ou si son contexte est incomplet,
      // on ne peut pas re-fetcher son contexte spécifique.
      print("Impossible de déterminer le contexte complet du chapitre ID: $chapitreId (ou chapitre non trouvé dans l'état) pour le re-fetch après suppression. Tentative avec les filtres de l'état actuel.");
    }

    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      await _supabaseClient
          .from('chapitres')
          .delete()
          .eq('id', chapitreId);
      
      if (state.chapitrePourEdition?.id == chapitreId) {
        state = state.copyWith(setToNullChapitrePourEdition: true, isLoading: false); 
      }

      // Essayer de re-fetcher avec le contexte du chapitre supprimé si disponible et valide
      if (chapitreASupprimer.id != 0 && chapitreASupprimer.matiereId != null && chapitreASupprimer.niveauCode != null && chapitreASupprimer.serieCode != null) {
         await fetchChapitres(
          matiereId: chapitreASupprimer.matiereId!, // MODIFIÉ: ! ré-ajouté
          niveauCode: chapitreASupprimer.niveauCode!, // MODIFIÉ: ! ré-ajouté
          serieCode: chapitreASupprimer.serieCode!    // MODIFIÉ: ! ré-ajouté
        );
      } else if (state.currentMatiereId != null && state.currentNiveauCode != null && state.currentSerieCode != null) {
        // Fallback: utiliser les derniers filtres connus de l'état du provider
        await fetchChapitres(
          matiereId: state.currentMatiereId!, // MODIFIÉ: ! ré-ajouté
          niveauCode: state.currentNiveauCode!, // MODIFIÉ: ! ré-ajouté
          serieCode: state.currentSerieCode! // MODIFIÉ: ! ré-ajouté
        );
      } else {
        // Si aucun contexte n'est connu, vider la liste ou gérer autrement.
        // S'assurer que isLoading est mis à jour si fetchChapitres n'est pas appelé.
        state = state.copyWith(chapitres: [], isLoading: false);
      }
      // Note: fetchChapitres met à jour isLoading. La branche `else` ci-dessus aussi.
      return true;
    } on PostgrestException catch (e) {
      print("Erreur Postgrest deleteChapitre: ${e.message}");
      if (e.code == '23503') { 
         state = state.copyWith(isLoading: false, errorMessage: "Impossible de supprimer: ce chapitre contient des leçons.");
      } else {
        state = state.copyWith(isLoading: false, errorMessage: "Erreur DB (sup chapitre): ${e.message}");
      }
      return false;
    } catch (e) {
      print("Erreur Générale deleteChapitre: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur inattendue (sup chapitre): $e");
      return false;
    }
  }

   // Appelé quand les filtres changent et qu'aucune matière/niveau/série n'est sélectionné (ou invalide)
  void clearChapitres() {
    state = state.copyWith(chapitres: [], isLoading: false, resetErrorMessage: true, resetCurrentFilters: true );
  }
}

final chapitreProvider = StateNotifierProvider<ChapitreNotifier, ChapitreState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ChapitreNotifier(supabaseClient);
});
