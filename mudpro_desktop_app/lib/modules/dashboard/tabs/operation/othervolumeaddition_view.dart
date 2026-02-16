import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class OtherVolAdditionActiveSystemView extends StatelessWidget {
  OtherVolAdditionActiveSystemView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();

  // Fixed rows data
  final List<Map<String, String>> fixedRows = [
    {"label": "Formation", "volume": ""},
    {"label": "Cuttings", "volume": ""},
    {"label": "Volume Not Fluid", "volume": ""},
  ];

  // Dynamic empty rows - starts with 2
  final RxList<Map<String, String>> dynamicRows = <Map<String, String>>[
    {"label": "", "volume": ""},
    {"label": "", "volume": ""},
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
            "Other Vol. Addition - Active System",
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
              width: 400, // Compressed width
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
                              // Addition Header
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                        "Addition",
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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

                        // ================= FIXED ROWS =================
                        ...fixedRows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;
                          
                          return Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Addition Label (Fixed)
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    child: Text(
                                      row["label"]!,
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: TextField(
                                      enabled: !dashboardController.isLocked.value,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: "",
                                        contentPadding:
                                            const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        row["volume"] = val;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        // ================= DYNAMIC EMPTY ROWS =================
                        ...dynamicRows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;
                          final globalIndex = fixedRows.length + index;
                          
                          return Container(
                            height: 36,
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
                                // Addition Label (Editable)
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                            const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      onChanged: (val) {
                                        row["label"] = val;
                                        // Check if this is the last row and both fields have values
                                        if (index == dynamicRows.length - 1 &&
                                            val.isNotEmpty &&
                                            row["volume"]!.isNotEmpty) {
                                          dynamicRows.add({"label": "", "volume": ""});
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                // Volume Input (Editable)
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: TextField(
                                      enabled: !dashboardController.isLocked.value,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: "",
                                        contentPadding:
                                            const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        row["volume"] = val;
                                        // Check if this is the last row and both fields have values
                                        if (index == dynamicRows.length - 1 &&
                                            val.isNotEmpty &&
                                            row["label"]!.isNotEmpty) {
                                          dynamicRows.add({"label": "", "volume": ""});
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