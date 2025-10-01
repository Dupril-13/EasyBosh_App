import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<bool> _requestPermissions() async {
    // Sur Android, demandez la permission de stockage.
    // Sur iOS, cette permission spécifique n'est pas nécessaire pour écrire dans le dossier de l'app,
    // mais pourrait l'être pour d'autres opérations (ex: galerie photos).
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      // Pour Android 11+ (SDK 30+), MANAGE_EXTERNAL_STORAGE est une permission sensible.
      // Il est préférable de cibler des dossiers spécifiques ou d'utiliser MediaStore/SAF.
      // Pour l'instant, on se contente de Permission.storage.
      return status.isGranted;
    }
    return true; // Pour iOS et autres plateformes, on considère la permission comme acquise ici.
  }

  Future<String?> getDownloadPath(BuildContext context, String subfolderName) async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        // Sur iOS, le dossier des documents est le plus approprié et accessible.
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        if (await _requestPermissions()) {
          // Tenter d'accéder au dossier de téléchargement public
          Directory? externalDir = await getExternalStorageDirectory(); // Chemin de base du stockage externe
          if (externalDir != null) {
            // Essayer de trouver le dossier "Download" typique.
            // Note: ce chemin n'est pas toujours garanti et peut varier.
            // Une solution plus robuste utiliserait MediaStore ou SAF pour Android 10+.
            String downloadsPath = '/storage/emulated/0/Download'; // Chemin commun
            directory = Directory(downloadsPath);
            
            // Vérifier si le dossier existe, sinon utiliser le stockage externe de l'app
            if (!await directory.exists()) {
                print("Le dossier public Download ($downloadsPath) n'existe pas, utilisation du stockage externe de l'app.");
                directory = externalDir; // Se rabattre sur le dossier externe de l'application
            }
          } else {
             print("Impossible d'accéder au stockage externe, utilisation du dossier de documents de l'app.");
            directory = await getApplicationDocumentsDirectory(); // Fallback
          }
        } else {
          print("Permission de stockage refusée, utilisation du dossier de documents de l'app.");
          directory = await getApplicationDocumentsDirectory(); // Fallback si permission refusée
        }
      } else {
        // Pour les autres plateformes (desktop, etc.), utiliser le dossier de documents.
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (err) {
      print("Erreur lors de l'obtention du répertoire de téléchargement: $err");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'accès au stockage: ${err.toString().substring(0, (err.toString().length > 100) ? 100 : err.toString().length )}'), backgroundColor: Colors.red),
      );
      return null;
    }

    if (directory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de déterminer le répertoire de stockage.'), backgroundColor: Colors.red),
      );
      return null;
    }
    
    // Créer un sous-dossier pour votre application à l'intérieur du dossier de téléchargement choisi
    final String appSpecificDownloadPath = "${directory.path}/$subfolderName";
    final Directory appSpecificDir = Directory(appSpecificDownloadPath);
    
    if (!await appSpecificDir.exists()) {
      try {
        await appSpecificDir.create(recursive: true);
        print("Sous-dossier créé: $appSpecificDownloadPath");
      } catch (e) {
        print("Erreur lors de la création du sous-dossier $appSpecificDownloadPath: $e");
        // Si la création du sous-dossier échoue (ex: dans un dossier public sans permission totale),
        // se rabattre sur le répertoire de base (documents de l'app ou le public accessible)
        return directory.path; 
      }
    }
    return appSpecificDownloadPath;
  }

  Future<String?> downloadFile({
    required BuildContext context, 
    required String url,
    required String filename, 
    void Function(int, int)? onReceiveProgress, 
  }) async {
    if (kIsWeb) {
      // Le téléchargement sur le Web est généralement géré par le navigateur.
      // On pourrait utiliser html.AnchorElement pour déclencher un téléchargement nommé.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le téléchargement sur le web est géré par le navigateur.'), backgroundColor: Colors.blue),
      );
      // html.AnchorElement(href: url)..setAttribute("download", filename)..click(); // Exemple pour le web
      return null; // Pas de chemin de fichier local pour le web de cette manière
    }

    final String? downloadDirPath = await getDownloadPath(context, "Easybosh_v2_Downloads");

    if (downloadDirPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'obtenir le chemin de téléchargement.'), backgroundColor: Colors.red),
      );
      return null;
    }

    String savePath = "$downloadDirPath/$filename";
    print("Chemin de sauvegarde du fichier: $savePath");

    try {
      // Afficher un message de début de téléchargement
      if (ScaffoldMessenger.maybeOf(context) != null) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Téléchargement de "$filename" en cours...'), backgroundColor: Colors.blue),
           );
      }

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            if (onReceiveProgress != null) {
              onReceiveProgress(received, total);
            }
            print("Progression: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true, // Peut être nécessaire pour certains serveurs
          validateStatus: (status) {
            return status != null && status < 500; 
          },
        ),
      );

      print('Fichier téléchargé avec succès: $savePath');
      if (ScaffoldMessenger.maybeOf(context) != null) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Enlever le SnackBar de progression
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$filename" téléchargé!'), 
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OUVRIR',
              onPressed: () {
                OpenFilex.open(savePath);
              },
            ),
          ),
        );
      }
      return savePath;
    } on DioException catch (e) {
      print('Erreur Dio lors du téléchargement: ${e.message}');
      print('Dio error details: ${e.response?.statusCode} - ${e.response?.statusMessage}');
      if (ScaffoldMessenger.maybeOf(context) != null) {
         ScaffoldMessenger.of(context).removeCurrentSnackBar();
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erreur réseau: ${e.message?.substring(0, (e.message!.length > 100) ? 100 : e.message!.length)}'), backgroundColor: Colors.red),
         );
      }
      return null;
    } catch (e) {
      print('Erreur inconnue lors du téléchargement: $e');
      if (ScaffoldMessenger.maybeOf(context) != null) {
         ScaffoldMessenger.of(context).removeCurrentSnackBar();
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erreur de téléchargement: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length )}'), backgroundColor: Colors.red),
         );
      }
      return null;
    }
  }
}
