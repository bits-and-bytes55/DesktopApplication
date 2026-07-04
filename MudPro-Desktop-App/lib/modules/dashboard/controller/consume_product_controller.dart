import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ConsumeProductController {
  ConsumeProductController({this.operationInstanceKey = ''});

  final String baseUrl = ApiEndpoint.baseUrl;
  final String operationInstanceKey;

  Map<String, String> get _headers => ApiEndpoint.jsonHeaders;

  Map<String, dynamic> _withReportScope(Map<String, dynamic> payload) {
    final reportId = reportContext.selectedReportId.value.trim();
    if (reportId.isNotEmpty) payload['reportId'] = reportId;
    final instanceKey = operationInstanceKey.trim();
    if (instanceKey.isNotEmpty) payload['operationInstanceKey'] = instanceKey;
    return payload;
  }

  Map<String, String> get _queryScope {
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();
    return {
      if (wellId.isNotEmpty) 'wellId': wellId,
      if (reportId.isNotEmpty) 'reportId': reportId,
      if (operationInstanceKey.trim().isNotEmpty)
        'operationInstanceKey': operationInstanceKey.trim(),
    };
  }

  // ═══════════════════════════════════════════
  //  CREATE CONSUME PRODUCT
  // ═══════════════════════════════════════════
  Future<Map<String, dynamic>> createConsumeProduct({
    required String productName, // ✅ FIX: productId → productName
    required String code,
    required double sg,
    required String unit,
    required double price,
    required double initial,
    required double adjust,
    required double used,
    required double numberOfBags,
    required double weightPerBag,
    int sortOrder = 0,
  }) async {
    try {
      final wellId = currentBackendWellId.trim();
      if (wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final body = jsonEncode(
        _withReportScope({
          'wellId': wellId,
          'product': productName, // ✅ FIX: name send ho raha hai
          'code': code,
          'sg': sg,
          'unit': unit,
          'price': price,
          'initial': initial,
          'adjust': adjust,
          'used': used,
          'numberOfBags': numberOfBags,
          'weightPerBag': weightPerBag,
          'sortOrder': sortOrder,
        }),
      );

      print('🔵 [API] POST ${baseUrl}consume-product');
      print('🔵 [API] Body: $body');

      final response = await http.post(
        Uri.parse('${baseUrl}consume-product'),
        headers: _headers,
        body: body,
      );

      print(
        '🟢 [API] Create ConsumeProduct - statusCode: ${response.statusCode}',
      );
      print('🟢 [API] Create ConsumeProduct - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Product consumed successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to consume product',
        };
      }
    } catch (e) {
      print('🔴 [API] Create ConsumeProduct exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══════════════════════════════════════════
  //  UPDATE CONSUME PRODUCT
  // ═══════════════════════════════════════════
  Future<Map<String, dynamic>> updateConsumeProduct({
    required String id,
    required String productName, // ✅ FIX: productId → productName
    required String code,
    required double sg,
    required String unit,
    required double price,
    required double initial,
    required double adjust,
    required double used,
    required double numberOfBags,
    required double weightPerBag,
    int sortOrder = 0,
  }) async {
    try {
      final wellId = currentBackendWellId.trim();
      if (wellId.isEmpty) {
        return {'success': false, 'message': 'No backend well selected'};
      }

      final body = jsonEncode(
        _withReportScope({
          'wellId': wellId,
          'product': productName, // ✅ FIX: name send ho raha hai
          'code': code,
          'sg': sg,
          'unit': unit,
          'price': price,
          'initial': initial,
          'adjust': adjust,
          'used': used,
          'numberOfBags': numberOfBags,
          'weightPerBag': weightPerBag,
          'sortOrder': sortOrder,
        }),
      );

      print('🔵 [API] PUT ${baseUrl}consume-product/$id');
      print('🔵 [API] Body: $body');

      final response = await http.put(
        Uri.parse(
          '${baseUrl}consume-product/$id',
        ).replace(queryParameters: _queryScope),
        headers: _headers,
        body: body,
      );

      print(
        '🟢 [API] Update ConsumeProduct - statusCode: ${response.statusCode}',
      );
      print('🟢 [API] Update ConsumeProduct - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Product updated successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      print('🔴 [API] Update ConsumeProduct exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══════════════════════════════════════════
  //  DELETE CONSUME PRODUCT
  // ═══════════════════════════════════════════
  Future<Map<String, dynamic>> deleteConsumeProduct(String id) async {
    try {
      print('🔵 [API] DELETE ${baseUrl}consume-product/$id');

      final response = await http.delete(
        Uri.parse(
          '${baseUrl}consume-product/$id',
        ).replace(queryParameters: _queryScope),
        headers: _headers,
      );

      print(
        '🟢 [API] Delete ConsumeProduct - statusCode: ${response.statusCode}',
      );
      print('🟢 [API] Delete ConsumeProduct - responseBody: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Product deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete product',
        };
      }
    } catch (e) {
      print('🔴 [API] Delete ConsumeProduct exception: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ═══════════════════════════════════════════
  //  GET ALL CONSUME PRODUCTS
  // ═══════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getAllConsumeProducts({
    String? reportIdOverride,
    bool scopeToOperationInstance = true,
  }) async {
    try {
      final wellId = currentBackendWellId.trim();
      final reportId =
          reportIdOverride?.trim() ??
          reportContext.selectedReportId.value.trim();
      if (wellId.isEmpty || reportId.isEmpty) {
        return [];
      }

      final uri = Uri.parse('${baseUrl}consume-product').replace(
        queryParameters: {
          'wellId': wellId,
          'strictScope': 'true',
          if (reportId.isNotEmpty) 'reportId': reportId,
          if (scopeToOperationInstance &&
              operationInstanceKey.trim().isNotEmpty)
            'operationInstanceKey': operationInstanceKey.trim(),
        },
      );

      print('🔵 [API] GET $uri');

      final response = await http.get(uri, headers: _headers);

      print(
        '🟢 [API] Get All ConsumeProducts - statusCode: ${response.statusCode}',
      );
      print(
        '🟢 [API] Get All ConsumeProducts - responseBody: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final List items = responseData['data'] ?? [];
        return items
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where(
              (item) => (item['wellId']?.toString().trim() ?? '') == wellId,
            )
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('🔴 [API] Get All ConsumeProducts exception: $e');
      return [];
    }
  }
}
