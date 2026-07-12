import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/unit_conversion_service.dart';
import 'package:mudpro_desktop_app/modules/options/unit_definitions.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';

class UnitConversionView extends StatefulWidget {
  const UnitConversionView({super.key});

  @override
  State<UnitConversionView> createState() => _UnitConversionViewState();
}

class _UnitConversionViewState extends State<UnitConversionView> {
  final TextEditingController inputCtrl = TextEditingController();
  final TextEditingController outputCtrl = TextEditingController();

  String parameterNumber = UnitDefinitions.parameters.first['number']!;
  String decimalFormat = 'Default';
  late String inputUnit;
  late String outputUnit;

  final List<String> decimalOptions = const [
    'Default',
    '0',
    '0.0',
    '0.00',
    '0.000',
    '0.0000',
    '0.00000',
  ];

  @override
  void initState() {
    super.initState();
    final units = _unitsFor(parameterNumber);
    inputUnit = units.first;
    outputUnit = units.length > 1 ? units[1] : units.first;
  }

  @override
  void dispose() {
    inputCtrl.dispose();
    outputCtrl.dispose();
    super.dispose();
  }

  void _changeParameter(String nextNumber) {
    final units = _unitsFor(nextNumber);
    setState(() {
      parameterNumber = nextNumber;
      inputUnit = units.first;
      outputUnit = units.length > 1 ? units[1] : units.first;
      outputCtrl.clear();
    });
  }

  void calculate() {
    final value = double.tryParse(inputCtrl.text.trim());
    if (value == null) {
      outputCtrl.clear();
      return;
    }

    final result = UnitConversionService.instance.convertValue(
      value,
      inputUnit,
      outputUnit,
    );
    outputCtrl.text = result == null ? '' : _formatDecimal(result);
  }

  void copyFormula() {
    final result = UnitConversionService.instance.convertValue(
      1.0,
      inputUnit,
      outputUnit,
    );
    final formula = result == null
        ? 'No conversion available for $inputUnit to $outputUnit'
        : '1 $inputUnit = ${_formatDecimal(result)} $outputUnit';
    Clipboard.setData(ClipboardData(text: formula));
  }

  void copyResult() {
    Clipboard.setData(ClipboardData(text: outputCtrl.text));
  }

  String _formatDecimal(double value) {
    if (decimalFormat == 'Default') {
      return formatOperationNumber(
        value,
        fallbackDecimals: 2,
        trimFallback: true,
      );
    }
    final decimals = decimalFormat.contains('.')
        ? decimalFormat.split('.').last.length
        : 0;
    return value.toStringAsFixed(decimals);
  }

  List<String> _unitsFor(String number) {
    return UnitConversionService.instance.getUnitsForParam(number);
  }

  @override
  Widget build(BuildContext context) {
    final units = _unitsFor(parameterNumber);

    return DefaultTextStyle.merge(
      style: engineeringDataText,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F1F1),
        appBar: AppBar(
          toolbarHeight: 34,
          backgroundColor: const Color(0xFFEAF4F8),
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 10,
          title: const Text(
            'Unit Conversion',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(30, 18, 30, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(width: 130, child: _label('Parameter')),
                  SizedBox(width: 360, child: _parameterDropdown()),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 225,
                    child: _inputBlock('Input', inputCtrl),
                  ),
                  const SizedBox(width: 28),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: _button('Calculate', calculate, width: 110),
                  ),
                  const SizedBox(width: 28),
                  SizedBox(
                    width: 235,
                    child: _outputBlock(),
                  ),
                  const SizedBox(width: 28),
                  SizedBox(
                    width: 230,
                    child: _decimalBlock(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 225,
                    height: 142,
                    child: _unitList(
                      units: units,
                      selected: inputUnit,
                      onSelected: (unit) => setState(() => inputUnit = unit),
                    ),
                  ),
                  const SizedBox(width: 166),
                  SizedBox(
                    width: 235,
                    height: 142,
                    child: _unitList(
                      units: units,
                      selected: outputUnit,
                      onSelected: (unit) => setState(() => outputUnit = unit),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _button('Copy the Formula', copyFormula, width: 170),
                  const SizedBox(width: 12),
                  _button('Copy the Result', copyResult, width: 170),
                  const Spacer(),
                  _button(
                    'Close',
                    () => Navigator.pop(context),
                    width: 170,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _parameterDropdown() {
    return SizedBox(
      height: 31,
      child: DropdownButtonFormField<String>(
        value: parameterNumber,
        isExpanded: true,
        menuMaxHeight: 320,
        style: engineeringDataText,
        dropdownColor: Colors.white,
        decoration: _fieldDecoration(),
        items: UnitDefinitions.parameters
            .map(
              (item) => DropdownMenuItem<String>(
                value: item['number'],
                child: Text(
                  item['name']!,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: engineeringDataText,
                ),
              ),
            )
            .toList(),
        selectedItemBuilder: (context) => UnitDefinitions.parameters
            .map(
              (item) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item['name']!,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: engineeringDataText,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) _changeParameter(value);
        },
      ),
    );
  }

  Widget _inputBlock(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        const SizedBox(height: 12),
        SizedBox(
          height: 30,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: engineeringDataText,
            decoration: _fieldDecoration(),
          ),
        ),
      ],
    );
  }

  Widget _outputBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Output'),
        const SizedBox(height: 12),
        SizedBox(
          height: 30,
          child: TextField(
            controller: outputCtrl,
            readOnly: true,
            textAlign: TextAlign.right,
            style: engineeringDataText,
            decoration: _fieldDecoration(readOnly: true),
          ),
        ),
      ],
    );
  }

  Widget _decimalBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Decimal'),
        const SizedBox(height: 12),
        SizedBox(
          height: 30,
          child: DropdownButtonFormField<String>(
            value: decimalFormat,
            isExpanded: true,
            style: engineeringDataText,
            decoration: _fieldDecoration(),
            items: decimalOptions
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: engineeringDataText),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => decimalFormat = value);
              if (outputCtrl.text.isNotEmpty) calculate();
            },
          ),
        ),
      ],
    );
  }

  Widget _unitList({
    required List<String> units,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF9EA9B5)),
      ),
      child: ListView.builder(
        itemCount: units.length,
        itemBuilder: (context, index) {
          final unit = units[index];
          final isSelected = unit == selected;
          return InkWell(
            onTap: () => onSelected(unit),
            child: Container(
              height: 22,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: isSelected ? const Color(0xFF0078D7) : Colors.white,
              child: Text(
                unit,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: engineeringDataText.copyWith(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      textAlign: TextAlign.left,
      style: engineeringDataText.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed, {required double width}) {
    return SizedBox(
      width: width,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          textStyle: engineeringDataText,
          side: const BorderSide(color: Color(0xFFCFCFCF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: engineeringDataText,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({bool readOnly = false}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: readOnly ? engineeringReadOnly : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFFB6B6B6)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFFB6B6B6)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFF1683D8)),
      ),
    );
  }
}
