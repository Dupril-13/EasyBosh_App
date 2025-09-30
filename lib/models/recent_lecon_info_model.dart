import 'package:easybosh_v2/models/lecon_model.dart';
import 'package:easybosh_v2/models/chapitre_model.dart';
import 'package:easybosh_v2/models/matiere_model.dart';
import 'package:equatable/equatable.dart';

class RecentLeconInfoModel extends Equatable {
  final LeconModel lecon;
  final ChapitreModel chapitre; // Chapitre parent de la leçon
  final MatiereModel matiere;   // Matière parente du chapitre
  final DateTime lastViewedAt;

  const RecentLeconInfoModel({
    required this.lecon,
    required this.chapitre,
    required this.matiere,
    required this.lastViewedAt,
  });

  @override
  List<Object?> get props => [lecon, chapitre, matiere, lastViewedAt];

  // Pas de toJson/fromJson ici car ce modèle est construit côté client après plusieurs requêtes.
  // Si on stockait directement cette structure, il en faudrait.
}
