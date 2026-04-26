import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cost_dist/controller/recap_cost_dist_controller.dart';

const Color _costDistOuterBorder = Color(0xFF2F92E8);
const Color _costDistCanvas = Color(0xFFF4F4F4);
const Color _costDistPanelBorder = Color(0xFFC8C8C8);
const Color _costDistHeaderFill = Color(0xFFF7F7F7);
const Color _costDistText = Color(0xFF1C1C1C);
const Color _costDistGrid = Color(0xFFD7D7D7);
const Color _costDistBlueBar = Color(0xFF89ACD9);
const Color _costDistAltBar = Color(0xFF8CC4D7);
const Color _costDistTabFill = Color(0xFFEAEAEA);

class CostDistTabView extends StatefulWidget {
  const CostDistTabView({super.key});

  @override
  State<CostDistTabView> createState() => _CostDistTabViewState();
}

class _CostDistTabViewState extends State<CostDistTabView> {
  int _selectedTab = 0;

  RecapCostDistController get _controller =>
      Get.isRegistered<RecapCostDistController>()
      ? Get.find<RecapCostDistController>()
      : Get.put(RecapCostDistController());

  static const _tabs = [
    _CostDistTabMeta(title: 'Product'),
    _CostDistTabMeta(title: 'Others'),
    _CostDistTabMeta(title: 'Summary'),
    _CostDistTabMeta(title: 'Table'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _costDistCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _costDistOuterBorder, width: 1.4),
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

  Widget _buildContent(RecapCostDistController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _CostDistMessageState(
        title: 'Cost Distribution',
        message: controller.errorMessage.value,
      );
    }

    if (!controller.hasLiveData) {
      return _CostDistMessageState(
        title: 'Cost Distribution',
        message: controller.emptyMessage.value.isNotEmpty
            ? controller.emptyMessage.value
            : 'No live cost distribution data is available.',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _CostDistProductTab(controller: controller);
      case 1:
        return _CostDistOthersTab(controller: controller);
      case 2:
        return _CostDistSummaryTab(controller: controller);
      case 3:
        return _CostDistTableTab(controller: controller);
      default:
        return _CostDistProductTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _costDistCanvas,
        border: Border(left: BorderSide(color: _costDistPanelBorder)),
      ),
      child: Column(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
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
                  color: selected ? Colors.white : _costDistTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _costDistPanelBorder),
                    left: BorderSide(
                      color: selected
                          ? _costDistOuterBorder
                          : _costDistPanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _costDistPanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _costDistPanelBorder)
                        : BorderSide.none,
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      tab.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _costDistText,
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

class _CostDistProductTab extends StatelessWidget {
  final RecapCostDistController controller;

  const _CostDistProductTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ChartPanel(
              title: 'Cost Distribution - Product',
              child: _LegacyPercentChart(
                entries: controller.productSlices,
                barColor: _costDistBlueBar,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ChartPanel(
              title: 'Cost Distribution - Group',
              child: _LegacyPercentChart(
                entries: controller.groupSlices,
                barColor: _costDistBlueBar,
                alternateColor: _costDistAltBar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostDistOthersTab extends StatelessWidget {
  final RecapCostDistController controller;

  const _CostDistOthersTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _ChartPanel(
                    title: 'Cost Distribution - Package',
                    child: _LegacyPercentChart(
                      entries: controller.packageSlices,
                      barColor: _costDistBlueBar,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ChartPanel(
                    title: 'Cost Distribution - Service',
                    child: _LegacyPercentChart(
                      entries: controller.serviceSlices,
                      barColor: _costDistAltBar,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _ChartPanel(
                    title: 'Cost Distribution - Engineering',
                    child: _LegacyPercentChart(
                      entries: controller.engineeringSlices,
                      barColor: _costDistBlueBar,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ChartPanel(
                    title: 'Cost Distribution - All Categories',
                    child: _LegacyPercentChart(
                      entries: controller.allCategorySlices,
                      barColor: _costDistAltBar,
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
}

class _CostDistSummaryTab extends StatelessWidget {
  final RecapCostDistController controller;

  const _CostDistSummaryTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: Row(
              children: [
                SizedBox(
                  width: 880,
                  child: _LegacySummaryPanel(controller: controller),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 6,
            child: _LegacyBreakdownPanel(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _CostDistTableTab extends StatelessWidget {
  final RecapCostDistController controller;

  const _CostDistTableTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 64,
            child: _LegacyProductGroupPanel(controller: controller),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 36,
            child: Column(
              children: [
                Expanded(
                  child: _LegacyCategoryTablePanel(
                    title: 'Cost Distribution - Package',
                    entityLabel: 'Package',
                    rows: controller.packageTableRows,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _LegacyCategoryTablePanel(
                    title: 'Cost Distribution - Service',
                    entityLabel: 'Service',
                    rows: controller.serviceTableRows,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _LegacyCategoryTablePanel(
                    title: 'Cost Distribution - Engineering',
                    entityLabel: 'Engineering',
                    rows: controller.engineeringTableRows,
                    highlightColor: const Color(0xFFA99AD2),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _LegacyCategoryTablePanel(
                    title: 'Cost Distribution - All Categories',
                    entityLabel: 'Category',
                    rows: controller.allCategoryTableRows,
                    categoryMode: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _costDistPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _costDistText,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _LegacyPercentChart extends StatelessWidget {
  final List<CostDistSlice> entries;
  final Color barColor;
  final Color? alternateColor;

  const _LegacyPercentChart({
    required this.entries,
    required this.barColor,
    this.alternateColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _ChartFramePainter()),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 14, 30),
                      child: entries.isEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              children: List.generate(entries.length, (index) {
                                final entry = entries[index];
                                final factor = (entry.percent / 100).clamp(
                                  0.0,
                                  1.0,
                                );
                                final color = index.isEven
                                    ? barColor
                                    : (alternateColor ?? barColor);

                                return Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: factor,
                                      heightFactor: 0.52,
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        color: color,
                                        child: Text(
                                          '${entry.label}, ${entry.percent.toStringAsFixed(1)}%',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _costDistText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const _AxisFooter(),
          ],
        );
      },
    );
  }
}

class _AxisFooter extends StatelessWidget {
  const _AxisFooter();

  @override
  Widget build(BuildContext context) {
    const ticks = ['0', '20', '40', '60', '80', '100'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 14, 6),
      child: Column(
        children: [
          Row(
            children: List.generate(ticks.length, (index) {
              return Expanded(
                child: Align(
                  alignment: index == 0
                      ? Alignment.centerLeft
                      : index == ticks.length - 1
                      ? Alignment.centerRight
                      : Alignment.center,
                  child: Text(
                    ticks[index],
                    style: const TextStyle(fontSize: 10, color: _costDistText),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          const Text('%', style: TextStyle(fontSize: 11, color: _costDistText)),
        ],
      ),
    );
  }
}

class _ChartFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frameRect = Rect.fromLTRB(16, 12, size.width - 14, size.height - 30);
    final borderPaint = Paint()
      ..color = _costDistPanelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = _costDistGrid
      ..strokeWidth = 1;

    canvas.drawRect(frameRect, borderPaint);

    for (int i = 1; i < 5; i++) {
      final x = frameRect.left + frameRect.width * i / 5;
      canvas.drawLine(
        Offset(x, frameRect.top),
        Offset(x, frameRect.bottom),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegacySummaryPanel extends StatelessWidget {
  final RecapCostDistController controller;

  const _LegacySummaryPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _costDistPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Text(
              'Cost Distribution - Summary (After Tax)',
              style: TextStyle(fontSize: 13, color: _costDistText),
            ),
          ),
          Expanded(
            child: Table(
              border: const TableBorder(
                top: BorderSide(color: _costDistPanelBorder),
                left: BorderSide(color: _costDistPanelBorder),
                right: BorderSide(color: _costDistPanelBorder),
                bottom: BorderSide(color: _costDistPanelBorder),
                horizontalInside: BorderSide(color: _costDistPanelBorder),
                verticalInside: BorderSide(color: _costDistPanelBorder),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1.65),
                1: FlexColumnWidth(1.3),
                2: FlexColumnWidth(1.05),
              },
              children: controller.summaryDisplayRows
                  .map((row) {
                    return TableRow(
                      children: [
                        _LegacyCell(text: row.label, align: TextAlign.left),
                        _LegacyCell(text: row.value, align: TextAlign.right),
                        _LegacyCell(text: row.unit, align: TextAlign.left),
                      ],
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyBreakdownPanel extends StatelessWidget {
  final RecapCostDistController controller;

  const _LegacyBreakdownPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _costDistPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Text(
              'Cost Distribution - Breakdown',
              style: TextStyle(fontSize: 13, color: _costDistText),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: _LegacyBreakdownTable(controller: controller),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyBreakdownTable extends StatelessWidget {
  final RecapCostDistController controller;

  const _LegacyBreakdownTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    const widths = <int, TableColumnWidth>{
      0: FixedColumnWidth(110),
      1: FixedColumnWidth(120),
      2: FixedColumnWidth(80),
      3: FixedColumnWidth(120),
      4: FixedColumnWidth(84),
      5: FixedColumnWidth(108),
      6: FixedColumnWidth(84),
      7: FixedColumnWidth(84),
      8: FixedColumnWidth(100),
      9: FixedColumnWidth(92),
      10: FixedColumnWidth(90),
      11: FixedColumnWidth(92),
      12: FixedColumnWidth(92),
      13: FixedColumnWidth(104),
      14: FixedColumnWidth(92),
    };

    return Table(
      columnWidths: widths,
      border: const TableBorder(
        top: BorderSide(color: _costDistPanelBorder),
        left: BorderSide(color: _costDistPanelBorder),
        right: BorderSide(color: _costDistPanelBorder),
        bottom: BorderSide(color: _costDistPanelBorder),
        horizontalInside: BorderSide(color: _costDistPanelBorder),
        verticalInside: BorderSide(color: _costDistPanelBorder),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: _costDistHeaderFill),
          children: const [
            _LegacyHeaderCell('TD\n(ft)', height: 60),
            _LegacyHeaderCell('Interval', height: 60),
            _LegacyHeaderCell('Days', height: 60),
            _LegacyHeaderCell('Mud Type', height: 60),
            _LegacyHeaderCell('', height: 60, colSpanText: 'Subtotal\n(Kwd)'),
            _LegacyBlankHeaderCell(height: 60),
            _LegacyBlankHeaderCell(height: 60),
            _LegacyBlankHeaderCell(height: 60),
            _LegacyBlankHeaderCell(height: 60),
            _LegacyBlankHeaderCell(height: 60),
            _LegacyHeaderCell('Tax\n(Kwd)', height: 60),
            _LegacyHeaderCell('Cost\n(Kwd)', height: 60),
            _LegacyHeaderCell('(Kwd/ft)', height: 60),
            _LegacyHeaderCell('(Kwd/day)', height: 60),
            _LegacyHeaderCell('(ft/day)', height: 60),
          ],
        ),
        TableRow(
          decoration: const BoxDecoration(color: _costDistHeaderFill),
          children: const [
            _LegacyBlankHeaderCell(height: 48),
            _LegacyBlankHeaderCell(height: 48),
            _LegacyBlankHeaderCell(height: 48),
            _LegacyBlankHeaderCell(height: 48),
            _LegacyHeaderCell('Product', height: 48),
            _LegacyHeaderCell('Premixed\nMud', height: 48),
            _LegacyHeaderCell('Package', height: 48),
            _LegacyHeaderCell('Service', height: 48),
            _LegacyHeaderCell('Engineering', height: 48),
            _LegacyHeaderCell('Subtotal', height: 48),
            _LegacyBlankHeaderCell(height: 48),
            _LegacyBlankHeaderCell(height: 48),
            _LegacyBlankHeaderCell(height: 48),
            _LegacyBlankHeaderCell(height: 48),
            _LegacyBlankHeaderCell(height: 48),
          ],
        ),
        ...controller.breakdownRows.map((row) {
          return TableRow(
            children: [
              _LegacyCell(text: row.tdRange),
              _LegacyCell(text: row.interval),
              _LegacyCell(text: '${row.days}', align: TextAlign.center),
              _LegacyCell(text: row.mudType),
              _LegacyCell(
                text: _formatCost(row.product),
                align: TextAlign.right,
              ),
              _LegacyCell(
                text: _formatCost(row.premixedMud),
                align: TextAlign.right,
              ),
              _LegacyCell(
                text: _formatCost(row.package),
                align: TextAlign.right,
              ),
              _LegacyCell(
                text: _formatCost(row.service),
                align: TextAlign.right,
              ),
              _LegacyCell(
                text: _formatCost(row.engineering),
                align: TextAlign.right,
              ),
              _LegacyCell(
                text: _formatCost(row.subtotal),
                align: TextAlign.right,
              ),
              _LegacyCell(text: _formatCost(row.tax), align: TextAlign.right),
              _LegacyCell(text: _formatCost(row.cost), align: TextAlign.right),
              _LegacyCell(
                text: _formatCost(row.costPerFoot),
                align: TextAlign.right,
              ),
              _LegacyCell(
                text: _formatCost(row.costPerDay),
                align: TextAlign.right,
              ),
              _LegacyCell(
                text: _formatDepth(row.footagePerDay),
                align: TextAlign.right,
              ),
            ],
          );
        }),
        TableRow(
          decoration: const BoxDecoration(color: _costDistHeaderFill),
          children: [
            const _LegacyCell(
              text: 'Total/Average',
              isBold: false,
              align: TextAlign.left,
            ),
            const _LegacyCell(text: '', align: TextAlign.left),
            _LegacyCell(
              text: '${controller.breakdownTotal.days}',
              align: TextAlign.center,
            ),
            const _LegacyCell(text: '', align: TextAlign.left),
            _LegacyCell(
              text: _formatCost(controller.breakdownTotal.product),
              align: TextAlign.right,
            ),
            _LegacyCell(
              text: _formatCost(controller.breakdownTotal.premixedMud),
              align: TextAlign.right,
            ),
            _LegacyCell(
              text: _formatCost(controller.breakdownTotal.package),
              align: TextAlign.right,
            ),
            _LegacyCell(
              text: _formatCost(controller.breakdownTotal.service),
              align: TextAlign.right,
            ),
            _LegacyCell(
              text: _formatCost(controller.breakdownTotal.engineering),
              align: TextAlign.right,
            ),
            _LegacyCell(
              text: _formatCost(controller.breakdownTotal.subtotal),
              align: TextAlign.right,
            ),
            _LegacyCell(
              text: _formatCost(controller.breakdownTotal.tax),
              align: TextAlign.right,
            ),
            _LegacyCell(
              text: _formatCost(controller.breakdownTotal.cost),
              align: TextAlign.right,
            ),
            _LegacyCell(
              text: _formatCost(controller.breakdownTotal.costPerFoot),
              align: TextAlign.right,
            ),
            _LegacyCell(
              text: _formatCost(controller.breakdownTotal.costPerDay),
              align: TextAlign.right,
            ),
            _LegacyCell(
              text: _formatDepth(controller.breakdownTotal.footagePerDay),
              align: TextAlign.right,
            ),
          ],
        ),
      ],
    );
  }
}

class _LegacyProductGroupPanel extends StatelessWidget {
  final RecapCostDistController controller;

  const _LegacyProductGroupPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _costDistPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Text(
              'Cost Distribution - Product and Group',
              style: TextStyle(fontSize: 13, color: _costDistText),
            ),
          ),
          Container(
            color: _costDistHeaderFill,
            child: const Row(
              children: [
                SizedBox(width: 24),
                SizedBox(width: 42),
                Expanded(flex: 30, child: _HeaderCellText('Group')),
                Expanded(flex: 19, child: _HeaderCellText('Cost\n(Kwd)')),
                Expanded(flex: 12, child: _HeaderCellText('(%)')),
                SizedBox(width: 42),
                Expanded(flex: 35, child: _HeaderCellText('Product')),
                Expanded(flex: 19, child: _HeaderCellText('Cost\n(Kwd)')),
                Expanded(flex: 12, child: _HeaderCellText('(%)')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: controller.productGroupTableRows.length,
              itemBuilder: (context, index) {
                final row = controller.productGroupTableRows[index];
                return Container(
                  height: 32,
                  decoration: BoxDecoration(
                    border: const Border(
                      top: BorderSide(color: _costDistPanelBorder),
                    ),
                    color: index.isEven
                        ? Colors.white
                        : const Color(0xFFFBFBFB),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: index == 0
                            ? const Icon(
                                Icons.play_arrow,
                                size: 12,
                                color: Color(0xFF6D6D6D),
                              )
                            : const SizedBox(),
                      ),
                      SizedBox(
                        width: 42,
                        child: Center(
                          child: Text(
                            row.groupLabel.isEmpty ? '' : '${index + 1}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 30,
                        child: _BodyCellText(text: row.groupLabel),
                      ),
                      Expanded(
                        flex: 19,
                        child: _BodyCellText(
                          text: _formatCost(row.groupAmount),
                          align: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 12,
                        child: _BodyCellText(
                          text: _formatPercent(row.groupPercent),
                          align: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 42,
                        child: Center(
                          child: Text(
                            row.productLabel.isEmpty ? '' : '${index + 1}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 35,
                        child: _BodyCellText(text: row.productLabel),
                      ),
                      Expanded(
                        flex: 19,
                        child: Container(
                          color: row.productAmount > 0
                              ? const Color(0xFF90B2E3)
                              : null,
                          child: _BodyCellText(
                            text: _formatCost(row.productAmount),
                            align: TextAlign.right,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 12,
                        child: Container(
                          color: row.productAmount > 0
                              ? const Color(0xFF90B2E3)
                              : null,
                          child: _BodyCellText(
                            text: _formatPercent(row.productPercent),
                            align: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            height: 36,
            decoration: const BoxDecoration(
              color: _costDistHeaderFill,
              border: Border(top: BorderSide(color: _costDistPanelBorder)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const SizedBox(width: 42),
                const Expanded(
                  flex: 30,
                  child: _BodyCellText(text: 'Total', isBold: false),
                ),
                Expanded(
                  flex: 19,
                  child: _BodyCellText(
                    text: _formatCost(controller.productGroupCombinedTotal),
                    align: TextAlign.right,
                    isBold: false,
                  ),
                ),
                const Expanded(
                  flex: 12,
                  child: _BodyCellText(
                    text: '100',
                    align: TextAlign.right,
                    isBold: false,
                  ),
                ),
                const SizedBox(width: 42),
                const Expanded(flex: 35, child: SizedBox()),
                Expanded(
                  flex: 19,
                  child: _BodyCellText(
                    text: _formatCost(controller.productGroupCombinedTotal),
                    align: TextAlign.right,
                    isBold: false,
                  ),
                ),
                const Expanded(
                  flex: 12,
                  child: _BodyCellText(
                    text: '100',
                    align: TextAlign.right,
                    isBold: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyCategoryTablePanel extends StatelessWidget {
  final String title;
  final String entityLabel;
  final List<CostDistTableRow> rows;
  final Color? highlightColor;
  final bool categoryMode;

  const _LegacyCategoryTablePanel({
    required this.title,
    required this.entityLabel,
    required this.rows,
    this.highlightColor,
    this.categoryMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<double>(0, (sum, row) => sum + row.amount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _costDistPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: _costDistText),
            ),
          ),
          Container(
            color: _costDistHeaderFill,
            child: Row(
              children: [
                const SizedBox(width: 24),
                Expanded(flex: 38, child: _HeaderCellText(entityLabel)),
                const Expanded(flex: 22, child: _HeaderCellText('Cost\n(Kwd)')),
                const Expanded(flex: 16, child: _HeaderCellText('(%)')),
              ],
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? const SizedBox()
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final rowColor = categoryMode
                          ? _categoryColor(row.label)
                          : (highlightColor ?? Colors.transparent);
                      final useFill =
                          categoryMode ||
                          (highlightColor != null && row.amount > 0);

                      return Container(
                        height: 32,
                        decoration: BoxDecoration(
                          border: const Border(
                            top: BorderSide(color: _costDistPanelBorder),
                          ),
                          color: useFill ? rowColor : Colors.white,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: index == 0
                                  ? const Icon(
                                      Icons.play_arrow,
                                      size: 12,
                                      color: Color(0xFF6D6D6D),
                                    )
                                  : const SizedBox(),
                            ),
                            Expanded(
                              flex: 38,
                              child: _BodyCellText(text: row.label),
                            ),
                            Expanded(
                              flex: 22,
                              child: _BodyCellText(
                                text: _formatCost(row.amount),
                                align: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 16,
                              child: _BodyCellText(
                                text: _formatPercent(row.percent),
                                align: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            height: 36,
            decoration: const BoxDecoration(
              color: _costDistHeaderFill,
              border: Border(top: BorderSide(color: _costDistPanelBorder)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const Expanded(
                  flex: 38,
                  child: _BodyCellText(text: 'Total', isBold: false),
                ),
                Expanded(
                  flex: 22,
                  child: _BodyCellText(
                    text: _formatCost(total),
                    align: TextAlign.right,
                    isBold: false,
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: _BodyCellText(
                    text: total > 0 ? '100' : '100',
                    align: TextAlign.right,
                    isBold: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyHeaderCell extends StatelessWidget {
  final String text;
  final double height;
  final String? colSpanText;

  const _LegacyHeaderCell(this.text, {required this.height, this.colSpanText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        colSpanText ?? text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: _costDistText),
      ),
    );
  }
}

class _LegacyBlankHeaderCell extends StatelessWidget {
  final double height;

  const _LegacyBlankHeaderCell({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

class _LegacyCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  final bool isBold;

  const _LegacyCell({
    required this.text,
    this.align = TextAlign.left,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : align == TextAlign.center
          ? Alignment.center
          : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 11,
          color: _costDistText,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HeaderCellText extends StatelessWidget {
  final String text;

  const _HeaderCellText(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _costDistPanelBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: _costDistText),
      ),
    );
  }
}

class _BodyCellText extends StatelessWidget {
  final String text;
  final TextAlign align;
  final bool isBold;

  const _BodyCellText({
    required this.text,
    this.align = TextAlign.left,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _costDistPanelBorder)),
      ),
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : align == TextAlign.center
          ? Alignment.center
          : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: _costDistText,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _CostDistMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _CostDistMessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _costDistPanelBorder),
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
                  color: _costDistText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _costDistText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostDistTabMeta {
  final String title;

  const _CostDistTabMeta({required this.title});
}

String _formatCost(double value) => value.toStringAsFixed(3);

String _formatPercent(double value) => value.toStringAsFixed(1);

String _formatDepth(double value) => value.toStringAsFixed(1);

Color _categoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'premixed mud':
      return const Color(0xFF8CC4D7);
    case 'engineering':
      return const Color(0xFFA99AD2);
    case 'product':
      return const Color(0xFF90B2E3);
    case 'package':
      return const Color(0xFFF8BE85);
    case 'service':
      return const Color(0xFFC5E09C);
    default:
      return Colors.white;
  }
}
