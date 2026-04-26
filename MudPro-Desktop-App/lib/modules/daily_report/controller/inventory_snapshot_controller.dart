import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class InventorySnapshotController {
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _buildUri(String path, {String? wellId, String? reportIdOverride}) {
    final activeWellId = (wellId ?? currentBackendWellId).trim();
    final base = Uri.parse('$baseUrl$path');
    final queryParameters = Map<String, String>.from(base.queryParameters);

    if (activeWellId.isNotEmpty) {
      queryParameters['wellId'] = activeWellId;
    }
    final reportId =
        reportIdOverride?.trim() ?? reportContext.selectedReportId.value.trim();
    if (reportId.isNotEmpty) {
      queryParameters['reportId'] = reportId;
    }

    return base.replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> getInventorySnapshot({
    String? wellId,
    String? reportIdOverride,
  }) async {
    try {
      final activeWellId = (wellId ?? currentBackendWellId).trim();
      if (activeWellId.isEmpty) {
        return {
          'success': false,
          'items': const <Map<String, dynamic>>[],
          'summary': const <String, dynamic>{},
          'message': 'Select a well first.',
        };
      }

      // Always refresh snapshot from the latest source rows before reading it.
      // This keeps receive/return/consume changes visible without requiring
      // every source tab to manage snapshot invalidation perfectly.
      await generateInventorySnapshot(
        wellId: activeWellId,
        reportIdOverride: reportIdOverride,
      );

      final response = await http.get(
        _buildUri(
          'inventory/',
          wellId: activeWellId,
          reportIdOverride: reportIdOverride,
        ),
        headers: _headers,
      );

      debugPrint("Get Inventory Snapshot - responseBody: ${response.body}");
      debugPrint("Get Inventory Snapshot - statusCode: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List items = data['data'] ?? const [];
        if (items.isEmpty) {
          final generated = await generateInventorySnapshot(
            wellId: activeWellId,
            reportIdOverride: reportIdOverride,
          );
          final generatedCount = (generated['count'] is num)
              ? (generated['count'] as num).toInt()
              : 0;

          if (generated['success'] == true && generatedCount > 0) {
            final refreshedResponse = await http.get(
              _buildUri(
                'inventory/',
                wellId: activeWellId,
                reportIdOverride: reportIdOverride,
              ),
              headers: _headers,
            );
            final refreshedData =
                jsonDecode(refreshedResponse.body) as Map<String, dynamic>;
            final List refreshedItems = refreshedData['data'] ?? const [];
            return {
              'success':
                  refreshedResponse.statusCode == 200 ||
                  refreshedResponse.statusCode == 201,
              'items': refreshedItems
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
              'summary': _map(refreshedData['summary']),
              'message': generated['message'],
            };
          }

          return {
            'success': true,
            'items': const <Map<String, dynamic>>[],
            'summary': _map(generated['summary']),
            'message':
                generated['message'] ??
                'No inventory source data found for the selected well.',
          };
        }

        return {
          'success': true,
          'items': items
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          'summary': _map(data['summary']),
          'message': data['message'],
        };
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to load inventory snapshot');
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

  Future<Map<String, dynamic>> generateInventorySnapshot({
    String? wellId,
    String? reportIdOverride,
  }) async {
    try {
      final response = await http.post(
        _buildUri(
          'inventory/generate',
          wellId: wellId,
          reportIdOverride: reportIdOverride,
        ),
        headers: _headers,
      );

      debugPrint(
        "Generate Inventory Snapshot - responseBody: ${response.body}",
      );
      debugPrint(
        "Generate Inventory Snapshot - statusCode: ${response.statusCode}",
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Snapshot generated successfully',
          'count': data['count'] ?? 0,
          'items': (data['data'] as List? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          'summary': _map(data['summary']),
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to generate snapshot',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }
}
