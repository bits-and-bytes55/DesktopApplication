import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/volume/controller/recap_volume_controller.dart';

const Color _volumeOuterBorder = Color(0xFF2F92E8);
const Color _volumeCanvas = Color(0xFFF4F4F4);
const Color _volumePanelBorder = Color(0xFFC8C8C8);
const Color _volumeHeaderFill = Color(0xFFF7F7F7);
const Color _volumeText = Color(0xFF1C1C1C);
const Color _volumeGrid = Color(0xFFD6D6D6);
const Color _volumeTabFill = Color(0xFFEAEAEA);
const Color _volumeLine = Color(0xFF86D8FB);

class RecapVolumeTabView extends StatefulWidget {
  const RecapVolumeTabView({super.key});

  @override
  State<RecapVolumeTabView> createState() => _RecapVolumeTabViewState();
}

class _RecapVolumeTabViewState extends State<RecapVolumeTabView> {
  int _selectedTab = 0;

  RecapVolumeController get _controller => Get.isRegistered<RecapVolumeController>()
      ? Get.find<RecapVolumeController>()
      : Get.put(RecapVolumeController());

  static const _tabs = [
    _VolumeTabMeta(title: 'Graph'),
    _VolumeTabMeta(title: 'Summary'),
    _VolumeTabMeta(title: 'Addition'),
    _VolumeTabMeta(title: 'Loss'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _volumeCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _volumeOuterBorder, width: 1.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: Obx(() => _buildContent(controller))),
            _buildVerticalTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RecapVolumeController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _VolumeMessageState(
        title: 'Volume (bbl)',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty || controller.emptyMessage.value.isNotEmpty) {
      return _VolumeMessageState(
        title: 'Volume (bbl)',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live volume history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _VolumeGraphTab(controller: controller);
      case 1:
        return _VolumeSummaryTab(rows: controller.rows.toList());
      case 2:
        return _VolumeAdditionTab(rows: controller.rows.toList());
      case 3:
        return _VolumeLossTab(rows: controller.rows.toList());
      default:
        return _VolumeGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _volumeCanvas,
        border: Border(left: BorderSide(color: _volumePanelBorder)),
      ),
      child: Column(
        children: List.generate(_tabs.length, (index) {
          final selected = index == _selectedTab;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? Colors.white : _volumeTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _volumePanelBorder),
                    left: BorderSide(
                      color: selected ? _volumeOuterBorder : _volumePanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _volumePanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _volumePanelBorder)
                        : BorderSide.none,
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      _tabs[index].title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _volumeText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _VolumeGraphTab extends StatelessWidget {
  final RecapVolumeController controller;

  const _VolumeGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _VolumeGraphSection(label: 'Start', values: controller.startSeries()),
      _VolumeGraphSection(
        label: 'Addition - Total',
        values: controller.additionSeries(),
      ),
      _VolumeGraphSection(label: 'Loss - Total', values: controller.lossSeries()),
      _VolumeGraphSection(
        label: 'Transfer - Total',
        values: controller.transferSeries(),
      ),
      _VolumeGraphSection(label: 'End', values: controller.endSeries()),
    ];

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _volumePanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
              child: Text(
                'Volume (bbl)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _volumeText,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 10, 8),
                child: CustomPaint(
                  painter: _LegacyVolumeGraphPainter(
                    sections: sections,
                    slotCount: math.max(5, controller.rows.length),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeSummaryTab extends StatelessWidget {
  final List<VolumeHistoryRow> rows;

  const _VolumeSummaryTab({required this.rows});

  @override
  Widget build(BuildContext context) {
    final columns = [
      _VolumeTableColumn(
        title: 'Start',
        valueFor: (row) => _formatNumber(row.startVol),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Addition Total',
        valueFor: (row) => _formatNumber(row.additionTotal),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Loss Total',
        valueFor: (row) => _formatNumber(row.lossTotal),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'From Storage',
        valueFor: (row) => _formatNumber(row.fromStorage),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'To Storage',
        valueFor: (row) => _formatNumber(row.toStorage),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Return',
        valueFor: (row) => _formatNumber(row.returnVol),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Transfer Total',
        valueFor: (row) => _formatNumber(row.transferTotal),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'End',
        valueFor: (row) => _formatNumber(row.endVol),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Hole',
        valueFor: (row) => _formatNumber(row.hole),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Active Pits',
        valueFor: (row) => _formatNumber(row.activePits),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Active System',
        valueFor: (row) => _formatNumber(row.activeSystem),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Total Storage',
        valueFor: (row) => _formatNumber(row.totalStorage),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Total on Location',
        valueFor: (row) => _formatNumber(row.totalOnLocation),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Ledger TOL',
        valueFor: (row) => _formatNumber(row.ledgerTotalOnLocation),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Cum. Leased',
        valueFor: (row) => _formatNumber(row.cumLeased),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Volume Difference',
        valueFor: (row) => _formatNumber(row.volumeDifference),
        alignRight: true,
      ),
    ];

    return _VolumeTableShell(
      title: 'Volume Summary',
      rows: rows,
      columns: columns,
    );
  }
}

class _VolumeAdditionTab extends StatelessWidget {
  final List<VolumeHistoryRow> rows;

  const _VolumeAdditionTab({required this.rows});

  @override
  Widget build(BuildContext context) {
    final columns = [
      _VolumeTableColumn(
        title: 'Receive Mud',
        valueFor: (row) => _formatNumber(row.receiveMud),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Base Fluid',
        valueFor: (row) => _formatNumber(row.baseFluid),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Weight Material',
        valueFor: (row) => _formatNumber(row.weightMaterial),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Products',
        valueFor: (row) => _formatNumber(row.products),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Water',
        valueFor: (row) => _formatNumber(row.water),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Formation',
        valueFor: (row) => _formatNumber(row.formation),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Cuttings',
        valueFor: (row) => _formatNumber(row.cuttings),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Volume Not Fluid',
        valueFor: (row) => _formatNumber(row.volumeNotFluid),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Cuttings/Retention',
        valueFor: (row) => _formatNumber(row.cuttingsRetention),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Seepage',
        valueFor: (row) => _formatNumber(row.seepage),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Addition Total',
        valueFor: (row) => _formatNumber(row.additionTotal),
        alignRight: true,
      ),
    ];

    return _VolumeTableShell(
      title: 'Volume Addition',
      rows: rows,
      columns: columns,
    );
  }
}

class _VolumeLossTab extends StatelessWidget {
  final List<VolumeHistoryRow> rows;

  const _VolumeLossTab({required this.rows});

  @override
  Widget build(BuildContext context) {
    final columns = [
      _VolumeTableColumn(
        title: 'Dump',
        valueFor: (row) => _formatNumber(row.dump),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Shakers',
        valueFor: (row) => _formatNumber(row.shakers),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Centrifuge',
        valueFor: (row) => _formatNumber(row.centrifuge),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Evaporation',
        valueFor: (row) => _formatNumber(row.evaporation),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Pit Cleaning',
        valueFor: (row) => _formatNumber(row.pitCleaning),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Formation',
        valueFor: (row) => _formatNumber(row.formationLoss),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Abandon in Hole',
        valueFor: (row) => _formatNumber(row.abandonInHole),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Left behind Casing',
        valueFor: (row) => _formatNumber(row.leftBehindCasing),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Tripping',
        valueFor: (row) => _formatNumber(row.tripping),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Extra Loss',
        valueFor: (row) => _formatNumber(row.extraLossVolume),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Storage Dump',
        valueFor: (row) => _formatNumber(row.storageDump),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Storage Evap.',
        valueFor: (row) => _formatNumber(row.storageEvaporation),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Storage Pit Cleaning',
        valueFor: (row) => _formatNumber(row.storagePitCleaning),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Storage Loss Total',
        valueFor: (row) => _formatNumber(row.storageLossTotal),
        alignRight: true,
      ),
      _VolumeTableColumn(
        title: 'Loss Total',
        valueFor: (row) => _formatNumber(row.lossTotal),
        alignRight: true,
      ),
    ];

    return _VolumeTableShell(
      title: 'Volume Loss',
      rows: rows,
      columns: columns,
    );
  }
}

class _VolumeTableShell extends StatelessWidget {
  final String title;
  final List<VolumeHistoryRow> rows;
  final List<_VolumeTableColumn> columns;

  const _VolumeTableShell({
    required this.title,
    required this.rows,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _volumePanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _volumeText,
                ),
              ),
            ),
            Expanded(
              child: _LegacyVolumeTable(
                rows: rows,
                columns: columns,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyVolumeTable extends StatefulWidget {
  final List<VolumeHistoryRow> rows;
  final List<_VolumeTableColumn> columns;

  const _LegacyVolumeTable({
    required this.rows,
    required this.columns,
  });

  @override
  State<_LegacyVolumeTable> createState() => _LegacyVolumeTableState();
}

class _LegacyVolumeTableState extends State<_LegacyVolumeTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  bool _syncingHorizontal = false;

  static const double _rowHeight = 31;
  static const double _indexWidth = 52;
  static const double _dateWidth = 102;
  static const double _reportWidth = 70;
  static const double _mdWidth = 82;
  static const double _columnWidth = 126;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController.addListener(
      () => _syncHorizontal(_headerHorizontalController),
    );
    _bodyHorizontalController.addListener(
      () => _syncHorizontal(_bodyHorizontalController),
    );
  }

  void _syncHorizontal(ScrollController source) {
    if (_syncingHorizontal) return;
    _syncingHorizontal = true;
    for (final controller in [
      _headerHorizontalController,
      _bodyHorizontalController,
    ]) {
      if (controller == source || !controller.hasClients) continue;
      controller.jumpTo(
        source.offset.clamp(0, controller.position.maxScrollExtent),
      );
    }
    _syncingHorizontal = false;
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicWidth = widget.columns.length * _columnWidth;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Container(
            height: _rowHeight,
            color: _volumeHeaderFill,
            child: Row(
              children: [
                _headerCell('No', _indexWidth),
                _headerCell('Date', _dateWidth),
                _headerCell('Rpt #', _reportWidth),
                _headerCell('MD (ft)', _mdWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: dynamicWidth,
                      child: Row(
                        children: widget.columns
                            .map((column) => _headerCell(column.title, _columnWidth))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: _indexWidth + _dateWidth + _reportWidth + _mdWidth,
                  child: ListView.builder(
                    itemCount: widget.rows.length,
                    itemBuilder: (context, index) {
                      final row = widget.rows[index];
                      return SizedBox(
                        height: _rowHeight,
                        child: Row(
                          children: [
                            _dataCell('${index + 1}', _indexWidth, index),
                            _dataCell(
                              _formatDate(row.reportDate, row.createdAt),
                              _dateWidth,
                              index,
                            ),
                            _dataCell(row.reportLabel, _reportWidth, index),
                            _dataCell(_formatNumber(row.md), _mdWidth, index),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _bodyHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: dynamicWidth,
                      child: ListView.builder(
                        itemCount: widget.rows.length,
                        itemBuilder: (context, index) {
                          final row = widget.rows[index];
                          return SizedBox(
                            height: _rowHeight,
                            child: Row(
                              children: widget.columns.map((column) {
                                return _dataCell(
                                  column.valueFor(row),
                                  _columnWidth,
                                  index,
                                  alignRight: column.alignRight,
                                );
                              }).toList(),
                            ),
                          );
                        },
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

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _volumeHeaderFill,
        border: Border.all(color: _volumePanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _volumeText,
        ),
      ),
    );
  }

  Widget _dataCell(
    String text,
    double width,
    int rowIndex, {
    bool alignRight = false,
  }) {
    return Container(
      width: width,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: rowIndex.isOdd ? const Color(0xFFF8F8F8) : Colors.white,
        border: Border.all(color: _volumePanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _volumeText),
      ),
    );
  }
}

class _LegacyVolumeGraphPainter extends CustomPainter {
  final List<_VolumeGraphSection> sections;
  final int slotCount;

  const _LegacyVolumeGraphPainter({
    required this.sections,
    required this.slotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftLabelWidth = 92.0;
    const yAxisWidth = 58.0;
    const footerHeight = 30.0;
    const sectionGap = 3.0;
    const tickCount = 5;

    final usableHeight =
        size.height - footerHeight - (sections.length - 1) * sectionGap;
    final sectionHeight = usableHeight / sections.length;
    final plotLeft = leftLabelWidth + yAxisWidth;
    final plotRight = size.width - 8;
    final slotWidth = slotCount <= 0 ? 0.0 : (plotRight - plotLeft) / slotCount;

    final borderPaint = Paint()
      ..color = _volumePanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _volumeGrid
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = _volumeLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final pointPaint = Paint()
      ..color = _volumeLine
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int index = 0; index < sections.length; index++) {
      final section = sections[index];
      final top = index * (sectionHeight + sectionGap);
      final bottom = top + sectionHeight;
      final plotRect = Rect.fromLTRB(plotLeft, top, plotRight, bottom);
      final bounds = _niceBounds(section.values);

      canvas.drawRect(plotRect, borderPaint);

      for (int line = 1; line < tickCount; line++) {
        final y = plotRect.top + plotRect.height * line / tickCount;
        canvas.drawLine(
          Offset(plotRect.left, y),
          Offset(plotRect.right, y),
          gridPaint,
        );
      }

      for (int column = 1; column < slotCount; column++) {
        final x = plotRect.left + slotWidth * column;
        canvas.drawLine(
          Offset(x, plotRect.top),
          Offset(x, plotRect.bottom),
          gridPaint,
        );
      }

      for (int tick = 0; tick <= tickCount; tick++) {
        final factor = 1 - (tick / tickCount);
        final value = bounds.min + (bounds.max - bounds.min) * factor;
        final y = plotRect.top + plotRect.height * tick / tickCount;
        textPainter.text = TextSpan(
          text: _formatAxisTick(value, bounds.max - bounds.min),
          style: const TextStyle(fontSize: 9.5, color: _volumeText),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            plotRect.left - textPainter.width - 6,
            y - textPainter.height / 2,
          ),
        );
      }

      _drawVerticalLabel(
        canvas,
        textPainter,
        label: section.label,
        top: top,
        height: sectionHeight,
        width: leftLabelWidth,
      );

      final path = Path();
      var hasSegment = false;

      for (int pointIndex = 0; pointIndex < slotCount; pointIndex++) {
        final value = pointIndex < section.values.length
            ? section.values[pointIndex]
            : null;
        if (value == null) {
          hasSegment = false;
          continue;
        }

        final span = bounds.max - bounds.min;
        final normalized = span <= 0 ? 0.5 : (value - bounds.min) / span;
        final x = plotRect.left + slotWidth * pointIndex + slotWidth / 2;
        final y = plotRect.bottom - plotRect.height * normalized.clamp(0.0, 1.0);

        if (!hasSegment) {
          path.moveTo(x, y);
          hasSegment = true;
        } else {
          path.lineTo(x, y);
        }

        canvas.drawCircle(Offset(x, y), 2.2, pointPaint);
      }

      if (hasSegment) {
        canvas.drawPath(path, linePaint);
      }
    }

    final footerTop = size.height - footerHeight + 4;
    for (int column = 0; column < slotCount; column++) {
      final x = plotLeft + slotWidth * column + slotWidth / 2;
      textPainter.text = TextSpan(
        text: '${column + 1}',
        style: const TextStyle(fontSize: 10, color: _volumeText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, footerTop));
    }

    textPainter.text = const TextSpan(
      text: 'Day',
      style: TextStyle(fontSize: 12, color: _volumeText),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        plotLeft + (plotRight - plotLeft - textPainter.width) / 2,
        size.height - textPainter.height,
      ),
    );
  }

  void _drawVerticalLabel(
    Canvas canvas,
    TextPainter textPainter, {
    required String label,
    required double top,
    required double height,
    required double width,
  }) {
    textPainter.text = TextSpan(
      text: label,
      style: const TextStyle(fontSize: 11, color: _volumeText),
    );
    textPainter.layout();

    canvas.save();
    canvas.translate(12, top + height / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    canvas.drawLine(
      Offset(width, top),
      Offset(width, top + height),
      Paint()
        ..color = _volumePanelBorder
        ..strokeWidth = 1,
    );
  }

  _AxisBounds _niceBounds(List<double> values) {
    if (values.isEmpty) {
      return const _AxisBounds(min: 0, max: 1);
    }

    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);

    if ((maxValue - minValue).abs() < 0.0001) {
      if (maxValue.abs() < 1) {
        return const _AxisBounds(min: 0, max: 1);
      }

      final padding = math.max(0.5, maxValue.abs() * 0.0025);
      minValue -= padding;
      maxValue += padding;
    }

    final rawStep = (maxValue - minValue) / 5;
    final step = _niceStep(rawStep <= 0 ? 1 : rawStep);
    final lower = (minValue / step).floorToDouble() * step;
    final upper = (maxValue / step).ceilToDouble() * step;

    if ((upper - lower).abs() < 0.0001) {
      return _AxisBounds(min: lower, max: lower + step);
    }

    return _AxisBounds(min: lower, max: upper);
  }

  double _niceStep(double value) {
    final exponent = math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
    final fraction = value / exponent;

    if (fraction <= 1) return exponent;
    if (fraction <= 2) return 2 * exponent;
    if (fraction <= 2.5) return 2.5 * exponent;
    if (fraction <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  String _formatAxisTick(double value, double span) {
    if (span >= 50) {
      return value.toStringAsFixed(0);
    }
    if (span >= 5) {
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  bool shouldRepaint(covariant _LegacyVolumeGraphPainter oldDelegate) {
    return oldDelegate.sections != sections || oldDelegate.slotCount != slotCount;
  }
}

class _VolumeMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _VolumeMessageState({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _volumePanelBorder),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _volumeText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _volumeText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolumeGraphSection {
  final String label;
  final List<double> values;

  const _VolumeGraphSection({
    required this.label,
    required this.values,
  });
}

class _VolumeTableColumn {
  final String title;
  final String Function(VolumeHistoryRow row) valueFor;
  final bool alignRight;

  const _VolumeTableColumn({
    required this.title,
    required this.valueFor,
    this.alignRight = false,
  });
}

class _VolumeTabMeta {
  final String title;

  const _VolumeTabMeta({required this.title});
}

class _AxisBounds {
  final double min;
  final double max;

  const _AxisBounds({
    required this.min,
    required this.max,
  });
}

String _formatDate(String raw, String createdAt) {
  final source = raw.trim().isNotEmpty ? raw.trim() : createdAt.trim();
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return source.isEmpty ? '-' : source;
  return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatNumber(double? value, {int digits = 2}) {
  if (value == null) return '0';
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(digits)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
