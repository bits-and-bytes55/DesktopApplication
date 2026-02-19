import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/return_product_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/products_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/service_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/model/ug_inventory_product_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

abstract class BaseRowData {
  String selectedItem = '';
  String code = '';
  String unit = '';
  String amount = '';
}

class ProductRowData extends BaseRowData {}
class PackageRowData extends BaseRowData {}

class ReturnProductView extends StatefulWidget {
  const ReturnProductView({super.key});

  @override
  State<ReturnProductView> createState() => _ReturnProductViewState();
}

class _ReturnProductViewState extends State<ReturnProductView> {
  final DashboardController dashboardController = Get.find<DashboardController>();
  final ProductsController productsController = Get.put(ProductsController());
  final ServiceController serviceController = Get.put(ServiceController());
  final ReturnProductController returnProductController = ReturnProductController();

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<PackageItem> packages = <PackageItem>[].obs;

  final RxList<ProductRowData> productRows = <ProductRowData>[].obs;
  final RxList<PackageRowData> packageRows = <PackageRowData>[].obs;

  final RxInt selectedProductRow = 0.obs;
  final RxInt selectedPackageRow = 0.obs;

  final TextEditingController bolController = TextEditingController();

  final RxString alertMessage = ''.obs;
  final RxBool alertIsError = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    // Start with 1 empty row each
    productRows.add(ProductRowData());
    packageRows.add(PackageRowData());
  }

  Future<void> _loadDropdownData() async {
    print('🔵 [LOAD] Loading dropdown data from inventory...');
    try {
      const wellId = '507f1f77bcf86cd799439011';
      
      final inventoryProducts = await InventoryProductsService.fetchProducts(wellId);
      final inventoryPackages = await InventoryProductsService.fetchPackages(wellId);
      
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
      
      packages.value = inventoryPackages;
      
      print('🟢 [LOAD] products=${inventoryProducts.length} packages=${inventoryPackages.length}');
    } catch (e) {
      print("Error loading dropdown data: $e");
    }
  }

  void _showAlert(String message, {bool isError = false}) {
    alertMessage.value = message;
    alertIsError.value = isError;
    Future.delayed(const Duration(seconds: 3), () => alertMessage.value = '');
  }

  // When last row gets an item selected → add a new empty row automatically
  void _checkAndAddRow<T extends BaseRowData>(RxList<T> rows) {
    if (rows.isNotEmpty && rows.last.selectedItem.isNotEmpty) {
      if (T == ProductRowData) rows.add(ProductRowData() as T);
      else if (T == PackageRowData) rows.add(PackageRowData() as T);
    }
  }

  // Fill all products + packages into rows (leaves last row empty for new input)
  void _returnAllInventory() {
    if (dashboardController.isLocked.value) return;

    productRows.clear();
    packageRows.clear();

    for (var product in products) {
      final row = ProductRowData();
      row.selectedItem = product.product ?? '';
      row.code = product.code ?? '';
      row.unit = product.unitClass ?? '';
      productRows.add(row);
    }
    // Always keep one empty row at the end
    productRows.add(ProductRowData());

    for (var package in packages) {
      final row = PackageRowData();
      row.selectedItem = package.name;
      row.code = package.code;
      row.unit = package.unit;
      packageRows.add(row);
    }
    // Always keep one empty row at the end
    packageRows.add(PackageRowData());

    _showAlert('All inventory items added for return');
  }

  Future<void> _saveAllData() async {
    if (dashboardController.isLocked.value) return;
    isSaving.value = true;
    try {
      List<Map<String, dynamic>> productData = [];
      List<Map<String, dynamic>> packageData = [];

      for (var row in productRows) {
        if (row.selectedItem.isNotEmpty && row.amount.isNotEmpty) {
          productData.add({
            'productName': row.selectedItem,
            'code': row.code,
            'unit': row.unit,
            'amount': row.amount,
          });
        }
      }
      for (var row in packageRows) {
        if (row.selectedItem.isNotEmpty && row.amount.isNotEmpty) {
          packageData.add({
            'packageName': row.selectedItem,
            'code': row.code,
            'unit': row.unit,
            'amount': row.amount,
          });
        }
      }

      if (productData.isEmpty && packageData.isEmpty) {
        _showAlert('No data to save', isError: true);
        return;
      }

      final result = await returnProductController.saveAllReturnData(
        products: productData,
        packages: packageData,
      );

      if (result['success'] == true) {
        _showAlert(result['message'] ?? 'Saved successfully');
        // Reset to single empty row
        productRows.clear();
        packageRows.clear();
        productRows.add(ProductRowData());
        packageRows.add(PackageRowData());
        bolController.clear();
      } else {
        _showAlert(result['message'] ?? 'Save failed', isError: true);
      }
    } catch (e) {
      _showAlert('Failed to save: $e', isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              // Top bar: BOL + Return All Inventory + Save
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Text("BOL No.", style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: InputBorder.none,
                            hintText: "Enter BOL number...",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Return All Inventory button
                    Obx(() => ElevatedButton(
                      onPressed: dashboardController.isLocked.value ? null : _returnAllInventory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        elevation: 0,
                        minimumSize: const Size(0, 32),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.all_inbox_rounded, size: 14),
                          const SizedBox(width: 6),
                          Text("Return All Inventory", style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
                        ],
                      ),
                    )),
                    const SizedBox(width: 12),
                    // Save button
                    Obx(() => ElevatedButton.icon(
                      onPressed: dashboardController.isLocked.value || isSaving.value ? null : _saveAllData,
                      icon: isSaving.value
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Icon(Icons.save, size: 16),
                      label: Text(isSaving.value ? 'Saving...' : 'Save', style: const TextStyle(fontSize: 12)),
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

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompactTable(
                          title: "Product",
                          rows: productRows,
                          dropdownItems: products,
                          selectedRowIndex: selectedProductRow,
                          onDropdownChanged: (index, item) {
                            productRows[index].selectedItem = item.product ?? '';
                            productRows[index].code = item.code ?? '';
                            productRows[index].unit = item.unitClass ?? '';
                            productRows.refresh();
                            _checkAndAddRow(productRows);
                          },
                          onFieldChanged: (index) => _checkAndAddRow(productRows),
                          headers: ["No", "Product", "Code", "Unit", "Amount"],
                          color: AppTheme.primaryColor,
                          itemNameGetter: (item) => (item as ProductModel).product ?? '',
                        ),
                        const SizedBox(height: 16),
                        _buildCompactTable(
                          title: "Package",
                          rows: packageRows,
                          dropdownItems: packages,
                          selectedRowIndex: selectedPackageRow,
                          onDropdownChanged: (index, item) {
                            packageRows[index].selectedItem = item.name;
                            packageRows[index].code = item.code;
                            packageRows[index].unit = item.unit;
                            packageRows.refresh();
                            _checkAndAddRow(packageRows);
                          },
                          onFieldChanged: (index) => _checkAndAddRow(packageRows),
                          headers: ["No", "Package", "Code", "Unit", "Amount"],
                          color: AppTheme.successColor,
                          itemNameGetter: (item) => (item as PackageItem).name,
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

  Widget _buildCompactTable<T extends BaseRowData, I>({
    required String title,
    required RxList<T> rows,
    required RxList<I> dropdownItems,
    required RxInt selectedRowIndex,
    required Function(int, I) onDropdownChanged,
    required Function(int) onFieldChanged,
    required List<String> headers,
    required Color color,
    required String Function(I) itemNameGetter,
  }) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(title, color),
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
                      child: Obx(() => SingleChildScrollView(
                        child: Column(
                          children: List.generate(rows.length, (index) {
                            final row = rows[index];
                            final isSelected = selectedRowIndex.value == index;
                            return Container(
                              decoration: BoxDecoration(
                                color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                              ),
                              child: Row(
                                children: _buildInputRowCells(
                                  row: row, index: index, isSelected: isSelected,
                                  dropdownItems: dropdownItems, onDropdownChanged: onDropdownChanged,
                                  onFieldChanged: onFieldChanged,
                                  onRowSelected: () => selectedRowIndex.value = index,
                                  headers: headers, itemNameGetter: itemNameGetter,
                                ),
                              ),
                            );
                          }),
                        ),
                      )),
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

  List<Widget> _buildInputRowCells<T extends BaseRowData, I>({
    required T row, required int index, required bool isSelected,
    required RxList<I> dropdownItems, required Function(int, I) onDropdownChanged,
    required Function(int) onFieldChanged, required VoidCallback onRowSelected,
    required List<String> headers, required String Function(I) itemNameGetter,
  }) {
    return [
      _cell(50, Text((index + 1).toString(), style: AppTheme.bodySmall.copyWith(fontSize: 10)), center: true),
      GestureDetector(
        onTap: onRowSelected,
        child: Container(
          width: 350, height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300, width: 0.5))),
          child: Row(
            children: [
              Icon(isSelected ? Icons.arrow_drop_down : Icons.arrow_right, size: 16,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400),
              const SizedBox(width: 4),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<I>(
                    value: row.selectedItem.isNotEmpty
                        ? dropdownItems.firstWhereOrNull((item) => itemNameGetter(item) == row.selectedItem)
                        : null,
                    hint: Text("", style: AppTheme.bodySmall.copyWith(fontSize: 10, color: Colors.grey)),
                    isExpanded: true, isDense: true, icon: const SizedBox.shrink(),
                    style: AppTheme.bodySmall.copyWith(fontSize: 10, color: AppTheme.textPrimary),
                    menuMaxHeight: 250,
                    items: dropdownItems.map((item) => DropdownMenuItem<I>(
                      value: item,
                      child: Text(itemNameGetter(item), style: AppTheme.bodySmall.copyWith(fontSize: 10), overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: dashboardController.isLocked.value ? null : (I? value) {
                      if (value != null) { onRowSelected(); onDropdownChanged(index, value); }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      _cell(150, Text(row.code, style: AppTheme.bodySmall.copyWith(fontSize: 10), overflow: TextOverflow.ellipsis)),
      _cell(150, Text(row.unit, style: AppTheme.bodySmall.copyWith(fontSize: 10), overflow: TextOverflow.ellipsis)),
      _cell(150, TextField(
        controller: TextEditingController(text: row.amount),
        enabled: !dashboardController.isLocked.value,
        style: AppTheme.bodySmall.copyWith(fontSize: 10),
        textAlign: TextAlign.right,
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6), border: InputBorder.none),
        keyboardType: TextInputType.number,
        onChanged: (val) { row.amount = val; onFieldChanged(index); },
      ), noBorder: true),
    ];
  }

  Widget _buildTableHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Text(title, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 11, color: color)),
    );
  }

  Widget _buildColumnHeaders(List<String> headers, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: headers.map((h) => Container(
          width: _getColumnWidth(h),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300, width: 0.5))),
          alignment: h == 'Amount' ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(h, style: AppTheme.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        )).toList(),
      ),
    );
  }

  Widget _cell(double width, Widget child, {bool center = false, bool noBorder = false}) {
    return Container(
      width: width, height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: noBorder ? null : BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300, width: 0.5))),
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: child,
    );
  }

  double _getTableWidth(List<String> headers) => headers.fold(0.0, (sum, h) => sum + _getColumnWidth(h));

  double _getColumnWidth(String h) {
    switch (h) {
      case 'No': return 50;
      case 'Product': case 'Package': return 350;
      case 'Code': case 'Unit': case 'Amount': return 150;
      default: return 100;
    }
  }

  Widget _buildAlert() {
    return Positioned(
      top: 16, right: 16,
      child: Obx(() {
        if (alertMessage.value.isEmpty) return const SizedBox.shrink();
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: alertIsError.value ? Colors.red.shade600 : AppTheme.successColor,
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: const BoxConstraints(maxWidth: 300),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(alertIsError.value ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(alertMessage.value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
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
    super.dispose();
  }
}