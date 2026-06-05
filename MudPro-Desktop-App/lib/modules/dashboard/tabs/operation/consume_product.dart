import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/consume_product_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/consume_product_save_bridge.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/recieve_product_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/return_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'operation_desktop_ui.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ConsumeProductView extends StatefulWidget {
  const ConsumeProductView({super.key, required this.instanceKey});

  final String instanceKey;

  @override
  State<ConsumeProductView> createState() => _ConsumeProductViewState();
}

class _ConsumeProductViewState extends State<ConsumeProductView> {
  final OperationController operationController =
      Get.find<OperationController>();
  final DashboardController dashboardController =
      Get.find<DashboardController>();
  final PitController pitController = Get.isRegistered<PitController>()
      ? Get.find<PitController>()
      : Get.put(PitController());
  final AuthRepository _authRepository = AuthRepository();
  late final ConsumeProductController consumeProductController;
  final ReceiveProductController _receiveProductController =
      ReceiveProductController();
  final ReturnProductController _returnProductController =
      ReturnProductController();
  final InventorySnapshotController inventorySnapshotController =
      InventorySnapshotController();

  late final InventoryProductsStore _inventoryStore;
  late final ConsumeProductSaveBridge _saveBridge;

  final RxString selectedMethod = "Used".obs;
  final RxBool addWater = false.obs;
  final TextEditingController waterVolumeController = TextEditingController();
  final RxString totalVolumeDisplay = '0.000'.obs;

  final RxList<ProductRowData> productRows = <ProductRowData>[].obs;
  final RxList<DistributeRowData> distributeRows = <DistributeRowData>[].obs;
  final RxList<bool> productRowSaving = <bool>[].obs;
  final RxList<bool> productRowDeleting = <bool>[].obs;

  // Selected distribute row index for delete
  final RxInt selectedDistributeRow = (-1).obs;

  final Set<int> _savingInProgress = {};

  final RxInt selectedProductRow = 0.obs;
  final Rx<ProductModel?> selectedTopProduct = Rx<ProductModel?>(null);
  final RxString selectedPreviousReportId = ''.obs;
  final RxBool isLoadingPreviousProducts = false.obs;
  final RxBool isSavingAll = false.obs;
  final Map<String, double> _receiveProductTotals = {};
  final Map<String, double> _returnProductTotals = {};
  final Map<String, double> _previousFinalByProductKey = {};
  final Map<int, Timer> _autoSaveProductTimers = {};
  Map<String, dynamic>? _productRowClipboard;
  Map<String, dynamic>? _distributeRowClipboard;
  Timer? _autoSaveDistributionTimer;
  String _previousFinalCacheReportId = '';
  Worker? _wellWorker;
  Worker? _reportWorker;
  Worker? _totalVolumeWorker;
  bool _isApplyingDistributionState = false;

  // Special option constants
  static const String kActiveSystem = 'Active System';
  static const String kEmpty = '';

  RxList<ProductModel> get products => _inventoryStore.selectedProducts;

  @override
  void initState() {
    super.initState();
    consumeProductController = ConsumeProductController(
      operationInstanceKey: widget.instanceKey,
    );
    _inventoryStore = Get.find<InventoryProductsStore>();
    _saveBridge = Get.isRegistered<ConsumeProductSaveBridge>()
        ? Get.find<ConsumeProductSaveBridge>()
        : Get.put(ConsumeProductSaveBridge(), permanent: true);
    _saveBridge.register(_saveAll);
    pitController.fetchAllPits();
    pitController.fetchUnselectedPits();
    // Start with 1 row in distribute table
    _addDistributeRow(initialPit: kActiveSystem);
    _resetProductRows();
    Future.microtask(_reloadScopedState);

    waterVolumeController.addListener(_recalculateTotalVolume);
    addWater.listen((enabled) {
      if (_isApplyingDistributionState) return;
      if (!enabled) {
        waterVolumeController.text = '';
        _recalculateTotalVolume();
      } else {
        _recalculateTotalVolume();
        _rebalanceDistributeVolumes();
      }
      _scheduleDistributionAutoSave();
    });

    // Automatically rebalance distribution whenever total volume changes
    _wellWorker = ever<String>(
      padWellContext.selectedWellId,
      (_) => _reloadScopedState(),
    );
    _reportWorker = ever<String>(reportContext.selectedReportId, (reportId) {
      if (reportId.trim().isEmpty) return;
      _reloadScopedState();
    });
    _totalVolumeWorker = ever<double>(
      operationController.totalVolume,
      (_) => _rebalanceDistributeVolumes(),
    );
  }

  Future<void> _loadSavedDistributionState() async {
    if (currentBackendWellId.trim().isEmpty) {
      _resetDistributionStateUi();
      return;
    }
    if (reportContext.selectedReportId.value.trim().isEmpty) return;
    await pitController.fetchVolumeNameData(
      operationInstanceKey: widget.instanceKey,
    );
    if (!mounted) return;
    _hydrateDistributionStateFromPitData();
  }

  Future<void> _reloadScopedState() async {
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();
    if (wellId.isEmpty) {
      _resetProductRows();
      _resetDistributionStateUi();
      return;
    }
    if (reportId.isEmpty) return;

    await _loadProductsIfNeeded();
    await _loadProductMovementTotals();
    await _loadPreviousProductFinals();
    await _fetchAllConsumeProducts();
    await _loadSavedDistributionState();
  }

  void _resetProductRows() {
    productRows.clear();
    productRowSaving.clear();
    productRowDeleting.clear();
    _savingInProgress.clear();
    productRows.add(ProductRowData());
    productRowSaving.add(false);
    productRowDeleting.add(false);
    productRows.refresh();
    _recalculateTotalVolume();
  }

  void _applyAddWaterState({required bool enabled, String volume = ''}) {
    _isApplyingDistributionState = true;
    addWater.value = enabled;
    waterVolumeController.text = volume;
    _isApplyingDistributionState = false;
  }

  void _resetDistributionStateUi() {
    selectedMethod.value = 'Used';
    _applyAddWaterState(enabled: false);
    totalVolumeDisplay.value = '0.000';
    operationController.totalVolume.value = 0.0;
    _replaceDistributeRows([DistributeRowData(pit: kActiveSystem)]);
    selectedDistributeRow.value = 0;
  }

  void _hydrateDistributionStateFromPitData() {
    final raw = pitController.volumeNameData['consumeProductDistribution'];
    if (raw is! Map) {
      _applyAddWaterState(enabled: false);
      _recalculateTotalVolume();
      _ensureDefaultDistributionRow();
      return;
    }

    final state = Map<String, dynamic>.from(raw);
    final savedMethod = (state['inputMethod'] ?? '').toString().trim();
    if (savedMethod == 'Used' || savedMethod == 'Final') {
      selectedMethod.value = savedMethod;
    }

    final savedAddWaterEnabled = state['addWaterEnabled'] == true;
    final savedAddWaterVolume = _toDouble(state['addWaterVolume']);
    _applyAddWaterState(
      enabled: savedAddWaterEnabled,
      volume: savedAddWaterEnabled && savedAddWaterVolume > 0
          ? savedAddWaterVolume.toStringAsFixed(3)
          : '',
    );
    _recalculateTotalVolume();

    final rawRows = state['distributions'];
    if (rawRows is! List) {
      _ensureDefaultDistributionRow();
      return;
    }

    final restoredRows = <DistributeRowData>[];
    for (final item in rawRows) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final pitName = (map['pitName'] ?? '').toString().trim();
      final volume = _toDouble(map['volume']);
      if (pitName.isEmpty || volume <= 0) continue;
      restoredRows.add(
        DistributeRowData(pit: pitName, volume: volume.toStringAsFixed(3)),
      );
    }

    if (restoredRows.isEmpty) {
      _ensureDefaultDistributionRow();
      return;
    }

