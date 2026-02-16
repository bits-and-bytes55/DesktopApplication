import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import '../../controller/operation_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReceiveMudView extends StatelessWidget {
  ReceiveMudView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  final ScrollController scrollController = ScrollController();

  final List<Map<String, String>> rows = const [
    {"label": "Premixed Mud", "unit": "", "value": "Yes", "color": "primary"},
    {"label": "MW", "unit": "(ppg)", "value": "12.5", "color": "warning"},
    {"label": "Mud Type", "unit": "", "value": "Water Based", "color": "primary"},
    {"label": "Leasing Fee", "unit": "(kwd/bbl)", "value": "45.25", "color": "warning"},
    {"label": "From", "unit": "", "value": "Supplier A", "color": "primary"},
    {"label": "To", "unit": "", "value": "Active System", "color": "primary"},
    {"label": "Volume", "unit": "(bbl)", "value": "250.75", "color": "primary"},
    {"label": "Leased", "unit": "", "value": "true", "color": "success"},
  ];

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

            // ================= ENHANCED TABLE =================
            _buildEnhancedTable(),

            const SizedBox(height: 24),

            // ================= ENHANCED LOSS VOLUME SECTION =================
            _buildLossVolumeSection(),

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
              Icons.water_damage_rounded,
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
                  "Receive Mud",
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Record incoming mud shipments with detailed specifications",
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
                  "Total Volume",
                  style: AppTheme.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "250.75 bbl",
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
                  width: 100,
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
                    controller: TextEditingController(text: "MUD-BOL-2024-00123"),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      hintText: "Enter mud shipment BOL number...",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
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
                "Enter the Bill of Lading number associated with the mud shipment",
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

  // ================= ENHANCED TABLE =================
  Widget _buildEnhancedTable() {
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
                  "Mud Specifications",
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
                    "8 Parameters",
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
          Obx(() => DataTable(
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
            headingRowHeight: 0,
            dataRowHeight: 60,
            columns: const [
              DataColumn(label: Text("Parameter")),
              DataColumn(label: Text("Value")),
              DataColumn(label: Text("Unit")),
            ],
            rows: rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              
              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    return index % 2 == 0
                        ? Colors.white
                        : Colors.grey.shade50;
                  },
                ),
                cells: [
                  // Parameter Column
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getColorForRow(row["color"]!),
                            ),
                          ),
                          Text(
                            row["label"]!,
                            style: AppTheme.bodySmall.copyWith(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Value Column
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: row["label"] == "Leased"
                          ? _buildLeasedCheckbox()
                          : _buildEditableCell(row["value"]!, row["color"]!),
                    ),
                  ),
                  
                  // Unit Column
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        row["unit"]!,
                        style: AppTheme.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontStyle: row["unit"]!.isNotEmpty 
                              ? FontStyle.normal 
                              : FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          )),
        ],
      ),
    );
  }

  Color _getColorForRow(String colorType) {
    switch (colorType) {
      case "primary":
        return AppTheme.primaryColor;
      case "warning":
        return AppTheme.warningColor;
      case "success":
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildEditableCell(String value, String colorType) {
    final isEditable = !dashboardController.isLocked.value;
    final color = _getColorForRow(colorType);
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorType == "warning" ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: colorType == "warning" 
            ? Border.all(color: color.withOpacity(0.3))
            : null,
      ),
      child: isEditable
          ? TextField(
              controller: TextEditingController(text: value),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                hintText: "Enter value...",
                hintStyle: AppTheme.caption.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 12,
                color: colorType == "warning" ? color : AppTheme.textPrimary,
                fontWeight: colorType == "warning" ? FontWeight.w600 : FontWeight.w500,
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                value,
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 12,
                  color: colorType == "warning" ? color : AppTheme.textPrimary,
                  fontWeight: colorType == "warning" ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
    );
  }

  Widget _buildLeasedCheckbox() {
    return Obx(() => Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: true,
            activeColor: AppTheme.successColor,
            onChanged: dashboardController.isLocked.value ? null : (_) {},
          ),
          Text(
            "Yes",
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ));
  }

  // ================= ENHANCED LOSS VOLUME SECTION =================
  Widget _buildLossVolumeSection() {
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
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Loss Volume Tracking",
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => Container(
            padding: const EdgeInsets.all(16),
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
                Obx(() => InkWell(
                  onTap: dashboardController.isLocked.value ? null : () {
                    // Toggle checkbox
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: false ? AppTheme.warningColor : Colors.grey.shade400,
                        width: false ? 1.5 : 1,
                      ),
                      color: false ? AppTheme.warningColor.withOpacity(0.1) : Colors.transparent,
                    ),
                    child: false
                        ? Icon(Icons.check, size: 16, color: AppTheme.warningColor)
                        : null,
                  ),
                )),
                const SizedBox(width: 16),
                
                // Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Loss Volume",
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Track mud loss during transfer process",
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Volume Input
                SizedBox(
                  width: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          enabled: !dashboardController.isLocked.value,
                          controller: TextEditingController(text: "12.5"),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            hintText: "Enter volume...",
                            hintStyle: AppTheme.caption.copyWith(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                          border: Border(
                            left: BorderSide(color: Colors.grey.shade300),
                            top: BorderSide(color: Colors.grey.shade300),
                            right: BorderSide(color: Colors.grey.shade300),
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "bbl",
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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
              Expanded(
                child: Text(
                  "Enable to track mud loss volume during the receiving process. This helps in accurate inventory management.",
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
                title: "Mud Volume",
                value: "250.75 bbl",
                color: AppTheme.primaryColor,
                icon: Icons.water_damage_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Mud Weight",
                value: "12.5 ppg",
                color: AppTheme.warningColor,
                icon: Icons.scale_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Leasing Fee",
                value: "45.25 kwd/bbl",
                color: AppTheme.successColor,
                icon: Icons.attach_money_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Total Cost",
                value: "11,345.25 kwd",
                color: AppTheme.infoColor,
                icon: Icons.account_balance_wallet_rounded,
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
                            "Ready for Receiving",
                            style: AppTheme.caption.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Status: Verified",
                            style: AppTheme.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
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
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 24,
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
                        // Receive mud action
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
                          Icon(Icons.check_circle_rounded, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            "Receive Mud",
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
                        // Save as draft action
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
                          Icon(Icons.save_alt_rounded, size: 18, color: AppTheme.textPrimary),
                          const SizedBox(width: 10),
                          Text(
                            "Save as Draft",
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