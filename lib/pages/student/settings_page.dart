import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../pages/student/help_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoSaveEnabled = true;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F5F5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Mon Profil
            _buildSection(
              title: 'Mon Profil',
              children: [
                _buildSection(
                  title: 'Informations personnelles',
                  children: [
                    _buildEditableField(
                      icon: Icons.person,
                      title: 'Nom complet',
                      value: 'Dupril Inuwa',
                      onTap: () => _showEditDialog(context, 'Nom complet', 'Dupril Inuwa'),
                    ),
                    _buildEditableField(
                      icon: Icons.email,
                      title: 'Email',
                      value: 'duprilinuwa@gmail.com',
                      onTap: () => _showEditDialog(context, 'Email', 'duprilinuwa@gmail.com'),
                    ),
                    _buildEditableField(
                      icon: Icons.phone,
                      title: 'Téléphone',
                      value: '+237 6 52 01 49 82',
                      onTap: () => _showEditDialog(context, 'Téléphone', '+237 6 52 01 49 82'),
                    ),
                  ],
                ),

                _buildSection(
                  title: 'Informations académiques',
                  children: [
                    _buildEditableField(
                      icon: Icons.school,
                      title: 'Classe',
                      value: 'Tle',
                      onTap: () => _showEditDialog(context, 'Classe', 'Tle'),
                    ),
                    _buildEditableField(
                      icon: Icons.book,
                      title: 'Série',
                      value: 'C',
                      onTap: () => _showEditDialog(context, 'Série', 'C'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Section Thème
            _buildSection(
              title: 'Thème',
              children: [
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  title: 'Mode sombre',
                  subtitle: 'Activer le thème sombre',
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.auto_awesome,
                  title: 'Thème automatique',
                  subtitle: 'Suivre les préférences système',
                  value: !_darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = !value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Section À Propos
            _buildSection(
              title: 'À Propos',
              children: [

                _buildSection(
                  title: 'Application',
                  children: [
                    _buildInfoTile(
                      icon: Icons.info_outline,
                      title: 'Version',
                      subtitle: '2.0.0',
                    ),
                    _buildInfoTile(
                      icon: Icons.update,
                      title: 'Dernière mise à jour',
                      subtitle: '22 Septembre 2025',
                    ),
                    _buildInfoTile(
                      icon: Icons.developer_mode,
                      title: 'Développeur',
                      subtitle: 'EasyBosh Team',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Section Autres
            _buildSection(
              title: 'Autres',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Recevoir des notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.save,
                  title: 'Sauvegarde automatique',
                  subtitle: 'Sauvegarder automatiquement',
                  value: _autoSaveEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoSaveEnabled = value;
                    });
                  },
                ),
                _buildListTile(
                  icon: Icons.help_outline,
                  title: 'Aide et support',
                  subtitle: 'Tutoriels et FAQ',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HelpPage(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.delete_forever,
                  title: 'Supprimer mon compte',
                  subtitle: 'Supprimer définitivement',
                  onTap: () {
                    _showDeleteAccountDialog(context);
                  },
                ),
                _buildListTile(
                  icon: Icons.logout,
                  title: 'Se déconnecter',
                  subtitle: 'Fermer la session',
                  onTap: () async {
                    await _supabase.auth.signOut();
                    if (mounted) {
                      context.go('/get-started');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit, color: Colors.blue),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
      onTap: onTap,
    );
  }

  void _showEditDialog(BuildContext context, String field, String currentValue) {
    final TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Modifier $field'),
        content: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveProfileField(dialogContext, field, controller.text);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              if (!dialogContext.mounted) return;
              _showInfoDialog(dialogContext, 'Succès', '$field modifié avec succès');
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileField(BuildContext context, String field, String value) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Mapper les champs aux colonnes de la base de données
        String columnName = '';
        switch (field) {
          case 'Nom complet':
            columnName = 'nom';
            break;
          case 'Email':
            columnName = 'email';
            break;
          case 'Téléphone':
            columnName = 'telephone';
            break;
          case 'Classe':
            columnName = 'classe';
            break;
          case 'Série':
            columnName = 'serie';
            break;
          default:
            throw Exception('Champ inconnu: $field');
        }

        // Mettre à jour dans la base de données
        await Supabase.instance.client
            .from('users')
            .update({columnName: value})
            .eq('uid', user.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  // Supprimer l'utilisateur de la base de données
                  await Supabase.instance.client
                      .from('users')
                      .delete()
                      .eq('uid', user.id);

                  // Déconnexion
                  await Supabase.instance.client.auth.signOut();

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    context.go('/get-started');
                    _showInfoDialog(dialogContext, 'Succès', 'Votre compte a été supprimé');
                  }
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  _showInfoDialog(dialogContext, 'Erreur', 'Impossible de supprimer le compte: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}