import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_chapter_progress_model.dart';

final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

// Provider for the current user ID (assuming you have an authProvider that exposes it)
// You might need to adjust this based on your existing authProvider structure.
final currentUserIdProvider = Provider<String?>((ref) {
  // Example: Replace with your actual way of getting the user ID
  // final authState = ref.watch(authProvider);
  // return authState.user?.id;
  return Supabase.instance.client.auth.currentUser?.id;
});

class UserChapterProgressState {
  final Map<int, UserChapterProgressModel> progressMap; // chapitreId -> progress
  final bool isLoading;
  final String? errorMessage;

  UserChapterProgressState({
    this.progressMap = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  UserChapterProgressState copyWith({
    Map<int, UserChapterProgressModel>? progressMap,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return UserChapterProgressState(
      progressMap: progressMap ?? this.progressMap,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class UserChapterProgressNotifier extends StateNotifier<UserChapterProgressState> {
  final SupabaseClient _supabaseClient;
  final String? _userId;

  UserChapterProgressNotifier(this._supabaseClient, this._userId)
      : super(UserChapterProgressState());

  Future<void> fetchProgressForChapters(List<int> chapitreIds) async {
    if (_userId == null || chapitreIds.isEmpty) {
      state = state.copyWith(progressMap: {}); // Clear progress if no user or no IDs
      return;
    }
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      // Format chapitreIds for the IN filter: (id1,id2,id3)
      final idsString = '(${chapitreIds.join(',')})';

      final response = await _supabaseClient
          .from('user_chapter_progress')
          .select()
          .eq('user_id', _userId!)
          .filter('chapitre_id', 'in', idsString); // Corrected line

      // print("Supabase response for chapter progress: $response"); // Debug log

      final newProgressMap = Map<int, UserChapterProgressModel>.from(state.progressMap);
      for (var item in response) {
        final progress = UserChapterProgressModel.fromJson(item);
        newProgressMap[progress.chapitreId] = progress;
      }
      state = state.copyWith(progressMap: newProgressMap, isLoading: false);
    } catch (e) {
      print("Error fetching chapter progress: $e");
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> toggleChapterCompletion(int chapitreId, bool currentIsCompleted) async {
    if (_userId == null) {
      state = state.copyWith(errorMessage: "Utilisateur non connecté.");
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    final newCompletedStatus = !currentIsCompleted;

    try {
      // Check if a record already exists
      final existingResponse = await _supabaseClient
          .from('user_chapter_progress')
          .select('id')
          .eq('user_id', _userId!)
          .eq('chapitre_id', chapitreId)
          .maybeSingle();

      UserChapterProgressModel updatedProgress;

      if (existingResponse != null && existingResponse['id'] != null) {
        // Update existing record
        final recordId = existingResponse['id'];
        final updateResponse = await _supabaseClient
            .from('user_chapter_progress')
            .update({'is_completed': newCompletedStatus, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', recordId)
            .select()
            .single();
         updatedProgress = UserChapterProgressModel.fromJson(updateResponse);
      } else {
        // Insert new record
        final insertResponse = await _supabaseClient
            .from('user_chapter_progress')
            .insert({
              'user_id': _userId!,
              'chapitre_id': chapitreId,
              'is_completed': newCompletedStatus,
            })
            .select()
            .single();
        updatedProgress = UserChapterProgressModel.fromJson(insertResponse);
      }
      
      final newProgressMap = Map<int, UserChapterProgressModel>.from(state.progressMap);
      newProgressMap[chapitreId] = updatedProgress;
      state = state.copyWith(progressMap: newProgressMap, isLoading: false);

    } catch (e) {
      print("Error toggling chapter completion: $e");
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }
  
  // Helper to get completion status for a single chapter
  bool isChapterCompleted(int chapitreId) {
    return state.progressMap[chapitreId]?.isCompleted ?? false;
  }
}

final userChapterProgressProvider = StateNotifierProvider<UserChapterProgressNotifier, UserChapterProgressState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  // Pass userId to the notifier. It will handle the case where userId is null.
  return UserChapterProgressNotifier(supabaseClient, userId);
});
