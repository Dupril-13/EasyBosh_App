import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_session_model.dart';
import '../models/question_model.dart';

class QuizSessionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Crée une nouvelle session de quiz pour un élève
  Future<QuizSessionModel> createSession(int quizId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Compter les tentatives précédentes
      final previousSessions = await _client
          .from('quiz_sessions')
          .select()
          .eq('user_id', currentUser.id)
          .eq('quiz_id', quizId);

      final tentativeNumber = (previousSessions as List).length + 1;

      final sessionData = {
        'user_id': currentUser.id,
        'quiz_id': quizId,
        'tentative': tentativeNumber,
        'score': 0,
        'temps_passe': 0,
        'termine': false,
        'reponses_utilisateur': {},
      };

      final response = await _client
          .from('quiz_sessions')
          .insert(sessionData)
          .select()
          .single();

      return QuizSessionModel.fromMap(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (createSession): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (createSession): $e');
    }
  }

  /// Sauvegarde la progression (auto-save pendant le quiz)
  Future<void> saveProgress(
      int sessionId,
      Map<String, dynamic> reponsesUtilisateur,
      int tempsPasse,
      ) async {
    try {
      await _client.from('quiz_sessions').update({
        'reponses_utilisateur': reponsesUtilisateur,
        'temps_passe': tempsPasse,
      }).eq('id', sessionId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (saveProgress): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (saveProgress): $e');
    }
  }

  /// Soumet le quiz et calcule le score final
  Future<QuizSessionModel> submitSession(
      int sessionId,
      Map<String, dynamic> reponsesUtilisateur,
      int tempsPasse,
      List<QuestionModel> questions,
      ) async {
    try {
      // Calculer le score
      final scoreResult = _calculateScore(reponsesUtilisateur, questions);

      final updateData = {
        'reponses_utilisateur': reponsesUtilisateur,
        'temps_passe': tempsPasse,
        'score': scoreResult['score'],
        'note_sur_bareme_quiz': scoreResult['note_sur_20'],
        'termine': true,
        'reussi': scoreResult['reussi'],
        'completed_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('quiz_sessions')
          .update(updateData)
          .eq('id', sessionId)
          .select()
          .single();

      return QuizSessionModel.fromMap(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (submitSession): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (submitSession): $e');
    }
  }

  /// Calcule le score selon la logique définie
  Map<String, dynamic> _calculateScore(
      Map<String, dynamic> reponsesUtilisateur,
      List<QuestionModel> questions,
      ) {
    double totalPoints = 0;
    double pointsObtenus = 0;

    for (final question in questions) {
      totalPoints += question.points;

      final userAnswers = reponsesUtilisateur[question.id.toString()];
      if (userAnswers == null) continue;

      final correctOptionIds = question.options
          .where((opt) => opt.estCorrecte)
          .map((opt) => opt.id)
          .toSet();

      Set<int> userSelectedIds = {};

      if (userAnswers is List) {
        userSelectedIds = userAnswers.map((e) => e as int).toSet();
      } else if (userAnswers is int) {
        userSelectedIds = {userAnswers};
      }

      final incorrectOptionIds = question.options
          .where((opt) => !opt.estCorrecte)
          .map((opt) => opt.id)
          .toSet();

      final hasIncorrectAnswer =
      userSelectedIds.any((id) => incorrectOptionIds.contains(id));

      if (hasIncorrectAnswer) continue;

      final correctAnswersFound =
      userSelectedIds.intersection(correctOptionIds);
      if (correctAnswersFound.isEmpty) continue;

      final proportionCorrect =
          correctAnswersFound.length / correctOptionIds.length;
      pointsObtenus += question.points * proportionCorrect;
    }

    final noteSur20 = totalPoints > 0 ? (pointsObtenus / totalPoints) * 20 : 0;

    return {
      'score': pointsObtenus,
      'total_points': totalPoints,
      'note_sur_20': noteSur20,
      'reussi': noteSur20 >= 10,
    };
  }

  /// Récupère les sessions d'un élève pour un quiz donné
  Future<List<QuizSessionModel>> fetchUserSessions(int quizId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final response = await _client
          .from('quiz_sessions')
          .select()
          .eq('user_id', currentUser.id)
          .eq('quiz_id', quizId)
          .order('tentative', ascending: false);

      return (response as List)
          .map((item) =>
          QuizSessionModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (fetchUserSessions): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (fetchUserSessions): $e');
    }
  }

  /// Récupère une session spécifique par son ID
  Future<QuizSessionModel> fetchSessionById(int sessionId) async {
    try {
      final response = await _client
          .from('quiz_sessions')
          .select()
          .eq('id', sessionId)
          .single();

      return QuizSessionModel.fromMap(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (fetchSessionById): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (fetchSessionById): $e');
    }
  }

  /// Récupère la meilleure session d'un élève pour un quiz
  Future<QuizSessionModel?> fetchBestSession(int quizId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final response = await _client
          .from('quiz_sessions')
          .select()
          .eq('user_id', currentUser.id)
          .eq('quiz_id', quizId)
          .eq('termine', true)
          .order('score', ascending: false)
          .limit(1);

      final list = response as List;
      if (list.isEmpty) return null;

      return QuizSessionModel.fromMap(list.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (fetchBestSession): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (fetchBestSession): $e');
    }
  }

  /// Vérifie si l'élève a une session en cours (non terminée)
  Future<QuizSessionModel?> fetchOngoingSession(int quizId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final response = await _client
          .from('quiz_sessions')
          .select()
          .eq('user_id', currentUser.id)
          .eq('quiz_id', quizId)
          .eq('termine', false)
          .order('started_at', ascending: false)
          .limit(1);

      final list = response as List;
      if (list.isEmpty) return null;

      return QuizSessionModel.fromMap(list.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (fetchOngoingSession): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (fetchOngoingSession): $e');
    }
  }
}