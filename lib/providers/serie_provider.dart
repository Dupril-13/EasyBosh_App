import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/serie_model.dart';
import '../main.dart'; // For supabaseClientProvider

part 'serie_provider.g.dart';

// État pour le provider des séries
class SerieState {
  final List<SerieModel> series;
  final bool isLoading;
  final String? errorMessage;

  SerieState({
    this.series = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  SerieState copyWith({
    List<SerieModel>? series,
    bool? isLoading,
    String? errorMessage,
    bool? resetErrorMessage = false,
  }) {
    return SerieState(
      series: series ?? this.series,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: resetErrorMessage == true ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// Notifier pour gérer la logique de l'état des séries
@Riverpod(keepAlive: true)
class Serie extends _$Serie {
  late SupabaseClient _supabaseClient;

  @override
  SerieState build() {
    _supabaseClient = ref.watch(supabaseClientProvider);
    fetchSeries(); // Charger initialement les séries
    return SerieState(isLoading: true); 
  }

  Future<void> fetchSeries() async {
    // Assurer que isLoading est mis à true au début de la récupération, même si appelé plusieurs fois
    if (!state.isLoading || state.errorMessage != null) { // Vérifier aussi errorMessage pour reset en cas de re-fetch après erreur
        state = state.copyWith(isLoading: true, resetErrorMessage: true);
    }
    try {
      final List<dynamic> response = await _supabaseClient
          .from('series')
          .select()
          .order('nom', ascending: true); 

      final seriesData = response.map((item) => SerieModel.fromMap(item as Map<String, dynamic>)).toList();
      state = state.copyWith(series: seriesData, isLoading: false, resetErrorMessage: true);
    } on PostgrestException catch (e) {
      print("Erreur Postgrest fetchSeries: ${e.message}");
      state = state.copyWith(errorMessage: "Erreur de base de données: ${e.message}", isLoading: false);
    } catch (e) {
      print("Erreur Générale fetchSeries: $e");
      state = state.copyWith(errorMessage: "Une erreur inattendue est survenue: $e", isLoading: false);
    }
  }
}

// L'ancien "final serieProvider = StateNotifierProvider..." est supprimé.
// Le générateur créera `serieProvider`.
