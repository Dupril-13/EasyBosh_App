import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/models/user_model.dart';
import '../config/app_config.dart';

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

/// Provider pour l'état d'authentification
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Provider pour l'utilisateur courant
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AuthAuthenticated ? authState.user : null;
});

/// Notifier pour gérer l'authentification
class AuthNotifier extends StateNotifier<AuthState> {
  late final SupabaseClient _supabase;
  UserModel? _currentUser;

  AuthNotifier() : super(AuthLoading()) {
    _supabase = Supabase.instance.client;
    _initialize();
  }

  /// Initialisation de l'authentification
  Future<void> _initialize() async {
    try {
      // Écouter les changements d'état d'authentification
      _supabase.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data.session);
      });

      // Vérifier la session actuelle
      final session = _supabase.auth.currentSession;
      await _handleAuthStateChange(session);
    } catch (e) {
      state = AuthError('Erreur d\'initialisation: $e');
    }
  }

  /// Gestion des changements d'état d'authentification
  Future<void> _handleAuthStateChange(Session? session) async {
    if (session?.user == null) {
      _currentUser = null;
      state = AuthUnauthenticated();
      return;
    }

    try {
      // Récupérer les données utilisateur depuis la base
      final userData = await _supabase
          .from('users')
          .select()
          .eq('uid', session!.user.id)
          .maybeSingle();

      if (userData != null) {
        _currentUser = UserModel.fromMap(userData);
        state = AuthAuthenticated(_currentUser!);
      } else {
        // Utilisateur authentifié mais pas de données en base
        _currentUser = null;
        state = AuthError('Données utilisateur introuvables');
      }
    } catch (e) {
      state = AuthError('Erreur lors de la récupération des données: $e');
    }
  }

  /// Connexion avec email et mot de passe
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = AuthLoading();

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.session == null) {
        throw Exception('Échec de la connexion');
      }

      // L'état sera mis à jour via onAuthStateChange
    } on AuthException catch (e) {
      state = AuthError(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthError('Erreur de connexion: $e');
    }
  }

  /// Inscription avec email et mot de passe
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String role,
    String? niveauCode,
    String? serieCode,
  }) async {
    try {
      state = AuthLoading();

      // Validation des données d'inscription
      _validateSignUpData(email, password, nom, prenom, role, niveauCode, serieCode);

      // Créer le compte d'authentification
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('Échec de la création du compte');
      }

      // Créer l'enregistrement utilisateur
      final userModel = UserModel(
        uid: response.user!.id,
        email: email.trim(),
        role: role,
        nom: nom.trim(),
        prenom: prenom.trim(),
        niveauCode: niveauCode,
        serieCode: serieCode,
        emailVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabase.from('users').insert(userModel.toInsertMap());

      // L'état sera mis à jour via onAuthStateChange
    } on AuthException catch (e) {
      state = AuthError(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthError('Erreur d\'inscription: $e');
    }
  }

  /// Connexion avec Google
  Future<void> signInWithGoogle() async {
    try {
      state = AuthLoading();

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );

      // Pour OAuth, la redirection est gérée par le navigateur
      // L'état sera mis à jour via onAuthStateChange
    } on AuthException catch (e) {
      state = AuthError(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthError('Erreur de connexion Google: $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      state = AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Erreur de déconnexion: $e');
    }
  }

  /// Mise à jour du profil utilisateur
  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      if (_currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final updatedData = updatedUser.copyWith(
        updatedAt: DateTime.now(),
      );

      await _supabase
          .from('users')
          .update(updatedData.toMap())
          .eq('uid', _currentUser!.uid);

      _currentUser = updatedData;
      state = AuthAuthenticated(_currentUser!);
    } catch (e) {
      state = AuthError('Erreur de mise à jour: $e');
    }
  }

  /// Renvoyer l'email de vérification
  Future<void> resendEmailVerification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      await _supabase.auth.resend(
        email: user!.email!,
        type: OtpType.signup,
      );
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi: $e');
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Erreur de réinitialisation: $e');
    }
  }

  /// Changer le mot de passe
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Vérifier l'ancien mot de passe en se reconnectant
      await _supabase.auth.signInWithPassword(
        email: user!.email!,
        password: currentPassword,
      );

      // Changer le mot de passe
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Erreur de changement de mot de passe: $e');
    }
  }

  /// Supprimer le compte
  Future<void> deleteAccount() async {
    try {
      if (_currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Supprimer les données utilisateur
      await _supabase
          .from('users')
          .delete()
          .eq('uid', _currentUser!.uid);

      // Supprimer le compte d'authentification
      await _supabase.auth.admin.deleteUser(_currentUser!.uid);

      _currentUser = null;
      state = AuthUnauthenticated();
    } catch (e) {
      throw Exception('Erreur de suppression du compte: $e');
    }
  }

  /// Validation des données d'inscription
  void _validateSignUpData(
    String email,
    String password,
    String nom,
    String prenom,
    String role,
    String? niveauCode,
    String? serieCode,
  ) {
    // Validation email
    if (!RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email)) {
      throw Exception(AppConfig.invalidEmailMessage);
    }

    // Validation mot de passe
    if (password.length < AppConfig.minPasswordLength) {
      throw Exception(AppConfig.passwordTooShortMessage);
    }

    // Validation nom et prénom
    if (nom.trim().isEmpty || prenom.trim().isEmpty) {
      throw Exception('Le nom et le prénom sont obligatoires');
    }

    // Validation rôle
    if (!AppConfig.roles.contains(role)) {
      throw Exception('Rôle invalide');
    }

    // Validation niveau/série pour les étudiants
    if (role == 'etudiant') {
      if (niveauCode == null || (niveauCode != '3eme' && serieCode == null)) {
        throw Exception('Le niveau et la série sont obligatoires pour les étudiants');
      }

      // À ce stade, niveauCode et serieCode ne peuvent pas être null grâce aux vérifications précédentes
      // On peut donc les passer directement à isValidCombination
      if (!AppConfig.isValidCombination(niveauCode!, serieCode!)) {
        throw Exception('Combinaison niveau/série invalide');
      }
    }
  }

  /// Convertir les erreurs Supabase en messages lisibles
  String _getAuthErrorMessage(AuthException error) {
    switch (error.message) {
      case 'Invalid login credentials':
        return 'Email ou mot de passe incorrect';
      case 'User already registered':
        return 'Un compte existe déjà avec cet email';
      case 'Email not confirmed':
        return 'Veuillez vérifier votre email avant de vous connecter';
      case 'Invalid email':
        return 'Adresse email invalide';
      case 'Password should be at least 6 characters':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'Signup requires a valid password':
        return 'Mot de passe requis pour l\'inscription';
      case 'User not found':
        return 'Aucun compte trouvé avec cet email';
      case 'Too many requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      default:
        return error.message;
    }
  }

  /// Getters utiles
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isEtudiant => _currentUser?.isEtudiant ?? false;
  bool get isEnseignant => _currentUser?.isEnseignant ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isStaff => _currentUser?.isStaff ?? false;
}