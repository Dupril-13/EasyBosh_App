import 'dart:async';
import 'package:flutter/foundation.dart'; // Importé pour ChangeNotifier
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:easybosh_v2/models/profile_model.dart';

class AuthStateData {
  final supabase.User? supabaseUser;
  final ProfileModel? userProfile;
  final bool isLoading;
  final String? errorMessage;

  AuthStateData({
    this.supabaseUser,
    this.userProfile,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthStateData copyWith({
    supabase.User? supabaseUser,
    ProfileModel? userProfile,
    bool? isLoading,
    String? errorMessage,
    bool clearSupabaseUser = false,
    bool clearUserProfile = false,
  }) {
    return AuthStateData(
      supabaseUser: clearSupabaseUser ? null : supabaseUser ?? this.supabaseUser,
      userProfile: clearUserProfile ? null : userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthStateData> {
  final supabase.SupabaseClient _supabaseClient;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  AuthNotifier(this._supabaseClient) : super(AuthStateData(isLoading: true)) {
    _initialize();
  }

  Future<void> _initialize() async {
    _authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen((data) async {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (event == supabase.AuthChangeEvent.signedIn) {
        if (session != null && session.user != null) {
          state = state.copyWith(supabaseUser: session.user, isLoading: true, errorMessage: null);
          await _fetchUserProfile(session.user.id);
        } else {
          state = state.copyWith(isLoading: false, supabaseUser: null, userProfile: null, errorMessage: "Session invalide après connexion.");
        }
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false, errorMessage: null);
      } else if (event == supabase.AuthChangeEvent.userUpdated) {
        if (session != null && session.user != null) {
          state = state.copyWith(supabaseUser: session.user, isLoading: state.userProfile == null);
          if (state.userProfile == null || state.userProfile!.id != session.user.id) {
             await _fetchUserProfile(session.user.id);
          }
        }
      } else if (event == supabase.AuthChangeEvent.tokenRefreshed) {
        if (session != null && session.user != null) {
          state = state.copyWith(supabaseUser: session.user);
          if (state.userProfile == null || state.userProfile!.id != session.user.id) {
             await _fetchUserProfile(session.user.id);
          }
        } else {
           state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false);
        }
      } else if (event == supabase.AuthChangeEvent.initialSession) {
         if (session != null && session.user != null) {
          state = state.copyWith(supabaseUser: session.user, isLoading: true, errorMessage: null);
          await _fetchUserProfile(session.user.id);
        } else {
          state = state.copyWith(isLoading: false);
        }
      }

      if (session == null && event != supabase.AuthChangeEvent.signedOut && event != supabase.AuthChangeEvent.initialSession ) {
        state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false);
      }
    });

    final initialSession = _supabaseClient.auth.currentSession;
    if (initialSession != null && initialSession.user != null) {
      if(state.supabaseUser == null || state.supabaseUser!.id != initialSession.user.id) {
         state = state.copyWith(supabaseUser: initialSession.user, isLoading: true, errorMessage: null);
         await _fetchUserProfile(initialSession.user.id);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    if (state.isLoading && state.userProfile?.id == userId && state.userProfile != null) {
       if(state.isLoading) {
         state = state.copyWith(isLoading: false);
       }
       return;
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final profile = ProfileModel.fromMap(response);
      state = state.copyWith(userProfile: profile, isLoading: false, errorMessage: null);

    } catch (e) {
      print('Erreur fetchUserProfile pour $userId: $e');
      state = state.copyWith(isLoading: false, userProfile: null, errorMessage: "Profil utilisateur introuvable ou erreur de chargement.");
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      print('Erreur signOut: $e');
      state = state.copyWith(isLoading: false, errorMessage: "Erreur lors de la déconnexion: ${e.toString()}");
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> dataToUpdate) async {
    if (state.supabaseUser == null) {
      state = state.copyWith(errorMessage: "Utilisateur non connecté pour mettre à jour le profil.");
      return false;
    }
    state = state.copyWith(isLoading: true);
    try {
      await _supabaseClient
          .from('profiles')
          .update(dataToUpdate)
          .eq('id', state.supabaseUser!.id);
      
      await _fetchUserProfile(state.supabaseUser!.id);
      return true;
    } catch (e) {
      print('Erreur updateUserProfile: $e');
      state = state.copyWith(isLoading: false, errorMessage: "Erreur lors de la mise à jour du profil: ${e.toString()}");
      return false;
    }
  }
  
  Future<void> refreshAuthStatusAndProfile() async {
    final currentSupabaseUser = _supabaseClient.auth.currentUser;
    if (currentSupabaseUser != null) {
        if (state.supabaseUser?.id != currentSupabaseUser.id || state.userProfile == null) {
           state = state.copyWith(supabaseUser: currentSupabaseUser, isLoading: true, errorMessage: null);
           await _fetchUserProfile(currentSupabaseUser.id);
        } else if(state.isLoading) { 
            state = state.copyWith(isLoading: false);
        }
    } else {
      if (state.supabaseUser != null || state.userProfile != null) {
        state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false, errorMessage: null);
      }
    }
  }

  bool get isLoggedIn => state.supabaseUser != null && state.userProfile != null;
  String? get userRole => state.userProfile?.role?.name;

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final supabaseClient = supabase.Supabase.instance.client;
  return AuthNotifier(supabaseClient);
});

// Classe pont pour GoRouter refreshListenable
class AuthStateListenable extends ChangeNotifier {
  final AuthNotifier _authNotifier;
  late final StreamSubscription<AuthStateData> _subscription;
  AuthStateData? _previousState;

  AuthStateListenable(this._authNotifier) {
    _previousState = _authNotifier.state;
    _subscription = _authNotifier.stream.listen((newState) {
      // Nous notifions seulement si l'état de connexion ou le rôle a changé
      // ou si l'utilisateur vient de se connecter/déconnecter (le profil peut être en cours de chargement).
      if (newState.supabaseUser?.id != _previousState?.supabaseUser?.id || 
          newState.userProfile?.role != _previousState?.userProfile?.role) {
        notifyListeners();
      }
      _previousState = newState;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
