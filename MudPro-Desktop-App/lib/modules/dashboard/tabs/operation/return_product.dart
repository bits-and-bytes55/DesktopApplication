import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/return_product_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
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
  Worker? _wellWorker;
  Worker? _reportWorker;

  String? get _currentReportId {
    final reportId = reportContext.selectedReportId.value.trim();
    return reportId.isEmpty ? null : reportId;
  }

  @override
  void initState() {
    super.initState();
    _inventoryStore = Get.find<InventoryProductsStore>();
    _loadPackages();
    _loadSavedData();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      _handleContextChange();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      _handleContextChange();
    });
  }

  @override
  void dispose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    bolController.dispose();
    for (final row in productRows) {
      row.dispose();
    }
    for (final row in packageRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _handleContextChange() {
    bolController.clear();
    _loadPackages();
    _loadSavedData();
  }

  // ─── Fetch saved records on load ──────────────────────────
  Future<void> _loadSavedData() async {
    try {
      final wellId = currentBackendWellId.trim();
      for (final row in productRows) {
        row.dispose();
      }
      for (final row in packageRows) {
        row.dispose();
      }
      productRows.clear();
      packageRows.clear();

      if (wellId.isEmpty) {
        productRows.add(ProductRowData());
        packageRows.add(PackageRowData());
        return;
      }

      final savedProducts = await _apiController.getReturnProducts(
        wellId: wellId,
        reportId: _currentReportId,
      );
      final savedPackages = await _apiController.getReturnPackages(
        wellId: wellId,
        reportId: _currentReportId,
      );

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

  void _showAlert(String message, {bool isError = false}) {
    alertMessage.value = message;
    alertIsError.value = isError;
    Future.delayed(const Duration(seconds: 3), () => alertMessage.value = '');
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
          wellId: currentBackendWellId.trim(),
          reportId: _currentReportId,
          productName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
          productRows[index].savedId = result['data']?['_id']?.toString();
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
          wellId: currentBackendWellId.trim(),
          reportId: _currentReportId,
          productName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
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
          wellId: currentBackendWellId.trim(),
          reportId: _currentReportId,
          packageName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
          packageRows[index].savedId = result['data']?['_id']?.toString();
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
          wellId: currentBackendWellId.trim(),
          reportId: _currentReportId,
          packageName: row.selectedItem,
          code: row.code,
          unit: row.unit,
          amount: double.tryParse(row.amount) ?? 0.0,
        );
        if (result['success'] == true) {
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
      for (int i = 0; i < productRows.length; i++) {
        final row = productRows[i];
        row.amount = row.amountController.text;
        if (row.selectedItem.isNotEmpty &&
            row.amount.isNotEmpty &&
            row.savedId == null) {
          await _saveProductRow(i);
        }
      }
      for (int i = 0; i < packageRows.length; i++) {
        final row = packageRows[i];
        row.amount = row.amountController.text;
        if (row.selectedItem.isNotEmpty &&
            row.amount.isNotEmpty &&
            row.savedId == null) {
          await _savePackageRow(i);
        }
      }
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

                    const SizedBox(width: 16),

                    // ✅ Save button
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed:
                            dashboardController.isLocked.value || isSaving.value
                            ? null
                            : _saveAllData,
                        icon: isSaving.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.save, size: 16),
                        label: Text(
                          isSaving.value ? 'Saving...' : 'Save',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          minimumSize: const Size(100, 32),
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
                          title: "Add Product",
                          rows: productRows,
                          dropdownItems: products,
                          selectedRowIndex: selectedProductRow,
                          onDropdownChanged: (index, item) {
                            productRows[index].selectedItem = item.product;
                            productRows[index].code = item.code;
                            productRows[index].unit = item.formattedUnit;
                            productRows.refresh();
                            if (productRows.last.selectedItem.isNotEmpty) {
                              productRows.add(ProductRowData());
                            }
                          },
                          onSaveRow: _saveProductRow,
                          onDeleteRow: _deleteProductRow,
                          headers: [
                            "No",
                            "Product",
                            "Code",
                            "Unit",
                            "Amount",
                            "",
                          ],
                          color: AppTheme.primaryColor,
                          itemNameGetter: (item) => item.product,
                        ),
                        const SizedBox(height: 16),
                        _buildCompactTable<PackageRowData, PackageItem>(
                          title: "Add Package",
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
                          },
                          onSaveRow: _savePackageRow,
                          onDeleteRow: _deletePackageRow,
                          headers: [
                            "No",
                            "Package",
                            "Code",
                            "Unit",
                            "Amount",
                            "",
                          ],
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
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              title,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: color,
              ),
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

                              return Container(
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
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        )
                                                      : Text(
                                                          "",
                                                          style: AppTheme
                                                              .bodySmall
                                                              .copyWith(
                                                                fontSize: 10,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                        ),
                                                  isExpanded: true,
                                                  isDense: true,
                                                  icon: const SizedBox.shrink(),
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
                                                                  fontSize: 10,
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
                                        enabled:
                                            !dashboardController.isLocked.value,
                                        style: AppTheme.bodySmall.copyWith(
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.right,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
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
                                          } else if (T == PackageRowData) {
                                            (rows[index] as PackageRowData)
                                                    .amount =
                                                val;
                                          }
                                        },
                                        onSubmitted: (_) => onSaveRow(index),
                                      ),
                                      noBorder: true,
                                    ),

                                    SizedBox(
                                      width: 60,
                                      height: 32,
                                      child: isSavingRow || isDeletingRow
                                          ? Center(
                                              child: SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: isDeletingRow
                                                          ? Colors.red
                                                          : color,
                                                    ),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                InkWell(
                                                  onTap:
                                                      dashboardController
                                                          .isLocked
                                                          .value
                                                      ? null
                                                      : () => onSaveRow(index),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    child: Icon(
                                                      Icons.save_outlined,
                                                      size: 14,
                                                      color:
                                                          dashboardController
                                                              .isLocked
                                                              .value
                                                          ? Colors.grey.shade300
                                                          : color,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap:
                                                      dashboardController
                                                          .isLocked
                                                          .value
                                                      ? null
                                                      : () =>
                                                            onDeleteRow(index),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    child: Icon(
                                                      Icons.delete_outline,
                                                      size: 14,
                                                      color:
                                                          dashboardController
                                                              .isLocked
                                                              .value
                                                          ? Colors.grey.shade300
                                                          : Colors.red.shade400,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
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
      case '':
        return 60;
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

  void _disposeLegacyRows() {
    bolController.dispose(); // ✅ BOL controller dispose
    for (final r in productRows) r.dispose();
    for (final r in packageRows) r.dispose();
    super.dispose();
  }
}
