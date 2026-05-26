import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/concentration/controller/recap_concentration_controller.dart';

const Color _concentrationOuterBorder = Color(0xFF2F92E8);
const Color _concentrationCanvas = Color(0xFFF4F4F4);
const Color _concentrationPanelBorder = Color(0xFFC8C8C8);
const Color _concentrationHeaderFill = Color(0xFFF7F7F7);
const Color _concentrationText = Color(0xFF1C1C1C);
const Color _concentrationGrid = Color(0xFFD6D6D6);
const Color _concentrationTabFill = Color(0xFFEAEAEA);
const Color _concentrationLine = Color(0xFF86D8FB);
const Color _concentrationSelectedHeader = Color(0xFFD7EBFF);
const Color _concentrationSelectedCell = Color(0xFFEFF7FF);

class RecapConcentrationTabView extends StatefulWidget {
  const RecapConcentrationTabView({super.key});

  @override
  State<RecapConcentrationTabView> createState() =>
      _RecapConcentrationTabViewState();
}

class _RecapConcentrationTabViewState extends State<RecapConcentrationTabView> {
  int _selectedTab = 0;

  RecapConcentrationController get _controller =>
      Get.isRegistered<RecapConcentrationController>()
      ? Get.find<RecapConcentrationController>()
      : Get.put(RecapConcentrationController());

