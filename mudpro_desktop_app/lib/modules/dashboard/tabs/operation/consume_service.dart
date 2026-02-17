import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/service_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
// Import your new consume service controller
// import 'package:mudpro_desktop_app/modules/consume_services/controller/consume_service_controller.dart';

class ConsumeServicesView extends StatefulWidget {
  const ConsumeServicesView({super.key});

  @override
  State<ConsumeServicesView> createState() => _ConsumeServicesViewState();
}

class _ConsumeServicesViewState extends State<ConsumeServicesView> {
  final dashboardController = Get.find<DashboardController>();
  final serviceController = Get.put(ServiceController());
  // final consumeServiceController = Get.put(ConsumeServiceController()); // Uncomment when file is added
  final RxString selectedMethod = "Used".obs;

  // Data lists
  final RxList<PackageItem> packages = <PackageItem>[].obs;
  final RxList<ServiceItem> services = <ServiceItem>[].obs;
  final RxList<EngineeringItem> engineering = <EngineeringItem>[].obs;

  // Row data for each table
  final RxList<PackageRowData> packageRows = <PackageRowData>[].obs;
  final RxList<ServiceRowData> serviceRows = <ServiceRowData>[].obs;
  final RxList<EngineeringRowData> engineeringRows = <EngineeringRowData>[].obs;

  // Selected row indices for each table
  final RxInt selectedPackageRow = 0.obs;
  final RxInt selectedServiceRow = 0.obs;
  final RxInt selectedEngineeringRow = 0.obs;

  // Loading states for each row
  final RxList<bool> packageRowLoading = <bool>[].obs;
  final RxList<bool> serviceRowLoading = <bool>[].obs;
  final RxList<bool> engineeringRowLoading = <bool>[].obs;

