import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
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
    final query = reportId.isEmpty ? '' : '?reportId=$reportId';
    final uri = Uri.parse('${baseUrl}export/inventory-export/$wellId$query');

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

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = await _resolveOutputPath(tempDir, response);

    final String finalPath =
        await _writeBytesWithRetry(filePath, response.bodyBytes);
    final openResult = await OpenFilex.open(finalPath);
    if (openResult.type != ResultType.done) {
      if (await _openWithExcel(finalPath)) return;
      final docsDir = await getApplicationDocumentsDirectory();
      final docsPath =
          '${docsDir.path}/${_fallbackBaseName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final docsFile = File(docsPath);
      await docsFile.writeAsBytes(response.bodyBytes, flush: true);
      final docsResult = await OpenFilex.open(docsPath);
      if (docsResult.type != ResultType.done) {
        if (!await _openWithExcel(docsPath)) {
          throw Exception(docsResult.message);
        }
      }
    }
  }

  static String? _filenameFromHeaders(http.Response response) {
    final disposition = response.headers['content-disposition'];
    if (disposition == null) return null;

    final match = RegExp(
      "filename\\*?=(?:UTF-8''|\"|)?([^\";]+)",
      caseSensitive: false,
    ).firstMatch(disposition);

    return match?.group(1)?.trim();
  }

  static Future<String> _resolveOutputPath(
    Directory tempDir,
    http.Response response,
  ) async {
    final headerName = _filenameFromHeaders(response);
    final baseName = (headerName ?? _fallbackBaseName).trim();
    final cleanedBase = baseName.isEmpty ? _fallbackBaseName : baseName;
    final String ext = cleanedBase.toLowerCase().endsWith('.xlsx')
        ? ''
        : '.xlsx';
    final String safeBase = cleanedBase.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String candidate = '${tempDir.path}/$safeBase$ext';
    final File file = File(candidate);
    if (await file.exists()) {
      return '${tempDir.path}/${safeBase}_$stamp$ext';
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
      final fallbackPath =
          '${filePath.replaceAll('.xlsx', '')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final fallbackFile = File(fallbackPath);
      await fallbackFile.writeAsBytes(bytes, flush: true);
      return fallbackPath;
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
          final process = await Process.start(path, [filePath]);
          final exitCode = await process.exitCode;
          return exitCode == 0;
        } catch (_) {
          return false;
        }
      }
    }
    return false;
  }
}
