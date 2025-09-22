// Créez ces fichiers séparément dans votre projet :

// ============================================
// lib/features/cours/presentation/pages/cours_page.dart
// ============================================
import 'package:flutter/material.dart';

class CoursPage extends StatelessWidget {
  const CoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cours'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('Page Cours', style: TextStyle(fontSize: 24)),
            Text('🎉 Jalon 1 fonctionne !'),
          ],
        ),
      ),
    );
  }
}

// ============================================
// lib/features/cours/presentation/pages/matiere_detail_page.dart
// ============================================

class MatiereDetailPage extends StatelessWidget {
  final int matiereId;
  const MatiereDetailPage({super.key, required this.matiereId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Matière $matiereId')),
      body: const Center(child: Text('Détail matière')),
    );
  }
}

// ============================================
// lib/features/cours/presentation/pages/chapitres_page.dart
// ============================================

class ChapitresPage extends StatelessWidget {
  final int matiereId;
  final String typeContenu;
  const ChapitresPage({super.key, required this.matiereId, required this.typeContenu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chapitres $typeContenu')),
      body: const Center(child: Text('Liste chapitres')),
    );
  }
}

// ============================================
// lib/features/cours/presentation/pages/lecons_page.dart
// ============================================

class LeconsPage extends StatelessWidget {
  final int chapitreId;
  const LeconsPage({super.key, required this.chapitreId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leçons du chapitre $chapitreId')),
      body: const Center(child: Text('Liste leçons')),
    );
  }
}

// ============================================
// lib/features/cours/presentation/pages/lecon_viewer_page.dart
// ============================================

class LeconViewerPage extends StatelessWidget {
  final int leconId;
  const LeconViewerPage({super.key, required this.leconId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leçon $leconId')),
      body: const Center(child: Text('Lecteur de leçon')),
    );
  }
}

// ============================================
// Autres pages (créez les fichiers séparément)
// ============================================

// lib/features/epreuves/presentation/pages/epreuves_page.dart
class EpreuvesPage extends StatelessWidget {
  const EpreuvesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page Épreuves')),
    );
  }
}

// lib/features/quiz/presentation/pages/quiz_page.dart
class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page Quiz')),
    );
  }
}

// lib/features/statistiques/presentation/pages/statistiques_page.dart
class StatistiquesPage extends StatelessWidget {
  const StatistiquesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page Statistiques')),
    );
  }
}

// lib/features/profile/presentation/pages/profile_page.dart
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page Profil')),
    );
  }
}

// lib/features/settings/presentation/pages/settings_page.dart
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page Paramètres')),
    );
  }
}

// lib/features/staff/presentation/pages/enseignant_dashboard.dart
class EnseignantDashboard extends StatelessWidget {
  const EnseignantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('Dashboard Enseignant', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}

// lib/features/staff/presentation/pages/admin_dashboard.dart
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Dashboard Admin', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}