import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ExportController {
  static const String baseUrl = ApiEndpoint.baseUrl;
  static const String _fallbackBaseName = 'WBM_Report';

  static Future<void> downloadAndOpenInventoryReport() async {
    final wellId = currentBackendWellId;
    if (wellId.isEmpty) {
      throw Exception('No backend well selected');
    }

    final reportId = reportContext.selectedReportId.value.trim();
    final snapshotResult = await InventorySnapshotController()
        .generateInventorySnapshot(wellId: wellId);
    if (snapshotResult['success'] != true) {
      throw Exception(
        snapshotResult['message'] ?? 'Failed to update report data',
      );
    }

    final baseUri = Uri.parse('${baseUrl}export/inventory-export/$wellId');
    final queryParameters = <String, String>{
      'lengthUnit': AppUnits.length,
      'diameterUnit': AppUnits.diameter,
      'fluidVolumeUnit': AppUnits.fluidVolume,
      'decimals': '2',
      if (reportId.isNotEmpty) 'reportId': reportId,
    };
    final uri = baseUri.replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Accept':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      },
    );

    if (response.statusCode != 200) {
      final body = response.body.trim();
      throw Exception(
        body.isEmpty
            ? 'Server error: ${response.statusCode}'
            : 'Server error: ${response.statusCode} $body',
      );
    }
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('spreadsheetml') &&
        !contentType.contains('application/octet-stream')) {
      final body = response.body.trim();
      throw Exception(
        body.isEmpty
            ? 'Invalid report response'
            : 'Invalid report response: $body',
      );
    }

    if (!_looksLikeXlsx(response.bodyBytes)) {
      final contentType = response.headers['content-type'] ?? 'unknown';
      final body = response.body.trim();
      throw Exception(
        body.isEmpty
            ? 'Server did not return an Excel file ($contentType)'
            : 'Server did not return an Excel file ($contentType): $body',
      );
    }

    final Directory reportDir = await _resolveReportDirectory();
    final String filePath = await _resolveOutputPath(reportDir, response);
    final String finalPath =
        await _writeBytesWithRetry(filePath, response.bodyBytes);

    if (!await _openReportFile(finalPath)) {
      await _openContainingFolder(finalPath);
      throw Exception(
        'Report saved at $finalPath, but no application could open .xlsx files automatically.',
      );
    }
  }

  static bool _looksLikeXlsx(List<int> bytes) =>
      bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;

  static String? _filenameFromHeaders(http.Response response) {
    final disposition = response.headers['content-disposition'];
    if (disposition == null) return null;

    final match = RegExp(
      "filename\\*?=(?:UTF-8''|\"|)?([^\";]+)",
      caseSensitive: false,
    ).firstMatch(disposition);

    final raw = match?.group(1)?.trim();
    if (raw == null || raw.isEmpty) return raw;
    try {
      return Uri.decodeComponent(raw);
    } catch (_) {
      return raw;
    }
  }

  static Future<Directory> _resolveReportDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final reportDir = Directory('${docsDir.path}/MudPro Reports');
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }
    return reportDir;
  }

  static Future<String> _resolveOutputPath(
    Directory tempDir,
    http.Response response,
  ) async {
    final headerName = _filenameFromHeaders(response);
    final baseName = (headerName ?? _fallbackBaseName).trim();
    final cleanedBase = baseName.isEmpty ? _fallbackBaseName : baseName;
    final hasXlsxExtension = cleanedBase.toLowerCase().endsWith('.xlsx');
    final nameWithoutExtension = hasXlsxExtension
        ? cleanedBase.substring(0, cleanedBase.length - '.xlsx'.length)
        : cleanedBase;
    final String safeBase =
        nameWithoutExtension.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String candidate = '${tempDir.path}/$safeBase.xlsx';
    final File file = File(candidate);
    if (await file.exists()) {
      return '${tempDir.path}/${safeBase}_$stamp.xlsx';
    }
    return candidate;
  }

  static Future<String> _writeBytesWithRetry(
    String filePath,
    List<int> bytes,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      return filePath;
    } on FileSystemException {
      final fallbackPath = _pathWithTimestamp(filePath);
      final fallbackFile = File(fallbackPath);
      await fallbackFile.writeAsBytes(bytes, flush: true);
      return fallbackPath;
    }
  }

  static String _pathWithTimestamp(String filePath) {
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    if (filePath.toLowerCase().endsWith('.xlsx')) {
      return '${filePath.substring(0, filePath.length - '.xlsx'.length)}_$stamp.xlsx';
    }
    return '${filePath}_$stamp.xlsx';
  }

  static Future<bool> _openReportFile(String filePath) async {
    if (Platform.isWindows) {
      if (await _openWithWindowsAssociation(filePath)) return true;
      if (await _openWithExcel(filePath)) return true;
      if (await _openWithExplorer(filePath)) return true;
    }

    final openResult = await OpenFilex.open(filePath);
    return openResult.type == ResultType.done;
  }

  static Future<bool> _openWithWindowsAssociation(String filePath) async {
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-NonInteractive',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          r'Invoke-Item -LiteralPath $args[0]',
          filePath,
        ],
      ).timeout(const Duration(seconds: 10));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _openWithExcel(String filePath) async {
    const candidates = [
      'C:\\\\Program Files\\\\Microsoft Office\\\\root\\\\Office16\\\\EXCEL.EXE',
      'C:\\\\Program Files (x86)\\\\Microsoft Office\\\\root\\\\Office16\\\\EXCEL.EXE',
      'C:\\\\Program Files\\\\Microsoft Office\\\\Office16\\\\EXCEL.EXE',
      'C:\\\\Program Files (x86)\\\\Microsoft Office\\\\Office16\\\\EXCEL.EXE',
    ];
    for (final path in candidates) {
      final exe = File(path);
      if (await exe.exists()) {
        try {
          await Process.start(
            path,
            [filePath],
            mode: ProcessStartMode.detached,
          );
          return true;
        } catch (_) {
          return false;
        }
      }
    }
    return false;
  }

  static Future<bool> _openWithExplorer(String filePath) async {
    try {
      await Process.start(
        'explorer.exe',
        [filePath],
        mode: ProcessStartMode.detached,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _openContainingFolder(String filePath) async {
    final file = File(filePath);
    final folderPath = file.parent.path;
    if (Platform.isWindows) {
      try {
        await Process.start(
          'explorer.exe',
          ['/select,$filePath'],
          mode: ProcessStartMode.detached,
        );
        return;
      } catch (_) {}
    }
    await OpenFilex.open(folderPath);
  }
}
