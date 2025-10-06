import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import '../models/option_reponse_model.dart';

class QuestionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Crée une question avec ses options
  Future<QuestionModel> createQuestionWithOptions(
      QuestionModel question,
      List<OptionReponseModel> options,
      ) async {
    try {
      // 1. Créer la question
      final questionResponse = await _client
          .from('questions')
          .insert(question.toMapForInsert())
          .select()
          .single();

      final createdQuestion = QuestionModel.fromMap(
        questionResponse as Map<String, dynamic>,
      );

      // 2. Créer les options
      if (options.isNotEmpty) {
        final optionsData = options.map((opt) {
          final optMap = opt.toMapForInsert();
          optMap['question_id'] = createdQuestion.id;
          return optMap;
        }).toList();

        await _client.from('options_reponse').insert(optionsData);
      }

      // 3. Récupérer la question avec ses options
      return await _fetchQuestionWithOptions(createdQuestion.id);
    } on PostgrestException catch (e) {
      throw Exception(
          'Erreur PostgreSQL (createQuestionWithOptions): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (createQuestionWithOptions): $e');
    }
  }

  /// Met à jour une question
  Future<QuestionModel> updateQuestion(QuestionModel question) async {
    try {
      final response = await _client
          .from('questions')
          .update(question.toMap())
          .eq('id', question.id)
          .select()
          .single();

      return QuestionModel.fromMap(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (updateQuestion): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (updateQuestion): $e');
    }
  }

  /// Supprime une question (et ses options via CASCADE)
  Future<void> deleteQuestion(int questionId) async {
    try {
      await _client.from('questions').delete().eq('id', questionId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (deleteQuestion): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (deleteQuestion): $e');
    }
  }

  /// Met à jour les options d'une question
  Future<void> updateOptions(
      int questionId,
      List<OptionReponseModel> options,
      ) async {
    try {
      // 1. Supprimer les anciennes options
      await _client
          .from('options_reponse')
          .delete()
          .eq('question_id', questionId);

      // 2. Insérer les nouvelles options
      if (options.isNotEmpty) {
        final optionsData = options.map((opt) {
          final optMap = opt.toMapForInsert();
          optMap['question_id'] = questionId;
          return optMap;
        }).toList();

        await _client.from('options_reponse').insert(optionsData);
      }
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (updateOptions): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (updateOptions): $e');
    }
  }

  /// Récupère une question avec ses options
  Future<QuestionModel> _fetchQuestionWithOptions(int questionId) async {
    final response = await _client
        .from('questions')
        .select('*, options_reponse(*)')
        .eq('id', questionId)
        .single();

    final questionMap = Map<String, dynamic>.from(response);
    if (questionMap['options_reponse'] != null) {
      questionMap['options'] = questionMap['options_reponse'];
      questionMap.remove('options_reponse');
    }

    return QuestionModel.fromMap(questionMap);
  }

  /// Réorganise l'ordre des questions d'un quiz
  Future<void> reorderQuestions(List<QuestionModel> questions) async {
    try {
      for (int i = 0; i < questions.length; i++) {
        await _client
            .from('questions')
            .update({'ordre': i})
            .eq('id', questions[i].id);
      }
    } on PostgrestException catch (e) {
      throw Exception('Erreur PostgreSQL (reorderQuestions): ${e.message}');
    } catch (e) {
      throw Exception('Erreur inattendue (reorderQuestions): $e');
    }
  }
}