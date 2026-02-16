import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import '../../widgets/editable_cell.dart';

class MudLossStorageView extends StatelessWidget {
  MudLossStorageView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  final ScrollController scrollController = ScrollController();

  final RxInt activeDropdownRow = (-1).obs;
  final RxString selectedStorage = "Select Storage".obs;

  final List<String> storageOptions = [
    "Active System",
    "Storage Tank 1",
    "Storage Tank 2",
    "Reserve Pit 1",
    "Reserve Pit 2",
    "Suction Pit 4A",
    "Suction Pit 4B",
    "Trip Tank",
    "Mixing Pit",
    "Discharge Pit",
    "Emergency Pit",
    "Overflow Pit",
    "Containment Pit",
    "Waste Tank",
    "Treatment Pit",
    "Recycle Pit",
    "Fresh Water Tank",
    "Brine Tank",
    "Chemical Storage",
    "Slurry Pit"
  ];

  final List<Map<String, RxString>> tableData = List.generate(
    20,
    (_) => {
      'storage': "Select Storage".obs,
      'dump': "".obs,
      'evaporation': "".obs,
      'pitCleaning': "".obs,
      'other': "".obs,
      'total': "".obs,
    },
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= ENHANCED HEADER =================
            // _buildHeader(),

            // const SizedBox(height: 20),

            // ================= ENHANCED TABLE (EMPTY) =================
            _buildEnhancedEmptyTable(),

            const SizedBox(height: 24),

            // ================= ENHANCED ACTION SECTION =================
            _buildActionSection(),
          ],
        ),
      ),
    );
  }

  // ================= ENHANCED HEADER =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storage_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mud Loss - Storage",
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Track mud loss across different storage locations and categories",
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Empty Table",
                  style: AppTheme.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Add Data",
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ENHANCED EMPTY TABLE =================
  Widget _buildEnhancedEmptyTable() {
    final List<String> headers = ["No.", "Storage", "Dump (bbl)", "Evaporation (bbl)", "Pit Cleaning (bbl)", "Other (bbl)", "Total (bbl)"];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.table_chart_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Storage Loss Tracking",
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "20 Rows",
                    style: AppTheme.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Content (Empty)
          SizedBox(
            height: 500,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1200, // Increased width for wider Storage column
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Obx(
                        () => DataTable(
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            verticalInside: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            right: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            top: BorderSide.none,
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          headingRowHeight: 48,
                          dataRowHeight: 56,
                          headingTextStyle: AppTheme.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.3,
                          ),
                          dataTextStyle: AppTheme.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppTheme.textPrimary,
                          ),
                          columnSpacing: 12,
                          columns: headers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final header = entry.value;
                            
                            return DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: index == 0 ? Alignment.center : 
                                         index >= 2 ? Alignment.centerRight : Alignment.centerLeft,
                                child: Text(
                                  header,
                                  style: AppTheme.bodySmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  textAlign: index == 0 ? TextAlign.center : 
                                            index >= 2 ? TextAlign.right : TextAlign.left,
                                ),
                              ),
                              // Increased width for Storage column
                              tooltip: index == 1 ? "Select storage location from dropdown" : null,
                            );
                          }).toList(),
                          rows: List.generate(
                            20,
                            (rowIndex) => DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  return rowIndex % 2 == 0
                                      ? Colors.white
                                      : Colors.grey.shade50;
                                },
                              ),
                              cells: [
                                // No. Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    alignment: Alignment.center,
                                    child: Text(
                                      (rowIndex + 1).toString(),
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Storage Column with Dropdown (WIDENED)
                                DataCell(
                                  InkWell(
                                    onTap: dashboardController.isLocked.value ? null : () {
                                      activeDropdownRow.value = rowIndex;
                                      tableData[rowIndex]['storage']!.value = "Select Storage";
                                    },
                                    child: Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Obx(() => Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: activeDropdownRow.value == rowIndex
                                              ? AppTheme.primaryColor.withOpacity(0.1)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: activeDropdownRow.value == rowIndex
                                                ? AppTheme.primaryColor
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: activeDropdownRow.value == rowIndex
                                            ? DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  isExpanded: true,
                                                  value: tableData[rowIndex]['storage']!.value == "Select Storage" ? null : tableData[rowIndex]['storage']!.value,
                                                  icon: const Icon(
                                                    Icons.arrow_drop_down_rounded,
                                                    size: 20,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                  menuMaxHeight: 200,
                                                  elevation: 4,
                                                  dropdownColor: Colors.white,
                                                  style: AppTheme.bodySmall.copyWith(
                                                    fontSize: 11,
                                                    color: AppTheme.textPrimary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  hint: Text(
                                                    "Select Storage",
                                                    style: AppTheme.bodySmall.copyWith(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                  onChanged: (newValue) {
                                                    if (newValue != null) {
                                                      tableData[rowIndex]['storage']!.value = newValue;
                                                      activeDropdownRow.value = -1;
                                                    }
                                                  },
                                                  items: storageOptions.map((option) {
                                                    return DropdownMenuItem<String>(
                                                      value: option,
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                                        child: Text(
                                                          option,
                                                          style: AppTheme.bodySmall.copyWith(
                                                            fontSize: 11,
                                                            color: AppTheme.textPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              )
                                            : Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        tableData[rowIndex]['storage']!.value == "Select Storage"
                                                            ? "Select Storage"
                                                            : tableData[rowIndex]['storage']!.value,
                                                        style: AppTheme.bodySmall.copyWith(
                                                          fontSize: 11,
                                                          color: tableData[rowIndex]['storage']!.value == "Select Storage"
                                                              ? Colors.grey.shade500
                                                              : AppTheme.textPrimary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.arrow_drop_down_rounded,
                                                      size: 20,
                                                      color: Colors.grey.shade400,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      )),
                                    ),
                                  ),
                                ),
                                
                                // Dump Column
                                DataCell(
                                  EditableCell(
                                    value: tableData[rowIndex]['dump']!,
                                    minHeight: 40,
                                  ),
                                ),
                                
                                // Evaporation Column
                                DataCell(
                                  EditableCell(
                                    value: tableData[rowIndex]['evaporation']!,
                                    minHeight: 40,
                                  ),
                                ),
                                
                                // Pit Cleaning Column
                                DataCell(
                                  EditableCell(
                                    value: tableData[rowIndex]['pitCleaning']!,
                                    minHeight: 40,
                                  ),
                                ),
                                
                                // Other Column
                                DataCell(
                                  EditableCell(
                                    value: tableData[rowIndex]['other']!,
                                    minHeight: 40,
                                  ),
                                ),
                                
                                // Total Column (Calculated)
                                DataCell(
                                  Obx(() {
                                    final dump = double.tryParse(tableData[rowIndex]['dump']!.value) ?? 0.0;
                                    final evaporation = double.tryParse(tableData[rowIndex]['evaporation']!.value) ?? 0.0;
                                    final pitCleaning = double.tryParse(tableData[rowIndex]['pitCleaning']!.value) ?? 0.0;
                                    final other = double.tryParse(tableData[rowIndex]['other']!.value) ?? 0.0;
                                    final total = dump + evaporation + pitCleaning + other;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        total == 0.0 ? "0.00" : total.toStringAsFixed(2),
                                        style: AppTheme.bodySmall.copyWith(
                                          fontSize: 11,
                                          color: total == 0.0 ? Colors.grey.shade400 : AppTheme.textPrimary,
                                          fontStyle: total == 0.0 ? FontStyle.italic : FontStyle.normal,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Table Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Click on Storage column to select location, then enter volume data",
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Obx(() => Text(
                  "Selected: ${selectedStorage.value}",
                  style: AppTheme.caption.copyWith(
                    color: selectedStorage.value == "Select Storage" 
                        ? AppTheme.textSecondary 
                        : AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerRight,
      child: Container(
        height: 40,
        width: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            "0.00",
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  // ================= ENHANCED ACTION SECTION =================
  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Table Actions",
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.table_rows_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Storage Selection",
                                  style: AppTheme.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Obx(() => Text(
                                  selectedStorage.value == "Select Storage"
                                      ? "No storage selected"
                                      : "Selected: ${selectedStorage.value}",
                                  style: AppTheme.caption.copyWith(
                                    color: selectedStorage.value == "Select Storage"
                                        ? AppTheme.textSecondary
                                        : AppTheme.primaryColor,
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Click on any Storage cell to open dropdown and select a storage location. Only one dropdown can be active at a time.",
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quick Actions",
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(() => ElevatedButton(
                      onPressed: dashboardController.isLocked.value ? null : () {
                        // Clear selection
                        activeDropdownRow.value = -1;
                        selectedStorage.value = "Select Storage";
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.clear_rounded, size: 18, color: AppTheme.textPrimary),
                          const SizedBox(width: 8),
                          Text(
                            "Clear Selection",
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 8),
                    Obx(() => ElevatedButton(
                      onPressed: dashboardController.isLocked.value || selectedStorage.value == "Select Storage" ? null : () {
                        // Add data for selected storage
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_chart_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Add Volume Data",
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 8),
                    Obx(() => ElevatedButton(
                      onPressed: dashboardController.isLocked.value ? null : () {
                        // Fill all with sample data
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.infoColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.data_array_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Fill Sample Data",
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}