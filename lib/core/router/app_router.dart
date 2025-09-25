import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pages d'authentification
import '../../pages/auth/get_started_page.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/signup_page.dart';
import '../../pages/auth/verification_page.dart';

// Pages Étudiant
import '../../pages/student/cours_page.dart';
import '../../pages/student/epreuves_page.dart';
import '../../pages/student/quiz_page.dart';
import '../../pages/student/statistiques_page.dart';
import '../../pages/student/settings_page.dart';
import '../../pages/student/help_page.dart';
import '../../pages/notifications/notifications_page.dart';
import '../../pages/student/epreuves/anciens_sujets_page.dart';
import '../../pages/student/epreuves/sujets_colleges_page.dart';
import '../../pages/student/epreuves/examens_blancs_page.dart';
import '../../pages/student/epreuves/epreuves_exclusives_page.dart';
import '../../pages/student/epreuves/epreuve_details_page.dart';
import '../../pages/student/epreuves/epreuve_composition_page.dart';
import '../../pages/student/epreuves/epreuve_correction_page.dart';
import '../../pages/student/quiz/quiz_matiere_selection_page.dart';
import '../../pages/student/quiz/quiz_list_par_matiere_page.dart';
import '../../pages/student/quiz/quiz_play_page.dart';
import '../../pages/student/quiz/quiz_express_placeholder_page.dart';
import '../../pages/student/quiz/quiz_bilan_niveau_placeholder_page.dart';
import '../../pages/student/quiz/quiz_challenge_list_page.dart';
import '../../pages/student/quiz/quiz_results_page.dart';
import '../../pages/chatbot/chatbot_page.dart';

// Pages Staff (Login et Dashboards placeholders)
import '../../pages/staff/staff_login_page.dart';
import '../../pages/staff/admin/admin_dashboard_page.dart';
import '../../pages/staff/admin/manage_teachers_page.dart';
import '../../pages/staff/admin/manage_admins_page.dart';
import '../../pages/staff/admin/activity_logs_page.dart';
import '../../pages/staff/admin/admin_profile_page.dart';
import '../../pages/staff/teacher/teacher_dashboard_page.dart';
import '../../pages/staff/teacher/manage_courses_page.dart';
import '../../pages/staff/teacher/manage_exams_page.dart';
import '../../pages/staff/teacher/manage_quizzes_page.dart';
import '../../pages/staff/teacher/teacher_analytics_page.dart';
import '../../pages/staff/teacher/teacher_profile_page.dart';

// Pages Shell pour Staff
import '../../pages/staff/admin/admin_shell_page.dart';
import '../../pages/staff/teacher/teacher_shell_page.dart';


final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _adminShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'adminShell');
final GlobalKey<NavigatorState> _teacherShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'teacherShell');


