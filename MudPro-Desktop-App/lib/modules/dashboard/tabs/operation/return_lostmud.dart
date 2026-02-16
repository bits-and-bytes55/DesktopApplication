import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReturnLostMudView extends StatelessWidget {
  ReturnLostMudView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  final ScrollController scrollController = ScrollController();

  final List<String> pitOptions = [
    "Active System",
    "Intermediate 2C",
    "Suction 4A",
    "Suction 4B",
    "Reserve 5B",
    "Reserve 6A",
  ];

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

            // ================= ENHANCED PREMIXED MUD SECTION =================
            _buildPremixedMudSection(),

            const SizedBox(height: 20),

            // ================= ENHANCED TABLE =================
            _buildEnhancedTable(),
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
              Icons.replay_circle_filled_rounded,
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
                  "Return / Lost Mud",
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Track mud returns and losses with detailed specifications",
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
                  "Active Fields",
                  style: AppTheme.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "10 Fields",
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

  // ================= ENHANCED PREMIXED MUD SECTION =================
  Widget _buildPremixedMudSection() {
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
                  Icons.rocket_rounded,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Premixed Mud Configuration",
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
              Obx(() => InkWell(
                onTap: dashboardController.isLocked.value ? null : () {
                  controller.premixedMud.value = !controller.premixedMud.value;
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: controller.premixedMud.value
                          ? AppTheme.primaryColor
                          : Colors.grey.shade400,
                      width: controller.premixedMud.value ? 1.5 : 1,
                    ),
                    color: controller.premixedMud.value
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: controller.premixedMud.value
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                ),
              )),
              const SizedBox(width: 12),
              Text(
                "Premixed Mud",
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
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
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      hintText: "Enter mud details...",
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
                  "Return/Lost Mud Details",
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
                    "10 Fields",
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
            height: 450,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 800,
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
                      headingRowHeight: 40,
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
                      columnSpacing: 15,
                      columns: const [
                        DataColumn(
                          label: Text("Field"),
                        ),
                        DataColumn(
                          label: Text("Value"),
                        ),
                        DataColumn(
                          label: Text("Unit"),
                        ),
                      ],
                      rows: List.generate(10, (index) {
                        // LAST ROW = LEASED CHECKBOX
                        if (index == 9) {
                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                                return Colors.grey.shade50;
                              },
                            ),
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "Leased",
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Obx(() => InkWell(
                                        onTap: dashboardController.isLocked.value ? null : () {
                                          controller.leased.value = !controller.leased.value;
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: controller.leased.value
                                                  ? AppTheme.successColor
                                                  : Colors.grey.shade400,
                                              width: controller.leased.value ? 1.5 : 1,
                                            ),
                                            color: controller.leased.value
                                                ? AppTheme.successColor.withOpacity(0.1)
                                                : Colors.transparent,
                                          ),
                                          child: controller.leased.value
                                              ? Icon(
                                                  Icons.check_rounded,
                                                  size: 16,
                                                  color: AppTheme.successColor,
                                                )
                                              : null,
                                        ),
                                      )),
                                      const SizedBox(width: 12),
                                      Text(
                                        controller.leased.value ? "Yes" : "No",
                                        style: AppTheme.bodySmall.copyWith(
                                          fontSize: 11,
                                          color: controller.leased.value
                                              ? AppTheme.successColor
                                              : AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const DataCell(
                                SizedBox.shrink(),
                              ),
                            ],
                          );
                        }

                        final isDropdown = controller.returnLostDropdownIndex[index];
                        final fieldLabel = controller.returnLostLabels[index];
                        final unit = controller.returnLostUnits[index];
                        final isFromField = fieldLabel.toLowerCase().contains("from");

                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              return index % 2 == 0
                                  ? Colors.white
                                  : Colors.grey.shade50;
                            },
                          ),
                          cells: [
                            // Field Column
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
                                        color: isDropdown
                                            ? AppTheme.primaryColor
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      fieldLabel,
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
                                child: isDropdown
                                    ? Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: dashboardController.isLocked.value
                                            ? Colors.grey.shade50
                                            : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            isExpanded: true,
                                            value: controller.returnLostDropdownValue[index],
                                            icon: Padding(
                                              padding: const EdgeInsets.only(right: 12),
                                              child: Icon(
                                                Icons.arrow_drop_down_rounded,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            style: AppTheme.bodySmall.copyWith(
                                              fontSize: 11,
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            onChanged: dashboardController.isLocked.value
                                                ? null
                                                : (v) {
                                                    if (v != null) {
                                                      controller.returnLostDropdownValue[index] = v;
                                                    }
                                                  },
                                            // Remove "To" options, keep only "From" options
                                            items: (isFromField ? pitOptions : [])
                                                .map((option) {
                                                  return DropdownMenuItem<String>(
                                                    value: option,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                        ),
                                      )
                                    : Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: dashboardController.isLocked.value
                                            ? Colors.grey.shade50
                                            : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: TextField(
                                          enabled: !dashboardController.isLocked.value,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                            hintText: "Enter value...",
                                            hintStyle: AppTheme.caption.copyWith(
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                          style: AppTheme.bodySmall.copyWith(
                                            fontSize: 11,
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                              ),
                            ),

                            // Unit Column
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  unit,
                                  style: AppTheme.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: unit.isNotEmpty
                                        ? AppTheme.textPrimary
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
        ]  ),

          
      
      );
  
  }
}
