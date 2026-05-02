import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapDrillingDataController extends GetxController {
  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapDrillingDataController({
    ReportApiService? reportApi,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _reportApi = reportApi ?? ReportApiService(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  static Map<String, String> get _headers => ApiEndpoint.jsonHeaders;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final rows = <DrillingDataHistoryRow>[].obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(_padWellController.selectedWellId, (_) => load());
    _reportWorker = ever<String>(_reportContext.selectedReportId, (_) => load());
    load();
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final wellId = currentBackendWellId.trim();
    errorMessage.value = '';
    emptyMessage.value = '';

    if (wellId.isEmpty) {
      rows.clear();
      emptyMessage.value = 'Select a well first to open Drilling Data recap.';
      return;
    }

    isLoading.value = true;

    try {
      final summaries = await _reportApi.fetchReportManagerRows(wellId);
      if (summaries.isEmpty) {
        rows.clear();
        emptyMessage.value = 'No reports are available for the selected well.';
        return;
      }

      final ordered = [...summaries]..sort(_compareRowsOldestFirst);
      final wellGeneralRows = await _fetchWellGeneralRows(wellId);

      final byReportId = _pickLatestByKey(
        wellGeneralRows,
        (row) => _text(row['reportId']),
      );
      final byReportNo = _pickLatestByKey(
        wellGeneralRows,
        (row) => _text(row['reportNo']),
      );
      final byUserReportNo = _pickLatestByKey(
        wellGeneralRows,
        (row) => _text(row['userReportNo']),
      );

      final history = ordered.map((summary) {
        final matched =
            byReportId[summary.reportId] ??
            byReportNo[summary.reportNo] ??
            byUserReportNo[summary.userReportNo] ??
            _matchByDate(wellGeneralRows, summary);

        final mudType = summary.mudType.isNotEmpty
            ? summary.mudType
            : 'Unspecified';

        return DrillingDataHistoryRow(
          reportId: summary.reportId,
          reportLabel: summary.reportLabel,
          reportDate: summary.reportDate.isNotEmpty
              ? summary.reportDate
              : _text(matched?['date']),
          createdAt: summary.createdAt,
          md: _number(matched?['md'], fallback: summary.md),
          tvd: _number(matched?['tvd']),
          inc: _number(matched?['inc']),
          azi: _number(matched?['azi']),
          wob: _number(matched?['wob']),
          rotWt: _number(matched?['rotWt']),
          soWt: _number(matched?['soWt']),
          puWt: _number(matched?['puWt']),
          rpm: _number(matched?['rpm']),
          rop: _number(matched?['rop']),
          depthDrilled: _number(matched?['depthDrilled']),
          activity: _text(matched?['activity']).isNotEmpty
              ? _text(matched?['activity'])
              : summary.activity,
          interval: _text(matched?['interval']).isNotEmpty
              ? _text(matched?['interval'])
              : summary.interval,
          formation: _text(matched?['formation']),
          mudType: mudType,
        );
      }).toList();

      rows.assignAll(history);
      if (history.isEmpty) {
        emptyMessage.value = 'No drilling history is available yet.';
      }
    } catch (error) {
      rows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  List<double> get wobSeries => rows.map((row) => row.wob).toList();
  List<double> get soWtSeries => rows.map((row) => row.soWt).toList();
  List<double> get puWtSeries => rows.map((row) => row.puWt).toList();
  List<double> get rpmSeries => rows.map((row) => row.rpm).toList();
  List<double> get ropSeries => rows.map((row) => row.rop).toList();

  Future<List<Map<String, dynamic>>> _fetchWellGeneralRows(String wellId) async {
    final decoded = await _getObject(path: 'well-general/$wellId');
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, Map<String, dynamic>> _pickLatestByKey(
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic> item) keyFor,
  ) {
    final ordered = [...items]..sort((left, right) {
      final leftTime = _timestampOf(left);
      final rightTime = _timestampOf(right);
      return rightTime.compareTo(leftTime);
    });

    final output = <String, Map<String, dynamic>>{};
    for (final item in ordered) {
      final key = keyFor(item);
      if (key.isEmpty || output.containsKey(key)) continue;
      output[key] = item;
    }
    return output;
  }

  Map<String, dynamic>? _matchByDate(
    List<Map<String, dynamic>> candidates,
    ReportManagerRow summary,
  ) {
    final targetDate = _parseDate(summary.reportDate) ?? _parseDate(summary.createdAt);
    if (targetDate == null) return null;

    for (final candidate in candidates) {
      final candidateDate =
          _parseDate(_text(candidate['date'])) ??
          _parseDate(_text(candidate['createdAt']));
      if (candidateDate == null) continue;
      if (_sameDay(candidateDate, targetDate)) {
        return candidate;
      }
    }
    return null;
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
            .timeout(const Duration(seconds: 20));
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
      } on FormatException catch (error) {
        failures.add('${uri.origin}: ${error.message}');
      } catch (error) {
        failures.add('${uri.origin}: ${_cleanError(error)}');
      }
    }

    throw Exception(
      'Drilling Data recap backend routes are not available. '
      'Tried: ${failures.join(' | ')}',
    );
  }

  Iterable<String> get _candidateBaseUrls sync* {
    final seen = <String>{};
    for (final baseUrl in [ApiEndpoint.baseUrl, 'http://localhost:3000/api/']) {
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
    final isJson = (contentType ?? '').toLowerCase().contains('application/json');
    if (!isJson &&
        (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html'))) {
      throw FormatException(
        'HTML error page returned from ${uri.origin}. Expected JSON response.',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw FormatException('Unexpected response format from ${uri.origin}');
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\\s*'), '');
  }

  int _timestampOf(Map<String, dynamic> row) {
    final updated = _parseDate(_text(row['updatedAt']));
    if (updated != null) return updated.millisecondsSinceEpoch;
    final created = _parseDate(_text(row['createdAt']));
    if (created != null) return created.millisecondsSinceEpoch;
    return 0;
  }

  DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    final slashParts = trimmed.split('/');
    if (slashParts.length == 3) {
      final month = int.tryParse(slashParts[0]);
      final day = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  bool _sameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';

  double _number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class DrillingDataHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final double tvd;
  final double inc;
  final double azi;
  final double wob;
  final double rotWt;
  final double soWt;
  final double puWt;
  final double rpm;
  final double rop;
  final double depthDrilled;
  final String activity;
  final String interval;
  final String formation;
  final String mudType;

  const DrillingDataHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.tvd,
    required this.inc,
    required this.azi,
    required this.wob,
    required this.rotWt,
    required this.soWt,
    required this.puWt,
    required this.rpm,
    required this.rop,
    required this.depthDrilled,
    required this.activity,
    required this.interval,
    required this.formation,
    required this.mudType,
  });
}

int _compareRowsOldestFirst(ReportManagerRow left, ReportManagerRow right) {
  final leftDate = _parseReportDate(left);
  final rightDate = _parseReportDate(right);

  if (leftDate != null && rightDate != null) {
    final compare = leftDate.compareTo(rightDate);
    if (compare != 0) return compare;
  } else if (leftDate != null) {
    return -1;
  } else if (rightDate != null) {
    return 1;
  }

  final leftNo = int.tryParse(left.reportLabel);
  final rightNo = int.tryParse(right.reportLabel);
  if (leftNo != null && rightNo != null) {
    return leftNo.compareTo(rightNo);
  }
  return left.reportLabel.toLowerCase().compareTo(
    right.reportLabel.toLowerCase(),
  );
}

DateTime? _parseReportDate(ReportManagerRow row) {
  for (final value in [row.reportDate, row.createdAt]) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;

    final parts = value.split('/');
    if (parts.length == 3) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }
  }
  return null;
}
