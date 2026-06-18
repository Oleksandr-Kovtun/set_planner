import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppPrefs {
  static AppPrefs _instance = AppPrefs._();
  static AppPrefs get instance => _instance;

  AppPrefs._();

  String? projectsFolder;
  String? lastFilePath;

  static Future<void> load() async {
    final prefs = AppPrefs._();
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/prefs.json');
      if (file.existsSync()) {
        final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        prefs.projectsFolder = map['projectsFolder'] as String?;
        final last = map['lastFilePath'] as String?;
        // Only restore if the file still exists on disk.
        if (last != null && File(last).existsSync()) {
          prefs.lastFilePath = last;
        }
      }
    } catch (_) {}
    _instance = prefs;
  }

  Future<void> save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/prefs.json');
      file.writeAsStringSync(jsonEncode({
        'projectsFolder': projectsFolder,
        'lastFilePath': lastFilePath,
      }));
    } catch (_) {}
  }

  Future<String> effectiveProjectsFolder() async {
    final f = projectsFolder;
    if (f != null && f.isNotEmpty && Directory(f).existsSync()) return f;
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }
}
