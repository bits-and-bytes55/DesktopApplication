import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';

class PumpOutPage extends StatelessWidget {
  PumpOutPage({super.key});

  final EngineeringToolsController c = Get.find<EngineeringToolsController>();

  final List<String> tabs = const ['Duplex Pump', 'Triplex Pump'];

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
                final isActive = c.activePumpOutTab.value == index;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => c.activePumpOutTab.value = index,
                    child: Container(
                      width: 112,
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
            final activeTab = c.activePumpOutTab.value;
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
    final widths = _pumpOutWidths(maxWidth);
    switch (activeTab) {
      case 0:
        return _layout(
          inputs: [
            _PumpOutInput(label: 'Liner ID ${AppUnits.diameter}', value: c.duplexLinerId),
            _PumpOutInput(label: 'Rod OD ${AppUnits.diameter}', value: c.duplexRodOd),
            _PumpOutInput(label: 'Stroke length ${AppUnits.diameter}', value: c.duplexStrokeLength),
            _PumpOutInput(label: 'Pump efficiency (%)', value: c.duplexEfficiency),
          ],
          outputLabel: 'Pump output ${AppUnits.strokeDisplacement}',
          outputValue: c.duplexPumpOutput,
          onCalculate: () => c.calculateDuplexPump(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
      case 1:
      default:
        return _layout(
          inputs: [
            _PumpOutInput(label: 'Liner ID ${AppUnits.diameter}', value: c.triplexLinerId),
            _PumpOutInput(label: 'Stroke length ${AppUnits.diameter}', value: c.triplexStrokeLength),
            _PumpOutInput(label: 'Pump efficiency (%)', value: c.triplexEfficiency),
          ],
          outputLabel: 'Pump output ${AppUnits.strokeDisplacement}',
          outputValue: c.triplexPumpOutput,
          onCalculate: () => c.calculateTriplexPump(),
          leftWidth: widths.left,
          outputWidth: widths.right,
        );
    }
  }

  _PumpOutWidths _pumpOutWidths(double maxWidth) {
    const buttonWidth = 110.0;
    const gap = 24.0;
    final available = (maxWidth - buttonWidth - gap)
        .clamp(720.0, 1600.0)
        .toDouble();
    final left = (available * 0.46).clamp(420.0, 580.0).toDouble();
    final right = available - left;
    return _PumpOutWidths(left: left, right: right);
  }

  Widget _layout({
    required List<_PumpOutInput> inputs,
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

  Widget _inputTable(List<_PumpOutInput> rows, {required double width}) {
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

  Widget _inputRow(_PumpOutInput row, double width) {
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
            Expanded(
              child: Obx(() => _resultCell(_format(value.value))),
            ),
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
    return formatOperationNumber(
      value,
      fallbackDecimals: 4,
      trimFallback: true,
    );
  }
}

class _PumpOutInput {
  const _PumpOutInput({required this.label, required this.value});

  final String label;
  final RxString value;
}

class _PumpOutWidths {
  const _PumpOutWidths({required this.left, required this.right});

  final double left;
  final double right;
}
