import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

class ConsumeServiceController {
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ═══════════════════════════════════════════
  //  PACKAGE
  // ═══════════════════════════════════════════

  Future<Map<String, dynamic>> createConsumePackage({
    required String packageName,
    required String code,
    required String unit,
    required double price,
    required double initial,
    required double used,
  }) async {
    try {
      final body = jsonEncode({
        'packageName': packageName,
        'code':        code,
        'unit':        unit,
        'price':       price,
        'initial':     initial,
        'used':        used,
      });

      print('🔵 [API] POST ${baseUrl}cs/package');
      print('🔵 [API] Body: $body');

      final response = await http.post(
        Uri.parse('${baseUrl}cs/package'),
        headers: _headers,
        body: body,
      );

      print('🟢 [API] Create Package - statusCode: ${response.statusCode}');
      print('🟢 [API] Create Package - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Package created',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create package',
        };
      }
    } catch (e) {
      print('🔴 [API] Create Package exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateConsumePackage({
    required String id,
    required String packageName,
    required String code,
    required String unit,
    required double price,
    required double initial,
    required double used,
  }) async {
    try {
      final body = jsonEncode({
        'packageName': packageName,
        'code':        code,
        'unit':        unit,
        'price':       price,
        'initial':     initial,
        'used':        used,
      });

      print('🔵 [API] PUT ${baseUrl}cs/package/$id');
      print('🔵 [API] Body: $body');

      final response = await http.put(
        Uri.parse('${baseUrl}cs/package/$id'),
        headers: _headers,
        body: body,
      );

      print('🟢 [API] Update Package - statusCode: ${response.statusCode}');
      print('🟢 [API] Update Package - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Package updated',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update package',
        };
      }
    } catch (e) {
      print('🔴 [API] Update Package exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteConsumePackage(String id) async {
    try {
      print('🔵 [API] DELETE ${baseUrl}cs/package/$id');

      final response = await http.delete(
        Uri.parse('${baseUrl}cs/package/$id'),
        headers: _headers,
      );

      print('🟢 [API] Delete Package - statusCode: ${response.statusCode}');
      print('🟢 [API] Delete Package - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Package deleted',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete package',
        };
      }
    } catch (e) {
      print('🔴 [API] Delete Package exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getAllConsumePackages() async {
    try {
      print('🔵 [API] GET ${baseUrl}cs/package');

      final response = await http.get(
        Uri.parse('${baseUrl}cs/package'),
        headers: _headers,
      );

      print('🟢 [API] Get All Packages - statusCode: ${response.statusCode}');
      print('🟢 [API] Get All Packages - responseBody: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final List items = responseData['data'] ?? [];
        return items.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('🔴 [API] Get All Packages exception: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════
  //  SERVICE
  // ═══════════════════════════════════════════

  Future<Map<String, dynamic>> createConsumeService({
    required String serviceName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    try {
      final body = jsonEncode({
        'serviceName': serviceName,
        'code':        code,
        'unit':        unit,
        'price':       price,
        'usage':       usage,
      });

      print('🔵 [API] POST ${baseUrl}cs/service');
      print('🔵 [API] Body: $body');

      final response = await http.post(
        Uri.parse('${baseUrl}cs/service'),
        headers: _headers,
        body: body,
      );

      print('🟢 [API] Create Service - statusCode: ${response.statusCode}');
      print('🟢 [API] Create Service - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Service created',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create service',
        };
      }
    } catch (e) {
      print('🔴 [API] Create Service exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateConsumeService({
    required String id,
    required String serviceName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    try {
      final body = jsonEncode({
        'serviceName': serviceName,
        'code':        code,
        'unit':        unit,
        'price':       price,
        'usage':       usage,
      });

      print('🔵 [API] PUT ${baseUrl}cs/service/$id');
      print('🔵 [API] Body: $body');

      final response = await http.put(
        Uri.parse('${baseUrl}cs/service/$id'),
        headers: _headers,
        body: body,
      );

      print('🟢 [API] Update Service - statusCode: ${response.statusCode}');
      print('🟢 [API] Update Service - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Service updated',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update service',
        };
      }
    } catch (e) {
      print('🔴 [API] Update Service exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteConsumeService(String id) async {
    try {
      print('🔵 [API] DELETE ${baseUrl}cs/service/$id');

      final response = await http.delete(
        Uri.parse('${baseUrl}cs/service/$id'),
        headers: _headers,
      );

      print('🟢 [API] Delete Service - statusCode: ${response.statusCode}');
      print('🟢 [API] Delete Service - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Service deleted',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete service',
        };
      }
    } catch (e) {
      print('🔴 [API] Delete Service exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getAllConsumeServices() async {
    try {
      print('🔵 [API] GET ${baseUrl}cs/service');

      final response = await http.get(
        Uri.parse('${baseUrl}cs/service'),
        headers: _headers,
      );

      print('🟢 [API] Get All Services - statusCode: ${response.statusCode}');
      print('🟢 [API] Get All Services - responseBody: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final List items = responseData['data'] ?? [];
        return items.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('🔴 [API] Get All Services exception: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════
  //  ENGINEERING
  // ═══════════════════════════════════════════

  Future<Map<String, dynamic>> createConsumeEngineering({
    required String engineeringName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    try {
      final body = jsonEncode({
        'engineeringName': engineeringName,
        'code':            code,
        'unit':            unit,
        'price':           price,
        'usage':           usage,
      });

      print('🔵 [API] POST ${baseUrl}cs/engineering');
      print('🔵 [API] Body: $body');

      final response = await http.post(
        Uri.parse('${baseUrl}cs/engineering'),
        headers: _headers,
        body: body,
      );

      print('🟢 [API] Create Engineering - statusCode: ${response.statusCode}');
      print('🟢 [API] Create Engineering - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Engineering created',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create engineering',
        };
      }
    } catch (e) {
      print('🔴 [API] Create Engineering exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateConsumeEngineering({
    required String id,
    required String engineeringName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    try {
      final body = jsonEncode({
        'engineeringName': engineeringName,
        'code':            code,
        'unit':            unit,
        'price':           price,
        'usage':           usage,
      });

      print('🔵 [API] PUT ${baseUrl}cs/engineering/$id');
      print('🔵 [API] Body: $body');

      final response = await http.put(
        Uri.parse('${baseUrl}cs/engineering/$id'),
        headers: _headers,
        body: body,
      );

      print('🟢 [API] Update Engineering - statusCode: ${response.statusCode}');
      print('🟢 [API] Update Engineering - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Engineering updated',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update engineering',
        };
      }
    } catch (e) {
      print('🔴 [API] Update Engineering exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteConsumeEngineering(String id) async {
    try {
      print('🔵 [API] DELETE ${baseUrl}cs/engineering/$id');

      final response = await http.delete(
        Uri.parse('${baseUrl}cs/engineering/$id'),
        headers: _headers,
      );

      print('🟢 [API] Delete Engineering - statusCode: ${response.statusCode}');
      print('🟢 [API] Delete Engineering - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Engineering deleted',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete engineering',
        };
      }
    } catch (e) {
      print('🔴 [API] Delete Engineering exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getAllConsumeEngineering() async {
    try {
      print('🔵 [API] GET ${baseUrl}cs/engineering');

      final response = await http.get(
        Uri.parse('${baseUrl}cs/engineering'),
        headers: _headers,
      );

      print('🟢 [API] Get All Engineering - statusCode: ${response.statusCode}');
      print('🟢 [API] Get All Engineering - responseBody: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final List items = responseData['data'] ?? [];
        return items.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('🔴 [API] Get All Engineering exception: $e');
      return [];
    }
  }
}