import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';

class MaxRopPage extends StatelessWidget {
  MaxRopPage({super.key});

  final EngineeringToolsController c = Get.find<EngineeringToolsController>();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: engineeringPage,
      child: Obx(() {
        AppUnits.signature;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widths = _maxRopWidths(constraints.maxWidth);
              return _layout(
                inputs: [
                  _MaxRopInput(
                    label: 'Hole ID ${AppUnits.diameter}',
                    value: c.maxRopHoleId,
                  ),
                  _MaxRopInput(
                    label: 'Pipe OD ${AppUnits.diameter}',
                    value: c.maxRopPipeOd,
                  ),
                  _MaxRopInput(
                    label: 'Cutting diameter ${AppUnits.diameter}',
                    value: c.maxRopCuttingDiameter,
                  ),
                  _MaxRopInput(
                    label: 'Cutting density ${AppUnits.mudWeight}',
                    value: c.maxRopCuttingDensity,
                  ),
                  _MaxRopInput(
                    label: 'MW ${AppUnits.mudWeight}',
                    value: c.maxRopMw,
                  ),
                  _MaxRopInput(
                    label: 'PV ${AppUnits.viscosity}',
                    value: c.maxRopPv,
                  ),
                  _MaxRopInput(
                    label: 'YP ${AppUnits.yieldPoint}',
                    value: c.maxRopYp,
                  ),
                  _MaxRopInput(
                    label: 'Flow rate ${AppUnits.drillingFlowRate}',
                    value: c.maxRopFlowRate,
                  ),
                  _MaxRopInput(
                    label: 'Cutting concentration (%)',
                    value: c.maxRopCuttingConcentration,
                  ),
                ],
                outputLabel: 'Max. ROP ${AppUnits.rop}',
                outputValue: c.maxRop,
                onCalculate: () => c.calculateMaxRop(),
                leftWidth: widths.left,
                outputWidth: widths.right,
              );
            },
          ),
        );
      }),
    );
  }

  _MaxRopWidths _maxRopWidths(double maxWidth) {
    const buttonWidth = 110.0;
    const gap = 24.0;
    final available = (maxWidth - buttonWidth - gap)
        .clamp(720.0, 1600.0)
        .toDouble();
    final left = (available * 0.46).clamp(420.0, 580.0).toDouble();
    final right = available - left;
    return _MaxRopWidths(left: left, right: right);
  }

  Widget _layout({
    required List<_MaxRopInput> inputs,
    required String outputLabel,
    required RxnDouble outputValue,
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
        _outputTable(outputLabel, outputValue, width: outputWidth),
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

  Widget _inputTable(List<_MaxRopInput> rows, {required double width}) {
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

  Widget _inputRow(_MaxRopInput row, double width) {
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

  Widget _outputTable(
    String label,
    RxnDouble value, {
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: SizedBox(
        height: 30,
        child: Row(
          children: [
            _labelCell(label, width: width * 0.70),
            Expanded(child: Obx(() => _resultCell(_format(value.value)))),
          ],
        ),
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

  String _format(double? value) {
    if (value == null || value.isNaN || value.isInfinite) return '';
    return value.toStringAsFixed(0);
  }
}

class _MaxRopInput {
  const _MaxRopInput({required this.label, required this.value});

  final String label;
  final RxString value;
}

class _MaxRopWidths {
  const _MaxRopWidths({required this.left, required this.right});

  final double left;
  final double right;
}
