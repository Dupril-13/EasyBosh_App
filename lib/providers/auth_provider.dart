import 'dart:async';
import 'package:flutter/foundation.dart'; // Conservé pour ChangeNotifier si AuthStateListenable est restauré différemment
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:easybosh_v2/models/profile_model.dart';

part 'auth_provider.g.dart';

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

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  @override
  AuthStateData build() {
    final supabaseClient = supabase.Supabase.instance.client;
    _initialize(supabaseClient);
    // Établir un état initial synchrone
    final initialSession = supabaseClient.auth.currentSession;
    if (initialSession != null && initialSession.user != null) {
      // Si une session existe, on peut essayer de charger le profil immédiatement
      // ou au moins mettre l'utilisateur supabase.
      // L'initialisation asynchrone ci-dessous s'occupera du reste.
      _fetchUserProfile(initialSession.user.id); 
      return AuthStateData(supabaseUser: initialSession.user, isLoading: true);
    }
    return AuthStateData(isLoading: true); 
  }

  Future<void> _initialize(supabase.SupabaseClient supabaseClient) async {
    _authStateSubscription = supabaseClient.auth.onAuthStateChange.listen((data) async {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;

      if (event == supabase.AuthChangeEvent.signedIn) {
        if (session != null && session.user != null) {
          state = state.copyWith(supabaseUser: session.user, isLoading: true, errorMessage: null);
          await _fetchUserProfile(session.user.id);
        } else {
          state = state.copyWith(isLoading: false, supabaseUser: null, userProfile: null, errorMessage: "Session invalide après connexion.");
        }
      } else if (event == supabase.AuthChangeEvent.signedOut || event == supabase.AuthChangeEvent.userDeleted) {
        state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false, errorMessage: null);
      } else if (event == supabase.AuthChangeEvent.userUpdated) {
        if (session != null && session.user != null) {
          final currentProfile = state.userProfile;
          state = state.copyWith(supabaseUser: session.user, isLoading: currentProfile == null || currentProfile.id != session.user.id);
          if (state.userProfile == null || state.userProfile!.id != session.user.id) {
             await _fetchUserProfile(session.user.id);
          }
        }
      } else if (event == supabase.AuthChangeEvent.tokenRefreshed) {
        if (session != null && session.user != null) {
          final currentProfile = state.userProfile;
          state = state.copyWith(supabaseUser: session.user);
          if (currentProfile == null || currentProfile.id != session.user.id) {
             await _fetchUserProfile(session.user.id);
          }
        } else {
           state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false);
        }
      } else if (event == supabase.AuthChangeEvent.initialSession) {
         // Ce cas peut être géré par l'état initial dans build() ou ici si nécessaire.
         // Pour l'instant, on s'assure que si la session est là, on fetch le profil.
         if (session != null && session.user != null) {
           if (state.supabaseUser?.id != session.user.id || state.userProfile == null) {
             state = state.copyWith(supabaseUser: session.user, isLoading: true, errorMessage: null);
             await _fetchUserProfile(session.user.id);
           } else {
             state = state.copyWith(isLoading: false); // Déjà chargé
           }
        } else {
          state = state.copyWith(isLoading: false, clearSupabaseUser: true, clearUserProfile: true);
        }
      }
      
      // Sécurité supplémentaire si une session devient null de manière inattendue
      if (session == null && 
          event != supabase.AuthChangeEvent.signedOut && 
          event != supabase.AuthChangeEvent.userDeleted && 
          event != supabase.AuthChangeEvent.initialSession) {
         state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false, errorMessage: "Session devenue null de manière inattendue pour l'événement: $event");
      }
    });

    ref.onDispose(() {
      _authStateSubscription?.cancel();
    });
  }

  Future<void> _fetchUserProfile(String userId) async {
    final supabaseClient = supabase.Supabase.instance.client;
    
    if (state.userProfile?.id == userId && !state.isLoading) {
       // Profil déjà chargé et pas en cours de chargement, rien à faire.
       // Si on est en isLoading, on continue pour potentiellement mettre à jour ou finir le chargement.
       if(!state.isLoading) return;
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null); // Mettre isLoading à true
    try {
      final response = await supabaseClient
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
    final supabaseClient = supabase.Supabase.instance.client;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await supabaseClient.auth.signOut();
      // onAuthStateChange s'occupera de mettre à jour l'état à signedOut
    } catch (e) {
      print('Erreur signOut: $e');
      state = state.copyWith(isLoading: false, errorMessage: "Erreur lors de la déconnexion: ${e.toString()}");
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> dataToUpdate) async {
    final supabaseClient = supabase.Supabase.instance.client;
    if (state.supabaseUser == null) {
      state = state.copyWith(errorMessage: "Utilisateur non connecté pour mettre à jour le profil.");
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await supabaseClient
          .from('profiles')
          .update(dataToUpdate)
          .eq('id', state.supabaseUser!.id);
      
      // Re-fetch le profil pour s'assurer que l'état local est à jour
      await _fetchUserProfile(state.supabaseUser!.id);
      return true;
    } catch (e) {
      print('Erreur updateUserProfile: $e');
      state = state.copyWith(isLoading: false, errorMessage: "Erreur lors de la mise à jour du profil: ${e.toString()}");
      return false;
    }
  }
  
  Future<void> refreshAuthStatusAndProfile() async {
    final supabaseClient = supabase.Supabase.instance.client;
    final currentSupabaseUser = supabaseClient.auth.currentUser;

    if (currentSupabaseUser != null) {
        // Si l'utilisateur Supabase a changé, ou si le profil n'est pas chargé ou ne correspond pas
        if (state.supabaseUser?.id != currentSupabaseUser.id || state.userProfile == null || state.userProfile?.id != currentSupabaseUser.id) {
           state = state.copyWith(supabaseUser: currentSupabaseUser, isLoading: true, errorMessage: null);
           await _fetchUserProfile(currentSupabaseUser.id);
        } else if (state.isLoading) {
            // Si déjà en cours de chargement pour le bon utilisateur, on peut simplement attendre ou juste s'assurer que isLoading devient false
            state = state.copyWith(isLoading: false); 
        }
    } else {
      // S'il n'y a pas d'utilisateur Supabase actuel
      if (state.supabaseUser != null || state.userProfile != null) {
        // S'il y avait un utilisateur/profil dans l'état, on nettoie
        state = state.copyWith(clearSupabaseUser: true, clearUserProfile: true, isLoading: false, errorMessage: null);
      } else if (state.isLoading) {
        // S'il n'y avait pas d'utilisateur et qu'on était en chargement, on arrête le chargement
        state = state.copyWith(isLoading: false);
      }
    }
  }

  bool get isLoggedIn => state.supabaseUser != null && state.userProfile != null;
  String? get userRole => state.userProfile?.role?.name;
}

/*
// Classe pont pour GoRouter refreshListenable - NECESSITE UNE REVISION POUR RIVERPOD GENERATOR
// L'intégration avec GoRouter doit être revue. Une approche possible est:
// dans votre configuration GoRouter:
// refreshListenable: ValueNotifier(ref.watch(authNotifierProvider.select((value) => value.supabaseUser))),
// ou écouter plusieurs changements si nécessaire.

// class AuthStateListenable extends ChangeNotifier {
//   final Ref ref; // Riverpod v2 passe souvent Ref directement
//   late final StreamSubscription _subscription;
//   AuthStateData? _previousState;

//   AuthStateListenable(this.ref) {
//     _previousState = ref.read(authNotifierProvider);
//     _subscription = ref.listen<AuthStateData>(authNotifierProvider, (previous, next) {
//       if (next.supabaseUser?.id != _previousState?.supabaseUser?.id || 
//           next.userProfile?.role != _previousState?.userProfile?.role) {
//         notifyListeners();
//       }
//       _previousState = next;
//     });
//   }

//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }
// }
*/
