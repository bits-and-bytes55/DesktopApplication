import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudLossActiveSystemView extends StatelessWidget {
  MudLossActiveSystemView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  final ScrollController scrollController = ScrollController();

  final List<String> lossTypes = const [
    "Cuttings / Retention",
    "Seepage",
    "Dump",
    "Shakers",
    "Centrifuge",
    "Evaporation",
    "Pit Cleaning",
    "Formation",
    "Abandon in Hole",
    "Left behind Casing",
    "Tripping",
    "Other Loss 1",
    "Other Loss 2",
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

            // ================= MAIN CONTENT =================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= ENHANCED LOSS TABLE =================
                Expanded(
                  child: _buildEnhancedLossTable(),
                ),

                const SizedBox(width: 20),

                // ================= ENHANCED ACTION BUTTONS =================
                _buildEnhancedActionButtons(),
              ],
            ),

            // ================= SUMMARY SECTION =================
            const SizedBox(height: 24),
            _buildSummarySection(),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // ENHANCED HEADER
  // ===================================================
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
                  "Mud Loss - Active System",
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Track and manage mud loss volumes across different categories",
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
                  "Total Loss Volume",
                  style: AppTheme.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "2,845.50 bbl",
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

  // ===================================================
  // ENHANCED LOSS TABLE
  // ===================================================
  Widget _buildEnhancedLossTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  "Mud Loss Categories",
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
                    "${lossTypes.length} Items",
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
            height: 500, // Fixed height for scrolling
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
                    headingRowHeight: 45,
                    dataRowHeight: 48,
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
                      DataColumn(
                        label: Text("No."),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text("Loss Type"),
                      ),
                      DataColumn(
                        label: Text("Volume (bbl)"),
                        numeric: true,
                      ),
                    ],
                    rows: List.generate(
                      lossTypes.length,
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
                          
                          // Loss Type Column
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                lossTypes[index],
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
                                  ? _buildStaticVolume(index)
                                  : _buildEditableVolumeCell(index),
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

          // Table Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${lossTypes.length} categories",
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Enter volume in barrels (bbl)",
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticVolume(int index) {
    // Sample volumes for each loss type
    final sampleVolumes = [
      1250.50,  // Cuttings / Retention
      480.25,   // Seepage
      320.75,   // Dump
      195.00,   // Shakers
      85.50,    // Centrifuge
      42.25,    // Evaporation
      180.75,   // Pit Cleaning
      95.25,    // Formation
      0.00,     // Abandon in Hole
      0.00,     // Left behind Casing
      125.50,   // Tripping
      50.00,    // Other Loss 1
      25.00,    // Other Loss 2
    ];
    
    return Text(
      sampleVolumes[index] > 0 ? "${sampleVolumes[index].toStringAsFixed(2)}" : "-",
      style: AppTheme.bodySmall.copyWith(
        fontSize: 11,
        color: sampleVolumes[index] > 0 ? AppTheme.textPrimary : Colors.grey.shade400,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEditableVolumeCell(int index) {
    final sampleVolumes = [
      1250.50, 480.25, 320.75, 195.00, 85.50, 42.25, 
      180.75, 95.25, 0.00, 0.00, 125.50, 50.00, 25.00
    ];
    
    return SizedBox(
      width: 120,
      child: TextField(
        controller: TextEditingController(
          text: sampleVolumes[index] > 0 ? sampleVolumes[index].toStringAsFixed(2) : "",
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
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.right,
        keyboardType: TextInputType.number,
      ),
    );
  }

  // ===================================================
  // ENHANCED ACTION BUTTONS
  // ===================================================
  Widget _buildEnhancedActionButtons() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Actions",
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildActionButton(
            icon: Icons.help_outline_rounded,
            title: "Help & Guide",
            subtitle: "View documentation",
            color: AppTheme.infoColor,
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildActionButton(
            icon: Icons.calculate_rounded,
            title: "Calculations",
            subtitle: "Perform calculations",
            color: AppTheme.successColor,
            onTap: () {
              // TODO: Navigate to calculation page
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildActionButton(
            icon: Icons.open_in_new_rounded,
            title: "Open Details",
            subtitle: "View detailed report",
            color: AppTheme.primaryColor,
            onTap: () {
              // TODO: Navigate to details page
            },
          ),
          
          const SizedBox(height: 24),
          
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
          
          const SizedBox(height: 20),
          
          // Quick Actions
          Column(
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
              Row(
                children: [
                  _buildSmallButton(
                    icon: Icons.download_rounded,
                    label: "Export",
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildSmallButton(
                    icon: Icons.print_rounded,
                    label: "Print",
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildSmallButton(
                    icon: Icons.refresh_rounded,
                    label: "Refresh",
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Obx(() => InkWell(
      onTap: dashboardController.isLocked.value ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Obx(() => Expanded(
      child: InkWell(
        onTap: dashboardController.isLocked.value ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  // ===================================================
  // SUMMARY SECTION
  // ===================================================
  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Volume Summary",
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildSummaryCard(
                title: "Total Loss",
                value: "2,845.50 bbl",
                color: AppTheme.primaryColor,
                icon: Icons.water_damage_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Average per Day",
                value: "125.75 bbl",
                color: AppTheme.successColor,
                icon: Icons.trending_up_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Highest Loss",
                value: "Cuttings/Retention",
                subValue: "1,250.50 bbl",
                color: AppTheme.warningColor,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Controlled Loss",
                value: "8 Categories",
                color: AppTheme.infoColor,
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
              onPressed: dashboardController.isLocked.value ? null : () {
                // Save changes
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
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
                    "Save All Changes",
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    String? subValue,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTheme.titleMedium.copyWith(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subValue != null) ...[
              const SizedBox(height: 4),
              Text(
                subValue,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}