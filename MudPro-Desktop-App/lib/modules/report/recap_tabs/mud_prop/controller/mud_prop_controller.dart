import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapMudPropController extends GetxController {
  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapMudPropController({
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
  final rows = <MudPropHistoryRow>[].obs;
  final selectedGroupId = 'group_1'.obs;

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
      emptyMessage.value = 'Select a well first to open Mud Properties recap.';
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
      final mudStates = await Future.wait(
        ordered.map((summary) => _fetchMudReportState(wellId, summary.reportId)),
      );

      final history = <MudPropHistoryRow>[];
      for (int index = 0; index < ordered.length; index++) {
        final summary = ordered[index];
        final mudState = mudStates[index];

        final sampleLabels = _sampleLabels(mudState['samples']);
        final sampleIndex = _sampleIndex(sampleLabels, '1', 0);
        final planLowIndex = _sampleIndex(sampleLabels, 'plan-l', 3);
        final planHighIndex = _sampleIndex(sampleLabels, 'plan-h', 4);

        final propertyTable = _mapFromDynamic(mudState['propertyTable']);
        final propertyUnits = _mapFromDynamic(mudState['propertyUnits']);
        final metrics = <String, MudMetricValue>{};

        for (final definition in _allMetricDefinitions) {
          final matchedKey = _findMetricKey(propertyTable, definition.id);
          if (matchedKey == null) continue;
          final rawValues = _listFromDynamic(propertyTable[matchedKey]);
          metrics[definition.id] = MudMetricValue(
            actualText: _valueAt(rawValues, sampleIndex),
            planText: _firstNonEmpty(
              _valueAt(rawValues, planLowIndex),
              _valueAt(rawValues, planHighIndex),
            ),
            unit: _text(propertyUnits[matchedKey]).isNotEmpty
                ? _text(propertyUnits[matchedKey])
                : definition.defaultUnit,
          );
        }

        final fluidType = _firstNonEmpty(
          _text(mudState['fluidType']),
          summary.mudType,
          'Water-based',
        );

        history.add(
          MudPropHistoryRow(
            reportId: summary.reportId,
            reportLabel: summary.reportLabel,
            reportDate: summary.reportDate,
            createdAt: summary.createdAt,
            md: summary.md,
            fluidType: fluidType,
            metrics: metrics,
          ),
        );
      }

      rows.assignAll(history);
      _ensureValidGroupSelection();

      if (history.isEmpty) {
        emptyMessage.value = 'No mud-property history is available yet.';
      }
    } catch (error) {
      rows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  List<MudPropGroupDefinition> get activeGroups {
    final family = primaryFluidFamily;
    return family == MudFluidFamily.water
        ? _waterGroupDefinitions
        : _oilSyntheticGroupDefinitions;
  }

  MudPropGroupDefinition get selectedGroup {
    _ensureValidGroupSelection();
    return activeGroups.firstWhere(
      (group) => group.id == selectedGroupId.value,
      orElse: () => activeGroups.first,
    );
  }

  List<MudPropertyMetricDefinition> get selectedGroupMetrics => selectedGroup
      .metricIds
      .map((id) => _metricById[id]!)
      .toList(growable: false);

  List<MudPropertyMetricDefinition> get waterTableMetrics =>
      _waterTableMetricIds.map((id) => _metricById[id]!).toList(growable: false);

  List<MudPropertyMetricDefinition> get oilSyntheticTableMetrics =>
      _oilSyntheticTableMetricIds
          .map((id) => _metricById[id]!)
          .toList(growable: false);

  List<MudPropHistoryRow> get waterRows => rows
      .where((row) => row.family == MudFluidFamily.water)
      .toList(growable: false);

  List<MudPropHistoryRow> get oilSyntheticRows => rows
      .where((row) => row.family != MudFluidFamily.water)
      .toList(growable: false);

  MudFluidFamily get primaryFluidFamily {
    var waterCount = 0;
    var oilCount = 0;
    for (final row in rows) {
      if (row.family == MudFluidFamily.water) {
        waterCount++;
      } else {
        oilCount++;
      }
    }
    return waterCount >= oilCount
        ? MudFluidFamily.water
        : MudFluidFamily.oilSynthetic;
  }

  String get primaryFluidLabel {
    final counts = <String, int>{};
    for (final row in rows) {
      final label = row.fluidType.trim().isEmpty ? 'Water-based' : row.fluidType;
      counts[label] = (counts[label] ?? 0) + 1;
    }

    String best = primaryFluidFamily == MudFluidFamily.water
        ? 'Water-based'
        : 'Oil/Synthetic';
    var bestCount = -1;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }

  bool get hasPlanData {
    for (final row in rows) {
      for (final metricId in selectedGroup.metricIds) {
        final value = row.metric(metricId);
        if (value?.planNumber != null) return true;
      }
    }
    return false;
  }

  void selectGroup(String id) {
    selectedGroupId.value = id;
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
      'Mud Properties recap backend routes are not available. '
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

  void _ensureValidGroupSelection() {
    if (activeGroups.any((group) => group.id == selectedGroupId.value)) return;
    if (activeGroups.isNotEmpty) {
      selectedGroupId.value = activeGroups.first.id;
    }
  }

  String? _findMetricKey(Map<String, dynamic> propertyTable, String metricId) {
    for (final key in propertyTable.keys) {
      if (_matchesMetric(metricId, _normalizeKey(key))) {
        return key;
      }
    }
    return null;
  }

  bool _matchesMetric(String metricId, String key) {
    switch (metricId) {
      case 'flowline_temp':
        return key.contains('flowline') || key.contains('suction');
      case 'depth':
        return key == 'depth' || key == 'md' || key.contains('measured depth');
      case 'mw':
        return key == 'mw' || key.startsWith('mw ') || key.contains('mud weight');
      case 'funnel_visc':
        return key.contains('funnel');
      case 'pv':
        return (key == 'pv' || key.startsWith('pv ')) && !key.contains('for');
      case 'yp':
        return key == 'yp' || key.startsWith('yp ');
      case 'gel_10s':
        return key.contains('gel') &&
            (key.contains('10s') || key.contains('10 s') || key.contains('10 sec'));
      case 'gel_10m':
        return key.contains('gel') &&
            (key.contains('10m') || key.contains('10 m') || key.contains('10 min'));
      case 'gel_30m':
        return key.contains('gel') &&
            (key.contains('30m') || key.contains('30 m') || key.contains('30 min'));
      case 'api_filtrate':
        return key.contains('api filtrate') && !key.contains('cake');
      case 'api_cake':
        return key.contains('api') && key.contains('cake');
      case 'hthp_filtrate':
        return key.contains('hthp') && key.contains('filtrate') && !key.contains('cake');
      case 'hthp_cake':
        return key.contains('hthp') && key.contains('cake');
      case 'solids':
        return (key == 'solids' || key.startsWith('solids ') || key == 'retort solids') &&
            !key.contains('correct') &&
            !key.contains('corr') &&
            !key.contains('drill') &&
            !key.contains('salt');
      case 'corrected_solids':
        return key.contains('corrected solids') ||
            key.contains('corr. solids') ||
            key.contains('solids adjusted');
      case 'oil':
        return (key == 'oil' || key.startsWith('oil ')) && !key.contains('ratio');
      case 'water':
        return (key == 'water' || key.startsWith('water ')) &&
            !key.contains('phase') &&
            !key.contains('activity');
      case 'sand_content':
        return key.contains('sand content');
      case 'mbt':
        return key.contains('mbt') || key.contains('methylene');
      case 'ph':
        return key == 'ph' || key.startsWith('ph ');
      case 'mud_alkalinity':
        return key.contains('mud alkalinity') ||
            (key.contains('alkalinity') && key.contains('pm'));
      case 'filtrate_pf':
        return key.contains('filtrate alkalinity') && key.contains('pf');
      case 'filtrate_mf':
        return key.contains('filtrate alkalinity') && key.contains('mf');
      case 'calcium':
        return key == 'calcium' || key.startsWith('calcium ');
      case 'chlorides':
        return key.contains('chloride') &&
            !key.contains('make up') &&
            !key.contains('makeup') &&
            !key.contains('whole mud') &&
            !key.contains('cacl2') &&
            !key.contains('calcium chloride');
      case 'total_hardness':
        return key.contains('total hardness');
      case 'excess_lime':
        return key.contains('excess lime');
      case 'potassium':
        return key == 'k+' || key == 'k' || key.startsWith('k+ ');
      case 'makeup_water_chlorides':
        return key.contains('make up') && key.contains('chloride');
      case 'fine_lcm':
        return key.contains('fine lcm');
      case 'coarse_lcm':
        return key.contains('coarse lcm');
      case 'r600':
        return key == 'r600' || key.startsWith('r600 ');
      case 'r300':
        return key == 'r300' || key.startsWith('r300 ');
      case 'r200':
        return key == 'r200' || key.startsWith('r200 ');
      case 'r100':
        return key == 'r100' || key.startsWith('r100 ');
      case 'r6':
        return key == 'r6' || key.startsWith('r6 ');
      case 'r3':
        return key == 'r3' || key.startsWith('r3 ');
      case 'oil_water_ratio':
        return key.contains('oil') && key.contains('water') && key.contains('ratio');
      case 'whole_mud_alkalinity':
        return key.contains('whole mud alkalinity') ||
            (key.contains('mud alkalinity') && key.contains('pom'));
      case 'electrical_stability':
        return key.contains('electrical stability');
      case 'whole_mud_chlorides':
        return key.contains('whole mud chlorides') ||
            (key.contains('mud chloride') && key.contains('whole'));
      case 'cacl2_concentration':
        return key.contains('cacl2 concentration') ||
            (key.startsWith('cacl2') && key.contains('mg'));
      case 'cacl2_wt':
        return key == 'cacl2' ||
            key == 'cacl2 % wt' ||
            (key.startsWith('cacl2') && key.contains('wt'));
      case 'wps_ppm':
        return (key.contains('water phase salinity') || key.contains('wps')) &&
            (key.contains('ppm') || (!key.contains('mg') && !key.contains('%')));
      case 'wps_mgl':
        return (key.contains('water phase salinity') || key.contains('wps')) &&
            key.contains('mg');
      case 'water_activity':
        return key.contains('water activity');
      case 'brine_density':
        return key.contains('brine density');
      default:
        return false;
    }
  }

  List<String> _sampleLabels(dynamic raw) {
    final labels = _listFromDynamic(raw)
        .map((item) => item.toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (labels.isNotEmpty) return labels;
    return const ['1', '2', '3', 'plan-l', 'plan-h'];
  }

  int _sampleIndex(List<String> labels, String label, int fallback) {
    final index = labels.indexOf(label.toLowerCase());
    return index >= 0 ? index : fallback;
  }

  String _valueAt(List<String> values, int index) {
    if (index < 0 || index >= values.length) return '';
    return values[index].trim();
  }

  String _normalizeKey(String value) => value
      .toLowerCase()
      .replaceAll('*', '')
      .replaceAll(RegExp(r'[()/_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Map<String, dynamic> _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  List<String> _listFromDynamic(dynamic value) {
    if (value is List) {
      return value.map((item) => item?.toString().trim() ?? '').toList();
    }
    return const <String>[];
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';

  String _firstNonEmpty(String left, [String right = '', String third = '']) {
    for (final value in [left, right, third]) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

enum MudFluidFamily { water, oilSynthetic }

class MudPropHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final String fluidType;
  final Map<String, MudMetricValue> metrics;

  const MudPropHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.fluidType,
    required this.metrics,
  });

  MudFluidFamily get family {
    final normalized = fluidType.toLowerCase();
    if (normalized.contains('water')) return MudFluidFamily.water;
    return MudFluidFamily.oilSynthetic;
  }

  MudMetricValue? metric(String id) => metrics[id];
}

class MudMetricValue {
  final String actualText;
  final String planText;
  final String unit;

  const MudMetricValue({
    required this.actualText,
    required this.planText,
    required this.unit,
  });

  double? get actualNumber => _parseNumeric(actualText);
  double? get planNumber => _parseNumeric(planText);

  static double? _parseNumeric(String value) {
    final cleaned = value.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}

class MudPropertyMetricDefinition {
  final String id;
  final String label;
  final String defaultUnit;

  const MudPropertyMetricDefinition({
    required this.id,
    required this.label,
    required this.defaultUnit,
  });
}

class MudPropGroupDefinition {
  final String id;
  final String label;
  final List<String> metricIds;

  const MudPropGroupDefinition({
    required this.id,
    required this.label,
    required this.metricIds,
  });
}

const _allMetricDefinitions = <MudPropertyMetricDefinition>[
  MudPropertyMetricDefinition(id: 'flowline_temp', label: 'Flowline T.', defaultUnit: 'degF'),
  MudPropertyMetricDefinition(id: 'depth', label: 'Depth', defaultUnit: 'ft'),
  MudPropertyMetricDefinition(id: 'mw', label: 'MW', defaultUnit: 'ppg'),
  MudPropertyMetricDefinition(id: 'funnel_visc', label: 'Funnel Visc.', defaultUnit: 'sec/qt'),
  MudPropertyMetricDefinition(id: 'pv', label: 'PV', defaultUnit: 'cP'),
  MudPropertyMetricDefinition(id: 'yp', label: 'YP', defaultUnit: 'lbf/100ft2'),
  MudPropertyMetricDefinition(id: 'gel_10s', label: 'Gel 10s', defaultUnit: 'lbf/100ft2'),
  MudPropertyMetricDefinition(id: 'gel_10m', label: 'Gel 10m', defaultUnit: 'lbf/100ft2'),
  MudPropertyMetricDefinition(id: 'gel_30m', label: 'Gel 30m', defaultUnit: 'lbf/100ft2'),
  MudPropertyMetricDefinition(id: 'api_filtrate', label: 'API Filtrate', defaultUnit: 'mL/30min'),
  MudPropertyMetricDefinition(id: 'api_cake', label: 'API Cake', defaultUnit: '1/32in'),
  MudPropertyMetricDefinition(id: 'hthp_filtrate', label: 'HTHP Filtrate', defaultUnit: 'mL/30min'),
  MudPropertyMetricDefinition(id: 'hthp_cake', label: 'HTHP Cake', defaultUnit: '1/32in'),
  MudPropertyMetricDefinition(id: 'solids', label: 'Solids', defaultUnit: '% vol'),
  MudPropertyMetricDefinition(id: 'corrected_solids', label: 'Corrected Solids', defaultUnit: '% vol'),
  MudPropertyMetricDefinition(id: 'oil', label: 'Oil', defaultUnit: '% vol'),
  MudPropertyMetricDefinition(id: 'water', label: 'Water', defaultUnit: '% vol'),
  MudPropertyMetricDefinition(id: 'sand_content', label: 'Sand Content', defaultUnit: '% vol'),
  MudPropertyMetricDefinition(id: 'mbt', label: 'MBT', defaultUnit: 'ppb'),
  MudPropertyMetricDefinition(id: 'ph', label: 'pH', defaultUnit: ''),
  MudPropertyMetricDefinition(id: 'mud_alkalinity', label: 'Mud Alkalinity', defaultUnit: 'mL'),
  MudPropertyMetricDefinition(id: 'filtrate_pf', label: 'Filtrate Pf', defaultUnit: 'mL'),
  MudPropertyMetricDefinition(id: 'filtrate_mf', label: 'Filtrate Mf', defaultUnit: 'mL'),
  MudPropertyMetricDefinition(id: 'calcium', label: 'Calcium', defaultUnit: 'mg/L'),
  MudPropertyMetricDefinition(id: 'chlorides', label: 'Chlorides', defaultUnit: 'mg/L'),
  MudPropertyMetricDefinition(id: 'total_hardness', label: 'Total Hardness', defaultUnit: 'mg/L'),
  MudPropertyMetricDefinition(id: 'excess_lime', label: 'Excess Lime', defaultUnit: 'lb/bbl'),
  MudPropertyMetricDefinition(id: 'potassium', label: 'K+', defaultUnit: 'mg/L'),
  MudPropertyMetricDefinition(id: 'makeup_water_chlorides', label: 'Make up Water: Chlorides', defaultUnit: 'mg/L'),
  MudPropertyMetricDefinition(id: 'fine_lcm', label: 'Fine LCM', defaultUnit: 'lb/bbl'),
  MudPropertyMetricDefinition(id: 'coarse_lcm', label: 'Coarse LCM', defaultUnit: 'lb/bbl'),
  MudPropertyMetricDefinition(id: 'r600', label: 'R600', defaultUnit: 'rpm'),
  MudPropertyMetricDefinition(id: 'r300', label: 'R300', defaultUnit: 'rpm'),
  MudPropertyMetricDefinition(id: 'r200', label: 'R200', defaultUnit: 'rpm'),
  MudPropertyMetricDefinition(id: 'r100', label: 'R100', defaultUnit: 'rpm'),
  MudPropertyMetricDefinition(id: 'r6', label: 'R6', defaultUnit: 'rpm'),
  MudPropertyMetricDefinition(id: 'r3', label: 'R3', defaultUnit: 'rpm'),
  MudPropertyMetricDefinition(id: 'oil_water_ratio', label: 'Oil/Water Ratio', defaultUnit: 'ratio'),
  MudPropertyMetricDefinition(id: 'whole_mud_alkalinity', label: 'Whole Mud Alkalinity', defaultUnit: 'mL'),
  MudPropertyMetricDefinition(id: 'electrical_stability', label: 'Electrical Stability', defaultUnit: 'volts'),
  MudPropertyMetricDefinition(id: 'whole_mud_chlorides', label: 'Whole Mud Chlorides', defaultUnit: 'mg/L'),
  MudPropertyMetricDefinition(id: 'cacl2_concentration', label: 'CaCl2 Conc.', defaultUnit: 'mg/L'),
  MudPropertyMetricDefinition(id: 'cacl2_wt', label: 'CaCl2', defaultUnit: '% wt'),
  MudPropertyMetricDefinition(id: 'wps_ppm', label: 'WPS', defaultUnit: 'ppm'),
  MudPropertyMetricDefinition(id: 'wps_mgl', label: 'WPS', defaultUnit: 'mg/L'),
  MudPropertyMetricDefinition(id: 'water_activity', label: 'Water Activity', defaultUnit: 'aw'),
  MudPropertyMetricDefinition(id: 'brine_density', label: 'Brine Density', defaultUnit: 'ppg'),
];

final _metricById = {
  for (final definition in _allMetricDefinitions) definition.id: definition,
};

const _waterGroupDefinitions = <MudPropGroupDefinition>[
  MudPropGroupDefinition(
    id: 'group_1',
    label: 'Group 1',
    metricIds: ['mw', 'pv', 'yp', 'api_filtrate'],
  ),
  MudPropGroupDefinition(
    id: 'group_2',
    label: 'Group 2',
    metricIds: ['funnel_visc', 'gel_10s', 'gel_10m', 'gel_30m'],
  ),
  MudPropGroupDefinition(
    id: 'group_3',
    label: 'Group 3',
    metricIds: ['hthp_filtrate', 'hthp_cake', 'solids', 'sand_content'],
  ),
  MudPropGroupDefinition(
    id: 'group_4',
    label: 'Group 4',
    metricIds: ['ph', 'mud_alkalinity', 'filtrate_pf', 'filtrate_mf'],
  ),
  MudPropGroupDefinition(
    id: 'group_5',
    label: 'Group 5',
    metricIds: ['calcium', 'chlorides', 'total_hardness', 'excess_lime'],
  ),
  MudPropGroupDefinition(
    id: 'group_6',
    label: 'Group 6',
    metricIds: ['potassium', 'makeup_water_chlorides', 'fine_lcm', 'coarse_lcm'],
  ),
];

const _oilSyntheticGroupDefinitions = <MudPropGroupDefinition>[
  MudPropGroupDefinition(
    id: 'group_1',
    label: 'Group 1',
    metricIds: ['mw', 'pv', 'yp', 'hthp_filtrate'],
  ),
  MudPropGroupDefinition(
    id: 'group_2',
    label: 'Group 2',
    metricIds: ['funnel_visc', 'r600', 'r300', 'r200'],
  ),
  MudPropGroupDefinition(
    id: 'group_3',
    label: 'Group 3',
    metricIds: ['r100', 'r6', 'r3', 'gel_10s'],
  ),
  MudPropGroupDefinition(
    id: 'group_4',
    label: 'Group 4',
    metricIds: ['gel_10m', 'gel_30m', 'solids', 'corrected_solids'],
  ),
  MudPropGroupDefinition(
    id: 'group_5',
    label: 'Group 5',
    metricIds: ['oil', 'water', 'oil_water_ratio', 'whole_mud_alkalinity'],
  ),
  MudPropGroupDefinition(
    id: 'group_6',
    label: 'Group 6',
    metricIds: ['electrical_stability', 'whole_mud_chlorides', 'cacl2_concentration', 'cacl2_wt'],
  ),
  MudPropGroupDefinition(
    id: 'group_7',
    label: 'Group 7',
    metricIds: ['wps_ppm', 'wps_mgl', 'brine_density', 'water_activity'],
  ),
];

const _waterTableMetricIds = <String>[
  'depth',
  'mw',
  'funnel_visc',
  'pv',
  'yp',
  'gel_10s',
  'gel_10m',
  'gel_30m',
  'api_filtrate',
  'api_cake',
  'hthp_filtrate',
  'hthp_cake',
  'solids',
  'oil',
  'water',
  'sand_content',
  'mbt',
  'ph',
  'mud_alkalinity',
  'filtrate_pf',
  'filtrate_mf',
  'calcium',
  'chlorides',
  'total_hardness',
  'excess_lime',
  'potassium',
  'makeup_water_chlorides',
  'fine_lcm',
  'coarse_lcm',
];

const _oilSyntheticTableMetricIds = <String>[
  'depth',
  'mw',
  'funnel_visc',
  'r600',
  'r300',
  'r200',
  'r100',
  'r6',
  'r3',
  'pv',
  'yp',
  'gel_10s',
  'gel_10m',
  'gel_30m',
  'hthp_filtrate',
  'hthp_cake',
  'solids',
  'corrected_solids',
  'oil',
  'water',
  'oil_water_ratio',
  'whole_mud_alkalinity',
  'electrical_stability',
  'whole_mud_chlorides',
  'cacl2_concentration',
  'cacl2_wt',
  'wps_ppm',
  'wps_mgl',
  'brine_density',
  'water_activity',
];

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
