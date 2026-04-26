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

class RecapSurveyController extends GetxController {
  RecapSurveyController({
    ReportApiService? reportApi,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _reportApi = reportApi ?? ReportApiService(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final rows = <SurveyHistoryRow>[].obs;

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

  String get wellName {
    final value = _padWellController.selectedWellName.trim();
    return value.isEmpty ? 'Selected well' : value;
  }

  Future<void> load() async {
    final wellId = currentBackendWellId.trim();
    errorMessage.value = '';
    emptyMessage.value = '';

    if (wellId.isEmpty) {
      rows.clear();
      emptyMessage.value = 'Select a well first to open Survey recap.';
      return;
    }

    isLoading.value = true;

    try {
      final summariesFuture = _reportApi.fetchReportManagerRows(wellId);
      final wellGeneralFuture = _fetchWellGeneralRows(wellId);

      final summaries = await summariesFuture;
      final wellGeneralRows = await wellGeneralFuture;

      final builtRows = _buildRows(
        summaries: summaries,
        wellGeneralRows: wellGeneralRows,
      );

      rows.assignAll(builtRows);

      if (builtRows.isEmpty) {
        emptyMessage.value =
            'No saved survey history is available for the selected well. Graph stays in safe blank state.';
      } else if (!builtRows.any((row) => row.hasAnySurveyData)) {
        emptyMessage.value =
            'Survey rows are present, but plotted values are missing. Blank-safe graph is shown.';
      }
    } catch (error) {
      rows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWellGeneralRows(String wellId) async {
    final decoded = await _getObject(path: 'well-general/$wellId');
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<SurveyHistoryRow> _buildRows({
    required List<ReportManagerRow> summaries,
    required List<Map<String, dynamic>> wellGeneralRows,
  }) {
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
    final byDate = _pickLatestByKey(
      wellGeneralRows,
      (row) => _text(row['date']),
    );

    final reportRows = <SurveyHistoryRow>[];

    if (summaries.isNotEmpty) {
      final orderedSummaries = [...summaries]..sort(_compareRowsOldestFirst);
      for (final summary in orderedSummaries) {
        final matched =
            byReportId[summary.reportId] ??
            byUserReportNo[summary.userReportNo] ??
            byReportNo[summary.reportNo] ??
            byDate[summary.reportDate];

        reportRows.add(
          SurveyHistoryRow.raw(
            reportId: summary.reportId,
            reportLabel: summary.reportLabel,
            reportDate: summary.reportDate,
            createdAt: summary.createdAt,
            md: _number(matched?['md'], fallback: summary.md),
            tvd: _number(matched?['tvd']),
            inc: _number(matched?['inc']),
            azi: _number(matched?['azi']),
          ),
        );
      }
    } else {
      final orderedWellGeneral = [...wellGeneralRows]..sort((left, right) {
        final leftTime = _timestampOf(left);
        final rightTime = _timestampOf(right);
        return leftTime.compareTo(rightTime);
      });

      for (final item in orderedWellGeneral) {
        reportRows.add(
          SurveyHistoryRow.raw(
            reportId: _text(item['reportId']),
            reportLabel: _reportLabelFromWellGeneral(item),
            reportDate: _text(item['date']),
            createdAt: _text(item['createdAt']),
            md: _number(item['md']),
            tvd: _number(item['tvd']),
            inc: _number(item['inc']),
            azi: _number(item['azi']),
          ),
        );
      }
    }

    final usable = reportRows
        .where((row) => row.hasAnySurveyData)
        .toList(growable: false);

    if (usable.isEmpty) {
      return reportRows;
    }

    final orderedByDepth = [...usable]..sort((left, right) {
      final depthCompare = left.md.compareTo(right.md);
      if (depthCompare != 0) return depthCompare;
      return _parseDate(left.reportDate)?.compareTo(_parseDate(right.reportDate) ?? DateTime(1970)) ?? 0;
    });

    final enriched = <SurveyHistoryRow>[];
    SurveyHistoryRow? previous;
    var northing = 0.0;
    var easting = 0.0;

    for (final row in orderedByDepth) {
      if (previous == null) {
        final originTvd = row.tvd > 0 ? row.tvd : 0.0;
        enriched.add(
          row.copyWith(
            tvd: _round2(originTvd),
            northSouth: 0,
            eastWest: 0,
            horizontalDisplacement: 0,
            doglegSeverity: 0,
          ),
        );
        previous = enriched.last;
        continue;
      }

      final deltaMd = math.max(0.0, row.md - previous.md).toDouble();
      final prevInc = _toRadians(previous.inc);
      final currInc = _toRadians(row.inc);
      final prevAzi = _toRadians(previous.azi);
      final currAzi = _toRadians(row.azi);

      final avgInc = (prevInc + currInc) / 2;
      final avgAzi = (prevAzi + currAzi) / 2;

      if (deltaMd > 0) {
        northing += deltaMd * math.sin(avgInc) * math.cos(avgAzi);
        easting += deltaMd * math.sin(avgInc) * math.sin(avgAzi);
      }

      final computedTvd = previous.tvd > 0
          ? previous.tvd + (deltaMd * math.cos(avgInc))
          : deltaMd * math.cos(avgInc);
      final tvd = row.tvd > 0 ? row.tvd : _round2(computedTvd);
      final hd = math.sqrt((northing * northing) + (easting * easting));
      final dogleg = _doglegSeverity(
        deltaMd: deltaMd,
        inc1: prevInc,
        inc2: currInc,
        azi1: prevAzi,
        azi2: currAzi,
      );

      enriched.add(
        row.copyWith(
          tvd: _round2(tvd),
          northSouth: _round2(northing),
          eastWest: _round2(easting),
          horizontalDisplacement: _round2(hd),
          doglegSeverity: _round2(dogleg),
        ),
      );
      previous = enriched.last;
    }

    return enriched;
  }

  Map<String, Map<String, dynamic>> _pickLatestByKey(
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic> item) keySelector,
  ) {
    final ordered = [...items]..sort((left, right) {
      final leftTime = _timestampOf(left);
      final rightTime = _timestampOf(right);
      return rightTime.compareTo(leftTime);
    });

    final latest = <String, Map<String, dynamic>>{};
    for (final item in ordered) {
      final key = keySelector(item).trim();
      if (key.isEmpty || latest.containsKey(key)) continue;
      latest[key] = item;
    }
    return latest;
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
      'Survey recap backend routes are not available. Tried: ${failures.join(' | ')}',
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
    final isJson = (contentType ?? '').toLowerCase().contains(
      'application/json',
    );
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

  String _reportLabelFromWellGeneral(Map<String, dynamic> item) {
    final userReportNo = _text(item['userReportNo']);
    if (userReportNo.isNotEmpty) return userReportNo;
    final reportNo = _text(item['reportNo']);
    if (reportNo.isNotEmpty) return reportNo;
    return '-';
  }

  double _doglegSeverity({
    required double deltaMd,
    required double inc1,
    required double inc2,
    required double azi1,
    required double azi2,
  }) {
    if (deltaMd <= 0) return 0;

    final cosine =
        (math.cos(inc1) * math.cos(inc2)) +
        (math.sin(inc1) * math.sin(inc2) * math.cos(azi2 - azi1));
    final clampedCosine = cosine.clamp(-1.0, 1.0).toDouble();
    final angle = math.acos(clampedCosine);
    if (angle.isNaN) return 0;
    return (angle * 180 / math.pi) * 100 / deltaMd;
  }

  int _timestampOf(Map<String, dynamic> row) {
    final updated = _parseDate(_text(row['updatedAt']));
    if (updated != null) return updated.millisecondsSinceEpoch;
    final created = _parseDate(_text(row['createdAt']));
    if (created != null) return created.millisecondsSinceEpoch;
    final dated = _parseDate(_text(row['date']));
    if (dated != null) return dated.millisecondsSinceEpoch;
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

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

class SurveyHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final double tvd;
  final double inc;
  final double azi;
  final double northSouth;
  final double eastWest;
  final double horizontalDisplacement;
  final double doglegSeverity;

  const SurveyHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.tvd,
    required this.inc,
    required this.azi,
    required this.northSouth,
    required this.eastWest,
    required this.horizontalDisplacement,
    required this.doglegSeverity,
  });

  factory SurveyHistoryRow.raw({
    required String reportId,
    required String reportLabel,
    required String reportDate,
    required String createdAt,
    required double md,
    required double tvd,
    required double inc,
    required double azi,
  }) {
    return SurveyHistoryRow(
      reportId: reportId,
      reportLabel: reportLabel,
      reportDate: reportDate,
      createdAt: createdAt,
      md: md,
      tvd: tvd,
      inc: inc,
      azi: azi,
      northSouth: 0,
      eastWest: 0,
      horizontalDisplacement: 0,
      doglegSeverity: 0,
    );
  }

  bool get hasAnySurveyData => md > 0 || tvd > 0 || inc > 0 || azi > 0;

  SurveyHistoryRow copyWith({
    double? tvd,
    double? northSouth,
    double? eastWest,
    double? horizontalDisplacement,
    double? doglegSeverity,
  }) {
    return SurveyHistoryRow(
      reportId: reportId,
      reportLabel: reportLabel,
      reportDate: reportDate,
      createdAt: createdAt,
      md: md,
      tvd: tvd ?? this.tvd,
      inc: inc,
      azi: azi,
      northSouth: northSouth ?? this.northSouth,
      eastWest: eastWest ?? this.eastWest,
      horizontalDisplacement:
          horizontalDisplacement ?? this.horizontalDisplacement,
      doglegSeverity: doglegSeverity ?? this.doglegSeverity,
    );
  }
}

String _text(dynamic value) => value?.toString().trim() ?? '';

double _number(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? fallback;
}

double _round2(double value) => double.parse(value.toStringAsFixed(2));

double _toRadians(double value) => value * math.pi / 180;

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
