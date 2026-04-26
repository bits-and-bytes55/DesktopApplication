import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/model/ug_inventory_product_model.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapCostDistController extends GetxController {
  final InventorySnapshotController _inventoryController;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;
  final ReportApiService _reportApi;
  final AuthRepository _authRepository;

  RecapCostDistController({
    InventorySnapshotController? inventoryController,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
    ReportApiService? reportApi,
    AuthRepository? authRepository,
  }) : _inventoryController =
           inventoryController ?? InventorySnapshotController(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext,
       _reportApi = reportApi ?? ReportApiService(),
       _authRepository = authRepository ?? AuthRepository();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;

  final items = <Map<String, dynamic>>[].obs;
  final summary = <String, dynamic>{}.obs;
  final reportRows = <ReportManagerRow>[].obs;
  final productCatalog = <ProductInventoryModel>[].obs;
  final receiveMudRows = <Map<String, dynamic>>[].obs;
  final returnLostRows = <Map<String, dynamic>>[].obs;

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
    errorMessage.value = '';
    emptyMessage.value = '';

    final wellId = currentBackendWellId.trim();
    if (wellId.isEmpty) {
      _clearAll();
      emptyMessage.value = 'Select a well first to open Cost Distribution.';
      return;
    }

    isLoading.value = true;

    try {
      final inventoryResult = await _inventoryController.getInventorySnapshot(
        wellId: wellId,
      );
      if (inventoryResult['success'] != true) {
        throw Exception(
          inventoryResult['message'] ?? 'Failed to load cost distribution',
        );
      }

      final fetchedItems =
          (inventoryResult['items'] as List<dynamic>? ?? const [])
              .map((entry) => Map<String, dynamic>.from(entry as Map))
              .toList(growable: false);
      final fetchedSummary = Map<String, dynamic>.from(
        inventoryResult['summary'] as Map? ?? const <String, dynamic>{},
      );

      final history = await _reportApi.fetchReportManagerRows(wellId);
      final products = await _loadProductsSafe(wellId);
      final receives = await _loadReceiveMudRowsSafe(wellId);
      final returns = await _loadReturnLostRowsSafe(wellId);

      items.assignAll(fetchedItems);
      summary.assignAll(fetchedSummary);
      reportRows.assignAll(history);
      productCatalog.assignAll(products);
      receiveMudRows.assignAll(receives);
      returnLostRows.assignAll(returns);

      if (fetchedItems.isEmpty &&
          receives.isEmpty &&
          returns.isEmpty &&
          history.isEmpty) {
        emptyMessage.value =
            inventoryResult['message']?.toString().trim().isNotEmpty == true
            ? inventoryResult['message'].toString()
            : 'No cost distribution data is available for the selected report.';
      }
    } catch (error) {
      _clearAll();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  String get selectedWellName =>
      _padWellController.selectedWell?.displayName ?? '';

  String get selectedReportLabel {
    final report = _reportContext.selectedReport;
    if (report == null) return '';
    final userNo = report.userReportNo.trim();
    if (userNo.isNotEmpty) return userNo;
    final reportNo = report.reportNo.trim();
    if (reportNo.isNotEmpty) return reportNo;
    return '';
  }

  double get subtotal => _number(summary['subtotal']) > 0
      ? _number(summary['subtotal'])
      : items.fold<double>(0, (sum, item) => sum + _number(item['subtotal']));

  double get taxRate => _number(summary['taxRate']);
  double get taxAmount => _number(summary['taxAmount']);
  double get dailyTotal => _number(summary['dailyTotal']);
  double get prevTotal => _number(summary['prevTotal']);
  double get cumTotal => _number(summary['cumTotal']);
  double get intervalTotal => _number(summary['intervalTotal']);
  double get stockBalance => _number(summary['stockBalance']);
  double get bulkTankSetupFee => _number(summary['bulkTankSetupFee']);

  double get productTotal => _categoryTotal('Product');
  double get packageTotal => _categoryTotal('Package');
  double get serviceTotal => _categoryTotal('Service');
  double get engineeringTotal => _categoryTotal('Engineering');
  double get premixedMudTotal =>
      _premixedEntries.fold<double>(0, (sum, entry) => sum + entry.amount);

  double get reportSubtotal =>
      productTotal +
      premixedMudTotal +
      packageTotal +
      serviceTotal +
      engineeringTotal;

  double get reportTotalCost => reportSubtotal + taxAmount;

  bool get hasLiveData =>
      items.isNotEmpty ||
      receiveMudRows.isNotEmpty ||
      returnLostRows.isNotEmpty ||
      reportRows.isNotEmpty;

  ReportManagerRow? get selectedHistoryRow {
    final rows = visibleReportRows;
    if (rows.isEmpty) return null;
    return rows.last;
  }

  ReportManagerRow? get previousHistoryRow {
    final rows = visibleReportRows;
    if (rows.length < 2) return null;
    return rows[rows.length - 2];
  }

  List<ReportManagerRow> get visibleReportRows {
    final rows = [...reportRows];
    if (rows.isEmpty) return const <ReportManagerRow>[];

    final selectedId = _reportContext.selectedReportId.value.trim();
    if (selectedId.isEmpty) return rows;

    final selectedIndex = rows.indexWhere((row) => row.reportId == selectedId);
    if (selectedIndex < 0) return rows;
    return rows.sublist(0, selectedIndex + 1);
  }

  double get totalDepth => _positiveOrZero(selectedHistoryRow?.md ?? 0);

  int get reportDayCount => visibleReportRows.length;

  double get selectedFootage {
    final currentMd = selectedHistoryRow?.md ?? 0;
    final previousMd = previousHistoryRow?.md ?? 0;
    final delta = (currentMd - previousMd).abs();
    if (delta > 0) return delta;

    final rows = visibleReportRows;
    if (rows.length > 1) {
      final minMd = rows.map((row) => row.md).reduce(math.min);
      final maxMd = rows.map((row) => row.md).reduce(math.max);
      final span = (maxMd - minMd).abs();
      if (span > 0) return span;
    }

    return _positiveOrZero(currentMd);
  }

  double get avgCostPerUnitLength =>
      selectedFootage > 0 ? reportTotalCost / selectedFootage : 0;

  double get avgDailyCost =>
      reportDayCount > 0 ? reportTotalCost / reportDayCount : 0;

  double get dailyFootage =>
      reportDayCount > 0 ? selectedFootage / reportDayCount : 0;

  List<CostDistSlice> get productSlices =>
      _buildItemSlices('Product', shareWithinCategory: true, limit: 10);

  List<CostDistSlice> get packageSlices =>
      _buildItemSlices('Package', shareWithinCategory: true, limit: 10);

  List<CostDistSlice> get serviceSlices =>
      _buildItemSlices('Service', shareWithinCategory: true, limit: 10);

  List<CostDistSlice> get engineeringSlices =>
      _buildItemSlices('Engineering', shareWithinCategory: true, limit: 10);

  List<CostDistSlice> get groupSlices => _buildCategorySlices(limit: 10);

  List<CostDistSlice> get allCategorySlices => _buildCategorySlices();

  List<Map<String, dynamic>> get compactRows {
    final rows = [...items];
    rows.sort((left, right) {
      final categoryCompare = _categoryRank(
        left['category'],
      ).compareTo(_categoryRank(right['category']));
      if (categoryCompare != 0) return categoryCompare;

      final leftName = _text(left['itemName']).toLowerCase();
      final rightName = _text(right['itemName']).toLowerCase();
      return leftName.compareTo(rightName);
    });
    return rows;
  }

  List<CostDistSummaryDisplayRow> get summaryDisplayRows => [
    CostDistSummaryDisplayRow(
      label: 'Total Depth',
      value: _formatDepth(totalDepth),
      unit: '(ft)',
    ),
    CostDistSummaryDisplayRow(
      label: 'Total Cost',
      value: _formatCost(reportTotalCost),
      unit: '(Kwd)',
    ),
    CostDistSummaryDisplayRow(
      label: 'Days',
      value: '$reportDayCount',
      unit: '',
    ),
    CostDistSummaryDisplayRow(
      label: 'Avg. Cost per Unit Length',
      value: _formatCost(avgCostPerUnitLength),
      unit: '(Kwd/ft)',
    ),
    CostDistSummaryDisplayRow(
      label: 'Avg. Daily Cost',
      value: _formatCost(avgDailyCost),
      unit: '(Kwd/day)',
    ),
    CostDistSummaryDisplayRow(
      label: 'Daily Footage',
      value: _formatDepth(dailyFootage),
      unit: '(ft/day)',
    ),
    CostDistSummaryDisplayRow(
      label: 'Cost - Product',
      value: _formatCost(productTotal),
      unit: '(Kwd)',
    ),
    CostDistSummaryDisplayRow(
      label: 'Cost - Premixed Mud',
      value: _formatCost(premixedMudTotal),
      unit: '(Kwd)',
    ),
    CostDistSummaryDisplayRow(
      label: 'Cost - Package',
      value: _formatCost(packageTotal),
      unit: '(Kwd)',
    ),
    CostDistSummaryDisplayRow(
      label: 'Cost - Service',
      value: _formatCost(serviceTotal),
      unit: '(Kwd)',
    ),
    CostDistSummaryDisplayRow(
      label: 'Cost - Engineering',
      value: _formatCost(engineeringTotal),
      unit: '(Kwd)',
    ),
  ];

  List<CostDistBreakdownRow> get breakdownRows {
    final rows = visibleReportRows;
    if (rows.isEmpty) return const <CostDistBreakdownRow>[];

    final byInterval = <String, _IntervalAggregate>{};
    final order = <String>[];

    for (final row in rows) {
      final key = _intervalKey(row.interval);
      if (!byInterval.containsKey(key)) {
        order.add(key);
        byInterval[key] = _IntervalAggregate(
          label: row.interval.trim().isNotEmpty
              ? row.interval.trim()
              : 'Unspecified',
        );
      }

      final aggregate = byInterval[key]!;
      aggregate.days += 1;
      aggregate.minMd = aggregate.hasDepth
          ? math.min(aggregate.minMd, row.md)
          : row.md;
      aggregate.maxMd = aggregate.hasDepth
          ? math.max(aggregate.maxMd, row.md)
          : row.md;
      aggregate.hasDepth = true;
      if (_text(row.mudType).isNotEmpty) {
        aggregate.mudType = _text(row.mudType);
      }
    }

    final currentKey = _intervalKey(selectedHistoryRow?.interval ?? '');
    if (order.contains(currentKey)) {
      order
        ..remove(currentKey)
        ..insert(0, currentKey);
    }

    return order
        .map((key) {
          final aggregate = byInterval[key]!;
          final isCurrentInterval = key == currentKey;
          final footage = _intervalFootage(aggregate, isCurrentInterval);
          final product = isCurrentInterval ? productTotal : 0.0;
          final premixedMud = isCurrentInterval ? premixedMudTotal : 0.0;
          final package = isCurrentInterval ? packageTotal : 0.0;
          final service = isCurrentInterval ? serviceTotal : 0.0;
          final engineering = isCurrentInterval ? engineeringTotal : 0.0;
          final subtotalValue =
              product + premixedMud + package + service + engineering;
          final tax = isCurrentInterval ? taxAmount : 0.0;
          final cost = subtotalValue + tax;
          final costPerFoot = footage > 0 ? cost / footage : 0.0;
          final costPerDay = aggregate.days > 0 ? cost / aggregate.days : 0.0;
          final footagePerDay = aggregate.days > 0
              ? footage / aggregate.days
              : 0.0;

          return CostDistBreakdownRow(
            tdRange:
                '${_formatDepth(aggregate.minMd)} - ${_formatDepth(aggregate.maxMd)}',
            interval: aggregate.label,
            days: aggregate.days,
            mudType: aggregate.mudType.isNotEmpty ? aggregate.mudType : '-',
            product: product,
            premixedMud: premixedMud,
            package: package,
            service: service,
            engineering: engineering,
            subtotal: subtotalValue,
            tax: tax,
            cost: cost,
            costPerFoot: costPerFoot,
            costPerDay: costPerDay,
            footagePerDay: footagePerDay,
          );
        })
        .toList(growable: false);
  }

  CostDistBreakdownTotal get breakdownTotal => CostDistBreakdownTotal(
    days: reportDayCount,
    product: productTotal,
    premixedMud: premixedMudTotal,
    package: packageTotal,
    service: serviceTotal,
    engineering: engineeringTotal,
    subtotal: reportSubtotal,
    tax: taxAmount,
    cost: reportTotalCost,
    costPerFoot: avgCostPerUnitLength,
    costPerDay: avgDailyCost,
    footagePerDay: dailyFootage,
  );

  List<CostDistTableRow> get productGroupTableRows {
    final groupTotals = <String, double>{};
    final keyToGroup = <String, String>{};
    final productTotals = <String, double>{};

    for (final product in productCatalog) {
      final key = _catalogKey(product);
      keyToGroup[key] = _text(product.group).isNotEmpty
          ? _text(product.group)
          : 'Ungrouped';
      if (_text(product.group).isNotEmpty) {
        groupTotals.putIfAbsent(_text(product.group), () => 0.0);
      }
    }

    for (final item in items.where((item) => _categoryOf(item) == 'Product')) {
      final label = _itemLabel(item);
      final key = _itemKey(item);
      final amount = _number(item['subtotal']);
      final group = keyToGroup[key] ?? 'Ungrouped';

      productTotals[label] = (productTotals[label] ?? 0) + amount;
      groupTotals[group] = (groupTotals[group] ?? 0) + amount;
    }

    if (premixedMudTotal > 0 || !groupTotals.containsKey('Premixed Mud')) {
      groupTotals['Premixed Mud'] = premixedMudTotal;
    }
    for (final entry in _premixedEntries) {
      productTotals[entry.label] =
          (productTotals[entry.label] ?? 0) + entry.amount;
    }

    final base = groupTotals.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    final groups =
        groupTotals.entries
            .map(
              (entry) => CostDistTableRow(
                label: entry.key,
                amount: entry.value,
                percent: base > 0 ? (entry.value / base) * 100 : 0,
              ),
            )
            .toList(growable: false)
          ..sort(_compareTableRows);

    final products =
        productTotals.entries
            .map(
              (entry) => CostDistTableRow(
                label: entry.key,
                amount: entry.value,
                percent: base > 0 ? (entry.value / base) * 100 : 0,
              ),
            )
            .toList(growable: false)
          ..sort(_compareTableRows);

    final rowCount = math.max(groups.length, products.length);
    return List.generate(rowCount, (index) {
      return CostDistTableRow.paired(
        groupLabel: index < groups.length ? groups[index].label : '',
        groupAmount: index < groups.length ? groups[index].amount : 0,
        groupPercent: index < groups.length ? groups[index].percent : 0,
        productLabel: index < products.length ? products[index].label : '',
        productAmount: index < products.length ? products[index].amount : 0,
        productPercent: index < products.length ? products[index].percent : 0,
      );
    });
  }

  double get productGroupCombinedTotal => productTotal + premixedMudTotal;

  List<CostDistTableRow> get packageTableRows =>
      _buildCategoryTableRows('Package');

  List<CostDistTableRow> get serviceTableRows =>
      _buildCategoryTableRows('Service');

  List<CostDistTableRow> get engineeringTableRows =>
      _buildCategoryTableRows('Engineering');

  List<CostDistTableRow> get allCategoryTableRows {
    final rows = [
      CostDistTableRow(
        label: 'Premixed Mud',
        amount: premixedMudTotal,
        percent: 0,
      ),
      CostDistTableRow(
        label: 'Engineering',
        amount: engineeringTotal,
        percent: 0,
      ),
      CostDistTableRow(label: 'Product', amount: productTotal, percent: 0),
      CostDistTableRow(label: 'Package', amount: packageTotal, percent: 0),
      CostDistTableRow(label: 'Service', amount: serviceTotal, percent: 0),
    ];

    final base = rows.fold<double>(0, (sum, row) => sum + row.amount);
    final output =
        rows
            .map(
              (row) => CostDistTableRow(
                label: row.label,
                amount: row.amount,
                percent: base > 0 ? (row.amount / base) * 100 : 0,
              ),
            )
            .toList(growable: false)
          ..sort(_compareTableRows);

    return output;
  }

  Future<List<ProductInventoryModel>> _loadProductsSafe(String wellId) async {
    try {
      return await InventoryProductsService.fetchProducts(wellId);
    } catch (_) {
      return const <ProductInventoryModel>[];
    }
  }

  Future<List<Map<String, dynamic>>> _loadReceiveMudRowsSafe(
    String wellId,
  ) async {
    try {
      final response = await _authRepository.getReceiveMudList(wellId);
      if (response['success'] != true) return const <Map<String, dynamic>>[];
      return _extractApiList(response['data']);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> _loadReturnLostRowsSafe(
    String wellId,
  ) async {
    try {
      final response = await _authRepository.getReturnLostMudList(wellId);
      if (response['success'] != true) return const <Map<String, dynamic>>[];
      return _extractApiList(response['data']);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  List<Map<String, dynamic>> _extractApiList(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    }
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final data = map['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
      }
    }
    return const <Map<String, dynamic>>[];
  }

  List<_PremixedCostEntry> get _premixedEntries {
    final totals = <String, double>{};

    for (final row in receiveMudRows) {
      final label = _text(row['premixedMud']).isNotEmpty
          ? _text(row['premixedMud'])
          : 'Premixed Mud';
      final volume = _number(row['netVolume']) > 0
          ? _number(row['netVolume'])
          : _number(row['volume']);
      final fee = _number(row['leasingFee']);
      final amount = volume * fee;
      totals[label] = (totals[label] ?? 0) + amount;
    }

    for (final row in returnLostRows) {
      final label = _text(row['premixedMud']).isNotEmpty
          ? _text(row['premixedMud'])
          : 'Premixed Mud';
      final amount = _number(row['costOfLostPreTax']);
      totals[label] = (totals[label] ?? 0) + amount;
    }

    return totals.entries
        .map(
          (entry) => _PremixedCostEntry(label: entry.key, amount: entry.value),
        )
        .toList(growable: false)
      ..sort((left, right) => right.amount.compareTo(left.amount));
  }

  List<CostDistTableRow> _buildCategoryTableRows(String category) {
    final rowsForCategory = items.where(
      (item) => _categoryOf(item) == category,
    );
    final totals = <String, double>{};

    for (final item in rowsForCategory) {
      final label = _itemLabel(item);
      totals[label] = (totals[label] ?? 0) + _number(item['subtotal']);
    }

    final totalForCategory = totals.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    final output =
        totals.entries
            .map(
              (entry) => CostDistTableRow(
                label: entry.key,
                amount: entry.value,
                percent: totalForCategory > 0
                    ? (entry.value / totalForCategory) * 100
                    : 0,
              ),
            )
            .toList(growable: false)
          ..sort(_compareTableRows);

    return output;
  }

  List<CostDistSlice> _buildItemSlices(
    String category, {
    bool shareWithinCategory = false,
    int? limit,
  }) {
    final filtered = items.where((item) => _categoryOf(item) == category);
    final totalsByItem = <String, double>{};

    for (final item in filtered) {
      final label = _itemLabel(item);
      totalsByItem[label] =
          (totalsByItem[label] ?? 0) + _number(item['subtotal']);
    }

    final baseTotal = shareWithinCategory
        ? totalsByItem.values.fold<double>(0, (sum, value) => sum + value)
        : subtotal;

    var output =
        totalsByItem.entries
            .map(
              (entry) => CostDistSlice(
                label: entry.key,
                amount: entry.value,
                percent: baseTotal <= 0 ? 0 : (entry.value / baseTotal) * 100,
              ),
            )
            .where((entry) => entry.amount > 0)
            .toList(growable: false)
          ..sort((left, right) => right.amount.compareTo(left.amount));

    if (limit != null && output.length > limit) {
      output = output.take(limit).toList(growable: false);
    }
    return output;
  }

  List<CostDistSlice> _buildCategorySlices({int? limit}) {
    final totals = <String, double>{};
    for (final item in items) {
      final category = _categoryOf(item).isNotEmpty
          ? _categoryOf(item)
          : 'Unknown';
      totals[category] = (totals[category] ?? 0) + _number(item['subtotal']);
    }

    var output =
        totals.entries
            .map(
              (entry) => CostDistSlice(
                label: entry.key,
                amount: entry.value,
                percent: subtotal <= 0 ? 0 : (entry.value / subtotal) * 100,
              ),
            )
            .where((entry) => entry.amount > 0)
            .toList(growable: false)
          ..sort((left, right) => right.amount.compareTo(left.amount));

    if (limit != null && output.length > limit) {
      output = output.take(limit).toList(growable: false);
    }
    return output;
  }

  double _categoryTotal(String category) {
    return items
        .where((item) => _categoryOf(item) == category)
        .fold<double>(0, (sum, item) => sum + _number(item['subtotal']));
  }

  String _categoryOf(Map<String, dynamic> item) => _text(item['category']);

  String _itemLabel(Map<String, dynamic> item) {
    final label = _text(item['itemName']);
    return label.isNotEmpty ? label : 'Unnamed';
  }

  String _itemKey(Map<String, dynamic> item) =>
      _keyFromCodeOrName(_text(item['code']), _itemLabel(item));

  String _catalogKey(ProductInventoryModel item) =>
      _keyFromCodeOrName(_text(item.code), _text(item.product));

  int _categoryRank(dynamic value) {
    switch (_text(value).toLowerCase()) {
      case 'product':
        return 0;
      case 'package':
        return 1;
      case 'service':
        return 2;
      case 'engineering':
        return 3;
      default:
        return 9;
    }
  }

  int _compareTableRows(CostDistTableRow left, CostDistTableRow right) {
    final byAmount = right.amount.compareTo(left.amount);
    if (byAmount != 0) return byAmount;
    return left.label.toLowerCase().compareTo(right.label.toLowerCase());
  }

  String _intervalKey(String value) {
    final text = _text(value);
    return text.isNotEmpty ? text.toLowerCase() : 'unspecified';
  }

  double _intervalFootage(
    _IntervalAggregate aggregate,
    bool isCurrentInterval,
  ) {
    final span = (aggregate.maxMd - aggregate.minMd).abs();
    if (span > 0) return span;
    if (isCurrentInterval) return selectedFootage;
    return 0;
  }

  String _formatCost(double value) => value.toStringAsFixed(3);

  String _formatDepth(double value) => value.toStringAsFixed(1);

  double _positiveOrZero(double value) => value > 0 ? value : 0;

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';

  void _clearAll() {
    items.clear();
    summary.clear();
    reportRows.clear();
    productCatalog.clear();
    receiveMudRows.clear();
    returnLostRows.clear();
  }
}

class CostDistSlice {
  final String label;
  final double amount;
  final double percent;

  const CostDistSlice({
    required this.label,
    required this.amount,
    required this.percent,
  });
}

class CostDistSummaryDisplayRow {
  final String label;
  final String value;
  final String unit;

  const CostDistSummaryDisplayRow({
    required this.label,
    required this.value,
    required this.unit,
  });
}

class CostDistBreakdownRow {
  final String tdRange;
  final String interval;
  final int days;
  final String mudType;
  final double product;
  final double premixedMud;
  final double package;
  final double service;
  final double engineering;
  final double subtotal;
  final double tax;
  final double cost;
  final double costPerFoot;
  final double costPerDay;
  final double footagePerDay;

  const CostDistBreakdownRow({
    required this.tdRange,
    required this.interval,
    required this.days,
    required this.mudType,
    required this.product,
    required this.premixedMud,
    required this.package,
    required this.service,
    required this.engineering,
    required this.subtotal,
    required this.tax,
    required this.cost,
    required this.costPerFoot,
    required this.costPerDay,
    required this.footagePerDay,
  });
}

class CostDistBreakdownTotal {
  final int days;
  final double product;
  final double premixedMud;
  final double package;
  final double service;
  final double engineering;
  final double subtotal;
  final double tax;
  final double cost;
  final double costPerFoot;
  final double costPerDay;
  final double footagePerDay;

  const CostDistBreakdownTotal({
    required this.days,
    required this.product,
    required this.premixedMud,
    required this.package,
    required this.service,
    required this.engineering,
    required this.subtotal,
    required this.tax,
    required this.cost,
    required this.costPerFoot,
    required this.costPerDay,
    required this.footagePerDay,
  });
}

class CostDistTableRow {
  final String label;
  final double amount;
  final double percent;

  final String groupLabel;
  final double groupAmount;
  final double groupPercent;
  final String productLabel;
  final double productAmount;
  final double productPercent;

  const CostDistTableRow({
    required this.label,
    required this.amount,
    required this.percent,
  }) : groupLabel = '',
       groupAmount = 0,
       groupPercent = 0,
       productLabel = '',
       productAmount = 0,
       productPercent = 0;

  const CostDistTableRow.paired({
    required this.groupLabel,
    required this.groupAmount,
    required this.groupPercent,
    required this.productLabel,
    required this.productAmount,
    required this.productPercent,
  }) : label = '',
       amount = 0,
       percent = 0;
}

class _PremixedCostEntry {
  final String label;
  final double amount;

  const _PremixedCostEntry({required this.label, required this.amount});
}

class _IntervalAggregate {
  final String label;
  int days = 0;
  bool hasDepth = false;
  double minMd = 0;
  double maxMd = 0;
  String mudType = '';

  _IntervalAggregate({required this.label});
}

String _keyFromCodeOrName(String code, String itemName) {
  final cleanCode = code.trim().toLowerCase();
  if (cleanCode.isNotEmpty) return 'code:$cleanCode';
  return 'name:${itemName.trim().toLowerCase()}';
}
