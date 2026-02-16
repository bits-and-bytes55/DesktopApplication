import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class TimeDistributionTable extends StatefulWidget {
  const TimeDistributionTable({super.key});

  @override
  State<TimeDistributionTable> createState() => _TimeDistributionTableState();
}

class _TimeDistributionTableState extends State<TimeDistributionTable> {
  static const double rowH = 36;

  final List<Map<String, dynamic>> rows = [
    {
      'index': 1,
      'event': 'Make up DP Stds',
      'time': 15.00,
      'percent': 62.5,
      'color': Colors.blue.shade600,
    },
    {
      'index': 2,
      'event': 'Pick Up BHA',
      'time': 5.00,
      'percent': 20.8,
      'color': Colors.green.shade600,
    },
    {
      'index': 3,
      'event': 'Rig-up / Service',
      'time': 3.00,
      'percent': 12.5,
      'color': Colors.orange.shade600,
    },
    {
      'index': 4,
      'event': 'Drilling Formation',
      'time': 1.00,
      'percent': 4.2,
      'color': Colors.red.shade600,
    },
    // Empty rows for adding new data
    ...List.generate(6, (i) => {
          'index': i + 5,
          'event': '',
          'time': 0.0,
          'percent': 0.0,
          'color': Colors.grey.shade400,
        }),
  ];

  final List<Map<String, TextEditingController>> controllers =
      List.generate(10, (_) => {
            'event': TextEditingController(),
            'time': TextEditingController(),
            'percent': TextEditingController(),
          });

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data
    for (int i = 0; i < rows.length; i++) {
      if (i < 4) {
        controllers[i]['event']!.text = rows[i]['event'] as String;
        controllers[i]['time']!.text = (rows[i]['time'] as double).toStringAsFixed(2);
        controllers[i]['percent']!.text = (rows[i]['percent'] as double).toStringAsFixed(1);
      }
    }
  }

  double get totalTime => rows.fold(
      0, (sum, row) => sum + (row['time'] as double));

  double get totalPercent => rows.fold(
      0, (sum, row) => sum + (row['percent'] as double));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
          // Table Title
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(
                  'Time Distribution Data',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add_circle_outline,
                      size: 20, color: Colors.blue.shade600),
                  onPressed: _addRow,
                  tooltip: 'Add Row',
                ),
              ],
            ),
          ),

          // Table Container
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 600,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    height: rowH,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: const Row(
                      children: [
                        _HCell('#', 60),
                        _HCell('Event', 200),
                        _HCell('Time (hr)', 120),
                        _HCell('(%)', 120),
                        _HCell('', 60), // Actions column
                      ],
                    ),
                  ),
            
                  // Table Rows
                  ...List.generate(rows.length, (index) => _row(index)),
            
                  // Total Row
                  Container(
                    height: rowH,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        _cell(
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Total',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          60,
                        ),
                        _cell(const SizedBox(), 200),
                        _cell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              totalTime.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          120,
                        ),
                        _cell(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              totalPercent.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          120,
                        ),
                        _cell(const SizedBox(), 60),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _row(int index) {
    final row = rows[index];
    final isEditable = index >= 4; // First 4 rows are pre-filled data

    return Container(
      height: rowH,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: index == rows.length - 1 ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Index with color dot
          _cell(
            Row(
              children: [
               
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${row['index']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            60,
          ),

          // Event
          _cell(
            _field(controllers[index]['event']!,
                hint: 'Enter event name',
                enabled: isEditable),
            200,
          ),

          // Time
          _cell(
            _field(controllers[index]['time']!,
                hint: '0.00',
                isNumber: true,
                enabled: isEditable,
                onChanged: (value) {
                  if (isEditable) {
                    setState(() {
                      rows[index]['time'] = double.tryParse(value) ?? 0.0;
                      _updatePercent(index);
                    });
                  }
                }),
            120,
          ),

          // Percent
          _cell(
            _field(controllers[index]['percent']!,
                hint: '0.0',
                isNumber: true,
                enabled: isEditable,
                onChanged: (value) {
                  if (isEditable) {
                    setState(() {
                      rows[index]['percent'] = double.tryParse(value) ?? 0.0;
                    });
                  }
                }),
            120,
          ),

          // Actions
          _cell(
            isEditable
                ? IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: Colors.red.shade400),
                    onPressed: () => _removeRow(index),
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox(),
            60,
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller,
      {String hint = '', bool isNumber = false, bool enabled = true, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.grey.shade800 : Colors.grey.shade600,
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onChanged: (value) {
          if (onChanged != null) onChanged(value);
        },
      ),
    );
  }

  Widget _cell(Widget child, double width) {
    return Container(
      width: width,
      height: rowH,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  void _addRow() {
    setState(() {
      final newIndex = rows.length + 1;
      rows.add({
        'index': newIndex,
        'event': '',
        'time': 0.0,
        'percent': 0.0,
        'color': Colors.grey.shade400,
      });
      controllers.add({
        'event': TextEditingController(),
        'time': TextEditingController(),
        'percent': TextEditingController(),
      });
    });
  }

  void _removeRow(int index) {
    if (index >= 4) {
      setState(() {
        rows.removeAt(index);
        controllers.removeAt(index);
        // Reindex remaining rows
        for (int i = 0; i < rows.length; i++) {
          rows[i]['index'] = i + 1;
        }
      });
    }
  }

  void _updatePercent(int index) {
    final total = totalTime;
    if (total > 0) {
      final time = rows[index]['time'] as double;
      final percent = (time / total * 100).toDouble();
      controllers[index]['percent']!.text = percent.toStringAsFixed(1);
      rows[index]['percent'] = percent;
    }
  }
}

class _HCell extends StatelessWidget {
  final String text;
  final double width;
  const _HCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: _TimeDistributionTableState.rowH,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}