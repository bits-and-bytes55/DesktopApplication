import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/recievemud_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReceiveMudView extends StatelessWidget {
  ReceiveMudView({super.key, required this.instanceKey})
    : controller = Get.put(
        ReceiveMudController(instanceKey: instanceKey),
        tag: instanceKey,
      );

  final String instanceKey;
  final ReceiveMudController controller;
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

          const SizedBox(height: 8),

          // Main Content - Compressed width
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Form
              SizedBox(
                width: 680,
                height: 530,
                child: _ReceiveMudScrollArea(
                  minWidth: 660,
                  child: _buildFormSection(),
                ),
              ),

              Expanded(child: SizedBox()), // Spacer to push everything left
            ],
          ),
        ],
      ),
    );
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
          Icon(Icons.water_drop, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Receive Mud',
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

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.tableGridBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // BOL No
          _buildBolSection(),

          Divider(height: 1, color: AppTheme.tableGridBlue),

          // Data Table
          _buildDataTable(),

          Divider(height: 1, color: AppTheme.tableGridBlue),

          // Loss Volume Section (below table)
          _buildLossVolumeSection(),
        ],
      ),
    );
  }

  Widget _buildBolSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.tableGridBlue)),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            child: Text(
              'BOL No.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => TextField(
                controller: controller.bolNoController,
                enabled: !dashboardController.isLocked.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.tableGridBlue),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.tableGridBlue),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  filled: true,
                  fillColor: dashboardController.isLocked.value
                      ? operationLockedEditableColor
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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
          0: FixedColumnWidth(100),
          1: FlexColumnWidth(2),
          2: FixedColumnWidth(70),
        },
        children: [
          // Premixed Mud Row (Dropdown)
          _buildPremixedMudRow(),

          // MW Row
          _buildEditableRow('MW', controller.mwController, '(ppg)'),

          // Mud Type Row
          _buildEditableRow('Mud Type', controller.mudTypeController, ''),

          // Leasing Fee Row
          _buildEditableRow(
            'Leasing Fee',
            controller.leasingFeeController,
            '(kwd/bbl)',
          ),

          // From Row (Pit Dropdown)
          _buildFromPitRow(),

          // To Row (Active System / Pit Dropdown)
          _buildToPitRow(),

          // Vol Row
          _buildEditableRow('Vol.', controller.volController, '(bbl)'),

          // Leased Row (Locked)
          _buildLeasedRow(),
        ],
      );
    });
  }

  TableRow _buildBolRow() {
    return TableRow(
      children: [
        _buildLabelCell('BOL. No.'),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Obx(
            () => TextField(
              controller: controller.bolNoController,
              enabled: !dashboardController.isLocked.value,
              style: TextStyle(fontSize: 11, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.tableGridBlue),
                  borderRadius: BorderRadius.circular(3),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.tableGridBlue),
                  borderRadius: BorderRadius.circular(3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                filled: true,
                fillColor: dashboardController.isLocked.value
                    ? operationLockedEditableColor
                    : Colors.white,
              ),
            ),
          ),
        ),
        _buildUnitCell(''),
      ],
    );
  }

  TableRow _buildPremixedMudRow() {
    return TableRow(
      children: [
        _buildLabelCell('Premixed Mud'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          child: Obx(
            () => Container(
              height: 25,
              decoration: BoxDecoration(
                color: dashboardController.isLocked.value
                    ? operationLockedEditableColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
              child: DropdownButtonHideUnderline(
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
                    fontSize: 11,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  dropdownColor: Colors.white,
                  items: controller.premixedList.map((premixed) {
                    return DropdownMenuItem<String>(
                      value: premixed.id,
                      child: Text(
                        premixed.description,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: dashboardController.isLocked.value
                      ? null
                      : (value) => value != null
                            ? controller.selectPremixed(value)
                            : null,
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  menuMaxHeight: 200,
                ),
              ),
            ),
          ),
        ),
        Container(
          color: Colors.grey.shade50,
          child: Center(
            child: _buildIconButton(
              icon: Icons.table_view_rounded,
              tooltip: 'Premixed Mud Concentration',
              onTap: () => _openConcentrationDialog(Get.context!),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildFromPitRow() {
    return TableRow(
      children: [
        _buildLabelCell('From'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          child: Obx(
            () => ColoredBox(
              color: dashboardController.isLocked.value
                  ? operationLockedEditableColor
                  : Colors.white,
              child: TextField(
                controller: controller.fromController,
                enabled: !dashboardController.isLocked.value,
              style: TextStyle(
                fontSize: 11,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          ),
        ),
        _buildUnitCell(''),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  TableRow _buildToPitRow() {
    return TableRow(
      children: [
        _buildLabelCell('To'),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Expanded(
                child: Obx(() {
                  final options = [
                    '',
                    'Active System',
                    ...controller.pitController.unselectedPits.map(
                      (e) => e.pitName,
                    ),
                  ];
                  final currentVal = controller.selectedToDestination.value;
                  final validVal = options.contains(currentVal)
                      ? currentVal
                      : null;
                  return Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: dashboardController.isLocked.value
                          ? operationLockedEditableColor
                          : Colors.white,
                      border: Border.all(color: AppTheme.tableGridBlue),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: validVal,
                        hint: Text(
                          'Select Destination',
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
                        items: options.map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: name.isEmpty
                                ? Text(
                                    '-- None --',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 11,
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
                                controller.selectedToDestination.value =
                                    value ?? '';
                              },
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        menuMaxHeight: 200,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        _buildUnitCell(''),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value, String unit) {
    return TableRow(
      children: [
        _buildLabelCell(label),
        _buildValueCell(value),
        _buildUnitCell(unit),
      ],
    );
  }

  TableRow _buildEditableRow(
    String label,
    TextEditingController controller,
    String unit, {
    bool isReadOnly = false,
  }) {
    return TableRow(
      children: [
        _buildLabelCell(label),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          child: Obx(
            () => ColoredBox(
              color: !isReadOnly && dashboardController.isLocked.value
                  ? operationLockedEditableColor
                  : Colors.white,
              child: Opacity(
                opacity: isReadOnly ? 0.6 : 1.0,
                child: TextField(
                controller: controller,
                enabled: !dashboardController.isLocked.value && !isReadOnly,
                readOnly: isReadOnly,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: isReadOnly,
                  fillColor: isReadOnly ? Colors.grey.shade200 : null,
                ),
                ),
              ),
            ),
          ),
        ),
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
          child: Container(
            color: Colors.grey.shade50,
            child: Opacity(
              opacity: 0.6,
              child: Row(
                children: [
                  Transform.scale(
                    scale: 0.85,
                    child: Checkbox(
                      value: true, // Hardcoded to true for locked state
                      onChanged: null, // Always disabled
                      activeColor: Colors
                          .grey
                          .shade400, // Show it as disabled but checked
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildUnitCell(''),
      ],
    );
  }

  Widget _buildLabelCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: AppTheme.primaryColor,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildValueCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: Colors.white,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildUnitCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: Colors.grey.shade50,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildLossVolumeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Obx(
            () => Row(
              children: [
                Transform.scale(
                  scale: 0.85,
                  child: Checkbox(
                    value: controller.hasLossVolume.value,
                    onChanged: dashboardController.isLocked.value
                        ? null
                        : (value) {
                            controller.hasLossVolume.value = value ?? false;
                          },
                    activeColor: AppTheme.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Loss Volume',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Obx(
              () => TextField(
                controller: controller.lossVolumeController,
                enabled:
                    !dashboardController.isLocked.value &&
                    controller.hasLossVolume.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.tableGridBlue),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.tableGridBlue),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  filled: true,
                  fillColor: dashboardController.isLocked.value
                      ? operationLockedEditableColor
                      : !controller.hasLossVolume.value
                      ? AppTheme.tableHeaderBlue
                      : Colors.white,
                  suffixText: '(bbl)',
                  suffixStyle: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openConcentrationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          _PremixedMudConcentrationDialog(controller: controller),
    );
  }
}

class _ReceiveMudScrollArea extends StatefulWidget {
  const _ReceiveMudScrollArea({required this.child, required this.minWidth});

  final Widget child;
  final double minWidth;

  @override
  State<_ReceiveMudScrollArea> createState() => _ReceiveMudScrollAreaState();
}

class _ReceiveMudScrollAreaState extends State<_ReceiveMudScrollArea> {
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

class _PremixedMudConcentrationDialog extends StatelessWidget {
  final ReceiveMudController controller;

  _PremixedMudConcentrationDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 800,
        height: 550,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.table_chart_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'MUDPRO+ - Premixed Mud Concentration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Subtitle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.grey.shade50,
              child: Obx(
                () => Text(
                  '${controller.selectedPremixed.value?.description ?? 'N/A'} Concentration',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),

            // Table Header
            _buildTableHeader(),

            // Table Body
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  itemCount: 20,
                  itemBuilder: (context, index) => _buildRow(index),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.tableGridBlue)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(bottom: BorderSide(color: AppTheme.tableGridBlue)),
      ),
      child: const Row(
        children: [
          _HeaderCell(text: '#', width: 40),
          _HeaderCell(text: 'Product', flex: 3),
          _HeaderCell(text: 'Code', flex: 2),
          _HeaderCell(text: 'SG', width: 100),
          _HeaderCell(text: 'Conc.', width: 100),
          _HeaderCell(text: 'Unit', width: 100),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.tableGridBlue.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: AppTheme.tableGridBlue)),
            ),
            child: Text('${index + 1}', style: const TextStyle(fontSize: 10)),
          ),
          const Expanded(flex: 3, child: _CellInput()),
          const Expanded(flex: 2, child: _CellInput()),
          const SizedBox(width: 100, child: _CellInput()),
          const SizedBox(width: 100, child: _CellInput()),
          const SizedBox(width: 100, child: _CellInput()),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double? width;
  final int? flex;
  const _HeaderCell({required this.text, this.width, this.flex});
  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.tableGridBlue)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
    return flex != null
        ? Expanded(flex: flex!, child: child)
        : SizedBox(width: width, child: child);
  }
}

class _CellInput extends StatelessWidget {
  const _CellInput();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.tableGridBlue)),
      ),
      child: const TextField(
        style: TextStyle(fontSize: 10),
        cursorHeight: 12,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
