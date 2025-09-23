import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnciensSujetsPage extends StatefulWidget {
  const AnciensSujetsPage({super.key});

  @override
  State<AnciensSujetsPage> createState() => _AnciensSujetsPageState();
}

class _AnciensSujetsPageState extends State<AnciensSujetsPage> {
  String? _selectedSession;
  String? _selectedSerie;
  String? _selectedMatiere;

  final List<String> _sessions = ['2023', '2022', '2021', '2020', '2019', '2018'];
  final List<String> _series = ['A', 'C', 'D', 'TI', 'SES', 'L'];
  final List<String> _matieres = ['Mathématiques', 'Physique', 'Chimie', 'SVT', 'Français', 'Philosophie', 'Anglais', 'Histoire-Géo'];

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
      15,
      (index) => {
        'titre': 'Sujet Examen ${2023 - index % 6} - ${String.fromCharCode(65 + index % 5)}${index + 1}',
        'matiere': _matieres[index % _matieres.length],
        'annee': _sessions[index % _sessions.length],
        'serie': _series[index % _series.length],
        'duree': '${(index % 3) + 2}h',
      },
    );
  }

  void _filterEpreuves() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _epreuvesFiltrees = _genererEpreuvesFactices().where((epreuve) {
        final titreMatch = epreuve['titre']!.toLowerCase().contains(query);
        final matiereMatch = epreuve['matiere']!.toLowerCase().contains(query);
        final sessionMatch = _selectedSession == null || epreuve['annee'] == _selectedSession;
        final serieMatch = _selectedSerie == null || epreuve['serie'] == _selectedSerie;
        final matiereFilterMatch = _selectedMatiere == null || epreuve['matiere'] == _selectedMatiere;
        return (titreMatch || matiereMatch) && sessionMatch && serieMatch && matiereFilterMatch;
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Anciens Sujets',
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
                hintText: 'Rechercher un sujet, matière...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Épreuves Disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
      height: 60, // Hauteur pour les DropdownButtonFormField
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
          ),
          const SizedBox(width: 12),
          _buildDropdownFilter(
            hint: 'Série',
            value: _selectedSerie,
            items: _series,
            onChanged: (value) {
              setState(() {
                _selectedSerie = value;
                _filterEpreuves();
              });
            },
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
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: 140, // Largeur fixe pour chaque filtre
      padding: const EdgeInsets.symmetric(vertical: 4), // Espace vertical
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
        ),
        value: value,
        hint: Text(hint, style: const TextStyle(fontSize: 14)),
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
        child: Text('Aucune épreuve trouvée pour les filtres ou la recherche.'),
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
                Row(
                  children: [
                    _buildInfoChip(Icons.calendar_today, epreuve['annee']!, Colors.blueGrey),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.library_books, epreuve['serie']!, Colors.teal),
                    const SizedBox(width: 8),
                    Flexible(child: _buildInfoChip(Icons.subject, epreuve['matiere']!, Colors.orange)),
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
                    child: const Text('Voir'),
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
