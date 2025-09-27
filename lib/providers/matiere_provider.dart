import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/main.dart'; // Pour supabaseClientProvider

class MatiereState {
  final bool isLoading;
  final List<MatiereModel> matieres;
  final String? errorMessage;

  MatiereState({
    this.isLoading = false,
    this.matieres = const [],
    this.errorMessage,
  });

  MatiereState copyWith({
    bool? isLoading,
    List<MatiereModel>? matieres,
    String? errorMessage,
  }) {
    return MatiereState(
      isLoading: isLoading ?? this.isLoading,
      matieres: matieres ?? this.matieres,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MatiereNotifier extends StateNotifier<MatiereState> {
  final SupabaseClient _supabaseClient;

  MatiereNotifier(this._supabaseClient) : super(MatiereState()) {
    fetchMatieres();
  }

  Future<void> fetchMatieres() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabaseClient
          .from('matieres')
          .select() // Sélecteur de colonnes peut être ajouté ici si nécessaire, ex: .select('id, nom, code, ...')
          .order('nom', ascending: true); 

      final List<MatiereModel> fetchedMatieres = (response as List)
          .map((data) => MatiereModel.fromMap(data as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, matieres: fetchedMatieres);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (fetchMatieres): ${e.toString()}");
    }
  }

  Future<bool> addMatiere(MatiereModel matiereAAjouter) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // L'ID est auto-généré par Supabase (SERIAL), donc on ne l'inclut pas dans le payload d'insertion.
      // matiereAAjouter est un MatiereModel qui peut avoir un ID (par ex. 0 ou un placeholder) 
      // mais toMapForInsert() ne devrait pas l'inclure.
      final response = await _supabaseClient
          .from('matieres')
          .insert(matiereAAjouter.toMapForInsert()) 
          .select(); // Récupère la ligne insérée avec l'ID généré et les valeurs par défaut (createdAt, updatedAt)

      final List<MatiereModel> newMatieresList = (response as List)
        .map((data) => MatiereModel.fromMap(data as Map<String, dynamic>))
        .toList();

      if (newMatieresList.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          matieres: [newMatieresList.first, ...state.matieres], 
        );
        return true;
      } else {
         throw Exception("N'a pas pu ajouter la matière et récupérer la confirmation.");
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (addMatiere): ${e.toString()}");
      return false;
    }
  }

  Future<bool> updateMatiere(MatiereModel matiereAMettreAJour) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabaseClient
          .from('matieres')
          .update(matiereAMettreAJour.toMapForUpdate()) 
          .eq('id', matiereAMettreAJour.id) // L'ID est un int
          .select();

      final List<MatiereModel> updatedMatieresList = (response as List)
        .map((data) => MatiereModel.fromMap(data as Map<String, dynamic>))
        .toList();
      
      if (updatedMatieresList.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          matieres: state.matieres.map((m) => m.id == matiereAMettreAJour.id ? updatedMatieresList.first : m).toList(),
        );
        return true;
      } else {
        // Si la liste est vide, cela peut signifier que la matière avec cet ID n'a pas été trouvée
        // ou que la mise à jour a réussi mais .select() n'a rien retourné (moins probable avec Supabase).
        // Un refetch peut être une bonne sécurité, ou lancer une exception.
        // throw Exception("La matière à mettre à jour n'a pas été trouvée ou le retour est vide.");
        // Pour l'instant, on considère que si select est vide, c'est un problème potentiel.
        fetchMatieres(); // Pour s'assurer de la cohérence de l'état local.
        state = state.copyWith(isLoading: false, errorMessage: "Matière mise à jour, mais n'a pas pu récupérer la confirmation. Liste rafraîchie.");
        return false; // Ou true si vous considérez que la MàJ a pu réussir côté DB.
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (updateMatiere): ${e.toString()}");
      return false;
    }
  }

  Future<bool> deleteMatiere(int matiereId) async { // L'ID est un int
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabaseClient
          .from('matieres')
          .delete()
          .eq('id', matiereId);
      
      state = state.copyWith(
        isLoading: false,
        matieres: state.matieres.where((m) => m.id != matiereId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (deleteMatiere): ${e.toString()}");
      return false;
    }
  }
}

final matiereProvider = StateNotifierProvider<MatiereNotifier, MatiereState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return MatiereNotifier(supabaseClient);
});
