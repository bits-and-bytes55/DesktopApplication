import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';

class ReportApiService {
  static const String _localDevBaseUrl = 'http://localhost:3000/api/';
  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<AppReport>> fetchReports(String wellId) async {
    final decoded = await _getObject(
      path: 'reports',
      queryParameters: {'wellId': wellId},
    );

    final data = decoded['data'];
    if (data is! List) return const <AppReport>[];

    final reports = data
        .whereType<Map>()
        .map((item) => AppReport.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    reports.sort(_compareReports);
    return reports;
  }

  Future<List<ReportManagerRow>> fetchReportManagerRows(String wellId) async {
    final decoded = await _getObject(
      path: 'reports/manager',
      queryParameters: {'wellId': wellId},
    );

    final data = decoded['data'];
    if (data is! List) return const <ReportManagerRow>[];

    final rows = data
        .whereType<Map>()
        .map(
          (item) => ReportManagerRow.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    rows.sort(_compareReportManagerRows);
    return rows;
  }

  Future<Map<String, dynamic>> createReport(Map<String, dynamic> payload) {
    return _sendObject(
      method: 'POST',
      path: 'reports',
      body: payload,
      successStatusCodes: const {201},
      defaultErrorMessage: 'Failed to create report',
    );
  }

  Future<Map<String, dynamic>> updateReport(
    String reportId,
    Map<String, dynamic> payload,
  ) {
    return _sendObject(
      method: 'PUT',
      path: 'reports/$reportId',
      body: payload,
      successStatusCodes: const {200},
      defaultErrorMessage: 'Failed to update report',
    );
  }

  Future<Map<String, dynamic>> deleteReport(String reportId) {
    return _sendObject(
      method: 'DELETE',
      path: 'reports/$reportId',
      successStatusCodes: const {200},
      defaultErrorMessage: 'Failed to delete report',
    );
  }

  Future<Map<String, dynamic>> _getObject({
    required String path,
    Map<String, String>? queryParameters,
  }) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParameters);

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
      'Report backend routes are not available. '
      'Deploy the latest backend or run local backend on '
      '$_localDevBaseUrl '
      'Tried: ${failures.join(' | ')}',
    );
  }

  Future<Map<String, dynamic>> _sendObject({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    required Set<int> successStatusCodes,
    required String defaultErrorMessage,
  }) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse('$baseUrl$path');

      try {
        final response = await _sendRequest(
          method: method,
          uri: uri,
          body: body,
        ).timeout(const Duration(seconds: 15));

        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if (!successStatusCodes.contains(response.statusCode)) {
          failures.add(
            '${uri.origin}: ${decoded['message'] ?? defaultErrorMessage}',
          );
          continue;
        }

        if (decoded['success'] != true) {
          failures.add(
            '${uri.origin}: ${decoded['message'] ?? defaultErrorMessage}',
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
      '$defaultErrorMessage. '
      'Deploy the latest backend or run local backend on '
      '$_localDevBaseUrl '
      'Tried: ${failures.join(' | ')}',
    );
  }

  Future<http.Response> _sendRequest({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
  }) {
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method.toUpperCase()) {
      case 'POST':
        return http.post(uri, headers: _headers, body: encodedBody);
      case 'PUT':
        return http.put(uri, headers: _headers, body: encodedBody);
      case 'DELETE':
        return http.delete(uri, headers: _headers, body: encodedBody);
      default:
        throw UnsupportedError('Unsupported method: $method');
    }
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
      throw const FormatException('empty response');
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

int _compareReports(AppReport a, AppReport b) {
  final leftNo = int.tryParse(a.reportNo.trim());
  final rightNo = int.tryParse(b.reportNo.trim());

  if (leftNo != null && rightNo != null && leftNo != rightNo) {
    return leftNo.compareTo(rightNo);
  }

  if (leftNo != null && rightNo == null) return -1;
  if (leftNo == null && rightNo != null) return 1;

  final leftCreated = DateTime.tryParse(a.createdAt);
  final rightCreated = DateTime.tryParse(b.createdAt);
  if (leftCreated != null && rightCreated != null) {
    final createdCompare = leftCreated.compareTo(rightCreated);
    if (createdCompare != 0) {
      return createdCompare;
    }
  }

  return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
}

int _compareReportManagerRows(ReportManagerRow a, ReportManagerRow b) {
  final leftNo = int.tryParse(a.reportNo.trim());
  final rightNo = int.tryParse(b.reportNo.trim());

  if (leftNo != null && rightNo != null && leftNo != rightNo) {
    return leftNo.compareTo(rightNo);
  }

  if (leftNo != null && rightNo == null) return -1;
  if (leftNo == null && rightNo != null) return 1;

  final leftCreated = DateTime.tryParse(a.createdAt);
  final rightCreated = DateTime.tryParse(b.createdAt);
  if (leftCreated != null && rightCreated != null) {
    final createdCompare = leftCreated.compareTo(rightCreated);
    if (createdCompare != 0) {
      return createdCompare;
    }
  }

  return a.reportLabel.toLowerCase().compareTo(b.reportLabel.toLowerCase());
}
