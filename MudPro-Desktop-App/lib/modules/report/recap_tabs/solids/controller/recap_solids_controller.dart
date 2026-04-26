import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapSolidsController extends GetxController {
  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapSolidsController({
    ReportApiService? reportApi,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _reportApi = reportApi ?? ReportApiService(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final rows = <SolidsHistoryRow>[].obs;

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
      emptyMessage.value = 'Select a well first to open Solids recap.';
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
      final reportRows = await Future.wait(
        ordered.map((summary) => _buildHistoryRow(wellId, summary)),
      );

      rows.assignAll(reportRows);
      if (reportRows.every((row) => !row.hasAnyData)) {
        emptyMessage.value =
            'No saved solids-analysis history is available for the selected well.';
      }
    } catch (error) {
      rows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  List<double?> correctedSolidsSeries(int sampleIndex) => rows
      .map((row) => row.sample(sampleIndex)?.correctedSolids)
      .toList(growable: false);

  List<double?> dissolvedSolidsSeries(int sampleIndex) => rows
      .map((row) => row.sample(sampleIndex)?.dissolvedSolids)
      .toList(growable: false);

  List<double?> lgsPercentSeries(int sampleIndex) => rows
      .map((row) => row.sample(sampleIndex)?.lgsPercent)
      .toList(growable: false);

  List<double?> hgsPercentSeries(int sampleIndex) => rows
      .map((row) => row.sample(sampleIndex)?.hgsPercent)
      .toList(growable: false);

  List<double?> avgSgSeries(int sampleIndex) => rows
      .map((row) => row.sample(sampleIndex)?.avgSG)
      .toList(growable: false);

  Future<SolidsHistoryRow> _buildHistoryRow(
    String wellId,
    ReportManagerRow summary,
  ) async {
    final solidsRows = await _fetchSolidsRows(wellId: wellId, reportId: summary.reportId);
    final latestBySample = <int, Map<String, dynamic>>{};

    for (final item in solidsRows) {
      final sampleIndex = _intValue(item['sampleIndex']);
      if (sampleIndex < 0 || sampleIndex > 2) continue;

      final previous = latestBySample[sampleIndex];
      final previousTime = _timestampOf(previous);
      final currentTime = _timestampOf(item);
      if (previous == null || currentTime >= previousTime) {
        latestBySample[sampleIndex] = item;
      }
    }

    return SolidsHistoryRow(
      reportId: summary.reportId,
      reportLabel: summary.reportLabel,
      reportDate: summary.reportDate,
      createdAt: summary.createdAt,
      md: summary.md,
      sample0: SolidsSampleResult.fromJson(latestBySample[0]),
      sample1: SolidsSampleResult.fromJson(latestBySample[1]),
      sample2: SolidsSampleResult.fromJson(latestBySample[2]),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchSolidsRows({
    required String wellId,
    required String reportId,
  }) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse('${baseUrl}solids').replace(
        queryParameters: {
          'wellId': wellId,
          'limit': '30',
          if (reportId.isNotEmpty) 'reportId': reportId,
        },
      );

      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 404) {
          return const <Map<String, dynamic>>[];
        }

        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if (response.statusCode != 200 || decoded['success'] != true) {
          failures.add(
            '${uri.origin}: ${decoded['message'] ?? 'Failed to load solids analysis'}',
          );
          continue;
        }

        final data = decoded['data'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
        if (data is Map) {
          return [Map<String, dynamic>.from(data)];
        }
        return const <Map<String, dynamic>>[];
      } on TimeoutException {
        failures.add('${uri.origin}: request timed out');
      } on FormatException catch (error) {
        failures.add('${uri.origin}: ${error.message}');
      } catch (error) {
        failures.add('${uri.origin}: ${_cleanError(error)}');
      }
    }

    if (failures.isNotEmpty) {
      throw Exception(
        'Solids recap backend routes are not available. '
        'Tried: ${failures.join(' | ')}',
      );
    }
    return const <Map<String, dynamic>>[];
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

  int _timestampOf(Map<String, dynamic>? item) {
    if (item == null) return 0;
    final updated = DateTime.tryParse(_text(item['updatedAt']));
    if (updated != null) return updated.millisecondsSinceEpoch;
    final created = DateTime.tryParse(_text(item['createdAt']));
    if (created != null) return created.millisecondsSinceEpoch;
    return 0;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';
}

class SolidsHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final SolidsSampleResult? sample0;
  final SolidsSampleResult? sample1;
  final SolidsSampleResult? sample2;

  const SolidsHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.sample0,
    required this.sample1,
    required this.sample2,
  });

  SolidsSampleResult? sample(int index) {
    switch (index) {
      case 0:
        return sample0;
      case 1:
        return sample1;
      case 2:
        return sample2;
      default:
        return null;
    }
  }

  bool get hasAnyData =>
      sample0?.hasData == true ||
      sample1?.hasData == true ||
      sample2?.hasData == true;
}

class SolidsSampleResult {
  final double mudWeight;
  final double retortSolids;
  final double bariteLb;
  final double bentoniteLb;
  final double brineSG;
  final double totalSolidsLb;
  final double hgsLb;
  final double hgsPercent;
  final double lgsLb;
  final double lgsPercent;
  final double dissolvedSolids;
  final double correctedSolids;
  final double bentPercent;
  final double drillSolidsLb;
  final double drillSolidsPercent;
  final double dsBentRatio;
  final double avgSG;

  const SolidsSampleResult({
    required this.mudWeight,
    required this.retortSolids,
    required this.bariteLb,
    required this.bentoniteLb,
    required this.brineSG,
    required this.totalSolidsLb,
    required this.hgsLb,
    required this.hgsPercent,
    required this.lgsLb,
    required this.lgsPercent,
    required this.dissolvedSolids,
    required this.correctedSolids,
    required this.bentPercent,
    required this.drillSolidsLb,
    required this.drillSolidsPercent,
    required this.dsBentRatio,
    required this.avgSG,
  });

  factory SolidsSampleResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SolidsSampleResult.empty();
    return SolidsSampleResult(
      mudWeight: _number(json['mudWeight']),
      retortSolids: _number(json['retortSolids']),
      bariteLb: _number(json['bariteLb']),
      bentoniteLb: _number(json['bentoniteLb']),
      brineSG: _number(json['brineSG']),
      totalSolidsLb: _number(json['totalSolidsLb']),
      hgsLb: _number(json['hgsLb']),
      hgsPercent: _number(json['hgsPercent']),
      lgsLb: _number(json['lgsLb']),
      lgsPercent: _number(json['lgsPercent']),
      dissolvedSolids: _number(json['dissolvedSolids']),
      correctedSolids: _number(json['correctedSolids']),
      bentPercent: _number(json['bentPercent']),
      drillSolidsLb: _number(json['drillSolidsLb']),
      drillSolidsPercent: _number(json['drillSolidsPercent']),
      dsBentRatio: _number(json['dsBentRatio']),
      avgSG: _number(json['avgSG']),
    );
  }

  const SolidsSampleResult.empty()
    : mudWeight = 0,
      retortSolids = 0,
      bariteLb = 0,
      bentoniteLb = 0,
      brineSG = 0,
      totalSolidsLb = 0,
      hgsLb = 0,
      hgsPercent = 0,
      lgsLb = 0,
      lgsPercent = 0,
      dissolvedSolids = 0,
      correctedSolids = 0,
      bentPercent = 0,
      drillSolidsLb = 0,
      drillSolidsPercent = 0,
      dsBentRatio = 0,
      avgSG = 0;

  bool get hasData =>
      mudWeight > 0 ||
      correctedSolids > 0 ||
      lgsPercent > 0 ||
      hgsPercent > 0 ||
      drillSolidsPercent > 0 ||
      avgSG > 0;
}

double _number(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
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
