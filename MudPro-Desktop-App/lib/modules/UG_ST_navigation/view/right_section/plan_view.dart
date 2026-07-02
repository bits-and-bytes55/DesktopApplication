import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/well_setup_ui_pattern.dart';

const int _planVisibleRows = 18;

const double _planIndexWidth = 44.0;
const double _planSummaryHeight = 32.0;
const double _planRowHeight = 31.0;
const double _planHeaderTopHeight = 34.0;
const double _planHeaderBottomHeight = 24.0;

const Color _planBorder = wellSetupBorder;
const Color _planHeader = wellSetupColumnHeader;
const Color _planLockedCell = wellSetupLockedEditable;
const Color _planEditableCell = Colors.white;
const Color _planSelectedCell = Color(0xFFEAF2FF);

class _PlanFixedColumn {
  final String title;
  final double width;

  const _PlanFixedColumn(this.title, this.width);
}

class _PlanGroupColumn {
  final String title;
  final double width;

  const _PlanGroupColumn(this.title, this.width);
}

const _planFixedColumns = <_PlanFixedColumn>[
  _PlanFixedColumn('MD\n(ft)', 116),
  _PlanFixedColumn('Days\n(-)', 92),
  _PlanFixedColumn('Cost\n(Kwd)', 96),
];

const _planGroupedColumns = <_PlanGroupColumn>[
  _PlanGroupColumn('MW\n(ppg)', 82),
  _PlanGroupColumn('Viscosity\n(sec/qt)', 82),
  _PlanGroupColumn('PV\n(cP)', 82),
  _PlanGroupColumn('YP\n(lbf/100ft2)', 82),
  _PlanGroupColumn('API Filtrate\n(mL/30min)', 82),
  _PlanGroupColumn('HTHP Filtrate\n(mL/30min)', 82),
  _PlanGroupColumn('pH', 70),
  _PlanGroupColumn('6 RPM\n(-)', 82),
  _PlanGroupColumn('WPS\n(ppm)', 82),
  _PlanGroupColumn('Elec. Stab.\n(Volt)', 82),
  _PlanGroupColumn('Water Act\n(AW)', 82),
  _PlanGroupColumn('Oil Ratio\n(%)', 82),
  _PlanGroupColumn('Excess Lime\n(lb/bbl)', 82),
  _PlanGroupColumn('LGS\n(%)', 82),
];

double get _planTableWidth {
  var width = _planIndexWidth;
  for (final column in _planFixedColumns) {
    width += column.width;
  }
  for (final group in _planGroupedColumns) {
    width += group.width * 2;
  }
  return width + 2;
}

class PlanPageView extends StatefulWidget {
  const PlanPageView({super.key});

  @override
  State<PlanPageView> createState() => _PlanPageViewState();
}

class _PlanPageViewState extends State<PlanPageView> {
  late final UgStController c;
  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _verticalScroll = ScrollController();
  final TextEditingController _tdController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  int _selectedRowIndex = -1;
  List<String>? _clipboardRow;

  @override
  void initState() {
    super.initState();
    c = Get.find<UgStController>();
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    _verticalScroll.dispose();
    _tdController.dispose();
    _daysController.dispose();
    _totalCostController.dispose();
    super.dispose();
  }

  bool get _locked => c.isLocked.value;

  void _syncSummaryControllers() {
    final summary = c.summaryData;
    final tdValue = summary.isNotEmpty ? (summary[0]['amount'] ?? '') : '';
    final daysValue = summary.length > 1 ? (summary[1]['amount'] ?? '') : '';
    final totalCostValue = summary.length > 2
        ? (summary[2]['amount'] ?? '')
        : '';
    _syncController(_tdController, tdValue);
    _syncController(_daysController, daysValue);
    _syncController(_totalCostController, totalCostValue);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _syncSummaryControllers();
      final rowCount = c.planData.length > _planVisibleRows
          ? c.planData.length
          : _planVisibleRows;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryStrip(),
            const SizedBox(height: 6),
            Expanded(
              child: Scrollbar(
                controller: _horizontalScroll,
                thumbVisibility: true,
                trackVisibility: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _planTableWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _planBorder),
                      ),
                      child: Column(
                        children: [
                          _header(),
                          Expanded(
                            child: c.isPlanLoading.value && c.planData.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _body(rowCount),
                          ),
                          _footer(),
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
    });
  }

