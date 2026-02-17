import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Conversion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ================= LEFT =================
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Parameter'),
                  DropdownButtonFormField(
                    value: parameter,
                    items: const [
                      DropdownMenuItem(
                        value: 'Length',
                        child: Text('Length'),
                      ),
                    ],
                    onChanged: (_) {},
                  ),

                  const SizedBox(height: 16),
                  _label('Input'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: inputCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: calculate,
                        child: const Text('Calculate'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    value: inputUnit,
                    items: const [
                      DropdownMenuItem(value: 'ft', child: Text('(ft)')),
                      DropdownMenuItem(value: 'm', child: Text('(m)')),
                    ],
                    onChanged: (v) => setState(() => inputUnit = v!),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: copyFormula,
                        child: const Text('Copy the Formula'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: copyResult,
                        child: const Text('Copy the Result'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // ================= RIGHT =================
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Output'),
                  TextField(
                    controller: outputCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    value: outputUnit,
                    items: const [
                      DropdownMenuItem(value: 'm', child: Text('(m)')),
                      DropdownMenuItem(value: 'ft', child: Text('(ft)')),
                    ],
                    onChanged: (v) => setState(() => outputUnit = v!),
                  ),

                  const SizedBox(height: 20),
                  _label('Decimal'),
                  DropdownButtonFormField(
                    value: decimalFormat,
                    items: decimalOptions
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => decimalFormat = v!),
                  ),

                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
}
