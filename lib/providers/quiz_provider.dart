
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/option_reponse_model.dart';
import '../models/matiere_model.dart';

// Provider pour le client Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

// Provider pour lister les matières qui ont des quiz
final matieresWithQuizzesProvider = FutureProvider<List<MatiereModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  
  // Astuce : Utiliser une vue ou une fonction RPC dans Supabase serait plus performant.
  // Pour l'instant, on récupère les quiz puis on déduit les matières.
  final quizResponse = await client.from('quiz').select('matiere_id').eq('actif', true);
  
  final matiereIds = (quizResponse as List).map((data) => data['matiere_id'] as int?).where((id) => id != null).toSet().toList();

  if (matiereIds.isEmpty) {
    return [];
  }

  final matieresResponse = await client.from('matieres').select().inFilter('id', matiereIds);

  return (matieresResponse as List).map((data) => MatiereModel.fromMap(data)).toList();
});


// Provider pour lister les Quizzes par matière
final quizListProvider = FutureProvider.family<List<QuizModel>, int>((ref, matiereId) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('quiz')
      .select()
      .eq('matiere_id', matiereId)
      .eq('actif', true);

  final quizzes = (response as List).map((data) => QuizModel.fromMap(data)).toList();
  return quizzes;
});

// Provider pour charger les détails d'un Quiz (questions et options)
final quizDetailProvider = FutureProvider.family<List<QuestionModel>, int>((ref, quizId) async {
  final client = ref.watch(supabaseClientProvider);

  // 1. Récupérer les questions
  final questionsResponse = await client
      .from('questions')
      .select()
      .eq('quiz_id', quizId)
      .order('ordre', ascending: true);

  final questions = (questionsResponse as List).map((data) => QuestionModel.fromMap(data, [])).toList();
  final questionIds = questions.map((q) => q.id).toList();

  if (questionIds.isEmpty) {
    return [];
  }

  // 2. Récupérer les options pour ces questions
  final optionsResponse = await client
      .from('options_reponse')
      .select()
      .inFilter('question_id', questionIds)
      .order('ordre', ascending: true);

  final options = (optionsResponse as List).map((data) => OptionReponseModel.fromMap(data)).toList();

  // 3. Associer les options aux questions
  final questionsWithOptions = questions.map((question) {
    final questionOptions = options.where((opt) => opt.questionId == question.id).toList();
    return QuestionModel(
      id: question.id,
      quizId: question.quizId,
      texte: question.texte,
      type: question.type,
      ordre: question.ordre,
      points: question.points,
      explication: question.explication,
      imageUrl: question.imageUrl,
      options: questionOptions,
    );
  }).toList();

  return questionsWithOptions;
});
