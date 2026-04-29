import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AddWaterView extends StatefulWidget {
  const AddWaterView({super.key});

  @override
  State<AddWaterView> createState() => _AddWaterViewState();
}

class _AddWaterViewState extends State<AddWaterView> {
  late final OperationController controller;
  late final DashboardController dashboardController;
  late final PitController pitController;
  late final TextEditingController _mainVolController;
  final List<TextEditingController> _extraVolControllers = [];
  final List<Worker> _workers = [];

  // Bind to OperationController for global state
  // selectedTo, addWaterMainVol, and addWaterExtraRows are now in operationController

  @override
  void initState() {
    super.initState();
    controller = Get.find<OperationController>();
    dashboardController = Get.find<DashboardController>();
    pitController = Get.isRegistered<PitController>()
        ? Get.find<PitController>()
        : Get.put(PitController());
    _mainVolController = TextEditingController(
      text: controller.addWaterMainVol.value,
    );
    _syncExtraControllers();
    _workers.addAll([
      ever<String>(
        controller.addWaterMainVol,
        (value) => _setControllerText(_mainVolController, value),
      ),
      ever<List<String>>(
        controller.addWaterExtraRows,
        (_) => _syncExtraControllers(notify: true),
      ),
    ]);
    pitController.fetchAllPits();
    controller.loadAddWater();
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _mainVolController.dispose();
    for (final textController in _extraVolControllers) {
      textController.dispose();
    }
    super.dispose();
  }

  void _setControllerText(TextEditingController textController, String value) {
    if (textController.text == value) return;
    textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _syncExtraControllers({bool notify = false}) {
    final values = controller.addWaterExtraRows;
    while (_extraVolControllers.length < values.length) {
      _extraVolControllers.add(TextEditingController());
    }
    while (_extraVolControllers.length > values.length) {
      _extraVolControllers.removeLast().dispose();
    }
    for (var index = 0; index < values.length; index++) {
      _setControllerText(_extraVolControllers[index], values[index]);
    }
    if (notify && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: Obx(() {
                  _syncExtraControllers();
                  return Column(
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
                                              controller.addWaterTo.value,
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
                                      controller.addWaterTo.value = value;
                                    },
                                    itemBuilder: (BuildContext context) {
                                      // Build dropdown items
                                      final items = <PopupMenuItem<String>>[];

                                      // Add "Active System" and "Empty" at top
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
                                      items.add(
                                        PopupMenuItem<String>(
                                          value: "",
                                          height: 32,
                                          child: Text(
                                            "",
                                            style: AppTheme.bodySmall.copyWith(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      );

                                      // Add divider
                                      if (pitController.pits.isNotEmpty) {
                                        items.add(
                                          const PopupMenuItem<String>(
                                            enabled: false,
                                            height: 1,
                                            child: Divider(height: 1),
                                          ),
                                        );
                                      }

                                      // Add all pits (Active & Storage)
                                      items.addAll(
                                        pitController.pits.map((pit) {
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
                                    controller: _mainVolController,
                                    onChanged: (val) {
                                      controller.addWaterMainVol.value = val;
                                    },
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ================= DYNAMIC EMPTY ROWS (2 initial) =================
                        ...List.generate(
                          controller.addWaterExtraRows.length,
                          (index) => Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: index % 2 == 0 
                                  ? Colors.white 
                                  : Colors.grey.shade50,
                              border: Border(
                                bottom: index == controller.addWaterExtraRows.length - 1
                                    ? BorderSide.none
                                    : BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                              ),
                              borderRadius: index == controller.addWaterExtraRows.length - 1
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Backend does not persist a per-row label here.
                                Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "",
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                // Volume Input Column
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: TextField(
                                      controller: _extraVolControllers[index],
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
                                        controller.addWaterExtraRows[index] = val;
                                        // Auto-generate next row if current is last and has value
                                        if (index == controller.addWaterExtraRows.length - 1 &&
                                            val.isNotEmpty) {
                                          controller.addWaterExtraRows.add("");
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
                    );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
