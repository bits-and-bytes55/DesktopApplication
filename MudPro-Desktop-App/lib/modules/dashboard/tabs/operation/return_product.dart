import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/return_product_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_desktop_ui.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

// ─── Row Models ───────────────────────────────────────────────
class ProductRowData {
  String? savedId;
  String selectedItem = '';
  String code = '';
  String unit = '';
  String amount = '';
  bool isSaving = false;
  bool isDeleting = false;

  final TextEditingController amountController = TextEditingController();

  void dispose() => amountController.dispose();
}

class PackageRowData {
  String? savedId;
  String selectedItem = '';
  String code = '';
  String unit = '';
  String amount = '';
  bool isSaving = false;
  bool isDeleting = false;

  final TextEditingController amountController = TextEditingController();

  void dispose() => amountController.dispose();
}

// ─── View ─────────────────────────────────────────────────────
class ReturnProductView extends StatefulWidget {
  const ReturnProductView({super.key});

  @override
  State<ReturnProductView> createState() => _ReturnProductViewState();
}

class _ReturnProductViewState extends State<ReturnProductView> {
  final DashboardController dashboardController =
      Get.find<DashboardController>();
  final ReturnProductController _apiController = ReturnProductController();
  final InventorySnapshotController _inventorySnapshotController =
      InventorySnapshotController();

  late final InventoryProductsStore _inventoryStore;

  final RxList<PackageItem> packages = <PackageItem>[].obs;
  RxList<ProductModel> get products => _inventoryStore.selectedProducts;

  final RxList<ProductRowData> productRows = <ProductRowData>[].obs;
  final RxList<PackageRowData> packageRows = <PackageRowData>[].obs;

  final RxInt selectedProductRow = 0.obs;
  final RxInt selectedPackageRow = 0.obs;

  // ✅ BOL No. field — same as ReceiveProductView
  final TextEditingController bolController = TextEditingController();

  final RxString alertMessage = ''.obs;
  final RxBool alertIsError = false.obs;
  final RxBool isSaving = false.obs;
  Timer? _inventorySnapshotRefreshTimer;
  final Map<String, Timer> _autoSaveTimers = {};
  Map<String, dynamic>? _productClipboard;
  Map<String, dynamic>? _packageClipboard;

  @override
  void initState() {
    super.initState();
    _inventoryStore = Get.find<InventoryProductsStore>();
    _loadProductsIfNeeded();
    _loadPackages();
    _loadSavedData();
  }

  // ─── Fetch saved records on load ──────────────────────────
  Future<void> _loadSavedData() async {
    try {
      final savedProducts = await _apiController.getReturnProducts();
      final savedPackages = await _apiController.getReturnPackages();

      productRows.clear();
      for (final item in savedProducts) {
        final row = ProductRowData();
        row.savedId = item['_id']?.toString();
        row.selectedItem = item['productName']?.toString() ?? '';
        row.code = item['code']?.toString() ?? '';
        row.unit = item['unit']?.toString() ?? '';
        row.amount = item['amount']?.toString() ?? '';
        row.amountController.text = row.amount;
        productRows.add(row);
      }
      productRows.add(ProductRowData());

      packageRows.clear();
      for (final item in savedPackages) {
        final row = PackageRowData();
        row.savedId = item['_id']?.toString();
        row.selectedItem = item['packageName']?.toString() ?? '';
        row.code = item['code']?.toString() ?? '';
        row.unit = item['unit']?.toString() ?? '';
        row.amount = item['amount']?.toString() ?? '';
        row.amountController.text = row.amount;
        packageRows.add(row);
      }
      packageRows.add(PackageRowData());
    } catch (e) {
      print('Error loading saved return data: $e');
      if (productRows.isEmpty) productRows.add(ProductRowData());
      if (packageRows.isEmpty) packageRows.add(PackageRowData());
    }
  }

  Future<void> _loadPackages() async {
    try {
      final wellId = currentBackendWellId;
      if (wellId.isEmpty) return;
      final inventoryPackages = await InventoryProductsService.fetchPackages(
        wellId,
      );
      packages.value = inventoryPackages;
    } catch (e) {
      print("Error loading packages: $e");
    }
  }

