import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easybosh_v2/models/profile_model.dart'; // Vérifiez ce chemin

// État de l'authentification et du profil
class AuthState {
  final User? supabaseUser; 
  final ProfileModel? userProfile;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.supabaseUser,
    this.userProfile,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    User? supabaseUser,
    ProfileModel? userProfile,
    bool? isLoading,
    String? errorMessage,
    bool clearSupabaseUser = false,
    bool clearUserProfile = false,
  }) {
    return AuthState(
      supabaseUser: clearSupabaseUser ? null : supabaseUser ?? this.supabaseUser,
      userProfile: clearUserProfile ? null : userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _supabaseClient;
  StreamSubscription<AuthStateChanges>? _authStateSubscription;

  AuthNotifier(this._supabaseClient) : super(AuthState(isLoading: true)) {
    _initialize();
  }

  Future<void> _initialize() async {
    _authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn) {
        if (session != null && session.user != null) {
          state = state.copyWith(supabaseUser: session.user, isLoading: true, errorMessage: null);
          await _fetchUserProfile(session.user.id);
        } else {
          state = state.copyWith(isLoading: false, supabaseUser: null, userProfile: null, errorMessage: "Session invalide après connexion.");
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false, errorMessage: null);
      } else if (event == AuthChangeEvent.userUpdated) {
        if (session != null && session.user != null) {
          state = state.copyWith(supabaseUser: session.user, isLoading: state.userProfile == null); // Ne charge que si le profil n'est pas déjà là
          if (state.userProfile == null || state.userProfile!.id != session.user.id) {
             await _fetchUserProfile(session.user.id);
          }
        }
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        if (session != null && session.user != null) {
          state = state.copyWith(supabaseUser: session.user);
          if (state.userProfile == null || state.userProfile!.id != session.user.id) {
             await _fetchUserProfile(session.user.id);
          }
        } else {
           state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false);
        }
      } else if (event == AuthChangeEvent.initialSession) {
        // Géré par la vérification de l'état initial ci-dessous
        // Si une session initiale est trouvée, on la traite comme un signedIn
         if (session != null && session.user != null) {
          state = state.copyWith(supabaseUser: session.user, isLoading: true, errorMessage: null);
          await _fetchUserProfile(session.user.id);
        } else {
          state = state.copyWith(isLoading: false);
        }
      }

      if (session == null && event != AuthChangeEvent.signedOut && event != AuthChangeEvent.initialSession ) {
        state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false);
      }
    });

    // Vérifier l'état initial au démarrage de l'app
    // Supabase SDK peut émettre initialSession, mais il est bon d'avoir un check explicite.
    final initialSession = _supabaseClient.auth.currentSession;
    if (initialSession != null && initialSession.user != null) {
      if(state.supabaseUser == null || state.supabaseUser!.id != initialSession.user.id) {
         state = state.copyWith(supabaseUser: initialSession.user, isLoading: true, errorMessage: null);
         await _fetchUserProfile(initialSession.user.id);
      }
    } else {
      state = state.copyWith(isLoading: false); // Assure que isLoading est false si pas de session initiale
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    // Si on est déjà en train de charger ou si le profil pour cet user est déjà chargé
    if (state.isLoading && state.userProfile?.id == userId && state.userProfile != null) return;
    
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
      // onAuthStateChange s'occupera de mettre à jour l'état à signedOut
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
      
      await _fetchUserProfile(state.supabaseUser!.id); // Rafraîchir après mise à jour
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
        state = state.copyWith(supabaseUser: currentSupabaseUser, isLoading: true, errorMessage: null);
        await _fetchUserProfile(currentSupabaseUser.id);
    } else {
        state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false, errorMessage: null);
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabaseClient = Supabase.instance.client;
  return AuthNotifier(supabaseClient);
});