  static const _tabs = [
    _ConcentrationTabMeta(title: 'Graph'),
    _ConcentrationTabMeta(title: 'Table'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _concentrationCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _concentrationOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapConcentrationController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _ConcentrationMessageState(
        title: 'Concentration',
        message: controller.errorMessage.value,
      );
    }

    if (controller.rows.isEmpty ||
        controller.products.isEmpty ||
        controller.emptyMessage.value.isNotEmpty) {
      return _ConcentrationMessageState(
        title: 'Concentration',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live concentration history is available for the selected well.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _ConcentrationGraphTab(controller: controller);
      case 1:
        return _ConcentrationTableTab(controller: controller);
      default:
        return _ConcentrationGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _concentrationCanvas,
        border: Border(left: BorderSide(color: _concentrationPanelBorder)),
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
                  color: selected ? Colors.white : _concentrationTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _concentrationPanelBorder),
                    left: BorderSide(
                      color: selected
                          ? _concentrationOuterBorder
                          : _concentrationPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _concentrationPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _concentrationPanelBorder)
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
                        color: _concentrationText,
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

class _ConcentrationGraphTab extends StatelessWidget {
  final RecapConcentrationController controller;

  const _ConcentrationGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final product = controller.selectedProduct;
    if (product == null) {
      return const _ConcentrationMessageState(
        title: 'Concentration',
        message: 'No concentration-enabled product is available to plot.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _concentrationPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: SizedBox(
                height: 34,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Concentration - ${controller.selectedSystem.value}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: _concentrationText,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _SystemDropdown(controller: controller),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 10, 8),
                child: CustomPaint(
                  painter: _LegacyConcentrationGraphPainter(
                    axisLabel: controller.selectedProductAxisLabel,
                    values: controller.endSeries(),
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

class _SystemDropdown extends StatelessWidget {
  final RecapConcentrationController controller;

  const _SystemDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _concentrationPanelBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedSystem.value,
          style: const TextStyle(
            fontSize: 11,
            color: _concentrationText,
          ),
          items: controller.systems
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
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
    );
  }
}

class _ConcentrationTableTab extends StatelessWidget {
  final RecapConcentrationController controller;

  const _ConcentrationTableTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _concentrationPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: SizedBox(
                height: 34,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Concentration Table - ${controller.selectedSystem.value}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: _concentrationText,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _SystemDropdown(controller: controller),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _LegacyConcentrationTable(
                rows: controller.tableRows(),
                products: controller.products.toList(growable: false),
                selectedProductKey: controller.selectedProductKey.value,
                onProductTap: controller.selectProduct,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyConcentrationTable extends StatefulWidget {
  final List<ConcentrationTableRow> rows;
  final List<ConcentrationProductMeta> products;
  final String selectedProductKey;
  final ValueChanged<String> onProductTap;

  const _LegacyConcentrationTable({
    required this.rows,
    required this.products,
    required this.selectedProductKey,
    required this.onProductTap,
  });

  @override
  State<_LegacyConcentrationTable> createState() =>
      _LegacyConcentrationTableState();
}

class _LegacyConcentrationTableState extends State<_LegacyConcentrationTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  bool _syncingHorizontal = false;

  static const double _rowHeight = 31;
  static const double _indexWidth = 52;
  static const double _dateWidth = 102;
  static const double _mdWidth = 82;
  static const double _reportWidth = 70;
  static const double _columnWidth = 154;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        const fixedWidth =
            _indexWidth + _dateWidth + _mdWidth + _reportWidth;
        final baseDynamicWidth = widget.products.length * _columnWidth;
        final availableDynamicWidth =
            (constraints.maxWidth - 16 - fixedWidth)
                .clamp(0, double.infinity)
                .toDouble();
        final dynamicWidth = math.max(baseDynamicWidth, availableDynamicWidth);
        final columnWidth = widget.products.isEmpty
            ? _columnWidth
            : dynamicWidth / widget.products.length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Container(
            height: _rowHeight,
            color: _concentrationHeaderFill,
            child: Row(
              children: [
                _headerCell('No', _indexWidth),
                _headerCell('Date', _dateWidth),
                _headerCell('MD (ft)', _mdWidth),
                _headerCell('Rpt #', _reportWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: dynamicWidth,
                      child: Row(
                        children: widget.products.map((product) {
                          final selected =
                              product.key == widget.selectedProductKey;
                          return _productHeaderCell(
                            product: product,
                            selected: selected,
                            width: columnWidth,
                          );
                        }).toList(growable: false),
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
                  width: fixedWidth,
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
                            _dataCell(_formatNumber(row.md), _mdWidth, index),
                            _dataCell(row.reportLabel, _reportWidth, index),
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
                          final background = index.isOdd
                              ? const Color(0xFFF8F8F8)
                              : Colors.white;
                          return SizedBox(
                            height: _rowHeight,
                            child: Row(
                              children: widget.products.map((product) {
                                final selected =
                                    product.key == widget.selectedProductKey;
                                final value =
                                    row.valuesByProductKey[product.key] ?? 0;
                                return Container(
                                  width: columnWidth,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? _concentrationSelectedCell
                                        : background,
                                    border: Border.all(
                                      color: _concentrationPanelBorder,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    _formatNumber(value),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _concentrationText,
                                    ),
                                  ),
                                );
                              }).toList(growable: false),
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
      },
    );
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _concentrationHeaderFill,
        border: Border.all(color: _concentrationPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _concentrationText,
        ),
      ),
    );
  }

  Widget _productHeaderCell({
    required ConcentrationProductMeta product,
    required bool selected,
    required double width,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onProductTap(product.key),
        child: Container(
          width: width,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? _concentrationSelectedHeader
                : _concentrationHeaderFill,
            border: Border.all(color: _concentrationPanelBorder, width: 0.8),
          ),
          child: Text(
            product.itemName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: _concentrationText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dataCell(String text, double width, int rowIndex) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: rowIndex.isOdd ? const Color(0xFFF8F8F8) : Colors.white,
        border: Border.all(color: _concentrationPanelBorder, width: 0.8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _concentrationText),
      ),
    );
  }
}

class _LegacyConcentrationGraphPainter extends CustomPainter {
  final String axisLabel;
  final List<double> values;
  final int slotCount;

  const _LegacyConcentrationGraphPainter({
    required this.axisLabel,
    required this.values,
    required this.slotCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftLabelWidth = 110.0;
    const yAxisWidth = 44.0;
    const footerHeight = 34.0;
    const topPadding = 6.0;
    final plotLeft = leftLabelWidth + yAxisWidth;
    final plotTop = topPadding;
    final plotRight = size.width - 8;
    final plotBottom = size.height - footerHeight;
    final plotRect = Rect.fromLTRB(plotLeft, plotTop, plotRight, plotBottom);
    final slotWidth = slotCount <= 0 ? 0.0 : (plotRect.width / slotCount);
    final maxValue = _niceMax(values);

    final borderPaint = Paint()
      ..color = _concentrationPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _concentrationGrid
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = _concentrationLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final pointPaint = Paint()
      ..color = _concentrationLine
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    canvas.drawRect(plotRect, borderPaint);

    for (int line = 1; line < 5; line++) {
      final y = plotRect.top + plotRect.height * line / 5;
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

    for (int tick = 0; tick <= 5; tick++) {
      final factor = 1 - (tick / 5);
      final value = maxValue * factor;
      final y = plotRect.top + plotRect.height * tick / 5;
      textPainter.text = TextSpan(
        text: _formatAxisTick(value),
        style: const TextStyle(fontSize: 9.5, color: _concentrationText),
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
      label: axisLabel,
      top: plotTop,
      height: plotRect.height,
      width: leftLabelWidth,
    );

    final path = Path();
    var hasSegment = false;

    for (int index = 0; index < slotCount; index++) {
      final value = index < values.length ? values[index] : null;
      if (value == null) {
        hasSegment = false;
        continue;
      }

      final x = plotRect.left + slotWidth * index + slotWidth / 2;
      final y = plotRect.bottom -
          (plotRect.height * (value / maxValue).clamp(0.0, 1.0));

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

    final footerTop = plotRect.bottom + 6;
    for (int column = 0; column < slotCount; column++) {
      final x = plotRect.left + slotWidth * column + slotWidth / 2;
      textPainter.text = TextSpan(
        text: '${column + 1}',
        style: const TextStyle(fontSize: 10, color: _concentrationText),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, footerTop));
    }

    textPainter.text = const TextSpan(
      text: 'Day',
      style: TextStyle(fontSize: 12, color: _concentrationText),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        plotRect.left + (plotRect.width - textPainter.width) / 2,
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
      style: const TextStyle(fontSize: 11, color: _concentrationText),
    );
    textPainter.layout(maxWidth: height - 24);

    canvas.save();
    canvas.translate(14, top + height / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    canvas.drawLine(
      Offset(width, top),
      Offset(width, top + height),
      Paint()
        ..color = _concentrationPanelBorder
        ..strokeWidth = 1,
    );
  }

  double _niceMax(List<double> series) {
    final filtered = series.where((value) => value > 0).toList(growable: false);
    if (filtered.isEmpty) return 1;
    final maxValue = filtered.reduce(math.max);
    if (maxValue <= 1) return 1;
    if (maxValue <= 2) return 2;
    if (maxValue <= 5) return 5;
    if (maxValue <= 10) return 10;
    if (maxValue <= 20) return 20;
    if (maxValue <= 50) return 50;
    if (maxValue <= 100) return 100;

    final exponent =
        math.pow(10, (math.log(maxValue) / math.ln10).floor()).toDouble();
    final scaled = maxValue / exponent;
    if (scaled <= 2) return 2 * exponent;
    if (scaled <= 5) return 5 * exponent;
    return 10 * exponent;
  }

  String _formatAxisTick(double value) {
    if (value >= 10) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  bool shouldRepaint(covariant _LegacyConcentrationGraphPainter oldDelegate) {
    return oldDelegate.axisLabel != axisLabel ||
        oldDelegate.values != values ||
        oldDelegate.slotCount != slotCount;
  }
}

class _ConcentrationMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _ConcentrationMessageState({
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
          border: Border.all(color: _concentrationPanelBorder),
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
                  color: _concentrationText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _concentrationText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConcentrationTabMeta {
  final String title;

  const _ConcentrationTabMeta({required this.title});
}

String _formatDate(String raw, String createdAt) {
  final source = raw.trim().isNotEmpty ? raw.trim() : createdAt.trim();
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return source.isEmpty ? '-' : source;
  return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatNumber(double? value, {int digits = 2}) {
  if (value == null) return '-';
  if (value.abs() < 0.0001) return '0';
  if (value == value.truncateToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(digits)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
