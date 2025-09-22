import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pages d'authentification (vraies pages)
import '../../features/onboarding/presentation/pages/get_started_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verification_page.dart';

// Pages principales
import '../../features/cours/presentation/pages/cours_page.dart';
import '../../features/epreuves/presentation/pages/epreuves_page.dart';
import '../../features/quiz/presentation/pages/quiz_page.dart';
import '../../features/statistiques/presentation/pages/statistiques_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

/// Provider pour le router principal
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/get-started',
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isAuthenticated = user != null;
      final isOnboarding = state.matchedLocation == '/get-started';
      final isAuth = state.matchedLocation.startsWith('/auth');

      // Si pas connecté et pas sur onboarding/auth -> onboarding
      if (!isAuthenticated && !isOnboarding && !isAuth) {
        return '/get-started';
      }

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