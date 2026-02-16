import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AddWaterView extends StatelessWidget {
  AddWaterView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  
  final RxList<TextEditingController> volControllers =
      List.generate(4, (_) => TextEditingController()).obs;

  final List<String> toOptions = [
    "Active System",
    "Storage Tank",
    "Trip Tank",
    "Reserve Pit 1",
    "Reserve Pit 2",
    "Suction Pit 4A",
    "Suction Pit 4B",
    "Mixing Pit",
    "Discharge Pit"
  ];

  final RxString selectedTo = "Active System".obs;
  final RxDouble totalVolume = 0.0.obs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= ENHANCED HEADER =================
            // _buildHeader(),

            // const SizedBox(height: 20),

            // ================= ENHANCED WATER ADDITION SECTION =================
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 800),
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
                  // Section Header
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
                            Icons.water_drop_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Water Addition Details",
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
                          child: Obx(() => Text(
                            "Total: ${totalVolume.value.toStringAsFixed(2)} bbl",
                            style: AppTheme.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),

                  // Enhanced Table
                  _buildEnhancedTable(),

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
                              "Add water volumes in barrels (bbl)",
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Obx(() => ElevatedButton(
                          onPressed: dashboardController.isLocked.value 
                              ? null 
                              : () {
                                  // Add new row
                                  volControllers.add(TextEditingController());
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.infoColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Add Volume Row",
                                style: AppTheme.caption.copyWith(
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
            ),

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
            AppTheme.primaryColor,
            AppTheme.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor,
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
              Icons.water_rounded,
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
                  "Add Water",
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Manage water addition to different system components with volume tracking",
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
                  "Active Rows",
                  style: AppTheme.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  "${volControllers.length} Rows",
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ENHANCED TABLE =================
  Widget _buildEnhancedTable() {
    return Column(
      children: [
        // -------- ROW 1: DESTINATION --------
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // Left Column: Label
              _buildEnhancedCell(
                width: 200,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        "Destination",
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

              // Right Column: Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Obx(() => Container(
                    height: 44,
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
                          width: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.infoColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: AppTheme.infoColor,
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedTo.value,
                              icon: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              onChanged: dashboardController.isLocked.value
                                  ? null
                                  : (v) {
                                      if (v != null) {
                                        selectedTo.value = v;
                                      }
                                    },
                              items: toOptions.map((option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      option,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ),
              ),
            ],
          ),
        ),

        // -------- ROW 2: VOLUME HEADER --------
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // Left Column: Volume Label
              _buildEnhancedCell(
                width: 200,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        "Volume (bbl)",
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

              // Right Column: Empty Header
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade200),
                    ),
                    color: Colors.grey.shade50,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Enter volume values",
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // -------- VOLUME INPUT ROWS --------
        Obx(() => Column(
          children: List.generate(volControllers.length, (index) {
            return Container(
              height: 60,
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                border: Border(
                  bottom: index == volControllers.length - 1
                      ? BorderSide.none
                      : BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  // Left Column: Row Number
                  _buildEnhancedCell(
                    width: 200,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.infoColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.infoColor.withOpacity(0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (index + 1).toString(),
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.infoColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "Volume ${index + 1}",
                            style: AppTheme.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Column: Volume Input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: dashboardController.isLocked.value 
                                  ? Colors.grey.shade100 
                                  : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextField(
                                controller: volControllers[index],
                                enabled: !dashboardController.isLocked.value,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  hintText: "Enter volume...",
                                  hintStyle: AppTheme.caption.copyWith(
                                    color: Colors.grey.shade400,
                                  ),
                                  suffixText: "bbl",
                                  suffixStyle: AppTheme.caption.copyWith(
                                    color: AppTheme.infoColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (value) {
                                  // Update total volume
                                  _updateTotalVolume();
                                  
                                  // Add new row if this is the last row and has value
                                  if (index == volControllers.length - 1 && 
                                      value.isNotEmpty && 
                                      !dashboardController.isLocked.value) {
                                    volControllers.add(TextEditingController());
                                  }
                                },
                              ),
                            ),
                          ),
                          
                          if (!dashboardController.isLocked.value && index > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 12),
                              child: IconButton(
                                onPressed: () {
                                  if (volControllers.length > 1) {
                                    volControllers.removeAt(index);
                                    _updateTotalVolume();
                                  }
                                },
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppTheme.errorColor,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: "Remove this volume",
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        )),
      ],
    );
  }

  void _updateTotalVolume() {
    double total = 0.0;
    for (var controller in volControllers) {
      try {
        final value = double.tryParse(controller.text) ?? 0.0;
        total += value;
      } catch (e) {
        // Ignore parsing errors
      }
    }
    totalVolume.value = total;
  }

  Widget _buildEnhancedCell({required double width, required Widget child}) {
    return SizedBox(
      width: width,
      child: child,
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
            "Water Addition Summary",
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              _buildSummaryCard(
                title: "Destination",
                value: selectedTo.value,
                color: AppTheme.primaryColor,
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Total Volume",
                value: "${totalVolume.value.toStringAsFixed(2)} bbl",
                color: AppTheme.infoColor,
                icon: Icons.water_drop_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Volume Rows",
                value: "${volControllers.length} Rows",
                color: AppTheme.successColor,
                icon: Icons.format_list_numbered_rounded,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                title: "Average per Row",
                value: volControllers.length > 1 
                    ? "${(totalVolume.value / volControllers.length).toStringAsFixed(2)} bbl"
                    : "0.00 bbl",
                color: AppTheme.warningColor,
                icon: Icons.calculate_rounded,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.infoColor.withOpacity(0.9),
                  AppTheme.infoColor,
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
                      "Ready to Add Water",
                      style: AppTheme.caption.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      "${totalVolume.value.toStringAsFixed(2)} bbl to ${selectedTo.value}",
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    )),
                  ],
                ),
                Row(
                  children: [
                    Obx(() => ElevatedButton(
                      onPressed: dashboardController.isLocked.value || totalVolume.value <= 0 
                          ? null 
                          : () {
                              // Confirm and add water
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.infoColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            "Confirm Addition",
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
                        // Clear all inputs
                        for (var controller in volControllers) {
                          controller.clear();
                        }
                        volControllers.value = [TextEditingController()];
                        totalVolume.value = 0.0;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.clear_all_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Clear All",
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
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
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