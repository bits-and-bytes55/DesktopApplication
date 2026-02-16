import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ConsumeServicesView extends StatelessWidget {
  ConsumeServicesView({super.key});

  final dashboardController = Get.find<DashboardController>();
  final RxString selectedMethod = "Used".obs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= COMPACT RADIO BUTTONS =================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    SizedBox(
                      height: 32,
                      child: Row(
                        children: [
                          buildCompactRadio("Used", Icons.trending_up_rounded, "Used"),
                          const SizedBox(width: 12),
                          buildCompactRadio("Final", Icons.flag_rounded, "Final"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              /// ================= PACKAGE TABLE (20 ROWS, SHOW 5) =================
              _buildCompactTableCard(
                title: "Package",
                icon: Icons.inventory_2_rounded,
                headers: [
                  "Package",
                  "Code",
                  "Unit",
                  "Price (\$)",
                  "Initial",
                  "Used",
                  "Final",
                  "Cost (\$)",
                ],
                color: AppTheme.primaryColor,
                totalRowCount: 20, // Total 20 rows
                visibleRowCount: 5, // Show only 5 at a time
                dropdownOptions: [
                  "Basic Package",
                  "Premium Package",
                  "Standard Package",
                  "Enterprise Package",
                  "Custom Package"
                ],
              ),

              const SizedBox(height: 16),

              /// ================= SERVICES TABLE (20 ROWS, SHOW 5) =================
              _buildCompactTableCard(
                title: "Services",
                icon: Icons.build_circle_rounded,
                headers: [
                  "Services",
                  "Code",
                  "Unit",
                  "Price (\$)",
                  "Usage",
                  "Cost (\$)",
                ],
                color: AppTheme.successColor,
                totalRowCount: 20, // Total 20 rows
                visibleRowCount: 5, // Show only 5 at a time
                dropdownOptions: [
                  "Standard Service",
                  "Premium Service",
                  "24/7 Support",
                  "Maintenance",
                  "Consulting"
                ],
              ),

              const SizedBox(height: 16),

              /// ================= ENGINEERING TABLE (20 ROWS, SHOW 5) =================
              _buildCompactTableCard(
                title: "Engineering",
                icon: Icons.engineering_rounded,
                headers: [
                  "Engineering",
                  "Code",
                  "Unit",
                  "Price (\$)",
                  "Usage",
                  "Cost (\$)",
                ],
                color: AppTheme.infoColor,
                totalRowCount: 20, // Total 20 rows
                visibleRowCount: 5, // Show only 5 at a time
                dropdownOptions: [
                  "Engineering Service",
                  "Technical Support",
                  "System Design",
                  "Development",
                  "Testing"
                ],
              ),

              /// ================= FOOTER SUMMARY =================
              const SizedBox(height: 20),
              _buildFooterSummary(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCompactRadio(String label, IconData icon, String value) {
    return Obx(() => InkWell(
      onTap: dashboardController.isLocked.value 
          ? null 
          : () => selectedMethod.value = value,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selectedMethod.value == value
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selectedMethod.value == value
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 6),
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
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            Icon(
              icon,
              size: 14,
              color: selectedMethod.value == value
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 12,
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

  // ----------------- COMPACT TABLE CARD -----------------
  Widget _buildCompactTableCard({
    required String title,
    required IconData icon,
    required List<String> headers,
    required Color color,
    required int totalRowCount, // Total rows in table
    required int visibleRowCount, // Rows visible at once
    required List<String> dropdownOptions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TABLE HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
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
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$totalRowCount Rows",
                    style: AppTheme.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// SCROLLABLE TABLE CONTENT (SHOWS 5 ROWS AT A TIME)
          SizedBox(
            height: 260, // Height for 5 rows + header
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: headers.length * 110, // Dynamic width based on columns
                  child: Column(
                    children: [
                      /// HEADER ROW
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.06),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: headers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final header = entry.value;
                            final isPriceColumn = header.contains('\$');
                            
                            return Container(
                              width: _getColumnWidth(index, headers.length),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              alignment: isPriceColumn 
                                  ? Alignment.centerRight 
                                  : Alignment.centerLeft,
                              child: Text(
                                header,
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                  letterSpacing: 0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      /// DATA ROWS (SHOW 5 VISIBLE ROWS, BUT TABLE HAS 20)
                      ...List.generate(visibleRowCount, (rowIndex) {
                        return Container(
                          height: 44, // Row height
                          decoration: BoxDecoration(
                            color: rowIndex % 2 == 0 
                                ? Colors.white 
                                : Colors.grey.shade50.withOpacity(0.5),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade100,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: headers.asMap().entries.map((entry) {
                              final columnIndex = entry.key;
                              final isFirstColumn = columnIndex == 0;
                              final isLastColumn = columnIndex == headers.length - 1;
                              
                              return Container(
                                width: _getColumnWidth(columnIndex, headers.length),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                alignment: _getColumnAlignment(columnIndex, headers),
                                child: isFirstColumn
                                    ? _buildSimpleDropdown(dropdownOptions, rowIndex, color)
                                    : _buildEmptyCell(
                                        columnIndex, 
                                        headers, 
                                        color, 
                                        isLastColumn,
                                      ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// TABLE FOOTER WITH SCROLL INFO
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing $visibleRowCount of $totalRowCount rows",
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    "Scroll to see more",
                    style: AppTheme.caption.copyWith(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- SIMPLE DROPDOWN (NO BORDER) -----------------
  Widget _buildSimpleDropdown(List<String> options, int rowIndex, Color color) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: options[rowIndex % options.length],
        icon: Icon(Icons.arrow_drop_down, size: 20, color: color),
        iconSize: 16,
        elevation: 0,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        isExpanded: true,
        isDense: true,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                color: AppTheme.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: dashboardController.isLocked.value 
            ? null 
            : (String? newValue) {
                // Handle dropdown change
              },
      ),
    );
  }

  // ----------------- EMPTY CELL (NO BORDERS, NO DATA) -----------------
  Widget _buildEmptyCell(
    int columnIndex, 
    List<String> headers, 
    Color color,
    bool isLastColumn,
  ) {
    final isPriceColumn = headers[columnIndex].contains('\$');
    
    return Text(
      "", // Empty text
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: isLastColumn ? color : AppTheme.textSecondary,
        fontWeight: isLastColumn ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  // ----------------- GET COLUMN WIDTH -----------------
  double _getColumnWidth(int index, int totalColumns) {
    if (index == 0) return 140; // Name column with dropdown
    if (index == 1) return 80;  // Code column
    if (index == 2) return 70;  // Unit column
    if (index == totalColumns - 1) return 100; // Cost column
    return 90; // Other columns
  }

  // ----------------- GET COLUMN ALIGNMENT -----------------
  Alignment _getColumnAlignment(int index, List<String> headers) {
    final header = headers[index];
    final isPriceColumn = header.contains('\$');
    
    if (index == 0) return Alignment.centerLeft;
    if (isPriceColumn) return Alignment.centerRight;
    return Alignment.centerLeft;
  }

  // ----------------- FOOTER SUMMARY -----------------
  Widget _buildFooterSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem(
            icon: Icons.summarize_rounded,
            title: "Total Records",
            value: "60 Items", // 20 × 3 tables
            color: AppTheme.successColor,
          ),
          _buildSummaryItem(
            icon: Icons.monetization_on_rounded,
            title: "Package Cost",
            value: "\$0.00",
            color: AppTheme.primaryColor,
          ),
          _buildSummaryItem(
            icon: Icons.handyman_rounded,
            title: "Services Cost",
            value: "\$0.00",
            color: AppTheme.successColor,
          ),
          _buildSummaryItem(
            icon: Icons.engineering_rounded,
            title: "Engineering Cost",
            value: "\$0.00",
            color: AppTheme.infoColor,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Grand Total",
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.primaryColor.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "\$0.00",
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- SUMMARY ITEM -----------------
  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}