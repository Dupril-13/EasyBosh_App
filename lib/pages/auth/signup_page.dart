import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClasse; // Stocke la valeur affichée (ex: "Troisième")
  String? _selectedSerie;  // Stocke la valeur affichée (ex: "Série A")

  // Controllers pour les champs de texte
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Maps pour la correspondance Affichage <-> Code BD
  // IMPORTANT: Les VALEURS (codes) doivent correspondre EXACTEMENT aux `code` dans vos tables `niveaux` et `series`
  final Map<String, String> _classesMap = {
    "Troisième": "3eme",
    "Première": "1ere",
    "Terminale": "tle",
  };

  final Map<String, String> _seriesMap = {
    "Série A": "A",
    "Série C": "C",
    "Série D": "D",
    "Série TI": "TI", // Assurez-vous que 'TI' est un code valide dans votre table series
  };

  late List<String> _displayClasses;
  late List<String> _displaySeries;

  // Constantes pour l'espacement
  static const SizedBox _gapH10 = SizedBox(height: 10);
  static const SizedBox _gapH20 = SizedBox(height: 20);
  static const SizedBox _gapH25 = SizedBox(height: 25);
  static const SizedBox _gapH30 = SizedBox(height: 30);
  static const SizedBox _gapW16 = SizedBox(width: 16);

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final SupabaseClient _supabase = Supabase.instance.client;

 @override
  void initState() {
    super.initState();
    _displayClasses = _classesMap.keys.toList();
    _displaySeries = _seriesMap.keys.toList();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Inscription avec Supabase
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final String? selectedLevelCode = _selectedClasse != null ? _classesMap[_selectedClasse!] : null;
    final String? selectedSerieCode = _selectedSerie != null ? _seriesMap[_selectedSerie!] : null;

    if (_selectedClasse != null && selectedLevelCode == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Code de classe invalide pour la base de données.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (_selectedClasse != null && _classesMap[_selectedClasse!] != '3eme' && _selectedSerie != null && selectedSerieCode == null) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Code de série invalide pour la base de données.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> userMetaData = {
        'first_name': _prenomController.text.trim(),
        'last_name': _nomController.text.trim(),
        'full_name': '${_prenomController.text.trim()} ${_nomController.text.trim()}',
        'student_level_code': selectedLevelCode,
        'student_serie_code': (selectedLevelCode == '3eme') ? null : selectedSerieCode,
        'role': 'student',
      };

      final AuthResponse response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: userMetaData,
      );

      if (mounted) {
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.session == null && response.user!.emailConfirmedAt == null
                  ? 'Compte créé ! Veuillez vérifier votre e-mail pour le code de vérification.' // Message ajusté pour OTP
                  : 'Compte créé avec succès !', // Moins probable si la vérification est active
              ),
              backgroundColor: Colors.green,
            ),
          );
          if (response.session == null && response.user!.emailConfirmedAt == null) {
             // Passer l'email est optionnel mais peut être utile pour la page de vérification
             context.go('/auth/verification', extra: {'email': _emailController.text.trim()});
          } else {
            // Si pour une raison l'email est déjà confirmé (ex: vérification désactivée par admin)
            context.go('/student/profile'); // Ou /auth/login
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de l\'inscription. Utilisateur non retourné.'), backgroundColor: Colors.red),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'authentification: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur inattendue est survenue: $e'), backgroundColor: Colors.red),
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

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIconData,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIconData, color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
      suffixIcon: suffixIcon,
    );
  }

  DropdownButtonFormField<String> _buildDropdownField({
    required String labelText,
    required String? currentValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required FormFieldValidator<String> validator,
  }) {
    return DropdownButtonFormField<String>(
      decoration: _buildInputDecoration(labelText: labelText, hintText: 'Choisir', prefixIconData: Icons.school_outlined),
      value: currentValue,
      items: items.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Créer un compte', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                _gapH10,
                Text('Remplissez les informations', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                _gapH30,
                TextFormField(
                  controller: _nomController,
                  decoration: _buildInputDecoration(labelText: 'Nom', hintText: 'Entrez votre nom', prefixIconData: Icons.person_outline),
                  validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer votre nom' : null,
                ),
                _gapH20,
                TextFormField(
                  controller: _prenomController,
                  decoration: _buildInputDecoration(labelText: 'Prénom', hintText: 'Entrez votre prénom', prefixIconData: Icons.person_outline),
                  validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer votre prénom' : null,
                ),
                _gapH20,
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildDropdownField(
                        labelText: 'Classe',
                        currentValue: _selectedClasse,
                        items: _displayClasses,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedClasse = newValue;
                            if (newValue != null && _classesMap[newValue] == '3eme') { 
                              _selectedSerie = null;
                            }
                          });
                        },
                        validator: (value) => value == null ? 'Choisissez une classe' : null,
                      ),
                    ),
                    _gapW16,
                    if (_selectedClasse != null && _classesMap[_selectedClasse!] != '3eme') 
                      Expanded(
                        child: _buildDropdownField(
                          labelText: 'Série',
                          currentValue: _selectedSerie,
                          items: _displaySeries, 
                          onChanged: (newValue) {
                            setState(() {
                              _selectedSerie = newValue; 
                            });
                          },
                          validator: (value) => (_selectedClasse != null && _classesMap[_selectedClasse!] != '3eme' && value == null)
                              ? 'Choisissez une série'
                              : null,
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
                _gapH20,
                TextFormField(
                  controller: _emailController,
                  decoration: _buildInputDecoration(labelText: 'Email', hintText: 'Entrez votre adresse email', prefixIconData: Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
                    if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) return 'Veuillez entrer un email valide';
                    return null;
                  },
                ),
                _gapH20,
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _buildInputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Créez un mot de passe',
                    prefixIconData: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[600]),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
                    if (value.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
                    return null;
                  },
                ),
                _gapH20,
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: _buildInputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    hintText: 'Retapez votre mot de passe',
                    prefixIconData: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[600]),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez confirmer votre mot de passe';
                    if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                _gapH30,
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 7,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text("S'inscrire", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _gapH25,
                GestureDetector(
                  onTap: () => context.go('/auth/login'),
                  child: Text.rich(
                    TextSpan(
                      text: 'Déjà inscrit ? ', 
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      children: const <TextSpan>[
                        TextSpan(text: 'Se connecter', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, decorationColor: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                _gapH20,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
