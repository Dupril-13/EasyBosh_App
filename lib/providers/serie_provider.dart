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
  }) {
    return SerieState(
      series: series ?? this.series,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabaseClient
          .from('series')
          .select()
          .order('nom', ascending: true); // Ordonner par 'nom' ou un champ d'ordre spécifique

      final List<dynamic> data = response as List<dynamic>; 
      final series = data.map((item) => SerieModel.fromMap(item as Map<String, dynamic>)).toList();
      state = state.copyWith(series: series, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      // print("Erreur fetchSeries: $e"); // Pour debug
    }
  }
}

// Provider Riverpod
final serieProvider = StateNotifierProvider<SerieNotifier, SerieState>((ref) {
  final supabaseClient = Supabase.instance.client;
  return SerieNotifier(supabaseClient);
});
