import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class InventorySnapshotController {
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _buildUri(String path, {String? wellId}) {
    final activeWellId = (wellId ?? currentBackendWellId).trim();
    final base = Uri.parse('$baseUrl$path');
    if (activeWellId.isEmpty) return base;

    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        'wellId': activeWellId,
      },
    );
  }

  Future<Map<String, dynamic>> getInventorySnapshot({String? wellId}) async {
    try {
      final response = await http.get(
        _buildUri('inventory/', wellId: wellId),
        headers: _headers,
      );

      debugPrint("Get Inventory Snapshot - responseBody: ${response.body}");
      debugPrint("Get Inventory Snapshot - statusCode: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List items = data['data'] ?? const [];
        return {
          'success': true,
          'items': items.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          'summary': _map(data['summary']),
        };
      }

      throw Exception('Failed to load inventory snapshot');
    } catch (e) {
      debugPrint('Error fetching inventory snapshot: $e');
      return {
        'success': false,
        'items': const <Map<String, dynamic>>[],
        'summary': const <String, dynamic>{},
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> generateInventorySnapshot({String? wellId}) async {
    try {
      final response = await http.post(
        _buildUri('inventory/generate', wellId: wellId),
        headers: _headers,
      );

      debugPrint("Generate Inventory Snapshot - responseBody: ${response.body}");
      debugPrint("Generate Inventory Snapshot - statusCode: ${response.statusCode}");

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Snapshot generated successfully',
          'count': data['count'] ?? 0,
          'summary': _map(data['summary']),
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to generate snapshot',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }
}
