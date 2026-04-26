import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapDailyCostController extends GetxController {
  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapDailyCostController({
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
  final rows = <DailyCostHistoryRow>[].obs;

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
      emptyMessage.value = 'Select a well first to open Daily Cost recap.';
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
      final history = await Future.wait(
        ordered.map((row) => _buildHistoryRow(wellId, row)),
      );

      rows.assignAll(history);
      if (history.isEmpty) {
        emptyMessage.value = 'No daily cost history is available yet.';
      }
    } catch (error) {
      rows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  List<double> get productSeries =>
      rows.map((row) => row.productTotal).toList();
  List<double> get premixedSeries =>
      rows.map((row) => row.premixedMudTotal).toList();
  List<double> get packageSeries =>
      rows.map((row) => row.packageTotal).toList();
  List<double> get serviceSeries =>
      rows.map((row) => row.serviceTotal).toList();
  List<double> get engineeringSeries =>
      rows.map((row) => row.engineeringTotal).toList();

  List<String> get dayLabels =>
      List.generate(rows.length, (index) => '${index + 1}');

  List<String> get productColumns => _orderedKeys((row) => row.productItems);
  List<String> get premixedColumns =>
      _orderedKeys((row) => row.premixedMudItems);
  List<String> get packageColumns => _orderedKeys((row) => row.packageItems);
  List<String> get serviceColumns => _orderedKeys((row) => row.serviceItems);
  List<String> get engineeringColumns =>
      _orderedKeys((row) => row.engineeringItems);

  List<String> get allCategoryColumns => const [
    'Product',
    'Premixed Mud',
    'Package',
    'Service',
    'Engineering',
    'Total',
  ];

  Future<DailyCostHistoryRow> _buildHistoryRow(
    String wellId,
    ReportManagerRow row,
  ) async {
    final results = await Future.wait([
      _fetchInventorySnapshot(wellId: wellId, reportId: row.reportId),
      _fetchList(
        path: 'receive-mud/$wellId',
        queryParameters: {'reportId': row.reportId},
      ),
      _fetchList(
        path: 'return-lost-mud/$wellId',
        queryParameters: {'reportId': row.reportId},
      ),
    ]);

    final inventory = results[0];
    final receiveMud = results[1];
    final returnLostMud = results[2];

    final productItems = _categoryItemTotals(inventory, 'Product');
    final packageItems = _categoryItemTotals(inventory, 'Package');
    final serviceItems = _categoryItemTotals(inventory, 'Service');
    final engineeringItems = _categoryItemTotals(inventory, 'Engineering');
    final premixedItems = _premixedItemTotals(receiveMud, returnLostMud);

    final productTotal = _sum(productItems.values);
    final premixedTotal = _sum(premixedItems.values);
    final packageTotal = _sum(packageItems.values);
    final serviceTotal = _sum(serviceItems.values);
    final engineeringTotal = _sum(engineeringItems.values);

    return DailyCostHistoryRow(
      reportId: row.reportId,
      reportLabel: row.reportLabel,
      reportDate: row.reportDate,
      md: row.md,
      productItems: productItems,
      premixedMudItems: premixedItems,
      packageItems: packageItems,
      serviceItems: serviceItems,
      engineeringItems: engineeringItems,
      productTotal: productTotal,
      premixedMudTotal: premixedTotal,
      packageTotal: packageTotal,
      serviceTotal: serviceTotal,
      engineeringTotal: engineeringTotal,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchInventorySnapshot({
    required String wellId,
    required String reportId,
  }) async {
    await _postObject(
      path: 'inventory/generate',
      queryParameters: {'wellId': wellId, 'reportId': reportId},
      body: const <String, dynamic>{},
      swallowErrors: true,
    );

    final decoded = await _getObject(
      path: 'inventory/',
      queryParameters: {'wellId': wellId, 'reportId': reportId},
    );
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchList({
    required String path,
    required Map<String, String> queryParameters,
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
      'Daily Cost recap backend routes are not available. '
      'Tried: ${failures.join(' | ')}',
    );
  }

  Future<void> _postObject({
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    bool swallowErrors = false,
  }) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParameters);

      try {
        final response = await http
            .post(
              uri,
              headers: _headers,
              body: jsonEncode(body ?? const <String, dynamic>{}),
            )
            .timeout(const Duration(seconds: 20));
        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if ((response.statusCode == 200 || response.statusCode == 201) &&
            decoded['success'] == true) {
          return;
        }

        failures.add(
          '${uri.origin}: ${decoded['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      } on TimeoutException {
        failures.add('${uri.origin}: request timed out');
      } on FormatException catch (error) {
        failures.add('${uri.origin}: ${error.message}');
      } catch (error) {
        failures.add('${uri.origin}: ${_cleanError(error)}');
      }
    }

    if (!swallowErrors) {
      throw Exception(
        'Daily Cost recap backend routes are not available. '
        'Tried: ${failures.join(' | ')}',
      );
    }
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

  Map<String, double> _categoryItemTotals(
    List<Map<String, dynamic>> items,
    String category,
  ) {
    final totals = <String, double>{};
    for (final item in items) {
      if (_text(item['category']).toLowerCase() != category.toLowerCase()) {
        continue;
      }
      final itemName = _text(item['itemName']).isNotEmpty
          ? _text(item['itemName'])
          : 'Unnamed';
      totals[itemName] = (totals[itemName] ?? 0) + _number(item['subtotal']);
    }
    return totals;
  }

  Map<String, double> _premixedItemTotals(
    List<Map<String, dynamic>> receiveMud,
    List<Map<String, dynamic>> returnLostMud,
  ) {
    final totals = <String, double>{};

    for (final item in receiveMud) {
      final label = _text(item['premixedMud']).isNotEmpty
          ? _text(item['premixedMud'])
          : 'Premixed Mud';
      final volume = _number(item['netVolume']) > 0
          ? _number(item['netVolume'])
          : _number(item['volume']);
      final amount = volume * _number(item['leasingFee']);
      totals[label] = (totals[label] ?? 0) + amount;
    }

    for (final item in returnLostMud) {
      final label = _text(item['premixedMud']).isNotEmpty
          ? _text(item['premixedMud'])
          : 'Premixed Mud';
      totals[label] = (totals[label] ?? 0) + _number(item['costOfLostPreTax']);
    }

    return totals.map((key, value) => MapEntry(key, _round2(value)));
  }

  List<String> _orderedKeys(
    Map<String, double> Function(DailyCostHistoryRow row) getter,
  ) {
    final totals = <String, double>{};
    for (final row in rows) {
      final items = getter(row);
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

  double _sum(Iterable<double> values) =>
      values.fold<double>(0, (sum, value) => sum + value);

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _round2(double value) => double.parse(value.toStringAsFixed(2));

  String _text(dynamic value) => value?.toString().trim() ?? '';
}

class DailyCostHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final double md;
  final Map<String, double> productItems;
  final Map<String, double> premixedMudItems;
  final Map<String, double> packageItems;
  final Map<String, double> serviceItems;
  final Map<String, double> engineeringItems;
  final double productTotal;
  final double premixedMudTotal;
  final double packageTotal;
  final double serviceTotal;
  final double engineeringTotal;

  const DailyCostHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.md,
    required this.productItems,
    required this.premixedMudItems,
    required this.packageItems,
    required this.serviceItems,
    required this.engineeringItems,
    required this.productTotal,
    required this.premixedMudTotal,
    required this.packageTotal,
    required this.serviceTotal,
    required this.engineeringTotal,
  });

  double get total =>
      productTotal +
      premixedMudTotal +
      packageTotal +
      serviceTotal +
      engineeringTotal;
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