  Widget _summaryStrip() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 602,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _planBorder),
          ),
          child: Column(
            children: [
              _summaryRow('TD', _tdController, AppUnits.unitText('(ft)'), 0),
              _summaryRow('Days', _daysController, '(-)', 1),
              _summaryRow(
                'Total Cost',
                _totalCostController,
                '(Kwd)',
                2,
                hasBottomBorder: false,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _iconButton(
          tooltip: 'Apply Summary To Row',
          icon: Icons.bolt_outlined,
          onTap: _locked ? null : _applySummaryToRow,
        ),
      ],
    );
  }

  int _nextSummaryTargetRow() {
    for (var index = 0; index < c.planData.length; index++) {
      final row = c.planData[index];
      final md = row.isNotEmpty ? row[0].trim() : '';
      final days = row.length > 1 ? row[1].trim() : '';
      final cost = row.length > 2 ? row[2].trim() : '';
      if (md.isEmpty && days.isEmpty && cost.isEmpty) {
        return index;
      }
    }
    return c.planData.isEmpty ? 0 : c.planData.length - 1;
  }

  void _applySummaryToRow() {
    final targetRow = _nextSummaryTargetRow();
    c.updatePlanData(
      targetRow,
      0,
      _tdController.text,
      notify: false,
      autoSave: false,
    );
    c.updatePlanData(
      targetRow,
      1,
      _daysController.text,
      notify: false,
      autoSave: false,
    );
    c.updatePlanData(
      targetRow,
      2,
      _totalCostController.text,
      notify: false,
      autoSave: false,
    );
    c.planData.refresh();
    c.schedulePlanAutoSave();
    setState(() => _selectedRowIndex = targetRow);
  }

  Widget _summaryRow(
    String label,
    TextEditingController controller,
    String unit,
    int summaryIndex, {
    bool hasBottomBorder = true,
  }) {
    return SizedBox(
      height: _planSummaryHeight,
      child: Row(
        children: [
          _summaryStaticCell(
            label,
            272,
            hasBottomBorder: hasBottomBorder,
            textAlign: TextAlign.left,
          ),
          _summaryEditorCell(
            controller: controller,
            width: 228,
            summaryIndex: summaryIndex,
            hasBottomBorder: hasBottomBorder,
          ),
          _summaryStaticCell(
            unit,
            100,
            hasBottomBorder: hasBottomBorder,
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _summaryStaticCell(
    String text,
    double width, {
    required bool hasBottomBorder,
    required TextAlign textAlign,
  }) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: textAlign == TextAlign.left
          ? Alignment.centerLeft
          : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: wellSetupReadOnlyFill,
        border: Border(
          right: const BorderSide(color: _planBorder),
          bottom: hasBottomBorder
              ? const BorderSide(color: _planBorder)
              : BorderSide.none,
        ),
      ),
      child: Text(
        text,
        textAlign: textAlign,
        style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _summaryEditorCell({
    required TextEditingController controller,
    required double width,
    required int summaryIndex,
    required bool hasBottomBorder,
  }) {
    return Container(
      width: width,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _locked ? _planLockedCell : _planEditableCell,
        border: Border(
          right: const BorderSide(color: _planBorder),
          bottom: hasBottomBorder
              ? const BorderSide(color: _planBorder)
              : BorderSide.none,
        ),
      ),
      alignment: Alignment.centerRight,
      child: TextField(
        controller: controller,
        readOnly: _locked,
        textAlign: TextAlign.right,
        onChanged: (value) =>
            c.updateSummaryData(summaryIndex, 'amount', value),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _iconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _planBorder),
          ),
          child: Icon(
            icon,
            size: 14,
            color: onTap == null
                ? const Color(0xFF9EA4AD)
                : const Color(0xFF1976D2),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Row(
          children: [
            _headerCell('', _planIndexWidth, _planHeaderTopHeight),
            for (final column in _planFixedColumns)
              _headerCell(
                AppUnits.label(column.title),
                column.width,
                _planHeaderTopHeight,
              ),
            for (final group in _planGroupedColumns)
              _headerCell(
                AppUnits.label(group.title),
                group.width * 2,
                _planHeaderTopHeight,
              ),
          ],
        ),
        Row(
          children: [
            _headerCell(
              '',
              _planIndexWidth,
              _planHeaderBottomHeight,
              highlighted: false,
            ),
            for (final column in _planFixedColumns)
              _headerCell(
                '',
                column.width,
                _planHeaderBottomHeight,
                highlighted: false,
              ),
            for (final group in _planGroupedColumns) ...[
              _headerCell(
                'L',
                group.width,
                _planHeaderBottomHeight,
                highlighted: false,
              ),
              _headerCell(
                'H',
                group.width,
                _planHeaderBottomHeight,
                highlighted: false,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _headerCell(
    String text,
    double width,
    double height, {
    bool highlighted = true,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          right: const BorderSide(color: _planBorder),
          bottom: const BorderSide(color: _planBorder),
        ),
        color: _planHeader,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _body(int rowCount) {
    return Scrollbar(
      controller: _verticalScroll,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _verticalScroll,
        itemCount: rowCount,
        itemExtent: _planRowHeight,
        itemBuilder: (context, index) {
          final row = index < c.planData.length
              ? List<String>.from(c.planData[index])
              : List<String>.filled(31, '');
          return _PlanDataRow(
            key: ValueKey('plan_row_$index'),
            rowIndex: index,
            values: row,
            locked: _locked,
            selected: _selectedRowIndex == index,
            clipboardAvailable: _clipboardRow != null,
            onSelected: () => setState(() => _selectedRowIndex = index),
            onValueChanged: (colIndex, value) {
              c.updatePlanData(index, colIndex, value);
            },
            onMenuAction: (action) => _handleRowAction(index, action),
          );
        },
      ),
    );
  }

  Widget _footer() {
    return Container(
      height: 28,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _planBorder)),
      ),
      child: Text(
        'L: Low; H: High',
        style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
      ),
    );
  }

  Future<void> _handleRowAction(int index, String action) async {
    setState(() => _selectedRowIndex = index);
    final row = index < c.planData.length
        ? List<String>.from(c.planData[index])
        : List<String>.filled(31, '');
    final hasData = row.any((value) => value.trim().isNotEmpty);

    switch (action) {
      case 'add_before':
        if (!_locked) c.insertPlanRow(index);
        break;
      case 'add_after':
        if (!_locked) c.insertPlanRow(index + 1);
        break;
      case 'copy':
        if (hasData) {
          _clipboardRow = List<String>.from(row);
        }
        break;
      case 'cut':
        if (!_locked && hasData) {
          _clipboardRow = List<String>.from(row);
          c.deletePlanRow(index);
        }
        break;
      case 'paste':
        if (!_locked && _clipboardRow != null) {
          c.replacePlanRow(index, _clipboardRow!);
        }
        break;
      case 'delete':
        if (!_locked) {
          c.deletePlanRow(index);
        }
        break;
      case 'top':
        if (!_locked) {
          c.movePlanRowToTop(index);
          setState(() => _selectedRowIndex = 0);
        }
        break;
      case 'bottom':
        if (!_locked) {
          c.movePlanRowToBottom(index);
          setState(() => _selectedRowIndex = c.planData.length - 1);
        }
        break;
    }
    setState(() {});
  }
}

class _PlanDataRow extends StatefulWidget {
  final int rowIndex;
  final List<String> values;
  final bool locked;
  final bool selected;
  final bool clipboardAvailable;
  final VoidCallback onSelected;
  final void Function(int colIndex, String value) onValueChanged;
  final ValueChanged<String> onMenuAction;

  const _PlanDataRow({
    super.key,
    required this.rowIndex,
    required this.values,
    required this.locked,
    required this.selected,
    required this.clipboardAvailable,
    required this.onSelected,
    required this.onValueChanged,
    required this.onMenuAction,
  });

  @override
  State<_PlanDataRow> createState() => _PlanDataRowState();
}

class _PlanDataRowState extends State<_PlanDataRow> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.values
        .map((value) => TextEditingController(text: value))
        .toList(growable: false);
  }

  @override
  void didUpdateWidget(covariant _PlanDataRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var index = 0; index < _controllers.length; index++) {
      final nextValue = index < widget.values.length
          ? widget.values[index]
          : '';
      _syncController(_controllers[index], nextValue);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton) {
          widget.onSelected();
          _openMenu(event.position);
        } else if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kPrimaryMouseButton) {
          widget.onSelected();
        }
      },
      child: Row(
        children: [
          _indexCell(),
          _fixedEditorCell(
            _controllers[0],
            _planFixedColumns[0].width,
            0,
            textAlign: TextAlign.right,
          ),
          _fixedEditorCell(
            _controllers[1],
            _planFixedColumns[1].width,
            1,
            textAlign: TextAlign.right,
          ),
          _fixedEditorCell(
            _controllers[2],
            _planFixedColumns[2].width,
            2,
            textAlign: TextAlign.right,
          ),
          for (var colIndex = 3; colIndex < _controllers.length; colIndex++)
            _groupEditorCell(_controllers[colIndex], colIndex),
        ],
      ),
    );
  }

  Widget _indexCell() {
    return Container(
      width: _planIndexWidth,
      height: _planRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: widget.selected ? _planSelectedCell : Colors.white,
        border: const Border(
          right: BorderSide(color: _planBorder),
          bottom: BorderSide(color: _planBorder),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: widget.selected
                ? const Icon(
                    Icons.play_arrow,
                    size: 10,
                    color: Color(0xFF5E5E5E),
                  )
                : null,
          ),
          const Spacer(),
          Text(
            '${widget.rowIndex + 1}',
            style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _fixedEditorCell(
    TextEditingController controller,
    double width,
    int colIndex, {
    required TextAlign textAlign,
  }) {
    return _editorCell(
      controller: controller,
      width: width,
      colIndex: colIndex,
      textAlign: textAlign,
    );
  }

  Widget _groupEditorCell(TextEditingController controller, int colIndex) {
    final groupIndex = ((colIndex - 3) ~/ 2);
    final width = _planGroupedColumns[groupIndex].width;
    return _editorCell(
      controller: controller,
      width: width,
      colIndex: colIndex,
      textAlign: TextAlign.right,
    );
  }

  Widget _editorCell({
    required TextEditingController controller,
    required double width,
    required int colIndex,
    required TextAlign textAlign,
  }) {
    return Container(
      width: width,
      height: _planRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: _planBorder),
          bottom: BorderSide(color: _planBorder),
        ),
      ),
      child: ColoredBox(
        color: widget.locked ? _planLockedCell : _planEditableCell,
        child: SizedBox.expand(
          child: Align(
            alignment: textAlign == TextAlign.right
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: TextField(
              controller: controller,
              readOnly: widget.locked,
              textAlign: textAlign,
              onChanged: (value) => widget.onValueChanged(colIndex, value),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
              ),
              style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu(Offset position) async {
    final hasData = widget.values.any((value) => value.trim().isNotEmpty);
    final canEdit = !widget.locked;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        _menuItem('add_before', 'Add Before', enabled: canEdit),
        _menuItem('add_after', 'Add After', enabled: canEdit),
        const PopupMenuDivider(),
        _menuItem('cut', 'Cut', enabled: canEdit && hasData),
        _menuItem('copy', 'Copy', enabled: hasData),
        _menuItem(
          'paste',
          'Paste',
          enabled: canEdit && widget.clipboardAvailable,
        ),
        _menuItem('delete', 'Delete', enabled: canEdit),
        const PopupMenuDivider(),
        _menuItem(
          'top',
          'To the Top',
          enabled: canEdit && hasData && widget.rowIndex > 0,
        ),
        _menuItem('bottom', 'To the Bottom', enabled: canEdit && hasData),
      ],
    );

    if (result != null) {
      widget.onMenuAction(result);
    }
  }

  PopupMenuEntry<String> _menuItem(
    String value,
    String label, {
    required bool enabled,
  }) {
    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      height: 28,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: enabled ? Colors.black : const Color(0xFF9EA4AD),
        ),
      ),
    );
  }
}

void _syncController(TextEditingController controller, String nextValue) {
  if (controller.text == nextValue) return;
  final selection = controller.selection;
  controller.value = controller.value.copyWith(
    text: nextValue,
    selection: selection.baseOffset <= nextValue.length
        ? selection
        : TextSelection.collapsed(offset: nextValue.length),
    composing: TextRange.empty,
  );
}
