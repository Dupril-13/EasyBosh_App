import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/app_config.dart';

/// Page de démarrage affichée pendant l'initialisation
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animé
            SizedBox(
              width: 120,
              height: 120,
              child: Image.asset(
                'assets/images/Logo_Easybosh_no_bg.png',
                // Vous pouvez ajouter un fit si nécessaire, par exemple BoxFit.contain
              ),
            )
                .animate()
                .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
                .then()
                .shake(duration: 500.ms),

            const SizedBox(height: 32),

            // Nom de l'application
            Text(
              AppConfig.appName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 800.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            // Slogan
            Text(
              'Votre réussite commence ici',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w300,
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 800.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 60),

            // Indicateur de chargement
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
                strokeWidth: 3,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(delay: 900.ms)
                .then()
                .rotate(duration: 2000.ms),

            const SizedBox(height: 24),

            // Version
            Text(
              'Version ${AppConfig.appVersion}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w300,
              ),
            )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}