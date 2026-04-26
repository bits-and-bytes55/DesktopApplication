import 'dart:convert';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/recap_daily_cost/controller/recap_daily_cost_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapDepthCostController extends GetxController {
  final RecapDailyCostController _dailyCostController;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapDepthCostController({
    RecapDailyCostController? dailyCostController,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _dailyCostController =
           dailyCostController ??
           (Get.isRegistered<RecapDailyCostController>()
               ? Get.find<RecapDailyCostController>()
               : Get.put(RecapDailyCostController())),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final rows = <DailyCostHistoryRow>[].obs;
  final casings = <DepthCostCasing>[].obs;

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
      casings.clear();
      emptyMessage.value = 'Select a well first to open Depth Cost recap.';
      return;
    }

    isLoading.value = true;

    try {
      final casingFuture = _fetchCasings(wellId);
      await _dailyCostController.load();
      final fetchedCasings = await casingFuture;

      if (_dailyCostController.errorMessage.value.isNotEmpty) {
        throw Exception(_dailyCostController.errorMessage.value);
      }

      final history = [..._dailyCostController.rows]..sort(_compareRowsByDepth);
      rows.assignAll(history);
      casings.assignAll(fetchedCasings);

      if (history.isEmpty) {
        emptyMessage.value = _dailyCostController.emptyMessage.value.isNotEmpty
            ? _dailyCostController.emptyMessage.value
            : 'No depth cost history is available yet.';
      }
    } catch (error) {
      rows.clear();
      casings.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  List<DailyCostHistoryRow> get graphRows {
    final nonZeroDepthRows = rows.where((row) => row.md > 0).toList();
    return nonZeroDepthRows.isNotEmpty ? nonZeroDepthRows : rows.toList();
  }

  List<String> get allCategoryColumns => const [
    'Product',
    'Premixed Mud',
    'Package',
    'Service',
    'Engineering',
    'Total',
  ];

  List<String> get groupColumns {
    final totals = <String, double>{};
    for (final row in rows) {
      final items = groupItemsForRow(row);
      for (final entry in items.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
      }
    }

    final keys = totals.keys.toList();
    keys.sort((left, right) {
      final amountCompare = (totals[right] ?? 0).compareTo(totals[left] ?? 0);
      if (amountCompare != 0) return amountCompare;
      return left.toLowerCase().compareTo(right.toLowerCase());
    });
    return keys;
  }

  Map<String, double> groupItemsForRow(DailyCostHistoryRow row) {
    final grouped = <String, double>{};
    _appendGroupItems(grouped, row.productItems, 'Product');
    _appendGroupItems(grouped, row.premixedMudItems, 'Premixed Mud');
    _appendGroupItems(grouped, row.packageItems, 'Package');
    _appendGroupItems(grouped, row.serviceItems, 'Service');
    _appendGroupItems(grouped, row.engineeringItems, 'Engineering');
    return grouped;
  }

  double allCategoryValueForRow(DailyCostHistoryRow row, String column) {
    switch (column) {
      case 'Product':
        return row.productTotal;
      case 'Premixed Mud':
        return row.premixedMudTotal;
      case 'Package':
        return row.packageTotal;
      case 'Service':
        return row.serviceTotal;
      case 'Engineering':
        return row.engineeringTotal;
      case 'Total':
        return row.total;
      default:
        return 0;
    }
  }

  double groupValueForRow(DailyCostHistoryRow row, String column) {
    return groupItemsForRow(row)[column] ?? 0;
  }

  double get maxDepth {
    var maxValue = 0.0;
    for (final row in graphRows) {
      maxValue = math.max(maxValue, row.md);
    }
    for (final casing in casings) {
      maxValue = math.max(maxValue, casing.shoe);
    }

    if (maxValue <= 0) return 20;
    return _niceDepthMax(maxValue);
  }

  Future<List<DepthCostCasing>> _fetchCasings(String wellId) async {
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
        if (data is! List) return const <DepthCostCasing>[];

        final fetchedCasings =
            data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .map(
                  (item) => DepthCostCasing(
                    label: _buildCasingLabel(item),
                    top: _number(item['top']),
                    shoe: _number(item['shoe']),
                  ),
                )
                .where((item) => item.shoe > 0)
                .toList()
              ..sort((left, right) => left.shoe.compareTo(right.shoe));

        return fetchedCasings;
      } catch (error) {
        failures.add('${uri.origin}: ${_cleanError(error)}');
      }
    }

    if (failures.isNotEmpty) {
      return const <DepthCostCasing>[];
    }
    return const <DepthCostCasing>[];
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

    if (trimmed.isEmpty) {
      throw const FormatException('empty response');
    }

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

  void _appendGroupItems(
    Map<String, double> grouped,
    Map<String, double> source,
    String prefix,
  ) {
    for (final entry in source.entries) {
      final baseLabel = entry.key.trim().isNotEmpty ? entry.key.trim() : prefix;
      var label = baseLabel;
      if (grouped.containsKey(label)) {
        label = '$prefix - $baseLabel';
      }
      grouped[label] = (grouped[label] ?? 0) + entry.value;
    }
  }

  String _buildCasingLabel(Map<String, dynamic> item) {
    final odText = _text(item['od']);
    if (odText.isNotEmpty) {
      return odText.toLowerCase().contains('inch') ? odText : '$odText inch';
    }
    final description = _text(item['description']);
    return description.isNotEmpty ? description : 'Casing';
  }

  double _niceDepthMax(double value) {
    if (value <= 20) return 20;
    if (value <= 50) return 50;
    if (value <= 100) return 100;
    if (value <= 250) return 250;
    if (value <= 500) return 500;
    if (value <= 1000) return 1000;

    final exponent = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toDouble();
    final scaled = value / exponent;
    if (scaled <= 2) return 2 * exponent;
    if (scaled <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

class DepthCostCasing {
  final String label;
  final double top;
  final double shoe;

  const DepthCostCasing({
    required this.label,
    required this.top,
    required this.shoe,
  });
}

int _compareRowsByDepth(DailyCostHistoryRow left, DailyCostHistoryRow right) {
  final mdCompare = left.md.compareTo(right.md);
  if (mdCompare != 0) return mdCompare;
  return left.reportLabel.toLowerCase().compareTo(
    right.reportLabel.toLowerCase(),
  );
}
