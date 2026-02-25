import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/recieve_product_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

// ─────────────────────────────────────────────
//  Row Data Models
// ─────────────────────────────────────────────
class ReceiveProductRow {
  String? savedId; // null = naya unsaved row
  String selectedItem = '';
  String code = '';
  String unit = '';
  String amount = '';
  bool isSaving = false;
  bool isDeleting = false;
}

class ReceivePackageRow {
  String? savedId;
  String selectedItem = '';
  String code = '';
  String unit = '';
  String amount = '';
  bool isSaving = false;
  bool isDeleting = false;
}

// ─────────────────────────────────────────────
//  View
// ─────────────────────────────────────────────
class ReceiveProductView extends StatefulWidget {
  const ReceiveProductView({super.key});

  @override
  State<ReceiveProductView> createState() => _ReceiveProductViewState();
}

class _ReceiveProductViewState extends State<ReceiveProductView> {
  final DashboardController dashboardController =
      Get.find<DashboardController>();
  final ReceiveProductController _controller = ReceiveProductController();

  late final InventoryProductsStore _inventoryStore;

  final RxList<PackageItem> packages = <PackageItem>[].obs;
  RxList<ProductModel> get products => _inventoryStore.selectedProducts;

  final RxList<ReceiveProductRow> productRows = <ReceiveProductRow>[].obs;
  final RxList<ReceivePackageRow> packageRows = <ReceivePackageRow>[].obs;

  final TextEditingController bolController = TextEditingController();
  final RxString alertMessage = ''.obs;
  final RxBool alertIsError = false.obs;
  final RxBool isLoadingProducts = false.obs;
  final RxBool isLoadingPackages = false.obs;

  // amount field controllers — indexed by row index
  final Map<String, TextEditingController> _amountControllers = {};

  @override
  void initState() {
    super.initState();
    _inventoryStore = Get.find<InventoryProductsStore>();
    _loadAll();
  }

  // ─────────────────────────────────────────────
  //  LOAD
  // ─────────────────────────────────────────────
  Future<void> _loadAll() async {
    // Dispose old controllers before reload
    _disposeAmountControllers();
    await Future.wait([
      _loadSavedProducts(),
      _loadSavedPackages(),
      _loadPackageDropdown(),
    ]);
  }

  Future<void> _loadPackageDropdown() async {
    try {
      const wellId = '507f1f77bcf86cd799439011';
      final list = await InventoryProductsService.fetchPackages(wellId);
      packages.value = list;
    } catch (e) {
      print('Error loading package dropdown: $e');
    }
  }

