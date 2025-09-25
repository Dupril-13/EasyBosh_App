import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    // Simulate network request & role check
    // In a real app, this would be an API call to Supabase
    await Future.delayed(const Duration(seconds: 1)); 

    final email = _emailController.text;
    final password = _passwordController.text;
    String role = "none";

    // TODO: Replace with actual Supabase authentication and role checking
    // For now, using placeholder logic:
    // admin@easybosh.com / adminpass -> admin
    // teacher@easybosh.com / teacherpass -> teacher
    if (email.toLowerCase() == 'admin@easybosh.com' && password == 'adminpass') {
      role = "admin";
    } else if (email.toLowerCase() == 'teacher@easybosh.com' && password == 'teacherpass') {
      role = "teacher";
    }

    setState(() {
      _isLoading = false;
    });

    if (role == "admin") {
      // ignore: use_build_context_synchronously
      context.go('/admin-dashboard'); 
    } else if (role == "teacher") {
      // ignore: use_build_context_synchronously
      context.go('/teacher-dashboard');
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifiants incorrects ou rôle non autorisé.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final screenWidth = MediaQuery.of(context).size.width;
    bool isLargeScreen = screenWidth > 800; // Arbitrary breakpoint for desktop layout

    return Scaffold(
      body: Row(
        children: [
          // Section Gauche (Informationnelle) - Visible seulement sur grand écran
          if (isLargeScreen)
            Expanded(
              flex: 2, // Ajustez le flex pour la proportion souhaitée
              child: Container(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // TODO: Remplacez par votre logo (ex: Image.asset('assets/icons/Logo_Easybosh.png', height: 80))
                    Icon(
                      Icons.school_outlined, 
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 32.0),
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
                    const Spacer(),
                    Text(
                      '© ${DateTime.now().year} Easybosh. Tous droits réservés.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

          // Section Droite (Formulaire de Connexion)
          Expanded(
            flex: isLargeScreen ? 3 : 5, // Prend plus de place sur petit écran
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450), // Largeur max du formulaire
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (!isLargeScreen) ...[ // Afficher le logo et titre si la section gauche est cachée
                        // TODO: Remplacez par votre logo
                        Icon(
                          Icons.school_outlined,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 24.0),
                        Text(
                          'Espace Staff Easybosh',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 32.0),
                      ],
                       Text(
                        'Connectez-vous',
                        textAlign: isLargeScreen ? TextAlign.start : TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Utilisez vos identifiants fournis par l\'administration.',
                         textAlign: isLargeScreen ? TextAlign.start : TextAlign.center,
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
                                if (!value.contains('@')) { // Validation simple
                                  return 'Adresse e-mail invalide.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: Icon(Icons.lock_outline),
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
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
                                    onPressed: _login,
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
    );
  }
}
