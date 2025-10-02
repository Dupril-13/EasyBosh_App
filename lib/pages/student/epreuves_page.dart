import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../widgets/custom_navbar.dart';

class EpreuvesPage extends StatefulWidget {
  const EpreuvesPage({super.key});

  @override
  State<EpreuvesPage> createState() => _EpreuvesPageState();
}

class _EpreuvesPageState extends State<EpreuvesPage> {
  int _currentIndex = 1;

  final List<Map<String, dynamic>> _categories = [
    {'nom': 'Anciens Sujets', 'icon': Icons.history_edu_outlined, 'route': '/anciens_sujets', 'color': Colors.blue, 'nombreSujets': 120, 'enabled': true},
    {'nom': 'Etablissements', 'icon': Icons.school_outlined, 'route': '/colleges_connus', 'color': Colors.orange, 'nombreSujets': 75, 'enabled': true},
    {'nom': 'Examens Blancs', 'icon': Icons.lightbulb_outline, 'route': '/examens_blancs', 'color': Colors.green, 'nombreSujets': 0, 'enabled': false},
    {'nom': 'Exclusif', 'icon': Icons.star_border_outlined, 'route': '/epreuves_exclusives', 'color': Colors.purple, 'nombreSujets': 0, 'enabled': false},
  ];

  void _navigateToCategory(String route, bool isEnabled) {
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce type d\'épreuve n\'est pas encore disponible.')),
      );
      return;
    }
    if (route.isNotEmpty) {
      context.go(route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route non définie pour cette catégorie')),
      );
    }
  }

  // ... (le reste de la page reste inchangé pour l'instant)

  @override
  Widget build(BuildContext context) {
    // ... (build method)
     return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.notification, color: Colors.grey[700]),
          onPressed: () {
            context.go('/notifications'); 
          },
          tooltip: 'Notifications',
        ),
        title: const Text(
          'Épreuves',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Iconsax.setting_2, color: Colors.grey[700]),
            onPressed: () {
              context.go('/settings');
            },
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... (En-tête)
                  const SizedBox(height: 24),
                  const Text(
                    'Types d\'epreuves',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildCategoriesGrid(),
                  // ... (le reste)
                ],
              ),
            ),
          ),
          CustomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
                if (index == _currentIndex) return;
                setState(() => _currentIndex = index);
                switch (index) {
                  case 0: context.go('/cours'); break;
                  case 2: context.go('/quiz'); break;
                  case 3: context.go('/statistiques'); break;
                }
            },
          ),
        ],
      ),
      // ... (FloatingActionButton)
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category, category['color'] as Color, category['enabled'] as bool);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, Color cardColor, bool isEnabled) {
    final IconData iconData = category['icon'] as IconData;
    final String nom = category['nom'] as String;
    final int nombreSujets = category['nombreSujets'] as int? ?? 0;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        // ... (décoration de la carte)
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToCategory(category['route'] as String? ?? '', isEnabled),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                // ... (contenu de la carte)
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... (le reste des widgets)
}
