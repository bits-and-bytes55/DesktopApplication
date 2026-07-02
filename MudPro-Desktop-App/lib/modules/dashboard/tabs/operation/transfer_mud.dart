import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class TransferMudView extends StatefulWidget {
  const TransferMudView({super.key, required this.instanceKey});

  final String instanceKey;

  @override
  State<TransferMudView> createState() => _TransferMudViewState();
}

class _TransferMudViewState extends State<TransferMudView> {
  final DashboardController dashboardController =
      Get.find<DashboardController>();
  final PitController pitController = Get.put(PitController());

  final RxInt selectedRow = 0.obs;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  static const String kActiveSystem = 'Active System';
  static const String kEmpty = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant TransferMudView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instanceKey != widget.instanceKey) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      await pitController.fetchSelectedPits();
      await pitController.fetchUnselectedPits();
      await pitController.setTransferMudInstanceKey(widget.instanceKey);
      // Initialize selectedFromPit if it's currently empty
      if (pitController.selectedFromPit.value.isEmpty) {
        pitController.selectedFromPit.value = kActiveSystem;
      }
    } catch (e) {
      debugPrint("Error loading pits: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildControlRow(),
              const SizedBox(height: 16),

              // Transfer Table
              _buildTransferTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlRow() {
    return Row(
      children: [
        _buildNotTreatedSection(),
        const Spacer(),
        _buildFromSection(),
      ],
    );
  }

  Widget _buildFromSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "From",
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 180,
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.tableGridBlue),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Obx(() {
              final transferPitOptions =
                  pitController.transferDestinationOptions;

              return ColoredBox(
                color: dashboardController.isLocked.value
                    ? operationLockedEditableColor
                    : Colors.white,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                  value: pitController.selectedFromPit.value.isEmpty
                      ? kEmpty
                      : pitController.selectedFromPit.value,
                  isExpanded: true,
                  isDense: true,
                  hint: const SizedBox.shrink(),
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  menuMaxHeight: 200,
                  items: [
                    const DropdownMenuItem<String>(
                      value: kEmpty,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(""),
                      ),
                    ),
                    const DropdownMenuItem<String>(
                      value: kActiveSystem,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          kActiveSystem,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    ...transferPitOptions
                        .where((pitName) => pitName != kActiveSystem)
                        .map((pitName) {
                          return DropdownMenuItem<String>(
                            value: pitName,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                pitName,
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }),
                  ],
                  onChanged: dashboardController.isLocked.value
                      ? null
                      : (String? value) {
                          if (value != null) {
                            pitController.selectedFromPit.value = value;
                            pitController.normalizeTransferRowsForSource();
                          }
                        },
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Icon(Icons.settings, size: 14, color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildNotTreatedSection() {
    return Obx(
      () => Row(
        children: [
          InkWell(
            onTap: dashboardController.isLocked.value
                ? null
                : () {
                    pitController.notTreatedMud.value =
                        !pitController.notTreatedMud.value;
                  },
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(
                  color: pitController.notTreatedMud.value
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
                color: pitController.notTreatedMud.value
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: pitController.notTreatedMud.value
                  ? Icon(Icons.check, size: 12, color: AppTheme.primaryColor)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Not Treated Mud",
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth > 720 ? constraints.maxWidth : 720.0)
            : 640.0;
        final pitWidth = tableWidth * 0.65;
        final volumeWidth = tableWidth - pitWidth;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.tableGridBlue),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SizedBox(
            height: 330,
            child: Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.vertical,
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
                    width: tableWidth,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.tableHeaderBlue,
                            border: Border(
                              bottom: BorderSide(color: AppTheme.tableGridBlue),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildHeaderCell("Pit", pitWidth),
                              _buildHeaderCell("Vol. (bbl)", volumeWidth),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Obx(
                            () => SingleChildScrollView(
                              controller: _verticalScrollController,
                              child: Column(
                                children: List.generate(
                                  pitController.transferRows.length,
                                  (index) {
                                    final row =
                                        pitController.transferRows[index];
                                    final isSelected =
                                        selectedRow.value == index;

                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => selectedRow.value = index,
                                      onSecondaryTapDown:
                                          dashboardController.isLocked.value
                                          ? null
                                          : (details) => _showTransferRowMenu(
                                              details,
                                              index,
                                            ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: index % 2 == 0
                                              ? Colors.white
                                              : Colors.grey.shade50,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            _buildPitDropdownCell(
                                              row,
                                              index,
                                              isSelected,
                                              pitWidth,
                                            ),
                                            _buildVolumeCell(row, volumeWidth),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
        );
      },
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.tableHeaderBlue,
        border: Border(
          right: BorderSide(color: AppTheme.tableGridBlue, width: 0.5),
        ),
      ),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildPitDropdownCell(
    TransferRowData row,
    int index,
    bool isSelected,
    double width,
  ) {
    final destinationOptions = pitController.transferDestinationOptions;
    final selectedValue = destinationOptions.contains(row.pitName)
        ? row.pitName
        : kEmpty;

    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: dashboardController.isLocked.value
            ? operationLockedEditableColor
            : Colors.transparent,
        border: Border(
          right: BorderSide(color: AppTheme.tableGridBlue, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Dropdown icon - logic: show if 1st row or if currently selected
          Opacity(
            opacity: (index == 0 || isSelected) ? 1.0 : 0.0,
            child: Icon(
              isSelected ? Icons.arrow_drop_down : Icons.arrow_right,
              size: 16,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 4),

          // Dropdown
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                isDense: true,
                icon: const SizedBox.shrink(),
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 11,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
                menuMaxHeight: 250,
                // Build the items list: empty + Active System + storage pits
                items: [
                  const DropdownMenuItem<String>(
                    value: kEmpty,
                    child: Text("", style: TextStyle(fontSize: 10)),
                  ),
                  ...destinationOptions.map((pitName) {
                    return DropdownMenuItem<String>(
                      value: pitName,
                      child: Text(
                        pitName,
                        style: AppTheme.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: dashboardController.isLocked.value
                    ? null
                    : (String? value) {
                        if (value != null) {
                          selectedRow.value = index;
                          row.pitName = value;
                          pitController.transferRows.refresh();
                          pitController.checkAndAddTransferRow();
                          pitController.scheduleTransferMudAutoSave();
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCell(TransferRowData row, double width) {
    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: dashboardController.isLocked.value
            ? operationLockedEditableColor
            : Colors.transparent,
        border: Border(
          right: BorderSide(color: AppTheme.tableGridBlue, width: 0.5),
        ),
      ),
      child: TextField(
        controller: row.volumeController,
        enabled: !dashboardController.isLocked.value,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: InputBorder.none,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        onChanged: (val) {
          row.volume = val;
          pitController.scheduleTransferMudAutoSave();
        },
      ),
    );
  }

  bool _rowHasData(TransferRowData row) {
    return row.pitName.trim().isNotEmpty ||
        row.volume.trim().isNotEmpty ||
        (row.savedId ?? '').isNotEmpty;
  }

  Future<void> _showTransferRowMenu(TapDownDetails details, int index) async {
    if (index < 0 || index >= pitController.transferRows.length) return;
    selectedRow.value = index;
    final row = pitController.transferRows[index];
    final hasData = _rowHasData(row);

    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        const PopupMenuItem<String>(value: 'insert', child: Text('Insert Row')),
        PopupMenuItem<String>(
          value: hasData ? 'clear' : null,
          enabled: hasData,
          child: const Text('Clear Row'),
        ),
        PopupMenuItem<String>(
          value: hasData ? 'delete' : null,
          enabled: hasData,
          child: const Text('Delete Row'),
        ),
      ],
    );

    if (action == null) return;
    switch (action) {
      case 'insert':
        pitController.insertTransferRowAfter(index);
        break;
      case 'clear':
        await pitController.clearTransferRow(index);
        break;
      case 'delete':
        await pitController.deleteTransferRow(index);
        break;
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }
}
