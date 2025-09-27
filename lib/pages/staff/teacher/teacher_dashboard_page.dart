import 'package:easybosh_v2/models/chapitre_model.dart'; 
import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './manage_chapitres_page.dart';
import './manage_lecons_page.dart';
import './edit_chapitre_page.dart'; 
import './edit_lecon_page.dart';

enum TeacherDashboardSection {
  overview,
  manageChapters,
  manageLessonsForChapter,
  editChapter,      // Pour ajout/modification de chapitre
  editLesson,       // Pour ajout/modification de leçon
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
  
  int? _currentChapitreIdForLessons; 
  int? _currentMatiereIdForChapitresFilter;

  int? _editingChapitreId;
  int? _editingLeconId;

  void _handleNavigation(TeacherDashboardSection section) {
    setState(() {
      _selectedSection = section;
      if (section != TeacherDashboardSection.editChapter && section != TeacherDashboardSection.editLesson) {
        _editingChapitreId = null;
        _editingLeconId = null;
      }
      if (section != TeacherDashboardSection.manageLessonsForChapter && section != TeacherDashboardSection.editLesson) {
         _currentChapitreIdForLessons = null;
      }
    });
  }

  void _navigateToChapitreLessons(ChapitreModel chapitre) {
    setState(() {
      _selectedSection = TeacherDashboardSection.manageLessonsForChapter;
      _currentChapitreIdForLessons = chapitre.id;
      _editingChapitreId = null; 
      _editingLeconId = null;
    });
  }

  void _navigateBackToChapitresList() {
    setState(() {
      _selectedSection = TeacherDashboardSection.manageChapters;
      _currentChapitreIdForLessons = null;
      _editingLeconId = null; 
    });
  }

  void _navigateToAddChapitre() {
    setState(() {
      _selectedSection = TeacherDashboardSection.editChapter;
      _editingChapitreId = null; 
    });
  }

  void _navigateToEditChapitre(ChapitreModel chapitre) {
    setState(() {
      _selectedSection = TeacherDashboardSection.editChapter;
      _editingChapitreId = chapitre.id;
    });
  }

  void _navigateToAddLecon() {
    if (_currentChapitreIdForLessons == null) return; 
    setState(() {
      _selectedSection = TeacherDashboardSection.editLesson;
      _editingLeconId = null; 
    });
  }

  void _navigateToEditLecon(LeconModel lecon) {
    if (_currentChapitreIdForLessons == null) return; 
    setState(() {
      _selectedSection = TeacherDashboardSection.editLesson;
      _editingLeconId = lecon.id;
    });
  }

