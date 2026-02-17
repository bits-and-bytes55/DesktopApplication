import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AddWaterView extends StatelessWidget {
  AddWaterView({super.key});

  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  final PitController pitController = Get.put(PitController());

  // Table data - starts with 2 empty rows
  final selectedTo = "Active System".obs;
  final volValues = <String>["", ""].obs;

  @override
  Widget build(BuildContext context) {
    // Fetch selected pits on init
    pitController.fetchSelectedPits();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Text(
            "Add Water",
            style: AppTheme.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // ================= COMPRESSED TABLE (LEFT ALIGNED) =================
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 300, // Reduced width
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
                        // ================= ROW 1: TO (Fixed Header) =================
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
                              // Label Column
                              Container(
                                width: 80,
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
                                      "To",
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Dropdown Column
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: PopupMenuButton<String>(
                                    enabled: !dashboardController.isLocked.value,
                                    offset: const Offset(0, 0),
                                    constraints: BoxConstraints(
                                      maxHeight: 180,
                                      minWidth: 200,
                                    ),
                                    child: Container(
                                      height: 24,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              selectedTo.value,
                                              style: AppTheme.bodySmall.copyWith(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                    onSelected: (String value) {
                                      selectedTo.value = value;
                                    },
                                    itemBuilder: (BuildContext context) {
                                      // Build dropdown items
                                      final items = <PopupMenuItem<String>>[];

                                      // Add "Active System" at top
                                      items.add(
                                        PopupMenuItem<String>(
                                          value: "Active System",
                                          height: 32,
                                          child: Text(
                                            "Active System",
                                            style: AppTheme.bodySmall.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      );

                                      // Add divider
                                      if (pitController.selectedPits.isNotEmpty) {
                                        items.add(
                                          const PopupMenuItem<String>(
                                            enabled: false,
                                            height: 1,
                                            child: Divider(height: 1),
                                          ),
                                        );
                                      }

                                      // Add selected pits dynamically
                                      items.addAll(
                                        pitController.selectedPits.map((pit) {
                                          return PopupMenuItem<String>(
                                            value: pit.pitName,
                                            height: 32,
                                            child: Text(
                                              pit.pitName,
                                              style: AppTheme.bodySmall.copyWith(
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );

                                      return items;
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ================= ROW 2: VOL (bbl) (Fixed Header) =================
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Label Column
                              Container(
                                width: 80,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Colors.grey.shade300),
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
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      "Vol. (bbl)",
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Text field for Vol value
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: TextField(
                                    enabled: !dashboardController.isLocked.value,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintText: "Enter value...",
                                      hintStyle: AppTheme.caption.copyWith(
                                        color: Colors.grey.shade400,
                                        fontSize: 10,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ================= DYNAMIC EMPTY ROWS (2 initial) =================
                        ...List.generate(
                          volValues.length,
                          (index) => Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: index % 2 == 0 
                                  ? Colors.white 
                                  : Colors.grey.shade50,
                              border: Border(
                                bottom: index == volValues.length - 1
                                    ? BorderSide.none
                                    : BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                              ),
                              borderRadius: index == volValues.length - 1
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Empty Label Column (can be filled manually)
                                Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                          color: Colors.grey.shade300),
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
                                  ),
                                ),
                                // Volume Input Column
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: volValues[index],
                                      ),
                                      enabled:
                                          !dashboardController.isLocked.value,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: "",
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8),
                                      ),
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        volValues[index] = val;
                                        // Auto-generate next row if current is last and has value
                                        if (index == volValues.length - 1 &&
                                            val.isNotEmpty) {
                                          volValues.add("");
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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