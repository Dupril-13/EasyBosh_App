import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final epreuveServiceProvider = Provider<EpreuveService>((ref) {
  return EpreuveService(Supabase.instance.client);
});

class EpreuveService {
  final SupabaseClient _client;

  EpreuveService(this._client);

  Future<Epreuve> getEpreuveById(int epreuveId) async {
    try {
      final data = await _client
          .from('epreuves')
          .select('*, matieres(nom), niveaux(nom)')
          .eq('id', epreuveId)
          .single();
      return Epreuve.fromMap(data);
    } on PostgrestException catch (e) {
      print('Postgrest error fetching epreuve by id: ${e.message}');
      throw Exception('Erreur base de données (get by id): ${e.message}');
    } catch (e) {
      print('Generic error fetching epreuve by id: ${e.toString()}');
      throw Exception('Erreur inattendue (get by id).');
    }
  }

  Future<void> updateEpreuve(
    int epreuveId,
    Map<String, dynamic> epreuveData,
    PlatformFile? sujetFile,
    PlatformFile? corrigeFile,
  ) async {
    try {
      // 1. Mettre à jour les métadonnées de l'épreuve
      await _client.from('epreuves').update(epreuveData).eq('id', epreuveId);

      String? sujetUrl;
      if (sujetFile != null && sujetFile.bytes != null) {
        final sujetPath = '$epreuveId/sujet.pdf';
        await _client.storage.from('epreuves').uploadBinary(
              sujetPath,
              sujetFile.bytes!,
              fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
            );
        sujetUrl = _client.storage.from('epreuves').getPublicUrl(sujetPath);
      }

      String? corrigeUrl;
      if (corrigeFile != null && corrigeFile.bytes != null) {
        final corrigePath = '$epreuveId/corrige.pdf';
        await _client.storage.from('epreuves').uploadBinary(
              corrigePath,
              corrigeFile.bytes!,
              fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
            );
        corrigeUrl = _client.storage.from('epreuves').getPublicUrl(corrigePath);
      }

      // 2. Mettre à jour les URLs des fichiers si de nouveaux fichiers ont été uploadés
      final Map<String, dynamic> urlUpdates = {};
      if (sujetUrl != null) urlUpdates['fichier_url'] = sujetUrl;
      if (corrigeUrl != null) urlUpdates['corrige_url'] = corrigeUrl;

      if (urlUpdates.isNotEmpty) {
        await _client.from('epreuves').update(urlUpdates).eq('id', epreuveId);
      }

    } on PostgrestException catch (e) {
      print('Postgrest error updating epreuve: ${e.message}');
      throw Exception('Erreur base de données (mise à jour): ${e.message}');
    } catch (e) {
      print('Generic error updating epreuve: ${e.toString()}');
      throw Exception('Erreur inattendue (mise à jour): ${e.toString()}');
    }
  }


  Future<void> deleteEpreuve(int epreuveId) async {
    try {
      // TODO: Supprimer les fichiers du storage avant de supprimer la ligne
      await _client.from('epreuves').delete().eq('id', epreuveId);
    } on PostgrestException catch (e) {
      print('Postgrest error deleting epreuve: ${e.message}');
      throw Exception('Erreur base de données lors de la suppression: ${e.message}');
    } catch (e) {
      print('Generic error deleting epreuve: ${e.toString()}');
      throw Exception('Une erreur inattendue est survenue lors de la suppression.');
    }
  }

  Future<void> createEpreuve(
    Map<String, dynamic> epreuveData,
    PlatformFile sujetFile,
    PlatformFile? corrigeFile,
  ) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié.');
      }
      epreuveData['created_by'] = currentUser.id;

      final newEpreuve = await _client
          .from('epreuves')
          .insert(epreuveData)
          .select('id')
          .single();

      final epreuveId = newEpreuve['id'];

      final sujetPath = '$epreuveId/sujet.pdf';
      await _client.storage.from('epreuves').uploadBinary(
            sujetPath,
            sujetFile.bytes!,
            fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
          );

      String? corrigePath;
      if (corrigeFile != null && corrigeFile.bytes != null) {
        corrigePath = '$epreuveId/corrige.pdf';
        await _client.storage.from('epreuves').uploadBinary(
              corrigePath,
              corrigeFile.bytes!,
              fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
            );
      }

      final sujetUrl = _client.storage.from('epreuves').getPublicUrl(sujetPath);
      final corrigeUrl = corrigePath != null ? _client.storage.from('epreuves').getPublicUrl(corrigePath) : null;

      await _client.from('epreuves').update({
        'fichier_url': sujetUrl,
        'corrige_url': corrigeUrl,
      }).eq('id', epreuveId);

    } on PostgrestException catch (e) {
      print('Postgrest error creating epreuve: ${e.message}');
      throw Exception('Erreur base de données: ${e.message}');
    } catch (e) {
      print('Generic error creating epreuve: ${e.toString()}');
      throw Exception('Une erreur inattendue est survenue: ${e.toString()}');
    }
  }

  Future<List<Epreuve>> fetchFilteredEpreuves({
    String? niveauCode,
    String? serieCode,
    int? matiereId,
    EpreuveType? epreuveType,
    EpreuveStatut? epreuveStatut,
  }) async {
    try {
      var query = _client.from('epreuves').select(
        '*, matiere_id, niveau_code, series_codes, matieres(nom), niveaux(nom)'
      );

      if (niveauCode != null) {
        query = query.eq('niveau_code', niveauCode);
      }
      if (serieCode != null) {
        query = query.contains('series_codes', [serieCode]);
      }
      if (matiereId != null) {
        query = query.eq('matiere_id', matiereId);
      }
      if (epreuveType != null) {
        query = query.eq('type', Epreuve.typeToString(epreuveType));
      }
      if (epreuveStatut != null) {
        query = query.eq('statut', Epreuve.statutToString(epreuveStatut));
      }

      final data = await query.order('created_at', ascending: false);
      
      return (data as List).map((row) => Epreuve.fromMap(row)).toList();

    } on PostgrestException catch (e) {
        print('Postgrest error fetching epreuves: ${e.message}');
        throw Exception('Erreur base de données: ${e.message}');
    } catch (e) {
        print('Generic error fetching epreuves: ${e.toString()}');
        throw Exception('Une erreur inattendue est survenue.');
    }
  }
}
