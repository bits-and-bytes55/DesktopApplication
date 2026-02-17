import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

class InventorySnapshotController {
  // Base URL - update this to your actual API URL
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ============ GET INVENTORY SNAPSHOT ============
  Future<List<Map<String, dynamic>>> getInventorySnapshot() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}inventory/'),
        headers: _headers,
      );

      print("Get Inventory Snapshot - responseBody: ${response.body}");
      print("Get Inventory Snapshot - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load inventory snapshot');
      }
    } catch (e) {
      print('Error fetching inventory snapshot: $e');
      return [];
    }
  }

  // ============ GENERATE INVENTORY SNAPSHOT ============
  Future<Map<String, dynamic>> generateInventorySnapshot() async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}inventory/generate'),
        headers: _headers,
      );

      print("Generate Inventory Snapshot - responseBody: ${response.body}");
      print("Generate Inventory Snapshot - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Snapshot generated successfully',
          'count': data['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to generate snapshot',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
