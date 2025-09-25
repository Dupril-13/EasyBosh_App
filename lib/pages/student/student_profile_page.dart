import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easybosh_v2/providers/auth_provider.dart'; 
import 'package:easybosh_v2/models/profile_model.dart'; 

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil Étudiant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              // La redirection sera gérée par votre GoRouter en écoutant les changements d'état
              // Pour l'instant, on peut forcer une redirection si GoRouter n'est pas configuré pour écouter
              // GoRouter.of(context).go('/auth/login'); // Exemple
            },
          )
        ],
      ),
      body: Center(
        child: Builder(
          builder: (context) {
            if (authState.isLoading && authState.userProfile == null) {
              return const CircularProgressIndicator();
            }

            if (authState.errorMessage != null && authState.userProfile == null) {
              // Afficher le message d'erreur et un bouton pour rafraîchir
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erreur: ${authState.errorMessage}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                       ref.read(authProvider.notifier).refreshAuthStatusAndProfile();
                    },
                    child: const Text("Réessayer de charger le profil"),
                  )
                ],
              );
            }

            final profile = authState.userProfile;
            final supabaseUser = authState.supabaseUser;

            if (profile == null || supabaseUser == null) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Aucun profil utilisateur trouvé ou utilisateur non connecté.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                       // Tenter de rafraîchir ou rediriger vers login
                       // GoRouter.of(context).go('/auth/login');
                       ref.read(authProvider.notifier).refreshAuthStatusAndProfile();
                    },
                    child: const Text("Tenter de recharger / Se connecter"),
                  )
                ],
              );
            }
            
            if (profile.role != UserRole.student) {
              return const Center(
                child: Text('Accès réservé aux étudiants. Veuillez vous connecter avec un compte étudiant.'),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView( // Utiliser ListView pour le défilement si le contenu est long
                children: <Widget>[
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) 
                          ? NetworkImage(profile.avatarUrl!) 
                          : null,
                      child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                          ? Text(profile.initials, style: const TextStyle(fontSize: 40))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(child: Text(profile.displayFullName, style: Theme.of(context).textTheme.headlineSmall)),
                  const SizedBox(height: 10),
                  Center(child: Text(UserRoleHelper.asString(profile.role).toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.blueAccent))),                  
                  const SizedBox(height: 30),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email_outlined, color: Colors.blueAccent),
                          title: const Text('Email'),
                          subtitle: Text(supabaseUser.email ?? 'Non fourni'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person_outline, color: Colors.blueAccent),
                          title: const Text('Prénom'),
                          subtitle: Text(profile.firstName ?? 'Non fourni'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person_pin_outlined, color: Colors.blueAccent),
                          title: const Text('Nom'),
                          subtitle: Text(profile.lastName ?? 'Non fourni'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.school_outlined, color: Colors.blueAccent),
                          title: const Text('Niveau'),
                          subtitle: Text(profile.studentLevelCode ?? 'Non fourni'), // Idéalement, afficher le nom du niveau
                        ),
                        ListTile(
                          leading: const Icon(Icons.book_outlined, color: Colors.blueAccent),
                          title: const Text('Série'),
                          subtitle: Text(profile.studentSerieCode ?? 'Non applicable'), // Idéalement, afficher le nom de la série
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined, color: Colors.blueAccent),
                          title: const Text('Téléphone'),
                          subtitle: Text(profile.phoneNumber ?? 'Non fourni'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.cake_outlined, color: Colors.blueAccent),
                          title: const Text('Date de naissance'),
                          subtitle: Text(profile.dateOfBirth?.toLocal().toString().split(' ').first ?? 'Non fournie'),
                        ),
                        ListTile(
                          leading: Icon(supabaseUser.emailConfirmedAt != null ? Icons.verified_user_outlined : Icons.warning_amber_rounded, color: supabaseUser.emailConfirmedAt != null ? Colors.green : Colors.orangeAccent),
                          title: const Text('Email Vérifié'),
                          subtitle: Text(supabaseUser.emailConfirmedAt != null ? 'Oui, le ${supabaseUser.emailConfirmedAt?.toLocal().toString().split(' ').first}' : 'Non'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.update_outlined, color: Colors.blueAccent),
                          title: const Text('Profil Mis à Jour le'),
                          subtitle: Text(profile.updatedAt?.toLocal().toString().split(' ').first ?? 'N/A'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     // Naviguer vers une page d'édition de profil
                  //     // context.go('/student/profile/edit');
                  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Page d'édition non implémentée.")));
                  //   },
                  //   child: const Text('Modifier mon profil'),
                  // ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
