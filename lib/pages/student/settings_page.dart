import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _userModel; // Will hold data from 'profiles' table
  bool _isLoading = true;

  final _oldPasswordController = TextEditingController(); // Controller for old password
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
            .from('profiles') 
            .select()
            .eq('id', user.id) 
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
    String initials = "U";
    final String? firstName = _userModel?['first_name']; 
    final String? lastName = _userModel?['last_name'];

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
          title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          centerTitle: true,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFFF5F5F5),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final String userEmail = _supabase.auth.currentUser?.email ?? 'N/A';
    final bool isEmailVerified = _supabase.auth.currentUser?.emailConfirmedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
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
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _userModel?['full_name'] ?? ((_userModel?['first_name'] ?? '') + ' ' + (_userModel?['last_name'] ?? '')).trim(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              userEmail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              title: 'Mon Profil',
              children: [
                _buildEditableField(
                  icon: Iconsax.user,
                  title: 'Nom',
                  value: _userModel?['last_name'] ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Nom', _userModel?['last_name'] ?? ''),
                ),
                _buildEditableField(
                  icon: Iconsax.user_add,
                  title: 'Prénom',
                  value: _userModel?['first_name'] ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Prénom', _userModel?['first_name'] ?? ''),
                ),
                _buildEditableField(
                  icon: Iconsax.sms,
                  title: 'Email',
                  value: userEmail,
                  editable: false, 
                  verificationStatusWidget: Icon(
                    isEmailVerified ? Iconsax.tick_circle_copy : Iconsax.info_circle_copy,
                    color: isEmailVerified ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                _buildEditableField(
                  icon: Iconsax.call,
                  title: 'Téléphone',
                  value: _userModel?['phone_number'] ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Téléphone', _userModel?['phone_number'] ?? ''),
                ),
                _buildEditableField(
                  icon: Iconsax.teacher,
                  title: 'Niveau',
                  value: _userModel?['student_level_code'] ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Niveau', _userModel?['student_level_code'] ?? ''),
                ),
                _buildEditableField(
                  icon: Iconsax.book,
                  title: 'Série',
                  value: _userModel?['student_serie_code'] ?? 'N/A',
                  onTap: () => _showEditDialog(context, 'Série', _userModel?['student_serie_code'] ?? ''),
                ),
                 _buildListTile(
                  icon: Iconsax.key,
                  title: 'Changer le mot de passe',
                  subtitle: 'Modifier votre mot de passe actuel',
                  onTap: () => _showChangePasswordDialog(context),
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
                  subtitle: '2.0.2', // Minor version bump for tracking changes
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
                     context.go('/help');
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
    VoidCallback? onTap, 
    Color? iconColor,
    Widget? verificationStatusWidget,
    bool editable = true,
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
          if (editable)
            Icon(Iconsax.edit, color: Theme.of(context).colorScheme.secondary, size: 20),
        ],
      ),
      onTap: editable ? onTap : null,
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

  void _showEditDialog(BuildContext pageContext, String fieldTitle, String currentValue) {
    final TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Modifier $fieldTitle'),
        content: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: fieldTitle,
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
              await _saveProfileField(dialogContext, fieldTitle, controller.text.trim()); 
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileField(BuildContext dialogContext, String fieldTitle, String value) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non authentifié.');

      String columnName = '';
      switch (fieldTitle) {
        case 'Nom':
          columnName = 'last_name';
          break;
        case 'Prénom':
          columnName = 'first_name';
          break;
        case 'Téléphone':
          columnName = 'phone_number';
          break;
        case 'Niveau':
          columnName = 'student_level_code';
          break;
        case 'Série':
          columnName = 'student_serie_code';
          break;
        default:
          throw Exception('Champ inconnu pour la sauvegarde: $fieldTitle');
      }

      await _supabase
          .from('profiles')
          .update({columnName: value, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          if (_userModel != null) {
            _userModel![columnName] = value;
            if (columnName == 'first_name' || columnName == 'last_name') {
                 _userModel!['full_name'] = (_userModel!['first_name'] ?? '') + ' ' + (_userModel!['last_name'] ?? '');
            }
          }
        });
        Navigator.of(dialogContext).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('$fieldTitle modifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(dialogContext).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde de $fieldTitle: $e'),
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

  void _showChangePasswordDialog(BuildContext pageContext) {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Form(
          key: _passwordFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Ancien mot de passe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Iconsax.password_check),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre ancien mot de passe.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Iconsax.lock_1),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nouveau mot de passe.';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit comporter au moins 6 caractères.';
                  }
                  // Optionally: check if new password is same as old if you want to enforce change
                  // if (_oldPasswordController.text == value) {
                  //   return 'Le nouveau mot de passe doit être différent de l\'ancien.';
                  // }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Iconsax.lock_slash),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez confirmer le nouveau mot de passe.';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Les mots de passe ne correspondent pas.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_passwordFormKey.currentState!.validate()) {
                // Note: _oldPasswordController.text is captured but not directly used by Supabase updateUser.
                // It's for UX validation; actual password change relies on the user being authenticated.
                _handleChangePassword(dialogContext, _newPasswordController.text);
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChangePassword(BuildContext dialogContext, String newPassword) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    bool dialogWasPopped = false;
    bool mainPageIsLoading = _isLoading;

    if(mounted) {
      setState(() {
        _isLoading = true; 
      });
    }
    
    try {
      // Supabase updateUser for an authenticated user does not require the old password.
      // The _oldPasswordController is for UX purposes as per the request.
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      
      if(mounted) {
          Navigator.of(dialogContext).pop();
          dialogWasPopped = true;
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Mot de passe modifié avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
      }
    } on AuthException catch (e) {
      if (mounted) {
        if (!dialogWasPopped) Navigator.of(dialogContext).pop(); 
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification du mot de passe: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
       if (mounted) {
        if (!dialogWasPopped) Navigator.of(dialogContext).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Une erreur inattendue est survenue: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
         setState(() {
            _isLoading = mainPageIsLoading; 
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
          'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et supprimera vos données de profil associées.',
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
              bool mainPageIsLoading = _isLoading;

              // Accessing _SettingsPageState's setState to show loading on the main page
              final _SettingsPageState? parentState = pageContext.findAncestorStateOfType<_SettingsPageState>();
              parentState?.setState(() {
                parentState._isLoading = true;
              });

              try {
                final user = _supabase.auth.currentUser;
                if (user == null) throw Exception('Utilisateur non authentifié.');

                await _supabase.from('profiles').delete().eq('id', user.id);
                await _supabase.auth.signOut();
                
                if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    dialogStillMounted = false;
                }

                if(pageContext.mounted) {
                    router.go('/get-started');
                    scaffoldMessenger.showSnackBar(
                        const SnackBar(
                        content: Text('Votre profil a été supprimé et vous avez été déconnecté.'),
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
                        content: Text('Impossible de supprimer le profil: $e'),
                        backgroundColor: Colors.red,
                        ),
                    );
                 }
              } finally {
                if(pageContext.mounted) {
                  parentState?.setState(() {
                    parentState._isLoading = mainPageIsLoading;
                  });
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
