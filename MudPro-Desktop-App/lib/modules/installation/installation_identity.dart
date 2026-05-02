import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

class InstallationIdentity {
  static const String fileName = 'mudpro_installation_id.txt';

  static String _id = '';

  static String get id => _id;

  static Future<void> ensureInitialized() async {
    if (_id.isNotEmpty) return;

    final file = await _identityFile();
    if (await file.exists()) {
      final saved = (await file.readAsString()).trim();
      if (_isValid(saved)) {
        _id = saved;
        return;
      }
    }

    _id = _generateId();
    await file.parent.create(recursive: true);
    await file.writeAsString(_id, flush: true);
  }

  static bool _isValid(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{16,80}$').hasMatch(value);

  static Future<File> _identityFile() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}${Platform.pathSeparator}$fileName');
    } catch (_) {
      return File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName',
      );
    }
  }

  static String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final token = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    return 'mudpro_${stamp}_$token';
  }
}
