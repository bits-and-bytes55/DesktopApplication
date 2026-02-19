import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/products_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/consume_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/model/ug_inventory_product_model.dart';
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
  final ProductsController productsController = Get.put(ProductsController());
  final PitController pitController = Get.put(PitController());
  final ConsumeProductController consumeProductController = ConsumeProductController();
  final InventorySnapshotController inventorySnapshotController = InventorySnapshotController();
  
  final RxString selectedMethod = "Used".obs;
  final RxBool addWater = false.obs;
  final TextEditingController waterVolumeController = TextEditingController();
  final TextEditingController totalVolumeController = TextEditingController(text: "2.62");

  // Row data for tables
  final RxList<ProductRowData> productRows = <ProductRowData>[].obs;
  final RxList<DistributeRowData> distributeRows = <DistributeRowData>[].obs;

  // Per-row saving/deleting states
  final RxList<bool> productRowSaving = <bool>[].obs;
  final RxList<bool> productRowDeleting = <bool>[].obs;

  // Selected row indices
  final RxInt selectedProductRow = 0.obs;
  final RxInt selectedDistributeRow = 0.obs;

  // Selected products for top dropdown
  final Rx<ProductModel?> selectedTopProduct = Rx<ProductModel?>(null);

  // Local list for inventory products
  final RxList<ProductModel> products = <ProductModel>[].obs;

  // Save All loading
  final RxBool isSavingAll = false.obs;

  @override
  void initState() {
    super.initState();
    print('🟡 [INIT] ConsumeProductView initState');
    // Fetch dropdown data from inventory
    _loadDropdownData();
    // Fetch pits data
    pitController.fetchAllPits();
    // Fetch saved consume products
    _fetchAllConsumeProducts();
    // Initialize distribute rows
    for (int i = 0; i < 5; i++) {
      distributeRows.add(DistributeRowData());
    }
  }

  // ─────────────────────────────────────────────
  //  Load dropdown data (Well-specific Inventory)
  // ─────────────────────────────────────────────
  Future<void> _loadDropdownData() async {
    print('🔵 [LOAD] Loading dropdown products...');
    try {
      const wellId = '507f1f77bcf86cd799439011';
      final inventoryProducts = await InventoryProductsService.fetchProducts(wellId);
      print('🟢 [LOAD] Fetched ${inventoryProducts.length} products from inventory');

      products.value = inventoryProducts.map((p) => ProductModel(
        id: p.id,
        product: p.product,
        code: p.code,
        sg: p.sg,
        unitClass: p.unit,
        price: p.price,
        initial: p.initial,
        group: p.group,
        volAdd: p.volAdd,
        calculate: p.calculate,
        plot: p.plot ?? false,
        tax: p.tax,
      )).toList();
    } catch (e) {
      print('🔴 [LOAD] Error loading dropdown data: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  Fetch all saved consume products from backend
  // ─────────────────────────────────────────────
  Future<void> _fetchAllConsumeProducts() async {
    print('🔵 [FETCH] Fetching saved consume products...');
    try {
      final data = await consumeProductController.getAllConsumeProducts();
      print('🟢 [FETCH] ConsumeProducts: ${data.length} items');

      productRows.clear();
      productRowSaving.clear();
      productRowDeleting.clear();

      for (var item in data) {
        final row = ProductRowData();
        
        // Match product by ID
        final productId = item['product']?.toString();
        if (productId != null && productId.isNotEmpty) {
          row.selectedProduct.value = _findProductById(productId);
        }

        row.code      = item['code']?.toString() ?? '';
        row.sg        = item['sg']?.toString() ?? '';
        row.unit      = item['unit']?.toString() ?? '';
        row.price     = (item['price'] ?? 0).toDouble();
        row.initial   = (item['initial'] ?? 0).toString();
        row.adjust    = (item['adjust'] ?? 0).toString();
        row.used      = (item['used'] ?? 0).toString();
        row.final_    = (item['final'] ?? 0).toString();
        row.savedId   = item['_id'];
        
        // Recalculate to update reactive values
        row.recalculate();

        productRows.add(row);
        productRowSaving.add(false);
        productRowDeleting.add(false);
      }

      // Add one empty row at end
      productRows.add(ProductRowData());
      productRowSaving.add(false);
      productRowDeleting.add(false);

      print('🟢 [FETCH] All products loaded');
    } catch (e) {
      print('🔴 [FETCH] Error fetching products: $e');
    }
  }

  ProductModel? _findProductById(String id) {
    return products.firstWhereOrNull((p) => p.id == id);
  }

  // ─────────────────────────────────────────────
  //  Calculate row (just updates reactive values)
  // ─────────────────────────────────────────────
  void _calculateRow(int index) {
    if (dashboardController.isLocked.value) return;
    final row = productRows[index];
    if (row.selectedProduct.value == null) {
      print('🔴 [CALC] Row $index: no product selected');
      return;
    }

    print('🔵 [CALC] Row $index → Calculating...');
    row.recalculate();
    productRows.refresh();
  }

  // ─────────────────────────────────────────────
  //  Save row (inline save)
  // ─────────────────────────────────────────────
  Future<void> _saveRow(int index) async {
    if (dashboardController.isLocked.value) return;
    final row = productRows[index];
    
    if (row.selectedProduct.value == null) {
      print('🔴 [SAVE] Row $index: no product selected');
      return;
    }

    // Calculate first
    _calculateRow(index);

    productRowSaving[index] = true;
    productRowSaving.refresh();

    final productId = row.selectedProduct.value!.id ?? '';
    final initial   = double.tryParse(row.initial) ?? 0.0;
    final adjust    = double.tryParse(row.adjust) ?? 0.0;
    final used      = double.tryParse(row.used) ?? 0.0;

    print('🔵 [SAVE] Row $index → productId=$productId | initial=$initial | adjust=$adjust | used=$used');

    try {
      Map<String, dynamic> result;

      if (row.savedId == null) {
        // CREATE
        result = await consumeProductController.createConsumeProduct(
          productId:     productId,
          code:          row.code,
          sg:            double.tryParse(row.sg) ?? 0.0,
          unit:          row.unit,
          price:         row.price,
          initial:       initial,
          adjust:        adjust,
          used:          used,
          numberOfBags:  1.0,  // Placeholder
          weightPerBag:  1.0,  // Placeholder
        );
      } else {
        // UPDATE
        result = await consumeProductController.updateConsumeProduct(
          id:            row.savedId!,
          productId:     productId,
          code:          row.code,
          sg:            double.tryParse(row.sg) ?? 0.0,
          unit:          row.unit,
          price:         row.price,
          initial:       initial,
          adjust:        adjust,
          used:          used,
          numberOfBags:  1.0,
          weightPerBag:  1.0,
        );
      }

      print('🟢 [SAVE] Row $index result: $result');

      if (result['success'] == true) {
        row.savedId = result['data']?['_id'] ?? row.savedId;
        productRows.refresh();
        _showSuccess('Product row ${index + 1} saved!');
        await _fetchAllConsumeProducts();
      } else {
        _showError(result['message'] ?? 'Save failed');
      }
    } catch (e) {
      print('🔴 [SAVE] Row $index exception: $e');
      _showError('Error: $e');
    } finally {
      productRowSaving[index] = false;
      productRowSaving.refresh();
    }
  }

  // ─────────────────────────────────────────────
  //  Delete row (inline delete)
  // ─────────────────────────────────────────────
  Future<void> _deleteRow(int index) async {
    final row = productRows[index];
    print('🔵 [DEL] Row $index | savedId=${row.savedId}');

    if (row.savedId != null) {
      productRowDeleting[index] = true;
      productRowDeleting.refresh();
      try {
        final result = await consumeProductController.deleteConsumeProduct(row.savedId!);
        print('🟢 [DEL] Row $index result: $result');
        if (result['success'] != true) {
          _showError(result['message'] ?? 'Delete failed');
          productRowDeleting[index] = false;
          productRowDeleting.refresh();
          return;
        }
        await _fetchAllConsumeProducts();
        _showSuccess('Product deleted');
      } catch (e) {
        print('🔴 [DEL] Row $index exception: $e');
        _showError('Error: $e');
      } finally {
        productRowDeleting[index] = false;
        productRowDeleting.refresh();
      }
    } else {
      // Just reset unsaved row
      productRows[index] = ProductRowData();
      productRows.refresh();
    }
  }

  // ─────────────────────────────────────────────
  //  Save All → generateInventorySnapshot
  // ─────────────────────────────────────────────
  Future<void> _saveAll() async {
    if (dashboardController.isLocked.value) return;
    isSavingAll.value = true;

    print('🟡 [SAVE-ALL] Save All button pressed');

    try {
      // Save all unsaved filled rows
      print('🔵 [SAVE-ALL] Saving all product rows...');
      for (int i = 0; i < productRows.length; i++) {
        if (productRows[i].selectedProduct.value != null && productRows[i].savedId == null) {
          await _saveRow(i);
        }
      }

      // Generate inventory snapshot
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
      isSavingAll.value = false;
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
              // Top Controls
              _buildTopControls(),
              const SizedBox(height: 10),

              // Main Product Table
              _buildProductTable(),
              const SizedBox(height: 10),

              // Bottom Section: Distribute Table + Right Controls
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
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Select Products Dropdown
          Expanded(
            flex: 2,
            child: _buildProductDropdown(),
          ),
          const SizedBox(width: 10),

          // Load Previous Products
          Expanded(
            flex: 2,
            child: _buildDropdown(
              hint: "Load Previous Products",
              icon: Icons.history,
            ),
          ),
          const SizedBox(width: 12),

          // Radio Buttons
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
                _buildCompactRadio("Used", "Used"),
                const SizedBox(width: 6),
                _buildCompactRadio("Final", "Final"),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Save All Button
          Obx(() => ElevatedButton.icon(
            onPressed: dashboardController.isLocked.value || isSavingAll.value
                ? null
                : _saveAll,
            icon: isSavingAll.value
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                : const Icon(Icons.save, size: 14),
            label: Text(
              isSavingAll.value ? 'Saving...' : 'Save All',
              style: const TextStyle(fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(90, 32),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildProductDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Obx(() => DropdownButtonHideUnderline(
              child: DropdownButton<ProductModel>(
                value: selectedTopProduct.value != null &&
                       products.any((p) => p.id == selectedTopProduct.value?.id)
                    ? selectedTopProduct.value
                    : null,
                hint: Text(
                  "Select Products",
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                icon: const Icon(Icons.arrow_drop_down, size: 16),
                isExpanded: true,
                isDense: true,
                menuMaxHeight: 300,
                items: products.where((p) => p.id != null).map((product) {
                  return DropdownMenuItem<ProductModel>(
                    value: product,
                    child: Text(
                      product.product,
                      style: AppTheme.bodySmall.copyWith(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: dashboardController.isLocked.value 
                    ? null 
                    : (ProductModel? value) {
                        selectedTopProduct.value = value;
                      },
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String hint, required IconData icon}) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: Text(
                  hint,
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                icon: const Icon(Icons.arrow_drop_down, size: 16),
                items: const [],
                onChanged: dashboardController.isLocked.value ? null : (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRadio(String label, String value) {
    return Obx(() => InkWell(
      onTap: dashboardController.isLocked.value 
          ? null 
          : () => selectedMethod.value = value,
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
              label,
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
    ));
  }

  Widget _buildProductTable() {
    final headers = [
      "Product",
      "Code",
      "SG",
      "Unit",
      "Price (\$)",
      "Initial",
      "Adjust",
      "Used",
      "Final",
      "Cost (\$)",
      "Vol (bbl)",
      "",  // Action buttons column
      "",  // Delete column
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Consume Product",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Table with fixed height and scrollable content
          SizedBox(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Obx(() => Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: DataTable(
                    headingRowHeight: 32,
                    dataRowHeight: 32,
                    columnSpacing: 0,
                    horizontalMargin: 0,
                    dividerThickness: 0,
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                    border: TableBorder(
                      verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
                      horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    headingTextStyle: AppTheme.bodySmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                    dataTextStyle: AppTheme.bodySmall.copyWith(fontSize: 10),
                    columns: headers.map((h) => DataColumn(
                      label: Container(
                        width: _getProductColumnWidth(h),
                        alignment: h.contains('Price') || h.contains('Cost') || h.contains('Initial') || 
                                   h.contains('Adjust') || h.contains('Used') || h.contains('Final') || h.contains('Vol')
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(h),
                      ),
                    )).toList(),
                    rows: List.generate(productRows.length, (index) {
                      final row = productRows[index];
                      final isSelected = selectedProductRow.value == index;
                      
                      return DataRow(
                        color: MaterialStateProperty.all(
                          index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        ),
                        cells: _buildProductCells(row, index, isSelected),
                      );
                    }),
                  ),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getProductColumnWidth(String header) {
    if (header == 'Product') return 150;
    if (header == 'Code') return 80;
    if (header == 'SG' || header == 'Unit') return 70;
    if (header.contains('Price') || header.contains('Cost')) return 85;
    if (header == '') return 32;  // Action/Delete column
    return 75;
  }

  List<DataCell> _buildProductCells(ProductRowData row, int index, bool isSelected) {
    List<DataCell> cells = [];

    // Product Dropdown with icon
    cells.add(DataCell(
      GestureDetector(
        onTap: () => selectedProductRow.value = index,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (isSelected)
                Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.primaryColor),
              if (isSelected)
                const SizedBox(width: 4),
              
              Expanded(
                child: Obx(() => DropdownButtonHideUnderline(
                  child: DropdownButton<ProductModel>(
                    value: row.selectedProduct.value != null &&
                           products.any((p) => p.id == row.selectedProduct.value?.id)
                        ? row.selectedProduct.value
                        : null,
                    hint: Text(
                      "Select",
                      style: AppTheme.bodySmall.copyWith(fontSize: 10, color: Colors.grey),
                    ),
                    isExpanded: true,
                    isDense: true,
                    icon: const SizedBox.shrink(),
                    menuMaxHeight: 300,
                    items: products.where((p) => p.id != null).map((product) {
                      return DropdownMenuItem<ProductModel>(
                        value: product,
                        child: Text(
                          product.product,
                          style: AppTheme.bodySmall.copyWith(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: dashboardController.isLocked.value 
                        ? null 
                        : (ProductModel? value) {
                            if (value != null) {
                              selectedProductRow.value = index;
                              row.selectedProduct.value = value;
                              row.code = value.code;
                              row.sg = value.sg;
                              row.unit = value.unitClass;
                              row.price = value.a.isNotEmpty 
                                  ? double.tryParse(value.a) ?? 0.0 
                                  : 0.0;
                              row.initial = value.initial;
                              productRows.refresh();
                              _checkAndAddProductRow();
                              row.recalculate();
                            }
                          },
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    ));

    // Code
    cells.add(_buildTableCell(row.code, 80, isEditable: false));

    // SG
    cells.add(_buildTableCell(row.sg, 70, isEditable: false));

    // Unit
    cells.add(_buildTableCell(row.unit, 70, isEditable: false));

    // Price
    cells.add(_buildTableCell(
      row.price > 0 ? row.price.toStringAsFixed(2) : '',
      85,
      isEditable: false,
      isRightAligned: true,
    ));

    // Initial
    cells.add(_buildEditableTableCell(row.initial, (val) {
      row.initial = val;
      row.recalculate();
      _checkAndAddProductRow();
    }, 75));

    // Adjust
    cells.add(_buildEditableTableCell(row.adjust, (val) {
      row.adjust = val;
      row.recalculate();
      _checkAndAddProductRow();
    }, 75));

    // Used
    cells.add(_buildEditableTableCell(row.used, (val) {
      row.used = val;
      row.recalculate();
      _checkAndAddProductRow();
    }, 75));

    // Final (calculated, can be negative, shown in red if negative)
    cells.add(DataCell(
      Container(
        width: 75,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Obx(() => Text(
          row.calculatedFinal.value.toStringAsFixed(2),
          style: AppTheme.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: row.calculatedFinal.value < 0 
                ? Colors.red 
                : Colors.grey.shade700,
          ),
          textAlign: TextAlign.right,
        )),
      ),
    ));

    // Cost (calculated, highlighted)
    cells.add(_buildTableCell(
      row.calculatedCost.value > 0 ? row.calculatedCost.value.toStringAsFixed(2) : '',
      85,
      isEditable: false,
      isRightAligned: true,
      isBold: true,
      isHighlighted: true,
    ));

    // Vol (calculated, highlighted)
    cells.add(_buildTableCell(
      row.calculatedVolume.value > 0 ? row.calculatedVolume.value.toStringAsFixed(3) : '',
      80,
      isEditable: false,
      isRightAligned: true,
      isHighlighted: true,
    ));

    // Action buttons (calculate + save)
    cells.add(DataCell(
      _buildActionButtons(
        index: index,
        isSaving: productRowSaving[index],
        hasProduct: row.selectedProduct.value != null,
        onCalculate: () => _calculateRow(index),
        onSave: () => _saveRow(index),
      ),
    ));

    // Delete button
    cells.add(DataCell(
      _buildDeleteButton(
        index: index,
        isDeleting: productRowDeleting[index],
        onDelete: () => _deleteRow(index),
      ),
    ));

    return cells;
  }

  DataCell _buildTableCell(
    String text,
    double width, {
    bool isEditable = false,
    bool isRightAligned = false,
    bool isBold = false,
    bool isHighlighted = false,
  }) {
    return DataCell(
      Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: isHighlighted
            ? BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
              )
            : null,
        child: Text(
          text,
          style: AppTheme.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isHighlighted ? AppTheme.primaryColor : null,
          ),
          textAlign: isRightAligned ? TextAlign.right : TextAlign.left,
        ),
      ),
    );
  }

  DataCell _buildEditableTableCell(
    String value,
    Function(String) onChanged,
    double width, {
    bool isRightAligned = false,
  }) {
    return DataCell(
      Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: TextEditingController(text: value),
          enabled: !dashboardController.isLocked.value,
          style: AppTheme.bodySmall.copyWith(fontSize: 10),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            border: InputBorder.none,
          ),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          textAlign: isRightAligned ? TextAlign.right : TextAlign.left,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionButtons({
    required int index,
    required bool isSaving,
    required bool hasProduct,
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
                color: hasProduct && !dashboardController.isLocked.value
                    ? AppTheme.primaryColor
                    : Colors.grey.shade400),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: hasProduct && !dashboardController.isLocked.value
                ? onCalculate
                : null,
            tooltip: 'Calculate',
          ),
          const SizedBox(width: 4),
          // Save
          IconButton(
            icon: Icon(Icons.save_outlined,
                size: 16,
                color: hasProduct && !dashboardController.isLocked.value
                    ? const Color(0xff10B981)
                    : Colors.grey.shade400),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: hasProduct && !dashboardController.isLocked.value
                ? onSave
                : null,
            tooltip: 'Save row',
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton({
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
        onPressed: dashboardController.isLocked.value ? null : onDelete,
        tooltip: 'Delete row',
      ),
    );
  }

  void _checkAndAddProductRow() {
    if (productRows.length >= 5) {
      final lastRow = productRows.last;
      if (lastRow.selectedProduct.value != null) {
        productRows.add(ProductRowData());
        productRowSaving.add(false);
        productRowDeleting.add(false);
      }
    }
  }

  Widget _buildBottomSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Distribute Table
        SizedBox(
          width: 280,
          child: _buildDistributeTable(),
        ),
        const SizedBox(width: 12),

        // Right Controls
        Expanded(
          child: _buildRightControls(),
        ),
      ],
    );
  }

  Widget _buildDistributeTable() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.share, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Distribute to",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Obx(() => DataTable(
                headingRowHeight: 32,
                dataRowHeight: 32,
                columnSpacing: 0,
                horizontalMargin: 0,
                dividerThickness: 0,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                border: TableBorder(
                  verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
                  horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                headingTextStyle: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successColor,
                ),
                dataTextStyle: AppTheme.bodySmall.copyWith(fontSize: 10),
                columns: [
                  DataColumn(
                    label: Container(
                      width: 150,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Text("Pit"),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: 100,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Text("Vol (bbl)"),
                    ),
                  ),
                ],
                rows: List.generate(distributeRows.length, (index) {
                  final row = distributeRows[index];
                  final isSelected = selectedDistributeRow.value == index;
                  
                  return DataRow(
                    color: MaterialStateProperty.all(
                      index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                    ),
                    cells: [
                      DataCell(
                        GestureDetector(
                          onTap: () => selectedDistributeRow.value = index,
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                if (isSelected)
                                  Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.successColor),
                                if (isSelected)
                                  const SizedBox(width: 4),
                                
                                Expanded(
                                  child: Obx(() => DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: row.pit.isNotEmpty ? row.pit : null,
                                      hint: Text(
                                        "Select Pit",
                                        style: AppTheme.bodySmall.copyWith(fontSize: 10, color: Colors.grey),
                                      ),
                                      isExpanded: true,
                                      isDense: true,
                                      icon: const SizedBox.shrink(),
                                      menuMaxHeight: 250,
                                      items: pitController.pits
                                          .where((pit) => pit.id != null && pit.pitName.isNotEmpty)
                                          .map((pit) {
                                        return DropdownMenuItem<String>(
                                          value: pit.pitName,
                                          child: Text(
                                            pit.pitName,
                                            style: AppTheme.bodySmall.copyWith(fontSize: 10),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: dashboardController.isLocked.value
                                          ? null
                                          : (String? newValue) {
                                              if (newValue != null) {
                                                selectedDistributeRow.value = index;
                                                row.pit = newValue;
                                                distributeRows.refresh();
                                                _checkAndAddDistributeRow();
                                              }
                                            },
                                    ),
                                  )),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      DataCell(
                        Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextField(
                            controller: TextEditingController(text: row.volume),
                            enabled: !dashboardController.isLocked.value,
                            style: AppTheme.bodySmall.copyWith(fontSize: 10),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            onChanged: (val) {
                              row.volume = val;
                              _checkAndAddDistributeRow();
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              )),
            ),
          ),
        ],
      ),
    );
  }

  void _checkAndAddDistributeRow() {
    if (distributeRows.length >= 5) {
      final lastRow = distributeRows.last;
      if (lastRow.volume.isNotEmpty) {
        distributeRows.add(DistributeRowData());
      }
    }
  }

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
          Obx(() => Row(
            children: [
              InkWell(
                onTap: dashboardController.isLocked.value 
                    ? null 
                    : () => addWater.value = !addWater.value,
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
                            ? const Icon(Icons.check, size: 11, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Add Water",
                        style: AppTheme.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 10),
              
              if (addWater.value)
                Expanded(
                  child: _buildCompactInputField(
                    controller: waterVolumeController,
                    suffix: "bbl",
                  ),
                ),
            ],
          )),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                "Total Vol.",
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCompactInputField(
                  controller: totalVolumeController,
                  suffix: "bbl",
                ),
              ),
            ],
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: Colors.amber.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Products distributed evenly if multiple pits selected",
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 9,
                      color: Colors.amber.shade900,
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

  Widget _buildCompactInputField({
    required TextEditingController controller,
    required String suffix,
  }) {
    return Obx(() => Container(
      height: 32,
      decoration: BoxDecoration(
        color: dashboardController.isLocked.value 
            ? Colors.grey.shade50 
            : Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !dashboardController.isLocked.value,
              style: AppTheme.bodySmall.copyWith(fontSize: 10),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.number,
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
                suffix,
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

// Product Row Data Model with Calculation Logic
class ProductRowData {
  final Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);
  String code = '';
  String sg = '';
  String unit = '';
  double price = 0.0;
  String initial = '';
  String adjust = '';
  String used = '';
  String final_ = '';
  String? savedId;  // MongoDB _id after save
  
  // Reactive calculated values
  final RxDouble calculatedCost = 0.0.obs;
  final RxDouble calculatedVolume = 0.0.obs;
  final RxDouble calculatedFinal = 0.0.obs;

  // Recalculate cost, final, and volume whenever inputs change
  void recalculate() {
    final initialVal = double.tryParse(initial) ?? 0.0;
    final adjustVal  = double.tryParse(adjust) ?? 0.0;
    final usedVal    = double.tryParse(used) ?? 0.0;
    final sgVal      = double.tryParse(sg) ?? 0.0;

    // Final = initial + adjust - used (CAN BE NEGATIVE)
    calculatedFinal.value = initialVal + adjustVal - usedVal;

    // Cost = used * price
    calculatedCost.value = usedVal * price;

    // Volume in BBL (simplified formula)
    if (sgVal > 0 && usedVal > 0) {
      final totalWeight = usedVal;  // Assuming used is in kg
      calculatedVolume.value = double.parse(
        (totalWeight / (sgVal * 158.987)).toStringAsFixed(3)
      );
    } else {
      calculatedVolume.value = 0.0;
    }
  }
}

// Distribute Row Data Model
class DistributeRowData {
  String pit = '';
  String volume = '';
}