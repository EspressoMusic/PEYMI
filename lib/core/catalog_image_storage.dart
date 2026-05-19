import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Saves manager-uploaded photos under app documents (not bundle assets).
class CatalogImageStorage {
  static Future<String> saveFromPicker(String sourcePath) async {
    final dir = await _imagesDir();
    final ext = p.extension(sourcePath);
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final dest = p.join(dir.path, 'catalog_${DateTime.now().millisecondsSinceEpoch}$safeExt');
    await File(sourcePath).copy(dest);
    return dest;
  }

  static Future<Directory> _imagesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'catalog_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
