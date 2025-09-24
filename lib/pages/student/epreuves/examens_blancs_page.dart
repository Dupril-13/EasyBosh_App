import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExamensBlancsPage extends StatefulWidget {
  const ExamensBlancsPage({super.key});

  @override
  State<ExamensBlancsPage> createState() => _ExamensBlancsPageState();
}

class _ExamensBlancsPageState extends State<ExamensBlancsPage> {
  String? _selectedSession;
  String? _selectedMatiere;
  String? _selectedEtablissement;

  final List<String> _sessions = ['Juin 2024', 'Mars 2024', 'Décembre 2023', 'Septembre 2023'];
  final List<String> _matieres = ['Toutes les matières', 'Mathématiques', 'Physique-Chimie', 'SVT', 'Philosophie'];
  final List<String> _etablissements = ['Tous les organisateurs', 'Plateforme Easybosh', 'Collège Libermann', 'Lycée de Mballa II'];

  late List<Map<String, String>> _epreuvesFiltrees;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _epreuvesFiltrees = _genererEpreuvesFactices();
    _searchController.addListener(_filterEpreuves);
  }

  List<Map<String, String>> _genererEpreuvesFactices() {
    return List.generate(
      10,
      (index) => {
        'titre': 'Examen Blanc #${index + 1} - ${_sessions[index % _sessions.length]}',
        'matiere': _matieres[(index + 1) % _matieres.length],
        'session': _sessions[index % _sessions.length],
        'etablissement': _etablissements[(index + 1) % _etablissements.length],
        'duree': '${(index % 4) + 1}h',
        'typeExamen': ['BEPC', 'Probatoire A', 'Probatoire C', 'Baccalauréat A', 'Baccalauréat C', 'Baccalauréat D'][index % 6],
      },
    );
  }

  void _filterEpreuves() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _epreuvesFiltrees = _genererEpreuvesFactices().where((epreuve) {
        final titreMatch = epreuve['titre']!.toLowerCase().contains(query);
        final matiereQueryMatch = epreuve['matiere']!.toLowerCase().contains(query);
        final etablissementQueryMatch = epreuve['etablissement']!.toLowerCase().contains(query);
        final typeQueryMatch = epreuve['typeExamen']!.toLowerCase().contains(query);

        final sessionFilterMatch = _selectedSession == null || epreuve['session'] == _selectedSession;
        final matiereFilterMatch = _selectedMatiere == null || _selectedMatiere == 'Toutes les matières' || epreuve['matiere'] == _selectedMatiere;
        final etablissementFilterMatch = _selectedEtablissement == null || _selectedEtablissement == 'Tous les organisateurs' || epreuve['etablissement'] == _selectedEtablissement;
        
        return (titreMatch || matiereQueryMatch || etablissementQueryMatch || typeQueryMatch) && sessionFilterMatch && matiereFilterMatch && etablissementFilterMatch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterEpreuves);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Examens Blancs',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFiltersRow(),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par titre, matière, type...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Disponibles Actuellement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildEpreuvesListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return SizedBox(
      height: 60, 
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildDropdownFilter(
            hint: 'Session',
            value: _selectedSession,
            items: _sessions,
            onChanged: (value) {
              setState(() {
                _selectedSession = value;
                _filterEpreuves();
              });
            },
            width: 110,
          ),
          const SizedBox(width: 12),
          _buildDropdownFilter(
            hint: 'Matière',
            value: _selectedMatiere,
            items: _matieres,
            onChanged: (value) {
              setState(() {
                _selectedMatiere = value;
                _filterEpreuves();
              });
            },
            width: 110,
          ),
          const SizedBox(width: 12),
          _buildDropdownFilter(
            hint: 'Organisateur',
            value: _selectedEtablissement,
            items: _etablissements,
            onChanged: (value) {
              setState(() {
                _selectedEtablissement = value;
                _filterEpreuves();
              });
            },
            width: 140,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String hint, // Ce "hint" sera utilisé pour InputDecoration.hintText
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    double width = 150,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        isDense: true,
        decoration: InputDecoration(
          hintText: hint, // Utilisation de hintText au lieu de labelText
          hintStyle: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), // Ajusté
          filled: true,
          fillColor: Colors.white,
          isDense: true,
        ),
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEpreuvesListView() {
    if (_epreuvesFiltrees.isEmpty) {
      return const Center(
        child: Text('Aucun examen blanc trouvé pour les filtres ou la recherche.'),
      );
    }
    return ListView.builder(
      itemCount: _epreuvesFiltrees.length,
      itemBuilder: (context, index) {
        final epreuve = _epreuvesFiltrees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(epreuve['titre']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    _buildInfoChip(Icons.event_note, epreuve['session']!, Colors.cyan),
                    _buildInfoChip(Icons.book, epreuve['matiere']!, Colors.orange),
                    _buildInfoChip(Icons.school, epreuve['etablissement']!, Colors.purple),
                    _buildInfoChip(Icons.assignment, epreuve['typeExamen']!, Colors.teal),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/epreuve_details', extra: epreuve);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text('Voir Détails'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
