import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Pour la cohérence avec les autres pages
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        // GoRouter devrait ajouter automatiquement un bouton de retour.
        // Si ce n'est pas le cas ou si vous souhaitez un style spécifique :
        // leading: IconButton(
        //   icon: Icon(Iconsax.arrow_left_2, color: Colors.grey[700]), // Nécessiterait l'import Iconsax
        //   onPressed: () => context.pop(),
        //   tooltip: 'Retour',
        // ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Aucune notification disponible pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.0, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
