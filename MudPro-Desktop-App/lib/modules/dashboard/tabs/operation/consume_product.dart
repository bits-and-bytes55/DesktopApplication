import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/consume_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ConsumeProductView extends StatefulWidget {
  const ConsumeProductView({super.key});

  @override
  State<ConsumeProductView> createState() => _ConsumeProductViewState();
}

class _ConsumeProductViewState extends State<ConsumeProductView> {
  final OperationController operationController = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  final PitController pitController = Get.isRegistered<PitController>()
      ? Get.find<PitController>()
      : Get.put(PitController());
  final ConsumeProductController consumeProductController = ConsumeProductController();
  final InventorySnapshotController inventorySnapshotController = InventorySnapshotController();

  late final InventoryProductsStore _inventoryStore;

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
  final RxBool isSavingAll = false.obs;

  // Special option constants
  static const String kActiveSystem = 'Active System';
  static const String kEmpty = '';

  RxList<ProductModel> get products => _inventoryStore.selectedProducts;

  @override
  void initState() {
    super.initState();
    _inventoryStore = Get.find<InventoryProductsStore>();
    pitController.fetchAllPits();
    pitController.fetchUnselectedPits();
    _fetchAllConsumeProducts();
    // Start with 1 row in distribute table
    _addDistributeRow();
    
    waterVolumeController.addListener(_recalculateTotalVolume);
    waterVolumeController.addListener(() {
      operationController.addWaterVolume.value = waterVolumeController.text;
      operationController.addWaterMainVol.value = waterVolumeController.text;
    });

    Future.microtask(_loadSavedAddWater);

    final lastWater = operationController.addWaterMainVol.value.trim().isNotEmpty
        ? operationController.addWaterMainVol.value.trim()
        : operationController.addWaterVolume.value.trim();
    if (lastWater.isNotEmpty && (double.tryParse(lastWater) ?? 0) > 0) {
      addWater.value = true;
      waterVolumeController.text = lastWater;
    }
    addWater.listen((enabled) {
      if (!enabled) {
        waterVolumeController.text = '';
        operationController.addWaterVolume.value = '';
        operationController.addWaterMainVol.value = '';
        _recalculateTotalVolume();
      }
    });

    // Automatically rebalance distribution whenever total volume changes
    ever(operationController.totalVolume, (_) => _rebalanceDistributeVolumes());
  }

  Future<void> _loadSavedAddWater() async {
    await operationController.loadAddWater(force: true);
    if (!mounted) return;

    final savedWater = operationController.addWaterMainVol.value.trim();
    final savedWaterValue = double.tryParse(savedWater) ?? 0.0;
    if (savedWaterValue <= 0 || waterVolumeController.text.trim().isNotEmpty) {
      return;
    }

    addWater.value = true;
    waterVolumeController.text = savedWater;
    operationController.addWaterVolume.value = savedWater;
    _recalculateTotalVolume();
  }

