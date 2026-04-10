import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

class ConsumeServiceController {
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _buildUri(String path, {String? wellId, String? reportId}) {
    final base = Uri.parse('${baseUrl}$path');
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        if (wellId != null && wellId.isNotEmpty) 'wellId': wellId,
        if (reportId != null && reportId.isNotEmpty) 'reportId': reportId,
      },
    );
  }

  Map<String, dynamic> _withScope(
    Map<String, dynamic> data, {
    String? wellId,
    String? reportId,
  }) {
    return {
      ...data,
      if (wellId != null && wellId.isNotEmpty) 'wellId': wellId,
      if (reportId != null && reportId.isNotEmpty) 'reportId': reportId,
    };
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Saved successfully',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Request failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}$path'),
        headers: _headers,
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Updated successfully',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Request failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}$path'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Deleted successfully',
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Request failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    String? wellId,
    String? reportId,
  }) async {
    try {
      final response = await http.get(
        _buildUri(path, wellId: wellId, reportId: reportId),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final List items = responseData['data'] ?? [];
        return items.map((e) => e as Map<String, dynamic>).toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createConsumePackage({
    String? wellId,
    String? reportId,
    required String packageName,
    required String code,
    required String unit,
    required double price,
    required double initial,
    required double used,
  }) async {
    return _post(
      'cs/package',
      _withScope(
        {
          'packageName': packageName,
          'code': code,
          'unit': unit,
          'price': price,
          'initial': initial,
          'used': used,
        },
        wellId: wellId,
        reportId: reportId,
      ),
    );
  }

  Future<Map<String, dynamic>> updateConsumePackage({
    required String id,
    String? wellId,
    String? reportId,
    required String packageName,
    required String code,
    required String unit,
    required double price,
    required double initial,
    required double used,
  }) async {
    return _put(
      'cs/package/$id',
      _withScope(
        {
          'packageName': packageName,
          'code': code,
          'unit': unit,
          'price': price,
          'initial': initial,
          'used': used,
        },
        wellId: wellId,
        reportId: reportId,
      ),
    );
  }

  Future<Map<String, dynamic>> deleteConsumePackage(String id) async {
    return _delete('cs/package/$id');
  }

  Future<List<Map<String, dynamic>>> getAllConsumePackages({
    String? wellId,
    String? reportId,
  }) async {
    return _getList('cs/package', wellId: wellId, reportId: reportId);
  }

  Future<Map<String, dynamic>> createConsumeService({
    String? wellId,
    String? reportId,
    required String serviceName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    return _post(
      'cs/service',
      _withScope(
        {
          'serviceName': serviceName,
          'code': code,
          'unit': unit,
          'price': price,
          'usage': usage,
        },
        wellId: wellId,
        reportId: reportId,
      ),
    );
  }

  Future<Map<String, dynamic>> updateConsumeService({
    required String id,
    String? wellId,
    String? reportId,
    required String serviceName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    return _put(
      'cs/service/$id',
      _withScope(
        {
          'serviceName': serviceName,
          'code': code,
          'unit': unit,
          'price': price,
          'usage': usage,
        },
        wellId: wellId,
        reportId: reportId,
      ),
    );
  }

  Future<Map<String, dynamic>> deleteConsumeService(String id) async {
    return _delete('cs/service/$id');
  }

  Future<List<Map<String, dynamic>>> getAllConsumeServices({
    String? wellId,
    String? reportId,
  }) async {
    return _getList('cs/service', wellId: wellId, reportId: reportId);
  }

  Future<Map<String, dynamic>> createConsumeEngineering({
    String? wellId,
    String? reportId,
    required String engineeringName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    return _post(
      'cs/engineering',
      _withScope(
        {
          'engineeringName': engineeringName,
          'code': code,
          'unit': unit,
          'price': price,
          'usage': usage,
        },
        wellId: wellId,
        reportId: reportId,
      ),
    );
  }

  Future<Map<String, dynamic>> updateConsumeEngineering({
    required String id,
    String? wellId,
    String? reportId,
    required String engineeringName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    return _put(
      'cs/engineering/$id',
      _withScope(
        {
          'engineeringName': engineeringName,
          'code': code,
          'unit': unit,
          'price': price,
          'usage': usage,
        },
        wellId: wellId,
        reportId: reportId,
      ),
    );
  }

  Future<Map<String, dynamic>> deleteConsumeEngineering(String id) async {
    return _delete('cs/engineering/$id');
  }

  Future<List<Map<String, dynamic>>> getAllConsumeEngineering({
    String? wellId,
    String? reportId,
  }) async {
    return _getList('cs/engineering', wellId: wellId, reportId: reportId);
  }
}
