import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/option_reponse_model.dart';

class QuizService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Récupère les quiz filtrés (pour élèves)
  /// Seuls les quiz actifs sont retournés
  Future<List<QuizModel>> fetchQuizForStudent({
    String? niveauCode,
    String? serieCode,
    int? matiereId,
    int? chapitreId,
  }) async {
    try {
      var query = _client.from('quiz').select();

      // Filtres obligatoires pour élèves
      query = query.eq('actif', true);

      if (niveauCode != null) {
        query = query.eq('niveau_code', niveauCode);
      }
      if (serieCode != null) {
        query = query.eq('serie_code', serieCode);
      }
      if (matiereId != null) {
        query = query.eq('matiere_id', matiereId);
      }
      if (chapitreId != null) {
        query = query.eq('chapitre_id', chapitreId);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((item) => QuizModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (fetchQuizForStudent): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (fetchQuizForStudent): $e');
    }
  }

  /// Récupère les quiz pour enseignants (tous les quiz, actifs ou non)
  Future<List<QuizModel>> fetchQuizForTeacher({
    String? niveauCode,
    String? serieCode,
    int? matiereId,
    int? chapitreId,
    String? createdBy,
  }) async {
    try {
      var query = _client.from('quiz').select();

      if (niveauCode != null) {
        query = query.eq('niveau_code', niveauCode);
      }
      if (serieCode != null) {
        query = query.eq('serie_code', serieCode);
      }
      if (matiereId != null) {
        query = query.eq('matiere_id', matiereId);
      }
      if (chapitreId != null) {
        query = query.eq('chapitre_id', chapitreId);
      }
      if (createdBy != null) {
        query = query.eq('created_by', createdBy);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((item) => QuizModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (fetchQuizForTeacher): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (fetchQuizForTeacher): $e');
    }
  }

  /// Récupère un quiz par son ID avec ses questions et options
  Future<QuizModel> fetchQuizById(int quizId) async {
    try {
      final quizResponse = await _client
          .from('quiz')
          .select()
          .eq('id', quizId)
          .single();

      return QuizModel.fromMap(quizResponse as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (fetchQuizById): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (fetchQuizById): $e');
    }
  }

  /// Récupère les questions d'un quiz avec leurs options
  Future<List<QuestionModel>> fetchQuestionsWithOptions(int quizId) async {
    try {
      final questionsResponse = await _client
          .from('questions')
          .select('*, options_reponse(*)')
          .eq('quiz_id', quizId)
          .order('ordre', ascending: true);

      return (questionsResponse as List).map((item) {
        final questionMap = Map<String, dynamic>.from(item);

        // Parser les options
        if (questionMap['options_reponse'] != null) {
          questionMap['options'] = questionMap['options_reponse'];
          questionMap.remove('options_reponse');
        }

        return QuestionModel.fromMap(questionMap);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (fetchQuestionsWithOptions): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (fetchQuestionsWithOptions): $e');
    }
  }

  /// Crée un nouveau quiz (enseignant)
  Future<QuizModel> createQuiz(QuizModel quiz) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final quizData = quiz.toMapForInsert();
      quizData['created_by'] = currentUser.id;

      final response = await _client
          .from('quiz')
          .insert(quizData)
          .select()
          .single();

      return QuizModel.fromMap(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (createQuiz): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (createQuiz): $e');
    }
  }

  /// Met à jour un quiz existant
  Future<QuizModel> updateQuiz(QuizModel quiz) async {
    try {
      final response = await _client
          .from('quiz')
          .update(quiz.toMap())
          .eq('id', quiz.id)
          .select()
          .single();

      return QuizModel.fromMap(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (updateQuiz): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (updateQuiz): $e');
    }
  }

  /// Supprime un quiz
  Future<void> deleteQuiz(int quizId) async {
    try {
      await _client.from('quiz').delete().eq('id', quizId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (deleteQuiz): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (deleteQuiz): $e');
    }
  }

  /// Active ou désactive un quiz
  Future<void> toggleQuizStatus(int quizId, bool actif) async {
    try {
      await _client
          .from('quiz')
          .update({'actif': actif})
          .eq('id', quizId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (toggleQuizStatus): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (toggleQuizStatus): $e');
    }
  }
}
