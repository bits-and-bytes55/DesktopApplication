import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/service_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/consume_service_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ConsumeServicesView extends StatefulWidget {
  const ConsumeServicesView({super.key});

  @override
  State<ConsumeServicesView> createState() => _ConsumeServicesViewState();
}

class _ConsumeServicesViewState extends State<ConsumeServicesView> {
  final dashboardController = Get.find<DashboardController>();
  final serviceController   = Get.put(ServiceController());
  final consumeServiceController   = ConsumeServiceController();
  final inventorySnapshotController = InventorySnapshotController();

  final RxString selectedMethod = "Used".obs;

  // ── Dropdown source data ──
  final RxList<PackageItem>     packages    = <PackageItem>[].obs;
  final RxList<ServiceItem>     services    = <ServiceItem>[].obs;
  final RxList<EngineeringItem> engineering = <EngineeringItem>[].obs;

  // ── Row data ──
  final RxList<PackageRowData>     packageRows     = <PackageRowData>[].obs;
  final RxList<ServiceRowData>     serviceRows     = <ServiceRowData>[].obs;
  final RxList<EngineeringRowData> engineeringRows = <EngineeringRowData>[].obs;

  // ── Per-row flags ──
  final RxList<bool> packageRowLoading     = <bool>[].obs;
  final RxList<bool> serviceRowLoading     = <bool>[].obs;
  final RxList<bool> engineeringRowLoading = <bool>[].obs;
  final RxList<bool> packageRowSaving      = <bool>[].obs;
  final RxList<bool> serviceRowSaving      = <bool>[].obs;
  final RxList<bool> engineeringRowSaving  = <bool>[].obs;
  final RxList<bool> packageRowDeleting    = <bool>[].obs;
  final RxList<bool> serviceRowDeleting    = <bool>[].obs;
  final RxList<bool> engineeringRowDeleting = <bool>[].obs;

  // ✅ FIX: prevent duplicate creates — same as ConsumeProductView
  final Set<int> _pkgSavingInProgress  = {};
  final Set<int> _srvSavingInProgress  = {};
  final Set<int> _engSavingInProgress  = {};

  final RxInt selectedPackageRow     = 0.obs;
  final RxInt selectedServiceRow     = 0.obs;
  final RxInt selectedEngineeringRow = 0.obs;

