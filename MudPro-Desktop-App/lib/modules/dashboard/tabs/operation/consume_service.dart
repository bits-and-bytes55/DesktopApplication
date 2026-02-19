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
  final serviceController = Get.put(ServiceController());
  final consumeServiceController = ConsumeServiceController();
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

  // ── Per-row loading (calculate) ──
  final RxList<bool> packageRowLoading = <bool>[].obs;
  final RxList<bool> serviceRowLoading = <bool>[].obs;
  final RxList<bool> engineeringRowLoading = <bool>[].obs;

  // ── Per-row saving ──
  final RxList<bool> packageRowSaving = <bool>[].obs;
  final RxList<bool> serviceRowSaving = <bool>[].obs;
  final RxList<bool> engineeringRowSaving = <bool>[].obs;

  // ── Per-row deleting ──
  final RxList<bool> packageRowDeleting = <bool>[].obs;
  final RxList<bool> serviceRowDeleting = <bool>[].obs;
  final RxList<bool> engineeringRowDeleting = <bool>[].obs;

  // ── Selected row ──
  final RxInt selectedPackageRow = 0.obs;
  final RxInt selectedServiceRow = 0.obs;
  final RxInt selectedEngineeringRow = 0.obs;

  // ── Save All button ──
  final RxBool isSaving = false.obs;

  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    print('🟡 [INIT] ConsumeServicesView initState');
    _loadDropdownData();
    _fetchAllData();  // Fetch saved data on page load
  }

  void _initRows(int count) {
    for (int i = 0; i < count; i++) {
      packageRows.add(PackageRowData());
      serviceRows.add(ServiceRowData());
      engineeringRows.add(EngineeringRowData());
      packageRowLoading.add(false);
      serviceRowLoading.add(false);
      engineeringRowLoading.add(false);
      packageRowSaving.add(false);
      serviceRowSaving.add(false);
      engineeringRowSaving.add(false);
      packageRowDeleting.add(false);
      serviceRowDeleting.add(false);
      engineeringRowDeleting.add(false);
    }
  }

  // ─────────────────────────────────────────────
  //  Load dropdown source data (Well-specific Inventory)
  // ─────────────────────────────────────────────
  Future<void> _loadDropdownData() async {
    print('🔵 [LOAD] Loading dropdown data from inventory...');
    try {
      const wellId = '507f1f77bcf86cd799439011';
      
      final pkgs = await InventoryProductsService.fetchPackages(wellId);
      final srvs = await InventoryProductsService.fetchServices(wellId);
      final engs = await InventoryProductsService.fetchEngineering(wellId);
      
      packages.value = pkgs;
      services.value = srvs;
      engineering.value = engs;
      
      print('🟢 [LOAD] packages=${pkgs.length} services=${srvs.length} engineering=${engs.length}');
    } catch (e) {
      print('🔴 [LOAD] Error loading dropdown data: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  Fetch saved data from backend
  // ─────────────────────────────────────────────
  Future<void> _fetchAllData() async {
    print('🔵 [FETCH] Fetching all saved data...');
    try {
      // Fetch packages
      final pkgData = await consumeServiceController.getAllConsumePackages();
      print('🟢 [FETCH] Packages: ${pkgData.length} items');
      
      // Clear existing rows except first empty one
      packageRows.clear();
      packageRowLoading.clear();
      packageRowSaving.clear();
      packageRowDeleting.clear();

      // Add fetched data
      for (var item in pkgData) {
        final row = PackageRowData();
        row.selectedItem = item['packageName'] ?? '';
        row.code         = item['code'] ?? '';
        row.unit         = item['unit'] ?? '';
        row.price        = (item['price'] ?? 0).toDouble();
        row.initial      = (item['initial'] ?? 0).toString();
        row.used         = (item['used'] ?? 0).toString();
        row.finalValue   = (item['final'] ?? 0).toString();
        row.cost         = (item['cost'] ?? 0).toDouble();
        row.savedId      = item['_id'];
        
        packageRows.add(row);
        packageRowLoading.add(false);
        packageRowSaving.add(false);
        packageRowDeleting.add(false);
      }
      
      // Add one empty row at end
      packageRows.add(PackageRowData());
      packageRowLoading.add(false);
      packageRowSaving.add(false);
      packageRowDeleting.add(false);

      // Fetch services
      final srvData = await consumeServiceController.getAllConsumeServices();
      print('🟢 [FETCH] Services: ${srvData.length} items');
      
      serviceRows.clear();
      serviceRowLoading.clear();
      serviceRowSaving.clear();
      serviceRowDeleting.clear();

      for (var item in srvData) {
        final row = ServiceRowData();
        row.selectedItem = item['serviceName'] ?? '';
        row.code         = item['code'] ?? '';
        row.unit         = item['unit'] ?? '';
        row.price        = (item['price'] ?? 0).toDouble();
        row.usage        = (item['usage'] ?? 0).toString();
        row.cost         = (item['cost'] ?? 0).toDouble();
        row.savedId      = item['_id'];
        
        serviceRows.add(row);
        serviceRowLoading.add(false);
        serviceRowSaving.add(false);
        serviceRowDeleting.add(false);
      }
      
      serviceRows.add(ServiceRowData());
      serviceRowLoading.add(false);
      serviceRowSaving.add(false);
      serviceRowDeleting.add(false);

      // Fetch engineering
      final engData = await consumeServiceController.getAllConsumeEngineering();
      print('🟢 [FETCH] Engineering: ${engData.length} items');
      
      engineeringRows.clear();
      engineeringRowLoading.clear();
      engineeringRowSaving.clear();
      engineeringRowDeleting.clear();

      for (var item in engData) {
        final row = EngineeringRowData();
        row.selectedItem = item['engineeringName'] ?? '';
        row.code         = item['code'] ?? '';
        row.unit         = item['unit'] ?? '';
        row.price        = (item['price'] ?? 0).toDouble();
        row.usage        = (item['usage'] ?? 0).toString();
        row.cost         = (item['cost'] ?? 0).toDouble();
        row.savedId      = item['_id'];
        
        engineeringRows.add(row);
        engineeringRowLoading.add(false);
        engineeringRowSaving.add(false);
        engineeringRowDeleting.add(false);
      }
      
      engineeringRows.add(EngineeringRowData());
      engineeringRowLoading.add(false);
      engineeringRowSaving.add(false);
      engineeringRowDeleting.add(false);

      print('🟢 [FETCH] All data loaded successfully');
    } catch (e) {
      print('🔴 [FETCH] Error fetching data: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  CALCULATION — Package
  //  initial blank → treated as 0
  //  final = initial - used  (can be negative)
  //  cost  = used * price
  // ─────────────────────────────────────────────
  void _calculatePackage(int index) {
    if (dashboardController.isLocked.value) return;
    final row = packageRows[index];
    if (row.selectedItem.isEmpty) {
      print('🔴 [CALC-PKG] Row $index: no item selected, skip');
      return;
    }

    final initial = double.tryParse(row.initial) ?? 0.0;
    final used    = double.tryParse(row.used)    ?? 0.0;
    final finalV  = initial - used;          // negative if initial < used
    final cost    = used * row.price;

    print('🔵 [CALC-PKG] Row $index → initial=$initial | used=$used | final=$finalV | cost=$cost');

    row.finalValue = finalV.toStringAsFixed(2);
    row.cost       = cost;
    packageRows.refresh();
    setState(() {});
  }

  // ─────────────────────────────────────────────
  //  CALCULATION — Service / Engineering
  //  cost = usage * price
  // ─────────────────────────────────────────────
  void _calculateService(int index) {
    if (dashboardController.isLocked.value) return;
    final row = serviceRows[index];
    if (row.selectedItem.isEmpty) return;

    final usage = double.tryParse(row.usage) ?? 0.0;
    final cost  = usage * row.price;
    print('🔵 [CALC-SRV] Row $index → usage=$usage | cost=$cost');
    row.cost = cost;
    serviceRows.refresh();
    setState(() {});
  }

  void _calculateEngineering(int index) {
    if (dashboardController.isLocked.value) return;
    final row = engineeringRows[index];
    if (row.selectedItem.isEmpty) return;

    final usage = double.tryParse(row.usage) ?? 0.0;
    final cost  = usage * row.price;
    print('🔵 [CALC-ENG] Row $index → usage=$usage | cost=$cost');
    row.cost = cost;
    engineeringRows.refresh();
    setState(() {});
  }

  // ─────────────────────────────────────────────
  //  INLINE SAVE (calculate → POST to API)
  // ─────────────────────────────────────────────
  Future<void> _savePackageRow(int index) async {
    if (dashboardController.isLocked.value) return;
    final row = packageRows[index];
    if (row.selectedItem.isEmpty) {
      print('🔴 [SAVE-PKG] Row $index empty, skip');
      return;
    }

    // Calculate first
    _calculatePackage(index);

    packageRowSaving[index] = true;
    packageRowSaving.refresh();

    final initial = double.tryParse(row.initial) ?? 0.0;
    final used    = double.tryParse(row.used)    ?? 0.0;

    print('🔵 [SAVE-PKG] Row $index → POST packageName=${row.selectedItem} initial=$initial used=$used price=${row.price}');

    try {
      Map<String, dynamic> result;

      if (row.savedId == null) {
        // CREATE
        result = await consumeServiceController.createConsumePackage(
          packageName: row.selectedItem,
          code:        row.code,
          unit:        row.unit,
          price:       row.price,
          initial:     initial,
          used:        used,
        );
      } else {
        // UPDATE
        result = await consumeServiceController.updateConsumePackage(
          id:          row.savedId!,
          packageName: row.selectedItem,
          code:        row.code,
          unit:        row.unit,
          price:       row.price,
          initial:     initial,
          used:        used,
        );
      }

      print('🟢 [SAVE-PKG] Row $index result: $result');

      if (result['success'] == true) {
        row.savedId = result['data']?['_id'] ?? row.savedId;
        packageRows.refresh();
        _showSuccess('Package row ${index + 1} saved!');
        await _fetchAllData();  // Reload all data after save
      } else {
        _showError(result['message'] ?? 'Save failed');
      }
    } catch (e) {
      print('🔴 [SAVE-PKG] Row $index exception: $e');
      _showError('Error: $e');
    } finally {
      packageRowSaving[index] = false;
      packageRowSaving.refresh();
    }
  }

  Future<void> _saveServiceRow(int index) async {
    if (dashboardController.isLocked.value) return;
    final row = serviceRows[index];
    if (row.selectedItem.isEmpty) return;

    _calculateService(index);

    serviceRowSaving[index] = true;
    serviceRowSaving.refresh();

    final usage = double.tryParse(row.usage) ?? 0.0;
    print('🔵 [SAVE-SRV] Row $index → POST serviceName=${row.selectedItem} usage=$usage price=${row.price}');

    try {
      Map<String, dynamic> result;
      if (row.savedId == null) {
        result = await consumeServiceController.createConsumeService(
          serviceName: row.selectedItem,
          code:        row.code,
          unit:        row.unit,
          price:       row.price,
          usage:       usage,
        );
      } else {
        result = await consumeServiceController.updateConsumeService(
          id:          row.savedId!,
          serviceName: row.selectedItem,
          code:        row.code,
          unit:        row.unit,
          price:       row.price,
          usage:       usage,
        );
      }

      print('🟢 [SAVE-SRV] Row $index result: $result');

      if (result['success'] == true) {
        row.savedId = result['data']?['_id'] ?? row.savedId;
        serviceRows.refresh();
        _showSuccess('Service row ${index + 1} saved!');
        await _fetchAllData();  // Reload all data after save
      } else {
        _showError(result['message'] ?? 'Save failed');
      }
    } catch (e) {
      print('🔴 [SAVE-SRV] Row $index exception: $e');
      _showError('Error: $e');
    } finally {
      serviceRowSaving[index] = false;
      serviceRowSaving.refresh();
    }
  }

  Future<void> _saveEngineeringRow(int index) async {
    if (dashboardController.isLocked.value) return;
    final row = engineeringRows[index];
    if (row.selectedItem.isEmpty) return;

    _calculateEngineering(index);

    engineeringRowSaving[index] = true;
    engineeringRowSaving.refresh();

    final usage = double.tryParse(row.usage) ?? 0.0;
    print('🔵 [SAVE-ENG] Row $index → POST engineeringName=${row.selectedItem} usage=$usage price=${row.price}');

    try {
      Map<String, dynamic> result;
      if (row.savedId == null) {
        result = await consumeServiceController.createConsumeEngineering(
          engineeringName: row.selectedItem,
          code:            row.code,
          unit:            row.unit,
          price:           row.price,
          usage:           usage,
        );
      } else {
        result = await consumeServiceController.updateConsumeEngineering(
          id:              row.savedId!,
          engineeringName: row.selectedItem,
          code:            row.code,
          unit:            row.unit,
          price:           row.price,
          usage:           usage,
        );
      }

      print('🟢 [SAVE-ENG] Row $index result: $result');

      if (result['success'] == true) {
        row.savedId = result['data']?['_id'] ?? row.savedId;
        engineeringRows.refresh();
        _showSuccess('Engineering row ${index + 1} saved!');
        await _fetchAllData();  // Reload all data after save
      } else {
        _showError(result['message'] ?? 'Save failed');
      }
    } catch (e) {
      print('🔴 [SAVE-ENG] Row $index exception: $e');
      _showError('Error: $e');
    } finally {
      engineeringRowSaving[index] = false;
      engineeringRowSaving.refresh();
    }
  }

  // ─────────────────────────────────────────────
  //  INLINE DELETE
  // ─────────────────────────────────────────────
  Future<void> _deletePackageRow(int index) async {
    final row = packageRows[index];
    print('🔵 [DEL-PKG] Row $index | savedId=${row.savedId}');

    if (row.savedId != null) {
      packageRowDeleting[index] = true;
      packageRowDeleting.refresh();
      try {
        final result = await consumeServiceController.deleteConsumePackage(row.savedId!);
        print('🟢 [DEL-PKG] Row $index result: $result');
        if (result['success'] != true) {
          _showError(result['message'] ?? 'Delete failed');
          packageRowDeleting[index] = false;
          packageRowDeleting.refresh();
          return;
        }
        // Reload all data after successful delete
        await _fetchAllData();
        _showSuccess('Package deleted');
      } catch (e) {
        print('🔴 [DEL-PKG] Row $index exception: $e');
        _showError('Error: $e');
      } finally {
        packageRowDeleting[index] = false;
        packageRowDeleting.refresh();
      }
    } else {
      // Just reset unsaved row
      packageRows[index] = PackageRowData();
      packageRows.refresh();
    }
  }

  Future<void> _deleteServiceRow(int index) async {
    final row = serviceRows[index];
    print('🔵 [DEL-SRV] Row $index | savedId=${row.savedId}');

    if (row.savedId != null) {
      serviceRowDeleting[index] = true;
      serviceRowDeleting.refresh();
      try {
        final result = await consumeServiceController.deleteConsumeService(row.savedId!);
        print('🟢 [DEL-SRV] Row $index result: $result');
        if (result['success'] != true) {
          _showError(result['message'] ?? 'Delete failed');
          serviceRowDeleting[index] = false;
          serviceRowDeleting.refresh();
          return;
        }
        await _fetchAllData();
        _showSuccess('Service deleted');
      } catch (e) {
        print('🔴 [DEL-SRV] Row $index exception: $e');
        _showError('Error: $e');
      } finally {
        serviceRowDeleting[index] = false;
        serviceRowDeleting.refresh();
      }
    } else {
      serviceRows[index] = ServiceRowData();
      serviceRows.refresh();
    }
  }

  Future<void> _deleteEngineeringRow(int index) async {
    final row = engineeringRows[index];
    print('🔵 [DEL-ENG] Row $index | savedId=${row.savedId}');

    if (row.savedId != null) {
      engineeringRowDeleting[index] = true;
      engineeringRowDeleting.refresh();
      try {
        final result = await consumeServiceController.deleteConsumeEngineering(row.savedId!);
        print('🟢 [DEL-ENG] Row $index result: $result');
        if (result['success'] != true) {
          _showError(result['message'] ?? 'Delete failed');
          engineeringRowDeleting[index] = false;
          engineeringRowDeleting.refresh();
          return;
        }
        await _fetchAllData();
        _showSuccess('Engineering deleted');
      } catch (e) {
        print('🔴 [DEL-ENG] Row $index exception: $e');
        _showError('Error: $e');
      } finally {
        engineeringRowDeleting[index] = false;
        engineeringRowDeleting.refresh();
      }
    } else {
      engineeringRows[index] = EngineeringRowData();
      engineeringRows.refresh();
    }
  }

  // ─────────────────────────────────────────────
  //  SAVE ALL → generateInventorySnapshot
  // ─────────────────────────────────────────────
  Future<void> _saveAll() async {
    if (dashboardController.isLocked.value) return;
    isSaving.value = true;

    print('🟡 [SAVE-ALL] Save All button pressed');

    try {
      // Step 1: Save all unsaved filled rows
      print('🔵 [SAVE-ALL] Saving package rows...');
      for (int i = 0; i < packageRows.length; i++) {
        if (packageRows[i].selectedItem.isNotEmpty) {
          await _savePackageRow(i);
        }
      }

      print('🔵 [SAVE-ALL] Saving service rows...');
      for (int i = 0; i < serviceRows.length; i++) {
        if (serviceRows[i].selectedItem.isNotEmpty) {
          await _saveServiceRow(i);
        }
      }

      print('🔵 [SAVE-ALL] Saving engineering rows...');
      for (int i = 0; i < engineeringRows.length; i++) {
        if (engineeringRows[i].selectedItem.isNotEmpty) {
          await _saveEngineeringRow(i);
        }
      }

      // Step 2: Generate inventory snapshot
      print('🔵 [SAVE-ALL] Calling generateInventorySnapshot...');
      final snapResult = await inventorySnapshotController.generateInventorySnapshot();
      print('🟢 [SAVE-ALL] generateInventorySnapshot result: $snapResult');

      if (snapResult['success'] == true) {
        _showSuccess(
          'All saved! Snapshot generated (${snapResult['count']} items)',
          duration: 3,
        );
      } else {
        _showError('Rows saved but snapshot failed: ${snapResult['message']}');
      }
    } catch (e) {
      print('🔴 [SAVE-ALL] Exception: $e');
      _showError('Save All failed: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ─────────────────────────────────────────────
  //  Auto-add new row when last row is filled
  // ─────────────────────────────────────────────
  void _checkAndAddRow<T extends BaseRowData>(
    RxList<T> rows,
    RxList<bool> loading,
    RxList<bool> saving,
    RxList<bool> deleting,
  ) {
    if (rows.last.selectedItem.isNotEmpty) {
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
      print('🟢 [ROW] New empty row added to ${T.toString()} table');
    }
  }

  // ─────────────────────────────────────────────
  //  Auto-add new row when last row is filled
  // ─────────────────────────────────────────────
  void checkAndAddRow<T extends BaseRowData>(
    RxList<T> rows,
    RxList<bool> loading,
    RxList<bool> saving,
    RxList<bool> deleting,
  ) {
    // If last row is filled, add a new empty row
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
      print('🟢 [ROW] New empty row added to ${T.toString()} table');
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
                    style: AppTheme.bodySmall
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
                const SizedBox(width: 16),
                _buildCompactRadio("Used", "Used"),
                const SizedBox(width: 12),
                _buildCompactRadio("Final", "Final"),
                const Spacer(),
                Obx(() => ElevatedButton.icon(
                      onPressed: dashboardController.isLocked.value || isSaving.value
                          ? null
                          : _saveAll,
                      icon: isSaving.value
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Icon(Icons.save, size: 16),
                      label: Text(isSaving.value ? 'Saving...' : 'Save All',
                          style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        minimumSize: const Size(100, 32),
                      ),
                    )),
              ],
            ),
          ),

          // ── Tables — equally split, each fills 1/3 of available height ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Left align tables
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
                      headers: const ["Package", "Code", "Unit", "Price (\$)", "Initial", "Used", "Final", "Cost (\$)", "", ""],
                      onDropdownChanged: (i, item) {
                        packageRows[i].selectedItem = item.name;
                        packageRows[i].code  = item.code;
                        packageRows[i].unit  = item.unit;
                        packageRows[i].price = item.price;
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
                      headers: const ["Services", "Code", "Unit", "Price (\$)", "Usage", "Cost (\$)", "", ""],
                      onDropdownChanged: (i, item) {
                        serviceRows[i].selectedItem = item.name;
                        serviceRows[i].code  = item.code;
                        serviceRows[i].unit  = item.unit;
                        serviceRows[i].price = item.price;
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
                      headers: const ["Engineering", "Code", "Unit", "Price (\$)", "Usage", "Cost (\$)", "", ""],
                      onDropdownChanged: (i, item) {
                        engineeringRows[i].selectedItem = item.name;
                        engineeringRows[i].code  = item.code;
                        engineeringRows[i].unit  = item.unit;
                        engineeringRows[i].price = item.price;
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
      T row,
      int index,
      bool isSelected,
      RxList<I> dropdownItems,
      Function(int, I) onDropdownChanged,
      VoidCallback onRowSelected,
      Function(int) onCalculate,
      Function(int) onSave,
      Function(int) onDelete,
      bool isSaving,
      bool isDeleting,
    ) cellBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Text(title,
                style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Colors.white)),
          ),

          // Data table — compressed height with scrollable rows
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Obx(() => DataTable(
                      headingRowHeight: 26,  // compressed from 28
                      dataRowHeight: 26,      // compressed from 28
                      columnSpacing: 0,
                      horizontalMargin: 0,
                      dividerThickness: 0,
                      headingRowColor:
                          MaterialStateProperty.all(Colors.grey.shade50),
                      border: TableBorder(
                        verticalInside: BorderSide(
                            color: Colors.grey.shade300, width: 1),
                        horizontalInside: BorderSide(
                            color: Colors.grey.shade200, width: 1),
                      ),
                      headingTextStyle: AppTheme.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color),
                      dataTextStyle: AppTheme.bodySmall.copyWith(fontSize: 9),
                      columns: headers
                          .map((h) => DataColumn(
                                label: Container(
                                  width: _colWidth(h),
                                  alignment: _isNumericHeader(h)
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  child: Text(h),
                                ),
                              ))
                          .toList(),
                      rows: List.generate(rows.length, (i) {
                        final row        = rows[i];
                        final isSelected = selectedRowIndex.value == i;
                        final saving     = rowSaving[i];
                        final deleting   = rowDeleting[i];

                        return DataRow(
                          color: MaterialStateProperty.all(
                              i % 2 == 0 ? Colors.white : Colors.grey.shade50),
                          cells: cellBuilder(
                            row,
                            i,
                            isSelected,
                            dropdownItems,
                            onDropdownChanged,
                            () => selectedRowIndex.value = i,
                            onCalculate,
                            onSave,
                            onDelete,
                            saving,
                            deleting,
                          ),
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
  //  PACKAGE row cells
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
  ) {
    return [
      // Dropdown
      _dropdownCell<PackageItem>(
        row: row,
        index: index,
        isSelected: isSelected,
        dropdownItems: dropdownItems,
        onDropdownChanged: onDropdownChanged,
        onRowSelected: onRowSelected,
        width: 160,
        getName: (i) => i.name,
      ),
      // Code (editable)
      _editCell(row.code, 90, (v) => row.code = v),
      // Unit (editable)
      _editCell(row.unit, 70, (v) => row.unit = v),
      // Price (editable)
      _editCell(row.price > 0 ? row.price.toStringAsFixed(2) : '', 90, (v) {
        row.price = double.tryParse(v) ?? 0.0;
        _calculatePackage(index);
      }),
      // Initial (editable)
      _editCell(row.initial, 80, (v) {
        row.initial = v;
        _calculatePackage(index);
      }),
      // Used (editable)
      _editCell(row.used, 80, (v) {
        row.used = v;
        _calculatePackage(index);
      }),
      // Final (auto-computed, read-only, colored if negative)
      DataCell(Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerRight,
        child: Text(
          row.finalValue,
          style: AppTheme.bodySmall.copyWith(
            fontSize: 9,
            color: (double.tryParse(row.finalValue) ?? 0) < 0
                ? Colors.red
                : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      )),
      // Cost (auto-computed)
      _readCell(row.cost > 0 ? row.cost.toStringAsFixed(2) : '', 90,
          rightAlign: true, bold: true, color: AppTheme.primaryColor),
      // Calculate + Save button
      DataCell(_actionButtons(
        index: index,
        isSaving: isSaving,
        isDeleting: isDeleting,
        hasItem: row.selectedItem.isNotEmpty,
        onCalculate: () => onCalculate(index),
        onSave: () => onSave(index),
      )),
      // Delete button
      DataCell(_deleteButton(
        index: index,
        isDeleting: isDeleting,
        onDelete: () => onDelete(index),
      )),
    ];
  }

  // ─────────────────────────────────────────────
  //  SERVICE row cells
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
  ) {
    return [
      _dropdownCell<ServiceItem>(
        row: row,
        index: index,
        isSelected: isSelected,
        dropdownItems: dropdownItems,
        onDropdownChanged: onDropdownChanged,
        onRowSelected: onRowSelected,
        width: 160,
        getName: (i) => i.name,
      ),
      _editCell(row.code, 90, (v) => row.code = v),
      _editCell(row.unit, 70, (v) => row.unit = v),
      _editCell(row.price > 0 ? row.price.toStringAsFixed(2) : '', 90, (v) {
        row.price = double.tryParse(v) ?? 0.0;
        _calculateService(index);
      }),
      _editCell(row.usage, 80, (v) {
        row.usage = v;
        _calculateService(index);
      }),
      _readCell(row.cost > 0 ? row.cost.toStringAsFixed(2) : '', 90,
          rightAlign: true, bold: true, color: AppTheme.successColor),
      DataCell(_actionButtons(
        index: index,
        isSaving: isSaving,
        isDeleting: isDeleting,
        hasItem: row.selectedItem.isNotEmpty,
        onCalculate: () => onCalculate(index),
        onSave: () => onSave(index),
      )),
      DataCell(_deleteButton(
        index: index,
        isDeleting: isDeleting,
        onDelete: () => onDelete(index),
      )),
    ];
  }

  // ─────────────────────────────────────────────
  //  ENGINEERING row cells
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
  ) {
    return [
      _dropdownCell<EngineeringItem>(
        row: row,
        index: index,
        isSelected: isSelected,
        dropdownItems: dropdownItems,
        onDropdownChanged: onDropdownChanged,
        onRowSelected: onRowSelected,
        width: 160,
        getName: (i) => i.name,
      ),
      _editCell(row.code, 90, (v) => row.code = v),
      _editCell(row.unit, 70, (v) => row.unit = v),
      _editCell(row.price > 0 ? row.price.toStringAsFixed(2) : '', 90, (v) {
        row.price = double.tryParse(v) ?? 0.0;
        _calculateEngineering(index);
      }),
      _editCell(row.usage, 80, (v) {
        row.usage = v;
        _calculateEngineering(index);
      }),
      _readCell(row.cost > 0 ? row.cost.toStringAsFixed(2) : '', 90,
          rightAlign: true, bold: true, color: AppTheme.infoColor),
      DataCell(_actionButtons(
        index: index,
        isSaving: isSaving,
        isDeleting: isDeleting,
        hasItem: row.selectedItem.isNotEmpty,
        onCalculate: () => onCalculate(index),
        onSave: () => onSave(index),
      )),
      DataCell(_deleteButton(
        index: index,
        isDeleting: isDeleting,
        onDelete: () => onDelete(index),
      )),
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
          if (isSelected)
            Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.primaryColor),
          if (isSelected) const SizedBox(width: 2),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<I>(
                value: row.selectedItem.isNotEmpty
                    ? dropdownItems.firstWhereOrNull(
                        (item) => getName(item) == row.selectedItem)
                    : null,
                hint: Text("Select",
                    style: AppTheme.bodySmall.copyWith(
                        fontSize: 9, color: Colors.grey)),
                isExpanded: true,
                isDense: true,
                icon: const SizedBox.shrink(),
                menuMaxHeight: 200,
                items: dropdownItems
                    .map((item) => DropdownMenuItem<I>(
                          value: item,
                          child: Text(getName(item),
                              style: AppTheme.bodySmall.copyWith(fontSize: 9),
                              overflow: TextOverflow.ellipsis),
                        ))
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
      child: Text(
        val,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 9,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: color ?? Colors.grey.shade800,
        ),
      ),
    ));
  }

  DataCell _editCell(String value, double width, Function(String) onChanged) {
    return DataCell(Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: TextEditingController(text: value),
        enabled: !dashboardController.isLocked.value,
        style: AppTheme.bodySmall.copyWith(fontSize: 9),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          border: InputBorder.none,
        ),
        keyboardType: const TextInputType.numberWithOptions(
            signed: true, decimal: true),
        onChanged: onChanged,
      ),
    ));
  }

  // Action buttons: play (calculate) + save icon
  Widget _actionButtons({
    required int index,
    required bool isSaving,
    required bool isDeleting,
    required bool hasItem,
    required VoidCallback onCalculate,
    required VoidCallback onSave,
  }) {
    if (isSaving) {
      return const SizedBox(
        width: 60,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return SizedBox(
      width: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Calculate
          IconButton(
            icon: Icon(Icons.play_circle_outline,
                size: 16,
                color: hasItem && !dashboardController.isLocked.value
                    ? AppTheme.primaryColor
                    : Colors.grey.shade400),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: hasItem && !dashboardController.isLocked.value
                ? onCalculate
                : null,
            tooltip: 'Calculate',
          ),
          const SizedBox(width: 4),
          // Save
          IconButton(
            icon: Icon(Icons.save_outlined,
                size: 16,
                color: hasItem && !dashboardController.isLocked.value
                    ? const Color(0xff10B981)
                    : Colors.grey.shade400),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: hasItem && !dashboardController.isLocked.value
                ? onSave
                : null,
            tooltip: 'Save row',
          ),
        ],
      ),
    );
  }

  // Delete button
  Widget _deleteButton({
    required int index,
    required bool isDeleting,
    required VoidCallback onDelete,
  }) {
    if (isDeleting) {
      return const SizedBox(
        width: 32,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
          ),
        ),
      );
    }
    return SizedBox(
      width: 32,
      child: IconButton(
        icon: Icon(Icons.delete_outline,
            size: 15,
            color: dashboardController.isLocked.value
                ? Colors.grey.shade300
                : Colors.red.shade300),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed:
            dashboardController.isLocked.value ? null : onDelete,
        tooltip: 'Delete row',
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Radio button
  // ─────────────────────────────────────────────
  Widget _buildCompactRadio(String label, String value) {
    return Obx(() => InkWell(
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
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
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
              Text(label,
                  style: AppTheme.bodySmall.copyWith(
                      fontSize: 11,
                      color: selectedMethod.value == value
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary)),
            ]),
          ),
        ));
  }

  // ─────────────────────────────────────────────
  //  Column width / numeric header helpers
  // ─────────────────────────────────────────────
  double _colWidth(String h) {
    if (h == 'Package' || h == 'Services' || h == 'Engineering') return 160;
    if (h == 'Code')    return 90;
    if (h == 'Unit')    return 70;
    if (h.contains('Price') || h.contains('Cost')) return 90;
    if (h == '' )       return 32; // delete column
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
  String  selectedItem = '';
  String  code         = '';
  String  unit         = '';
  double  price        = 0.0;
  double  cost         = 0.0;
  String  initial      = '';
  String  used         = '';
  String  finalValue   = '';   // can be negative, shown in red
  String? savedId;          // MongoDB _id after save
}

class PackageRowData extends BaseRowData {}

class ServiceRowData extends BaseRowData {
  String get usage => used;
  set usage(String v) => used = v;
}

class EngineeringRowData extends BaseRowData {
  String usage = '';
}