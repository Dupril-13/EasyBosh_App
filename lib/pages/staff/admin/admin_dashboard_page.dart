import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enum pour représenter les différentes sections du dashboard
enum AdminDashboardSection {
  overview,
  userManagement, // Comprend maintenant admin et teachers
  activityLogs,
  profileManagement,
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminDashboardSection _selectedSection = AdminDashboardSection.overview;

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
              'Easybosh Admin', // Titre de la sidebar
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
            section: AdminDashboardSection.overview,
            onTap: () {
              setState(() {
                _selectedSection = AdminDashboardSection.overview;
              });
              // TODO: Naviguer vers la sous-route correspondante si chaque section est une route
              // context.go('/admin/dashboard/overview');
            }
          ),
          _buildSidebarItem(
            context,
            icon: Icons.group_outlined, 
            title: 'Gestion Utilisateurs', // Regroupe Admin et Enseignants
            section: AdminDashboardSection.userManagement,
            onTap: () {
              setState(() {
                _selectedSection = AdminDashboardSection.userManagement;
              });
              // TODO: Afficher ManageAdminsPage ou ManageTeachersPage dans _buildContentArea
              // ou naviguer vers des routes spécifiques comme '/admin/manage-admins'
              // context.go('/admin/manage-teachers'); // ou '/admin/manage-admins'
            }
          ),
          _buildSidebarItem(
            context,
            icon: Icons.history_outlined, 
            title: 'Logs d\'activité',
            section: AdminDashboardSection.activityLogs,
            onTap: () {
               setState(() {
                _selectedSection = AdminDashboardSection.activityLogs;
              });
              // context.go('/admin/activity-logs');
            }
          ),
          _buildSidebarItem(
            context,
            icon: Icons.manage_accounts_outlined, 
            title: 'Gestion profil',
            section: AdminDashboardSection.profileManagement,
            onTap: () {
               setState(() {
                _selectedSection = AdminDashboardSection.profileManagement;
              });
              // context.go('/admin/profile');
            }
          ),
          const Spacer(), 
          Divider(color: const Color(0xFF42A5F5), height: 1), 
          ListTile(
            leading: Icon(Icons.logout, color: Colors.white), 
            title: Text('Déconnexion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    required AdminDashboardSection section,
    VoidCallback? onTap,
  }) {
    final bool isSelected = _selectedSection == section;
    final Color itemColor = isSelected ? Colors.white : Colors.blue[100]!;
    final Color? tileBackgroundColor = isSelected ? const Color(0xFF2196F3) : null;

    return Material(
      color: tileBackgroundColor ?? Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: itemColor),
        title: Text(title, style: TextStyle(color: itemColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: onTap,
        selected: isSelected,
        hoverColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  // Méthode pour construire la zone de contenu principale
  Widget _buildContentArea(BuildContext context) {
    String title;
    Widget content;

    // TODO: Importer les vraies pages SANS leur Scaffold et les utiliser ici.
    // Exemple: import '../manage_teachers_page.dart';
    // Exemple: import '../manage_admins_page.dart';

    switch (_selectedSection) {
      case AdminDashboardSection.overview:
        title = 'Vue d\'ensemble';
        content = const Center(child: Text('Contenu de la Vue d\'ensemble Admin.'));
        break;
      case AdminDashboardSection.userManagement:
        title = 'Gestion Des Utilisateurs';
        // TODO: Mettre ici ManageTeachersPage() ou ManageAdminsPage() SANS leur Scaffold
        // Vous aurez besoin d'une logique pour choisir entre les deux, ou des sous-sections.
        content = const Center(child: Text('Contenu de la Gestion Des Utilisateurs (Admins, Enseignants).'));
        break;
      case AdminDashboardSection.activityLogs:
        title = 'Logs d\'activité';
        // TODO: Mettre ici ActivityLogsPage() SANS son Scaffold
        content = const Center(child: Text('Contenu des Logs d\'activité (Enseignants/Admins).'));
        break;
      case AdminDashboardSection.profileManagement:
        title = 'Gestion de son profil';
        // TODO: Mettre ici AdminProfilePage() SANS son Scaffold
        content = const Center(child: Text('Contenu de la Gestion de son profil Admin.'));
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
