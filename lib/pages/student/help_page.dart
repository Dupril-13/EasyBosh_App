import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {

  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'Comment commencer à utiliser EasyBosh ?',
      'answer':
      'Après avoir créé votre compte, vous pouvez commencer par explorer les cours disponibles dans l\'onglet "Cours". Sélectionnez votre niveau et votre série pour accéder au contenu adapté.',
    },
    {
      'question': 'Comment fonctionnent les quiz ?',
      'answer':
      'Les quiz sont des tests interactifs qui vous permettent d\'évaluer vos connaissances. Vous pouvez les trouver dans l\'onglet "Quiz" et les passer autant de fois que nécessaire.',
    },
    {
      'question': 'Comment suivre ma progression ?',
      'answer':
      'Votre progression est automatiquement enregistrée et visible dans l\'onglet "Statistiques". Vous y trouverez des graphiques détaillés de vos performances.',
    },
    {
      'question': 'Puis-je utiliser l\'app hors ligne ?',
      'answer':
      'Oui ! Vous pouvez télécharger du contenu pour l\'utiliser hors ligne. Allez dans les paramètres et activez le mode hors ligne.',
    },
    {
      'question': 'Comment changer mes informations de profil ?',
      'answer':
      'Accédez aux paramètres via l\'icône "more_vert" dans n\'importe quelle page, puis allez dans l\'onglet "Mon Profil" pour modifier vos informations.',
    },
    {
      'question': 'Que faire si j\'oublie mon mot de passe ?',
      'answer': 'Utilisez la fonction "Mot de passe oublié" sur la page de connexion. Un email de réinitialisation vous sera envoyé.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: const Text(
          'Centre d\'aide',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFAQ(),
            const SizedBox(height: 24),
            _buildContactSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 20),
          ..._faqItems.map((faq) => _buildFAQItem(faq)).toList(),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return ExpansionTile(
      iconColor: Colors.blueAccent,
      collapsedIconColor: Colors.blueGrey[600],
      title: Text(
        faq['question'],
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey[700],
        ),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            faq['answer'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey[500],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSupport() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Besoin d\'aide supplémentaire ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Notre équipe de support est là pour vous aider. N\'hésitez pas à nous contacter.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey[500],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showEmailDialog();
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Envoyer un Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Contacter le support',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey[800]),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envoyez-nous un email à support@easybosh.com avec votre question. Nous vous répondrons dans les plus brefs délais.',
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'support@easybosh.com',
                  queryParameters: {
                    'subject': 'Support EasyBosh',
                  },
                );

                try {
                  await launchUrl(emailLaunchUri);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Impossible d\'ouvrir l\'email: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.email_outlined),
              label: const Text('Ouvrir l\'email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Fermer',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }
}