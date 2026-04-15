import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/empty_Activesystem_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class EmptyActiveSystemView extends StatelessWidget {
  EmptyActiveSystemView({super.key});

  final controller = Get.put(EmptyActiveSystemController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Text(
            "Empty Fluid in Active System",
            style: AppTheme.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // ================= RADIO BUTTONS + TABLE =================
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4, // Decreased width
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  // Radio Buttons Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Obx(() => Row(
                          children: [
                            // Dump Radio
                            InkWell(
                              onTap: () => controller.isDumpSelected.value = true,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: controller.isDumpSelected.value
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: controller.isDumpSelected.value
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
                                  const SizedBox(width: 8),
                                  Text(
                                    "Dump",
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Transfer to Storage Radio
                            InkWell(
                              onTap: () => controller.isDumpSelected.value = false,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: !controller.isDumpSelected.value
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: !controller.isDumpSelected.value
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
                                  const SizedBox(width: 8),
                                  Text(
                                    "Transfer to Storage",
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Adjust Length Square Button
                            Tooltip(
                              message: "Adjust Length",
                              child: InkWell(
                                onTap: () {
                                  // Adjust length action
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.tune,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ),

                  // Table
                  Obx(() {
                    final isEnabled = controller.isTableEnabled;
                    return Opacity(
                      opacity: isEnabled ? 1.0 : 0.4,
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Pit Header
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "Pit",
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // Vertical Divider
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                // Volume Header
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      "Vol. (bbl)",
                                      style: AppTheme.bodySmall.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Table Body - Fixed Height with Scroll
                          SizedBox(
                            height: 200, // Fixed height
                            child: SingleChildScrollView(
                              child: Column(
                                children: List.generate(
                                  controller.pitValues.length,
                                  (index) => Container(
                                    height: 36,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Pit Dropdown Column
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: isEnabled
                                                ? PopupMenuButton<String>(
                                                    enabled: isEnabled,
                                                    offset: const Offset(0, 0),
                                                    constraints: BoxConstraints(
                                                      maxHeight: 180, // Fixed dropdown height
                                                      minWidth: 200,
                                                    ),
                                                    child: Container(
                                                      height: 36,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              controller.pitValues[
                                                                          index]
                                                                      .isEmpty
                                                                  ? ""
                                                                  : controller
                                                                          .pitValues[
                                                                      index],
                                                              style: AppTheme
                                                                  .bodySmall
                                                                  .copyWith(
                                                                fontSize: 11,
                                                                color: controller
                                                                        .pitValues[
                                                                            index]
                                                                        .isEmpty
                                                                    ? Colors.grey
                                                                        .shade400
                                                                    : AppTheme
                                                                        .textPrimary,
                                                              ),
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons
                                                                .arrow_drop_down_rounded,
                                                            size: 18,
                                                            color: Colors
                                                                .grey.shade600,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    onSelected: (String value) {
                                                      controller.setPit(
                                                          index, value);
                                                      // Auto-generate next row if last row is filled
                                                      if (index ==
                                                              controller.pitValues
                                                                      .length -
                                                                  1 &&
                                                          controller.pitValues[
                                                                  index] !=
                                                              "") {
                                                        controller.addNewRow();
                                                      }
                                                    },
                                                    itemBuilder:
                                                        (BuildContext context) {
                                                      return controller
                                                          .unselectedPits
                                                          .map((pit) {
                                                        return PopupMenuItem<
                                                            String>(
                                                          value: pit.pitName,
                                                          height: 32,
                                                          child: Text(
                                                            pit.pitName,
                                                            style: AppTheme
                                                                .bodySmall
                                                                .copyWith(
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        );
                                                      }).toList();
                                                    },
                                                  )
                                                : Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      controller
                                                              .pitValues[index]
                                                              .isEmpty
                                                          ? ""
                                                          : controller
                                                              .pitValues[index],
                                                      style: AppTheme.bodySmall
                                                          .copyWith(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey.shade400,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),

                                        // Vertical Divider
                                        Container(
                                          width: 1,
                                          height: 36,
                                          color: Colors.grey.shade200,
                                        ),

                                        // Volume Column
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: isEnabled
                                                ? TextField(
                                                    controller:
                                                        TextEditingController(
                                                      text: controller
                                                          .volValues[index],
                                                    ),
                                                    enabled: isEnabled,
                                                    decoration: InputDecoration(
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      hintText: "",
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              vertical: 8),
                                                    ),
                                                    style: AppTheme.bodySmall
                                                        .copyWith(
                                                      fontSize: 11,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    onChanged: (val) => controller
                                                        .volValues[index] = val,
                                                  )
                                                : Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      controller.volValues[index],
                                                      style: AppTheme.bodySmall
                                                          .copyWith(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey.shade400,
                                                      ),
                                                    ),
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
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ================= ACTION BUTTONS =================
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  // Cancel action
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Execute action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Execute Empty",
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}