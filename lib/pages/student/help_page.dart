import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; // No longer directly used here
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:math' as math; // For math.pi for rotation

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final Map<String, bool> _isExpandedMap = {};

  final List<Map<String, dynamic>> _faqItems = [
    {
      'id': 'commencer',
      'question': 'Comment commencer à utiliser EasyBosh ?',
      'answer':
          'Après avoir créé votre compte, vous pouvez commencer par explorer les cours disponibles dans l\'onglet "Cours". Sélectionnez votre niveau et votre série pour accéder au contenu adapté.',
      'icon': Iconsax.play_circle,
    },
    {
      'id': 'quiz',
      'question': 'Comment fonctionnent les quiz ?',
      'answer':
          'Les quiz sont des tests interactifs qui vous permettent d\'évaluer vos connaissances. Vous pouvez les trouver dans l\'onglet "Quiz" et les passer autant de fois que nécessaire.',
      'icon': Iconsax.message_question,
    },
    {
      'id': 'progression',
      'question': 'Comment suivre ma progression ?',
      'answer':
          'Votre progression est automatiquement enregistrée et visible dans l\'onglet "Statistiques". Vous y trouverez des graphiques détaillés de vos performances.',
      'icon': Iconsax.chart_1,
    },
    {
      'id': 'hors_ligne',
      'question': 'Puis-je utiliser l\'app hors ligne ?',
      'answer':
          'Certaines fonctionnalités peuvent nécessiter une connexion internet. La possibilité de télécharger du contenu pour un usage hors ligne est en cours de développement.',
      'icon': Iconsax.document_download,
    },
    {
      'id': 'profil',
      'question': 'Comment changer mes informations de profil ?',
      'answer':
          'Accédez à l\'onglet "Paramètres" (icône roue dentée en haut à droite sur la plupart des pages principales) pour modifier vos informations de profil.',
      'icon': Iconsax.user_edit,
    },
    {
      'id': 'mot_de_passe',
      'question': 'Que faire si j\'oublie mon mot de passe ?',
      'answer':
          'Utilisez la fonction "Mot de passe oublié" sur la page de connexion. Un email de réinitialisation vous sera envoyé à l\'adresse associée à votre compte.',
      'icon': Iconsax.key,
    },
  ];

  @override
  void initState() {
    super.initState();
    for (var item in _faqItems) {
      _isExpandedMap[item['id']] = false;
    }
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required List<Widget> children,
    EdgeInsetsGeometry? titlePadding,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: titlePadding ?? const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: children,
            ), 
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Aide et Support',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? const Color(0xFFF5F5F5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
        child: Column(
          children: [
            _buildSection(
              context,
              title: 'Questions fréquentes',
              children: _faqItems.map((faq) => _buildFAQItem(faq)).toList(),
            ),
            _buildSection(
              context,
              title: 'Besoin d\'aide supplémentaire ?',
              children: [_buildContactSupportCardContent(context)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    final String itemId = faq['id'];
    final bool isCurrentlyExpanded = _isExpandedMap[itemId] ?? false;

    return ExpansionTile(
      key: PageStorageKey<String>(itemId),
      leading: Icon(faq['icon'] ?? Iconsax.info_circle, color: Theme.of(context).colorScheme.primary),
      title: Text(
        faq['question'],
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Transform.rotate(
        angle: isCurrentlyExpanded ? math.pi : 0, // Rotate 180 degrees (pi radians) when expanded
        child: Icon(
          Iconsax.arrow_down_1, // Using a single icon that rotates
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      onExpansionChanged: (bool expanded) {
        setState(() {
          _isExpandedMap[itemId] = expanded;
        });
      },
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: Theme.of(context).colorScheme.surface, 
      collapsedBackgroundColor: Theme.of(context).colorScheme.surface,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: const Border(),
      collapsedShape: const Border(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            faq['answer'],
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5, 
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSupportCardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notre équipe de support est là pour vous aider. N\'hésitez pas à nous contacter.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _showEmailDialog(context);
            },
            icon: Icon(Iconsax.sms, color: Theme.of(context).colorScheme.onPrimary),
            label: Text('Nous contacter', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)), // Label updated
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(BuildContext pageContext) {
    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Contacter le support',
          style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(dialogContext).colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              'Envoyez-nous un email à support@easybosh.com avec votre question. Nous vous répondrons dans les plus brefs délais.',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
