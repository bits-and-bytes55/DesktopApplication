import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/products_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/service_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
// Import your new receive product controller
// import 'package:mudpro_desktop_app/modules/receive_product/controller/receive_product_controller.dart';

class ReceiveProductView extends StatefulWidget {
  const ReceiveProductView({super.key});

  @override
  State<ReceiveProductView> createState() => _ReceiveProductViewState();
}

class _ReceiveProductViewState extends State<ReceiveProductView> {
  final DashboardController dashboardController = Get.find<DashboardController>();
  final ProductsController productsController = Get.put(ProductsController());
  final ServiceController serviceController = Get.put(ServiceController());
  // final ReceiveProductController receiveProductController = Get.put(ReceiveProductController()); // Uncomment when added

  // Data lists for dropdown
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<PackageItem> packages = <PackageItem>[].obs;

  // Saved items from database
  final RxList<SavedProductItem> savedProducts = <SavedProductItem>[].obs;
  final RxList<SavedPackageItem> savedPackages = <SavedPackageItem>[].obs;

  // Row data for new entries
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
    _loadSavedData();
    // Initialize with 5 empty rows
    for (int i = 0; i < 5; i++) {
      productRows.add(ProductRowData());
      packageRows.add(PackageRowData());
    }
  }

  Future<void> _loadData() async {
    try {
      // Load products for dropdown
      final result = await productsController.repository.getProducts(page: 1, limit: 1000);
      if (result['success'] == true) {
        products.value = result['products'] ?? [];
      }

      // Load packages for dropdown
      final pkgs = await serviceController.getPackages();
      packages.value = pkgs;
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  Future<void> _loadSavedData() async {
    try {
      // Uncomment when controller is added
      // final receivedProducts = await receiveProductController.getReceiveProducts();
      // final receivedPackages = await receiveProductController.getReceivePackages();
      
      // savedProducts.value = receivedProducts.map((item) {
      //   return SavedProductItem(
      //     id: item['_id'] ?? '',
      //     productName: item['productName'] ?? '',
      //     code: item['code'] ?? '',
      //     unit: item['unit'] ?? '',
      //     amount: (item['amount'] ?? 0).toString(),
      //   );
      // }).toList();

      // savedPackages.value = receivedPackages.map((item) {
      //   return SavedPackageItem(
      //     id: item['_id'] ?? '',
      //     packageName: item['packageName'] ?? '',
      //     code: item['code'] ?? '',
      //     unit: item['unit'] ?? '',
      //     amount: (item['amount'] ?? 0).toString(),
      //   );
      // }).toList();
    } catch (e) {
      print("Error loading saved data: $e");
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

  Future<void> _updateSavedProduct(SavedProductItem item) async {
    try {
      // Uncomment when controller is added
      // final result = await receiveProductController.updateReceiveProduct(
      //   id: item.id,
      //   productName: item.productName,
      //   code: item.code,
      //   unit: item.unit,
      //   amount: double.tryParse(item.amount) ?? 0.0,
      // );

      // if (result['success']) {
      //   _showAlert('Product updated successfully');
      // } else {
      //   _showAlert(result['message'], isError: true);
      // }
      
      _showAlert('Product updated successfully');
    } catch (e) {
      _showAlert('Failed to update: $e', isError: true);
    }
  }

  Future<void> _deleteSavedProduct(String id) async {
    try {
      // Uncomment when controller is added
      // final result = await receiveProductController.deleteReceiveProduct(id);

      // if (result['success']) {
      //   savedProducts.removeWhere((item) => item.id == id);
      //   _showAlert('Product deleted successfully');
      // } else {
      //   _showAlert(result['message'], isError: true);
      // }
      
      savedProducts.removeWhere((item) => item.id == id);
      _showAlert('Product deleted successfully');
    } catch (e) {
      _showAlert('Failed to delete: $e', isError: true);
    }
  }

  Future<void> _updateSavedPackage(SavedPackageItem item) async {
    try {
      // Uncomment when controller is added
      // final result = await receiveProductController.updateReceivePackage(
      //   id: item.id,
      //   packageName: item.packageName,
      //   code: item.code,
      //   unit: item.unit,
      //   amount: double.tryParse(item.amount) ?? 0.0,
      // );

      // if (result['success']) {
      //   _showAlert('Package updated successfully');
      // } else {
      //   _showAlert(result['message'], isError: true);
      // }
      
      _showAlert('Package updated successfully');
    } catch (e) {
      _showAlert('Failed to update: $e', isError: true);
    }
  }

  Future<void> _deleteSavedPackage(String id) async {
    try {
      // Uncomment when controller is added
      // final result = await receiveProductController.deleteReceivePackage(id);

      // if (result['success']) {
      //   savedPackages.removeWhere((item) => item.id == id);
      //   _showAlert('Package deleted successfully');
      // } else {
      //   _showAlert(result['message'], isError: true);
      // }
      
      savedPackages.removeWhere((item) => item.id == id);
      _showAlert('Package deleted successfully');
    } catch (e) {
      _showAlert('Failed to delete: $e', isError: true);
    }
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

      // Uncomment when receive product controller is added
      // final result = await receiveProductController.saveAllReceiveData(
      //   products: productData,
      //   packages: packageData,
      // );

      // if (result['success']) {
      //   _showAlert(result['message']);
      //   // Reload saved data
      //   await _loadSavedData();
      //   // Clear input rows
      //   productRows.clear();
      //   packageRows.clear();
      //   for (int i = 0; i < 5; i++) {
      //     productRows.add(ProductRowData());
      //     packageRows.add(PackageRowData());
      //   }
      //   bolController.clear();
      // } else {
      //   _showAlert(result['message'], isError: true);
      // }

      // Temporary success message
      _showAlert('${productData.length + packageData.length} items saved successfully');
      
      // Reload saved data
      await _loadSavedData();
      
      // Clear input rows
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
              // Top bar with BOL and Save button
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
                        // Saved Products Table
                        Obx(() {
                          if (savedProducts.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSavedProductsTable(),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),

                        // Product Input Table
                        _buildInputTable(
                          title: "Add Product",
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

                        // Saved Packages Table
                        Obx(() {
                          if (savedPackages.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSavedPackagesTable(),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),

                        // Package Input Table
                        _buildInputTable(
                          title: "Add Package",
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

  Widget _buildSavedProductsTable() {
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
              color: AppTheme.primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              "Received Products",
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: Obx(() => DataTable(
                headingRowHeight: 30,
                dataRowHeight: 32,
                columnSpacing: 12,
                horizontalMargin: 12,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                columns: [
                  DataColumn(label: Text('No', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Product', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Code', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Unit', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Amount', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600)), numeric: true),
                  DataColumn(label: Text('Actions', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600))),
                ],
                rows: savedProducts.asMap().entries.map((entry) {
                  int index = entry.key;
                  SavedProductItem item = entry.value;
                  return DataRow(cells: [
                    DataCell(Text('${index + 1}', style: AppTheme.bodySmall.copyWith(fontSize: 10))),
                    DataCell(Text(item.productName, style: AppTheme.bodySmall.copyWith(fontSize: 10))),
                    DataCell(Text(item.code, style: AppTheme.bodySmall.copyWith(fontSize: 10))),
                    DataCell(Text(item.unit, style: AppTheme.bodySmall.copyWith(fontSize: 10))),
                    DataCell(
                      TextField(
                        controller: TextEditingController(text: item.amount),
                        enabled: !dashboardController.isLocked.value,
                        style: AppTheme.bodySmall.copyWith(fontSize: 10),
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          item.amount = val;
                        },
                        onSubmitted: (_) => _updateSavedProduct(item),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check, size: 16, color: AppTheme.successColor),
                            onPressed: dashboardController.isLocked.value ? null : () => _updateSavedProduct(item),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Update',
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            onPressed: dashboardController.isLocked.value ? null : () => _deleteSavedProduct(item.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPackagesTable() {
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
              color: AppTheme.successColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              "Received Packages",
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppTheme.successColor,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: Obx(() => DataTable(
                headingRowHeight: 30,
                dataRowHeight: 32,
                columnSpacing: 12,
                horizontalMargin: 12,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                columns: [
                  DataColumn(label: Text('No', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Package', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Code', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Unit', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Amount', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600)), numeric: true),
                  DataColumn(label: Text('Actions', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600))),
                ],
                rows: savedPackages.asMap().entries.map((entry) {
                  int index = entry.key;
                  SavedPackageItem item = entry.value;
                  return DataRow(cells: [
                    DataCell(Text('${index + 1}', style: AppTheme.bodySmall.copyWith(fontSize: 10))),
                    DataCell(Text(item.packageName, style: AppTheme.bodySmall.copyWith(fontSize: 10))),
                    DataCell(Text(item.code, style: AppTheme.bodySmall.copyWith(fontSize: 10))),
                    DataCell(Text(item.unit, style: AppTheme.bodySmall.copyWith(fontSize: 10))),
                    DataCell(
                      TextField(
                        controller: TextEditingController(text: item.amount),
                        enabled: !dashboardController.isLocked.value,
                        style: AppTheme.bodySmall.copyWith(fontSize: 10),
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          item.amount = val;
                        },
                        onSubmitted: (_) => _updateSavedPackage(item),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check, size: 16, color: AppTheme.successColor),
                            onPressed: dashboardController.isLocked.value ? null : () => _updateSavedPackage(item),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Update',
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            onPressed: dashboardController.isLocked.value ? null : () => _deleteSavedPackage(item.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              )),
            ),
          ),
        ],
      ),
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

  Widget _buildInputTable<T extends BaseRowData, I>({
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
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 850,
                child: Column(
                  children: [
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
                            width: header == 'No' ? 50 : (header == 'Product' || header == 'Package') ? 350 : 150,
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
                                children: _buildInputRowCells(
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

  List<Widget> _buildInputRowCells<T extends BaseRowData, I>({
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

    cells.add(
      Container(
        width: 50,
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

    cells.add(
      GestureDetector(
        onTap: onRowSelected,
        child: Container(
          width: 350,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.arrow_drop_down : Icons.arrow_right,
                size: 16,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
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

    cells.add(
      Container(
        width: 150,
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

    cells.add(
      Container(
        width: 150,
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

    cells.add(
      Container(
        width: 150,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: TextEditingController(text: row.amount),
          enabled: !dashboardController.isLocked.value,
          style: AppTheme.bodySmall.copyWith(fontSize: 10),
          textAlign: TextAlign.right,
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

abstract class BaseRowData {
  String selectedItem = '';
  String code = '';
  String unit = '';
  String amount = '';
}

class ProductRowData extends BaseRowData {}
class PackageRowData extends BaseRowData {}

class SavedProductItem {
  String id;
  String productName;
  String code;
  String unit;
  String amount;

  SavedProductItem({
    required this.id,
    required this.productName,
    required this.code,
    required this.unit,
    required this.amount,
  });
}

class SavedPackageItem {
  String id;
  String packageName;
  String code;
  String unit;
  String amount;

  SavedPackageItem({
    required this.id,
    required this.packageName,
    required this.code,
    required this.unit,
    required this.amount,
  });
}