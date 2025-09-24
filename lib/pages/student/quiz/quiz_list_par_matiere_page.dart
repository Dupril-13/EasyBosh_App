import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizListByMatierePage extends StatefulWidget {
  final String matiereNom;

  const QuizListByMatierePage({super.key, required this.matiereNom});

  @override
  State<QuizListByMatierePage> createState() => _QuizListByMatierePageState();
}

class _QuizListByMatierePageState extends State<QuizListByMatierePage> {
  String? _selectedChapitre;
  String? _selectedDifficulte;

  final List<String> _chapitres = ['Tous les chapitres', 'Chapitre 1: Algèbre', 'Chapitre 2: Géométrie', 'Chapitre 3: Fonctions'];
  final List<String> _difficultes = ['Toutes difficultés', 'Facile', 'Moyen', 'Difficile'];
  late List<Map<String, dynamic>> _quizFiltres;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quizFiltres = _genererQuizFactices();
    _searchController.addListener(_filterQuiz);
  }

  List<Map<String, dynamic>> _genererQuizFactices() {
    return List.generate(8, (index) {
      final chapitreIndex = index % (_chapitres.length - 1) + 1;
      final difficulteIndex = index % (_difficultes.length - 1) + 1;
      return {
        'titre': 'Quiz ${widget.matiereNom} - ${_chapitres[chapitreIndex]} #${index + 1}',
        'chapitre': _chapitres[chapitreIndex],
        'difficulte': _difficultes[difficulteIndex],
        'questions': (index % 3 + 1) * 5,
        'tempsEstime': '${(index % 3 + 1) * 5 + 5} min',
      };
    });
  }

  void _filterQuiz() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _quizFiltres = _genererQuizFactices().where((quiz) {
        final titreMatch = quiz['titre']!.toLowerCase().contains(query);
        final chapitreMatch = _selectedChapitre == null || _selectedChapitre == 'Tous les chapitres' || quiz['chapitre'] == _selectedChapitre;
        final difficulteMatch = _selectedDifficulte == null || _selectedDifficulte == 'Toutes difficultés' || quiz['difficulte'] == _selectedDifficulte;
        return titreMatch && chapitreMatch && difficulteMatch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterQuiz);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz de ${widget.matiereNom}'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/quiz_par_matiere_selection');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFiltersRow(),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un quiz...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quiz disponibles en ${widget.matiereNom}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildQuizListView(),
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
            hint: 'Chapitre',
            value: _selectedChapitre,
            items: _chapitres,
            onChanged: (value) {
              setState(() {
                _selectedChapitre = value;
                _filterQuiz();
              });
            },
            width: 150, // Réduit de 180
          ),
          const SizedBox(width: 12),
          _buildDropdownFilter(
            hint: 'Difficulté',
            value: _selectedDifficulte,
            items: _difficultes,
            onChanged: (value) {
              setState(() {
                _selectedDifficulte = value;
                _filterQuiz();
              });
            },
            width: 130, // Réduit de 150
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
    double width = 150,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  Widget _buildQuizListView() {
    if (_quizFiltres.isEmpty) {
      return const Center(
        child: Text('Aucun quiz trouvé pour les filtres ou la recherche.'),
      );
    }
    return ListView.builder(
      itemCount: _quizFiltres.length,
      itemBuilder: (context, index) {
        final quiz = _quizFiltres[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz['titre']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    _buildInfoChip(Icons.library_books, quiz['chapitre']!, Colors.teal),
                    _buildInfoChip(Icons.leaderboard, quiz['difficulte']!, Colors.orange),
                    _buildInfoChip(Icons.question_answer, '${quiz['questions']} questions', Colors.blue),
                    _buildInfoChip(Icons.timer_outlined, quiz['tempsEstime']!, Colors.purple),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      // Correction ici pour utiliser la navigation définie dans app_router.dart
                      context.go('/quiz_play', extra: quiz);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text('Commencer le Quiz'),
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
