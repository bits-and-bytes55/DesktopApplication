import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/bit_hydra_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';

class HydraulicsCompactTool extends StatelessWidget {
  const HydraulicsCompactTool({super.key, required this.tabIndex});

  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    final engineering = Get.find<EngineeringToolsController>();
    final bit = Get.isRegistered<BitHydraulicsController>()
        ? Get.find<BitHydraulicsController>()
        : Get.put(BitHydraulicsController());

    return Obx(() {
      AppUnits.signature;
      return ColoredBox(
        color: engineeringPage,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _content(engineering, bit, constraints.maxWidth);
            },
          ),
        ),
      );
    });
  }

  Widget _content(
    EngineeringToolsController engineering,
    BitHydraulicsController bit,
    double maxWidth,
  ) {
    final widths = _tableWidths(maxWidth);
    switch (tabIndex) {
      case 0:
        return _layout(
          inputs: [
            _HydraulicInput(
              label: 'Pump output ${AppUnits.cementingFlowRate}',
              value: engineering.pumpOutput,
            ),
            _HydraulicInput(
              label: 'Hole size ${AppUnits.diameter}',
              value: engineering.holeSize,
            ),
            _HydraulicInput(
              label: 'Pipe OD ${AppUnits.diameter}',
              value: engineering.pipeOD,
            ),
          ],
          outputs: [
            _HydraulicOutput(
              label: 'Annular velocity ${AppUnits.velocity}',
              value: engineering.annularVelocity,
              decimals: 1,
            ),
          ],
          onCalculate: () => engineering.calculateAnnularVelocity(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 1:
        return _layout(
          inputs: [
            _HydraulicInput(label: 'MW ${AppUnits.mudWeight}', value: bit.mw),
            _HydraulicInput(
              label: 'Pump output ${AppUnits.drillingFlowRate}',
              value: bit.pumpOutput,
            ),
            _HydraulicInput(
              label: 'Standpipe pressure ${AppUnits.pressure}',
              value: bit.standpipePressure,
            ),
            _HydraulicInput(
              label: 'Bit size ${AppUnits.diameter}',
              value: bit.bitSize,
            ),
            ...List.generate(
              bit.jetNozzles.length,
              (index) => _HydraulicInput(
                label: 'Jet nozzle ${index + 1} ${AppUnits.nozzleDiameter}',
                value: bit.jetNozzles[index],
              ),
            ),
          ],
          outputs: [
            _HydraulicOutput(
              label: 'Nozzle area ${AppUnits.crossSection}',
              value: bit.nozzleArea,
              decimals: 3,
            ),
            _HydraulicOutput(
              label: 'Nozzle velocity ${AppUnits.nozzleVelocity}',
              value: bit.nozzleVelocity,
              decimals: 0,
            ),
            _HydraulicOutput(
              label: 'Bit P. drop ${AppUnits.pressure}',
              value: bit.bitPressureDrop,
              decimals: 1,
              trimZeros: true,
              truncate: true,
            ),
            _HydraulicOutput(
              label: 'Hydraulic horsepower ${AppUnits.power}',
              value: bit.hydraulicHP,
              decimals: 1,
            ),
            _HydraulicOutput(
              label: 'Bit HHP / unit bit area',
              value: bit.hhpPerArea,
              decimals: 2,
            ),
            _HydraulicOutput(
              label: 'P. drop (%)',
              value: bit.pressureDropPercent,
              decimals: 1,
              truncate: true,
            ),
            _HydraulicOutput(
              label: 'Jet impact force ${AppUnits.force}',
              value: bit.jetImpactForce,
              decimals: 0,
            ),
          ],
          onCalculate: () => bit.calculateBitHydraulics(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 2:
        return _layout(
          inputs: [
            _HydraulicInput(
              label: 'MW ${AppUnits.mudWeight}',
              value: engineering.criticalAnnulusMw,
            ),
            _HydraulicInput(
              label: 'PV (cP)',
              value: engineering.criticalAnnulusPv,
            ),
            _HydraulicInput(
              label: 'YP ${AppUnits.yieldPoint}',
              value: engineering.criticalAnnulusYp,
            ),
            _HydraulicInput(
              label: 'Hole ID ${AppUnits.diameter}',
              value: engineering.criticalAnnulusHoleId,
            ),
            _HydraulicInput(
              label: 'Pipe OD ${AppUnits.diameter}',
              value: engineering.criticalAnnulusPipeOd,
            ),
          ],
          outputs: [
            _HydraulicOutput(
              label: 'Critical velocity ${AppUnits.velocity}',
              value: engineering.criticalAnnulusVelocity,
              decimals: 1,
            ),
          ],
          onCalculate: () => engineering.calculateCriticalAnnulus(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 3:
        return _layout(
          inputs: [
            _HydraulicInput(
              label: 'MW ${AppUnits.mudWeight}',
              value: engineering.criticalPipeMw,
            ),
            _HydraulicInput(
              label: 'PV (cP)',
              value: engineering.criticalPipePv,
            ),
            _HydraulicInput(
              label: 'YP ${AppUnits.yieldPoint}',
              value: engineering.criticalPipeYp,
            ),
            _HydraulicInput(
              label: 'Pipe ID ${AppUnits.diameter}',
              value: engineering.criticalPipeId,
            ),
          ],
          outputs: [
            _HydraulicOutput(
              label: 'Critical velocity ${AppUnits.velocity}',
              value: engineering.criticalPipeVelocity,
              decimals: 1,
            ),
          ],
          onCalculate: () => engineering.calculateCriticalPipe(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 4:
      default:
        return _layout(
          inputs: [
            _HydraulicInput(
              label: 'MW ${AppUnits.mudWeight}',
              value: engineering.ecdMw,
            ),
            _HydraulicInput(
              label: 'YP ${AppUnits.yieldPoint}',
              value: engineering.ecdYp,
            ),
            _HydraulicInput(
              label: 'Hole Size ${AppUnits.diameter}',
              value: engineering.ecdHoleSize,
            ),
            _HydraulicInput(
              label: 'Pipe OD ${AppUnits.diameter}',
              value: engineering.ecdPipeOd,
            ),
          ],
          outputs: [
            _HydraulicOutput(
              label: 'ECD ${AppUnits.mudWeight}',
              value: engineering.ecd,
            ),
          ],
          onCalculate: () => engineering.calculateEcd(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
    }
  }

  _HydraulicWidths _tableWidths(double maxWidth) {
    const buttonWidth = 110.0;
    const gap = 24.0;
    final available = (maxWidth - buttonWidth - gap)
        .clamp(720.0, 1600.0)
        .toDouble();
    final left = (available * 0.46).clamp(420.0, 580.0).toDouble();
    final right = available - left;
    return _HydraulicWidths(left: left, right: right);
  }

  Widget _layout({
    required List<_HydraulicInput> inputs,
    required List<_HydraulicOutput> outputs,
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

  Widget _inputTable(List<_HydraulicInput> rows, {required double width}) {
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

  Widget _inputRow(_HydraulicInput row, double width) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _labelCell(row.label, width: width * 0.70),
          Expanded(
            child: _valueEditor(row.value),
          ),
        ],
      ),
    );
  }

  Widget _outputTable(List<_HydraulicOutput> rows, {required double width}) {
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

  Widget _outputRow(_HydraulicOutput row, double width) {
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
                  trimZeros: row.trimZeros,
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
    bool trimZeros = false,
    bool truncate = false,
  }) {
    if (value == null || value.isNaN || value.isInfinite) return '';
    if (decimals != null) {
      final factor = math.pow(10, decimals).toDouble();
      final displayValue = truncate ? (value * factor).truncate() / factor : value;
      final formatted = displayValue.toStringAsFixed(decimals);
      if (!trimZeros) return formatted;
      return formatted
          .replaceFirst(RegExp(r'\.0+$'), '')
          .replaceFirst(RegExp(r'(\.\d*?)0+$'), r'$1');
    }
    return formatOperationNumber(
      value,
      fallbackDecimals: 2,
      trimFallback: true,
    );
  }
}

class _HydraulicInput {
  const _HydraulicInput({required this.label, required this.value});

  final String label;
  final RxString value;
}

class _HydraulicOutput {
  const _HydraulicOutput({
    required this.label,
    required this.value,
    this.decimals,
    this.trimZeros = false,
    this.truncate = false,
  });

  final String label;
  final RxnDouble value;
  final int? decimals;
  final bool trimZeros;
  final bool truncate;
}

class _HydraulicWidths {
  const _HydraulicWidths({required this.left, required this.right});

  final double left;
  final double right;
}