final appRouterProvider = Provider<GoRouter>((ref) {
  // TODO: Auth logic with Riverpod for redirection
  // final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/staff-login', // Modifié pour démarrer sur la page de connexion staff
    debugLogDiagnostics: true, 

    redirect: (BuildContext context, GoRouterState state) {
      // Pour l'instant, aucune redirection globale. 
      // Nous pourrons ajouter ici la logique pour rediriger un staff déjà connecté vers son dashboard.
      return null; 
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/get-started',
        name: 'getStarted',
        builder: (context, state) => const GetStartedPage(),
      ),
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
        builder: (context, state) {
          String? emailFromExtra;
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            emailFromExtra = (state.extra as Map<String, dynamic>)['email'] as String?;
          }
          return VerificationPage(email: emailFromExtra);
        },
      ),
      GoRoute(
        path: '/staff-login',
        name: 'staffLogin',
        builder: (context, state) => const StaffLoginPage(),
      ),

      // --- Admin Section Shell ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShellPage(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _adminShellNavigatorKey, 
            routes: <RouteBase>[
              GoRoute(
                path: '/admin/dashboard',
                name: 'adminDashboard',
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/admin/manage-teachers',
                name: 'adminManageTeachers',
                builder: (BuildContext context, GoRouterState state) => const ManageTeachersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/admin/manage-admins',
                name: 'adminManageAdmins',
                builder: (BuildContext context, GoRouterState state) => const ManageAdminsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/admin/activity-logs',
                name: 'adminActivityLogs',
                builder: (BuildContext context, GoRouterState state) => const ActivityLogsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/admin/profile',
                name: 'adminProfile',
                builder: (BuildContext context, GoRouterState state) => const AdminProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // --- Teacher Section Shell ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return TeacherShellPage(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _teacherShellNavigatorKey, 
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/dashboard',
                name: 'teacherDashboard',
                builder: (BuildContext context, GoRouterState state) => const TeacherDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/manage-courses',
                name: 'teacherManageCourses',
                builder: (BuildContext context, GoRouterState state) => const ManageCoursesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/manage-exams',
                name: 'teacherManageExams',
                builder: (BuildContext context, GoRouterState state) => const ManageExamsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/manage-quizzes',
                name: 'teacherManageQuizzes',
                builder: (BuildContext context, GoRouterState state) => const ManageQuizzesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/analytics',
                name: 'teacherAnalytics',
                builder: (BuildContext context, GoRouterState state) => const TeacherAnalyticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/profile',
                name: 'teacherProfile',
                builder: (BuildContext context, GoRouterState state) => const TeacherProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // --- Routes Étudiant --- 
      GoRoute(path: '/cours', name: 'cours', builder: (context, state) => const CoursPage()),
      GoRoute(path: '/epreuves', name: 'epreuves', builder: (context, state) => const EpreuvesPage()),
      GoRoute(path: '/quiz',name: 'quiz',builder: (context, state) => const QuizPage()),
      GoRoute(path: '/statistiques',name: 'statistiques',builder: (context, state) => const StatistiquesPage()),
      GoRoute(path: '/settings',name: 'settings',builder: (context, state) => const SettingsPage()),
      GoRoute(path: '/help',name: 'help',builder: (context, state) => const HelpPage()),
      GoRoute(path: '/notifications',name: 'notifications',builder: (context, state) => const NotificationsPage()),
      GoRoute(path: '/anciens_sujets', name: 'anciensSujets', builder: (context, state) => const AnciensSujetsPage()),
      GoRoute(path: '/colleges_connus', name: 'collegesConnus', builder: (context, state) => const SujetsCollegesPage()),
      GoRoute(path: '/examens_blancs', name: 'examensBlancs', builder: (context, state) => const ExamensBlancsPage()),
      GoRoute(path: '/epreuves_exclusives', name: 'epreuvesExclusives', builder: (context, state) => const EpreuvesExclusivesPage()),
      GoRoute(path: '/epreuve_details', name: 'epreuveDetails', builder: (context, state) {
        final epreuveDetails = state.extra as Map<String, String>? ?? const {};
        return EpreuveDetailsPage(epreuveDetails: epreuveDetails);
      }),
      GoRoute(path: '/epreuve_composition', name: 'epreuveComposition', builder: (context, state) {
        final epreuveDetails = state.extra as Map<String, String>? ?? const {};
        return EpreuveCompositionPage(epreuveDetails: epreuveDetails);
      }),
      GoRoute(path: '/epreuve_correction', name: 'epreuveCorrection', builder: (context, state) {
        final epreuveDetails = state.extra as Map<String, String>? ?? const {};
        return EpreuveCorrectionPage(epreuveDetails: epreuveDetails);
      }),
      GoRoute(path: '/quiz_par_matiere_selection', name: 'quizMatiereSelection', builder: (context, state) => const QuizMatiereSelectionPage()),
      GoRoute(path: '/quiz_list_par_matiere', name: 'quizListByMatiere', builder: (context, state) {
        final matiereNom = state.extra as String? ?? 'Inconnue';
        return QuizListByMatierePage(matiereNom: matiereNom);
      }),
      GoRoute(path: '/quiz_play', name: 'quizPlay', builder: (context, state) {
        final quizDetails = state.extra as Map<String, dynamic>? ?? const {};
        return QuizPlayPage(quizDetails: quizDetails);
      }),
      GoRoute(path: '/quiz_express_placeholder', name: 'quizExpressPlaceholder', builder: (context, state) => const QuizExpressPlaceholderPage()),
      GoRoute(path: '/quiz_bilan_niveau_placeholder', name: 'quizBilanNiveauPlaceholder', builder: (context, state) => const QuizBilanNiveauPlaceholderPage()),
      GoRoute(path: '/quiz_challenge_list', name: 'quizChallengeList', builder: (context, state) => const QuizChallengeListPage()),
      GoRoute(path: '/quiz_results', name: 'quizResults', builder: (context, state) {
        final results = state.extra as Map<String, dynamic>?;
        return QuizResultsPage(results: results ?? QuizResultsPage.getDummyResults());
      }),
      GoRoute(path: '/chatbot', name: 'chatbot', builder: (context, state) => const ChatbotPage()),

    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );
});

class _ErrorPage extends StatelessWidget {
  final Exception? error;
  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page non trouvée')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Oops ! Page Introuvable.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'La page que vous cherchez n\'existe pas ou a été déplacée.\n${error != null ? error.toString() : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.home_outlined),
              label: const Text('Retour à l\'accueil'),
              onPressed: () => context.go('/get-started'), // Redirige vers la page de démarrage générale
            ),
          ],
        ),
      ),
    );
  }
}