  @override
  void dispose() {
    waterVolumeController.removeListener(_recalculateTotalVolume);
    waterVolumeController.dispose();
    
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

        row.code    = item['code']?.toString() ?? '';
        row.sg      = item['sg']?.toString() ?? '';
        row.unit    = item['unit']?.toString() ?? '';
        row.price   = _toDouble(item['price']);
        row.initial = _numStr(item['initial']);
        row.adjust  = _numStr(item['adjust']);
        row.used    = _numStr(item['used']);
        row.savedId = item['_id']?.toString();

        row.recalculate();
        productRows.add(row);
        productRowSaving.add(false);
        productRowDeleting.add(false);

        debugPrint('🟢 [ROW] name="$productName" code=${row.code} savedId=${row.savedId}');
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

  bool _isCostCalculated(ProductRowData row) {
    final usedVal = double.tryParse(row.used) ?? 0.0;
    return usedVal > 0 && row.price > 0;
  }

  void _onFieldChanged(int index) {
    if (index >= productRows.length) return;
    final row = productRows[index];
    if (row.productName.isEmpty && row.selectedProduct.value == null) return;

    row.recalculate();
    productRows.refresh();
    _recalculateTotalVolume();

    if (_isCostCalculated(row)) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (index < productRows.length) {
          _saveRow(index);
        }
      });
    }
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
  void _addDistributeRow() {
    final newRow = DistributeRowData();
    distributeRows.add(newRow);
    // Rebalance volumes to ensure first row is correct
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
      return;
    }
    
    // Dispose the controller before removing to avoid leaks
    distributeRows[index].volumeController.dispose();
    distributeRows.removeAt(index);
    
    if (selectedDistributeRow.value >= distributeRows.length) {
      selectedDistributeRow.value = distributeRows.length - 1;
    }
    _rebalanceDistributeVolumes();
  }

  /// Auto-fill first row with total vol when a pit is selected
  void _onDistributePitSelected(int index, String pitName) {
    distributeRows[index].pit = pitName;

    if (pitName == kEmpty) {
      // Clear volume if empty selected
      distributeRows[index].volume = '';
      distributeRows[index].volumeController.text = '';
      distributeRows.refresh();
      return;
    }

    if (index == 0) {
      // First row always gets total volume (minus other assigned rows)
      _rebalanceDistributeVolumes();
    }
    distributeRows.refresh();
  }

  /// Called when user manually changes volume (triggered on every keystroke)
  void _onDistributeVolumeChanged(int index, String value) {
    // Update internal value only
    distributeRows[index].volume = value;
    // We don't automatically trigger rebalance on every keypress for other rows 
    // to prevent Row 1's volume jumping while the user is typing.
    // Rebalance will happen when user clicks Calculate or on lose focus/submit.
  }

  /// Calculate button: recalculate first row as the remainder of Total Vol.
  void _calculateDistribution() {
    _rebalanceDistributeVolumes();
  }

  /// Rebalance: update row 0 volume = totalVol - sum of other rows
  void _rebalanceDistributeVolumes() {
    if (distributeRows.isEmpty) return;

    final totalVol = operationController.totalVolume.value;
    
    // Sum volumes allocated to all rows except the first one
    double otherVolumes = 0.0;
    for (int i = 1; i < distributeRows.length; i++) {
      otherVolumes += double.tryParse(distributeRows[i].volume) ?? 0.0;
    }

    // First row automatically adjusts to take the remainder of Total Volume
    if (distributeRows[0].pit.isNotEmpty) {
      final remaining = totalVol - otherVolumes;
      final formattedVol = remaining >= 0 ? remaining.toStringAsFixed(3) : '0.000';
      
      distributeRows[0].volume = formattedVol;
      distributeRows[0].volumeController.text = formattedVol;
      distributeRows.refresh();
    }
  }

  // ─────────────────────────────────────────────
  //  SAVE ROW
  // ─────────────────────────────────────────────
  Future<void> _saveRow(int index) async {
    if (dashboardController.isLocked.value) return;
    if (index >= productRows.length) return;
    final row = productRows[index];

    final productName = row.selectedProduct.value?.product.isNotEmpty == true
        ? row.selectedProduct.value!.product
        : row.productName;

    if (productName.isEmpty) return;
    if (!_isCostCalculated(row)) return;

    if (_savingInProgress.contains(index)) {
      debugPrint('⏳ [SAVE] Row $index already saving — skip');
      return;
    }

    _savingInProgress.add(index);

    row.recalculate();
    productRows.refresh();

    if (index < productRowSaving.length) {
      productRowSaving[index] = true;
      productRowSaving.refresh();
    }

    try {
      Map<String, dynamic> result;

      if (row.savedId == null) {
        debugPrint('🆕 [CREATE] Row $index — product="$productName"');
        result = await consumeProductController.createConsumeProduct(
          productName:  productName,
          code:         row.code,
          sg:           double.tryParse(row.sg) ?? 0.0,
          unit:         row.unit,
          price:        row.price,
          initial:      double.tryParse(row.initial) ?? 0.0,
          adjust:       double.tryParse(row.adjust) ?? 0.0,
          used:         double.tryParse(row.used) ?? 0.0,
          numberOfBags: 1.0,
          weightPerBag: 1.0,
        );

        if (result['success'] == true) {
          row.savedId     = result['data']?['_id']?.toString();
          row.productName = productName;
          productRows.refresh();
          debugPrint('✅ [CREATE] Done — savedId=${row.savedId}');
        } else {
          _showToast(result['message'] ?? 'Save failed', isError: true);
        }
      } else {
        debugPrint('✏️ [UPDATE] Row $index — product="$productName" id=${row.savedId}');
        result = await consumeProductController.updateConsumeProduct(
          id:           row.savedId!,
          productName:  productName,
          code:         row.code,
          sg:           double.tryParse(row.sg) ?? 0.0,
          unit:         row.unit,
          price:        row.price,
          initial:      double.tryParse(row.initial) ?? 0.0,
          adjust:       double.tryParse(row.adjust) ?? 0.0,
          used:         double.tryParse(row.used) ?? 0.0,
          numberOfBags: 1.0,
          weightPerBag: 1.0,
        );

        if (result['success'] == true) {
          debugPrint('✅ [UPDATE] Done — savedId=${row.savedId}');
        } else {
          _showToast(result['message'] ?? 'Update failed', isError: true);
        }
      }
    } catch (e) {
      _showToast('Save error: $e', isError: true);
    } finally {
      _savingInProgress.remove(index);
      if (index < productRowSaving.length) {
        productRowSaving[index] = false;
        productRowSaving.refresh();
      }
    }
  }

  Future<void> _deleteRow(int index) async {
    if (index >= productRows.length) return;
    final row = productRows[index];

    if (row.savedId == null) {
      if (productRows.length > 1) {
        productRows.removeAt(index);
        if (index < productRowSaving.length) productRowSaving.removeAt(index);
        if (index < productRowDeleting.length) productRowDeleting.removeAt(index);
        _savingInProgress.remove(index);
      } else {
        productRows[index] = ProductRowData();
        productRows.refresh();
      }
      _recalculateTotalVolume();
      return;
    }

    if (index < productRowDeleting.length) {
      productRowDeleting[index] = true;
      productRowDeleting.refresh();
    }

    try {
      final result = await consumeProductController.deleteConsumeProduct(row.savedId!);
      if (result['success'] == true) {
        _savingInProgress.remove(index);
        await _fetchAllConsumeProducts();
        _showToast('Deleted');
      } else {
        _showToast(result['message'] ?? 'Delete failed', isError: true);
        if (index < productRowDeleting.length) {
          productRowDeleting[index] = false;
          productRowDeleting.refresh();
        }
      }
    } catch (e) {
      _showToast('Delete error: $e', isError: true);
      if (index < productRowDeleting.length) {
        productRowDeleting[index] = false;
        productRowDeleting.refresh();
      }
    }
  }

  Future<void> _saveAll() async {
    if (dashboardController.isLocked.value || isSavingAll.value) return;
    isSavingAll.value = true;
    try {
      for (int i = 0; i < productRows.length; i++) {
        if (productRows[i].productName.isNotEmpty &&
            productRows[i].savedId == null &&
            _isCostCalculated(productRows[i])) {
          await _saveRow(i);
        }
      }

      final waterResult = await _saveAddWaterIfNeeded();
      if (waterResult != null && waterResult['success'] != true) {
        _showToast('Add Water failed: ${waterResult['message']}', isError: true);
      }
      final snapResult = await inventorySnapshotController.generateInventorySnapshot();
      if (snapResult['success'] == true) {
        _showToast('Saved! Snapshot: ${snapResult['count']} items');
      } else {
        _showToast('Snapshot failed: ${snapResult['message']}', isError: true);
      }
    } catch (e) {
      _showToast('Save All failed: $e', isError: true);
    } finally {
      isSavingAll.value = false;
    }
  }

  Future<Map<String, dynamic>?> _saveAddWaterIfNeeded() async {
    if (!addWater.value) return null;

    final waterText = waterVolumeController.text.trim();
    final waterVol = double.tryParse(waterText) ?? 0.0;
    if (waterVol <= 0) return null;

    await operationController.loadAddWater(force: true);
    operationController.addWaterTo.value = kActiveSystem;
    operationController.addWaterMainVol.value = waterText;
    operationController.addWaterVolume.value = waterText;

    return operationController.saveAddWater();
  }

  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 12))),
      ]),
      backgroundColor: isError ? const Color(0xffEF4444) : const Color(0xff10B981),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
      duration: Duration(seconds: isError ? 3 : 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ));
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildTopControls(),
            const SizedBox(height: 10),
            _buildProductTable(),
            const SizedBox(height: 10),
            _buildBottomSection(),
          ]),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(children: [
        Expanded(flex: 2, child: _buildTopProductDropdown()),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: _buildDropdown(hint: "Load Previous Products", icon: Icons.history)),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: Row(children: [
          Text("Input Method",
              style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 10)),
          const SizedBox(width: 10),
          _buildRadioBtn("Used"),
          const SizedBox(width: 6),
          _buildRadioBtn("Final"),
        ])),
      ]),
    );
  }

  Widget _buildTopProductDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(children: [
        Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(child: Obx(() => DropdownButtonHideUnderline(
          child: DropdownButton<ProductModel>(
            value: selectedTopProduct.value != null &&
                products.any((p) => p.id == selectedTopProduct.value?.id)
                ? selectedTopProduct.value : null,
            hint: Text("Select Products",
                style: AppTheme.bodySmall.copyWith(fontSize: 10, color: AppTheme.textSecondary)),
            icon: const Icon(Icons.arrow_drop_down, size: 16),
            isExpanded: true, isDense: true, menuMaxHeight: 300,
            items: products.where((p) => p.id != null).map((p) =>
              DropdownMenuItem(value: p,
                child: Text(p.product,
                    style: AppTheme.bodySmall.copyWith(fontSize: 10),
                    overflow: TextOverflow.ellipsis))).toList(),
            onChanged: dashboardController.isLocked.value
                ? null : (v) => selectedTopProduct.value = v,
          ),
        ))),
      ]),
    );
  }

  Widget _buildDropdown({required String hint, required IconData icon}) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            hint: Text(hint,
                style: AppTheme.bodySmall.copyWith(fontSize: 10, color: AppTheme.textSecondary)),
            icon: const Icon(Icons.arrow_drop_down, size: 16),
            items: const [], onChanged: (_) {},
          ),
        )),
      ]),
    );
  }

  Widget _buildRadioBtn(String value) {
    return Obx(() => InkWell(
      onTap: dashboardController.isLocked.value
          ? null : () => selectedMethod.value = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selectedMethod.value == value
              ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
              color: selectedMethod.value == value
                  ? AppTheme.primaryColor : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 11, height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: selectedMethod.value == value
                      ? AppTheme.primaryColor : Colors.grey.shade400,
                  width: 1.5),
            ),
            child: selectedMethod.value == value
                ? Center(child: Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: AppTheme.primaryColor)))
                : null,
          ),
          const SizedBox(width: 5),
          Text(value, style: AppTheme.bodySmall.copyWith(
            fontSize: 10,
            color: selectedMethod.value == value
                ? AppTheme.primaryColor : AppTheme.textSecondary,
          )),
        ]),
      ),
    ));
  }

  Widget _buildProductTable() {
    const headers = [
      "Product", "Code", "SG", "Unit", "Price (\$)",
      "Initial", "Adjust", "Used", "Final", "Cost (\$)", "Vol (bbl)", "",
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Row(children: [
            const Icon(Icons.inventory_2, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text("Consume Product", style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600, fontSize: 11, color: Colors.white)),
          ]),
        ),
        SizedBox(
          height: 220,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Obx(() => DataTable(
                headingRowHeight: 32, dataRowHeight: 38,
                columnSpacing: 0, horizontalMargin: 0, dividerThickness: 0,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                border: TableBorder(
                  verticalInside: BorderSide(color: Colors.grey.shade300),
                  horizontalInside: BorderSide(color: Colors.grey.shade200),
                ),
                headingTextStyle: AppTheme.bodySmall.copyWith(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor),
                dataTextStyle: AppTheme.bodySmall.copyWith(fontSize: 10),
                columns: headers.map((h) => DataColumn(label: Container(
                  width: _colWidth(h),
                  alignment: _isRightCol(h) ? Alignment.centerRight : Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: (h == 'Used' && selectedMethod.value == 'Used') ||
                           (h == 'Final' && selectedMethod.value == 'Final')
                        ? const Color(0xFFD6EAF8)
                        : null,
                  ),
                  child: Text(h),
                ))).toList(),
                rows: List.generate(productRows.length, (i) => DataRow(
                  color: MaterialStateProperty.all(
                      i % 2 == 0 ? Colors.white : Colors.grey.shade50),
                  cells: _buildRowCells(productRows[i], i),
                )),
              )),
            ),
          ),
        ),
      ]),
    );
  }

  bool _isRightCol(String h) => const {
    'Price (\$)', 'Cost (\$)', 'Initial', 'Adjust', 'Used', 'Final', 'Vol (bbl)'
  }.contains(h);

  double _colWidth(String h) {
    switch (h) {
      case 'Product':    return 160;
      case 'Code':       return 80;
      case 'SG':
      case 'Unit':       return 70;
      case 'Price (\$)':
      case 'Cost (\$)':  return 90;
      case '':           return 36;
      default:           return 75;
    }
  }

  List<DataCell> _buildRowCells(ProductRowData row, int i) {
    final locked = dashboardController.isLocked.value;

    return [
      // ══════════════════════════════════════════
      // 1. Product Column
      // ══════════════════════════════════════════
      DataCell(Container(
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
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                isExpanded: true, isDense: true,
                icon: const Icon(Icons.arrow_drop_down, size: 14),
                menuMaxHeight: 300,
                items: storeProducts.where((p) => p.id != null).map((p) =>
                  DropdownMenuItem(value: p,
                    child: Text(p.product,
                        style: AppTheme.bodySmall.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis))).toList(),
                onChanged: locked ? null : (ProductModel? val) {
                  if (val == null) return;
                  selectedProductRow.value = i;
                  row.selectedProduct.value = val;
                  row.productName = val.product;
                  row.code  = val.code;
                  row.sg    = val.sg;
                  row.unit  = _mergeUnit(val);
                  row.price = double.tryParse(val.a) ?? 0.0;
                  final initD = double.tryParse(val.initial) ?? 0.0;
                  row.initial = initD != 0.0 ? val.initial : '';
                  row.adjust = '';
                  row.used   = '';
                  productRows.refresh();
                  _checkAndAddProductRow();
                  row.recalculate();
                  _recalculateTotalVolume();
                },
              ),
            );
          }

          final validVal = currentVal != null &&
              storeProducts.any((p) => p.id == currentVal.id)
              ? currentVal : null;

          return DropdownButtonHideUnderline(
            child: DropdownButton<ProductModel>(
              value: validVal,
              hint: Text("Select",
                  style: AppTheme.bodySmall.copyWith(fontSize: 10, color: Colors.grey)),
              isExpanded: true, isDense: true,
              icon: const Icon(Icons.arrow_drop_down, size: 14),
              menuMaxHeight: 300,
              items: storeProducts.where((p) => p.id != null).map((p) =>
                DropdownMenuItem(value: p,
                  child: Text(p.product,
                      style: AppTheme.bodySmall.copyWith(fontSize: 10),
                      overflow: TextOverflow.ellipsis))).toList(),
              onChanged: locked ? null : (ProductModel? val) {
                if (val == null) return;
                selectedProductRow.value = i;
                row.selectedProduct.value = val;
                row.productName = val.product;
                row.code  = val.code;
                row.sg    = val.sg;
                row.unit  = _mergeUnit(val);
                row.price = double.tryParse(val.a) ?? 0.0;
                final initD = double.tryParse(val.initial) ?? 0.0;
                row.initial = initD != 0.0 ? val.initial : '';
                row.adjust = '';
                row.used   = '';
                productRows.refresh();
                _checkAndAddProductRow();
                row.recalculate();
                _recalculateTotalVolume();
              },
            ),
          );
        }),
      )),

      // 2–5. Static read-only cells
      DataCell(_staticField(row.code, 80)),
      DataCell(_staticField(row.sg, 70)),
      DataCell(_staticField(row.unit, 70)),
      DataCell(_staticField(row.price > 0 ? row.price.toStringAsFixed(2) : '', 90, right: true)),

      // 6. Initial
      DataCell(_editField(
        key: ValueKey('init_${row.savedId ?? i}_${row.productName}'),
        value: row.initial, width: 75, locked: locked,
        onChange: (v) { row.initial = v; _onFieldChanged(i); _checkAndAddProductRow(); },
      )),

      // 7. Adjust
      DataCell(_editField(
        key: ValueKey('adj_${row.savedId ?? i}_${row.productName}'),
        value: row.adjust, width: 75, locked: locked,
        onChange: (v) { row.adjust = v; _onFieldChanged(i); _checkAndAddProductRow(); },
      )),

      // 8. Used
      DataCell(Obx(() {
        final isUsedMode = selectedMethod.value == "Used";
        return _editField(
          key: ValueKey('used_${row.savedId ?? i}_${row.productName}_$isUsedMode'),
          value: row.used,
          width: 75,
          locked: locked || !isUsedMode,
          highlighted: isUsedMode,
          onChange: (v) { row.used = v; _onFieldChanged(i); _checkAndAddProductRow(); },
        );
      })),

      // 9. Final
      DataCell(Obx(() {
        final isFinalMode = selectedMethod.value == "Final";

        if (isFinalMode) {
          return _editField(
            key: ValueKey('final_edit_${row.savedId ?? i}_${row.productName}'),
            value: row.used,
            width: 75,
            locked: locked,
            highlighted: true,
            onChange: (v) { row.used = v; _onFieldChanged(i); _checkAndAddProductRow(); },
          );
        }

        final fv = row.calculatedFinal.value;
        return Container(
          width: 75,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            row.productName.isNotEmpty ? fv.toStringAsFixed(2) : '',
            textAlign: TextAlign.right,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: fv < 0 ? Colors.red : Colors.grey.shade700,
            ),
          ),
        );
      })),

      // 10. Cost
      DataCell(Container(
        width: 90, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.05)),
        child: Obx(() {
          final cv = row.calculatedCost.value;
          return Text(cv > 0 ? cv.toStringAsFixed(2) : '',
            textAlign: TextAlign.right,
            style: AppTheme.bodySmall.copyWith(
                fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryColor));
        }),
      )),

      // 11. Vol
      DataCell(Container(
        width: 75, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.03)),
        child: Obx(() {
          final vv = row.calculatedVolume.value;
          return Text(vv > 0 ? vv.toStringAsFixed(3) : '',
            textAlign: TextAlign.right,
            style: AppTheme.bodySmall.copyWith(fontSize: 10, color: AppTheme.primaryColor));
        }),
      )),

      // 12. Delete
      DataCell(Obx(() {
        final del = i < productRowDeleting.length && productRowDeleting[i];
        if (del) {
          return const SizedBox(width: 36, child: Center(
              child: SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))));
        }
        return SizedBox(width: 36, child: IconButton(
          icon: Icon(Icons.delete_outline, size: 15,
              color: locked ? Colors.grey.shade300 : Colors.red.shade300),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          onPressed: locked ? null : () => _deleteRow(i),
        ));
      })),
    ];
  }

  Widget _staticField(String text, double width, {bool right = false}) {
    return Container(
      width: width, padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodySmall.copyWith(fontSize: 10)),
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
        style: AppTheme.bodySmall.copyWith(fontSize: 10),
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: InputBorder.none,
        ),
        onChanged: onChange,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BOTTOM SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomSection() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 310, child: _buildDistributeTable()),
      const SizedBox(width: 12),
      Expanded(child: _buildRightControls()),
    ]);
  }

  // ── Distribute Table ──────────────────────────────────────────────────────
  Widget _buildDistributeTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(children: [
        // ── Header row with title + action buttons ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.successColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Row(children: [
            const Icon(Icons.share, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text("Distribute to", style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600, fontSize: 11, color: Colors.white)),
            const Spacer(),
            // Calculate button
            Obx(() => _distributeHeaderBtn(
              icon: Icons.calculate_outlined,
              tooltip: 'Calculate distribution',
              onTap: dashboardController.isLocked.value ? null : _calculateDistribution,
            )),
            const SizedBox(width: 4),
            // Delete selected row button
            Obx(() => _distributeHeaderBtn(
              icon: Icons.delete_outline,
              tooltip: 'Delete selected row',
              color: Colors.red.shade100,
              iconColor: Colors.red.shade700,
              onTap: dashboardController.isLocked.value
                  ? null
                  : (selectedDistributeRow.value >= 0 &&
                          selectedDistributeRow.value < distributeRows.length
                      ? () => _deleteDistributeRow(selectedDistributeRow.value)
                      : null),
            )),
            const SizedBox(width: 4),
            // Add row button
            Obx(() => _distributeHeaderBtn(
              icon: Icons.add,
              tooltip: 'Add row',
              onTap: dashboardController.isLocked.value ? null : _addDistributeRow,
            )),
          ]),
        ),

        // ── Table header ──
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(children: [
            _distHeaderCell('Pit', 180),
            _distHeaderCell('Vol (bbl)', 110, right: true),
          ]),
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
                    onTap: () => selectedDistributeRow.value = i,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.successColor.withOpacity(0.06)
                            : (i % 2 == 0 ? Colors.white : Colors.grey.shade50),
                        border: Border(
                          left: isSelected
                              ? BorderSide(color: AppTheme.successColor, width: 2)
                              : BorderSide.none,
                          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                        ),
                      ),
                      child: Row(children: [
                        // Pit dropdown cell
                        SizedBox(
                          width: 180,
                          height: 32,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _buildDistributePitDropdown(dr, i, unselectedPits),
                          ),
                        ),
                        // Volume divider
                        Container(width: 1, height: 32, color: Colors.grey.shade200),
                        // Volume input cell
                        SizedBox(
                          width: 110,
                          height: 32,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: TextField(
                              controller: dr.volumeController,
                              enabled: !dashboardController.isLocked.value,
                              style: AppTheme.bodySmall.copyWith(fontSize: 10),
                              textAlign: TextAlign.right,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 6),
                                border: InputBorder.none,
                              ),
                              onChanged: (v) => _onDistributeVolumeChanged(i, v),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ]),
    );
  }

  Widget _buildDistributePitDropdown(
      DistributeRowData dr, int index, List unselectedPits) {
    // Build items: empty option + Active System + unselected pits
    final items = <DropdownMenuItem<String>>[
      // Empty option to clear selection
      DropdownMenuItem<String>(
        value: kEmpty,
        child: Text('',
            style: AppTheme.bodySmall.copyWith(fontSize: 10)),
      ),
      // Active System fixed option
      DropdownMenuItem<String>(
        value: kActiveSystem,
        child: Row(children: [
          Icon(Icons.layers_outlined, size: 12,
              color: AppTheme.primaryColor.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(kActiveSystem,
              style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
      // Unselected pits from API
      ...unselectedPits.map((p) => DropdownMenuItem<String>(
        value: p.pitName,
        child: Text(p.pitName,
            style: AppTheme.bodySmall.copyWith(fontSize: 10),
            overflow: TextOverflow.ellipsis),
      )),
    ];

    // Validate current value
    final validValues = {kEmpty, kActiveSystem, ...unselectedPits.map((p) => p.pitName)};
    final currentValue = validValues.contains(dr.pit) ? dr.pit : kEmpty;

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
        style: AppTheme.bodySmall.copyWith(fontSize: 10, color: AppTheme.textPrimary),
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
                ? Colors.white.withOpacity(0.1)
                : (color ?? Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(
            icon,
            size: 13,
            color: onTap == null
                ? Colors.white.withOpacity(0.3)
                : (iconColor ?? Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _distHeaderCell(String text, double width, {bool right = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: AppTheme.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.successColor),
      ),
    );
  }

  // ── Right Controls ────────────────────────────────────────────────────────
  Widget _buildRightControls() {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Obx(() => Row(children: [
          InkWell(
            onTap: dashboardController.isLocked.value ? null : () {
              addWater.value = !addWater.value;
              _recalculateTotalVolume();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: addWater.value
                    ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                    color: addWater.value ? AppTheme.primaryColor : Colors.grey.shade300),
              ),
              child: Row(children: [
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                        color: addWater.value ? AppTheme.primaryColor : Colors.grey.shade400),
                    color: addWater.value ? AppTheme.primaryColor : Colors.transparent,
                  ),
                  child: addWater.value
                      ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                ),
                const SizedBox(width: 8),
                Text("Add Water", style: AppTheme.bodySmall.copyWith(
                    fontSize: 10, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
          if (addWater.value) ...[
            const SizedBox(width: 10),
            Expanded(child: _waterField()),
          ],
        ])),

        const SizedBox(height: 10),

        Row(children: [
          Text("Total Vol.",
              style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Expanded(child: Obx(() => Container(
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(children: [
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(totalVolumeDisplay.value,
                  textAlign: TextAlign.right,
                  style: AppTheme.bodySmall.copyWith(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor)),
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
                ),
                child: Center(child: Text("bbl", style: AppTheme.bodySmall.copyWith(
                    fontSize: 10, color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600))),
              ),
            ]),
          ))),
        ]),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50, borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 13, color: Colors.amber.shade700),
            const SizedBox(width: 6),
            Expanded(child: Text(
              "If the total volume is 0 and multiple pits are selected, the consumed products will be evenly distributed.",
              style: AppTheme.bodySmall.copyWith(fontSize: 9, color: Colors.amber.shade900),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _waterField() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(children: [
        Expanded(child: TextField(
          controller: waterVolumeController,
          enabled: !dashboardController.isLocked.value,
          style: AppTheme.bodySmall.copyWith(fontSize: 10),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: InputBorder.none,
          ),
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
          ),
          child: Center(child: Text("bbl", style: AppTheme.bodySmall.copyWith(
              fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600))),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class ProductRowData {
  final Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);

  String productName = '';
  String code    = '';
  String sg      = '';
  String unit    = '';
  double price   = 0.0;
  String initial = '';
  String adjust  = '';
  String used    = '';
  String? savedId;

  final RxDouble calculatedCost   = 0.0.obs;
  final RxDouble calculatedVolume = 0.0.obs;
  final RxDouble calculatedFinal  = 0.0.obs;

  void recalculate() {
    final iVal = double.tryParse(initial) ?? 0.0;
    final aVal = double.tryParse(adjust)  ?? 0.0;
    final uVal = double.tryParse(used)    ?? 0.0;
    final sVal = double.tryParse(sg)      ?? 0.0;

    calculatedFinal.value  = iVal + aVal - uVal;
    calculatedCost.value   = uVal * price;
    calculatedVolume.value = (sVal > 0 && uVal > 0)
        ? double.parse((uVal / (sVal * 158.987)).toStringAsFixed(3))
        : 0.0;
  }
}

class DistributeRowData {
  String pit = '';
  String volume = '';
  final TextEditingController volumeController = TextEditingController();
}
