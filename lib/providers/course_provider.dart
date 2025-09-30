import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_model.dart';
import '../main.dart'; // For supabaseClientProvider
import '../core/providers/auth_provider.dart'; // For authProvider and AuthState

part 'course_provider.g.dart';

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
    bool? resetErrorMessage = false, // Ajouté pour cohérence
  }) {
    return CourseState(
      courses: courses ?? this.courses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: resetErrorMessage == true ? null : errorMessage ?? this.errorMessage,
    );
  }
}

@Riverpod(keepAlive: true)
class Course extends _$Course {
  late SupabaseClient _supabaseClient;
  String? _userId;

  @override
  CourseState build() {
    _supabaseClient = ref.watch(supabaseClientProvider);
    final authState = ref.watch(authProvider);

    if (authState is AuthAuthenticated) {
      _userId = authState.user.uid;
      // Déclencher le fetch ici si l'utilisateur est authentifié
      // fetchCoursesCreatedByCurrentUser est async, donc build retournera l'état initial avant la fin du fetch.
      fetchCoursesCreatedByCurrentUser(); 
      return CourseState(isLoading: true); // Indiquer le chargement initial
    } else {
      _userId = null;
      return CourseState(isLoading: false, courses: [], errorMessage: "Utilisateur non identifié pour charger les cours.");
    }
  }

  Future<void> fetchCoursesByChapter(int chapitreId) async {
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      final response = await _supabaseClient
          .from('cours')
          .select('*, chapitres(*, matieres(*), niveaux(*), series(*))') // Exemple avec données imbriquées
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
      state = state.copyWith(isLoading: false, courses: [], errorMessage: "Aucun utilisateur connecté pour récupérer les cours.");
      return;
    }
    // Si l'état n'est pas déjà en chargement pour cette opération précise, le mettre.
    if (!state.isLoading) {
        state = state.copyWith(isLoading: true, resetErrorMessage: true);
    }
    try {
      final response = await _supabaseClient
          .from('cours')
          .select('*, chapitres(*, matieres(*), niveaux(*), series(*))')
          .eq('created_by', _userId!) 
          .order('created_at', ascending: false); 

      final courses = response.map((data) => CourseModel.fromMap(data)).toList();
      state = state.copyWith(courses: courses, isLoading: false);
    } catch (e) {
      print("Erreur fetchCoursesCreatedByCurrentUser: $e");
      state = state.copyWith(isLoading: false, errorMessage: "Erreur de chargement de vos cours: ${e.toString()}");
    }
  }

  Future<bool> addCourse(CourseModel courseDetails, int chapitreId) async {
    if (_userId == null) {
      state = state.copyWith(errorMessage: "Action non autorisée: utilisateur non connecté.", isLoading: false);
      return false;
    }
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      final courseData = courseDetails.copyWith(
        createdBy: _userId,
        chapitreId: chapitreId,
      ).toMap();
      
      courseData.remove('id'); 

      final response = await _supabaseClient
          .from('cours')
          .insert(courseData)
          .select('*, chapitres(*, matieres(*), niveaux(*), series(*))')
          .single();

      final newCourse = CourseModel.fromMap(response);
      // Optimistic update: add to current list or refetch if list is not just "user's courses"
      // Since this provider is focused on current user's courses via build, we can add it.
      final currentCourses = List<CourseModel>.from(state.courses);
      state = state.copyWith(
        courses: [newCourse, ...currentCourses], 
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
      state = state.copyWith(errorMessage: "Action non autorisée: utilisateur non connecté.", isLoading: false);
      return false;
    }
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
    try {
      final courseData = course.toMap();
      courseData.remove('created_by');
      courseData.remove('created_at');
      final Map<String, dynamic> updateData = Map.from(courseData);
      updateData.remove('id');
      updateData['updated_at'] = DateTime.now().toIso8601String(); // Explicitly set updated_at

      final response = await _supabaseClient
          .from('cours')
          .update(updateData)
          .eq('id', course.id)
          .eq('created_by', _userId!) // Ensure user can only update their own courses
          .select('*, chapitres(*, matieres(*), niveaux(*), series(*))')
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
      state = state.copyWith(errorMessage: "Action non autorisée: utilisateur non connecté.", isLoading: false);
      return false;
    }
    state = state.copyWith(isLoading: true, resetErrorMessage: true);
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

// L'ancien "final courseProvider = StateNotifierProvider..." est supprimé.
// Le générateur créera `courseProvider`.
