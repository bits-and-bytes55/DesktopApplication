import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/empty_Activesystem_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class EmptyActiveSystemView extends StatefulWidget {
  const EmptyActiveSystemView({super.key, required this.instanceKey});

  final String instanceKey;

  @override
  State<EmptyActiveSystemView> createState() => _EmptyActiveSystemViewState();
}

class _EmptyActiveSystemViewState extends State<EmptyActiveSystemView> {
  late final EmptyActiveSystemController controller;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      EmptyActiveSystemController(instanceKey: widget.instanceKey),
      tag: widget.instanceKey,
    );
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    if (Get.isRegistered<EmptyActiveSystemController>(
      tag: widget.instanceKey,
    )) {
      Get.delete<EmptyActiveSystemController>(tag: widget.instanceKey);
    }
    super.dispose();
  }

  Future<void> _showTransferRowMenuAt(Offset globalPosition, int index) async {
    if (controller.isDumpSelected.value) return;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final hasData = controller.transferRowHasData(index);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem<String>(value: 'insert', child: Text('Insert Row')),
        PopupMenuItem<String>(
          value: 'clear',
          enabled: hasData,
          child: const Text('Clear Row'),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          enabled: controller.pitValues.length > 1,
          child: const Text('Delete Row'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'save',
          enabled: hasData,
          child: const Text('Save'),
        ),
      ],
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'insert':
        controller.insertTransferRowAfter(index);
        break;
      case 'clear':
        await _runRowAction(controller.clearTransferRow(index));
        break;
      case 'delete':
        await _runRowAction(controller.deleteTransferRow(index));
        break;
      case 'save':
        await _runRowAction(controller.saveEmptyActiveSystem());
        break;
    }
  }

  Future<void> _runRowAction(Future<Map<String, dynamic>> action) async {
    final result = await action;
    if (!mounted || result['success'] == true) return;
    Get.snackbar(
      'Error',
      result['message']?.toString() ?? 'Operation failed',
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth > 1000
            ? constraints.maxWidth
            : 1000.0;
        return Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.vertical,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ================= HEADER =================
                        Text(
                          "Empty Fluid in Active System",
                          style: AppTheme.titleMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ================= RADIO BUTTONS + TABLE =================
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.tableGridBlue),
                            ),
                            child: Column(
                              children: [
                                // Radio Buttons Row
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppTheme.tableGridBlue,
                                      ),
                                    ),
                                  ),
                                  child: Obx(
                                    () => Row(
                                      children: [
                                        // Dump Radio
                                        InkWell(
                                          onTap: () =>
                                              controller.isDumpSelected.value =
                                                  true,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        controller
                                                            .isDumpSelected
                                                            .value
                                                        ? AppTheme.primaryColor
                                                        : Colors.grey.shade400,
                                                    width: 2,
                                                  ),
                                                ),
                                                child:
                                                    controller
                                                        .isDumpSelected
                                                        .value
                                                    ? Center(
                                                        child: Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration:
                                                              BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: AppTheme
                                                                    .primaryColor,
                                                              ),
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Dump",
                                                style: AppTheme.bodySmall
                                                    .copyWith(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.black,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        // Transfer to Storage Radio
                                        InkWell(
                                          onTap: () =>
                                              controller.isDumpSelected.value =
                                                  false,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        !controller
                                                            .isDumpSelected
                                                            .value
                                                        ? AppTheme.primaryColor
                                                        : Colors.grey.shade400,
                                                    width: 2,
                                                  ),
                                                ),
                                                child:
                                                    !controller
                                                        .isDumpSelected
                                                        .value
                                                    ? Center(
                                                        child: Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration:
                                                              BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: AppTheme
                                                                    .primaryColor,
                                                              ),
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Transfer to Storage",
                                                style: AppTheme.bodySmall
                                                    .copyWith(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.black,
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
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                    ),
                                  ),
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: AppTheme.tableGridBlue,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Pit Header
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  "Pit",
                                                  style: AppTheme.bodySmall
                                                      .copyWith(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.black,
                                                      ),
                                                ),
                                              ),
                                              // Vertical Divider
                                              Container(
                                                width: 1,
                                                height: 20,
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                              // Volume Header
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 8,
                                                      ),
                                                  child: Text(
                                                    AppUnits.label(
                                                      "Vol. (bbl)",
                                                    ),
                                                    style: AppTheme.bodySmall
                                                        .copyWith(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.black,
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
                                                (index) => Listener(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onPointerDown: isEnabled
                                                      ? (event) {
                                                          if ((event.buttons &
                                                                  kSecondaryMouseButton) !=
                                                              0) {
                                                            _showTransferRowMenuAt(
                                                              event.position,
                                                              index,
                                                            );
                                                          }
                                                        }
                                                      : null,
                                                  child: Container(
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        // Pit Dropdown Column
                                                        Expanded(
                                                          flex: 3,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                ),
                                                            child: isEnabled
                                                                ? PopupMenuButton<
                                                                    String
                                                                  >(
                                                                    enabled:
                                                                        isEnabled,
                                                                    offset:
                                                                        const Offset(
                                                                          0,
                                                                          0,
                                                                        ),
                                                                    constraints: BoxConstraints(
                                                                      maxHeight:
                                                                          180, // Fixed dropdown height
                                                                      minWidth:
                                                                          200,
                                                                    ),
                                                                    child: Container(
                                                                      height:
                                                                          36,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: Row(
                                                                        children: [
                                                                          Expanded(
                                                                            child: Text(
                                                                              controller.pitValues[index].isEmpty
                                                                                  ? ""
                                                                                  : controller.pitValues[index],
                                                                              style: AppTheme.bodySmall.copyWith(
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.w700,
                                                                                color: Colors.black,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Icon(
                                                                            Icons.arrow_drop_down_rounded,
                                                                            size:
                                                                                18,
                                                                            color:
                                                                                Colors.grey.shade600,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    onSelected:
                                                                        (
                                                                          String
                                                                          value,
                                                                        ) {
                                                                          controller.setPit(
                                                                            index,
                                                                            value,
                                                                          );
                                                                          // Auto-generate next row if last row is filled
                                                                          if (index ==
                                                                                  controller.pitValues.length -
                                                                                      1 &&
                                                                              controller.pitValues[index] !=
                                                                                  "") {
                                                                            controller.addNewRow();
                                                                          }
                                                                        },
                                                                    itemBuilder:
                                                                        (
                                                                          BuildContext
                                                                          context,
                                                                        ) {
                                                                          return controller.unselectedPits.map((
                                                                            pit,
                                                                          ) {
                                                                            return PopupMenuItem<
                                                                              String
                                                                            >(
                                                                              value: pit.pitName,
                                                                              height: 32,
                                                                              child: Text(
                                                                                pit.pitName,
                                                                                style: AppTheme.bodySmall.copyWith(
                                                                                  fontSize: 12,
                                                                                  fontWeight: FontWeight.w700,
                                                                                  color: Colors.black,
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }).toList();
                                                                        },
                                                                  )
                                                                : Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    child: Text(
                                                                      controller
                                                                              .pitValues[index]
                                                                              .isEmpty
                                                                          ? ""
                                                                          : controller.pitValues[index],
                                                                      style: AppTheme.bodySmall.copyWith(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),

                                                        // Vertical Divider
                                                        Container(
                                                          width: 1,
                                                          height: 36,
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                        ),

                                                        // Volume Column
                                                        Expanded(
                                                          flex: 2,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                ),
                                                            child: isEnabled
                                                                ? TextField(
                                                                    controller:
                                                                        controller
                                                                            .volControllers[index],
                                                                    enabled:
                                                                        isEnabled,
                                                                    decoration: InputDecoration(
                                                                      border: InputBorder
                                                                          .none,
                                                                      isDense:
                                                                          true,
                                                                      hintText:
                                                                          "",
                                                                      contentPadding:
                                                                          const EdgeInsets.symmetric(
                                                                            vertical:
                                                                                8,
                                                                          ),
                                                                    ),
                                                                    style: AppTheme.bodySmall.copyWith(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .number,
                                                                    onChanged:
                                                                        (
                                                                          val,
                                                                        ) => controller.setVolume(
                                                                          index,
                                                                          val,
                                                                        ),
                                                                  )
                                                                : Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    child: Text(
                                                                      controller
                                                                          .volValues[index],
                                                                      style: AppTheme.bodySmall.copyWith(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        color: Colors
                                                                            .black,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await controller
                                    .saveEmptyActiveSystem();
                                Get.snackbar(
                                  result['success'] == true ? 'Saved' : 'Error',
                                  result['message']?.toString() ??
                                      (result['success'] == true
                                          ? 'Empty Active System saved'
                                          : 'Failed to save Empty Active System'),
                                  snackPosition: SnackPosition.TOP,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                "Execute Empty",
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
