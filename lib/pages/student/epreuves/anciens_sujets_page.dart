import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/providers/student_epreuves_provider.dart';
import 'package:easybosh_v2/core/providers/auth_provider.dart';
import 'package:easybosh_v2/widgets/student/epreuve_card.dart';

class AnciensSujetsPage extends ConsumerStatefulWidget {
  const AnciensSujetsPage({super.key});

  @override
  ConsumerState<AnciensSujetsPage> createState() => _AnciensSujetsPageState();
}

class _AnciensSujetsPageState extends ConsumerState<AnciensSujetsPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedAnnee;
  int? _selectedMatiereId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final epreuvesAsync = ref.watch(epreuvesByTypeProvider(EpreuveType.ancienSujet));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white, // Changé à blanc
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/epreuves'),
        ),
        title: const Text(
          'Anciens Sujets',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: epreuvesAsync.when(
        data: (epreuves) {
          final epreuvesEtudiant = epreuves.where((e) {
            if (currentUser?.niveauCode != null && e.niveauCode != currentUser!.niveauCode) {
              return false;
            }
            if (currentUser?.serieCode != null && !e.seriesCodes.contains(currentUser!.serieCode)) {
              return false;
            }
            return true;
          }).toList();

          var filteredEpreuves = epreuvesEtudiant.where((e) {
            if (_searchController.text.isNotEmpty) {
              final searchLower = _searchController.text.toLowerCase();
              if (!e.nom.toLowerCase().contains(searchLower) &&
                  !e.matiereDisplay.toLowerCase().contains(searchLower)) {
                return false;
              }
            }

            if (_selectedAnnee != null && e.anneeExamen != _selectedAnnee) {
              return false;
            }

            if (_selectedMatiereId != null && e.matiereId != _selectedMatiereId) {
              return false;
            }

            return true;
          }).toList();

          return Column(
            children: [
              // Barre de recherche
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un sujet, matière...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Filtres - Alignés à gauche
              Container(
                width: double.infinity, // Prend toute la largeur
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: _selectedAnnee?.toString() ?? 'Année',
                      isActive: _selectedAnnee != null,
                      onTap: () => _showAnneeFilter(epreuvesEtudiant),
                      onClear: _selectedAnnee != null ? () => setState(() => _selectedAnnee = null) : null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Matière',
                      isActive: _selectedMatiereId != null,
                      onTap: () => _showMatiereFilter(epreuvesEtudiant),
                      onClear: _selectedMatiereId != null ? () => setState(() => _selectedMatiereId = null) : null,
                    ),
                  ],
                ),
              ),

              // En-tête + Liste
              Expanded(
                child: Container(
                  color: Colors.grey[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Text(
                          '${filteredEpreuves.length} sujet(s) trouvé(s)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),

                      Expanded(
                        child: filteredEpreuves.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun sujet trouvé',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Essayez de modifier vos filtres',
                                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredEpreuves.length,
                          itemBuilder: (context, index) {
                            return EpreuveCard(epreuve: filteredEpreuves[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            if (isActive && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              )
            else
              Icon(Icons.arrow_drop_down, size: 18, color: isActive ? Colors.white : Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showAnneeFilter(List<Epreuve> epreuves) {
    final annees = epreuves
        .where((e) => e.anneeExamen != null)
        .map((e) => e.anneeExamen!)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        width: double.infinity, // Largeur complète
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrer par année',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...annees.map((annee) => ListTile(
              title: Text(annee.toString()),
              onTap: () {
                setState(() => _selectedAnnee = annee);
                Navigator.pop(context);
              },
              trailing: _selectedAnnee == annee ? const Icon(Icons.check, color: Colors.blue) : null,
            )),
          ],
        ),
      ),
    );
  }

  void _showMatiereFilter(List<Epreuve> epreuves) {
    final matieresMap = <int, String>{};
    for (var epreuve in epreuves) {
      matieresMap[epreuve.matiereId] = epreuve.matiereDisplay;
    }

    final matieres = matieresMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Permet un meilleur contrôle de la taille
      builder: (context) => Container(
        width: double.infinity, // Largeur complète
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrer par matière',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...matieres.map((entry) => ListTile(
              title: Text(entry.value),
              onTap: () {
                setState(() => _selectedMatiereId = entry.key);
                Navigator.pop(context);
              },
              trailing: _selectedMatiereId == entry.key ? const Icon(Icons.check, color: Colors.blue) : null,
            )),
          ],
        ),
      ),
    );
  }
}