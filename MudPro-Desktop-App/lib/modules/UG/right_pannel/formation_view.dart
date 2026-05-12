import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/formation_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/formation_row_model.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class FormationView extends StatefulWidget {
  const FormationView({super.key});

  @override
  State<FormationView> createState() => _FormationViewState();
}

class _FormationViewState extends State<FormationView> {
  static const double _rowHeight = 27;
  static const double _headerTopHeight = 34;
  static const double _headerBottomHeight = 24;
  static const Color _borderColor = Color(0xFFC9CED6);
  static const Color _headerColor = Color(0xFFF3F3F3);
  static const Color _highlightColor = Color(0xFFFFF6C7);

  final UgController ugController = Get.find<UgController>();
  final FormationController controller = Get.isRegistered<FormationController>()
      ? Get.find<FormationController>()
      : Get.put(FormationController());
  final ScrollController _scrollController = ScrollController();

  FormationRow? _clipboard;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isLocked => ugController.isLocked.value;

  bool _rowHasData(FormationRow row) => row.hasData;

  _FormationLayout _layoutFor(double totalWidth, bool showGraph) {
    final desiredGraphWidth = showGraph
        ? (totalWidth * 0.20).clamp(220.0, 284.0)
        : 0.0;
    final graphWidth = showGraph
        ? math.min(desiredGraphWidth, math.max(0.0, totalWidth - 24))
        : 0.0;
    return _FormationLayout(
      gap: showGraph ? 8 : 0,
      graphWidth: graphWidth,
      indexWidth: 54,
      descriptionWidth: 196,
      tvdWidth: 132,
      dataWidth: 88,
      lithologyWidth: 124,
    );
  }

  bool _isModeEditable(String field) {
    switch (controller.mode.value) {
      case 'Density':
        return field == 'porePpg' || field == 'fracPpg';
      case 'Pressure':
        return field == 'porePsi' || field == 'fracPsi';
      case 'Gradient':
      default:
        return field == 'poreGrad' || field == 'fracGrad';
    }
  }

  Color _cellColor({
    required bool editableWhenUnlocked,
    bool highlightWhenReadOnly = true,
  }) {
    if (_isLocked) return _highlightColor;
    if (editableWhenUnlocked) return Colors.white;
    return highlightWhenReadOnly ? _highlightColor : Colors.white;
  }

