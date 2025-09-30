import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
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
      _supabase.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data.session);
      });
      final session = _supabase.auth.currentSession;
      await _handleAuthStateChange(session);
    } catch (e) {
      state = AuthError('Erreur d\'initialisation: $e');
    }
  }

  Future<void> _handleAuthStateChange(Session? session) async {
    print("[AUTH_PROVIDER] _handleAuthStateChange: Received session is ${session == null ? 'NULL' : 'NOT NULL (User ID: ${session.user?.id})'}");

    if (session == null || session.user == null) { 
      _currentUser = null;
      state = AuthUnauthenticated();
      print("[AUTH_PROVIDER] _handleAuthStateChange: Setting state to AuthUnauthenticated");
      return;
    }
    
    final userId = session.user!.id;
    final userEmail = session.user!.email ?? 'fallback@example.com'; // Fallback, though email should always exist for a logged-in user
    final userEmailVerified = session.user!.emailConfirmedAt != null;

    try {
      print("[AUTH_PROVIDER] _handleAuthStateChange: Fetching user data from 'profiles' for ID $userId...");
      final userData = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userData != null) {
        print("[AUTH_PROVIDER] _handleAuthStateChange: User data FOUND from 'profiles' for ID $userId. Data: $userData");
        _currentUser = UserModel.fromMap(
          userData, 
          emailFromSession: userEmail, 
          emailVerifiedFromSession: userEmailVerified
        );
        print("[AUTH_PROVIDER] _handleAuthStateChange: UserModel created. Role is: ${_currentUser?.role}"); // DEBUG LOG ADDED
        state = AuthAuthenticated(_currentUser!);
        print("[AUTH_PROVIDER] _handleAuthStateChange: Setting state to AuthAuthenticated for ${_currentUser!.email}");
      } else {
        print("[AUTH_PROVIDER] _handleAuthStateChange: User data NOT FOUND in 'profiles' for ID $userId.");
        _currentUser = null;
        state = AuthError('Données utilisateur introuvables dans \'profiles\' pour ID $userId');
        print("[AUTH_PROVIDER] _handleAuthStateChange: Setting state to AuthError (Données utilisateur introuvables dans \'profiles\')");
      }
    } catch (e, stackTrace) {
      print("[AUTH_PROVIDER] _handleAuthStateChange: EXCEPTION while processing user data for ID $userId: $e");
      print(stackTrace);
      state = AuthError('Erreur lors du traitement des données de \'profiles\' pour ID $userId: $e');
      print("[AUTH_PROVIDER] _handleAuthStateChange: Setting state to AuthError (Exception on processing)");
    }
  }

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
    } on AuthException catch (e) {
      state = AuthError(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthError('Erreur de connexion: $e');
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
    try {
      state = AuthLoading();
      _validateSignUpData(email, password, nom, prenom, role, niveauCode, serieCode);

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('Échec de la création du compte d\'authentification Supabase.');
      }
      if (response.user!.email == null) {
        throw Exception('Email manquant dans la réponse d\'authentification Supabase après inscription.');
      }

      final userModel = UserModel(
        uid: response.user!.id,
        email: response.user!.email!, // Garanti non null par la vérification précédente
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
      
      await _supabase.from('profiles').insert(userModel.toMapForProfiles());

    } on AuthException catch (e) {
      state = AuthError(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthError('Erreur d\'inscription: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = AuthLoading();
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
    } on AuthException catch (e) {
      state = AuthError(_getAuthErrorMessage(e));
    } catch (e) {
      state = AuthError('Erreur de connexion Google: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      state = AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Erreur de déconnexion: $e');
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      if (_currentUser == null) {
        throw Exception('Aucun utilisateur connecté pour la mise à jour du profil.');
      }

      final userForDb = updatedUser.copyWith(
        updatedAt: DateTime.now(),
        // Assurez-vous que l'email n'est pas accidentellement modifié ici s'il ne doit pas l'être
        // email: _currentUser!.email, // Conserver l'email original si non modifiable
      );
      
      Map<String, dynamic> profileDataToUpdate = userForDb.toMapForProfiles();
      // Retirer les champs qui ne doivent pas être envoyés ou qui sont gérés par la DB lors d'un update simple
      profileDataToUpdate.remove('id'); // L'ID est utilisé dans .eq() et ne doit pas être dans le payload de mise à jour
      profileDataToUpdate.remove('created_at'); // Généralement non modifié
      // Si l'email ne peut pas être modifié via cette méthode, retirez-le aussi.
      // La map `toMapForProfiles` ne contient déjà pas l'email.

      // Permettre la mise à null explicite de certains champs si nécessaire
      // Par exemple, si on veut pouvoir vider le numéro de téléphone :
      if (updatedUser.telephone == null && _currentUser!.telephone != null) {
        profileDataToUpdate['phone_number'] = null;
      }
      if (updatedUser.niveauCode == null && _currentUser!.niveauCode != null) {
        profileDataToUpdate['student_level_code'] = null;
      }
       if (updatedUser.serieCode == null && _currentUser!.serieCode != null) {
        profileDataToUpdate['student_serie_code'] = null;
      }
       if (updatedUser.dateNaissance == null && _currentUser!.dateNaissance != null) {
        profileDataToUpdate['date_of_birth'] = null;
      }

      await _supabase
          .from('profiles')
          .update(profileDataToUpdate)
          .eq('id', _currentUser!.uid); 

      _currentUser = userForDb; 
      state = AuthAuthenticated(_currentUser!);
    } catch (e) {
      state = AuthError('Erreur de mise à jour du profil: $e');
    }
  }

  Future<void> resendEmailVerification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        throw Exception('Aucun utilisateur connecté pour renvoyer l\'email de vérification.');
      }
      await _supabase.auth.resend(email: user!.email!, type: OtpType.signup);
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Erreur lors du renvoi de l\'email de vérification: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Erreur de réinitialisation du mot de passe: $e');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        throw Exception('Aucun utilisateur connecté pour changer le mot de passe.');
      }
      await _supabase.auth.signInWithPassword(email: user!.email!, password: currentPassword);
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Erreur de changement de mot de passe: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (_currentUser == null) {
        throw Exception('Aucun utilisateur connecté pour supprimer le compte.');
      }
      await _supabase.from('profiles').delete().eq('id', _currentUser!.uid); 
      // Considérer la suppression de auth.user via une fonction Edge si nécessaire
      // await _supabase.auth.admin.deleteUser(_currentUser!.uid); 
      _currentUser = null;
      state = AuthUnauthenticated();
    } catch (e) {
      throw Exception('Erreur de suppression du compte: $e');
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

  String _getAuthErrorMessage(AuthException error) {
    // ... (inchangé)
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

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isEtudiant => _currentUser?.isEtudiant ?? false;
  bool get isEnseignant => _currentUser?.isEnseignant ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isStaff => _currentUser?.isStaff ?? false;
}
