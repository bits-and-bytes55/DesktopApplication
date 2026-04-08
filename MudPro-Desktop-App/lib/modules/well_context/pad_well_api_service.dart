import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';

class PadWellApiService {
  static const String _localDevBaseUrl = 'http://localhost:3000/api/';
  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<AppPad>> fetchPads({bool includeWells = true}) async {
    final decoded = await _getObject(
      path: 'pads',
      queryParameters: {
        if (includeWells) 'includeWells': 'true',
      },
    );

    final data = decoded['data'];
    if (data is! List) return const <AppPad>[];

    return data
        .whereType<Map>()
        .map((item) => AppPad.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<AppWell>> fetchWells({
    String padId = '',
    bool includePad = true,
  }) async {
    final decoded = await _getObject(
      path: 'wells',
      queryParameters: {
        if (padId.isNotEmpty) 'padId': padId,
        if (includePad) 'includePad': 'true',
      },
    );

    final data = decoded['data'];
    if (data is! List) return const <AppWell>[];

    return data
        .whereType<Map>()
        .map((item) => AppWell.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> _getObject({
    required String path,
    Map<String, String>? queryParameters,
  }) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: queryParameters,
      );

      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 12));
        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if (response.statusCode != 200) {
          failures.add(
            '${uri.origin}: ${decoded['message'] ?? 'HTTP ${response.statusCode}'}',
          );
          continue;
        }

        if (decoded['success'] != true) {
          failures.add(
            '${uri.origin}: ${decoded['message'] ?? 'Request failed'}',
          );
          continue;
        }

        return decoded;
      } on TimeoutException {
        failures.add('${uri.origin}: request timed out');
      } on FormatException catch (e) {
        failures.add('${uri.origin}: ${e.message}');
      } catch (e) {
        failures.add('${uri.origin}: ${_cleanError(e)}');
      }
    }

    throw Exception(
      'Pad/well backend routes are not available. '
      'Deploy the latest backend or run local backend on '
      '$_localDevBaseUrl '
      'Tried: ${failures.join(' | ')}',
    );
  }

  Iterable<String> get _candidateBaseUrls sync* {
    final seen = <String>{};
    for (final baseUrl in [ApiEndpoint.baseUrl, _localDevBaseUrl]) {
      final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
      if (seen.add(normalized)) {
        yield normalized;
      }
    }
  }

  Map<String, dynamic> _decodeObject({
    required String body,
    required Uri uri,
    String? contentType,
  }) {
    final trimmed = body.trim();
    final lowerContentType = (contentType ?? '').toLowerCase();

    if (trimmed.isEmpty) {
      throw FormatException('empty response');
    }

    if (lowerContentType.contains('text/html') ||
        trimmed.startsWith('<!DOCTYPE html') ||
        trimmed.startsWith('<html')) {
      throw FormatException('HTML error page returned for ${uri.path}');
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const FormatException('Unexpected API response');
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
