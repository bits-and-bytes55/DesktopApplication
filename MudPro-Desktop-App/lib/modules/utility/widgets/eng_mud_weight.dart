import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';

class MudWeightPage extends StatelessWidget {
  MudWeightPage({super.key});

  final EngineeringToolsController c = Get.find<EngineeringToolsController>();

  final List<String> tabs = const [
    'Kill Mud Weight',
    'Overbalance Mud Weight',
    'Equivalent Mud Weight',
    'Weight Up (No volume increase)',
    'Weight Up (Volume increase)',
    'Cut Back (No volume change)',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          decoration: const BoxDecoration(
            color: engineeringColumn,
            border: Border(bottom: BorderSide(color: engineeringGrid)),
          ),
          child: Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final isActive = c.activeMudWeightTab.value == index;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => c.activeMudWeightTab.value = index,
                      child: Container(
                        width: _tabWidth(index),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : engineeringColumn,
                          border: const Border(
                            right: BorderSide(color: engineeringGrid),
                            bottom: BorderSide(color: engineeringGrid),
                          ),
                        ),
                        child: Text(
                          tabs[index],
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          style: engineeringDataText,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            AppUnits.signature;
            final activeTab = c.activeMudWeightTab.value;
            return ColoredBox(
              color: engineeringPage,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _content(activeTab, constraints.maxWidth);
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  double _tabWidth(int index) {
    switch (index) {
      case 3:
      case 4:
      case 5:
        return 245;
      case 1:
      case 2:
        return 190;
      default:
        return 130;
    }
  }

  Widget _content(int activeTab, double maxWidth) {
    final widths = _mudWeightWidths(maxWidth);
    switch (activeTab) {
      case 0:
        return _layout(
          inputs: [
            _MudWeightInput(label: 'MW ${AppUnits.mudWeight}', value: c.killMw),
            _MudWeightInput(label: 'SIDPP ${AppUnits.pressure}', value: c.killSidpp),
            _MudWeightInput(label: 'TVD ${AppUnits.length}', value: c.killTvd),
          ],
          outputs: [
            _MudWeightOutput(
              label: 'Kill mud weight ${AppUnits.mudWeight}',
              value: c.killMudWeight,
              decimals: 1,
            ),
          ],
          onCalculate: () => c.calculateKillMudWeight(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 1:
        return _layout(
          inputs: [
            _MudWeightInput(
              label: 'MW ${AppUnits.mudWeight}',
              value: c.overbalanceMw,
            ),
            _MudWeightInput(
              label: 'SIDPP ${AppUnits.pressure}',
              value: c.overbalanceSidpp,
            ),
            _MudWeightInput(label: 'TVD ${AppUnits.length}', value: c.overbalanceTvd),
          ],
          outputs: [
            _MudWeightOutput(
              label: 'Overbalance mud weight ${AppUnits.mudWeight}',
              value: c.overbalanceMudWeight,
            ),
          ],
          onCalculate: () => c.calculateOverbalanceMudWeight(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 2:
        return _layout(
          inputs: [
            _MudWeightInput(
              label: 'MW ${AppUnits.mudWeight}',
              value: c.equivalentMw,
            ),
            _MudWeightInput(
              label: 'SICP ${AppUnits.pressure}',
              value: c.equivalentSicp,
            ),
            _MudWeightInput(label: 'TVD ${AppUnits.length}', value: c.equivalentTvd),
          ],
          outputs: [
            _MudWeightOutput(
              label: 'Equivalent mud weight ${AppUnits.mudWeight}',
              value: c.equivalentMudWeight,
            ),
          ],
          onCalculate: () => c.calculateEquivalentMudWeight(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 3:
        return _layout(
          inputs: [
            _MudWeightInput(
              label: 'Original mud weight ${AppUnits.mudWeight}',
              value: c.weightUpNoVolumeOriginalMw,
            ),
            _MudWeightInput(
              label: 'Desired mud weight ${AppUnits.mudWeight}',
              value: c.weightUpNoVolumeDesiredMw,
            ),
          ],
          outputs: [
            _MudWeightOutput(
              label: 'Barite addition per 100 bbls (sk)',
              value: c.weightUpNoVolumeBarite,
              decimals: 2,
            ),
            _MudWeightOutput(
              label: 'Volume of original mud to jet ${AppUnits.fluidVolume}',
              value: c.weightUpNoVolumeJet,
            ),
          ],
          onCalculate: () => c.calculateWeightUpNoVolume(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 4:
        return _layout(
          inputs: [
            _MudWeightInput(
              label: 'Original mud weight ${AppUnits.mudWeight}',
              value: c.weightUpVolumeOriginalMw,
            ),
            _MudWeightInput(
              label: 'Desired mud weight ${AppUnits.mudWeight}',
              value: c.weightUpVolumeDesiredMw,
            ),
          ],
          outputs: [
            _MudWeightOutput(
              label: 'Barite addition per 100 bbls (sk)',
              value: c.weightUpVolumeBarite,
            ),
            _MudWeightOutput(
              label: 'Volume increase ${AppUnits.fluidVolume}',
              value: c.weightUpVolumeIncrease,
            ),
          ],
          onCalculate: () => c.calculateWeightUpVolume(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 5:
      default:
        return _layout(
          inputs: [
            _MudWeightInput(
              label: 'Original mud weight ${AppUnits.mudWeight}',
              value: c.cutBackOriginalMw,
            ),
            _MudWeightInput(
              label: 'Desired mud weight ${AppUnits.mudWeight}',
              value: c.cutBackDesiredMw,
            ),
            _MudWeightInput(
              label: 'Cut back fluid weight ${AppUnits.mudWeight}',
              value: c.cutBackFluidWeight,
            ),
            _MudWeightInput(
              label: 'Original mud volume ${AppUnits.fluidVolume}',
              value: c.cutBackOriginalVolume,
            ),
          ],
          outputs: [
            _MudWeightOutput(
              label: 'Volume of mud to jet ${AppUnits.fluidVolume}',
              value: c.cutBackVolumeToJet,
            ),
          ],
          onCalculate: () => c.calculateCutBackNoVolume(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
    }
  }

  _MudWeightWidths _mudWeightWidths(double maxWidth) {
    const buttonWidth = 110.0;
    const gap = 24.0;
    final available = (maxWidth - buttonWidth - gap)
        .clamp(720.0, 1600.0)
        .toDouble();
    final left = (available * 0.46).clamp(420.0, 580.0).toDouble();
    final right = available - left;
    return _MudWeightWidths(left: left, right: right);
  }

  Widget _layout({
    required List<_MudWeightInput> inputs,
    required List<_MudWeightOutput> outputs,
    required VoidCallback onCalculate,
    required double leftWidth,
    required double outputWidth,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputTable(inputs, width: leftWidth),
        const SizedBox(width: 12),
        _calculateButton(onCalculate),
        const SizedBox(width: 12),
        _outputTable(outputs, width: outputWidth),
      ],
    );
  }

  Widget _calculateButton(VoidCallback onPressed) {
    return SizedBox(
      width: 110,
      height: 31,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          textStyle: engineeringDataText,
          side: const BorderSide(color: engineeringBorder),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFF7F7F7),
        ),
        child: const Text('Calculate'),
      ),
    );
  }

  Widget _inputTable(List<_MudWeightInput> rows, {required double width}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows.map((row) => _inputRow(row, width)).toList(),
      ),
    );
  }

  Widget _inputRow(_MudWeightInput row, double width) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _labelCell(row.label, width: width * 0.70),
          Expanded(child: _valueEditor(row.value)),
        ],
      ),
    );
  }

  Widget _outputTable(List<_MudWeightOutput> rows, {required double width}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows.map((row) => _outputRow(row, width)).toList(),
      ),
    );
  }

  Widget _outputRow(_MudWeightOutput row, double width) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _labelCell(row.label, width: width * 0.70),
          Expanded(
            child: Obx(
              () => _resultCell(
                _format(
                  row.value.value,
                  decimals: row.decimals,
                  truncate: row.truncate,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelCell(String text, {required double width}) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: engineeringReadOnly,
        border: Border(
          right: BorderSide(color: engineeringGrid),
          bottom: BorderSide(color: engineeringGrid),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: engineeringDataText,
      ),
    );
  }

  Widget _valueEditor(RxString value) {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: engineeringGrid)),
      ),
      child: Obx(
        () => TextField(
          controller: TextEditingController(text: value.value)
            ..selection = TextSelection.collapsed(offset: value.value.length),
          onChanged: (next) => value.value = next,
          textAlign: TextAlign.left,
          style: engineeringDataText,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _resultCell(String value) {
    return Container(
      height: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFD7),
        border: Border(bottom: BorderSide(color: engineeringGrid)),
      ),
      child: Text(
        value,
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: engineeringDataText,
      ),
    );
  }

  String _format(
    double? value, {
    int? decimals,
    bool truncate = false,
  }) {
    if (value == null || value.isNaN || value.isInfinite) return '';
    if (decimals != null) {
      final factor = math.pow(10, decimals).toDouble();
      final displayValue = truncate ? (value * factor).truncate() / factor : value;
      return displayValue.toStringAsFixed(decimals);
    }
    return formatOperationNumber(
      value,
      fallbackDecimals: 2,
      trimFallback: true,
    );
  }
}

class _MudWeightInput {
  const _MudWeightInput({required this.label, required this.value});

  final String label;
  final RxString value;
}

class _MudWeightOutput {
  const _MudWeightOutput({
    required this.label,
    required this.value,
    this.decimals,
    this.truncate = false,
  });

  final String label;
  final RxnDouble value;
  final int? decimals;
  final bool truncate;
}

class _MudWeightWidths {
  const _MudWeightWidths({required this.left, required this.right});

  final double left;
  final double right;
}
