import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/well_comparision/controller/well_comparision_controller.dart';
import 'package:mudpro_desktop_app/modules/well_comparision/model/well_comparision_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

const Color _comparisonPage = Color(0xFFF2F2F2);
const Color _comparisonSection = Color(0xFF6C9BCF);
const Color _comparisonColumn = Color(0xFFEAF3FC);
const Color _comparisonGroup = Color(0xFFE8F1E3);
const Color _comparisonRow = Color(0xFFFFFFD7);
const Color _comparisonGrid = Color(0xFFC8C8C8);
const Color _comparisonText = Color(0xFF222222);

class WellComparisonPage extends StatelessWidget {
  WellComparisonPage({super.key});

  final WellComparisonController controller =
      Get.isRegistered<WellComparisonController>()
      ? Get.find<WellComparisonController>()
      : Get.put(WellComparisonController());

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _comparisonText,
      ),
      child: Scaffold(
        backgroundColor: _comparisonPage,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titleBar(),
              const SizedBox(height: 6),
              _toolButtons(),
              const SizedBox(height: 6),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 52, child: _leftGrid()),
                    const SizedBox(width: 10),
                    Expanded(flex: 50, child: _rightGrid()),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _bottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleBar() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _comparisonSection,
        border: Border.all(color: _comparisonSection),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Well Comparison',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          InkWell(
            onTap: _closeOverlay,
            child: const Icon(Icons.close, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _toolButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _squareToolButton(
          icon: Icons.add_circle_outline,
          tooltip: 'Expand all pads',
          onTap: controller.expandAllPads,
        ),
        const SizedBox(width: 4),
        _squareToolButton(
          icon: Icons.remove_circle_outline,
          tooltip: 'Collapse all pads',
          onTap: controller.collapseAllPads,
        ),
      ],
    );
  }

  Widget _squareToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _comparisonColumn,
            border: Border.all(color: _comparisonGrid),
          ),
          child: Icon(icon, size: 18, color: _comparisonSection),
        ),
      ),
    );
  }

  Widget _leftGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _comparisonGrid),
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return _stateMessage('Loading comparison data...');
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return _stateMessage(controller.errorMessage.value);
        }
        if (controller.pads.isEmpty) {
          return _stateMessage('No wells available for comparison.');
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 790,
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tableHeader(
                      const [
                        26,
                        44,
                        126,
                        102,
                        102,
                        126,
                        88,
                        88,
                        88,
                      ],
                      const [
                        '',
                        '',
                        'Well Name',
                        'Operator',
                        'Field/Block',
                        'API Well No.',
                        'Rig',
                        'Spud Date',
                        'Selection',
                      ],
                    ),
                    ...controller.pads.expand(_padRows),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Iterable<Widget> _padRows(PadModel pad) sync* {
    yield _padGroupRow(pad);
    if (controller.isPadExpanded(pad.padId)) {
      var index = 1;
      for (final well in pad.wells) {
        yield _wellSelectionRow(index, well);
        index += 1;
      }
    }
  }

  Widget _padGroupRow(PadModel pad) {
    return InkWell(
      onTap: () => controller.togglePadExpanded(pad.padId),
      child: Container(
        height: 28,
        decoration: const BoxDecoration(
          color: _comparisonGroup,
          border: Border(bottom: BorderSide(color: _comparisonGrid)),
        ),
        child: Row(
          children: [
            _cell('', 26, background: _comparisonGroup),
            _cell(
              controller.isPadExpanded(pad.padId) ? 'v' : '>',
              44,
              background: _comparisonGroup,
            ),
            Expanded(
              child: Text(
                'Pad: ${pad.padName} (${pad.wells.length})',
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _comparisonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wellSelectionRow(int index, ComparisonWellModel well) {
    return Obx(() {
      final selected = controller.isWellSelected(well);
      return Container(
        height: 28,
        decoration: const BoxDecoration(
          color: _comparisonRow,
          border: Border(bottom: BorderSide(color: _comparisonGrid)),
        ),
        child: Row(
          children: [
            _cell('', 26, background: _comparisonRow),
            _cell(index.toString(), 44, background: _comparisonRow),
            _cell(well.wellName, 126, background: _comparisonRow),
            _cell(well.operatorName, 102, background: _comparisonRow),
            _cell(well.fieldBlock, 102, background: _comparisonRow),
            _cell(well.apiWellNo, 126, background: _comparisonRow),
            _cell(well.rig, 88, background: _comparisonRow),
            _cell(well.spudDate, 88, background: _comparisonRow),
            SizedBox(
              width: 88,
              child: Center(
                child: Checkbox(
                  value: selected,
                  onChanged: well.reports.isEmpty
                      ? null
                      : (value) =>
                            controller.toggleWell(well, value ?? false),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _rightGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _comparisonGrid),
      ),
      child: Obx(() {
        final reports = controller.comparedReports.toList(growable: false);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 782,
            child: Column(
              children: [
                _tableHeader(
                  const [26, 44, 128, 102, 102, 126, 102, 88, 64],
                  const [
                    '',
                    '',
                    'Well Name',
                    'Operator',
                    'Field/Block',
                    'API Well No.',
                    'Rig',
                    'Spud Date',
                    'Status',
                  ],
                ),
                Expanded(
                  child: reports.isEmpty
                      ? const SizedBox.shrink()
                      : SingleChildScrollView(
                          child: Column(
                            children: reports.asMap().entries.map((entry) {
                              return _comparedWellRow(
                                entry.key + 1,
                                entry.value,
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _comparedWellRow(int index, ReportModel report) {
    return Container(
      height: 28,
      decoration: const BoxDecoration(
        color: _comparisonRow,
        border: Border(bottom: BorderSide(color: _comparisonGrid)),
      ),
      child: Row(
        children: [
          _cell('>', 26, background: _comparisonRow),
          _cell(index.toString(), 44, background: _comparisonRow),
          _cell(report.wellName, 128, background: _comparisonRow),
          _cell(report.operatorName, 102, background: _comparisonRow),
          _cell(report.fieldBlock, 102, background: _comparisonRow),
          _cell(report.apiWellNo, 126, background: _comparisonRow),
          _cell(report.rig, 102, background: _comparisonRow),
          _cell(report.spudDate, 88, background: _comparisonRow),
          SizedBox(
            width: 64,
            child: Tooltip(
              message: _statusText(report),
              child: Icon(
                _statusIcon(report),
                size: 18,
                color: _statusColor(report),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<double> widths, List<String> labels) {
    return Container(
      height: 28,
      decoration: const BoxDecoration(
        color: _comparisonColumn,
        border: Border(bottom: BorderSide(color: _comparisonGrid)),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          return _cell(
            labels[index],
            widths[index],
            background: _comparisonColumn,
            header: true,
          );
        }),
      ),
    );
  }

  Widget _cell(
    String value,
    double width, {
    Color background = Colors.white,
    bool header = false,
  }) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: background,
        border: const Border(right: BorderSide(color: _comparisonGrid)),
      ),
      child: Text(
        _valueOrDash(value),
        textAlign: TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 12,
          fontWeight: header ? FontWeight.w600 : FontWeight.w500,
          color: _comparisonText,
        ),
      ),
    );
  }

  Widget _stateMessage(String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 12,
          color: _comparisonText,
        ),
      ),
    );
  }

  Widget _bottomButtons() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 106,
            height: 30,
            child: OutlinedButton(
              onPressed: controller.isComparing.value
                  ? null
                  : controller.compareSelectedWells,
              style: _dialogButtonStyle(),
              child: const Text('Compare'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 106,
            height: 30,
            child: OutlinedButton(
              onPressed: _closeOverlay,
              style: _dialogButtonStyle(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _dialogButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _comparisonText,
      textStyle: const TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      side: const BorderSide(color: _comparisonGrid),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      padding: EdgeInsets.zero,
      backgroundColor: const Color(0xFFF7F7F7),
    );
  }

  void _closeOverlay() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().closeOverlay();
    } else {
      Get.back();
    }
  }

  IconData _statusIcon(ReportModel report) {
    return controller.reportWarning(report).isEmpty
        ? Icons.check_circle_outline
        : Icons.help_outline;
  }

  Color _statusColor(ReportModel report) {
    return controller.reportWarning(report).isEmpty
        ? AppTheme.successColor
        : _comparisonSection;
  }

  String _statusText(ReportModel report) {
    final warning = controller.reportWarning(report);
    return warning.isEmpty ? 'Ready for comparison' : warning;
  }
}

String _valueOrDash(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '' : trimmed;
}
