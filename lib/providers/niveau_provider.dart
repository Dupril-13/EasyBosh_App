import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/niveau_model.dart';
import '../main.dart'; // For supabaseClientProvider

part 'niveau_provider.g.dart';

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
@Riverpod(keepAlive: true) // Ou simplement @riverpod si keepAlive n'est pas critique
class Niveau extends _$Niveau {
  late SupabaseClient _supabaseClient;

  @override
  NiveauState build() {
    _supabaseClient = ref.watch(supabaseClientProvider);
    fetchNiveaux(); // Charger initialement les niveaux
    // L'état initial peut indiquer un chargement si fetchNiveaux est asynchrone
    // et ne met pas à jour l'état immédiatement de manière synchrone avant de retourner.
    return NiveauState(isLoading: true); 
  }

  Future<void> fetchNiveaux() async {
    // Si build retourne isLoading:true, on peut éviter de le remettre ici
    // ou s'assurer que l'état initial dans build est NiveauState() et ici state.copyWith(isLoading: true...)
    if (!state.isLoading) {
        state = state.copyWith(isLoading: true, resetErrorMessage: true);
    }
    try {
      final List<dynamic> response = await _supabaseClient
          .from('niveaux')
          .select()
          .order('ordre', ascending: true);

      final niveaux = response.map((item) => NiveauModel.fromMap(item as Map<String, dynamic>)).toList();
      state = state.copyWith(niveaux: niveaux, isLoading: false, resetErrorMessage: true);
    } on PostgrestException catch (e) {
      print("Erreur Postgrest fetchNiveaux: ${e.message}");
      state = state.copyWith(errorMessage: "Erreur de base de données: ${e.message}", isLoading: false);
    } catch (e) {
      print("Erreur Générale fetchNiveaux: $e");
      state = state.copyWith(errorMessage: "Une erreur inattendue est survenue: $e", isLoading: false);
    }
  }
}

// L'ancien "final niveauProvider = StateNotifierProvider..." est supprimé.
// Le générateur créera `niveauProvider`.