  PopupMenuItem<String> _menuItem(
    String value,
    String label,
    String shortcut, {
    required bool enabled,
  }) {
    final color = enabled ? const Color(0xFF2F2F2F) : const Color(0xFF9EA4AD);
    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 20),
          Text(shortcut, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Future<void> _showRowMenu(TapDownDetails details, int index) async {
    final row = controller.rows[index];
    final hasData = _rowHasData(row);
    final canMoveToTop = !_isLocked && hasData && index > 0;
    final canMoveToBottom =
        !_isLocked && hasData && index < controller.rows.length - 1;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        _menuItem('cut', 'Cut', 'Ctrl+X', enabled: !_isLocked && hasData),
        _menuItem('copy', 'Copy', 'Ctrl+C', enabled: hasData),
        _menuItem(
          'paste',
          'Paste',
          'Ctrl+V',
          enabled: !_isLocked && _clipboard != null,
        ),
        _menuItem('delete', 'Delete', 'Delete', enabled: !_isLocked && hasData),
        const PopupMenuDivider(),
        _menuItem('top', 'To the Top', 'Ctrl+Up', enabled: canMoveToTop),
        _menuItem(
          'bottom',
          'To the Bottom',
          'Ctrl+Down',
          enabled: canMoveToBottom,
        ),
      ],
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'cut':
        _clipboard = row.clone();
        controller.clearRow(index);
        break;
      case 'copy':
        _clipboard = row.clone();
        break;
      case 'paste':
        if (_clipboard != null) {
          controller.pasteRow(index, _clipboard!);
        }
        break;
      case 'delete':
        controller.clearRow(index);
        break;
      case 'top':
        controller.moveRowToTop(index);
        break;
      case 'bottom':
        controller.moveRowToBottom(index);
        break;
    }
  }

  Widget _headerCell(
    String text, {
    required double width,
    double height = _headerBottomHeight,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: const BoxDecoration(
        color: _headerColor,
        border: Border(
          right: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: 2,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2F2F2F),
        ),
      ),
    );
  }

  Widget _indexCell(FormationRow row, int index, _FormationLayout layout) {
    return Container(
      width: layout.indexWidth,
      height: _rowHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: Text(
              row.hasData ? '▸' : '',
              style: const TextStyle(fontSize: 9, color: Color(0xFF5B6470)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF404040)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableTextCell({
    required String value,
    required ValueChanged<String> onChanged,
    required double width,
    required bool editableWhenUnlocked,
    bool highlightWhenReadOnly = true,
    TextAlign textAlign = TextAlign.left,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isEditable = !_isLocked && editableWhenUnlocked;
    return Container(
      width: width,
      height: _rowHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _cellColor(
          editableWhenUnlocked: editableWhenUnlocked,
          highlightWhenReadOnly: highlightWhenReadOnly,
        ),
        border: const Border(
          right: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: isEditable
          ? TextFormField(
              initialValue: value,
              onChanged: onChanged,
              textAlign: textAlign,
              inputFormatters: inputFormatters,
              style: const TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 5),
              ),
            )
          : Align(
              alignment: textAlign == TextAlign.left
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Text(
                value,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 10,
                  color: value.isEmpty
                      ? const Color(0xFFB2B7BF)
                      : const Color(0xFF2F2F2F),
                ),
              ),
            ),
    );
  }

  Widget _lithologyCell(FormationRow row, _FormationLayout layout) {
    final text = row.lithology.value.trim().isEmpty
        ? 'No image data'
        : row.lithology.value;
    return Container(
      width: layout.lithologyWidth,
      height: _rowHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _isLocked ? _highlightColor : Colors.white,
        border: const Border(
          right: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: row.lithology.value.trim().isEmpty
              ? const Color(0xFF4A4F57)
              : const Color(0xFF2F2F2F),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRow(FormationRow row, int index, _FormationLayout layout) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => _showRowMenu(details, index),
      child: Row(
        children: [
          _indexCell(row, index, layout),
          _editableTextCell(
            value: row.description.value,
            onChanged: (value) => controller.updateDescription(index, value),
            width: layout.descriptionWidth,
            editableWhenUnlocked: true,
            textAlign: TextAlign.left,
          ),
          _editableTextCell(
            value: row.tvd.value,
            onChanged: (value) => controller.updateTvd(index, value),
            width: layout.tvdWidth,
            editableWhenUnlocked: true,
            textAlign: TextAlign.right,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          _editableTextCell(
            value: row.porePpg.value,
            onChanged: (value) =>
                controller.updateValue(index, 'porePpg', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('porePpg'),
            textAlign: TextAlign.right,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
            ],
          ),
          _editableTextCell(
            value: row.poreGrad.value,
            onChanged: (value) =>
                controller.updateValue(index, 'poreGrad', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('poreGrad'),
            textAlign: TextAlign.right,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          _editableTextCell(
            value: row.porePsi.value,
            onChanged: (value) =>
                controller.updateValue(index, 'porePsi', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('porePsi'),
            textAlign: TextAlign.right,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          _editableTextCell(
            value: row.fracPpg.value,
            onChanged: (value) =>
                controller.updateValue(index, 'fracPpg', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('fracPpg'),
            textAlign: TextAlign.right,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
            ],
          ),
          _editableTextCell(
            value: row.fracGrad.value,
            onChanged: (value) =>
                controller.updateValue(index, 'fracGrad', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('fracGrad'),
            textAlign: TextAlign.right,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          _editableTextCell(
            value: row.fracPsi.value,
            onChanged: (value) =>
                controller.updateValue(index, 'fracPsi', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('fracPsi'),
            textAlign: TextAlign.right,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          _lithologyCell(row, layout),
        ],
      ),
    );
  }

  Widget _topControls() {
    return Obx(
      () => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            Checkbox(
              value: controller.poreFromTop.value,
              onChanged: _isLocked
                  ? null
                  : (value) => controller.setPoreFromTop(value ?? true),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Pore and Fracture (from top down)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2F2F2F),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 92,
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: _isLocked ? _highlightColor : Colors.white,
                border: Border.all(color: _borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.mode.value,
                  items: const [
                    DropdownMenuItem(value: 'Density', child: Text('Density')),
                    DropdownMenuItem(
                      value: 'Gradient',
                      child: Text('Gradient'),
                    ),
                    DropdownMenuItem(
                      value: 'Pressure',
                      child: Text('Pressure'),
                    ),
                  ],
                  onChanged: _isLocked
                      ? null
                      : (value) => controller.setMode(value ?? 'Gradient'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF2F2F2F),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, size: 14),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: controller.isGraphVisible.value
                    ? const Color(0xFFE9F2FF)
                    : Colors.white,
                border: Border.all(color: _borderColor),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 13,
                tooltip: 'Graph',
                onPressed: controller.toggleGraph,
                icon: const Icon(Icons.show_chart, color: Color(0xFF2265A8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(_FormationLayout layout) {
    return Column(
      children: [
        Row(
          children: [
            _headerCell('', width: layout.indexWidth, height: _headerTopHeight),
            _headerCell(
              'Description',
              width: layout.descriptionWidth,
              height: _headerTopHeight,
            ),
            _headerCell(
              'Btm TVD\n${AppUnits.unitText('(ft)')}',
              width: layout.tvdWidth,
              height: _headerTopHeight,
            ),
            _headerCell(
              'Pore',
              width: layout.dataWidth * 3,
              height: _headerTopHeight,
            ),
            _headerCell(
              'Frac.',
              width: layout.dataWidth * 3,
              height: _headerTopHeight,
            ),
            _headerCell(
              'Lithology',
              width: layout.lithologyWidth,
              height: _headerTopHeight,
            ),
          ],
        ),
        Row(
          children: [
            _headerCell('', width: layout.indexWidth),
            _headerCell('', width: layout.descriptionWidth),
            _headerCell('', width: layout.tvdWidth),
            _headerCell(AppUnits.unitText('(ppg)'), width: layout.dataWidth),
            _headerCell(AppUnits.unitText('(psi/ft)'), width: layout.dataWidth),
            _headerCell(AppUnits.unitText('(psi)'), width: layout.dataWidth),
            _headerCell(AppUnits.unitText('(ppg)'), width: layout.dataWidth),
            _headerCell(AppUnits.unitText('(psi/ft)'), width: layout.dataWidth),
            _headerCell(AppUnits.unitText('(psi)'), width: layout.dataWidth),
            _headerCell('', width: layout.lithologyWidth),
          ],
        ),
      ],
    );
  }

  Widget _tableBody(_FormationLayout layout) {
    return Obx(
      () => Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: controller.rows.length,
          itemBuilder: (_, index) =>
              _buildRow(controller.rows[index], index, layout),
        ),
      ),
    );
  }

  Widget _formationTable(_FormationLayout layout) {
    return SizedBox(
      width: layout.tableWidth,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            _topControls(),
            _tableHeader(layout),
            Expanded(child: _tableBody(layout)),
            Container(
              height: 28,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: const Text(
                'Formation properties below the last entered depth are constant.',
                style: TextStyle(fontSize: 10, color: Color(0xFF3E5D7A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _graphPanel(_FormationLayout layout) {
    return Obx(() {
      if (!controller.isGraphVisible.value) {
        return const SizedBox.shrink();
      }

      return Container(
        width: layout.graphWidth,
        margin: EdgeInsets.only(left: layout.gap),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            const Text(
              'Formation P.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2F2F2F),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: CustomPaint(
                painter: _FormationGraphPainter(
                  porePoints: controller.showPoreGraph.value
                      ? controller.graphPoints(pore: true)
                      : const <FormationGraphPoint>[],
                  fracPoints: controller.showFracGraph.value
                      ? controller.graphPoints(pore: false)
                      : const <FormationGraphPoint>[],
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: controller.showPoreGraph.value,
                  onChanged: (value) =>
                      controller.showPoreGraph.value = value ?? true,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  activeColor: Colors.green,
                ),
                const Text(
                  'Pore',
                  style: TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
                ),
                const SizedBox(width: 10),
                Checkbox(
                  value: controller.showFracGraph.value,
                  onChanged: (value) =>
                      controller.showFracGraph.value = value ?? true,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  activeColor: Colors.red,
                ),
                const Text(
                  'Frac',
                  style: TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: LayoutBuilder(
        builder: (context, constraints) => Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final layout = _layoutFor(
            constraints.maxWidth,
            controller.isGraphVisible.value,
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _formationTable(layout),
                  ),
                ),
              ),
              _graphPanel(layout),
            ],
          );
        }),
      ),
    );
  }
}

class _FormationLayout {
  final double gap;
  final double graphWidth;
  final double indexWidth;
  final double descriptionWidth;
  final double tvdWidth;
  final double dataWidth;
  final double lithologyWidth;
  double get tableWidth =>
      indexWidth +
      descriptionWidth +
      tvdWidth +
      (dataWidth * 6) +
      lithologyWidth +
      4;

  const _FormationLayout({
    required this.gap,
    required this.graphWidth,
    required this.indexWidth,
    required this.descriptionWidth,
    required this.tvdWidth,
    required this.dataWidth,
    required this.lithologyWidth,
  });
}

class _FormationGraphPainter extends CustomPainter {
  final List<FormationGraphPoint> porePoints;
  final List<FormationGraphPoint> fracPoints;

  const _FormationGraphPainter({
    required this.porePoints,
    required this.fracPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 52.0;
    const rightPad = 16.0;
    const topPad = 18.0;
    const bottomPad = 52.0;
    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      math.max(0, size.width - leftPad - rightPad),
      math.max(0, size.height - topPad - bottomPad),
    );

    final axisPaint = Paint()
      ..color = const Color(0xFFB7BDC7)
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = const Color(0xFFD8DCE3)
      ..strokeWidth = 1;

    canvas.drawRect(chartRect, axisPaint);

    final allPoints = [...porePoints, ...fracPoints];
    final maxTvd = allPoints.isEmpty
        ? 14.0
        : math.max(14.0, allPoints.map((item) => item.tvd).reduce(math.max));
    final maxGrad = allPoints.isEmpty
        ? 30.0
        : math.max(
            30.0,
            allPoints.map((item) => item.gradient).reduce(math.max),
          );

    for (int i = 1; i < 6; i++) {
      final dx = chartRect.left + (chartRect.width / 6) * i;
      canvas.drawLine(
        Offset(dx, chartRect.top),
        Offset(dx, chartRect.bottom),
        gridPaint,
      );
    }
    for (int i = 1; i < 7; i++) {
      final dy = chartRect.top + (chartRect.height / 7) * i;
      canvas.drawLine(
        Offset(chartRect.left, dy),
        Offset(chartRect.right, dy),
        gridPaint,
      );
    }

    _drawAxisLabels(canvas, chartRect, maxTvd, maxGrad);
    _drawLine(canvas, chartRect, porePoints, maxTvd, maxGrad, Colors.green);
    _drawLine(canvas, chartRect, fracPoints, maxTvd, maxGrad, Colors.red);
  }

  void _drawAxisLabels(
    Canvas canvas,
    Rect rect,
    double maxTvd,
    double maxGrad,
  ) {
    final labelStyle = const TextStyle(fontSize: 10, color: Color(0xFF4A4F57));
    final axisStyle = const TextStyle(fontSize: 11, color: Color(0xFF2F2F2F));

    for (int i = 0; i <= 7; i++) {
      final tvd = (maxTvd / 7) * i;
      final y = rect.top + (rect.height / 7) * i;
      final painter = TextPainter(
        text: TextSpan(text: tvd.toStringAsFixed(0), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(rect.left - painter.width - 8, y - 6));
    }

    for (int i = 0; i <= 6; i++) {
      final grad = (maxGrad / 6) * i;
      final x = rect.left + (rect.width / 6) * i;
      final painter = TextPainter(
        text: TextSpan(text: grad.toStringAsFixed(0), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x - (painter.width / 2), rect.bottom + 8));
    }

    final yAxis = TextPainter(
      text: TextSpan(
        text: 'TVD ${AppUnits.unitText('(ft)')}',
        style: axisStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(16, rect.center.dy + (yAxis.width / 2));
    canvas.rotate(-math.pi / 2);
    yAxis.paint(canvas, Offset.zero);
    canvas.restore();

    final xAxis = TextPainter(
      text: TextSpan(
        text: 'P. Gradient ${AppUnits.unitText('(psi/ft)')}',
        style: axisStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xAxis.paint(
      canvas,
      Offset(rect.center.dx - (xAxis.width / 2), rect.bottom + 28),
    );
  }

  void _drawLine(
    Canvas canvas,
    Rect rect,
    List<FormationGraphPoint> points,
    double maxTvd,
    double maxGrad,
    Color color,
  ) {
    if (points.isEmpty) return;
    final path = Path();
    path.moveTo(rect.left, rect.top);
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final x = rect.left + (point.gradient / maxGrad) * rect.width;
      final y = rect.top + (point.tvd / maxTvd) * rect.height;
      path.lineTo(x, y);
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FormationGraphPainter oldDelegate) {
    return oldDelegate.porePoints != porePoints ||
        oldDelegate.fracPoints != fracPoints;
  }
}
