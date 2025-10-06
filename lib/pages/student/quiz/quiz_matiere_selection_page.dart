import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/matiere_model.dart';
import '../../../providers/matiere_provider.dart';
import '../../../providers/auth_provider.dart';

class QuizMatiereSelectionPage extends ConsumerStatefulWidget {
  const QuizMatiereSelectionPage({super.key});

  @override
  ConsumerState<QuizMatiereSelectionPage> createState() =>
      _QuizMatiereSelectionPageState();
}

class _QuizMatiereSelectionPageState
    extends ConsumerState<QuizMatiereSelectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatieres();
    });
  }

  Future<void> _loadMatieres() async {
    final authState = ref.read(authProvider);
    final user = (authState is AuthAuthenticated) ? authState.user : null;

    if (user == null ||
        user.studentLevelCode == null ||
        user.studentSerieCode == null) {
      return;
    }

    await ref.read(matiereProvider.notifier).fetchMatieres(
      niveauCode: user.studentLevelCode,
      serieCode: user.studentSerieCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final matiereState = ref.watch(matiereProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Choisir une Matière',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(matiereState),
    );
  }

  Widget _buildBody(MatiereState matiereState) {
    // Loading
    if (matiereState.isLoading && matiereState.matieres.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Erreur
    if (matiereState.errorMessage != null && matiereState.matieres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              matiereState.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMatieres,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // Aucune matière
    if (matiereState.matieres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune matière disponible pour votre classe.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Grille de matières
    return RefreshIndicator(
      onRefresh: _loadMatieres,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionnez une matière',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: matiereState.matieres.length,
                itemBuilder: (context, index) {
                  final matiere = matiereState.matieres[index];
                  return _buildMatiereCard(matiere);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereCard(MatiereModel matiere) {
    final Color matiereColor = _hexToColor(
      matiere.couleur,
      defaultColor: Colors.blueAccent,
    );
    final IconData matiereIcon = _stringToIconData(
      matiere.icone,
      defaultIcon: Icons.school,
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigation vers la liste des quiz de cette matière
          context.push('/quiz_list_matiere', extra: matiere);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                matiereColor,
                matiereColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    matiereIcon,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Nom de la matière
                Text(
                  matiere.nom,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String? hexString, {required Color defaultColor}) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return defaultColor;
    }
  }

  IconData _stringToIconData(String? iconString, {required IconData defaultIcon}) {
    if (iconString == null || iconString.isEmpty) return defaultIcon;
    switch (iconString.toLowerCase()) {
      case 'book':
        return Icons.book;
      case 'calculate':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'language':
        return Icons.language;
      case 'history':
        return Icons.history_edu;
      case 'palette':
        return Icons.palette;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'computer':
        return Icons.computer;
      case 'music_note':
        return Icons.music_note;
      case 'biotech':
        return Icons.biotech;
      default:
        return defaultIcon;
    }
  }
}