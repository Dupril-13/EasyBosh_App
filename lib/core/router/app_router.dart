import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pages d'authentification (vraies pages)
import '../../pages/auth/get_started_page.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/signup_page.dart';
import '../../pages/auth/verification_page.dart';

// Pages principales
import '../../pages/student/cours_page.dart';
import '../../pages/student/epreuves_page.dart';
import '../../pages/student/quiz_page.dart';
import '../../pages/student/statistiques_page.dart';
import '../../pages/student/settings_page.dart';
import '../../pages/student/profile_page.dart';

// Pages des catégories d'épreuves
import '../../pages/student/epreuves/anciens_sujets_page.dart';
import '../../pages/student/epreuves/sujets_colleges_page.dart';
import '../../pages/student/epreuves/examens_blancs_page.dart';
import '../../pages/student/epreuves/epreuves_exclusives_page.dart';
import '../../pages/student/epreuves/epreuve_details_page.dart';
import '../../pages/student/epreuves/epreuve_composition_page.dart';
import '../../pages/student/epreuves/epreuve_correction_page.dart'; // Ajout de l'import

/// Provider pour le router principal
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/cours',
    redirect: (context, state) {
      final isAuthenticated = true;  // Forcer l'authentification
      final isOnboarding = state.matchedLocation == '/get-started';
      final isAuth = state.matchedLocation.startsWith('/auth');

      // Si connecté et sur onboarding/auth -> cours
      if (isAuthenticated && (isOnboarding || isAuth)) {
        return '/cours';
      }

      return null; // Pas de redirection
    },
    routes: [
      // Onboarding
      GoRoute(
        path: '/get-started',
        name: 'getStarted',
        builder: (context, state) => const GetStartedPage(),
      ),

      // Authentification
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/signup',
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/auth/verification',
        name: 'verification',
        builder: (context, state) => const VerificationPage(),
      ),

      // Pages principales
      GoRoute(
        path: '/cours',
        name: 'cours',
        builder: (context, state) => const CoursPage(),
      ),
      GoRoute(
        path: '/epreuves',
        name: 'epreuves',
        builder: (context, state) => const EpreuvesPage(),
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) => const QuizPage(),
      ),
      GoRoute(
        path: '/statistiques',
        name: 'statistiques',
        builder: (context, state) => const StatistiquesPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),

      // Pages des catégories d'épreuves
      GoRoute(
        path: '/anciens_sujets',
        name: 'anciensSujets',
        builder: (context, state) => const AnciensSujetsPage(),
      ),
      GoRoute(
        path: '/colleges_connus',
        name: 'collegesConnus',
        builder: (context, state) => const SujetsCollegesPage(),
      ),
      GoRoute(
        path: '/examens_blancs',
        name: 'examensBlancs',
        builder: (context, state) => const ExamensBlancsPage(),
      ),
      GoRoute(
        path: '/epreuves_exclusives',
        name: 'epreuvesExclusives',
        builder: (context, state) => const EpreuvesExclusivesPage(),
      ),

      // Page de détails d'une épreuve
      GoRoute(
        path: '/epreuve_details',
        name: 'epreuveDetails',
        builder: (context, state) {
          final epreuveDetails = state.extra as Map<String, String>? ?? const {};
          return EpreuveDetailsPage(epreuveDetails: epreuveDetails);
        },
      ),

      // Page de composition d'une épreuve
      GoRoute(
        path: '/epreuve_composition',
        name: 'epreuveComposition',
        builder: (context, state) {
          final epreuveDetails = state.extra as Map<String, String>? ?? const {};
          return EpreuveCompositionPage(epreuveDetails: epreuveDetails);
        },
      ),

      // Page de correction d'une épreuve
      GoRoute(
        path: '/epreuve_correction',
        name: 'epreuveCorrection',
        builder: (context, state) {
          final epreuveDetails = state.extra as Map<String, String>? ?? const {};
          return EpreuveCorrectionPage(epreuveDetails: epreuveDetails);
        },
      ),
    ],
    errorBuilder: (context, state) => const _ErrorPage(),
  );
});

/// Page d'erreur
class _ErrorPage extends StatelessWidget {
  const _ErrorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page non trouvée'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'La page que vous recherchez n\'existe pas.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
