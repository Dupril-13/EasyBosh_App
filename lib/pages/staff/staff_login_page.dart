import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffLoginPage extends StatefulWidget {
  const StaffLoginPage({super.key});

  @override
  State<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // Pour la visibilité du mot de passe
  final _supabase = Supabase.instance.client;

  Future<void> _login() async {
    if (!mounted || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (res.user != null) {
        final String? appRole = res.user?.appMetadata?['app_role'];
        // ignore: avoid_print
        print('App Role from Supabase: $appRole'); // Log pour débogage

        if (appRole == 'admin') {
          context.go('/admin/dashboard');
        } else if (appRole == 'teacher') {
          context.go('/teacher/dashboard');
        } else {
          await _supabase.auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Accès non autorisé pour ce rôle.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec de la connexion. Utilisateur non trouvé.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Erreur d\'authentification.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Une erreur inattendue est survenue: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Panneau de gauche (toujours affiché)
          Expanded(
              flex: 2,
              child: Container(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/Easybosh_staff_logo.png', height: 120, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, size: 90)), // Logo avec fallback
                    const SizedBox(height: 16.0),
                    Text(
                      'Bienvenue sur l\'Espace Staff Easybosh',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColorDark,
                          ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Gérez efficacement vos cours, épreuves, quiz et analysez les performances des étudiants.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.black54,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 24.0), 
                    Image.asset(
                      'assets/images/Thesis-pana.png', 
                      height: 220,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, size: 90) 
                    ),
                    const SizedBox(height: 24.0), 
                    const Spacer(),
                    Text(
                      '© ${DateTime.now().year} Easybosh. Tous droits réservés.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          // Panneau de droite (formulaire)
          Expanded(
            flex: 3,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container( // Conteneur extérieur pour la bordure
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue, // Couleur de la bordure
                            width: 2.0,       // Épaisseur de la bordure
                          ),
                          borderRadius: BorderRadius.circular(12.0), // Coins arrondis
                        ),
                        child: ClipRRect( // Pour que le BackdropFilter respecte les coins arrondis
                          borderRadius: BorderRadius.circular(12.0),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                            child: Container( // Conteneur intérieur pour le padding et le contenu sur le flou
                              padding: const EdgeInsets.all(24.0), // Padding pour le contenu
                              color: Colors.transparent, // Changé pour être transparent
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Connectez-vous',
                                    textAlign: TextAlign.start,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Utilisez vos identifiants fournis par l\'administration.',
                                    textAlign: TextAlign.start,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 32.0),
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        TextFormField(
                                          controller: _emailController,
                                          decoration: const InputDecoration(
                                            labelText: 'Adresse e-mail',
                                            prefixIcon: Icon(Icons.person_outline),
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Veuillez entrer votre adresse e-mail.';
                                            }
                                            if (!value.contains('@')) { 
                                              return 'Adresse e-mail invalide.';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16.0),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          decoration: InputDecoration(
                                            labelText: 'Mot de passe',
                                            prefixIcon: const Icon(Icons.lock_outline),
                                            border: const OutlineInputBorder(),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Veuillez entrer votre mot de passe.';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 32.0),
                                        _isLoading
                                            ? const Center(child: CircularProgressIndicator())
                                            : ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                  backgroundColor: Theme.of(context).primaryColor,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                ),
                                                onPressed: _isLoading ? null : _login,
                                                child: const Text('Se Connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
