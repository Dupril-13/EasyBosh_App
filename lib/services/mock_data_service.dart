// lib/services/mock_data_service.dart
import 'package:flutter/material.dart';
import '../models/matiere_model.dart';

class MockDataService {
  static List<MatiereModel> getMatieres() {
    return [
      // MATHÉMATIQUES
      MatiereModel(
        id: 1,
        nom: 'Maths',
        description: 'Mathématiques générales et appliquées',
        icon: Icons.functions,
        color: Colors.blue,
        niveaux: ['3ème', '1ère', 'Tle'],
        series: ['A', 'C', 'D', 'TI'],
        chapitres: [
          ChapitreModel(
            id: 1,
            matiereId: 1,
            nom: 'Algèbre',
            description: 'Équations, inéquations et systèmes',
            icon: Icons.functions,
            color: Colors.blue,
            difficulte: 'Moyen',
            dureeEstimeeMinutes: 480,
            progression: 0.75,
            lecons: [
              LeconModel(
                id: 1,
                chapitreId: 1,
                titre: 'Introduction aux équations',
                description: 'Bases des équations du premier degré',
                contenu: '''# Introduction aux Équations

Les équations sont des égalités mathématiques qui contiennent une ou plusieurs inconnues. Une équation du premier degré à une inconnue est de la forme :

**ax + b = 0**

où a et b sont des nombres réels et a ≠ 0.

## Méthodes de résolution

1. **Isoler l'inconnue** : Déplacer tous les termes avec x d'un côté
2. **Simplifier** : Réduire l'expression
3. **Vérifier** : Substituer la solution dans l'équation originale

### Exemple
Résolvons : 3x + 5 = 14

1. 3x = 14 - 5
2. 3x = 9
3. x = 3

Vérification : 3(3) + 5 = 9 + 5 = 14 ✓''',
                type: 'texte',
                dureeEstimeeMinutes: 45,
                ordre: 1,
                estComplete: true,
                dateCompletion: DateTime.now().subtract(const Duration(days: 2)),
                createdAt: DateTime.now().subtract(const Duration(days: 30)),
                updatedAt: DateTime.now().subtract(const Duration(days: 2)),
              ),
              LeconModel(
                id: 2,
                chapitreId: 1,
                titre: 'Équations du second degré',
                description: 'Résolution des équations quadratiques',
                contenu: '''# Équations du Second Degré

Une équation du second degré (ou quadratique) est de la forme :

**ax² + bx + c = 0** (avec a ≠ 0)

## Discriminant

Le discriminant Δ = b² - 4ac permet de déterminer le nombre de solutions :

- Si Δ > 0 : deux solutions réelles distinctes
- Si Δ = 0 : une solution réelle double
- Si Δ < 0 : aucune solution réelle

## Formule des racines

x = (-b ± √Δ) / (2a)

### Exemple
Résolvons : x² - 5x + 6 = 0

a = 1, b = -5, c = 6
Δ = (-5)² - 4(1)(6) = 25 - 24 = 1

x₁ = (5 + 1)/2 = 3
x₂ = (5 - 1)/2 = 2''',
                type: 'video',
                videoUrl: 'https://example.com/equations-second-degre.mp4',
                dureeEstimeeMinutes: 60,
                ordre: 2,
                estComplete: false,
                createdAt: DateTime.now().subtract(const Duration(days: 25)),
                updatedAt: DateTime.now().subtract(const Duration(days: 25)),
              ),
              LeconModel(
                id: 3,
                chapitreId: 1,
                titre: 'Systèmes d\'équations',
                description: 'Résolution de systèmes à deux inconnues',
                contenu: '''# Systèmes d'Équations

Un système d'équations linéaires à deux inconnues :

{ax + by = c
{dx + ey = f

## Méthodes de résolution

### 1. Méthode de substitution
- Exprimer une inconnue en fonction de l'autre
- Substituer dans la seconde équation

### 2. Méthode d'élimination
- Éliminer une inconnue par addition ou soustraction

### 3. Méthode de Cramer
- Utiliser les déterminants

### Exemple
{2x + 3y = 7
{x - y = 1

De la seconde : x = 1 + y
Substitution : 2(1 + y) + 3y = 7
2 + 2y + 3y = 7
5y = 5
y = 1, donc x = 2''',
                type: 'interactive',
                dureeEstimeeMinutes: 50,
                ordre: 3,
                estComplete: false,
                createdAt: DateTime.now().subtract(const Duration(days: 20)),
                updatedAt: DateTime.now().subtract(const Duration(days: 20)),
              ),
              LeconModel(
                id: 4,
                chapitreId: 1,
                titre: 'Quiz - Algèbre',
                description: 'Évaluation sur les équations et systèmes',
                contenu: 'Quiz interactif couvrant tous les aspects de l\'algèbre vus dans ce chapitre.',
                type: 'quiz',
                dureeEstimeeMinutes: 30,
                ordre: 4,
                estComplete: false,
                createdAt: DateTime.now().subtract(const Duration(days: 15)),
                updatedAt: DateTime.now().subtract(const Duration(days: 15)),
              ),
            ],
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ChapitreModel(
            id: 2,
            matiereId: 1,
            nom: 'Géométrie',
            description: 'Figures planes et dans l\'espace',
            icon: Icons.crop_square,
            color: Colors.green,
            difficulte: 'Facile',
            dureeEstimeeMinutes: 360,
            progression: 0.60,
            lecons: [
              LeconModel(
                id: 5,
                chapitreId: 2,
                titre: 'Les triangles',
                description: 'Propriétés et classification des triangles',
                contenu: '''# Les Triangles

Un triangle est une figure géométrique formée de trois segments reliant trois points non alignés.

## Classification par côtés

- **Triangle équilatéral** : 3 côtés égaux
- **Triangle isocèle** : 2 côtés égaux  
- **Triangle scalène** : 3 côtés inégaux

## Classification par angles

- **Triangle acutangle** : 3 angles aigus (< 90°)
- **Triangle rectangle** : 1 angle droit (= 90°)
- **Triangle obtusangle** : 1 angle obtus (> 90°)

## Propriétés importantes

1. La somme des angles = 180°
2. Théorème de Pythagore (triangle rectangle)
3. Inégalité triangulaire : a + b > c

### Aire d'un triangle

Aire = (base × hauteur) / 2''',
                type: 'texte',
                dureeEstimeeMinutes: 45,
                ordre: 1,
                estComplete: true,
                dateCompletion: DateTime.now().subtract(const Duration(days: 5)),
                createdAt: DateTime.now().subtract(const Duration(days: 25)),
                updatedAt: DateTime.now().subtract(const Duration(days: 5)),
              ),
              LeconModel(
                id: 6,
                chapitreId: 2,
                titre: 'Constructions géométriques',
                description: 'Techniques de construction avec règle et compas',
                contenu: '''# Constructions Géométriques

Les constructions à la règle et au compas sont fondamentales en géométrie.

## Constructions de base

### 1. Médiatrice d'un segment
- Tracer deux cercles de même rayon centrés aux extrémités
- Relier les points d'intersection

### 2. Bissectrice d'un angle
- Tracer un arc centré au sommet
- Tracer deux arcs de même rayon aux intersections
- Relier le sommet au point d'intersection

### 3. Perpendiculaire à une droite
- Même technique que la médiatrice

### 4. Triangle équilatéral
- Tracer un cercle centré en A passant par B
- Tracer un cercle centré en B passant par A
- C est un point d'intersection

## Applications pratiques

Ces constructions permettent de résoudre de nombreux problèmes géométriques et sont à la base de la géométrie euclidienne.''',
                type: 'interactive',
                dureeEstimeeMinutes: 40,
                ordre: 2,
                estComplete: false,
                createdAt: DateTime.now().subtract(const Duration(days: 20)),
                updatedAt: DateTime.now().subtract(const Duration(days: 20)),
              ),
            ],
            createdAt: DateTime.now().subtract(const Duration(days: 25)),
            updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),

      // PHYSIQUE
      MatiereModel(
        id: 2,
        nom: 'Physique',
        description: 'Physique générale et expérimentale',
        icon: Icons.science,
        color: Colors.orange,
        niveaux: ['3ème', '1ère', 'Tle'],
        series: ['A', 'C', 'D', 'TI'],
        chapitres: [
          ChapitreModel(
            id: 3,
            matiereId: 2,
            nom: 'Mécanique',
            description: 'Forces, mouvement et énergie',
            icon: Icons.settings,
            color: Colors.red,
            difficulte: 'Moyen',
            dureeEstimeeMinutes: 600,
            progression: 0.65,
            lecons: [
              LeconModel(
                id: 7,
                chapitreId: 3,
                titre: 'Les forces',
                description: 'Introduction aux forces physiques',
                contenu: '''# Les Forces

Une force est une action mécanique capable de déformer un objet ou de modifier son mouvement.

## Caractéristiques d'une force

1. **Point d'application** : où s'exerce la force
2. **Direction** : droite d'action de la force
3. **Sens** : orientation sur la droite
4. **Intensité** : valeur en Newtons (N)

## Types de forces

### Forces de contact
- Force normale
- Force de frottement
- Force de tension

### Forces à distance
- Force gravitationnelle
- Forces électromagnétiques

## Principe fondamental

**Première loi de Newton** : Dans un référentiel galiléen, si les forces qui s'exercent sur un objet se compensent, alors l'objet reste au repos ou en mouvement rectiligne uniforme.

## Représentation

Les forces se représentent par des vecteurs avec origine, direction, sens et norme.''',
                type: 'video',
                videoUrl: 'https://example.com/forces-physique.mp4',
                dureeEstimeeMinutes: 50,
                ordre: 1,
                estComplete: true,
                dateCompletion: DateTime.now().subtract(const Duration(days: 3)),
                createdAt: DateTime.now().subtract(const Duration(days: 28)),
                updatedAt: DateTime.now().subtract(const Duration(days: 3)),
              ),
            ],
            createdAt: DateTime.now().subtract(const Duration(days: 28)),
            updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 28)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),

      // Vous pouvez ajouter d'autres matières (Chimie, Français, etc.)
    ];
  }

  // Méthode pour obtenir une matière par ID
  static MatiereModel? getMatiereById(int id) {
    final matieres = getMatieres();
    try {
      return matieres.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  // Méthode pour obtenir un chapitre par ID
  static ChapitreModel? getChapitreById(int id) {
    final matieres = getMatieres();
    for (final matiere in matieres) {
      try {
        return matiere.chapitres.firstWhere((c) => c.id == id);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  // Méthode pour obtenir une leçon par ID
  static LeconModel? getLeconById(int id) {
    final matieres = getMatieres();
    for (final matiere in matieres) {
      for (final chapitre in matiere.chapitres) {
        try {
          return chapitre.lecons.firstWhere((l) => l.id == id);
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }
}