    _replaceDistributeRows(restoredRows);
  }

  void _replaceDistributeRows(List<DistributeRowData> rows) {
    for (final row in distributeRows) {
      row.volumeController.dispose();
    }
    distributeRows.assignAll(rows);
    if (selectedDistributeRow.value >= distributeRows.length) {
      selectedDistributeRow.value = distributeRows.isEmpty ? -1 : 0;
    }
    distributeRows.refresh();
  }

  void _ensureDefaultDistributionRow() {
    if (distributeRows.isEmpty) {
      _addDistributeRow(initialPit: kActiveSystem);
      return;
    }

    if (distributeRows.length == 1 &&
        distributeRows.first.pit.trim().isEmpty &&
        distributeRows.first.volume.trim().isEmpty) {
      _onDistributePitSelected(0, kActiveSystem);
    }
  }

  @override
  void dispose() {
    for (final timer in _autoSaveProductTimers.values) {
      timer.cancel();
    }
    _autoSaveProductTimers.clear();
    _autoSaveDistributionTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    _totalVolumeWorker?.dispose();
    waterVolumeController.removeListener(_recalculateTotalVolume);
    waterVolumeController.dispose();
    _saveBridge.unregister();

    // Dispose all distribution row controllers
    for (var row in distributeRows) {
      row.volumeController.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  Fetch saved consume products
  // ─────────────────────────────────────────────
  Future<void> _fetchAllConsumeProducts() async {
    debugPrint('🔵 [FETCH] Fetching saved consume products...');
    try {
      final wellId = currentBackendWellId.trim();
      final reportId = reportContext.selectedReportId.value.trim();
      if (wellId.isEmpty) {
        _resetProductRows();
        return;
      }
      if (reportId.isEmpty) return;

      final data = await consumeProductController.getAllConsumeProducts();
      debugPrint('🟢 [FETCH] ConsumeProducts: ${data.length} items');

      productRows.clear();
      productRowSaving.clear();
      productRowDeleting.clear();
      _savingInProgress.clear();

      for (final item in data) {
        final row = ProductRowData();

        final productName = item['product']?.toString() ?? '';
        row.productName = productName;

        if (productName.isNotEmpty) {
          row.selectedProduct.value = _findByName(productName);
        }

        row.code = item['code']?.toString() ?? '';
        row.sg = item['sg']?.toString() ?? '';
        row.unit = item['unit']?.toString() ?? '';
        row.price = _toDouble(item['price']);
        final savedInitial = _numStr(item['initial']);
        row.initial = savedInitial.isNotEmpty
            ? savedInitial
            : (row.selectedProduct.value == null
                  ? ''
                  : _initialForSelectedProduct(row.selectedProduct.value!));
        row.adjust = _numStr(item['adjust']);
        row.used = _numStr(item['used']);
        row.savedId = item['_id']?.toString();

        _applyProductMovementToRow(row);
        row.recalculate();
        productRows.add(row);
        productRowSaving.add(false);
        productRowDeleting.add(false);

        debugPrint(
          '🟢 [ROW] name="$productName" code=${row.code} savedId=${row.savedId}',
        );
      }

      productRows.add(ProductRowData());
      productRowSaving.add(false);
      productRowDeleting.add(false);

      _recalculateTotalVolume();
      debugPrint('🟢 [FETCH] Done, ${productRows.length} rows');
    } catch (e) {
      debugPrint('🔴 [FETCH] $e');
      productRows.add(ProductRowData());
      productRowSaving.add(false);
      productRowDeleting.add(false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ProductModel? _findByName(String name) =>
      _inventoryStore.selectedProducts.firstWhereOrNull(
        (p) => p.product.trim().toLowerCase() == name.trim().toLowerCase(),
      );

  String _nameMovementKey(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ? '' : 'name:$normalized';
  }

  String _codeMovementKey(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ? '' : 'code:$normalized';
  }

  List<String> _productCarryKeys({String productName = '', String code = ''}) {
    final keys = <String>[];
    final codeKey = _codeMovementKey(code);
    if (codeKey.isNotEmpty) keys.add(codeKey);
    final nameKey = _nameMovementKey(productName);
    if (nameKey.isNotEmpty) keys.add(nameKey);
    return keys;
  }

  String _formatCarryInitial(double value) {
    final text = value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return text.isEmpty ? '0' : text;
  }

  Future<void> _loadPreviousProductFinals() async {
    final previousReports = _previousReports();
    final previousReportId = previousReports.isEmpty
        ? ''
        : previousReports.first.id.toString().trim();

    if (previousReportId.isEmpty) {
      _previousFinalCacheReportId = '';
      _previousFinalByProductKey.clear();
      return;
    }

    if (_previousFinalCacheReportId == previousReportId &&
        _previousFinalByProductKey.isNotEmpty) {
      return;
    }

    try {
      final data = await consumeProductController.getAllConsumeProducts(
        reportIdOverride: previousReportId,
      );
      _previousFinalByProductKey.clear();
      for (final item in data) {
        final finalValue = _toDouble(item['final']);
        final keys = _productCarryKeys(
          productName: item['product']?.toString() ?? '',
          code: item['code']?.toString() ?? '',
        );
        for (final key in keys) {
          _previousFinalByProductKey[key] = finalValue;
        }
      }
      _previousFinalCacheReportId = previousReportId;
    } catch (e) {
      debugPrint('[CONSUME PRODUCT] Previous final load failed: $e');
      _previousFinalCacheReportId = '';
      _previousFinalByProductKey.clear();
    }
  }

  String _initialForSelectedProduct(ProductModel product) {
    final keys = _productCarryKeys(
      productName: product.product,
      code: product.code,
    );
    for (final key in keys) {
      if (_previousFinalByProductKey.containsKey(key)) {
        return _formatCarryInitial(_previousFinalByProductKey[key] ?? 0.0);
      }
    }

    final initD = double.tryParse(product.initial) ?? 0.0;
    return initD != 0.0 ? product.initial : '';
  }

  void _addMovementTotal(
    Map<String, double> totals,
    Map<String, dynamic> item,
  ) {
    final amount = _toDouble(item['amount']);
    if (amount == 0) return;

    final codeKey = _codeMovementKey(item['code']?.toString() ?? '');
    final nameKey = _nameMovementKey(item['productName']?.toString() ?? '');

    if (codeKey.isNotEmpty) {
      totals[codeKey] = (totals[codeKey] ?? 0.0) + amount;
    }
    if (nameKey.isNotEmpty) {
      totals[nameKey] = (totals[nameKey] ?? 0.0) + amount;
    }
  }

  double _movementTotalForRow(Map<String, double> totals, ProductRowData row) {
    final codeKey = _codeMovementKey(row.code);
    if (codeKey.isNotEmpty && totals.containsKey(codeKey)) {
      return totals[codeKey] ?? 0.0;
    }

    final productName = row.selectedProduct.value?.product.isNotEmpty == true
        ? row.selectedProduct.value!.product
        : row.productName;
    final nameKey = _nameMovementKey(productName);
    return nameKey.isEmpty ? 0.0 : (totals[nameKey] ?? 0.0);
  }

  void _applyProductMovementToRow(ProductRowData row) {
    row.received = _movementTotalForRow(_receiveProductTotals, row);
    row.returned = _movementTotalForRow(_returnProductTotals, row);
  }

  void _applyProductMovementTotals() {
    for (final row in productRows) {
      _applyProductMovementToRow(row);
      row.recalculate();
    }
    productRows.refresh();
    _recalculateTotalVolume();
  }

  Future<void> _loadProductMovementTotals() async {
    try {
      final results = await Future.wait([
        _receiveProductController.getReceiveProducts(),
        _returnProductController.getReturnProducts(),
      ]);

      _receiveProductTotals.clear();
      _returnProductTotals.clear();

      for (final item in results[0]) {
        _addMovementTotal(_receiveProductTotals, item);
      }
      for (final item in results[1]) {
        _addMovementTotal(_returnProductTotals, item);
      }

      _applyProductMovementTotals();
    } catch (e) {
      debugPrint('[PRODUCT MOVEMENT] Error loading receive/return totals: $e');
    }
  }

  Future<void> _loadProductsIfNeeded() async {
    try {
      final wellId = currentBackendWellId.trim();
      if (wellId.isNotEmpty) {
        final savedProducts = await InventoryProductsService.fetchProducts(
          wellId,
        );
        if (savedProducts.isNotEmpty) {
          _inventoryStore.setSelectedProducts(
            savedProducts.map(_toProductModel).toList(),
          );
        }
      }

      _syncProductSelectionsWithInventory();
    } catch (e) {
      debugPrint('🔴 [PRODUCTS] Error loading inventory products: $e');
    }
  }

  void _syncProductSelectionsWithInventory() {
    for (final row in productRows) {
      if (row.productName.trim().isNotEmpty) {
        final matchedProduct = _findByName(row.productName);
        if (matchedProduct != null) {
          row.selectedProduct.value = matchedProduct;
          if (row.initial.trim().isEmpty) {
            row.initial = _initialForSelectedProduct(matchedProduct);
          }
        }
      }
      _applyProductMovementToRow(row);
      row.recalculate();
    }
    productRows.refresh();
  }

  ProductModel _toProductModel(dynamic product) {
    return ProductModel(
      id: product.id,
      product: product.product,
      code: product.code,
      sg: product.sg,
      unitNum: product.unit,
      unitClass: '',
      group: product.group,
      a: product.price,
      price: product.price,
      initial: product.initial,
      volAdd: product.volAdd,
      calculate: product.calculate,
      plot: product.plot ?? false,
      tax: product.tax,
    );
  }

  double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  String _numStr(dynamic v) {
    final d = _toDouble(v);
    return d == 0.0 ? '' : d.toString();
  }

  String _mergeUnit(ProductModel p) {
    final n = p.unitNum.trim();
    final c = p.unitClass.trim();
    if (n.isNotEmpty && c.isNotEmpty) return '$n $c';
    if (c.isNotEmpty) return c;
    return n;
  }

  void _fillRowFromProduct(
    ProductRowData row,
    ProductModel product, {
    bool clearUsage = true,
  }) {
    row.selectedProduct.value = product;
    row.productName = product.product;
    row.code = product.code;
    row.sg = product.sg;
    row.unit = _mergeUnit(product);
    row.price =
        double.tryParse(product.a.isNotEmpty ? product.a : product.price) ??
        0.0;
    row.initial = _initialForSelectedProduct(product);
    if (clearUsage) {
      row.adjust = '';
      row.used = '';
    }
    _applyProductMovementToRow(row);
    row.recalculate();
  }

  void _addProductFromTop(ProductModel? product) {
    if (product == null || dashboardController.isLocked.value) return;

    var index = productRows.indexWhere(
      (row) =>
          row.productName.trim().isEmpty && row.selectedProduct.value == null,
    );
    if (index < 0) {
      productRows.add(ProductRowData());
      productRowSaving.add(false);
      productRowDeleting.add(false);
      index = productRows.length - 1;
    }

    selectedProductRow.value = index;
    _fillRowFromProduct(productRows[index], product);
    productRows.refresh();
    _checkAndAddProductRow();
    _recalculateTotalVolume();
    selectedTopProduct.value = null;
  }

  int _reportOrderValue(dynamic report) {
    final userNo = int.tryParse(report.userReportNo.toString().trim());
    final reportNo = int.tryParse(report.reportNo.toString().trim());
    return userNo ?? reportNo ?? 0;
  }

  List<dynamic> _previousReports() {
    final currentId = reportContext.selectedReportId.value.trim();
    final reports = reportContext.reports.toList();
    reports.sort((a, b) {
      final orderDiff = _reportOrderValue(a).compareTo(_reportOrderValue(b));
      if (orderDiff != 0) return orderDiff;
      return a.createdAt.toString().compareTo(b.createdAt.toString());
    });

    final currentIndex = reports.indexWhere((report) => report.id == currentId);
    if (currentIndex <= 0) return const [];
    return reports.sublist(0, currentIndex).reversed.toList();
  }

  Future<void> _loadPreviousReportProducts(String reportId) async {
    if (reportId.isEmpty || isLoadingPreviousProducts.value) return;

    isLoadingPreviousProducts.value = true;
    try {
      final data = await consumeProductController.getAllConsumeProducts(
        reportIdOverride: reportId,
      );
      if (data.isEmpty) {
        _showToast('Previous report me products nahi mile', isError: true);
        return;
      }

      for (var index = productRows.length - 1; index >= 0; index--) {
        final row = productRows[index];
        if (row.savedId == null &&
            row.productName.trim().isEmpty &&
            row.selectedProduct.value == null) {
          productRows.removeAt(index);
          if (index < productRowSaving.length) productRowSaving.removeAt(index);
          if (index < productRowDeleting.length)
            productRowDeleting.removeAt(index);
        }
      }

      for (final item in data) {
        final row = ProductRowData();
        final productName = item['product']?.toString() ?? '';
        row.productName = productName;
        row.selectedProduct.value = _findByName(productName);
        row.code = item['code']?.toString() ?? '';
        row.sg = item['sg']?.toString() ?? '';
        row.unit = item['unit']?.toString() ?? '';
        row.price = _toDouble(item['price']);
        row.initial = _formatCarryInitial(_toDouble(item['final']));
        row.adjust = '';
        row.used = '';
        row.savedId = null;
        _applyProductMovementToRow(row);
        row.recalculate();
        productRows.add(row);
        productRowSaving.add(false);
        productRowDeleting.add(false);
      }

      productRows.add(ProductRowData());
      productRowSaving.add(false);
      productRowDeleting.add(false);
      productRows.refresh();
      _recalculateTotalVolume();
      _showToast('Previous products loaded');
    } catch (e) {
      _showToast('Previous products load failed: $e', isError: true);
    } finally {
      isLoadingPreviousProducts.value = false;
      selectedPreviousReportId.value = '';
    }
  }

  void _recalculateTotalVolume() {
    double total = 0.0;
    for (final row in productRows) {
      total += row.calculatedVolume.value;
    }
    if (addWater.value) {
      total += double.tryParse(waterVolumeController.text) ?? 0.0;
    }
    totalVolumeDisplay.value = total.toStringAsFixed(3);
    operationController.totalVolume.value = total;
  }

  bool _hasProductRowData(ProductRowData row) {
    return row.savedId != null ||
        row.productName.trim().isNotEmpty ||
        row.selectedProduct.value != null ||
        row.code.trim().isNotEmpty ||
        row.sg.trim().isNotEmpty ||
        row.unit.trim().isNotEmpty ||
        row.initial.trim().isNotEmpty ||
        row.adjust.trim().isNotEmpty ||
        row.used.trim().isNotEmpty;
  }

  Map<String, dynamic> _productRowSnapshot(ProductRowData row) {
    return {
      'productName': row.productName,
      'selectedProduct': row.selectedProduct.value,
      'code': row.code,
      'sg': row.sg,
      'unit': row.unit,
      'price': row.price,
      'initial': row.initial,
      'adjust': row.adjust,
      'used': row.used,
    };
  }

  void _applyProductRowSnapshot(ProductRowData row, Map<String, dynamic> data) {
    final selected = data['selectedProduct'];
    row.productName = (data['productName'] ?? '').toString();
    row.selectedProduct.value = selected is ProductModel ? selected : null;
    row.code = (data['code'] ?? '').toString();
    row.sg = (data['sg'] ?? '').toString();
    row.unit = (data['unit'] ?? '').toString();
    row.price = (data['price'] as num?)?.toDouble() ?? 0.0;
    row.initial = (data['initial'] ?? '').toString();
    row.adjust = (data['adjust'] ?? '').toString();
    row.used = (data['used'] ?? '').toString();
    row.recalculate();
  }

  void _clearProductRowUi(ProductRowData row) {
    row.savedId = null;
    row.productName = '';
    row.selectedProduct.value = null;
    row.code = '';
    row.sg = '';
    row.unit = '';
    row.price = 0.0;
    row.initial = '';
    row.adjust = '';
    row.used = '';
    row.recalculate();
  }

  void _insertProductRow(int index) {
    productRows.insert(index, ProductRowData());
    productRowSaving.insert(index, false);
    productRowDeleting.insert(index, false);
    productRows.refresh();
  }

  Future<void> _clearProductRow(int index) async {
    if (index < 0 || index >= productRows.length) return;
    final row = productRows[index];
    if (row.savedId != null) {
      await _deleteRow(index);
      return;
    }
    _clearProductRowUi(row);
    productRows.refresh();
    _recalculateTotalVolume();
  }

  Future<void> _showProductRowMenu(TapDownDetails details, int index) async {
    if (index < 0 || index >= productRows.length) return;
    selectedProductRow.value = index;
    final row = productRows[index];
    final action = await showOperationRowMenu(
      context: context,
      details: details,
      canEdit: !dashboardController.isLocked.value,
      hasData: _hasProductRowData(row),
      canPaste: _productRowClipboard != null,
      canInsertRow: true,
      canDeleteRow: true,
      canMoveTop: false,
      canMoveBottom: false,
    );
    switch (action) {
      case 'cut':
        _productRowClipboard = _productRowSnapshot(row);
        await _clearProductRow(index);
        break;
      case 'copy':
        _productRowClipboard = _productRowSnapshot(row);
        break;
      case 'paste':
        if (_productRowClipboard != null) {
          _applyProductRowSnapshot(row, _productRowClipboard!);
          productRows.refresh();
          _checkAndAddProductRow();
          _recalculateTotalVolume();
          _scheduleProductAutoSave(index);
        }
        break;
      case 'delete':
      case 'clear':
        await _clearProductRow(index);
        break;
      case 'insertRow':
        _insertProductRow(index);
        break;
      case 'deleteRow':
        await _deleteRow(index);
        break;
    }
  }

  bool _hasDistributeRowData(DistributeRowData row) {
    return row.pit.trim().isNotEmpty ||
        row.volumeController.text.trim().isNotEmpty;
  }

  Map<String, dynamic> _distributeRowSnapshot(DistributeRowData row) {
    return {'pit': row.pit, 'volume': row.volumeController.text.trim()};
  }

  void _applyDistributeRowSnapshot(
    DistributeRowData row,
    Map<String, dynamic> data,
  ) {
    final index = distributeRows.indexOf(row);
    final nextVolume = (data['volume'] ?? '').toString();
    if (index >= 0 && !_canSetDistributeVolume(index, nextVolume)) {
      _showDistributionLimitAlert();
      return;
    }
    row.pit = (data['pit'] ?? '').toString();
    row.volume = nextVolume;
    row.volumeController.text = row.volume;
  }

  Future<void> _showDistributeRowMenu(TapDownDetails details, int index) async {
    if (index < 0 || index >= distributeRows.length) return;
    selectedDistributeRow.value = index;
    final row = distributeRows[index];
    final action = await showOperationRowMenu(
      context: context,
      details: details,
      canEdit: !dashboardController.isLocked.value,
      hasData: _hasDistributeRowData(row),
      canPaste: _distributeRowClipboard != null,
      canInsertRow: true,
      canDeleteRow: true,
      canMoveTop: false,
      canMoveBottom: false,
    );
    switch (action) {
      case 'cut':
        _distributeRowClipboard = _distributeRowSnapshot(row);
        _deleteDistributeRow(index);
        _scheduleDistributionAutoSave();
        break;
      case 'copy':
        _distributeRowClipboard = _distributeRowSnapshot(row);
        break;
      case 'paste':
        if (_distributeRowClipboard != null) {
          _applyDistributeRowSnapshot(row, _distributeRowClipboard!);
          _scheduleDistributionAutoSave();
        }
        break;
      case 'delete':
      case 'clear':
      case 'deleteRow':
        _deleteDistributeRow(index);
        _scheduleDistributionAutoSave();
        break;
      case 'insertRow':
        _addDistributeRow(insertIndex: index);
        _scheduleDistributionAutoSave();
        break;
    }
  }

  double _volumeGroupTotal(bool Function(ProductModel product) matcher) {
    double total = 0.0;
    for (final row in productRows) {
      final product = row.selectedProduct.value;
      if (product == null) continue;
      if (!matcher(product)) continue;
      total += row.calculatedVolume.value;
    }
    return total;
  }

  Future<void> _openVolumeByGroupDialog() {
    final weightMaterial = _volumeGroupTotal(
      (product) => product.group.toLowerCase().contains('weight'),
    );
    final baseFluid = _volumeGroupTotal(
      (product) => product.group.toLowerCase().contains('base fluid'),
    );
    final water = addWater.value
        ? (double.tryParse(waterVolumeController.text.trim()) ?? 0.0)
        : 0.0;
    final productsTotal = productRows.fold<double>(
      0.0,
      (sum, row) => sum + row.calculatedVolume.value,
    );
    final remainingProducts = (productsTotal - baseFluid - weightMaterial)
        .clamp(0.0, double.infinity);
    return showVolumeByGroupDialog(
      context,
      baseFluid: baseFluid,
      weightMaterial: weightMaterial,
      products: remainingProducts,
      water: water,
    );
  }

  bool _isCostCalculated(ProductRowData row) {
    final usedVal = double.tryParse(row.used) ?? 0.0;
    return usedVal > 0 && row.price > 0;
  }

  bool _hasSavableProductRow(ProductRowData row) {
    final productName = row.selectedProduct.value?.product.isNotEmpty == true
        ? row.selectedProduct.value!.product
        : row.productName;
    if (productName.trim().isEmpty) return false;
    return row.savedId != null ||
        row.initial.trim().isNotEmpty ||
        row.adjust.trim().isNotEmpty ||
        row.used.trim().isNotEmpty ||
        row.price > 0;
  }

  void _scheduleProductAutoSave(int index) {
    if (dashboardController.isLocked.value || index >= productRows.length)
      return;
    if (!_hasSavableProductRow(productRows[index])) return;
    _autoSaveProductTimers[index]?.cancel();
    _autoSaveProductTimers[index] = Timer(
      const Duration(milliseconds: 650),
      () {
        _autoSaveProductTimers.remove(index);
        if (!mounted ||
            dashboardController.isLocked.value ||
            index >= productRows.length ||
            !_hasSavableProductRow(productRows[index])) {
          return;
        }
        _saveRow(index);
      },
    );
  }

  void _scheduleDistributionAutoSave() {
    if (dashboardController.isLocked.value) return;
    if (currentBackendWellId.trim().isEmpty) return;
    if (reportContext.selectedReportId.value.trim().isEmpty) return;
    _autoSaveDistributionTimer?.cancel();
    _autoSaveDistributionTimer = Timer(
      const Duration(milliseconds: 750),
      () async {
        if (!mounted || dashboardController.isLocked.value) return;
        final result = await _saveDistributionState();
        if (result['success'] == true) {
          await pitController.fetchVolumeNameData(
            operationInstanceKey: widget.instanceKey,
          );
        }
      },
    );
  }

  void _onFieldChanged(int index) {
    if (index >= productRows.length) return;
    final row = productRows[index];
    if (row.productName.isEmpty && row.selectedProduct.value == null) return;

    _applyProductMovementToRow(row);
    row.recalculate();
    _recalculateTotalVolume();
    _scheduleProductAutoSave(index);
    _scheduleDistributionAutoSave();
  }

  void _checkAndAddProductRow() {
    if (productRows.isNotEmpty && productRows.last.productName.isNotEmpty) {
      productRows.add(ProductRowData());
      productRowSaving.add(false);
      productRowDeleting.add(false);
    }
  }

  // ─────────────────────────────────────────────
  //  Distribute table helpers
  // ─────────────────────────────────────────────

  /// Add a new distribute row
  void _addDistributeRow({String initialPit = kEmpty, int? insertIndex}) {
    final newRow = DistributeRowData(pit: initialPit);
    if (insertIndex != null &&
        insertIndex >= 0 &&
        insertIndex <= distributeRows.length) {
      distributeRows.insert(insertIndex, newRow);
    } else {
      distributeRows.add(newRow);
    }
    // Keep the Active System row aligned with Total Vol.
    _rebalanceDistributeVolumes();
  }

  /// Delete selected/specific distribute row
  void _deleteDistributeRow(int index) {
    if (distributeRows.length <= 1) {
      // Clear the last row instead of deleting
      distributeRows[0].pit = '';
      distributeRows[0].volume = '';
      distributeRows[0].volumeController.text = '';
      distributeRows.refresh();
      _scheduleDistributionAutoSave();
      return;
    }

    // Dispose the controller before removing to avoid leaks
    distributeRows[index].volumeController.dispose();
    distributeRows.removeAt(index);

    if (selectedDistributeRow.value >= distributeRows.length) {
      selectedDistributeRow.value = distributeRows.length - 1;
    }
    _rebalanceDistributeVolumes();
    _scheduleDistributionAutoSave();
  }

  /// Auto-fill first row with total vol when a pit is selected
  void _onDistributePitSelected(int index, String pitName) {
    distributeRows[index].pit = pitName;

    if (pitName == kEmpty) {
      // Clear volume if empty selected
      distributeRows[index].volume = '';
      distributeRows[index].volumeController.text = '';
      distributeRows.refresh();
      _scheduleDistributionAutoSave();
      return;
    }

    if (index == 0) {
      // First row always mirrors Total Vol. like the legacy desktop flow.
      _rebalanceDistributeVolumes();
    }
    distributeRows.refresh();
    _scheduleDistributionAutoSave();
  }

  /// Called when user manually changes volume (triggered on every keystroke)
  void _onDistributeVolumeChanged(int index, String value) {
    if (!_canSetDistributeVolume(index, value)) {
      final row = distributeRows[index];
      _setDistributeVolumeText(row, row.volume);
      _showDistributionLimitAlert();
      return;
    }
    // Update internal value only
    distributeRows[index].volume = value;
    // We don't automatically trigger rebalance on every keypress for other rows
    // to prevent Row 1's volume jumping while the user is typing.
    // Rebalance will happen when user clicks Calculate or on lose focus/submit.
    _scheduleDistributionAutoSave();
  }

  /// Calculate button: refresh the Active System row from Total Vol.
  void _calculateDistribution() {
    _rebalanceDistributeVolumes();
    _scheduleDistributionAutoSave();
  }

  /// Legacy behavior: row 0 mirrors Total Vol.; storage rows stay manual.
  void _rebalanceDistributeVolumes() {
    if (distributeRows.isEmpty) return;
    final hasManualDistributionRows = distributeRows.skip(1).any((row) {
      return row.pit.trim().isNotEmpty || row.volume.trim().isNotEmpty;
    });
    if (hasManualDistributionRows) return;

    if (distributeRows[0].pit.isNotEmpty) {
      final formattedVol = totalVolumeDisplay.value.trim().isNotEmpty
          ? totalVolumeDisplay.value.trim()
          : '0.000';
      distributeRows[0].volume = formattedVol;
      if (distributeRows[0].volumeController.text != formattedVol) {
        _setDistributeVolumeText(distributeRows[0], formattedVol);
      }
    }
  }

  double _parseVolume(String value) {
    return double.tryParse(value.trim()) ?? 0.0;
  }

  double _distributedVolumeTotal({int? overrideIndex, String? overrideValue}) {
    var total = 0.0;
    for (var i = 0; i < distributeRows.length; i++) {
      final row = distributeRows[i];
      final value = i == overrideIndex ? overrideValue ?? '' : row.volume;
      final parsed = _parseVolume(value);
      if (parsed > 0) total += parsed;
    }
    return total;
  }

  bool _canSetDistributeVolume(int index, String value) {
    final totalVolume = _parseVolume(totalVolumeDisplay.value);
    if (totalVolume <= 0) return _parseVolume(value) <= 0;
    final distributed = _distributedVolumeTotal(
      overrideIndex: index,
      overrideValue: value,
    );
    return distributed <= totalVolume + 0.0005;
  }

  bool _validateDistributionTotal() {
    final totalVolume = _parseVolume(totalVolumeDisplay.value);
    final distributed = _distributedVolumeTotal();
    if (totalVolume <= 0) return distributed <= 0;
    return distributed <= totalVolume + 0.0005;
  }

  void _setDistributeVolumeText(DistributeRowData row, String value) {
    row.volumeController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _showDistributionLimitAlert() {
    _showToast(
      'Distributed volume cannot exceed Total Vol. ${totalVolumeDisplay.value} bbl',
      isError: true,
    );
  }

  // ─────────────────────────────────────────────
  //  SAVE ROW
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>> _saveRow(int index) async {
    _autoSaveProductTimers.remove(index)?.cancel();
    if (dashboardController.isLocked.value) {
      return {'success': false, 'message': 'Report is locked'};
    }
    if (index >= productRows.length) {
      return {'success': false, 'message': 'Invalid product row'};
    }
    final row = productRows[index];

    final productName = row.selectedProduct.value?.product.isNotEmpty == true
        ? row.selectedProduct.value!.product
        : row.productName;

    if (productName.isEmpty) {
      return {'success': false, 'message': 'Product is required'};
    }

    if (_savingInProgress.contains(index)) {
      debugPrint('⏳ [SAVE] Row $index already saving — skip');
      return {'success': true, 'message': 'Save already in progress'};
    }

    _savingInProgress.add(index);

    row.recalculate();

    try {
      Map<String, dynamic> result;

      if (row.savedId == null) {
        debugPrint('🆕 [CREATE] Row $index — product="$productName"');
        result = await consumeProductController.createConsumeProduct(
          productName: productName,
          code: row.code,
          sg: double.tryParse(row.sg) ?? 0.0,
          unit: row.unit,
          price: row.price,
          initial: double.tryParse(row.initial) ?? 0.0,
          adjust: double.tryParse(row.adjust) ?? 0.0,
          used: double.tryParse(row.used) ?? 0.0,
          numberOfBags: 1.0,
          weightPerBag: 1.0,
        );

        if (result['success'] == true) {
          row.savedId = result['data']?['_id']?.toString();
          row.productName = productName;
          await pitController.fetchVolumeNameData(
            operationInstanceKey: widget.instanceKey,
          );
          debugPrint('✅ [CREATE] Done — savedId=${row.savedId}');
        } else {
          _showToast(result['message'] ?? 'Save failed', isError: true);
        }
      } else {
        debugPrint(
          '✏️ [UPDATE] Row $index — product="$productName" id=${row.savedId}',
        );
        result = await consumeProductController.updateConsumeProduct(
          id: row.savedId!,
          productName: productName,
          code: row.code,
          sg: double.tryParse(row.sg) ?? 0.0,
          unit: row.unit,
          price: row.price,
          initial: double.tryParse(row.initial) ?? 0.0,
          adjust: double.tryParse(row.adjust) ?? 0.0,
          used: double.tryParse(row.used) ?? 0.0,
          numberOfBags: 1.0,
          weightPerBag: 1.0,
        );

        if (result['success'] == true) {
          debugPrint('✅ [UPDATE] Done — savedId=${row.savedId}');
        } else {
          _showToast(result['message'] ?? 'Update failed', isError: true);
        }
      }
      await pitController.fetchVolumeNameData(
        operationInstanceKey: widget.instanceKey,
      );
      return result;
    } catch (e) {
      _showToast('Save error: $e', isError: true);
      return {'success': false, 'message': 'Save error: $e'};
    } finally {
      _savingInProgress.remove(index);
    }
  }

  Future<void> _deleteRow(int index) async {
    _autoSaveProductTimers.remove(index)?.cancel();
    if (index >= productRows.length) return;
    final row = productRows[index];

    if (row.savedId == null) {
      if (productRows.length > 1) {
        productRows.removeAt(index);
        if (index < productRowSaving.length) productRowSaving.removeAt(index);
        if (index < productRowDeleting.length)
          productRowDeleting.removeAt(index);
        _savingInProgress.remove(index);
      } else {
        productRows[index] = ProductRowData();
      }
      _recalculateTotalVolume();
      _rebalanceDistributeVolumes();
      _scheduleDistributionAutoSave();
      return;
    }

    try {
      final result = await consumeProductController.deleteConsumeProduct(
        row.savedId!,
      );
      if (result['success'] == true) {
        _savingInProgress.remove(index);
        if (productRows.length > 1) {
          productRows.removeAt(index);
          if (index < productRowSaving.length) productRowSaving.removeAt(index);
          if (index < productRowDeleting.length) {
            productRowDeleting.removeAt(index);
          }
        } else {
          _clearProductRowUi(row);
        }
        _recalculateTotalVolume();
        _rebalanceDistributeVolumes();
        final distributionResult = await _saveDistributionState();
        if (distributionResult['success'] == true) {
          await _refreshPitStateAfterConsumeProductSave();
        } else {
          await pitController.fetchVolumeNameData(
            operationInstanceKey: widget.instanceKey,
          );
        }
        await inventorySnapshotController.generateInventorySnapshot();
        _showToast('Deleted');
      } else {
        _showToast(result['message'] ?? 'Delete failed', isError: true);
      }
    } catch (e) {
      _showToast('Delete error: $e', isError: true);
    }
  }

  Future<void> _refreshPitStateAfterConsumeProductSave() async {
    await pitController.fetchAllPits();
    await pitController.fetchSelectedPits();
    await pitController.fetchUnselectedPits();
    await pitController.fetchVolumeNameData(
      operationInstanceKey: widget.instanceKey,
    );
    _hydrateDistributionStateFromPitData();
  }

  Future<Map<String, dynamic>> _saveDistributionState() async {
    final wellId = currentBackendWellId.trim();
    if (wellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }
    final reportId = reportContext.selectedReportId.value.trim();
    if (reportId.isEmpty) {
      return {'success': false, 'message': 'No report selected'};
    }

    _recalculateTotalVolume();

    final totalVolume = double.tryParse(totalVolumeDisplay.value) ?? 0.0;
    if (!_validateDistributionTotal()) {
      return {
        'success': false,
        'message':
            'Distributed volume cannot exceed Total Vol. ${totalVolumeDisplay.value} bbl',
      };
    }
    final candidateRows = distributeRows
        .where(
          (row) => row.pit.trim().isNotEmpty || row.volume.trim().isNotEmpty,
        )
        .toList();

    final errors = <String>[];
    final distributions = <Map<String, dynamic>>[];

    for (var i = 0; i < candidateRows.length; i++) {
      final row = candidateRows[i];
      final pitName = row.pit.trim();
      final volume = double.tryParse(row.volume.trim()) ?? 0.0;

      if (pitName.isEmpty && volume <= 0) {
        continue;
      }
      if (pitName.isEmpty) {
        errors.add('Distribute row ${i + 1}: pit is required');
        continue;
      }
      if (volume <= 0) {
        continue;
      }

      distributions.add({
        'pitName': pitName,
        'volume': double.parse(volume.toStringAsFixed(3)),
      });
    }

    if (errors.isNotEmpty) {
      return {'success': false, 'message': errors.join(' | ')};
    }
    final addWaterVolume =
        double.tryParse(waterVolumeController.text.trim()) ?? 0.0;

    return _authRepository.saveConsumeProductVolumeName({
      'wellId': wellId,
      'reportId': reportId,
      'operationInstanceKey': widget.instanceKey,
      'inputMethod': selectedMethod.value,
      'addWater': addWater.value,
      'addWaterVolume': addWater.value ? addWaterVolume : 0.0,
      'totalVolume': totalVolume,
      'distributions': distributions,
    });
  }

  Future<Map<String, dynamic>> _saveAll() async {
    if (dashboardController.isLocked.value) {
      return {'success': false, 'message': 'Report is locked'};
    }
    if (isSavingAll.value) {
      return {'success': false, 'message': 'Save is already in progress'};
    }

    isSavingAll.value = true;
    final errors = <String>[];
    var savedRows = 0;

    try {
      for (int i = 0; i < productRows.length; i++) {
        final row = productRows[i];
        final productName =
            row.selectedProduct.value?.product.isNotEmpty == true
            ? row.selectedProduct.value!.product
            : row.productName;

        if (productName.isNotEmpty && _hasSavableProductRow(row)) {
          final saveResult = await _saveRow(i);
          if (saveResult['success'] == true) {
            savedRows++;
          } else {
            errors.add(
              'Product "${productName.trim()}": ${saveResult['message'] ?? 'Save failed'}',
            );
          }
        }
      }

      final distributionResult = await _saveDistributionState();
      if (distributionResult['success'] != true) {
        errors.add(
          'Distribute to: ${distributionResult['message'] ?? 'Save failed'}',
        );
      }

      await _refreshPitStateAfterConsumeProductSave();

      final snapResult = await inventorySnapshotController
          .generateInventorySnapshot();
      if (snapResult['success'] != true) {
        errors.add('Snapshot: ${snapResult['message'] ?? 'Failed'}');
      }

      if (errors.isEmpty) {
        return {
          'success': true,
          'message': savedRows > 0
              ? 'Consume Product saved successfully'
              : 'Consume Product state saved successfully',
        };
      }

      return {'success': false, 'message': errors.join(' | ')};
    } catch (e) {
      return {'success': false, 'message': 'Save All failed: $e'};
    } finally {
      isSavingAll.value = false;
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xffEF4444)
            : const Color(0xff10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
        duration: Duration(seconds: isError ? 3 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopControls(),
              const SizedBox(height: 10),
              _buildProductTable(),
              const SizedBox(height: 10),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildSelectProductsButton()),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _buildPreviousProductsButton()),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  "Input Method",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 10),
                _buildRadioBtn("Used"),
                const SizedBox(width: 6),
                _buildRadioBtn("Final"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectProductsButton() {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: dashboardController.isLocked.value
            ? null
            : () async {
                final selected = await showSelectProductsDialog(
                  context: context,
                  products: products.toList(),
                  title: 'Select Products',
                );
                if (selected == null || selected.isEmpty) return;
                for (final product in selected) {
                  _addProductFromTop(product);
                }
              },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
        child: Text(
          'Select Products ...',
          style: AppTheme.bodySmall.copyWith(
            fontSize: 11,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviousProductsButton() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Obx(() {
        final previousReports = _previousReports();
        return PopupMenuButton<String>(
          enabled:
              !dashboardController.isLocked.value &&
              !isLoadingPreviousProducts.value &&
              previousReports.isNotEmpty,
          tooltip: 'Load Previous Products',
          itemBuilder: (context) => previousReports
              .map<PopupMenuEntry<String>>(
                (report) => PopupMenuItem<String>(
                  value: report.id.toString(),
                  child: Text(
                    report.displayName.toString(),
                    style: AppTheme.bodySmall.copyWith(fontSize: 11),
                  ),
                ),
              )
              .toList(),
          onSelected: (reportId) {
            selectedPreviousReportId.value = reportId;
            _loadPreviousReportProducts(reportId);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(Icons.history, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isLoadingPreviousProducts.value
                        ? 'Loading Previous Products...'
                        : 'Load Previous Products',
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 11,
                      color: previousReports.isEmpty
                          ? Colors.grey.shade400
                          : AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRadioBtn(String value) {
    return Obx(
      () => InkWell(
        onTap: dashboardController.isLocked.value
            ? null
            : () {
                selectedMethod.value = value;
                _scheduleDistributionAutoSave();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: selectedMethod.value == value
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: selectedMethod.value == value
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedMethod.value == value
                        ? AppTheme.primaryColor
                        : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: selectedMethod.value == value
                    ? Center(
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 5),
              Text(
                value,
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  color: selectedMethod.value == value
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductTable() {
    const headers = [
      "Product",
      "Code",
      "SG",
      "Unit",
      "Price (Kwd)",
      "Initial",
      "Adjust",
      "Used",
      "Final",
      "Cost (Kwd)",
      "Vol (bbl)",
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              "Consume Product",
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(
            height: 232,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Obx(
                  () => DataTable(
                    headingRowHeight: 34,
                    dataRowHeight: 34,
                    columnSpacing: 0,
                    horizontalMargin: 0,
                    dividerThickness: 0,
                    headingRowColor: MaterialStateProperty.all(
                      AppTheme.primaryColor,
                    ),
                    border: TableBorder(
                      verticalInside: BorderSide(color: Colors.grey.shade300),
                      horizontalInside: BorderSide(color: Colors.grey.shade200),
                    ),
                    headingTextStyle: AppTheme.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    dataTextStyle: AppTheme.bodySmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    columns: headers
                        .map(
                          (h) => DataColumn(
                            label: Container(
                              width: _colWidth(h),
                              alignment: _isRightCol(h)
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(AppUnits.label(h)),
                            ),
                          ),
                        )
                        .toList(),
                    rows: List.generate(
                      productRows.length,
                      (i) => DataRow(
                        color: MaterialStateProperty.all(
                          i % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        ),
                        cells: _withProductRowMenu(
                          _buildRowCells(productRows[i], i),
                          i,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isRightCol(String h) => const {
    'Price (Kwd)',
    'Cost (Kwd)',
    'Initial',
    'Adjust',
    'Used',
    'Final',
    'Vol (bbl)',
  }.contains(h);

  double _colWidth(String h) {
    switch (h) {
      case 'Product':
        return 160;
      case 'Code':
        return 80;
      case 'SG':
      case 'Unit':
        return 70;
      case 'Price (Kwd)':
      case 'Cost (Kwd)':
        return 90;
      default:
        return 75;
    }
  }

  List<DataCell> _buildRowCells(ProductRowData row, int i) {
    final locked = dashboardController.isLocked.value;

    return [
      // ══════════════════════════════════════════
      // 1. Product Column
      // ══════════════════════════════════════════
      DataCell(
        Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Obx(() {
            final storeProducts = _inventoryStore.selectedProducts;
            final currentVal = row.selectedProduct.value;

            if (currentVal == null && row.productName.isNotEmpty) {
              return DropdownButtonHideUnderline(
                child: DropdownButton<ProductModel>(
                  value: null,
                  hint: Text(
                    row.productName,
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 10,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 14),
                  menuMaxHeight: 300,
                  items: storeProducts
                      .where((p) => p.id != null)
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p.product,
                            style: AppTheme.bodySmall.copyWith(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: locked
                      ? null
                      : (ProductModel? val) {
                          if (val == null) return;
                          selectedProductRow.value = i;
                          _fillRowFromProduct(row, val);
                          productRows.refresh();
                          _checkAndAddProductRow();
                          _recalculateTotalVolume();
                          _scheduleProductAutoSave(i);
                          _scheduleDistributionAutoSave();
                        },
                ),
              );
            }

            final validVal =
                currentVal != null &&
                    storeProducts.any((p) => p.id == currentVal.id)
                ? currentVal
                : null;

            return DropdownButtonHideUnderline(
              child: DropdownButton<ProductModel>(
                value: validVal,
                hint: Text(
                  "Select",
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                isExpanded: true,
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down, size: 14),
                menuMaxHeight: 300,
                items: storeProducts
                    .where((p) => p.id != null)
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p.product,
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: locked
                    ? null
                    : (ProductModel? val) {
                        if (val == null) return;
                        selectedProductRow.value = i;
                        _fillRowFromProduct(row, val);
                        productRows.refresh();
                        _checkAndAddProductRow();
                        _recalculateTotalVolume();
                        _scheduleProductAutoSave(i);
                        _scheduleDistributionAutoSave();
                      },
              ),
            );
          }),
        ),
      ),

      // 2–5. Static read-only cells
      DataCell(_staticField(row.code, 80)),
      DataCell(_staticField(row.sg, 70)),
      DataCell(_staticField(row.unit, 70)),
      DataCell(
        _staticField(
          row.price > 0 ? row.price.toStringAsFixed(2) : '',
          90,
          right: true,
        ),
      ),

      // 6. Initial
      DataCell(
        _editField(
          key: ValueKey('init_${identityHashCode(row)}'),
          value: row.initial,
          width: 75,
          locked: locked,
          onChange: (v) {
            row.initial = v;
            _onFieldChanged(i);
            _checkAndAddProductRow();
          },
        ),
      ),

      // 7. Adjust
      DataCell(
        _editField(
          key: ValueKey('adj_${identityHashCode(row)}'),
          value: row.adjust,
          width: 75,
          locked: locked,
          onChange: (v) {
            row.adjust = v;
            _onFieldChanged(i);
            _checkAndAddProductRow();
          },
        ),
      ),

      // 8. Used
      DataCell(
        Obx(() {
          final isUsedMode = selectedMethod.value == "Used";
          return _editField(
            key: ValueKey('used_${identityHashCode(row)}_$isUsedMode'),
            value: row.used,
            width: 75,
            locked: locked,
            highlighted: isUsedMode,
            onChange: (v) {
              row.used = v;
              _onFieldChanged(i);
              _checkAndAddProductRow();
            },
          );
        }),
      ),

      // 9. Final
      DataCell(
        Obx(() {
          final fv = row.calculatedFinal.value;
          return Container(
            width: 75,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              row.productName.isNotEmpty ? fv.toStringAsFixed(2) : '',
              textAlign: TextAlign.right,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: fv < 0 ? Colors.red : Colors.black,
              ),
            ),
          );
        }),
      ),

      // 10. Cost
      DataCell(
        Container(
          width: 90,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
          ),
          child: Obx(() {
            final cv = row.calculatedCost.value;
            return Text(
              cv > 0 ? cv.toStringAsFixed(2) : '',
              textAlign: TextAlign.right,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            );
          }),
        ),
      ),

      // 11. Vol
      DataCell(
        Container(
          width: 75,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.03),
          ),
          child: Obx(() {
            final vv = row.calculatedVolume.value;
            return Text(
              vv > 0 ? vv.toStringAsFixed(3) : '',
              textAlign: TextAlign.right,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            );
          }),
        ),
      ),
    ];
  }

  Widget _staticField(String text, double width, {bool right = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _editField({
    required Key key,
    required String value,
    required double width,
    required Function(String) onChange,
    bool locked = false,
    bool highlighted = false,
  }) {
    return Container(
      key: key,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: highlighted ? const Color(0xFFE8F4FD) : null,
      child: TextFormField(
        initialValue: value,
        enabled: !locked,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: InputBorder.none,
        ),
        onChanged: onChange,
      ),
    );
  }

  List<DataCell> _withProductRowMenu(List<DataCell> cells, int index) {
    return cells
        .map(
          (cell) => DataCell(
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapDown: (details) =>
                  _showProductRowMenu(details, index),
              child: cell.child,
            ),
          ),
        )
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BOTTOM SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 310, child: _buildDistributeTable()),
        const SizedBox(width: 12),
        Expanded(child: _buildRightControls()),
      ],
    );
  }

  // ── Distribute Table ──────────────────────────────────────────────────────
  Widget _buildDistributeTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // ── Header row with title + action buttons ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Text(
                  "Distribute to",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                // Calculate button
                Obx(
                  () => _distributeHeaderBtn(
                    icon: Icons.calculate_outlined,
                    tooltip: 'Calculate distribution',
                    onTap: dashboardController.isLocked.value
                        ? null
                        : _calculateDistribution,
                    color: Colors.grey.shade100,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Obx(
                  () => _distributeHeaderBtn(
                    icon: Icons.add,
                    tooltip: 'Add row',
                    onTap: dashboardController.isLocked.value
                        ? null
                        : () {
                            _addDistributeRow();
                            _scheduleDistributionAutoSave();
                          },
                    color: Colors.grey.shade100,
                    iconColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // ── Table header ──
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                _distHeaderCell('Pit', 180),
                _distHeaderCell('Vol (bbl)', 110, right: true),
              ],
            ),
          ),

          // ── Rows ──
          SizedBox(
            height: 185,
            child: SingleChildScrollView(
              child: Obx(() {
                // Build the dropdown items list: empty + Active System + unselected pits
                final unselectedPits = pitController.unselectedPits
                    .where((p) => p.id != null && p.pitName.isNotEmpty)
                    .toList();

                return Column(
                  children: List.generate(distributeRows.length, (i) {
                    final dr = distributeRows[i];
                    final isSelected = selectedDistributeRow.value == i;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => selectedDistributeRow.value = i,
                      onSecondaryTapDown: (details) =>
                          _showDistributeRowMenu(details, i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.successColor.withOpacity(0.06)
                              : (i % 2 == 0
                                    ? Colors.white
                                    : Colors.grey.shade50),
                          border: Border(
                            left: isSelected
                                ? BorderSide(
                                    color: AppTheme.successColor,
                                    width: 2,
                                  )
                                : BorderSide.none,
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Pit dropdown cell
                            SizedBox(
                              width: 180,
                              height: 32,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: _buildDistributePitDropdown(
                                  dr,
                                  i,
                                  unselectedPits,
                                ),
                              ),
                            ),
                            // Volume divider
                            Container(
                              width: 1,
                              height: 32,
                              color: Colors.grey.shade200,
                            ),
                            // Volume input cell
                            SizedBox(
                              width: 110,
                              height: 32,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: TextField(
                                  controller: dr.volumeController,
                                  enabled: !dashboardController.isLocked.value,
                                  style: AppTheme.bodySmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.right,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (v) =>
                                      _onDistributeVolumeChanged(i, v),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributePitDropdown(
    DistributeRowData dr,
    int index,
    List unselectedPits,
  ) {
    final currentPit = dr.pit.trim();
    final normalizedNames = <String>{};
    final dropdownPitNames = <String>[];

    for (final pit in unselectedPits) {
      final pitName = pit.pitName.toString().trim();
      final normalized = pitName.toLowerCase();
      if (pitName.isEmpty ||
          normalized == kEmpty ||
          normalized == kActiveSystem.toLowerCase() ||
          !normalizedNames.add(normalized)) {
        continue;
      }
      dropdownPitNames.add(pitName);
    }

    if (currentPit.isNotEmpty &&
        currentPit.toLowerCase() != kActiveSystem.toLowerCase() &&
        normalizedNames.add(currentPit.toLowerCase())) {
      dropdownPitNames.insert(0, currentPit);
    }

    // Build items: empty option + Active System + unique storage pits
    final items = <DropdownMenuItem<String>>[
      // Empty option to clear selection
      DropdownMenuItem<String>(
        value: kEmpty,
        child: Text('', style: AppTheme.bodySmall.copyWith(fontSize: 11)),
      ),
      // Active System fixed option
      DropdownMenuItem<String>(
        value: kActiveSystem,
        child: Row(
          children: [
            Icon(
              Icons.layers_outlined,
              size: 12,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              kActiveSystem,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      // Unselected pits from API
      ...dropdownPitNames.map(
        (pitName) => DropdownMenuItem<String>(
          value: pitName,
          child: Text(
            pitName,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    // Validate current value
    final validValues = {kEmpty, kActiveSystem, ...dropdownPitNames};
    final currentValue = validValues.contains(currentPit) ? currentPit : kEmpty;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentValue,
        isExpanded: true,
        isDense: true,
        icon: Icon(
          Icons.arrow_drop_down,
          size: 14,
          color: Colors.grey.shade500,
        ),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 10,
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
        menuMaxHeight: 250,
        items: items,
        onChanged: dashboardController.isLocked.value
            ? null
            : (String? val) {
                if (val == null) return;
                selectedDistributeRow.value = index;
                _onDistributePitSelected(index, val);
              },
      ),
    );
  }

  Widget _distributeHeaderBtn({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color? color,
    Color? iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: onTap == null
                ? Colors.grey.shade100
                : (color ?? Colors.grey.shade100),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(
            icon,
            size: 13,
            color: onTap == null
                ? Colors.grey.shade400
                : (iconColor ?? AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _distHeaderCell(String text, double width, {bool right = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Obx(
        () => Text(
          AppUnits.label(text),
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: AppTheme.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // ── Right Controls ────────────────────────────────────────────────────────
  Widget _buildRightControls() {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Row(
              children: [
                InkWell(
                  onTap: dashboardController.isLocked.value
                      ? null
                      : () {
                          addWater.value = !addWater.value;
                          _recalculateTotalVolume();
                          _scheduleDistributionAutoSave();
                        },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: addWater.value
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: addWater.value
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: addWater.value
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade400,
                            ),
                            color: addWater.value
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                          ),
                          child: addWater.value
                              ? const Icon(
                                  Icons.check,
                                  size: 11,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Add Water",
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (addWater.value) ...[
                  const SizedBox(width: 10),
                  Expanded(child: _waterField()),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                "Total Vol.",
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _openVolumeByGroupDialog,
                icon: Icon(
                  Icons.help_outline,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                tooltip: 'Volume By Group',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(
                  () => Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              totalVolumeDisplay.value,
                              textAlign: TextAlign.right,
                              style: AppTheme.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "bbl",
                              style: AppTheme.bodySmall.copyWith(
                                fontSize: 10,
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 13,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Active System follows Total Vol. Storage pit rows are saved separately for Volume Name End Vol. calculations.",
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 9,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _waterField() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: waterVolumeController,
              enabled: !dashboardController.isLocked.value,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: InputBorder.none,
              ),
              onChanged: (_) {
                _recalculateTotalVolume();
                _rebalanceDistributeVolumes();
                _scheduleDistributionAutoSave();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
            child: Center(
              child: Text(
                "bbl",
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class ProductRowData {
  final Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);

  String productName = '';
  String code = '';
  String sg = '';
  String unit = '';
  double price = 0.0;
  String initial = '';
  String adjust = '';
  String used = '';
  String? savedId;
  double received = 0.0;
  double returned = 0.0;

  final RxDouble calculatedCost = 0.0.obs;
  final RxDouble calculatedVolume = 0.0.obs;
  final RxDouble calculatedFinal = 0.0.obs;

  ({double amount, String unitClass}) _parseUnitValue() {
    final raw = unit.trim();
    final match = RegExp(r'^([0-9]*\.?[0-9]+)\s*([a-zA-Z]+)').firstMatch(raw);
    final amount = match == null
        ? 1.0
        : (double.tryParse(match.group(1) ?? '') ?? 1.0)
              .clamp(1.0, double.infinity)
              .toDouble();
    return (
      amount: amount,
      unitClass: (match?.group(2) ?? raw).trim().toLowerCase(),
    );
  }

  double _calculateVolumeBbl(double usedValue, double sgValue) {
    if (usedValue <= 0) return 0.0;

    final parsedUnit = _parseUnitValue();
    final totalUnits = usedValue * parsedUnit.amount;
    final unitClass = parsedUnit.unitClass;

    if (unitClass.contains('gal')) return totalUnits / 42;
    if (unitClass.contains('bbl')) return totalUnits;
    if (unitClass.contains('kg')) {
      return sgValue > 0 ? totalUnits / (sgValue * 158.987) : 0.0;
    }
    if (unitClass == 'lb' ||
        unitClass == 'lbs' ||
        unitClass == 'lbm' ||
        unitClass.contains('pound')) {
      return sgValue > 0 ? totalUnits / (sgValue * 350) : 0.0;
    }
    if (unitClass == 'ton' ||
        unitClass == 'tons' ||
        unitClass == 'tonne' ||
        unitClass == 'tonnes' ||
        unitClass == 'mt') {
      return sgValue > 0 ? (totalUnits * 2000) / (sgValue * 350) : 0.0;
    }
    if (unitClass == 'l' ||
        unitClass == 'ltr' ||
        unitClass == 'liter' ||
        unitClass == 'liters' ||
        unitClass == 'litre' ||
        unitClass == 'litres') {
      return totalUnits / 158.987;
    }
    if (unitClass == 'ml') return totalUnits / 158987;
    if (unitClass == 'm3' || unitClass == 'm^3') return totalUnits * 6.28981;

    return sgValue > 0 ? totalUnits / (sgValue * 158.987) : 0.0;
  }

  void recalculate() {
    final iVal = double.tryParse(initial) ?? 0.0;
    final aVal = double.tryParse(adjust) ?? 0.0;
    final uVal = double.tryParse(used) ?? 0.0;
    final sVal = double.tryParse(sg) ?? 0.0;

    calculatedFinal.value = iVal + received - returned - aVal - uVal;
    calculatedCost.value = uVal * price;
    calculatedVolume.value = double.parse(
      _calculateVolumeBbl(uVal, sVal).toStringAsFixed(3),
    );
  }
}

class DistributeRowData {
  String pit;
  String volume;
  final TextEditingController volumeController = TextEditingController();

  DistributeRowData({this.pit = '', this.volume = ''}) {
    volumeController.text = volume;
  }
}
