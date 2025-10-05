import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/providers/student_epreuves_provider.dart';
import 'package:easybosh_v2/widgets/student/epreuve_card.dart';

class SujetsCollegesPage extends ConsumerStatefulWidget {
  const SujetsCollegesPage({super.key});

  @override
  ConsumerState<SujetsCollegesPage> createState() => _SujetsCollegesPageState();
}

class _SujetsCollegesPageState extends ConsumerState<SujetsCollegesPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedVille;
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
    final epreuvesAsync = ref.watch(epreuvesByTypeProvider(EpreuveType.sujetCollege));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/epreuves');
            }
          },
        ),
        title: const Text(
          'Sujets de Collèges',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: epreuvesAsync.when(
        data: (epreuves) {
          // Appliquer les filtres
          var filteredEpreuves = epreuves.where((e) {
            // Filtre de recherche
            if (_searchController.text.isNotEmpty) {
              final searchLower = _searchController.text.toLowerCase();
              if (!e.nom.toLowerCase().contains(searchLower) &&
                  !e.matiereDisplay.toLowerCase().contains(searchLower) &&
                  !(e.nomEtablissement?.toLowerCase().contains(searchLower) ?? false) &&
                  !(e.villeEtablissement?.toLowerCase().contains(searchLower) ?? false)) {
                return false;
              }
            }

            // Filtre par ville
            if (_selectedVille != null && e.villeEtablissement != _selectedVille) {
              return false;
            }

            // Filtre par matière
            if (_selectedMatiereId != null && e.matiereId != _selectedMatiereId) {
              return false;
            }

            return true;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher sujet, collège, ville...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),

                const SizedBox(height: 16),

                // Filtres
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: _selectedVille ?? 'Ville',
                        isActive: _selectedVille != null,
                        onTap: () => _showVilleFilter(epreuves),
                        onClear: _selectedVille != null ? () => setState(() => _selectedVille = null) : null,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Matière',
                        isActive: _selectedMatiereId != null,
                        onTap: () => _showMatiereFilter(epreuves),
                        onClear: _selectedMatiereId != null ? () => setState(() => _selectedMatiereId = null) : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // En-tête de résultats
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filteredEpreuves.length} sujet(s) trouvé(s)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des épreuves
                Expanded(
                  child: filteredEpreuves.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun sujet trouvé',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: filteredEpreuves.length,
                    itemBuilder: (context, index) {
                      return EpreuveCard(epreuve: filteredEpreuves[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erreur: $error'),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.orange : Colors.grey[400]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            if (isActive && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              )
            else
              Icon(Icons.arrow_drop_down, size: 16, color: isActive ? Colors.white : Colors.grey[700]),
          ],
        ),
      ),
    );
  }

  void _showVilleFilter(List<Epreuve> epreuves) {
    // Obtenir la liste unique des villes
    final villes = epreuves
        .where((e) => e.villeEtablissement != null)
        .map((e) => e.villeEtablissement!)
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrer par ville',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...villes.map((ville) => ListTile(
              title: Text(ville),
              onTap: () {
                setState(() => _selectedVille = ville);
                Navigator.pop(context);
              },
              trailing: _selectedVille == ville ? const Icon(Icons.check, color: Colors.orange) : null,
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

    final matieres = matieresMap.entries.toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              trailing: _selectedMatiereId == entry.key ? const Icon(Icons.check, color: Colors.orange) : null,
            )),
          ],
        ),
      ),
    );
  }
}