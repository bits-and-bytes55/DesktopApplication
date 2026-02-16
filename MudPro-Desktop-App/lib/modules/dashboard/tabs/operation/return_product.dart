import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReturnProductView extends StatelessWidget {
  ReturnProductView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  final ScrollController scrollController = ScrollController();

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

            // ================= ENHANCED TOP CONTROLS =================
            _buildTopControls(),

            const SizedBox(height: 24),

            // ================= ENHANCED PRODUCT TABLE =================
            _buildEnhancedProductTable(),

            const SizedBox(height: 24),

            // ================= ENHANCED PACKAGE TABLE =================
            _buildEnhancedPackageTable(),

            const SizedBox(height: 24),

            // ================= ENHANCED SUMMARY =================
            _buildSummarySection(),
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
              Icons.assignment_return_rounded,
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
                  "Return Product",
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Process product returns with detailed tracking and documentation",
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
                  "Pending Returns",
                  style: AppTheme.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "20 Items",
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

  // ================= ENHANCED TOP CONTROLS =================
  Widget _buildTopControls() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.confirmation_number_rounded,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Return Documentation",
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // BOL Number Input
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BOL Number",
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: dashboardController.isLocked.value 
                          ? Colors.grey.shade50 
                          : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        enabled: !dashboardController.isLocked.value,
                        controller: TextEditingController(text: "BOL-RET-2024-00123"),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          hintText: "Enter BOL number...",
                          hintStyle: AppTheme.caption.copyWith(
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.receipt_long_rounded,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              
              // Return All Inventory Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24), // Align with input label
                  Obx(() => ElevatedButton(
                    onPressed: dashboardController.isLocked.value ? null : () {
                      // Return all inventory action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.all_inbox_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Return All Inventory",
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Enter the Bill of Lading number associated with the return. Use 'Return All Inventory' to process bulk returns.",
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= ENHANCED PRODUCT TABLE =================
  Widget _buildEnhancedProductTable() {
    final headers = ["No.", "Product", "Code", "Unit", "Amount", "Actions"];

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
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Product Returns (15 Items)",
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
                    "Total Value: \$32,450.75",
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
            height: 400,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1000,
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
                          dataRowHeight: 52,
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
                          columnSpacing: 20,
                          columns: headers.map((header) {
                            return DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: header == "Amount" || header == "No." 
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
                            15,
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
                                    alignment: Alignment.centerRight,
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
                                
                                // Product Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: dashboardController.isLocked.value
                                        ? _buildStaticProduct(rowIndex)
                                        : _buildEditableProductCell(rowIndex),
                                  ),
                                ),
                                
                                // Code Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: dashboardController.isLocked.value
                                        ? _buildStaticProductCode(rowIndex)
                                        : _buildEditableProductCodeCell(rowIndex),
                                  ),
                                ),
                                
                                // Unit Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: dashboardController.isLocked.value
                                        ? _buildStaticProductUnit(rowIndex)
                                        : _buildEditableProductUnitCell(rowIndex),
                                  ),
                                ),
                                
                                // Amount Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    alignment: Alignment.centerRight,
                                    child: dashboardController.isLocked.value
                                        ? _buildStaticProductAmount(rowIndex)
                                        : _buildEditableProductAmountCell(rowIndex),
                                  ),
                                ),
                                
                                // Actions Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!dashboardController.isLocked.value)
                                          IconButton(
                                            onPressed: () {},
                                            icon: Icon(
                                              Icons.remove_circle_outline_rounded,
                                              size: 18,
                                              color: AppTheme.errorColor,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: "Remove Return",
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.arrow_circle_right_rounded,
                                            size: 18,
                                            color: AppTheme.successColor,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: "Process Return",
                                        ),
                                      ],
                                    ),
                                  ),
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
        ],
      ),
    );
  }

  // Static data for product table
  String _getStaticProduct(int index) {
    final products = [
      "Defective Fluid Additive",
      "Excess Barite Powder",
      "Bentonite Clay Return",
      "Unused Calcium Chloride",
      "Polymer Viscosifier (Expired)",
      "Defoamer Chemical Return",
      "Lubricant Additive (Surplus)",
      "Shale Inhibitor Return",
      "Weighting Material Return",
      "Filtration Control Agent",
      "Emulsifier Return",
      "Corrosion Inhibitor (Damaged)",
      "Biocide (Expired)",
      "pH Control Agent Return",
      "Lost Circulation Material"
    ];
    return products[index];
  }

  Widget _buildStaticProduct(int index) {
    return Text(
      _getStaticProduct(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _getStaticProductCode(int index) {
    return "RET-PROD-${(index + 1).toString().padLeft(3, '0')}";
  }

  Widget _buildStaticProductCode(int index) {
    return Text(
      _getStaticProductCode(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.textPrimary,
      ),
    );
  }

  String _getStaticProductUnit(int index) {
    final units = ["Pcs", "Kg", "L", "Bbl", "Ton", "Bag", "Drum", "Ctn"];
    return units[index % units.length];
  }

  Widget _buildStaticProductUnit(int index) {
    return Text(
      _getStaticProductUnit(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.textPrimary,
      ),
    );
  }

  String _getStaticProductAmount(int index) {
    final amount = (250 + (index * 150)).toDouble();
    return "\$${amount.toStringAsFixed(2)}";
  }

  Widget _buildStaticProductAmount(int index) {
    return Text(
      _getStaticProductAmount(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Editable cells for product table
  Widget _buildEditableProductCell(int index) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: TextEditingController(text: _getStaticProduct(index)),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "Enter product name...",
          hintStyle: AppTheme.caption.copyWith(
            color: Colors.grey.shade400,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEditableProductCodeCell(int index) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: TextEditingController(text: _getStaticProductCode(index)),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "Return code...",
          hintStyle: AppTheme.caption.copyWith(
            color: Colors.grey.shade400,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEditableProductUnitCell(int index) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: TextEditingController(text: _getStaticProductUnit(index)),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "Unit...",
          hintStyle: AppTheme.caption.copyWith(
            color: Colors.grey.shade400,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEditableProductAmountCell(int index) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: TextEditingController(text: _getStaticProductAmount(index)),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "0.00",
          hintStyle: AppTheme.caption.copyWith(
            color: Colors.grey.shade400,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixText: "\$",
          prefixStyle: AppTheme.bodySmall.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.right,
        keyboardType: TextInputType.number,
      ),
    );
  }

  // ================= ENHANCED PACKAGE TABLE =================
  Widget _buildEnhancedPackageTable() {
    final headers = ["No.", "Package", "Code", "Unit", "Amount", "Actions"];

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
              color: AppTheme.successColor.withOpacity(0.95),
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
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Package Returns (5 Items)",
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
                    "Total Value: \$8,750.25",
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
            height: 320,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 800,
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
                          dataRowHeight: 52,
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
                          columnSpacing: 20,
                          columns: headers.map((header) {
                            return DataColumn(
                              label: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: header == "Amount" || header == "No." 
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
                            5,
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
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      (rowIndex + 1).toString(),
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: AppTheme.successColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Package Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: dashboardController.isLocked.value
                                        ? _buildStaticPackage(rowIndex)
                                        : _buildEditablePackageCell(rowIndex),
                                  ),
                                ),
                                
                                // Code Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: dashboardController.isLocked.value
                                        ? _buildStaticPackageCode(rowIndex)
                                        : _buildEditablePackageCodeCell(rowIndex),
                                  ),
                                ),
                                
                                // Unit Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: dashboardController.isLocked.value
                                        ? _buildStaticPackageUnit(rowIndex)
                                        : _buildEditablePackageUnitCell(rowIndex),
                                  ),
                                ),
                                
                                // Amount Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    alignment: Alignment.centerRight,
                                    child: dashboardController.isLocked.value
                                        ? _buildStaticPackageAmount(rowIndex)
                                        : _buildEditablePackageAmountCell(rowIndex),
                                  ),
                                ),
                                
                                // Actions Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!dashboardController.isLocked.value)
                                          IconButton(
                                            onPressed: () {},
                                            icon: Icon(
                                              Icons.remove_circle_outline_rounded,
                                              size: 18,
                                              color: AppTheme.errorColor,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: "Remove Return",
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.arrow_circle_right_rounded,
                                            size: 18,
                                            color: AppTheme.successColor,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: "Process Return",
                                        ),
                                      ],
                                    ),
                                  ),
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
        ],
      ),
    );
  }

  // Static data for package table
  String _getStaticPackage(int index) {
    final packages = [
      "Defective Fluid Kit",
      "Chemical Additives Pack (Expired)",
      "Maintenance Package Return",
      "Safety Equipment Set (Damaged)",
      "Emergency Response Kit (Unused)"
    ];
    return packages[index];
  }

  Widget _buildStaticPackage(int index) {
    return Text(
      _getStaticPackage(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _getStaticPackageCode(int index) {
    return "RET-PKG-${(index + 1).toString().padLeft(3, '0')}";
  }

  Widget _buildStaticPackageCode(int index) {
    return Text(
      _getStaticPackageCode(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.textPrimary,
      ),
    );
  }

  String _getStaticPackageUnit(int index) {
    final units = ["Kit", "Set", "Pack", "Box", "Pallet"];
    return units[index];
  }

  Widget _buildStaticPackageUnit(int index) {
    return Text(
      _getStaticPackageUnit(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.textPrimary,
      ),
    );
  }

  String _getStaticPackageAmount(int index) {
    final amount = (850 + (index * 350)).toDouble();
    return "\$${amount.toStringAsFixed(2)}";
  }

  Widget _buildStaticPackageAmount(int index) {
    return Text(
      _getStaticPackageAmount(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.successColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Editable cells for package table
  Widget _buildEditablePackageCell(int index) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: TextEditingController(text: _getStaticPackage(index)),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "Enter package name...",
          hintStyle: AppTheme.caption.copyWith(
            color: Colors.grey.shade400,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEditablePackageCodeCell(int index) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: TextEditingController(text: _getStaticPackageCode(index)),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "Return code...",
          hintStyle: AppTheme.caption.copyWith(
            color: Colors.grey.shade400,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEditablePackageUnitCell(int index) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: TextEditingController(text: _getStaticPackageUnit(index)),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "Unit...",
          hintStyle: AppTheme.caption.copyWith(
            color: Colors.grey.shade400,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEditablePackageAmountCell(int index) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: TextEditingController(text: _getStaticPackageAmount(index)),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "0.00",
          hintStyle: AppTheme.caption.copyWith(
            color: Colors.grey.shade400,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixText: "\$",
          prefixStyle: AppTheme.bodySmall.copyWith(
            color: AppTheme.successColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.successColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.right,
        keyboardType: TextInputType.number,
      ),
    );
  }

  // ================= ENHANCED SUMMARY =================
  Widget _buildSummarySection() {
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
            "Return Summary",
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              _buildSummaryCard(
                title: "Total Product Value",
                value: "\$32,450.75",
                color: AppTheme.primaryColor,
                icon: Icons.inventory_2_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Total Package Value",
                value: "\$8,750.25",
                color: AppTheme.successColor,
                icon: Icons.account_box,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Credit Amount",
                value: "\$41,201.00",
                color: AppTheme.infoColor,
                icon: Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Processing Fee",
                value: "\$1,250.00",
                color: AppTheme.warningColor,
                icon: Icons.request_quote_rounded,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successColor.withOpacity(0.9),
                  AppTheme.successColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Net Refund Amount",
                      style: AppTheme.caption.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "\$39,951.00",
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Obx(() => ElevatedButton(
                      onPressed: dashboardController.isLocked.value ? null : () {
                        // Process returns action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Process Returns",
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(width: 12),
                    Obx(() => ElevatedButton(
                      onPressed: dashboardController.isLocked.value ? null : () {
                        // Cancel returns action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cancel_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Cancel Returns",
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTheme.titleMedium.copyWith(
                      fontSize: 16,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}