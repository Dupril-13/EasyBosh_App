
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider & Listenable
import '../../providers/auth_provider.dart'; 

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

// Pages Staff
import '../../pages/staff/staff_login_page.dart';
import '../../pages/staff/admin/admin_dashboard_page.dart';
import '../../pages/staff/admin/manage_teachers_page.dart';
import '../../pages/staff/admin/manage_admins_page.dart';
import '../../pages/staff/admin/activity_logs_page.dart';
import '../../pages/staff/admin/admin_profile_page.dart';
import '../../pages/staff/teacher/teacher_dashboard_page.dart';
import '../../pages/staff/teacher/manage_chapitres_page.dart'; 
import '../../pages/staff/teacher/edit_chapitre_page.dart';   
import '../../pages/staff/teacher/manage_lecons_page.dart';    
import '../../pages/staff/teacher/edit_lecon_page.dart';      
import '../../pages/staff/teacher/manage_exams_page.dart';
import '../../pages/staff/teacher/manage_quizzes_page.dart';
import '../../pages/staff/teacher/teacher_analytics_page.dart';
import '../../pages/staff/teacher/teacher_profile_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  final authListenable = AuthStateListenable(authNotifier);

  ref.onDispose(() {
    authListenable.dispose();
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/staff-login',
    debugLogDiagnostics: true,
    refreshListenable: authListenable,

    redirect: (BuildContext context, GoRouterState state) {
      final bool isLoggedIn = authNotifier.isLoggedIn;
      final String? userRole = authNotifier.userRole;
      final String currentLocation = state.uri.path;

      const List<String> publicAuthPaths = [
        '/staff-login',
        '/auth/login',
        '/auth/signup',
        '/get-started',
      ];
      const String verificationPath = '/auth/verification';

      final bool isOnPublicAuthPath = publicAuthPaths.contains(currentLocation);
      final bool isOnVerificationPath = currentLocation == verificationPath;

      if (!isLoggedIn) {
        if (!isOnPublicAuthPath && !isOnVerificationPath) {
          return '/staff-login'; 
        }
      } else {
        if (isOnPublicAuthPath) {
          if (userRole == 'admin') return '/admin/dashboard';
          if (userRole == 'teacher') return '/teacher/dashboard';
          if (userRole == 'student') return '/cours';
          return '/staff-login';
        }
        if (userRole == 'student' && (currentLocation.startsWith('/admin') || currentLocation.startsWith('/teacher'))) {
          return '/cours';
        }
        if (userRole == 'teacher' && currentLocation.startsWith('/admin')) {
          return '/teacher/dashboard';
        }
      }
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
      
      // Routes Admin
      GoRoute(
        path: '/admin/dashboard',
        name: 'adminDashboard',
        builder: (BuildContext context, GoRouterState state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/admin/manage-teachers',
        name: 'adminManageTeachers',
        builder: (BuildContext context, GoRouterState state) => const ManageTeachersPage(), 
      ),
      GoRoute(
        path: '/admin/manage-admins',
        name: 'adminManageAdmins',
        builder: (BuildContext context, GoRouterState state) => const ManageAdminsPage(), 
      ),
      GoRoute(
        path: '/admin/activity-logs',
        name: 'adminActivityLogs',
        builder: (BuildContext context, GoRouterState state) => const ActivityLogsPage(), 
      ),
      GoRoute(
        path: '/admin/profile',
        name: 'adminProfile',
        builder: (BuildContext context, GoRouterState state) => const AdminProfilePage(), 
      ),

      // Routes Teacher
      GoRoute(
        path: '/teacher/dashboard',
        name: 'teacherDashboard',
        builder: (BuildContext context, GoRouterState state) => const TeacherDashboardPage(),
      ),
      // GoRoute(
      //   path: '/teacher/cours/manage-chapitres', 
      //   name: 'teacherManageChapitres',
      //   builder: (BuildContext context, GoRouterState state) => const ManageChapitresPage(onChapitreSelected: (chapitre) {
      //     // Cette page est maintenant gérée par TeacherDashboardPage
      //   }), 
      // ),
      GoRoute(
        path: '/teacher/cours/chapitres/add', 
        name: 'teacherAddChapitre',
        // Ce formulaire est maintenant affiché dans TeacherDashboardPage.
        // Un accès direct ici ne fournira pas les callbacks onSubmitted/onCancel.
        builder: (context, state) => const EditChapitrePage(), 
      ),
      GoRoute(
        path: '/teacher/cours/chapitres/:chapitreId/edit',
        name: 'teacherEditChapitre',
        builder: (context, state) {
          final chapitreIdString = state.pathParameters['chapitreId'];
          final chapitreId = chapitreIdString != null ? int.tryParse(chapitreIdString) : null;
          if (chapitreId == null) {
            return const Center(child: Text("ID de chapitre invalide"));
          }
          // Ce formulaire est maintenant affiché dans TeacherDashboardPage.
          // Un accès direct ici ne fournira pas les callbacks onSubmitted/onCancel.
          return EditChapitrePage(chapitreId: chapitreId);
        },
      ),
      // GoRoute(
      //   path: '/teacher/cours/manage-lecons', 
      //   name: 'teacherManageLecons',
      //    builder: (BuildContext context, GoRouterState state) {
      //     // Cette page est maintenant gérée par TeacherDashboardPage
      //     return Center(child: Text("Accès direct non configuré pour la gestion des leçons. Utilisez le dashboard."));
      //   }
      // ),
      GoRoute(
        path: '/teacher/cours/lecons/add', 
        name: 'teacherAddLecon',
        // EditLeconPage a besoin de chapitreId et des callbacks, qui sont fournis par TeacherDashboardPage.
        // Un accès direct n'est plus supporté de cette manière.
        builder: (context, state) => const Center(child: Text("Pour ajouter une leçon, passez par la gestion des cours du tableau de bord enseignant.")),
      ),
      GoRoute(
        path: '/teacher/cours/lecons/:leconId/edit',
        name: 'teacherEditLecon',
        // EditLeconPage a besoin de chapitreId et des callbacks, qui sont fournis par TeacherDashboardPage.
        // Un accès direct n'est plus supporté de cette manière.
        builder: (context, state) {
          // final leconIdString = state.pathParameters['leconId'];
          // final leconId = leconIdString != null ? int.tryParse(leconIdString) : null;
          // if (leconId == null) {
          //   return const Center(child: Text("ID de leçon invalide"));
          // }
          // Il manque chapitreId et les callbacks ici.
          return const Center(child: Text("Pour modifier une leçon, passez par la gestion des cours du tableau de bord enseignant."));
        },
      ),
      GoRoute(
        path: '/teacher/manage-exams',
        name: 'teacherManageExams',
        builder: (BuildContext context, GoRouterState state) => const ManageExamsPage(), 
      ),
      GoRoute(
        path: '/teacher/manage-quizzes',
        name: 'teacherManageQuizzes',
        builder: (BuildContext context, GoRouterState state) => const ManageQuizzesPage(), 
      ),
      GoRoute(
        path: '/teacher/analytics',
        name: 'teacherAnalytics',
        builder: (BuildContext context, GoRouterState state) => const TeacherAnalyticsPage(), 
      ),
      GoRoute(
        path: '/teacher/profile',
        name: 'teacherProfile',
        builder: (BuildContext context, GoRouterState state) => const TeacherProfilePage(), 
      ),

      // Student Routes
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
      GoRoute(
        path: '/quiz/selection-matiere',
        name: 'quizMatiereSelection',
        builder: (context, state) => const QuizMatiereSelectionPage(),
      ),
      GoRoute(
        path: '/quiz/list-par-matiere/:matiereId',
        name: 'quizListParMatiere',
        builder: (context, state) => QuizListByMatierePage(matiereNom: state.pathParameters['matiereId']!),
      ),
      GoRoute(
        path: '/quiz/play/:quizId',
        name: 'quizPlay',
        builder: (context, state) {
          if (state.extra is Map<String, dynamic>) {
            return QuizPlayPage(quizDetails: state.extra as Map<String, dynamic>);
          }          
          return const Scaffold(body: Center(child: Text("Détails du quiz non fournis correctement.")));
        },
      ),
      GoRoute(
        path: '/quiz/express-placeholder',
        name: 'quizExpressPlaceholder',
        builder: (context, state) => const QuizExpressPlaceholderPage(),
      ),
      GoRoute(
        path: '/quiz/bilan-niveau-placeholder',
        name: 'quizBilanNiveauPlaceholder',
        builder: (context, state) => const QuizBilanNiveauPlaceholderPage(),
      ),
      GoRoute(
        path: '/quiz/challenges',
        name: 'quizChallengeList',
        builder: (context, state) => const QuizChallengeListPage(),
      ),
      GoRoute(
        path: '/quiz/results/:quizAttemptId',
        name: 'quizResults',
        builder: (context, state) {
          if (state.extra is Map<String, dynamic>) { 
            return QuizResultsPage(results: state.extra as Map<String, dynamic>);
          }          
          return const Scaffold(body: Center(child: Text("Résultats du quiz non fournis correctement.")));
        },
      ),
      GoRoute(
        path: '/chatbot',
        name: 'chatbot',
        builder: (context, state) => const ChatbotPage(),
      ),
    ],
  );
});
