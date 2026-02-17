import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudLossActiveSystemView extends StatelessWidget {
  MudLossActiveSystemView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();

  // 11 Fixed loss types (non-editable)
  final List<String> fixedLossTypes = const [
    "Cuttings/Retention",
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
  ];

  // Volume controllers for fixed rows
  final List<TextEditingController> fixedVolumeControllers = List.generate(
    11,
    (_) => TextEditingController(),
  );

  // Dynamic empty rows - starts with 2
  final RxList<Map<String, String>> dynamicRows = <Map<String, String>>[
    {"loss": "", "volume": ""},
    {"loss": "", "volume": ""},
  ].obs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Text(
            "Mud Loss - Active System",
            style: AppTheme.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // ================= COMPRESSED TABLE =================
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 350, // Compressed width
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ================= TABLE HEADER =================
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.95),
                                AppTheme.primaryColor,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              // # Column Header
                              Container(
                                width: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "#",
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              // Loss Header
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      Text(
                                        "Loss",
                                        style: AppTheme.bodySmall.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Vol. (bbl) Header
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      Text(
                                        "Vol. (bbl)",
                                        style: AppTheme.bodySmall.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ================= FIXED ROWS (11 rows) =================
                        ...fixedLossTypes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final lossType = entry.value;

                          return Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                // # Column
                                Container(
                                  width: 40,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${index + 1}",
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 10,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                // Loss Type (Fixed, Non-editable)
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    child: Text(
                                      lossType,
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 10,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                // Volume Input (Editable)
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: TextField(
                                      controller: fixedVolumeControllers[index],
                                      enabled: !dashboardController.isLocked.value,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: "",
                                        contentPadding:
                                            const EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 10,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        // ================= DYNAMIC EMPTY ROWS (2 initial) =================
                        ...dynamicRows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;
                          final globalIndex = fixedLossTypes.length + index;

                          return Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: globalIndex % 2 == 0
                                  ? Colors.grey.shade50
                                  : Colors.white,
                              border: Border(
                                bottom: index == dynamicRows.length - 1
                                    ? BorderSide.none
                                    : BorderSide(color: Colors.grey.shade200),
                              ),
                              borderRadius: index == dynamicRows.length - 1
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // # Column
                                Container(
                                  width: 40,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${globalIndex + 1}",
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 10,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                // Loss Type (Editable)
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    child: TextField(
                                      enabled: !dashboardController.isLocked.value,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: "",
                                        contentPadding:
                                            const EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 10,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      onChanged: (val) {
                                        row["loss"] = val;
                                        // Check if this is the last row and both fields have values
                                        if (index == dynamicRows.length - 1 &&
                                            val.isNotEmpty &&
                                            row["volume"]!.isNotEmpty) {
                                          dynamicRows.add({"loss": "", "volume": ""});
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                // Volume Input (Editable)
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: TextField(
                                      enabled: !dashboardController.isLocked.value,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: "",
                                        contentPadding:
                                            const EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 10,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        row["volume"] = val;
                                        // Check if this is the last row and both fields have values
                                        if (index == dynamicRows.length - 1 &&
                                            val.isNotEmpty &&
                                            row["loss"]!.isNotEmpty) {
                                          dynamicRows.add({"loss": "", "volume": ""});
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}