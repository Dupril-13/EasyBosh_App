import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:easybosh_v2/main.dart'; // Assurez-vous que supabaseClientProvider est exporté ou accessible

part 'matiere_provider.g.dart';

class MatiereState {
  final bool isLoading;
  final List<MatiereModel> matieres;
  final String? errorMessage;

  MatiereState({
    this.isLoading = false,
    this.matieres = const [],
    this.errorMessage,
  });

  MatiereState copyWith({
    bool? isLoading,
    List<MatiereModel>? matieres,
    String? errorMessage,
    bool? resetErrorMessage = false,
  }) {
    return MatiereState(
      isLoading: isLoading ?? this.isLoading,
      matieres: matieres ?? this.matieres,
      errorMessage: resetErrorMessage == true ? null : errorMessage ?? this.errorMessage,
    );
  }
}

@Riverpod(keepAlive: true)
class Matiere extends _$Matiere {
  late SupabaseClient _supabaseClient;
  String? _lastNiveauCode;
  String? _lastSerieCode;

  @override
  MatiereState build() {
    _supabaseClient = ref.watch(supabaseClientProvider);
    return MatiereState();
  }

  Future<void> fetchMatieres({String? niveauCode, String? serieCode}) async {
    if (niveauCode == null || niveauCode.isEmpty || serieCode == null || serieCode.isEmpty) {
      state = state.copyWith(isLoading: false, matieres: [], errorMessage: "Niveau ou série non spécifié pour charger les matières.");
      return;
    }
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    _lastNiveauCode = niveauCode;
    _lastSerieCode = serieCode;

    try {
      final matiereNiveauSerieResponse = await _supabaseClient
          .from('matiere_niveau_serie')
          .select('matiere_id')
          .eq('niveau_code', niveauCode)
          .eq('serie_code', serieCode);

      final List<int> matiereIds = matiereNiveauSerieResponse
          .map((item) => item['matiere_id'] as int)
          .toList();

      List<MatiereModel> fetchedMatieres;
      if (matiereIds.isEmpty) {
        fetchedMatieres = [];
      } else {
        final String matiereIdsString = '(${matiereIds.join(',')})';
        final matieresResponse = await _supabaseClient
            .from('matieres')
            .select()
            .filter('id', 'in', matiereIdsString)
            .order('nom', ascending: true);
        
        fetchedMatieres = matieresResponse
            .map((data) => MatiereModel.fromMap(data as Map<String, dynamic>))
            .toList();
      }
      state = state.copyWith(isLoading: false, matieres: fetchedMatieres);
    } on PostgrestException catch (e) {
      print("Erreur Postgrest fetchMatieres: ${e.message}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur de base de données (matieres): ${e.message}");
    } catch (e) {
      print("Erreur Générale fetchMatieres: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Une erreur inattendue est survenue (matieres): $e");
    }
  }

  void setExternalError(String message) {
    state = state.copyWith(isLoading: false, matieres: [], errorMessage: message, resetErrorMessage: false);
  }

  void clearDataAndError() {
    state = state.copyWith(isLoading: false, matieres: [], errorMessage: null, resetErrorMessage: true);
  }

  Future<bool> addMatiere(MatiereModel matiereAAjouter) async {
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      final response = await _supabaseClient
          .from('matieres')
          .insert(matiereAAjouter.toMapForInsert())
          .select();

      final List<dynamic> insertedDataList = response as List<dynamic>;

      if (insertedDataList.isNotEmpty) {
        if (_lastNiveauCode != null && _lastSerieCode != null) {
           await fetchMatieres(niveauCode: _lastNiveauCode, serieCode: _lastSerieCode);
        } else {
            state = state.copyWith(isLoading: false);
        }
        return true;
      } else {
         state = state.copyWith(isLoading: false, errorMessage: "N'a pas pu ajouter la matière et récupérer la confirmation.");
         return false;
      }
    } on PostgrestException catch (e) {
      print("Erreur Postgrest addMatiere: ${e.message}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur de base de données (ajout matière): ${e.message}");
      return false;
    } catch (e) {
      print("Erreur Générale addMatiere: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur inattendue (ajout matière): $e");
      return false;
    }
  }

  Future<bool> updateMatiere(MatiereModel matiereAMettreAJour) async {
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      final response = await _supabaseClient
          .from('matieres')
          .update(matiereAMettreAJour.toMapForUpdate())
          .eq('id', matiereAMettreAJour.id)
          .select();
      
      final List<dynamic> updatedDataList = response as List<dynamic>;
      
      if (updatedDataList.isNotEmpty) {
        if (_lastNiveauCode != null && _lastSerieCode != null) {
          await fetchMatieres(niveauCode: _lastNiveauCode, serieCode: _lastSerieCode);
        } else {
            state = state.copyWith(isLoading: false);
        }
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: "Matière mise à jour, mais n'a pas pu récupérer la confirmation.");
        return false; 
      }
    } on PostgrestException catch (e) {
      print("Erreur Postgrest updateMatiere: ${e.message}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur de base de données (maj matière): ${e.message}");
      return false;
    } catch (e) {
      print("Erreur Générale updateMatiere: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur inattendue (maj matière): $e");
      return false;
    }
  }

  Future<bool> deleteMatiere(int matiereId) async {
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      await _supabaseClient
          .from('matieres')
          .delete()
          .eq('id', matiereId);
      
      if (_lastNiveauCode != null && _lastSerieCode != null) {
        await fetchMatieres(niveauCode: _lastNiveauCode, serieCode: _lastSerieCode);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } on PostgrestException catch (e) {
      print("Erreur Postgrest deleteMatiere: ${e.message}");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur de base de données (sup matière): ${e.message}");
      return false;
    } catch (e) {
      print("Erreur Générale deleteMatiere: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur inattendue (sup matière): $e");
      return false;
    }
  }
}
