import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/providers/student_epreuves_provider.dart';
import 'package:easybosh_v2/providers/auth_provider.dart';
import 'package:easybosh_v2/widgets/student/epreuve_card.dart';
import 'package:easybosh_v2/core/providers/auth_provider.dart';

class AnciensSujetsPage extends ConsumerStatefulWidget {
  const AnciensSujetsPage({super.key});

  @override
  ConsumerState<AnciensSujetsPage> createState() => _AnciensSujetsPageState();
}

class _AnciensSujetsPageState extends ConsumerState<AnciensSujetsPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSession;
  String? _selectedSerie;
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
          'Anciens Sujets',
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
                  !e.matiereDisplay.toLowerCase().contains(searchLower)) {
                return false;
              }
            }

            // Filtre par session
            if (_selectedSession != null && e.sessionExamen != _selectedSession) {
              return false;
            }

            // Filtre par série
            if (_selectedSerie != null && !e.seriesCodes.contains(_selectedSerie)) {
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
                    hintText: 'Rechercher un sujet, matière...',
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

                // Filtres en chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: _selectedSession ?? 'Session',
                        isActive: _selectedSession != null,
                        onTap: () => _showSessionFilter(),
                        onClear: _selectedSession != null ? () => setState(() => _selectedSession = null) : null,
                      ),
                      const SizedBox(width: 8),
                      if (currentUser?.niveauCode != '3eme')
                        _buildFilterChip(
                          label: _selectedSerie ?? 'Série',
                          isActive: _selectedSerie != null,
                          onTap: () => _showSerieFilter(),
                          onClear: _selectedSerie != null ? () => setState(() => _selectedSerie = null) : null,
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
                        const SizedBox(height: 8),
                        Text(
                          'Essayez de modifier vos filtres',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey[400]!,
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

  void _showSessionFilter() {
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
              'Filtrer par session',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('BEPC'),
              onTap: () {
                setState(() => _selectedSession = 'BEPC');
                Navigator.pop(context);
              },
              trailing: _selectedSession == 'BEPC' ? const Icon(Icons.check, color: Colors.blue) : null,
            ),
            ListTile(
              title: const Text('Probatoire'),
              onTap: () {
                setState(() => _selectedSession = 'Probatoire');
                Navigator.pop(context);
              },
              trailing: _selectedSession == 'Probatoire' ? const Icon(Icons.check, color: Colors.blue) : null,
            ),
            ListTile(
              title: const Text('Baccalauréat'),
              onTap: () {
                setState(() => _selectedSession = 'Baccalauréat');
                Navigator.pop(context);
              },
              trailing: _selectedSession == 'Baccalauréat' ? const Icon(Icons.check, color: Colors.blue) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showSerieFilter() {
    final currentUser = ref.read(currentUserProvider);
    final userSerie = currentUser?.serieCode;

    final series = ['A', 'C', 'D', 'E', 'F'];

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
              'Filtrer par série',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...series.map((serie) => ListTile(
              title: Text(serie),
              onTap: () {
                setState(() => _selectedSerie = serie);
                Navigator.pop(context);
              },
              trailing: _selectedSerie == serie ? const Icon(Icons.check, color: Colors.blue) : null,
            )),
          ],
        ),
      ),
    );
  }

  void _showMatiereFilter(List<Epreuve> epreuves) {
    // Obtenir la liste unique des matières
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
              trailing: _selectedMatiereId == entry.key ? const Icon(Icons.check, color: Colors.blue) : null,
            )),
          ],
        ),
      ),
    );
  }
}