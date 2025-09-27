import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/niveau_model.dart';

// État pour le provider des niveaux
class NiveauState {
  final List<NiveauModel> niveaux;
  final bool isLoading;
  final String? errorMessage;

  NiveauState({
    this.niveaux = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  NiveauState copyWith({
    List<NiveauModel>? niveaux,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NiveauState(
      niveaux: niveaux ?? this.niveaux,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Notifier pour gérer la logique de l'état des niveaux
class NiveauNotifier extends StateNotifier<NiveauState> {
  final SupabaseClient _supabaseClient;

  NiveauNotifier(this._supabaseClient) : super(NiveauState()) {
    fetchNiveaux(); // Charger initialement les niveaux
  }

  Future<void> fetchNiveaux() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabaseClient
          .from('niveaux')
          .select()
          .order('ordre', ascending: true); // Ordonner par 'ordre' ou 'nom' selon préférence

      // Gestion des erreurs Supabase v2+
      // if (response.error != null) { // Supabase < v2
      //   throw Exception(response.error!.message);
      // }
      // Pour Supabase >= v2, la réponse elle-même est la liste ou une PostgrestException est levée
      
      final List<dynamic> data = response as List<dynamic>; // Cast direct si succès
      final niveaux = data.map((item) => NiveauModel.fromMap(item as Map<String, dynamic>)).toList();
      state = state.copyWith(niveaux: niveaux, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      // print("Erreur fetchNiveaux: $e"); // Pour debug
    }
  }
}

// Provider Riverpod
final niveauProvider = StateNotifierProvider<NiveauNotifier, NiveauState>((ref) {
  final supabaseClient = Supabase.instance.client;
  return NiveauNotifier(supabaseClient);
});
