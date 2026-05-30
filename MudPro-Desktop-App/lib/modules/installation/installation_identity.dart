import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

class InstallationIdentity {
  static const String fileName = 'mudpro_installation_id.txt';
  static const int identityVersion = 2;

  static String _id = '';
  static String _machineKey = '';

  static String get id => _id;
  static String get machineKey => _machineKey;

  static Future<void> ensureInitialized() async {
    if (_id.isNotEmpty) return;

    final file = await _identityFile();
    final machineKey = await _machineFingerprint();
    _machineKey = machineKey;
    if (await file.exists()) {
      final saved = (await file.readAsString()).trim();
      final record = _parseRecord(saved);
      if (record != null &&
          _isValid(record.id) &&
          record.machineKey == machineKey) {
        _id = record.id;
        _machineKey = record.machineKey;
        return;
      }

      await cleanSystemIdentity();
    }

    _id = _generateId();
    await file.parent.create(recursive: true);
    await file.writeAsString(_encodeRecord(_id, machineKey), flush: true);
  }

  static bool _isValid(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{16,80}$').hasMatch(value);

  static Future<void> cleanSystemIdentity() async {
    _id = '';
    _machineKey = '';
    for (final file in await _identityFiles()) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

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

  static Future<List<File>> _identityFiles() async {
    final files = <File>[];
    final seen = <String>{};

    Future<void> add(File file) async {
      final key = file.path.toLowerCase();
      if (seen.add(key)) {
        files.add(file);
      }
    }

    try {
      final dir = await getApplicationSupportDirectory();
      await add(File('${dir.path}${Platform.pathSeparator}$fileName'));
    } catch (_) {}

    await add(
      File('${Directory.systemTemp.path}${Platform.pathSeparator}$fileName'),
    );

    return files;
  }

  static _InstallationIdentityRecord? _parseRecord(String value) {
    if (value.isEmpty || !value.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;

      final version = decoded['version'];
      final id = decoded['id']?.toString().trim() ?? '';
      final machineKey = decoded['machineKey']?.toString().trim() ?? '';
      if (version != identityVersion || id.isEmpty || machineKey.isEmpty) {
        return null;
      }

      return _InstallationIdentityRecord(id: id, machineKey: machineKey);
    } catch (_) {
      return null;
    }
  }

  static String _encodeRecord(String id, String machineKey) {
    return jsonEncode({
      'version': identityVersion,
      'id': id,
      'machineKey': machineKey,
    });
  }

  static Future<String> _machineFingerprint() async {
    final environment = Platform.environment;
    final values = <String>[
      Platform.operatingSystem,
      ...await _macAddresses(),
      environment['COMPUTERNAME'] ?? '',
      environment['USERDOMAIN'] ?? '',
      environment['USERNAME'] ?? '',
      environment['USERPROFILE'] ?? '',
      environment['LOCALAPPDATA'] ?? '',
    ]
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList();

    if (values.length <= 1) {
      values.add(Directory.current.path.trim().toLowerCase());
    }

    return _stableHash(values.join('|'));
  }

  static Future<List<String>> _macAddresses() async {
    if (!Platform.isWindows) return const <String>[];

    try {
      final result = await Process.run('getmac', const ['/fo', 'csv', '/nh']);
      if (result.exitCode != 0) return const <String>[];

      final pattern = RegExp(r'([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}');
      final matches = pattern
          .allMatches(result.stdout.toString())
          .map((match) => match.group(0)!.replaceAll(':', '-').toLowerCase())
          .toSet()
          .toList()
        ..sort();

      return matches;
    } catch (_) {
      return const <String>[];
    }
  }

  static String _stableHash(String input) {
    const offset = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    const mask = 0xffffffffffffffff;
    var hash = offset;

    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * prime) & mask;
    }

    return hash.toRadixString(16).padLeft(16, '0');
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

class _InstallationIdentityRecord {
  const _InstallationIdentityRecord({
    required this.id,
    required this.machineKey,
  });

  final String id;
  final String machineKey;
}
