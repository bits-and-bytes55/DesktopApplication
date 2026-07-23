import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';

class VolumePage extends StatelessWidget {
  VolumePage({super.key});

  final EngineeringToolsController c = Get.find<EngineeringToolsController>();

  final List<String> tabs = const [
    'Hole Volume',
    'Annular Volume',
    'Capacity',
    'Displacement',
    'Rectangular Pits',
    'Vertical Cylindrical Tank',
    'Horizontal Cylindrical Tank',
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
                  final isActive = c.activeVolumeTab.value == index;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => c.activeVolumeTab.value = index,
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
            final activeTab = c.activeVolumeTab.value;
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
      case 5:
      case 6:
        return 210;
      case 1:
      case 4:
        return 140;
      default:
        return 112;
    }
  }

  Widget _content(int activeTab, double maxWidth) {
    final widths = _volumeWidths(maxWidth);
    switch (activeTab) {
      case 0:
        return _layout(
          inputs: [
            _VolumeInput(label: 'Hole size ${AppUnits.diameter}', value: c.holeVolumeHoleSize),
            _VolumeInput(label: 'Length ${AppUnits.length}', value: c.holeVolumeLength),
            _VolumeInput(
              label: 'Pipe displacement ${AppUnits.pipeCapacityVolumeLength}',
              value: c.holeVolumePipeDisplacement,
            ),
          ],
          outputs: [
            _VolumeOutput(
              label: 'Hole capacity ${AppUnits.pipeCapacityVolumeLength}',
              value: c.holeCapacity,
              decimals: 2,
            ),
            _VolumeOutput(
              label: 'Hole volume ${AppUnits.fluidVolume}',
              value: c.holeVolume,
              decimals: 2,
            ),
          ],
          onCalculate: () => c.calculateHoleVolume(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 1:
        return _layout(
          inputs: [
            _VolumeInput(label: 'Hole size ${AppUnits.diameter}', value: c.annularVolumeHoleSize),
            _VolumeInput(label: 'Length ${AppUnits.length}', value: c.annularVolumeLength),
            _VolumeInput(
              label: 'Pipe displacement ${AppUnits.pipeCapacityVolumeLength}',
              value: c.annularVolumePipeDisplacement,
            ),
          ],
          outputs: [
            _VolumeOutput(
              label: 'Hole capacity ${AppUnits.pipeCapacityVolumeLength}',
              value: c.annularHoleCapacity,
            ),
            _VolumeOutput(label: 'Annular volume ${AppUnits.fluidVolume}', value: c.annularVolume),
          ],
          onCalculate: () => c.calculateAnnularVolume(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 2:
        return _layout(
          inputs: [
            _VolumeInput(label: 'Pipe ID ${AppUnits.diameter}', value: c.capacityPipeId),
            _VolumeInput(label: 'Pipe length ${AppUnits.length}', value: c.capacityPipeLength),
          ],
          outputs: [
            _VolumeOutput(label: 'Pipe capacity ${AppUnits.fluidVolume}', value: c.pipeCapacity),
          ],
          onCalculate: () => c.calculatePipeCapacity(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 3:
        return _layout(
          inputs: [
            _VolumeInput(label: 'Pipe weight (lb/ft)', value: c.displacementPipeWeight),
            _VolumeInput(label: 'Pipe length ${AppUnits.length}', value: c.displacementPipeLength),
          ],
          outputs: [
            _VolumeOutput(label: 'Pipe displacement ${AppUnits.fluidVolume}', value: c.pipeDisplacement),
          ],
          onCalculate: () => c.calculatePipeDisplacement(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 4:
        return _layout(
          inputs: [
            _VolumeInput(label: 'Pit length ${AppUnits.length}', value: c.rectangularPitLength),
            _VolumeInput(label: 'Pit width ${AppUnits.length}', value: c.rectangularPitWidth),
            _VolumeInput(label: 'Pit depth ${AppUnits.length}', value: c.rectangularPitDepth),
          ],
          outputs: [
            _VolumeOutput(label: 'Total volume ${AppUnits.fluidVolume}', value: c.rectangularTotalVolume),
            _VolumeOutput(label: 'Volume per inch ${AppUnits.fluidVolume}', value: c.rectangularVolumePerInch),
            _VolumeOutput(label: 'Volume per foot ${AppUnits.fluidVolume}', value: c.rectangularVolumePerFoot),
          ],
          onCalculate: () => c.calculateRectangularPits(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 5:
        return _layout(
          inputs: [
            _VolumeInput(label: 'Tank diameter ${AppUnits.diameter}', value: c.verticalTankDiameter),
            _VolumeInput(label: 'Tank height ${AppUnits.diameter}', value: c.verticalTankHeight),
            _VolumeInput(label: 'Fluid depth (bottom to surface) ${AppUnits.diameter}', value: c.verticalTankFluidDepth),
          ],
          outputs: [
            _VolumeOutput(label: 'Tank capacity ${AppUnits.fluidVolume}', value: c.verticalTankCapacity),
            _VolumeOutput(label: 'Fluid volume ${AppUnits.fluidVolume}', value: c.verticalTankFluidVolume),
          ],
          onCalculate: () => c.calculateVerticalTank(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 6:
      default:
        return _layout(
          inputs: [
            _VolumeInput(label: 'Tank diameter ${AppUnits.diameter}', value: c.horizontalTankDiameter),
            _VolumeInput(label: 'Tank length ${AppUnits.diameter}', value: c.horizontalTankLength),
            _VolumeInput(label: 'Fluid depth (bottom to surface) ${AppUnits.diameter}', value: c.horizontalTankFluidDepth),
          ],
          outputs: [
            _VolumeOutput(label: 'Tank capacity ${AppUnits.fluidVolume}', value: c.horizontalTankCapacity),
            _VolumeOutput(label: 'Fluid volume ${AppUnits.fluidVolume}', value: c.horizontalTankFluidVolume),
          ],
          onCalculate: () => c.calculateHorizontalTank(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
    }
  }

  _VolumeWidths _volumeWidths(double maxWidth) {
    const buttonWidth = 110.0;
    const gap = 24.0;
    final available = (maxWidth - buttonWidth - gap)
        .clamp(720.0, 1600.0)
        .toDouble();
    final left = (available * 0.46).clamp(420.0, 580.0).toDouble();
    final right = available - left;
    return _VolumeWidths(left: left, right: right);
  }

  Widget _layout({
    required List<_VolumeInput> inputs,
    required List<_VolumeOutput> outputs,
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

  Widget _inputTable(List<_VolumeInput> rows, {required double width}) {
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

  Widget _inputRow(_VolumeInput row, double width) {
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

  Widget _outputTable(List<_VolumeOutput> rows, {required double width}) {
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

  Widget _outputRow(_VolumeOutput row, double width) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _labelCell(row.label, width: width * 0.70),
          Expanded(
            child: Obx(
              () => _resultCell(
                _format(row.value.value, decimals: row.decimals),
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

  String _format(double? value, {int? decimals}) {
    if (value == null || value.isNaN || value.isInfinite) return '';
    if (decimals != null) return value.toStringAsFixed(decimals);
    return formatOperationNumber(
      value,
      fallbackDecimals: 2,
      trimFallback: true,
    );
  }
}

class _VolumeInput {
  const _VolumeInput({required this.label, required this.value});

  final String label;
  final RxString value;
}

class _VolumeOutput {
  const _VolumeOutput({
    required this.label,
    required this.value,
    this.decimals,
  });

  final String label;
  final RxnDouble value;
  final int? decimals;
}

class _VolumeWidths {
  const _VolumeWidths({required this.left, required this.right});

  final double left;
  final double right;
}
