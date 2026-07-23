import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';

class SolidsRemovalPage extends StatelessWidget {
  SolidsRemovalPage({super.key});

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
              final widths = _solidsWidths(constraints.maxWidth);
              return _layout(
                inputs: [
                  _SolidsInput(
                    label: 'Base fluid volume ${AppUnits.fluidVolume}',
                    value: c.solidsBaseFluidVolume,
                  ),
                  _SolidsInput(
                    label: 'Base fluid fraction (%)',
                    value: c.solidsBaseFluidFraction,
                  ),
                  _SolidsInput(
                    label: 'Drilled solids fraction (%)',
                    value: c.solidsDrilledSolidsFraction,
                  ),
                  _SolidsInput(
                    label: 'Wellbore length ${AppUnits.length}',
                    value: c.solidsWellboreLength,
                  ),
                  _SolidsInput(
                    label: 'Wellbore ID ${AppUnits.diameter}',
                    value: c.solidsWellboreId,
                  ),
                ],
                outputs: [
                  _SolidsOutput(
                    label: 'Mud built volume ${AppUnits.fluidVolume}',
                    value: c.solidsMudBuiltVolume,
                  ),
                  _SolidsOutput(
                    label: 'Solids drilled volume ${AppUnits.fluidVolume}',
                    value: c.solidsDrilledVolume,
                  ),
                  _SolidsOutput(
                    label: 'Total dilution ${AppUnits.fluidVolume}',
                    value: c.solidsTotalDilution,
                  ),
                  _SolidsOutput(
                    label: 'Dilution factor',
                    value: c.solidsDilutionFactor,
                  ),
                  _SolidsOutput(
                    label: 'Drilled solids performance (%)',
                    value: c.solidsPerformance,
                  ),
                ],
                onCalculate: () => c.calculateSolidsRemovalPerformance(),
                leftWidth: widths.left,
                outputWidth: widths.right,
              );
            },
          ),
        );
      }),
    );
  }

  _SolidsWidths _solidsWidths(double maxWidth) {
    const buttonWidth = 110.0;
    const gap = 24.0;
    final available = (maxWidth - buttonWidth - gap)
        .clamp(720.0, 1600.0)
        .toDouble();
    final left = (available * 0.46).clamp(420.0, 580.0).toDouble();
    final right = available - left;
    return _SolidsWidths(left: left, right: right);
  }

  Widget _layout({
    required List<_SolidsInput> inputs,
    required List<_SolidsOutput> outputs,
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

  Widget _inputTable(List<_SolidsInput> rows, {required double width}) {
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

  Widget _inputRow(_SolidsInput row, double width) {
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

  Widget _outputTable(List<_SolidsOutput> rows, {required double width}) {
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

  Widget _outputRow(_SolidsOutput row, double width) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _labelCell(row.label, width: width * 0.70),
          Expanded(child: Obx(() => _resultCell(_format(row.value.value)))),
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

  String _format(double? value) {
    if (value == null || value.isNaN || value.isInfinite) return '';
    return formatOperationNumber(
      value,
      fallbackDecimals: 2,
      trimFallback: true,
    );
  }
}

class _SolidsInput {
  const _SolidsInput({required this.label, required this.value});

  final String label;
  final RxString value;
}

class _SolidsOutput {
  const _SolidsOutput({required this.label, required this.value});

  final String label;
  final RxnDouble value;
}

class _SolidsWidths {
  const _SolidsWidths({required this.left, required this.right});

  final double left;
  final double right;
}