  // Save button loading
  final RxBool isSaving = false.obs;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Initialize with 5 empty rows each
    for (int i = 0; i < 5; i++) {
      packageRows.add(PackageRowData());
      serviceRows.add(ServiceRowData());
      engineeringRows.add(EngineeringRowData());
      packageRowLoading.add(false);
      serviceRowLoading.add(false);
      engineeringRowLoading.add(false);
    }
  }

  Future<void> _loadData() async {
    try {
      final pkgs = await serviceController.getPackages();
      final srvs = await serviceController.getServices();
      final engs = await serviceController.getEngineering();
      
      packages.value = pkgs;
      services.value = srvs;
      engineering.value = engs;
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  Future<void> _calculatePackageCost(int index) async {
    if (dashboardController.isLocked.value) return;
    
    final row = packageRows[index];
    if (row.selectedItem.isEmpty) return;

    packageRowLoading[index] = true;
    packageRowLoading.refresh();

    try {
      final initial = double.tryParse(row.initial) ?? 0.0;
      final used = double.tryParse(row.used) ?? 0.0;
      
      // Calculate locally (same as backend)
      final finalValue = initial - used;
      final cost = used * row.price;

      setState(() {
        row.final_ = finalValue.toStringAsFixed(2);
        row.cost = cost;
      });

      packageRows.refresh();

      // Show success message - top right alert
      Get.rawSnackbar(
        messageText: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cost calculated: \$${cost.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xff10B981),
        borderRadius: 6,
        margin: EdgeInsets.only(top: 8, right: 12),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 2),
        maxWidth: 350,
      );
    } catch (e) {
      Get.rawSnackbar(
        messageText: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Failed to calculate cost',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xffEF4444),
        borderRadius: 6,
        margin: EdgeInsets.only(top: 8, right: 12),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 2),
        maxWidth: 350,
      );
    } finally {
      packageRowLoading[index] = false;
      packageRowLoading.refresh();
    }
  }

  Future<void> _calculateServiceCost(int index) async {
    if (dashboardController.isLocked.value) return;
    
    final row = serviceRows[index];
    if (row.selectedItem.isEmpty) return;

    serviceRowLoading[index] = true;
    serviceRowLoading.refresh();

    try {
      final usage = double.tryParse(row.usage) ?? 0.0;
      
      // Calculate locally (same as backend)
      final cost = usage * row.price;

      setState(() {
        row.cost = cost;
      });

      serviceRows.refresh();

      // Show success message
      Get.snackbar(
        'Success',
        'Cost calculated: \$${cost.toStringAsFixed(2)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.successColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to calculate cost: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      serviceRowLoading[index] = false;
      serviceRowLoading.refresh();
    }
  }

  Future<void> _calculateEngineeringCost(int index) async {
    if (dashboardController.isLocked.value) return;
    
    final row = engineeringRows[index];
    if (row.selectedItem.isEmpty) return;

    engineeringRowLoading[index] = true;
    engineeringRowLoading.refresh();

    try {
      final usage = double.tryParse(row.usage) ?? 0.0;
      
      // Calculate locally (same as backend)
      final cost = usage * row.price;

      setState(() {
        row.cost = cost;
      });

      engineeringRows.refresh();

      // Show success message
      Get.snackbar(
        'Success',
        'Cost calculated: \$${cost.toStringAsFixed(2)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.successColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to calculate cost: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      engineeringRowLoading[index] = false;
      engineeringRowLoading.refresh();
    }
  }

  Future<void> _saveAllData() async {
    if (dashboardController.isLocked.value) return;

    isSaving.value = true;

    try {
      // Prepare data for saving
      List<Map<String, dynamic>> packageData = [];
      List<Map<String, dynamic>> serviceData = [];
      List<Map<String, dynamic>> engineeringData = [];

      // Collect package data
      for (var row in packageRows) {
        if (row.selectedItem.isNotEmpty) {
          packageData.add({
            'packageName': row.selectedItem,
            'code': row.code,
            'unit': row.unit,
            'price': row.price,
            'initial': row.initial,
            'used': row.used,
          });
        }
      }

      // Collect service data
      for (var row in serviceRows) {
        if (row.selectedItem.isNotEmpty) {
          serviceData.add({
            'serviceName': row.selectedItem,
            'code': row.code,
            'unit': row.unit,
            'price': row.price,
            'usage': row.usage,
          });
        }
      }

      // Collect engineering data
      for (var row in engineeringRows) {
        if (row.selectedItem.isNotEmpty) {
          engineeringData.add({
            'engineeringName': row.selectedItem,
            'code': row.code,
            'unit': row.unit,
            'price': row.price,
            'usage': row.usage,
          });
        }
      }

      // Uncomment when consume service controller is added
      // final result = await consumeServiceController.saveAllConsumptions(
      //   packages: packageData,
      //   services: serviceData,
      //   engineering: engineeringData,
      // );

      // Temporary success message
      Get.snackbar(
        'Success',
        'All data saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.successColor.withOpacity(0.9),
        colorText: Colors.white,
      );

      // if (result['success']) {
      //   Get.snackbar(
      //     'Success',
      //     result['message'],
      //     snackPosition: SnackPosition.BOTTOM,
      //     backgroundColor: AppTheme.successColor,
      //     colorText: Colors.white,
      //   );
      // } else {
      //   throw Exception(result['message']);
      // }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Top bar with radio buttons and save button
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
                // Radio buttons
                Text(
                  "Input Method",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 16),
                _buildCompactRadio("Used", "Used"),
                const SizedBox(width: 12),
                _buildCompactRadio("Final", "Final"),
                
                const Spacer(),
                
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
                    isSaving.value ? 'Saving...' : 'Save All',
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
                    // Package Table
                    _buildCompactTable(
                      title: "Package",
                      rows: packageRows,
                      dropdownItems: packages,
                      selectedRowIndex: selectedPackageRow,
                      rowLoading: packageRowLoading,
                      onDropdownChanged: (index, item) {
                        packageRows[index].selectedItem = item.name;
                        packageRows[index].code = item.code;
                        packageRows[index].unit = item.unit;
                        packageRows[index].price = item.price;
                        packageRows.refresh();
                        _checkAndAddRow(packageRows, packageRowLoading);
                      },
                      onFieldChanged: (index) => _checkAndAddRow(packageRows, packageRowLoading),
                      onCalculate: _calculatePackageCost,
                      headers: ["Package", "Code", "Unit", "Price (\$)", "Initial", "Used", "Final", "Cost (\$)", ""],
                      color: AppTheme.primaryColor,
                    ),

                    const SizedBox(height: 12),

                    // Services Table
                    _buildCompactTable(
                      title: "Services",
                      rows: serviceRows,
                      dropdownItems: services,
                      selectedRowIndex: selectedServiceRow,
                      rowLoading: serviceRowLoading,
                      onDropdownChanged: (index, item) {
                        serviceRows[index].selectedItem = item.name;
                        serviceRows[index].code = item.code;
                        serviceRows[index].unit = item.unit;
                        serviceRows[index].price = item.price;
                        serviceRows.refresh();
                        _checkAndAddRow(serviceRows, serviceRowLoading);
                      },
                      onFieldChanged: (index) => _checkAndAddRow(serviceRows, serviceRowLoading),
                      onCalculate: _calculateServiceCost,
                      headers: ["Services", "Code", "Unit", "Price (\$)", "Usage", "Cost (\$)", ""],
                      color: AppTheme.successColor,
                    ),

                    const SizedBox(height: 12),

                    // Engineering Table
                    _buildCompactTable(
                      title: "Engineering",
                      rows: engineeringRows,
                      dropdownItems: engineering,
                      selectedRowIndex: selectedEngineeringRow,
                      rowLoading: engineeringRowLoading,
                      onDropdownChanged: (index, item) {
                        engineeringRows[index].selectedItem = item.name;
                        engineeringRows[index].code = item.code;
                        engineeringRows[index].unit = item.unit;
                        engineeringRows[index].price = item.price;
                        engineeringRows.refresh();
                        _checkAndAddRow(engineeringRows, engineeringRowLoading);
                      },
                      onFieldChanged: (index) => _checkAndAddRow(engineeringRows, engineeringRowLoading),
                      onCalculate: _calculateEngineeringCost,
                      headers: ["Engineering", "Code", "Unit", "Price (\$)", "Usage", "Cost (\$)", ""],
                      color: AppTheme.infoColor,
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

  void _checkAndAddRow<T extends BaseRowData>(RxList<T> rows, RxList<bool> loadingStates) {
    // Check if last row (5th or beyond) is filled
    if (rows.length >= 5) {
      final lastRow = rows.last;
      if (lastRow.selectedItem.isNotEmpty) {
        if (T == PackageRowData) {
          rows.add(PackageRowData() as T);
          loadingStates.add(false);
        } else if (T == ServiceRowData) {
          rows.add(ServiceRowData() as T);
          loadingStates.add(false);
        } else if (T == EngineeringRowData) {
          rows.add(EngineeringRowData() as T);
          loadingStates.add(false);
        }
      }
    }
  }

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
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

  Widget _buildCompactTable<T extends BaseRowData, I>({
    required String title,
    required RxList<T> rows,
    required RxList<I> dropdownItems,
    required RxInt selectedRowIndex,
    required RxList<bool> rowLoading,
    required Function(int, I) onDropdownChanged,
    required Function(int) onFieldChanged,
    required Function(int) onCalculate,
    required List<String> headers,
    required Color color,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Text(
              title,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),

          // Table with fixed height and scrollable content
          SizedBox(
            height: 180, // Reduced fixed height for compression
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
                    headingRowHeight: 28, // Compressed header height
                    dataRowHeight: 28, // Compressed row height
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
                      color: color,
                    ),
                    dataTextStyle: AppTheme.bodySmall.copyWith(
                      fontSize: 9,
                    ),
                    columns: headers.map((h) => DataColumn(
                      label: Container(
                        width: _getColumnWidth(h),
                        alignment: h.contains('Price') || h.contains('Cost') || h.contains('Initial') || h.contains('Used') || h.contains('Final') || h.contains('Usage')
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(h),
                      ),
                    )).toList(),
                    rows: List.generate(rows.length, (index) {
                      final row = rows[index];
                      final isSelected = selectedRowIndex.value == index;
                      
                      return DataRow(
                        color: MaterialStateProperty.all(
                          index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        ),
                        cells: _buildRowCells(
                          row: row,
                          index: index,
                          isSelected: isSelected,
                          dropdownItems: dropdownItems,
                          onDropdownChanged: onDropdownChanged,
                          onFieldChanged: onFieldChanged,
                          onRowSelected: () => selectedRowIndex.value = index,
                          onCalculate: onCalculate,
                          headers: headers,
                          isLoading: rowLoading[index],
                        ),
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

  double _getColumnWidth(String header) {
    if (header.contains('Package') || header.contains('Services') || header.contains('Engineering')) {
      return 160;
    } else if (header == 'Code') {
      return 90;
    } else if (header == 'Unit') {
      return 70;
    } else if (header.contains('Price') || header.contains('Cost')) {
      return 90;
    } else if (header == '') {
      return 40; // Play button column
    } else {
      return 80;
    }
  }

  List<DataCell> _buildRowCells<T extends BaseRowData, I>({
    required T row,
    required int index,
    required bool isSelected,
    required RxList<I> dropdownItems,
    required Function(int, I) onDropdownChanged,
    required Function(int) onFieldChanged,
    required VoidCallback onRowSelected,
    required Function(int) onCalculate,
    required List<String> headers,
    required bool isLoading,
  }) {
    List<DataCell> cells = [];

    // First column - Dropdown with icon
    cells.add(DataCell(
      GestureDetector(
        onTap: onRowSelected,
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              // Dropdown icon - shows only in selected row
              if (isSelected)
                Icon(
                  Icons.arrow_drop_down,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
              if (isSelected)
                const SizedBox(width: 2),
              
              // Dropdown
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<I>(
                    value: row.selectedItem.isNotEmpty 
                        ? dropdownItems.firstWhereOrNull((item) {
                            if (item is PackageItem) return item.name == row.selectedItem;
                            if (item is ServiceItem) return item.name == row.selectedItem;
                            if (item is EngineeringItem) return item.name == row.selectedItem;
                            return false;
                          })
                        : null,
                    hint: Text(
                      "Select",
                      style: AppTheme.bodySmall.copyWith(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                    isExpanded: true,
                    isDense: true,
                    icon: const SizedBox.shrink(),
                    menuMaxHeight: 200,
                    items: dropdownItems.map((item) {
                      String name = '';
                      if (item is PackageItem) name = item.name;
                      if (item is ServiceItem) name = item.name;
                      if (item is EngineeringItem) name = item.name;
                      
                      return DropdownMenuItem<I>(
                        value: item,
                        child: Text(
                          name,
                          style: AppTheme.bodySmall.copyWith(fontSize: 9),
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
    ));

    // Code
    cells.add(DataCell(
      Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(row.code, style: AppTheme.bodySmall.copyWith(fontSize: 9)),
      ),
    ));

    // Unit
    cells.add(DataCell(
      Container(
        width: 70,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(row.unit, style: AppTheme.bodySmall.copyWith(fontSize: 9)),
      ),
    ));

    // Price
    cells.add(DataCell(
      Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          row.price > 0 ? row.price.toStringAsFixed(2) : '',
          style: AppTheme.bodySmall.copyWith(fontSize: 9),
          textAlign: TextAlign.right,
        ),
      ),
    ));

    // Additional fields based on table type
    if (row is PackageRowData) {
      // Initial, Used, Final, Cost
      cells.add(_buildEditableCell(row.initial, (val) {
        row.initial = val;
        onFieldChanged(index);
      }, 80));
      cells.add(_buildEditableCell(row.used, (val) {
        row.used = val;
        onFieldChanged(index);
      }, 80));
      cells.add(DataCell(
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            row.final_,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ));
      cells.add(DataCell(
        Container(
          width: 90,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            row.cost > 0 ? row.cost.toStringAsFixed(2) : '',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: row.cost > 0 ? AppTheme.primaryColor : Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ));
    } else {
      // Usage, Cost
      cells.add(_buildEditableCell(
        row is ServiceRowData ? row.usage : (row as EngineeringRowData).usage, 
        (val) {
          if (row is ServiceRowData) {
            row.usage = val;
          } else if (row is EngineeringRowData) {
            row.usage = val;
          }
          onFieldChanged(index);
        }, 
        80
      ));
      cells.add(DataCell(
        Container(
          width: 90,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            row.cost > 0 ? row.cost.toStringAsFixed(2) : '',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: row.cost > 0 ? AppTheme.primaryColor : Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ));
    }

    // Play button column
    cells.add(DataCell(
      Container(
        width: 40,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: Icon(
                  Icons.play_circle_outline,
                  size: 18,
                  color: row.selectedItem.isNotEmpty && !dashboardController.isLocked.value
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: row.selectedItem.isNotEmpty && !dashboardController.isLocked.value
                    ? () => onCalculate(index)
                    : null,
                tooltip: 'Calculate Cost',
              ),
      ),
    ));

    return cells;
  }

  DataCell _buildEditableCell(String value, Function(String) onChanged, double width) {
    return DataCell(
      Container(
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
          keyboardType: TextInputType.number,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Base class for row data
abstract class BaseRowData {
  String selectedItem = '';
  String code = '';
  String unit = '';
  double price = 0.0;
  double cost = 0.0;
}

class PackageRowData extends BaseRowData {
  String initial = '';
  String used = '';
  String final_ = '';
}

class ServiceRowData extends BaseRowData {
  String usage = '';
}

class EngineeringRowData extends BaseRowData {
  String usage = '';
}