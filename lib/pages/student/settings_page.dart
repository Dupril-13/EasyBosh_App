import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../pages/student/help_page.dart'; // Assurez-vous que cette page existe ou commentez l'import si non utilisée

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userData = await _supabase
            .from('users')
            .select()
            .eq('uid', user.id)
            .single();

        if (mounted && userData != null) {
          setState(() {
            _userModel = userData;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement du profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials() {
    String initials = "U"; // Utilisateur par défaut
    final String? firstName = _userModel?['prenom'];
    final String? lastName = _userModel?['nom'];

    if (firstName != null && firstName.isNotEmpty) {
      initials = firstName[0].toUpperCase();
      if (lastName != null && lastName.isNotEmpty) {
        initials += lastName[0].toUpperCase();
      } else if (firstName.length > 1) {
        initials += firstName[1].toUpperCase();
      }
    } else if (lastName != null && lastName.isNotEmpty) {
      initials = lastName[0].toUpperCase();
      if (lastName.length > 1) {
        initials += lastName[1].toUpperCase();
      }
    }
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Paramètres',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFFF5F5F5),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isEmailVerified = _supabase.auth.currentUser?.emailConfirmedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFFF5F5F5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _getInitials(),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            _buildSection(
              context,
              title: 'Mon Profil',
              children: [
                _buildEditableField(
                  icon: Iconsax.user,
                  title: 'Nom',
                  value: _userModel?['nom'] ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Nom', _userModel?['nom'] ?? ''),
                ),
                _buildEditableField(
                  icon: Iconsax.user,
                  title: 'Prénom',
                  value: _userModel?['prenom'] ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Prénom', _userModel?['prenom'] ?? ''),
                ),
                _buildEditableField(
                  icon: Iconsax.sms,
                  title: 'Email',
                  value: _userModel?['email'] ?? _supabase.auth.currentUser?.email ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Email', _userModel?['email'] ?? _supabase.auth.currentUser?.email ?? ''),
                  verificationStatusWidget: Icon(
                    isEmailVerified ? Iconsax.tick_circle : Iconsax.info_circle,
                    color: isEmailVerified ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                _buildEditableField(
                  icon: Iconsax.call,
                  title: 'Téléphone',
                  value: _userModel?['telephone'] ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Téléphone', _userModel?['telephone'] ?? ''),
                ),
                _buildEditableField(
                  icon: Iconsax.teacher,
                  title: 'Classe',
                  value: _userModel?['classe'] ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Classe', _userModel?['classe'] ?? ''),
                ),
                _buildEditableField(
                  icon: Iconsax.book,
                  title: 'Série',
                  value: _userModel?['serie'] ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Série', _userModel?['serie'] ?? ''),
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'Thème',
              children: [
                _buildSwitchTile(
                  icon: Iconsax.moon,
                  title: 'Mode sombre',
                  subtitle: 'Activer le thème sombre',
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'À Propos',
              children: [
                _buildInfoTile(
                  icon: Iconsax.info_circle,
                  title: 'Version',
                  subtitle: '2.0.0', 
                ),
                _buildInfoTile(
                  icon: Iconsax.code,
                  title: 'Développeur',
                  subtitle: 'EasyBosh Team',
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'Autres',
              children: [
                _buildSwitchTile(
                  icon: Iconsax.notification,
                  title: 'Notifications',
                  subtitle: 'Recevoir des notifications de l\'application',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildListTile(
                  icon: Iconsax.message_question,
                  title: 'Aide et support',
                  subtitle: 'Consulter la FAQ ou contacter le support',
                  onTap: () {
                     context.go('/help'); // CORRIGÉ: Navigation vers HelpPage
                  },
                ),
                _buildListTile(
                  icon: Iconsax.trash,
                  title: 'Supprimer mon compte',
                  subtitle: 'Cette action est irréversible',
                  onTap: () {
                    _showDeleteAccountDialog(context);
                  },
                  textColor: Colors.red,
                  iconColor: Colors.red,
                ),
                _buildListTile(
                  icon: Iconsax.logout,
                  title: 'Se déconnecter',
                  subtitle: 'Fermer votre session actuelle',
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

  Widget _buildSection(BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: children,
            ), 
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? verificationStatusWidget,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: TextStyle(color: Colors.grey[600])),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (verificationStatusWidget != null) ...[
            verificationStatusWidget,
            const SizedBox(width: 8),
          ],
          Icon(Iconsax.edit, color: Theme.of(context).colorScheme.secondary, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: textColor ?? Colors.grey[600])),
      trailing: Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 16),
      onTap: onTap,
    );
  }

  void _showEditDialog(BuildContext pageContext, String field, String currentValue) {
    final TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Modifier $field'),
        content: TextFormField(
          controller: controller,
          autofocus: true,
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
              await _saveProfileField(dialogContext, field, controller.text.trim()); 
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileField(BuildContext dialogContext, String field, String value) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non authentifié.');

      String columnName = '';
      switch (field) {
        case 'Nom':
          columnName = 'nom';
          break;
        case 'Prénom':
          columnName = 'prenom';
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
          throw Exception('Champ inconnu pour la sauvegarde: $field');
      }

      await _supabase
          .from('users')
          .update({columnName: value, 'updated_at': DateTime.now().toIso8601String()})
          .eq('uid', user.id);

      if (mounted) {
        setState(() {
          if (_userModel != null) {
            _userModel![columnName] = value;
          }
        });
        Navigator.of(dialogContext).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('$field modifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(dialogContext).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde de $field: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
       if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext pageContext) {
    showDialog(
      context: pageContext,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(pageContext); 
              final router = GoRouter.of(pageContext);
              bool dialogStillMounted = true;

              try {
                final user = _supabase.auth.currentUser;
                if (user == null) throw Exception('Utilisateur non authentifié.');

                await _supabase.from('users').delete().eq('uid', user.id);
                await _supabase.auth.signOut();
                
                if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    dialogStillMounted = false;
                }

                if(pageContext.mounted) {
                    router.go('/get-started');
                    scaffoldMessenger.showSnackBar(
                        const SnackBar(
                        content: Text('Votre compte a été supprimé avec succès.'),
                        backgroundColor: Colors.green,
                        ),
                    );
                }

              } catch (e) {
                if (dialogStillMounted && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                 if(pageContext.mounted) {
                    scaffoldMessenger.showSnackBar(
                        SnackBar(
                        content: Text('Impossible de supprimer le compte: $e'),
                        backgroundColor: Colors.red,
                        ),
                    );
                 }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
