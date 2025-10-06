import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/matiere_model.dart';
import '../../../providers/quiz_list_provider.dart';
import '../../../providers/auth_provider.dart';

class QuizListByMatierePage extends ConsumerStatefulWidget {
  final MatiereModel matiere;

  const QuizListByMatierePage({super.key, required this.matiere});

  @override
  ConsumerState<QuizListByMatierePage> createState() => _QuizListByMatierePageState();
}

class _QuizListByMatierePageState extends ConsumerState<QuizListByMatierePage> {
  String? _selectedChapitre;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Charger les quiz au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuizzes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadQuizzes() async {
    final authState = ref.read(authProvider);
    final user = (authState is AuthAuthenticated) ? authState.user : null;

    if (user == null) return;

    await ref.read(quizListProvider.notifier).fetchQuizzes(
      niveauCode: user.studentLevelCode,
      serieCode: user.studentSerieCode,
      matiereId: widget.matiere.id,
    );
  }

  List<int> _getAvailableChapitres() {
    final quizState = ref.watch(quizListProvider);
    final chapitreIds = quizState.quizzes
        .where((quiz) => quiz.chapitreId != null)
        .map((quiz) => quiz.chapitreId!)
        .toSet()
        .toList();
    chapitreIds.sort();
    return chapitreIds;
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizListProvider);
    final availableChapitres = _getAvailableChapitres();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Quiz ${widget.matiere.nom}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un quiz...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Filtre par chapitre (si plusieurs chapitres disponibles)
            if (availableChapitres.length > 1)
              _buildChapitreFilter(availableChapitres),

            const SizedBox(height: 12),

            // Texte d'en-tête
            Text(
              'Quiz disponibles',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Liste des quiz
            Expanded(
              child: _buildQuizListView(quizState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapitreFilter(List<int> availableChapitres) {
    return Container(
      height: 50,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Chapitre',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
        ),
        value: _selectedChapitre,
        hint: const Text('Tous les chapitres', style: TextStyle(fontSize: 14)),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Tous les chapitres', style: TextStyle(fontSize: 14)),
          ),
          ...availableChapitres.map((chapitreId) {
            return DropdownMenuItem<String>(
              value: chapitreId.toString(),
              child: Text(
                'Chapitre $chapitreId',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ],
        onChanged: (value) {
          setState(() {
            _selectedChapitre = value;
          });
        },
      ),
    );
  }

  Widget _buildQuizListView(QuizListState quizState) {
    // Loading
    if (quizState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Erreur
    if (quizState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              quizState.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadQuizzes,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // Filtrer les quiz
    final filteredQuizzes = quizState.quizzes.where((quiz) {
      // Filtre chapitre
      if (_selectedChapitre != null &&
          quiz.chapitreId?.toString() != _selectedChapitre) {
        return false;
      }

      // Filtre recherche
      if (_searchQuery.isNotEmpty &&
          !quiz.nom.toLowerCase().contains(_searchQuery)) {
        return false;
      }

      return true;
    }).toList();

    // Aucun quiz
    if (filteredQuizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedChapitre != null
                  ? 'Aucun quiz trouvé pour les filtres sélectionnés.'
                  : 'Aucun quiz disponible pour cette matière.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Liste des quiz
    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      child: ListView.builder(
        itemCount: filteredQuizzes.length,
        itemBuilder: (context, index) {
          final quiz = filteredQuizzes[index];
          return _buildQuizCard(quiz);
        },
      ),
    );
  }

  Widget _buildQuizCard(quiz) {
    // Calculer la durée estimée
    final dureeText = quiz.tempsLimite != null
        ? '${quiz.tempsLimite} min'
        : 'Pas de limite';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          // Navigation vers la page de passage du quiz
          context.push('/quiz_play', extra: quiz);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre du quiz
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Badge "Nouveau" si créé dans les 7 derniers jours
                  if (_isNew(quiz.createdAt))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Nouveau',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              if (quiz.description != null && quiz.description!.isNotEmpty)
                Text(
                  quiz.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Informations (questions, temps, feedback)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  _buildInfoChip(
                    Icons.question_answer,
                    '${quiz.nombreQuestions} questions',
                    Colors.blue,
                  ),
                  _buildInfoChip(
                    Icons.timer_outlined,
                    dureeText,
                    Colors.purple,
                  ),
                  if (quiz.feedbackImmediat)
                    _buildInfoChip(
                      Icons.check_circle_outline,
                      'Feedback immédiat',
                      Colors.orange,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  bool _isNew(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays <= 7;
  }
}