import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';

class OilMudPage extends StatelessWidget {
  OilMudPage({super.key});

  final EngineeringToolsController c = Get.find<EngineeringToolsController>();

  final List<String> tabs = const [
    'O/W Ratio',
    'Ratio Change',
    'Mixture Density',
    'Starting Volume',
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
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(tabs.length, (index) {
                final isActive = c.activeOilMudTab.value == index;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => c.activeOilMudTab.value = index,
                    child: Container(
                      width: index == 0 ? 96 : 135,
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
        Expanded(
          child: Obx(() {
            AppUnits.signature;
            final activeTab = c.activeOilMudTab.value;
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

  Widget _content(int activeTab, double maxWidth) {
    final widths = _oilMudWidths(maxWidth);
    switch (activeTab) {
      case 0:
        return _layout(
          inputs: [
            _OilMudInput(label: 'Retort oil (%)', value: c.owRetortOil),
            _OilMudInput(label: 'Retort water (%)', value: c.owRetortWater),
          ],
          outputs: [
            _OilMudOutput(label: 'Oil in liquid phase (%)', value: _format(c.owOilInLiquidPhase.value)),
            _OilMudOutput(label: 'Water in liquid phase (%)', value: _format(c.owWaterInLiquidPhase.value)),
          ],
          onCalculate: () => c.calculateOilWaterRatio(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 1:
        return _layout(
          inputs: [
            _OilMudInput(label: 'Retort oil (%)', value: c.ratioRetortOil),
            _OilMudInput(label: 'Retort water (%)', value: c.ratioRetortWater),
            _OilMudInput(label: 'Oil in liquid phase (%)', value: c.ratioOilInLiquidPhase),
            _OilMudInput(label: 'Water in liquid phase (%)', value: c.ratioWaterInLiquidPhase),
            _OilMudInput(label: 'Add', value: c.ratioAdd),
          ],
          outputs: [
            const _OilMudOutput(label: 'Add', value: ''),
            _OilMudOutput(label: 'Volume ${AppUnits.fluidVolume}', value: _format(c.ratioVolume.value)),
          ],
          onCalculate: () => c.calculateOilMudRatioChange(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 2:
        return _layout(
          inputs: [
            _OilMudInput(label: 'Diesel density ${AppUnits.mudWeight}', value: c.mixtureDieselDensity),
            _OilMudInput(label: 'Water density ${AppUnits.mudWeight}', value: c.mixtureWaterDensity),
            _OilMudInput(label: 'Oil in liquid phase (%)', value: c.mixtureOilInLiquidPhase),
            _OilMudInput(label: 'Water in liquid phase (%)', value: c.mixtureWaterInLiquidPhase),
          ],
          outputs: [
            _OilMudOutput(label: 'Mixture density ${AppUnits.mudWeight}', value: _format(c.mixtureDensity.value)),
          ],
          onCalculate: () => c.calculateMixtureDensity(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 3:
      default:
        return _layout(
          inputs: [
            _OilMudInput(label: 'Initial density ${AppUnits.mudWeight}', value: c.startingInitialDensity),
            _OilMudInput(label: 'Desired density ${AppUnits.mudWeight}', value: c.startingDesiredDensity),
            _OilMudInput(label: 'Desired volume ${AppUnits.fluidVolume}', value: c.startingDesiredVolume),
          ],
          outputs: [
            _OilMudOutput(label: 'Starting volume ${AppUnits.fluidVolume}', value: _format(c.startingVolume.value)),
          ],
          onCalculate: () => c.calculateStartingVolume(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
    }
  }

  _OilMudWidths _oilMudWidths(double maxWidth) {
    const buttonWidth = 110.0;
    const gap = 24.0;
    final available = (maxWidth - buttonWidth - gap)
        .clamp(720.0, 1600.0)
        .toDouble();
    final left = (available * 0.46).clamp(420.0, 580.0).toDouble();
    final right = available - left;
    return _OilMudWidths(left: left, right: right);
  }

  Widget _layout({
    required List<_OilMudInput> inputs,
    required List<_OilMudOutput> outputs,
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

  Widget _inputTable(List<_OilMudInput> rows, {required double width}) {
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

  Widget _inputRow(_OilMudInput row, double width) {
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

  Widget _outputTable(List<_OilMudOutput> rows, {required double width}) {
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

  Widget _outputRow(_OilMudOutput row, double width) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _labelCell(row.label, width: width * 0.70),
          Expanded(child: _resultCell(row.value)),
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

class _OilMudInput {
  const _OilMudInput({required this.label, required this.value});

  final String label;
  final RxString value;
}

class _OilMudOutput {
  const _OilMudOutput({required this.label, required this.value});

  final String label;
  final String value;
}

class _OilMudWidths {
  const _OilMudWidths({required this.left, required this.right});

  final double left;
  final double right;
}
