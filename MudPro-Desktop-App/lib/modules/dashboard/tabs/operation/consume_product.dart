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
  final PitController pitController = Get.put(PitController());
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

  final Set<int> _savingInProgress = {};

  final RxInt selectedProductRow = 0.obs;
  final Rx<ProductModel?> selectedTopProduct = Rx<ProductModel?>(null);
  final RxBool isSavingAll = false.obs;

  RxList<ProductModel> get products => _inventoryStore.selectedProducts;

  @override
  void initState() {
    super.initState();
    _inventoryStore = Get.find<InventoryProductsStore>();
    pitController.fetchAllPits();
    _fetchAllConsumeProducts();
    for (int i = 0; i < 5; i++) distributeRows.add(DistributeRowData());
    waterVolumeController.addListener(_recalculateTotalVolume);
  }

  @override
  void dispose() {
    waterVolumeController.removeListener(_recalculateTotalVolume);
    waterVolumeController.dispose();
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

        // ✅ DB se seedha product name lo — yahi dropdown mein dikhega
        final productName = item['product']?.toString() ?? '';
        row.productName = productName;

        // Store mein match karo agar mile — editing ke liye helpful
        if (productName.isNotEmpty) {
          row.selectedProduct.value = _findByName(productName);
        }

        // ✅ Saari details DB se directly load karo
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
  }

  bool _isCostCalculated(ProductRowData row) {
    final usedVal = double.tryParse(row.used) ?? 0.0;
    return usedVal > 0 && row.price > 0;
  }

  void _onFieldChanged(int index) {
    if (index >= productRows.length) return;
    final row = productRows[index];
    // productName set hona chahiye — selectedProduct null ho tab bhi chale
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

  void _checkAndAddDistributeRow() {
    if (distributeRows.isNotEmpty &&
        (distributeRows.last.pit.isNotEmpty || distributeRows.last.volume.isNotEmpty)) {
      distributeRows.add(DistributeRowData());
    }
  }

  // ─────────────────────────────────────────────
  //  SAVE ROW
  // ─────────────────────────────────────────────
  Future<void> _saveRow(int index) async {
    if (dashboardController.isLocked.value) return;
    if (index >= productRows.length) return;
    final row = productRows[index];

    // productName — selectedProduct se lo ya row.productName se
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

          // ✅ KEY FIX: Agar selectedProduct null hai lekin productName set hai
          // toh wo naam directly text ke roop mein dikha do — "Select" mat dikha
          if (currentVal == null && row.productName.isNotEmpty) {
            // DB se aaya hua naam — sirf text dikhao, dropdown bhi rakhenge
            return DropdownButtonHideUnderline(
              child: DropdownButton<ProductModel>(
                value: null,
                // ✅ Yahan productName as hint dikhao — "Select" ki jagah
                hint: Text(
                  row.productName,
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    color: Colors.black87, // Dark color — data hai toh clearly dikhe
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

          // Normal case — selectedProduct available hai
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
      _staticCell(row.code, 80),
      _staticCell(row.sg, 70),
      _staticCell(row.unit, 70),
      _staticCell(row.price > 0 ? row.price.toStringAsFixed(2) : '', 90, right: true),

      // 6. Initial
      _editCell(
        key: ValueKey('init_${row.savedId ?? i}_${row.productName}'),
        value: row.initial, width: 75, locked: locked,
        onChange: (v) { row.initial = v; _onFieldChanged(i); _checkAndAddProductRow(); },
      ),
      // 7. Adjust
      _editCell(
        key: ValueKey('adj_${row.savedId ?? i}_${row.productName}'),
        value: row.adjust, width: 75, locked: locked,
        onChange: (v) { row.adjust = v; _onFieldChanged(i); _checkAndAddProductRow(); },
      ),
      // 8. Used
      _editCell(
        key: ValueKey('used_${row.savedId ?? i}_${row.productName}'),
        value: row.used, width: 75, locked: locked,
        onChange: (v) { row.used = v; _onFieldChanged(i); _checkAndAddProductRow(); },
      ),

      // 9. Final — reactive
      DataCell(Container(
        width: 75, padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Obx(() {
          final fv = row.calculatedFinal.value;
          return Text(
            row.productName.isNotEmpty ? fv.toStringAsFixed(2) : '',
            textAlign: TextAlign.right,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: fv < 0 ? Colors.red : Colors.grey.shade700,
            ),
          );
        }),
      )),

      // 10. Cost — reactive
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

      // 11. Vol — reactive
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

  DataCell _staticCell(String text, double width, {bool right = false}) {
    return DataCell(Container(
      width: width, padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodySmall.copyWith(fontSize: 10)),
    ));
  }

  DataCell _editCell({
    required Key key, required String value, required double width,
    required Function(String) onChange, bool locked = false,
  }) {
    return DataCell(Container(
      key: key, width: width, padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextFormField(
        initialValue: value, enabled: !locked,
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
    ));
  }

  // ── Bottom Section ────────────────────────────────────────────────────────
  Widget _buildBottomSection() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 280, child: _buildDistributeTable()),
      const SizedBox(width: 12),
      Expanded(child: _buildRightControls()),
    ]);
  }

  Widget _buildDistributeTable() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.successColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Row(children: [
            const Icon(Icons.share, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text("Distribute to", style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600, fontSize: 11, color: Colors.white)),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          child: Obx(() {
            final pitList = pitController.pits
                .where((p) => p.id != null && p.pitName.isNotEmpty)
                .toList();

            return DataTable(
              headingRowHeight: 32, dataRowHeight: 32,
              columnSpacing: 0, horizontalMargin: 0, dividerThickness: 0,
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
              border: TableBorder(
                verticalInside: BorderSide(color: Colors.grey.shade300),
                horizontalInside: BorderSide(color: Colors.grey.shade200),
              ),
              headingTextStyle: AppTheme.bodySmall.copyWith(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.successColor),
              columns: [
                DataColumn(label: Container(width: 150,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Text("Pit"))),
                DataColumn(label: Container(width: 100,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Text("Vol (bbl)"))),
              ],
              rows: List.generate(distributeRows.length, (i) {
                final dr = distributeRows[i];
                return DataRow(
                  color: MaterialStateProperty.all(
                      i % 2 == 0 ? Colors.white : Colors.grey.shade50),
                  cells: [
                    DataCell(Container(
                      width: 150, padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: dr.pit.isNotEmpty &&
                              pitList.any((p) => p.pitName == dr.pit)
                              ? dr.pit : null,
                          hint: Text("Select Pit",
                              style: AppTheme.bodySmall.copyWith(fontSize: 10, color: Colors.grey)),
                          isExpanded: true, isDense: true,
                          icon: const SizedBox.shrink(), menuMaxHeight: 250,
                          items: pitList.map((p) => DropdownMenuItem(value: p.pitName,
                            child: Text(p.pitName,
                                style: AppTheme.bodySmall.copyWith(fontSize: 10),
                                overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: dashboardController.isLocked.value
                              ? null : (v) {
                            if (v == null) return;
                            dr.pit = v;
                            distributeRows.refresh();
                            _checkAndAddDistributeRow();
                          },
                        ),
                      ),
                    )),
                    DataCell(Container(
                      width: 100, padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextFormField(
                        initialValue: dr.volume,
                        enabled: !dashboardController.isLocked.value,
                        style: AppTheme.bodySmall.copyWith(fontSize: 10),
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            border: InputBorder.none),
                        onChanged: (v) { dr.volume = v; _checkAndAddDistributeRow(); },
                      ),
                    )),
                  ],
                );
              }),
            );
          }),
        )),
      ]),
    );
  }

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
              "Products distributed evenly if multiple pits selected",
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

  // ✅ DB se aaya hua product name — selectedProduct null ho tab bhi kaam karta hai
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
  String pit    = '';
  String volume = '';
}