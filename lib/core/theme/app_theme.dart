import 'package:flutter/material.dart';

/// Thème de l'application EasyBosh
class AppTheme {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF2196F3); // Bleu
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF26A69A); // Teal
  static const Color accentColor = Color(0xFFFF9800); // Orange

  // Couleurs de fond
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Couleurs de texte
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFBDBDBD);

  // Couleurs d'état
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Couleurs des matières (basées sur le système camerounais)
  static const Map<String, Color> subjectColors = {
    // Matières principales
    'MATH': Color(0xFF2196F3), // Bleu
    'FRAN': Color(0xFF9C27B0), // Violet
    'ANGL': Color(0xFFF44336), // Rouge
    'PHYS': Color(0xFFFF9800), // Orange
    'CHIM': Color(0xFF4CAF50), // Vert
    'PCT': Color(0xFFFF9800), // Orange (comme physique)
    'SVT': Color(0xFF8BC34A), // Vert clair
    'HIST_GEO': Color(0xFF795548), // Marron
    'PHIL': Color(0xFF009688), // Teal
    'INFO': Color(0xFF3F51B5), // Indigo
    'ECM': Color(0xFFFFC107), // Jaune
    'EPS': Color(0xFFFF5722), // Rouge orangé

    // Langues vivantes
    'ESP': Color(0xFFE91E63), // Rose
    'ALL': Color(0xFFFFEB3B), // Jaune
    'ITA': Color(0xFFFF9800), // Orange
    'CHI': Color(0xFFF44336), // Rouge

    // Matières facultatives
    'MUS': Color(0xFF9C27B0), // Violet
    'DESS': Color(0xFFFF9800), // Orange
    'THEAT': Color(0xFF673AB7), // Violet foncé
    'ESF': Color(0xFF00BCD4), // Cyan
  };

  // Couleurs des séries
  static const Map<String, Color> serieColors = {
    'A': Color(0xFF9C27B0), // Violet - Littéraire
    'A4Esp': Color(0xFFE91E63), // Rose - Espagnol
    'A4All': Color(0xFFFFEB3B), // Jaune - Allemand
    'A4ITA': Color(0xFFFF9800), // Orange - Italien
    'A4CHI': Color(0xFFF44336), // Rouge - Chinois
    'C': Color(0xFF2196F3), // Bleu - Scientifique Math-Physique
    'D': Color(0xFF4CAF50), // Vert - Scientifique Math-SVT
    'TI': Color(0xFF3F51B5), // Indigo - Technique
  };

  /// Thème clair
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Poppins',

    // Schéma de couleurs
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      primaryContainer: Color(0xFFE3F2FD),
      secondary: secondaryColor,
      secondaryContainer: Color(0xFFE0F2F1),
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryColor,
      onBackground: textPrimaryColor,
      onError: Colors.white,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
      iconTheme: IconThemeData(
        color: textSecondaryColor,
      ),
    ),

    // Cartes
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Boutons élevés
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),

    // Boutons de texte
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),

    // Boutons en relief
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Champs de texte
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        color: textSecondaryColor,
        fontFamily: 'Poppins',
      ),
      hintStyle: const TextStyle(
        color: textLightColor,
        fontFamily: 'Poppins',
      ),
    ),

    // Navigation du bas
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontFamily: 'Poppins'),
      unselectedLabelStyle: TextStyle(fontFamily: 'Poppins'),
    ),

    // Icônes
    iconTheme: const IconThemeData(
      color: textSecondaryColor,
      size: 24,
    ),

    // Textes
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        fontFamily: 'Poppins',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: textSecondaryColor,
        fontFamily: 'Poppins',
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        fontFamily: 'Poppins',
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        fontFamily: 'Poppins',
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textLightColor,
        fontFamily: 'Poppins',
      ),
    ),

    // Indicateurs de progression
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: Color(0xFFE0E0E0),
    ),

    // Commutateurs
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return textLightColor;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor.withOpacity(0.5);
        }
        return textLightColor.withOpacity(0.5);
      }),
    ),

    // Cases à cocher
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
      side: const BorderSide(color: textLightColor, width: 2),
    ),

    // Boutons radio
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return textLightColor;
      }),
    ),

    // Snackbars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimaryColor,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  /// Thème sombre
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: 'Poppins',

    // Schéma de couleurs sombre
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: Color(0xFF1565C0),
      secondary: secondaryColor,
      secondaryContainer: Color(0xFF004D40),
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
    ),

    // AppBar sombre
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
      iconTheme: IconThemeData(
        color: Colors.white70,
      ),
    ),

    // Cartes sombres
    cardTheme: CardThemeData(
      color: const Color(0xFF2C2C2C),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  /// Obtenir la couleur d'une matière
  static Color getSubjectColor(String subjectCode) {
    return subjectColors[subjectCode] ?? primaryColor;
  }

  /// Obtenir la couleur d'une série
  static Color getSerieColor(String serieCode) {
    return serieColors[serieCode] ?? primaryColor;
  }

  /// Obtenir une couleur avec opacité
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Obtenir une couleur plus claire
  static Color lighter(Color color, [double factor = 0.1]) {
    return Color.lerp(color, Colors.white, factor) ?? color;
  }

  /// Obtenir une couleur plus sombre
  static Color darker(Color color, [double factor = 0.1]) {
    return Color.lerp(color, Colors.black, factor) ?? color;
  }

  /// Créer un dégradé basé sur une couleur
  static LinearGradient createGradient(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        darker(baseColor, 0.2),
      ],
    );
  }

  /// Style pour les cartes de matières
  static BoxDecoration matiereCardDecoration(Color color) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Style pour les boutons d'action
  static ButtonStyle actionButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }
}