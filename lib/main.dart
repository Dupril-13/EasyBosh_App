import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Pour charger les variables d'environnement

import 'package:easybosh_v2/core/router/app_router.dart'; 
import 'package:easybosh_v2/core/theme/app_theme.dart'; // Décommenté et importé

// Provider pour le client Supabase, accessible globalement via ref.watch(supabaseClientProvider)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les variables d'environnement depuis le fichier .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Erreur lors du chargement du fichier .env: $e"); // Gérer l'erreur si le fichier n'est pas trouvé
    // Vous pourriez vouloir arrêter l'app ou utiliser des valeurs par défaut ici
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    print("ERREUR: SUPABASE_URL ou SUPABASE_ANON_KEY ne sont pas définies dans le fichier .env");
    // Arrêter l'application ou gérer cette erreur de configuration critique
    return; 
  }

  // Initialiser Supabase avec les variables d'environnement
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    // authFlowType: AuthFlowType.pkce, // Optionnel, pour le flux PKCE si vous l'utilisez
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Easybosh V2',
      theme: AppTheme.lightTheme, // Appliqué le thème clair
      darkTheme: AppTheme.darkTheme, // Thème sombre défini (au cas où, mais non utilisé avec ThemeMode.light)
      themeMode: ThemeMode.light, // Forcer le thème clair pour toute l'application
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
