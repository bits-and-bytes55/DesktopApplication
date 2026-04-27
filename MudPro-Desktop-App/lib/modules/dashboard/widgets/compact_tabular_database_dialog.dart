import 'dart:math' as math;

import 'package:flutter/material.dart';

class CompactTabularDatabaseDialog extends StatefulWidget {
  const CompactTabularDatabaseDialog({super.key});

  @override
  State<CompactTabularDatabaseDialog> createState() =>
      _CompactTabularDatabaseDialogState();
}

class _CompactTabularDatabaseDialogState
    extends State<CompactTabularDatabaseDialog> {
  final List<String> _types = const [
    'CWS',
    'CWS w/ FICD',
    'ECL',
    'Drill Pipe Premium',
    'Heavy Weight DP',
    'Drill Collar',
    'Tubing',
    'Casing',
    'Coiled Tubing',
    'Drill Pipe Class 2',
    'Drill Pipe New',
    'Line Pipe',
    'Aluminum DP',
    'Mud Motor',
    'Drilling Reamer',
    'Rotary Steerable',
    'MWD',
    'LWD',
  ];

  final List<String> _catalogs = const ['Weatherford'];
  final List<String> _ods = const [
    '69.09',
    '69.34',
    '78.23',
    '81.79',
    '82.04',
    '83.06',
    '90.68',
    '90.93',
    '95.76',
    '97.79',
    '100.84',
    '101.60',
    '103.38',
    '104.39',
    '106.68',
    '107.19',
    '110.49',
    '113.54',
  ];
  final List<String> _weights = const ['0.000'];
  final List<String> _grades = const ['Super weld'];

  int _typeIndex = 0;
  int _catalogIndex = 0;
  int _odIndex = 0;
  int _weightIndex = 0;
  int _gradeIndex = 0;
  int _rowIndex = 0;

  List<Map<String, String>> get _rows => List<Map<String, String>>.generate(
    20,
    (_) => {
      'bodyId': '50.67',
      'yield': '33034',
      'connType': 'Various',
      'connOd': '71.63',
      'connId': '50.67',
      'adjWt': '7.900',
    },
  );

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(screenSize.width - 40, 1540.0);
    final dialogHeight = math.min(screenSize.height - 40, 690.0);
    const leftPaneWidth = 285.0;
    const middlePaneWidth = 264.0;
    const gradePaneWidth = 126.0;
    const bodyGapsWidth = 26.0;
    const tablePaneWidth = 814.0;
    const minContentWidth =
        leftPaneWidth +
        middlePaneWidth +
        gradePaneWidth +
        bodyGapsWidth +
        tablePaneWidth;
    final bodyWidth = math.max(minContentWidth, dialogWidth - 20);
    final selectedType = _types[_typeIndex];
    final selectedCatalog = _catalogs[_catalogIndex];
    final selectedOd = _ods[_odIndex];
    final selectedWeight = _weights[_weightIndex];
    final selectedGrade = _grades[_gradeIndex];
    final selectedRow = _rows[_rowIndex];

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _titleBar(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: bodyWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: leftPaneWidth,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _listPane('Type', _types, _typeIndex, (index) {
                                setState(() => _typeIndex = index);
                              }, width: 104),
                              const SizedBox(width: 8),
                              _listPane('Catalog', _catalogs, _catalogIndex, (
                                index,
                              ) {
                                setState(() => _catalogIndex = index);
                              }, width: 126),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: middlePaneWidth,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _listPane('OD (mm)', _ods, _odIndex, (index) {
                                setState(() => _odIndex = index);
                              }, width: 130),
                              const SizedBox(width: 8),
                              _listPane(
                                'Weight (lb/ft)',
                                _weights,
                                _weightIndex,
                                (index) {
                                  setState(() => _weightIndex = index);
                                },
                                width: 126,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _listPane('Grade', _grades, _gradeIndex, (index) {
                          setState(() => _gradeIndex = index);
                        }, width: gradePaneWidth),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: tablePaneWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    height: 28,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFBFC5CC),
                                      ),
                                      color: const Color(0xFFF8F8F8),
                                    ),
                                    child: Text(
                                      '$selectedType - $selectedCatalog : $selectedOd mm , $selectedWeight lb/ft , $selectedGrade',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0D74C7),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFBFC5CC),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          _tableHeader(),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: _rows.length,
                                              itemBuilder: (context, index) {
                                                final row = _rows[index];
                                                final isSelected =
                                                    index == _rowIndex;
                                                return InkWell(
                                                  onTap: () => setState(
                                                    () => _rowIndex = index,
                                                  ),
                                                  child: Container(
                                                    height: 33,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF1D6FCC,
                                                          )
                                                        : Colors.white,
                                                    child: Row(
                                                      children: [
                                                        _dataCell(
                                                          '${index + 1}',
                                                          42,
                                                          isSelected,
                                                          align:
                                                              TextAlign.center,
                                                        ),
                                                        _dataCell(
                                                          row['bodyId']!,
                                                          128,
                                                          isSelected,
                                                        ),
                                                        _dataCell(
                                                          row['yield']!,
                                                          132,
                                                          isSelected,
                                                        ),
                                                        _dataCell(
                                                          row['connType']!,
                                                          126,
                                                          isSelected,
                                                        ),
                                                        _dataCell(
                                                          row['connOd']!,
                                                          128,
                                                          isSelected,
                                                        ),
                                                        _dataCell(
                                                          row['connId']!,
                                                          128,
                                                          isSelected,
                                                        ),
                                                        _dataCell(
                                                          row['adjWt']!,
                                                          130,
                                                          isSelected,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Editor...'),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 110,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop({
                        'type': selectedType,
                        'catalog': selectedCatalog,
                        'odMm': selectedOd,
                        'weightLbFt': selectedRow['adjWt'] ?? selectedWeight,
                        'grade': selectedGrade,
                        'idMm': selectedRow['connId'] ?? '',
                      }),
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text('Accept'),
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

  Widget _titleBar(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Row(
        children: [
          const Text(
            'Tubular Database',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            splashRadius: 14,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _listPane(
    String title,
    List<String> items,
    int selectedIndex,
    ValueChanged<int> onSelected, {
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(title, style: const TextStyle(fontSize: 10)),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBFC5CC)),
              ),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final isSelected = index == selectedIndex;
                  return InkWell(
                    onTap: () => onSelected(index),
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.centerLeft,
                      color: isSelected
                          ? const Color(0xFF1D6FCC)
                          : Colors.white,
                      child: Text(
                        items[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: const [
                SizedBox(width: 42),
                Expanded(child: Center(child: Text('Body'))),
                Expanded(child: Center(child: Text('Connection'))),
                SizedBox(width: 130, child: Center(child: Text('Assembly'))),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: const [
                SizedBox(width: 42),
                SizedBox(
                  width: 128,
                  child: Center(
                    child: Text(
                      'ID\n(mm)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                SizedBox(
                  width: 132,
                  child: Center(
                    child: Text(
                      'Yield\n(psi)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                SizedBox(
                  width: 126,
                  child: Center(
                    child: Text('Type', style: TextStyle(fontSize: 10)),
                  ),
                ),
                SizedBox(
                  width: 128,
                  child: Center(
                    child: Text(
                      'OD\n(mm)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                SizedBox(
                  width: 128,
                  child: Center(
                    child: Text(
                      'ID\n(mm)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Center(
                    child: Text(
                      'Adjust Wt.\n(lb/ft)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(
    String value,
    double width,
    bool selected, {
    TextAlign align = TextAlign.center,
  }) {
    return Container(
      width: width,
      height: 33,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFD4D8DD)),
          bottom: BorderSide(color: Color(0xFFD4D8DD)),
        ),
      ),
      child: Text(
        value,
        textAlign: align,
        style: TextStyle(
          fontSize: 10,
          color: selected ? Colors.white : Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
