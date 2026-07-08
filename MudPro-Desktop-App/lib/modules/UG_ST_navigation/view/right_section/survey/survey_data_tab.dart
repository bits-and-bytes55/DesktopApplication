import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/survey_model.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_import_dialog.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_point_calculation_dialog.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/well_setup_ui_pattern.dart';

class SurveyDataTab extends StatefulWidget {
  const SurveyDataTab({super.key});

  @override
  State<SurveyDataTab> createState() => _SurveyDataTabState();
}

class _SurveyDataTabState extends State<SurveyDataTab> {
  final SurveyController controller = Get.find<SurveyController>();
  final ScrollController _stationScrollController = ScrollController();
  final ScrollController _annotationScrollController = ScrollController();

  static const _gridBorder = wellSetupBorder;
  static const _readOnlyBg = wellSetupReadOnlyFill;
  static const _lockedBg = wellSetupLockedEditable;

  @override
  void dispose() {
    _stationScrollController.dispose();
    _annotationScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const toolbarWidth = 42.0;
        const gap = 8.0;
        const targetTableWidth = 860.0;
        const minAnnotationWidth = 360.0;
        const maxAnnotationWidth = 560.0;

        var annotationWidth = (constraints.maxWidth * 0.33).clamp(
          minAnnotationWidth,
          maxAnnotationWidth,
        );
        var tableWidth =
            constraints.maxWidth - annotationWidth - toolbarWidth - (gap * 2);

        if (tableWidth < targetTableWidth) {
          final reduceBy = targetTableWidth - tableWidth;
          annotationWidth = math.max(
            minAnnotationWidth,
            annotationWidth - reduceBy,
          );
          tableWidth =
              constraints.maxWidth - annotationWidth - toolbarWidth - (gap * 2);
        }

        final leftWidths = _fitWidths(tableWidth - 2, const [
          36,
          84,
          84,
          84,
          80,
          80,
          86,
          86,
          104,
        ]);
        final annotationWidths = _fitWidths(annotationWidth - 2, const [
          42,
          112,
          198,
          102,
        ]);

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: tableWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _surveyTable(leftWidths)),
                          const SizedBox(height: 8),
                          _projectAziRow(),
                        ],
                      ),
                    ),
                    const SizedBox(width: gap),
                    _surveyToolbar(context),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: annotationWidth,
                      child: _annotationPanel(annotationWidths),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _surveyTable(List<double> widths) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _gridBorder),
        color: Colors.white,
      ),
      child: Column(
        children: [
          _gridRow(
            widths: widths,
            header: true,
            cells: [
              '',
              'MD\n${AppUnits.unitText('(ft)')}',
              'Inc\n${AppUnits.unitText('(°)')}',
              'Azi\n${AppUnits.unitText('(°)')}',
              'TVD\n${AppUnits.unitText('(ft)')}',
              'Vsec\n${AppUnits.unitText('(ft)')}',
              'N+/S-\n${AppUnits.unitText('(ft)')}',
              'E+/W-\n${AppUnits.unitText('(ft)')}',
              'Dogleg\n${AppUnits.dogleg}',
            ],
          ),
          Expanded(
            child: Obx(
              () => Scrollbar(
                controller: _stationScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _stationScrollController,
                  child: Column(
                    children: List.generate(
                      controller.stations.length,
                      (index) => _stationRow(
                        context: Get.context!,
                        index: index,
                        row: controller.stations[index],
                        widths: widths,
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
  }

  Widget _stationRow({
    required BuildContext context,
    required int index,
    required SurveyStationRow row,
    required List<double> widths,
  }) {
    return Obx(() {
      final selected = controller.selectedStationIndex.value == index;
      final canEdit = !controller.isLocked && !controller.plannedSurvey.value;
      return GestureDetector(
        onTap: () => controller.selectStation(index),
        onSecondaryTapDown: (details) async {
          controller.selectStation(index);
          final action = await _showCrudMenu(
            context: context,
            position: details.globalPosition,
            allowPaste: controller.hasStationClipboard,
            canDelete: canEdit && row.hasAnyData,
            canMoveTop: canEdit && row.hasAnyData && index > 0,
            canMoveBottom:
                canEdit &&
                row.hasAnyData &&
                index < controller.stations.length - 1,
          );
          _runStationAction(action, index);
        },
        child: _gridRow(
          widths: widths,
          selected: selected,
          cells: [
            _rowIndexCell(index, selected),
            _editableCell(
              row.mdController,
              enabled: canEdit,
              stationIndex: index,
              stationColumnIndex: 0,
              onChanged: (value) =>
                  controller.updateStationField(index, 'md', value),
            ),
            _editableCell(
              row.incController,
              enabled: canEdit,
              stationIndex: index,
              stationColumnIndex: 1,
              onChanged: (value) =>
                  controller.updateStationField(index, 'inc', value),
            ),
            _editableCell(
              row.aziController,
              enabled: canEdit,
              stationIndex: index,
              stationColumnIndex: 2,
              onChanged: (value) =>
                  controller.updateStationField(index, 'azi', value),
            ),
            _readonlyCell(row.tvd),
            _readonlyCell(row.vsec),
            _readonlyCell(row.northSouth),
            _readonlyCell(row.eastWest),
            _readonlyCell(row.dogleg),
          ],
        ),
      );
    });
  }

  Widget _surveyToolbar(BuildContext context) {
    return Obx(() {
      final canEdit = !controller.isLocked && !controller.plannedSurvey.value;
      return Container(
        width: 42,
        decoration: BoxDecoration(
          border: Border.all(color: _gridBorder),
          color: Colors.white,
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),
            _toolButton(
              icon: Icons.calculate_outlined,
              tooltip: 'Calculate',
              enabled: true,
              onTap: controller.calculateSurvey,
            ),
            _toolButton(
              icon: Icons.show_chart_outlined,
              tooltip: 'Point Calculation',
              enabled: true,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const SurveyPointCalculationDialog(),
              ),
            ),
            _toolButton(
              icon: Icons.file_upload_outlined,
              tooltip: 'Survey Import',
              enabled: canEdit,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const SurveyImportDialog(),
              ),
            ),
            _toolButton(
              icon: Icons.delete_sweep_outlined,
              tooltip: 'Remove Empty Row',
              enabled: canEdit,
              onTap: controller.removeEmptyRows,
            ),
            _toolButton(
              icon: Icons.explore_outlined,
              tooltip: 'Adjust Azi Angle',
              enabled: canEdit,
              onTap: () => _showAdjustAziDialog(context),
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: _gridBorder),
            const SizedBox(height: 6),
            _toolButton(
              icon: Icons.content_copy,
              tooltip: 'Copy',
              enabled: controller.hasStationSelection,
              onTap: controller.copySelectedStation,
            ),
            _toolButton(
              icon: Icons.content_paste,
              tooltip: 'Paste',
              enabled:
                  canEdit &&
                  controller.hasStationSelection &&
                  controller.hasStationClipboard,
              onTap: controller.pasteStationIntoSelected,
            ),
            _toolButton(
              icon: Icons.add_box_outlined,
              tooltip: 'Add Row',
              enabled: canEdit,
              onTap: () => controller.insertStationAfter(
                controller.hasStationSelection
                    ? controller.selectedStationIndex.value
                    : controller.stations.length - 1,
              ),
            ),
            _toolButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete Row',
              enabled: canEdit && controller.hasStationSelection,
              onTap: controller.deleteSelectedStation,
            ),
            const Spacer(),
            _toolButton(
              icon: Icons.vertical_align_top,
              tooltip: 'To the Top',
              enabled: canEdit && controller.hasStationSelection,
              onTap: controller.moveSelectedStationToTop,
            ),
            _toolButton(
              icon: Icons.vertical_align_bottom,
              tooltip: 'To the Bottom',
              enabled: canEdit && controller.hasStationSelection,
              onTap: controller.moveSelectedStationToBottom,
            ),
            const SizedBox(height: 4),
          ],
        ),
      );
    });
  }

  Widget _annotationPanel(List<double> widths) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _gridBorder),
        color: Colors.white,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: Obx(
              () => Row(
                children: [
                  Checkbox(
                    value: controller.annotationEnabled.value,
                    onChanged:
                        controller.isLocked || controller.plannedSurvey.value
                        ? null
                        : (value) =>
                              controller.setAnnotationEnabled(value ?? false),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    'Annotation',
                    style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          _gridRow(
            widths: widths,
            header: true,
            cells: [
              '',
              'MD ${AppUnits.unitText('(ft)')}',
              'Annotation',
              'Symbol',
            ],
          ),
          Expanded(
            child: Obx(
              () => Scrollbar(
                controller: _annotationScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _annotationScrollController,
                  child: Column(
                    children: List.generate(
                      controller.annotations.length,
                      (index) => _annotationRow(
                        context: Get.context!,
                        index: index,
                        row: controller.annotations[index],
                        widths: widths,
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
  }

  Widget _annotationRow({
    required BuildContext context,
    required int index,
    required SurveyAnnotationRow row,
    required List<double> widths,
  }) {
    return Obx(() {
      final selected = controller.selectedAnnotationIndex.value == index;
      final enabled =
          !controller.isLocked &&
          !controller.plannedSurvey.value &&
          controller.annotationEnabled.value;
      return GestureDetector(
        onTap: () => controller.selectAnnotation(index),
        onSecondaryTapDown: (details) async {
          controller.selectAnnotation(index);
          final action = await _showCrudMenu(
            context: context,
            position: details.globalPosition,
            allowPaste: controller.hasAnnotationClipboard,
            canDelete: enabled && row.hasData,
            canMoveTop: enabled && row.hasData && index > 0,
            canMoveBottom:
                enabled &&
                row.hasData &&
                index < controller.annotations.length - 1,
          );
          _runAnnotationAction(action, index);
        },
        child: _gridRow(
          widths: widths,
          selected: selected,
          cells: [
            _rowIndexCell(index, selected),
            _editableCell(
              row.mdController,
              enabled: enabled,
              onChanged: (value) =>
                  controller.updateAnnotationField(index, 'md', value),
            ),
            _editableCell(
              row.annotationController,
              enabled: enabled,
              onChanged: (value) =>
                  controller.updateAnnotationField(index, 'annotation', value),
              textAlign: TextAlign.left,
            ),
            _symbolCell(index, row, enabled),
          ],
        ),
      );
    });
  }

  Widget _projectAziRow() {
    return SizedBox(
      height: 30,
      child: Obx(() {
        final enabled =
            !controller.isLocked &&
            !controller.plannedSurvey.value &&
            controller.projectAziEnabled.value;
        return Row(
          children: [
            Checkbox(
              value: controller.projectAziEnabled.value,
              onChanged: controller.isLocked || controller.plannedSurvey.value
                  ? null
                  : (value) => controller.setProjectAziEnabled(value ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 2),
            Text(
              'Project Azi',
              style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
            ),
            const SizedBox(width: 10),
            Container(
              width: 108,
              height: 24,
              decoration: BoxDecoration(
                color: _fieldBackground(enabled),
                border: Border.all(color: _gridBorder),
              ),
              child: TextField(
                controller: controller.projectAziController,
                enabled: enabled,
                textAlign: TextAlign.left,
                style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                ),
                onChanged: controller.updateProjectAzi,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(deg)',
              style: AppTheme.wellLikeUnitText.copyWith(fontSize: 11),
            ),
          ],
        );
      }),
    );
  }

  Widget _gridRow({
    required List<double> widths,
    required List<dynamic> cells,
    bool header = false,
    bool selected = false,
  }) {
    return Container(
      height: header ? 42 : 34,
      color: header
          ? wellSetupColumnHeader
          : (selected ? const Color(0xFFEAF1FF) : Colors.white),
      child: Row(
        children: List.generate(widths.length, (index) {
          return Container(
            width: widths[index],
            height: double.infinity,
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: _gridBorder),
                bottom: BorderSide(color: _gridBorder),
              ),
            ),
            child: cells[index] is Widget
                ? cells[index] as Widget
                : Text(
                    cells[index].toString(),
                    textAlign: TextAlign.left,
                    style: header
                        ? const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          )
                        : AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                  ),
          );
        }),
      ),
    );
  }

  Widget _rowIndexCell(int index, bool selected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (selected)
          const Icon(Icons.play_arrow, size: 10, color: Color(0xFF585858)),
        if (selected) const SizedBox(width: 2),
        Text(
          '${index + 1}',
          style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Color _fieldBackground(bool enabled) {
    if (controller.plannedSurvey.value) return _readOnlyBg;
    if (controller.isLocked) return _lockedBg;
    return enabled ? Colors.white : _readOnlyBg;
  }

  Widget _editableCell(
    TextEditingController controllerField, {
    required bool enabled,
    required ValueChanged<String> onChanged,
    TextAlign textAlign = TextAlign.left,
    int? stationIndex,
    int? stationColumnIndex,
  }) {
    return Obx(() {
      final bg = _fieldBackground(enabled);
      return Container(
        color: bg,
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.keyV, control: true):
                _PasteSurveyDataIntent(),
          },
          child: Actions(
            actions: {
              _PasteSurveyDataIntent: CallbackAction<_PasteSurveyDataIntent>(
                onInvoke: (_) {
                  if (stationIndex == null || stationColumnIndex == null) {
                    return null;
                  }
                  _pasteSurveyStationData(stationIndex, stationColumnIndex);
                  return null;
                },
              ),
            },
            child: TextField(
              controller: controllerField,
              enabled: enabled,
              textAlign: textAlign,
              style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 8,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      );
    });
  }

  Future<void> _pasteSurveyStationData(
    int stationIndex,
    int stationColumnIndex,
  ) async {
    if (controller.isLocked || controller.plannedSurvey.value) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final parsed = _parseSurveyClipboardRows(
      data?.text ?? '',
      stationColumnIndex,
    );
    if (parsed.isEmpty) return;
    controller.pasteStationTriples(stationIndex, parsed);
  }

  List<List<String>> _parseSurveyClipboardRows(String raw, int startColumn) {
    final lines = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((line) => line.trim().isNotEmpty);

    final rows = <List<String>>[];
    for (final line in lines) {
      final cells = line.split('\t').map((cell) => cell.trim()).toList();
      if (cells.every((cell) => cell.isEmpty)) continue;
      final row = List<String>.filled(3, '');
      for (var i = 0; i < cells.length && startColumn + i < 3; i++) {
        row[startColumn + i] = cells[i];
      }
      rows.add(row);
    }
    return rows;
  }

  Widget _readonlyCell(String value) {
    return Container(
      color: _readOnlyBg,
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _symbolCell(int index, SurveyAnnotationRow row, bool enabled) {
    return Container(
      color: _fieldBackground(enabled),
      alignment: Alignment.center,
      child: SizedBox(
        width: 38,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: row.symbol.isEmpty ? '' : row.symbol,
            isExpanded: true,
            isDense: true,
            menuMaxHeight: 240,
            icon: enabled
                ? const Icon(Icons.arrow_drop_down, size: 14)
                : const SizedBox.shrink(),
            onChanged: enabled
                ? (value) => controller.setAnnotationSymbol(index, value ?? '')
                : null,
            items: SurveyController.annotationSymbols.map((symbol) {
              return DropdownMenuItem<String>(
                value: symbol,
                child: Align(
                  alignment: Alignment.center,
                  child: _symbolWidget(symbol),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _symbolWidget(String symbol) {
    switch (symbol) {
      case 'circle_open':
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7A7A7A), width: 1.3),
          ),
        );
      case 'circle':
      case 'circle_filled':
        return Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF8C8C8C),
          ),
        );
      case 'square':
      case 'square_cross':
        return SizedBox(
          width: 18,
          height: 18,
          child: CustomPaint(painter: _SquareCrossPainter()),
        );
      case 'square_filled':
        return Container(width: 18, height: 18, color: const Color(0xFF8C8C8C));
      case 'square_grid':
        return SizedBox(
          width: 18,
          height: 18,
          child: CustomPaint(painter: _SquareGridPainter()),
        );
      case 'triangle':
        return SizedBox(
          width: 18,
          height: 18,
          child: CustomPaint(painter: _TrianglePainter()),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _toolButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              icon,
              size: 17,
              color: enabled
                  ? const Color(0xFF2780E3)
                  : const Color(0xFFBFC7D1),
            ),
          ),
        ),
      ),
    );
  }

  List<double> _fitWidths(double targetWidth, List<double> base) {
    final sum = base.fold<double>(0, (a, b) => a + b);
    final scale = sum == 0 ? 1.0 : targetWidth / sum;
    return base.map((value) => value * scale).toList();
  }

  Future<void> _showAdjustAziDialog(BuildContext context) async {
    final field = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adjust Azi Angle'),
          content: TextField(
            controller: field,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Angle Offset (deg)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                controller.adjustAziAngle(
                  double.tryParse(field.text.trim()) ?? 0,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    field.dispose();
  }

  Future<String?> _showCrudMenu({
    required BuildContext context,
    required Offset position,
    required bool allowPaste,
    required bool canDelete,
    required bool canMoveTop,
    required bool canMoveBottom,
  }) {
    return showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        const PopupMenuItem(value: 'cut', child: Text('Cut')),
        const PopupMenuItem(value: 'copy', child: Text('Copy')),
        PopupMenuItem(
          value: allowPaste ? 'paste' : null,
          enabled: allowPaste,
          child: const Text('Paste'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: canDelete ? 'delete' : null,
          enabled: canDelete,
          child: const Text('Delete'),
        ),
        PopupMenuItem(
          value: canMoveTop ? 'top' : null,
          enabled: canMoveTop,
          child: const Text('To the Top'),
        ),
        PopupMenuItem(
          value: canMoveBottom ? 'bottom' : null,
          enabled: canMoveBottom,
          child: const Text('To the Bottom'),
        ),
      ],
    );
  }

  void _runStationAction(String? action, int index) {
    switch (action) {
      case 'cut':
        controller.selectStation(index);
        controller.cutSelectedStation();
        break;
      case 'copy':
        controller.selectStation(index);
        controller.copySelectedStation();
        break;
      case 'paste':
        controller.selectStation(index);
        controller.pasteStationIntoSelected();
        break;
      case 'delete':
        controller.selectStation(index);
        controller.deleteSelectedStation();
        break;
      case 'top':
        controller.selectStation(index);
        controller.moveSelectedStationToTop();
        break;
      case 'bottom':
        controller.selectStation(index);
        controller.moveSelectedStationToBottom();
        break;
    }
  }

  void _runAnnotationAction(String? action, int index) {
    switch (action) {
      case 'cut':
        controller.selectAnnotation(index);
        controller.cutSelectedAnnotation();
        break;
      case 'copy':
        controller.selectAnnotation(index);
        controller.copySelectedAnnotation();
        break;
      case 'paste':
        controller.selectAnnotation(index);
        controller.pasteAnnotationIntoSelected();
        break;
      case 'delete':
        controller.selectAnnotation(index);
        controller.deleteSelectedAnnotation();
        break;
      case 'top':
        controller.selectAnnotation(index);
        controller.moveSelectedAnnotationToTop();
        break;
      case 'bottom':
        controller.selectAnnotation(index);
        controller.moveSelectedAnnotationToBottom();
        break;
    }
  }
}

class _PasteSurveyDataIntent extends Intent {
  const _PasteSurveyDataIntent();
}

class _SquareCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = const Color(0xFF7A7A7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final line = Paint()
      ..color = const Color(0xFF7A7A7A)
      ..strokeWidth = 1;
    canvas.drawRect(Offset.zero & size, border);
    canvas.drawLine(
      const Offset(3, 3),
      Offset(size.width - 3, size.height - 3),
      line,
    );
    canvas.drawLine(
      Offset(size.width - 3, 3),
      Offset(3, size.height - 3),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SquareGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = const Color(0xFF7A7A7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Offset.zero & size, border);
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      border,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF7A7A7A);
    final path = Path()
      ..moveTo(2, size.height - 2)
      ..lineTo(2, 2)
      ..lineTo(size.width - 2, size.height - 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
