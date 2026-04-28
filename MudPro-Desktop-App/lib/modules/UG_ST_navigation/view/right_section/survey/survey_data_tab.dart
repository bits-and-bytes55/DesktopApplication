import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/survey_model.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';

class SurveyDataTab extends StatelessWidget {
  SurveyDataTab({super.key});

  final SurveyController controller = Get.find<SurveyController>();

  static const _headerBg = Color(0xFFF4F4F4);
  static const _gridBorder = Color(0xFFC8CED6);
  static const _readOnlyBg = Color(0xFFFFF8C9);
  static const _lockedBg = Color(0xFFFFF1A6);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _surveyTable()),
                      const SizedBox(height: 8),
                      _projectAziRow(),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _surveyToolbar(),
                const SizedBox(width: 6),
                SizedBox(width: 540, child: _annotationPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _surveyTable() {
    const widths = <double>[38, 94, 94, 94, 90, 90, 96, 96, 110];
    final totalWidth = widths.reduce((a, b) => a + b);
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
            cells: const [
              '',
              'MD\n(ft)',
              'Inc\n(°)',
              'Azi\n(°)',
              'TVD\n(ft)',
              'Vsec\n(ft)',
              'N+/S-\n(ft)',
              'E+/W-\n(ft)',
              'Dogleg\n(°/100ft)',
            ],
          ),
          Expanded(
            child: Obx(
              () => Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: totalWidth,
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
      return GestureDetector(
        onTap: () => controller.selectStation(index),
        onSecondaryTapDown: (details) async {
          controller.selectStation(index);
          final action = await _showCrudMenu(
            context: context,
            position: details.globalPosition,
            allowPaste: controller.hasStationClipboard,
            canDelete: !controller.isLocked && row.hasAnyData,
            canMoveTop: !controller.isLocked && row.hasAnyData && index > 0,
            canMoveBottom:
                !controller.isLocked &&
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
              enabled: !controller.isLocked,
              onChanged: (value) =>
                  controller.updateStationField(index, 'md', value),
            ),
            _editableCell(
              row.incController,
              enabled: !controller.isLocked,
              onChanged: (value) =>
                  controller.updateStationField(index, 'inc', value),
            ),
            _editableCell(
              row.aziController,
              enabled: !controller.isLocked,
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

  Widget _surveyToolbar() {
    return Obx(() {
      final canEdit = !controller.isLocked;
      return Container(
        width: 34,
        decoration: BoxDecoration(
          border: Border.all(color: _gridBorder),
          color: Colors.white,
        ),
        child: Column(
          children: [
            const SizedBox(height: 6),
            _toolButton(
              icon: Icons.content_copy,
              enabled: controller.hasStationSelection,
              onTap: controller.copySelectedStation,
            ),
            _toolButton(
              icon: Icons.content_paste,
              enabled:
                  canEdit &&
                  controller.hasStationSelection &&
                  controller.hasStationClipboard,
              onTap: controller.pasteStationIntoSelected,
            ),
            _toolButton(
              icon: Icons.add_box_outlined,
              enabled: canEdit,
              onTap: () => controller.insertStationAfter(
                controller.hasStationSelection
                    ? controller.selectedStationIndex.value
                    : controller.stations.length - 1,
              ),
            ),
            _toolButton(
              icon: Icons.delete_outline,
              enabled: canEdit && controller.hasStationSelection,
              onTap: controller.deleteSelectedStation,
            ),
            _toolButton(
              icon: Icons.arrow_circle_up_outlined,
              enabled: canEdit && controller.hasStationSelection,
              onTap: controller.moveSelectedStationUp,
            ),
            _toolButton(
              icon: Icons.arrow_circle_down_outlined,
              enabled: canEdit && controller.hasStationSelection,
              onTap: controller.moveSelectedStationDown,
            ),
            const Spacer(),
            _toolButton(
              icon: Icons.vertical_align_top,
              enabled: canEdit && controller.hasStationSelection,
              onTap: controller.moveSelectedStationToTop,
            ),
            _toolButton(
              icon: Icons.vertical_align_bottom,
              enabled: canEdit && controller.hasStationSelection,
              onTap: controller.moveSelectedStationToBottom,
            ),
            const SizedBox(height: 6),
          ],
        ),
      );
    });
  }

  Widget _annotationPanel() {
    const widths = <double>[38, 116, 260, 110];
    final totalWidth = widths.reduce((a, b) => a + b);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _gridBorder),
        color: Colors.white,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: Obx(
              () => Row(
                children: [
                  Checkbox(
                    value: controller.annotationEnabled.value,
                    onChanged: controller.isLocked
                        ? null
                        : (value) =>
                              controller.setAnnotationEnabled(value ?? false),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Text('Annotation', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          _gridRow(
            widths: widths,
            header: true,
            cells: const ['', 'MD (ft)', 'Annotation', 'Symbol'],
          ),
          Expanded(
            child: Obx(
              () => Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: totalWidth,
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
          !controller.isLocked && controller.annotationEnabled.value;
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
      height: 28,
      child: Obx(() {
        final enabled =
            !controller.isLocked && controller.projectAziEnabled.value;
        return Row(
          children: [
            Checkbox(
              value: controller.projectAziEnabled.value,
              onChanged: controller.isLocked
                  ? null
                  : (value) => controller.setProjectAziEnabled(value ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 2),
            const Text('Project Azi', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 10),
            Container(
              width: 90,
              height: 24,
              decoration: BoxDecoration(
                color: controller.isLocked
                    ? _lockedBg
                    : (enabled ? Colors.white : _readOnlyBg),
                border: Border.all(color: _gridBorder),
              ),
              child: TextField(
                controller: controller.projectAziController,
                enabled: enabled,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
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
            const Text('(°)', style: TextStyle(fontSize: 12)),
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
      height: header ? 44 : 34,
      color: header
          ? _headerBg
          : (selected ? const Color(0xFFEAF1FF) : Colors.white),
      child: Row(
        children: List.generate(widths.length, (index) {
          return Container(
            width: widths[index],
            height: double.infinity,
            alignment: Alignment.center,
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
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: header ? 11.5 : 12,
                      fontWeight: header ? FontWeight.w600 : FontWeight.normal,
                      color: const Color(0xFF2F2F2F),
                    ),
                  ),
          );
        }),
      ),
    );
  }

  Widget _rowIndexCell(int index, bool selected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          selected ? Icons.play_arrow : Icons.circle,
          size: selected ? 10 : 0,
          color: const Color(0xFF585858),
        ),
        if (selected) const SizedBox(width: 2),
        Text(
          '${index + 1}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF2F2F2F)),
        ),
      ],
    );
  }

  Widget _editableCell(
    TextEditingController controllerField, {
    required bool enabled,
    required ValueChanged<String> onChanged,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Obx(() {
      final bg = controller.isLocked
          ? _lockedBg
          : (enabled ? Colors.white : _readOnlyBg);
      return Container(
        color: bg,
        child: TextField(
          controller: controllerField,
          enabled: enabled,
          textAlign: textAlign,
          style: const TextStyle(fontSize: 12, color: Color(0xFF2F2F2F)),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          ),
          onChanged: onChanged,
        ),
      );
    });
  }

  Widget _readonlyCell(String value) {
    return Container(
      color: _readOnlyBg,
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(fontSize: 12, color: Color(0xFF2F2F2F)),
      ),
    );
  }

  Widget _symbolCell(int index, SurveyAnnotationRow row, bool enabled) {
    return InkWell(
      onTap: enabled ? () => controller.cycleAnnotationSymbol(index) : null,
      child: Container(
        color: controller.isLocked ? _lockedBg : Colors.white,
        alignment: Alignment.center,
        child: _symbolWidget(row.symbol),
      ),
    );
  }

  Widget _symbolWidget(String symbol) {
    switch (symbol) {
      case 'square':
        return SizedBox(
          width: 18,
          height: 18,
          child: CustomPaint(painter: _SquareCrossPainter()),
        );
      case 'circle':
        return Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF8C8C8C),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _toolButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF2780E3) : const Color(0xFFBFC7D1),
        ),
      ),
    );
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