  void _handleFormCompletion({bool fromLeconForm = false}) {
    setState(() {
      if (fromLeconForm) {
        _selectedSection = TeacherDashboardSection.manageLessonsForChapter;
      } else {
        _selectedSection = TeacherDashboardSection.manageChapters;
      }
      _editingChapitreId = null;
      _editingLeconId = null;
    });
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260, 
      color: const Color(0xFF1976D2), 
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Text(
              'Easybosh Enseignant',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: const Color(0xFF42A5F5), height: 1),
          _buildSidebarItem(
            context,
            icon: Icons.dashboard_outlined,
            title: 'Vue d\'ensemble',
            currentSection: TeacherDashboardSection.overview,
            onTap: () => _handleNavigation(TeacherDashboardSection.overview)
          ),
          _buildSidebarItem(
            context,
            icon: Icons.list_alt_outlined, 
            title: 'Gestion Cours',
            currentSection: TeacherDashboardSection.manageChapters, 
            isActiveOverride: _selectedSection == TeacherDashboardSection.manageLessonsForChapter || 
                              _selectedSection == TeacherDashboardSection.editChapter || 
                              _selectedSection == TeacherDashboardSection.editLesson,
            onTap: () => _handleNavigation(TeacherDashboardSection.manageChapters)
          ),
          _buildSidebarItem(
            context,
            icon: Icons.assignment_outlined,
            title: 'Gestion Épreuves',
            currentSection: TeacherDashboardSection.examManagement,
            onTap: () => _handleNavigation(TeacherDashboardSection.examManagement)
          ),
          _buildSidebarItem(
            context,
            icon: Icons.quiz_outlined,
            title: 'Gestion Quiz',
            currentSection: TeacherDashboardSection.quizManagement,
            onTap: () => _handleNavigation(TeacherDashboardSection.quizManagement)
          ),
           _buildSidebarItem(
            context,
            icon: Icons.person_outline, 
            title: 'Profil',
            currentSection: TeacherDashboardSection.profileManagement,
            onTap: () => _handleNavigation(TeacherDashboardSection.profileManagement)
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
                  const SnackBar(content: Text('Vous avez été déconnecté.'), backgroundColor: Colors.green)
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.redAccent)
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required TeacherDashboardSection currentSection, 
    bool isActiveOverride = false, 
    VoidCallback? onTap,
  }) {
    bool isSelected = (_selectedSection == currentSection) || isActiveOverride;

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

  Widget _buildContentArea(BuildContext context) {
    String title;
    Widget content;

    switch (_selectedSection) {
      case TeacherDashboardSection.overview:
        title = 'Vue d\'ensemble';
        content = const Center(child: Text('Contenu de la Vue d\'ensemble Enseignant.'));
        break;
      case TeacherDashboardSection.manageChapters:
        title = 'Gestion des Chapitres';
        content = ManageChapitresPage(
          onChapitreSelected: _navigateToChapitreLessons,
          initialSelectedMatiereId: _currentMatiereIdForChapitresFilter, 
          onMatiereFilterChanged: (newMatiereId) {
            setState(() {
              _currentMatiereIdForChapitresFilter = newMatiereId;
            });
          },
          onAddChapitre: _navigateToAddChapitre,       
          onEditChapitre: _navigateToEditChapitre,     
        );
        break;
      case TeacherDashboardSection.manageLessonsForChapter:
        title = 'Leçons du Chapitre'; 
        if (_currentChapitreIdForLessons == null) {
          content = const Center(child: Text('Erreur: Aucun chapitre sélectionné pour afficher les leçons.'));
        } else {
          content = ManageLeconsPage(
            chapitreId: _currentChapitreIdForLessons!,
            onBackToChapitres: _navigateBackToChapitresList,
            onAddLecon: _navigateToAddLecon,           
            onEditLecon: _navigateToEditLecon,         
          );
        }
        break;
      case TeacherDashboardSection.editChapter:
        title = _editingChapitreId == null ? 'Ajouter un Chapitre' : 'Modifier le Chapitre';
        content = EditChapitrePage(
          chapitreId: _editingChapitreId,
          matiereIdInitial: _editingChapitreId == null ? _currentMatiereIdForChapitresFilter : null,
          onSubmitted: () => _handleFormCompletion(fromLeconForm: false),
          onCancel: () => _handleFormCompletion(fromLeconForm: false), 
        );
        break;
      case TeacherDashboardSection.editLesson:
        title = _editingLeconId == null ? 'Ajouter une Leçon' : 'Modifier la Leçon';
        if (_currentChapitreIdForLessons == null) {
           content = const Center(child: Text('Erreur: Contexte de chapitre manquant pour éditer la leçon.'));
        } else {
          content = EditLeconPage(
            leconId: _editingLeconId,
            chapitreId: _currentChapitreIdForLessons, 
            onSubmitted: () => _handleFormCompletion(fromLeconForm: true),
            onCancel: () => _handleFormCompletion(fromLeconForm: true),
          );
        }
        break;
      case TeacherDashboardSection.examManagement:
        title = 'Gestion des Épreuves';
        content = const Center(child: Text('Contenu de la Gestion des Épreuves.')); 
        break;
      case TeacherDashboardSection.quizManagement:
        title = 'Gestion des Quiz';
        content = const Center(child: Text('Contenu de la Gestion des Quiz.')); 
        break;
      case TeacherDashboardSection.profileManagement:
        title = 'Gestion du Profil';
        content = const Center(child: Text('Contenu de la Gestion du Profil.')); 
        break;
      default:
        title = 'Erreur';
        content = const Center(child: Text('Section non trouvée.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0), 
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant 
                ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // MODIFIED: Added vertical padding
            child: Card(
              elevation: 0, 
              color: Theme.of(context).colorScheme.surface, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              margin: EdgeInsets.zero, // ADDED: Explicitly set margin to zero
              clipBehavior: Clip.antiAlias, // ADDED: Ensure content clipping
              child: content, // MODIFIED: Removed redundant inner Padding(all:0)
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant, 
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
