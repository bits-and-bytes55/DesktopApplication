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

class RecapConcentrationController extends GetxController {
  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapConcentrationController({
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
  final rows = <ConcentrationHistoryRow>[].obs;
  final products = <ConcentrationProductMeta>[].obs;
  final selectedProductKey = ''.obs;
  final selectedSystem = 'Active System'.obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

  List<String> get systems => const ['Active System'];

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
      emptyMessage.value = 'Select a well first to open Concentration recap.';
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
      final rawRows = await Future.wait(
        ordered.map((summary) => _loadRawReport(wellId, summary)),
      );
      final ugInventory = await _fetchUgInventory(wellId);

      var trackedProducts = _buildTrackedProducts(ugInventory);
      if (trackedProducts.isEmpty) {
        trackedProducts = _buildFallbackProducts(rawRows);
      }

      if (trackedProducts.isEmpty) {
        rows.clear();
        products.clear();
        selectedProductKey.value = '';
        emptyMessage.value =
            'No saved concentration-enabled products are available for the selected well.';
        return;
      }

      final historyRows = <ConcentrationHistoryRow>[];
      var previousEndVolume = 0.0;

      for (final rawRow in rawRows) {
        final endVolume = rawRow.endVolume > 0
            ? rawRow.endVolume
            : (previousEndVolume > 0 ? previousEndVolume : 0.0);
        final startVolume = previousEndVolume > 0 ? previousEndVolume : endVolume;

        final entries = trackedProducts.map((product) {
          final inventory = rawRow.entryFor(product.key);
          final startQuantity = inventory?.initial ?? 0.0;
          final endQuantity = inventory?.finalValue ?? 0.0;

          return ConcentrationProductEntry(
            key: product.key,
            itemName: product.itemName,
            code: product.code,
            concentrationUnit: product.concentrationUnit,
            startQuantity: startQuantity,
            endQuantity: endQuantity,
            startConcentration: _calculateConcentration(
              product,
              quantity: startQuantity,
              systemVolume: startVolume,
            ),
            endConcentration: _calculateConcentration(
              product,
              quantity: endQuantity,
              systemVolume: endVolume,
            ),
          );
        }).toList(growable: false);

        historyRows.add(
          ConcentrationHistoryRow(
            reportId: rawRow.summary.reportId,
            reportLabel: rawRow.summary.reportLabel,
            reportDate: rawRow.summary.reportDate,
            createdAt: rawRow.summary.createdAt,
            md: rawRow.summary.md,
            systemName: selectedSystem.value,
            startVolume: startVolume,
            endVolume: endVolume,
            entries: entries,
          ),
        );

        if (endVolume > 0) {
          previousEndVolume = endVolume;
        }
      }

      final catalog = _buildCatalog(historyRows, trackedProducts);
      if (catalog.isEmpty) {
        rows.assignAll(historyRows);
        products.clear();
        selectedProductKey.value = '';
        emptyMessage.value =
            'Concentration products are configured, but no live concentration history is available yet.';
        return;
      }

      rows.assignAll(historyRows);
      products.assignAll(catalog);
      _syncSelectedProduct(catalog);
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
    if (products.any((item) => item.key == key.trim())) {
      selectedProductKey.value = key.trim();
    }
  }

  void selectSystem(String value) {
    if (systems.contains(value)) {
      selectedSystem.value = value;
    }
  }

  ConcentrationProductMeta? get selectedProduct {
    final key = selectedProductKey.value.trim();
    if (key.isEmpty) return products.isEmpty ? null : products.first;
    for (final product in products) {
      if (product.key == key) return product;
    }
    return products.isEmpty ? null : products.first;
  }

  String get selectedProductAxisLabel {
    final product = selectedProduct;
    if (product == null) return 'Concentration';
    return '${product.itemName}\n(${product.concentrationUnit})';
  }

  List<double> endSeries() {
    final key = selectedProduct?.key ?? '';
    return rows
        .map((row) => row.entryFor(key)?.endConcentration ?? 0)
        .toList(growable: false);
  }

  List<ConcentrationTableRow> tableRows() {
    return rows
        .map(
          (row) => ConcentrationTableRow(
            reportId: row.reportId,
            reportLabel: row.reportLabel,
            reportDate: row.reportDate,
            createdAt: row.createdAt,
            md: row.md,
            valuesByProductKey: {
              for (final entry in row.entries) entry.key: entry.endConcentration,
            },
          ),
        )
        .toList(growable: false);
  }

  Future<_RawConcentrationReport> _loadRawReport(
    String wellId,
    ReportManagerRow summary,
  ) async {
    final responses = await Future.wait<dynamic>([
      _fetchInventoryRows(wellId: wellId, reportId: summary.reportId),
      _fetchVolumePayload(wellId: wellId, reportId: summary.reportId),
    ]);

    final inventoryRows = responses[0] as List<Map<String, dynamic>>;
    final volumePayload = _asMap(responses[1]);
    final volumeName = _asMap(volumePayload['volumeName']);
    final endVolume = _resolveEndVolume(volumeName);

    final entries = inventoryRows
        .where((item) => _normalizeText(item['category']) == 'product')
        .map((item) => _InventoryProductSnapshot.fromJson(item))
        .where((item) => item.itemName.isNotEmpty)
        .toList(growable: false);

    return _RawConcentrationReport(
      summary: summary,
      endVolume: endVolume,
      entries: entries,
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
          '${generateUri.origin}: ${decoded['message'] ?? 'Failed to generate concentration snapshot'}',
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
        'Concentration recap backend routes are not available. '
        'Tried: ${failures.join(' | ')}',
      );
    }

    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> _fetchVolumePayload({
    required String wellId,
    required String reportId,
  }) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse('${baseUrl}volume-name/$wellId').replace(
        queryParameters: {
          if (reportId.isNotEmpty) 'reportId': reportId,
        },
      );

      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));
        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if (response.statusCode == 200 && decoded['success'] == true) {
          return _asMap(decoded['data']);
        }

        failures.add(
          '${uri.origin}: ${decoded['message'] ?? 'Failed to load volume history'}',
        );
      } on TimeoutException {
        failures.add('${uri.origin}: request timed out');
      } on FormatException catch (error) {
        failures.add('${uri.origin}: ${error.message}');
      } catch (error) {
        failures.add('${uri.origin}: ${_cleanError(error)}');
      }
    }

    throw Exception(
      'Concentration recap volume routes are not available. '
      'Tried: ${failures.join(' | ')}',
    );
  }

  Future<Map<String, dynamic>> _fetchUgInventory(String wellId) async {
    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse('${baseUrl}ug-inventory/$wellId');

      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));
        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if (response.statusCode == 200 && decoded['success'] == true) {
          return _asMap(decoded['data']);
        }
      } catch (_) {
        continue;
      }
    }

    return const <String, dynamic>{};
  }

  List<_TrackedConcentrationProduct> _buildTrackedProducts(
    Map<String, dynamic> ugInventory,
  ) {
    final products = ugInventory['products'];
    if (products is! List) return const <_TrackedConcentrationProduct>[];

    final tracked = <_TrackedConcentrationProduct>[];
    for (final raw in products.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      if (!_boolValue(item['calculate']) && !_boolValue(item['plot'])) {
        continue;
      }

      final product = _buildTrackedProduct(
        itemName: _text(item['product']),
        code: _text(item['code']),
        packUnit: _text(item['unit']),
      );
      if (product != null) {
        tracked.add(product);
      }
    }

    tracked.sort(
      (left, right) => left.itemName.toLowerCase().compareTo(
        right.itemName.toLowerCase(),
      ),
    );
    return tracked;
  }

  List<_TrackedConcentrationProduct> _buildFallbackProducts(
    List<_RawConcentrationReport> rawRows,
  ) {
    final byKey = <String, _TrackedConcentrationProduct>{};

    for (final rawRow in rawRows) {
      for (final entry in rawRow.entries) {
        if (entry.initial <= 0 && entry.finalValue <= 0) {
          continue;
        }

        final product = _buildTrackedProduct(
          itemName: entry.itemName,
          code: entry.code,
          packUnit: entry.packUnit,
        );
        if (product == null) continue;
        byKey.putIfAbsent(product.key, () => product);
      }
    }

    final list = byKey.values.toList()
      ..sort(
        (left, right) => left.itemName.toLowerCase().compareTo(
          right.itemName.toLowerCase(),
        ),
      );
    return list;
  }

  _TrackedConcentrationProduct? _buildTrackedProduct({
    required String itemName,
    required String code,
    required String packUnit,
  }) {
    final basis = _basisFromPackUnit(packUnit);
    if (basis == null) return null;

    return _TrackedConcentrationProduct(
      key: _keyFromCodeOrName(code, itemName),
      itemName: itemName,
      code: code,
      packUnit: packUnit,
      factorPerPack: basis.factorPerPack,
      concentrationUnit: basis.concentrationUnit,
    );
  }

  List<ConcentrationProductMeta> _buildCatalog(
    List<ConcentrationHistoryRow> historyRows,
    List<_TrackedConcentrationProduct> trackedProducts,
  ) {
    final maxByKey = <String, double>{};
    final hasQuantityByKey = <String, bool>{};

    for (final row in historyRows) {
      for (final entry in row.entries) {
        maxByKey[entry.key] = math.max(
          maxByKey[entry.key] ?? 0.0,
          math.max(entry.startConcentration, entry.endConcentration),
        ).toDouble();
        if (entry.startQuantity > 0 || entry.endQuantity > 0) {
          hasQuantityByKey[entry.key] = true;
        }
      }
    }

    final catalog = <ConcentrationProductMeta>[];
    for (final product in trackedProducts) {
      if (hasQuantityByKey[product.key] != true) continue;
      catalog.add(
        ConcentrationProductMeta(
          key: product.key,
          itemName: product.itemName,
          code: product.code,
          packUnit: product.packUnit,
          concentrationUnit: product.concentrationUnit,
          maxConcentration: maxByKey[product.key] ?? 0,
        ),
      );
    }

    catalog.sort((left, right) {
      final byMax = right.maxConcentration.compareTo(left.maxConcentration);
      if (byMax != 0) return byMax;
      return left.itemName.toLowerCase().compareTo(right.itemName.toLowerCase());
    });
    return catalog;
  }

  double _calculateConcentration(
    _TrackedConcentrationProduct product, {
    required double quantity,
    required double systemVolume,
  }) {
    if (quantity <= 0 || systemVolume <= 0 || product.factorPerPack <= 0) {
      return 0;
    }
    return _round2((quantity * product.factorPerPack) / systemVolume);
  }

  _ConcentrationBasis? _basisFromPackUnit(String unit) {
    final normalized = _normalizeText(unit);
    final amount = _packSize(unit);
    if (amount <= 0) return null;

    if (normalized.contains('ton')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 2000,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('kg')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 2.20462,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('lb')) {
      return _ConcentrationBasis(
        factorPerPack: amount,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('gal')) {
      return _ConcentrationBasis(
        factorPerPack: amount,
        concentrationUnit: 'gal/bbl',
      );
    }
    if (normalized.contains(' bbl') || normalized.startsWith('bbl')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 42,
        concentrationUnit: 'gal/bbl',
      );
    }
    if (normalized.contains(' m3') || normalized.startsWith('m3')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 264.172,
        concentrationUnit: 'gal/bbl',
      );
    }
    if (normalized.contains('ml')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 0.000264172,
        concentrationUnit: 'gal/bbl',
      );
    }
    if (normalized.contains(' l') || normalized.startsWith('l')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 0.264172,
        concentrationUnit: 'gal/bbl',
      );
    }
    return null;
  }

  double _packSize(String unit) {
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(unit);
    if (match == null) return 1;
    return double.tryParse(match.group(0) ?? '') ?? 1;
  }

  double _resolveEndVolume(Map<String, dynamic> volumeName) {
    final endVol = _number(volumeName['endVol']);
    if (endVol > 0) return endVol;
    final activeSystem = _number(volumeName['activeSystem']);
    if (activeSystem > 0) return activeSystem;
    return 0;
  }

  void _syncSelectedProduct(List<ConcentrationProductMeta> catalog) {
    final current = selectedProductKey.value.trim();
    if (current.isNotEmpty && catalog.any((item) => item.key == current)) {
      return;
    }
    selectedProductKey.value = catalog.isEmpty ? '' : catalog.first.key;
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
    final isJson =
        (contentType ?? '').toLowerCase().contains('application/json');
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

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

class ConcentrationHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final String systemName;
  final double startVolume;
  final double endVolume;
  final List<ConcentrationProductEntry> entries;

  const ConcentrationHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.systemName,
    required this.startVolume,
    required this.endVolume,
    required this.entries,
  });

  ConcentrationProductEntry? entryFor(String key) {
    if (key.trim().isEmpty) return null;
    for (final entry in entries) {
      if (entry.key == key) return entry;
    }
    return null;
  }
}

