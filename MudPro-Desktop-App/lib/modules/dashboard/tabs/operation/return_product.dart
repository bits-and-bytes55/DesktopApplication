import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/products_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/service_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/return_product_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReturnProductView extends StatefulWidget {
  const ReturnProductView({super.key});

  @override
  State<ReturnProductView> createState() => _ReturnProductViewState();
}

class _ReturnProductViewState extends State<ReturnProductView> {
  final DashboardController dashboardController = Get.find<DashboardController>();
  final ProductsController productsController = Get.put(ProductsController());
  final ServiceController serviceController = Get.put(ServiceController());
  final ReturnProductController returnProductController = Get.put(ReturnProductController()); 

  // Data lists
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<PackageItem> packages = <PackageItem>[].obs;

  // Row data for each table
  final RxList<ProductRowData> productRows = <ProductRowData>[].obs;
  final RxList<PackageRowData> packageRows = <PackageRowData>[].obs;

  // Selected row indices
  final RxInt selectedProductRow = 0.obs;
  final RxInt selectedPackageRow = 0.obs;

  // BOL Number controller
  final TextEditingController bolController = TextEditingController();

  // Alert state
  final RxString alertMessage = ''.obs;
  final RxBool alertIsError = false.obs;

  // Save button loading
  final RxBool isSaving = false.obs;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Initialize with 5 empty rows
    for (int i = 0; i < 5; i++) {
      productRows.add(ProductRowData());
      packageRows.add(PackageRowData());
    }
  }

  Future<void> _loadData() async {
    try {
      // Load products
      final result = await productsController.repository.getProducts(page: 1, limit: 1000);
      if (result['success'] == true) {
        products.value = result['products'] ?? [];
      }

      // Load packages
      final pkgs = await serviceController.getPackages();
      packages.value = pkgs;
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  void _showAlert(String message, {bool isError = false}) {
    alertMessage.value = message;
    alertIsError.value = isError;
    
    // Auto hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      alertMessage.value = '';
    });
  }

  // Return All Inventory function
  void _returnAllInventory() {
    if (dashboardController.isLocked.value) return;

    // Clear all existing rows
    productRows.clear();
    packageRows.clear();

    // Add all products to product rows
    for (var product in products) {
      final row = ProductRowData();
      row.selectedItem = product.product ?? '';
      row.code = product.code ?? '';
      row.unit = product.unitClass ?? '';
      productRows.add(row);
    }

    // Add all packages to package rows
    for (var package in packages) {
      final row = PackageRowData();
      row.selectedItem = package.name;
      row.code = package.code;
      row.unit = package.unit;
      packageRows.add(row);
    }

    _showAlert('All inventory items added for return');
  }

  Future<void> _saveAllData() async {
    if (dashboardController.isLocked.value) return;

    isSaving.value = true;

    try {
      // Prepare data for saving
      List<Map<String, dynamic>> productData = [];
      List<Map<String, dynamic>> packageData = [];

      // Collect product data
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

      // Collect package data
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

      if (result['success']) {
        _showAlert(result['message']);
        // Clear rows after successful save
        productRows.clear();
        packageRows.clear();
        for (int i = 0; i < 5; i++) {
          productRows.add(ProductRowData());
          packageRows.add(PackageRowData());
        }
        bolController.clear();
      } else {
        _showAlert(result['message'], isError: true);
      }

      // Temporary success message
      _showAlert('${productData.length + packageData.length} items saved successfully');
      
      // Clear rows after successful save
      productRows.clear();
      packageRows.clear();
      for (int i = 0; i < 5; i++) {
        productRows.add(ProductRowData());
        packageRows.add(PackageRowData());
      }
      bolController.clear();

    } catch (e) {
      _showAlert('Failed to save data: $e', isError: true);
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
              // Top bar with BOL, Return All Inventory, and Save button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    // BOL No. Label
                    Text(
                      "BOL No.",
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // BOL Text Field
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
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Return All Inventory Button
                    Obx(() => ElevatedButton(
                      onPressed: dashboardController.isLocked.value ? null : _returnAllInventory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                        minimumSize: const Size(0, 32),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.all_inbox_rounded, size: 14),
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
                    )),
                    
                    const SizedBox(width: 12),
                    
                    // Save button
                    Obx(() => ElevatedButton.icon(
                      onPressed: dashboardController.isLocked.value || isSaving.value
                          ? null
                          : _saveAllData,
                      icon: isSaving.value
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        minimumSize: const Size(100, 32),
                      ),
                    )),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Table
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

                        // Package Table
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

        // Top right alert
        Positioned(
          top: 16,
          right: 16,
          child: Obx(() {
            if (alertMessage.value.isNotEmpty) {
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
                      Icon(
                        alertIsError.value ? Icons.error_outline : Icons.check_circle_outline,
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
            }
            return const SizedBox.shrink();
          }),
        ),
      ],
    );
  }

  void _checkAndAddRow<T extends BaseRowData>(RxList<T> rows) {
    if (rows.length >= 5) {
      final lastRow = rows.last;
      if (lastRow.selectedItem.isNotEmpty) {
        if (T == ProductRowData) {
          rows.add(ProductRowData() as T);
        } else if (T == PackageRowData) {
          rows.add(PackageRowData() as T);
        }
      }
    }
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
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
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

          // Table with fixed height
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: _getTableWidth(headers),
                child: Column(
                  children: [
                    // Table Header - Fixed
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: headers.map((header) {
                          return Container(
                            width: _getColumnWidth(header),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                              ),
                            ),
                            alignment: header == 'Amount' ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              header,
                              style: AppTheme.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Table Rows - Scrollable
                    Expanded(
                      child: Obx(() => SingleChildScrollView(
                        child: Column(
                          children: List.generate(rows.length, (index) {
                            final row = rows[index];
                            final isSelected = selectedRowIndex.value == index;

                            return Container(
                              decoration: BoxDecoration(
                                color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: _buildRowCells(
                                  row: row,
                                  index: index,
                                  isSelected: isSelected,
                                  dropdownItems: dropdownItems,
                                  onDropdownChanged: onDropdownChanged,
                                  onFieldChanged: onFieldChanged,
                                  onRowSelected: () => selectedRowIndex.value = index,
                                  headers: headers,
                                  itemNameGetter: itemNameGetter,
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

  double _getTableWidth(List<String> headers) {
    double totalWidth = 0;
    for (String header in headers) {
      totalWidth += _getColumnWidth(header);
    }
    return totalWidth;
  }

  double _getColumnWidth(String header) {
    if (header == 'No') {
      return 50;
    } else if (header == 'Product' || header == 'Package') {
      return 350;
    } else if (header == 'Code') {
      return 150;
    } else if (header == 'Unit') {
      return 150;
    } else if (header == 'Amount') {
      return 150;
    }
    return 100;
  }

  List<Widget> _buildRowCells<T extends BaseRowData, I>({
    required T row,
    required int index,
    required bool isSelected,
    required RxList<I> dropdownItems,
    required Function(int, I) onDropdownChanged,
    required Function(int) onFieldChanged,
    required VoidCallback onRowSelected,
    required List<String> headers,
    required String Function(I) itemNameGetter,
  }) {
    List<Widget> cells = [];

    // No column
    cells.add(
      Container(
        width: _getColumnWidth('No'),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          (index + 1).toString(),
          style: AppTheme.bodySmall.copyWith(fontSize: 10),
        ),
      ),
    );

    // Second column - Dropdown with icon
    cells.add(
      GestureDetector(
        onTap: onRowSelected,
        child: Container(
          width: _getColumnWidth(headers[1]),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Dropdown icon
              Icon(
                isSelected ? Icons.arrow_drop_down : Icons.arrow_right,
                size: 16,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              ),
              const SizedBox(width: 4),

              // Dropdown
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<I>(
                    value: row.selectedItem.isNotEmpty
                        ? dropdownItems.firstWhereOrNull((item) => itemNameGetter(item) == row.selectedItem)
                        : null,
                    hint: Text(
                      "",
                      style: AppTheme.bodySmall.copyWith(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    isExpanded: true,
                    isDense: true,
                    icon: const SizedBox.shrink(),
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppTheme.textPrimary,
                    ),
                    menuMaxHeight: 250,
                    items: dropdownItems.map((item) {
                      String name = itemNameGetter(item);

                      return DropdownMenuItem<I>(
                        value: item,
                        child: Text(
                          name,
                          style: AppTheme.bodySmall.copyWith(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: dashboardController.isLocked.value
                        ? null
                        : (I? value) {
                            if (value != null) {
                              onRowSelected();
                              onDropdownChanged(index, value);
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

    // Code column
    cells.add(
      Container(
        width: _getColumnWidth('Code'),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          row.code,
          style: AppTheme.bodySmall.copyWith(fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    // Unit column
    cells.add(
      Container(
        width: _getColumnWidth('Unit'),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          row.unit,
          style: AppTheme.bodySmall.copyWith(fontSize: 10),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    // Amount column - Right aligned
    cells.add(
      Container(
        width: _getColumnWidth('Amount'),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: TextEditingController(text: row.amount),
          enabled: !dashboardController.isLocked.value,
          style: AppTheme.bodySmall.copyWith(fontSize: 10),
          textAlign: TextAlign.right, // Right align the text
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            border: InputBorder.none,
          ),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            row.amount = val;
            onFieldChanged(index);
          },
        ),
      ),
    );

    return cells;
  }

  @override
  void dispose() {
    bolController.dispose();
    super.dispose();
  }
}

// Base class for row data
abstract class BaseRowData {
  String selectedItem = '';
  String code = '';
  String unit = '';
  String amount = '';
}

class ProductRowData extends BaseRowData {}

class PackageRowData extends BaseRowData {}