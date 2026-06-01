import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ReturnProductController {
  ReturnProductController({this.operationInstanceKey = ''});

  final String baseUrl = ApiEndpoint.baseUrl;
  final String operationInstanceKey;

  Map<String, String> get _headers => ApiEndpoint.jsonHeaders;

  String get _wellId => currentBackendWellId.trim();

  Map<String, String> get _queryScope {
    final reportId = reportContext.selectedReportId.value.trim();
    return {
      'wellId': _wellId,
      if (reportId.isNotEmpty) 'reportId': reportId,
      if (operationInstanceKey.trim().isNotEmpty)
        'operationInstanceKey': operationInstanceKey.trim(),
    };
  }

  Map<String, dynamic> _withReportScope(Map<String, dynamic> payload) {
    final reportId = reportContext.selectedReportId.value.trim();
    if (reportId.isNotEmpty) payload['reportId'] = reportId;
    final instanceKey = operationInstanceKey.trim();
    if (instanceKey.isNotEmpty) payload['operationInstanceKey'] = instanceKey;
    return payload;
  }

  Future<List<Map<String, dynamic>>> getReturnProducts() async {
    try {
      if (_wellId.isEmpty) {
        return [];
      }

      final uri = Uri.parse(
        '${baseUrl}return-product',
      ).replace(queryParameters: _queryScope);

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      throw Exception('Failed to load return products');
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createReturnProduct({
    required String productName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      if (_wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final response = await http.post(
        Uri.parse('${baseUrl}return-product'),
        headers: _headers,
        body: jsonEncode(
          _withReportScope({
            'wellId': _wellId,
            'productName': productName,
            'code': code,
            'unit': unit,
            'amount': amount,
          }),
        ),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Product returned successfully',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to return product',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateReturnProduct({
    required String id,
    required String productName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      if (_wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final response = await http.put(
        Uri.parse('${baseUrl}return-product/$id'),
        headers: _headers,
        body: jsonEncode(
          _withReportScope({
            'wellId': _wellId,
            'productName': productName,
            'code': code,
            'unit': unit,
            'amount': amount,
          }),
        ),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Product updated successfully',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update product',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteReturnProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${baseUrl}return-product/$id',
        ).replace(queryParameters: _queryScope),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Product deleted successfully'};
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to delete product',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getReturnPackages() async {
    try {
      if (_wellId.isEmpty) {
        return [];
      }

      final uri = Uri.parse(
        '${baseUrl}return-package',
      ).replace(queryParameters: _queryScope);

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      throw Exception('Failed to load return packages');
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createReturnPackage({
    required String packageName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      if (_wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final response = await http.post(
        Uri.parse('${baseUrl}return-package'),
        headers: _headers,
        body: jsonEncode(
          _withReportScope({
            'wellId': _wellId,
            'packageName': packageName,
            'code': code,
            'unit': unit,
            'amount': amount,
          }),
        ),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Package returned successfully',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to return package',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateReturnPackage({
    required String id,
    required String packageName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      if (_wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final response = await http.put(
        Uri.parse('${baseUrl}return-package/$id'),
        headers: _headers,
        body: jsonEncode(
          _withReportScope({
            'wellId': _wellId,
            'packageName': packageName,
            'code': code,
            'unit': unit,
            'amount': amount,
          }),
        ),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Package updated successfully',
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

  Future<Map<String, dynamic>> deleteReturnPackage(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${baseUrl}return-package/$id',
        ).replace(queryParameters: _queryScope),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Package deleted successfully'};
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to delete package',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> saveAllReturnData({
    required List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> packages = const [],
  }) async {
    try {
      final productResults = <Map<String, dynamic>>[];
      final packageResults = <Map<String, dynamic>>[];

      for (final product in products) {
        if (product['productName'] != null &&
            product['productName'].toString().isNotEmpty) {
          final result = await createReturnProduct(
            productName: product['productName'],
            code: product['code'] ?? '',
            unit: product['unit'] ?? '',
            amount: double.tryParse(product['amount'] ?? '0') ?? 0.0,
          );
          productResults.add(result);
        }
      }

      for (final pkg in packages) {
        if (pkg['packageName'] != null &&
            pkg['packageName'].toString().isNotEmpty) {
          final result = await createReturnPackage(
            packageName: pkg['packageName'],
            code: pkg['code'] ?? '',
            unit: pkg['unit'] ?? '',
            amount: double.tryParse(pkg['amount'] ?? '0') ?? 0.0,
          );
          packageResults.add(result);
        }
      }

      final totalSuccess =
          productResults.where((r) => r['success'] == true).length +
          packageResults.where((r) => r['success'] == true).length;

      return {
        'success': true,
        'message': '$totalSuccess items saved successfully',
        'productResults': productResults,
        'packageResults': packageResults,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error saving data: $e'};
    }
  }
}
