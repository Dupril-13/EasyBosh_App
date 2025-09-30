import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chapitre_model.dart';
import 'package:flutter/foundation.dart'; // Import pour debugPrint

// 1. Définition de l'état du provider
class ChapitreState {
  final List<ChapitreModel> chapitres;
  final bool isLoading;
  final String? errorMessage;
  final ChapitreModel? chapitrePourEdition;

  ChapitreState({
    this.chapitres = const [],
    this.isLoading = false,
    this.errorMessage,
    this.chapitrePourEdition,
  });

  ChapitreState copyWith({
    List<ChapitreModel>? chapitres,
    bool? isLoading,
    String? errorMessage,
    ChapitreModel? chapitrePourEdition,
    bool clearChapitrePourEdition = false,
  }) {
    return ChapitreState(
      chapitres: chapitres ?? this.chapitres,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      chapitrePourEdition: clearChapitrePourEdition ? null : chapitrePourEdition ?? this.chapitrePourEdition,
    );
  }
}

// 2. Création du Notifier
class ChapitreNotifier extends StateNotifier<ChapitreState> {
  final SupabaseClient _supabaseClient;

  ChapitreNotifier(this._supabaseClient) : super(ChapitreState());

  Future<void> fetchChapitres(int matiereId, {String? niveauCode, String? serieCode}) async {
    debugPrint("[ChapitreProvider] Fetching chapitres for matiereId: $matiereId, niveauCode: $niveauCode, serieCode: $serieCode");
    state = state.copyWith(isLoading: true, errorMessage: null, clearChapitrePourEdition: true, chapitres: []);
    
    try {
      // Utiliser PostgrestFilterBuilder pour construire la requête de filtre
      PostgrestFilterBuilder<List<Map<String, dynamic>>> queryBuilder = _supabaseClient
          .from('chapitres')
          .select()
          .eq('matiere_id', matiereId)
          .eq('actif', true);

      if (niveauCode != null && niveauCode.isNotEmpty) {
        queryBuilder = queryBuilder.eq('niveau_code', niveauCode);
      } else {
        debugPrint("[ChapitreProvider] niveauCode non fourni, ne filtre pas par niveau.");
      }

      if (niveauCode == '3eme') {
         if (serieCode == null || serieCode.isEmpty || serieCode == 'TC') {
            queryBuilder = queryBuilder.or('serie_code.is.null,serie_code.eq.TC');
         } else {
            queryBuilder = queryBuilder.eq('serie_code', serieCode);
         }
      } else if (serieCode != null && serieCode.isNotEmpty) {
         queryBuilder = queryBuilder.eq('serie_code', serieCode);
      } else if (niveauCode != null && niveauCode.isNotEmpty && niveauCode != '3eme'){
         debugPrint("[ChapitreProvider] serieCode non fourni pour niveau $niveauCode (non-3eme). Les résultats pourraient être vides ou incomplets.");
      }

      // Appliquer .order() à la fin et exécuter la requête
      final response = await queryBuilder.order('ordre', ascending: true);

      final List<dynamic> data = response; // response est déjà List<Map<String, dynamic>>
      final chapitres = data.map((item) => ChapitreModel.fromMap(item as Map<String, dynamic>)).toList();
      state = state.copyWith(chapitres: chapitres, isLoading: false);
      debugPrint("[ChapitreProvider] Fetched ${chapitres.length} chapitres.");
      
    } catch (e) {
      debugPrint('[ChapitreProvider] Exception fetching chapitres: $e');
      String errorMessage = 'Une erreur est survenue lors de la récupération des chapitres.';
      if (e is PostgrestException) {
        errorMessage = 'Erreur Supabase (fetchChapitres): ${e.message} (code: ${e.code})';
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMessage, chapitres: []);
    }
  }

  void clearDataAndError() {
    state = ChapitreState(); 
  }

  void clearChapitres() { 
    state = state.copyWith(chapitres: [], errorMessage: null, isLoading: false, clearChapitrePourEdition: true);
  }

   void setExternalError(String message) {
    state = state.copyWith(isLoading: false, errorMessage: message, chapitres: []);
  }

