import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enum pour représenter les différentes sections du dashboard
enum TeacherDashboardSection {
  overview,
  courseManagement,
  examManagement,
  quizManagement,
  profileManagement,
}

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  TeacherDashboardSection _selectedSection = TeacherDashboardSection.overview;

  // Méthode pour construire la Sidebar
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260, // Largeur de la sidebar
      color: const Color(0xFF1976D2), // Colors.blue[700]
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Text(
              'Easybosh Enseignant', // Titre de la sidebar
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: const Color(0xFF42A5F5), height: 1), // Colors.blue[400]
          _buildSidebarItem(
            context,
            icon: Icons.dashboard_outlined,
            title: 'Vue d\'ensemble',
            section: TeacherDashboardSection.overview,
          ),
          _buildSidebarItem(
            context,
            icon: Icons.library_books_outlined,
            title: 'Gestion de cours',
            section: TeacherDashboardSection.courseManagement,
          ),
          _buildSidebarItem(
            context,
            icon: Icons.assignment_outlined,
            title: 'Gestion d\'épreuves',
            section: TeacherDashboardSection.examManagement,
          ),
          _buildSidebarItem(
            context,
            icon: Icons.quiz_outlined,
            title: 'Gestion de quiz',
            section: TeacherDashboardSection.quizManagement,
          ),
           _buildSidebarItem(
            context,
            icon: Icons.person_outline, 
            title: 'Gestion profil',
            section: TeacherDashboardSection.profileManagement,
          ),
          const Spacer(), // Pour pousser les derniers éléments en bas
          Divider(color: const Color(0xFF42A5F5), height: 1), // Colors.blue[400]
          ListTile(
            leading: Icon(Icons.logout, color: Colors.white), // Icône en blanc
            title: Text('Déconnexion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Texte en blanc
            onTap: () async {
              try {
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                context.go('/staff-login'); 
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vous avez été déconnecté.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  )
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  )
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper pour construire un item de la sidebar
  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required TeacherDashboardSection section,
  }) {
    final bool isSelected = _selectedSection == section;
    final Color itemColor = isSelected ? Colors.white : Colors.blue[100]!;
    final Color? tileBackgroundColor = isSelected ? const Color(0xFF2196F3) : null; // Colors.blue[500]

    return Material(
      color: tileBackgroundColor ?? Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: itemColor),
        title: Text(title, style: TextStyle(color: itemColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: () {
          setState(() {
            _selectedSection = section;
          });
        },
        selected: isSelected,
        hoverColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  // Méthode pour construire la zone de contenu principale
  Widget _buildContentArea(BuildContext context) {
    String title;
    Widget content;

    switch (_selectedSection) {
      case TeacherDashboardSection.overview:
        title = 'Vue d\'ensemble';
        content = const Center(child: Text('Contenu de la Vue d\'ensemble Enseignant.'));
        break;
      case TeacherDashboardSection.courseManagement:
        title = 'Gestion de cours';
        content = const Center(child: Text('Contenu de la Gestion de cours.'));
        break;
      case TeacherDashboardSection.examManagement:
        title = 'Gestion d\'épreuves';
        content = const Center(child: Text('Contenu de la Gestion d\'épreuves.'));
        break;
      case TeacherDashboardSection.quizManagement:
        title = 'Gestion de quiz';
        content = const Center(child: Text('Contenu de la Gestion de quiz.'));
        break;
      case TeacherDashboardSection.profileManagement:
        title = 'Gestion profil';
        content = const Center(child: Text('Contenu de la Gestion du profil Enseignant.'));
        break;
      default:
        title = 'Erreur';
        content = const Center(child: Text('Section non trouvée.'));
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary // Utilise la couleur primaire du thème
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // Bleu très clair pour la zone de contenu (Colors.blue[50])
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: _buildContentArea(context),
          ),
        ],
      ),
    );
  }
}
