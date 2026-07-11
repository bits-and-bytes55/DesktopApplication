import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

PopupMenuItem<String> _menuItem(
  String value,
  String label,
  String shortcut, {
  bool enabled = true,
}) {
  final color = enabled ? Colors.black87 : Colors.grey.shade400;
  return PopupMenuItem<String>(
    value: enabled ? value : null,
    enabled: enabled,
    height: 30,
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 11, color: color)),
        ),
        Text(shortcut, style: TextStyle(fontSize: 11, color: color)),
      ],
    ),
  );
}

Future<String?> showOperationRowMenu({
  required BuildContext context,
  required TapDownDetails details,
  required bool canEdit,
  required bool hasData,
  required bool canPaste,
  bool canInsertRow = true,
  bool canDeleteRow = true,
  bool canMoveTop = false,
  bool canMoveBottom = false,
}) {
  return showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      details.globalPosition.dx,
      details.globalPosition.dy,
      details.globalPosition.dx,
      details.globalPosition.dy,
    ),
    items: [
      _menuItem('cut', 'Cut', 'Ctrl+X', enabled: canEdit && hasData),
      _menuItem('copy', 'Copy', 'Ctrl+C', enabled: hasData),
      _menuItem('paste', 'Paste', 'Ctrl+V', enabled: canEdit && canPaste),
      _menuItem('delete', 'Delete', 'Delete', enabled: canEdit && hasData),
      const PopupMenuDivider(height: 4),
      _menuItem(
        'insertRow',
        'Insert Row',
        'Shift+Insert',
        enabled: canEdit && canInsertRow,
      ),
      _menuItem(
        'deleteRow',
        'Delete Row',
        'Shift+Delete',
        enabled: canEdit && canDeleteRow && hasData,
      ),
      _menuItem('clear', 'Clear', 'Ctrl+Delete', enabled: canEdit && hasData),
      const PopupMenuDivider(height: 4),
      _menuItem('top', 'To the Top', 'Ctrl+Up', enabled: canEdit && canMoveTop),
      _menuItem(
        'bottom',
        'To the Bottom',
        'Ctrl+Down',
        enabled: canEdit && canMoveBottom,
      ),
    ],
  );
}

