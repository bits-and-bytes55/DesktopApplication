import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ExportController {
  static const String baseUrl = ApiEndpoint.baseUrl;

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
    final filename =
        _filenameFromHeaders(response) ??
        'WBM_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final String filePath = '${tempDir.path}/$filename';

    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    await OpenFilex.open(filePath);
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
}
