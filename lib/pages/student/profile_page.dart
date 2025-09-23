import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userModel;
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  String? _selectedClasse;
  String? _selectedSerie;

  final List<String> _classes = ["3ème", "1ère", "Tle"];
  final List<String> _series = ["A", "C", "D", "TI"];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final userData = await _supabase
            .from('users')
            .select()
            .eq('uid', user.id)
            .single();

        if (userData != null) {
          setState(() {
            _userModel = userData;
            _nomController.text = _userModel?['nom'] ?? '';
            _prenomController.text = _userModel?['prenom'] ?? '';
            _selectedClasse = _userModel?['classe'];
            _selectedSerie = _userModel?['serie'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null && _userModel != null) {
        final updatedUser = Map<String, dynamic>.from(_userModel!)
          ..addAll({
            'nom': _nomController.text.trim(),
            'prenom': _prenomController.text.trim(),
            'classe': _selectedClasse,
            'serie': _selectedSerie,
            'updated_at': DateTime.now().toIso8601String(),
          });

        await _supabase
            .from('users')
            .update(updatedUser)
            .eq('uid', user.id);

        setState(() {
          _userModel = updatedUser;
          _isEditing = false;
        });

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        context.go('/get-started');
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.grey[700],
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  // Restaurer les valeurs originales
                  _nomController.text = _userModel?['nom'] ?? '';
                  _prenomController.text = _userModel?['prenom'] ?? '';
                  _selectedClasse = _userModel?['classe'];
                  _selectedSerie = _userModel?['serie'];
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du profil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      _getInitials(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userModel?['email'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userModel?['email_verified'] == true ? 'Email vérifié' : 'Email non vérifié',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Formulaire de profil
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations personnelles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nom
                  TextFormField(
                    controller: _nomController,
                    enabled: _isEditing,
                    decoration: _buildInputDecoration(
                      labelText: 'Nom',
                      hintText: 'Entrez votre nom',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Prénom
                  TextFormField(
                    controller: _prenomController,
                    enabled: _isEditing,
                    decoration: _buildInputDecoration(
                      labelText: 'Prénom',
                      hintText: 'Entrez votre prénom',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre prénom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Classe
                  DropdownButtonFormField<String>(
                    value: _selectedClasse,
                    decoration: _buildInputDecoration(
                      labelText: 'Classe',
                      hintText: 'Choisir votre classe',
                      prefixIcon: Icons.school_outlined,
                    ),
                    items: _classes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: _isEditing ? (String? newValue) {
                      setState(() {
                        _selectedClasse = newValue;
                      });
                    } : null,
                    validator: _isEditing ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez choisir votre classe';
                      }
                      return null;
                    } : null,
                  ),
                  const SizedBox(height: 16),

                  // Série
                  DropdownButtonFormField<String>(
                    value: _selectedSerie,
                    decoration: _buildInputDecoration(
                      labelText: 'Série',
                      hintText: 'Choisir votre série',
                      prefixIcon: Icons.school_outlined,
                    ),
                    items: _series.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: _isEditing ? (String? newValue) {
                      setState(() {
                        _selectedSerie = newValue;
                      });
                    } : null,
                    validator: _isEditing ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez choisir votre série';
                      }
                      return null;
                    } : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sauvegarder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Section des actions
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildActionTile(
              icon: Icons.email_outlined,
              title: 'Vérifier l\'email',
              subtitle: 'Renvoi de l\'email de vérification',
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  final user = _supabase.auth.currentUser;
                  if (user != null) {
                    await _supabase.auth.resend(
                      email: user.email!,
                      type: OtpType.signup,
                    );

                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Email de vérification envoyé !'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),

            _buildActionTile(
              icon: Icons.lock_outline,
              title: 'Changer le mot de passe',
              subtitle: 'Réinitialiser votre mot de passe',
              onTap: () {
                _showChangePasswordDialog();
              },
            ),

            _buildActionTile(
              icon: Icons.logout,
              title: 'Se déconnecter',
              subtitle: 'Fermer votre session',
              onTap: () async {
                await _signOut();
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    final nom = _userModel?['nom'] ?? '';
    final prenom = _userModel?['prenom'] ?? '';

    if (nom.isNotEmpty && prenom.isNotEmpty) {
      return '${prenom[0]}${nom[0]}'.toUpperCase();
    } else if (nom.isNotEmpty) {
      return nom[0].toUpperCase();
    } else if (prenom.isNotEmpty) {
      return prenom[0].toUpperCase();
    } else {
      return 'U';
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.blueAccent,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmNewPasswordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Ancien mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre ancien mot de passe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nouveau mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmNewPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez confirmer le nouveau mot de passe';
                  }
                  if (value != newPasswordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                await _changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );
              }
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null && user.email != null) {
        // Vérifier l'ancien mot de passe en se reconnectant
        await _supabase.auth.signInWithPassword(
          email: user.email!,
          password: oldPassword,
        );

        // Changer le mot de passe
        await _supabase.auth.updateUser(
          UserAttributes(
            password: newPassword,
          ),
        );

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Mot de passe changé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur lors du changement de mot de passe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}