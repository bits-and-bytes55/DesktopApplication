import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/return_lostmud_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReturnLostMudView extends StatelessWidget {
  ReturnLostMudView({super.key, required this.instanceKey})
    : controller = Get.put(
        ReturnLostMudController(instanceKey: instanceKey),
        tag: instanceKey,
      );

  static Map<String, dynamic>? _clipboard;

  final String instanceKey;
  final ReturnLostMudController controller;
  final DashboardController dashboardController =
      Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.tableHeaderBlue,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 16),

          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onSecondaryTapDown: (details) =>
                  _showReturnLostMudMenu(context, details),
              child: _ReturnLostMudScrollArea(
                minWidth: 1000,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPremixedMudSection(),
                    const SizedBox(height: 16),
                    _buildDataTable(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    String label, {
    required bool enabled,
  }) {
    final color = enabled ? Colors.black87 : Colors.grey.shade400;
    return PopupMenuItem<String>(
      value: enabled ? value : null,
      enabled: enabled,
      height: 30,
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  Future<void> _showReturnLostMudMenu(
    BuildContext context,
    TapDownDetails details,
  ) async {
    final canEdit = !dashboardController.isLocked.value;
    final hasData = controller.hasReturnLostData;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        _menuItem('cut', 'Cut', enabled: canEdit && hasData),
        _menuItem('copy', 'Copy', enabled: hasData),
        _menuItem('paste', 'Paste', enabled: canEdit && _clipboard != null),
        const PopupMenuDivider(height: 4),
        _menuItem('save', 'Save', enabled: canEdit && hasData),
        _menuItem('delete', 'Delete', enabled: canEdit && hasData),
        _menuItem('clear', 'Clear', enabled: canEdit && hasData),
      ],
    );

    switch (action) {
      case 'cut':
        _clipboard = controller.formSnapshot();
        await controller.deleteCurrentRecord(silent: false);
        break;
      case 'copy':
        _clipboard = controller.formSnapshot();
        break;
      case 'paste':
        final snapshot = _clipboard;
        if (snapshot == null) return;
        controller.applyFormSnapshot(snapshot);
        await controller.saveReturnLostMud(silent: true);
        break;
      case 'save':
        await controller.saveReturnLostMud();
        break;
      case 'delete':
        await controller.deleteCurrentRecord();
        break;
      case 'clear':
        await controller.deleteCurrentRecord();
        break;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.replay_circle_filled, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Return / Lost Mud',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremixedMudSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.tableGridBlue),
      ),
      child: Row(
        children: [
          Obx(
            () => InkWell(
              onTap: dashboardController.isLocked.value
                  ? null
                  : () {
                      controller.isPremixedMud.value =
                          !controller.isPremixedMud.value;
                      if (!controller.isPremixedMud.value) {
                        controller.selectedPremixedId.value = '';
                        controller.selectedPremixed.value = null;
                        controller.mw.value = '';
                        controller.mudType.value = '';
                        controller.costOfLostController.clear();
                      }
                    },
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: controller.isPremixedMud.value
                        ? AppTheme.primaryColor
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(3),
                  color: controller.isPremixedMud.value
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: controller.isPremixedMud.value
                    ? Icon(Icons.check, size: 14, color: AppTheme.primaryColor)
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Container(
            width: 90,
            child: Text(
              'Premixed Mud',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),

          Expanded(
            child: Obx(
              () => Container(
                height: 30,
                decoration: BoxDecoration(
                  color:
                      dashboardController.isLocked.value ||
                          !controller.isPremixedMud.value
                      ? AppTheme.tableHeaderBlue
                      : Colors.white,
                  border: Border.all(color: AppTheme.tableGridBlue),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: controller.isLoading.value
                    ? Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.selectedPremixedId.value.isEmpty
                              ? null
                              : controller.selectedPremixedId.value,
                          hint: const SizedBox.shrink(),
                          isExpanded: true,
                          isDense: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          dropdownColor: Colors.white,
                          items: controller.premixedList.map((premixed) {
                            return DropdownMenuItem<String>(
                              value: premixed.id,
                              child: Text(
                                premixed.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged:
                              dashboardController.isLocked.value ||
                                  !controller.isPremixedMud.value
                              ? null
                              : (value) {
                                  if (value != null) {
                                    controller.selectPremixed(value);
                                  }
                                },
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          menuMaxHeight: 200,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.tableGridBlue),
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return Container(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          );
        }

        return Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
            verticalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
          ),
          columnWidths: const {
            0: FixedColumnWidth(120),
            1: FlexColumnWidth(2),
            2: FixedColumnWidth(70),
          },
          children: [
            // From (Pit Dropdown)
            _buildFromPitRow(),

            // To (Manual Input)
            _buildEditableRow('To', controller.toController, ''),

            // Vol. Returned (Manual Input)
            _buildEditableRow(
              'Vol. Returned',
              controller.volReturnedController,
              '(bbl)',
            ),

            // MW (Auto-filled from selected premixed)
            _buildDisplayRow('MW', controller.mw.value, '(ppg)'),

            // Mud Type (Auto-filled from selected premixed)
            _buildDisplayRow('Mud Type', controller.mudType.value, ''),

            // BOL (Manual Input)
            _buildEditableRow('BOL', controller.bolController, ''),

            // Cost of Lost (Pre-tax) (Manual Input)
            _buildEditableRow(
              'Cost of Lost (Pre-tax)',
              controller.costOfLostController,
              '(Kwd)',
            ),

            // Leased Checkbox
            _buildLeasedRow(),
          ],
        );
      }),
    );
  }

  TableRow _buildFromPitRow() {
    return TableRow(
      children: [
        _buildLabelCell('From'),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Obx(
            () => Container(
              height: 30,
              decoration: BoxDecoration(
                color: dashboardController.isLocked.value
                    ? AppTheme.tableHeaderBlue
                    : Colors.white,
                border: Border.all(color: AppTheme.tableGridBlue),
                borderRadius: BorderRadius.circular(3),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedPitId.value.isEmpty
                      ? null
                      : controller.selectedPitId.value,
                  hint: Text(
                    'Select Pit',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  isExpanded: true,
                  isDense: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  dropdownColor: Colors.white,
                  items: controller.fromOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['id'],
                      child: Text(
                        option['name'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: dashboardController.isLocked.value
                      ? null
                      : (value) {
                          if (value != null) {
                            controller.selectPit(value);
                          }
                        },
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  menuMaxHeight: 200,
                ),
              ),
            ),
          ),
        ),
        _buildUnitCell(''),
      ],
    );
  }

  TableRow _buildEditableRow(
    String label,
    TextEditingController textController,
    String unit,
  ) {
    return TableRow(
      children: [
        _buildLabelCell(label),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Obx(
            () => Container(
              height: 30,
              child: TextField(
                controller: textController,
                enabled: !dashboardController.isLocked.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: true,
                  fillColor: dashboardController.isLocked.value
                      ? AppTheme.tableHeaderBlue
                      : Colors.white,
                ),
              ),
            ),
          ),
        ),
        _buildUnitCell(unit),
      ],
    );
  }

  TableRow _buildDisplayRow(String label, String value, String unit) {
    return TableRow(
      children: [
        _buildLabelCell(label),
        _buildValueCell(value),
        _buildUnitCell(unit),
      ],
    );
  }

  TableRow _buildLeasedRow() {
    return TableRow(
      children: [
        _buildLabelCell('Leased'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Obx(
            () => Row(
              children: [
                InkWell(
                  onTap: dashboardController.isLocked.value
                      ? null
                      : () {
                          controller.isLeased.value =
                              !controller.isLeased.value;
                        },
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: controller.isLeased.value
                            ? AppTheme.primaryColor
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(3),
                      color: controller.isLeased.value
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: controller.isLeased.value
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildUnitCell(''),
      ],
    );
  }

  Widget _buildLabelCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: AppTheme.primaryColor,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildValueCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: Colors.white,
      child: Text(
        text.isEmpty ? '-' : text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildUnitCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: Colors.grey.shade50,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _ReturnLostMudScrollArea extends StatefulWidget {
  const _ReturnLostMudScrollArea({required this.child, required this.minWidth});

  final Widget child;
  final double minWidth;

  @override
  State<_ReturnLostMudScrollArea> createState() =>
      _ReturnLostMudScrollAreaState();
}

class _ReturnLostMudScrollAreaState extends State<_ReturnLostMudScrollArea> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      trackVisibility: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.vertical,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        trackVisibility: true,
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.horizontal,
        child: SingleChildScrollView(
          controller: _verticalController,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: widget.minWidth, child: widget.child),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }
}
