import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState; // AuthState de supabase masqué
import '../models/user_chapter_progress_model.dart';
import '../main.dart'; // For supabaseClientProvider
import '../core/providers/auth_provider.dart'; // For authProvider and our AuthState

part 'user_chapter_progress_provider.g.dart';

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

@Riverpod(keepAlive: true)
class UserChapterProgress extends _$UserChapterProgress {
  late SupabaseClient _supabaseClient;
  String? _userId;

  @override
  UserChapterProgressState build() {
    _supabaseClient = ref.watch(supabaseClientProvider);

    // Listen to authProvider for changes to userId 
    // and clear state if user logs out/changes.
    // Here, AuthState refers to our sealed class from auth_provider.dart
    ref.listen<AuthState>(authProvider, (previous, next) {
      String? newUserId;
      if (next is AuthAuthenticated) {
        newUserId = next.user.uid;
      } 

      if (_userId != newUserId) {
        print("[UserChapterProgress] Auth state changed. Old userId: $_userId, New userId: $newUserId");
        _userId = newUserId;
        state = UserChapterProgressState(); 
      }
    });

    final initialAuthState = ref.read(authProvider); 
    if (initialAuthState is AuthAuthenticated) {
      _userId = initialAuthState.user.uid;
    } else {
      _userId = null;
    }
    print("[UserChapterProgress] Initial build. userId: $_userId");
    
    return UserChapterProgressState();
  }

  Future<void> fetchProgressForChapters(List<int> chapitreIds) async {
    if (_userId == null) {
      state = state.copyWith(progressMap: {}, isLoading: false, clearErrorMessage: true, errorMessage: "Utilisateur non connecté pour récupérer la progression.");
      return;
    }
    if (chapitreIds.isEmpty) {
       state = state.copyWith(isLoading: false); 
       return;
    }
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final idsString = '(${chapitreIds.join(',')})';
      final response = await _supabaseClient
          .from('user_chapter_progress')
          .select()
          .eq('user_id', _userId!)
          .filter('chapitre_id', 'in', idsString);

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
      state = state.copyWith(errorMessage: "Utilisateur non connecté.", isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    final newCompletedStatus = !currentIsCompleted;

    try {
      final existingResponse = await _supabaseClient
          .from('user_chapter_progress')
          .select('id')
          .eq('user_id', _userId!)
          .eq('chapitre_id', chapitreId)
          .maybeSingle();

      UserChapterProgressModel updatedProgress;

      if (existingResponse != null && existingResponse['id'] != null) {
        final recordId = existingResponse['id'];
        final updateResponse = await _supabaseClient
            .from('user_chapter_progress')
            .update({'is_completed': newCompletedStatus, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', recordId)
            .select()
            .single();
         updatedProgress = UserChapterProgressModel.fromJson(updateResponse);
      } else {
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
  
  bool isChapterCompleted(int chapitreId) {
    return state.progressMap[chapitreId]?.isCompleted ?? false;
  }
}