  final RxBool isSaving = false.obs;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _fetchAllData();
  }

  @override
  void dispose() {
    for (var r in packageRows) r.dispose();
    for (var r in serviceRows) r.dispose();
    for (var r in engineeringRows) r.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  Load dropdown source data
  // ─────────────────────────────────────────────
  Future<void> _loadDropdownData() async {
    try {
      const wellId = '507f1f77bcf86cd799439011';
      final pkgs = await InventoryProductsService.fetchPackages(wellId);
      final srvs = await InventoryProductsService.fetchServices(wellId);
      final engs = await InventoryProductsService.fetchEngineering(wellId);
      packages.value    = pkgs;
      services.value    = srvs;
      engineering.value = engs;
      print('🟢 [LOAD] packages=${pkgs.length} services=${srvs.length} engineering=${engs.length}');
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
        row.code         = item['code']?.toString() ?? '';
        row.unit         = item['unit']?.toString() ?? '';
        row.price        = _toDouble(item['price']);
        row.initial      = _numStr(item['initial']);
        row.used         = _numStr(item['used']);
        row.finalValue   = _numStr(item['final']);
        row.cost         = _toDouble(item['cost']);
        row.savedId      = item['_id']?.toString();
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
        row.code         = item['code']?.toString() ?? '';
        row.unit         = item['unit']?.toString() ?? '';
        row.price        = _toDouble(item['price']);
        row.usage        = _numStr(item['usage']);
        row.cost         = _toDouble(item['cost']);
        row.savedId      = item['_id']?.toString();
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
        row.code         = item['code']?.toString() ?? '';
        row.unit         = item['unit']?.toString() ?? '';
        row.price        = _toDouble(item['price']);
        row.usage        = _numStr(item['usage']);
        row.cost         = _toDouble(item['cost']);
        row.savedId      = item['_id']?.toString();
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
  double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  String _numStr(dynamic v) {
    final d = _toDouble(v);
    return d == 0.0 ? '' : d.toString();
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
    final used    = double.tryParse(row.used)    ?? 0.0;
    row.finalValue = (initial - used).toStringAsFixed(2);
    row.cost       = used * row.price;
    packageRows.refresh();
  }

  void _calculateService(int index) {
    if (dashboardController.isLocked.value) return;
    final row = serviceRows[index];
    if (row.selectedItem.isEmpty) return;
    final usage = double.tryParse(row.usage) ?? 0.0;
    row.cost = usage * row.price;
    serviceRows.refresh();
  }

  void _calculateEngineering(int index) {
    if (dashboardController.isLocked.value) return;
    final row = engineeringRows[index];
    if (row.selectedItem.isEmpty) return;
    final usage = double.tryParse(row.usage) ?? 0.0;
    row.cost = usage * row.price;
    engineeringRows.refresh();
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
    Future.delayed(const Duration(milliseconds: 600), () {
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
    Future.delayed(const Duration(milliseconds: 600), () {
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
    Future.delayed(const Duration(milliseconds: 600), () {
      if (index < engineeringRows.length && _isEngCostReady(engineeringRows[index])) {
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

    if (index < packageRowSaving.length) {
      packageRowSaving[index] = true;
      packageRowSaving.refresh();
    }

    final initial = double.tryParse(row.initial) ?? 0.0;
    final used    = double.tryParse(row.used)    ?? 0.0;

    try {
      Map<String, dynamic> result;

      if (row.savedId == null) {
        print('🆕 [PKG] Creating row $index — name="${row.selectedItem}"');
        result = await consumeServiceController.createConsumePackage(
          packageName: row.selectedItem,
          code:        row.code,
          unit:        row.unit,
          price:       row.price,
          initial:     initial,
          used:        used,
        );
        if (result['success'] == true) {
          // ✅ FIX: savedId turant set karo
          row.savedId = result['data']?['_id']?.toString();
          packageRows.refresh();
          print('✅ [PKG] Created — savedId=${row.savedId}');
        } else {
          _showError(result['message'] ?? 'Save failed');
        }
      } else {
        print('✏️ [PKG] Updating row $index — id=${row.savedId}');
        result = await consumeServiceController.updateConsumePackage(
          id:          row.savedId!,
          packageName: row.selectedItem,
          code:        row.code,
          unit:        row.unit,
          price:       row.price,
          initial:     initial,
          used:        used,
        );
        if (result['success'] == true) {
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
      if (index < packageRowSaving.length) {
        packageRowSaving[index] = false;
        packageRowSaving.refresh();
      }
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

    if (index < serviceRowSaving.length) {
      serviceRowSaving[index] = true;
      serviceRowSaving.refresh();
    }

    final usage = double.tryParse(row.usage) ?? 0.0;

    try {
      Map<String, dynamic> result;

      if (row.savedId == null) {
        print('🆕 [SRV] Creating row $index — name="${row.selectedItem}"');
        result = await consumeServiceController.createConsumeService(
          serviceName: row.selectedItem,
          code:        row.code,
          unit:        row.unit,
          price:       row.price,
          usage:       usage,
        );
        if (result['success'] == true) {
          row.savedId = result['data']?['_id']?.toString();
          serviceRows.refresh();
          print('✅ [SRV] Created — savedId=${row.savedId}');
        } else {
          _showError(result['message'] ?? 'Save failed');
        }
      } else {
        print('✏️ [SRV] Updating row $index — id=${row.savedId}');
        result = await consumeServiceController.updateConsumeService(
          id:          row.savedId!,
          serviceName: row.selectedItem,
          code:        row.code,
          unit:        row.unit,
          price:       row.price,
          usage:       usage,
        );
        if (result['success'] == true) {
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
      if (index < serviceRowSaving.length) {
        serviceRowSaving[index] = false;
        serviceRowSaving.refresh();
      }
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

    if (index < engineeringRowSaving.length) {
      engineeringRowSaving[index] = true;
      engineeringRowSaving.refresh();
    }

    final usage = double.tryParse(row.usage) ?? 0.0;

    try {
      Map<String, dynamic> result;

      if (row.savedId == null) {
        print('🆕 [ENG] Creating row $index — name="${row.selectedItem}"');
        result = await consumeServiceController.createConsumeEngineering(
          engineeringName: row.selectedItem,
          code:            row.code,
          unit:            row.unit,
          price:           row.price,
          usage:           usage,
        );
        if (result['success'] == true) {
          row.savedId = result['data']?['_id']?.toString();
          engineeringRows.refresh();
          print('✅ [ENG] Created — savedId=${row.savedId}');
        } else {
          _showError(result['message'] ?? 'Save failed');
        }
      } else {
        print('✏️ [ENG] Updating row $index — id=${row.savedId}');
        result = await consumeServiceController.updateConsumeEngineering(
          id:              row.savedId!,
          engineeringName: row.selectedItem,
          code:            row.code,
          unit:            row.unit,
          price:           row.price,
          usage:           usage,
        );
        if (result['success'] == true) {
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
      if (index < engineeringRowSaving.length) {
        engineeringRowSaving[index] = false;
        engineeringRowSaving.refresh();
      }
    }
  }

  // ─────────────────────────────────────────────
  //  DELETE
  // ─────────────────────────────────────────────
  Future<void> _deletePackageRow(int index) async {
    final row = packageRows[index];
    if (row.savedId != null) {
      if (index < packageRowDeleting.length) {
        packageRowDeleting[index] = true;
        packageRowDeleting.refresh();
      }
      try {
        final result = await consumeServiceController.deleteConsumePackage(row.savedId!);
        if (result['success'] == true) {
          _pkgSavingInProgress.remove(index);
          await _fetchAllData();
          _showSuccess('Package deleted');
        } else {
          _showError(result['message'] ?? 'Delete failed');
        }
      } catch (e) {
        _showError('Error: $e');
      } finally {
        if (index < packageRowDeleting.length) {
          packageRowDeleting[index] = false;
          packageRowDeleting.refresh();
        }
      }
    } else {
      if (packageRows.length > 1) {
        packageRows[index].dispose();
        packageRows.removeAt(index);
        if (index < packageRowLoading.length)  packageRowLoading.removeAt(index);
        if (index < packageRowSaving.length)   packageRowSaving.removeAt(index);
        if (index < packageRowDeleting.length) packageRowDeleting.removeAt(index);
      } else {
        packageRows[index] = PackageRowData();
        packageRows.refresh();
      }
    }
  }

  Future<void> _deleteServiceRow(int index) async {
    final row = serviceRows[index];
    if (row.savedId != null) {
      if (index < serviceRowDeleting.length) {
        serviceRowDeleting[index] = true;
        serviceRowDeleting.refresh();
      }
      try {
        final result = await consumeServiceController.deleteConsumeService(row.savedId!);
        if (result['success'] == true) {
          _srvSavingInProgress.remove(index);
          await _fetchAllData();
          _showSuccess('Service deleted');
        } else {
          _showError(result['message'] ?? 'Delete failed');
        }
      } catch (e) {
        _showError('Error: $e');
      } finally {
        if (index < serviceRowDeleting.length) {
          serviceRowDeleting[index] = false;
          serviceRowDeleting.refresh();
        }
      }
    } else {
      if (serviceRows.length > 1) {
        serviceRows[index].dispose();
        serviceRows.removeAt(index);
        if (index < serviceRowLoading.length)  serviceRowLoading.removeAt(index);
        if (index < serviceRowSaving.length)   serviceRowSaving.removeAt(index);
        if (index < serviceRowDeleting.length) serviceRowDeleting.removeAt(index);
      } else {
        serviceRows[index] = ServiceRowData();
        serviceRows.refresh();
      }
    }
  }

  Future<void> _deleteEngineeringRow(int index) async {
    final row = engineeringRows[index];
    if (row.savedId != null) {
      if (index < engineeringRowDeleting.length) {
        engineeringRowDeleting[index] = true;
        engineeringRowDeleting.refresh();
      }
      try {
        final result = await consumeServiceController.deleteConsumeEngineering(row.savedId!);
        if (result['success'] == true) {
          _engSavingInProgress.remove(index);
          await _fetchAllData();
          _showSuccess('Engineering deleted');
        } else {
          _showError(result['message'] ?? 'Delete failed');
        }
      } catch (e) {
        _showError('Error: $e');
      } finally {
        if (index < engineeringRowDeleting.length) {
          engineeringRowDeleting[index] = false;
          engineeringRowDeleting.refresh();
        }
      }
    } else {
      if (engineeringRows.length > 1) {
        engineeringRows[index].dispose();
        engineeringRows.removeAt(index);
        if (index < engineeringRowLoading.length)  engineeringRowLoading.removeAt(index);
        if (index < engineeringRowSaving.length)   engineeringRowSaving.removeAt(index);
        if (index < engineeringRowDeleting.length) engineeringRowDeleting.removeAt(index);
      } else {
        engineeringRows[index] = EngineeringRowData();
        engineeringRows.refresh();
      }
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
      messageText: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 12))),
      ]),
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
      messageText: Row(children: [
        const Icon(Icons.error, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 12))),
      ]),
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
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Text("Input Method",
                    style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
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
                      headers: const ["Package", "Code", "Unit", "Price (\$)", "Initial", "Used", "Final", "Cost (\$)", ""],
                      onDropdownChanged: (i, item) {
  packageRows[i].selectedItem = '';
  packageRows[i].code         = '';
  packageRows[i].unit         = '';
  packageRows[i].price        = 0.0;
  packageRows[i].initial      = '';
  packageRows[i].used         = '';
  packageRows[i].finalValue   = '';
  packageRows[i].cost         = 0.0;
  // Populate with new selection
  packageRows[i].selectedItem = item.name;
  packageRows[i].code         = item.code;
  packageRows[i].unit         = item.unit;
  packageRows[i].price        = item.price;
  packageRows[i].initial      = item.initial;  // ✅ YE FIX HAI
  packageRows[i].used         = '';
  packageRows[i].finalValue   = '';
  packageRows[i].cost         = 0.0;
  packageRows.refresh();
  _checkAndAddRow(packageRows, packageRowLoading, packageRowSaving, packageRowDeleting);
},
                      onCalculate: _calculatePackage,
                      onSave:      _savePackageRow,
                      onDelete:    _deletePackageRow,
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
                      headers: const ["Services", "Code", "Unit", "Price (\$)", "Usage", "Cost (\$)", ""],
                     
                      onDropdownChanged: (i, item) {
                        // Clear old data first
                        serviceRows[i].selectedItem = '';
                        serviceRows[i].code  = '';
                        serviceRows[i].unit  = '';
                        serviceRows[i].price = 0.0;
                        serviceRows[i].used  = '';
                        serviceRows[i].cost  = 0.0;
                        // Populate with new selection
                        serviceRows[i].selectedItem = item.name;
                        serviceRows[i].code         = item.code;
                        serviceRows[i].unit         = item.unit;
                        serviceRows[i].price        = item.price;
                        serviceRows[i].usage        = '';
                        serviceRows[i].cost         = 0.0;
                        serviceRows.refresh();
                        _checkAndAddRow(serviceRows, serviceRowLoading, serviceRowSaving, serviceRowDeleting);
                      },
                      onCalculate: _calculateService,
                      onSave:      _saveServiceRow,
                      onDelete:    _deleteServiceRow,
                      cellBuilder: _serviceCells,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Engineering
                  Expanded(
                    child: _buildTableSection<EngineeringRowData, EngineeringItem>(
                      title: "Engineering",
                      color: AppTheme.infoColor,
                      rows: engineeringRows,
                      dropdownItems: engineering,
                      selectedRowIndex: selectedEngineeringRow,
                      rowSaving: engineeringRowSaving,
                      rowDeleting: engineeringRowDeleting,
                      headers: const ["Engineering", "Code", "Unit", "Price (\$)", "Usage", "Cost (\$)", ""],
                      onDropdownChanged: (i, item) {
                        // Clear old data first
                        engineeringRows[i].selectedItem = '';
                        engineeringRows[i].code  = '';
                        engineeringRows[i].unit  = '';
                        engineeringRows[i].price = 0.0;
                        engineeringRows[i].usage = '';
                        engineeringRows[i].cost  = 0.0;
                        // Populate with new selection
                        engineeringRows[i].selectedItem = item.name;
                        engineeringRows[i].code         = item.code;
                        engineeringRows[i].unit         = item.unit;
                        engineeringRows[i].price        = item.price;
                        engineeringRows[i].usage        = '';
                        engineeringRows[i].cost         = 0.0;
                        engineeringRows.refresh();
                        _checkAndAddRow(engineeringRows, engineeringRowLoading, engineeringRowSaving, engineeringRowDeleting);
                      },
                      onCalculate: _calculateEngineering,
                      onSave:      _saveEngineeringRow,
                      onDelete:    _deleteEngineeringRow,
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
      T, int, bool, RxList<I>, Function(int, I), VoidCallback,
      Function(int), Function(int), Function(int), bool, bool,
    ) cellBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ LEFT ALIGN
        children: [
          Container(
            width: double.infinity, // ✅ full width header
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6), topRight: Radius.circular(6),
              ),
            ),
            child: Text(title,
                style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, fontSize: 11, color: Colors.white)),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Obx(() => DataTable(
                  headingRowHeight: 26,
                  dataRowHeight: 26,
                  columnSpacing: 0,
                  horizontalMargin: 0,
                  dividerThickness: 0,
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                  border: TableBorder(
                    verticalInside: BorderSide(color: Colors.grey.shade300),
                    horizontalInside: BorderSide(color: Colors.grey.shade200),
                  ),
                  headingTextStyle: AppTheme.bodySmall.copyWith(
                      fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  dataTextStyle: AppTheme.bodySmall.copyWith(fontSize: 9),
                  columns: headers.map((h) => DataColumn(label: Container(
                    width: _colWidth(h),
                    alignment: _isNumericHeader(h) ? Alignment.centerRight : Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(h),
                  ))).toList(),
                  rows: List.generate(rows.length, (i) {
                    final row      = rows[i];
                    final selected = selectedRowIndex.value == i;
                    final saving   = i < rowSaving.length  ? rowSaving[i]   : false;
                    final deleting = i < rowDeleting.length ? rowDeleting[i] : false;
                    return DataRow(
                      color: MaterialStateProperty.all(
                          i % 2 == 0 ? Colors.white : Colors.grey.shade50),
                      cells: cellBuilder(row, i, selected, dropdownItems, onDropdownChanged,
                          () => selectedRowIndex.value = i,
                          onCalculate, onSave, onDelete, saving, deleting),
                    );
                  }),
                )),
              ),
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
    PackageRowData row, int index, bool isSelected,
    RxList<PackageItem> dropdownItems,
    Function(int, PackageItem) onDropdownChanged,
    VoidCallback onRowSelected,
    Function(int) onCalculate, Function(int) onSave, Function(int) onDelete,
    bool isSaving, bool isDeleting,
  ) {
    return [
      _dropdownCell<PackageItem>(
        row: row, index: index, isSelected: isSelected,
        dropdownItems: dropdownItems, onDropdownChanged: onDropdownChanged,
        onRowSelected: onRowSelected, width: 160, getName: (i) => i.name,
      ),
      _editCell(row.codeCtrl, 90, (v) => {}),
      _editCell(row.unitCtrl, 70, (v) => {}),
      _editCell(row.priceCtrl, 90, (v) => _autoSavePackage(index)),
      _editCell(row.initialCtrl, 80, (v) => _autoSavePackage(index)),
      _editCell(row.usedCtrl, 80, (v) => _autoSavePackage(index)),
      // Final — read-only, negative = red
      DataCell(Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerRight,
        child: Text(
          row.finalValue,
          style: AppTheme.bodySmall.copyWith(
            fontSize: 9,
            color: (double.tryParse(row.finalValue) ?? 0) < 0 ? Colors.red : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      )),
      _readCell(row.cost > 0 ? row.cost.toStringAsFixed(2) : '', 90,
          rightAlign: true, bold: true, color: AppTheme.primaryColor),
      DataCell(_deleteButton(index: index, isDeleting: isDeleting, onDelete: () => onDelete(index))),
    ];
  }

  // ─────────────────────────────────────────────
  //  SERVICE CELLS
  // ─────────────────────────────────────────────
  List<DataCell> _serviceCells(
    ServiceRowData row, int index, bool isSelected,
    RxList<ServiceItem> dropdownItems,
    Function(int, ServiceItem) onDropdownChanged,
    VoidCallback onRowSelected,
    Function(int) onCalculate, Function(int) onSave, Function(int) onDelete,
    bool isSaving, bool isDeleting,
  ) {
    return [
      _dropdownCell<ServiceItem>(
        row: row, index: index, isSelected: isSelected,
        dropdownItems: dropdownItems, onDropdownChanged: onDropdownChanged,
        onRowSelected: onRowSelected, width: 160, getName: (i) => i.name,
      ),
      _editCell(row.codeCtrl, 90, (v) => {}),
      _editCell(row.unitCtrl, 70, (v) => {}),
      _editCell(row.priceCtrl, 90, (v) => _autoSaveService(index)),
      _editCell(row.usedCtrl, 80, (v) => _autoSaveService(index)),
      _readCell(row.cost > 0 ? row.cost.toStringAsFixed(2) : '', 90,
          rightAlign: true, bold: true, color: AppTheme.successColor),
      DataCell(_deleteButton(index: index, isDeleting: isDeleting, onDelete: () => onDelete(index))),
    ];
  }

  // ─────────────────────────────────────────────
  //  ENGINEERING CELLS
  // ─────────────────────────────────────────────
  List<DataCell> _engineeringCells(
    EngineeringRowData row, int index, bool isSelected,
    RxList<EngineeringItem> dropdownItems,
    Function(int, EngineeringItem) onDropdownChanged,
    VoidCallback onRowSelected,
    Function(int) onCalculate, Function(int) onSave, Function(int) onDelete,
    bool isSaving, bool isDeleting,
  ) {
    return [
      _dropdownCell<EngineeringItem>(
        row: row, index: index, isSelected: isSelected,
        dropdownItems: dropdownItems, onDropdownChanged: onDropdownChanged,
        onRowSelected: onRowSelected, width: 160, getName: (i) => i.name,
      ),
      _editCell(row.codeCtrl, 90, (v) => {}),
      _editCell(row.unitCtrl, 70, (v) => {}),
      _editCell(row.priceCtrl, 90, (v) => _autoSaveEngineering(index)),
      _editCell(row.usageCtrl, 80, (v) => _autoSaveEngineering(index)),
      _readCell(row.cost > 0 ? row.cost.toStringAsFixed(2) : '', 90,
          rightAlign: true, bold: true, color: AppTheme.infoColor),
      DataCell(_deleteButton(index: index, isDeleting: isDeleting, onDelete: () => onDelete(index))),
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
    return DataCell(GestureDetector(
      onTap: onRowSelected,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: [
          if (isSelected) Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.primaryColor),
          if (isSelected) const SizedBox(width: 2),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<I>(
                value: row.selectedItem.isNotEmpty
                    ? dropdownItems.firstWhereOrNull((item) => getName(item) == row.selectedItem)
                    : null,
                hint: Text("Select",
                    style: AppTheme.bodySmall.copyWith(fontSize: 9, color: Colors.grey)),
                isExpanded: true, isDense: true,
                icon: const SizedBox.shrink(), menuMaxHeight: 200,
                items: dropdownItems.map((item) => DropdownMenuItem<I>(
                  value: item,
                  child: Text(getName(item),
                      style: AppTheme.bodySmall.copyWith(fontSize: 9),
                      overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: dashboardController.isLocked.value ? null : (I? val) {
                  if (val != null) {
                    onRowSelected();
                    onDropdownChanged(index, val);
                  }
                },
              ),
            ),
          ),
        ]),
      ),
    ));
  }

  DataCell _readCell(String val, double width,
      {bool rightAlign = false, bool bold = false, Color? color}) {
    return DataCell(Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: rightAlign ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(val,
          style: AppTheme.bodySmall.copyWith(
            fontSize: 9,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: color ?? Colors.grey.shade800,
          )),
    ));
  }

  DataCell _editCell(TextEditingController ctrl, double width, Function(String) onChanged) {
    return DataCell(Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextFormField(
        controller: ctrl,
        enabled: !dashboardController.isLocked.value,
        style: AppTheme.bodySmall.copyWith(fontSize: 9),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          border: InputBorder.none,
        ),
        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
        onChanged: (v) {
          onChanged(v);
        },
      ),
    ));
  }

  Widget _deleteButton({
    required int index,
    required bool isDeleting,
    required VoidCallback onDelete,
  }) {
    if (isDeleting) {
      return const SizedBox(width: 32, child: Center(
        child: SizedBox(width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)),
      ));
    }
    return SizedBox(
      width: 32,
      child: IconButton(
        icon: Icon(Icons.delete_outline, size: 15,
            color: dashboardController.isLocked.value ? Colors.grey.shade300 : Colors.red.shade300),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: dashboardController.isLocked.value ? null : onDelete,
      ),
    );
  }

  Widget _buildCompactRadio(String label, String value) {
    return Obx(() => InkWell(
      onTap: dashboardController.isLocked.value ? null : () => selectedMethod.value = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selectedMethod.value == value
              ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selectedMethod.value == value ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedMethod.value == value ? AppTheme.primaryColor : Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            child: selectedMethod.value == value
                ? Center(child: Container(width: 6, height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor)))
                : null,
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              color: selectedMethod.value == value ? AppTheme.primaryColor : AppTheme.textSecondary)),
        ]),
      ),
    ));
  }

  double _colWidth(String h) {
    if (h == 'Initial' || h == 'Used' || h == 'Final' || h == 'Usage') return 80;
    if (h == 'Package' || h == 'Services' || h == 'Engineering') return 160;
    if (h == 'Code') return 90;
    if (h == 'Unit') return 70;
    if (h.contains('Price') || h.contains('Cost')) return 90;
    if (h == '') return 32;
    return 80;
  }

  bool _isNumericHeader(String h) =>
      h.contains('Price') || h.contains('Cost') ||
      h == 'Initial' || h == 'Used' || h == 'Final' || h == 'Usage';
}

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────
abstract class BaseRowData {
  String selectedItem = '';
  String? savedId;

  final codeCtrl    = TextEditingController();
  final unitCtrl    = TextEditingController();
  final priceCtrl   = TextEditingController();
  final initialCtrl = TextEditingController();
  final usedCtrl    = TextEditingController();

  String get code => codeCtrl.text;
  set code(String v) => codeCtrl.text = v;

  String get unit => unitCtrl.text;
  set unit(String v) => unitCtrl.text = v;

  double get price => double.tryParse(priceCtrl.text) ?? 0.0;
  set price(double v) => priceCtrl.text = (v == 0.0) ? '' : v.toStringAsFixed(2);

  String get initial => initialCtrl.text;
  set initial(String v) => initialCtrl.text = v;

  String get used => usedCtrl.text;
  set used(String v) => usedCtrl.text = v;

  double cost = 0.0;
  String finalValue = '';

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