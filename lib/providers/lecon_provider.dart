import 'dart:typed_data'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:easybosh_v2/main.dart'; 

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
  static const String _tableName = 'cours'; 
  static const String _storageBucketName = 'lecons';

  LeconNotifier(this._supabaseClient) : super(LeconState());

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
        return 'audio/mp4';
      default:
        return 'application/octet-stream';
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

    // Éviter les underscores multiples ou en début/fin de nom après sanitization
    sanitizedName = sanitizedName.replaceAll(RegExp(r'_+'), '_');
    if (sanitizedName.startsWith('_')) {
      sanitizedName = sanitizedName.substring(1);
    }
    if (sanitizedName.endsWith('_')) {
      sanitizedName = sanitizedName.substring(0, sanitizedName.length - 1);
    }
    if (sanitizedName.isEmpty) {
      sanitizedName = 'file'; // Fallback si le nom devient vide
    }

    return '$sanitizedName$sanitizedExtension';
  }

  Future<void> chargerLeconPourEdition(int leconId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, setToNullLeconPourEdition: true);
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('id', leconId)
          .single();
      state = state.copyWith(leconPourEdition: LeconModel.fromMap(response as Map<String, dynamic>), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (chargerLeconPourEdition): ${e.toString()}");
    }
  }

  Future<void> fetchLecons({int? chapitreId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      PostgrestFilterBuilder query = _supabaseClient.from(_tableName).select();

      if (chapitreId != null) {
        query = query.eq('chapitre_id', chapitreId);
      }
      final response = await query.order('ordre', ascending: true);
      
      final List<LeconModel> fetchedLecons = (response as List)
          .map((data) => LeconModel.fromMap(data as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, lecons: fetchedLecons);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (fetchLecons): ${e.toString()}");
    }
  }

  Future<bool> addLecon(LeconModel leconSansOrdre, {Uint8List? fileBytes, String? fileName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (leconSansOrdre.chapitreId == null) {
        throw Exception("chapitreId ne peut pas être null pour ajouter une leçon.");
      }

      String? finalUrlMedia = leconSansOrdre.urlMedia;

      if (fileBytes != null && fileName != null) {
        final String sanitizedFileName = _sanitizeFileName(fileName);
        final filePathInBucket = 'lecons/${leconSansOrdre.chapitreId}/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
        print("Uploading to Supabase Storage with key: $filePathInBucket"); // Debug log
        await _supabaseClient.storage
            .from(_storageBucketName)
            .uploadBinary(
              filePathInBucket, 
              fileBytes, 
              fileOptions: FileOptions(contentType: _getMimeType(sanitizedFileName), upsert: false)
            );
        finalUrlMedia = _supabaseClient.storage.from(_storageBucketName).getPublicUrl(filePathInBucket);
      }

      int nouvelOrdre = 1;
      final existingLeconsResponse = await _supabaseClient
          .from(_tableName)
          .select('ordre')
          .eq('chapitre_id', leconSansOrdre.chapitreId!)
          .order('ordre', ascending: false)
          .limit(1);

      final List<dynamic> existingLeconsData = existingLeconsResponse as List<dynamic>; 
      if (existingLeconsData.isNotEmpty) {
        final maxOrdre = existingLeconsData.first['ordre'] as int? ?? 0;
        nouvelOrdre = maxOrdre + 1;
      }

      final leconData = leconSansOrdre.copyWith(urlMedia: finalUrlMedia).toMap();
      leconData['ordre'] = nouvelOrdre;
      
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser != null) {
        leconData['created_by'] = currentUser.id;
      } 

      final response = await _supabaseClient
          .from(_tableName)
          .insert(leconData)
          .select();

      final List<LeconModel> newLeconsList = (response as List)
        .map((data) => LeconModel.fromMap(data as Map<String, dynamic>))
        .toList();

      if (newLeconsList.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          lecons: [...state.lecons, newLeconsList.first]..sort((a, b) => a.ordre.compareTo(b.ordre)),
        );
        return true;
      } else {
         throw Exception("N'a pas pu ajouter la leçon et récupérer la confirmation.");
      }
    } catch (e) {
      print("Error in addLecon: ${e.toString()}"); // Debug log
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (addLecon): ${e.toString()}");
      return false;
    }
  }

  Future<bool> updateLecon(LeconModel leconAMettreAJour, {Uint8List? fileBytes, String? fileName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    String oldPathToRemove = ''; 
    try {
      String? finalUrlMedia = leconAMettreAJour.urlMedia;
      
      if (fileBytes != null && fileName != null) {
        final String sanitizedFileName = _sanitizeFileName(fileName);
        if (leconAMettreAJour.urlMedia != null && leconAMettreAJour.urlMedia!.isNotEmpty) {
            const String dummyFileNameForPrefix = 'update_check_prefix_dummy.txt';
            final String dummyFilePublicUrlForPrefix = _supabaseClient.storage.from(_storageBucketName).getPublicUrl(dummyFileNameForPrefix);
            final String expectedStoragePrefixForOldFile = dummyFilePublicUrlForPrefix.substring(0, dummyFilePublicUrlForPrefix.length - dummyFileNameForPrefix.length);
            
            if (leconAMettreAJour.urlMedia!.startsWith(expectedStoragePrefixForOldFile)) {
                oldPathToRemove = leconAMettreAJour.urlMedia!.substring(expectedStoragePrefixForOldFile.length);
                try {
                    if(oldPathToRemove.isNotEmpty) {
                        await _supabaseClient.storage.from(_storageBucketName).remove([oldPathToRemove]);
                        print("Successfully removed old file from storage during update: $oldPathToRemove");
                    }
                } catch (e) {
                    print("Could not remove old file during update ($oldPathToRemove): $e");
                }
            }
        }

        final filePathInBucket = 'lecons/${leconAMettreAJour.chapitreId}/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
        print("Uploading to Supabase Storage with key: $filePathInBucket"); // Debug log
        await _supabaseClient.storage
            .from(_storageBucketName)
            .uploadBinary(
              filePathInBucket, 
              fileBytes, 
              fileOptions: FileOptions(contentType: _getMimeType(sanitizedFileName), upsert: false)
            );
        finalUrlMedia = _supabaseClient.storage.from(_storageBucketName).getPublicUrl(filePathInBucket);
      }
      
      final Map<String, dynamic> leconData = leconAMettreAJour.copyWith(urlMedia: finalUrlMedia).toMap();

      final response = await _supabaseClient
          .from(_tableName)
          .update(leconData)
          .eq('id', leconAMettreAJour.id)
          .select();

      final List<LeconModel> updatedLeconsList = (response as List)
        .map((data) => LeconModel.fromMap(data as Map<String, dynamic>))
        .toList();
      
      if (updatedLeconsList.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          lecons: state.lecons.map((l) => l.id == leconAMettreAJour.id ? updatedLeconsList.first : l).toList()..sort((a,b) => a.ordre.compareTo(b.ordre)),
          leconPourEdition: updatedLeconsList.first,
        );
        return true;
      } else {
        if(leconAMettreAJour.chapitreId != null) {
             await fetchLecons(chapitreId: leconAMettreAJour.chapitreId); 
        }
        state = state.copyWith(isLoading: false, errorMessage: "Leçon potentiellement mise à jour, mais confirmation non récupérée. Liste rafraîchie si possible.");
        return false; 
      }
    } catch (e) {
      print("Error in updateLecon (oldPath attempted: $oldPathToRemove): ${e.toString()}"); // Debug log
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (updateLecon): ${e.toString()}");
      return false;
    }
  }

  Future<void> updateLeconsOrder(List<LeconModel> leconsReordonnees, int chapitreId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      for (int i = 0; i < leconsReordonnees.length; i++) {
        final lecon = leconsReordonnees[i];
        await _supabaseClient
            .from(_tableName)
            .update({'ordre': i + 1}) 
            .eq('id', lecon.id)
            .eq('chapitre_id', chapitreId); 
      }
      await fetchLecons(chapitreId: chapitreId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur Supabase (updateLeconsOrder): ${e.toString()}");
      await fetchLecons(chapitreId: chapitreId);
    }
  }

  Future<bool> deleteLecon(int leconId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    String pathToRemoveForDebug = 'path_not_set';
    try {
      LeconModel? leconASupprimer = state.lecons.firstWhere((lec) => lec.id == leconId, 
          orElse: () => state.leconPourEdition?.id == leconId ? state.leconPourEdition! : LeconModel(id:0, nom:'', ordre:0, chapitreId:0, type:'', createdAt: DateTime.now(), actif: false) );
      final chapitreIdConcerne = leconASupprimer.chapitreId;
      final urlMediaASupprimer = leconASupprimer.urlMedia;

      await _supabaseClient
          .from(_tableName)
          .delete()
          .eq('id', leconId);
      
      if (urlMediaASupprimer != null && urlMediaASupprimer.isNotEmpty) {
        const String dummyFileName = 'check_path_prefix_dummy.txt';
        final String dummyFilePublicUrl = _supabaseClient.storage
            .from(_storageBucketName)
            .getPublicUrl(dummyFileName);

        final String expectedStoragePrefix = dummyFilePublicUrl.substring(0, dummyFilePublicUrl.length - dummyFileName.length);
        
        if (urlMediaASupprimer.startsWith(expectedStoragePrefix)) {
          pathToRemoveForDebug = urlMediaASupprimer.substring(expectedStoragePrefix.length);
          if (pathToRemoveForDebug.isNotEmpty) {
            await _supabaseClient.storage
                .from(_storageBucketName)
                .remove([pathToRemoveForDebug]);
            print("Successfully removed from storage: $pathToRemoveForDebug");
          }
        } else {
           print("URL media ($urlMediaASupprimer) does not match expected Supabase storage prefix ($expectedStoragePrefix)");
        }
      }

      if (chapitreIdConcerne != 0) { 
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
