import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeacherShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TeacherShellPage({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 720;

    // Destinations mises à jour pour inclure "Gestion Cours"
    final List<NavigationRailDestination> railDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.folder_copy_outlined), // Icône pour Gestion Cours
        selectedIcon: Icon(Icons.folder_copy),
        label: Text('Gestion Cours'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: Text('Épreuves'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.quiz_outlined),
        selectedIcon: Icon(Icons.quiz),
        label: Text('Quiz'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: Text('Stats'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: Text('Profil'),
      ),
    ];

    final List<NavigationDestination> barDestinations = [
      const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
      const NavigationDestination(icon: Icon(Icons.folder_copy_outlined), selectedIcon: Icon(Icons.folder_copy), label: 'Gestion Cours'),
      const NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Épreuves'),
      const NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz), label: 'Quiz'),
      const NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Stats'),
      const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person),label: 'Profil'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enseignant Easybosh'), 
        leading: !isDesktop && GoRouter.of(context).canPop() 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  GoRouter.of(context).pop();
                },
              )
            : null,
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _onDestinationSelected(context, index),
              labelType: NavigationRailLabelType.all,
              destinations: railDestinations,
            ),
          Expanded(
            child: navigationShell,
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
        ? NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => _onDestinationSelected(context, index),
            destinations: barDestinations,
          )
        : null,
    );
  }

  void _onDestinationSelected(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
