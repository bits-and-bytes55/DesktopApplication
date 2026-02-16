import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ConsumeProductView extends StatelessWidget {
  ConsumeProductView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  final ScrollController scrollController = ScrollController();
  final ScrollController horizontalScrollController = ScrollController();
  final ScrollController verticalScrollController = ScrollController();
  
  // Radio button state
  final RxString selectedMethod = "Used".obs;
  
  // Add water checkbox state
  final RxBool addWater = false.obs;
  
  // Water volume controller
  final TextEditingController waterVolumeController = TextEditingController(text: "10.5");
  
  // Total volume controller
  final TextEditingController totalVolumeController = TextEditingController(text: "152.75");

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- ENHANCED TITLE ----------------
            // _buildTitleSection(),

            // const SizedBox(height: 16),

            // ---------------- ENHANCED TOP CONTROLS ----------------
            _buildTopControls(),

            const SizedBox(height: 20),

            // ---------------- ENHANCED MAIN TABLE ----------------
            _buildEnhancedProductTable(),

            const SizedBox(height: 20),

            // ---------------- ENHANCED BOTTOM SECTION IN GRID ----------------
            _buildBottomGridSection(),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // ENHANCED TITLE SECTION
  // ===========================================================
  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
              Icons.inventory_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Consume Product",
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage product consumption with detailed tracking",
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warehouse_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "Products: 12 Active",
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // ENHANCED TOP CONTROLS
  // ===========================================================
  Widget _buildTopControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth > 1000;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isWideScreen
              ? Row(
                  children: [
                    // Product Selection Dropdown
                    Expanded(
                      child: _buildEnhancedDropdown(
                        hintText: "Select Products",
                        icon: Icons.search_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Load Previous Products
                    Expanded(
                      child: _buildEnhancedDropdown(
                        hintText: "Load Previous Products",
                        icon: Icons.history_rounded,
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Radio Buttons
                    Expanded(
                      child: Obx(() => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: dashboardController.isLocked.value 
                            ? Colors.grey.shade100 
                            : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Input Method",
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                buildEnhancedRadio("Used", Icons.trending_up_rounded, "Used"),
                                const SizedBox(width: 20),
                                buildEnhancedRadio("Final", Icons.flag_rounded, "Final"),
                              ],
                            ),
                          ],
                        ),
                      )),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedDropdown(
                            hintText: "Select Products",
                            icon: Icons.search_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEnhancedDropdown(
                            hintText: "Load Previous",
                            icon: Icons.history_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: dashboardController.isLocked.value 
                          ? Colors.grey.shade100 
                          : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Input Method",
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              buildEnhancedRadio("Used", Icons.trending_up_rounded, "Used"),
                              const SizedBox(width: 20),
                              buildEnhancedRadio("Final", Icons.flag_rounded, "Final"),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEnhancedDropdown({required String hintText, required IconData icon}) {
    return Obx(() => Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: dashboardController.isLocked.value ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: null,
                hint: Text(
                  hintText,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppTheme.textSecondary,
                ),
                onChanged: dashboardController.isLocked.value ? null : (_) {},
                items: [
                  DropdownMenuItem(
                    value: "1",
                    child: Text(
                      "Product 1",
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget buildEnhancedRadio(String label, IconData icon, String value) {
    return Obx(() => InkWell(
      onTap: dashboardController.isLocked.value 
          ? null 
          : () => selectedMethod.value = value,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedMethod.value == value
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selectedMethod.value == value
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Radio Button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedMethod.value == value
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selectedMethod.value == value
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 16,
              color: selectedMethod.value == value
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: selectedMethod.value == value
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // ===========================================================
  // ENHANCED MAIN PRODUCT TABLE
  // ===========================================================
  Widget _buildEnhancedProductTable() {
    final headers = [
      "No.",
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
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth > 1200;
        final double tableHeight = isWideScreen ? 450 : 350;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.table_chart_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Product Consumption Details",
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "8 Records",
                        style: AppTheme.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Content
              SizedBox(
                height: tableHeight,
                child: Scrollbar(
                  controller: verticalScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: verticalScrollController,
                    scrollDirection: Axis.vertical,
                    child: Scrollbar(
                      controller: horizontalScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: isWideScreen ? 1200 : 800,
                          ),
                          child: Obx(() => DataTable(
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
                            headingRowHeight: 45,
                            dataRowHeight: 48,
                            headingTextStyle: AppTheme.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            dataTextStyle: AppTheme.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppTheme.textPrimary,
                            ),
                            columns: headers.map((header) {
                              return DataColumn(
                                label: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  alignment: header.contains('\$') 
                                      ? Alignment.centerRight 
                                      : Alignment.centerLeft,
                                  child: Text(
                                    header,
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            rows: List.generate(
                              8,
                              (rowIndex) => DataRow(
                                color: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                    return rowIndex % 2 == 0
                                        ? Colors.white
                                        : Colors.grey.shade50;
                                  },
                                ),
                                cells: headers.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final header = entry.value;
                                  return DataCell(
                                    _buildTableCellContent(rowIndex, index, header),
                                  );
                                }).toList(),
                              ),
                            ),
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableCellContent(int rowIndex, int columnIndex, String header) {
    // Sample data for demonstration
    final sampleData = [
      "${rowIndex + 1}",
      "Product ${rowIndex + 1}",
      "PRD-${(rowIndex + 1).toString().padLeft(3, '0')}",
      "${1.0 + (rowIndex * 0.1)}",
      ["Pcs", "Kg", "Ltr", "Bbl"][rowIndex % 4],
      "\$${(100 + rowIndex * 50).toStringAsFixed(2)}",
      "${100 + rowIndex * 10}",
      "${5 + rowIndex}",
      "${20 + rowIndex * 5}",
      "${80 + rowIndex * 10}",
      "\$${(2500 + rowIndex * 500).toStringAsFixed(2)}",
      "${10.5 + rowIndex * 2.5}",
    ];

    final isEditable = !dashboardController.isLocked.value && 
                       ![0, 1].contains(columnIndex); // Don't make No. and Product columns editable
    
    if (columnIndex == 1) {
      // Product column with dropdown icon
      return InkWell(
        onTap: dashboardController.isLocked.value ? null : () {
          // Show product dropdown when clicked
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  sampleData[columnIndex],
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: header.contains('\$') ? Alignment.centerRight : Alignment.centerLeft,
      child: isEditable
          ? TextField(
              controller: TextEditingController(text: sampleData[columnIndex]),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: "Enter...",
                hintStyle: AppTheme.caption.copyWith(
                  color: Colors.grey.shade400,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                color: AppTheme.textPrimary,
                fontWeight: header.contains('\$') ? FontWeight.w500 : FontWeight.w400,
              ),
              textAlign: header.contains('\$') ? TextAlign.right : TextAlign.left,
            )
          : Text(
              sampleData[columnIndex],
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                color: columnIndex == 0 ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: columnIndex == 0 ? FontWeight.w600 : 
                          header.contains('\$') ? FontWeight.w500 : FontWeight.w400,
              ),
              textAlign: header.contains('\$') ? TextAlign.right : TextAlign.left,
            ),
    );
  }

  // ===========================================================
  // ENHANCED BOTTOM SECTION IN GRID
  // ===========================================================
  Widget _buildBottomGridSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth > 1000;
        
        if (isWideScreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Section - Distribute To Table (50%)
              Expanded(
                child: _buildEnhancedDistributeTable(),
              ),
              const SizedBox(width: 16),

              // Right Section - Controls (50%)
              Expanded(
                child: _buildEnhancedRightControls(),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              // Distribute To Table
              _buildEnhancedDistributeTable(),
              const SizedBox(height: 16),

              // Right Section - Controls
              _buildEnhancedRightControls(),
            ],
          );
        }
      },
    );
  }

  Widget _buildEnhancedDistributeTable() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.share_arrival_time_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Distribution Points",
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Content
          Expanded(
            child: SingleChildScrollView(
              child: Obx(() => DataTable(
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
                headingRowHeight: 40,
                dataRowHeight: 52, // Increased height for dropdown
                headingTextStyle: AppTheme.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                dataTextStyle: AppTheme.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                ),
                columns: const [
                  DataColumn(label: Text("Pit")),
                  DataColumn(label: Text("Vol (bbl)")),
                ],
                rows: List.generate(
                  8,
                  (rowIndex) => DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        return rowIndex % 2 == 0
                            ? Colors.white
                            : Colors.grey.shade50;
                      },
                    ),
                    cells: [
                      // Pit Column with Dropdown
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: dashboardController.isLocked.value
                              ? Text(
                                  rowIndex == 0 
                                    ? "Active System" 
                                    : "Reserve ${rowIndex}",
                                  style: AppTheme.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : DropdownButton<String>(
                                  value: rowIndex == 0 ? "Active System" : "Reserve $rowIndex",
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  icon: Icon(
                                    Icons.arrow_drop_down_rounded,
                                    size: 20,
                                    color: AppTheme.textSecondary,
                                  ),
                                  items: [
                                    "Active System",
                                    "Reserve 1",
                                    "Reserve 2",
                                    "Reserve 3",
                                    "Reserve 4",
                                    "Reserve 5",
                                    "Reserve 6",
                                    "Reserve 7",
                                    "Reserve 8",
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: AppTheme.bodySmall.copyWith(
                                          fontSize: 11,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    // Handle dropdown change
                                  },
                                ),
                        ),
                      ),
                      
                      // Volume Column
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerRight,
                          child: dashboardController.isLocked.value
                              ? Text(
                                  "${2.62 + (rowIndex * 0.5)}",
                                  style: AppTheme.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppTheme.textPrimary,
                                  ),
                                )
                              : TextField(
                                  controller: TextEditingController(
                                    text: "${2.62 + (rowIndex * 0.5)}",
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintText: "0.00",
                                    hintStyle: AppTheme.caption.copyWith(
                                      color: Colors.grey.shade400,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  style: AppTheme.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppTheme.textPrimary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRightControls() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
            "Configuration",
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Add Water Checkbox
          Obx(() => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dashboardController.isLocked.value 
                ? Colors.grey.shade50 
                : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                // Checkbox
                InkWell(
                  onTap: dashboardController.isLocked.value 
                      ? null 
                      : () {
                          addWater.value = !addWater.value;
                        },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: addWater.value ? AppTheme.primaryColor : Colors.grey.shade400,
                        width: addWater.value ? 1.5 : 1,
                      ),
                      color: addWater.value ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                    ),
                    child: addWater.value
                        ? Icon(Icons.check, size: 16, color: AppTheme.primaryColor)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.water_drop_rounded,
                  size: 18,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: 8),
                Text(
                  "Add Water",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 12),

          // Add Water Input Field (shown when Add Water is checked)
          Obx(() => addWater.value
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Water Volume",
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: dashboardController.isLocked.value 
                          ? Colors.grey.shade50 
                          : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              enabled: !dashboardController.isLocked.value,
                              controller: waterVolumeController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                hintText: "Enter water volume...",
                              ),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.infoColor.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "bbl",
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.infoColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink()),

          // Total Volume Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Volume",
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => Container(
                height: 45,
                decoration: BoxDecoration(
                  color: dashboardController.isLocked.value 
                    ? Colors.grey.shade50 
                    : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enabled: !dashboardController.isLocked.value,
                        controller: totalVolumeController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          hintText: "Enter volume...",
                        ),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "bbl",
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),

          const Spacer(),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: dashboardController.isLocked.value ? null : () {},
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
                      Icon(Icons.save_alt_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Save Changes",
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: dashboardController.isLocked.value ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardColor,
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 0,
                ),
                child: Icon(Icons.refresh_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}