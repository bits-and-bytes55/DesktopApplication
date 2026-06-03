import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_loss_storage_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudLossStorageView extends StatefulWidget {
  const MudLossStorageView({super.key, required this.instanceKey});

  final String instanceKey;

  @override
  State<MudLossStorageView> createState() => _MudLossStorageViewState();
}

class _MudLossStorageViewState extends State<MudLossStorageView> {
  final DashboardController dashboardController =
      Get.find<DashboardController>();
  final PitController pitController = Get.find<PitController>();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  late final MudLossStorageController controller;
  static Map<String, String>? _rowClipboard;

  int selectedRowIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      MudLossStorageController(instanceKey: widget.instanceKey),
      tag: widget.instanceKey,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await pitController.fetchUnselectedPits();
      await controller.load();
    });
  }

  @override
  void dispose() {
    unawaited(controller.flushPendingAutoSave());
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mud Loss - Storage',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth < 720
                      ? 720.0
                      : constraints.maxWidth;
                  return Scrollbar(
                    controller: _verticalScrollController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.metrics.axis == Axis.vertical,
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      child: Scrollbar(
                        controller: _horizontalScrollController,
                        thumbVisibility: constraints.maxWidth < 720,
                        notificationPredicate: (notification) =>
                            notification.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onSecondaryTapDown: (details) =>
                                _handleTableRightClick(context, details),
                            child: SizedBox(
                              width: tableWidth,
                              child: Table(
                                border: TableBorder.all(
                                  color: Colors.grey.shade400,
                                  width: 1,
                                ),
                                columnWidths: const {
                                  0: FixedColumnWidth(28),
                                  1: FixedColumnWidth(42),
                                  2: FlexColumnWidth(2.1),
                                  3: FlexColumnWidth(1.25),
                                  4: FlexColumnWidth(1.25),
                                  5: FlexColumnWidth(1.25),
                                },
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                children: [
                                  _headerRow(),
                                  ...List.generate(controller.rows.length, (
                                    index,
                                  ) {
                                    return _dataRow(
                                      index,
                                      controller.rows[index],
                                    );
                                  }),
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
            }),
          ),
        ],
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: const BoxDecoration(color: AppTheme.primaryColor),
      children: [
        _headerCell(''),
        _headerCell(''),
        _headerCell('Storage'),
        _headerCell('Dump\n(bbl)'),
        _headerCell('Evaporation\n(bbl)'),
        _headerCell('Pit Cleaning\n(bbl)'),
      ],
    );
  }

  TableRow _dataRow(int index, MudLossStorageEntry row) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        _selectorCell(index),
        _numberCell(index),
        _storageCell(row),
        _inputCell(row.dumpController, row.dump),
        _inputCell(row.evaporationController, row.evaporation),
        _inputCell(row.pitCleaningController, row.pitCleaning),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _selectorCell(int index) {
    return InkWell(
      onTap: () => setState(() => selectedRowIndex = index),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        child: selectedRowIndex == index
            ? Icon(Icons.arrow_right, size: 17, color: Colors.grey.shade700)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _numberCell(int index) {
    return InkWell(
      onTap: () => setState(() => selectedRowIndex = index),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        child: Text(
          '${index + 1}',
          style: AppTheme.bodySmall.copyWith(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _storageCell(MudLossStorageEntry row) {
    return Obx(() {
      final names = pitController.unselectedPits
          .map((pit) => pit.pitName.trim())
          .where((name) => name.isNotEmpty)
          .toList();
      final current = row.storage.value.trim();
      if (current.isNotEmpty && !names.contains(current)) {
        names.insert(0, current);
      }
      final selectedValue = current.isEmpty || !names.contains(current)
          ? null
          : current;

      return SizedBox(
        height: 32,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            isDense: true,
            hint: const SizedBox.shrink(),
            icon: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: dashboardController.isLocked.value
                    ? Colors.grey.shade400
                    : Colors.grey.shade700,
              ),
            ),
            style: AppTheme.bodySmall.copyWith(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 220,
            items: names.map((pitName) {
              return DropdownMenuItem<String>(
                value: pitName,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    pitName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: dashboardController.isLocked.value
                ? null
                : (value) {
                    if (value == null) return;
                    row.storage.value = value;
                    controller.ensureTrailingRow();
                    controller.scheduleAutoSave();
                  },
          ),
        ),
      );
    });
  }

  Widget _inputCell(TextEditingController textController, RxString value) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: textController,
        enabled: !dashboardController.isLocked.value,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 12,
          color: Colors.black87,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          filled: true,
          fillColor: dashboardController.isLocked.value
              ? Colors.grey.shade100
              : Colors.white,
        ),
        onTap: () {
          final index = controller.rows.indexWhere(
            (row) =>
                row.dumpController == textController ||
                row.evaporationController == textController ||
                row.pitCleaningController == textController,
          );
          if (index >= 0) {
            setState(() => selectedRowIndex = index);
          }
        },
        onChanged: (text) {
          value.value = text;
          controller.ensureTrailingRow();
          controller.scheduleAutoSave();
        },
      ),
    );
  }

  void _handleTableRightClick(BuildContext context, TapDownDetails details) {
    const headerHeight = 48.0;
    const rowHeight = 32.0;
    final localY = details.localPosition.dy;
    if (localY >= headerHeight) {
      final rowIndex = ((localY - headerHeight) / rowHeight).floor();
      if (rowIndex >= 0 && rowIndex < controller.rows.length) {
        setState(() => selectedRowIndex = rowIndex);
      }
    }
    _showContextMenu(context, details.globalPosition);
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    if (dashboardController.isLocked.value) return;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        _menuItem('cut', Icons.content_cut, 'Cut'),
        _menuItem('copy', Icons.copy, 'Copy'),
        _menuItem('paste', Icons.content_paste, 'Paste'),
        _menuItem('save', Icons.save_outlined, 'Save'),
        _menuItem('delete', Icons.delete_outline, 'Delete'),
        _menuItem('clear', Icons.clear, 'Clear'),
      ],
    );
    if (selected == null || selectedRowIndex >= controller.rows.length) {
      return;
    }

    final row = controller.rows[selectedRowIndex];
    switch (selected) {
      case 'cut':
        _rowClipboard = controller.rowSnapshot(row);
        await _runRowAction(controller.deleteRow(row));
        break;
      case 'copy':
        _rowClipboard = controller.rowSnapshot(row);
        break;
      case 'paste':
        final snapshot = _rowClipboard;
        if (snapshot == null) return;
        controller.applyRowSnapshot(row, snapshot);
        await _runRowAction(controller.save());
        break;
      case 'save':
        await _runRowAction(controller.save());
        break;
      case 'delete':
        await _runRowAction(controller.deleteRow(row));
        break;
      case 'clear':
        await _runRowAction(controller.deleteRow(row));
        break;
    }
    if (mounted) setState(() {});
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runRowAction(Future<Map<String, dynamic>> action) async {
    final result = await action;
    if (result['success'] == true) return;
    Get.snackbar(
      'Mud Loss - Storage',
      (result['message'] ?? 'Action failed').toString(),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }
}
