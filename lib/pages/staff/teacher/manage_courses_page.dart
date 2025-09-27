import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easybosh_v2/providers/course_provider.dart';
import '../../../models/course_model.dart'; 
import './edit_course_page.dart'; // Importer EditCoursePage

class ManageCoursesPage extends ConsumerWidget {
  const ManageCoursesPage({super.key});

  void _navigateToEditPage(BuildContext context, {CourseModel? course}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCoursePage(course: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseState = ref.watch(courseProvider);
    // Écouter les changements pour afficher les SnackBars après les opérations CRUD
    // Ceci est un exemple simple, une gestion d'état plus robuste pour les messages
    // pourrait être mise en place (ex: avec un provider dédié pour les notifications utilisateur)
    ref.listen<CourseState>(courseProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false && next.errorMessage == null) {
        // Potentiellement, si on voulait un SnackBar de succès global après chaque op sans erreur
        // Mais c'est mieux géré localement dans EditCoursePage ou après delete ici.
      } else if (next.errorMessage != null && (previous?.errorMessage != next.errorMessage)) {
        // Si une erreur globale survient sur le provider, on peut l'afficher
        // Mais attention à ne pas dupliquer les erreurs déjà gérées par les Snackbars locaux
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        // );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Cours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(courseProvider.notifier).fetchCoursesCreatedByCurrentUser();
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (courseState.isLoading && courseState.courses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (courseState.errorMessage != null && courseState.courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(courseState.errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(courseProvider.notifier).fetchCoursesCreatedByCurrentUser();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (courseState.courses.isEmpty) {
            return const Center(
              child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun cours trouvé.', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Appuyez sur le bouton + pour en ajouter un.', textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: courseState.courses.length,
            itemBuilder: (context, index) {
              final course = courseState.courses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(course.type.substring(0, 1).toUpperCase()), // Initiale du type
                  ),
                  title: Text(course.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Chapitre ID: ${course.chapitreId?.toString() ?? 'N/A'}\n${course.description ?? 'Pas de description'}",
                     maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                        tooltip: 'Modifier le cours',
                        onPressed: () {
                          _navigateToEditPage(context, course: course);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Supprimer le cours',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirmer la suppression'),
                                content: Text('Voulez-vous vraiment supprimer le cours "${course.nom}"?\nCette action est irréversible.'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm == true) {
                            final success = await ref.read(courseProvider.notifier).deleteCourse(course.id);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Cours "${course.nom}" supprimé.'), backgroundColor: Colors.green),
                              );
                            } else if (context.mounted){
                               ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur lors de la suppression: ${ref.read(courseProvider).errorMessage ?? "Erreur inconnue"}'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                     _navigateToEditPage(context, course: course); // Ou vers une page de détails dédiée
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _navigateToEditPage(context); // Appel sans argument 'course' pour l'ajout
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        tooltip: 'Ajouter un nouveau cours',
      ),
    );
  }
}
