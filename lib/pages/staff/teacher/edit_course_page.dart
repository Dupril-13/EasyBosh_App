import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easybosh_v2/models/course_model.dart';
import 'package:easybosh_v2/providers/course_provider.dart';
// import 'package:easybosh_v2/providers/chapitre_provider.dart'; // Pour plus tard

class EditCoursePage extends ConsumerStatefulWidget {
  final CourseModel? course; // Null pour ajout, non-null pour édition

  const EditCoursePage({super.key, this.course});

  @override
  ConsumerState<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends ConsumerState<EditCoursePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _typeController;
  late TextEditingController _urlMediaController;
  late TextEditingController _ordreController;
  late TextEditingController _chapitreIdController; // Pour l'ID du chapitre
  // late TextEditingController _contenuController; // Pour JSONB, plus complexe

  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.course?.nom ?? '');
    _descriptionController = TextEditingController(text: widget.course?.description ?? '');
    _typeController = TextEditingController(text: widget.course?.type ?? 'text_rich');
    _urlMediaController = TextEditingController(text: widget.course?.urlMedia ?? '');
    _ordreController = TextEditingController(text: widget.course?.ordre.toString() ?? '0');
    _chapitreIdController = TextEditingController(text: widget.course?.chapitreId?.toString() ?? '');
    // _contenuController = TextEditingController(text: widget.course?.contenu?.toString() ?? '{}');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _urlMediaController.dispose();
    _ordreController.dispose();
    _chapitreIdController.dispose();
    // _contenuController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final courseDetails = CourseModel(
        id: _isEditing ? widget.course!.id : 0, 
        nom: _nomController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        chapitreId: int.tryParse(_chapitreIdController.text),
        ordre: int.tryParse(_ordreController.text) ?? 0,
        type: _typeController.text,
        urlMedia: _urlMediaController.text.isEmpty ? null : _urlMediaController.text,
        contenu: null, // TODO: Gérer le champ contenu JSONB
        actif: _isEditing ? widget.course!.actif : true, 
        createdAt: _isEditing ? widget.course!.createdAt : DateTime.now(), 
      );

      bool success;
      if (_isEditing) {
        success = await ref.read(courseProvider.notifier).updateCourse(courseDetails);
      } else {
        if (courseDetails.chapitreId == null) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('L\'ID du chapitre est requis.'), backgroundColor: Colors.red),
          );
          return;
        }
        success = await ref.read(courseProvider.notifier).addCourse(courseDetails, courseDetails.chapitreId!);
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cours ${ _isEditing ? "mis à jour" : "ajouté"} avec succès!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); 
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${ref.read(courseProvider).errorMessage ?? "Une erreur inconnue s\'est produite."}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(courseProvider.select((state) => state.isLoading));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le Cours' : 'Ajouter un Cours'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom du cours *'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom pour le cours.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField( 
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type de cours * (ex: text_rich, video)'),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le type du cours.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _chapitreIdController,
                decoration: const InputDecoration(labelText: 'ID du Chapitre Associé *'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'ID du chapitre est requis.';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un ID de chapitre valide (nombre entier).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ordreController,
                decoration: const InputDecoration(labelText: 'Ordre dans le chapitre *'),
                keyboardType: TextInputType.number,
                validator: (value) {
                   if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un ordre.';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide pour l\'ordre.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlMediaController,
                decoration: const InputDecoration(labelText: 'URL Média (si applicable)'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'Mettre à jour' : 'Ajouter le Cours'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
