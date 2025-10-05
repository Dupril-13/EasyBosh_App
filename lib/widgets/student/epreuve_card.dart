import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easybosh_v2/models/epreuve_model.dart';
import 'package:easybosh_v2/providers/epreuve_progression_provider.dart';
import 'package:easybosh_v2/services/epreuve_progression_service.dart';

class EpreuveCard extends ConsumerWidget {
  final Epreuve epreuve;

  const EpreuveCard({super.key, required this.epreuve});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressionState = ref.watch(epreuveProgressionProvider);
    final status = _getStatus(progressionState);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/epreuve_details', extra: epreuve),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      epreuve.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.subject, epreuve.matiereDisplay, Colors.blue),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.timer, '${epreuve.dureeMinutes} min', Colors.orange),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(Icons.grade, epreuve.niveauScolaireDisplay, Colors.green),
                  if (epreuve.anneeExamen != null) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.calendar_today, '${epreuve.anneeExamen}', Colors.purple),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatus(Map<int, EpreuveProgressionModel> progressionState) {
    if (epreuve.id == null) return 'Nouveau';
    if (!progressionState.containsKey(epreuve.id!)) return 'Nouveau';

    final progression = progressionState[epreuve.id!]!;
    if (progression.termine) return 'Terminé';
    if (progression.commenced) return 'En cours';
    return 'Nouveau';
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Terminé':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'En cours':
        color = Colors.orange;
        icon = Icons.play_circle;
        break;
      default:
        color = Colors.blue;
        icon = Icons.fiber_new;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}