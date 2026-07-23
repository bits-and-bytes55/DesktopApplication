import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';

class CostEffectivenessScePage extends StatelessWidget {
  CostEffectivenessScePage({super.key});

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
              final widths = _sceWidths(constraints.maxWidth);
              return _layout(
                inputs: [
                  _SceInput(
                    label: 'Daily operating time (hr)',
                    value: c.sceDailyOperatingTime,
                  ),
                  _SceInput(
                    label: 'Equipment discard flow rate ${AppUnits.drillingFlowRate}',
                    value: c.sceDiscardFlowRate,
                  ),
                  _SceInput(
                    label: 'Discard density ${AppUnits.mudWeight}',
                    value: c.sceDiscardDensity,
                  ),
                  _SceInput(
                    label: 'Solids volume percent (%)',
                    value: c.sceSolidsVolumePercent,
                  ),
                  _SceInput(
                    label: 'Bentonite content (lb/bbl)',
                    value: c.sceBentoniteContent,
                  ),
                  _SceInput(
                    label: 'Chloride content (mg/L)',
                    value: c.sceChlorideContent,
                  ),
                  _SceInput(
                    label: 'Desired drilled solids content (%)',
                    value: c.sceDesiredDrilledSolidsContent,
                  ),
                  _SceInput(
                    label: 'Drilled solids density (SG)',
                    value: c.sceDrilledSolidsDensity,
                  ),
                  _SceInput(
                    label: 'Weighting material density (SG)',
                    value: c.sceWeightingMaterialDensity,
                  ),
                  _SceInput(
                    label: 'Drilling fluid cost per bbl (Kwd)',
                    value: c.sceDrillingFluidCost,
                  ),
                  _SceInput(
                    label: 'Drilling fluid liquid phase cost per bbl (Kwd)',
                    value: c.sceLiquidPhaseCost,
                  ),
                  _SceInput(
                    label: 'Weighting material cost per bbl (Kwd)',
                    value: c.sceWeightingMaterialCost,
                  ),
                  _SceInput(
                    label: 'Chemicals cost per bbl (Kwd)',
                    value: c.sceChemicalsCost,
                  ),
                  _SceInput(
                    label: 'Daily rental equipment cost (Kwd)',
                    value: c.sceDailyRentalEquipmentCost,
                  ),
                  _SceInput(
                    label: 'Waster disposal cost per bbl (Kwd)',
                    value: c.sceWasteDisposalCost,
                  ),
                ],
                outputs: [
                  _SceOutput(
                    label: 'Corrected liquid content (%)',
                    value: c.sceCorrectedLiquidContent,
                  ),
                  _SceOutput(
                    label: 'Corrected solids content (%)',
                    value: c.sceCorrectedSolidsContent,
                  ),
                  _SceOutput(
                    label: 'Liquid phase density (SG)',
                    value: c.sceLiquidPhaseDensity,
                  ),
                  _SceOutput(
                    label: 'Solids density (SG)',
                    value: c.sceSolidsDensity,
                  ),
                  _SceOutput(
                    label: 'Weighting material content (lb/bbl)',
                    value: c.sceWeightingMaterialContent,
                  ),
                  _SceOutput(
                    label: 'Weighting material percentage (%)',
                    value: c.sceWeightingMaterialPercentage,
                  ),
                  _SceOutput(
                    label: 'LGS content (%)',
                    value: c.sceLgsContent,
                  ),
                  _SceOutput(
                    label: 'Drilled solids percentage (%)',
                    value: c.sceDrilledSolidsPercentage,
                  ),
                  _SceOutput(
                    label: 'Drilled solids content (lb/bbl)',
                    value: c.sceDrilledSolidsContent,
                  ),
                  _SceOutput(
                    label: 'Volume per day ${AppUnits.fluidVolume}',
                    value: c.sceVolumePerDay,
                  ),
                  _SceOutput(
                    label: 'Liquid volume ${AppUnits.fluidVolume}',
                    value: c.sceLiquidVolume,
                  ),
                  _SceOutput(
                    label: 'Drilled solids volume ${AppUnits.fluidVolume}',
                    value: c.sceDrilledSolidsVolume,
                  ),
                  _SceOutput(
                    label: 'Weighting material volume ${AppUnits.fluidVolume}',
                    value: c.sceWeightingMaterialVolume,
                  ),
                  _SceOutput(
                    label: 'Weighting material cost per day (Kwd)',
                    value: c.sceWeightingMaterialCostPerDay,
                  ),
                  _SceOutput(
                    label: 'Chemicals cost per day (Kwd)',
                    value: c.sceChemicalsCostPerDay,
                  ),
                  _SceOutput(
                    label: 'Liquid cost per day (Kwd)',
                    value: c.sceLiquidCostPerDay,
                  ),
                  _SceOutput(
                    label: 'Dispose cost per day (Kwd)',
                    value: c.sceDisposeCostPerDay,
                  ),
                  _SceOutput(
                    label: 'Total cost per day (Kwd)',
                    value: c.sceTotalCostPerDay,
                  ),
                  _SceOutput(
                    label: 'Dilution volume ${AppUnits.fluidVolume}',
                    value: c.sceDilutionVolume,
                  ),
                  _SceOutput(
                    label: 'Dilution cost per day (Kwd)',
                    value: c.sceDilutionCostPerDay,
                  ),
                  _SceOutput(
                    label: 'Cost Effectiveness',
                    textValue: c.sceCostEffectivenessText,
                  ),
                ],
                onCalculate: () => c.calculateCostEffectivenessSce(),
                leftWidth: widths.left,
                outputWidth: widths.right,
              );
            },
          ),
        );
      }),
    );
  }

  _SceWidths _sceWidths(double maxWidth) {
    const buttonWidth = 110.0;
    const gap = 24.0;
    final available = (maxWidth - buttonWidth - gap)
        .clamp(720.0, 1600.0)
        .toDouble();
    final left = (available * 0.46).clamp(420.0, 580.0).toDouble();
    final right = available - left;
    return _SceWidths(left: left, right: right);
  }

  Widget _layout({
    required List<_SceInput> inputs,
    required List<_SceOutput> outputs,
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

  Widget _inputTable(List<_SceInput> rows, {required double width}) {
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

  Widget _inputRow(_SceInput row, double width) {
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

  Widget _outputTable(List<_SceOutput> rows, {required double width}) {
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

  Widget _outputRow(_SceOutput row, double width) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _labelCell(row.label, width: width * 0.70),
          Expanded(
            child: Obx(
              () => _resultCell(
                row.textValue?.value ?? _format(row.value?.value),
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

  String _format(double? value) {
    if (value == null || value.isNaN || value.isInfinite) return '';
    return formatOperationNumber(
      value,
      fallbackDecimals: 2,
      trimFallback: true,
    );
  }
}

class _SceInput {
  const _SceInput({required this.label, required this.value});

  final String label;
  final RxString value;
}

class _SceOutput {
  const _SceOutput({required this.label, this.value, this.textValue});

  final String label;
  final RxnDouble? value;
  final RxString? textValue;
}

class _SceWidths {
  const _SceWidths({required this.left, required this.right});

  final double left;
  final double right;
}
