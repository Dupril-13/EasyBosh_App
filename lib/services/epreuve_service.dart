import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EpreuveService {
  final SupabaseClient _supabaseClient;

  EpreuveService(this._supabaseClient);

  Future<List<Epreuve>> fetchFilteredEpreuves({
    String? niveauCode,
    String? serieCode,
    int? matiereId,
    EpreuveType? epreuveType,
    EpreuveStatut? epreuveStatut,
  }) async {
    try {
      print(
          "EpreuveService: Fetching epreuves with filters: N:$niveauCode, S:$serieCode, M:$matiereId, T:$epreuveType, ST:$epreuveStatut");

      // Start with PostgrestQueryBuilder
      var request = _supabaseClient.from('epreuves').select();

      if (niveauCode != null && niveauCode.isNotEmpty) {
        // .eq() returns PostgrestFilterBuilder
        request = request.eq('niveau_code', niveauCode);
      }
      if (serieCode != null && serieCode.isNotEmpty) {
        // .filter() can be chained on PostgrestFilterBuilder or PostgrestQueryBuilder
        // Ensure the type of 'request' remains compatible or use dynamic if necessary,
        // but here it should correctly chain and return PostgrestFilterBuilder.
        request = request.filter('series_codes', 'cs', '{${serieCode}}'); 
      }
      if (matiereId != null) {
        request = request.eq('matiere_id', matiereId);
      }
      if (epreuveType != null) {
        request = request.eq('type', Epreuve.typeToString(epreuveType));
      }
      if (epreuveStatut != null) {
        request = request.eq('statut', Epreuve.statutToString(epreuveStatut));
      }

      // .order() is called on the result of the filtering, which could be PostgrestFilterBuilder
      // and it returns PostgrestTransformBuilder. This is fine before await.
      final response = await request.order('created_at', ascending: false);

      return response.map((map) => Epreuve.fromMap(map)).toList();

    } catch (e) {
      print('Error fetching filtered epreuves: $e');
      return []; 
    }
  }
}

final epreuveServiceProvider = Provider<EpreuveService>((ref) {
  final supabaseClient = Supabase.instance.client;
  return EpreuveService(supabaseClient);
});
