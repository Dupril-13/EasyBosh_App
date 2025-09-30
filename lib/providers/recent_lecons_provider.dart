import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recent_lecon_info_model.dart';
import '../models/lecon_model.dart';
import '../models/chapitre_model.dart';
import '../models/matiere_model.dart';
import 'user_chapter_progress_provider.dart'; // For supabaseClientProvider & currentUserIdProvider

const int _recentLeconsLimit = 3; // MODIFIÉ: Max number of recent lecons to show

class RecentLeconsState {
  final List<RecentLeconInfoModel> recentLecons;
  final bool isLoading;
  final String? errorMessage;

  RecentLeconsState({
    this.recentLecons = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RecentLeconsState copyWith({
    List<RecentLeconInfoModel>? recentLecons,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RecentLeconsState(
      recentLecons: recentLecons ?? this.recentLecons,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class RecentLeconsNotifier extends StateNotifier<RecentLeconsState> {
  final SupabaseClient _supabaseClient;
  final String? _userId;
  final Ref _ref; // To read other providers if necessary

  RecentLeconsNotifier(this._supabaseClient, this._userId, this._ref)
      : super(RecentLeconsState());

  Future<void> fetchRecentLecons() async {
    if (_userId == null) {
      state = state.copyWith(recentLecons: [], isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final progressionResponse = await _supabaseClient
          .from('cours_progression')
          .select('cours_id, updated_at')
          .eq('user_id', _userId!)
          .order('updated_at', ascending: false)
          .limit(_recentLeconsLimit);

      if (progressionResponse.isEmpty) {
        state = state.copyWith(recentLecons: [], isLoading: false);
        return;
      }

      List<RecentLeconInfoModel> detailedRecentLecons = [];

      for (var progressEntry in progressionResponse) {
        final leconId = progressEntry['cours_id'] as int?;
        final lastViewedAtString = progressEntry['updated_at'] as String?;

        if (leconId == null || lastViewedAtString == null) continue;
        final lastViewedAt = DateTime.tryParse(lastViewedAtString);
        if (lastViewedAt == null) continue;

        final leconResponse = await _supabaseClient
            .from('cours')
            .select('''
              *,
              chapitre_id:chapitres!inner(
                *,
                matiere_id:matieres!inner(*)
              )
            ''')
            .eq('id', leconId)
            .eq('actif', true)
            .maybeSingle();

        if (leconResponse == null) {
          print("Skipping lecon $leconId: Lecon details not found or not active.");
          continue;
        }
        
        final Map<String, dynamic> leconDataFromSupabase = leconResponse;
        final Map<String, dynamic>? chapitreObjectFromSupabase = leconDataFromSupabase['chapitre_id'] as Map<String, dynamic>?;
        final Map<String, dynamic>? matiereObjectFromSupabase = chapitreObjectFromSupabase?['matiere_id'] as Map<String, dynamic>?;

        if (chapitreObjectFromSupabase == null || matiereObjectFromSupabase == null) {
            print("Skipping lecon $leconId due to missing nested chapitreObject or matiereObject.");
            continue;
        }

        Map<String, dynamic> finalDataForLeconModel = Map.from(leconDataFromSupabase);
        finalDataForLeconModel['chapitre_id'] = chapitreObjectFromSupabase['id'] as int?;

        Map<String, dynamic> finalDataForChapitreModel = Map.from(chapitreObjectFromSupabase);
        finalDataForChapitreModel['matiere_id'] = matiereObjectFromSupabase['id'] as int?;

        final Map<String, dynamic> finalDataForMatiereModel = matiereObjectFromSupabase;
        
        try {
            final lecon = LeconModel.fromMap(finalDataForLeconModel);
            final chapitre = ChapitreModel.fromMap(finalDataForChapitreModel);
            final matiere = MatiereModel.fromMap(finalDataForMatiereModel);

            detailedRecentLecons.add(RecentLeconInfoModel(
              lecon: lecon,
              chapitre: chapitre,
              matiere: matiere,
              lastViewedAt: lastViewedAt,
            ));
        } catch (e, modelStackTrace) {
            print("Error creating models for lecon $leconId during fromMap conversion: $e\nStackTrace: $modelStackTrace");
        }
      }
      state = state.copyWith(recentLecons: detailedRecentLecons, isLoading: false);
    } catch (e, stackTrace) {
      print("Error fetching recent lecons (outer try-catch): $e\nStackTrace: $stackTrace");
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> markLeconAsViewed(int leconId) async {
    print("[markLeconAsViewed] Tentative de marquer leconId: $leconId comme vue.");

    if (_userId == null) {
      print("[markLeconAsViewed] ERREUR: Utilisateur non connecté (_userId est null). Impossible de marquer la leçon.");
      return;
    }
    print("[markLeconAsViewed] Pour userId: $_userId");

    try {
      final now = DateTime.now().toIso8601String();
      print("[markLeconAsViewed] Timestamp actuel: $now");

      print("[markLeconAsViewed] Recherche d'une progression existante pour leconId: $leconId, userId: $_userId");
      final existingProgression = await _supabaseClient
          .from('cours_progression')
          .select('id')
          .eq('user_id', _userId!)
          .eq('cours_id', leconId)
          .maybeSingle();

      if (existingProgression != null) {
        print("[markLeconAsViewed] Progression existante trouvée (id: ${existingProgression['id']}). Mise à jour.");
        await _supabaseClient
            .from('cours_progression')
            .update({'updated_at': now, 'commence': true})
            .eq('id', existingProgression['id']);
        print("[markLeconAsViewed] Progression mise à jour avec succès.");
      } else {
        print("[markLeconAsViewed] Aucune progression existante. Insertion d'une nouvelle entrée.");
        await _supabaseClient.from('cours_progression').insert({
          'user_id': _userId!,
          'cours_id': leconId,
          'updated_at': now,
          'commence': true,
        });
        print("[markLeconAsViewed] Nouvelle progression insérée avec succès.");
      }
      
      print("[markLeconAsViewed] Lecon $leconId marquée comme vue à $now pour user $_userId.");

    } catch (e, stackTrace) {
      print("[markLeconAsViewed] ERREUR lors du marquage de la leçon $leconId comme vue: $e");
      print("[markLeconAsViewed] StackTrace: $stackTrace");
    }
  }
}

final recentLeconsProvider = StateNotifierProvider<RecentLeconsNotifier, RecentLeconsState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  return RecentLeconsNotifier(supabaseClient, userId, ref);
});