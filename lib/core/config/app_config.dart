import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration centrale de l'application
class AppConfig {
  // Informations de l'application
  static const String appName = 'EasyBosh';
  static const String appVersion = '2.0.0';
  static const String appDescription = 'Application éducative pour les élèves en classe d\'examen du Cameroun';

  // Configuration Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Configuration environnement
  static String get environment => dotenv.env['APP_ENVIRONMENT'] ?? 'development';
  static bool get isDebugMode => environment == 'development';
  static bool get isProduction => environment == 'production';

  // Features flags
  static bool get enableBiometricAuth =>
      dotenv.env['ENABLE_BIOMETRIC_AUTH']?.toLowerCase() == 'true';
  static bool get enableOfflineMode =>
      dotenv.env['ENABLE_OFFLINE_MODE']?.toLowerCase() == 'true';
  static bool get enablePushNotifications =>
      dotenv.env['ENABLE_PUSH_NOTIFICATIONS']?.toLowerCase() == 'true';
  static bool get enableAnalytics =>
      dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true';

  // OAuth Configuration
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static String get appleClientId => dotenv.env['APPLE_CLIENT_ID'] ?? '';

  // API Keys
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';

  // Base de données
  static int get dbTimeout => int.tryParse(dotenv.env['DB_TIMEOUT'] ?? '30000') ?? 30000;
  static int get maxRetries => int.tryParse(dotenv.env['MAX_RETRIES'] ?? '3') ?? 3;

  // Cache
  static int get cacheDuration => int.tryParse(dotenv.env['CACHE_DURATION'] ?? '3600') ?? 3600;
  static String get maxCacheSize => dotenv.env['MAX_CACHE_SIZE'] ?? '50MB';

  // URLs et endpoints
  static const String websiteUrl = 'https://easybosh.com';
  static const String supportEmail = 'support@easybosh.com';
  static const String privacyPolicyUrl = 'https://easybosh.com/privacy';
  static const String termsOfServiceUrl = 'https://easybosh.com/terms';

  // Niveaux scolaires
  static const List<String> niveaux = ['3eme', '1ere', 'tle'];
  static const Map<String, String> niveauxLabels = {
    '3eme': 'Troisième',
    '1ere': 'Première',
    'tle': 'Terminale',
  };

  // Séries scolaires
  static const List<String> series = ['A', 'A4Esp', 'A4All', 'A4ITA', 'A4CHI', 'C', 'D', 'TI'];
  static const Map<String, String> seriesLabels = {
    'A': 'Série A - Littéraire',
    'A4Esp': 'Série A4 - Espagnol',
    'A4All': 'Série A4 - Allemand',
    'A4ITA': 'Série A4 - Italien',
    'A4CHI': 'Série A4 - Chinois',
    'C': 'Série C - Math-Physique',
    'D': 'Série D - Math-SVT',
    'TI': 'Série TI - Technologie Industrielle',
  };

  // Combinaisons niveau/série valides
  static const Map<String, List<String>> combinaisonsValides = {
    '3eme': ['A'],
    '1ere': ['A', 'A4Esp', 'A4All', 'A4ITA', 'A4CHI', 'C', 'D', 'TI'],
    'tle': ['A', 'A4Esp', 'A4All', 'A4ITA', 'A4CHI', 'C', 'D', 'TI'],
  };

  // Rôles utilisateur
  static const List<String> roles = ['etudiant', 'enseignant', 'admin'];
  static const Map<String, String> rolesLabels = {
    'etudiant': 'Étudiant',
    'enseignant': 'Enseignant',
    'admin': 'Administrateur',
  };

  // Limites et constantes
  static const int maxPasswordLength = 128;
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  static const int maxEmailLength = 255;
  static const int maxDescriptionLength = 1000;

  // Délais et timeouts
  static const int emailVerificationTimeout = 60; // secondes
  static const int sessionTimeout = 3600; // secondes (1 heure)
  static const int requestTimeout = 30000; // millisecondes (30 secondes)

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Animations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  // Messages d'erreur
  static const String networkErrorMessage = 'Erreur de connexion. Vérifiez votre connexion internet.';
  static const String serverErrorMessage = 'Erreur du serveur. Veuillez réessayer plus tard.';
  static const String unknownErrorMessage = 'Une erreur inattendue s\'est produite.';

  // Messages de succès
  static const String accountCreatedMessage = 'Compte créé avec succès ! Vérifiez votre email.';
  static const String loginSuccessMessage = 'Connexion réussie !';
  static const String profileUpdatedMessage = 'Profil mis à jour avec succès !';
  static const String emailVerifiedMessage = 'Email vérifié avec succès !';

  // Validation messages
  static const String requiredFieldMessage = 'Ce champ est obligatoire.';
  static const String invalidEmailMessage = 'Veuillez entrer un email valide.';
  static const String passwordTooShortMessage = 'Le mot de passe doit contenir au moins 6 caractères.';
  static const String passwordsDoNotMatchMessage = 'Les mots de passe ne correspondent pas.';

  /// Valide une combinaison niveau/série
  static bool isValidCombination(String niveau, String serie) {
    return combinaisonsValides[niveau]?.contains(serie) ?? false;
  }

  /// Retourne les séries disponibles pour un niveau
  static List<String> getSeriesForNiveau(String niveau) {
    return combinaisonsValides[niveau] ?? [];
  }

  /// Retourne le label d'un niveau
  static String getNiveauLabel(String niveau) {
    return niveauxLabels[niveau] ?? niveau;
  }

  /// Retourne le label d'une série
  static String getSerieLabel(String serie) {
    return seriesLabels[serie] ?? serie;
  }

  /// Retourne le label d'un rôle
  static String getRoleLabel(String role) {
    return rolesLabels[role] ?? role;
  }

  /// Vérifie si la configuration est valide
  static bool get isConfigValid {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}