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

class RecapUsageController extends GetxController {
  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapUsageController({
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
  final rows = <UsageHistoryRow>[].obs;
  final products = <UsageProductMeta>[].obs;
  final selectedProductKey = ''.obs;

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
      products.clear();
      selectedProductKey.value = '';
      emptyMessage.value = 'Select a well first to open Usage recap.';
      return;
    }

    isLoading.value = true;

    try {
      final summaries = await _reportApi.fetchReportManagerRows(wellId);
      if (summaries.isEmpty) {
        rows.clear();
        products.clear();
        selectedProductKey.value = '';
        emptyMessage.value = 'No reports are available for the selected well.';
        return;
      }

      final ordered = [...summaries]..sort(_compareRowsOldestFirst);
      final historyRows = await Future.wait(
        ordered.map((summary) => _buildHistoryRow(wellId, summary)),
      );

      rows.assignAll(historyRows);

      final catalog = _buildProductCatalog(historyRows);
      products.assignAll(catalog);

      if (catalog.isEmpty) {
        selectedProductKey.value = '';
        emptyMessage.value =
            'No saved product-usage history is available for the selected well.';
      } else if (catalog.every((item) => item.maxValue <= 0)) {
        emptyMessage.value =
            'Product inventory exists, but no received/used/final history is available yet.';
        _syncSelectedProduct(catalog);
      } else {
        _syncSelectedProduct(catalog);
      }
    } catch (error) {
      rows.clear();
      products.clear();
      selectedProductKey.value = '';
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void selectProduct(String key) {
    if (key.trim().isEmpty) return;
    selectedProductKey.value = key.trim();
  }

  UsageProductMeta? get selectedProduct {
    final key = selectedProductKey.value.trim();
    if (key.isEmpty) return products.isEmpty ? null : products.first;
    for (final product in products) {
      if (product.key == key) return product;
    }
    return products.isEmpty ? null : products.first;
  }

  String get selectedProductAxisLabel {
    final product = selectedProduct;
    if (product == null) return 'Product Usage';
    if (product.unit.isEmpty) return product.itemName;
    return '${product.itemName}\n(${product.unit})';
  }

  List<double> recSeries() => _seriesFor((entry) => entry?.rec ?? 0);

  List<double> usedSeries() => _seriesFor((entry) => entry?.used ?? 0);

  List<double> finalSeries() => _seriesFor((entry) => entry?.finalValue ?? 0);

  List<UsageDetailRow> selectedProductRows() {
    final key = selectedProduct?.key ?? '';
    return rows
        .map((row) {
          final entry = row.entryFor(key);
          return UsageDetailRow(
            reportId: row.reportId,
            reportLabel: row.reportLabel,
            reportDate: row.reportDate,
            createdAt: row.createdAt,
            md: row.md,
            itemName: selectedProduct?.itemName ?? '',
            unit: selectedProduct?.unit ?? '',
            initial: entry?.initial ?? 0,
            rec: entry?.rec ?? 0,
            ret: entry?.ret ?? 0,
            adj: entry?.adj ?? 0,
            used: entry?.used ?? 0,
            finalValue: entry?.finalValue ?? 0,
            price: entry?.price ?? 0,
            costDollar: entry?.costDollar ?? 0,
            cumulativeRec: entry?.cumulativeRec ?? 0,
            cumulativeRet: entry?.cumulativeRet ?? 0,
            cumulativeUsed: entry?.cumulativeUsed ?? 0,
          );
        })
        .toList(growable: false);
  }

  List<ProductInventoryRow> productInventoryRows() {
    final list = <ProductInventoryRow>[];

    for (final row in rows) {
      for (final entry in row.entries) {
        list.add(
          ProductInventoryRow(
            productKey: entry.key,
            itemName: entry.itemName,
            unit: entry.unit,
            code: entry.code,
            reportId: row.reportId,
            reportLabel: row.reportLabel,
            reportDate: row.reportDate,
            createdAt: row.createdAt,
            md: row.md,
            price: entry.price,
            initial: entry.initial,
            rec: entry.rec,
            ret: entry.ret,
            adj: entry.adj,
            used: entry.used,
            finalValue: entry.finalValue,
            costDollar: entry.costDollar,
            cumulativeRec: entry.cumulativeRec,
            cumulativeRet: entry.cumulativeRet,
            cumulativeUsed: entry.cumulativeUsed,
          ),
        );
      }
    }

    return list;
  }

  Future<UsageHistoryRow> _buildHistoryRow(
    String wellId,
    ReportManagerRow summary,
  ) async {
    final inventoryRows = await _fetchInventoryRows(
      wellId: wellId,
      reportId: summary.reportId,
    );

    final productEntries = inventoryRows
        .where((item) => _normalizeText(item['category']) == 'product')
        .map((item) => UsageProductEntry.fromJson(item))
        .where((item) => item.itemName.isNotEmpty)
        .toList()
      ..sort((left, right) {
        final byName = left.itemName.toLowerCase().compareTo(
          right.itemName.toLowerCase(),
        );
        if (byName != 0) return byName;
        return left.code.toLowerCase().compareTo(right.code.toLowerCase());
      });

    return UsageHistoryRow(
      reportId: summary.reportId,
      reportLabel: summary.reportLabel,
      reportDate: summary.reportDate,
      createdAt: summary.createdAt,
      md: summary.md,
      entries: productEntries,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchInventoryRows({
    required String wellId,
    required String reportId,
  }) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final generateUri = Uri.parse('${baseUrl}inventory/generate').replace(
        queryParameters: {
          'wellId': wellId,
          if (reportId.isNotEmpty) 'reportId': reportId,
        },
      );

      try {
        final response = await http
            .post(generateUri, headers: _headers, body: '{}')
            .timeout(const Duration(seconds: 25));
        final decoded = _decodeObject(
          body: response.body,
          uri: generateUri,
          contentType: response.headers['content-type'],
        );

        if ((response.statusCode == 200 || response.statusCode == 201) &&
            decoded['success'] == true) {
          return _extractList(decoded['data']);
        }

        failures.add(
          '${generateUri.origin}: ${decoded['message'] ?? 'Failed to generate usage snapshot'}',
        );
      } on TimeoutException {
        failures.add('${generateUri.origin}: request timed out');
      } on FormatException catch (error) {
        failures.add('${generateUri.origin}: ${error.message}');
      } catch (error) {
        failures.add('${generateUri.origin}: ${_cleanError(error)}');
      }

      final readUri = Uri.parse('${baseUrl}inventory/').replace(
        queryParameters: {
          'wellId': wellId,
          if (reportId.isNotEmpty) 'reportId': reportId,
        },
      );

      try {
        final response = await http
            .get(readUri, headers: _headers)
            .timeout(const Duration(seconds: 20));
        final decoded = _decodeObject(
          body: response.body,
          uri: readUri,
          contentType: response.headers['content-type'],
        );

        if (response.statusCode == 200 && decoded['success'] == true) {
          return _extractList(decoded['data']);
        }
      } catch (_) {
        continue;
      }
    }

    if (failures.isNotEmpty) {
      throw Exception(
        'Usage recap backend routes are not available. '
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

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final envelope = _asMap(raw);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  List<double> _seriesFor(double Function(UsageProductEntry? entry) selector) {
    final key = selectedProduct?.key ?? '';
    return rows
        .map((row) => selector(row.entryFor(key)))
        .toList(growable: false);
  }

  List<UsageProductMeta> _buildProductCatalog(List<UsageHistoryRow> historyRows) {
    final metaByKey = <String, UsageProductMeta>{};

    for (final row in historyRows) {
      for (final entry in row.entries) {
        final existing = metaByKey[entry.key];
        final candidateMax = math.max(
          entry.rec,
          math.max(entry.used, entry.finalValue),
        );

        if (existing == null) {
          metaByKey[entry.key] = UsageProductMeta(
            key: entry.key,
            itemName: entry.itemName,
            unit: entry.unit,
            code: entry.code,
            maxValue: candidateMax,
          );
        } else {
          metaByKey[entry.key] = existing.copyWith(
            itemName: existing.itemName.isEmpty ? entry.itemName : existing.itemName,
            unit: existing.unit.isEmpty ? entry.unit : existing.unit,
            code: existing.code.isEmpty ? entry.code : existing.code,
            maxValue: math.max(existing.maxValue, candidateMax),
          );
        }
      }
    }

    final list = metaByKey.values.toList()
      ..sort((left, right) {
        final byMax = right.maxValue.compareTo(left.maxValue);
        if (byMax != 0) return byMax;
        return left.itemName.toLowerCase().compareTo(right.itemName.toLowerCase());
      });

    return list;
  }

  void _syncSelectedProduct(List<UsageProductMeta> catalog) {
    final current = selectedProductKey.value.trim();
    if (current.isNotEmpty && catalog.any((item) => item.key == current)) {
      return;
    }

    selectedProductKey.value = catalog.isEmpty ? '' : catalog.first.key;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

class UsageHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final List<UsageProductEntry> entries;

  const UsageHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.entries,
  });

  UsageProductEntry? entryFor(String key) {
    if (key.trim().isEmpty) return null;
    for (final entry in entries) {
      if (entry.key == key) return entry;
    }
    return null;
  }
}

class UsageProductEntry {
  final String key;
  final String itemName;
  final String code;
  final String unit;
  final double price;
  final double cumulativeRec;
  final double cumulativeRet;
  final double cumulativeUsed;
  final double initial;
  final double rec;
  final double ret;
  final double adj;
  final double used;
  final double finalValue;
  final double subtotal;
  final double costDollar;

  const UsageProductEntry({
    required this.key,
    required this.itemName,
    required this.code,
    required this.unit,
    required this.price,
    required this.cumulativeRec,
    required this.cumulativeRet,
    required this.cumulativeUsed,
    required this.initial,
    required this.rec,
    required this.ret,
    required this.adj,
    required this.used,
    required this.finalValue,
    required this.subtotal,
    required this.costDollar,
  });

  factory UsageProductEntry.fromJson(Map<String, dynamic> json) {
    final itemName = _text(json['itemName']);
    final code = _text(json['code']);
    return UsageProductEntry(
      key: _keyFromCodeOrName(code, itemName),
      itemName: itemName,
      code: code,
      unit: _text(json['unit']),
      price: _number(json['price']),
      cumulativeRec: _number(json['cumulativeRec']),
      cumulativeRet: _number(json['cumulativeRet']),
      cumulativeUsed: _number(json['cumulativeUsed']),
      initial: _number(json['initial']),
      rec: _number(json['rec']),
      ret: _number(json['ret']),
      adj: _number(json['adj']),
      used: _number(json['used']),
      finalValue: _number(json['final']),
      subtotal: _number(json['subtotal']),
      costDollar: _number(json['costDollar']),
    );
  }
}

class UsageProductMeta {
  final String key;
  final String itemName;
  final String unit;
  final String code;
  final double maxValue;

  const UsageProductMeta({
    required this.key,
    required this.itemName,
    required this.unit,
    required this.code,
    required this.maxValue,
  });

  UsageProductMeta copyWith({
    String? itemName,
    String? unit,
    String? code,
    double? maxValue,
  }) {
    return UsageProductMeta(
      key: key,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      code: code ?? this.code,
      maxValue: maxValue ?? this.maxValue,
    );
  }
}

class UsageDetailRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final String itemName;
  final String unit;
  final double initial;
  final double rec;
  final double ret;
  final double adj;
  final double used;
  final double finalValue;
  final double price;
  final double costDollar;
  final double cumulativeRec;
  final double cumulativeRet;
  final double cumulativeUsed;

  const UsageDetailRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.itemName,
    required this.unit,
    required this.initial,
    required this.rec,
    required this.ret,
    required this.adj,
    required this.used,
    required this.finalValue,
    required this.price,
    required this.costDollar,
    required this.cumulativeRec,
    required this.cumulativeRet,
    required this.cumulativeUsed,
  });
}

class ProductInventoryRow {
  final String productKey;
  final String itemName;
  final String unit;
  final String code;
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final double price;
  final double initial;
  final double rec;
  final double ret;
  final double adj;
  final double used;
  final double finalValue;
  final double costDollar;
  final double cumulativeRec;
  final double cumulativeRet;
  final double cumulativeUsed;

  const ProductInventoryRow({
    required this.productKey,
    required this.itemName,
    required this.unit,
    required this.code,
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.price,
    required this.initial,
    required this.rec,
    required this.ret,
    required this.adj,
    required this.used,
    required this.finalValue,
    required this.costDollar,
    required this.cumulativeRec,
    required this.cumulativeRet,
    required this.cumulativeUsed,
  });
}

String _keyFromCodeOrName(String code, String itemName) {
  final cleanCode = _normalizeText(code);
  if (cleanCode.isNotEmpty) return 'code:$cleanCode';
  return 'name:${_normalizeText(itemName)}';
}

String _normalizeText(dynamic value) => _text(value).toLowerCase();

String _text(dynamic value) => value?.toString().trim() ?? '';

double _number(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0.0;
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