  Future<void> chargerChapitrePourEdition(int chapitreId) async {
    debugPrint("[ChapitreProvider] Chargement du chapitre $chapitreId pour édition.");
    state = state.copyWith(isLoading: true, errorMessage: null, clearChapitrePourEdition: true);
    try {
      final response = await _supabaseClient
          .from('chapitres')
          .select()
          .eq('id', chapitreId)
          .single(); 

      final chapitre = ChapitreModel.fromMap(response as Map<String, dynamic>); 
      state = state.copyWith(chapitrePourEdition: chapitre, isLoading: false);
      debugPrint("[ChapitreProvider] Chapitre chargé pour édition: ${chapitre.nom}");
    } catch (e) {
      debugPrint("[ChapitreProvider] Erreur lors du chargement du chapitre $chapitreId: $e");
      String errorMessage = 'Impossible de charger le chapitre.';
      if (e is PostgrestException) {
        errorMessage = 'Erreur Supabase (chargerChapitre): ${e.message} (code: ${e.code})';
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
    }
  }

  Future<bool> addChapitre(ChapitreModel chapitreDetails) async {
    debugPrint("[ChapitreProvider] Ajout du chapitre: ${chapitreDetails.nom} pour matiereId ${chapitreDetails.matiereId}, niveau ${chapitreDetails.niveauCode}, serie ${chapitreDetails.serieCode}");
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final mapData = chapitreDetails.toMap();
      
      if (mapData['matiere_id'] == null) {
         debugPrint("[ChapitreProvider] Erreur: matiere_id est manquant.");
         state = state.copyWith(isLoading: false, errorMessage: "L\'ID de la matière est requis.");
         return false;
      }
      if (mapData['niveau_code'] == null || (mapData['niveau_code'] as String).isEmpty) {
         debugPrint("[ChapitreProvider] Erreur: niveau_code est manquant.");
         state = state.copyWith(isLoading: false, errorMessage: "Le code du niveau est requis.");
         return false;
      }
      if (mapData['niveau_code'] != '3eme' && (mapData['serie_code'] == null || (mapData['serie_code'] as String).isEmpty)) {
         debugPrint("[ChapitreProvider] Erreur: serie_code est manquant pour niveau ${mapData['niveau_code']}.");
         state = state.copyWith(isLoading: false, errorMessage: "Le code de la série est requis pour ce niveau.");
         return false;
      }
      if (mapData['niveau_code'] == '3eme' && mapData['serie_code'] == 'TC') {
        // Laisser TC tel quel
      } else if (mapData['niveau_code'] == '3eme' && (mapData['serie_code'] == null || (mapData['serie_code'] as String).isEmpty)) {
          mapData['serie_code'] = null; 
      }

      await _supabaseClient.from('chapitres').insert(mapData);
      debugPrint("[ChapitreProvider] Chapitre ${chapitreDetails.nom} ajouté avec succès.");
      if (chapitreDetails.matiereId != null) {
         await fetchChapitres(chapitreDetails.matiereId!, niveauCode: chapitreDetails.niveauCode, serieCode: chapitreDetails.serieCode);
      }
      // state = state.copyWith(isLoading: false); // fetchChapitres s'en occupe
      return true;
    } catch (e) {
      debugPrint("[ChapitreProvider] Erreur lors de l'ajout du chapitre ${chapitreDetails.nom}: $e");
      String errorMessage = 'Impossible d\'ajouter le chapitre.';
      if (e is PostgrestException) {
        errorMessage = 'Erreur Supabase (addChapitre): ${e.message} (code: ${e.code})';
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  Future<bool> updateChapitre(ChapitreModel chapitreDetails) async {
    debugPrint("[ChapitreProvider] Mise à jour du chapitre: ${chapitreDetails.id} - ${chapitreDetails.nom}");
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final mapData = chapitreDetails.toMap();
      await _supabaseClient.from('chapitres').update(mapData).eq('id', chapitreDetails.id);
      debugPrint("[ChapitreProvider] Chapitre ${chapitreDetails.nom} mis à jour avec succès.");
      if (chapitreDetails.matiereId != null) {
        await fetchChapitres(chapitreDetails.matiereId!, niveauCode: chapitreDetails.niveauCode, serieCode: chapitreDetails.serieCode);
      }
      state = state.copyWith(clearChapitrePourEdition: true); // isLoading est géré par fetchChapitres
      return true;
    } catch (e) {
      debugPrint("[ChapitreProvider] Erreur lors de la maj du chapitre ${chapitreDetails.nom}: $e");
      String errorMessage = 'Impossible de mettre à jour le chapitre.';
      if (e is PostgrestException) {
        errorMessage = 'Erreur Supabase (updateChapitre): ${e.message} (code: ${e.code})';
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  Future<bool> deleteChapitre(int chapitreId, {int? currentMatiereId, String? currentNiveauCode, String? currentSerieCode}) async {
    debugPrint("[ChapitreProvider] Suppression du chapitre $chapitreId.");
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabaseClient.from('chapitres').delete().eq('id', chapitreId);
      debugPrint("[ChapitreProvider] Chapitre $chapitreId supprimé avec succès.");
      if (currentMatiereId != null) {
        await fetchChapitres(currentMatiereId, niveauCode: currentNiveauCode, serieCode: currentSerieCode);
      }
      // state = state.copyWith(isLoading: false); // fetchChapitres s'en occupe
      return true;
    } catch (e) {
      debugPrint("[ChapitreProvider] Erreur lors de la suppression du chapitre $chapitreId: $e");
      String errorMessage = 'Impossible de supprimer le chapitre.';
      if (e is PostgrestException) {
        errorMessage = 'Erreur Supabase (deleteChapitre): ${e.message} (code: ${e.code})';
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  Future<void> updateChapitresOrder(List<ChapitreModel> chapitres, {int? matiereId, String? niveauCode, String? serieCode}) async {
    debugPrint("[ChapitreProvider] Mise à jour de l'ordre des chapitres pour matiereId: $matiereId, niveau: $niveauCode, serie: $serieCode.");
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      for (var i = 0; i < chapitres.length; i++) {
        final chapitre = chapitres[i];
        await _supabaseClient.from('chapitres').update({'ordre': i}).eq('id', chapitre.id);
      }
      debugPrint("[ChapitreProvider] Ordre des chapitres mis à jour.");
      if (matiereId != null) {
        await fetchChapitres(matiereId, niveauCode: niveauCode, serieCode: serieCode);
      }
      // state = state.copyWith(isLoading: false); // fetchChapitres s'en occupe
    } catch (e) {
      debugPrint("[ChapitreProvider] Erreur lors de la mise à jour de l'ordre des chapitres: $e");
      String errorMessage = 'Impossible de mettre à jour l\'ordre des chapitres.';
      if (e is PostgrestException) {
        errorMessage = 'Erreur Supabase (updateChapitresOrder): ${e.message} (code: ${e.code})';
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
    }
  }
}

final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

final chapitreProvider = StateNotifierProvider<ChapitreNotifier, ChapitreState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ChapitreNotifier(client);
});
