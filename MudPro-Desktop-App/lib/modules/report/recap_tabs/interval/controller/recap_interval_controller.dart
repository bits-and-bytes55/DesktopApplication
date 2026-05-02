import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/recap_daily_cost/controller/recap_daily_cost_controller.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/volume/controller/recap_volume_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapIntervalController extends GetxController {
  RecapIntervalController({
    ReportApiService? reportApi,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
    RecapDailyCostController? dailyCostController,
    RecapVolumeController? volumeController,
  }) : _reportApi = reportApi ?? ReportApiService(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext,
       _dailyCostController =
           dailyCostController ??
           (Get.isRegistered<RecapDailyCostController>()
               ? Get.find<RecapDailyCostController>()
               : Get.put(RecapDailyCostController())),
       _volumeController =
           volumeController ??
           (Get.isRegistered<RecapVolumeController>()
               ? Get.find<RecapVolumeController>()
               : Get.put(RecapVolumeController()));

  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;
  final RecapDailyCostController _dailyCostController;
  final RecapVolumeController _volumeController;

  static Map<String, String> get _headers => ApiEndpoint.jsonHeaders;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final intervalRows = <RecapIntervalRow>[].obs;
  final groupRows = <RecapIntervalGroupRow>[].obs;
  final casings = <RecapIntervalCasing>[].obs;

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
      intervalRows.clear();
      groupRows.clear();
      casings.clear();
      emptyMessage.value = 'Select a well first to open Interval recap.';
      return;
    }

    isLoading.value = true;

    try {
      final summaries = await _reportApi.fetchReportManagerRows(wellId);
      final orderedSummaries = [...summaries]..sort(_compareRowsOldestFirst);

      final masterFuture = _fetchIntervalBundle(wellId);
      final wellGeneralFuture = _fetchWellGeneralRows(wellId);
      final casingFuture = _fetchCasings(wellId);

      await Future.wait<void>([
        _safeLoadDailyCost(),
        _safeLoadVolume(),
      ]);

      final intervalBundle = await masterFuture;
      final wellGeneralRows = await wellGeneralFuture;
      final fetchedCasings = await casingFuture;

      final builtIntervalRows = _buildIntervalRows(
        summaries: orderedSummaries,
        wellGeneralRows: wellGeneralRows,
        dailyCostRows: _dailyCostController.rows.toList(growable: false),
        volumeRows: _volumeController.rows.toList(growable: false),
        intervalBundle: intervalBundle,
      );

      final normalizedRows = _normalizeDepthRanges(builtIntervalRows);
      final builtGroupRows = _buildGroupRows(
        intervalRows: normalizedRows,
        intervalBundle: intervalBundle,
      );

      intervalRows.assignAll(normalizedRows);
      groupRows.assignAll(builtGroupRows);
      casings.assignAll(fetchedCasings);

      if (orderedSummaries.isEmpty) {
        emptyMessage.value =
            'No reports are available for the selected well. Graph is shown in safe blank state.';
      } else if (!_hasAnyLiveMetric(normalizedRows)) {
        emptyMessage.value =
            'Interval data is partially missing for this well. Available graph frames are shown without locking the UI.';
      }
    } catch (error) {
      intervalRows.clear();
      groupRows.clear();
      casings.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  double get maxDepth {
    var maxValue = 0.0;
    for (final row in intervalRows) {
      maxValue = math.max(maxValue, row.endDepth);
    }
    for (final casing in casings) {
      maxValue = math.max(maxValue, casing.shoe);
    }

    if (maxValue <= 20) return 20;
    if (maxValue <= 50) return 50;
    if (maxValue <= 100) return 100;
    if (maxValue <= 250) return 250;
    if (maxValue <= 500) return 500;

    final exponent = math
        .pow(10, (math.log(maxValue) / math.ln10).floor())
        .toDouble();
    final scaled = maxValue / exponent;
    if (scaled <= 2) return 2 * exponent;
    if (scaled <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  Future<void> _safeLoadDailyCost() async {
    try {
      await _dailyCostController.load();
    } catch (_) {}
  }

  Future<void> _safeLoadVolume() async {
    try {
      await _volumeController.load();
    } catch (_) {}
  }

  Future<_IntervalBundle> _fetchIntervalBundle(String wellId) async {
    final decoded = await _getObject(path: 'intervals/$wellId');
    final data = decoded['data'];
    if (data is! List) {
      return const _IntervalBundle(
        intervals: <_IntervalMeta>[],
        groups: <_IntervalGroupMeta>[],
      );
    }

    final groupLookup = <String, _IntervalGroupMeta>{};
    final intervals = <_IntervalMeta>[];

    for (final rawItem in data.whereType<Map>()) {
      final item = Map<String, dynamic>.from(rawItem);
      if (_text(item['_type']) == 'group') {
        final group = _IntervalGroupMeta(
          id: _text(item['_id']),
          name: _text(item['name']).isNotEmpty ? _text(item['name']) : 'Group',
          order: _intValue(item['order']),
          intervalIds: (item['intervalIds'] is List)
              ? (item['intervalIds'] as List)
                    .map((entry) => _text(entry))
                    .where((entry) => entry.isNotEmpty)
                    .toList(growable: false)
              : const <String>[],
        );
        groupLookup[group.id] = group;
        continue;
      }

      intervals.add(
        _IntervalMeta(
          id: _text(item['_id']).isNotEmpty
              ? _text(item['_id'])
              : _text(item['name']),
          name: _text(item['name']).isNotEmpty
              ? _text(item['name'])
              : 'Interval',
          order: _intValue(item['order']),
          groupId: _text(item['groupId']),
        ),
      );
    }

    final groups = groupLookup.values.toList()
      ..sort((left, right) {
        final orderCompare = left.order.compareTo(right.order);
        if (orderCompare != 0) return orderCompare;
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });

    return _IntervalBundle(intervals: intervals, groups: groups);
  }

  Future<List<Map<String, dynamic>>> _fetchWellGeneralRows(String wellId) async {
    try {
      final decoded = await _getObject(path: 'well-general/$wellId');
      final data = decoded['data'];
      if (data is! List) return const <Map<String, dynamic>>[];
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<List<RecapIntervalCasing>> _fetchCasings(String wellId) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse('${baseUrl}casing/$wellId').replace(
        queryParameters: {
          if (_reportContext.selectedReportId.value.trim().isNotEmpty)
            'reportId': _reportContext.selectedReportId.value.trim(),
        },
      );

      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));
        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if (response.statusCode != 200 || decoded['success'] != true) {
          failures.add(
            '${uri.origin}: ${decoded['message'] ?? 'Failed to load casings'}',
          );
          continue;
        }

        final data = decoded['data'];
        if (data is! List) return const <RecapIntervalCasing>[];

        final fetched = data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .map(
              (item) => RecapIntervalCasing(
                label: _buildCasingLabel(item),
                top: _number(item['top']),
                shoe: _number(item['shoe']),
              ),
            )
            .where((item) => item.shoe > 0)
            .toList()
          ..sort((left, right) => left.shoe.compareTo(right.shoe));

        return fetched;
      } catch (error) {
        failures.add('${uri.origin}: ${_cleanError(error)}');
      }
    }

    return const <RecapIntervalCasing>[];
  }

  List<RecapIntervalRow> _buildIntervalRows({
    required List<ReportManagerRow> summaries,
    required List<Map<String, dynamic>> wellGeneralRows,
    required List<DailyCostHistoryRow> dailyCostRows,
    required List<VolumeHistoryRow> volumeRows,
    required _IntervalBundle intervalBundle,
  }) {
    final masterIntervals = intervalBundle.intervals.toList()
      ..sort((left, right) {
        final orderCompare = left.order.compareTo(right.order);
        if (orderCompare != 0) return orderCompare;
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });

    final metaByName = <String, _IntervalMeta>{
      for (final item in masterIntervals) _normalizeIntervalKey(item.name): item,
    };
    final groupById = <String, _IntervalGroupMeta>{
      for (final group in intervalBundle.groups) group.id: group,
    };

    final wellGeneralByReportId = _pickLatestByKey(
      wellGeneralRows,
      (item) => _text(item['reportId']),
    );
    final wellGeneralByReportNo = _pickLatestByKey(
      wellGeneralRows,
      (item) => _text(item['reportNo']),
    );
    final dailyByReportId = <String, DailyCostHistoryRow>{
      for (final row in dailyCostRows) row.reportId: row,
    };
    final volumeByReportId = <String, VolumeHistoryRow>{
      for (final row in volumeRows) row.reportId: row,
    };

    final accumulators = <String, _IntervalAccumulator>{};
    final fallbackOrder = <String, int>{};

    for (int index = 0; index < summaries.length; index++) {
      final summary = summaries[index];
      final wellGeneral =
          wellGeneralByReportId[summary.reportId] ??
          wellGeneralByReportNo[summary.reportNo];

      var intervalName = _text(wellGeneral?['interval']);
      if (intervalName.isEmpty) intervalName = summary.interval;
      if (intervalName.isEmpty && masterIntervals.length == 1) {
        intervalName = masterIntervals.first.name;
      }
      if (intervalName.isEmpty) intervalName = 'Interval ${index + 1}';

      final normalizedName = _normalizeIntervalKey(intervalName);
      final matchedMeta = metaByName[normalizedName];
      final effectiveMeta =
          matchedMeta ??
          _IntervalMeta(
            id: intervalName,
            name: intervalName,
            order: fallbackOrder.putIfAbsent(normalizedName, () => 1000 + index),
            groupId: '',
          );

      final accumulator = accumulators.putIfAbsent(
        effectiveMeta.id,
        () => _IntervalAccumulator(meta: effectiveMeta),
      );

      final groupName = _resolveGroupName(
        intervalMeta: effectiveMeta,
        groups: groupById,
      );
      accumulator.groupName = groupName;

      final resolvedMd = _positiveOrZero(
        summary.md > 0 ? summary.md : _number(wellGeneral?['md']),
      );
      if (resolvedMd > 0) {
        accumulator.depths.add(resolvedMd);
      }

      accumulator.reportCount += 1;
      accumulator.reportIds.add(summary.reportId);
      accumulator.reportLabels.add(summary.reportLabel);
      accumulator.totalCostKwd += dailyByReportId[summary.reportId]?.total ?? 0;
      accumulator.mudTreatedBbl +=
          volumeByReportId[summary.reportId]?.additionTotal ?? 0;
    }

    for (final meta in masterIntervals) {
      accumulators.putIfAbsent(meta.id, () => _IntervalAccumulator(meta: meta));
      accumulators[meta.id]!.groupName = _resolveGroupName(
        intervalMeta: meta,
        groups: groupById,
      );
    }

    final rows = accumulators.values
        .map((entry) => entry.toRow())
        .toList()
      ..sort((left, right) {
        final orderCompare = left.order.compareTo(right.order);
        if (orderCompare != 0) return orderCompare;
        return left.intervalName.toLowerCase().compareTo(
          right.intervalName.toLowerCase(),
        );
      });

    return rows;
  }

  List<RecapIntervalRow> _normalizeDepthRanges(List<RecapIntervalRow> rows) {
    final normalized = <RecapIntervalRow>[];
    var previousEnd = 0.0;

    for (final row in rows) {
      var startDepth = row.startDepth;
      var endDepth = row.endDepth;

      if (endDepth <= 0 && previousEnd > 0) {
        endDepth = previousEnd;
      }

      if (startDepth <= 0) {
        startDepth = previousEnd > 0 && previousEnd < endDepth ? previousEnd : 0;
      }

      if (endDepth <= startDepth && row.hasLiveData) {
        if (row.endDepth > startDepth) {
          endDepth = row.endDepth;
        } else if (previousEnd > 0) {
          startDepth = previousEnd;
          endDepth = math.max(previousEnd, row.endDepth);
        }
      }

      previousEnd = math.max(previousEnd, endDepth);
      normalized.add(
        row.copyWith(
          startDepth: _round2(startDepth),
          endDepth: _round2(endDepth),
        ),
      );
    }

    return normalized;
  }

  List<RecapIntervalGroupRow> _buildGroupRows({
    required List<RecapIntervalRow> intervalRows,
    required _IntervalBundle intervalBundle,
  }) {
    final grouped = <String, _IntervalGroupAccumulator>{};

    for (final group in intervalBundle.groups) {
      grouped.putIfAbsent(
        group.name,
        () => _IntervalGroupAccumulator(name: group.name, order: group.order),
      );
    }

    for (final row in intervalRows) {
      final groupName = row.groupName.isNotEmpty ? row.groupName : 'Ungrouped';
      final accumulator = grouped.putIfAbsent(
        groupName,
        () => _IntervalGroupAccumulator(
          name: groupName,
          order: 1000 + grouped.length,
        ),
      );
      accumulator.intervalCount += 1;
      accumulator.reportCount += row.reportCount;
      accumulator.totalCostKwd += row.totalCostKwd;
      accumulator.mudTreatedBbl += row.mudTreatedBbl;
      accumulator.startDepth = accumulator.startDepth == null
          ? row.startDepth
          : math.min(accumulator.startDepth!, row.startDepth);
      accumulator.endDepth = math.max(accumulator.endDepth ?? 0, row.endDepth);
    }

    final rows = grouped.values
        .map((entry) => entry.toRow())
        .where((entry) => entry.intervalCount > 0)
        .toList()
      ..sort((left, right) {
        final orderCompare = left.order.compareTo(right.order);
        if (orderCompare != 0) return orderCompare;
        return left.groupName.toLowerCase().compareTo(
          right.groupName.toLowerCase(),
        );
      });

    return rows;
  }

  bool _hasAnyLiveMetric(List<RecapIntervalRow> rows) {
    return rows.any((row) => row.hasGraphData || row.hasLiveData);
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
      'Interval recap backend routes are not available. Tried: ${failures.join(' | ')}',
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

  String _resolveGroupName({
    required _IntervalMeta intervalMeta,
    required Map<String, _IntervalGroupMeta> groups,
  }) {
    if (intervalMeta.groupId.isNotEmpty && groups.containsKey(intervalMeta.groupId)) {
      return groups[intervalMeta.groupId]!.name;
    }

    for (final group in groups.values) {
      if (group.intervalIds.contains(intervalMeta.id)) {
        return group.name;
      }
    }

    return '';
  }

  String _buildCasingLabel(Map<String, dynamic> item) {
    final odText = _text(item['od']);
    if (odText.isNotEmpty) {
      return odText.toLowerCase().contains('inch') ? odText : '$odText inch';
    }
    final description = _text(item['description']);
    return description.isNotEmpty ? description : 'Casing';
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

class RecapIntervalRow {
  final String intervalId;
  final String intervalName;
  final String groupName;
  final int order;
  final double startDepth;
  final double endDepth;
  final int reportCount;
  final double mudTreatedBbl;
  final double mudUsageBblPerFt;
  final double costKwdPerDay;
  final double costKwdPerFt;
  final double costKwdPerBbl;
  final double totalCostKwd;

  const RecapIntervalRow({
    required this.intervalId,
    required this.intervalName,
    required this.groupName,
    required this.order,
    required this.startDepth,
    required this.endDepth,
    required this.reportCount,
    required this.mudTreatedBbl,
    required this.mudUsageBblPerFt,
    required this.costKwdPerDay,
    required this.costKwdPerFt,
    required this.costKwdPerBbl,
    required this.totalCostKwd,
  });

  double get footage => math.max(0, endDepth - startDepth);

  bool get hasLiveData =>
      reportCount > 0 || mudTreatedBbl > 0 || totalCostKwd > 0 || endDepth > 0;

  bool get hasGraphData =>
      hasLiveData &&
      (mudTreatedBbl > 0 ||
          mudUsageBblPerFt > 0 ||
          costKwdPerDay > 0 ||
          costKwdPerFt > 0 ||
          costKwdPerBbl > 0 ||
          totalCostKwd > 0) &&
      endDepth >= startDepth;

  RecapIntervalRow copyWith({
    double? startDepth,
    double? endDepth,
  }) {
    return RecapIntervalRow(
      intervalId: intervalId,
      intervalName: intervalName,
      groupName: groupName,
      order: order,
      startDepth: startDepth ?? this.startDepth,
      endDepth: endDepth ?? this.endDepth,
      reportCount: reportCount,
      mudTreatedBbl: mudTreatedBbl,
      mudUsageBblPerFt: mudUsageBblPerFt,
      costKwdPerDay: costKwdPerDay,
      costKwdPerFt: costKwdPerFt,
      costKwdPerBbl: costKwdPerBbl,
      totalCostKwd: totalCostKwd,
    );
  }
}

class RecapIntervalGroupRow {
  final String groupName;
  final int order;
  final int intervalCount;
  final int reportCount;
  final double startDepth;
  final double endDepth;
  final double mudTreatedBbl;
  final double mudUsageBblPerFt;
  final double costKwdPerDay;
  final double costKwdPerFt;
  final double costKwdPerBbl;
  final double totalCostKwd;

  const RecapIntervalGroupRow({
    required this.groupName,
    required this.order,
    required this.intervalCount,
    required this.reportCount,
    required this.startDepth,
    required this.endDepth,
    required this.mudTreatedBbl,
    required this.mudUsageBblPerFt,
    required this.costKwdPerDay,
    required this.costKwdPerFt,
    required this.costKwdPerBbl,
    required this.totalCostKwd,
  });

  double get footage => math.max(0, endDepth - startDepth);

  bool get hasLiveData =>
      intervalCount > 0 || reportCount > 0 || mudTreatedBbl > 0 || totalCostKwd > 0;
}

class RecapIntervalCasing {
  final String label;
  final double top;
  final double shoe;

  const RecapIntervalCasing({
    required this.label,
    required this.top,
    required this.shoe,
  });
}

class _IntervalBundle {
  final List<_IntervalMeta> intervals;
  final List<_IntervalGroupMeta> groups;

  const _IntervalBundle({
    required this.intervals,
    required this.groups,
  });
}

class _IntervalMeta {
  final String id;
  final String name;
  final int order;
  final String groupId;

  const _IntervalMeta({
    required this.id,
    required this.name,
    required this.order,
    required this.groupId,
  });
}

class _IntervalGroupMeta {
  final String id;
  final String name;
  final int order;
  final List<String> intervalIds;

  const _IntervalGroupMeta({
    required this.id,
    required this.name,
    required this.order,
    required this.intervalIds,
  });
}

class _IntervalAccumulator {
  final _IntervalMeta meta;
  final List<double> depths = <double>[];
  final Set<String> reportIds = <String>{};
  final List<String> reportLabels = <String>[];
  String groupName = '';
  int reportCount = 0;
  double mudTreatedBbl = 0;
  double totalCostKwd = 0;

  _IntervalAccumulator({required this.meta});

  RecapIntervalRow toRow() {
    final sortedDepths = [...depths]..sort();
    final startDepth = sortedDepths.isEmpty ? 0.0 : sortedDepths.first;
    final endDepth = sortedDepths.isEmpty ? 0.0 : sortedDepths.last;
    final footage = math.max(0, endDepth - startDepth);
    final safeDays = reportCount <= 0 ? 0 : reportCount;

    return RecapIntervalRow(
      intervalId: meta.id,
      intervalName: meta.name,
      groupName: groupName,
      order: meta.order,
      startDepth: _round2(startDepth),
      endDepth: _round2(endDepth),
      reportCount: reportCount,
      mudTreatedBbl: _round2(mudTreatedBbl),
      mudUsageBblPerFt: footage > 0 ? _round2(mudTreatedBbl / footage) : 0,
      costKwdPerDay: safeDays > 0 ? _round2(totalCostKwd / safeDays) : 0,
      costKwdPerFt: footage > 0 ? _round2(totalCostKwd / footage) : 0,
      costKwdPerBbl: mudTreatedBbl > 0 ? _round2(totalCostKwd / mudTreatedBbl) : 0,
      totalCostKwd: _round2(totalCostKwd),
    );
  }
}

class _IntervalGroupAccumulator {
  final String name;
  final int order;
  int intervalCount = 0;
  int reportCount = 0;
  double? startDepth;
  double? endDepth;
  double mudTreatedBbl = 0;
  double totalCostKwd = 0;

  _IntervalGroupAccumulator({
    required this.name,
    required this.order,
  });

  RecapIntervalGroupRow toRow() {
    final safeStart = startDepth ?? 0;
    final safeEnd = endDepth ?? safeStart;
    final footage = math.max(0, safeEnd - safeStart);
    final safeDays = reportCount <= 0 ? 0 : reportCount;

    return RecapIntervalGroupRow(
      groupName: name,
      order: order,
      intervalCount: intervalCount,
      reportCount: reportCount,
      startDepth: _round2(safeStart),
      endDepth: _round2(safeEnd),
      mudTreatedBbl: _round2(mudTreatedBbl),
      mudUsageBblPerFt: footage > 0 ? _round2(mudTreatedBbl / footage) : 0,
      costKwdPerDay: safeDays > 0 ? _round2(totalCostKwd / safeDays) : 0,
      costKwdPerFt: footage > 0 ? _round2(totalCostKwd / footage) : 0,
      costKwdPerBbl: mudTreatedBbl > 0 ? _round2(totalCostKwd / mudTreatedBbl) : 0,
      totalCostKwd: _round2(totalCostKwd),
    );
  }
}

String _text(dynamic value) => value?.toString().trim() ?? '';

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_text(value)) ?? 0;
}

double _number(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(_text(value).replaceAll(',', '')) ?? 0;
}

double _positiveOrZero(double value) => value > 0 ? value : 0;

double _round2(double value) => double.parse(value.toStringAsFixed(2));

String _normalizeIntervalKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

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