  Future<void> _loadProductsIfNeeded() async {
    try {
      if (_inventoryStore.selectedProducts.isNotEmpty) return;
      final wellId = currentBackendWellId.trim();
      if (wellId.isEmpty) return;
      final savedProducts = await InventoryProductsService.fetchProducts(
        wellId,
      );
      if (savedProducts.isNotEmpty) {
        _inventoryStore.setSelectedProducts(
          savedProducts.map(_toProductModel).toList(),
        );
      }
    } catch (e) {
      print("Error loading inventory products: $e");
    }
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

  void _showAlert(String message, {bool isError = false}) {
    alertMessage.value = message;
    alertIsError.value = isError;
    Future.delayed(const Duration(seconds: 3), () => alertMessage.value = '');
  }

  void _scheduleInventorySnapshotRefresh() {
    _inventorySnapshotRefreshTimer?.cancel();
    _inventorySnapshotRefreshTimer = Timer(
      const Duration(milliseconds: 900),
      () async {
        await _inventorySnapshotController.generateInventorySnapshot();
      },
    );
  }

  void _scheduleAutoSaveRow(String kind, int index) {
    if (dashboardController.isLocked.value) return;
    final key = '$kind:$index';
    _autoSaveTimers[key]?.cancel();
    _autoSaveTimers[key] = Timer(const Duration(milliseconds: 650), () {
      _autoSaveTimers.remove(key);
      if (!mounted || dashboardController.isLocked.value) return;
      if (kind == 'product') {
        _saveProductRow(index);
      } else {
        _savePackageRow(index);
      }
    });
  }

  void _cancelAutoSaves() {
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
  }

  bool _hasProductRowData(ProductRowData row) {
    return row.savedId != null ||
        row.selectedItem.trim().isNotEmpty ||
        row.code.trim().isNotEmpty ||
        row.unit.trim().isNotEmpty ||
        row.amountController.text.trim().isNotEmpty;
  }

  bool _hasPackageRowData(PackageRowData row) {
    return row.savedId != null ||
        row.selectedItem.trim().isNotEmpty ||
        row.code.trim().isNotEmpty ||
        row.unit.trim().isNotEmpty ||
        row.amountController.text.trim().isNotEmpty;
  }

  Map<String, dynamic> _productRowSnapshot(ProductRowData row) => {
    'selectedItem': row.selectedItem,
    'code': row.code,
    'unit': row.unit,
    'amount': row.amountController.text.trim(),
  };

  Map<String, dynamic> _packageRowSnapshot(PackageRowData row) => {
    'selectedItem': row.selectedItem,
    'code': row.code,
    'unit': row.unit,
    'amount': row.amountController.text.trim(),
  };

  void _applyProductRowSnapshot(
    ProductRowData row,
    Map<String, dynamic> snapshot,
  ) {
    row.savedId = null;
    row.selectedItem = (snapshot['selectedItem'] ?? '').toString();
    row.code = (snapshot['code'] ?? '').toString();
    row.unit = (snapshot['unit'] ?? '').toString();
    row.amount = (snapshot['amount'] ?? '').toString();
    row.amountController.text = row.amount;
  }

  void _applyPackageRowSnapshot(
    PackageRowData row,
    Map<String, dynamic> snapshot,
  ) {
    row.savedId = null;
    row.selectedItem = (snapshot['selectedItem'] ?? '').toString();
    row.code = (snapshot['code'] ?? '').toString();
    row.unit = (snapshot['unit'] ?? '').toString();
    row.amount = (snapshot['amount'] ?? '').toString();
    row.amountController.text = row.amount;
  }

  void _insertProductRow(int index) {
    productRows.insert(index, ProductRowData());
    productRows.refresh();
  }

  void _insertPackageRow(int index) {
    packageRows.insert(index, PackageRowData());
    packageRows.refresh();
  }

  void _moveProductRow(int from, int to) {
    if (from < 0 ||
        from >= productRows.length ||
        to < 0 ||
        to >= productRows.length) {
      return;
    }
    final row = productRows.removeAt(from);
    productRows.insert(to, row);
    productRows.refresh();
  }

  void _movePackageRow(int from, int to) {
    if (from < 0 ||
        from >= packageRows.length ||
        to < 0 ||
        to >= packageRows.length) {
      return;
    }
    final row = packageRows.removeAt(from);
    packageRows.insert(to, row);
    packageRows.refresh();
  }

  Future<void> _openProductSelector() async {
    final selected = await showSelectProductsDialog(
      context: context,
      products: products.toList(),
      title: 'Select Products',
    );
    if (selected == null || selected.isEmpty) return;
    for (final item in selected) {
      final existingIndex = productRows.indexWhere(
        (row) => row.selectedItem == item.product,
      );
      if (existingIndex != -1) continue;
      final insertIndex =
          productRows.isNotEmpty &&
              productRows.last.selectedItem.isEmpty &&
              productRows.last.savedId == null
          ? productRows.length - 1
          : productRows.length;
      final row = ProductRowData()
        ..selectedItem = item.product
        ..code = item.code
        ..unit = item.formattedUnit;
      if (insertIndex >= productRows.length) {
        productRows.add(row);
      } else {
        productRows.insert(insertIndex, row);
      }
    }
    if (productRows.isEmpty || productRows.last.selectedItem.isNotEmpty) {
      productRows.add(ProductRowData());
    }
    productRows.refresh();
  }

  List<PopupMenuEntry<String>> _rowMenuItems({
    required bool hasData,
    required bool canPaste,
    required bool canMoveTop,
    required bool canMoveBottom,
  }) {
    return [
      PopupMenuItem<String>(
        value: hasData ? 'cut' : null,
        enabled: hasData,
        child: const Text('Cut'),
      ),
      PopupMenuItem<String>(
        value: hasData ? 'copy' : null,
        enabled: hasData,
        child: const Text('Copy'),
      ),
      PopupMenuItem<String>(
        value: canPaste ? 'paste' : null,
        enabled: canPaste,
        child: const Text('Paste'),
      ),
      PopupMenuItem<String>(
        value: hasData ? 'delete' : null,
        enabled: hasData,
        child: const Text('Delete'),
      ),
      const PopupMenuDivider(height: 4),
      const PopupMenuItem<String>(
        value: 'insertRow',
        child: Text('Insert Row'),
      ),
      PopupMenuItem<String>(
        value: hasData ? 'deleteRow' : null,
        enabled: hasData,
        child: const Text('Delete Row'),
      ),
      PopupMenuItem<String>(
        value: hasData ? 'clear' : null,
        enabled: hasData,
        child: const Text('Clear'),
      ),
      const PopupMenuDivider(height: 4),
      PopupMenuItem<String>(
        value: canMoveTop ? 'top' : null,
        enabled: canMoveTop,
        child: const Text('To the Top'),
      ),
      PopupMenuItem<String>(
        value: canMoveBottom ? 'bottom' : null,
        enabled: canMoveBottom,
        child: const Text('To the Bottom'),
      ),
    ];
  }

  Future<void> _showProductRowMenu(TapDownDetails details, int index) async {
    if (index < 0 || index >= productRows.length) return;
    selectedProductRow.value = index;
    final row = productRows[index];
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: _rowMenuItems(
        hasData: _hasProductRowData(row),
        canPaste: _productClipboard != null,
        canMoveTop: index > 0,
        canMoveBottom: index < productRows.length - 1,
      ),
    );
    switch (action) {
      case 'cut':
        _productClipboard = _productRowSnapshot(row);
        await _deleteProductRow(index);
        break;
      case 'copy':
        _productClipboard = _productRowSnapshot(row);
        break;
      case 'paste':
        if (_productClipboard != null) {
          _applyProductRowSnapshot(row, _productClipboard!);
          productRows.refresh();
          if (productRows.last.selectedItem.isNotEmpty) {
            productRows.add(ProductRowData());
          }
          _scheduleAutoSaveRow('product', index);
        }
        break;
      case 'delete':
      case 'clear':
      case 'deleteRow':
        await _deleteProductRow(index);
        break;
      case 'insertRow':
        _insertProductRow(index);
        break;
      case 'top':
        _moveProductRow(index, 0);
        break;
      case 'bottom':
        _moveProductRow(index, productRows.length - 1);
        break;
    }
  }

