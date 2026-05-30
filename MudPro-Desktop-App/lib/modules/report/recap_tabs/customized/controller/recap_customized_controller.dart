import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapCustomizedController extends GetxController {
  RecapCustomizedController({
    ReportApiService? reportApi,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _reportApi = reportApi ?? ReportApiService(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  static Map<String, String> get _headers => ApiEndpoint.jsonHeaders;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final rows = <RecapCustomizedHistoryRow>[].obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(
      _padWellController.selectedWellId,
      (_) => load(),
    );
    _reportWorker = ever<String>(
      _reportContext.selectedReportId,
      (_) => load(),
    );
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
      emptyMessage.value = 'Select a well first to open Customized recap.';
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
      List<Map<String, dynamic>> wellGeneralRows;
      try {
        wellGeneralRows = await _fetchWellGeneralRows(wellId);
      } catch (_) {
        wellGeneralRows = const <Map<String, dynamic>>[];
      }

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

      final history = <RecapCustomizedHistoryRow>[];

      for (int index = 0; index < ordered.length; index++) {
        final summary = ordered[index];
        final matched =
            byReportId[summary.reportId] ??
            byReportNo[summary.reportNo] ??
            byUserReportNo[summary.userReportNo] ??
            _matchByDate(wellGeneralRows, summary);

        history.add(
          RecapCustomizedHistoryRow(
            dayNumber: index + 1,
            reportId: summary.reportId,
            reportLabel: summary.reportLabel,
            reportDate: summary.reportDate,
            createdAt: summary.createdAt,
            mw: summary.mw > 0
                ? summary.mw
                : _rawNumberOrNull(matched, const ['mw', 'mudWeight']),
            totalKwd: _resolveTotal(summary, matched),
            puWt: _rawNumberOrNull(matched, const ['puWt']),
            rpm: _rawNumberOrNull(matched, const ['rpm']),
            rop: _rawNumberOrNull(matched, const ['rop']),
          ),
        );
      }

      rows.assignAll(history);
      if (history.isEmpty) {
        emptyMessage.value = 'No customized graph history is available yet.';
      } else if (!history.any((row) => row.hasAnyMetric)) {
        emptyMessage.value =
            'Report history is available, but customized graph values are empty.';
      }
    } catch (error) {
      rows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWellGeneralRows(
    String wellId,
  ) async {
    final decoded = await _getObject(path: 'well-general/$wellId');
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
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
      'Customized recap backend routes are not available. '
      'Tried: ${failures.join(' | ')}',
    );
  }

  Iterable<String> get _candidateBaseUrls sync* {
    final seen = <String>{};
    for (final baseUrl in ApiEndpoint.candidateBaseUrls) {
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
    final isJson = (contentType ?? '').toLowerCase().contains(
      'application/json',
    );
    if (!isJson &&
        (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html'))) {
      throw FormatException(
        'HTML error page returned from ${uri.origin}. '
        'Expected JSON response.',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw FormatException('Unexpected response format from ${uri.origin}');
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  Map<String, Map<String, dynamic>> _pickLatestByKey(
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic> item) keyFor,
  ) {
    final ordered = [...items]
      ..sort((left, right) {
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
    final targetDate =
        _parseDate(summary.reportDate) ?? _parseDate(summary.createdAt);
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

  double? _resolveTotal(
    ReportManagerRow summary,
    Map<String, dynamic>? matched,
  ) {
    if (summary.cumulativeCost > 0) return summary.cumulativeCost;
    if (summary.dailyCost > 0) return summary.dailyCost;
    return _rawNumberOrNull(matched, const [
      'cumulativeCost',
      'totalKwd',
      'dailyCost',
    ]);
  }

  double? _rawNumberOrNull(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;

    for (final key in keys) {
      if (!source.containsKey(key)) continue;
      final value = source[key];
      if (value == null) return null;
      if (value is num) return value.toDouble();
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      return double.tryParse(text);
    }
    return null;
  }

  int _timestampOf(Map<String, dynamic> item) {
    for (final value in [
      item['updatedAt'],
      item['createdAt'],
      item['date'],
      item['reportDate'],
    ]) {
      final parsed = _parseDate(_text(value));
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
    return 0;
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  bool _sameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class RecapCustomizedHistoryRow {
  final int dayNumber;
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double? mw;
  final double? totalKwd;
  final double? puWt;
  final double? rpm;
  final double? rop;

  const RecapCustomizedHistoryRow({
    required this.dayNumber,
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.mw,
    required this.totalKwd,
    required this.puWt,
    required this.rpm,
    required this.rop,
  });

  bool get hasAnyMetric =>
      mw != null ||
      totalKwd != null ||
      puWt != null ||
      rpm != null ||
      rop != null;
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
  }
  return null;
}

String _text(dynamic value) => value?.toString().trim() ?? '';
