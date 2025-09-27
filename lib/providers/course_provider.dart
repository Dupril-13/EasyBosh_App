import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_model.dart';
import './auth_provider.dart'; // Pour obtenir l'ID de l'utilisateur connecté

// État pour le CourseNotifier
class CourseState {
  final List<CourseModel> courses;
  final bool isLoading;
  final String? errorMessage;

  CourseState({
    this.courses = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CourseState copyWith({
    List<CourseModel>? courses,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CourseState(
      courses: courses ?? this.courses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CourseNotifier extends StateNotifier<CourseState> {
  final SupabaseClient _supabaseClient;
  final String? _userId; // ID de l'enseignant connecté

  CourseNotifier(this._supabaseClient, this._userId) : super(CourseState(isLoading: true)) { // isLoading à true au début
    if (_userId != null) {
      fetchCoursesCreatedByCurrentUser();
    } else {
      state = state.copyWith(isLoading: false, errorMessage: "Utilisateur non identifié pour charger les cours.");
    }
  }

  Future<void> fetchCoursesByChapter(int chapitreId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabaseClient
          .from('cours')
          .select()
          .eq('chapitre_id', chapitreId)
          .order('ordre', ascending: true);

      final courses = response.map((data) => CourseModel.fromMap(data)).toList();
      state = state.copyWith(courses: courses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: "Erreur de chargement des cours: ${e.toString()}");
    }
  }

  Future<void> fetchCoursesCreatedByCurrentUser() async {
    if (_userId == null) {
      state = state.copyWith(isLoading: false, errorMessage: "Aucun utilisateur connecté pour récupérer les cours.");
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabaseClient
          .from('cours')
          .select('*, chapitres(*, matieres(*), niveaux(*), series(*))') // Exemple de récupération imbriquée
          .eq('created_by', _userId!) 
          .order('created_at', ascending: false); 

      final courses = response.map((data) => CourseModel.fromMap(data)).toList();
      state = state.copyWith(courses: courses, isLoading: false);
    } catch (e) {
      print("Erreur fetchCoursesCreatedByCurrentUser: $e"); // Pour le débogage
      state = state.copyWith(isLoading: false, errorMessage: "Erreur de chargement de vos cours: ${e.toString()}");
    }
  }


  Future<bool> addCourse(CourseModel courseDetails, int chapitreId) async {
    if (_userId == null) {
      state = state.copyWith(errorMessage: "Action non autorisée: utilisateur non connecté.");
      return false;
    }
    state = state.copyWith(isLoading: true);
    try {
      final courseData = courseDetails.copyWith(
        createdBy: _userId,
        chapitreId: chapitreId,
        // createdAt est géré par la BD, updatedAt aussi au premier ajout (ou via trigger)
      ).toMap();
      
      courseData.remove('id'); 
      // courseData.remove('created_at'); // Laissé pour être potentiellement géré par le client si besoin
      // courseData.remove('updated_at');

      final response = await _supabaseClient
          .from('cours')
          .insert(courseData)
          .select('*, chapitres(*, matieres(*), niveaux(*), series(*))') // Récupérer le nouveau cours avec les données imbriquées
          .single();

      final newCourse = CourseModel.fromMap(response);
      state = state.copyWith(
        courses: [newCourse, ...state.courses], 
        isLoading: false
      );
      return true;
    } catch (e) {
      print("Erreur addCourse: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur lors de l'ajout du cours: ${e.toString()}");
      return false;
    }
  }

  Future<bool> updateCourse(CourseModel course) async {
     if (_userId == null) {
      state = state.copyWith(errorMessage: "Action non autorisée: utilisateur non connecté.");
      return false;
    }
    state = state.copyWith(isLoading: true);
    try {
      final courseData = course.copyWith(
        // updated_at devrait être mis à jour par Supabase via trigger ou default now() on update
      ).toMap();

      courseData.remove('created_by');
      courseData.remove('created_at');
      final Map<String, dynamic> updateData = Map.from(courseData);
      updateData.remove('id');
      // Assurez-vous que updated_at est mis à jour si ce n'est pas automatique en BD
      // updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabaseClient
          .from('cours')
          .update(updateData)
          .eq('id', course.id)
          .eq('created_by', _userId!)
          .select('*, chapitres(*, matieres(*), niveaux(*), series(*))') // Récupérer le cours mis à jour
          .single();

      final updatedCourse = CourseModel.fromMap(response);
      state = state.copyWith(
        courses: state.courses.map((c) => c.id == updatedCourse.id ? updatedCourse : c).toList(),
        isLoading: false
      );
      return true;
    } catch (e) {
      print("Erreur updateCourse: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur lors de la mise à jour du cours: ${e.toString()}");
      return false;
    }
  }

  Future<bool> deleteCourse(int courseId) async {
    if (_userId == null) {
      state = state.copyWith(errorMessage: "Action non autorisée: utilisateur non connecté.");
      return false;
    }
    state = state.copyWith(isLoading: true);
    try {
      await _supabaseClient
          .from('cours')
          .delete()
          .eq('id', courseId)
          .eq('created_by', _userId!); 

      state = state.copyWith(
        courses: state.courses.where((c) => c.id != courseId).toList(),
        isLoading: false
      );
      return true;
    } catch (e) {
      print("Erreur deleteCourse: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur lors de la suppression du cours: ${e.toString()}");
      return false;
    }
  }
}

final courseProvider = StateNotifierProvider<CourseNotifier, CourseState>((ref) {
  final supabaseClient = Supabase.instance.client;
  final userId = ref.watch(authProvider.select((authState) => authState.supabaseUser?.id));
  return CourseNotifier(supabaseClient, userId);
});
