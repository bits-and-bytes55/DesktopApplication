import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/service_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/consume_service_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'operation_desktop_ui.dart';
import 'operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ConsumeServicesView extends StatefulWidget {
  const ConsumeServicesView({super.key, required this.instanceKey});

  final String instanceKey;

  @override
  State<ConsumeServicesView> createState() => _ConsumeServicesViewState();
}

class _ConsumeServicesViewState extends State<ConsumeServicesView> {
  final dashboardController = Get.find<DashboardController>();
  final serviceController = Get.put(ServiceController());
  late final ConsumeServiceController consumeServiceController;
  final inventorySnapshotController = InventorySnapshotController();

  final RxString selectedMethod = "Used".obs;

  // ── Dropdown source data ──
  final RxList<PackageItem> packages = <PackageItem>[].obs;
  final RxList<ServiceItem> services = <ServiceItem>[].obs;
  final RxList<EngineeringItem> engineering = <EngineeringItem>[].obs;

  // ── Row data ──
  final RxList<PackageRowData> packageRows = <PackageRowData>[].obs;
  final RxList<ServiceRowData> serviceRows = <ServiceRowData>[].obs;
  final RxList<EngineeringRowData> engineeringRows = <EngineeringRowData>[].obs;

  // ── Per-row flags ──
  final RxList<bool> packageRowLoading = <bool>[].obs;
  final RxList<bool> serviceRowLoading = <bool>[].obs;
  final RxList<bool> engineeringRowLoading = <bool>[].obs;
  final RxList<bool> packageRowSaving = <bool>[].obs;
  final RxList<bool> serviceRowSaving = <bool>[].obs;
  final RxList<bool> engineeringRowSaving = <bool>[].obs;
  final RxList<bool> packageRowDeleting = <bool>[].obs;
  final RxList<bool> serviceRowDeleting = <bool>[].obs;
  final RxList<bool> engineeringRowDeleting = <bool>[].obs;

  // ✅ FIX: prevent duplicate creates — same as ConsumeProductView
  final Set<int> _pkgSavingInProgress = {};
  final Set<int> _srvSavingInProgress = {};
  final Set<int> _engSavingInProgress = {};
  final Map<int, Timer> _pkgAutosaveTimers = {};
  final Map<int, Timer> _srvAutosaveTimers = {};
  final Map<int, Timer> _engAutosaveTimers = {};

  final RxInt selectedPackageRow = 0.obs;
  final RxInt selectedServiceRow = 0.obs;
  final RxInt selectedEngineeringRow = 0.obs;

  final RxBool isSaving = false.obs;
  Timer? _inventorySnapshotRefreshTimer;
  Worker? _wellWorker;
  Worker? _reportWorker;
  Map<String, dynamic>? _packageClipboard;
  Map<String, dynamic>? _serviceClipboard;
  Map<String, dynamic>? _engineeringClipboard;

  @override
  void initState() {
    super.initState();
    consumeServiceController = ConsumeServiceController(
      operationInstanceKey: widget.instanceKey,
    );
    _resetAllRows();
    Future.microtask(_reloadScopedData);
    _wellWorker = ever<String>(
      padWellContext.selectedWellId,
      (_) => _reloadScopedData(),
    );
    _reportWorker = ever<String>(reportContext.selectedReportId, (reportId) {
      if (reportId.trim().isEmpty) return;
      _reloadScopedData();
    });
  }

  @override
  void dispose() {
    _inventorySnapshotRefreshTimer?.cancel();
    for (final timer in _pkgAutosaveTimers.values) {
      timer.cancel();
    }
    for (final timer in _srvAutosaveTimers.values) {
      timer.cancel();
    }
    for (final timer in _engAutosaveTimers.values) {
      timer.cancel();
    }
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (var r in packageRows) r.dispose();
    for (var r in serviceRows) r.dispose();
    for (var r in engineeringRows) r.dispose();
    super.dispose();
  }

  Future<void> _reloadScopedData() async {
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();
    if (wellId.isEmpty) {
      _clearDropdownData();
      _resetAllRows();
      return;
    }
    if (reportId.isEmpty) return;

    await _loadDropdownData();
    await _fetchAllData();
  }

