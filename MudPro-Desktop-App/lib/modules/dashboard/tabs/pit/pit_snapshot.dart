import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/pit_snapshot_Controller.dart';

const _snapshotFrameBlue = Color(0xFF3A98F5);
const _snapshotBorder = Color(0xFFB7B7B7);
const _snapshotHeaderFill = Color(0xFFF3F3F3);
const _snapshotValueFill = Color(0xFFFFF8CC);
const _snapshotActive = Color(0xFFF47B20);
const _snapshotStorage = Color(0xFF4C78C6);
const _snapshotWellGrey = Color(0xFFA6A6A6);
const _snapshotAxisRed = Color(0xFFFF1E1E);

class PitSnapshotPage extends StatelessWidget {
  const PitSnapshotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PitSnapshotController>()
        ? Get.find<PitSnapshotController>()
        : Get.put(PitSnapshotController());

    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildWindowBar(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _snapshotFrameBlue, width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildLeftPane(controller),
                                ),
                                Container(width: 1, color: _snapshotBorder),
                                Expanded(
                                  flex: 2,
                                  child: _buildRightPane(controller),
                                ),
                              ],
                            ),
                          ),
                          _buildFooter(),
                        ],
                      ),
                      if (controller.isLoading.value)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.65),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: _snapshotHeaderFill,
      child: Row(
        children: [
          const Text(
            'Pit Snapshot',
            style: TextStyle(fontSize: 18, color: Color(0xFF2B2B2B)),
          ),
          const Spacer(),
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.close, color: Color(0xFF666666), size: 26),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPane(PitSnapshotController controller) {
    final note = controller.errorMessage.value.isNotEmpty
        ? controller.errorMessage.value
        : controller.emptyMessage.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 12),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 160),
                Expanded(
                  child: Center(
                    child: Text(
                      controller.reportHeaderText,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Row(
                  children: const [
                    _LegendSwatch(label: 'Active Pits', color: _snapshotActive),
                    SizedBox(width: 28),
                    _LegendSwatch(label: 'Storage', color: _snapshotStorage),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PitSnapshotDiagramPainter(
                      measuredDepth: controller.measuredDepth.value,
                      shoeDepth: controller.shoeDepth.value,
                      activePits: controller.activePits.toList(growable: false),
                      storagePits: controller.storagePits.toList(
                        growable: false,
                      ),
                    ),
                  ),
                ),
                if (note.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 6,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: Colors.white,
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 11,
                            color: controller.errorMessage.value.isNotEmpty
                                ? Colors.red.shade700
                                : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPane(PitSnapshotController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 10),
      child: Column(
        children: [
          _buildVolumeSummary(controller),
          const SizedBox(height: 8),
          Expanded(child: _buildConcentration(controller)),
        ],
      ),
    );
  }

  Widget _buildVolumeSummary(PitSnapshotController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Volume Summary',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _snapshotBorder),
                ),
                child: Table(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: _snapshotBorder),
                    verticalInside: BorderSide(color: _snapshotBorder),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(2.4),
                    1: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: _snapshotHeaderFill),
                      children: [
                        _SummaryHeaderCell('Vol. Name'),
                        _SummaryHeaderCell('Vol. (bbl)', alignRight: true),
                      ],
                    ),
                    ...controller.volumeSummaryRows.map(
                      (row) => TableRow(
                        children: [
                          _SummaryValueCell(
                            row.name,
                            fill: Colors.white,
                            alignRight: false,
                            textColor: Colors.black87,
                          ),
                          _SummaryValueCell(
                            row.value.toStringAsFixed(2),
                            fill: _snapshotValueFill,
                            alignRight: true,
                            textColor: row.highlightRed
                                ? Colors.red
                                : Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              margin: const EdgeInsets.only(top: 96),
              width: 24,
              height: 42,
              decoration: BoxDecoration(
                color: _snapshotHeaderFill,
                border: Border.all(color: _snapshotBorder),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                splashRadius: 16,
                onPressed: () => _showHoleVolumeDialog(controller),
                icon: const Icon(
                  Icons.help_outline,
                  color: _snapshotFrameBlue,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConcentration(PitSnapshotController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 2, bottom: 6),
                child: Text(
                  'Pit Concentration',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ),
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: _snapshotBorder),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedSystem.value,
                  items: controller.systemOptions
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectSystem(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _snapshotBorder),
            ),
            child: Column(
              children: [
                Container(
                  color: _snapshotHeaderFill,
                  child: const Row(
                    children: [
                      _ConcentrationHeaderCell('', width: 18),
                      _ConcentrationHeaderCell('', width: 40),
                      _ConcentrationHeaderCell('Product', flex: 5),
                      _ConcentrationHeaderCell('Unit', flex: 2),
                      _ConcentrationHeaderCell('Start Conc.', flex: 2),
                      _ConcentrationHeaderCell('End Conc.', flex: 2),
                    ],
                  ),
                ),
                Expanded(
                  child: controller.concentrationRows.isEmpty
                      ? Center(
                          child: Text(
                            controller.isLoading.value
                                ? ''
                                : 'No live pit concentration rows are available.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: controller.concentrationRows
                                .map(_buildConcentrationRow)
                                .toList(growable: false),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConcentrationRow(PitConcentrationRow row) {
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _snapshotBorder)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            child: Icon(Icons.play_arrow, size: 12, color: Color(0xFF6F6F6F)),
          ),
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                '${row.rowNumber}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              height: double.infinity,
              color: _snapshotValueFill,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                row.product,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              height: double.infinity,
              decoration: const BoxDecoration(
                color: _snapshotValueFill,
                border: Border(left: BorderSide(color: _snapshotBorder)),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                row.unit,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              height: double.infinity,
              decoration: const BoxDecoration(
                color: _snapshotValueFill,
                border: Border(left: BorderSide(color: _snapshotBorder)),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(row.startConc, style: const TextStyle(fontSize: 11)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              height: double.infinity,
              decoration: const BoxDecoration(
                color: _snapshotValueFill,
                border: Border(left: BorderSide(color: _snapshotBorder)),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(row.endConc, style: const TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 90,
        height: 40,
        child: OutlinedButton(
          onPressed: Get.back,
          style: OutlinedButton.styleFrom(
            shape: const RoundedRectangleBorder(),
            side: const BorderSide(color: _snapshotBorder),
            foregroundColor: Colors.black87,
          ),
          child: const Text('Close', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Future<void> _showHoleVolumeDialog(PitSnapshotController controller) {
    final rows = controller.holeVolumeRows.toList(growable: false);
    return Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 420,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Hole Volume (bbl)',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      Icons.close,
                      size: 22,
                      color: Color(0xFF666666),
                    ),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _snapshotBorder),
                ),
                child: Table(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: _snapshotBorder),
                    verticalInside: BorderSide(color: _snapshotBorder),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1.6),
                    1: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: _snapshotHeaderFill),
                      children: [
                        _SummaryHeaderCell('', alignRight: false),
                        _SummaryHeaderCell('', alignRight: true),
                      ],
                    ),
                    ...rows.map(
                      (row) => TableRow(
                        children: [
                          _SummaryValueCell(
                            row.label,
                            fill: Colors.white,
                            alignRight: false,
                            textColor: Colors.black87,
                          ),
                          _SummaryValueCell(
                            row.value.toStringAsFixed(2),
                            fill: _snapshotValueFill,
                            alignRight: true,
                            textColor: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 20, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}

class _SummaryHeaderCell extends StatelessWidget {
  const _SummaryHeaderCell(this.text, {this.alignRight = false});

  final String text;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SummaryValueCell extends StatelessWidget {
  const _SummaryValueCell(
    this.text, {
    required this.fill,
    required this.alignRight,
    required this.textColor,
  });

  final String text;
  final Color fill;
  final bool alignRight;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fill,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(text, style: TextStyle(fontSize: 11, color: textColor)),
    );
  }
}

class _ConcentrationHeaderCell extends StatelessWidget {
  const _ConcentrationHeaderCell(this.text, {this.width, this.flex});

  final String text;
  final double? width;
  final int? flex;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _snapshotBorder)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex ?? 1, child: child);
  }
}

class _PitSnapshotDiagramPainter extends CustomPainter {
  _PitSnapshotDiagramPainter({
    required this.measuredDepth,
    required this.shoeDepth,
    required this.activePits,
    required this.storagePits,
  });

  final double measuredDepth;
  final double shoeDepth;
  final List<PitSnapshotPitRow> activePits;
  final List<PitSnapshotPitRow> storagePits;

  @override
  void paint(Canvas canvas, Size size) {
    final maxDepth = math.max(math.max(measuredDepth, shoeDepth), 10.0);
    const topInset = 56.0;
    const bottomInset = 22.0;
    final depthTop = topInset + 36;
    final depthBottom = size.height - bottomInset;
    final depthHeight = math.max(40.0, depthBottom - depthTop);

    _drawDepthScale(canvas, size, maxDepth, depthTop, depthBottom, depthHeight);
    _drawWellShape(canvas, size, depthTop, depthBottom);
    _drawPitBoxes(canvas, size, depthTop);
  }

  void _drawDepthScale(
    Canvas canvas,
    Size size,
    double maxDepth,
    double depthTop,
    double depthBottom,
    double depthHeight,
  ) {
    const axisX = 56.0;
    final axisPaint = Paint()
      ..color = _snapshotAxisRed
      ..strokeWidth = 1.2;
    final tickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    final tp = _textPainter(
      'MD/TVD (ft)Shoe (ft)',
      const TextStyle(fontSize: 11, color: Colors.black87),
    );
    tp.paint(canvas, const Offset(12, 16));

    canvas.drawLine(
      Offset(axisX, depthTop),
      Offset(axisX, depthBottom),
      axisPaint,
    );

    const majorTicks = 5;
    for (var i = 0; i <= majorTicks; i++) {
      final fraction = i / majorTicks;
      final y = depthTop + (depthHeight * fraction);
      final value = (maxDepth * fraction).toStringAsFixed(1);

      canvas.drawLine(Offset(axisX - 6, y), Offset(axisX + 6, y), axisPaint);
      for (var minor = 1; minor <= 3 && i < majorTicks; minor++) {
        final minorY = y + ((depthHeight / majorTicks) * (minor / 4));
        canvas.drawLine(
          Offset(axisX - 4, minorY),
          Offset(axisX, minorY),
          tickPaint,
        );
      }

      final left = _textPainter(
        value,
        const TextStyle(fontSize: 11, color: Colors.black87),
      );
      left.paint(canvas, Offset(18, y - (left.height / 2)));

      final marker = _textPainter(
        '⊕',
        const TextStyle(fontSize: 12, color: _snapshotAxisRed),
      );
      marker.paint(canvas, Offset(axisX - 10, y - (marker.height / 2)));

      final right = _textPainter(
        value,
        const TextStyle(fontSize: 11, color: Colors.black87),
      );
      right.paint(canvas, Offset(axisX + 12, y - (right.height / 2)));
    }
  }

  void _drawWellShape(
    Canvas canvas,
    Size size,
    double depthTop,
    double depthBottom,
  ) {
    final fillPaint = Paint()..color = _snapshotWellGrey;
    final strokePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final leftBar = Rect.fromLTWH(
      170,
      depthTop,
      44,
      depthBottom - depthTop - 12,
    );
    final rightBar = Rect.fromLTWH(
      math.max(320.0, size.width * 0.64),
      depthTop,
      44,
      depthBottom - depthTop - 12,
    );

    canvas.drawRect(leftBar, fillPaint);
    canvas.drawRect(leftBar, strokePaint);
    canvas.drawRect(rightBar, fillPaint);
    canvas.drawRect(rightBar, strokePaint);

    final leftFoot = Path()
      ..moveTo(leftBar.left - 8, depthBottom)
      ..lineTo(leftBar.right + 2, depthBottom)
      ..lineTo(leftBar.left - 2, depthBottom - 10)
      ..close();
    canvas.drawPath(leftFoot, fillPaint);
    canvas.drawPath(leftFoot, strokePaint);

    final rightFoot = Path()
      ..moveTo(rightBar.left - 2, depthBottom)
      ..lineTo(rightBar.right + 8, depthBottom)
      ..lineTo(rightBar.right + 2, depthBottom - 10)
      ..close();
    canvas.drawPath(rightFoot, fillPaint);
    canvas.drawPath(rightFoot, strokePaint);
  }

  void _drawPitBoxes(Canvas canvas, Size size, double depthTop) {
    final allPits = [...activePits, ...storagePits];
    if (allPits.isEmpty) return;

    final startX = math.max(420.0, size.width * 0.74);
    final width = math.min(255.0, size.width - startX - 14);
    final availableHeight = size.height - depthTop - 30;
    final count = allPits.length;
    final gap = count <= 5 ? 14.0 : 8.0;
    final boxHeight = math.min(
      48.0,
      math.max(28.0, (availableHeight - (gap * (count - 1))) / count),
    );

    final activeConnectorPaint = Paint()
      ..color = _snapshotActive
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final storageConnectorPaint = Paint()
      ..color = _snapshotStorage
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final trunkX = startX - 32;
    final trunkTop = depthTop - 14;
    final wellX = math.max(300.0, size.width * 0.55);
    canvas.drawLine(
      Offset(wellX, trunkTop),
      Offset(trunkX, trunkTop),
      activeConnectorPaint,
    );

    for (var i = 0; i < allPits.length; i++) {
      final pit = allPits[i];
      final top = depthTop + (i * (boxHeight + gap));
      final rect = Rect.fromLTWH(startX, top, width, boxHeight);
      final boxPaint = Paint()
        ..color = pit.isActive ? _snapshotActive : _snapshotStorage;
      final borderPaint = Paint()
        ..color = pit.isActive ? _snapshotActive : _snapshotStorage
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke;

      final centerY = rect.center.dy;
      final connectorPaint = pit.isActive
          ? activeConnectorPaint
          : storageConnectorPaint;

      if (pit.isActive) {
        final branchY = trunkTop + (i * 16);
        canvas.drawLine(
          Offset(trunkX, trunkTop),
          Offset(trunkX, centerY),
          connectorPaint,
        );
        canvas.drawLine(
          Offset(trunkX, centerY),
          Offset(rect.left, centerY),
          connectorPaint,
        );
        canvas.drawLine(
          Offset(wellX - 110, branchY),
          Offset(wellX, branchY),
          connectorPaint,
        );
      } else {
        canvas.drawLine(
          Offset(trunkX, centerY),
          Offset(rect.left, centerY),
          connectorPaint,
        );
      }

      canvas.drawRect(rect, boxPaint);
      canvas.drawRect(rect, borderPaint);

      final label = _fitLabel(pit.label);
      final tp = _textPainter(
        label,
        const TextStyle(fontSize: 12, color: Colors.white),
        maxWidth: rect.width - 16,
      );
      tp.paint(
        canvas,
        Offset(rect.left + 10, rect.top + ((rect.height - tp.height) / 2)),
      );
    }
  }

  String _fitLabel(String text) {
    if (text.length <= 34) return text;
    return '${text.substring(0, 31)}...';
  }

  @override
  bool shouldRepaint(covariant _PitSnapshotDiagramPainter oldDelegate) {
    if (oldDelegate.measuredDepth != measuredDepth ||
        oldDelegate.shoeDepth != shoeDepth) {
      return true;
    }
    if (oldDelegate.activePits.length != activePits.length ||
        oldDelegate.storagePits.length != storagePits.length) {
      return true;
    }
    for (var i = 0; i < activePits.length; i++) {
      final left = oldDelegate.activePits[i];
      final right = activePits[i];
      if (left.id != right.id ||
          left.displayVolume != right.displayVolume ||
          left.pitName != right.pitName) {
        return true;
      }
    }
    for (var i = 0; i < storagePits.length; i++) {
      final left = oldDelegate.storagePits[i];
      final right = storagePits[i];
      if (left.id != right.id ||
          left.displayVolume != right.displayVolume ||
          left.pitName != right.pitName) {
        return true;
      }
    }
    return false;
  }
}

TextPainter _textPainter(String text, TextStyle style, {double? maxWidth}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '...',
  )..layout(maxWidth: maxWidth ?? double.infinity);
  return painter;
}
