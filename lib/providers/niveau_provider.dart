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
    // Permet de explicitement mettre à null le message d'erreur
    String? errorMessage,
    bool? resetErrorMessage = false,
  }) {
    return NiveauState(
      niveaux: niveaux ?? this.niveaux,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: resetErrorMessage == true ? null : errorMessage ?? this.errorMessage,
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
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      final List<dynamic> response = await _supabaseClient
          .from('niveaux')
          .select()
          .order('ordre', ascending: true); // Ordonner par 'ordre' ou 'nom' selon préférence

      final niveaux = response.map((item) => NiveauModel.fromMap(item as Map<String, dynamic>)).toList();
      state = state.copyWith(niveaux: niveaux, isLoading: false);
    } on PostgrestException catch (e) {
      print("Erreur Postgrest fetchNiveaux: ${e.message}");
      state = state.copyWith(errorMessage: "Erreur de base de données: ${e.message}", isLoading: false);
    } catch (e) {
      print("Erreur Générale fetchNiveaux: $e");
      state = state.copyWith(errorMessage: "Une erreur inattendue est survenue: $e", isLoading: false);
    }
  }
}

// Provider Riverpod
final niveauProvider = StateNotifierProvider<NiveauNotifier, NiveauState>((ref) {
  final supabaseClient = Supabase.instance.client;
  return NiveauNotifier(supabaseClient);
});