  Future<void> _showPackageRowMenu(TapDownDetails details, int index) async {
    if (index < 0 || index >= packageRows.length) return;
    selectedPackageRow.value = index;
    final row = packageRows[index];
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: _rowMenuItems(
        hasData: _hasPackageRowData(row),
        canPaste: _packageClipboard != null,
        canMoveTop: index > 0,
        canMoveBottom: index < packageRows.length - 1,
      ),
    );
    switch (action) {
      case 'cut':
        _packageClipboard = _packageRowSnapshot(row);
        await _deletePackageRow(index);
        break;
      case 'copy':
        _packageClipboard = _packageRowSnapshot(row);
        break;
      case 'paste':
        if (_packageClipboard != null) {
          _applyPackageRowSnapshot(row, _packageClipboard!);
          packageRows.refresh();
          if (packageRows.last.selectedItem.isNotEmpty) {
            packageRows.add(PackageRowData());
          }
          _scheduleAutoSaveRow('package', index);
        }
        break;
      case 'delete':
      case 'clear':
      case 'deleteRow':
        await _deletePackageRow(index);
        break;
      case 'insertRow':
        _insertPackageRow(index);
        break;
      case 'top':
        _movePackageRow(index, 0);
        break;
      case 'bottom':
        _movePackageRow(index, packageRows.length - 1);
        break;
    }
  }

  // ─── Return All Inventory ──────────────────────────────────
  void _returnAllInventory() {
    if (dashboardController.isLocked.value) return;

    productRows.removeWhere((r) => r.savedId == null);
    packageRows.removeWhere((r) => r.savedId == null);

    for (var product in products) {
      final alreadyExists = productRows.any(
        (r) => r.selectedItem == product.product,
      );
      if (!alreadyExists) {
        final row = ProductRowData();
        row.selectedItem = product.product;
        row.code = product.code;
        row.unit = product.formattedUnit;
        productRows.add(row);
      }
    }
    for (var pkg in packages) {
      final alreadyExists = packageRows.any((r) => r.selectedItem == pkg.name);
      if (!alreadyExists) {
        final row = PackageRowData();
        row.selectedItem = pkg.name;
        row.code = pkg.code;
        row.unit = pkg.unit;
        packageRows.add(row);
      }
    }

    if (productRows.isEmpty || productRows.last.selectedItem.isNotEmpty) {
      productRows.add(ProductRowData());
    }
    if (packageRows.isEmpty || packageRows.last.selectedItem.isNotEmpty) {
      packageRows.add(PackageRowData());
    }

    productRows.refresh();
    packageRows.refresh();
    _showAlert('All inventory items added');
  }

  // ─── Save single product row ────────────────────────────────
  Future<void> _saveProductRow(int index) async {
    _autoSaveTimers.remove('product:$index')?.cancel();
    if (index >= productRows.length) return;
    final row = productRows[index];
    row.amount = row.amountController.text;

    if (row.selectedItem.isEmpty || row.amount.isEmpty) return;

    productRows[index].isSaving = true;
    productRows.refresh();

    try {
      Map<String, dynamic> result;
      if (row.savedId == null) {
        result = await _apiController.createReturnProduct(
          productName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
          productRows[index].savedId = result['data']?['_id']?.toString();
          _scheduleInventorySnapshotRefresh();
          _showAlert('Saved ✓');
          if (productRows.isEmpty || productRows.last.selectedItem.isNotEmpty) {
            productRows.add(ProductRowData());
          }
        } else {
          _showAlert(result['message'] ?? 'Save failed', isError: true);
        }
      } else {
        result = await _apiController.updateReturnProduct(
          id: row.savedId!,
          productName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
          _scheduleInventorySnapshotRefresh();
          _showAlert('Updated ✓');
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

  // ─── Delete product row ─────────────────────────────────────
  Future<void> _deleteProductRow(int index) async {
    _cancelAutoSaves();
    if (index >= productRows.length) return;
    final row = productRows[index];

    if (row.savedId == null) {
      row.dispose();
      if (productRows.length > 1)
        productRows.removeAt(index);
      else
        productRows[index] = ProductRowData();
      productRows.refresh();
      return;
    }

    productRows[index].isDeleting = true;
    productRows.refresh();

    try {
      final result = await _apiController.deleteReturnProduct(row.savedId!);
      if (result['success'] == true) {
        row.dispose();
        productRows.removeAt(index);
        _scheduleInventorySnapshotRefresh();
        if (productRows.isEmpty || productRows.last.selectedItem.isNotEmpty) {
          productRows.add(ProductRowData());
        }
        productRows.refresh();
        _showAlert('Deleted');
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

  // ─── Save single package row ────────────────────────────────
  Future<void> _savePackageRow(int index) async {
    _autoSaveTimers.remove('package:$index')?.cancel();
    if (index >= packageRows.length) return;
    final row = packageRows[index];
    row.amount = row.amountController.text;

    if (row.selectedItem.isEmpty || row.amount.isEmpty) return;

    packageRows[index].isSaving = true;
    packageRows.refresh();

    try {
      Map<String, dynamic> result;
      if (row.savedId == null) {
        result = await _apiController.createReturnPackage(
          packageName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
          packageRows[index].savedId = result['data']?['_id']?.toString();
          _scheduleInventorySnapshotRefresh();
          _showAlert('Saved ✓');
          if (packageRows.isEmpty || packageRows.last.selectedItem.isNotEmpty) {
            packageRows.add(PackageRowData());
          }
        } else {
          _showAlert(result['message'] ?? 'Save failed', isError: true);
        }
      } else {
        result = await _apiController.updateReturnPackage(
          id: row.savedId!,
          packageName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
          _scheduleInventorySnapshotRefresh();
          _showAlert('Updated ✓');
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

  // ─── Delete package row ─────────────────────────────────────
  Future<void> _deletePackageRow(int index) async {
    _cancelAutoSaves();
    if (index >= packageRows.length) return;
    final row = packageRows[index];

    if (row.savedId == null) {
      row.dispose();
      if (packageRows.length > 1)
        packageRows.removeAt(index);
      else
        packageRows[index] = PackageRowData();
      packageRows.refresh();
      return;
    }

    packageRows[index].isDeleting = true;
    packageRows.refresh();

    try {
      final result = await _apiController.deleteReturnPackage(row.savedId!);
      if (result['success'] == true) {
        row.dispose();
        packageRows.removeAt(index);
        _scheduleInventorySnapshotRefresh();
        if (packageRows.isEmpty || packageRows.last.selectedItem.isNotEmpty) {
          packageRows.add(PackageRowData());
        }
        packageRows.refresh();
        _showAlert('Deleted');
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

  // ─── Save All ───────────────────────────────────────────────
  Future<void> _saveAllData() async {
    if (dashboardController.isLocked.value) return;
    isSaving.value = true;
    try {
      int saved = 0;
      final productCount = productRows.length;
      for (int i = 0; i < productCount; i++) {
        final row = productRows[i];
        row.amount = row.amountController.text;
        if (row.selectedItem.isNotEmpty && row.amount.isNotEmpty) {
          await _saveProductRow(i);
          saved++;
        }
      }
      final packageCount = packageRows.length;
      for (int i = 0; i < packageCount; i++) {
        final row = packageRows[i];
        row.amount = row.amountController.text;
        if (row.selectedItem.isNotEmpty && row.amount.isNotEmpty) {
          await _savePackageRow(i);
          saved++;
        }
      }
      if (saved == 0) _showAlert('No data to save', isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    // ✅ BOL No. — pehle (same as ReceiveProductView)
                    Text(
                      "BOL No.",
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Obx(
                          () => TextField(
                            controller: bolController,
                            enabled: !dashboardController.isLocked.value,
                            style: AppTheme.bodySmall.copyWith(fontSize: 11),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: InputBorder.none,
                              hintText: "Enter BOL number...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ✅ Return All Inventory button — BOL ke right mein
                    Obx(
                      () => ElevatedButton(
                        onPressed: dashboardController.isLocked.value
                            ? null
                            : _returnAllInventory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                          minimumSize: const Size(0, 32),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.all_inbox_rounded, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              "Return All Inventory",
                              style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompactTable<ProductRowData, ProductModel>(
                          title: "Product",
                          rows: productRows,
                          dropdownItems: products,
                          selectedRowIndex: selectedProductRow,
                          trailing: SizedBox(
                            width: 30,
                            height: 30,
                            child: OutlinedButton(
                              onPressed: dashboardController.isLocked.value
                                  ? null
                                  : _openProductSelector,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                side: BorderSide(color: Colors.grey.shade500),
                              ),
                              child: const Icon(
                                Icons.task_alt_outlined,
                                size: 15,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          onDropdownChanged: (index, item) {
                            productRows[index].selectedItem = item.product;
                            productRows[index].code = item.code;
                            productRows[index].unit = item.formattedUnit;
                            productRows.refresh();
                            if (productRows.last.selectedItem.isNotEmpty) {
                              productRows.add(ProductRowData());
                            }
                            _scheduleAutoSaveRow('product', index);
                          },
                          onSaveRow: _saveProductRow,
                          onDeleteRow: _deleteProductRow,
                          headers: ["No", "Product", "Code", "Unit", "Amount"],
                          color: AppTheme.primaryColor,
                          itemNameGetter: (item) => item.product,
                        ),
                        const SizedBox(height: 16),
                        _buildCompactTable<PackageRowData, PackageItem>(
                          title: "Package",
                          rows: packageRows,
                          dropdownItems: packages,
                          selectedRowIndex: selectedPackageRow,
                          onDropdownChanged: (index, item) {
                            packageRows[index].selectedItem = item.name;
                            packageRows[index].code = item.code;
                            packageRows[index].unit = item.unit;
                            packageRows.refresh();
                            if (packageRows.last.selectedItem.isNotEmpty) {
                              packageRows.add(PackageRowData());
                            }
                            _scheduleAutoSaveRow('package', index);
                          },
                          onSaveRow: _savePackageRow,
                          onDeleteRow: _deletePackageRow,
                          headers: ["No", "Package", "Code", "Unit", "Amount"],
                          color: AppTheme.successColor,
                          itemNameGetter: (item) => item.name,
                        ),
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

  Widget _buildCompactTable<T, I>({
    required String title,
    required RxList<T> rows,
    required RxList<I> dropdownItems,
    required RxInt selectedRowIndex,
    required Function(int, I) onDropdownChanged,
    required Function(int) onSaveRow,
    required Function(int) onDeleteRow,
    required List<String> headers,
    required Color color,
    required String Function(I) itemNameGetter,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _getTableWidth(headers),
                child: Column(
                  children: [
                    _buildColumnHeaders(headers, color),
                    Expanded(
                      child: Obx(
                        () => SingleChildScrollView(
                          child: Column(
                            children: List.generate(rows.length, (index) {
                              final isSelected =
                                  selectedRowIndex.value == index;

                              String selItem = '';
                              String code = '';
                              String unit = '';
                              bool isSavingRow = false;
                              bool isDeletingRow = false;
                              TextEditingController? amtCtrl;

                              if (T == ProductRowData) {
                                final r = rows[index] as ProductRowData;
                                selItem = r.selectedItem;
                                code = r.code;
                                unit = r.unit;
                                isSavingRow = r.isSaving;
                                isDeletingRow = r.isDeleting;
                                amtCtrl = r.amountController;
                              } else if (T == PackageRowData) {
                                final r = rows[index] as PackageRowData;
                                selItem = r.selectedItem;
                                code = r.code;
                                unit = r.unit;
                                isSavingRow = r.isSaving;
                                isDeletingRow = r.isDeleting;
                                amtCtrl = r.amountController;
                              }

                              final menuHandler = T == ProductRowData
                                  ? (TapDownDetails details) =>
                                        _showProductRowMenu(details, index)
                                  : (TapDownDetails details) =>
                                        _showPackageRowMenu(details, index);

                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onSecondaryTapDown: menuHandler,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0
                                        ? Colors.white
                                        : Colors.grey.shade50,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _cell(
                                        50,
                                        Text(
                                          '${index + 1}',
                                          style: AppTheme.bodySmall.copyWith(
                                            fontSize: 10,
                                          ),
                                        ),
                                        center: true,
                                      ),

                                      GestureDetector(
                                        onTap: () =>
                                            selectedRowIndex.value = index,
                                        child: Container(
                                          width: 350,
                                          height: 32,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isSelected
                                                    ? Icons.arrow_drop_down
                                                    : Icons.arrow_right,
                                                size: 16,
                                                color: isSelected
                                                    ? AppTheme.primaryColor
                                                    : Colors.grey.shade400,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<I>(
                                                    value: selItem.isNotEmpty
                                                        ? dropdownItems
                                                              .firstWhereOrNull(
                                                                (item) =>
                                                                    itemNameGetter(
                                                                      item,
                                                                    ) ==
                                                                    selItem,
                                                              )
                                                        : null,
                                                    hint: selItem.isNotEmpty
                                                        ? Text(
                                                            selItem,
                                                            style: AppTheme
                                                                .bodySmall
                                                                .copyWith(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          )
                                                        : Text(
                                                            "",
                                                            style: AppTheme
                                                                .bodySmall
                                                                .copyWith(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                          ),
                                                    isExpanded: true,
                                                    isDense: true,
                                                    icon:
                                                        const SizedBox.shrink(),
                                                    style: AppTheme.bodySmall
                                                        .copyWith(
                                                          fontSize: 10,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                    menuMaxHeight: 250,
                                                    items: dropdownItems
                                                        .map(
                                                          (
                                                            item,
                                                          ) => DropdownMenuItem<I>(
                                                            value: item,
                                                            child: Text(
                                                              itemNameGetter(
                                                                item,
                                                              ),
                                                              style: AppTheme
                                                                  .bodySmall
                                                                  .copyWith(
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged:
                                                        dashboardController
                                                            .isLocked
                                                            .value
                                                        ? null
                                                        : (I? value) {
                                                            if (value != null) {
                                                              selectedRowIndex
                                                                      .value =
                                                                  index;
                                                              onDropdownChanged(
                                                                index,
                                                                value,
                                                              );
                                                            }
                                                          },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      _cell(
                                        150,
                                        Text(
                                          code,
                                          style: AppTheme.bodySmall.copyWith(
                                            fontSize: 10,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      _cell(
                                        150,
                                        Text(
                                          unit,
                                          style: AppTheme.bodySmall.copyWith(
                                            fontSize: 10,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      _cell(
                                        150,
                                        TextField(
                                          controller: amtCtrl,
                                          enabled: !dashboardController
                                              .isLocked
                                              .value,
                                          style: AppTheme.bodySmall.copyWith(
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.right,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 6,
                                                ),
                                            border: InputBorder.none,
                                          ),
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          onChanged: (val) {
                                            if (T == ProductRowData) {
                                              (rows[index] as ProductRowData)
                                                      .amount =
                                                  val;
                                              _scheduleAutoSaveRow(
                                                'product',
                                                index,
                                              );
                                            } else if (T == PackageRowData) {
                                              (rows[index] as PackageRowData)
                                                      .amount =
                                                  val;
                                              _scheduleAutoSaveRow(
                                                'package',
                                                index,
                                              );
                                            }
                                          },
                                          onSubmitted: (_) => onSaveRow(index),
                                        ),
                                        noBorder: true,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
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
    );
  }

  Widget _buildColumnHeaders(List<String> headers, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: headers
            .map(
              (h) => Container(
                width: _getColumnWidth(h),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                alignment: h == 'Amount'
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  h,
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _cell(
    double width,
    Widget child, {
    bool center = false,
    bool noBorder = false,
  }) {
    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: noBorder
          ? null
          : BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: child,
    );
  }

  double _getTableWidth(List<String> headers) =>
      headers.fold(0.0, (sum, h) => sum + _getColumnWidth(h));

  double _getColumnWidth(String h) {
    switch (h) {
      case 'No':
        return 50;
      case 'Product':
      case 'Package':
        return 350;
      case 'Code':
      case 'Unit':
      case 'Amount':
        return 150;
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    alertMessage.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _cancelAutoSaves();
    _inventorySnapshotRefreshTimer?.cancel();
    bolController.dispose(); // ✅ BOL controller dispose
    for (final r in productRows) r.dispose();
    for (final r in packageRows) r.dispose();
    super.dispose();
  }
}
