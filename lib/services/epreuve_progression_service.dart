import 'package:supabase_flutter/supabase_flutter.dart';

// Modèle de progression d'épreuve
class EpreuveProgressionModel {
  final int id;
  final int epreuveId;
  final String userId;
  final bool commenced;
  final bool termine;
  final int? tempsPasse; // en secondes
  final double? score;
  final String statut; // 'en_cours', 'soumis', 'corrige', 'annule'
  final DateTime? startedAt;
  final DateTime? submittedAt;

  EpreuveProgressionModel({
    required this.id,
    required this.epreuveId,
    required this.userId,
    required this.commenced,
    required this.termine,
    this.tempsPasse,
    this.score,
    required this.statut,
    this.startedAt,
    this.submittedAt,
  });

  factory EpreuveProgressionModel.fromMap(Map<String, dynamic> map) {
    return EpreuveProgressionModel(
      id: map['id'] as int,
      epreuveId: map['epreuve_id'] as int,
      userId: map['user_id'] as String,
      commenced: map['statut'] != null && map['statut'] != 'nouveau',
      termine: map['statut'] == 'soumis' || map['statut'] == 'corrige',
      tempsPasse: map['temps_passe'] as int?,
      score: map['score'] != null ? (map['score'] as num).toDouble() : null,
      statut: map['statut'] as String,
      startedAt: map['started_at'] != null ? DateTime.parse(map['started_at'] as String) : null,
      submittedAt: map['submitted_at'] != null ? DateTime.parse(map['submitted_at'] as String) : null,
    );
  }
}

class EpreuveProgressionService {
  final SupabaseClient _client;

  EpreuveProgressionService(this._client);

  // Récupérer toutes les progressions d'un utilisateur
  Future<List<EpreuveProgressionModel>> getUserProgressions(String userId) async {
    try {
      final response = await _client
          .from('epreuve_soumissions')
          .select()
          .eq('user_id', userId);

      return (response as List).map((e) => EpreuveProgressionModel.fromMap(e)).toList();
    } on PostgrestException catch (e) {
      print('Erreur Postgrest getUserProgressions: ${e.message}');
      throw Exception('Erreur lors de la récupération des progressions: ${e.message}');
    } catch (e) {
      print('Erreur getUserProgressions: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Démarrer une épreuve
  Future<void> startEpreuve(int epreuveId, String userId) async {
    try {
      // Vérifier si l'épreuve n'est pas déjà commencée
      final existing = await _client
          .from('epreuve_soumissions')
          .select()
          .eq('epreuve_id', epreuveId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        print('Épreuve déjà commencée');
        return;
      }

      await _client.from('epreuve_soumissions').insert({
        'epreuve_id': epreuveId,
        'user_id': userId,
        'statut': 'en_cours',
        'started_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      print('Erreur Postgrest startEpreuve: ${e.message}');
      throw Exception('Erreur lors du démarrage de l\'épreuve: ${e.message}');
    } catch (e) {
      print('Erreur startEpreuve: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Soumettre une épreuve
  Future<void> submitEpreuve(int epreuveId, String userId, int tempsPasse) async {
    try {
      await _client
          .from('epreuve_soumissions')
          .update({
        'statut': 'soumis',
        'temps_passe': tempsPasse,
        'submitted_at': DateTime.now().toIso8601String(),
      })
          .eq('epreuve_id', epreuveId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      print('Erreur Postgrest submitEpreuve: ${e.message}');
      throw Exception('Erreur lors de la soumission: ${e.message}');
    } catch (e) {
      print('Erreur submitEpreuve: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }
}