class ConcentrationProductEntry {
  final String key;
  final String itemName;
  final String code;
  final String concentrationUnit;
  final double startQuantity;
  final double endQuantity;
  final double startConcentration;
  final double endConcentration;

  const ConcentrationProductEntry({
    required this.key,
    required this.itemName,
    required this.code,
    required this.concentrationUnit,
    required this.startQuantity,
    required this.endQuantity,
    required this.startConcentration,
    required this.endConcentration,
  });
}

class ConcentrationProductMeta {
  final String key;
  final String itemName;
  final String code;
  final String packUnit;
  final String concentrationUnit;
  final double maxConcentration;

  const ConcentrationProductMeta({
    required this.key,
    required this.itemName,
    required this.code,
    required this.packUnit,
    required this.concentrationUnit,
    required this.maxConcentration,
  });
}

class ConcentrationTableRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final Map<String, double> valuesByProductKey;

  const ConcentrationTableRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.valuesByProductKey,
  });
}

class _RawConcentrationReport {
  final ReportManagerRow summary;
  final double endVolume;
  final List<_InventoryProductSnapshot> entries;

  const _RawConcentrationReport({
    required this.summary,
    required this.endVolume,
    required this.entries,
  });

  _InventoryProductSnapshot? entryFor(String key) {
    if (key.trim().isEmpty) return null;
    for (final entry in entries) {
      if (entry.key == key) return entry;
    }
    return null;
  }
}

