import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class TransferMudView extends StatelessWidget {
  TransferMudView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  
  // Sample data for transfer table
  final List<Map<String, String>> transferData = [
    {"pit": "Active System", "volume": "200.00", "status": "Active"},
    {"pit": "Reserve Pit 1", "volume": "150.50", "status": "Available"},
    {"pit": "Reserve Pit 2", "volume": "85.25", "status": "Available"},
    {"pit": "Suction Pit 4A", "volume": "320.75", "status": "Source"},
    {"pit": "Suction Pit 4B", "volume": "180.00", "status": "Source"},
    {"pit": "Mixing Pit", "volume": "95.50", "status": "Processing"},
    {"pit": "Discharge Pit", "volume": "45.25", "status": "Target"},
    {"pit": "Emergency Pit", "volume": "0.00", "status": "Empty"},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- ENHANCED HEADER ----------------
            // _buildHeader(),

            // const SizedBox(height: 20),

            // ---------------- ENHANCED FROM SECTION ----------------
            _buildSourceSection(),

            const SizedBox(height: 20),

            // ---------------- ENHANCED CHECKBOX ----------------
            _buildMudTypeSection(),

            const SizedBox(height: 20),

            // ---------------- ENHANCED TABLE ----------------
            _buildEnhancedTransferTable(),

            const SizedBox(height: 24),

            // ---------------- SUMMARY SECTION ----------------
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
              Icons.swap_horiz_rounded,
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
                  "Transfer Mud",
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Manage mud transfers between pits with volume tracking",
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
                  "1,077.25 bbl",
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

  // ================= ENHANCED SOURCE SECTION =================
  Widget _buildSourceSection() {
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
                  Icons.location_on_rounded,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Transfer Source",
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Source Pit",
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
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: "Suction 4A",
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onChanged: dashboardController.isLocked.value ? null : (_) {},
                          items: const [
                            DropdownMenuItem(
                              value: "Suction 4A",
                              child: Text("Suction Pit 4A"),
                            ),
                            DropdownMenuItem(
                              value: "Suction 4B",
                              child: Text("Suction Pit 4B"),
                            ),
                            DropdownMenuItem(
                              value: "Reserve 1",
                              child: Text("Reserve Pit 1"),
                            ),
                            DropdownMenuItem(
                              value: "Reserve 2",
                              child: Text("Reserve Pit 2"),
                            ),
                            DropdownMenuItem(
                              value: "Active System",
                              child: Text("Active System"),
                            ),
                          ].map((item) {
                            return DropdownMenuItem<String>(
                              value: item.value,
                              child: item.child,
                            );
                          }).toList(),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Advanced Options Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24), // Align with dropdown label
                  Obx(() => ElevatedButton(
                    onPressed: dashboardController.isLocked.value ? null : () {
                      // Show advanced options
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cardColor,
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Advanced Options",
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
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
                  "Select the source pit for mud transfer. Use Advanced Options for flow rate and pressure settings.",
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

  // ================= ENHANCED MUD TYPE SECTION =================
  Widget _buildMudTypeSection() {
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
                  Icons.science_rounded,
                  size: 20,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Mud Treatment Status",
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: dashboardController.isLocked.value 
                ? Colors.grey.shade50 
                : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
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
                const SizedBox(width: 12),
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Not Treated Mud",
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Warning",
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Text(
            "Untreated mud may contain solids and require additional processing before transfer.",
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ================= ENHANCED TRANSFER TABLE =================
  Widget _buildEnhancedTransferTable() {
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
                  "Transfer Targets (${transferData.length} Pits)",
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
                    "Total: 1,077.25 bbl",
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
                    columns: const [
                      DataColumn(label: Text("No.")),
                      DataColumn(label: Text("Pit")),
                      DataColumn(label: Text("Volume (bbl)")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: List.generate(
                      transferData.length,
                      (index) => DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            return index % 2 == 0
                                ? Colors.white
                                : Colors.grey.shade50;
                          },
                        ),
                        cells: [
                          // No. Column
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                (index + 1).toString(),
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          // Pit Column
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                transferData[index]["pit"]!,
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          
                          // Volume Column
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerRight,
                              child: dashboardController.isLocked.value
                                  ? Text(
                                      transferData[index]["volume"]!,
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : SizedBox(
                                      width: 120,
                                      child: TextField(
                                        controller: TextEditingController(
                                          text: transferData[index]["volume"]!,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          hintText: "0.00",
                                          hintStyle: AppTheme.caption.copyWith(
                                            color: Colors.grey.shade400,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                          suffixText: "bbl",
                                          suffixStyle: AppTheme.caption.copyWith(
                                            color: AppTheme.textSecondary,
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
                                    ),
                            ),
                          ),
                          
                          // Status Column
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: _buildStatusIndicator(transferData[index]["status"]!),
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
                                        Icons.edit_rounded,
                                        size: 18,
                                        color: AppTheme.primaryColor,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: "Edit Volume",
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.visibility_rounded,
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
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case "active":
        color = Colors.green;
        icon = Icons.play_arrow_rounded;
        break;
      case "available":
        color = Colors.blue;
        icon = Icons.check_circle_rounded;
        break;
      case "source":
        color = Colors.orange;
        icon = Icons.location_on_rounded;
        break;
      case "processing":
        color = Colors.purple;
        icon = Icons.autorenew_rounded;
        break;
      case "target":
        color = Colors.teal;
        icon = Icons.flag_rounded;
        break;
      case "empty":
        color = Colors.grey;
        icon = Icons.close_rounded;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: AppTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================= SUMMARY SECTION =================
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
            "Transfer Summary",
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              _buildSummaryCard(
                title: "Total Volume",
                value: "1,077.25 bbl",
                color: AppTheme.primaryColor,
                icon: Icons.water_drop_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Active Pits",
                value: "3 Pits",
                color: AppTheme.successColor,
                icon: Icons.play_arrow_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Transfer Rate",
                value: "150 bbl/hr",
                color: AppTheme.infoColor,
                icon: Icons.speed_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Estimated Time",
                value: "7.2 hrs",
                color: AppTheme.warningColor,
                icon: Icons.timer_rounded,
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
                            "Transfer Status",
                            style: AppTheme.caption.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ready to Transfer",
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
                        child: Icon(
                          Icons.swap_horiz_rounded,
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
                        // Start transfer action
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
                          Icon(Icons.play_arrow_rounded, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            "Start Transfer",
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
                        // Stop transfer action
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
                          Icon(Icons.stop_rounded, size: 18, color: AppTheme.textPrimary),
                          const SizedBox(width: 10),
                          Text(
                            "Stop Transfer",
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