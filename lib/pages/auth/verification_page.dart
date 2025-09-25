import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class VerificationPage extends ConsumerStatefulWidget {
  final String? email;

  const VerificationPage({super.key, this.email});

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers and FocusNodes for 6 OTP fields
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;

  bool _isLoading = false;
  bool _isResending = false;
  Timer? _timer;
  int _timeLeft = 60;

  String get _userEmailForDisplay =>
      widget.email ?? _supabase.auth.currentUser?.email ?? 'votre adresse email';

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) {
          setState(() {
            _timeLeft--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  String _getOtpFromFields() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    // Basic validation: check if all fields are filled
    final String otp = _getOtpFromFields();
    if (otp.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer les 6 chiffres du code OTP.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String? emailForVerification = widget.email ?? _supabase.auth.currentUser?.email;

    if (emailForVerification == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "L'adresse e-mail pour la vérification est introuvable. Veuillez retourner à l'inscription."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
      }
      return;
    }

    try {
      final AuthResponse response = await _supabase.auth.verifyOTP(
        token: otp,
        type: OtpType.signup,
        email: emailForVerification,
      );

      if (mounted) {
        if (response.session != null && response.user?.emailConfirmedAt != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email vérifié avec succès ! Redirection...'), backgroundColor: Colors.green),
          );
          context.go('/cours');
        } else {
          await _supabase.auth.refreshSession();
          final updatedUser = _supabase.auth.currentUser;
          if (updatedUser?.emailConfirmedAt != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email vérifié après rafraîchissement ! Redirection...'), backgroundColor: Colors.green),
            );
            context.go('/cours');
          } else {
            throw Exception(
                "La vérification OTP semble avoir réussi mais la confirmation de l'email n'a pas été enregistrée.");
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de vérification OTP: ${e.message}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur inattendue: ${e.toString()}"), backgroundColor: Colors.red),
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

  Future<void> _resendOtpEmail() async {
    setState(() {
      _isResending = true;
    });

    final String? emailForResend = widget.email ?? _supabase.auth.currentUser?.email;
    if (emailForResend == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible de trouver l\'email pour renvoyer le code."), backgroundColor: Colors.red),
        );
        setState(() => _isResending = false);
      }
      return;
    }

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: emailForResend,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nouveau code de vérification envoyé !'), backgroundColor: Colors.green),
        );
        _startTimer();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors du renvoi: ${e.message}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur inattendue: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Widget _buildOtpTextField(int index) {
    return SizedBox(
      width: 45, // Largeur de chaque carreau OTP
      height: 55, // Hauteur de chaque carreau OTP
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: "", // Hide the counter text
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          contentPadding: EdgeInsets.zero, // Adjust padding for better centering of text
        ),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            } else {
              _otpFocusNodes[index].unfocus(); // Unfocus if last field is filled
            }
          }
        },
        // Handle backspace for previous field focus
        onTap: () { // This helps manage focus when a field is already filled and tapped
          if (_otpControllers[index].text.isEmpty && index > 0 && _otpControllers[index-1].text.isNotEmpty) {
             // If current is empty, and previous is not, backspace should focus previous
          } else if (_otpControllers[index].text.isNotEmpty && index < 5) {
            // If current is full and tapped, select its content to allow overwrite
            _otpControllers[index].selection = TextSelection(baseOffset: 0, extentOffset: _otpControllers[index].text.length);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[800]),
          onPressed: () => context.go('/auth/login'),
        ),
        title: const Text('Vérification Email', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Form(
            key: _formKey, // _formKey is not strictly necessary for validation with this OTP setup, but can be kept
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.shield_moon_outlined, size: 90, color: Colors.blueAccent),
                ),
                const SizedBox(height: 30),
                const Text('Entrez le code de vérification', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                Text('Un code à 6 chiffres a été envoyé à', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Text(_userEmailForDisplay, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                const SizedBox(height: 30),
                // OTP Input Fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) => _buildOtpTextField(index)),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 7,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('Vérifier le code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                Text('Vous n\'avez pas reçu le code ? ', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isResending || _timeLeft > 0 ? null : _resendOtpEmail,
                  child: _isResending
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          _timeLeft > 0 ? 'Renvoyer (${_timeLeft}s)' : 'Renvoyer le code',
                          style: TextStyle(color: _timeLeft > 0 ? Colors.grey : Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
