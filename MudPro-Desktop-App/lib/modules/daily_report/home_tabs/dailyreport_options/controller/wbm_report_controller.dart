import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ExportController {
  // ✅ Change this to your actual backend IP/URL
  static const String baseUrl = ApiEndpoint.baseUrl;

  static Future<void> downloadAndOpenInventoryReport() async {
    final uri = Uri.parse('${baseUrl}export/inventory-export');

    final response = await http.get(uri, headers: {
      'Accept':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });
    print('🔵 [API] GET ${uri.toString()}');
    print('🔵 [API] Response status: ${response.statusCode}');
    

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final Directory tempDir = await getTemporaryDirectory();
    final String filePath =
        '${tempDir.path}/WBM_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    await OpenFilex.open(filePath);
  }
}