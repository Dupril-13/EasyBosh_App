import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:easybosh_v2/main.dart'; // Pour supabaseClientProvider

class LeconState {
  final List<LeconModel> lecons;
  final LeconModel? leconPourEdition;
  final bool isLoading;
  final String? errorMessage;

  LeconState({
    this.lecons = const [],
    this.leconPourEdition,
    this.isLoading = false,
    this.errorMessage,
  });

  LeconState copyWith({
    List<LeconModel>? lecons,
    LeconModel? leconPourEdition,
    bool? isLoading,
    String? errorMessage,
    bool setToNullLeconPourEdition = false,
  }) {
    return LeconState(
      lecons: lecons ?? this.lecons,
      leconPourEdition: setToNullLeconPourEdition ? null : (leconPourEdition ?? this.leconPourEdition),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LeconNotifier extends StateNotifier<LeconState> {
  final SupabaseClient _supabaseClient;
  static const String _tableName = 'cours'; // NOTE: This seems to be used for lecons
  static const String _storageBucketName = 'lecons';

  LeconNotifier(this._supabaseClient) : super(LeconState());

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf': return 'application/pdf';
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'avi': return 'video/x-msvideo';
      case 'mkv': return 'video/x-matroska';
      case 'webm': return 'video/webm';
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      case 'aac': return 'audio/aac';
      case 'ogg': return 'audio/ogg';
      case 'm4a': return 'audio/mp4';
      default: return 'application/octet-stream';
    }
  }

  String _sanitizeFileName(String fileName) {
    String namePart = fileName;
    String extensionPart = '';
    if (fileName.contains('.')) {
      namePart = fileName.substring(0, fileName.lastIndexOf('.'));
      extensionPart = fileName.substring(fileName.lastIndexOf('.'));
    }

    String sanitizedName = namePart.replaceAll(' ', '_');
    sanitizedName = sanitizedName
        .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e').replaceAll('ë', 'e')
        .replaceAll('à', 'a').replaceAll('â', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u').replaceAll('û', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('î', 'i').replaceAll('ï', 'i');

    sanitizedName = sanitizedName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    String sanitizedExtension = extensionPart.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '');

    sanitizedName = sanitizedName.replaceAll(RegExp(r'_+'), '_');
    if (sanitizedName.startsWith('_')) sanitizedName = sanitizedName.substring(1);
    if (sanitizedName.endsWith('_')) sanitizedName = sanitizedName.substring(0, sanitizedName.length - 1);
    if (sanitizedName.isEmpty) sanitizedName = 'file';

    return '$sanitizedName$sanitizedExtension';
  }

  Future<void> chargerLeconPourEdition(int leconId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, setToNullLeconPourEdition: true);
    try {
      final response = await _supabaseClient.from(_tableName).select().eq('id', leconId).single();
      state = state.copyWith(leconPourEdition: LeconModel.fromMap(response as Map<String, dynamic>), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (chargerLeconPourEdition): ${e.toString()}");
    }
  }

  Future<void> fetchLecons({int? chapitreId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      PostgrestFilterBuilder query = _supabaseClient.from(_tableName).select();
      if (chapitreId != null) query = query.eq('chapitre_id', chapitreId);
      
      final response = await query.order('ordre', ascending: true);
      
      final List<LeconModel> fetchedLecons = (response as List)
          .map((data) => LeconModel.fromMap(data as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, lecons: fetchedLecons);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (fetchLecons): ${e.toString()}");
    }
  }

  Future<bool> addLecon(LeconModel leconSansOrdreEtSansId, {Uint8List? fileBytes, String? fileName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (leconSansOrdreEtSansId.chapitreId == null) {
        throw Exception("chapitreId ne peut pas être null pour ajouter une leçon.");
      }

      String? finalUrlMedia = leconSansOrdreEtSansId.urlMedia;
      if (fileBytes != null && fileName != null) {
        final String sanitizedFileName = _sanitizeFileName(fileName);
        // CORRECTED filePathInBucket:
        final filePathInBucket = '${leconSansOrdreEtSansId.chapitreId}/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
        print("Uploading to Supabase Storage with key: $filePathInBucket");
        await _supabaseClient.storage.from(_storageBucketName).uploadBinary(
            filePathInBucket, fileBytes,
            fileOptions: FileOptions(contentType: _getMimeType(sanitizedFileName), upsert: false));
        finalUrlMedia = _supabaseClient.storage.from(_storageBucketName).getPublicUrl(filePathInBucket);
      }

      int nouvelOrdreGlobal = 1;
      final existingLeconsGlobalResponse = await _supabaseClient
          .from(_tableName).select('ordre').eq('chapitre_id', leconSansOrdreEtSansId.chapitreId!)
          .order('ordre', ascending: false).limit(1);
      if ((existingLeconsGlobalResponse as List<dynamic>).isNotEmpty) {
        final maxOrdre = (existingLeconsGlobalResponse).first['ordre'] as int? ?? 0;
        nouvelOrdreGlobal = maxOrdre + 1;
      }

      int nouvelOrdrePourType = 1;
      final existingLeconsForTypeResponse = await _supabaseClient
          .from(_tableName).select('ordre_par_type') 
          .eq('chapitre_id', leconSansOrdreEtSansId.chapitreId!)
          .eq('type', leconSansOrdreEtSansId.type); 

      if ((existingLeconsForTypeResponse as List<dynamic>).isNotEmpty) {
        int maxOrdrePourType = 0;
        for (var leconData in existingLeconsForTypeResponse) {
          final ordreParTypeMap = (leconData as Map<String, dynamic>)['ordre_par_type'];
          if (ordreParTypeMap != null && ordreParTypeMap is Map && ordreParTypeMap.containsKey(leconSansOrdreEtSansId.type)) {
             final currentOrderForType = ordreParTypeMap[leconSansOrdreEtSansId.type];
             if (currentOrderForType is int && currentOrderForType > maxOrdrePourType) {
                 maxOrdrePourType = currentOrderForType;
             }
          }
        }
        nouvelOrdrePourType = maxOrdrePourType + 1;
      }
      
      final Map<String, int> ordreParTypeData = {leconSansOrdreEtSansId.type: nouvelOrdrePourType};

      final leconModelPourInsertion = leconSansOrdreEtSansId.copyWith(
        urlMedia: finalUrlMedia,
        ordre: nouvelOrdreGlobal, 
        ordreParType: ordreParTypeData 
      );
      
      Map<String, dynamic> leconData = leconModelPourInsertion.toMap();
      leconData.remove('id');
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser != null) leconData['created_by'] = currentUser.id;
      else leconData.remove('created_by');

      final response = await _supabaseClient.from(_tableName).insert(leconData).select();

      final List<LeconModel> newLeconsList = (response as List)
          .map((data) => LeconModel.fromMap(data as Map<String, dynamic>))
          .toList();

      if (newLeconsList.isNotEmpty) {
        await fetchLecons(chapitreId: leconSansOrdreEtSansId.chapitreId); 
        return true;
      } else {
        throw Exception("N'a pas pu ajouter la leçon et récupérer la confirmation.");
      }
    } catch (e) {
      print("Error in addLecon: ${e.toString()}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (addLecon): ${e.toString()}");
      return false;
    }
  }

  Future<bool> updateLecon(LeconModel leconAMettreAJour, {Uint8List? fileBytes, String? fileName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    String oldPathToRemove = '';
    try {
      String? finalUrlMedia = leconAMettreAJour.urlMedia;
      LeconModel leconAvecValeursMaj = leconAMettreAJour;

      final currentLeconInDbData = await _supabaseClient
          .from(_tableName)
          .select('type, ordre_par_type, url_media') 
          .eq('id', leconAMettreAJour.id)
          .maybeSingle();
      
      String? oldUrlMediaFromDb = currentLeconInDbData != null ? currentLeconInDbData['url_media'] as String? : null;
      String? currentTypeFromDb = currentLeconInDbData != null ? currentLeconInDbData['type'] as String? : null;

      if (fileBytes != null && fileName != null) {
        final String sanitizedFileName = _sanitizeFileName(fileName);
        if (oldUrlMediaFromDb != null && oldUrlMediaFromDb.isNotEmpty) {
          // Construct the path relative to the bucket for removal
          try {
            final Uri oldUri = Uri.parse(oldUrlMediaFromDb);
            // The path in the URL after /object/public/bucket_name/
            oldPathToRemove = oldUri.pathSegments.sublist(oldUri.pathSegments.indexOf(_storageBucketName) + 1).join('/');
            if (oldPathToRemove.isNotEmpty) {
                await _supabaseClient.storage.from(_storageBucketName).remove([oldPathToRemove]);
                print("Successfully removed old file from storage during update: $oldPathToRemove");
            }
          } catch (e) {
             print("Could not parse or remove old file during update ($oldUrlMediaFromDb / $oldPathToRemove): $e");
          }
        }
        // CORRECTED filePathInBucket:
        final filePathInBucket = '${leconAMettreAJour.chapitreId}/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
        print("Uploading to Supabase Storage with key: $filePathInBucket");
        await _supabaseClient.storage.from(_storageBucketName).uploadBinary(
            filePathInBucket, fileBytes,
            fileOptions: FileOptions(contentType: _getMimeType(sanitizedFileName), upsert: false));
        finalUrlMedia = _supabaseClient.storage.from(_storageBucketName).getPublicUrl(filePathInBucket);
        leconAvecValeursMaj = leconAvecValeursMaj.copyWith(urlMedia: finalUrlMedia);
      }

      bool typeChanged = currentTypeFromDb != null && currentTypeFromDb != leconAvecValeursMaj.type;
      bool ordreParTypeManquantOuInvalide = leconAvecValeursMaj.ordreParType == null || 
                                          !leconAvecValeursMaj.ordreParType!.containsKey(leconAvecValeursMaj.type) ||
                                          (leconAvecValeursMaj.ordreParType![leconAvecValeursMaj.type] ?? 0) == 0;

      if (typeChanged || ordreParTypeManquantOuInvalide) {
        print("Type changed or ordreParType needs update for type: ${leconAvecValeursMaj.type}");
        int nouvelOrdrePourType = 1;
        final existingLeconsForTypeResponse = await _supabaseClient
            .from(_tableName)
            .select('ordre_par_type, id')
            .eq('chapitre_id', leconAvecValeursMaj.chapitreId!)
            .eq('type', leconAvecValeursMaj.type);

        if ((existingLeconsForTypeResponse as List<dynamic>).isNotEmpty) {
          int maxOrdrePourType = 0;
          for (var leconData in existingLeconsForTypeResponse) {
            final leconMap = leconData as Map<String, dynamic>;
            if (leconMap['id'] == leconAvecValeursMaj.id && !typeChanged) continue; 
            
            final ordreParTypeMap = leconMap['ordre_par_type'];
            if (ordreParTypeMap != null && ordreParTypeMap is Map && ordreParTypeMap.containsKey(leconAvecValeursMaj.type)) {
              final currentOrderForType = ordreParTypeMap[leconAvecValeursMaj.type];
              if (currentOrderForType is int && currentOrderForType > maxOrdrePourType) {
                maxOrdrePourType = currentOrderForType;
              }
            }
          }
          nouvelOrdrePourType = maxOrdrePourType + 1;
        }
        
        Map<String, int> updatedOrdreParType = Map.from(leconAvecValeursMaj.ordreParType ?? {});
        updatedOrdreParType[leconAvecValeursMaj.type] = nouvelOrdrePourType;
        leconAvecValeursMaj = leconAvecValeursMaj.copyWith(ordreParType: updatedOrdreParType);
        print("Nouvel ordre pour type ${leconAvecValeursMaj.type}: $nouvelOrdrePourType. Map: $updatedOrdreParType");
      }
      
      final Map<String, dynamic> leconDataForUpdate = leconAvecValeursMaj.toMapForUpdate();
      leconDataForUpdate['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabaseClient.from(_tableName)
          .update(leconDataForUpdate).eq('id', leconAvecValeursMaj.id).select();

      final List<LeconModel> updatedLeconsList = (response as List)
          .map((data) => LeconModel.fromMap(data as Map<String, dynamic>))
          .toList();
      
      if (updatedLeconsList.isNotEmpty) {
        await fetchLecons(chapitreId: leconAvecValeursMaj.chapitreId);
        state = state.copyWith(leconPourEdition: updatedLeconsList.first); 
        return true;
      } else {
        if(leconAvecValeursMaj.chapitreId != null) await fetchLecons(chapitreId: leconAvecValeursMaj.chapitreId);
        state = state.copyWith(isLoading: false, errorMessage: "Leçon potentiellement mise à jour, mais confirmation non récupérée. Liste rafraîchie si possible.");
        return false; 
      }
    } catch (e) {
      print("Error in updateLecon (oldPath attempted: $oldPathToRemove): ${e.toString()}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (updateLecon): ${e.toString()}");
      return false;
    }
  }

  Future<void> updateLeconsOrder(List<LeconModel> leconsReordonnees, int chapitreId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      for (int i = 0; i < leconsReordonnees.length; i++) {
        final lecon = leconsReordonnees[i];
        await _supabaseClient.from(_tableName)
            .update({'ordre': i + 1, 'updated_at': DateTime.now().toIso8601String()}) 
            .eq('id', lecon.id).eq('chapitre_id', chapitreId); 
      }
      await fetchLecons(chapitreId: chapitreId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (updateLeconsOrder): ${e.toString()}");
      if (chapitreId != 0) await fetchLecons(chapitreId: chapitreId);
    }
  }

  Future<void> updateLeconsOrderForType(List<LeconModel> leconsReordonneesDuType, String type, int chapitreId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      for (int i = 0; i < leconsReordonneesDuType.length; i++) {
        final lecon = leconsReordonneesDuType[i];
        Map<String, int> newOrdreParType = Map.from(lecon.ordreParType ?? {});
        newOrdreParType[type] = i + 1;

        await _supabaseClient.from(_tableName)
            .update({
              'ordre_par_type': newOrdreParType,
              'updated_at': DateTime.now().toIso8601String()
            })
            .eq('id', lecon.id)
            .eq('chapitre_id', chapitreId);
      }
      await fetchLecons(chapitreId: chapitreId); 
    } catch (e) {
      print("Erreur Supabase (updateLeconsOrderForType): ${e.toString()}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (updateLeconsOrderForType): ${e.toString()}");
      if (chapitreId != 0) await fetchLecons(chapitreId: chapitreId);
    }
  }

  Future<void> updateLeconSpecificOrder(int leconId, String type, int newOrderInType) async {
    try {
      final leconDataResponse = await _supabaseClient
          .from(_tableName) 
          .select('ordre_par_type')
          .eq('id', leconId)
          .maybeSingle();

      Map<String, int> updatedOrdreParType = {};

      if (leconDataResponse != null && leconDataResponse['ordre_par_type'] != null) {
        var rawMap = leconDataResponse['ordre_par_type'] as Map;
         rawMap.forEach((key, value) {
          if (value is int) {
            updatedOrdreParType[key.toString()] = value;
          } else if (value is String) {
            updatedOrdreParType[key.toString()] = int.tryParse(value) ?? 0;
          } else {
            updatedOrdreParType[key.toString()] = 0; 
          }
        });
      }
      
      updatedOrdreParType[type] = newOrderInType;
      
      await _supabaseClient
          .from(_tableName)
          .update({
            'ordre_par_type': updatedOrdreParType,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', leconId);
          
      print("Lecon $leconId specific order for type '$type' updated to $newOrderInType. Full map: $updatedOrdreParType");

    } catch (e) {
      print("Error in updateLeconSpecificOrder for leconId $leconId, type $type: ${e.toString()}");
      rethrow;
    }
  }

  Future<bool> deleteLecon(int leconId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    String pathToRemoveForDebug = 'path_not_set';
    LeconModel? leconASupprimer;

    try {
      try {
        leconASupprimer = state.lecons.firstWhere((lec) => lec.id == leconId);
      } catch (e) {
        if (state.leconPourEdition?.id == leconId) {
          leconASupprimer = state.leconPourEdition!;
        }
      }
      
      if (leconASupprimer == null) {
          final leconData = await _supabaseClient.from(_tableName).select().eq('id', leconId).maybeSingle();
          if (leconData != null) {
              leconASupprimer = LeconModel.fromMap(leconData as Map<String, dynamic>);
          } else {
              await _supabaseClient.from(_tableName).delete().eq('id', leconId);
              state = state.copyWith(isLoading: false, lecons: state.lecons.where((l) => l.id != leconId).toList());
              print("Leçon non trouvée localement ou en BDD pour suppression, suppression par ID seulement.");
              return true; 
          }
      }

      final chapitreIdConcerne = leconASupprimer.chapitreId;
      final urlMediaASupprimer = leconASupprimer.urlMedia;

      await _supabaseClient.from(_tableName).delete().eq('id', leconId);
      
      if (urlMediaASupprimer != null && urlMediaASupprimer.isNotEmpty) {
         try {
            final Uri oldUri = Uri.parse(urlMediaASupprimer);
            // The path in the URL after /object/public/bucket_name/
            pathToRemoveForDebug = oldUri.pathSegments.sublist(oldUri.pathSegments.indexOf(_storageBucketName) + 1).join('/');
            if (pathToRemoveForDebug.isNotEmpty) {
                await _supabaseClient.storage.from(_storageBucketName).remove([pathToRemoveForDebug]);
                print("Successfully removed from storage: $pathToRemoveForDebug");
            }
          } catch (e) {
             print("Could not parse or remove old file during delete ($urlMediaASupprimer / $pathToRemoveForDebug): $e");
          }
      }

      if (chapitreIdConcerne != null && chapitreIdConcerne != 0) { 
          await fetchLecons(chapitreId: chapitreIdConcerne);
      } else {
          state = state.copyWith(isLoading: false, lecons: state.lecons.where((l) => l.id != leconId).toList());
          if (state.leconPourEdition?.id == leconId) {
             state = state.copyWith(setToNullLeconPourEdition: true);
          }
      }
      return true;
    } catch (e) {
      print("Error in deleteLecon (path attempt: $pathToRemoveForDebug): ${e.toString()}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (deleteLecon): ${e.toString()}");
      return false;
    }
  }
}

final leconProvider = StateNotifierProvider<LeconNotifier, LeconState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return LeconNotifier(supabaseClient);
});
