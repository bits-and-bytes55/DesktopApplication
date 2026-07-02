import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudpro_desktop_app/modules/utility/engineering_tools_ui_pattern.dart';

class UnitConversionView extends StatefulWidget {
  const UnitConversionView({super.key});

  @override
  State<UnitConversionView> createState() => _UnitConversionViewState();
}

class _UnitConversionViewState extends State<UnitConversionView> {
  final TextEditingController inputCtrl = TextEditingController();
  final TextEditingController outputCtrl = TextEditingController();

  String parameter = 'Length';

  String inputUnit = 'ft';
  String outputUnit = 'm';

  String decimalFormat = 'Default';

  final List<String> decimalOptions = [
    'Default',
    '0',
    '0.0',
    '0.00',
    '0.000',
    '0.0000',
    '0.00000',
  ];

  // ---------------- CALCULATION ----------------
  void calculate() {
    final value = double.tryParse(inputCtrl.text);
    if (value == null) {
      outputCtrl.clear();
      return;
    }

    double result = value;

    // Length conversion
    if (inputUnit == 'm' && outputUnit == 'ft') {
      result = value * 3.28084;
    } else if (inputUnit == 'ft' && outputUnit == 'm') {
      result = value * 0.3048;
    }

    outputCtrl.text = _formatDecimal(result);
  }

  String _formatDecimal(double value) {
    if (decimalFormat == 'Default') {
      return value.toStringAsFixed(2);
    }
    final decimals = decimalFormat.split('.').last.length;
    return value.toStringAsFixed(decimals);
  }

  // ---------------- COPY ----------------
  void copyFormula() {
    Clipboard.setData(const ClipboardData(
      text: '1 m = 3.28084 ft\n1 ft = 0.3048 m',
    ));
  }

  void copyResult() {
    Clipboard.setData(ClipboardData(text: outputCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: engineeringDataText,
      child: Scaffold(
        backgroundColor: engineeringPage,
        appBar: AppBar(
          backgroundColor: engineeringSection,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Unit Conversion', style: engineeringSectionText),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _panel(
                  title: 'Input',
                  icon: Icons.input,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Parameter'),
                      DropdownButtonFormField<String>(
                        value: parameter,
                        style: engineeringDataText,
                        decoration: _fieldDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Length',
                            child: Text('Length'),
                          ),
                        ],
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 14),
                      _label('Value'),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: inputCtrl,
                              keyboardType: TextInputType.number,
                              style: engineeringDataText,
                              decoration: _fieldDecoration(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _actionButton(
                            label: 'Calculate',
                            icon: Icons.calculate_outlined,
                            onPressed: calculate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: inputUnit,
                        style: engineeringDataText,
                        decoration: _fieldDecoration(),
                        items: const [
                          DropdownMenuItem(value: 'ft', child: Text('(ft)')),
                          DropdownMenuItem(value: 'm', child: Text('(m)')),
                        ],
                        onChanged: (v) => setState(() => inputUnit = v!),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _actionButton(
                            label: 'Copy Formula',
                            icon: Icons.copy_outlined,
                            onPressed: copyFormula,
                          ),
                          _actionButton(
                            label: 'Copy Result',
                            icon: Icons.content_copy,
                            onPressed: copyResult,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _panel(
                  title: 'Output',
                  icon: Icons.output,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Converted Value'),
                      TextField(
                        controller: outputCtrl,
                        readOnly: true,
                        style: engineeringDataText,
                        decoration: _fieldDecoration(readOnly: true),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: outputUnit,
                        style: engineeringDataText,
                        decoration: _fieldDecoration(),
                        items: const [
                          DropdownMenuItem(value: 'm', child: Text('(m)')),
                          DropdownMenuItem(value: 'ft', child: Text('(ft)')),
                        ],
                        onChanged: (v) => setState(() => outputUnit = v!),
                      ),
                      const SizedBox(height: 18),
                      _label('Decimal'),
                      DropdownButtonFormField<String>(
                        value: decimalFormat,
                        style: engineeringDataText,
                        decoration: _fieldDecoration(),
                        items: decimalOptions
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => decimalFormat = v!),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _actionButton(
                          label: 'Close',
                          icon: Icons.close,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: engineeringBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: engineeringSection,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(title, style: engineeringSectionText),
              ],
            ),
          ),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(12), child: child),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({bool readOnly = false}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: readOnly ? engineeringReadOnly : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: engineeringGrid),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: engineeringGrid),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: engineeringSection),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: engineeringSection,
        foregroundColor: Colors.white,
        textStyle: engineeringDataText.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: engineeringDataText,
        ),
      );
}
