import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapHydraulicsController extends GetxController {
  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapHydraulicsController({
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
  final rows = <HydraulicsHistoryRow>[].obs;

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
      emptyMessage.value = 'Select a well first to open Hydraulics recap.';
      return;
    }

    isLoading.value = true;

    try {
      final results = await Future.wait<dynamic>([
        _reportApi.fetchReportManagerRows(wellId),
        _fetchReports(wellId),
        _fetchWellGeneralRows(wellId),
        _fetchIntervals(wellId),
        _fetchCasings(wellId),
      ]);

      final summaries = results[0] as List<ReportManagerRow>;
      final reports = results[1] as List<Map<String, dynamic>>;
      final wellGeneralRows = results[2] as List<Map<String, dynamic>>;
      final intervals = results[3] as List<Map<String, dynamic>>;
      final casings = results[4] as List<Map<String, dynamic>>;

      if (summaries.isEmpty) {
        rows.clear();
        emptyMessage.value = 'No reports are available for the selected well.';
        return;
      }

      final ordered = [...summaries]..sort(_compareRowsOldestFirst);
      final reportsById = <String, Map<String, dynamic>>{
        for (final report in reports)
          _text(report['_id']).isNotEmpty
              ? _text(report['_id'])
              : _text(report['id']): report,
      };

      final wellGeneralByReportId = _pickLatestByKey(
        wellGeneralRows,
        (row) => _text(row['reportId']),
      );
      final wellGeneralByReportNo = _pickLatestByKey(
        wellGeneralRows,
        (row) => _text(row['reportNo']),
      );
      final wellGeneralByUserReportNo = _pickLatestByKey(
        wellGeneralRows,
        (row) => _text(row['userReportNo']),
      );
      final formationReference = _buildFormationReference();

      final history = await Future.wait(
        ordered.map((summary) {
          final report = reportsById[summary.reportId] ?? const <String, dynamic>{};
          final matchedWellGeneral =
              wellGeneralByReportId[summary.reportId] ??
              wellGeneralByReportNo[summary.reportNo] ??
              wellGeneralByUserReportNo[summary.userReportNo] ??
              _matchWellGeneralByDate(wellGeneralRows, summary);

          return _buildHistoryRow(
            wellId: wellId,
            summary: summary,
            report: report,
            wellGeneral: matchedWellGeneral,
            intervals: intervals,
            casings: casings,
            formationReference: formationReference,
          );
        }),
      );

      rows.assignAll(history);
      if (history.isEmpty) {
        emptyMessage.value = 'No hydraulics history is available yet.';
      }
    } catch (error) {
      rows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  List<double?> get flowRateSeries =>
      rows.map((row) => row.flowRateGpm).toList(growable: false);

  List<double?> get pumpPressureSeries =>
      rows.map((row) => row.pumpPressurePsi).toList(growable: false);

  List<double?> get impactForceSeries =>
      rows.map((row) => row.impactForceLbf).toList(growable: false);

  List<double?> get hsiSeries =>
      rows.map((row) => row.hsi).toList(growable: false);

  List<double?> get bhEcdSeries =>
      rows.map((row) => row.bhEcdPpg).toList(growable: false);

  List<double?> get poreSeries =>
      rows.map((row) => row.porePpg).toList(growable: false);

  List<double?> get fracSeries =>
      rows.map((row) => row.fracPpg).toList(growable: false);

  Future<HydraulicsHistoryRow> _buildHistoryRow({
    required String wellId,
    required ReportManagerRow summary,
    required Map<String, dynamic> report,
    required Map<String, dynamic>? wellGeneral,
    required List<Map<String, dynamic>> intervals,
    required List<Map<String, dynamic>> casings,
    required _HydraulicsFormationReference formationReference,
  }) async {
    final results = await Future.wait<dynamic>([
      _fetchList(
        path: 'pump',
        queryParameters: {
          'wellId': wellId,
          if (summary.reportId.isNotEmpty) 'reportId': summary.reportId,
        },
      ),
      _fetchList(
        path: 'drill-string',
        queryParameters: {
          'wellId': wellId,
          if (summary.reportId.isNotEmpty) 'reportId': summary.reportId,
        },
      ),
      _fetchList(
        path: 'pit/well/$wellId/selected',
        queryParameters: {
          if (summary.reportId.isNotEmpty) 'reportId': summary.reportId,
        },
      ),
      _fetchNozzle(
        wellId: wellId,
        reportId: summary.reportId,
      ),
      _fetchMudReportState(wellId, summary.reportId),
    ]);

    final pumps = results[0] as List<Map<String, dynamic>>;
    final drillStrings = results[1] as List<Map<String, dynamic>>;
    final activePits = results[2] as List<Map<String, dynamic>>;
    final nozzle = results[3] as Map<String, dynamic>;
    final mudReportState = results[4] as Map<String, dynamic>;

    final pumpRateAndPressure = _mapFromDynamic(report['pumpRateAndPressure']);
    final mud = _loadMudHydraulicValues(
      mudReportState: mudReportState,
      activePits: activePits,
    );
    final pumpFlow = _summarizePumpFlow(pumps);
    final pumpRate = _positiveOrNull(
      _firstHydraulicNumber([
        pumpRateAndPressure['pumpRate'],
        pumpFlow.rateGpm,
      ]),
    );
    final totalPressureLoss = _positiveOrNull(
      _firstHydraulicNumber([
        pumpRateAndPressure['pumpPressure'],
        pumpFlow.maxPumpP,
      ]),
    );
    final dhToolsLoss = _positiveOrNull(
      _firstHydraulicNumber([pumpRateAndPressure['dhToolsPressureLoss']]),
    );
    final motorLoss = _positiveOrNull(
      _firstHydraulicNumber([pumpRateAndPressure['motorPressureLoss']]),
    );
    final segments = _buildHydraulicSegments(
      drillStrings: drillStrings,
      casings: casings,
      intervals: intervals,
      intervalName: _text(wellGeneral?['interval']).isNotEmpty
          ? _text(wellGeneral?['interval'])
          : summary.interval,
    );

    final remainingPressure = math.max(
      0,
      (totalPressureLoss ?? 0) - (dhToolsLoss ?? 0) - (motorLoss ?? 0),
    );
    final bitLoss = _positiveOrNull(remainingPressure > 0 ? remainingPressure * 0.65 : 0);
    final dsLossTotal = _positiveOrNull(
      remainingPressure > 0 ? remainingPressure * 0.25 : 0,
    );
    final annLossTotal = _positiveOrNull(
      remainingPressure > 0 ? remainingPressure * 0.10 : 0,
    );
    final tfa = _positiveOrNull(_nozzleTotalArea(nozzle));
    final bitSize = _positiveOrNull(
      _firstHydraulicNumber([
        _resolveIntervalBitSize(
          intervals,
          _text(wellGeneral?['interval']).isNotEmpty
              ? _text(wellGeneral?['interval'])
              : summary.interval,
        ),
        for (final casing in casings) casing['bit'],
        for (final casing in casings) casing['od'],
        for (final casing in casings) casing['id'],
      ]),
    );
    final bitArea = bitSize != null && bitSize > 0
        ? 0.785 * bitSize * bitSize
        : 0.0;
    final nozzleVelocity = _positiveOrNull(
      pumpRate != null && pumpRate > 0 && tfa != null && tfa > 0
          ? (0.408 * pumpRate) / tfa
          : 0,
    );
    final bitHhp = _positiveOrNull(
      bitLoss != null && bitLoss > 0 && pumpRate != null && pumpRate > 0
          ? (bitLoss * pumpRate) / 1714
          : 0,
    );
    final hsi = _positiveOrNull(
      bitHhp != null && bitHhp > 0 && bitArea > 0 ? bitHhp / bitArea : 0,
    );
    final impactForce = _positiveOrNull(
      mud.mw != null &&
              mud.mw! > 0 &&
              pumpRate != null &&
              pumpRate > 0 &&
              nozzleVelocity != null &&
              nozzleVelocity > 0
          ? 0.01823 * mud.mw! * pumpRate * nozzleVelocity
          : 0,
    );
    final tdDepth = _positiveOrNull(
      _firstHydraulicNumber([
        wellGeneral?['tvd'],
        wellGeneral?['md'],
        wellGeneral?['depthDrilled'],
        summary.md,
      ]),
    );
    final bhEcd = _calculateEcd(
      mud.mw,
      annLossTotal,
      tdDepth,
    );

    return HydraulicsHistoryRow(
      reportId: summary.reportId,
      reportLabel: summary.reportLabel,
      reportDate: summary.reportDate,
      createdAt: summary.createdAt,
      md: tdDepth ?? summary.md,
      interval: _text(wellGeneral?['interval']).isNotEmpty
          ? _text(wellGeneral?['interval'])
          : summary.interval,
      activity: _text(wellGeneral?['activity']).isNotEmpty
          ? _text(wellGeneral?['activity'])
          : summary.activity,
      flowRateGpm: pumpRate,
      pumpPressurePsi: totalPressureLoss,
      impactForceLbf: impactForce,
      hsi: hsi,
      bhEcdPpg: bhEcd,
      porePpg: formationReference.porePpg,
      fracPpg: formationReference.fracPpg,
      mudWeightPpg: mud.mw,
      pv: mud.pv,
      yp: mud.yp,
      dhToolsPressureLossPsi: dhToolsLoss,
      motorPressureLossPsi: motorLoss,
      bitPressureLossPsi: bitLoss,
      drillStringPressureLossPsi: dsLossTotal,
      annularPressureLossPsi: annLossTotal,
      nozzleAreaIn2: tfa,
      nozzleVelocityFtSec: nozzleVelocity,
      segmentCount: segments.length,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchReports(String wellId) async {
    final decoded = await _getObject(
      path: 'reports',
      queryParameters: {'wellId': wellId},
    );
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

  Future<List<Map<String, dynamic>>> _fetchIntervals(String wellId) async {
    final decoded = await _getObject(path: 'intervals/$wellId');
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchCasings(String wellId) async {
    final decoded = await _getObject(path: 'casing/$wellId');
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];

    final items = data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final deduped = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final key = [
        _text(item['description']),
        _text(item['type']),
        _text(item['top']),
        _text(item['shoe']),
      ].join('|').toLowerCase();
      if (key.isEmpty) continue;
      deduped[key] = item;
    }

    final rows = deduped.values.toList();
    rows.sort((left, right) {
      final compare = _number(left['top']).compareTo(_number(right['top']));
      if (compare != 0) return compare;
      return _number(left['shoe']).compareTo(_number(right['shoe']));
    });
    return rows;
  }

  Future<List<Map<String, dynamic>>> _fetchList({
    required String path,
    Map<String, String>? queryParameters,
  }) async {
    final decoded = await _getObject(
      path: path,
      queryParameters: queryParameters,
    );
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> _fetchNozzle({
    required String wellId,
    required String reportId,
  }) async {
    final list = await _fetchList(
      path: 'nozzle',
      queryParameters: {
        'wellId': wellId,
        if (reportId.isNotEmpty) 'reportId': reportId,
      },
    );
    return list.isNotEmpty ? list.first : const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _fetchMudReportState(
    String wellId,
    String reportId,
  ) async {
    final decoded = await _getObject(
      path: 'mud-report/$wellId',
      queryParameters: reportId.isEmpty ? null : {'reportId': reportId},
    );
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const <String, dynamic>{};
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
      'Hydraulics recap backend routes are not available. '
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

  _HydraulicsFormationReference _buildFormationReference() {
    if (!Get.isRegistered<UgController>()) {
      return const _HydraulicsFormationReference();
    }

    final controller = Get.find<UgController>();
    double? pore;
    double? frac;
    var deepestTvd = -1.0;

    for (final row in controller.formations) {
      final tvd = _number(row.tvd.value);
      final rowPore = _positiveOrNull(_number(row.porePpg.value));
      final rowFrac = _positiveOrNull(_number(row.fracPpg.value));
      if (rowPore == null && rowFrac == null) continue;

      if (tvd >= deepestTvd) {
        deepestTvd = tvd;
        pore = rowPore ?? pore;
        frac = rowFrac ?? frac;
      }
    }

    return _HydraulicsFormationReference(
      porePpg: pore,
      fracPpg: frac,
    );
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

  Map<String, dynamic>? _matchWellGeneralByDate(
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

  _HydraulicsMudValues _loadMudHydraulicValues({
    required Map<String, dynamic> mudReportState,
    required List<Map<String, dynamic>> activePits,
  }) {
    final propertyTable = _mapFromDynamic(mudReportState['propertyTable']);
    final mwRow = _findMudRow(
      propertyTable,
      (key) => key == 'mw' || key.startsWith('mw ') || key.contains('mud weight'),
    );
    final pvRow = _findMudRow(
      propertyTable,
      (key) => (key == 'pv' || key.startsWith('pv ')) && !key.contains('for'),
    );
    final ypRow = _findMudRow(
      propertyTable,
      (key) => key == 'yp' || key.startsWith('yp '),
    );

    return _HydraulicsMudValues(
      mw: _positiveOrNull(
        _firstHydraulicNumber([
          _mudRowNumber(mwRow),
          if (activePits.isNotEmpty) activePits[0]['density'],
          if (activePits.length > 1) activePits[1]['density'],
        ]),
      ),
      pv: _positiveOrNull(_mudRowNumber(pvRow)),
      yp: _positiveOrNull(_mudRowNumber(ypRow)),
    );
  }

  List<dynamic> _findMudRow(
    Map<String, dynamic> propertyTable,
    bool Function(String key) matches,
  ) {
    for (final entry in propertyTable.entries) {
      if (matches(_normalizeKey(entry.key))) {
        return _listFromDynamic(entry.value);
      }
    }
    return const <dynamic>[];
  }

  _HydraulicsPumpFlowSummary _summarizePumpFlow(List<Map<String, dynamic>> pumps) {
    final activePumps = pumps.where((pump) => _number(pump['spm']) > 0).toList();
    final sourcePumps = activePumps.isNotEmpty ? activePumps : pumps;

    var displacementBblPerStroke = 0.0;
    var rateGpm = 0.0;
    var spm = 0.0;
    var maxPumpP = 0.0;

    for (final pump in sourcePumps) {
      final displacement = _getPumpDisplacement(pump);
      final strokesPerMinute = _number(pump['spm']);
      final rate = _getPumpRateGpm(pump);
      final pumpPressure = _number(pump['maxPumpP']);

      displacementBblPerStroke += strokesPerMinute > 0 ? displacement : 0;
      rateGpm += rate;
      spm += strokesPerMinute;
      maxPumpP = math.max(maxPumpP, pumpPressure);
    }

    return _HydraulicsPumpFlowSummary(
      displacementBblPerStroke: displacementBblPerStroke,
      rateGpm: rateGpm,
      spm: spm,
      maxPumpP: maxPumpP,
    );
  }

  double _calculatePumpDisplacement(Map<String, dynamic> pump) {
    final linerId = _number(pump['linerId']);
    final strokeLength = _number(pump['strokeLength']);
    final efficiency = _number(pump['efficiency']) / 100;
    final rodOd = _number(pump['rodOd']);

    if (linerId <= 0 || strokeLength <= 0 || efficiency <= 0) {
      return 0;
    }

    if (_text(pump['type']) == 'Duplex') {
      return rodOd > 0
          ? 0.000162 *
                (2 * linerId * linerId - rodOd * rodOd) *
                strokeLength *
                efficiency
          : 0.000324 * linerId * linerId * strokeLength * efficiency;
    }

    final constants = <String, double>{
      'Triplex': 0.000243,
      'Quadplex': 0.000324,
      'Quintuplex': 0.000405,
    };
    final constant = constants[_text(pump['type'])] ?? 0;
    return constant > 0
        ? constant * linerId * linerId * strokeLength * efficiency
        : 0;
  }

  double _getPumpDisplacement(Map<String, dynamic> pump) {
    final saved = _number(pump['displacement']);
    return saved > 0 ? saved : _calculatePumpDisplacement(pump);
  }

  double _getPumpRateGpm(Map<String, dynamic> pump) {
    final saved = _number(pump['rate']);
    if (saved > 0) return saved;

    final displacement = _getPumpDisplacement(pump);
    final spm = _number(pump['spm']);
    return displacement > 0 && spm > 0 ? displacement * spm * 42 : 0;
  }

  List<_HydraulicsSegment> _buildHydraulicSegments({
    required List<Map<String, dynamic>> drillStrings,
    required List<Map<String, dynamic>> casings,
    required List<Map<String, dynamic>> intervals,
    required String intervalName,
  }) {
    final intervalBitSize = _resolveIntervalBitSize(intervals, intervalName);
    final firstCasingWithSize = casings.firstWhereOrNull(
      (item) =>
          _firstHydraulicNumber([item['bit'], item['od'], item['id']]) > 0,
    );
    final holeSize = _firstHydraulicNumber([
      intervalBitSize,
      firstCasingWithSize?['bit'],
      firstCasingWithSize?['od'],
      firstCasingWithSize?['id'],
    ]);

    return drillStrings
        .where(
          (item) =>
              _firstHydraulicNumber([item['od']]) > 0 &&
              _firstHydraulicNumber([item['id']]) > 0 &&
              _firstHydraulicNumber([item['length']]) > 0,
        )
        .take(5)
        .map(
          (item) => _HydraulicsSegment(
            holeSize: holeSize,
            pipeOd: _firstHydraulicNumber([item['od']]),
            pipeId: _firstHydraulicNumber([item['id']]),
            length: _firstHydraulicNumber([item['length']]),
          ),
        )
        .toList();
  }

  double _resolveIntervalBitSize(
    List<Map<String, dynamic>> intervals,
    String intervalName,
  ) {
    final normalizedInterval = _normalizeKey(intervalName);
    if (normalizedInterval.isNotEmpty) {
      for (final interval in intervals) {
        if (_normalizeKey(interval['name']) == normalizedInterval) {
          final matched = _firstHydraulicNumber([interval['bitSize']]);
          if (matched > 0) return matched;
        }
      }
    }

    for (final interval in intervals) {
      final matched = _firstHydraulicNumber([interval['bitSize']]);
      if (matched > 0) return matched;
    }
    return 0;
  }

  double _nozzleTotalArea(Map<String, dynamic> nozzleData) {
    final saved = _number(nozzleData['tfa']);
    if (saved > 0) return saved;

    final nozzles = _listFromDynamic(nozzleData['nozzles']);
    var total = 0.0;
    for (final nozzle in nozzles) {
      final nozzleMap = _mapFromDynamic(nozzle);
      final count = _number(nozzleMap['count']);
      final size32 = _firstHydraulicNumber([
        nozzleMap['size32'],
        nozzleMap['size'],
        nozzleMap['diameterInch'],
      ]);
      final diameter = _number(nozzleMap['diameterInch']) > 0
          ? _number(nozzleMap['diameterInch'])
          : size32 / 32;
      if (count <= 0 || diameter <= 0) continue;
      total += count * 0.785 * diameter * diameter;
    }
    return total;
  }

  double? _calculateEcd(
    double? mudWeight,
    double? annularPressureLoss,
    double? depth,
  ) {
    final baseMw = mudWeight ?? 0;
    final loss = annularPressureLoss ?? 0;
    final depthFt = depth ?? 0;

    if (baseMw <= 0) return null;
    if (loss <= 0 || depthFt <= 0) return baseMw;
    return baseMw + loss / (0.052 * depthFt);
  }

  String _normalizeKey(dynamic value) {
    return _text(value).toLowerCase().replaceAll('*', '').replaceAll(
      RegExp(r'\s+'),
      ' ',
    ).trim();
  }

  double _mudRowNumber(List<dynamic> row, [int preferredIndex = 0]) {
    if (preferredIndex >= 0 && preferredIndex < row.length) {
      final preferred = _parseFraction(row[preferredIndex]);
      if (preferred != null && preferred > 0) return preferred;
    }

    for (final value in row) {
      final parsed = _parseFraction(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0;
  }

  double _firstHydraulicNumber(Iterable<dynamic> values) {
    for (final value in values) {
      final parsed = _parseFraction(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0;
  }

  double? _parseFraction(dynamic value) {
    if (value is num) return value.toDouble();

    final raw = _text(value)
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(',', '')
        .trim();
    if (raw.isEmpty) return null;

    final plain = double.tryParse(raw);
    if (plain != null) return plain;

    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length == 2 && parts.last.contains('/')) {
      final whole = double.tryParse(parts.first);
      final fraction = _parseSimpleFraction(parts.last);
      if (whole != null && fraction != null) {
        return whole + fraction;
      }
    }

    if (raw.contains('/')) {
      return _parseSimpleFraction(raw);
    }

    return double.tryParse(raw.replaceAll(RegExp(r'[^0-9.\-]'), ''));
  }

  double? _parseSimpleFraction(String raw) {
    final fractionParts = raw.split('/');
    if (fractionParts.length != 2) return null;
    final numerator = double.tryParse(
      fractionParts[0].replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
    final denominator = double.tryParse(
      fractionParts[1].replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }
    return numerator / denominator;
  }

  Map<String, dynamic> _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  List<dynamic> _listFromDynamic(dynamic value) {
    if (value is List) return value;
    return const <dynamic>[];
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

    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return parsed;

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

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _positiveOrNull(double value) => value > 0 ? value : null;
}

class HydraulicsHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final String interval;
  final String activity;
  final double? flowRateGpm;
  final double? pumpPressurePsi;
  final double? impactForceLbf;
  final double? hsi;
  final double? bhEcdPpg;
  final double? porePpg;
  final double? fracPpg;
  final double? mudWeightPpg;
  final double? pv;
  final double? yp;
  final double? dhToolsPressureLossPsi;
  final double? motorPressureLossPsi;
  final double? bitPressureLossPsi;
  final double? drillStringPressureLossPsi;
  final double? annularPressureLossPsi;
  final double? nozzleAreaIn2;
  final double? nozzleVelocityFtSec;
  final int segmentCount;

  const HydraulicsHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.interval,
    required this.activity,
    required this.flowRateGpm,
    required this.pumpPressurePsi,
    required this.impactForceLbf,
    required this.hsi,
    required this.bhEcdPpg,
    required this.porePpg,
    required this.fracPpg,
    required this.mudWeightPpg,
    required this.pv,
    required this.yp,
    required this.dhToolsPressureLossPsi,
    required this.motorPressureLossPsi,
    required this.bitPressureLossPsi,
    required this.drillStringPressureLossPsi,
    required this.annularPressureLossPsi,
    required this.nozzleAreaIn2,
    required this.nozzleVelocityFtSec,
    required this.segmentCount,
  });
}

class _HydraulicsPumpFlowSummary {
  final double displacementBblPerStroke;
  final double rateGpm;
  final double spm;
  final double maxPumpP;

  const _HydraulicsPumpFlowSummary({
    required this.displacementBblPerStroke,
    required this.rateGpm,
    required this.spm,
    required this.maxPumpP,
  });
}

class _HydraulicsMudValues {
  final double? mw;
  final double? pv;
  final double? yp;

  const _HydraulicsMudValues({
    required this.mw,
    required this.pv,
    required this.yp,
  });
}

class _HydraulicsSegment {
  final double holeSize;
  final double pipeOd;
  final double pipeId;
  final double length;

  const _HydraulicsSegment({
    required this.holeSize,
    required this.pipeOd,
    required this.pipeId,
    required this.length,
  });
}

class _HydraulicsFormationReference {
  final double? porePpg;
  final double? fracPpg;

  const _HydraulicsFormationReference({
    this.porePpg,
    this.fracPpg,
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