  Future<void> _loadSavedProducts() async {
    isLoadingProducts.value = true;
    try {
      final data = await _controller.getReceiveProducts();
      productRows.clear();
      for (final item in data) {
        final row = ReceiveProductRow();
        row.savedId = item['_id']?.toString();
        row.selectedItem = item['productName']?.toString() ?? '';
        row.code = item['code']?.toString() ?? '';
        row.unit = item['unit']?.toString() ?? '';
        row.amount = item['amount']?.toString() ?? '';
        productRows.add(row);
      }
      _ensureEmptyProductRow();
    } catch (e) {
      print('Error loading saved products: $e');
      productRows.add(ReceiveProductRow());
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> _loadSavedPackages() async {
    isLoadingPackages.value = true;
    try {
      final data = await _controller.getReceivePackages();
      packageRows.clear();
      for (final item in data) {
        final row = ReceivePackageRow();
        row.savedId = item['_id']?.toString();
        row.selectedItem = item['packageName']?.toString() ?? '';
        row.code = item['code']?.toString() ?? '';
        row.unit = item['unit']?.toString() ?? '';
        row.amount = item['amount']?.toString() ?? '';
        packageRows.add(row);
      }
      _ensureEmptyPackageRow();
    } catch (e) {
      print('Error loading saved packages: $e');
      packageRows.add(ReceivePackageRow());
    } finally {
      isLoadingPackages.value = false;
    }
  }

  // ─────────────────────────────────────────────
  //  PRODUCT CRUD
  // ─────────────────────────────────────────────
  Future<void> _saveProductRow(int index) async {
    if (dashboardController.isLocked.value) return;
    if (index >= productRows.length) return;
    final row = productRows[index];

    // Amount controller se latest value lo
    final amtCtrl = _amountControllers['p_$index'];
    if (amtCtrl != null) row.amount = amtCtrl.text;

    if (row.selectedItem.isEmpty || row.amount.isEmpty) {
      _showAlert('Product aur Amount dono required hain', isError: true);
      return;
    }

    productRows[index].isSaving = true;
    productRows.refresh();

    try {
      if (row.savedId == null) {
        // CREATE — naya row
        final result = await _controller.createReceiveProduct(
          productName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
          productRows[index].savedId =
              result['data']?['_id']?.toString();
          _showAlert('Product saved ✓');
          _ensureEmptyProductRow();
        } else {
          _showAlert(result['message'] ?? 'Save failed', isError: true);
        }
      } else {
        // UPDATE — existing row
        final result = await _controller.updateReceiveProduct(
          id: row.savedId!,
          productName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
          _showAlert('Product updated ✓');
        } else {
          _showAlert(result['message'] ?? 'Update failed', isError: true);
        }
      }
    } catch (e) {
      _showAlert('Error: $e', isError: true);
    } finally {
      if (index < productRows.length) {
        productRows[index].isSaving = false;
        productRows.refresh();
      }
    }
  }

  Future<void> _deleteProductRow(int index) async {
    if (dashboardController.isLocked.value) return;
    if (index >= productRows.length) return;
    final row = productRows[index];

    // Unsaved row — sirf UI se hata do
    if (row.savedId == null) {
      _amountControllers.remove('p_$index')?.dispose();
      if (productRows.length > 1) {
        productRows.removeAt(index);
      } else {
        productRows[index] = ReceiveProductRow();
      }
      productRows.refresh();
      return;
    }

    productRows[index].isDeleting = true;
    productRows.refresh();

    try {
      final result = await _controller.deleteReceiveProduct(row.savedId!);
      if (result['success'] == true) {
        _amountControllers.remove('p_$index')?.dispose();
        productRows.removeAt(index);
        _ensureEmptyProductRow();
        _showAlert('Product deleted');
      } else {
        _showAlert(result['message'] ?? 'Delete failed', isError: true);
        if (index < productRows.length) {
          productRows[index].isDeleting = false;
          productRows.refresh();
        }
      }
    } catch (e) {
      _showAlert('Error: $e', isError: true);
      if (index < productRows.length) {
        productRows[index].isDeleting = false;
        productRows.refresh();
      }
    }
  }

  void _ensureEmptyProductRow() {
    if (productRows.isEmpty || productRows.last.selectedItem.isNotEmpty) {
      productRows.add(ReceiveProductRow());
    }
    productRows.refresh();
  }

  // ─────────────────────────────────────────────
  //  PACKAGE CRUD
  // ─────────────────────────────────────────────
  Future<void> _savePackageRow(int index) async {
    if (dashboardController.isLocked.value) return;
    if (index >= packageRows.length) return;
    final row = packageRows[index];

    final amtCtrl = _amountControllers['pkg_$index'];
    if (amtCtrl != null) row.amount = amtCtrl.text;

    if (row.selectedItem.isEmpty || row.amount.isEmpty) {
      _showAlert('Package aur Amount dono required hain', isError: true);
      return;
    }

    packageRows[index].isSaving = true;
    packageRows.refresh();

    try {
      if (row.savedId == null) {
        final result = await _controller.createReceivePackage(
          packageName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
          packageRows[index].savedId =
              result['data']?['_id']?.toString();
          _showAlert('Package saved ✓');
          _ensureEmptyPackageRow();
        } else {
          _showAlert(result['message'] ?? 'Save failed', isError: true);
        }
      } else {
        final result = await _controller.updateReceivePackage(
          id: row.savedId!,
          packageName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
          _showAlert('Package updated ✓');
        } else {
          _showAlert(result['message'] ?? 'Update failed', isError: true);
        }
      }
    } catch (e) {
      _showAlert('Error: $e', isError: true);
    } finally {
      if (index < packageRows.length) {
        packageRows[index].isSaving = false;
        packageRows.refresh();
      }
    }
  }

  Future<void> _deletePackageRow(int index) async {
    if (dashboardController.isLocked.value) return;
    if (index >= packageRows.length) return;
    final row = packageRows[index];

    if (row.savedId == null) {
      _amountControllers.remove('pkg_$index')?.dispose();
      if (packageRows.length > 1) {
        packageRows.removeAt(index);
      } else {
        packageRows[index] = ReceivePackageRow();
      }
      packageRows.refresh();
      return;
    }

    packageRows[index].isDeleting = true;
    packageRows.refresh();

    try {
      final result = await _controller.deleteReceivePackage(row.savedId!);
      if (result['success'] == true) {
        _amountControllers.remove('pkg_$index')?.dispose();
        packageRows.removeAt(index);
        _ensureEmptyPackageRow();
        _showAlert('Package deleted');
      } else {
        _showAlert(result['message'] ?? 'Delete failed', isError: true);
        if (index < packageRows.length) {
          packageRows[index].isDeleting = false;
          packageRows.refresh();
        }
      }
    } catch (e) {
      _showAlert('Error: $e', isError: true);
      if (index < packageRows.length) {
        packageRows[index].isDeleting = false;
        packageRows.refresh();
      }
    }
  }

  void _ensureEmptyPackageRow() {
    if (packageRows.isEmpty || packageRows.last.selectedItem.isNotEmpty) {
      packageRows.add(ReceivePackageRow());
    }
    packageRows.refresh();
  }

  void _showAlert(String message, {bool isError = false}) {
    alertMessage.value = message;
    alertIsError.value = isError;
    Future.delayed(const Duration(seconds: 3), () => alertMessage.value = '');
  }

  void _disposeAmountControllers() {
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    _amountControllers.clear();
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductTable(),
                        const SizedBox(height: 16),
                        _buildPackageTable(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildAlert(),
      ],
    );
  }

  // ─── Top Bar ──────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Text("BOL No.",
              style: AppTheme.bodySmall
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: bolController,
                enabled: !dashboardController.isLocked.value,
                style: AppTheme.bodySmall.copyWith(fontSize: 11),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: InputBorder.none,
                  hintText: "Enter BOL number...",
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Refresh button
          Obx(() => (isLoadingProducts.value || isLoadingPackages.value)
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                      child:
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))))
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  color: AppTheme.primaryColor,
                  tooltip: 'Refresh',
                  onPressed: _loadAll,
                )),
        ],
      ),
    );
  }

  // ─── Product Table ────────────────────────────
  Widget _buildProductTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Receive Products', Icons.inventory_2_outlined, AppTheme.primaryColor,
              isLoading: isLoadingProducts),
          _buildColHeaders(
              ['No', 'Product', 'Code', 'Unit', 'Amount', 'Actions'],
              AppTheme.primaryColor),
          Obx(() => Column(
                children: List.generate(productRows.length,
                    (i) => _buildProductRow(productRows[i], i)),
              )),
        ],
      ),
    );
  }

  Widget _buildProductRow(ReceiveProductRow row, int index) {
    final locked = dashboardController.isLocked.value;

    // Amount controller — reuse if exists, create if new
    final amtKey = 'p_$index';
    if (!_amountControllers.containsKey(amtKey)) {
      _amountControllers[amtKey] = TextEditingController(text: row.amount);
    } else if (_amountControllers[amtKey]!.text != row.amount &&
        !_amountControllers[amtKey]!.selection.isValid) {
      _amountControllers[amtKey]!.text = row.amount;
    }
    final amtCtrl = _amountControllers[amtKey]!;

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Row(
        children: [
          // No.
          _cell(50,
              Text('${index + 1}',
                  style: AppTheme.bodySmall.copyWith(fontSize: 10)),
              center: true),

          // Product Dropdown
          Container(
            width: 280,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
                border: Border(
                    right:
                        BorderSide(color: Colors.grey.shade300, width: 0.5))),
            child: Obx(() {
              final storeProducts = _inventoryStore.selectedProducts;
              final matched = storeProducts
                  .firstWhereOrNull((p) => p.product == row.selectedItem);
              return DropdownButtonHideUnderline(
                child: DropdownButton<ProductModel>(
                  value: matched,
                  hint: row.selectedItem.isNotEmpty
                      ? Text(row.selectedItem,
                          style: AppTheme.bodySmall
                              .copyWith(fontSize: 10, color: Colors.black87),
                          overflow: TextOverflow.ellipsis)
                      : Text('Select Product',
                          style: AppTheme.bodySmall.copyWith(
                              fontSize: 10, color: Colors.grey.shade400)),
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 14),
                  menuMaxHeight: 280,
                  items: storeProducts
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.product,
                                style:
                                    AppTheme.bodySmall.copyWith(fontSize: 10),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: locked
                      ? null
                      : (ProductModel? val) {
                          if (val == null) return;
                          productRows[index].selectedItem = val.product;
                          productRows[index].code = val.code;
                          productRows[index].unit = val.formattedUnit;
                          productRows.refresh();
                          _ensureEmptyProductRow();
                        },
                ),
              );
            }),
          ),

          // Code
          _cell(
              110,
              Text(row.code,
                  style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis)),

          // Unit
          _cell(
              110,
              Text(row.unit,
                  style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis)),

          // Amount — editable field, Enter dabo to auto-save
          _cell(
              110,
              TextField(
                controller: amtCtrl,
                enabled: !locked,
                style: AppTheme.bodySmall.copyWith(fontSize: 10),
                textAlign: TextAlign.right,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  productRows[index].amount = val;
                },
                // Enter press hone par auto-save
                onSubmitted: (_) => _saveProductRow(index),
              ),
              noBorder: true),

          // Actions — Save + Delete
          _buildActionButtons(
            isSaving: row.isSaving,
            isDeleting: row.isDeleting,
            color: AppTheme.primaryColor,
            onSave: () => _saveProductRow(index),
            onDelete: () => _deleteProductRow(index),
            locked: locked,
          ),
        ],
      ),
    );
  }

  // ─── Package Table ────────────────────────────
  Widget _buildPackageTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Receive Packages', Icons.inventory_outlined, AppTheme.successColor,
              isLoading: isLoadingPackages),
          _buildColHeaders(
              ['No', 'Package', 'Code', 'Unit', 'Amount', 'Actions'],
              AppTheme.successColor),
          Obx(() => Column(
                children: List.generate(packageRows.length,
                    (i) => _buildPackageRow(packageRows[i], i)),
              )),
        ],
      ),
    );
  }

  Widget _buildPackageRow(ReceivePackageRow row, int index) {
    final locked = dashboardController.isLocked.value;

    final amtKey = 'pkg_$index';
    if (!_amountControllers.containsKey(amtKey)) {
      _amountControllers[amtKey] = TextEditingController(text: row.amount);
    } else if (_amountControllers[amtKey]!.text != row.amount &&
        !_amountControllers[amtKey]!.selection.isValid) {
      _amountControllers[amtKey]!.text = row.amount;
    }
    final amtCtrl = _amountControllers[amtKey]!;

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Row(
        children: [
          _cell(50,
              Text('${index + 1}',
                  style: AppTheme.bodySmall.copyWith(fontSize: 10)),
              center: true),

          // Package Dropdown
          Container(
            width: 280,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
                border: Border(
                    right:
                        BorderSide(color: Colors.grey.shade300, width: 0.5))),
            child: Obx(() {
              final matched =
                  packages.firstWhereOrNull((p) => p.name == row.selectedItem);
              return DropdownButtonHideUnderline(
                child: DropdownButton<PackageItem>(
                  value: matched,
                  hint: row.selectedItem.isNotEmpty
                      ? Text(row.selectedItem,
                          style: AppTheme.bodySmall
                              .copyWith(fontSize: 10, color: Colors.black87),
                          overflow: TextOverflow.ellipsis)
                      : Text('Select Package',
                          style: AppTheme.bodySmall.copyWith(
                              fontSize: 10, color: Colors.grey.shade400)),
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 14),
                  menuMaxHeight: 280,
                  items: packages
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name,
                                style:
                                    AppTheme.bodySmall.copyWith(fontSize: 10),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: locked
                      ? null
                      : (PackageItem? val) {
                          if (val == null) return;
                          packageRows[index].selectedItem = val.name;
                          packageRows[index].code = val.code;
                          packageRows[index].unit = val.unit;
                          packageRows.refresh();
                          _ensureEmptyPackageRow();
                        },
                ),
              );
            }),
          ),

          _cell(
              110,
              Text(row.code,
                  style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis)),
          _cell(
              110,
              Text(row.unit,
                  style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis)),

          _cell(
              110,
              TextField(
                controller: amtCtrl,
                enabled: !locked,
                style: AppTheme.bodySmall.copyWith(fontSize: 10),
                textAlign: TextAlign.right,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  packageRows[index].amount = val;
                },
                onSubmitted: (_) => _savePackageRow(index),
              ),
              noBorder: true),

          _buildActionButtons(
            isSaving: row.isSaving,
            isDeleting: row.isDeleting,
            color: AppTheme.successColor,
            onSave: () => _savePackageRow(index),
            onDelete: () => _deletePackageRow(index),
            locked: locked,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SHARED WIDGETS
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, Color color,
      {required RxBool isLoading}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600, fontSize: 11, color: color)),
          const Spacer(),
          Obx(() => isLoading.value
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color))
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildColHeaders(List<String> headers, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: headers.map((h) {
          return Container(
            width: _colWidth(h),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(
                        color: Colors.grey.shade300, width: 0.5))),
            alignment:
                h == 'Amount' ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(h,
                style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons({
    required bool isSaving,
    required bool isDeleting,
    required Color color,
    required VoidCallback onSave,
    required VoidCallback onDelete,
    required bool locked,
  }) {
    return SizedBox(
      width: 90,
      height: 36,
      child: isSaving || isDeleting
          ? Center(
              child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDeleting ? Colors.red.shade400 : color)))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Save / Update button
                Tooltip(
                  message: 'Save / Update',
                  child: InkWell(
                    onTap: locked ? null : onSave,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.save_outlined,
                          size: 16,
                          color:
                              locked ? Colors.grey.shade300 : color),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Delete button
                Tooltip(
                  message: 'Delete',
                  child: InkWell(
                    onTap: locked ? null : onDelete,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline,
                          size: 16,
                          color: locked
                              ? Colors.grey.shade300
                              : Colors.red.shade400),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _cell(double width, Widget child,
      {bool center = false, bool noBorder = false}) {
    return Container(
      width: width,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: noBorder
          ? null
          : BoxDecoration(
              border: Border(
                  right: BorderSide(
                      color: Colors.grey.shade300, width: 0.5))),
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: child,
    );
  }

  double _colWidth(String h) {
    switch (h) {
      case 'No':
        return 50;
      case 'Product':
      case 'Package':
        return 280;
      case 'Code':
      case 'Unit':
      case 'Amount':
        return 110;
      case 'Actions':
        return 90;
      default:
        return 100;
    }
  }

  Widget _buildAlert() {
    return Positioned(
      top: 16,
      right: 16,
      child: Obx(() {
        if (alertMessage.value.isEmpty) return const SizedBox.shrink();
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: alertIsError.value
                  ? Colors.red.shade600
                  : AppTheme.successColor,
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: const BoxConstraints(maxWidth: 300),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    alertIsError.value
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(alertMessage.value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    bolController.dispose();
    _disposeAmountControllers();
    super.dispose();
  }
}