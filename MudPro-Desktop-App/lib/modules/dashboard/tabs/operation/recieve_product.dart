import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import '../../controller/operation_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReceiveProductView extends StatelessWidget {
  ReceiveProductView({super.key});

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

            // ================= ENHANCED BOL NO SECTION =================
            _buildBolNumberSection(),

            const SizedBox(height: 24),

            // ================= ENHANCED PRODUCT TABLE =================
            _buildEnhancedProductTable(),

            const SizedBox(height: 24),

            // ================= ENHANCED PACKAGE TABLE =================
            _buildEnhancedPackageTable(),

            const SizedBox(height: 24),

            // ================= SUMMARY FOOTER =================
            _buildSummaryFooter(),
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
              Icons.inventory_rounded,
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
                  "Receive Product",
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Record incoming products and packages with detailed tracking",
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
                  "Total Items",
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

  // ================= ENHANCED BOL NO SECTION =================
  Widget _buildBolNumberSection() {
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
                "Bill of Lading Number",
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => Container(
            height: 48,
            decoration: BoxDecoration(
              color: dashboardController.isLocked.value 
                ? Colors.grey.shade50 
                : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "BOL No.",
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    enabled: !dashboardController.isLocked.value,
                    controller: TextEditingController(text: "BOL-2024-00123"),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      hintText: "Enter BOL number...",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 80,
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
                      "Required",
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                "Enter the Bill of Lading number for tracking purposes",
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
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
                  "Product Details (15 Items)",
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
                    "Total: \$45,280.50",
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
            height: 380,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1000, // Fixed width for horizontal scrolling
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
                                        ? _buildStaticCode(rowIndex)
                                        : _buildEditableCodeCell(rowIndex),
                                  ),
                                ),
                                
                                // Unit Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: dashboardController.isLocked.value
                                        ? _buildStaticUnit(rowIndex)
                                        : _buildEditableUnitCell(rowIndex),
                                  ),
                                ),
                                
                                // Amount Column
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    alignment: Alignment.centerRight,
                                    child: dashboardController.isLocked.value
                                        ? _buildStaticAmount(rowIndex)
                                        : _buildEditableAmountCell(rowIndex),
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
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppTheme.errorColor,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: "Remove",
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.visibility_outlined,
                                            size: 18,
                                            color: AppTheme.textSecondary,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: "View Details",
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
      "Drilling Fluid Additive",
      "Barite Powder",
      "Bentonite Clay",
      "Calcium Chloride",
      "Polymer Viscosifier",
      "Defoamer Chemical",
      "Lubricant Additive",
      "Shale Inhibitor",
      "Weighting Material",
      "Filtration Control Agent",
      "Emulsifier",
      "Corrosion Inhibitor",
      "Biocide",
      "pH Control Agent",
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

  String _getStaticCode(int index) {
    return "PROD-${(index + 1).toString().padLeft(3, '0')}";
  }

  String _getStaticUnit(int index) {
    final units = ["Pcs", "Kg", "L", "Bbl", "Ton", "Bag", "Drum", "Ctn"];
    return units[index % units.length];
  }

  String _getStaticAmount(int index) {
    final amount = (100 + (index * 250)).toDouble();
    return "\$${amount.toStringAsFixed(2)}";
  }

  Widget _buildStaticCode(int index) {
    return Text(
      _getStaticCode(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildStaticUnit(int index) {
    return Text(
      _getStaticUnit(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildStaticAmount(int index) {
    return Text(
      _getStaticAmount(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Editable cells
  Widget _buildEditableProductCell(int index) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: TextEditingController(text: _getStaticProduct(index)),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "Enter product...",
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

  Widget _buildEditableCodeCell(int index) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: TextEditingController(text: _getStaticCode(index)),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: "Code...",
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

  Widget _buildEditableUnitCell(int index) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: TextEditingController(text: _getStaticUnit(index)),
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

  Widget _buildEditableAmountCell(int index) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: TextEditingController(text: _getStaticAmount(index)),
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
                  "Package Details (5 Items)",
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
                    "Total: \$12,450.00",
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
            height: 300,
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
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppTheme.errorColor,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: "Remove",
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.visibility_outlined,
                                            size: 18,
                                            color: AppTheme.textSecondary,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: "View Details",
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
      "Drilling Fluid Kit",
      "Chemical Additives Pack",
      "Maintenance Package",
      "Safety Equipment Set",
      "Emergency Response Kit"
    ];
    return packages[index];
  }

  String _getStaticPackageCode(int index) {
    return "PKG-${(index + 1).toString().padLeft(3, '0')}";
  }

  String _getStaticPackageUnit(int index) {
    final units = ["Kit", "Set", "Pack", "Box", "Pallet"];
    return units[index];
  }

  String _getStaticPackageAmount(int index) {
    final amount = (1000 + (index * 500)).toDouble();
    return "\$${amount.toStringAsFixed(2)}";
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

  Widget _buildStaticPackageCode(int index) {
    return Text(
      _getStaticPackageCode(index),
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: AppTheme.textPrimary,
      ),
    );
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
          hintText: "Enter package...",
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
          hintText: "Code...",
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

  // ================= SUMMARY FOOTER =================
  Widget _buildSummaryFooter() {
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
            "Receiving Summary",
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              _buildSummaryCard(
                title: "Total Products",
                value: "15 Items",
                color: AppTheme.primaryColor,
                icon: Icons.inventory_2_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Total Packages",
                value: "5 Items",
                color: AppTheme.successColor,
                icon: Icons.account_box_outlined,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Product Value",
                value: "\$45,280.50",
                color: AppTheme.warningColor,
                icon: Icons.attach_money_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Package Value",
                value: "\$12,450.00",
                color: AppTheme.infoColor,
                icon: Icons.shopping_bag_rounded,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: Container(
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Grand Total Value",
                            style: AppTheme.caption.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "\$57,730.50",
                            style: AppTheme.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.summarize_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    Obx(() => ElevatedButton(
                      onPressed: dashboardController.isLocked.value ? null : () {
                        // Save action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_alt_rounded, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            "Save Receipt",
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 12),
                    Obx(() => ElevatedButton(
                      onPressed: dashboardController.isLocked.value ? null : () {
                        // Print action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.print_rounded, size: 18, color: AppTheme.textPrimary),
                          const SizedBox(width: 10),
                          Text(
                            "Print Receipt",
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
              ),
            ],
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