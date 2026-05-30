import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapBitController extends GetxController {
  RecapBitController({
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
  final rows = <RecapBitHistoryRow>[].obs;

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
      emptyMessage.value = 'Select a well first to open Bit recap.';
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
      final intervals = await _fetchIntervals(wellId);
      final casings = await _fetchCasings(wellId);
      final nozzleRows = await Future.wait(
        ordered.map((summary) => _fetchNozzleRow(wellId, summary.reportId)),
      );

      final wellGeneralByReportId = _pickLatestByKey(
        wellGeneralRows,
        (item) => _text(item['reportId']),
      );
      final wellGeneralByReportNo = _pickLatestByKey(
        wellGeneralRows,
        (item) => _text(item['reportNo']),
      );

      final built = <RecapBitHistoryRow>[];

      for (int index = 0; index < ordered.length; index++) {
        final summary = ordered[index];
        final wellGeneral =
            wellGeneralByReportId[summary.reportId] ??
            wellGeneralByReportNo[summary.reportNo];
        final nozzle = nozzleRows[index];

        final intervalName = _text(wellGeneral?['interval']).isNotEmpty
            ? _text(wellGeneral?['interval'])
            : summary.interval;
        final bitSizeText = _resolveBitSizeText(
          intervals: intervals,
          casings: casings,
          intervalName: intervalName,
        );
        final bitSizeIn = _positiveOrNull(_parseFraction(bitSizeText));
        final bitSizeMm = bitSizeIn == null
            ? null
            : double.parse((bitSizeIn * 25.4).toStringAsFixed(2));

        final md = _positiveOrNull(
          summary.md > 0 ? summary.md : _number(wellGeneral?['md']),
        );
        final depthDrilled = _positiveOrNull(
          _number(wellGeneral?['depthDrilled']),
        );
        final depthInFt = md != null && depthDrilled != null
            ? _positiveOrNull(math.max(0, md - depthDrilled))
            : null;

        built.add(
          RecapBitHistoryRow(
            dayNumber: index + 1,
            reportId: summary.reportId,
            reportLabel: summary.reportLabel,
            reportDate: summary.reportDate,
            createdAt: summary.createdAt,
            manufacturer: _text(nozzle['bitModel']),
            bitType: _text(nozzle['bitType']),
            bitSizeText: bitSizeText,
            bitSizeMm: bitSizeMm,
            tfa: _positiveOrNull(_number(nozzle['tfa'])),
            depthInFt: depthInFt,
            depthFt: md,
            bitNumber: null,
          ),
        );
      }

      rows.assignAll(_assignBitNumbers(built));
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

  Future<List<Map<String, dynamic>>> _fetchIntervals(String wellId) async {
    final decoded = await _getObject(path: 'intervals/$wellId');
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => _text(item['_type']) != 'group')
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetchCasings(String wellId) async {
    final decoded = await _getObject(path: 'casing/$wellId');
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _fetchNozzleRow(
    String wellId,
    String reportId,
  ) async {
    if (reportId.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      final decoded = await _getObject(
        path: 'nozzle',
        queryParameters: {'wellId': wellId, 'reportId': reportId},
      );
      final data = decoded['data'];
      if (data is! List || data.isEmpty) return const <String, dynamic>{};
      final first = data.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
      return const <String, dynamic>{};
    } catch (_) {
      return const <String, dynamic>{};
    }
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
            .timeout(const Duration(seconds: 15));
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
      'Bit recap backend routes are not available. Tried: ${failures.join(' | ')}',
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

  Map<String, Map<String, dynamic>> _pickLatestByKey(
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic> item) keySelector,
  ) {
    final latest = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final key = keySelector(item).trim();
      if (key.isEmpty || latest.containsKey(key)) continue;
      latest[key] = item;
    }
    return latest;
  }

  List<RecapBitHistoryRow> _assignBitNumbers(List<RecapBitHistoryRow> source) {
    final assigned = <RecapBitHistoryRow>[];
    int currentBitNumber = 0;
    String lastSignature = '';
    double? lastDepthIn;

    for (final row in source) {
      if (!row.hasAnyData) {
        assigned.add(row);
        continue;
      }

      final signature = [
        row.manufacturer,
        row.bitType,
        row.bitSizeText,
      ].where((item) => item.trim().isNotEmpty).join('|');

      final depthReset =
          row.depthInFt != null &&
          lastDepthIn != null &&
          row.depthInFt! + 0.01 < lastDepthIn;

      if (currentBitNumber == 0) {
        currentBitNumber = 1;
      } else if (signature.isNotEmpty && signature != lastSignature) {
        currentBitNumber += 1;
      } else if (depthReset) {
        currentBitNumber += 1;
      }

      if (signature.isNotEmpty) {
        lastSignature = signature;
      }
      if (row.depthInFt != null) {
        lastDepthIn = row.depthInFt;
      }

      assigned.add(row.copyWith(bitNumber: currentBitNumber.toDouble()));
    }

    return assigned;
  }

  String _resolveBitSizeText({
    required List<Map<String, dynamic>> intervals,
    required List<Map<String, dynamic>> casings,
    required String intervalName,
  }) {
    final intervalBitSize = _resolveIntervalBitSizeText(
      intervals,
      intervalName,
    );
    if (intervalBitSize.isNotEmpty) return intervalBitSize;

    final firstCasingWithBit = casings.firstWhereOrNull(
      (item) => _text(item['bit']).isNotEmpty,
    );
    return _text(firstCasingWithBit?['bit']);
  }

  String _resolveIntervalBitSizeText(
    List<Map<String, dynamic>> intervals,
    String intervalName,
  ) {
    if (intervals.isEmpty) return '';

    final normalizedTarget = _normalizeIntervalKey(intervalName);
    if (normalizedTarget.isNotEmpty) {
      final exact = intervals.firstWhereOrNull(
        (interval) =>
            _normalizeIntervalKey(_text(interval['name'])) == normalizedTarget,
      );
      final exactBitSize = _text(exact?['bitSize']);
      if (exactBitSize.isNotEmpty) return exactBitSize;
    }

    final firstWithBitSize = intervals.firstWhereOrNull(
      (interval) => _text(interval['bitSize']).isNotEmpty,
    );
    return _text(firstWithBitSize?['bitSize']);
  }
}

class RecapBitHistoryRow {
  final int dayNumber;
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final String manufacturer;
  final String bitType;
  final String bitSizeText;
  final double? bitSizeMm;
  final double? tfa;
  final double? depthInFt;
  final double? depthFt;
  final double? bitNumber;

  const RecapBitHistoryRow({
    required this.dayNumber,
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.manufacturer,
    required this.bitType,
    required this.bitSizeText,
    required this.bitSizeMm,
    required this.tfa,
    required this.depthInFt,
    required this.depthFt,
    required this.bitNumber,
  });

  bool get hasAnyData =>
      manufacturer.isNotEmpty ||
      bitType.isNotEmpty ||
      bitSizeText.isNotEmpty ||
      bitSizeMm != null ||
      tfa != null ||
      depthInFt != null ||
      depthFt != null;

  RecapBitHistoryRow copyWith({double? bitNumber}) {
    return RecapBitHistoryRow(
      dayNumber: dayNumber,
      reportId: reportId,
      reportLabel: reportLabel,
      reportDate: reportDate,
      createdAt: createdAt,
      manufacturer: manufacturer,
      bitType: bitType,
      bitSizeText: bitSizeText,
      bitSizeMm: bitSizeMm,
      tfa: tfa,
      depthInFt: depthInFt,
      depthFt: depthFt,
      bitNumber: bitNumber ?? this.bitNumber,
    );
  }
}

String _text(dynamic value) => value?.toString().trim() ?? '';

double _number(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0.0;
}

double? _positiveOrNull(double value) {
  if (value <= 0) return null;
  return double.parse(value.toStringAsFixed(2));
}

String _normalizeIntervalKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

double _parseFraction(String input) {
  final cleaned = input
      .replaceAll('"', '')
      .replaceAll("'", '')
      .replaceAll('-', ' ')
      .trim();
  if (cleaned.isEmpty) return 0;

  final direct = double.tryParse(cleaned);
  if (direct != null) return direct;

  final parts = cleaned.split(RegExp(r'\s+'));
  if (parts.length == 2 && parts[1].contains('/')) {
    final whole = double.tryParse(parts[0]) ?? 0;
    return whole + _parseSimpleFraction(parts[1]);
  }
  if (parts.length == 1 && parts[0].contains('/')) {
    return _parseSimpleFraction(parts[0]);
  }
  return 0;
}

double _parseSimpleFraction(String value) {
  final pieces = value.split('/');
  if (pieces.length != 2) return 0;
  final numerator = double.tryParse(pieces[0]) ?? 0;
  final denominator = double.tryParse(pieces[1]) ?? 0;
  if (denominator == 0) return 0;
  return numerator / denominator;
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
