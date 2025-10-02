import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Pour debugPrint

class FiltersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<NiveauSelectionItem>> getNiveaux() async {
    try {
      debugPrint("[FiltersService] getNiveaux: Début de la méthode.");
      final response = await _supabase
          .from('niveaux')
          .select('code, nom')
          .order('ordre', ascending: true);
      debugPrint("[FiltersService] getNiveaux: Réponse Supabase reçue, ${response.length} items.");
      final result = response
          .map((item) => NiveauSelectionItem(code: item['code'], nomDisplay: item['nom']))
          .toList();
      debugPrint("[FiltersService] getNiveaux: Mapping terminé, ${result.length} items mappés.");
      return result;
    } catch (e, stacktrace) {
      debugPrint('[FiltersService] getNiveaux: ERREUR CAPTURÉE: $e');
      debugPrint('[FiltersService] getNiveaux: STACKTRACE: $stacktrace');
      return []; 
    }
  }

  Future<List<SerieSelectionItem>> getSeriesForSelection() async {
    try {
      debugPrint("[FiltersService] getSeriesForSelection: Début de la méthode.");
      final response = await _supabase
          .from('series')
          .select('code, nom')
          .neq('code', 'TC') 
          .order('nom', ascending: true);
      debugPrint("[FiltersService] getSeriesForSelection: Réponse Supabase reçue, ${response.length} items.");
      final result = response
          .map((item) => SerieSelectionItem(code: item['code'], nomDisplay: item['nom']))
          .toList();
      debugPrint("[FiltersService] getSeriesForSelection: Mapping terminé, ${result.length} items mappés.");
      return result;
    } catch (e, stacktrace) {
      debugPrint('[FiltersService] getSeriesForSelection: ERREUR CAPTURÉE: $e');
      debugPrint('[FiltersService] getSeriesForSelection: STACKTRACE: $stacktrace');
      return [];
    }
  }

  Future<List<MatiereSelectionItem>> getAllMatieres() async {
    try {
      debugPrint("[FiltersService] getAllMatieres: Début de la méthode.");
      final response = await _supabase
          .from('matieres')
          .select('id, nom')
          .order('nom', ascending: true);
      // Note: Supabase retourne une List<Map<String, dynamic>>. Si la table est vide, c'est une liste vide.
      // Si RLS bloque, cela peut être une PostgrestException ou une liste vide selon la config.
      debugPrint("[FiltersService] getAllMatieres: Réponse Supabase reçue, nombre d'items: ${response.length}.");
      final result = response
          .map((item) => MatiereSelectionItem(id: item['id'] as int, nomDisplay: item['nom']))
          .toList();
      debugPrint("[FiltersService] getAllMatieres: Mapping terminé, ${result.length} items mappés.");
      return result;
    } catch (e, stacktrace) {
      debugPrint('[FiltersService] getAllMatieres: ERREUR CAPTURÉE: $e');
      debugPrint('[FiltersService] getAllMatieres: STACKTRACE: $stacktrace');
      return [];
    }
  }

  Future<List<int>> getMatiereIdsByNiveauAndSeries(
      String niveauCode, List<String> seriesCodes) async {
    if (niveauCode.isEmpty) return [];
    try {
      debugPrint("[FiltersService] getMatiereIdsByNiveauAndSeries: Début (niveau: $niveauCode, series: $seriesCodes).");
      var query = _supabase
          .from('matiere_niveau_serie')
          .select('matiere_id')
          .eq('niveau_code', niveauCode);

      if (seriesCodes.isNotEmpty) {
        query = query.inFilter('serie_code', seriesCodes);
      }
      // Pas besoin de 'else if (niveauCode != '3eme') return [];' ici, car si seriesCodes est vide pour non-3eme,
      // la requête Supabase sans .inFilter (ou avec .inFilter sur une liste vide) se comportera correctement
      // ou retournera une erreur si .inFilter avec liste vide n'est pas supporté (à vérifier, mais Supabase gère souvent bien ça).
      // La logique de filtrage dans le provider est déjà là pour retourner [] si seriesCodes est vide pour non-3eme.

      final response = await query;
      debugPrint("[FiltersService] getMatiereIdsByNiveauAndSeries: Réponse Supabase reçue, ${response.length} items.");
      final Set<int> matiereIds = response.map((item) => item['matiere_id'] as int).toSet();
      debugPrint("[FiltersService] getMatiereIdsByNiveauAndSeries: IDs mappés: $matiereIds.");
      return matiereIds.toList();
    } catch (e, stacktrace) {
      debugPrint('[FiltersService] getMatiereIdsByNiveauAndSeries: ERREUR CAPTURÉE: $e');
      debugPrint('[FiltersService] getMatiereIdsByNiveauAndSeries: STACKTRACE: $stacktrace');
      return [];
    }
  }
}
