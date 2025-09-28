import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/serie_model.dart';

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
class SerieNotifier extends StateNotifier<SerieState> {
  final SupabaseClient _supabaseClient;

  SerieNotifier(this._supabaseClient) : super(SerieState()) {
    fetchSeries(); // Charger initialement les séries
  }

  Future<void> fetchSeries() async {
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      final List<dynamic> response = await _supabaseClient
          .from('series')
          .select()
          .order('nom', ascending: true); // Ordonner par 'nom' ou un champ d'ordre spécifique

      final seriesData = response.map((item) => SerieModel.fromMap(item as Map<String, dynamic>)).toList();
      state = state.copyWith(series: seriesData, isLoading: false);
    } on PostgrestException catch (e) {
      print("Erreur Postgrest fetchSeries: ${e.message}");
      state = state.copyWith(errorMessage: "Erreur de base de données: ${e.message}", isLoading: false);
    } catch (e) {
      print("Erreur Générale fetchSeries: $e");
      state = state.copyWith(errorMessage: "Une erreur inattendue est survenue: $e", isLoading: false);
    }
  }
}

// Provider Riverpod
final serieProvider = StateNotifierProvider<SerieNotifier, SerieState>((ref) {
  final supabaseClient = Supabase.instance.client;
  return SerieNotifier(supabaseClient);
});