class _InventoryProductSnapshot {
  final String key;
  final String itemName;
  final String code;
  final String packUnit;
  final double initial;
  final double finalValue;

  const _InventoryProductSnapshot({
    required this.key,
    required this.itemName,
    required this.code,
    required this.packUnit,
    required this.initial,
    required this.finalValue,
  });

  factory _InventoryProductSnapshot.fromJson(Map<String, dynamic> json) {
    final itemName = _text(json['itemName']);
    final code = _text(json['code']);
    return _InventoryProductSnapshot(
      key: _keyFromCodeOrName(code, itemName),
      itemName: itemName,
      code: code,
      packUnit: _text(json['unit']),
      initial: _number(json['initial']),
      finalValue: _number(json['final']),
    );
  }
}

class _TrackedConcentrationProduct {
  final String key;
  final String itemName;
  final String code;
  final String packUnit;
  final double factorPerPack;
  final String concentrationUnit;

  const _TrackedConcentrationProduct({
    required this.key,
    required this.itemName,
    required this.code,
    required this.packUnit,
    required this.factorPerPack,
    required this.concentrationUnit,
  });
}

class _ConcentrationBasis {
  final double factorPerPack;
  final String concentrationUnit;

  const _ConcentrationBasis({
    required this.factorPerPack,
    required this.concentrationUnit,
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

double _round2(double value) => double.parse(value.toStringAsFixed(2));

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
