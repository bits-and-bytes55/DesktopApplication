import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ConsumeServiceController {
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String get _wellId => currentBackendWellId.trim();

  Future<Map<String, dynamic>> createConsumePackage({
    required String packageName,
    required String code,
    required String unit,
    required double price,
    required double initial,
    required double used,
  }) async {
    try {
      if (_wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final body = jsonEncode({
        'wellId': _wellId,
        'packageName': packageName,
        'code': code,
        'unit': unit,
        'price': price,
        'initial': initial,
        'used': used,
      });

      final response = await http.post(
        Uri.parse('${baseUrl}cs/package'),
        headers: _headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Package created',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to create package',
      };
    } catch (e) {
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
      if (_wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final body = jsonEncode({
        'wellId': _wellId,
        'packageName': packageName,
        'code': code,
        'unit': unit,
        'price': price,
        'initial': initial,
        'used': used,
      });

      final response = await http.put(
        Uri.parse('${baseUrl}cs/package/$id'),
        headers: _headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Package updated',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update package',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteConsumePackage(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}cs/package/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Package deleted',
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to delete package',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getAllConsumePackages() async {
    try {
      if (_wellId.isEmpty) {
        return [];
      }

      final uri = Uri.parse(
        '${baseUrl}cs/package',
      ).replace(queryParameters: {'wellId': _wellId});

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final List items = responseData['data'] ?? [];
        return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createConsumeService({
    required String serviceName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    try {
      if (_wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final body = jsonEncode({
        'wellId': _wellId,
        'serviceName': serviceName,
        'code': code,
        'unit': unit,
        'price': price,
        'usage': usage,
      });

      final response = await http.post(
        Uri.parse('${baseUrl}cs/service'),
        headers: _headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Service created',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to create service',
      };
    } catch (e) {
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
      if (_wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final body = jsonEncode({
        'wellId': _wellId,
        'serviceName': serviceName,
        'code': code,
        'unit': unit,
        'price': price,
        'usage': usage,
      });

      final response = await http.put(
        Uri.parse('${baseUrl}cs/service/$id'),
        headers: _headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Service updated',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update service',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteConsumeService(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}cs/service/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Service deleted',
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to delete service',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getAllConsumeServices() async {
    try {
      if (_wellId.isEmpty) {
        return [];
      }

      final uri = Uri.parse(
        '${baseUrl}cs/service',
      ).replace(queryParameters: {'wellId': _wellId});

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final List items = responseData['data'] ?? [];
        return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createConsumeEngineering({
    required String engineeringName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    try {
      if (_wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final body = jsonEncode({
        'wellId': _wellId,
        'engineeringName': engineeringName,
        'code': code,
        'unit': unit,
        'price': price,
        'usage': usage,
      });

      final response = await http.post(
        Uri.parse('${baseUrl}cs/engineering'),
        headers: _headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Engineering created',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to create engineering',
      };
    } catch (e) {
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
      if (_wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final body = jsonEncode({
        'wellId': _wellId,
        'engineeringName': engineeringName,
        'code': code,
        'unit': unit,
        'price': price,
        'usage': usage,
      });

      final response = await http.put(
        Uri.parse('${baseUrl}cs/engineering/$id'),
        headers: _headers,
        body: body,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Engineering updated',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update engineering',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteConsumeEngineering(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}cs/engineering/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Engineering deleted',
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to delete engineering',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getAllConsumeEngineering() async {
    try {
      if (_wellId.isEmpty) {
        return [];
      }

      final uri = Uri.parse(
        '${baseUrl}cs/engineering',
      ).replace(queryParameters: {'wellId': _wellId});

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final List items = responseData['data'] ?? [];
        return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }
}