  // ─────────────────────────────────────────────
  //  Load dropdown source data
  // ─────────────────────────────────────────────
  Future<void> _loadDropdownData() async {
    try {
      final wellId = currentBackendWellId.trim();
      if (wellId.isEmpty) {
        _clearDropdownData();
        return;
      }
      final pkgs = await InventoryProductsService.fetchPackages(wellId);
      final srvs = await InventoryProductsService.fetchServices(wellId);
      final engs = await InventoryProductsService.fetchEngineering(wellId);
      packages.value = pkgs;
      services.value = srvs;
      engineering.value = engs;
      print(
        '🟢 [LOAD] packages=${pkgs.length} services=${srvs.length} engineering=${engs.length}',
      );
    } catch (e) {
      print('🔴 [LOAD] Error: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  Fetch saved data — with name matching
  // ─────────────────────────────────────────────
  Future<void> _fetchAllData() async {
    print('🔵 [FETCH] Fetching all saved data...');
    try {
      // ── PACKAGES ──
      final wellId = currentBackendWellId.trim();
      final reportId = reportContext.selectedReportId.value.trim();
      if (wellId.isEmpty) {
        _resetAllRows();
        return;
      }
      if (reportId.isEmpty) return;

      final pkgData = await consumeServiceController.getAllConsumePackages();
      for (var r in packageRows) r.dispose();
      packageRows.clear();
      packageRowLoading.clear();
      packageRowSaving.clear();
      packageRowDeleting.clear();
      _pkgSavingInProgress.clear();

      for (final item in pkgData) {
        final row = PackageRowData();
        // ✅ FIX: name seedha String se read karo
        row.selectedItem = item['packageName']?.toString() ?? '';
        row.code = item['code']?.toString() ?? '';
        row.unit = item['unit']?.toString() ?? '';
        row.price = _toDouble(item['price']);
        row.initial = _numStr(item['initial']);
        row.used = _numStr(item['used']);
        row.finalValue = _numStr(item['final']);
        row.cost = _toDouble(item['cost']);
        row.savedId = item['_id']?.toString();
        packageRows.add(row);
        packageRowLoading.add(false);
        packageRowSaving.add(false);
        packageRowDeleting.add(false);
      }
      packageRows.add(PackageRowData());
      packageRowLoading.add(false);
      packageRowSaving.add(false);
      packageRowDeleting.add(false);

      // ── SERVICES ──
      final srvData = await consumeServiceController.getAllConsumeServices();
      for (var r in serviceRows) r.dispose();
      serviceRows.clear();
      serviceRowLoading.clear();
      serviceRowSaving.clear();
      serviceRowDeleting.clear();
      _srvSavingInProgress.clear();

      for (final item in srvData) {
        final row = ServiceRowData();
        // ✅ FIX: name seedha String se read karo
        row.selectedItem = item['serviceName']?.toString() ?? '';
        row.code = item['code']?.toString() ?? '';
        row.unit = item['unit']?.toString() ?? '';
        row.price = _toDouble(item['price']);
        row.usage = _numStr(item['usage']);
        row.cost = _toDouble(item['cost']);
        row.savedId = item['_id']?.toString();
        serviceRows.add(row);
        serviceRowLoading.add(false);
        serviceRowSaving.add(false);
        serviceRowDeleting.add(false);
      }
      serviceRows.add(ServiceRowData());
      serviceRowLoading.add(false);
      serviceRowSaving.add(false);
      serviceRowDeleting.add(false);

      // ── ENGINEERING ──
      final engData = await consumeServiceController.getAllConsumeEngineering();
      for (var r in engineeringRows) r.dispose();
      engineeringRows.clear();
      engineeringRowLoading.clear();
      engineeringRowSaving.clear();
      engineeringRowDeleting.clear();
      _engSavingInProgress.clear();

      for (final item in engData) {
        final row = EngineeringRowData();
        // ✅ FIX: name seedha String se read karo
        row.selectedItem = item['engineeringName']?.toString() ?? '';
        row.code = item['code']?.toString() ?? '';
        row.unit = item['unit']?.toString() ?? '';
        row.price = _toDouble(item['price']);
        row.usage = _numStr(item['usage']);
        row.cost = _toDouble(item['cost']);
        row.savedId = item['_id']?.toString();
        engineeringRows.add(row);
        engineeringRowLoading.add(false);
        engineeringRowSaving.add(false);
        engineeringRowDeleting.add(false);
      }
      engineeringRows.add(EngineeringRowData());
      engineeringRowLoading.add(false);
      engineeringRowSaving.add(false);
      engineeringRowDeleting.add(false);

      print('🟢 [FETCH] All data loaded');
    } catch (e) {
      print('🔴 [FETCH] Error: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────
  void _clearDropdownData() {
    packages.clear();
    services.clear();
    engineering.clear();
  }

  void _resetAllRows() {
    for (var r in packageRows) {
      r.dispose();
    }
    for (var r in serviceRows) {
      r.dispose();
    }
    for (var r in engineeringRows) {
      r.dispose();
    }

    packageRows
      ..clear()
      ..add(PackageRowData());
    serviceRows
      ..clear()
      ..add(ServiceRowData());
    engineeringRows
      ..clear()
      ..add(EngineeringRowData());

    packageRowLoading
      ..clear()
      ..add(false);
    serviceRowLoading
      ..clear()
      ..add(false);
    engineeringRowLoading
      ..clear()
      ..add(false);

    packageRowSaving
      ..clear()
      ..add(false);
    serviceRowSaving
      ..clear()
      ..add(false);
    engineeringRowSaving
      ..clear()
      ..add(false);

    packageRowDeleting
      ..clear()
      ..add(false);
    serviceRowDeleting
      ..clear()
      ..add(false);
    engineeringRowDeleting
      ..clear()
      ..add(false);

    _pkgSavingInProgress.clear();
    _srvSavingInProgress.clear();
    _engSavingInProgress.clear();
    for (final timer in _pkgAutosaveTimers.values) {
      timer.cancel();
    }
    for (final timer in _srvAutosaveTimers.values) {
      timer.cancel();
    }
    for (final timer in _engAutosaveTimers.values) {
      timer.cancel();
    }
    _pkgAutosaveTimers.clear();
    _srvAutosaveTimers.clear();
    _engAutosaveTimers.clear();
  }

  double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  String _numStr(dynamic v) {
    final d = _toDouble(v);
    return d == 0.0 ? '' : d.toString();
  }

  void _scheduleInventorySnapshotRefresh() {
    _inventorySnapshotRefreshTimer?.cancel();
    _inventorySnapshotRefreshTimer = Timer(
      const Duration(milliseconds: 900),
      () async {
        final result = await inventorySnapshotController
            .generateInventorySnapshot();
        if (result['success'] != true) {
          print('Snapshot refresh failed: ${result['message']}');
        }
      },
    );
  }

  bool _hasPackageData(PackageRowData row) {
    return row.savedId != null ||
        row.selectedItem.trim().isNotEmpty ||
        row.code.trim().isNotEmpty ||
        row.unit.trim().isNotEmpty ||
        row.initial.trim().isNotEmpty ||
        row.used.trim().isNotEmpty ||
        row.price > 0 ||
        row.cost > 0;
  }

  bool _hasServiceData(ServiceRowData row) {
    return row.savedId != null ||
        row.selectedItem.trim().isNotEmpty ||
        row.code.trim().isNotEmpty ||
        row.unit.trim().isNotEmpty ||
        row.usage.trim().isNotEmpty ||
        row.price > 0 ||
        row.cost > 0;
  }

  bool _hasEngineeringData(EngineeringRowData row) {
    return row.savedId != null ||
        row.selectedItem.trim().isNotEmpty ||
        row.code.trim().isNotEmpty ||
        row.unit.trim().isNotEmpty ||
        row.usage.trim().isNotEmpty ||
        row.price > 0 ||
        row.cost > 0;
  }

  Map<String, dynamic> _packageSnapshot(PackageRowData row) => {
    'selectedItem': row.selectedItem,
    'code': row.code,
    'unit': row.unit,
    'price': row.price,
    'initial': row.initial,
    'used': row.used,
    'finalValue': row.finalValue,
    'cost': row.cost,
  };

  Map<String, dynamic> _serviceSnapshot(ServiceRowData row) => {
    'selectedItem': row.selectedItem,
    'code': row.code,
    'unit': row.unit,
    'price': row.price,
    'usage': row.usage,
    'cost': row.cost,
  };

  Map<String, dynamic> _engineeringSnapshot(EngineeringRowData row) => {
    'selectedItem': row.selectedItem,
    'code': row.code,
    'unit': row.unit,
    'price': row.price,
    'usage': row.usage,
    'cost': row.cost,
  };

  void _applyPackageSnapshot(PackageRowData row, Map<String, dynamic> data) {
    row.savedId = null;
    row.selectedItem = (data['selectedItem'] ?? '').toString();
    row.code = (data['code'] ?? '').toString();
    row.unit = (data['unit'] ?? '').toString();
    row.price = (data['price'] as num?)?.toDouble() ?? 0.0;
    row.initial = (data['initial'] ?? '').toString();
    row.used = (data['used'] ?? '').toString();
    row.finalValue = (data['finalValue'] ?? '').toString();
    row.cost = (data['cost'] as num?)?.toDouble() ?? 0.0;
  }

  void _applyServiceSnapshot(ServiceRowData row, Map<String, dynamic> data) {
    row.savedId = null;
    row.selectedItem = (data['selectedItem'] ?? '').toString();
    row.code = (data['code'] ?? '').toString();
    row.unit = (data['unit'] ?? '').toString();
    row.price = (data['price'] as num?)?.toDouble() ?? 0.0;
    row.usage = (data['usage'] ?? '').toString();
    row.cost = (data['cost'] as num?)?.toDouble() ?? 0.0;
  }

  void _applyEngineeringSnapshot(
    EngineeringRowData row,
    Map<String, dynamic> data,
  ) {
    row.savedId = null;
    row.selectedItem = (data['selectedItem'] ?? '').toString();
    row.code = (data['code'] ?? '').toString();
    row.unit = (data['unit'] ?? '').toString();
    row.price = (data['price'] as num?)?.toDouble() ?? 0.0;
    row.usage = (data['usage'] ?? '').toString();
    row.cost = (data['cost'] as num?)?.toDouble() ?? 0.0;
  }

  void _clearBaseRow(BaseRowData row) {
    row.savedId = null;
    row.selectedItem = '';
    row.code = '';
    row.unit = '';
    row.price = 0.0;
    row.initial = '';
    row.used = '';
    row.finalValue = '';
    row.cost = 0.0;
    if (row is EngineeringRowData) {
      row.usage = '';
    }
  }

  void _insertSectionRow<T extends BaseRowData>(
    RxList<T> rows,
    RxList<bool> loading,
    RxList<bool> saving,
    RxList<bool> deleting,
    T row,
    int index,
  ) {
    rows.insert(index, row);
    loading.insert(index, false);
    saving.insert(index, false);
    deleting.insert(index, false);
    rows.refresh();
  }

  void _moveSectionRow<T extends BaseRowData>(
    RxList<T> rows,
    RxList<bool> loading,
    RxList<bool> saving,
    RxList<bool> deleting,
    int from,
    int to,
  ) {
    if (from < 0 || from >= rows.length || to < 0 || to >= rows.length) return;
    final row = rows.removeAt(from);
    final load = loading.removeAt(from);
    final save = saving.removeAt(from);
    final del = deleting.removeAt(from);
    rows.insert(to, row);
    loading.insert(to, load);
    saving.insert(to, save);
    deleting.insert(to, del);
    rows.refresh();
  }

  List<DataCell> _withRowMenu(
    List<DataCell> cells,
    Future<void> Function(TapDownDetails details) onMenu,
  ) {
    return cells
        .map(
          (cell) => DataCell(
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onSecondaryTapDown: (details) {
                onMenu(details);
              },
              child: cell.child,
            ),
          ),
        )
        .toList();
  }

  Future<void> _showPackageRowMenu(TapDownDetails details, int index) async {
    if (index < 0 || index >= packageRows.length) return;
    selectedPackageRow.value = index;
    final row = packageRows[index];
    final action = await showOperationRowMenu(
      context: context,
      details: details,
      canEdit: !dashboardController.isLocked.value,
      hasData: _hasPackageData(row),
      canPaste: _packageClipboard != null,
      canInsertRow: true,
      canDeleteRow: true,
      canMoveTop: index > 0,
      canMoveBottom: index < packageRows.length - 1,
    );
    switch (action) {
      case 'cut':
        _packageClipboard = _packageSnapshot(row);
        await _deletePackageRow(index);
        break;
      case 'copy':
        _packageClipboard = _packageSnapshot(row);
        break;
      case 'paste':
        if (_packageClipboard != null) {
          _applyPackageSnapshot(row, _packageClipboard!);
          packageRows.refresh();
          _checkAndAddRow(
            packageRows,
            packageRowLoading,
            packageRowSaving,
            packageRowDeleting,
          );
          _autoSavePackage(index);
        }
        break;
      case 'delete':
      case 'clear':
      case 'deleteRow':
        await _deletePackageRow(index);
        break;
      case 'insertRow':
        _insertSectionRow(
          packageRows,
          packageRowLoading,
          packageRowSaving,
          packageRowDeleting,
          PackageRowData(),
          index,
        );
        break;
      case 'top':
        _moveSectionRow(
          packageRows,
          packageRowLoading,
          packageRowSaving,
          packageRowDeleting,
          index,
          0,
        );
        break;
      case 'bottom':
        _moveSectionRow(
          packageRows,
          packageRowLoading,
          packageRowSaving,
          packageRowDeleting,
          index,
          packageRows.length - 1,
        );
        break;
    }
  }

  Future<void> _showServiceRowMenu(TapDownDetails details, int index) async {
    if (index < 0 || index >= serviceRows.length) return;
    selectedServiceRow.value = index;
    final row = serviceRows[index];
    final action = await showOperationRowMenu(
      context: context,
      details: details,
      canEdit: !dashboardController.isLocked.value,
      hasData: _hasServiceData(row),
      canPaste: _serviceClipboard != null,
      canInsertRow: true,
      canDeleteRow: true,
      canMoveTop: index > 0,
      canMoveBottom: index < serviceRows.length - 1,
    );
    switch (action) {
      case 'cut':
        _serviceClipboard = _serviceSnapshot(row);
        await _deleteServiceRow(index);
        break;
      case 'copy':
        _serviceClipboard = _serviceSnapshot(row);
        break;
      case 'paste':
        if (_serviceClipboard != null) {
          _applyServiceSnapshot(row, _serviceClipboard!);
          serviceRows.refresh();
          _checkAndAddRow(
            serviceRows,
            serviceRowLoading,
            serviceRowSaving,
            serviceRowDeleting,
          );
          _autoSaveService(index);
        }
        break;
      case 'delete':
      case 'clear':
      case 'deleteRow':
        await _deleteServiceRow(index);
        break;
      case 'insertRow':
        _insertSectionRow(
          serviceRows,
          serviceRowLoading,
          serviceRowSaving,
          serviceRowDeleting,
          ServiceRowData(),
          index,
        );
        break;
      case 'top':
        _moveSectionRow(
          serviceRows,
          serviceRowLoading,
          serviceRowSaving,
          serviceRowDeleting,
          index,
          0,
        );
        break;
      case 'bottom':
        _moveSectionRow(
          serviceRows,
          serviceRowLoading,
          serviceRowSaving,
          serviceRowDeleting,
          index,
          serviceRows.length - 1,
        );
        break;
    }
  }

  Future<void> _showEngineeringRowMenu(
    TapDownDetails details,
    int index,
  ) async {
    if (index < 0 || index >= engineeringRows.length) return;
    selectedEngineeringRow.value = index;
    final row = engineeringRows[index];
    final action = await showOperationRowMenu(
      context: context,
      details: details,
      canEdit: !dashboardController.isLocked.value,
      hasData: _hasEngineeringData(row),
      canPaste: _engineeringClipboard != null,
      canInsertRow: true,
      canDeleteRow: true,
      canMoveTop: index > 0,
      canMoveBottom: index < engineeringRows.length - 1,
    );
    switch (action) {
      case 'cut':
        _engineeringClipboard = _engineeringSnapshot(row);
        await _deleteEngineeringRow(index);
        break;
      case 'copy':
        _engineeringClipboard = _engineeringSnapshot(row);
        break;
      case 'paste':
        if (_engineeringClipboard != null) {
          _applyEngineeringSnapshot(row, _engineeringClipboard!);
          engineeringRows.refresh();
          _checkAndAddRow(
            engineeringRows,
            engineeringRowLoading,
            engineeringRowSaving,
            engineeringRowDeleting,
          );
          _autoSaveEngineering(index);
        }
        break;
      case 'delete':
      case 'clear':
      case 'deleteRow':
        await _deleteEngineeringRow(index);
        break;
      case 'insertRow':
        _insertSectionRow(
          engineeringRows,
          engineeringRowLoading,
          engineeringRowSaving,
          engineeringRowDeleting,
          EngineeringRowData(),
          index,
        );
        break;
      case 'top':
        _moveSectionRow(
          engineeringRows,
          engineeringRowLoading,
          engineeringRowSaving,
          engineeringRowDeleting,
          index,
          0,
        );
        break;
      case 'bottom':
        _moveSectionRow(
          engineeringRows,
          engineeringRowLoading,
          engineeringRowSaving,
          engineeringRowDeleting,
          index,
          engineeringRows.length - 1,
        );
        break;
    }
  }

  // ─────────────────────────────────────────────
  //  Cost calculated check
  // ─────────────────────────────────────────────
  bool _isPkgCostReady(PackageRowData row) {
    final used = double.tryParse(row.used) ?? 0.0;
    return used > 0 && row.price > 0 && row.selectedItem.isNotEmpty;
  }

  bool _isSrvCostReady(ServiceRowData row) {
    final usage = double.tryParse(row.usage) ?? 0.0;
    return usage > 0 && row.price > 0 && row.selectedItem.isNotEmpty;
  }

  bool _isEngCostReady(EngineeringRowData row) {
    final usage = double.tryParse(row.usage) ?? 0.0;
    return usage > 0 && row.price > 0 && row.selectedItem.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  //  CALCULATION
  // ─────────────────────────────────────────────
  void _calculatePackage(int index) {
    if (dashboardController.isLocked.value) return;
    final row = packageRows[index];
    if (row.selectedItem.isEmpty) return;
    final initial = double.tryParse(row.initial) ?? 0.0;
    final used = double.tryParse(row.used) ?? 0.0;
    row.finalValue = (initial - used).toStringAsFixed(2);
    row.cost = used * row.price;
  }

  void _calculateService(int index) {
    if (dashboardController.isLocked.value) return;
    final row = serviceRows[index];
    if (row.selectedItem.isEmpty) return;
    final usage = double.tryParse(row.usage) ?? 0.0;
    row.cost = usage * row.price;
  }

  void _calculateEngineering(int index) {
    if (dashboardController.isLocked.value) return;
    final row = engineeringRows[index];
    if (row.selectedItem.isEmpty) return;
    final usage = double.tryParse(row.usage) ?? 0.0;
    row.cost = usage * row.price;
  }

  // ─────────────────────────────────────────────
  //  AUTO-SAVE — debounce + cost check
  // ─────────────────────────────────────────────
  void _autoSavePackage(int index) {
    if (dashboardController.isLocked.value) return;
    final row = packageRows[index];
    if (row.selectedItem.isEmpty) return;
    _calculatePackage(index);
    // ✅ FIX: debounce 600ms, cost check se pehle save nahi
    _pkgAutosaveTimers[index]?.cancel();
    _pkgAutosaveTimers[index] = Timer(const Duration(milliseconds: 600), () {
      if (index < packageRows.length && _isPkgCostReady(packageRows[index])) {
        _savePackageRow(index);
      }
    });
  }

  void _autoSaveService(int index) {
    if (dashboardController.isLocked.value) return;
    final row = serviceRows[index];
    if (row.selectedItem.isEmpty) return;
    _calculateService(index);
    _srvAutosaveTimers[index]?.cancel();
    _srvAutosaveTimers[index] = Timer(const Duration(milliseconds: 600), () {
      if (index < serviceRows.length && _isSrvCostReady(serviceRows[index])) {
        _saveServiceRow(index);
      }
    });
  }

  void _autoSaveEngineering(int index) {
    if (dashboardController.isLocked.value) return;
    final row = engineeringRows[index];
    if (row.selectedItem.isEmpty) return;
    _calculateEngineering(index);
    _engAutosaveTimers[index]?.cancel();
    _engAutosaveTimers[index] = Timer(const Duration(milliseconds: 600), () {
      if (index < engineeringRows.length &&
          _isEngCostReady(engineeringRows[index])) {
        _saveEngineeringRow(index);
      }
    });
  }

  // ─────────────────────────────────────────────
  //  SAVE PACKAGE
  // ─────────────────────────────────────────────
  Future<void> _savePackageRow(int index) async {
    if (dashboardController.isLocked.value) return;
    if (index >= packageRows.length) return;
    final row = packageRows[index];
    if (row.selectedItem.isEmpty) return;
    if (!_isPkgCostReady(row)) return;

    // ✅ FIX: duplicate save guard
    if (_pkgSavingInProgress.contains(index)) {
      print('⏳ [PKG] Row $index already saving — skip');
      return;
    }
    _pkgSavingInProgress.add(index);

    _calculatePackage(index);

    final initial = double.tryParse(row.initial) ?? 0.0;
    final used = double.tryParse(row.used) ?? 0.0;

    try {
      Map<String, dynamic> result;

      if (row.savedId == null) {
        print('🆕 [PKG] Creating row $index — name="${row.selectedItem}"');
        result = await consumeServiceController.createConsumePackage(
          packageName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          price: row.price,
          initial: initial,
          used: used,
        );
        if (result['success'] == true) {
          // ✅ FIX: savedId turant set karo
          row.savedId = result['data']?['_id']?.toString();
          _scheduleInventorySnapshotRefresh();
          print('✅ [PKG] Created — savedId=${row.savedId}');
        } else {
          _showError(result['message'] ?? 'Save failed');
        }
      } else {
        print('✏️ [PKG] Updating row $index — id=${row.savedId}');
        result = await consumeServiceController.updateConsumePackage(
          id: row.savedId!,
          packageName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          price: row.price,
          initial: initial,
          used: used,
        );
        if (result['success'] == true) {
          _scheduleInventorySnapshotRefresh();
          print('✅ [PKG] Updated — savedId=${row.savedId}');
        } else {
          _showError(result['message'] ?? 'Update failed');
        }
      }
    } catch (e) {
      print('🔴 [PKG] Exception: $e');
      _showError('Error: $e');
    } finally {
      _pkgSavingInProgress.remove(index);
    }
  }

  // ─────────────────────────────────────────────
  //  SAVE SERVICE
  // ─────────────────────────────────────────────
  Future<void> _saveServiceRow(int index) async {
    if (dashboardController.isLocked.value) return;
    if (index >= serviceRows.length) return;
    final row = serviceRows[index];
    if (row.selectedItem.isEmpty) return;
    if (!_isSrvCostReady(row)) return;

    // ✅ FIX: duplicate save guard
    if (_srvSavingInProgress.contains(index)) {
      print('⏳ [SRV] Row $index already saving — skip');
      return;
    }
    _srvSavingInProgress.add(index);

    _calculateService(index);

    final usage = double.tryParse(row.usage) ?? 0.0;

    try {
      Map<String, dynamic> result;

      if (row.savedId == null) {
        print('🆕 [SRV] Creating row $index — name="${row.selectedItem}"');
        result = await consumeServiceController.createConsumeService(
          serviceName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          price: row.price,
          usage: usage,
        );
        if (result['success'] == true) {
          row.savedId = result['data']?['_id']?.toString();
          _scheduleInventorySnapshotRefresh();
          print('✅ [SRV] Created — savedId=${row.savedId}');
        } else {
          _showError(result['message'] ?? 'Save failed');
        }
      } else {
        print('✏️ [SRV] Updating row $index — id=${row.savedId}');
        result = await consumeServiceController.updateConsumeService(
          id: row.savedId!,
          serviceName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          price: row.price,
          usage: usage,
        );
        if (result['success'] == true) {
          _scheduleInventorySnapshotRefresh();
          print('✅ [SRV] Updated — savedId=${row.savedId}');
        } else {
          _showError(result['message'] ?? 'Update failed');
        }
      }
    } catch (e) {
      print('🔴 [SRV] Exception: $e');
      _showError('Error: $e');
    } finally {
      _srvSavingInProgress.remove(index);
    }
  }

  // ─────────────────────────────────────────────
  //  SAVE ENGINEERING
  // ─────────────────────────────────────────────
  Future<void> _saveEngineeringRow(int index) async {
    if (dashboardController.isLocked.value) return;
    if (index >= engineeringRows.length) return;
    final row = engineeringRows[index];
    if (row.selectedItem.isEmpty) return;
    if (!_isEngCostReady(row)) return;

    // ✅ FIX: duplicate save guard
    if (_engSavingInProgress.contains(index)) {
      print('⏳ [ENG] Row $index already saving — skip');
      return;
    }
    _engSavingInProgress.add(index);

    _calculateEngineering(index);

    final usage = double.tryParse(row.usage) ?? 0.0;

    try {
      Map<String, dynamic> result;

      if (row.savedId == null) {
        print('🆕 [ENG] Creating row $index — name="${row.selectedItem}"');
        result = await consumeServiceController.createConsumeEngineering(
          engineeringName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          price: row.price,
          usage: usage,
        );
        if (result['success'] == true) {
          row.savedId = result['data']?['_id']?.toString();
          _scheduleInventorySnapshotRefresh();
          print('✅ [ENG] Created — savedId=${row.savedId}');
        } else {
          _showError(result['message'] ?? 'Save failed');
        }
      } else {
        print('✏️ [ENG] Updating row $index — id=${row.savedId}');
        result = await consumeServiceController.updateConsumeEngineering(
          id: row.savedId!,
          engineeringName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          price: row.price,
          usage: usage,
        );
        if (result['success'] == true) {
          _scheduleInventorySnapshotRefresh();
          print('✅ [ENG] Updated — savedId=${row.savedId}');
        } else {
          _showError(result['message'] ?? 'Update failed');
        }
      }
    } catch (e) {
      print('🔴 [ENG] Exception: $e');
      _showError('Error: $e');
    } finally {
      _engSavingInProgress.remove(index);
    }
  }

  // ─────────────────────────────────────────────
  //  DELETE
  // ─────────────────────────────────────────────
  void _removePackageRowFromUi(int index) {
    if (index < 0 || index >= packageRows.length) return;
    _pkgAutosaveTimers.remove(index)?.cancel();
    _pkgSavingInProgress.remove(index);
    final row = packageRows[index];
    if (packageRows.length > 1) {
      row.dispose();
      packageRows.removeAt(index);
      if (index < packageRowLoading.length) packageRowLoading.removeAt(index);
      if (index < packageRowSaving.length) packageRowSaving.removeAt(index);
      if (index < packageRowDeleting.length) packageRowDeleting.removeAt(index);
    } else {
      row.dispose();
      packageRows[index] = PackageRowData();
    }
  }

  void _removeServiceRowFromUi(int index) {
    if (index < 0 || index >= serviceRows.length) return;
    _srvAutosaveTimers.remove(index)?.cancel();
    _srvSavingInProgress.remove(index);
    final row = serviceRows[index];
    if (serviceRows.length > 1) {
      row.dispose();
      serviceRows.removeAt(index);
      if (index < serviceRowLoading.length) serviceRowLoading.removeAt(index);
      if (index < serviceRowSaving.length) serviceRowSaving.removeAt(index);
      if (index < serviceRowDeleting.length) serviceRowDeleting.removeAt(index);
    } else {
      row.dispose();
      serviceRows[index] = ServiceRowData();
    }
  }

  void _removeEngineeringRowFromUi(int index) {
    if (index < 0 || index >= engineeringRows.length) return;
    _engAutosaveTimers.remove(index)?.cancel();
    _engSavingInProgress.remove(index);
    final row = engineeringRows[index];
    if (engineeringRows.length > 1) {
      row.dispose();
      engineeringRows.removeAt(index);
      if (index < engineeringRowLoading.length) {
        engineeringRowLoading.removeAt(index);
      }
      if (index < engineeringRowSaving.length) {
        engineeringRowSaving.removeAt(index);
      }
      if (index < engineeringRowDeleting.length) {
        engineeringRowDeleting.removeAt(index);
      }
    } else {
      row.dispose();
      engineeringRows[index] = EngineeringRowData();
    }
  }

  Future<void> _deletePackageRow(int index) async {
    final row = packageRows[index];
    if (row.savedId != null) {
      try {
        final result = await consumeServiceController.deleteConsumePackage(
          row.savedId!,
        );
        if (result['success'] == true) {
          _removePackageRowFromUi(index);
          _scheduleInventorySnapshotRefresh();
          _showSuccess('Package deleted');
        } else {
          _showError(result['message'] ?? 'Delete failed');
        }
      } catch (e) {
        _showError('Error: $e');
      }
    } else {
      _removePackageRowFromUi(index);
    }
  }

  Future<void> _deleteServiceRow(int index) async {
    final row = serviceRows[index];
    if (row.savedId != null) {
      try {
        final result = await consumeServiceController.deleteConsumeService(
          row.savedId!,
        );
        if (result['success'] == true) {
          _removeServiceRowFromUi(index);
          _scheduleInventorySnapshotRefresh();
          _showSuccess('Service deleted');
        } else {
          _showError(result['message'] ?? 'Delete failed');
        }
      } catch (e) {
        _showError('Error: $e');
      }
    } else {
      _removeServiceRowFromUi(index);
    }
  }

  Future<void> _deleteEngineeringRow(int index) async {
    final row = engineeringRows[index];
    if (row.savedId != null) {
      try {
        final result = await consumeServiceController.deleteConsumeEngineering(
          row.savedId!,
        );
        if (result['success'] == true) {
          _removeEngineeringRowFromUi(index);
          _scheduleInventorySnapshotRefresh();
          _showSuccess('Engineering deleted');
        } else {
          _showError(result['message'] ?? 'Delete failed');
        }
      } catch (e) {
        _showError('Error: $e');
      }
    } else {
      _removeEngineeringRowFromUi(index);
    }
  }

  // ─────────────────────────────────────────────
  //  Auto-add new row
  // ─────────────────────────────────────────────
  void _checkAndAddRow<T extends BaseRowData>(
    RxList<T> rows,
    RxList<bool> loading,
    RxList<bool> saving,
    RxList<bool> deleting,
  ) {
    if (rows.isNotEmpty && rows.last.selectedItem.isNotEmpty) {
      if (T == PackageRowData) {
        rows.add(PackageRowData() as T);
      } else if (T == ServiceRowData) {
        rows.add(ServiceRowData() as T);
      } else if (T == EngineeringRowData) {
        rows.add(EngineeringRowData() as T);
      }
      loading.add(false);
      saving.add(false);
      deleting.add(false);
    }
  }

  // ─────────────────────────────────────────────
  //  Snackbar helpers
  // ─────────────────────────────────────────────
  void _showSuccess(String msg, {int duration = 2}) {
    Get.rawSnackbar(
      messageText: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xff10B981),
      borderRadius: 6,
      margin: const EdgeInsets.only(top: 8, right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: duration),
      maxWidth: 380,
    );
  }

  void _showError(String msg) {
    Get.rawSnackbar(
      messageText: Row(
        children: [
          const Icon(Icons.error, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xffEF4444),
      borderRadius: 6,
      margin: const EdgeInsets.only(top: 8, right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      maxWidth: 380,
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // ── Top bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.tableGridBlue)),
            ),
            child: Row(
              children: [
                Text(
                  "Input Method",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 16),
                _buildCompactRadio("Used", "Used"),
                const SizedBox(width: 12),
                _buildCompactRadio("Final", "Final"),
              ],
            ),
          ),

          // ── Tables ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // ✅ LEFT ALIGN
                children: [
                  // Package
                  Expanded(
                    child: _buildTableSection<PackageRowData, PackageItem>(
                      title: "Package",
                      color: AppTheme.primaryColor,
                      rows: packageRows,
                      dropdownItems: packages,
                      selectedRowIndex: selectedPackageRow,
                      rowSaving: packageRowSaving,
                      rowDeleting: packageRowDeleting,
                      headers: const [
                        "Package",
                        "Code",
                        "Unit",
                        "Price (Kwd)",
                        "Initial",
                        "Used",
                        "Final",
                        "Cost (Kwd)",
                      ],
                      onDropdownChanged: (i, item) {
                        packageRows[i].selectedItem = '';
                        packageRows[i].code = '';
                        packageRows[i].unit = '';
                        packageRows[i].price = 0.0;
                        packageRows[i].initial = '';
                        packageRows[i].used = '';
                        packageRows[i].finalValue = '';
                        packageRows[i].cost = 0.0;
                        // Populate with new selection
                        packageRows[i].selectedItem = item.name;
                        packageRows[i].code = item.code;
                        packageRows[i].unit = item.unit;
                        packageRows[i].price = item.price;
                        packageRows[i].initial = item.initial; // ✅ YE FIX HAI
                        packageRows[i].used = '';
                        packageRows[i].finalValue = '';
                        packageRows[i].cost = 0.0;
                        packageRows.refresh();
                        _checkAndAddRow(
                          packageRows,
                          packageRowLoading,
                          packageRowSaving,
                          packageRowDeleting,
                        );
                      },
                      onCalculate: _calculatePackage,
                      onSave: _savePackageRow,
                      onDelete: _deletePackageRow,
                      cellBuilder: _packageCells,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Services
                  Expanded(
                    child: _buildTableSection<ServiceRowData, ServiceItem>(
                      title: "Services",
                      color: AppTheme.successColor,
                      rows: serviceRows,
                      dropdownItems: services,
                      selectedRowIndex: selectedServiceRow,
                      rowSaving: serviceRowSaving,
                      rowDeleting: serviceRowDeleting,
                      headers: const [
                        "Services",
                        "Code",
                        "Unit",
                        "Price (Kwd)",
                        "Usage",
                        "Cost (Kwd)",
                      ],

                      onDropdownChanged: (i, item) {
                        // Clear old data first
                        serviceRows[i].selectedItem = '';
                        serviceRows[i].code = '';
                        serviceRows[i].unit = '';
                        serviceRows[i].price = 0.0;
                        serviceRows[i].used = '';
                        serviceRows[i].cost = 0.0;
                        // Populate with new selection
                        serviceRows[i].selectedItem = item.name;
                        serviceRows[i].code = item.code;
                        serviceRows[i].unit = item.unit;
                        serviceRows[i].price = item.price;
                        serviceRows[i].usage = '';
                        serviceRows[i].cost = 0.0;
                        serviceRows.refresh();
                        _checkAndAddRow(
                          serviceRows,
                          serviceRowLoading,
                          serviceRowSaving,
                          serviceRowDeleting,
                        );
                      },
                      onCalculate: _calculateService,
                      onSave: _saveServiceRow,
                      onDelete: _deleteServiceRow,
                      cellBuilder: _serviceCells,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Engineering
                  Expanded(
                    child:
                        _buildTableSection<EngineeringRowData, EngineeringItem>(
                          title: "Engineering",
                          color: AppTheme.infoColor,
                          rows: engineeringRows,
                          dropdownItems: engineering,
                          selectedRowIndex: selectedEngineeringRow,
                          rowSaving: engineeringRowSaving,
                          rowDeleting: engineeringRowDeleting,
                          headers: const [
                            "Engineering",
                            "Code",
                            "Unit",
                            "Price (Kwd)",
                            "Usage",
                            "Cost (Kwd)",
                          ],
                          onDropdownChanged: (i, item) {
                            // Clear old data first
                            engineeringRows[i].selectedItem = '';
                            engineeringRows[i].code = '';
                            engineeringRows[i].unit = '';
                            engineeringRows[i].price = 0.0;
                            engineeringRows[i].usage = '';
                            engineeringRows[i].cost = 0.0;
                            // Populate with new selection
                            engineeringRows[i].selectedItem = item.name;
                            engineeringRows[i].code = item.code;
                            engineeringRows[i].unit = item.unit;
                            engineeringRows[i].price = item.price;
                            engineeringRows[i].usage = '';
                            engineeringRows[i].cost = 0.0;
                            engineeringRows.refresh();
                            _checkAndAddRow(
                              engineeringRows,
                              engineeringRowLoading,
                              engineeringRowSaving,
                              engineeringRowDeleting,
                            );
                          },
                          onCalculate: _calculateEngineering,
                          onSave: _saveEngineeringRow,
                          onDelete: _deleteEngineeringRow,
                          cellBuilder: _engineeringCells,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TABLE SECTION WIDGET
  // ─────────────────────────────────────────────
  Widget _buildTableSection<T extends BaseRowData, I>({
    required String title,
    required Color color,
    required RxList<T> rows,
    required RxList<I> dropdownItems,
    required RxInt selectedRowIndex,
    required RxList<bool> rowSaving,
    required RxList<bool> rowDeleting,
    required List<String> headers,
    required Function(int, I) onDropdownChanged,
    required Function(int) onCalculate,
    required Function(int) onSave,
    required Function(int) onDelete,
    required List<DataCell> Function(
      T,
      int,
      bool,
      RxList<I>,
      Function(int, I),
      VoidCallback,
      Function(int),
      Function(int),
      Function(int),
      bool,
      bool,
      double,
    )
    cellBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.tableGridBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ LEFT ALIGN
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              border: Border(bottom: BorderSide(color: AppTheme.tableGridBlue)),
            ),
            child: Text(
              title,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final baseWidth = headers.fold<double>(
                  0,
                  (total, header) => total + _colWidth(header),
                );
                final availableWidth = constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : baseWidth;
                final widthScale = baseWidth <= 0
                    ? 1.0
                    : (availableWidth / baseWidth)
                          .clamp(1.0, double.infinity)
                          .toDouble();
                final tableWidth = baseWidth * widthScale;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
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
                            AppTheme.tableHeaderBlue,
                          ),
                          border: TableBorder(
                            verticalInside: BorderSide(
                              color: AppTheme.tableGridBlue,
                            ),
                            horizontalInside: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          headingTextStyle: AppTheme.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          dataTextStyle: AppTheme.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          columns: headers
                              .map(
                                (h) => DataColumn(
                                  label: Container(
                                    width: _colWidth(h) * widthScale,
                                    alignment: _isNumericHeader(h)
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(h),
                                  ),
                                ),
                              )
                              .toList(),
                          rows: List.generate(rows.length, (i) {
                            final row = rows[i];
                            final selected = selectedRowIndex.value == i;
                            final saving = i < rowSaving.length
                                ? rowSaving[i]
                                : false;
                            final deleting = i < rowDeleting.length
                                ? rowDeleting[i]
                                : false;
                            final cells = cellBuilder(
                              row,
                              i,
                              selected,
                              dropdownItems,
                              onDropdownChanged,
                              () => selectedRowIndex.value = i,
                              onCalculate,
                              onSave,
                              onDelete,
                              saving,
                              deleting,
                              widthScale,
                            );
                            return DataRow(
                              color: MaterialStateProperty.all(
                                i % 2 == 0 ? Colors.white : Colors.grey.shade50,
                              ),
                              cells: title == 'Package'
                                  ? _withRowMenu(
                                      cells,
                                      (details) =>
                                          _showPackageRowMenu(details, i),
                                    )
                                  : title == 'Services'
                                  ? _withRowMenu(
                                      cells,
                                      (details) =>
                                          _showServiceRowMenu(details, i),
                                    )
                                  : _withRowMenu(
                                      cells,
                                      (details) =>
                                          _showEngineeringRowMenu(details, i),
                                    ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PACKAGE CELLS
  // ─────────────────────────────────────────────
  List<DataCell> _packageCells(
    PackageRowData row,
    int index,
    bool isSelected,
    RxList<PackageItem> dropdownItems,
    Function(int, PackageItem) onDropdownChanged,
    VoidCallback onRowSelected,
    Function(int) onCalculate,
    Function(int) onSave,
    Function(int) onDelete,
    bool isSaving,
    bool isDeleting,
    double widthScale,
  ) {
    double w(double width) => width * widthScale;
    return [
      _dropdownCell<PackageItem>(
        row: row,
        index: index,
        isSelected: isSelected,
        dropdownItems: dropdownItems,
        onDropdownChanged: onDropdownChanged,
        onRowSelected: onRowSelected,
        width: w(160),
        getName: (i) => i.name,
      ),
      _editCell(row.codeCtrl, w(90), (v) => {}),
      _editCell(row.unitCtrl, w(70), (v) => {}),
      _editCell(row.priceCtrl, w(90), (v) => _autoSavePackage(index)),
      _editCell(row.initialCtrl, w(80), (v) => _autoSavePackage(index)),
      _editCell(row.usedCtrl, w(80), (v) => _autoSavePackage(index)),
      // Final — read-only, negative = red
      _reactiveReadCell(
        text: () => row.finalValue,
        width: w(80),
        rightAlign: true,
        bold: true,
        colorForValue: (value) => (double.tryParse(value) ?? 0) < 0
            ? Colors.red
            : Colors.grey.shade700,
      ),
      _reactiveReadCell(
        text: () => row.cost > 0 ? row.cost.toStringAsFixed(2) : '',
        width: w(90),
        rightAlign: true,
        bold: true,
        color: AppTheme.primaryColor,
      ),
    ];
  }

  // ─────────────────────────────────────────────
  //  SERVICE CELLS
  // ─────────────────────────────────────────────
  List<DataCell> _serviceCells(
    ServiceRowData row,
    int index,
    bool isSelected,
    RxList<ServiceItem> dropdownItems,
    Function(int, ServiceItem) onDropdownChanged,
    VoidCallback onRowSelected,
    Function(int) onCalculate,
    Function(int) onSave,
    Function(int) onDelete,
    bool isSaving,
    bool isDeleting,
    double widthScale,
  ) {
    double w(double width) => width * widthScale;
    return [
      _dropdownCell<ServiceItem>(
        row: row,
        index: index,
        isSelected: isSelected,
        dropdownItems: dropdownItems,
        onDropdownChanged: onDropdownChanged,
        onRowSelected: onRowSelected,
        width: w(160),
        getName: (i) => i.name,
      ),
      _editCell(row.codeCtrl, w(90), (v) => {}),
      _editCell(row.unitCtrl, w(70), (v) => {}),
      _editCell(row.priceCtrl, w(90), (v) => _autoSaveService(index)),
      _editCell(row.usedCtrl, w(80), (v) => _autoSaveService(index)),
      _reactiveReadCell(
        text: () => row.cost > 0 ? row.cost.toStringAsFixed(2) : '',
        width: w(90),
        rightAlign: true,
        bold: true,
        color: AppTheme.successColor,
      ),
    ];
  }

  // ─────────────────────────────────────────────
  //  ENGINEERING CELLS
  // ─────────────────────────────────────────────
  List<DataCell> _engineeringCells(
    EngineeringRowData row,
    int index,
    bool isSelected,
    RxList<EngineeringItem> dropdownItems,
    Function(int, EngineeringItem) onDropdownChanged,
    VoidCallback onRowSelected,
    Function(int) onCalculate,
    Function(int) onSave,
    Function(int) onDelete,
    bool isSaving,
    bool isDeleting,
    double widthScale,
  ) {
    double w(double width) => width * widthScale;
    return [
      _dropdownCell<EngineeringItem>(
        row: row,
        index: index,
        isSelected: isSelected,
        dropdownItems: dropdownItems,
        onDropdownChanged: onDropdownChanged,
        onRowSelected: onRowSelected,
        width: w(160),
        getName: (i) => i.name,
      ),
      _editCell(row.codeCtrl, w(90), (v) => {}),
      _editCell(row.unitCtrl, w(70), (v) => {}),
      _editCell(row.priceCtrl, w(90), (v) => _autoSaveEngineering(index)),
      _editCell(row.usageCtrl, w(80), (v) => _autoSaveEngineering(index)),
      _reactiveReadCell(
        text: () => row.cost > 0 ? row.cost.toStringAsFixed(2) : '',
        width: w(90),
        rightAlign: true,
        bold: true,
        color: AppTheme.infoColor,
      ),
    ];
  }

  // ─────────────────────────────────────────────
  //  REUSABLE CELL BUILDERS
  // ─────────────────────────────────────────────
  DataCell _dropdownCell<I>({
    required BaseRowData row,
    required int index,
    required bool isSelected,
    required RxList<I> dropdownItems,
    required Function(int, I) onDropdownChanged,
    required VoidCallback onRowSelected,
    required double width,
    required String Function(I) getName,
  }) {
    return DataCell(
      GestureDetector(
        onTap: onRowSelected,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: dashboardController.isLocked.value
              ? operationLockedEditableColor
              : Colors.transparent,
          child: Row(
            children: [
              if (isSelected)
                Icon(
                  Icons.arrow_drop_down,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
              if (isSelected) const SizedBox(width: 2),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<I>(
                    value: row.selectedItem.isNotEmpty
                        ? dropdownItems.firstWhereOrNull(
                            (item) => getName(item) == row.selectedItem,
                          )
                        : null,
                    hint: const SizedBox.shrink(),
                    isExpanded: true,
                    isDense: true,
                    icon: const SizedBox.shrink(),
                    menuMaxHeight: 200,
                    items: dropdownItems
                        .map(
                          (item) => DropdownMenuItem<I>(
                            value: item,
                            child: Text(
                              getName(item),
                              style: operationDataTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: dashboardController.isLocked.value
                        ? null
                        : (I? val) {
                            if (val != null) {
                              onRowSelected();
                              onDropdownChanged(index, val);
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataCell _readCell(
    String val,
    double width, {
    bool rightAlign = false,
    bool bold = false,
    Color? color,
  }) {
    return DataCell(
      Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: rightAlign ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          val,
          style: AppTheme.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color ?? Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  DataCell _reactiveReadCell({
    required String Function() text,
    required double width,
    bool rightAlign = false,
    bool bold = false,
    Color? color,
    Color Function(String value)? colorForValue,
  }) {
    return DataCell(
      Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: rightAlign ? Alignment.centerRight : Alignment.centerLeft,
        child: Obx(() {
          final value = text();
          return Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color:
                  colorForValue?.call(value) ?? color ?? Colors.grey.shade800,
            ),
          );
        }),
      ),
    );
  }

  DataCell _editCell(
    TextEditingController ctrl,
    double width,
    Function(String) onChanged,
  ) {
    return DataCell(
      Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        color: dashboardController.isLocked.value
            ? operationLockedEditableColor
            : Colors.transparent,
        child: TextFormField(
          controller: ctrl,
          enabled: !dashboardController.isLocked.value,
          style: operationDataTextStyle,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            border: InputBorder.none,
          ),
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          onChanged: (v) {
            onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildCompactRadio(String label, String value) {
    return Obx(
      () => InkWell(
        onTap: dashboardController.isLocked.value
            ? null
            : () => selectedMethod.value = value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selectedMethod.value == value
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selectedMethod.value == value
                  ? AppTheme.primaryColor
                  : AppTheme.tableGridBlue,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
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
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 11,
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

  double _colWidth(String h) {
    if (h == 'Initial' || h == 'Used' || h == 'Final' || h == 'Usage')
      return 80;
    if (h == 'Package' || h == 'Services' || h == 'Engineering') return 160;
    if (h == 'Code') return 90;
    if (h == 'Unit') return 70;
    if (h.contains('Price') || h.contains('Cost')) return 90;
    return 80;
  }

  bool _isNumericHeader(String h) =>
      h.contains('Price') ||
      h.contains('Cost') ||
      h == 'Initial' ||
      h == 'Used' ||
      h == 'Final' ||
      h == 'Usage';
}

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────
abstract class BaseRowData {
  String selectedItem = '';
  String? savedId;

  final codeCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final initialCtrl = TextEditingController();
  final usedCtrl = TextEditingController();

  String get code => codeCtrl.text;
  set code(String v) => codeCtrl.text = v;

  String get unit => unitCtrl.text;
  set unit(String v) => unitCtrl.text = v;

  double get price => double.tryParse(priceCtrl.text) ?? 0.0;
  set price(double v) =>
      priceCtrl.text = (v == 0.0) ? '' : v.toStringAsFixed(2);

  String get initial => initialCtrl.text;
  set initial(String v) => initialCtrl.text = v;

  String get used => usedCtrl.text;
  set used(String v) => usedCtrl.text = v;

  final RxDouble costRx = 0.0.obs;
  final RxString finalValueRx = ''.obs;

  double get cost => costRx.value;
  set cost(double v) => costRx.value = v;

  String get finalValue => finalValueRx.value;
  set finalValue(String v) => finalValueRx.value = v;

  void dispose() {
    codeCtrl.dispose();
    unitCtrl.dispose();
    priceCtrl.dispose();
    initialCtrl.dispose();
    usedCtrl.dispose();
  }
}

class PackageRowData extends BaseRowData {}

class ServiceRowData extends BaseRowData {
  String get usage => used;
  set usage(String v) => used = v;
}

class EngineeringRowData extends BaseRowData {
  final usageCtrl = TextEditingController();
  String get usage => usageCtrl.text;
  set usage(String v) => usageCtrl.text = v;

  @override
  void dispose() {
    super.dispose();
    usageCtrl.dispose();
  }
}