Future<void> showVolumeByGroupDialog(
  BuildContext context, {
  required double baseFluid,
  required double weightMaterial,
  required double products,
  required double water,
}) {
  final total = baseFluid + weightMaterial + products + water;
  final rows = [
    {'label': 'Base Fluid', 'value': baseFluid},
    {'label': 'Weight Material', 'value': weightMaterial},
    {'label': 'Products', 'value': products},
    {'label': 'Water', 'value': water},
    {'label': 'Total', 'value': total},
  ];

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        child: SizedBox(
          width: 560,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Volume By Group',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Table(
                  border: TableBorder.all(color: AppTheme.tableGridBlue),
                  columnWidths: const {
                    0: FlexColumnWidth(),
                    1: FixedColumnWidth(190),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.tableHeaderBlue),
                      children: [
                        const SizedBox(height: 34),
                        _tableHeader('Vol. (bbl)'),
                      ],
                    ),
                    ...rows.map(
                      (row) => TableRow(
                        children: [
                          _tableCell(row['label'] as String),
                          _tableValueCell(
                            formatOperationNumber(row['value'] as double),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 110,
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('OK'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showCuttingsRetentionDialog({
  required BuildContext context,
  required String initialValue,
  required ValueChanged<String> onAccepted,
}) async {
  final volDrilledController = TextEditingController();
  final mudLossRatioController = TextEditingController();
  final resultController = TextEditingController(
    text: initialValue.trim().isEmpty ? '' : initialValue.trim(),
  );

  void recalculate() {
    if (volDrilledController.text.trim().isEmpty &&
        mudLossRatioController.text.trim().isEmpty) {
      resultController.text = '';
      return;
    }
    final drilled = double.tryParse(volDrilledController.text.trim()) ?? 0.0;
    final ratio = double.tryParse(mudLossRatioController.text.trim()) ?? 0.0;
    final result = drilled * ratio / 100;
    resultController.text = formatOperationNumber(result);
  }

  volDrilledController.addListener(recalculate);
  mudLossRatioController.addListener(recalculate);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return _calculationDialog(
        context: dialogContext,
        title: 'Cuttings/Retention Calculation',
        rows: [
          _CalcRowSpec(
            label: 'Vol. Drilled (bbl)',
            controller: volDrilledController,
            highlight: true,
          ),
          _CalcRowSpec(
            label: 'Mud Loss Ratio (%)',
            controller: mudLossRatioController,
          ),
          _CalcRowSpec(
            label: 'Cuttings/Retention (bbl)',
            controller: resultController,
            readOnly: true,
            highlight: true,
          ),
        ],
        onAccept: () {
          onAccepted(resultController.text.trim());
          Navigator.of(dialogContext).pop();
        },
      );
    },
  );
}

Future<void> showEvaporationDialog({
  required BuildContext context,
  required String initialValue,
  required ValueChanged<String> onAccepted,
}) async {
  final flowlineController = TextEditingController();
  final drillingController = TextEditingController();
  final circulatingController = TextEditingController();
  final resultController = TextEditingController(
    text: initialValue.trim().isEmpty ? '' : initialValue.trim(),
  );

  void recalculate() {
    if (flowlineController.text.trim().isEmpty &&
        drillingController.text.trim().isEmpty &&
        circulatingController.text.trim().isEmpty) {
      resultController.text = '';
      return;
    }
    final flowlineT = double.tryParse(flowlineController.text.trim()) ?? 0.0;
    final drilling = double.tryParse(drillingController.text.trim()) ?? 0.0;
    final circulating =
        double.tryParse(circulatingController.text.trim()) ?? 0.0;
    final activeHours = drilling + circulating;
    final result = flowlineT <= 0 || activeHours <= 0
        ? 0.0
        : ((flowlineT - 32).clamp(0, 9999) * activeHours) / 1000;
    resultController.text = formatOperationNumber(result);
  }

  flowlineController.addListener(recalculate);
  drillingController.addListener(recalculate);
  circulatingController.addListener(recalculate);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return _calculationDialog(
        context: dialogContext,
        title: 'Evaporation Calculation',
        rows: [
          _CalcRowSpec(
            label: 'Flowline T.  (°F)',
            controller: flowlineController,
            highlight: true,
          ),
          _CalcRowSpec(
            label: 'Drilling (hr)',
            controller: drillingController,
            highlight: true,
          ),
          _CalcRowSpec(
            label: 'Circulating (hr)',
            controller: circulatingController,
            highlight: true,
          ),
          _CalcRowSpec(
            label: 'Evaporation (bbl)',
            controller: resultController,
            readOnly: true,
            highlight: true,
          ),
        ],
        onAccept: () {
          onAccepted(resultController.text.trim());
          Navigator.of(dialogContext).pop();
        },
      );
    },
  );
}

Future<List<ProductModel>?> showSelectProductsDialog({
  required BuildContext context,
  required List<ProductModel> products,
  String title = 'Select Products',
}) {
  final selectedKeys = <String>{};
  var sortBy = 'group';
  final sorted = List<ProductModel>.from(products);
  final horizontalController = ScrollController();
  final verticalController = ScrollController();
  const tableWidth = 1112.0;

  void sortList() {
    sorted.sort((a, b) {
      if (sortBy == 'product') {
        return a.product.toLowerCase().compareTo(b.product.toLowerCase());
      }
      final groupCompare = a.group.toLowerCase().compareTo(
        b.group.toLowerCase(),
      );
      if (groupCompare != 0) return groupCompare;
      return a.product.toLowerCase().compareTo(b.product.toLowerCase());
    });
  }

  sortList();

  final dialogFuture = showDialog<List<ProductModel>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            child: SizedBox(
              width: 1080,
              height: 620,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        border: Border(
                          bottom: BorderSide(color: AppTheme.tableGridBlue),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            title,
                            style: AppTheme.bodyLarge.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Sort By',
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Radio<String>(
                          value: 'group',
                          groupValue: sortBy,
                          onChanged: (value) {
                            setState(() {
                              sortBy = value ?? 'group';
                              sortList();
                            });
                          },
                        ),
                        const Text('Group'),
                        const SizedBox(width: 10),
                        Radio<String>(
                          value: 'product',
                          groupValue: sortBy,
                          onChanged: (value) {
                            setState(() {
                              sortBy = value ?? 'product';
                              sortList();
                            });
                          },
                        ),
                        const Text('Product'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.tableGridBlue),
                        ),
                        child: Scrollbar(
                          controller: verticalController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          notificationPredicate: (notification) =>
                              notification.metrics.axis == Axis.vertical,
                          child: Scrollbar(
                            controller: horizontalController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            notificationPredicate: (notification) =>
                                notification.metrics.axis == Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: SingleChildScrollView(
                                  controller: verticalController,
                                  child: Table(
                                    border: TableBorder.symmetric(
                                      inside: BorderSide(
                                        color: AppTheme.tableGridBlue,
                                      ),
                                    ),
                                    columnWidths: const {
                                      0: FixedColumnWidth(42),
                                      1: FixedColumnWidth(220),
                                      2: FixedColumnWidth(320),
                                      3: FixedColumnWidth(140),
                                      4: FixedColumnWidth(120),
                                      5: FixedColumnWidth(150),
                                      6: FixedColumnWidth(120),
                                    },
                                    children: [
                                      TableRow(
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                        ),
                                        children: [
                                          const SizedBox(height: 34),
                                          _tableHeader('Group'),
                                          _tableHeader('Product'),
                                          _tableHeader('Code'),
                                          _tableHeader('SG'),
                                          _tableHeader('Unit'),
                                          _tableHeader('Used'),
                                        ],
                                      ),
                                      ...sorted.map((product) {
                                        final key =
                                            product.id ?? product.product;
                                        final checked = selectedKeys.contains(
                                          key,
                                        );
                                        return TableRow(
                                          children: [
                                            SizedBox(
                                              height: 34,
                                              child: Checkbox(
                                                value: checked,
                                                onChanged: (value) {
                                                  setState(() {
                                                    if (value == true) {
                                                      selectedKeys.add(key);
                                                    } else {
                                                      selectedKeys.remove(key);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            _tableCell(product.group),
                                            _tableCell(product.product),
                                            _tableCell(product.code),
                                            _tableCell(product.sg),
                                            _tableCell(product.formattedUnit),
                                            _tableCell(product.initial),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 36,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(
                                sorted
                                    .where(
                                      (product) => selectedKeys.contains(
                                        product.id ?? product.product,
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  dialogFuture.whenComplete(() {
    horizontalController.dispose();
    verticalController.dispose();
  });
  return dialogFuture;
}

Widget _tableHeader(String label) {
  return SizedBox(
    height: 34,
    child: Center(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    ),
  );
}

Widget _tableCell(String value, {bool highlight = false}) {
  return Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    alignment: Alignment.centerLeft,
    color: highlight ? const Color(0xFFFFF9CC) : Colors.white,
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black,
        fontWeight: FontWeight.w700,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );
}

Widget _tableValueCell(String value) {
  return Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    alignment: Alignment.centerRight,
    color: const Color(0xFFFFF9CC),
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _CalcRowSpec {
  const _CalcRowSpec({
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.highlight = false,
  });

  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final bool highlight;
}

Widget _calculationDialog({
  required BuildContext context,
  required String title,
  required List<_CalcRowSpec> rows,
  required VoidCallback onAccept,
}) {
  return Dialog(
    insetPadding: const EdgeInsets.all(24),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    child: SizedBox(
      width: 720,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Table(
              border: TableBorder.all(color: AppTheme.tableGridBlue),
              columnWidths: const {
                0: FlexColumnWidth(),
                1: FixedColumnWidth(220),
              },
              children: rows
                  .map(
                    (row) => TableRow(
                      children: [
                        _tableCell(row.label),
                        Container(
                          height: 34,
                          color: row.highlight
                              ? const Color(0xFFFFF9CC)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerRight,
                          child: TextField(
                            controller: row.controller,
                            readOnly: row.readOnly,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 110,
                  height: 34,
                  child: OutlinedButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
