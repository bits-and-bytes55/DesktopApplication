import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/empty_Activesystem_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class EmptyActiveSystemView extends StatelessWidget {
  EmptyActiveSystemView({super.key});

  final controller = Get.put(EmptyActiveSystemController());
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= ENHANCED HEADER =================
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [
            //         AppTheme.primaryColor.withOpacity(0.9),
            //         AppTheme.primaryColor,
            //       ],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //     borderRadius: BorderRadius.circular(12),
            //     boxShadow: [
            //       BoxShadow(
            //         color: AppTheme.primaryColor.withOpacity(0.2),
            //         blurRadius: 8,
            //         offset: const Offset(0, 4),
            //       ),
            //     ],
            //   ),
            //   child: Row(
            //     children: [
            //       Container(
            //         padding: const EdgeInsets.all(10),
            //         decoration: BoxDecoration(
            //           color: Colors.white.withOpacity(0.2),
            //           borderRadius: BorderRadius.circular(10),
            //         ),
            //         child: const Icon(
            //           Icons.delete_outline_rounded,
            //           color: Colors.white,
            //           size: 24,
            //         ),
            //       ),
            //       const SizedBox(width: 16),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               "Empty Fluid in Active System",
            //               style: AppTheme.titleMedium.copyWith(
            //                 fontSize: 18,
            //                 color: Colors.white,
            //                 fontWeight: FontWeight.w700,
            //                 letterSpacing: 0.5,
            //               ),
            //             ),
            //             const SizedBox(height: 4),
            //             Text(
            //               "Manage fluid transfer between active system and storage",
            //               style: AppTheme.bodySmall.copyWith(
            //                 color: Colors.white.withOpacity(0.9),
            //                 fontSize: 12,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // const SizedBox(height: 20),

            // ================= ENHANCED RADIO BUTTONS =================
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Action",
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Dump Radio
                          Expanded(
                            child: InkWell(
                              onTap: () => controller.isDumpSelected.value = true,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: controller.isDumpSelected.value
                                      ? AppTheme.errorColor.withOpacity(0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: controller.isDumpSelected.value
                                        ? AppTheme.errorColor.withOpacity(0.3)
                                        : Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: controller.isDumpSelected.value
                                              ? AppTheme.errorColor
                                              : Colors.grey.shade400,
                                          width: controller.isDumpSelected.value
                                              ? 1.5
                                              : 1,
                                        ),
                                      ),
                                      child: controller.isDumpSelected.value
                                          ? Center(
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppTheme.errorColor,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.delete_forever_rounded,
                                      size: 18,
                                      color: controller.isDumpSelected.value
                                          ? AppTheme.errorColor
                                          : Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Dump",
                                      style: AppTheme.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: controller.isDumpSelected.value
                                            ? AppTheme.errorColor
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Transfer to Storage Radio
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  controller.isDumpSelected.value = false,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: !controller.isDumpSelected.value
                                      ? AppTheme.successColor.withOpacity(0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: !controller.isDumpSelected.value
                                        ? AppTheme.successColor.withOpacity(0.3)
                                        : Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: !controller.isDumpSelected.value
                                              ? AppTheme.successColor
                                              : Colors.grey.shade400,
                                          width: !controller.isDumpSelected.value
                                              ? 1.5
                                              : 1,
                                        ),
                                      ),
                                      child: !controller.isDumpSelected.value
                                          ? Center(
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppTheme.successColor,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 18,
                                      color: !controller.isDumpSelected.value
                                          ? AppTheme.successColor
                                          : Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Transfer to Storage",
                                      style: AppTheme.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: !controller.isDumpSelected.value
                                            ? AppTheme.successColor
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
            ),

            const SizedBox(height: 20),

            // ================= ADJUST BUTTON =================
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Fluid Management",
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Configure pit volumes and transfers",
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.isTableEnabled) {
                        controller.adjustVolumes();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "Adjust Volumes",
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= ENHANCED TABLE WITH MINIMUM 5 ROWS =================
            Container(
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
                children: [
                  // Table Header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Pit",
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Volume (bbl)",
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Body - Fixed Height with Scroll
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 300, // Minimum height
                      maxHeight: MediaQuery.of(context).size.height * 0.5, // Maximum height
                    ),
                    child: SingleChildScrollView(
                      child: Obx(() {
                        // Ensure minimum 5 rows
                        final rowCount = controller.pitValues.length < 5 
                            ? 5 
                            : controller.pitValues.length;
                        
                        return Column(
                          children: List.generate(
                            rowCount,
                            (row) => Container(
                              height: 60, // Increased row height
                              decoration: BoxDecoration(
                                color: row % 2 == 0
                                    ? Colors.white
                                    : Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(
                                    color: row == rowCount - 1
                                        ? Colors.transparent
                                        : Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // PIT COLUMN
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: row < controller.pitValues.length 
                                          ? (controller.isTableEnabled
                                              ? DropdownButton<String>(
                                                  value: controller.pitValues[row].isEmpty
                                                      ? null
                                                      : controller.pitValues[row],
                                                  isExpanded: true,
                                                  underline: const SizedBox(),
                                                  icon: Icon(
                                                    Icons.arrow_drop_down_rounded,
                                                    size: 20,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  hint: Text(
                                                    "Select Pit",
                                                    style: AppTheme.bodySmall.copyWith(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade500,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  onChanged: (String? newValue) {
                                                    if (newValue != null) {
                                                      controller.setPit(row, newValue);
                                                    }
                                                  },
                                                  items: controller.pits
                                                      .map((String value) {
                                                    return DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(
                                                        value,
                                                        style:
                                                            AppTheme.bodySmall.copyWith(
                                                          fontSize: 11,
                                                          color: AppTheme.textPrimary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    );
                                                  }).toList(),
                                                )
                                              : Container(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    controller.pitValues[row].isEmpty
                                                        ? "Select Pit"
                                                        : controller.pitValues[row],
                                                    style: AppTheme.bodySmall.copyWith(
                                                      fontSize: 11,
                                                      color:
                                                          controller.pitValues[row].isEmpty
                                                              ? Colors.grey.shade400
                                                              : AppTheme.textPrimary,
                                                      fontWeight: FontWeight.w500,
                                                      fontStyle:
                                                          controller.pitValues[row].isEmpty
                                                              ? FontStyle.italic
                                                              : null,
                                                    ),
                                                  ),
                                                ))
                                          : Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                "Empty Row",
                                                style: AppTheme.bodySmall.copyWith(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade400,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),

                                  // VOLUME COLUMN
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 16),
                                      child: row < controller.pitValues.length 
                                          ? (controller.isTableEnabled
                                              ? TextField(
                                                  controller: TextEditingController(
                                                      text: controller.volValues[row]),
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    hintText: "0.00",
                                                    hintStyle:
                                                        AppTheme.caption.copyWith(
                                                      color: Colors.grey.shade400,
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                            vertical: 12),
                                                  ),
                                                  style: AppTheme.bodySmall.copyWith(
                                                    fontSize: 11,
                                                    color: AppTheme.textPrimary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (val) =>
                                                      controller.volValues[row] = val,
                                                )
                                              : Container(
                                                  alignment: Alignment.centerRight,
                                                  child: Text(
                                                    controller.volValues[row],
                                                    style: AppTheme.bodySmall.copyWith(
                                                      fontSize: 11,
                                                      color: AppTheme.textPrimary,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ))
                                          : Container(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                "0.00",
                                                style: AppTheme.bodySmall.copyWith(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade400,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= ACTION BUTTONS =================
            Container(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Cancel action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textPrimary,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cancel_rounded,
                            size: 18, color: AppTheme.textPrimary),
                        const SizedBox(width: 8),
                        Text(
                          "Cancel",
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Execute action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                          "Execute Empty",
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
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