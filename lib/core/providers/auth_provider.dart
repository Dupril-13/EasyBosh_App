import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ajout pour Provider
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase; // Alias pour éviter conflit avec UserModel
import '../../models/user_model.dart';
import '../config/app_config.dart';

part 'auth_provider.g.dart';

/// État d'authentification
sealed class AuthState {}

class AuthLoading extends AuthState {}
class AuthUnauthenticated extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

/// Notifier pour gérer l'authentification
@Riverpod(keepAlive: true)
class Auth extends _$Auth { // Changé de AuthNotifier à Auth pour la convention, étend _$Auth
  late final supabase.SupabaseClient _supabase;
  UserModel? _currentUser;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  @override
  AuthState build() {
    _supabase = supabase.Supabase.instance.client;
    _initialize(); // Lance l'écouteur
    
    final currentSupabaseSession = _supabase.auth.currentSession;
    if (currentSupabaseSession != null && currentSupabaseSession.user != null) {
      return AuthLoading(); 
    }
    return AuthUnauthenticated(); 
  }

  Future<void> _initialize() async {
    await _authStateSubscription?.cancel();
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      _handleAuthStateChange(data.session);
    });
    ref.onDispose(() {
      _authStateSubscription?.cancel();
    });
  }

  Future<void> _handleAuthStateChange(supabase.Session? session) async {
    if (session == null || session.user == null) { 
      _currentUser = null;
      state = AuthUnauthenticated();
      return;
    }
    
    final userId = session.user!.id;
    final userEmail = session.user!.email ?? 'fallback@example.com'; 
    final userEmailVerified = session.user!.emailConfirmedAt != null;

    try {
      final userData = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userData != null) {
        _currentUser = UserModel.fromMap(
          userData, 
          emailFromSession: userEmail, 
          emailVerifiedFromSession: userEmailVerified
        );
        state = AuthAuthenticated(_currentUser!);
      } else {
        _currentUser = null;
        state = AuthError('Données utilisateur (profil) introuvables pour ID $userId. L\'utilisateur est authentifié mais le profil est manquant.');
      }
    } catch (e, stackTrace) {
      print("[AUTH_PROVIDER] _handleAuthStateChange: EXCEPTION while processing user data for ID $userId: $e");
      print(stackTrace);
      state = AuthError('Erreur lors du traitement des données de profil pour ID $userId: $e');
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session == null) {
         throw Exception('Échec de la connexion, session non établie.');
      }
    } on supabase.AuthException catch (e) {
      state = AuthError(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthError('Erreur de connexion: ${e.toString()}');
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String role,
    String? niveauCode,
    String? serieCode,
  }) async {
    state = AuthLoading();
    try {
      _validateSignUpData(email, password, nom, prenom, role, niveauCode, serieCode);
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (response.user == null || response.user!.email == null) {
        throw Exception('Échec de la création du compte d\'authentification Supabase.');
      }
      final userModelForProfile = UserModel(
        uid: response.user!.id,
        email: response.user!.email!,
        role: role,
        nom: nom.trim(),
        prenom: prenom.trim(),
        niveauCode: niveauCode,
        serieCode: serieCode,
        emailVerified: response.user!.emailConfirmedAt != null, 
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        actif: true, 
      );
      await _supabase.from('profiles').insert(userModelForProfile.toMapForProfiles());
    } on supabase.AuthException catch (e) {
      state = AuthError(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthError('Erreur d\'inscription: ${e.toString()}');
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthLoading();
    try {
      await _supabase.auth.signInWithOAuth(supabase.OAuthProvider.google);
    } on supabase.AuthException catch (e) {
      state = AuthError(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthError('Erreur de connexion Google: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      state = AuthError('Erreur de déconnexion: ${e.toString()}');
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    final authenticatedUserId = _supabase.auth.currentUser?.id;
    if (authenticatedUserId == null || authenticatedUserId != updatedUser.uid) {
       state = AuthError('Action non autorisée pour la mise à jour du profil.');
       return;
    }
    state = AuthLoading();
    try {
      final userForDb = updatedUser.copyWith(updatedAt: DateTime.now());
      Map<String, dynamic> profileDataToUpdate = userForDb.toMapForProfiles();
      profileDataToUpdate.remove('id'); 
      profileDataToUpdate.remove('created_at');
      profileDataToUpdate.remove('email');
      await _supabase.from('profiles').update(profileDataToUpdate).eq('id', authenticatedUserId); 
      await _handleAuthStateChange(_supabase.auth.currentSession); 
      if (state is! AuthAuthenticated && state is! AuthError) {
        state = AuthError('Mise à jour du profil effectuée mais impossible de confirmer le nouvel état.');
      }
    } catch (e) {
      state = AuthError('Erreur de mise à jour du profil: ${e.toString()}');
      await _handleAuthStateChange(_supabase.auth.currentSession);
    }
  }

  Future<void> resendEmailVerification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        throw Exception('Aucun utilisateur connecté ou email manquant.');
      }
      await _supabase.auth.resend(email: user!.email!, type: supabase.OtpType.signup);
    } on supabase.AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Erreur lors du renvoi de l\'email de vérification: ${e.toString()}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on supabase.AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Erreur de réinitialisation du mot de passe: ${e.toString()}');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = AuthLoading();
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        throw Exception('Aucun utilisateur connecté.');
      }
      await _supabase.auth.signInWithPassword(email: user!.email!, password: currentPassword);
      await _supabase.auth.updateUser(supabase.UserAttributes(password: newPassword));
      // Rafraîchir l'état ou informer du succès
    } on supabase.AuthException catch (e) {
       state = AuthError(_getAuthErrorMessage(e));
    } catch (e) {
       state = AuthError('Erreur de changement de mot de passe: ${e.toString()}');
    }
  }

  Future<void> deleteAccount() async {
    state = AuthLoading();
    try {
      final authenticatedUserId = _supabase.auth.currentUser?.id;
      if (authenticatedUserId == null) {
        throw Exception('Aucun utilisateur connecté.');
      }
      await _supabase.from('profiles').delete().eq('id', authenticatedUserId); 
      await _supabase.auth.signOut();
      _currentUser = null; 
    } catch (e) {
      await _handleAuthStateChange(_supabase.auth.currentSession);
      if (state is! AuthError) {
          state = AuthError('Erreur de suppression du compte: ${e.toString()}');
      }
    }
  }

  void _validateSignUpData(
    String email,
    String password,
    String nom,
    String prenom,
    String role,
    String? niveauCode,
    String? serieCode,
  ) {
    if (!RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email)) {
      throw Exception(AppConfig.invalidEmailMessage);
    }
    if (password.length < AppConfig.minPasswordLength) {
      throw Exception(AppConfig.passwordTooShortMessage);
    }
    if (nom.trim().isEmpty || prenom.trim().isEmpty) {
      throw Exception('Le nom et le prénom sont obligatoires.');
    }
    if (!AppConfig.roles.contains(role)) {
      throw Exception('Rôle invalide: $role');
    }
    if (role == 'etudiant') {
      if (niveauCode == null || niveauCode.trim().isEmpty) {
        throw Exception('Le niveau est obligatoire pour les étudiants.');
      }
      String effectiveSerieCode = serieCode?.trim() ?? "";
      if (niveauCode != '3eme' && effectiveSerieCode.isEmpty){
         throw Exception('La série est obligatoire pour le niveau $niveauCode.');
      }
      if (!AppConfig.isValidCombination(niveauCode.trim(), effectiveSerieCode)) {
        throw Exception('Combinaison niveau/série invalide: ${niveauCode.trim()} / $effectiveSerieCode');
      }
    }
  }

  String _getAuthErrorMessage(supabase.AuthException error) {
    if (error.message.contains('Invalid login credentials')) return 'Email ou mot de passe incorrect.';
    if (error.message.contains('User already registered')) return 'Un compte existe déjà avec cet email.';
    if (error.message.contains('Email not confirmed')) return 'Veuillez vérifier votre email avant de vous connecter.';
    if (error.message.contains('Unable to validate email address: invalid format')) return AppConfig.invalidEmailMessage;
    if (error.message.contains('Password should be at least 6 characters')) return AppConfig.passwordTooShortMessage;
    if (error.message.contains('Signup requires a valid password')) return 'Mot de passe requis pour l\'inscription.';
    return error.message;
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => state is AuthAuthenticated;
  bool get isEtudiant => (state as AuthAuthenticated?)?.user.isEtudiant ?? false;
  bool get isEnseignant => (state as AuthAuthenticated?)?.user.isEnseignant ?? false;
  bool get isAdmin => (state as AuthAuthenticated?)?.user.isAdmin ?? false;
  bool get isStaff => (state as AuthAuthenticated?)?.user.isStaff ?? false;
}

/// Provider pour l'utilisateur courant (UserModel)
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider); // authProvider est auto-généré
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

// L'ancien authStateProvider est supprimé car le générateur va créer authProvider.
