import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easybosh_v2/widgets/custom_navbar.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/providers/student_epreuves_provider.dart';

class EpreuvesPage extends ConsumerStatefulWidget {
  const EpreuvesPage({super.key});

  @override
  ConsumerState<EpreuvesPage> createState() => _EpreuvesPageState();
}

class _EpreuvesPageState extends ConsumerState<EpreuvesPage> {
  int _currentIndex = 1;

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0: context.go('/cours'); break;
      case 2: context.go('/quiz'); break;
      case 3: context.go('/statistiques'); break;
    }
  }

  void _navigateToCategory(String route, bool isEnabled) {
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce type d\'épreuve n\'est pas encore disponible.')),
      );
      return;
    }
    if (route.isNotEmpty) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer les compteurs d'épreuves par type
    final anciensSujetsCountAsync = ref.watch(epreuvesCountByTypeProvider(EpreuveType.ancienSujet));
    final sujetsCollegesCountAsync = ref.watch(epreuvesCountByTypeProvider(EpreuveType.sujetCollege));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.notification, color: Colors.grey[700]),
          onPressed: () => context.push('/notifications'),
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
            onPressed: () => context.push('/settings'),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bannière de bienvenue
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange, Colors.orange.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Préparez vos examens !',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Entraînez-vous avec les épreuves officielles',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Image.asset(
                              'assets/images/Thesis-pana.png',
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.assignment,
                                  size: 100,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Grille de catégories
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.05,
                        children: [
                          _buildCategoryCard(
                            nom: 'Anciens Sujets',
                            icon: Icons.history_edu_outlined,
                            route: '/anciens_sujets',
                            color: Colors.blue,
                            nombreSujetsAsync: anciensSujetsCountAsync,
                            enabled: true,
                          ),
                          _buildCategoryCard(
                            nom: 'Etablissements',
                            icon: Icons.school_outlined,
                            route: '/colleges_connus',
                            color: Colors.orange,
                            nombreSujetsAsync: sujetsCollegesCountAsync,
                            enabled: true,
                          ),
                          _buildCategoryCard(
                            nom: 'Examens Blancs',
                            icon: Icons.lightbulb_outline,
                            route: '/examens_blancs',
                            color: Colors.green,
                            nombreSujetsAsync: const AsyncValue.data(0),
                            enabled: false,
                          ),
                          _buildCategoryCard(
                            nom: 'Exclusif',
                            icon: Icons.star_border_outlined,
                            route: '/epreuves_exclusives',
                            color: Colors.purple,
                            nombreSujetsAsync: const AsyncValue.data(0),
                            enabled: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          CustomNavBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String nom,
    required IconData icon,
    required String route,
    required Color color,
    required AsyncValue<int> nombreSujetsAsync,
    required bool enabled,
  }) {
    return nombreSujetsAsync.when(
      data: (nombreSujets) => Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _navigateToCategory(route, enabled),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 36, color: color),
                    const SizedBox(height: 8),
                    Text(
                      nom,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$nombreSujets sujets',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (!enabled)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Bientôt',
                          style: TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      loading: () => _buildLoadingCard(nom, icon, color),
      error: (_, __) => _buildErrorCard(nom, icon, color),
    );
  }

  Widget _buildLoadingCard(String nom, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 8),
          Text(nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String nom, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 8),
          Text(nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('--', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}